import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لاستخدام FilteringTextInputFormatter و rootBundle
import 'package:pdf/pdf.dart'; // لاستخدام مكتبة PDF
import 'package:pdf/widgets.dart' as pw; // اختصار pw لـ widgets الخاصة بالـ PDF
import 'package:path_provider/path_provider.dart'; // لحفظ الملفات على الجهاز
import 'dart:io'; // للتعامل مع الملفات
import 'package:open_filex/open_filex.dart'; // لفتح الملفات
import 'package:google_fonts/google_fonts.dart'; // لاستخدام خطوط جوجل في PDF (لتحسين دعم العربية)
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد Supabase

class ContractPage extends StatefulWidget {
  // المعاملات لاستقبال الأسعار من صفحة CalacterPage (للعقود الجديدة)
  final double pricePerPersonQuad;
  final double pricePerPersonTriple;
  final double pricePerPersonDouble;
  final Map<String, dynamic> tripData; // بيانات الرحلة لربط العقد بها
  final Map<String, dynamic>?
  existingContractData; // بيانات العقد الحالي للتعديل

  const ContractPage({
    super.key,
    required this.pricePerPersonQuad,
    required this.pricePerPersonTriple,
    required this.pricePerPersonDouble, // تم التصحيح هنا
    required this.tripData,
    this.existingContractData, // يمكن أن يكون null عند إضافة عقد جديد
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

  // NEW: متحكمات أسعار البرنامج القابلة للتحرير
  final TextEditingController pricePerPersonQuadController =
      TextEditingController();
  final TextEditingController pricePerPersonTripleController =
      TextEditingController();
  final TextEditingController pricePerPersonDoubleController =
      TextEditingController();

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

    // تهيئة المتحكمات ببيانات العقد الموجودة أو القيم الافتراضية
    if (widget.existingContractData != null) {
      // تعديل عقد موجود: قم بملء الحقول ببيانات العقد الموجودة
      agentNameController.text =
          widget.existingContractData!['agent_name']?.toString() ?? '';
      contractNumberController.text =
          widget.existingContractData!['contract_number']?.toString() ?? '';
      totalPilgrimsController.text =
          widget.existingContractData!['total_pilgrims']?.toString() ?? '';
      contractTermsController.text =
          widget.existingContractData!['contract_terms']?.toString() ?? '';
      madinahDoubleRoomsController.text =
          widget.existingContractData!['madinah_double_rooms']?.toString() ??
          '';
      madinahTripleRoomsController.text =
          widget.existingContractData!['madinah_triple_rooms']?.toString() ??
          '';
      makkahDoubleRoomsController.text =
          widget.existingContractData!['makkah_double_rooms']?.toString() ?? '';
      makkahTripleRoomsController.text =
          widget.existingContractData!['makkah_triple_rooms']?.toString() ?? '';
      selectedSignatory = widget.existingContractData!['company_signatory']
          ?.toString();

      // تحميل أسعار البرنامج الخاصة بالعقد الموجود
      pricePerPersonQuadController.text =
          (widget.existingContractData!['price_per_person_quad'] as double?)
              ?.toStringAsFixed(2) ??
          '0.00';
      pricePerPersonTripleController.text =
          (widget.existingContractData!['price_per_person_triple'] as double?)
              ?.toStringAsFixed(2) ??
          '0.00';
      pricePerPersonDoubleController.text =
          (widget.existingContractData!['price_per_person_double'] as double?)
              ?.toStringAsFixed(2) ??
          '0.00';

      // أعد حساب العقد مباشرة لملء القيم المحسوبة (مثل الغرف الرباعية والتكاليف)
      // تأخير بسيط لضمان تهيئة جميع المتحكمات
      WidgetsBinding.instance.addPostFrameCallback((_) {
        calculateContract();
      });
    } else {
      // إنشاء عقد جديد: استخدم الأسعار الممررة كقيم افتراضية للبرنامج
      pricePerPersonQuadController.text = widget.pricePerPersonQuad
          .toStringAsFixed(2);
      pricePerPersonTripleController.text = widget.pricePerPersonTriple
          .toStringAsFixed(2);
      pricePerPersonDoubleController.text = widget.pricePerPersonDouble
          .toStringAsFixed(2);
    }
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
    pricePerPersonQuadController.dispose(); // NEW
    pricePerPersonTripleController.dispose(); // NEW
    pricePerPersonDoubleController.dispose(); // NEW
    super.dispose();
  }

  // دالة لحساب التكلفة الإجمالية للعقد وتوزيع المعتمرين
  void calculateContract() {
    setState(() {
      warningMessage = ""; // مسح التحذيرات السابقة
      totalMadinahRooms = 0; // إعادة تعيين إجمالي الغرف
      totalMakkahRooms = 0; // إعادة تعيين إجمالي الغرف
    });

    // ✅ استخدام القيم من المتحكمات الجديدة للأسعار
    double currentPricePerPersonQuad =
        double.tryParse(pricePerPersonQuadController.text) ?? 0.0;
    double currentPricePerPersonTriple =
        double.tryParse(pricePerPersonTripleController.text) ?? 0.0;
    double currentPricePerPersonDouble =
        double.tryParse(pricePerPersonDoubleController.text) ?? 0.0;

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
    // التكلفة الإجمالية لغرف المدينة بناءً على التخصيص الفعلي والأسعار المحررة
    currentTotalMadinahCost =
        (madinahQuadRoomsCalculated * currentPricePerPersonQuad * 4) +
        (madinahTripleRooms * currentPricePerPersonTriple * 3) +
        (madinahDoubleRooms * currentPricePerPersonDouble * 2);

    // التكلفة الإجمالية لغرف مكة بناءً على التخصيص الفعلي والأسعار المحررة
    currentTotalMakkahCost =
        (makkahQuadRoomsCalculated * currentPricePerPersonQuad * 4) +
        (makkahTripleRooms * currentPricePerPersonTriple * 3) +
        (makkahDoubleRooms * currentPricePerPersonDouble * 2);

    // إجمالي قيمة العقد الكلي
    currentOverallContractTotal =
        currentTotalMadinahCost + currentTotalMakkahCost;
  }

  // ✅ دالة لحفظ أو تحديث بيانات العقد في Supabase
  Future<void> _saveContractData() async {
    final int? tripId = widget.tripData['id'] is int
        ? widget.tripData['id'] as int
        : (widget.tripData['id'] != null
              ? int.tryParse(widget.tripData['id'].toString())
              : null);

    if (tripId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'خطأ: لا يوجد معرف رحلة صالح لربط العقد بها.',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
      return;
    }

    // قم بإجراء الحسابات أولاً لضمان تحديث المجاميع قبل الحفظ
    calculateContract();

    final Map<String, dynamic> contractData = {
      'trip_id': tripId,
      'agent_name': agentNameController.text,
      'contract_number': contractNumberController.text,
      'total_pilgrims': int.tryParse(totalPilgrimsController.text) ?? 0,
      'madinah_double_rooms':
          int.tryParse(madinahDoubleRoomsController.text) ?? 0,
      'madinah_triple_rooms':
          int.tryParse(madinahTripleRoomsController.text) ?? 0,
      'madinah_quad_rooms': madinahQuadRoomsCalculated, // محسوب
      'makkah_double_rooms':
          int.tryParse(makkahDoubleRoomsController.text) ?? 0,
      'makkah_triple_rooms':
          int.tryParse(makkahTripleRoomsController.text) ?? 0,
      'makkah_quad_rooms': makkahQuadRoomsCalculated, // محسوب
      'contract_terms': contractTermsController.text,
      'total_madinah_cost': currentTotalMadinahCost,
      'total_makkah_cost': currentTotalMakkahCost,
      'overall_contract_total': currentOverallContractTotal,
      'company_signatory': selectedSignatory ?? 'غير محدد',
      // حفظ أسعار البرنامج القابلة للتحرير مع العقد
      'price_per_person_quad':
          double.tryParse(pricePerPersonQuadController.text) ?? 0.0,
      'price_per_person_triple':
          double.tryParse(pricePerPersonTripleController.text) ?? 0.0,
      'price_per_person_double':
          double.tryParse(pricePerPersonDoubleController.text) ?? 0.0,
    };

    try {
      if (widget.existingContractData != null &&
          widget.existingContractData!['id'] != null) {
        // تحديث عقد موجود
        await Supabase.instance.client
            .from('contracts')
            .update(contractData)
            .eq('id', widget.existingContractData!['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم تحديث العقد بنجاح!',
                textDirection: TextDirection.rtl,
              ),
            ),
          );
        }
      } else {
        // إدخال عقد جديد
        await Supabase.instance.client.from('contracts').insert(contractData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم إضافة العقد بنجاح!',
                textDirection: TextDirection.rtl,
              ),
            ),
          );
        }
      }
      // بعد الحفظ، العودة إلى TripOverviewPage
      if (mounted) {
        Navigator.pop(context); // العودة إلى TripOverviewPage
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في حفظ/تحديث العقد: ${e.message}',
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
              'خطأ غير متوقع عند حفظ/تحديث العقد: ${e.toString()}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
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
        title: Text(
          widget.existingContractData != null
              ? "تعديل العقد"
              : "إنشاء العقد", // تغيير العنوان بناءً على الحالة
          style: const TextStyle(color: Colors.white),
        ),
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
            buildCustomTextField(
              agentNameController,
              "اسم الوكيل",
              "مثال: وكيل السعادة",
              TextInputType.text,
            ),
            const SizedBox(height: 15),
            buildCustomTextField(
              contractNumberController,
              "رقم العقد",
              "مثال: UMRAH-2025-001",
              TextInputType.text,
            ),
            const SizedBox(height: 30),

            // مدخل العدد الإجمالي للمعتمرين
            _buildSectionHeader("العدد الإجمالي للمعتمرين"),
            buildCustomTextField(
              totalPilgrimsController,
              "العدد الإجمالي للمعتمرين",
              "مثال: 45",
              TextInputType.number,
            ),
            const SizedBox(height: 30),

            // NEW: قسم أسعار البرنامج (قابلة للتحرير)
            _buildSectionHeader("أسعار البرنامج (للفرد الواحد)"),
            buildCustomTextField(
              pricePerPersonQuadController,
              "سعر الغرفة الرباعية",
              "مثال: 500",
              TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 15),
            buildCustomTextField(
              pricePerPersonTripleController,
              "سعر الغرفة الثلاثية",
              "مثال: 600",
              TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 15),
            buildCustomTextField(
              pricePerPersonDoubleController,
              "سعر الغرفة الثنائية",
              "مثال: 750",
              TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 30),

            // أعداد غرف المدينة
            _buildSectionHeader("توزيع الغرف في المدينة"),
            buildCustomTextField(
              madinahDoubleRoomsController,
              "عدد الغرف الثنائية",
              "مثال: 2",
              TextInputType.number,
            ),
            const SizedBox(height: 15),
            buildCustomTextField(
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
            buildCustomTextField(
              makkahDoubleRoomsController,
              "عدد الغرف الثنائية",
              "مثال: 3",
              TextInputType.number,
            ),
            const SizedBox(height: 15),
            buildCustomTextField(
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
            buildCustomTextField(
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

            // زر حفظ العقد (جديد)
            ElevatedButton(
              onPressed: _saveContractData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600, // لون مختلف
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: Text(
                widget.existingContractData != null
                    ? "تحديث العقد"
                    : "حفظ العقد", // تغيير النص بناءً على الحالة
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // زر طباعة PDF
            ElevatedButton(
              onPressed: () => _generatePdfContract(
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
                // استخدام قيم المتحكمات لأسعار البرنامج عند طباعة PDF
                pricePerPersonQuad:
                    double.tryParse(pricePerPersonQuadController.text) ?? 0.0,
                pricePerPersonTriple:
                    double.tryParse(pricePerPersonTripleController.text) ?? 0.0,
                pricePerPersonDouble:
                    double.tryParse(pricePerPersonDoubleController.text) ?? 0.0,
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
                // استخدام قيم المتحكمات لأسعار البرنامج عند بناء الصورة
                pricePerPersonQuad:
                    double.tryParse(pricePerPersonQuadController.text) ?? 0.0,
                pricePerPersonTriple:
                    double.tryParse(pricePerPersonTripleController.text) ?? 0.0,
                pricePerPersonDouble:
                    double.tryParse(pricePerPersonDoubleController.text) ?? 0.0,
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لإنشاء حقول إدخال نصية مخصصة
  Widget buildCustomTextField(
    TextEditingController controller,
    String labelText,
    String hintText,
    TextInputType keyboardType, {
    int maxLines = 1, // المعامل الجديد: يسمح بتحديد عدد الأسطر الأقصى
    List<TextInputFormatter>? inputFormatters, // لإضافة inputFormatters
  }) {
    return TextField(
      controller: controller,
      textDirection: TextDirection.rtl,
      keyboardType: keyboardType,
      maxLines: maxLines, // تطبيق عدد الأسطر الأقصى
      inputFormatters: inputFormatters, // تطبيق inputFormatters
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
    required double pricePerPersonQuad, // NEW: Passed editable prices
    required double pricePerPersonTriple, // NEW
    required double pricePerPersonDouble, // NEW
  }) {
    // تحتاج إلى ضبط هذه الأحجام والمواضع بناءً على قالب صورتك الفعلية
    // هذا يفترض صورة بنسبة تقريبية لـ A4 (مثل 600 عرض × 800 ارتفاع)
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
              color: Colors.black.withOpacity(0.1),
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
                'assets/images/contract_template.jpg', // تم تحديث المسار ليتوافق مع الصورة الجديدة (JPG)
                fit: BoxFit.fill, // ملء الحاوية
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      'خطأ في تحميل الصورة: تأكد من إضافة contract_template.jpg في assets/images وتحديث pubspec.yaml',
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
              right: 180, // تم التعديل
              child: SizedBox(
                width: 150,
                child: Text(
                  contractNumber.isNotEmpty ? contractNumber : "غير محدد",
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
              right: 200,
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
              right: 210, // تم التعديل
              child: SizedBox(
                width: 250,
                child: Text(
                  agentName.isNotEmpty ? agentName : "غير محدد",
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
              right: 170, // موضع تقريبي
              child: SizedBox(
                width: 350,
                child: Text(
                  'إجمالي ${totalMadinahRooms + totalMakkahRooms} ليلة، وعدد المعتمرين ${totalPilgrims}', // دمج عدد الليالي مع عدد المعتمرين
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // --- جدول التفاصيل (تخطيط مخصص) ---
            // بناء جدول يدويا باستخدام Column و Row لوضعه بدقة
            Positioned(
              top: 360, // تم التعديل ليتوافق مع بداية الجدول في الصورة
              right: 75, // تم التعديل
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
                    "غرف رباعية",
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

  // دالة مساعدة لإنشاء حقول إدخال نصية مخصصة
  // Widget buildCustomTextField(
  //   TextEditingController controller,
  //   String labelText,
  //   String hintText,
  //   TextInputType keyboardType, {
  //   int maxLines = 1,
  //   List<TextInputFormatter>? inputFormatters,
  // }) {
  //   return TextField(
  //     controller: controller,
  //     textDirection: TextDirection.rtl,
  //     keyboardType: keyboardType,
  //     maxLines: maxLines,
  //     inputFormatters: inputFormatters,
  //     style: TextStyle(fontSize: 18, color: Colors.blueGrey.shade900),
  //     decoration: InputDecoration(
  //       labelText: labelText,
  //       labelStyle: TextStyle(fontSize: 16, color: Colors.blueGrey.shade600),
  //       hintText: hintText,
  //       hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14),
  //       hintTextDirection: TextDirection.rtl,
  //       filled: true,
  //       fillColor: Colors.white,
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(10),
  //         borderSide: BorderSide.none,
  //       ),
  //       enabledBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(10),
  //         borderSide: BorderSide(color: Colors.blue.shade200, width: 1.5),
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(10),
  //         borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 2),
  //       ),
  //       contentPadding: const EdgeInsets.symmetric(
  //         horizontal: 15,
  //         vertical: 12,
  //       ),
  //     ),
  //   );
  // }

  // // دالة مساعدة لعرض أعداد الغرف المحسوبة (في جزء الإدخال)
  // Widget _buildCalculatedRoomDisplay(String label, int count) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: Colors.grey.shade100,
  //       borderRadius: BorderRadius.circular(10),
  //       border: Border.all(color: Colors.blue.shade100, width: 1.5),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(
  //           label,
  //           textDirection: TextDirection.rtl,
  //           style: TextStyle(fontSize: 18, color: Colors.blueGrey.shade600),
  //         ),
  //         Text(
  //           count.toString(),
  //           textDirection: TextDirection.ltr,
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.blueGrey.shade900,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // // دالة مساعدة لإنشاء عناوين الأقسام (في جزء الإدخال)
  // Widget _buildSectionHeader(String title) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 15.0),
  //     child: Text(
  //       title,
  //       textDirection: TextDirection.rtl,
  //       style: TextStyle(
  //         fontSize: 22,
  //         fontWeight: FontWeight.bold,
  //         color: Colors.blueGrey.shade700,
  //       ),
  //     ),
  //   );
  // }

  // // --- دالة لإنشاء مستند PDF من بيانات العقد ---
  Future<void> _generatePdfContract({
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
    required double pricePerPersonQuad, // NEW: Passed editable prices
    required double pricePerPersonTriple, // NEW
    required double pricePerPersonDouble, // NEW
  }) async {
    final pdf = pw.Document();
    final pw.Font arabicFont = await _arabicFontFuture; // تحميل الخط العربي

    // تحميل صورة الخلفية
    final ByteData bytes = await rootBundle.load(
      'assets/images/contract_template.jpg',
    ); // تحديث المسار لـ JPG
    final Uint8List byteList = bytes.buffer.asUint8List();
    final pw.MemoryImage contractImage = pw.MemoryImage(byteList);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // صورة الخلفية كأول عنصر في الـ Stack
              pw.Image(contractImage, fit: pw.BoxFit.fill),

              // رقم العقد (في الصورة هو في الزاوية العلوية اليمنى)
              pw.Positioned(
                top: 70, // تم التعديل ليتناسب مع قالب الـ PDF
                right: 90, // تم التعديل
                child: pw.SizedBox(
                  width: 150,
                  child: pw.Text(
                    contractNumber.isNotEmpty ? contractNumber : "غير محدد",
                    textDirection: pw.TextDirection.ltr, // رقم العقد LTR
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
                top: 100, // تم التعديل
                right: 120, // تم التعديل
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
                top: 130, // تم التعديل
                right: 120, // تم التعديل
                child: pw.SizedBox(
                  width: 300,
                  child: pw.Text(
                    'إجمالي ${totalMadinahRooms + totalMakkahRooms} ليلة، وعدد المعتمرين ${totalPilgrims}',
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(fontSize: 10, font: arabicFont),
                    maxLines: 2,
                  ),
                ),
              ),

              // --- جدول التفاصيل في PDF ---
              pw.Positioned(
                top:
                    250, // اضبط هذا ليتوافق مع بداية منطقة الجدول في قالب الـ PDF
                right: 70, // هام لضبط عرض الجدول
                left: 70, // هام لضبط عرض الجدول
                child: pw.Table.fromTextArray(
                  headers: [
                    'التفاصيل',
                    'المدينة',
                    'مكة',
                    'السعر/شخص',
                    'الإجمالي',
                  ],
                  data: [
                    ['العدد الإجمالي للمعتمرين', '$totalPilgrims', '', '', ''],
                    ['غرف المدينة:', '', '', '', ''], // صف عنوان فرعي
                    [
                      'ثنائي',
                      madinahDouble.toString(),
                      '',
                      pricePerPersonDouble.toStringAsFixed(0),
                      (madinahDouble * pricePerPersonDouble * 2)
                          .toStringAsFixed(0),
                    ],
                    [
                      'ثلاثي',
                      madinahTriple.toString(),
                      '',
                      pricePerPersonTriple.toStringAsFixed(0),
                      (madinahTriple * pricePerPersonTriple * 3)
                          .toStringAsFixed(0),
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
                    ['غرف مكة:', '', '', '', ''], // صف عنوان فرعي
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
                  cellAlignment: pw.Alignment.center, // محاذاة الخلايا
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    font: arabicFont,
                  ),
                  cellStyle: pw.TextStyle(fontSize: 9, font: arabicFont),
                  columnWidths: {
                    // ضبط عرض الأعمدة
                    0: const pw.FlexColumnWidth(3), // التفاصيل
                    1: const pw.FlexColumnWidth(1.5), // المدينة
                    2: const pw.FlexColumnWidth(1.5), // مكة
                    3: const pw.FlexColumnWidth(2), // السعر/شخص
                    4: const pw.FlexColumnWidth(2), // الإجمالي
                  },
                  border: pw.TableBorder.all(
                    color: PdfColors.black,
                    width: 0.5,
                  ),
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

              // قسم التوقيعات (موضع افتراضي)
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
      OpenFilex.open(path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إنشاء ملف PDF بنجاح في: $path',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في إنشاء أو حفظ ملف PDF: $e',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }
}
