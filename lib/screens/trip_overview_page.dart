import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد Supabase
import 'package:umrah/componets/calecror.dart'; // استيراد صفحة الحاسبة
import 'package:umrah/screens/contracts_page.dart'; // استيراد صفحة العقود لعرضها وتعديلها
import 'package:umrah/screens/trips_profit_selection_page.dart'; // استيراد صفحة حساب الأرباح

class TripOverviewPage extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const TripOverviewPage({super.key, required this.tripData});

  @override
  State<TripOverviewPage> createState() => _TripOverviewPageState();
}

class _TripOverviewPageState extends State<TripOverviewPage> {
  // Future لتخزين نتيجة جلب العقود
  late Future<List<Map<String, dynamic>>> _contractsFuture;

  @override
  void initState() {
    super.initState();
    // جلب العقود عند تهيئة الصفحة
    _contractsFuture = _fetchContractsForTrip(widget.tripData['id']);
  }

  // دالة لجلب العقود المرتبطة بـ trip_id معين
  Future<List<Map<String, dynamic>>> _fetchContractsForTrip(int? tripId) async {
    if (tripId == null) {
      return []; // إرجاع قائمة فارغة إذا لم يكن هناك معرف رحلة
    }
    try {
      final List<Map<String, dynamic>> response = await Supabase.instance.client
          .from('contracts')
          .select('*')
          .eq('trip_id', tripId) // فلترة العقود بناءً على trip_id
          .order('created_at', ascending: false); // ترتيب حسب الأحدث
      return response;
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في جلب العقود من قاعدة البيانات: ${e.message}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
      return [];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ غير متوقع أثناء جلب العقود: ${e.toString()}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
      return [];
    }
  }

  // دالة لتحديث قائمة العقود بعد أي تغيير (مثل إضافة عقد جديد أو تعديل)
  void _refreshContracts() {
    setState(() {
      _contractsFuture = _fetchContractsForTrip(widget.tripData['id']);
    });
  }

