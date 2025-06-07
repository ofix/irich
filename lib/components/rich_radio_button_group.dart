// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/rich_radio_button_group.dart
// Purpose:     custom radio button group
// Author:      songhuabiao
// Created:     2025-06-07 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/widgets.dart';
import 'package:irich/components/rich_text_button.dart';

class RichRadioButtonGroup extends StatefulWidget {
  final List<String> options; // 选项列表
  final ValueChanged<String>? onChanged; // 选中变化回调
  final double height; // 组件高度

  const RichRadioButtonGroup({super.key, required this.options, this.onChanged, this.height = 32});

  @override
  State<RichRadioButtonGroup> createState() => _RichRadioButtonGroupState();
}

class _RichRadioButtonGroupState extends State<RichRadioButtonGroup> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    if (widget.options.isNotEmpty) {
      _selectedValue = widget.options.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          widget.options.map((option) {
            return RichTextButton(
              label: option,
              isSelected: _selectedValue == option,
              onTap: () {
                setState(() => _selectedValue = option);
                widget.onChanged?.call(option);
              },
              height: widget.height,
            );
          }).toList(),
    );
  }
}
