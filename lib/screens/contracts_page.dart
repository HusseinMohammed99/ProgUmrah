import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لاستخدام FilteringTextInputFormatter و rootBundle
import 'package:pdf/widgets.dart' as pw; // فقط لاستخدام pw.Font هنا

// استيراد ملف دالة إنشاء الـ PDF
import 'package:umrah/utils/pdf_contract_generator.dart'; // تأكد من المسار الصحيح

class ContractPage extends StatefulWidget {
  // المعاملات لاستقبال الأسعار من صفحة CalacterPage
  final double pricePerPersonQuad;
  final double pricePerPersonTriple;
  final double pricePerPersonDouble;

  const ContractPage({
    super.key,
    required this.pricePerPersonQuad,
    required this.pricePerPersonTriple,
    required this.pricePerPersonDouble,
  });

  @override
  State<ContractPage> createState() => _ContractPageState();
}

class _ContractPageState extends State<ContractPage> {
  // المتحكمات (Controllers) لتفاصيل العقد
  final TextEditingController agentNameController = TextEditingController();
  final TextEditingController contractNumberController =
      TextEditingController();
  final TextEditingController totalPilgrimsController = TextEditingController();
  final TextEditingController contractTermsController = TextEditingController();

  // متحكمات أعداد الغرف للمدينة
  final TextEditingController madinahDoubleRoomsController =
      TextEditingController();
  final TextEditingController madinahTripleRoomsController =
      TextEditingController();
  int madinahQuadRoomsCalculated = 0; // لتخزين عدد الغرف الرباعية المحسوب

  // متحكمات أعداد الغرف لمكة
  final TextEditingController makkahDoubleRoomsController =
      TextEditingController();
  final TextEditingController makkahTripleRoomsController =
      TextEditingController();
  int makkahQuadRoomsCalculated = 0; // لتخزين عدد الغرف الرباعية المحسوب

  // متغيرات نتائج العقد
  String warningMessage =
      ""; // للتحذيرات حول الأسرة الشاغرة أو المعتمرين غير المخصصين

  // متغيرات جديدة لإجمالي عدد الغرف
  int totalMadinahRooms = 0;
  int totalMakkahRooms = 0;

  // متغير لاسم موظف العمرة/المدير المفوض الذي سيوقع
  String? selectedSignatory;

  // متغيرات لتخزين التكاليف الإجمالية لاستخدامها في بناء الـ PDF والعرض
  double currentTotalMadinahCost = 0.0;
  double currentTotalMakkahCost = 0.0;
  double currentOverallContractTotal = 0.0;

  // لتحميل الخط العربي مرة واحدة
  late Future<pw.Font> _arabicFontFuture;

  @override
  void initState() {
    super.initState();
    _arabicFontFuture = _loadArabicFont();
  }

  Future<pw.Font> _loadArabicFont() async {
    // استخدم خط يدعم اللغة العربية. Noto Sans Arabic هو خيار جيد.
    // تأكد من إضافة google_fonts في pubspec.yaml وتنزيل الخط.
    try {
      final fontData = await rootBundle.load(
        "assets/fonts/NotoSansArabic-Regular.ttf",
      ); // تأكد من المسار الصحيح للخط
      return pw.Font.ttf(fontData);
    } catch (e) {
      // طباعة الخطأ فقط للتصحيح، لا تستخدم print في كود الإنتاج
      print("Error loading NotoSansArabic-Regular.ttf: $e");
      // Fallback to a default font if custom font fails
      return pw.Font.helvetica();
    }
  }

  @override
  void dispose() {
    // يجب التخلص من جميع المتحكمات لتجنب تسرب الذاكرة
    agentNameController.dispose();
    contractNumberController.dispose();
    totalPilgrimsController.dispose();
    contractTermsController.dispose();
    madinahDoubleRoomsController.dispose();
    madinahTripleRoomsController.dispose();
    makkahDoubleRoomsController.dispose();
    makkahTripleRoomsController.dispose();
    super.dispose();
  }

