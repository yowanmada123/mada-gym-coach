import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.initial});

  /// Jika diisi, layar dipakai untuk mengedit profil.
  final UserProfile? initial;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final UserProfile p =
      widget.initial?.copy() ?? UserProfile(trainingDays: {});
  final _page = PageController();
  int _step = 0;
  bool _conditionTouched = false;
  bool _saving = false;

  late final _name = TextEditingController(text: p.name);
  late final _age = TextEditingController(
    text: widget.initial == null ? '' : '${p.age}',
  );
  late final _height = TextEditingController(
    text: widget.initial == null ? '' : _fmt(p.heightCm),
  );
  late final _weight = TextEditingController(
    text: widget.initial == null ? '' : _fmt(p.weightKg),
  );

  static String _fmt(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : '$v';

  static const _titles = [
    'Data Diri',
    'Intensitas Latihan',
    'Kondisi Badan Saat Ini',
    'Target Bentuk Badan',
    'Jadwal Gym',
    'Tipe Gym',
    'Cedera & Keterbatasan',
    'Ringkasan',
  ];

  bool get _bioValid {
    final a = int.tryParse(_age.text);
    final h = double.tryParse(_height.text.replaceAll(',', '.'));
    final w = double.tryParse(_weight.text.replaceAll(',', '.'));
    return a != null &&
        a >= 12 &&
        a <= 90 &&
        h != null &&
        h >= 120 &&
        h <= 230 &&
        w != null &&
        w >= 30 &&
        w <= 250;
  }

  bool get _canNext => switch (_step) {
    0 => _bioValid,
    4 => p.trainingDays.isNotEmpty,
    _ => true,
  };

  void _syncBio() {
    p.name = _name.text.trim();
    p.age = int.tryParse(_age.text) ?? p.age;
    p.heightCm =
        double.tryParse(_height.text.replaceAll(',', '.')) ?? p.heightCm;
    p.weightKg =
        double.tryParse(_weight.text.replaceAll(',', '.')) ?? p.weightKg;
    if (!_conditionTouched && widget.initial == null) {
      p.condition = p.suggestedCondition;
    }
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    if (_step == 0) _syncBio();
    setState(() => _step = step);
    _page.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    _syncBio();
    final state = context.read<AppState>();
    await state.saveProfile(p);
    if (!mounted) return;
    if (widget.initial != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil diperbarui & jadwal dibuat ulang'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == _titles.length - 1;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(_step - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _step == 0
                          ? (widget.initial != null
                                ? () => Navigator.pop(context)
                                : null)
                          : () => _go(_step - 1),
                      icon: Icon(
                        _step == 0 && widget.initial != null
                            ? Icons.close
                            : Icons.arrow_back,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_step + 1) / _titles.length,
                          minHeight: 6,
                          color: kAccent,
                          backgroundColor: kSurface2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_step + 1}/${_titles.length}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _stepBio(),
                    _stepIntensity(),
                    _stepCondition(),
                    _stepTarget(),
                    _stepSchedule(),
                    _stepGym(),
                    _stepInjury(),
                    _stepSummary(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: kSurface2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: !_canNext || _saving
                        ? null
                        : last
                        ? _finish
                        : () => _go(_step + 1),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(
                            last ? 'Buat Jadwal Saya 💪' : 'Lanjut',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scaffoldStep(
    String subtitle,
    List<Widget> children, {
    String? heroImage,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        if (heroImage != null) ...[
          PhotoBanner(
            imageId: heroImage,
            height: 130,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                _titles[_step],
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ] else
          Text(
            _titles[_step],
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }

  // ───────────── Step 1: data diri ─────────────
  Widget _stepBio() {
    InputDecoration deco(String label, String suffix, IconData icon) =>
        InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: kSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        );
    final numFmt = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return _scaffoldStep(
      'Data ini dipakai untuk menghitung BMI, kebutuhan kalori, dan menyusun program.',
      heroImage: 'Dumbbell_Bicep_Curl',
      [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: deco(
            'Nama panggilan (opsional)',
            '',
            Icons.badge_outlined,
          ),
        ),
        const SizedBox(height: 16),
        const Text('Gender', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final g in Gender.values)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: g == Gender.male ? 6 : 0,
                    left: g == Gender.female ? 6 : 0,
                  ),
                  child: _GenderTile(
                    gender: g,
                    selected: p.gender == g,
                    onTap: () => setState(() => p.gender = g),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _age,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: deco('Usia', 'tahun', Icons.cake_outlined),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _height,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: numFmt,
          decoration: deco('Tinggi badan', 'cm', Icons.height),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: numFmt,
          decoration: deco('Berat badan', 'kg', Icons.monitor_weight_outlined),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        if (_bioValid)
          _BmiPreview(
            weight: double.parse(_weight.text.replaceAll(',', '.')),
            height: double.parse(_height.text.replaceAll(',', '.')),
          ),
      ],
    );
  }

  // ───────────── Step 2: intensitas ─────────────
  Widget _stepIntensity() {
    return _scaffoldStep(
      'Atur durasi & intensitas sesi latihan per hari.',
      heroImage: 'Battling_Ropes',
      [
        const Text(
          'Durasi per sesi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final m in const [45, 50, 55, 60])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _MinuteTile(
                    minutes: m,
                    selected: p.sessionMinutes == m,
                    onTap: () => setState(() => p.sessionMinutes = m),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Intensitas', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final i in Intensity.values)
          ChoiceCard(
            title: i.label,
            subtitle: i.desc,
            icon: i.icon,
            selected: p.intensity == i,
            onTap: () => setState(() => p.intensity = i),
          ),
        const SizedBox(height: 10),
        const Text(
          'Pengalaman latihan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final e in ExperienceLevel.values)
          ChoiceCard(
            title: e.label,
            subtitle: e.desc,
            icon: [Icons.looks_one, Icons.looks_two, Icons.looks_3][e.index],
            selected: p.experience == e,
            onTap: () => setState(() => p.experience = e),
          ),
      ],
    );
  }

  // ───────────── Step 3: kondisi badan ─────────────
  Widget _stepCondition() {
    final suggested = p.suggestedCondition;
    return _scaffoldStep(
      'Pilih yang paling menggambarkan kondisi tubuhmu sekarang. '
      'BMI kamu ${p.bmi.toStringAsFixed(1)} (${p.bmiCategory}).',
      [
        for (final c in BodyCondition.values)
          ChoiceCard(
            title: c.label,
            subtitle: c.desc,
            icon: c.icon,
            badge: c == suggested ? 'SESUAI BMI' : null,
            selected: p.condition == c,
            onTap: () => setState(() {
              _conditionTouched = true;
              p.condition = c;
            }),
          ),
      ],
    );
  }

  // ───────────── Step 4: target ─────────────
  Widget _stepTarget() {
    return _scaffoldStep(
      'Bentuk badan yang ingin dituju. Ini menentukan pembagian latihan, set, repetisi & kardio.',
      [
        for (final t in TargetBody.values)
          ChoiceCard(
            title: t.label,
            subtitle: t.desc,
            imageId: t.imageId,
            selected: p.target == t,
            onTap: () => setState(() => p.target = t),
          ),
      ],
    );
  }

  // ───────────── Step 5: jadwal ─────────────
  Widget _stepSchedule() {
    final n = p.trainingDays.length;
    final hint = switch (n) {
      0 => 'Pilih minimal 1 hari.',
      1 || 2 => 'Program Full Body — cocok untuk jadwal padat.',
      3 => 'Ideal untuk pemula–menengah (Full Body / Push-Pull-Legs).',
      4 => 'Upper/Lower split — seimbang antara volume & pemulihan.',
      5 => 'PPL + Upper/Lower — volume tinggi.',
      6 => 'Push-Pull-Legs 2× seminggu — untuk yang sudah terbiasa.',
      _ =>
        '7 hari: 6 hari beban + 1 hari active recovery. Pastikan tidur cukup!',
    };
    return _scaffoldStep(
      'Pilih hari kamu bisa ke gym dalam seminggu. Disarankan 3–5 hari dengan jeda istirahat.',
      heroImage: 'Barbell_Squat',
      [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var d = 1; d <= 7; d++)
              _DayToggle(
                label: kDayNames[d - 1],
                selected: p.trainingDays.contains(d),
                onTap: () => setState(() {
                  p.trainingDays.contains(d)
                      ? p.trainingDays.remove(d)
                      : p.trainingDays.add(d);
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: kAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$n hari/minggu • $hint',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────── Step 6: tipe gym ─────────────
  Widget _stepGym() {
    return _scaffoldStep(
      'Di gym seperti apa kamu berlatih? Jadwal hanya akan memakai alat yang biasanya tersedia.',
      [
        for (final g in GymType.values)
          _GymCard(
            gym: g,
            selected: p.gymType == g,
            onTap: () => setState(() => p.gymType = g),
          ),
        const SizedBox(height: 4),
        const Text(
          'Tips: alat tiap gym bisa berbeda. Gerakan di jadwal tetap bisa diganti satu per satu '
          'dari halaman detail hari latihan.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  // ───────────── Step 7: cedera ─────────────
  Widget _stepInjury() {
    return _scaffoldStep(
      'Pilih area yang sering cedera/nyeri. Gerakan yang rawan untuk area tersebut akan dihindari.',
      [
        ChoiceCard(
          title: 'Tidak ada cedera',
          subtitle: 'Semua gerakan sesuai level dapat dipilih',
          icon: Icons.verified_user_outlined,
          selected: p.injuries.isEmpty,
          onTap: () => setState(() => p.injuries.clear()),
        ),
        for (final i in Injury.values)
          ChoiceCard(
            title: i.label,
            subtitle: i.avoid,
            icon: Icons.healing_outlined,
            selected: p.injuries.contains(i),
            onTap: () => setState(() {
              p.injuries.contains(i) ? p.injuries.remove(i) : p.injuries.add(i);
            }),
          ),
        const SizedBox(height: 18),
        const Text(
          'Keterbatasan tubuh bagian bawah',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pilih bila kaki/pinggul memiliki keterbatasan fisik. Program akan mengurangi '
          'atau mengganti latihan kaki dengan latihan tubuh atas & core.',
          style: TextStyle(color: Colors.white54, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        for (final l in LowerBodyLimit.values)
          ChoiceCard(
            title: l.label,
            subtitle: l.desc,
            icon: l.icon,
            selected: p.lowerLimit == l,
            onTap: () => setState(() => p.lowerLimit = l),
          ),
        if (p.lowerLimit == LowerBodyLimit.upperOnly &&
            p.target == TargetBody.glutes)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Catatan: target "Bokong" tidak bisa dilatih langsung tanpa latihan kaki — '
              'program akan fokus ke tubuh atas & core.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          '⚠️ Aplikasi ini bukan pengganti saran medis. Konsultasikan dengan dokter/fisioterapis untuk cedera aktif.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  // ───────────── Step 8: ringkasan ─────────────
  Widget _stepSummary() {
    Widget row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kAccent),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    final days = (p.trainingDays.toList()..sort())
        .map((d) => kDayShort[d - 1])
        .join(', ');
    return _scaffoldStep(
      'Periksa kembali data kamu. Program akan dibuat otomatis.',
      heroImage: p.target.imageId,
      [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              row(
                p.gender.icon,
                'Profil',
                '${p.gender.label}, ${p.age} th, ${_fmt(p.heightCm)} cm, ${_fmt(p.weightKg)} kg',
              ),
              row(
                Icons.speed,
                'BMI',
                '${p.bmi.toStringAsFixed(1)} (${p.bmiCategory})',
              ),
              row(
                Icons.timer_outlined,
                'Sesi',
                '${p.sessionMinutes} menit • ${p.intensity.label} • ${p.experience.label}',
              ),
              row(Icons.person_outline, 'Kondisi', p.condition.label),
              row(Icons.flag_outlined, 'Target', p.target.label),
              row(
                Icons.calendar_month,
                'Jadwal',
                '$days (${p.trainingDays.length} hari)',
              ),
              row(p.gymType.icon, 'Tipe gym', p.gymType.label),
              row(
                Icons.healing_outlined,
                'Cedera',
                p.injuries.isEmpty
                    ? 'Tidak ada'
                    : p.injuries.map((e) => e.label).join(', '),
              ),
              row(Icons.accessible, 'Tubuh bawah', p.lowerLimit.label),
              row(
                Icons.local_fire_department_outlined,
                'Kalori',
                '±${p.targetCalories} kkal/hari • protein ${p.proteinGrams} g',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GymCard extends StatelessWidget {
  const _GymCard({
    required this.gym,
    required this.selected,
    required this.onTap,
  });
  final GymType gym;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: selected ? kAccent.withValues(alpha: .10) : kSurface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? kAccent : Colors.white10,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 110,
                  child: Row(
                    children: [
                      for (var i = 0; i < gym.images.length; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          child: ColorFiltered(
                            colorFilter: gym == GymType.oldSchool
                                ? const ColorFilter.matrix([
                                    .45, .45, .1, 0, 10, //
                                    .38, .4, .1, 0, 5,
                                    .3, .3, .1, 0, 0,
                                    0, 0, 0, 1, 0,
                                  ])
                                : const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.dst,
                                  ),
                            child: NetImage(gym.images[i], index: 1),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            gym.icon,
                            color: selected ? kAccent : Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              gym.label,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: selected ? kAccent : Colors.white24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        gym.desc,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final eq in gym.equipment)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                eq,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
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
        ),
      ),
    );
  }
}

class _GenderTile extends StatelessWidget {
  const _GenderTile({
    required this.gender,
    required this.selected,
    required this.onTap,
  });
  final Gender gender;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: selected ? kAccent.withValues(alpha: .12) : kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? kAccent : Colors.white10,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            gender.icon,
            size: 36,
            color: selected ? kAccent : Colors.white60,
          ),
          const SizedBox(height: 6),
          Text(
            gender.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class _MinuteTile extends StatelessWidget {
  const _MinuteTile({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });
  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: selected ? kAccent : kSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$minutes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: selected ? Colors.black : Colors.white,
            ),
          ),
          Text(
            'menit',
            style: TextStyle(
              fontSize: 11,
              color: selected ? Colors.black87 : Colors.white54,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: selected ? kAccent : kSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            selected ? Icons.fitness_center : Icons.weekend_outlined,
            color: selected ? Colors.black : Colors.white38,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : Colors.white70,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BmiPreview extends StatelessWidget {
  const _BmiPreview({required this.weight, required this.height});
  final double weight;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = UserProfile(weightKg: weight, heightCm: height);
    final bmi = p.bmi;
    final t = ((bmi - 15) / 20).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('BMI ', style: TextStyle(color: Colors.white54)),
              Text(
                bmi.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              InfoChip(p.bmiCategory, color: kAccent),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF42A5F5),
                          Color(0xFF66BB6A),
                          Color(0xFFFFCA28),
                          Color(0xFFFF7043),
                          Color(0xFFE53935),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (c.maxWidth - 14) * t,
                    top: -3,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: kBg, width: 3),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
