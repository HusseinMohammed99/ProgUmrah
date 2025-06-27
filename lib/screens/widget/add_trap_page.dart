import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for FilteringTextInputFormatter
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

class AddTrapPage extends StatefulWidget {
  const AddTrapPage({super.key});

  @override
  State<AddTrapPage> createState() => _AddTrapPageState();
}

class _AddTrapPageState extends State<AddTrapPage> {
  // --- Controllers for text input fields ---
  final TextEditingController _tripNameController = TextEditingController();
  final TextEditingController _tripDateController = TextEditingController();
  final TextEditingController _tripPriceController = TextEditingController();
  final TextEditingController _tripDescriptionController =
      TextEditingController();
  final TextEditingController _tripTypeController = TextEditingController();
  final TextEditingController _tripStatusController = TextEditingController();
  final TextEditingController _tripDurationController = TextEditingController();

  // --- Selected date variable ---
  DateTime? _selectedDate;

  @override
  void dispose() {
    // Dispose of all controllers to prevent memory leaks
    _tripNameController.dispose();
    _tripDateController.dispose();
    _tripPriceController.dispose();
    _tripDescriptionController.dispose();
    _tripTypeController.dispose();
    _tripStatusController.dispose();
    _tripDurationController.dispose();
    super.dispose();
  }

  // --- Function to select a date using a DatePicker ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now(), // Start with today's date if none selected
      firstDate: DateTime(2000), // Earliest selectable date
      lastDate: DateTime(2101), // Latest selectable date
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Format the date to YYYY-MM-DD (ISO 8601 standard) for database compatibility
        _tripDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // --- Function to save trip data to Supabase ---
  Future<void> _saveTripData() async {
    // Basic validation: ensure trip name is not empty
    if (_tripNameController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'الرجاء إدخال اسم الرحلة.',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
      return;
    }

    try {
      // Prepare data for insertion with CORRECT Supabase column names
      final Map<String, dynamic> tripData = {
        'trip_name': _tripNameController.text,
        'trip_date': _tripDateController.text.isEmpty
            ? null
            : _tripDateController.text,
        'trip_total': double.tryParse(_tripPriceController.text),
        'trip_note': _tripDescriptionController.text.isEmpty
            ? null
            : _tripDescriptionController.text,
        'type_trip': _tripTypeController.text.isEmpty
            ? null
            : _tripTypeController.text,
        'case_trip': _tripStatusController.text.isEmpty
            ? null
            : _tripStatusController.text,
        'trip_time': int.tryParse(_tripDurationController.text),
      };

      // Perform the insert operation
      // .select() returns the inserted data or throws an error on failure
      final List<Map<String, dynamic>> response = await Supabase.instance.client
          .from('trips')
          .insert(tripData)
          .select(); // Use .select() to get the inserted data (optional, but good for confirmation)

      if (mounted) {
        // If no exception was thrown, the insertion was successful
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حفظ الرحلة بنجاح!',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        // Clear controllers after successful insertion
        _tripNameController.clear();
        _tripDateController.clear();
        _tripPriceController.clear();
        _tripDescriptionController.clear();
        _tripTypeController.clear();
        _tripStatusController.clear();
        _tripDurationController.clear();
        _selectedDate = null; // Clear selected date as well
      }
    } on PostgrestException catch (e) {
      // Handles specific Supabase database errors (e.g., constraint violations, RLS issues)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في قاعدة البيانات: ${e.message}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        print('Supabase Postgrest Error: ${e.message}'); // Log for debugging
      }
    } catch (e) {
      // Handles any other unexpected errors during the process
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ غير متوقع عند حفظ الرحلة: ${e.toString()}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        print('General Save Error: ${e.toString()}'); // Log for debugging
      }
    }
  }

  // --- Helper widget to build custom text fields with improved styling ---
  Widget _buildCustomTextField(
    TextEditingController controller,
    String labelText,
    String hintText,
    TextInputType keyboardType, {
    int maxLines = 1, // Default to single line, can be overridden
    List<TextInputFormatter>? inputFormatters, // Optional formatters
    VoidCallback? onTap, // Optional tap callback (e.g., for date picker)
    bool readOnly = false, // Optional read-only state (e.g., for date picker)
  }) {
    return TextField(
      controller: controller,
      textDirection:
          TextDirection.rtl, // Text direction right-to-left for input
      keyboardType: keyboardType, // Numeric keyboard for number inputs
      maxLines: maxLines, // Set max lines for multiline input
      inputFormatters: inputFormatters, // Apply provided formatters
      onTap: onTap, // Set the onTap callback
      readOnly: readOnly, // Set read-only state
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة رحلة جديدة'),
        backgroundColor: Colors.indigo.shade700, // Consistent AppBar color
        foregroundColor: Colors.white, // Set icon and text color to white
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Consistent padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Trip Name Field
            _buildCustomTextField(
              _tripNameController,
              'اسم الرحلة',
              'مثلا رحلة شوال',
              TextInputType.text,
            ),

            const SizedBox(height: 16),

            // Trip Date Field (with DatePicker)
            _buildCustomTextField(
              _tripDateController,
              'تاريخ الرحلة',
              'اختر تاريخ الرحلة',
              TextInputType.datetime,
              readOnly: true, // Make it read-only as date is picked
              onTap: () => _selectDate(context), // Open date picker on tap
            ),

            const SizedBox(height: 16),

            // Trip Price Field
            _buildCustomTextField(
              _tripPriceController,
              'سعر الرحلة',
              'مثلا 1500',
              TextInputType.number,
              inputFormatters: [
                // Allow only numbers (integers or decimals)
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),

            // Trip Description Field
            _buildCustomTextField(
              _tripDescriptionController,
              'وصف الرحلة',
              'أدخل تفاصيل إضافية عن الرحلة',
              TextInputType.multiline,
              maxLines: 3, // Allow multiple lines for description
            ),
            const SizedBox(height: 16),

            // Trip Type Field
            _buildCustomTextField(
              _tripTypeController,
              'نوع الرحلة',
              'مثلا عمرة، حج، زيارة',
              TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Trip Status Field
            _buildCustomTextField(
              _tripStatusController,
              'حالة الرحلة',
              'مثلا متاحة، ممتلئة، ملغاة',
              TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Trip Duration Field
            _buildCustomTextField(
              _tripDurationController,
              'مدة الرحلة (بالأيام)',
              'مثلا 10',
              TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter
                    .digitsOnly, // Allow only digits for duration
              ],
            ),
            const SizedBox(height: 24), // More space before button
            // Save Button
            ElevatedButton(
              onPressed: _saveTripData, // Call the new save function
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.deepPurple.shade400, // Attractive button color
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ), // Increased vertical padding
                textStyle: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ), // Larger, bold text
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ), // Rounded button corners
                ),
                elevation: 5, // Add shadow for depth
              ),
              child: const Text(
                'حفظ',
                style: TextStyle(color: Colors.white),
              ), // Ensure text color is white
            ),
          ],
        ),
      ),
    );
  }
}
