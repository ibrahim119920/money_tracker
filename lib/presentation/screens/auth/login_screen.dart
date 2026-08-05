import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/validators.dart';
import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(supabaseClientProvider)
          .auth
          .signInWithPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );

      // Jika berhasil auth, redirect otomatis akan terjadi via GoRouter redirect logic
      // Tapi kita tunggu sebentar untuk memastikan auth state ter-update
      if (mounted && result.session != null) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          context.go(AppRoutes.loading);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        debugPrint('Login error: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg.contains('Invalid login credentials')
                  ? AppStrings.loginError
                  : 'Error: ${e.toString()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(supabaseClientProvider)
          .auth
          .signInWithOAuth(
            OAuthProvider.google,
            redirectTo: AppAuthConfig.googleRedirectUri,
          );

      // Session dan navigasi diperbarui melalui authStateProvider dan GoRouter
      // setelah Supabase menerima callback dari deep link Android.
    } catch (e) {
      if (mounted) {
        debugPrint('Google login error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.googleLoginError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(text: _emailCtrl.text.trim());
    final dialogFormKey = GlobalKey<FormState>();

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lupa kata sandi?'),
        content: Form(
          key: dialogFormKey,
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'nama@email.com',
            ),
            validator: Validators.validateEmail,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (dialogFormKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(emailController.text.trim());
              }
            },
            child: const Text('Kirim Email'),
          ),
        ],
      ),
    );
    emailController.dispose();

    if (email == null || !mounted) return;

    try {
      await ref
          .read(settingsRepositoryProvider)
          .sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Jika email terdaftar, instruksi pemulihan akan dikirimkan.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim email pemulihan. Coba lagi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxs,
                    AppSpacing.lg,
                    AppSpacing.xxs,
                    0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: Text(
                    'Selamat Datang',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: Text(
                    'Masuk untuk melanjutkan',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── FORM FIELDS ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email
                      _FieldLabel('Email'),
                      const SizedBox(height: AppSpacing.xxs),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Kata Sandi
                      _FieldLabel('Kata Sandi'),
                      const SizedBox(height: AppSpacing.xxs),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: _inputDecoration(
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Lupa kata sandi
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text(
                            'Lupa kata sandi?',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Tombol Masuk
                      SizedBox(
                        width: double.infinity,
                        height: AppComponentHeight.interactive,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Divider 'atau'
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: Text(
                              'atau',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Google OAuth menggunakan Supabase dan deep link Android.
                      SizedBox(
                        width: double.infinity,
                        height: AppComponentHeight.interactive,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _loginWithGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: const Text(AppStrings.googleLoginButton),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(color: colorScheme.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.controlBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: () => context.push(AppRoutes.register),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Daftar',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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

  InputDecoration _inputDecoration({Widget? prefixIcon, Widget? suffixIcon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: AppSpacing.controlPadding,
      border: OutlineInputBorder(
        borderRadius: AppRadius.controlBorder,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.controlBorder,
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.controlBorder,
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.controlBorder,
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.controlBorder,
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
