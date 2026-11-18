import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_db.dart';
import '../data/food_photos.dart';
import '../models/enums.dart';
import '../models/nutrition.dart';
import '../services/meal_planner.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/food_widgets.dart';
import 'food_catalog_tab.dart';

class NutritionGuideTab extends StatelessWidget {
  const NutritionGuideTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppState>().profile!;
    final male = p.gender == Gender.male;
    final water = MealPlanner.waterMl(p, false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // ── Isi Piringku ──
        const SectionTitle('Isi Piringku'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const IsiPiringkuPlate(size: 150),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (name, part, color, icon)
                            in IsiPiringkuPlate.sections)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(icon, color: color, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        part,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Pedoman Kemenkes RI untuk sekali makan: ½ piring sayur & buah, ½ piring '
                'makanan pokok & lauk. Sayur lebih banyak dari buah; makanan pokok lebih '
                'banyak dari lauk.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              const Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  InfoChip(
                    'Minum air putih',
                    icon: Icons.water_drop,
                    color: kWaterColor,
                  ),
                  InfoChip(
                    'Cuci tangan',
                    icon: Icons.clean_hands,
                    color: Colors.white70,
                  ),
                  InfoChip(
                    'Aktif bergerak',
                    icon: Icons.directions_run,
                    color: kAccent,
                  ),
                  InfoChip(
                    'Batasi gula-garam-lemak',
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Porsi tangan ──
        SectionTitle('Porsi Pakai Tangan (${male ? 'Pria' : 'Wanita'})'),
        const Text(
          'Cara praktis mengukur porsi saat makan di luar — tanpa timbangan.',
          style: TextStyle(color: Colors.white54, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            _HandCard(
              icon: Icons.back_hand,
              color: kProteinColor,
              title: 'Protein',
              amount: male ? '2 telapak' : '1 telapak',
              desc: 'Tebal & lebar telapak tangan — ayam, ikan, tempe, tahu.',
            ),
            _HandCard(
              icon: Icons.sports_mma,
              color: kCarbColor,
              title: 'Karbohidrat',
              amount: male ? '2 genggam' : '1 genggam',
              desc: 'Segenggam tangan menangkup — nasi, kentang, ubi.',
            ),
            _HandCard(
              icon: Icons.front_hand,
              color: const Color(0xFF66BB6A),
              title: 'Sayur',
              amount: male ? '2 kepalan' : '1–2 kepalan',
              desc: 'Sebesar kepalan tangan — makin banyak makin baik.',
            ),
            _HandCard(
              icon: Icons.thumb_up,
              color: kFatColor,
              title: 'Lemak',
              amount: male ? '2 ibu jari' : '1 ibu jari',
              desc: 'Seukuran ibu jari — minyak, kacang, selai, alpukat.',
            ),
          ],
        ),

        // ── Batas GGL ──
        const SectionTitle('Batas Harian Gula • Garam • Lemak'),
        const Row(
          children: [
            StatTile(
              value: '4 sdm',
              label: 'Gula\n(50 g)',
              icon: Icons.icecream,
              color: Color(0xFFF48FB1),
            ),
            SizedBox(width: 8),
            StatTile(
              value: '1 sdt',
              label: 'Garam\n(5 g)',
              icon: Icons.grain,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            StatTile(
              value: '5 sdm',
              label: 'Minyak\n(67 g)',
              icon: Icons.opacity,
              color: Color(0xFFFFD54F),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Sumber: Permenkes No. 30 Tahun 2013 — termasuk yang ada di makanan jadi.',
          style: TextStyle(fontSize: 11, color: Colors.white38),
        ),

        // ── Ukuran rumah tangga ──
        const SectionTitle('Takaran Rumah Tangga'),
        Container(
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (final id in const [
                'nasi',
                'nasi_merah',
                'kentang',
                'roti_gandum',
                'oat',
                'ayam_dada',
                'telur',
                'kembung',
                'tempe',
                'tahu',
                'bayam',
                'pisang',
                'pepaya',
                'susu_skim',
                'minyak',
                'selai_kacang',
              ])
                _MeasureRow(kFoodById[id]!),
            ],
          ),
        ),

        // ── Aturan ──
        const SectionTitle('10 Aturan Makan Sederhana'),
        for (final (i, (icon, title, desc)) in _rules.indexed)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: kAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}. $title',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // ── Seputar latihan ──
        const SectionTitle('Makan Seputar Latihan'),
        Row(
          children: [
            Expanded(
              child: _PhotoCard(
                photo: 'kurma',
                title: 'Sebelum',
                lines: const [
                  '2–3 jam: makan lengkap (nasi + lauk + sayur).',
                  '30–60 menit: snack karbo ringan — pisang, kurma, roti.',
                  'Hindari gorengan & porsi besar.',
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PhotoCard(
                photo: 'ayam_bakar',
                title: 'Sesudah',
                lines: const [
                  'Maks. 2 jam setelah latihan.',
                  'Protein 20–40 g + karbo.',
                  'Contoh: nasi + ayam + sayur, atau susu + pisang.',
                ],
              ),
            ),
          ],
        ),

        // ── Air ──
        const SectionTitle('Hidrasi'),
        UrlBanner(
          url: kDishPhotos['infused_water']?.url,
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '±${(water / 1000).toStringAsFixed(1).replaceAll('.', ',')} liter / hari',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                '35 ml × berat badan, +500 ml di hari latihan. Urine kuning jernih = cukup.',
                style: TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ],
          ),
        ),

        // ── Tukar ──
        const SectionTitle('Tukar Jadi Lebih Sehat'),
        for (final (from, to, photo, note) in _swaps)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: UrlPhoto(kDishPhotos[photo]?.url),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        from,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12.5,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: kAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              to,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        note,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () => _showCredits(context),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Sumber data & kredit foto'),
          ),
        ),
      ],
    );
  }
}