  // دالة لحساب التكلفة الإجمالية للعقد وتوزيع المعتمرين
  void calculateContract() {
    setState(() {
      warningMessage = ""; // مسح التحذيرات السابقة
      totalMadinahRooms = 0; // إعادة تعيين إجمالي الغرف
      totalMakkahRooms = 0; // إعادة تعيين إجمالي الغرف
    });

    int totalPilgrims = int.tryParse(totalPilgrimsController.text) ?? 0;
    if (totalPilgrims <= 0) {
      setState(() {
        warningMessage = "الرجاء إدخال العدد الإجمالي للمعتمرين أولاً.";
      });
      return;
    }

    // --- تخصيص غرف المدينة ---
    int madinahDoubleRooms =
        int.tryParse(madinahDoubleRoomsController.text) ?? 0;
    int madinahTripleRooms =
        int.tryParse(madinahTripleRoomsController.text) ?? 0;

    int pilgrimsInMadinahDoubleRooms = madinahDoubleRooms * 2;
    int pilgrimsInMadinahTripleRooms = madinahTripleRooms * 3;

    int pilgrimsAllocatedMadinah =
        pilgrimsInMadinahDoubleRooms + pilgrimsInMadinahTripleRooms;
    int remainingPilgrimsForMadinahQuad =
        totalPilgrims - pilgrimsAllocatedMadinah;

    if (remainingPilgrimsForMadinahQuad < 0) {
      setState(() {
        warningMessage +=
            "تنبيه (المدينة): عدد المعتمرين في الثنائي والثلاثي تجاوز العدد الإجمالي للمعتمرين.\n";
        madinahQuadRoomsCalculated =
            0; // لا توجد حاجة لغرف رباعية إذا كان العدد مفرطًا
        remainingPilgrimsForMadinahQuad = 0; // ضبط لحساب دقيق لاحقًا
      });
    } else {
      // حساب الغرف الرباعية اللازمة وأي معتمرين "فرديين" متبقين
      madinahQuadRoomsCalculated = (remainingPilgrimsForMadinahQuad / 4).ceil();
      int madinahTotalCapacity =
          (madinahQuadRoomsCalculated * 4) + pilgrimsAllocatedMadinah;
      int madinahEmptyBeds = madinahTotalCapacity - totalPilgrims;

      if (madinahEmptyBeds > 0) {
        warningMessage +=
            "تنبيه (المدينة): يوجد $madinahEmptyBeds سرير/أسرة شاغرة.\n";
      } else if (madinahEmptyBeds < 0) {
        warningMessage +=
            "تنبيه (المدينة): يوجد ${madinahEmptyBeds.abs()} معتمر/معتمرين لم يتم تخصيصهم.\n";
      }
    }
    // حساب إجمالي غرف المدينة
    totalMadinahRooms =
        madinahDoubleRooms + madinahTripleRooms + madinahQuadRoomsCalculated;

    // --- تخصيص غرف مكة ---
    int makkahDoubleRooms = int.tryParse(makkahDoubleRoomsController.text) ?? 0;
    int makkahTripleRooms = int.tryParse(makkahTripleRoomsController.text) ?? 0;

    int pilgrimsInMakkahDoubleRooms = makkahDoubleRooms * 2;
    int pilgrimsInMakkahTripleRooms = makkahTripleRooms * 3;

    int pilgrimsAllocatedMakkah =
        pilgrimsInMakkahDoubleRooms + pilgrimsInMakkahTripleRooms;
    int remainingPilgrimsForMakkahQuad =
        totalPilgrims - pilgrimsAllocatedMakkah;

    if (remainingPilgrimsForMakkahQuad < 0) {
      setState(() {
        warningMessage +=
            "تنبيه (مكة): عدد المعتمرين في الثنائي والثلاثي تجاوز العدد الإجمالي للمعتمرين.\n";
        makkahQuadRoomsCalculated = 0; // لا توجد حاجة لغرف رباعية
        remainingPilgrimsForMakkahQuad = 0; // ضبط لحساب دقيق لاحقًا
      });
    } else {
      // حساب الغرف الرباعية اللازمة وأي معتمرين "فرديين" متبقين
      makkahQuadRoomsCalculated = (remainingPilgrimsForMakkahQuad / 4).ceil();
      int makkahTotalCapacity =
          (makkahQuadRoomsCalculated * 4) + pilgrimsAllocatedMakkah;
      int makkahEmptyBeds = makkahTotalCapacity - totalPilgrims;

      if (makkahEmptyBeds > 0) {
        warningMessage +=
            "تنبيه (مكة): يوجد $makkahEmptyBeds سرير/أسرة شاغرة.\n";
      } else if (makkahEmptyBeds < 0) {
        warningMessage +=
            "تنبيه (مكة): يوجد ${makkahEmptyBeds.abs()} معتمر/معتمرين لم يتم تخصيصهم.\n";
      }
    }
    // حساب إجمالي غرف مكة
    totalMakkahRooms =
        makkahDoubleRooms + makkahTripleRooms + makkahQuadRoomsCalculated;

    // --- حساب التكاليف الإجمالية ---
    // التكلفة الإجمالية لغرف المدينة بناءً على التخصيص الفعلي
    currentTotalMadinahCost =
        (madinahQuadRoomsCalculated * widget.pricePerPersonQuad * 4) +
        (madinahTripleRooms * widget.pricePerPersonTriple * 3) +
        (madinahDoubleRooms * widget.pricePerPersonDouble * 2);

    // التكلفة الإجمالية لغرف مكة بناءً على التخصيص الفعلي
    currentTotalMakkahCost =
        (makkahQuadRoomsCalculated * widget.pricePerPersonQuad * 4) +
        (makkahTripleRooms * widget.pricePerPersonTriple * 3) +
        (makkahDoubleRooms * widget.pricePerPersonDouble * 2);

    // إجمالي قيمة العقد الكلي
    currentOverallContractTotal =
        currentTotalMadinahCost + currentTotalMakkahCost;
  }

