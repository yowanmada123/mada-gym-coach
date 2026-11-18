import 'package:flutter/material.dart';

import '../data/food_db.dart';
import '../models/nutrition.dart';
import '../widgets/common.dart';
import '../widgets/food_widgets.dart';

class FoodCatalogTab extends StatefulWidget {
  const FoodCatalogTab({super.key});

  @override
  State<FoodCatalogTab> createState() => _FoodCatalogTabState();
}

class _FoodCatalogTabState extends State<FoodCatalogTab>
    with AutomaticKeepAliveClientMixin {
  FoodCat? _cat;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final q = _query.toLowerCase();
    final foods = kFoods
        .where(
          (f) =>
              (_cat == null || f.cat == _cat) &&
              (q.isEmpty || f.name.toLowerCase().contains(q)),
        )
        .toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          sliver: SliverList.list(
            children: [
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cari bahan makanan…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CatChip(
                      label: 'Semua',
                      icon: Icons.apps,
                      color: kAccent,
                      selected: _cat == null,
                      onTap: () => setState(() => _cat = null),
                    ),
                    for (final c in FoodCat.values)
                      _CatChip(
                        label: c.label,
                        icon: c.icon,
                        color: c.color,
                        selected: _cat == c,
                        onTap: () => setState(() => _cat = c),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${foods.length} bahan • nilai per porsi rumah tangga',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: .78,
            ),
            itemCount: foods.length,
            itemBuilder: (_, i) => _FoodCard(foods[i]),
          ),
        ),
      ],
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 16, color: selected ? Colors.black : color),
      label: Text(label),
      showCheckmark: false,
      selectedColor: color,
      backgroundColor: kSurface,
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

class _FoodCard extends StatelessWidget {
  const _FoodCard(this.food);
  final Food food;

  @override
  Widget build(BuildContext context) {
    final f = food;
    final kcal = f.kcalFor(f.unitGrams).round();
    final prot = (f.protein * f.unitGrams / 100);
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showFoodDetail(context, f),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: f.photo == null
                        ? const Color(0xFFECEFF1)
                        : kSurface2,
                    child: UrlPhoto(
                      foodImageUrl(f),
                      fit: f.photo == null ? BoxFit.contain : BoxFit.cover,
                      icon: f.cat.icon,
                      color: f.cat.color,
                      padding: f.photo == null
                          ? const EdgeInsets.all(14)
                          : EdgeInsets.zero,
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: f.cat.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(f.cat.icon, size: 14, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    f.unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$kcal kkal',
                        style: const TextStyle(
                          color: kAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'P ${prot.toStringAsFixed(prot < 10 ? 1 : 0)}g',
                        style: const TextStyle(
                          color: kProteinColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showFoodDetail(BuildContext context, Food f) {
  final portion = Portion(f, f.unitGrams);
  const tagLabels = {
    FoodTag.meat: 'Daging/ayam',
    FoodTag.beef: 'Daging sapi',
    FoodTag.fish: 'Ikan',
    FoodTag.seafood: 'Seafood',
    FoodTag.egg: 'Telur',
    FoodTag.dairy: 'Mengandung susu',
    FoodTag.supplement: 'Suplemen',
  };

  showModalBottomSheet(
    context: context,
    backgroundColor: kSurface,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 180,
                width: double.infinity,
                color: f.photo == null ? const Color(0xFFECEFF1) : kSurface2,
                child: UrlPhoto(
                  foodImageUrl(f, small: false),
                  fit: f.photo == null ? BoxFit.contain : BoxFit.cover,
                  icon: f.cat.icon,
                  color: f.cat.color,
                  padding: f.photo == null
                      ? const EdgeInsets.all(18)
                      : EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    f.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                InfoChip(f.cat.label, icon: f.cat.icon, color: f.cat.color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '1 porsi = ${f.unit} (${f.unitGrams.round()} ${f.g})',
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                StatTile(
                  value: '${portion.kcal.round()}',
                  label: 'kkal',
                  color: kAccent,
                  highlight: true,
                ),
                const SizedBox(width: 8),
                StatTile(
                  value: '${portion.protein.toStringAsFixed(1)} g',
                  label: 'Protein',
                  color: kProteinColor,
                ),
                const SizedBox(width: 8),
                StatTile(
                  value: '${portion.carbs.toStringAsFixed(1)} g',
                  label: 'Karbo',
                  color: kCarbColor,
                ),
                const SizedBox(width: 8),
                StatTile(
                  value: '${portion.fat.toStringAsFixed(1)} g',
                  label: 'Lemak',
                  color: kFatColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Per 100 ${f.g}: ${f.kcal.round()} kkal • P ${f.protein} g • K ${f.carbs} g • L ${f.fat} g',
              style: const TextStyle(fontSize: 12, color: Colors.white38),
            ),
            if (f.note != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: kAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(f.note!)),
                  ],
                ),
              ),
            ],
            if (f.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in f.tags)
                    InfoChip(
                      tagLabels[t]!,
                      icon: Icons.label_outline,
                      color: Colors.white60,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Text(
              f.photo != null
                  ? 'Foto: Wikimedia Commons'
                  : (f.mealDb != null ? 'Gambar: TheMealDB' : ''),
              style: const TextStyle(fontSize: 11, color: Colors.white30),
            ),
          ],
        ),
      ),
    ),
  );
}
