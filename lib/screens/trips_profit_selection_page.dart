import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart'; // لاستخدام FilteringTextInputFormatter

class TripProfitPage extends StatefulWidget {
  const TripProfitPage({super.key});

  @override
  State<TripProfitPage> createState() => _TripProfitPageState();
}

class _TripProfitPageState extends State<TripProfitPage> {
  late Future<List<Map<String, dynamic>>> _tripsListFuture;
  Map<String, dynamic>? _selectedTrip;
  late Future<Map<String, dynamic>> _profitCalculationFuture;

  // حالة لزر "البرنامج مباع"
  bool _isTripSold = false;

  // تعريف متحكمات التكاليف الأساسية (الآن هي تكاليف للفرد الواحد)
  final TextEditingController _transportationCostPerPaxController =
      TextEditingController();
  final TextEditingController _giftCostPerPaxController =
      TextEditingController();
  final TextEditingController _authorityFeesPerPaxUsdController =
      TextEditingController();
  final TextEditingController _companyCommission1PerPaxUsdController =
      TextEditingController();
  final TextEditingController _companyCommission2PerPaxUsdController =
      TextEditingController();
  final TextEditingController _visaPricePerPaxSarController =
      TextEditingController();

  // متحكمات الفنادق (فندق 1 - حالياً هي الموجودة)
  final TextEditingController _madinahHotel1NightsController =
      TextEditingController();
  final TextEditingController _madinahHotel1PricePerNightSarController =
      TextEditingController();
  final TextEditingController _madinahHotel1RoomOccupancyFactorController =
      TextEditingController();
  final TextEditingController _makkahHotel1NightsController =
      TextEditingController();
  final TextEditingController _makkahHotel1PricePerNightSarController =
      TextEditingController();
  final TextEditingController _makkahHotel1RoomOccupancyFactorController =
      TextEditingController();

  // متحكمات الفنادق (فندق 2 - جديدة)
  final TextEditingController _madinahHotel2NightsController =
      TextEditingController();
  final TextEditingController _madinahHotel2PricePerNightSarController =
      TextEditingController();
  final TextEditingController _madinahHotel2RoomOccupancyFactorController =
      TextEditingController();
  final TextEditingController _makkahHotel2NightsController =
      TextEditingController();
  final TextEditingController _makkahHotel2PricePerNightSarController =
      TextEditingController();
  final TextEditingController _makkahHotel2RoomOccupancyFactorController =
      TextEditingController();

  // متحكم سعر الصرف للريال السعودي (قابل للتعديل يدوياً)
  final TextEditingController _sarToUsdRateController = TextEditingController();

  // لعرض العدد الإجمالي للمعتمرين (للقراءة فقط)
  int _totalPax = 0;

  double _totalSalesFromContracts =
      0.0; // إجمالي المبيعات الأصلية من العقود (للقراءة فقط)
  double _totalCalculatedCost = 0.0; // إجمالي التكاليف الكلي
  double _netProfit = 0.0; // صافي الربح

  @override
  void initState() {
    super.initState();
    _tripsListFuture = _fetchTrips();
    _sarToUsdRateController.text = '3.75'; // قيمة افتراضية لسعر الصرف
    _profitCalculationFuture = Future.value({}); // تهيئة أولية
  }

