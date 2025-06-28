import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umrah/screens/edit_calacter_page.dart'; // استيراد صفحة تعديل العقد

class AllContractsPage extends StatefulWidget {
  const AllContractsPage({super.key});

  @override
  State<AllContractsPage> createState() => _AllContractsPageState();
}

class _AllContractsPageState extends State<AllContractsPage> {
  late Future<List<Map<String, dynamic>>> _allContractsFuture;

  @override
  void initState() {
    super.initState();
    _allContractsFuture = _fetchAllContracts();
  }

  // دالة لجلب جميع العقود من جدول 'contracts' وربطها ببيانات الرحلة
  Future<List<Map<String, dynamic>>> _fetchAllContracts() async {
    try {
      // ✅ استخدام .select('*, trips(*)') لجلب جميع أعمدة العقود بالإضافة إلى أعمدة الرحلة المرتبطة
      final List<Map<String, dynamic>> response = await Supabase.instance.client
          .from('contracts')
          .select('*, trips(*)') // ✅ هنا يتم الربط لجلب بيانات الرحلة
          .order('created_at', ascending: false); // الترتيب حسب الأحدث
      print("Contracts fetched: ${response.length}");
      return response;
    } on PostgrestException catch (e) {
      print('Supabase Fetch All Contracts Error: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في جلب جميع العقود: ${e.message}',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    } catch (e) {
      print('General Fetch All Contracts Error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ غير متوقع أثناء جلب العقود: ${e.toString()}',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  // دالة لتحديث قائمة العقود
  void _refreshAllContracts() {
    setState(() {
      _allContractsFuture = _fetchAllContracts();
    });
  }

  // دالة لحذف عقد وتحديث إجمالي الرحلة المرتبطة
  Future<void> _deleteContract(int contractId, int tripId) async {
    final bool confirmDelete =
        await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text(
                'تأكيد الحذف',
                textDirection: TextDirection.rtl,
              ),
              content: const Text(
                'هل أنت متأكد أنك تريد حذف هذا العقد؟ لا يمكن التراجع عن هذا الإجراء.',
                textDirection: TextDirection.rtl,
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(false), // إلغاء
                  child: const Text('إلغاء', textDirection: TextDirection.rtl),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(true), // تأكيد الحذف
                  child: const Text(
                    'حذف',
                    style: TextStyle(color: Colors.red),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmDelete) {
      return;
    }

    try {
      await Supabase.instance.client
          .from('contracts')
          .delete()
          .eq('id', contractId);

      // بعد الحذف الناجح، قم بإعادة حساب إجمالي الرحلة المرتبطة
      await _updateTripTotalInDatabase(tripId);

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
      _refreshAllContracts(); // تحديث واجهة المستخدم بعد الحذف
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
              'خطأ غير متوقع عند حذف العقد: ${e.toString()}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  // دالة مساعدة لتحديث حقل trip_total في جدول trips
  // تم نسخها من TripOverviewPage وتكييفها لـ AllContractsPage
  Future<void> _updateTripTotalInDatabase(int tripId) async {
    try {
      // جلب جميع العقود المرتبطة بهذه الرحلة
      final List<Map<String, dynamic>> contracts = await Supabase
          .instance
          .client
          .from('contracts')
          .select('overall_contract_total')
          .eq('trip_id', tripId);

      // حساب مجموع overall_contract_total
      double newTripTotal = 0.0;
      for (final contract in contracts) {
        newTripTotal += (contract['overall_contract_total'] as double? ?? 0.0);
      }

      // تحديث حقل trip_total في جدول trips
      await Supabase.instance.client
          .from('trips')
          .update({'trip_total': newTripTotal})
          .eq('id', tripId);

      print('Trip total updated for trip ID: $tripId to $newTripTotal');
    } on PostgrestException catch (e) {
      print(
        'Supabase Error updating trip total in AllContractsPage: ${e.message}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في تحديث إجمالي الرحلة: ${e.message}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    } catch (e) {
      print(
        'General Error updating trip total in AllContractsPage: ${e.toString()}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ غير متوقع في تحديث إجمالي الرحلة: ${e.toString()}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كافة العقود', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshAllContracts,
            tooltip: 'تحديث العقود',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _allContractsFuture,
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
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'لا توجد عقود في قاعدة البيانات حتى الآن.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textDirection: TextDirection.rtl,
                ),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final contract = snapshot.data![index];
                // استخراج بيانات الرحلة المرتبطة
                final Map<String, dynamic> associatedTripData =
                    contract['trips'] ?? {}; // تأكد من التعامل مع القيمة null

                // تأكيد التحويلات إلى String لجميع القيم
                final String contractNumber =
                    contract['contract_number']?.toString() ?? 'غير معروف';
                final String agentName =
                    contract['agent_name']?.toString() ?? 'غير معروف';
                final String totalPilgrims = (contract['total_pilgrims'] ?? 0)
                    .toString();
                final String overallTotal =
                    (contract['overall_contract_total'] as double?)
                        ?.toStringAsFixed(2) ??
                    '0.00';
                // استخدام اسم الرحلة من البيانات المرتبطة
                final String tripName =
                    associatedTripData['trip_name']?.toString() ?? 'غير معروف';

                // استخراج أسعار البرنامج من العقد مباشرة
                final double pricePerPersonQuad =
                    (contract['price_per_person_quad'] as double?) ?? 0.0;
                final double pricePerPersonTriple =
                    (contract['price_per_person_triple'] as double?) ?? 0.0;
                final double pricePerPersonDouble =
                    (contract['price_per_person_double'] as double?) ?? 0.0;

                // الحصول على ID العقد والرحلة المرتبطة به
                final int? contractId = contract['id'] as int?;
                final int? tripId = associatedTripData['id'] as int?;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10.0),
                    title: Text(
                      'العقد رقم: $contractNumber (رحلة: $tripName)', // عرض اسم الرحلة أيضاً
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                    // زر الحذف
                    leading: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        if (contractId != null && tripId != null) {
                          _deleteContract(contractId, tripId);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'خطأ: معرف العقد أو الرحلة غير متوفر للحذف.',
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    trailing: const Icon(
                      Icons.edit,
                      size: 20,
                    ), // أيقونة التعديل
                    onTap: () async {
                      if (contractId != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditCalacterPage(
                              tripData:
                                  associatedTripData, // تمرير بيانات الرحلة المرتبطة
                              existingContractData:
                                  contract, // تمرير بيانات العقد الكاملة
                              pricePerPersonQuad: pricePerPersonQuad,
                              pricePerPersonTriple: pricePerPersonTriple,
                              pricePerPersonDouble: pricePerPersonDouble,
                            ),
                          ),
                        );
                        _refreshAllContracts(); // تحديث القائمة بعد العودة من صفحة التعديل
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'خطأ: معرف العقد غير متوفر.',
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
