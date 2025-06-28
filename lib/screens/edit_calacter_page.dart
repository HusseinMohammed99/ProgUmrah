import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for TextInputFormatter
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:umrah/screens/contracts_page.dart'; // استيراد صفحة العقود

class EditCalacterPage extends StatefulWidget {
  // هذه الصفحة مصممة خصيصًا لتعديل العقود، لذا يجب أن يكون existingContractData موجودًا دائمًا.
  // تم جعل existingContractData غير قابل للقيمة الفارغة (non-nullable) هنا لفرض ذلك.
  final Map<String, dynamic> tripData;
  final Map<String, dynamic>
  existingContractData; // بيانات العقد الحالي للتعديل (غير قابلة للقيمة الفارغة)

  const EditCalacterPage({
    super.key,
    required this.tripData,
    required this.existingContractData,
    required double pricePerPersonQuad,
    required double pricePerPersonTriple,
    required double
    pricePerPersonDouble, // يجب أن يتم تمرير بيانات عقد موجود دائمًا
  });

  @override
  State<EditCalacterPage> createState() => _EditCalacterPageState();
}

class _EditCalacterPageState extends State<EditCalacterPage> {
  // Input fields for Saudi Riyals (SAR)
  final TextEditingController numr1 =
      TextEditingController(); // Visa price (SAR)
  final TextEditingController numr2 =
      TextEditingController(); // Number of nights in Madinah
  final TextEditingController numr3 =
      TextEditingController(); // Price per night in Madinah (SAR)
  final TextEditingController numr4 =
      TextEditingController(); // Price per night in Makkah (SAR)
  final TextEditingController numr5 =
      TextEditingController(); // Number of nights in Makkah

  // Input fields for US Dollars (USD)
  final TextEditingController numd1 =
      TextEditingController(); // Transportation price (USD)
  final TextEditingController numd2 =
      TextEditingController(); // Authority/Fees price (USD)
  final TextEditingController numd3 = TextEditingController(); // Gifts USD
  final TextEditingController numd4 =
      TextEditingController(); // Company commission 1 (USD)
  final TextEditingController numd5 =
      TextEditingController(); // Company commission 2 (USD)

  // Custom occupancy input (t) - kept for potential future use or total passengers if different from room occupancy
  final TextEditingController t = TextEditingController();

  // Custom room occupancy input for MADINAH (e.g., 3.5 people per room)
  final TextEditingController madinahRoomOccupancyController =
      TextEditingController();
  // Custom room occupancy input for MAKKAH (e.g., 2.0 people per room)
  final TextEditingController makkahRoomOccupancyController =
      TextEditingController();

  // Result variables
  String resultQuad = ""; // For Quad occupancy
  String resultTriple = ""; // For Triple occupancy
  String resultDouble = ""; // For Double occupancy

  // Store calculated prices to pass to ContractPage
  double pricePerPersonQuad = 0.0;
  double pricePerPersonTriple = 0.0;
  double pricePerPersonDouble = 0.0;

  // Dispose controllers to prevent memory leaks when the widget is removed
  @override
  void dispose() {
    numr1.dispose();
    numr2.dispose();
    numr3.dispose();
    numr4.dispose();
    numr5.dispose();
    numd1.dispose();
    numd2.dispose();
    numd3.dispose();
    numd4.dispose();
    numd5.dispose();
    t.dispose();
    madinahRoomOccupancyController.dispose();
    makkahRoomOccupancyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // بما أن هذه الصفحة مخصصة للتعديل، existingContractData سيكون موجودًا دائمًا.
    print(
      "[EditCalacterPage] Received existing contract data: ${widget.existingContractData}",
    );
    _loadExistingContractData();
  }

