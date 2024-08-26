import 'package:flutter/material.dart';
import 'package:weavershub/DashBoard/Users/landing-page/my-orders.dart';

import 'market-place.dart';


class NavigationHome extends StatefulWidget {
  const NavigationHome({Key? key}) : super(key: key);

  @override
  State<NavigationHome> createState() => _NavigationHomeState();
}

class _NavigationHomeState extends State<NavigationHome> {
  int currentIndex = 0;
  List<Widget> screens = [

     MarketPlace(),
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