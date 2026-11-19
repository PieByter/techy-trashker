import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/eco_pattern.dart';
import '../../data/mock_data.dart';

class QrScreen extends StatelessWidget {
  const QrScreen({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.forest,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text(
            'Setor Sampah',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: EcoPattern(opacity: .08)),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      const Text(
                        'Tunjukkan QR ini\nke petugas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          height: 1.16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pindai QR untuk mencatat setoran sampahmu dan '
                        'mendapatkan poin secara otomatis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .64),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _QrCard(
                        onSave: () =>
                            _showMessage(context, 'QR disimpan (demo).'),
                      ),
                      const SizedBox(height: 22),
                      const _StepRow(
                        number: '1',
                        text: 'Datang ke bank sampah atau tunggu kurir.',
                      ),
                      const SizedBox(height: 12),
                      const _StepRow(
                        number: '2',
                        text: 'Tunjukkan QR ini ke petugas untuk dipindai.',
                      ),
                      const SizedBox(height: 12),
                      const _StepRow(
                        number: '3',
                        text: 'Poin otomatis masuk setelah sampah ditimbang.',
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              _showMessage(context, 'QR disimpan (demo).'),
                          icon: const Icon(Icons.download_rounded, size: 19),
                          label: const Text('Simpan QR'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.cream,
                            foregroundColor: AppColors.forestDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showMessage(context, 'QR dibagikan (demo).'),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Bagikan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: .24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppColors.forest,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Techy Trashker',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'AKTIF',
                  style: TextStyle(
                    color: AppColors.forest,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: _QrPatternPainter(data: 'TT-2024-00147'),
                  child: const SizedBox.expand(),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.forest,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(demoProfile.name, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 3),
          Text(
            'TT-2024-00147 · ${demoProfile.points} poin',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: Color(0xFF9A6B1F), size: 13),
                SizedBox(width: 5),
                Text(
                  'Berlaku 5 menit',
                  style: TextStyle(
                    color: Color(0xFF9A6B1F),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onSave, child: const Text('Simpan ke galeri')),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .68),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QrPatternPainter extends CustomPainter {
  _QrPatternPainter({required this.data});

  final String data;

  static const _modules = 29;
  static const _finder = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _modules;
    final paint = Paint()..color = AppColors.forestDark;

    // Quiet background.
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    var seed = data.codeUnits.fold<int>(
      17,
      (value, unit) => (value * 31 + unit) & 0x7fffffff,
    );
    bool nextBit() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return ((seed >> 16) & 1) == 1;
    }

    final reserved = <String>{};

    void reserve(int x, int y, int w, int h) {
      for (var dx = 0; dx < w; dx++) {
        for (var dy = 0; dy < h; dy++) {
          reserved.add('${x + dx}:${y + dy}');
        }
      }
    }

    void drawFinder(int x, int y) {
      canvas.drawRect(
        Rect.fromLTWH(x * cell, y * cell, 7 * cell, 7 * cell),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH((x + 1) * cell, (y + 1) * cell, 5 * cell, 5 * cell),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromLTWH((x + 2) * cell, (y + 2) * cell, 3 * cell, 3 * cell),
        paint,
      );
      reserve(x - 1, y - 1, 9, 9);
    }

    drawFinder(0, 0);
    drawFinder(_modules - _finder, 0);
    drawFinder(0, _modules - _finder);

    // Timing patterns.
    for (var i = 8; i < _modules - 8; i++) {
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(i * cell, 6 * cell, cell, cell), paint);
        canvas.drawRect(Rect.fromLTWH(6 * cell, i * cell, cell, cell), paint);
      }
      reserved.add('$i:6');
      reserved.add('6:$i');
    }

    // Data modules.
    for (var y = 0; y < _modules; y++) {
      for (var x = 0; x < _modules; x++) {
        if (reserved.contains('$x:$y')) continue;
        // Leave a little breathing room in the centre for the logo.
        if (x > 10 && x < 18 && y > 10 && y < 18) continue;
        if (nextBit()) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * cell + cell * .08,
              y * cell + cell * .08,
              cell * .84,
              cell * .84,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPatternPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
