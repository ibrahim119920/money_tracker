import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

/// Form screen untuk menambah/edit buku kas
class CashbookFormScreen extends ConsumerStatefulWidget {
  final CashbookEntity? cashbook;

  const CashbookFormScreen({super.key, this.cashbook});

  @override
  ConsumerState<CashbookFormScreen> createState() => _CashbookFormScreenState();
}

class _CashbookFormScreenState extends ConsumerState<CashbookFormScreen> {
  late final TextEditingController _cashbookNameCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cashbookNameCtrl = TextEditingController(
      text: widget.cashbook?.cashbookName ?? '',
    );
  }

  @override
  void dispose() {
    _cashbookNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCashbook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cashbookRepository = ref.read(cashbookRepositoryProvider);
      final cashbookName = _cashbookNameCtrl.text.trim();

      if (widget.cashbook == null) {
        // Mode TAMBAH
        final userId = ref.read(currentUserProvider).value?.userId ?? '';
        if (userId.isEmpty) {
          throw Exception('User ID tidak ditemukan');
        }

        await cashbookRepository.createCashbook(
          userId: userId,
          cashbookName: cashbookName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Buku kas berhasil ditambahkan'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Mode EDIT
        await cashbookRepository.updateCashbook(
          cashbookId: widget.cashbook!.cashbookId,
          cashbookName: cashbookName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Buku kas berhasil diperbarui'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      // Invalidate provider
      ref.invalidate(cashbooksProvider);
      ref.invalidate(defaultCashbookProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.cashbook != null;
    final title = isEditMode ? AppStrings.cashbookUpdated : 'Tambah Buku Kas';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.md,
            AppSpacing.screenHorizontal,
            AppSpacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cashbook Name Field
                TextFormField(
                  controller: _cashbookNameCtrl,
                  decoration: InputDecoration(
                    label: Text(AppStrings.cashbookName),
                    hintText: 'contoh: Personal, Bisnis, Keluarga',
                    enabled: !_isLoading,
                  ),
                  validator: (value) =>
                      Validators.validateFieldName(value, 'Nama buku kas'),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveCashbook,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(AppStrings.save),
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
