import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  bool _isSavingDefaultCashbook = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _selectedDefaultCashbookId;
  String? _initialDefaultCashbookId;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(UserEntity user) async {
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;

    final newDisplayName = _displayNameController.text.trim();
    if (newDisplayName == (user.displayName ?? '').trim()) {
      _showSnack('Tidak ada perubahan nama', AppColors.info);
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.updateDisplayName(
        userId: user.userId,
        displayName: newDisplayName,
      );

      ref.invalidate(currentUserProvider);
      _showSnack('Profil berhasil diperbarui', AppColors.success);
    } catch (_) {
      _showSnack(
        'Gagal memperbarui profil. Silakan coba lagi.',
        AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _savePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isSavingPassword = true);

    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.updatePassword(newPassword: _newPasswordController.text);

      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showSnack('Password berhasil diubah', AppColors.success);
    } catch (_) {
      _showSnack(
        'Gagal mengubah password. Silakan coba lagi.',
        AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingPassword = false);
      }
    }
  }

  Future<void> _saveDefaultCashbook({
    required UserEntity user,
    required List<CashbookEntity> cashbooks,
  }) async {
    final selectedId = _selectedDefaultCashbookId;
    if (selectedId == null || selectedId.isEmpty) return;

    setState(() => _isSavingDefaultCashbook = true);

    try {
      final repo = ref.read(cashbookRepositoryProvider);
      await repo.setDefaultCashbook(
        userId: user.userId,
        cashbookId: selectedId,
      );

      final selectedCashbook = cashbooks
          .where((cashbook) => cashbook.cashbookId == selectedId)
          .firstOrNull;

      if (selectedCashbook != null) {
        ref.read(activeCashbookProvider.notifier).state = selectedCashbook;
      }

      ref.invalidate(cashbooksProvider);
      ref.invalidate(defaultCashbookProvider);

      _initialDefaultCashbookId = selectedId;
      _showSnack('Buku kas default berhasil diperbarui', AppColors.success);
    } catch (_) {
      _showSnack(
        'Gagal mengatur buku kas default. Silakan coba lagi.',
        AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingDefaultCashbook = false);
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text(AppStrings.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.signOut();

      ref.read(activeCashbookProvider.notifier).state = null;
      ref.invalidate(currentUserProvider);

      if (mounted) {
        context.go('/landing');
      }
    } catch (_) {
      _showSnack('Gagal logout. Silakan coba lagi.', AppColors.error);
    }
  }

  void _showSnack(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final cashbooksAsync = ref.watch(cashbooksProvider);
    final activeCashbook = ref.watch(activeCashbookProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAccountSection(currentUserAsync),
          const SizedBox(height: 16),
          _buildPasswordSection(),
          const SizedBox(height: 16),
          _buildAppSection(
            currentUserAsync: currentUserAsync,
            cashbooksAsync: cashbooksAsync,
            activeCashbook: activeCashbook,
            selectedThemeMode: themeMode,
          ),
          const SizedBox(height: 16),
          _buildAboutSection(),
          const SizedBox(height: 16),
          _buildLogoutSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAccountSection(AsyncValue<UserEntity?> currentUserAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: currentUserAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.accountSettings,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text('Gagal memuat data akun'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(currentUserProvider),
                child: const Text(AppStrings.tryAgain),
              ),
            ],
          ),
          data: (user) {
            if (user == null) {
              return const Text('User tidak ditemukan');
            }

            if (_displayNameController.text.isEmpty) {
              _displayNameController.text = user.displayName ?? '';
            }

            return Form(
              key: _profileFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.accountSettings,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.displayName,
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user.email,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: AppStrings.email,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSavingProfile
                          ? null
                          : () => _saveProfile(user),
                      child: _isSavingProfile
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan Profil'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.changePassword,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      );
                    },
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => Validators.validatePasswordConfirmation(
                  value,
                  _newPasswordController.text,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSavingPassword ? null : _savePassword,
                  child: _isSavingPassword
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ubah Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppSection({
    required AsyncValue<UserEntity?> currentUserAsync,
    required AsyncValue<List<CashbookEntity>> cashbooksAsync,
    required CashbookEntity? activeCashbook,
    required ThemeMode selectedThemeMode,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.appSettings,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text('Mode Tema'),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('Sistem'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Terang'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Gelap'),
                ),
              ],
              selected: {selectedThemeMode},
              onSelectionChanged: (values) {
                final mode = values.first;
                ref.read(appThemeModeProvider.notifier).state = mode;
              },
            ),
            const SizedBox(height: 16),
            const Text('Buku Kas Default'),
            const SizedBox(height: 8),
            cashbooksAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gagal memuat daftar buku kas'),
                  TextButton(
                    onPressed: () => ref.invalidate(cashbooksProvider),
                    child: const Text(AppStrings.tryAgain),
                  ),
                ],
              ),
              data: (cashbooks) {
                if (cashbooks.isEmpty) {
                  return const Text('Belum ada buku kas');
                }

                final existingDefault = cashbooks
                    .where((cashbook) => cashbook.isDefault)
                    .firstOrNull;
                final fallbackDefault = existingDefault ?? activeCashbook;

                _initialDefaultCashbookId ??= fallbackDefault?.cashbookId;
                _selectedDefaultCashbookId ??= fallbackDefault?.cashbookId;

                final currentUser = currentUserAsync.valueOrNull;
                final canSave =
                    currentUser != null &&
                    _selectedDefaultCashbookId != null &&
                    _selectedDefaultCashbookId != _initialDefaultCashbookId;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedDefaultCashbookId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: cashbooks
                          .map(
                            (cashbook) => DropdownMenuItem<String>(
                              value: cashbook.cashbookId,
                              child: Text(cashbook.cashbookName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedDefaultCashbookId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSavingDefaultCashbook || !canSave
                            ? null
                            : () => _saveDefaultCashbook(
                                user: currentUser,
                                cashbooks: cashbooks,
                              ),
                        child: _isSavingDefaultCashbook
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Simpan Buku Kas Default'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text(AppStrings.about),
        subtitle: const Text('Money Tracker\nVersi 1.0.0+1'),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppColors.error),
        title: const Text(
          AppStrings.logout,
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Keluar dari akun saat ini'),
        onTap: _logout,
      ),
    );
  }
}
