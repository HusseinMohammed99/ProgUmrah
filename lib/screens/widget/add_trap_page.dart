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
  final TextEditingController _tripDescriptionController =
      TextEditingController();
  final TextEditingController _tripTypeController = TextEditingController();
  final TextEditingController _tripStatusController = TextEditingController();
  final TextEditingController _madinaNightsController =
      TextEditingController(); // متحكم لعدد ليالي المدينة
  final TextEditingController _makkahNightsController =
      TextEditingController(); // متحكم لعدد ليالي مكة
  final TextEditingController _tripDurationController =
      TextEditingController(); // متحكم لمدة الرحلة الإجمالية (مجموع الليالي)

  // --- Selected date variable ---
  DateTime? _selectedDate;

  // --- Calculated total nights ---
  int _totalNights = 0; // متغير لتخزين مجموع الليالي المحسوب

  @override
  void initState() {
    super.initState();
    // إضافة مستمعين للتغيرات في حقلي ليالي المدينة ومكة
    // عند أي تغيير، يتم استدعاء دالة _calculateTotalNights
    _madinaNightsController.addListener(_calculateTotalNights);
    _makkahNightsController.addListener(_calculateTotalNights);
  }

  // دالة لحساب مجموع الليالي وتحديث حقل مدة الرحلة في الواجهة
  void _calculateTotalNights() {
    final int madinaNights = int.tryParse(_madinaNightsController.text) ?? 0;
    final int makkahNights = int.tryParse(_makkahNightsController.text) ?? 0;

    final int newTotalNights = madinaNights + makkahNights;

    // تحديث الحالة فقط إذا كانت القيمة قد تغيرت لتجنب إعادة بناء غير ضرورية
    if (newTotalNights != _totalNights) {
      setState(() {
        _totalNights = newTotalNights;
        _tripDurationController.text = _totalNights
            .toString(); // تحديث حقل مدة الرحلة في الواجهة
        // print('Total Nights Calculated: $_totalNights'); // للتشخيص
      });
    }
  }

  @override
  void dispose() {
    // إزالة المستمعين والتخلص من جميع المتحكمات لتجنب تسرب الذاكرة
    _tripNameController.dispose();
    _tripDateController.dispose();
    _tripDescriptionController.dispose();
    _tripTypeController.dispose();
    _tripStatusController.dispose();
    // إزالة المستمعين قبل التخلص من المتحكمات المرتبطة بهم
    _madinaNightsController.removeListener(_calculateTotalNights);
    _makkahNightsController.removeListener(_calculateTotalNights);
    _madinaNightsController.dispose();
    _makkahNightsController.dispose();
    _tripDurationController.dispose();
    super.dispose();
  }

  // دالة لاختيار تاريخ باستخدام DatePicker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // تنسيق التاريخ إلى YYYY-MM-DD
        _tripDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // دالة لحفظ بيانات الرحلة إلى Supabase
  Future<void> _saveTripData() async {
    // التحقق الأساسي: التأكد من أن اسم الرحلة ليس فارغاً
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
      // إعداد البيانات للإدراج في Supabase باستخدام أسماء الأعمدة الصحيحة
      final Map<String, dynamic> tripData = {
        'trip_name': _tripNameController.text,
        'trip_date': _tripDateController.text.isEmpty
            ? null
            : _tripDateController.text,
        'trip_total': 0.0, // سيتم تحديث هذا لاحقًا بواسطة مجموع العقود المرتبطة
        'trip_note': _tripDescriptionController.text.isEmpty
            ? null
            : _tripDescriptionController.text,
        'type_trip': _tripTypeController.text.isEmpty
            ? null
            : _tripTypeController.text,
        'case_trip': _tripStatusController.text.isEmpty
            ? null
            : _tripStatusController.text,
        'trip_time': _totalNights, // حفظ مجموع الليالي المحسوب هنا
        'madinah_nights':
            int.tryParse(_madinaNightsController.text) ??
            0, // حفظ ليالي المدينة بشكل منفصل
        'makkah_nights':
            int.tryParse(_makkahNightsController.text) ??
            0, // حفظ ليالي مكة بشكل منفصل
      };

      // إجراء عملية الإدراج في جدول 'trips'
      await Supabase.instance.client
          .from('trips')
          .insert(tripData)
          .select(); // استخدام .select() للحصول على البيانات المدرجة (اختياري)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حفظ الرحلة بنجاح!',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        // مسح المتحكمات بعد الحفظ بنجاح
        _tripNameController.clear();
        _tripDateController.clear();
        _tripDescriptionController.clear();
        _tripTypeController.clear();
        _tripStatusController.clear();
        _madinaNightsController.clear();
        _makkahNightsController.clear();
        _tripDurationController.clear(); // مسح حقل المدة أيضاً
        _selectedDate = null; // مسح التاريخ المحدد
        setState(() {
          _totalNights = 0; // إعادة تعيين مجموع الليالي المحسوب
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في قاعدة البيانات: ${e.message}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        // print('Supabase Postgrest Error: ${e.message}'); // يمكنك تفعيل هذا للتشخيص
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ غير متوقع عند حفظ الرحلة: ${e.toString()}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        // print('General Save Error: ${e.toString()}'); // يمكنك تفعيل هذا للتشخيص
      }
    }
  }

  // دالة مساعدة لبناء حقول إدخال نصية مخصصة بتحسينات في التصميم
  Widget _buildCustomTextField(
    TextEditingController controller,
    String labelText,
    String hintText,
    TextInputType keyboardType, {
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      textDirection: TextDirection.rtl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      onTap: onTap,
      readOnly: readOnly,
      style: TextStyle(fontSize: 20, color: Colors.blueGrey.shade900),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontSize: 18,
          color: Colors.blueGrey.shade600,
          fontWeight: FontWeight.w600,
        ),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 16),
        hintTextDirection: TextDirection.rtl,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة رحلة جديدة'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // حقل اسم الرحلة
            _buildCustomTextField(
              _tripNameController,
              'اسم الرحلة',
              'مثلا رحلة شوال',
              TextInputType.text,
            ),

            const SizedBox(height: 16),

            // حقل تاريخ الرحلة (مع منتقي التاريخ)
            _buildCustomTextField(
              _tripDateController,
              'تاريخ الرحلة',
              'اختر تاريخ الرحلة',
              TextInputType.datetime,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),

            const SizedBox(height: 16),

            // حقل وصف الرحلة
            _buildCustomTextField(
              _tripDescriptionController,
              'وصف الرحلة',
              'أدخل تفاصيل إضافية عن الرحلة',
              TextInputType.multiline,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // حقل نوع الرحلة
            _buildCustomTextField(
              _tripTypeController,
              'نوع الرحلة',
              'مثلا عمرة، حج، زيارة',
              TextInputType.text,
            ),
            const SizedBox(height: 16),

            // حقل حالة الرحلة
            _buildCustomTextField(
              _tripStatusController,
              'حالة الرحلة',
              'مثلا متاحة، ممتلئة، ملغاة',
              TextInputType.text,
            ),
            const SizedBox(height: 16),

            // حقل ليالي المدينة
            _buildCustomTextField(
              _madinaNightsController,
              'عدد ليالي المدينة',
              'مثلا 2',
              TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // حقل ليالي مكة
            _buildCustomTextField(
              _makkahNightsController,
              'عدد ليالي مكة',
              'مثلا 2',
              TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // حقل مدة الرحلة (سيعرض مجموع الليالي المحسوب)
            _buildCustomTextField(
              _tripDurationController,
              'مدة الرحلة (بالأيام - مجموع الليالي)',
              '${_totalNights}', // يعرض القيمة المحسوبة
              TextInputType.number,
              readOnly: true, // يجعل هذا الحقل للقراءة فقط
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),

            // زر الحفظ
            ElevatedButton(
              onPressed: _saveTripData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade400,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
