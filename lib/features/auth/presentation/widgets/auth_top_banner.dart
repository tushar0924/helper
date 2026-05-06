import 'package:flutter/material.dart';

class AuthTopBanner extends StatelessWidget {
  const AuthTopBanner({
    super.key,
    this.title = 'Bookus',
    this.subtitle = 'Welcome!',
    this.imageAssetPath = 'assets/images/login.png',
    this.height = 340,
  });

  final String title;
  final String subtitle;
  final String imageAssetPath;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2A47), Color(0xFF0C223B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 50,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 27, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(imageAssetPath, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
