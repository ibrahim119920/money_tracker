import '../constants/app_strings.dart';
import 'money_amount.dart';

/// Form validators untuk Money Tracker
class Validators {
  /// Validasi email
  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return AppStrings.fieldRequired;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value!)) {
      return AppStrings.invalidEmail;
    }

    return null;
  }

  /// Validasi password
  static String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return AppStrings.fieldRequired;
    }

    if ((value?.length ?? 0) < 6) {
      return AppStrings.passwordTooShort;
    }

    return null;
  }

  /// Validasi konfirmasi password
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value?.isEmpty ?? true) {
      return AppStrings.fieldRequired;
    }

    if (value != password) {
      return AppStrings.passwordMismatch;
    }

    return null;
  }

  /// Validasi nama (display name, full name, etc)
  static String? validateName(String? value) {
    if (value?.isEmpty ?? true) {
      return AppStrings.fieldRequired;
    }

    if ((value?.length ?? 0) < 2) {
      return 'Nama minimal 2 karakter';
    }

    return null;
  }

  /// Validasi input umum (tidak boleh kosong)
  static String? validateRequired(String? value, String fieldName) {
    if (value?.isEmpty ?? true) {
      return '$fieldName ${AppStrings.fieldRequired}';
    }
    return null;
  }

  /// Validasi amount (jumlah uang)
  static String? validateAmount(String? value) {
    if (value?.isEmpty ?? true) {
      return AppStrings.fieldRequired;
    }

    final cleanValue = value!.replaceAll(RegExp(r'[^\d]'), '');
    final amount = int.tryParse(cleanValue);

    if (amount == null) {
      return AppStrings.invalidAmount;
    }

    return validateAmountValue(amount);
  }

  /// Validates an already-normalized Rupiah amount.
  ///
  /// Both the legacy edit form and the sequential add flows use this same
  /// limit so a value cannot pass client validation and overflow the BIGINT
  /// column during mutation.
  static String? validateAmountValue(int? value) {
    if (value == null) return AppStrings.fieldRequired;
    if (value <= 0) return AppStrings.amountMustBePositive;
    if (value > maxMoneyAmount) {
      return 'Jumlah terlalu besar untuk disimpan';
    }
    return null;
  }

  /// Validasi jumlah transfer/amount dengan batasan
  static String? validateAmountWithLimit(
    String? value, {
    int maxAmount = 9999999999, // 10 digit max
    int minAmount = 1,
  }) {
    final amountError = validateAmount(value);
    if (amountError != null) return amountError;

    final cleanValue = value!.replaceAll(RegExp(r'[^\d]'), '');
    final amount = int.parse(cleanValue);

    if (amount > maxAmount) {
      return 'Jumlah maksimal Rp ${maxAmount ~/ 1000}rb';
    }

    if (amount < minAmount) {
      return 'Jumlah minimal Rp $minAmount';
    }

    return null;
  }

  /// Validasi nomor rekening (opsional tapi jika ada harus valid)
  static String? validateAccountNumber(String? value) {
    if (value?.isEmpty ?? true) {
      return null; // Opsional
    }

    // Hanya boleh angka, minimal 5 karakter
    if (!RegExp(r'^\d{5,}$').hasMatch(value!)) {
      return 'Nomor rekening hanya boleh angka, minimal 5 digit';
    }

    return null;
  }

  /// Validasi nama field (cashbook name, wallet name, category name, etc)
  static String? validateFieldName(String? value, String fieldType) {
    if (value?.isEmpty ?? true) {
      return '$fieldType ${AppStrings.fieldRequired}';
    }

    if ((value?.length ?? 0) < 2) {
      return '$fieldType minimal 2 karakter';
    }

    if ((value?.length ?? 0) > 100) {
      return '$fieldType maksimal 100 karakter';
    }

    return null;
  }

  /// Validasi notes/description (opsional tapi jika ada ada batasan)
  static String? validateNotes(String? value) {
    if (value?.isEmpty ?? true) {
      return null; // Opsional
    }

    if ((value?.length ?? 0) > 500) {
      return 'Catatan maksimal 500 karakter';
    }

    return null;
  }

  /// Validasi tanggal (tidak boleh masa depan)
  static String? validatePastDate(DateTime? value) {
    if (value == null) {
      return AppStrings.fieldRequired;
    }

    if (value.isAfter(DateTime.now())) {
      return 'Tanggal tidak boleh di masa depan';
    }

    return null;
  }

  /// Validasi URL (untuk attachment/gambar)
  static String? validateUrl(String? value) {
    if (value?.isEmpty ?? true) {
      return null; // Opsional
    }

    try {
      Uri.parse(value!);
      return null;
    } catch (e) {
      return 'URL tidak valid';
    }
  }
}
