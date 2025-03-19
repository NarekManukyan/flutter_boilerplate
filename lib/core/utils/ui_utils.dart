class UiUtils {
  UiUtils._();

  static String formatFullName({
    String? email,
    String? firstName,
    String? lastName,
    bool useInitial = false,
  }) {
    final fNameTrim = firstName?.trim() ?? '';
    final lNameTrim = lastName?.trim() ?? '';

    if (fNameTrim.isEmpty) {
      if (email == null) {
        return 'U';
      }
      return email;
    }

    if (useInitial && lNameTrim.isNotEmpty) {
      final lastNameInitial = lNameTrim[0].toUpperCase();
      return '$fNameTrim $lastNameInitial.';
    }

    return '$fNameTrim $lNameTrim'.trim();
  }

  static String getInitialSymbol({
    required String email,
    String? name,
  }) {
    if (name == null && email.isEmpty) {
      return 'U';
    }
    return name?[0].trim().toUpperCase() ?? email[0].toUpperCase();
  }
}
