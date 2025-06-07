// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/rich_checkbox_button_group.dart
// Purpose:     custom checkbox button group
// Author:      songhuabiao
// Created:     2025-06-07 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/rich_checkbox_button.dart';

typedef OnCheckboxChanged =
    void Function(String key, CheckBoxOption option, Map<String, CheckBoxOption> allOptions);

class CheckBoxOption {
  final bool selected; // 是否选中
  final Color? selectedColor; // 选中的文本颜色
  final Color? unselectedColor; // 未选中的文本颜色

  const CheckBoxOption({
    this.selected = true,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.grey,
  });

  CheckBoxOption copyWith({bool? selected, Color? selectedColor, Color? unselectedColor}) {
    return CheckBoxOption(
      selected: selected ?? this.selected,
      selectedColor: selectedColor ?? this.selectedColor,
      unselectedColor: unselectedColor ?? this.unselectedColor,
    );
  }
}

class RichCheckboxButtonGroup extends StatefulWidget {
  final Map<String, CheckBoxOption> options; // 所有选项及其初始选中状态（例如 {"苹果": true, "香蕉": false}）
  final List<Color>? colors;
  final OnCheckboxChanged? onChanged;

  const RichCheckboxButtonGroup({super.key, required this.options, this.colors, this.onChanged});

  @override
  State<RichCheckboxButtonGroup> createState() => _RichCheckboxButtonGroupState();
}

class _RichCheckboxButtonGroupState extends State<RichCheckboxButtonGroup> {
  late Map<String, CheckBoxOption> _currentOptions; // 当前选项状态

  @override
  void initState() {
    super.initState();
    // 深拷贝初始状态，避免直接修改外部传入的 Map
    _currentOptions = Map.from(widget.options);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 4.0,
      children:
          _currentOptions.keys.map((String key) {
            final option = _currentOptions[key]!;
            return RichCheckboxButton(
              label: key,
              selectedColor: option.selectedColor ?? Colors.blue,
              unselectedColor: option.unselectedColor ?? Colors.grey,
              isSelected: option.selected,
              onTap: () {
                setState(() {
                  final newOption = option.copyWith(selected: !option.selected);
                  _currentOptions[key] = newOption;
                  widget.onChanged?.call(key, newOption, _currentOptions);
                });
              },
            );
          }).toList(),
    );
  }
}
