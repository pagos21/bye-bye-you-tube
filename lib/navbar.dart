import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:u_down2/home.dart';
import 'package:u_down2/preferiti.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _selectedMenu = 0;
  final List<Widget> _menuPages = [Principale(), Preferiti()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: GNav(
        rippleColor: Colors.tealAccent,
        hoverColor: Colors.teal,
        haptic: true,
        tabBorderRadius: 10,
        curve: Curves.easeInExpo,
        duration: Duration(milliseconds: 500),
        gap: 8,
        color: Colors.white38,
        activeColor: Colors.tealAccent,
        iconSize: 24,
        backgroundColor: Colors.black87,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        tabMargin: EdgeInsetsGeometry.only(bottom: 10),
        padding: EdgeInsetsGeometry.symmetric(horizontal: 25, vertical: 20),

        onTabChange: (i) {
          setState(() {
            _selectedMenu = i;
          });
        },
        tabs: [
          GButton(icon: Icons.home, text: "Home"),
          GButton(icon: Icons.favorite, text: "Preferiti"),
        ],
      ),
      body: _menuPages[_selectedMenu],
    );
  }
}
