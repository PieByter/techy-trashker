import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/eco_pattern.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      title: 'Sampah jadi\nberkah',
      description:
          'Pilah sampah dari rumah, setor ke bank sampah, dan ubah kebiasaan '
          'kecil jadi dampak besar untuk kota.',
      icon: Icons.recycling_rounded,
      badgeOneIcon: Icons.scale_rounded,
      badgeOneText: '12,4 kg',
      badgeTwoIcon: Icons.eco_rounded,
      badgeTwoText: '+147 poin',
    ),
    _OnboardingSlide(
      title: 'Jemput\nsampahmu',
      description:
          'Jadwalkan penjemputan sampah ke rumah. Kurir kami datang, '
          'kamu tetap dapat poin tanpa repot.',
      icon: Icons.local_shipping_rounded,
      badgeOneIcon: Icons.calendar_month_rounded,
      badgeOneText: 'Besok, 08.00',
      badgeTwoIcon: Icons.location_on_rounded,
      badgeTwoText: 'Medan',
    ),
    _OnboardingSlide(
      title: 'Poin jadi\nreward',
      description:
          'Kumpulkan poin dari setiap setoran dan tukarkan dengan reward '
          'yang bermanfaat untuk sehari-hari.',
      icon: Icons.card_giftcard_rounded,
      badgeOneIcon: Icons.local_cafe_rounded,
      badgeOneText: 'Tumbler Eco',
      badgeTwoIcon: Icons.stars_rounded,
      badgeTwoText: '120 poin',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLogin() => context.go('/login');

  void _next() {
    if (_page == _slides.length - 1) {
      _goToLogin();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.forest,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 14, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: AppColors.forest,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Techy Trashker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _goToLogin,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(
                              alpha: .72,
                            ),
                          ),
                          child: const Text('Lewati'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (page) => setState(() => _page = page),
                      itemBuilder: (context, index) {
                        return _OnboardingSlideView(slide: _slides[index]);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < _slides.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: i == _page ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == _page
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: .28),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _next,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.cream,
                              foregroundColor: AppColors.forestDark,
                              minimumSize: const Size.fromHeight(58),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _page == _slides.length - 1
                                      ? 'Mulai Sekarang'
                                      : 'Lanjut',
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 320,
                  maxHeight: 320,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(child: EcoPattern(opacity: .12)),
                    Container(
                      width: 236,
                      height: 236,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .14),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 184,
                        height: 184,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cream,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          slide.icon,
                          color: AppColors.forest,
                          size: 84,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -4,
                      top: 42,
                      child: _FloatingBadge(
                        icon: slide.badgeOneIcon,
                        label: slide.badgeOneText,
                      ),
                    ),
                    Positioned(
                      right: -8,
                      bottom: 48,
                      child: _FloatingBadge(
                        icon: slide.badgeTwoIcon,
                        label: slide.badgeTwoText,
                        highlighted: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              slide.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                height: 1.08,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .66),
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.amber : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: highlighted ? AppColors.forestDark : AppColors.forest,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.forestDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.badgeOneIcon,
    required this.badgeOneText,
    required this.badgeTwoIcon,
    required this.badgeTwoText,
  });

  final String title;
  final String description;
  final IconData icon;
  final IconData badgeOneIcon;
  final String badgeOneText;
  final IconData badgeTwoIcon;
  final String badgeTwoText;
}
