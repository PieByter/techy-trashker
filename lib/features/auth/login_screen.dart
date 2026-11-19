import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/eco_pattern.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(
    text: 'andhika@techytrashker.id',
  );
  final _passwordController = TextEditingController(text: 'rahasia123');

  var _isLogin = true;
  var _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _enterApp();
  }

  void _enterApp() {
    context.go('/home');
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      if (_isLogin) _nameController.clear();
    });
  }

  void _showHelper(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  _buildHeader(context),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.forest.withValues(alpha: .10),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: _buildForm(context),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(38)),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: EcoPattern(opacity: .10)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: AppColors.forest,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Text(
                        'Techy Trashker',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'PROTOTYPE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'Kelola sampah,\nraih reward.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1.13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Satu aplikasi untuk setor sampah, jadwalkan penjemputan, '
                    'dan pantau poinmu.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .66),
                      fontSize: 13.5,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModeToggle(),
          const SizedBox(height: 22),
          Text(
            _isLogin ? 'Masuk ke akunmu' : 'Buat akun baru',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _isLogin
                ? 'Lanjutkan perjalanan hijau kamu hari ini.'
                : 'Mulai kumpulkan poin dari sampah pertamamu.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          if (!_isLogin) ...[
            _buildField(
              controller: _nameController,
              label: 'Nama lengkap',
              hint: 'Nama kamu',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],
          _buildField(
            controller: _emailController,
            label: 'Email',
            hint: 'nama@email.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email tidak boleh kosong';
              }
              if (!value.contains('@')) return 'Format email belum benar';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Minimal 8 karakter',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password tidak boleh kosong';
              }
              if (value.length < 8) return 'Minimal 8 karakter';
              return null;
            },
          ),
          if (_isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showHelper(
                  'Fitur reset password akan tersedia di versi berikutnya.',
                ),
                child: const Text('Lupa password?'),
              ),
            )
          else
            const SizedBox(height: 16),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLogin ? 'Masuk' : 'Daftar'),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'atau lanjutkan dengan',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _enterApp,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F4F7),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Text('Google'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _isLogin ? 'Belum punya akun?' : 'Sudah punya akun?',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: _toggleMode,
                  child: Text(_isLogin ? 'Daftar' : 'Masuk'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Mode demo · data dummy tersimpan di perangkat',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: 'Masuk',
            selected: _isLogin,
            onTap: () {
              if (!_isLogin) _toggleMode();
            },
          ),
          _ModeButton(
            label: 'Daftar',
            selected: !_isLogin,
            onTap: () {
              if (_isLogin) _toggleMode();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.forest.withValues(alpha: .08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.forest : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
