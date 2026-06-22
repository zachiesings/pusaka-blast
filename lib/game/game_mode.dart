/// Blast play modes.
enum BlastMode { klasik, timeAttack }

extension BlastModeX on BlastMode {
  String get label => this == BlastMode.klasik ? 'Klasik' : 'Time Attack';
  String get desc =>
      this == BlastMode.klasik ? 'Main santai tanpa batas waktu' : 'Skor sebanyak mungkin dalam 90 detik';
  bool get timed => this == BlastMode.timeAttack;
  int get seconds => 90;
}
