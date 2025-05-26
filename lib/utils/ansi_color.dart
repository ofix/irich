abstract class AnsiColor {
  // 前景色（文字颜色）
  static const int black = 30;
  static const int red = 31;
  static const int green = 32;
  static const int yellow = 33;
  static const int blue = 34;
  static const int magenta = 35;
  static const int cyan = 36;
  static const int white = 37;
  static const int gray = 90;
  static const int brightRed = 91;
  static const int brightGreen = 92;
  static const int brightYellow = 93;
  static const int brightBlue = 94;
  static const int brightMagenta = 95;
  static const int brightCyan = 96;
  static const int brightWhite = 97;

  // 背景色
  static const int bgBlack = 40;
  static const int bgRed = 41;
  static const int bgGreen = 42;
  static const int bgYellow = 43;
  static const int bgBlue = 44;
  static const int bgMagenta = 45;
  static const int bgCyan = 46;
  static const int bgWhite = 47;
  static const int bgGray = 100;
  static const int bgBrightRed = 101;
  static const int bgBrightGreen = 102;
  static const int bgBrightYellow = 103;
  static const int bgBrightBlue = 104;
  static const int bgBrightMagenta = 105;
  static const int bgBrightCyan = 106;
  static const int bgBrightWhite = 107;

  // 样式
  static const int bold = 1;
  static const int italic = 3;
  static const int underline = 4;
  static const int reverse = 7; // 反转前景色和背景色
}

extension ColorString on String {
  // 前景色
  String get black => _applyStyle(AnsiColor.black);
  String get red => _applyStyle(AnsiColor.red);
  String get green => _applyStyle(AnsiColor.green);
  String get yellow => _applyStyle(AnsiColor.yellow);
  String get blue => _applyStyle(AnsiColor.blue);
  String get magenta => _applyStyle(AnsiColor.magenta);
  String get cyan => _applyStyle(AnsiColor.cyan);
  String get white => _applyStyle(AnsiColor.white);
  String get gray => _applyStyle(AnsiColor.gray);
  String get brightRed => _applyStyle(AnsiColor.brightRed);
  String get brightGreen => _applyStyle(AnsiColor.brightGreen);
  String get brightYellow => _applyStyle(AnsiColor.brightYellow);
  String get brightBlue => _applyStyle(AnsiColor.brightBlue);
  String get brightMagenta => _applyStyle(AnsiColor.brightMagenta);
  String get brightCyan => _applyStyle(AnsiColor.brightCyan);
  String get brightWhite => _applyStyle(AnsiColor.brightWhite);

  // 背景色
  String get bgBlack => _applyStyle(AnsiColor.bgBlack);
  String get bgRed => _applyStyle(AnsiColor.bgRed);
  String get bgGreen => _applyStyle(AnsiColor.bgGreen);
  String get bgYellow => _applyStyle(AnsiColor.bgYellow);
  String get bgBlue => _applyStyle(AnsiColor.bgBlue);
  String get bgMagenta => _applyStyle(AnsiColor.bgMagenta);
  String get bgCyan => _applyStyle(AnsiColor.bgCyan);
  String get bgWhite => _applyStyle(AnsiColor.bgWhite);
  String get bgGray => _applyStyle(AnsiColor.bgGray);
  String get bgBrightRed => _applyStyle(AnsiColor.bgBrightRed);
  String get bgBrightGreen => _applyStyle(AnsiColor.bgBrightGreen);
  String get bgBrightYellow => _applyStyle(AnsiColor.bgBrightYellow);
  String get bgBrightBlue => _applyStyle(AnsiColor.bgBrightBlue);
  String get bgBrightMagenta => _applyStyle(AnsiColor.bgBrightMagenta);
  String get bgBrightCyan => _applyStyle(AnsiColor.bgBrightCyan);
  String get bgBrightWhite => _applyStyle(AnsiColor.bgBrightWhite);

  // 样式
  String get bold => _applyStyle(AnsiColor.bold);
  String get italic => _applyStyle(AnsiColor.italic);
  String get underline => _applyStyle(AnsiColor.underline);
  String get reverse => _applyStyle(AnsiColor.reverse);

  // 核心方法：应用ANSI样式
  String _applyStyle(int code) {
    return '\x1B[${code}m$this\x1B[0m';
  }
}
