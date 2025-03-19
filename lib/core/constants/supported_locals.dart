import 'package:flutter/material.dart';

enum SupportedLocals { EN }

extension SupportedLocalsExtensions on SupportedLocals {
  Locale get getLocal {
    switch (this) {
      case SupportedLocals.EN:
        return const Locale('en', 'US');
    }
  }
}
