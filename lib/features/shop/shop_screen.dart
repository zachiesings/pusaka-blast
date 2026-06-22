import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/skins.dart';
import '../../state/app_state.dart';
import '../../widgets/batik.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Batik'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              const Icon(Icons.monetization_on, color: Palette.gold, size: 20),
              const SizedBox(width: 6),
              Text('${app.coins}',
                  style: const TextStyle(color: Palette.gold, fontWeight: FontWeight.w800)),
            ]),
          ),
        ],
      ),
      body: BatikBackground(
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: SkinCatalog.all.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final skin = SkinCatalog.all[i];
              final unlocked = app.isSkinUnlocked(skin.id);
              final selected = app.selectedSkin == skin.id;
              return _SkinCard(
                skin: skin,
                unlocked: unlocked,
                selected: selected,
                canAfford: app.coins >= skin.cost,
                onBuy: () {
                  final ok = app.buySkin(skin);
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Koin belum cukup. Bersihkan baris untuk koin!')),
                    );
                  }
                },
                onSelect: () => app.selectSkin(skin.id),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  final Skin skin;
  final bool unlocked, selected, canAfford;
  final VoidCallback onBuy, onSelect;
  const _SkinCard({
    required this.skin,
    required this.unlocked,
    required this.selected,
    required this.canAfford,
    required this.onBuy,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.panel,
        borderRadius: BorderRadius.circular(18),
        border: selected ? Border.all(color: Palette.gold, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(skin.name,
                        style: const TextStyle(
                            color: Palette.cream, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(skin.desc, style: const TextStyle(color: Palette.goldSoft, fontSize: 12)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: Palette.gold)
              else if (unlocked)
                TextButton(
                  onPressed: onSelect,
                  child: const Text('Pakai', style: TextStyle(color: Palette.gold)),
                )
              else
                ElevatedButton.icon(
                  onPressed: canAfford ? onBuy : null,
                  icon: const Icon(Icons.monetization_on, size: 18),
                  label: Text('${skin.cost}'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // color swatches
          Row(
            children: skin.colors
                .take(7)
                .map((c) => Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black26),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
