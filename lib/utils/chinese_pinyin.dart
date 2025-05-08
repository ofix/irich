import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ChinesePinYin {
  static Map<String, List<String>> pinyinDict = {};

  static Future<List<String>> getLetters(String chinese) async {
    List<String> letters = [];
    if (pinyinDict.isEmpty) {
      await loadPinYinDictionary();
    }

    var words = chinese.characters;
    for (var letter in words) {
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

  static Future<List<String>> getFirstLetters(String chinese) async {
    List<String> letters = [];
    if (pinyinDict.isEmpty) {
      await loadPinYinDictionary();
    }

    var words = chinese.characters;
    for (var letter in words) {
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

  static Future<bool> loadPinYinDictionary() async {
    try {
      String dic = await rootBundle.loadString('lib/runtime/data/chinese_pinyin.dic');
      List<String> lines = dic.split('\n');
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
    } catch (e) {
      debugPrint('加载拼音字典失败: $e');
      return false;
    }
  }

  static List<String> _removeRepeats(List<String> letters) {
    return letters.toSet().toList();
  }
}
