import 'package:irich/utils/helper.dart';
import 'package:trina_grid/trina_grid.dart';

enum CellType { number, text, price, priceYesterdayClose, pricePercent, amount, volume }

class TrinaColumnTypeStock
    with TrinaColumnTypeDefaultMixin
    implements TrinaColumnType, TrinaColumnTypeHasFormat<double> {
  @override
  final dynamic defaultValue;
  CellType cellType;
  TrinaColumnTypeStock({this.defaultValue = 0, this.cellType = CellType.price});

  @override
  bool isValid(dynamic value) {
    return value is String || value is num;
  }

  @override
  int compare(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a.compareTo(b);
    }
    if (a is String && b is String) {
      return a.compareTo(b);
    }
    return 0;
  }

  @override
  dynamic makeCompareValue(dynamic v) {
    return v;
  }

  @override
  String applyFormat(dynamic value) {
    if (cellType == CellType.price || cellType == CellType.priceYesterdayClose) {
      return value.toStringAsFixed(2); // Format as price with 2 decimal places
    } else if (cellType == CellType.pricePercent) {
      return '${value.toStringAsFixed(2)}%'; // Format as percentage
    } else if (cellType == CellType.amount) {
      return Helper.richUnit(value);
    } else if (cellType == CellType.volume) {
      return Helper.richUnit(value.toDouble());
    } else if (cellType == CellType.text) {
      return value ?? '';
    } else if (cellType == CellType.number) {
      return value.toString(); // Default string representation
    }
    return value.toString();
  }

  @override
  bool get applyFormatOnInit => false;

  @override
  double get format => 0.0; // Provide a default value or implement as needed
}
