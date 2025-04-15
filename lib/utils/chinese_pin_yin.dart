
// ignore_for_file: avoid_print

import 'dart:io';

class ChinesePinYin {
  static Map<String, List<String>> pinyinDict = {};

  static List<String> getLetters(String chinese) {
    List<String> letters = [];
    if (pinyinDict.isEmpty) {
      loadPinYinDictionary('${Directory.current.path}/chinese_pin_yin.dic');
    }

    int i = 0;
    while (i < chinese.length) {
      String letter = _nextUtf8Char(chinese, i);
      i += letter.length;

      if (pinyinDict.containsKey(letter)) {
        List<String> multiPinyin = pinyinDict[letter]!;
        if (letters.isEmpty) {
          letters.addAll(multiPinyin);
        } else {
          List<String> newLetters = [];
          for (String py in letters) {
            for (String pyNew in multiPinyin) {
              newLetters.add(py + pyNew);
            }
          }
          letters = newLetters;
        }
      } else {
        if (letters.isEmpty) {
          letters.add(letter);
        } else {
          letters = letters.map((py) => py + letter).toList();
        }
      }
    }
    return _removeRepeats(letters);
  }

  static List<String> getFirstLetters(String chinese) {
    List<String> letters = [];
    if (pinyinDict.isEmpty) {
      loadPinYinDictionary('${Directory.current.path}/chinese_pin_yin.dic');
    }

    int i = 0;
    while (i < chinese.length) {
      String letter = _nextUtf8Char(chinese, i);
      i += letter.length;

      if (pinyinDict.containsKey(letter)) {
        List<String> multiPinyin = pinyinDict[letter]!;
        if (letters.isEmpty) {
          letters.addAll(multiPinyin.map((py) => py.substring(0, 1)));
        } else {
          List<String> newLetters = [];
          for (String py in letters) {
            for (String pyNew in multiPinyin) {
              newLetters.add(py + pyNew.substring(0, 1));
            }
          }
          letters = newLetters;
        }
      } else {
        if (letters.isEmpty) {
          letters.add(letter);
        } else {
          letters = letters.map((py) => py + letter).toList();
        }
      }
    }
    return _removeRepeats(letters);
  }

  static bool loadPinYinDictionary(String dictPath) {
    try {
      final file = File(dictPath);
      if (!file.existsSync()) {
        print('$dictPath file not found');
        return false;
      }

      final lines = file.readAsLinesSync();
      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        final parts = line.split(' ');
        if (parts.length < 2) continue;

        final pinyin = parts[0].split(',');
        final hanzi = parts[1];
        pinyinDict[hanzi] = pinyin;
      }
      return true;
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 13) {
        print('$dictPath file no access permission');
      } else {
        print('$dictPath open failed: ${e.message}');
      }
      return false;
    } catch (e) {
      print('$dictPath open failed: $e');
      return false;
    }
  }

  static List<String> _removeRepeats(List<String> letters) {
    return letters.toSet().toList();
  }

  static String _nextUtf8Char(String str, int start) {
    if (start >= str.length) return '';
    
    int charCode = str.codeUnitAt(start);
    if (charCode < 0x80) {
      return str[start];
    } else if (charCode < 0xE0) {
      return str.substring(start, start + 2);
    } else if (charCode < 0xF0) {
      return str.substring(start, start + 3);
    } else {
      return str.substring(start, start + 4);
    }
  }
}