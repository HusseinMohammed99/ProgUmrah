import 'package:flutter/material.dart';
import 'package:umrah/componets/calecror.dart';
import 'package:umrah/screens/contracts_page.dart'; // استيراد صفحة العقود

class TripOverviewPage extends StatelessWidget {
  final Map<String, dynamic> tripData;

  const TripOverviewPage({super.key, required this.tripData});

  @override
  Widget build(BuildContext context) {
    final String tripName = tripData['trip_name'] ?? 'تفاصيل الرحلة';
    // محاولة استخراج id الرحلة إذا كان موجودًا في البيانات (مهم لربط العقود بالرحلة)
    final String tripId = tripData['id']?.toString() ?? 'unknown';

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
              'اسم الرحلة: ${tripData['trip_name'] ?? 'غير معروف'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),
            Text(
              'التاريخ: ${tripData['trip_date'] ?? 'غير معروف'}',
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),
            Text(
              'الإجمالي: \$${tripData['trip_total']?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // زر لعرض/إدارة العقود الخاصة بهذه الرحلة
            ElevatedButton.icon(
              onPressed: () {
                // الانتقال إلى صفحة العقود، مع تمرير معرف الرحلة إذا لزم الأمر
                // حالياً، ContractPage تستقبل أسعار، لذا سنحتاج لتعديلها لاحقاً
                // لكي تستقبل id الرحلة أو تقوم بجلب العقود المرتبطة بـ id الرحلة.
                // في هذه المرحلة، سننتقل إلى CalacterPage (حاسبة الأسعار) أولاً
                // لكي يتم تحديد الأسعار اللازمة لإنشاء العقد.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalacterPage(),
                  ), // الانتقال إلى حاسبة الأسعار أولاً
                );
              },
              icon: const Icon(Icons.description, color: Colors.white),
              label: const Text(
                'إدارة العقود',
                style: TextStyle(fontSize: 18, color: Colors.white),
                textDirection: TextDirection.rtl,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
            ),
            const SizedBox(height: 20),

            // زر لعرض/إدارة برامج العمرة لهذه الرحلة (يمكن إضافة صفحة جديدة لاحقاً)
            ElevatedButton.icon(
              onPressed: () {
                // TODO: هنا يمكن الانتقال لصفحة لإدارة برامج العمرة لهذه الرحلة
                // قد تحتاج لجدول 'programs' في Supabase وربطه بـ 'trips'
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'وظيفة إدارة برامج العمرة قيد التطوير!',
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.card_travel, color: Colors.white),
              label: const Text(
                'إدارة برامج العمرة',
                style: TextStyle(fontSize: 18, color: Colors.white),
                textDirection: TextDirection.rtl,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
