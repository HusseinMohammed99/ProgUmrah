import 'package:flutter/material.dart';
import 'package:umrah/screens/contracts_page.dart';
import 'package:umrah/screens/home_page.dart';
import 'package:umrah/screens/trips_page.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  int _selectedIndex = 0;
  final bool _isExtended = false;
  final List<Widget> _pages = const [
    HomePage(),
    TripsPage(),
    ContractPage(
      pricePerPersonQuad: 50,
      pricePerPersonTriple: 50,
      pricePerPersonDouble: 50,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
              },
              labelType: NavigationRailLabelType
                  .all, // Show labels for all destinations
              extended: _isExtended, // Control extension

              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.airplane_ticket_outlined),
                  selectedIcon: Icon(Icons.airplane_ticket),
                  label: Text('Trips'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.file_copy_outlined),
                  selectedIcon: Icon(Icons.file_copy),
                  label: Text('ContractsPage'),
                ),
              ],
            ),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),
    );
  }
}
