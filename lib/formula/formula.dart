enum FormulaType{
  ema, // 指数平滑移动平均线
}

class Formula {
  final FormulaType _type;
  Formula(this._type);
  FormulaType get type => _type;
}