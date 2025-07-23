import 'package:app_gest_lavage/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

extension BuildContextExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}

