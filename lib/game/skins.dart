import 'package:flutter/material.dart';

/// A batik color theme for the blocks. Unlocked with coins; the selected skin's
/// palette drives piece generation (see CoreColors.active).
class Skin {
  final String id;
  final String name;
  final String desc;
  final int cost; // coins; 0 = free/owned by default
  final List<Color> colors;

  const Skin({
    required this.id,
    required this.name,
    required this.desc,
    required this.cost,
    required this.colors,
  });
}

class SkinCatalog {
  SkinCatalog._();

  static const List<Skin> all = <Skin>[
    Skin(
      id: 'klasik',
      name: 'Klasik Sogan',
      desc: 'Warna batik klasik — cokelat sogan & indigo.',
      cost: 0,
      colors: [
        Color(0xFF7A3B2E), Color(0xFF1F4E5F), Color(0xFFB5832E),
        Color(0xFF4A6B3A), Color(0xFF6E3B5C), Color(0xFF2E5E6E), Color(0xFFA84B2A),
      ],
    ),
    Skin(
      id: 'pesisir',
      name: 'Pesisir',
      desc: 'Biru laut & toska pesisir utara.',
      cost: 60,
      colors: [
        Color(0xFF1F4E5F), Color(0xFF2E5E6E), Color(0xFF3B7C8C), Color(0xFF246A5B),
        Color(0xFF4C8FA6), Color(0xFF1C6E7A), Color(0xFF5BA3B8),
      ],
    ),
    Skin(
      id: 'keraton',
      name: 'Keraton',
      desc: 'Emas & marun mewah ala keraton.',
      cost: 150,
      colors: [
        Color(0xFFB5832E), Color(0xFF7A2E2E), Color(0xFFD4AF37), Color(0xFF8A5A1E),
        Color(0xFF5C2A2A), Color(0xFFC8923A), Color(0xFF9C6B2A),
      ],
    ),
    Skin(
      id: 'rimba',
      name: 'Rimba',
      desc: 'Hijau dedaunan & tanah Nusantara.',
      cost: 300,
      colors: [
        Color(0xFF4A6B3A), Color(0xFF3A5230), Color(0xFF6E8B4A), Color(0xFF8A6B2E),
        Color(0xFF2F5E3A), Color(0xFF5C7A3A), Color(0xFF7A5A2E),
      ],
    ),
    Skin(
      id: 'megamendung',
      name: 'Mega Mendung',
      desc: 'Awan biru Cirebon yang berlapis.',
      cost: 400,
      colors: [
        Color(0xFF1E5A8A), Color(0xFF2E7AB0), Color(0xFF14406A), Color(0xFF49A6D6),
        Color(0xFF0E2E50), Color(0xFF3A8FC4), Color(0xFF6CC3E8),
      ],
    ),
    Skin(
      id: 'truntum',
      name: 'Truntum',
      desc: 'Taburan bintang emas di langit nila.',
      cost: 500,
      colors: [
        Color(0xFFD9A636), Color(0xFFB8860B), Color(0xFFF2C75B), Color(0xFF5C4A8A),
        Color(0xFF8A6E2E), Color(0xFFE0B84E), Color(0xFF3E3268),
      ],
    ),
    Skin(
      id: 'senja',
      name: 'Senja Nusantara',
      desc: 'Gradasi hangat matahari terbenam.',
      cost: 650,
      colors: [
        Color(0xFFE8643C), Color(0xFFD23E5A), Color(0xFFF2913C), Color(0xFFB02E6A),
        Color(0xFFC0492E), Color(0xFFF2B14A), Color(0xFF8A2E5A),
      ],
    ),
  ];

  static Skin byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
