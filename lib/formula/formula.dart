// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/formula/formula.dart
// Purpose:     formula base class
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

enum FormulaType {
  ema, // 指数平滑移动平均线
}

class Formula {
  final FormulaType _type;
  Formula(this._type);
  FormulaType get type => _type;
}
