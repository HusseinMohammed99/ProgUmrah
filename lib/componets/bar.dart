import 'package:flutter/material.dart';
import 'package:umrah/screens/all_contracts_page.dart'; // استيراد صفحة كافة العقود
import 'package:umrah/screens/home_page.dart';
import 'package:umrah/screens/trips_profit_selection_page.dart'; // استيراد صفحة ربح الرحلة
import 'package:umrah/screens/trips_page.dart';
// لا نحتاج لاستيراد TripProfitPage هنا مباشرة

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  int _selectedIndex = 0;
  final bool _isExtended =
      false; // يمكنك التحكم في هذا المتغير لجعل الشريط الجانبي ممتدًا أو لا

  // قائمة الصفحات.
  // تم التأكد من أن AllContractsPage متاح هنا للعرض المباشر.
  final List<Widget> _pages = const [
    HomePage(),
    TripsPage(),
    AllContractsPage(), // الآن يمكن عرضها مباشرة
    TripProfitPage(), // ✅ تصحيح: هنا نضيف صفحة اختيار الرحلة لعرض الأرباح
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // إزالة debug banner
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              groupAlignment: -1.0, // Align items to the top
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
                // ✅ تم إزالة منطق إعادة التوجيه
                // الآن عند اختيار "العقود" (index 2)، سيتم عرض AllContractsPage مباشرة
              },
              labelType: NavigationRailLabelType
                  .all, // Show labels for all destinations
              extended: _isExtended, // Control extension
              backgroundColor: Colors.indigo.shade800, // لون خلفية شريط التنقل
              selectedIconTheme: const IconThemeData(
                color: Colors.white,
                size: 30,
              ), // أيقونة مختارة بيضاء أكبر
              unselectedIconTheme: IconThemeData(
                color: Colors.blue.shade200,
                size: 24,
              ), // أيقونة غير مختارة
              selectedLabelTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ), // نص مختار
              unselectedLabelTextStyle: TextStyle(
                color: Colors.blue.shade100,
                fontSize: 14,
              ), // نص غير مختار
              indicatorColor: Colors.deepPurple.shade400, // لون المؤشر
              elevation: 8, // ظل لشريط التنقل
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('الرئيسية', textDirection: TextDirection.rtl),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.airplane_ticket_outlined),
                  selectedIcon: Icon(Icons.airplane_ticket),
                  label: Text('الرحلات', textDirection: TextDirection.rtl),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.file_copy_outlined),
                  selectedIcon: Icon(Icons.file_copy),
                  label: Text('العقود', textDirection: TextDirection.rtl),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: Text('تقرير رحلة', textDirection: TextDirection.rtl),
                ),
              ],
            ),
            Expanded(
              // عرض الصفحة المحددة
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}