  @override
  Widget build(BuildContext context) {
    // Parse the values directly here to pass them to _buildContractImageFormat
    // These will reflect the last calculated state or initial empty state
    final int currentMadinahDoubleRooms =
        int.tryParse(madinahDoubleRoomsController.text) ?? 0;
    final int currentMadinahTripleRooms =
        int.tryParse(madinahTripleRoomsController.text) ?? 0;
    final int currentMakkahDoubleRooms =
        int.tryParse(makkahDoubleRoomsController.text) ?? 0;
    final int currentMakkahTripleRooms =
        int.tryParse(makkahTripleRoomsController.text) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("إنشاء العقد", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // قسم بيانات الوكيل والعقد
            _buildSectionHeader("بيانات الوكيل والعقد"),
            _buildCustomTextField(
              agentNameController,
              "اسم الوكيل",
              "مثال: وكيل السعادة",
              TextInputType.text,
            ),
            const SizedBox(height: 15),
            _buildCustomTextField(
              contractNumberController,
              "رقم العقد",
              "مثال: UMRAH-2025-001",
              TextInputType.text,
            ),
            const SizedBox(height: 30),

            // مدخل العدد الإجمالي للمعتمرين
            _buildSectionHeader("العدد الإجمالي للمعتمرين"),
            _buildCustomTextField(
              totalPilgrimsController,
              "العدد الإجمالي للمعتمرين",
              "مثال: 45",
              TextInputType.number,
            ),
            const SizedBox(height: 30),

            // أعداد غرف المدينة
            _buildSectionHeader("توزيع الغرف في المدينة"),
            _buildCustomTextField(
              madinahDoubleRoomsController,
              "عدد الغرف الثنائية",
              "مثال: 2",
              TextInputType.number,
            ),
            const SizedBox(height: 15),
            _buildCustomTextField(
              madinahTripleRoomsController,
              "عدد الغرف الثلاثية",
              "مثال: 3",
              TextInputType.number,
            ),
            const SizedBox(height: 15),
            _buildCalculatedRoomDisplay(
              "الغرف الرباعية (المدينة)",
              madinahQuadRoomsCalculated,
            ),
            const SizedBox(height: 30),

            // أعداد غرف مكة
            _buildSectionHeader("توزيع الغرف في مكة"),
            _buildCustomTextField(
              makkahDoubleRoomsController,
              "عدد الغرف الثنائية",
              "مثال: 3",
              TextInputType.number,
            ),
            const SizedBox(height: 15),
            _buildCustomTextField(
              makkahTripleRoomsController,
              "عدد الغرف الثلاثية",
              "مثال: 4",
              TextInputType.number,
            ),
            const SizedBox(height: 15),
            _buildCalculatedRoomDisplay(
              "الغرف الرباعية (مكة)",
              makkahQuadRoomsCalculated,
            ),
            const SizedBox(height: 30),

            // مدخل شروط العقد
            _buildSectionHeader("الشروط والتفاصيل الإضافية"),
            _buildCustomTextField(
              contractTermsController,
              "الشروط والتفاصيل",
              "أدخل هنا أي شروط أو تفاصيل إضافية للعقد",
              TextInputType.multiline,
              maxLines: 5, // السماح بعدة أسطر للشروط
            ),
            const SizedBox(height: 30),

            // Signatory Selection (اختيار الموقع)
            _buildSectionHeader("الموقع"),
            DropdownButtonFormField<String>(
              value: selectedSignatory,
              hint: const Text("اختر موظف العمرة/المدير المفوض"),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.blue.shade200,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.deepPurple.shade300,
                    width: 2,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(value: "محمود", child: Text("محمود")),
                DropdownMenuItem(value: "حسين", child: Text("حسين")),
                DropdownMenuItem(value: "علي", child: Text("علي")),
                DropdownMenuItem(
                  value: "المدير المفوض",
                  child: Text("المدير المفوض"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedSignatory = value;
                });
              },
            ),
            const SizedBox(height: 30),

            // زر حساب العقد
            ElevatedButton(
              onPressed: calculateContract,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade400,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: const Text(
                "حساب العقد وتوزيع الغرف",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // زر طباعة PDF (جديد)
            ElevatedButton(
              onPressed: () => generatePdfContract(
                // استدعاء الدالة من الملف المنفصل
                agentName: agentNameController.text,
                contractNumber: contractNumberController.text,
                totalPilgrims: int.tryParse(totalPilgrimsController.text) ?? 0,
                madinahDouble: currentMadinahDoubleRooms,
                madinahTriple: currentMadinahTripleRooms,
                madinahQuad: madinahQuadRoomsCalculated,
                makkahDouble: currentMakkahDoubleRooms,
                makkahTriple: currentMakkahTripleRooms,
                makkahQuad: makkahQuadRoomsCalculated,
                totalMadinahRooms: totalMadinahRooms,
                totalMakkahRooms: totalMakkahRooms,
                contractTerms: contractTermsController.text,
                totalMadinahCost: currentTotalMadinahCost,
                totalMakkahCost: currentTotalMakkahCost,
                overallContractTotal: currentOverallContractTotal,
                agentSignatory: agentNameController.text,
                companySignatory: selectedSignatory ?? "غير محدد",
                arabicFontFuture: _arabicFontFuture, // تمرير future الخط
                context: context, // تمرير الـ context لـ ScaffoldMessenger
                pricePerPersonDouble:
                    widget.pricePerPersonDouble, // تمرير أسعار الغرف
                pricePerPersonTriple: widget.pricePerPersonTriple,
                pricePerPersonQuad: widget.pricePerPersonQuad,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade400, // لون مختلف لزر الطباعة
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: const Text(
                "طباعة العقد بصيغة PDF",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // عرض رسالة التحذير (إن وجدت)
            if (warningMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Text(
                  warningMessage,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // --- عرض العقد بصيغة الصورة مع النصوص المتراكبة (للعرض على الشاشة) ---
            if (totalPilgrimsController.text.isNotEmpty &&
                int.tryParse(totalPilgrimsController.text)! > 0)
              _buildContractImageFormat(
                agentName: agentNameController.text,
                contractNumber: contractNumberController.text,
                totalPilgrims: int.tryParse(totalPilgrimsController.text) ?? 0,
                madinahDouble: currentMadinahDoubleRooms,
                madinahTriple: currentMadinahTripleRooms,
                madinahQuad: madinahQuadRoomsCalculated,
                makkahDouble: currentMakkahDoubleRooms,
                makkahTriple: currentMakkahTripleRooms,
                makkahQuad: makkahQuadRoomsCalculated,
                totalMadinahRooms: totalMadinahRooms,
                totalMakkahRooms: totalMakkahRooms,
                contractTerms: contractTermsController.text,
                totalMadinahCost: currentTotalMadinahCost,
                totalMakkahCost: currentTotalMakkahCost,
                overallContractTotal: currentOverallContractTotal,
                agentSignatory: agentNameController.text,
                companySignatory: selectedSignatory ?? "غير محدد",
                pricePerPersonDouble:
                    widget.pricePerPersonDouble, // سعر الشخص في الغرفة الثنائية
                pricePerPersonTriple:
                    widget.pricePerPersonTriple, // سعر الشخص في الغرفة الثلاثية
                pricePerPersonQuad:
                    widget.pricePerPersonQuad, // سعر الشخص في الغرفة الرباعية
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لإنشاء حقول إدخال نصية مخصصة
  Widget _buildCustomTextField(
    TextEditingController controller,
    String labelText,
    String hintText,
    TextInputType keyboardType, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      textDirection: TextDirection.rtl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: <TextInputFormatter>[
        if (keyboardType == TextInputType.number)
          FilteringTextInputFormatter.digitsOnly,
      ],
      style: TextStyle(fontSize: 18, color: Colors.blueGrey.shade900),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(fontSize: 16, color: Colors.blueGrey.shade600),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14),
        hintTextDirection: TextDirection.rtl,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
      ),
    );
  }

  // دالة مساعدة لعرض أعداد الغرف المحسوبة
  Widget _buildCalculatedRoomDisplay(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 18, color: Colors.blueGrey.shade600),
          ),
          Text(
            count.toString(),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لإنشاء عناوين الأقسام
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Text(
        title,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey.shade700,
        ),
      ),
    );
  }

  // --- دالة لبناء العقد داخل صيغة الصورة للعرض على الشاشة ---
  Widget _buildContractImageFormat({
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
    required double pricePerPersonDouble, // إضافة سعر الغرفة الثنائية
    required double pricePerPersonTriple, // إضافة سعر الغرفة الثلاثية
    required double pricePerPersonQuad, // إضافة سعر الغرفة الرباعية
  }) {
    const double imageHeight = 800; // ارتفاع مثال لعرض الصورة
    const double imageWidth = 600; // عرض مثال

    return Center(
      child: Container(
        width: imageWidth,
        height: imageHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(
                25,
              ), // استخدام withAlpha لتجنب deprecated
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // صورة الخلفية (قالب العقد الخاص بك)
            Positioned.fill(
              child: Image.asset(
                'assets/images/Form.jpg', // تأكد من وجود الصورة بهذا المسار في assets/images وتحديث pubspec.yaml
                fit: BoxFit.fill, // ملء الحاوية
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      'خطأ في تحميل الصورة: تأكد من إضافة Form.jpg في assets/images وتحديث pubspec.yaml',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  );
                },
              ),
            ),

            // رقم العقد (في الصورة هو في الزاوية العلوية اليمنى)
            Positioned(
              top: 155, // تم التعديل ليتوافق مع الصورة الجديدة
              right: 5, // تم التعديل
              child: SizedBox(
                width: 150,
                child: Text(
                  "رقم العقد: $contractNumber",
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // تاريخ العقد (إضافة تاريخ اليوم)
            Positioned(
              top: 180, // تقريبي، بالقرب من رقم العقد
              right: 10,
              child: Text(
                // يمكنك تنسيق التاريخ حسب الحاجة
                'التاريخ: ${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),

            // اسم الوكيل (الطرف الأول في العقد)
            Positioned(
              top: 205, // تم التعديل
              right: 10, // تم التعديل
              child: SizedBox(
                width: 250,
                child: Text(
                  "اسم الوكيل: $agentName",
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // العدد الإجمالي للمعتمرين وعدد الليالي (هذا الجزء نص مدمج في الصورة القديمة، لكننا سنضع قيمنا)
            Positioned(
              top: 230, // موضع تقريبي
              right: 10, // موضع تقريبي
              child: SizedBox(
                width: 600,
                child: Text(
                  // حساب عدد الليالي بناءً على عدد الغرف وتكلفة الشخص
                  // هذا تبسيط وقد لا يعكس بدقة عدد الليالي الفعلي للحزمة
                  'تم الاتفاق بين شركة المدينة المنورة العالمية الفوض لابرام القود السيد : $companySignatory , والسيد : $agentName على تنظيم برنامج عمرة لعدد ${totalPilgrims} معتمرين.', // تحديث النص ليعكس المتغيرات بشكل أفضل
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // شروط العقد (موضع افتراضي - قم بضبطه)
            Positioned(
              top: 590, // تم التعديل ليتناسب مع الصورة
              right: 80, // تم التعديل
              left: 80, // تم التعديل
              child: Text(
                contractTerms.isNotEmpty
                    ? contractTerms
                    : "لا يوجد شروط إضافية.",
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 12),
                maxLines: 5, // تقليل عدد الأسطر لتناسب المساحة
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // --- جدول التفاصيل (تخطيط مخصص) ---
            // بناء جدول يدويا باستخدام Column و Row لوضعه بدقة
            Positioned(
              top: 300, // تم التعديل ليتوافق مع بداية الجدول في الصورة
              right: 50, // تم التعديل
              left: 75, // تم التعديل
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // رأس الجدول
                  _buildContractTableRow(
                    "التفاصيل",
                    "المدينة",
                    "مكة",
                    "السعر/شخص",
                    "الإجمالي",
                    isHeader: true,
                  ),
                  const Divider(height: 5, thickness: 1, color: Colors.black54),

                  // صفوف بيانات المدينة
                  _buildContractTableRow(
                    "غرف ثنائية",
                    madinahDouble.toString(),
                    "",
                    pricePerPersonDouble.toStringAsFixed(0),
                    (madinahDouble * pricePerPersonDouble * 2).toStringAsFixed(
                      0,
                    ),
                  ),
                  _buildContractTableRow(
                    "غرف ثلاثية",
                    madinahTriple.toString(),
                    "",
                    pricePerPersonTriple.toStringAsFixed(0),
                    (madinahTriple * pricePerPersonTriple * 3).toStringAsFixed(
                      0,
                    ),
                  ),
                  _buildContractTableRow(
                    "غرف رباعية",
                    madinahQuad.toString(),
                    "",
                    pricePerPersonQuad.toStringAsFixed(0),
                    (madinahQuad * pricePerPersonQuad * 4).toStringAsFixed(0),
                  ),
                  _buildContractTableRow(
                    "إجمالي غرف المدينة",
                    totalMadinahRooms.toString(),
                    "",
                    "",
                    totalMadinahCost.toStringAsFixed(0),
                    isBold: true,
                  ),

                  const Divider(
                    height: 5,
                    thickness: 0.5,
                    color: Colors.black38,
                  ),

                  // صفوف بيانات مكة
                  _buildContractTableRow(
                    "غرف ثنائية",
                    "",
                    makkahDouble.toString(),
                    pricePerPersonDouble.toStringAsFixed(0),
                    (makkahDouble * pricePerPersonDouble * 2).toStringAsFixed(
                      0,
                    ),
                  ),
                  _buildContractTableRow(
                    "غرف ثلاثية",
                    "",
                    makkahTriple.toString(),
                    pricePerPersonTriple.toStringAsFixed(0),
                    (makkahTriple * pricePerPersonTriple * 3).toStringAsFixed(
                      0,
                    ),
                  ),
                  _buildContractTableRow(
                    "رباعي",
                    "",
                    makkahQuad.toString(),
                    pricePerPersonQuad.toStringAsFixed(0),
                    (makkahQuad * pricePerPersonQuad * 4).toStringAsFixed(0),
                  ),
                  _buildContractTableRow(
                    "إجمالي غرف مكة",
                    "",
                    totalMakkahRooms.toString(),
                    "",
                    totalMakkahCost.toStringAsFixed(0),
                    isBold: true,
                  ),

                  const Divider(height: 5, thickness: 1, color: Colors.black54),

                  // صف الإجمالي الكلي
                  _buildContractTableRow(
                    "الإجمالي الكلي للعقد",
                    "",
                    "",
                    "",
                    overallContractTotal.toStringAsFixed(0),
                    isBold: true,
                    isTotalRow: true,
                  ),
                ],
              ),
            ),

            // قسم التوقيعات (موضع افتراضي - قم بضبطه)
            // توقيع الوكيل
            Positioned(
              bottom: 120, // تم التعديل
              right: 100, // تم التعديل
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "توقيع الوكيل:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "____________________", // خط التوقيع
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Text(
                    agentSignatory.isNotEmpty ? agentSignatory : "غير محدد",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // توقيع موظف الشركة
            Positioned(
              bottom: 120, // تم التعديل
              left: 100, // تم التعديل
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "توقيع موظف الشركة:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "____________________", // خط التوقيع
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Text(
                    companySignatory,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لبناء صف واحد في الجدول المخصص للعرض على الشاشة
  // تم تعديلها لاستيعاب تنسيق الجدول الجديد
  Widget _buildContractTableRow(
    String detail,
    String madinahCount,
    String makkahCount,
    String pricePerPerson,
    String totalCost, {
    bool isHeader = false,
    bool isBold = false,
    bool isTotalRow = false,
  }) {
    TextStyle textStyle = TextStyle(
      fontSize: isHeader ? 13 : 12,
      fontWeight: (isHeader || isBold) ? FontWeight.bold : FontWeight.normal,
      color: Colors.black87,
    );

    // محاذاة النص داخل الخلايا
    TextAlign cellAlign = TextAlign.center;
    if (isHeader) cellAlign = TextAlign.center;
    if (isTotalRow) cellAlign = TextAlign.right; // Total row alignment

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            // التفاصيل
            flex: 3,
            child: Text(
              detail,
              textDirection: TextDirection.rtl,
              style: textStyle,
              textAlign: isTotalRow
                  ? TextAlign.right
                  : TextAlign.right, // Specific alignment for detail cell
            ),
          ),
          Expanded(
            // المدينة
            flex: 1,
            child: Text(
              madinahCount,
              textDirection: TextDirection.ltr,
              style: textStyle,
              textAlign: cellAlign,
            ),
          ),
          Expanded(
            // مكة
            flex: 1,
            child: Text(
              makkahCount,
              textDirection: TextDirection.ltr,
              style: textStyle,
              textAlign: cellAlign,
            ),
          ),
          Expanded(
            // السعر/شخص (إذا لم يكن صف إجمالي)
            flex: 2,
            child: Text(
              pricePerPerson,
              textDirection: TextDirection.ltr,
              style: textStyle,
              textAlign: cellAlign,
            ),
          ),
          Expanded(
            // الإجمالي
            flex: 2,
            child: Text(
              totalCost.isNotEmpty ? "$totalCost\$" : "",
              textDirection: TextDirection.ltr,
              style: textStyle,
              textAlign: cellAlign,
            ),
          ),
        ],
      ),
    );
  }
}
