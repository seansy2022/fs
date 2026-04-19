class AppDimens {
  static const double radiusL = 8;
  static const double radiusS = 4;
  static const double gapM = 12;
  static const double gapL = 12;
  static const double borderThin = 1;
  static const double borderStrong = 2;

  static const double chevron = 14.0;
  static const double action = 18.0;
  
  static const double iconS = 16;
  static const double iconM = 20;
  static const double iconL = 24;
  static const double item = 20;

  static const double compactScale = 0.5;
  static const double channelRowWidth = 686;
  static const double channelRowHeight = 120;
  static const double modeTileWidth = 212;
  static const double modeTileHeight = 270;
  static const double squareButton = 48;
  static const double squareButtonRadius = 4;

  static double compactCell(double value) =>
      (value * compactScale).clamp(value < 32 ? value : 32, value);
  static double compactIcon(double value) =>
      (value * compactScale).clamp(14, value);
}
