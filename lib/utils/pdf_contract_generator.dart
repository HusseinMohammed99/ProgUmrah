import 'package:flutter/material.dart'; // تم إضافة هذا الاستيراد لحل مشاكل BuildContext و ScaffoldMessenger و SnackBar و Text
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';

// تم إزالة دالة _buildPdfTableRowContent لأنها لم تكن مستخدمة مباشرة في بناء الجدول عبر TableHelper.fromTextArray

// دالة لإنشاء مستند PDF من بيانات العقد
Future<void> generatePdfContract({
  required String agentName,
  required String contractNumber,
  required int totalPilgrims,
  required int madinahDouble,
  required int madinahTriple,
  required int madinahQuad,
  required int makkahDouble,
  required int makkahTriple,
  required int makkahQuad,
  required int totalMadinahRooms,
  required int totalMakkahRooms,
  required String contractTerms,
  required double totalMadinahCost,
  required double totalMakkahCost,
  required double overallContractTotal,
  required String agentSignatory,
  required String companySignatory,
  required Future<pw.Font> arabicFontFuture, // استقبال future الخط
  required BuildContext context, // لاستخدام ScaffoldMessenger
  required double pricePerPersonDouble, // لإعادة حساب الليالي
  required double pricePerPersonTriple, // لإعادة حساب الليالي
  required double pricePerPersonQuad,
  required String madinahHotelName,
  required String makkahHotelName, // لإعادة حساب الليالي
}) async {
  final pdf = pw.Document();
  final pw.Font arabicFont = await arabicFontFuture; // تحميل الخط العربي

  // تحميل صورة الخلفية
  final ByteData bytes = await rootBundle.load('images/Form.jpg');
  final Uint8List byteList = bytes.buffer.asUint8List();
  final pw.MemoryImage contractImage = pw.MemoryImage(byteList);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context contextPdf) {
        // حساب عدد الليالي الإجمالي بشكل أكثر دقة
        double totalCapacityMadinah =
            (madinahDouble * 2) + (madinahTriple * 3) + (madinahQuad * 4);
        double totalCapacityMakkah =
            (makkahDouble * 2) + (makkahTriple * 3) + (makkahQuad * 4);
        double totalNights = (totalPilgrims > 0)
            ? (totalCapacityMadinah + totalCapacityMakkah) /
                  (2.0 * totalPilgrims)
            : 0.0; // تجنب القسمة على صفر
        // هذا التقدير لعدد الليالي يعتمد على أن السعر للشخص الواحد لليلة الواحدة ثابت، وهو تبسيط
        // يجب أن يتم حساب الليالي بناءً على تفاصيل حزمة العمرة (عدد الليالي في المدينة وعدد الليالي في مكة)

        return pw.Stack(
          children: [
            // صورة الخلفية كأول عنصر في الـ Stack
            pw.Image(contractImage, fit: pw.BoxFit.fill),

            // رقم العقد
            pw.Positioned(
              top: 70,
              right: 90,
              child: pw.SizedBox(
                width: 150,
                child: pw.Text(
                  contractNumber.isNotEmpty ? contractNumber : "غير محدد",
                  textDirection: pw.TextDirection.ltr,
                  style: pw.TextStyle(
                    fontSize: 10,
                    font: arabicFont,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),

            // اسم الوكيل (الطرف الأول في العقد)
            pw.Positioned(
              top: 100,
              right: 120,
              child: pw.SizedBox(
                width: 200,
                child: pw.Text(
                  agentName.isNotEmpty ? agentName : "غير محدد",
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                    fontSize: 10,
                    font: arabicFont,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),

            // تفاصيل عدد الليالي والمعتمرين
            pw.Positioned(
              top: 130,
              right: 120,
              child: pw.SizedBox(
                width: 300,
                child: pw.Text(
                  // تبسيط حساب الليالي ليتناسب مع البيانات المتاحة.
                  // يفضل أن يكون عدد الليالي مدخلًا مباشرًا إذا كان مهمًا
                  'إجمالي ${totalNights.toStringAsFixed(0)} ليلة، وعدد المعتمرين $totalPilgrims',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(fontSize: 10, font: arabicFont),
                  maxLines: 2,
                ),
              ),
            ),

            // --- جدول التفاصيل في PDF (باستخدام TableHelper) ---
            pw.Positioned(
              top:
                  250, // اضبط هذا ليتوافق مع بداية منطقة الجدول في قالب الـ PDF
              right: 70, // هام لضبط عرض الجدول
              left: 70, // هام لضبط عرض الجدول
              child: pw.TableHelper.fromTextArray(
                // استخدام TableHelper.fromTextArray()
                cellAlignments: {
                  0: pw.Alignment.centerRight, // التفاصيل RTL
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                },
                columnWidths: {
                  // ضبط عرض الأعمدة
                  0: const pw.FlexColumnWidth(3), // التفاصيل
                  1: const pw.FlexColumnWidth(1.5), // المدينة
                  2: const pw.FlexColumnWidth(1.5), // مكة
                  3: const pw.FlexColumnWidth(2), // السعر/شخص
                  4: const pw.FlexColumnWidth(2), // الإجمالي
                },
                cellStyle: pw.TextStyle(fontSize: 9, font: arabicFont),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  font: arabicFont,
                ),
                headers: [
                  'التفاصيل',
                  'المدينة',
                  'مكة',
                  'السعر/شخص',
                  'الإجمالي',
                ],
                data: [
                  ['العدد الإجمالي للمعتمرين', '$totalPilgrims', '', '', ''],
                  ['غرف المدينة:', '', '', '', ''],
                  [
                    'ثنائي',
                    madinahDouble.toString(),
                    '',
                    pricePerPersonDouble.toStringAsFixed(0),
                    (madinahDouble * pricePerPersonDouble * 2).toStringAsFixed(
                      0,
                    ),
                  ],
                  [
                    'ثلاثي',
                    madinahTriple.toString(),
                    '',
                    pricePerPersonTriple.toStringAsFixed(0),
                    (madinahTriple * pricePerPersonTriple * 3).toStringAsFixed(
                      0,
                    ),
                  ],
                  [
                    'رباعي',
                    madinahQuad.toString(),
                    '',
                    pricePerPersonQuad.toStringAsFixed(0),
                    (madinahQuad * pricePerPersonQuad * 4).toStringAsFixed(0),
                  ],
                  [
                    'إجمالي غرف المدينة',
                    totalMadinahRooms.toString(),
                    '',
                    '',
                    totalMadinahCost.toStringAsFixed(0),
                  ],
                  ['غرف مكة:', '', '', '', ''],
                  [
                    'ثنائي',
                    '',
                    makkahDouble.toString(),
                    pricePerPersonDouble.toStringAsFixed(0),
                    (makkahDouble * pricePerPersonDouble * 2).toStringAsFixed(
                      0,
                    ),
                  ],
                  [
                    'ثلاثي',
                    '',
                    makkahTriple.toString(),
                    pricePerPersonTriple.toStringAsFixed(0),
                    (makkahTriple * pricePerPersonTriple * 3).toStringAsFixed(
                      0,
                    ),
                  ],
                  [
                    'رباعي',
                    '',
                    makkahQuad.toString(),
                    pricePerPersonQuad.toStringAsFixed(0),
                    (makkahQuad * pricePerPersonQuad * 4).toStringAsFixed(0),
                  ],
                  [
                    'إجمالي غرف مكة',
                    '',
                    totalMakkahRooms.toString(),
                    '',
                    totalMakkahCost.toStringAsFixed(0),
                  ],
                  [
                    'الإجمالي الكلي للعقد',
                    '',
                    '',
                    '',
                    overallContractTotal.toStringAsFixed(0),
                  ],
                ],
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellPadding: const pw.EdgeInsets.all(3),
              ),
            ),

            // شروط العقد
            pw.Positioned(
              top: 550, // اضبط هذا ليتناسب مع قسم الشروط في قالب الـ PDF
              right: 50,
              left: 50,
              child: pw.Text(
                contractTerms.isNotEmpty
                    ? contractTerms
                    : "لا توجد شروط إضافية.",
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
            ),

            // قسم التوقيعات
            // توقيع الوكيل
            pw.Positioned(
              bottom: 50, // اضبط هذا
              right: 80, // اضبط هذا
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "توقيع الوكيل:",
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      font: arabicFont,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    "____________________", // خط التوقيع
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      font: arabicFont,
                    ),
                  ),
                  pw.Text(
                    agentSignatory.isNotEmpty ? agentSignatory : "غير محدد",
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      font: arabicFont,
                    ),
                  ),
                ],
              ),
            ),

            // توقيع موظف الشركة
            pw.Positioned(
              bottom: 50, // اضبط هذا
              left: 80, // اضبط هذا
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "توقيع موظف الشركة:",
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      font: arabicFont,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    "____________________", // خط التوقيع
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      font: arabicFont,
                    ),
                  ),
                  pw.Text(
                    companySignatory,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      font: arabicFont,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // --- حفظ وفتح ملف الـ PDF ---
  try {
    final String dir = (await getApplicationDocumentsDirectory()).path;
    final String path =
        '$dir/umrah_contract_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File file = File(path);
    await file.writeAsBytes(await pdf.save());
    if (context.mounted) {
      // Guard against using context after widget disposed
      OpenFilex.open(path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء ملف PDF بنجاح في: $path')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      // Guard against using context after widget disposed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إنشاء أو حفظ ملف PDF: $e')),
      );
    }
  }
}
