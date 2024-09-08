import 'package:flutter/material.dart';

import '../../../dashBoard/users/landingPage/my_orders.dart';
import 'market_place.dart';


class NavigationHome extends StatefulWidget {
  const NavigationHome({super.key});

  @override
  State<NavigationHome> createState() => _NavigationHomeState();
}

class _NavigationHomeState extends State<NavigationHome> {
  int currentIndex = 0;

  List<Widget> screens = [
    const MarketPlace(),
    const MyOrders(),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
          boxShadow: [
            BoxShadow(color: Colors.black38, spreadRadius: 0, blurRadius: 5),
          ],
        ),
        child: BottomNavigationBar(
          selectedItemColor: Colors.green,
          iconSize: 20,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: const [

            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Market place',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.ac_unit),
              label: 'My orders',
            ),
          ],
        ),
      ),
    );
  }
}