  // دالة لجلب جميع الرحلات من قاعدة البيانات
  Future<List<Map<String, dynamic>>> _fetchTrips() async {
    try {
      final List<Map<String, dynamic>> response = await Supabase.instance.client
          .from('trips')
          .select('*')
          .order('trip_date', ascending: false);

      if (response.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedTrip = response.first;
              _loadTripData(_selectedTrip!);
            });
          }
        });
      }
      return response;
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في جلب الرحلات: ${e.message}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
      return [];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ غير متوقع أثناء جلب الرحلات: ${e.toString()}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
      return [];
    }
  }

  // دالة لتحميل بيانات رحلة محددة في المتحكمات
  void _loadTripData(Map<String, dynamic> tripData) {
    _totalSalesFromContracts = (tripData['trip_total'] is num
        ? tripData['trip_total'].toDouble()
        : double.tryParse(tripData['trip_total']?.toString() ?? '') ?? 0.0);

    _totalPax = (tripData['num_of_pax'] is int
        ? tripData['num_of_pax']
        : int.tryParse(tripData['num_of_pax']?.toString() ?? '') ?? 0);

    _isTripSold = tripData['is_sold'] ?? false;

    // تحميل تكاليف الفرد الواحد
    _transportationCostPerPaxController.text = _parseAndFormatDouble(
      tripData['transportation_cost_per_pax'],
    );
    _giftCostPerPaxController.text = _parseAndFormatDouble(
      tripData['gift_cost_per_pax'],
    );
    _visaPricePerPaxSarController.text = _parseAndFormatDouble(
      tripData['visa_price_per_pax_sar'],
    );
    _authorityFeesPerPaxUsdController.text = _parseAndFormatDouble(
      tripData['authority_fees_per_pax_usd'],
    );
    _companyCommission1PerPaxUsdController.text = _parseAndFormatDouble(
      tripData['company_commission1_per_pax_usd'],
    );
    _companyCommission2PerPaxUsdController.text = _parseAndFormatDouble(
      tripData['company_commission2_per_pax_usd'],
    );

    // تحميل بيانات فندق المدينة 1
    _madinahHotel1NightsController.text = _parseAndFormatInt(
      tripData['madinah_hotel1_nights'],
    );
    _madinahHotel1PricePerNightSarController.text = _parseAndFormatDouble(
      tripData['madinah_hotel1_price_per_night_sar'],
    );
    _madinahHotel1RoomOccupancyFactorController.text = _parseAndFormatDouble(
      tripData['madinah_hotel1_room_occupancy_factor'],
      decimalPlaces: 1,
      defaultValue: 1.0,
    );

    // تحميل بيانات فندق المدينة 2
    _madinahHotel2NightsController.text = _parseAndFormatInt(
      tripData['madinah_hotel2_nights'],
    );
    _madinahHotel2PricePerNightSarController.text = _parseAndFormatDouble(
      tripData['madinah_hotel2_price_per_night_sar'],
    );
    _madinahHotel2RoomOccupancyFactorController.text = _parseAndFormatDouble(
      tripData['madinah_hotel2_room_occupancy_factor'],
      decimalPlaces: 1,
      defaultValue: 1.0,
    );

    // تحميل بيانات فندق مكة 1
    _makkahHotel1NightsController.text = _parseAndFormatInt(
      tripData['makkah_hotel1_nights'],
    );
    _makkahHotel1PricePerNightSarController.text = _parseAndFormatDouble(
      tripData['makkah_hotel1_price_per_night_sar'],
    );
    _makkahHotel1RoomOccupancyFactorController.text = _parseAndFormatDouble(
      tripData['makkah_hotel1_room_occupancy_factor'],
      decimalPlaces: 1,
      defaultValue: 1.0,
    );

    // تحميل بيانات فندق مكة 2
    _makkahHotel2NightsController.text = _parseAndFormatInt(
      tripData['makkah_hotel2_nights'],
    );
    _makkahHotel2PricePerNightSarController.text = _parseAndFormatDouble(
      tripData['makkah_hotel2_price_per_night_sar'],
    );
    _makkahHotel2RoomOccupancyFactorController.text = _parseAndFormatDouble(
      tripData['makkah_hotel2_room_occupancy_factor'],
      decimalPlaces: 1,
      defaultValue: 1.0,
    );

    _sarToUsdRateController.text = _parseAndFormatDouble(
      tripData['sar_to_usd_rate'],
      defaultValue: 3.75,
    );

    setState(() {});
  }

  // دالة مساعدة لتحويل dynamic إلى String مع تنسيق عشري
  String _parseAndFormatDouble(
    dynamic value, {
    int decimalPlaces = 2,
    double defaultValue = 0.0,
  }) {
    if (value == null) {
      return defaultValue.toStringAsFixed(decimalPlaces);
    }
    if (value is num) {
      return value.toDouble().toStringAsFixed(decimalPlaces);
    } else if (value is String) {
      return (double.tryParse(value) ?? defaultValue).toStringAsFixed(
        decimalPlaces,
      );
    }
    return defaultValue.toStringAsFixed(decimalPlaces);
  }

  // دالة مساعدة لتحويل dynamic إلى String مع تنسيق عدد صحيح
  String _parseAndFormatInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) {
      return defaultValue.toString();
    }
    if (value is num) {
      return value.toInt().toString();
    } else if (value is String) {
      return (int.tryParse(value) ?? defaultValue).toString();
    }
    return defaultValue.toString();
  }

  @override
  void dispose() {
    // التخلص من المتحكمات
    _transportationCostPerPaxController.dispose();
    _giftCostPerPaxController.dispose();
    _madinahHotel1NightsController.dispose();
    _madinahHotel1PricePerNightSarController.dispose();
    _madinahHotel1RoomOccupancyFactorController.dispose();
    _makkahHotel1NightsController.dispose();
    _makkahHotel1PricePerNightSarController.dispose();
    _makkahHotel1RoomOccupancyFactorController.dispose();
    _madinahHotel2NightsController.dispose();
    _madinahHotel2PricePerNightSarController.dispose();
    _madinahHotel2RoomOccupancyFactorController.dispose();
    _makkahHotel2NightsController.dispose();
    _makkahHotel2PricePerNightSarController.dispose();
    _makkahHotel2RoomOccupancyFactorController.dispose();
    _visaPricePerPaxSarController.dispose();
    _authorityFeesPerPaxUsdController.dispose();
    _companyCommission1PerPaxUsdController.dispose();
    _companyCommission2PerPaxUsdController.dispose();
    _sarToUsdRateController.dispose();
    super.dispose();
  }

  // دالة لحساب الربح من الرحلة وحفظه في قاعدة البيانات
  Future<Map<String, dynamic>> _calculateTripProfit() async {
    final int? tripId = _selectedTrip?['id'] as int?;
    if (tripId == null || _totalPax == 0) {
      // يجب أن يكون هناك رحلة وعدد معتمرين لحساب التكاليف
      _totalCalculatedCost = 0.0;
      _netProfit = 0.0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'الرجاء اختيار رحلة والتأكد من وجود عدد معتمرين لإجراء الحساب.',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return {
        'total_sales': _totalSalesFromContracts,
        'total_cost': 0.0,
        'net_profit': 0.0,
      };
    }

    try {
      // 1. قراءة سعر الصرف المدخل يدوياً
      double sarToUsdRate =
          double.tryParse(_sarToUsdRateController.text) ?? 3.75;
      if (sarToUsdRate == 0) sarToUsdRate = 3.75; // تجنب القسمة على صفر

      // 2. حساب التكاليف لكل معتمر ثم ضربها في إجمالي عدد المعتمرين
      double transportationCostTotal =
          (double.tryParse(_transportationCostPerPaxController.text) ?? 0.0) *
          _totalPax;
      double giftCostTotal =
          (double.tryParse(_giftCostPerPaxController.text) ?? 0.0) * _totalPax;

      double visaPricePerPaxSar =
          double.tryParse(_visaPricePerPaxSarController.text) ?? 0.0;
      double visaCostTotalUsd = (visaPricePerPaxSar / sarToUsdRate) * _totalPax;

      double authorityFeesTotalUsd =
          (double.tryParse(_authorityFeesPerPaxUsdController.text) ?? 0.0) *
          _totalPax;
      double companyCommission1TotalUsd =
          (double.tryParse(_companyCommission1PerPaxUsdController.text) ??
              0.0) *
          _totalPax;
      double companyCommission2TotalUsd =
          (double.tryParse(_companyCommission2PerPaxUsdController.text) ??
              0.0) *
          _totalPax;

      // 3. حساب تكاليف الفنادق
      double totalHotelCostUsd = 0.0;

      // فندق المدينة 1
      int madinahHotel1Nights =
          int.tryParse(_madinahHotel1NightsController.text) ?? 0;
      double madinahHotel1PricePerNightSar =
          double.tryParse(_madinahHotel1PricePerNightSarController.text) ?? 0.0;
      double madinahHotel1RoomOccupancyFactor =
          double.tryParse(_madinahHotel1RoomOccupancyFactorController.text) ??
          1.0;
      if (madinahHotel1RoomOccupancyFactor == 0)
        madinahHotel1RoomOccupancyFactor = 1.0;
      totalHotelCostUsd +=
          (madinahHotel1Nights *
              madinahHotel1PricePerNightSar /
              madinahHotel1RoomOccupancyFactor /
              sarToUsdRate) *
          _totalPax;

      // فندق المدينة 2
      int madinahHotel2Nights =
          int.tryParse(_madinahHotel2NightsController.text) ?? 0;
      double madinahHotel2PricePerNightSar =
          double.tryParse(_madinahHotel2PricePerNightSarController.text) ?? 0.0;
      double madinahHotel2RoomOccupancyFactor =
          double.tryParse(_madinahHotel2RoomOccupancyFactorController.text) ??
          1.0;
      if (madinahHotel2RoomOccupancyFactor == 0)
        madinahHotel2RoomOccupancyFactor = 1.0;
      totalHotelCostUsd +=
          (madinahHotel2Nights *
              madinahHotel2PricePerNightSar /
              madinahHotel2RoomOccupancyFactor /
              sarToUsdRate) *
          _totalPax;

      // فندق مكة 1
      int makkahHotel1Nights =
          int.tryParse(_makkahHotel1NightsController.text) ?? 0;
      double makkahHotel1PricePerNightSar =
          double.tryParse(_makkahHotel1PricePerNightSarController.text) ?? 0.0;
      double makkahHotel1RoomOccupancyFactor =
          double.tryParse(_makkahHotel1RoomOccupancyFactorController.text) ??
          1.0;
      if (makkahHotel1RoomOccupancyFactor == 0)
        makkahHotel1RoomOccupancyFactor = 1.0;
      totalHotelCostUsd +=
          (makkahHotel1Nights *
              makkahHotel1PricePerNightSar /
              makkahHotel1RoomOccupancyFactor /
              sarToUsdRate) *
          _totalPax;

      // فندق مكة 2
      int makkahHotel2Nights =
          int.tryParse(_makkahHotel2NightsController.text) ?? 0;
      double makkahHotel2PricePerNightSar =
          double.tryParse(_makkahHotel2PricePerNightSarController.text) ?? 0.0;
      double makkahHotel2RoomOccupancyFactor =
          double.tryParse(_makkahHotel2RoomOccupancyFactorController.text) ??
          1.0;
      if (makkahHotel2RoomOccupancyFactor == 0)
        makkahHotel2RoomOccupancyFactor = 1.0;
      totalHotelCostUsd +=
          (makkahHotel2Nights *
              makkahHotel2PricePerNightSar /
              makkahHotel2RoomOccupancyFactor /
              sarToUsdRate) *
          _totalPax;

      // 4. حساب إجمالي التكاليف الكلي
      _totalCalculatedCost =
          transportationCostTotal +
          giftCostTotal +
          visaCostTotalUsd +
          authorityFeesTotalUsd +
          companyCommission1TotalUsd +
          companyCommission2TotalUsd +
          totalHotelCostUsd;

      // 5. حساب صافي الربح
      _netProfit = _totalSalesFromContracts - _totalCalculatedCost;

      // 6. حفظ القيم المحدثة في قاعدة البيانات
      await Supabase.instance.client
          .from('trips')
          .update({
            'total_cost': _totalCalculatedCost,
            'net_profit': _netProfit,
            // حفظ التكاليف للفرد الواحد
            'transportation_cost_per_pax':
                transportationCostTotal / _totalPax, // حفظ القيمة الأصلية للفرد
            'gift_cost_per_pax': giftCostTotal / _totalPax,
            'visa_price_per_pax_sar': visaPricePerPaxSar,
            'authority_fees_per_pax_usd': authorityFeesTotalUsd / _totalPax,
            'company_commission1_per_pax_usd':
                companyCommission1TotalUsd / _totalPax,
            'company_commission2_per_pax_usd':
                companyCommission2TotalUsd / _totalPax,
            // حفظ بيانات الفنادق (فندق 1)
            'madinah_hotel1_nights': madinahHotel1Nights,
            'madinah_hotel1_price_per_night_sar': madinahHotel1PricePerNightSar,
            'madinah_hotel1_room_occupancy_factor':
                madinahHotel1RoomOccupancyFactor,
            'makkah_hotel1_nights': makkahHotel1Nights,
            'makkah_hotel1_price_per_night_sar': makkahHotel1PricePerNightSar,
            'makkah_hotel1_room_occupancy_factor':
                makkahHotel1RoomOccupancyFactor,
            // حفظ بيانات الفنادق (فندق 2)
            'madinah_hotel2_nights': madinahHotel2Nights,
            'madinah_hotel2_price_per_night_sar': madinahHotel2PricePerNightSar,
            'madinah_hotel2_room_occupancy_factor':
                madinahHotel2RoomOccupancyFactor,
            'makkah_hotel2_nights': makkahHotel2Nights,
            'makkah_hotel2_price_per_night_sar': makkahHotel2PricePerNightSar,
            'makkah_hotel2_room_occupancy_factor':
                makkahHotel2RoomOccupancyFactor,
            'sar_to_usd_rate': sarToUsdRate,
          })
          .eq('id', tripId);

      return {
        'total_sales': _totalSalesFromContracts,
        'total_cost': _totalCalculatedCost,
        'net_profit': _netProfit,
      };
    } on PostgrestException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'خطأ في حساب الربح: ${e.message}',
                textDirection: TextDirection.rtl,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
      return {};
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'خطأ غير متوقع: ${e.toString()}',
                textDirection: TextDirection.rtl,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
      return {};
    }
  }

  // دالة لتبديل حالة "مباع" للرحلة
  Future<void> _toggleTripSoldStatus() async {
    final int? tripId = _selectedTrip?['id'] as int?;
    if (tripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء اختيار رحلة أولاً لتبديل حالتها.',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final newStatus = !_isTripSold;
      await Supabase.instance.client
          .from('trips')
          .update({'is_sold': newStatus})
          .eq('id', tripId);

      setState(() {
        _isTripSold = newStatus;
        _selectedTrip!['is_sold'] = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'تم وضع علامة على البرنامج كمباع.'
                : 'تم إلغاء علامة "مباع" من البرنامج.',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: newStatus ? Colors.green : Colors.blueGrey,
        ),
      );
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في تحديث حالة البيع: ${e.message}',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ غير متوقع أثناء تحديث حالة البيع: ${e.toString()}',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ويدجت لبناء خلية جدول مخصصة (للعرض والقراءة فقط)
  Widget _buildTableCell({
    required String label,
    String? value,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.center,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 8.0,
      horizontal: 4.0,
    ),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: textAlign,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
          if (value != null && value.isNotEmpty)
            Text(
              value,
              textAlign: textAlign,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: fontSize * 0.9,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }

  // ويدجت لبناء حقل إدخال بستايل الخلية الجدولية
  Widget _buildTableInputField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.number,
    List<TextInputFormatter>? inputFormatters,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        textDirection: TextDirection.rtl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        style: TextStyle(fontSize: 16, color: textColor),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: labelText,
          hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 8.0,
          ),
          isDense: true,
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003366), // خلفية زرقاء داكنة جداً
      appBar: AppBar(
        title: Text(
          'الربح لرحلة: ${_selectedTrip?['trip_name'] ?? 'الرجاء اختيار رحلة'}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tripsListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'خطأ في جلب الرحلات: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textDirection: TextDirection.rtl,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد رحلات لعرض الأرباح. الرجاء إضافة رحلات أولاً.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textDirection: TextDirection.rtl,
              ),
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // رقم الرحلة (Header)
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 20.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        'رقم الرحلة (${_selectedTrip?['id'] ?? 'غير محدد'})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // جزء اختيار الرحلة (Dropdown)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedTrip,
                      hint: const Text(
                        'اختر رحلة',
                        textDirection: TextDirection.rtl,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey.shade900,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      isExpanded: true,
                      items: snapshot.data!.map((trip) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: trip,
                          child: Text(
                            trip['trip_name']?.toString() ?? 'رحلة غير معروفة',
                            textDirection: TextDirection.rtl,
                          ),
                        );
                      }).toList(),
                      onChanged: (trip) {
                        setState(() {
                          _selectedTrip = trip;
                          if (_selectedTrip != null) {
                            _loadTripData(_selectedTrip!);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // اعرض باقي الواجهة فقط إذا تم اختيار رحلة
                  if (_selectedTrip != null) ...[
                    // عرض إجمالي المبيعات من العقود (للقراءة فقط)
                    Card(
                      color: Colors.green.shade100,
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'إجمالي المبيعات من العقود (USD):',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            Text(
                              '\$${_totalSalesFromContracts.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // لوحة إيرادات ومصروفات تفصيلية
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // عمود "أسعار بالدولار" (على اليمين في التصميم العربي)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade300,
                                  ),
                                ),
                                child: Text(
                                  'أسعار بالدولار (لكل معتمر)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Table(
                                border: TableBorder.all(
                                  color: Colors.blue.shade300,
                                  width: 0.8,
                                ),
                                columnWidths: const {0: FlexColumnWidth(1)},
                                children: [
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _transportationCostPerPaxController,
                                        labelText: 'سعر النقل (للفرد)',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _authorityFeesPerPaxUsdController,
                                        labelText: 'سعر الهيئة (للفرد)',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller: _giftCostPerPaxController,
                                        labelText: 'سعر الهدايا (للفرد)',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _companyCommission1PerPaxUsdController,
                                        labelText: 'عمولة الشركة 1 (للفرد)',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _companyCommission2PerPaxUsdController,
                                        labelText: 'عمولة الشركة 2 (للفرد)',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableCell(
                                        label: 'العدد الإجمالي للمعتمرين',
                                        value: _totalPax.toString(),
                                        backgroundColor: Colors.blue.shade50,
                                        textColor: Colors.blueGrey.shade800,
                                        fontWeight: FontWeight.bold,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 8.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller: _sarToUsdRateController,
                                        labelText: '1 USD = SAR (سعر الصرف)',
                                        backgroundColor:
                                            Colors.lightBlue.shade50,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20), // مسافة بين الأعمدة
                        // عمود "أسعار بالريال" (على اليسار في التصميم العربي)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                  ),
                                ),
                                child: Text(
                                  'أسعار بالريال (للفرد والغرف)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Table(
                                border: TableBorder.all(
                                  color: Colors.green.shade300,
                                  width: 0.8,
                                ),
                                columnWidths: const {0: FlexColumnWidth(1)},
                                children: [
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _visaPricePerPaxSarController,
                                        labelText: 'سعر الفيزا (للفرد)',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  // فندق المدينة 1
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _madinahHotel1NightsController,
                                        labelText: 'عدد ليالي المدينة 1',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _madinahHotel1PricePerNightSarController,
                                        labelText: 'سعر المدينة لليلة 1',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _madinahHotel1RoomOccupancyFactorController,
                                        labelText: 'عامل إشغال غرفة المدينة 1',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  // فندق المدينة 2 (جديد)
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _madinahHotel2NightsController,
                                        labelText: 'عدد ليالي المدينة 2',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _madinahHotel2PricePerNightSarController,
                                        labelText: 'سعر المدينة لليلة 2',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _madinahHotel2RoomOccupancyFactorController,
                                        labelText: 'عامل إشغال غرفة المدينة 2',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  // فندق مكة 1
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _makkahHotel1NightsController,
                                        labelText: 'عدد ليالي مكة 1',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _makkahHotel1PricePerNightSarController,
                                        labelText: 'سعر مكة لليلة 1',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _makkahHotel1RoomOccupancyFactorController,
                                        labelText: 'عامل إشغال غرفة مكة 1',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  // فندق مكة 2 (جديد)
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _makkahHotel2NightsController,
                                        labelText: 'عدد ليالي مكة 2',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _makkahHotel2PricePerNightSarController,
                                        labelText: 'سعر مكة لليلة 2',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableInputField(
                                        controller:
                                            _makkahHotel2RoomOccupancyFactorController,
                                        labelText: 'عامل إشغال غرفة مكة 2',
                                        backgroundColor: Colors.white,
                                        textColor: Colors.blueGrey.shade800,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // زر حساب صافي الربح
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _profitCalculationFuture = _calculateTripProfit();
                        });
                      },
                      icon: const Icon(Icons.calculate, color: Colors.white),
                      label: const Text(
                        'حساب صافي الربح',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE), // لون بنفسجي
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 20), // مسافة بين الأزرار
                    // زر "البرنامج مباع" / "إلغاء بيع البرنامج"
                    ElevatedButton.icon(
                      onPressed: _toggleTripSoldStatus,
                      icon: Icon(
                        _isTripSold
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isTripSold
                            ? 'البرنامج مباع (انقر للإلغاء)'
                            : 'وضع علامة على البرنامج كمباع',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTripSold
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // عرض إجمالي المبيعات والتكاليف وصافي الربح
                    FutureBuilder<Map<String, dynamic>>(
                      future: _profitCalculationFuture,
                      builder: (context, profitSnapshot) {
                        if (profitSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (profitSnapshot.hasError) {
                          return Center(
                            child: Text(
                              'خطأ في حساب الربح: ${profitSnapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        } else {
                          final sales = (_totalSalesFromContracts)
                              .toStringAsFixed(
                                2,
                              ); // يعرض قيمة المبيعات التي تم تحميلها
                          final cost = (_totalCalculatedCost).toStringAsFixed(
                            2,
                          );
                          final profit = (_netProfit).toStringAsFixed(2);

                          return Card(
                            color: Colors.lightBlue.shade100,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'إجمالي المبيعات من العقود: \$$sales',
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'إجمالي التكاليف الكلي: \$$cost',
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  const Divider(
                                    height: 30,
                                    thickness: 2,
                                    color: Colors.blueGrey,
                                  ),
                                  Text(
                                    'صافي الربح: \$$profit',
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: double.tryParse(profit)! >= 0
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
