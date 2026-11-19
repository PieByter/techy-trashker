import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/auth/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/eco_pattern.dart';
import '../../data/api/api_client.dart';
import '../../data/mock_data.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/app_repository.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key, this.session});

  final SessionController? session;

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  late final AppRepository _repository =
      widget.session?.repository ?? AppRepository(ApiClient());
  late Future<QrSession> _qrFuture;
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _qrFuture = widget.session == null
        ? Future.value(
            QrSession(
              token: 'demo-qr-token',
              qrPayload: 'techytrashker://deposit?token=demo-qr-token',
              expiresAt: DateTime.now().add(const Duration(minutes: 5)),
              expiresInSeconds: 300,
              memberCode: 'TT-2024-00147',
            ),
          )
        : _createQrSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<QrSession> _createQrSession() async {
    final qr = await _repository.createQrSession();
    try {
      await widget.session?.refreshProfile();
    } catch (_) {
      // QR generation succeeded; a stale cached profile must not hide it.
    }
    if (mounted) {
      _timer?.cancel();
      setState(() => _secondsRemaining = qr.expiresInSeconds);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return timer.cancel();
        if (_secondsRemaining <= 1) {
          setState(() => _secondsRemaining = 0);
          timer.cancel();
        } else {
          setState(() => _secondsRemaining -= 1);
        }
      });
    }
    return qr;
  }

  void _regenerate() {
    setState(() {
      _secondsRemaining = 0;
      _qrFuture = _createQrSession();
    });
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.session?.profile ?? demoProfile;
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
                      FutureBuilder<QrSession>(
                        future: _qrFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const SizedBox(
                              height: 350,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return _QrError(
                              message: snapshot.error.toString(),
                              onRetry: _regenerate,
                            );
                          }
                          final qr = snapshot.requireData;
                          return _QrCard(
                            session: qr,
                            profile: profile,
                            secondsRemaining: widget.session == null
                                ? qr.expiresInSeconds
                                : _secondsRemaining,
                            onSave: () async {
                              await Clipboard.setData(
                                ClipboardData(text: qr.token),
                              );
                              if (context.mounted) {
                                _showMessage(
                                  context,
                                  'Token QR disalin. QR hanya berlaku sekali.',
                                );
                              }
                            },
                          );
                        },
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
                      if (_secondsRemaining == 0 && widget.session != null)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _regenerate,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Buat QR baru'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.cream,
                              foregroundColor: AppColors.forestDark,
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
  const _QrCard({
    required this.session,
    required this.profile,
    required this.secondsRemaining,
    required this.onSave,
  });

  final QrSession session;
  final UserProfile profile;
  final int secondsRemaining;
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
                QrImageView(
                  data: session.qrPayload,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                  padding: const EdgeInsets.all(10),
                  backgroundColor: Colors.white,
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
          Text(profile.name, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 3),
          Text(
            '${session.memberCode} Â· ${profile.points} poin',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: Color(0xFF9A6B1F), size: 13),
                SizedBox(width: 5),
                Text(
                  'Berlaku ${_formatCountdown(secondsRemaining)}',
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
          TextButton(onPressed: onSave, child: const Text('Salin token QR')),
        ],
      ),
    );
  }
}

String _formatCountdown(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}

class _QrError extends StatelessWidget {
  const _QrError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        const Icon(Icons.qr_code_2_rounded, size: 42, color: AppColors.forest),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    ),
  );
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
