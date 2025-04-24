import 'package:irich/store/stock.dart';
import 'package:irich/utils/chinese_pin_yin.dart';
import 'package:irich/utils/trie.dart';

class StoreQuote {
  static final List<Share> _shares = []; // 股票行情数据，交易时间需要每隔1s定时刷新，非交易时间读取本地文件
  static final Map<String, Share> _shareMap = {}; // 股票代码映射表，App启动时映射一次即可
  static final Map<String, List<Share>> _industryShares = {}; // 按行业名称分类的股票集合
  static final Map<String, List<Share>> _conceptShares = {}; // 按概念分类的股票集合
  static final Map<String, List<Share>> _provinceShares = {}; // 按省份分类的股票集合
  static final Trie _trie = Trie(); // 股票Trie树，支持模糊查询

  /// 私有构造函数防止实例化
  StoreQuote._();

  /// 根据用户输入的前缀字符返回对应的股票列表
  List<Share> searchShares(String prefix) {
    List<String> shareCodes = _trie.listPrefixWith(prefix);
    List<Share> shares = [];
    for (final shareCode in shareCodes) {
      final share = _shareMap[shareCode];
      if (share != null) {
        shares.add(share);
      }
    }
    return shares;
  }

  /// 获取所有股票列表
  static Future<void> load() async {
    // 1. 检查本地文件中是否存在股票行情数据

    // 2. 如果本地行情数据不存在或者旧了，就加载和讯网股票行情数据
    List<Share> shares = [];
    _init(shares);
  }

  /// 根据股票代码获取股票信息
  static Share? query(String shareCode) {
    return _shareMap[shareCode];
  }

  /// 刷新股票行情数据,间隔一秒一次
  static Future<void> refresh() async {
    // 异步请求股票行情数据
    List<Share> shares = [];
    // 更新内存中数据
    for (final share in shares) {
      final existShare = _shareMap[share.code];
      if (existShare != null) {
        existShare.priceOpen = share.priceOpen;
        existShare.priceClose = share.priceClose;
        existShare.priceMax = share.priceMax;
        existShare.priceMin = share.priceMin;
        existShare.priceNow = share.priceNow;
        existShare.priceYesterdayClose = share.priceYesterdayClose;
        existShare.amount = share.amount;
        existShare.changeAmount = share.changeAmount;
        existShare.changeRate = share.changeRate;
        existShare.qrr = share.qrr;
      }
    }
    // 如果收盘后，检查本地文件是否已刷新最新行情数据，如果没有，则刷新本地文件，需要考虑非交易日
  }

  // 添加股票列表(行情数据)
  static void _init(List<Share> shares) {
    for (final share in shares) {
      _shares.add(share);
      // 股票代码->股票哈希映射，Trie 股票哈希映射
      _shareMap[share.code] = share;
    }
    _buildClassfier(shares);
    _buildTrie(shares);
  }

  // 构建股票分类器
  static void _buildClassfier(List<Share> shares) {
    for (final share in shares) {
      if (share.industry != null) {
        _industryShares.putIfAbsent(share.industry!.name, () => []).add(share);
      }
      if (share.concepts != null) {
        for (final concept in share.concepts!) {
          _conceptShares.putIfAbsent(concept.name, () => []).add(share);
        }
      }
      if (share.province != null) {
        _provinceShares.putIfAbsent(share.province!, () => []).add(share);
      }
    }
  }

  /// 构建股票Trie树
  static void _buildTrie(List<Share> shares) {
    for (final share in shares) {
      _trie.insert(share.name, share.code);
      _trie.insert(share.code, share.code);
      // 插入拼音
      List<String> pinyin = ChinesePinYin.getFirstLetters(share.name);
      for (final char in pinyin) {
        _trie.insert(char.toLowerCase(), share.code);
      }
    }
  }

  /// 获取某个行业分类的所有股票
  static List<Share> getByIndustry(String industry) {
    return _industryShares[industry] ?? [];
  }

  /// 获取某个概念板块的所有股票
  static List<Share> getByConcept(String concept) {
    return _conceptShares[concept] ?? [];
  }

  /// 获取某个省份的所有股票
  static List<Share> getByProvince(String province) {
    return _provinceShares[province] ?? [];
  }

  /// 获取所有行业分类名称
  static List<String> get industries => _industryShares.keys.toList();

  /// 获取所有概念分类名称
  static List<String> get concepts => _conceptShares.keys.toList();

  /// 获取所有省份分类名称
  static List<String> get provinces => _provinceShares.keys.toList();
}
