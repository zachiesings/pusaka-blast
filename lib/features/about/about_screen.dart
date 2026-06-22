import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/batik.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang')),
      body: BatikBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: const [
              Text('Pusaka Blast',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Palette.cream)),
              SizedBox(height: 8),
              Text('Teka-teki balok 8×8 dengan motif batik Nusantara. '
                  'Susun balok, bersihkan baris & kolom, kejar skor tertinggi.',
                  style: TextStyle(color: Palette.goldSoft, height: 1.5)),
              SizedBox(height: 24),
              Text('Privasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Palette.cream)),
              SizedBox(height: 8),
              Text('Game ini menampilkan iklan (AdMob) yang bersifat non-personalisasi. '
                  'Skor dan koin disimpan hanya di perangkatmu.',
                  style: TextStyle(color: Palette.goldSoft, height: 1.5)),
              SizedBox(height: 24),
              Text('Versi 1.0.0', style: TextStyle(color: Palette.gold)),
            ],
          ),
        ),
      ),
    );
  }
}
