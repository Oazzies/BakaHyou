import 'package:flutter/widgets.dart';

/// Navigation glyphs from Phosphor Icons (MIT, https://phosphoricons.com).
///
/// Material's icons read heavier and squarer than the reference's nav, which
/// uses a thin, rounded, geometric family with a matched solid counterpart for
/// the active state. Phosphor is that family.
///
/// Rather than depending on `phosphor_flutter` — which cannot compile against
/// current Flutter, since `IconData` is now a `final class` it tries to extend —
/// the two font weights are bundled directly, subset to just these glyphs
/// (~3KB total instead of ~940KB). Codepoints are shared across weights; the
/// weight is selected by the font family.
abstract final class MbIcons {
  static const String _regular = 'PhosphorRegular';
  static const String _fill = 'PhosphorFill';

  // Outline — inactive destinations.
  static const IconData house = IconData(0xe2c6, fontFamily: _regular);
  static const IconData bookmark = IconData(0xe0ea, fontFamily: _regular);
  static const IconData compass = IconData(0xe1c8, fontFamily: _regular);
  static const IconData newspaper = IconData(0xe344, fontFamily: _regular);
  static const IconData user = IconData(0xe4c2, fontFamily: _regular);

  // Solid — the active destination, sitting in ink on the amber disc.
  static const IconData houseFill = IconData(0xe2c6, fontFamily: _fill);
  static const IconData bookmarkFill = IconData(0xe0ea, fontFamily: _fill);
  static const IconData compassFill = IconData(0xe1c8, fontFamily: _fill);
  static const IconData newspaperFill = IconData(0xe344, fontFamily: _fill);
  static const IconData userFill = IconData(0xe4c2, fontFamily: _fill);
}
