import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Loaded only when the licenses page is opened; no startup I/O or network.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final family in ['Manrope', 'Inter']) {
      final text = await rootBundle.loadString('assets/fonts/OFL-$family.txt');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}
