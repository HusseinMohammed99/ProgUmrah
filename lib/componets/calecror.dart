import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for TextInputFormatter
import 'package:umrah/screens/contracts_page.dart'; // استيراد صفحة العقود

class CalacterPage extends StatefulWidget {
  const CalacterPage({super.key});

  @override
  State<CalacterPage> createState() => _CalacterPageState();
}

class _CalacterPageState extends State<CalacterPage> {
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
  final TextEditingController numd3 =
      TextEditingController(); // Gifts price (USD)
  final TextEditingController numd4 =
      TextEditingController(); // Company commission 1 (USD)
  final TextEditingController numd5 =
      TextEditingController(); // Company commission 2 (USD)

  // Custom occupancy input (t) - kept for potential future use or total passengers if different from room occupancy
  final TextEditingController t = TextEditingController();

  // NEW: Custom room occupancy input for MADINAH (e.g., 3.5 people per room)
  final TextEditingController madinahRoomOccupancyController =
      TextEditingController();
  // NEW: Custom room occupancy input for MAKKAH (e.g., 2.0 people per room)
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
    madinahRoomOccupancyController
        .dispose(); // Dispose the new Madinah controller
    makkahRoomOccupancyController
        .dispose(); // Dispose the new Makkah controller
    super.dispose();
  }

  // Function to clear all input fields and reset results
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
      madinahRoomOccupancyController
          .clear(); // Clear the new Madinah controller
      makkahRoomOccupancyController.clear(); // Clear the new Makkah controller
      resultQuad = "";
      resultTriple = "";
      resultDouble = "";
      pricePerPersonQuad = 0.0;
      pricePerPersonTriple = 0.0;
      pricePerPersonDouble = 0.0;
    });
  }

  // Main calculation function
  void SumR() {
    // Parse input values to numbers, default to 0 if empty/invalid
    double nR1 = double.tryParse(numr1.text) ?? 0; // Visa price SAR
    double nR2 = double.tryParse(numr2.text) ?? 0; // Madinah nights
    double nR3 =
        double.tryParse(numr3.text) ?? 0; // Madinah price per night SAR
    double nR4 = double.tryParse(numr4.text) ?? 0; // Makkah price per night SAR
    double nR5 = double.tryParse(numr5.text) ?? 0; // Makkah nights

    double nD1 = double.tryParse(numd1.text) ?? 0; // Transportation USD
    double nD2 = double.tryParse(numd2.text) ?? 0; // Authority/Fees USD
    double nD3 = double.tryParse(numd3.text) ?? 0; // Gifts USD
    double nD4 = double.tryParse(numd4.text) ?? 0; // Company commission 1 USD
    double nD5 = double.tryParse(numd5.text) ?? 0; // Company commission 2 USD

    // NEW: Parse custom room occupancy for Madinah and Makkah separately
    double madinahRoomOccupancyFactor =
        double.tryParse(madinahRoomOccupancyController.text) ?? 0;
    double makkahRoomOccupancyFactor =
        double.tryParse(makkahRoomOccupancyController.text) ?? 0;

    // Validate room occupancy factors to prevent division by zero or negative values.
    // Default to 1 if 0 or less to allow calculation, or consider showing an error.
    if (madinahRoomOccupancyFactor <= 0) {
      madinahRoomOccupancyFactor = 1;
    }
    if (makkahRoomOccupancyFactor <= 0) {
      makkahRoomOccupancyFactor = 1;
    }

    // Convert SAR visa price to USD (assuming 1 USD = 3.75 SAR)
    double visaPriceInUsd = nR1 / 3.75;

    // Calculate Madinah accommodation cost per person
    double madinahAccommodationCostTotalSAR = nR2 * nR3;
    double madinahAccommodationCostPerPersonUSD =
        (madinahAccommodationCostTotalSAR / 3.75) / madinahRoomOccupancyFactor;

    // Calculate Makkah accommodation cost per person
    double makkahAccommodationCostTotalSAR = nR4 * nR5;
    double makkahAccommodationCostPerPersonUSD =
        (makkahAccommodationCostTotalSAR / 3.75) / makkahRoomOccupancyFactor;

    // Total accommodation cost per person is the sum of Madinah and Makkah per-person costs
    double totalAccommodationCostPerPersonUsd =
        madinahAccommodationCostPerPersonUSD +
        makkahAccommodationCostPerPersonUSD;

    // Calculate total fixed expenses in USD (assuming these are per group/trip fixed costs)
    double totalFixedExpensesPerGroupUsd = nD1 + nD2 + nD3 + nD4 + nD5;

    // Define default values for total occupancy per room type (Quad, Triple, Double)
    // These are used to divide the *total group fixed expenses* (like transportation, fees, etc.)
    // to get the per-person share of those fixed costs.
    int defaultQuadOccupancy = 4;
    int defaultTripleOccupancy = 3;
    int defaultDoubleOccupancy = 2;

    // Calculate total price for each occupancy type:
    // = Total Accommodation Cost Per Person (sum of Madinah & Makkah per-person costs)
    // + Visa Price Per Person
    // + Share of Total Fixed Group Expenses (divided by default room occupancy)

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

    // Round up results to the nearest whole number (as per common pricing practice)
    int roundedPriceQuad = calculatedPriceQuad.ceil();
    int roundedPriceTriple = calculatedPriceTriple.ceil();
    int roundedPriceDouble = calculatedPriceDouble.ceil();

    // Update the UI with the calculated results
    setState(() {
      resultQuad = roundedPriceQuad.toString();
      resultTriple = roundedPriceTriple.toString();
      resultDouble = roundedPriceDouble.toString();
      // Store the double values to pass to ContractPage
      pricePerPersonQuad = roundedPriceQuad.toDouble();
      pricePerPersonTriple = roundedPriceTriple.toDouble();
      pricePerPersonDouble = roundedPriceDouble.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
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
            "حاسبة العمرة", // Page title in Arabic
            style: TextStyle(
              // fontFamily: "Cairo", // Assuming Cairo font is available for Arabic text
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
                              onPressed: () {
                                // Navigate to ContractPage, passing the calculated prices
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ContractPage(
                                      pricePerPersonQuad: pricePerPersonQuad,
                                      pricePerPersonTriple:
                                          pricePerPersonTriple,
                                      pricePerPersonDouble:
                                          pricePerPersonDouble,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.assignment,
                                size: 30,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "إنشاء عقد", // "Create Contract" label in Arabic
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
                                  "عدد الأشخاص الكلي (اختياري)", // Total number of people (optional)
                                  "اترك فارغًا إذا لم تحتاج", // Leave empty if not needed
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
                                  "الأشخاص في غرفة المدينة", // NEW: Madinah room occupancy
                                  "مثال: 3.5", // Hint for Madinah room occupancy
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
                                  "الأشخاص في غرفة مكة", // NEW: Makkah room occupancy
                                  "مثال: 2.0", // Hint for Makkah room occupancy
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