  // دالة لحذف عقد معين
  Future<void> _deleteContract(int contractId) async {
    try {
      await Supabase.instance.client
          .from('contracts')
          .delete()
          .eq('id', contractId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حذف العقد بنجاح!',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
      _refreshContracts(); // تحديث قائمة العقود
      _updateTripTotalInDatabase(
        widget.tripData['id'] as int,
      ); // تحديث إجمالي الرحلة بعد الحذف
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في حذف العقد: ${e.message}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ غير متوقع أثناء حذف العقد: ${e.toString()}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  // دالة لحذف الرحلة بأكملها
  Future<void> _deleteTrip(int tripId) async {
    try {
      // 1. حذف جميع العقود المرتبطة بهذه الرحلة أولاً
      await Supabase.instance.client
          .from('contracts')
          .delete()
          .eq('trip_id', tripId);

      // 2. ثم حذف الرحلة نفسها
      await Supabase.instance.client.from('trips').delete().eq('id', tripId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حذف الرحلة وجميع عقودها بنجاح!',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        Navigator.pop(context); // العودة إلى الصفحة السابقة (قائمة الرحلات)
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في حذف الرحلة: ${e.message}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ غير متوقع أثناء حذف الرحلة: ${e.toString()}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  // دالة مساعدة لتحديث حقل trip_total في جدول trips
  Future<void> _updateTripTotalInDatabase(int tripId) async {
    try {
      final List<Map<String, dynamic>> contracts = await Supabase
          .instance
          .client
          .from('contracts')
          .select('overall_contract_total')
          .eq('trip_id', tripId);

      double newTripTotal = 0.0;
      for (final contract in contracts) {
        // التحقق من نوع القيمة قبل التحويل
        final dynamic totalValue = contract['overall_contract_total'];
        if (totalValue is num) {
          newTripTotal += totalValue.toDouble();
        } else if (totalValue is String) {
          newTripTotal += double.tryParse(totalValue) ?? 0.0;
        }
      }

      await Supabase.instance.client
          .from('trips')
          .update({'trip_total': newTripTotal})
          .eq('id', tripId);
    } on PostgrestException catch (e) {
      // Handle Supabase error if needed
    } catch (e) {
      // Handle general error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final String tripName = widget.tripData['trip_name'] ?? 'تفاصيل الرحلة';

    // تصحيح تحويل trip_total هنا
    final dynamic rawTripTotalDynamic = widget.tripData['trip_total'];
    double rawTripTotal = 0.0;
    if (rawTripTotalDynamic is num) {
      rawTripTotal = rawTripTotalDynamic.toDouble();
    } else if (rawTripTotalDynamic is String) {
      rawTripTotal = double.tryParse(rawTripTotalDynamic) ?? 0.0;
    }
    final String formattedTripTotal = rawTripTotal.toStringAsFixed(2);

    // تصحيح تحويل القيم هنا
    final String tripDescription =
        widget.tripData['trip_note']?.toString() ?? 'لا يوجد وصف';
    final String tripType =
        widget.tripData['type_trip']?.toString() ?? 'غير محدد';
    final String tripStatus =
        widget.tripData['case_trip']?.toString() ?? 'غير محدد';
    final int madinahNights =
        (widget.tripData['madinah_nights'] as num?)?.toInt() ?? 0;
    final int makkahNights =
        (widget.tripData['makkah_nights'] as num?)?.toInt() ?? 0;
    final int tripDuration =
        (widget.tripData['trip_time'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تفاصيل الرحلة: $tripName',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل الرحلة المختصرة
            Text(
              'اسم الرحلة: ${widget.tripData['trip_name']?.toString() ?? 'غير معروف'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),
            Text(
              'التاريخ: ${widget.tripData['trip_date']?.toString() ?? 'غير معروف'}',
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),
            Text(
              'الإجمالي: \$$formattedTripTotal',
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),
            Text(
              'الوصف: $tripDescription',
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),
            Text(
              'النوع: $tripType',
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),
            Text(
              'الحالة: $tripStatus',
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),
            Text(
              'ليالي المدينة: $madinahNights',
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),
            Text(
              'ليالي مكة: $makkahNights',
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),
            Text(
              'مدة الرحلة (بالأيام): $tripDuration',
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // قسم الأزرار
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CalacterPage(tripData: widget.tripData),
                        ),
                      );
                      _refreshContracts();
                    },
                    icon: const Icon(Icons.add_box, color: Colors.white),
                    label: const Text(
                      'إعداد البرنامج وإنشاء عقد',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textDirection: TextDirection.rtl,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15), // مسافة بين الأزرار

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TripProfitPage(),
                        ),
                      );
                      // يمكنك تحديث بيانات الرحلة هنا إذا كانت صفحة الأرباح تقوم بتعديلات عليها
                      // على سبيل المثال: _refreshTripData();
                    },
                    icon: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'حساب الأرباح',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textDirection: TextDirection.rtl,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.green.shade700, // لون مختلف للتمييز
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15), // مسافة بين الأزرار
            // زر حذف الرحلة
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text(
                              'تأكيد حذف الرحلة',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: const Text(
                              'هل أنت متأكد أنك تريد حذف هذه الرحلة وجميع العقود المرتبطة بها؟ هذا الإجراء لا يمكن التراجع عنه.',
                              textDirection: TextDirection.rtl,
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'إلغاء',
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pop(); // إغلاق نافذة التأكيد
                                  _deleteTrip(
                                    widget.tripData['id'] as int,
                                  ); // استدعاء دالة الحذف
                                },
                                child: const Text(
                                  'حذف',
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text(
                      'حذف الرحلة',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textDirection: TextDirection.rtl,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700, // لون أحمر للتمييز
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // عنوان قسم العقود
            const Text(
              'العقود المرتبطة بهذه الرحلة:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),

            // عرض العقود باستخدام FutureBuilder
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _contractsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'خطأ: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textDirection: TextDirection.rtl,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد عقود لهذه الرحلة حتى الآن.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textDirection: TextDirection.rtl,
                      ),
                    );
                  } else {
                    // عرض قائمة العقود في ListView
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final contract = snapshot.data![index];
                        // تصحيح تحويل القيم هنا في عرض العقود
                        final String contractNumber =
                            contract['contract_number']?.toString() ??
                            'غير معروف';
                        final String agentName =
                            contract['agent_name']?.toString() ?? 'غير معروف';
                        final String totalPilgrims =
                            (contract['total_pilgrims'] as num?)
                                ?.toInt()
                                .toString() ??
                            '0';

                        final dynamic rawOverallTotalDynamic =
                            contract['overall_contract_total'];
                        double rawOverallTotal = 0.0;
                        if (rawOverallTotalDynamic is num) {
                          rawOverallTotal = rawOverallTotalDynamic.toDouble();
                        } else if (rawOverallTotalDynamic is String) {
                          rawOverallTotal =
                              double.tryParse(rawOverallTotalDynamic) ?? 0.0;
                        }
                        final String overallTotal = rawOverallTotal
                            .toStringAsFixed(2);

                        // تصحيح تحويل قيم البرنامج
                        final double contractProgramPriceQuad =
                            (contract['price_per_person_quad'] as num?)
                                ?.toDouble() ??
                            0.0;
                        final double contractProgramPriceTriple =
                            (contract['price_per_person_triple'] as num?)
                                ?.toDouble() ??
                            0.0;
                        final double contractProgramPriceDouble =
                            (contract['price_per_person_double'] as num?)
                                ?.toDouble() ??
                            0.0;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 5.0,
                          ),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10.0),
                            title: Text(
                              'العقد رقم: $contractNumber',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'الوكيل: $agentName',
                                  textDirection: TextDirection.rtl,
                                ),
                                Text(
                                  'إجمالي المعتمرين: $totalPilgrims',
                                  textDirection: TextDirection.rtl,
                                ),
                                Text(
                                  'إجمالي التكلفة: \$$overallTotal',
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CalacterPage(
                                          tripData: widget.tripData,
                                          existingContractData: contract,
                                        ),
                                      ),
                                    );
                                    _refreshContracts();
                                    _updateTripTotalInDatabase(
                                      widget.tripData['id'] as int,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text(
                                            'تأكيد الحذف',
                                            textDirection: TextDirection.rtl,
                                          ),
                                          content: const Text(
                                            'هل أنت متأكد أنك تريد حذف هذا العقد؟',
                                            textDirection: TextDirection.rtl,
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text(
                                                'إلغاء',
                                                textDirection:
                                                    TextDirection.rtl,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(
                                                  context,
                                                ).pop(); // إغلاق نافذة التأكيد
                                                _deleteContract(
                                                  contract['id'] as int,
                                                ); // استدعاء دالة الحذف
                                              },
                                              child: const Text(
                                                'حذف',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                                textDirection:
                                                    TextDirection.rtl,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
