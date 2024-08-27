import 'package:flutter/material.dart';

class Loginpage extends StatelessWidget {
  const Loginpage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: const LoginScreen(),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity, // Container genişliği sayfanın tamamını kaplayacak
            decoration: BoxDecoration(
              color: const Color(0xFF162dd4), // Arka plan rengi
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(70),
                bottomRight: Radius.circular(70),
              ),
            ),
            padding: const EdgeInsets.all(40),
            child: Align(
              alignment: Alignment.bottomCenter, // Alt ortada hizalama
              child: Transform.translate(
                offset: Offset(0, 100), // Logo container'ını yukarı taşıma
                child: Container(
                  padding: const EdgeInsets.all(10.0), // Logo etrafında padding
                  decoration: BoxDecoration(
                    color: Colors.white, // Logo etrafında beyaz arka plan
                    borderRadius: BorderRadius.circular(10.0), // Border radius
                  ),
                  child: Image(
                    image: AssetImage('images/aif-logo.jpg'), // Logo
                    width: 100,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email),
                    hintText: 'E-Posta',
                    hintStyle: TextStyle(
                      color: Colors.grey, // Hint yazısı rengi
                      fontWeight: FontWeight.w300, // İnce yazı
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    hintText: 'Şifre',
                    hintStyle: TextStyle(
                      color: Colors.grey, // Hint yazısı rengi
                      fontWeight: FontWeight.w300, // İnce yazı
                    ),
                    suffixIcon: const Icon(Icons.visibility_off),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (value) {},
                      activeColor: const Color(0xFF162dd4), // Beni Hatırla checkbox'ın rengi
                    ),
                    const Text('Beni Hatırla'),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Şifremi Unuttum'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD), // Buton rengini değiştirdik
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Buton köşeleri yuvarlatıldı
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Giriş',
                    style: TextStyle(color: Colors.white), // Buton yazı rengi beyaz
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Image.asset('images/google-logo.png', width: 24), // Google logosu
                  label: const Text('Google ile Giriş Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Buton köşeleri yuvarlatıldı
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Image.asset('images/microsoft-logo.png', width: 24), // Microsoft logosu
                  label: const Text('Microsoft ile Giriş Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Buton köşeleri yuvarlatıldı
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
