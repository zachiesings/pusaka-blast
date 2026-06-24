import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/batik.dart';
import '../../widgets/mascot.dart';
import '../../widgets/blast_mascot.dart';
import '../../widgets/soft_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang')),
      body: BatikBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              const Center(child: BlastMascot(size: 110, mood: MascotMood.happy)),
              const SizedBox(height: 8),
              const Center(child: GoldTitle('PUSAKA BLAST', size: 28, letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Center(
                child: Text('Versi 1.0.0',
                    style: TextStyle(color: Palette.cream.withOpacity(0.5), letterSpacing: 1)),
              ),
              const SizedBox(height: 20),
              SoftCard(
                glow: Palette.gold,
                child: Text(
                    'Tata balok berukir batik di lantai pendopo emas. Lengkapi baris & '
                    'kolom untuk menyelesaikan motif, kumpulkan Berkah Keraton, dan kejar '
                    'skor tertinggi — diiringi gamelan orisinal & latar yang hidup.',
                    style: TextStyle(color: Palette.cream.withOpacity(0.78), height: 1.5)),
              ),
              const SizedBox(height: 14),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: const [
                      Icon(Icons.auto_awesome, color: Palette.gold, size: 20),
                      SizedBox(width: 8),
                      Text('Fitur',
                          style: TextStyle(
                              color: Palette.cream, fontSize: 16, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 8),
                    for (final f in const [
                      'Berkah Keraton — pembersihan beruntun skor ×2',
                      'Power-up: Palu, Bom 3×3, Acak',
                      'Mode Klasik & Time Attack',
                      'Toko Batik, Hadiah Harian, Pencapaian',
                      'Gamelan & efek suara orisinal, latar beranimasi',
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(Icons.check_circle, color: Palette.jade, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(f,
                                style: TextStyle(color: Palette.cream.withOpacity(0.7), height: 1.4)),
                          ),
                        ]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: const [
                      Icon(Icons.shield_rounded, color: Palette.gold, size: 20),
                      SizedBox(width: 8),
                      Text('Privasi',
                          style: TextStyle(
                              color: Palette.cream, fontSize: 16, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        'Iklan (AdMob) non-personalisasi. Skor & koin disimpan hanya di '
                        'perangkatmu. Tidak ada pelacakan lintas-aplikasi.',
                        style: TextStyle(color: Palette.cream.withOpacity(0.65), height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