const _rules = [
  (
    Icons.restaurant,
    'Jangan lewatkan sarapan',
    'Sarapan berprotein menjaga energi & mengurangi ngemil berlebihan di siang hari.',
  ),
  (
    Icons.egg_alt,
    'Protein di setiap makan',
    'Bagi rata 20–40 g protein tiap makan agar otot terus mendapat bahan bangunan.',
  ),
  (
    Icons.grass,
    'Setengah piring sayur',
    'Serat bikin kenyang lebih lama dengan kalori rendah.',
  ),
  (
    Icons.outdoor_grill,
    'Bakar, kukus, rebus, pepes',
    'Satu sendok makan minyak goreng ≈ 120 kkal. Gorengan cepat menambah kalori tersembunyi.',
  ),
  (
    Icons.local_cafe,
    'Minuman tanpa gula',
    'Segelas es teh manis ≈ 100–150 kkal; boba bisa >300 kkal. Pilih air putih, teh/kopi tawar.',
  ),
  (
    Icons.timer,
    'Makan pelan 15–20 menit',
    'Otak butuh waktu untuk menerima sinyal kenyang.',
  ),
  (
    Icons.schedule,
    'Jadwal makan teratur',
    'Jarak makan 3–4 jam menjaga gula darah stabil & mencegah lapar berlebihan.',
  ),
  (
    Icons.inventory_2,
    'Meal prep 2–3 hari',
    'Masak lauk & karbo sekaligus, simpan di kotak makan — mencegah jajan sembarangan.',
  ),
  (
    Icons.nightlight,
    'Makan malam 2–3 jam sebelum tidur',
    'Tidur lebih nyenyak; pemulihan otot lebih optimal.',
  ),
  (
    Icons.monitor_weight,
    'Pantau tren, bukan angka harian',
    'Timbang 1×/minggu pagi hari setelah BAK. Fluktuasi 1–2 kg harian itu normal (air).',
  ),
];

const _swaps = [
  (
    'Ayam goreng tepung',
    'Ayam bakar / panggang',
    'ayam_bakar',
    'Hemat ±150 kkal per potong',
  ),
  (
    'Nasi putih porsi besar',
    'Nasi merah / ubi rebus',
    'nasi_merah',
    'Serat lebih tinggi, kenyang lebih lama',
  ),
  (
    'Es teh manis / boba',
    'Infused water / teh tawar',
    'infused_water',
    'Hemat 100–300 kkal per gelas',
  ),
  (
    'Ikan goreng',
    'Pepes / ikan bakar',
    'pepes_ikan',
    'Hampir tanpa minyak tambahan',
  ),
  (
    'Sayur bersantan',
    'Sayur bening / sayur asem',
    'sayur_asem',
    'Lemak jenuh jauh lebih rendah',
  ),
  (
    'Keripik & gorengan',
    'Edamame / buah potong',
    'edamame',
    'Snack berprotein & berserat',
  ),
  (
    'Es krim',
    'Yogurt + buah',
    'yogurt_bowl',
    'Gula lebih rendah, protein lebih tinggi',
  ),
  (
    'Tempe goreng',
    'Tempe bacem / bakar',
    'tempe_bacem',
    'Kurangi minyak, rasa tetap enak',
  ),
];

class _HandCard extends StatelessWidget {
  const _HandCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.amount,
    required this.desc,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String amount;
  final String desc;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const Text(
          'per makan',
          style: TextStyle(fontSize: 10.5, color: Colors.white38),
        ),
        const Spacer(),
        Text(
          desc,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11.5, color: Colors.white60),
        ),
      ],
    ),
  );
}

class _MeasureRow extends StatelessWidget {
  const _MeasureRow(this.food);
  final Food food;

  @override
  Widget build(BuildContext context) {
    final kcal = food.kcalFor(food.unitGrams).round();
    return InkWell(
      onTap: () => showFoodDetail(context, food),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            FoodThumb(food, size: 40, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${food.unit} = ${food.unitGrams.round()} ${food.g}',
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Text(
              '$kcal kkal',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: kAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.photo,
    required this.title,
    required this.lines,
  });
  final String photo;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          width: double.infinity,
          child: UrlPhoto(kDishPhotos[photo]?.url),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: kAccent,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '• $l',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _showCredits(BuildContext context) {
  final entries = kDishPhotos.entries.toList();
  showModalBottomSheet(
    context: context,
    backgroundColor: kSurface,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .7,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const Text(
            'Sumber Data & Kredit Foto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nilai gizi: Tabel Komposisi Pangan Indonesia (Kemenkes), Daftar Bahan Makanan '
            'Penukar, USDA FoodData Central — dibulatkan.\n'
            'Pedoman: Isi Piringku & Permenkes 30/2013 (batas gula, garam, lemak).\n'
            'Gambar bahan makanan: TheMealDB (themealdb.com).\n'
            'Foto masakan: Wikimedia Commons — lisensi per foto di bawah.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const Divider(height: 24, color: Colors.white12),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: UrlPhoto(e.value.url),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${e.value.title}\n${e.value.author} • ${e.value.license}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
