import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umrah/componets/card.dart'; // تأكد أن هذا المسار صحيح
import 'package:umrah/screens/rip_overview_page.dart';
import 'package:umrah/screens/widget/add_trap_page.dart'; // تأكد أن هذا المسار صحيح

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  // Future لتخزين نتيجة جلب البيانات من Supabase
  late Future<List<Map<String, dynamic>>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = _fetchTrips(); // بدء جلب البيانات عند تهيئة الحالة
  }

  // دالة لجلب الرحلات من جدول 'trips' في Supabase
  Future<List<Map<String, dynamic>>> _fetchTrips() async {
    try {
      // استخدام .select('*') لجلب جميع الأعمدة لجميع الصفوف
      // يمكن إضافة .order('created_at', ascending: false) للترتيب حسب الأحدث مثلاً
      final List<Map<String, dynamic>> response = await Supabase.instance.client
          .from('trips')
          .select('*')
          .order('created_at', ascending: false);
      return response;
    } on PostgrestException catch (e) {
      // معالجة أخطاء Supabase المحددة (مثلاً، RLS، مشكلة في الاستعلام)
      print('Supabase Fetch Error: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في جلب البيانات من قاعدة البيانات: ${e.message}',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return []; // إرجاع قائمة فارغة عند الخطأ
    } catch (e) {
      // معالجة أي أخطاء أخرى غير متوقعة
      print('General Fetch Error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ غير متوقع أثناء جلب الرحلات: ${e.toString()}',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return []; // إرجاع قائمة فارغة عند الخطأ
    }
  }

  // دالة لتحديث قائمة الرحلات (يمكن استدعاؤها بعد إضافة رحلة جديدة)
  void _refreshTrips() {
    setState(() {
      _tripsFuture = _fetchTrips(); // إعادة تعيين Future لإعادة جلب البيانات
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرحلات', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // عرض مؤشر تحميل أثناء جلب البيانات
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // عرض رسالة خطأ إذا فشل الجلب
            return Center(
              child: Text(
                'خطأ: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textDirection: TextDirection
                    .rtl, // Ensure text direction for error message
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // عرض رسالة إذا لم تكن هناك بيانات
            return const Center(
              child: Padding(
                // Add padding for better readability
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'لا توجد رحلات حتى الآن. اضغط على زر الإضافة لإضافة رحلة جديدة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textDirection: TextDirection.rtl,
                ),
              ),
            );
          } else {
            // عرض الرحلات باستخدام Wrap، بناءً على طلبك
            // Map كل بيانات رحلة إلى CardWiget
            List<Widget> tripCards = snapshot.data!
                .map(
                  (trip) => CardWiget(
                    tripData: trip,
                    onTap: () {
                      // عند النقر على البطاقة، انتقل إلى صفحة نظرة عامة على الرحلة
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TripOverviewPage(tripData: trip),
                        ),
                      );
                    },
                  ),
                )
                .toList();

            // يجب استخدام SingleChildScrollView إذا كان عدد البطاقات يمكن أن يتجاوز ارتفاع الشاشة
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0), // تباعد ثابت حول الـ Wrap
                child: Wrap(
                  spacing: 16.0, // المسافة الأفقية بين البطاقات
                  runSpacing: 16.0, // المسافة العمودية بين صفوف البطاقات
                  children: tripCards, // عرض قائمة البطاقات هنا
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // عند الضغط على زر الإضافة، انتقل إلى AddTrapPage
          // وانتظر حتى تعود منها، ثم قم بتحديث قائمة الرحلات
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTrapPage(),
            ), // استخدام const هنا صحيح
          );
          _refreshTrips(); // تحديث الرحلات بعد العودة من صفحة الإضافة
        },
        backgroundColor: Colors.deepPurple.shade400, // لون مميز للزر
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
