import 'package:flutter/material.dart';

class CardWiget extends StatelessWidget {
  final Map<String, dynamic> tripData;
  final VoidCallback? onTap; // دالة يتم استدعاؤها عند النقر على البطاقة

  const CardWiget({super.key, required this.tripData, this.onTap});

  @override
  Widget build(BuildContext context) {
    // استخراج البيانات من الـ Map مع توفير قيم افتراضية
    final String tripName = tripData['trip_name'] ?? 'لا يوجد اسم';
    final String tripDate = tripData['trip_date'] ?? 'لا يوجد تاريخ';
    final String tripDuration =
        tripData['trip_time']?.toString() ??
        'لا يوجد مدة'; // 'trip_time' for duration

    // تصحيح: قم بتحويل trip_total إلى double أولاً قبل استخدام toStringAsFixed
    // يتم تحويل القيمة إلى String أولاً باستخدام .toString() للتأكد من أنها نص صالح لـ double.tryParse()
    final double? rawTripTotal = double.tryParse(
      tripData['trip_total']?.toString() ?? '',
    );
    // ثم نقوم بتنسيقها كرقم عشري، وإذا كانت القيمة لا تزال فارغة (null) نعيد '0.00'
    final String tripTotal =
        rawTripTotal?.toStringAsFixed(2) ?? '0.00'; // 'trip_total' for price

    return InkWell(
      // لجعل البطاقة قابلة للنقر وإضافة تأثيرات بصرية
      onTap: onTap, // استدعاء الدالة الممررة عند النقر
      borderRadius: BorderRadius.circular(
        15.0,
      ), // للحفاظ على الزوايا المستديرة عند النقر
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end, // محاذاة النص لليمين
            children: [
              SizedBox(
                height: 50,
                width: 250,
                child: Card(
                  color: Colors.red,
                  child: Text(
                    textAlign: TextAlign.center,
                    " الرحلة : 1",
                  ), // هذا النص ثابت حاليا
                ),
              ),
              SizedBox(
                height: 150,
                width: 250,
                child: Card(
                  color: Colors.amber,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('اسم الرحلة    :   $tripName'),
                      Text('تاريخ الرحلة : $tripDate'),
                      Text('اسم الوكيل الرحلة : محمد'), // هذا نص ثابت حاليا
                      Text("المدة : $tripDuration"),
                      Text('عدد معتمرين داخل الرحلة : 45'), // هذا نص ثابت حاليا
                      Text('اجمالي المبلغ الرحلة : $tripTotal'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