  // Function to load existing contract data into controllers
  void _loadExistingContractData() {
    final Map<String, dynamic> data =
        widget.existingContractData; // لا داعي لـ ! هنا

    print(
      "[EditCalacterPage] Raw existing contract data for loading: $data",
    ); // طباعة البيانات الخام

    // تحميل البيانات من العقد الموجود إلى المتحكمات
    // استخدام .toString() مباشرة لتحويل أي نوع بيانات رقمي إلى نص
    // استخدام (data['key'] as num?)?.toString() للتعامل مع int/double
    numr1.text = (data['visa_price_sar'] as num?)?.toString() ?? '';
    print("[EditCalacterPage] Loaded numr1 (Visa Price SAR): ${numr1.text}");

    numr2.text = (data['madinah_nights_input'] as num?)?.toString() ?? '';
    print("[EditCalacterPage] Loaded numr2 (Madinah Nights): ${numr2.text}");

    numr3.text =
        (data['madinah_price_per_night_sar'] as num?)?.toString() ?? '';
    print(
      "[EditCalacterPage] Loaded numr3 (Madinah Price/Night SAR): ${numr3.text}",
    );

    numr4.text = (data['makkah_price_per_night_sar'] as num?)?.toString() ?? '';
    print(
      "[EditCalacterPage] Loaded numr4 (Makkah Price/Night SAR): ${numr4.text}",
    );

    numr5.text = (data['makkah_nights_input'] as num?)?.toString() ?? '';
    print("[EditCalacterPage] Loaded numr5 (Makkah Nights): ${numr5.text}");

    numd1.text = (data['transportation_usd'] as num?)?.toString() ?? '';
    print(
      "[EditCalacterPage] Loaded numd1 (Transportation USD): ${numd1.text}",
    );

    numd2.text = (data['authority_fees_usd'] as num?)?.toString() ?? '';
    print(
      "[EditCalacterPage] Loaded numd2 (Authority Fees USD): ${numd2.text}",
    );

    numd3.text = (data['gifts_usd'] as num?)?.toString() ?? '';
    print("[EditCalacterPage] Loaded numd3 (Gifts USD): ${numd3.text}");

    numd4.text = (data['company_commission1_usd'] as num?)?.toString() ?? '';
    print(
      "[EditCalacterPage] Loaded numd4 (Company Commission 1 USD): ${numd4.text}",
    );

    numd5.text = (data['company_commission2_usd'] as num?)?.toString() ?? '';
    print(
      "[EditCalacterPage] Loaded numd5 (Company Commission 2 USD): ${numd5.text}",
    );

    t.text = (data['total_pilgrims'] as num?)?.toString() ?? '';
    print("[EditCalacterPage] Loaded t (Total Pilgrims): ${t.text}");

    madinahRoomOccupancyController.text =
        (data['madinah_room_occupancy_factor'] as num?)?.toString() ?? '1.0';
    print(
      "[EditCalacterPage] Loaded madinahRoomOccupancyController: ${madinahRoomOccupancyController.text}",
    );

    makkahRoomOccupancyController.text =
        (data['makkah_room_occupancy_factor'] as num?)?.toString() ?? '1.0';
    print(
      "[EditCalacterPage] Loaded makkahRoomOccupancyController: ${makkahRoomOccupancyController.text}",
    );

    // تحميل الأسعار المحسوبة من العقد الموجود
    pricePerPersonQuad = (data['price_per_person_quad'] as double?) ?? 0.0;
    pricePerPersonTriple = (data['price_per_person_triple'] as double?) ?? 0.0;
    pricePerPersonDouble = (data['price_per_person_double'] as double?) ?? 0.0;
    print(
      "[EditCalacterPage] Loaded pricePerPersonQuad from DB: $pricePerPersonQuad",
    );
    print(
      "[EditCalacterPage] Loaded pricePerPersonTriple from DB: $pricePerPersonTriple",
    );
    print(
      "[EditCalacterPage] Loaded pricePerPersonDouble from DB: $pricePerPersonDouble",
    );

    // تحديث متغيرات النتائج لعرضها في الواجهة
    resultQuad = pricePerPersonQuad.round().toString();
    resultTriple = pricePerPersonTriple.round().toString();
    resultDouble = pricePerPersonDouble.round().toString();
    print(
      "[EditCalacterPage] Initial UI resultQuad (from DB, pre-SumR): $resultQuad",
    );
    print(
      "[EditCalacterPage] Initial UI resultTriple (from DB, pre-SumR): $resultTriple",
    );
    print(
      "[EditCalacterPage] Initial UI resultDouble (from DB, pre-SumR): $resultDouble",
    );

    // تأخير استدعاء SumR() لضمان تحديث جميع المتحكمات أولاً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("[EditCalacterPage] Calling SumR after controllers updated.");
      SumR();
    });
  }

  // Function to clear all input fields and reset results (مع الاحتفاظ بعامل الإشغال الافتراضي)
  void _clearAllFields() {
    setState(() {
      numr1.clear();
      numr2.clear();
      numr3.clear();
      numr4.clear();
      numr5.clear();
      numd1.clear();
      numd2.clear();
      numd3.clear();
      numd4.clear();
      numd5.clear();
      t.clear();
      madinahRoomOccupancyController.text = '1.0'; // إعادة تعيين لافتراضي
      makkahRoomOccupancyController.text = '1.0'; // إعادة تعيين لافتراضي
      resultQuad = "0";
      resultTriple = "0";
      resultDouble = "0";
      pricePerPersonQuad = 0.0;
      pricePerPersonTriple = 0.0;
      pricePerPersonDouble = 0.0;
    });
  }

  // Main calculation function
  void SumR() {
    double nR1 = double.tryParse(numr1.text) ?? 0;
    double nR2 = double.tryParse(numr2.text) ?? 0;
    double nR3 = double.tryParse(numr3.text) ?? 0;
    double nR4 = double.tryParse(numr4.text) ?? 0;
    double nR5 = double.tryParse(numr5.text) ?? 0;

    double nD1 = double.tryParse(numd1.text) ?? 0;
    double nD2 = double.tryParse(numd2.text) ?? 0;
    double nD3 = double.tryParse(numd3.text) ?? 0;
    double nD4 = double.tryParse(numd4.text) ?? 0;
    double nD5 = double.tryParse(numd5.text) ?? 0;

    print(
      "[SumR] Parsed Inputs - nR1: $nR1, nR2: $nR2, nR3: $nR3, nR4: $nR4, nR5: $nR5",
    );
    print(
      "[SumR] Parsed Inputs - nD1: $nD1, nD2: $nD2, nD3: $nD3, nD4: $nD4, nD5: $nD5",
    );

    double madinahRoomOccupancyFactor =
        double.tryParse(madinahRoomOccupancyController.text) ?? 0;
    double makkahRoomOccupancyFactor =
        double.tryParse(makkahRoomOccupancyController.text) ?? 0;

    print(
      "[SumR] Room Occupancy Factors - Madinah: $madinahRoomOccupancyFactor, Makkah: $makkahRoomOccupancyFactor",
    );

    if (madinahRoomOccupancyFactor <= 0) {
      madinahRoomOccupancyFactor = 1;
      print("[SumR] Madinah Room Occupancy adjusted to 1.");
    }
    if (makkahRoomOccupancyFactor <= 0) {
      makkahRoomOccupancyFactor = 1;
      print("[SumR] Makkah Room Occupancy adjusted to 1.");
    }

    double visaPriceInUsd = nR1 / 3.75;
    print("[SumR] Visa Price in USD: $visaPriceInUsd");

    double madinahAccommodationCostTotalSAR = nR2 * nR3;
    double madinahAccommodationCostPerPersonUSD =
        (madinahAccommodationCostTotalSAR / 3.75) / madinahRoomOccupancyFactor;
    print(
      "[SumR] Madinah Accommodation Cost Total SAR: $madinahAccommodationCostTotalSAR",
    );
    print(
      "[SumR] Madinah Accommodation Cost Per Person USD: $madinahAccommodationCostPerPersonUSD",
    );

    double makkahAccommodationCostTotalSAR = nR4 * nR5;
    double makkahAccommodationCostPerPersonUSD =
        (makkahAccommodationCostTotalSAR / 3.75) / makkahRoomOccupancyFactor;
    print(
      "[SumR] Makkah Accommodation Cost Total SAR: $makkahAccommodationCostTotalSAR",
    );
    print(
      "[SumR] Makkah Accommodation Cost Per Person USD: $makkahAccommodationCostPerPersonUSD",
    );

    double totalAccommodationCostPerPersonUsd =
        madinahAccommodationCostPerPersonUSD +
        makkahAccommodationCostPerPersonUSD;
    print(
      "[SumR] Total Accommodation Cost Per Person USD: $totalAccommodationCostPerPersonUsd",
    );

    double totalFixedExpensesPerGroupUsd = nD1 + nD2 + nD3 + nD4 + nD5;
    print(
      "[SumR] Total Fixed Expenses Per Group USD: $totalFixedExpensesPerGroupUsd",
    );

    int defaultQuadOccupancy = 4;
    int defaultTripleOccupancy = 3;
    int defaultDoubleOccupancy = 2;

    double calculatedPriceQuad =
        totalAccommodationCostPerPersonUsd +
        visaPriceInUsd +
        (totalFixedExpensesPerGroupUsd / defaultQuadOccupancy);
    double calculatedPriceTriple =
        totalAccommodationCostPerPersonUsd +
        visaPriceInUsd +
        (totalFixedExpensesPerGroupUsd / defaultTripleOccupancy);
    double calculatedPriceDouble =
        totalAccommodationCostPerPersonUsd +
        visaPriceInUsd +
        (totalFixedExpensesPerGroupUsd / defaultDoubleOccupancy);

    print(
      "[SumR] Calculated Price Quad (before rounding): $calculatedPriceQuad",
    );
    print(
      "[SumR] Calculated Price Triple (before rounding): $calculatedPriceTriple",
    );
    print(
      "[SumR] Calculated Price Double (before rounding): $calculatedPriceDouble",
    );

    int roundedPriceQuad = calculatedPriceQuad.ceil();
    int roundedPriceTriple = calculatedPriceTriple.ceil();
    int roundedPriceDouble = calculatedPriceDouble.ceil();

    print("[SumR] Rounded Price Quad: $roundedPriceQuad");
    print("[SumR] Rounded Price Triple: $roundedPriceTriple");
    print("[SumR] Rounded Price Double: $roundedPriceDouble");

    setState(() {
      resultQuad = roundedPriceQuad.toString();
      resultTriple = roundedPriceTriple.toString();
      resultDouble = roundedPriceDouble.toString();
      pricePerPersonQuad = roundedPriceQuad.toDouble();
      pricePerPersonTriple = roundedPriceTriple.toDouble();
      pricePerPersonDouble = roundedPriceDouble.toDouble();
      print("[SumR] UI Result Quad updated to: $resultQuad");
      print("[SumR] UI Result Triple updated to: $resultTriple");
      print("[SumR] UI Result Double updated to: $resultDouble");
    });
  }

  // Function to save or update program data to Supabase and proceed to ContractPage
  Future<void> _saveProgramAndProceed() async {
    SumR(); // Ensure calculations are performed and values are up-to-date before saving

    if (int.tryParse(t.text) == null || int.tryParse(t.text)! <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'الرجاء إدخال عدد صحيح للمعتمرين أكبر من صفر قبل المتابعة.',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
      return;
    }

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

    // Build the data map to save to Supabase
    final Map<String, dynamic> programData = {
      'trip_id': tripId,
      'total_pilgrims': int.tryParse(t.text) ?? 0,
      'visa_price_sar': double.tryParse(numr1.text) ?? 0.0,
      'madinah_nights_input': double.tryParse(numr2.text) ?? 0.0,
      'madinah_price_per_night_sar': double.tryParse(numr3.text) ?? 0.0,
      'makkah_nights_input': double.tryParse(numr5.text) ?? 0.0,
      'makkah_price_per_night_sar': double.tryParse(numr4.text) ?? 0.0,
      'transportation_usd': double.tryParse(numd1.text) ?? 0.0,
      'authority_fees_usd': double.tryParse(numd2.text) ?? 0.0,
      'gifts_usd': double.tryParse(numd3.text) ?? 0.0,
      'company_commission1_usd': double.tryParse(numd4.text) ?? 0.0,
      'company_commission2_usd': double.tryParse(numd5.text) ?? 0.0,
      'price_per_person_quad': pricePerPersonQuad,
      'price_per_person_triple': pricePerPersonTriple,
      'price_per_person_double': pricePerPersonDouble,
      'madinah_room_occupancy_factor':
          double.tryParse(madinahRoomOccupancyController.text) ?? 1.0,
      'makkah_room_occupancy_factor':
          double.tryParse(makkahRoomOccupancyController.text) ?? 1.0,
    };

    try {
      // بما أن هذه الصفحة مخصصة للتعديل، سنقوم دائمًا بالتحديث
      await Supabase.instance.client
          .from('contracts')
          .update(programData)
          .eq(
            'id',
            widget.existingContractData['id'],
          ); // نستخدم existingContractData مباشرة هنا

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تحديث البرنامج بنجاح! سيتم نقلك لصفحة العقد.',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }

      // Navigate to ContractPage after saving the program
      if (mounted) {
        // تأكد من تمرير بيانات العقد المحدثة إلى صفحة العقد
        Map<String, dynamic> updatedContractData = {
          ...widget.existingContractData, // نسخ البيانات الأصلية
          ...programData, // دمج البيانات المحدثة
          'id': widget.existingContractData['id'], // التأكد من وجود الـ ID
        };

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContractPage(
              tripData: widget.tripData,
              pricePerPersonQuad: pricePerPersonQuad,
              pricePerPersonTriple: pricePerPersonTriple,
              pricePerPersonDouble: pricePerPersonDouble,
              existingContractData:
                  updatedContractData, // تمرير بيانات العقد المحدثة
            ),
          ),
        );
        if (mounted) {
          Navigator.pop(context); // Go back to TripOverviewPage after finishing
        }
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في تحديث البرنامج: ${e.message}',
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
              'خطأ غير متوقع عند تحديث البرنامج: ${e.toString()}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // بما أن هذه الصفحة للتعديل فقط، يمكننا جعل العنوان وثابتًا
    const String appBarTitle = "تعديل برنامج العقد";
    const String saveButtonText = "تحديث البرنامج ومتابعة العقد";

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for the whole page
      appBar: AppBar(
        toolbarHeight: 120, // Taller AppBar for more visual impact
        backgroundColor: Colors.blueAccent.shade700, // Deeper blue for AppBar
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Align(
          alignment:
              Alignment.centerRight, // Align title to the right for Arabic
          child: Text(
            appBarTitle, // Page title in Arabic, now dynamic
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 38, // Larger font size for prominence
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 4.0,
                  color: Colors.black26,
                  offset: Offset(2.0, 2.0),
                ),
              ],
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(
              30,
            ), // More rounded corners at the bottom
            bottomRight: Radius.circular(30),
          ),
        ),
        elevation: 8, // Add shadow to AppBar for depth
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(
            20.0,
          ), // Padding around the main content
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine if we are on a wide screen (desktop/tablet) or narrow (mobile)
                bool isWideScreen = constraints.maxWidth > 800;

                return Flex(
                  direction: isWideScreen
                      ? Axis.horizontal
                      : Axis.vertical, // Layout based on screen width
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // Align children to the start of the cross axis
                  mainAxisAlignment: MainAxisAlignment
                      .center, // Center children along the main axis
                  children: [
                    // Left Section (Results Display)
                    Flexible(
                      flex: isWideScreen
                          ? 1
                          : 0, // Flexible sizing for wide screens
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: isWideScreen
                              ? 350
                              : double
                                    .infinity, // Min width for wide, full width for narrow
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment
                              .stretch, // Stretch result cards to fill width
                          children: [
                            buildResultCard(
                              label: "رباعي", // Quad occupancy label
                              value: resultQuad,
                              color: Colors.purple.shade100,
                              icon: Icons.group_add,
                            ),
                            const SizedBox(height: 20), // Spacer
                            buildResultCard(
                              label: "ثلاثي", // Triple occupancy label
                              value: resultTriple,
                              color: Colors.orange.shade100,
                              icon: Icons.people_alt,
                            ),
                            const SizedBox(height: 20), // Spacer
                            buildResultCard(
                              label: "ثنائي", // Double occupancy label
                              value: resultDouble,
                              color: Colors.green.shade100,
                              icon: Icons.person_add_alt_1,
                            ),
                            const SizedBox(
                              height: 40,
                            ), // Larger spacer before button
                            // Clear All Fields Button
                            ElevatedButton.icon(
                              onPressed:
                                  _clearAllFields, // Call the clear function
                              icon: const Icon(
                                Icons.clear_all,
                                size: 30,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "مسح الكل", // Clear All label in Arabic
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.redAccent, // Red for clear action
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    15,
                                  ), // Rounded corners for button
                                ),
                                elevation: 5, // Add shadow
                                shadowColor: Colors.redAccent.shade200,
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ), // Spacer before navigate button
                            // Navigate to Contract Page Button
                            ElevatedButton.icon(
                              onPressed:
                                  _saveProgramAndProceed, // Call save function
                              icon: const Icon(
                                Icons.assignment,
                                size: 30,
                                color: Colors.white,
                              ),
                              label: const Text(
                                // النص ثابت الآن
                                saveButtonText, // "تحديث البرنامج ومتابعة العقد"
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .indigo
                                    .shade600, // Blue for contract action
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                shadowColor: Colors.indigo.shade200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isWideScreen)
                      const SizedBox(
                        width: 40,
                      ), // Spacer for horizontal layout on wide screens
                    // Right Section (Input Fields)
                    Flexible(
                      flex: isWideScreen
                          ? 2
                          : 0, // Flexible sizing for wide screens
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: isWideScreen
                              ? 700
                              : double
                                    .infinity, // Min width for wide, full width for narrow
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Wrap(
                          spacing:
                              20, // Horizontal spacing between input containers
                          runSpacing:
                              20, // Vertical spacing between rows of input containers
                          alignment: WrapAlignment
                              .center, // Center align items in wrap
                          children: [
                            // USD Inputs Container
                            _buildInputContainer(
                              title:
                                  "أسعار بالدولار", // USD Prices label in Arabic
                              color:
                                  Colors.blue.shade50, // Light blue background
                              children: [
                                buildCustomTextField(
                                  numd1,
                                  "سعر النقل", // Transportation price
                                  "مثال: 500",
                                  TextInputType.number,
                                ),
                                buildCustomTextField(
                                  numd2,
                                  "سعر الهيئة", // Authority/Fees price
                                  "مثال: 150",
                                  TextInputType.number,
                                ),
                                buildCustomTextField(
                                  numd3,
                                  "سعر الهدايا", // Gifts price
                                  "مثال: 100",
                                  TextInputType.number,
                                ),
                                buildCustomTextField(
                                  numd4,
                                  "عمولة الشركة 1", // Company commission 1
                                  "مثال: 75",
                                  TextInputType.number,
                                ),
                                buildCustomTextField(
                                  numd5,
                                  "عمولة الشركة 2", // Company commission 2
                                  "مثال: 25",
                                  TextInputType.number,
                                ),
                                // Custom Occupancy Input (original 't' field, can be repurposed or removed)
                                buildCustomTextField(
                                  t,
                                  "العدد الإجمالي للمعتمرين", // Total number of people (optional)
                                  "مثال: 45", // Leave empty if not needed
                                  TextInputType.number,
                                ),
                              ],
                            ),
                            // SAR Inputs Container
                            _buildInputContainer(
                              title:
                                  "أسعار بالريال", // SAR Prices label in Arabic
                              color: Colors
                                  .green
                                  .shade50, // Light green background
                              children: [
                                buildCustomTextField(
                                  numr1,
                                  "سعر الفيزا", // Visa price
                                  "مثال: 300",
                                  TextInputType.number,
                                ),
                                buildCustomTextField(
                                  numr2,
                                  "عدد ليالي المدينة", // Number of nights in Madinah
                                  "مثال: 4",
                                  TextInputType.number,
                                ),
                                buildCustomTextField(
                                  numr3,
                                  "سعر المدينة لليلة", // Price per night in Madinah
                                  "مثال: 120",
                                  TextInputType.number,
                                ),
                                buildCustomTextField(
                                  madinahRoomOccupancyController,
                                  "عامل إشغال غرفة المدينة", // NEW: Madinah room occupancy
                                  "مثال: 1.0 (للفرد الواحد)", // Hint for Madinah room occupancy
                                  TextInputType.number,
                                ),
                                buildCustomTextField(
                                  numr4,
                                  "سعر مكة لليلة", // Price per night in Makkah
                                  "مثال: 150",
                                  TextInputType.number,
                                ),
                                buildCustomTextField(
                                  numr5,
                                  "عدد ليالي مكة", // Number of nights in Makkah
                                  "مثال: 6",
                                  TextInputType.number,
                                ),
                                buildCustomTextField(
                                  makkahRoomOccupancyController,
                                  "عامل إشغال غرفة مكة", // NEW: Makkah room occupancy
                                  "مثال: 1.0 (للفرد الواحد)", // Hint for Makkah room occupancy
                                  TextInputType.number,
                                ),
                              ],
                            ),
                            // Calculate Button (placed centrally below input fields)
                            const SizedBox(height: 20), // Spacer
                            SizedBox(
                              width: isWideScreen
                                  ? 680
                                  : double
                                        .infinity, // Wider button for wide screens, full width for narrow
                              child: ElevatedButton(
                                onPressed:
                                    SumR, // Main calculation button action
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors
                                      .deepPurple
                                      .shade400, // Vibrant button color
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      25,
                                    ), // More rounded button
                                  ),
                                  elevation: 7, // More prominent shadow
                                  shadowColor: Colors.deepPurple.shade200,
                                ),
                                child: const Text(
                                  "حساب التكلفة", // Calculate Cost label in Arabic
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build input containers (e.g., for USD and SAR sections)
  Widget _buildInputContainer({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: 350, // Fixed width for input containers to keep them consistent
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          25,
        ), // Rounded corners for container
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 5), // Shadow for depth
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade800,
            ),
            textDirection: TextDirection.rtl, // Right-to-left for title
          ),
          const Divider(
            height: 25,
            thickness: 1.5,
            color: Colors.blueGrey,
          ), // Separator line
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(
                bottom: 15.0,
              ), // Spacing between text fields
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build custom text fields with improved styling
  Widget buildCustomTextField(
    TextEditingController controller,
    String labelText,
    String hintText,
    TextInputType keyboardType,
  ) {
    return TextField(
      controller: controller,
      textDirection:
          TextDirection.rtl, // Text direction right-to-left for input
      keyboardType: keyboardType, // Numeric keyboard for number inputs
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d+\.?\d{0,2}'),
        ), // Allow numbers and max 2 decimal places
      ],
      style: TextStyle(
        fontSize: 20,
        color: Colors.blueGrey.shade900,
      ), // Text field font size and color
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontSize: 18,
          color: Colors.blueGrey.shade600,
          fontWeight: FontWeight.w600,
        ),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 16),
        hintTextDirection: TextDirection.rtl, // Hint text direction
        filled: true,
        fillColor: Colors.white, // White fill for text fields
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ), // Rounded corners for input fields
          borderSide: BorderSide.none, // No default border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.blue.shade300,
            width: 2,
          ), // Lighter blue border when enabled
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.deepPurple.shade400,
            width: 2.5,
          ), // Thicker, vibrant border on focus
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ), // Padding inside text field
      ),
    );
  }

  // Helper widget for displaying calculation results in a styled card
  Widget buildResultCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4), // Shadow for result cards
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Space out label/icon and value
        children: [
          Icon(
            icon,
            size: 35,
            color: Colors.blueGrey.shade700,
          ), // Icon for each result type
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "$label :",
              textDirection:
                  TextDirection.rtl, // Label text direction (RTL for Arabic)
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
            ),
          ),
          Text(
            value.isNotEmpty
                ? "$value \$"
                : "---", // Display $ if value exists, otherwise "---"
            textDirection:
                TextDirection.ltr, // Numeric value text direction (LTR)
            style: TextStyle(
              fontSize: 28, // Larger font size for result value
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
