/// Tokens estructurales para adaptar la interfaz a distintos tamaños de pantalla.
///
/// Los widgets no deben declarar breakpoints, anchos máximos ni tamaños mínimos
/// de tarjetas directamente. Las proporciones internas siguen dependiendo del
/// espacio disponible mediante `LayoutBuilder`.
abstract final class AppLayout {
  AppLayout._();

  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 1024;

  static const double maxContentWidth = 1120;
  static const double maxBottomNavigationWidth = 760;
  static const double maxBottomNavigationHeight = 120;

  static const double minMetricCardWidth = 96;
  static const int maxMetricColumns = 3;

  static const double minSubjectCardWidth = 152;
  static const int maxSubjectColumns = 4;
  static const double subjectCardHeightFactor = 1.08;

  static const double challengeCircleWidthFactor = .36;
}
