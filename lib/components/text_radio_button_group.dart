// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/text_radio_button_group.dart
// Purpose:     text radio button group
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/widgets.dart';
import 'package:irich/components/text_radio_button.dart';

class TextRadioButtonGroup extends StatefulWidget {
  final List<String> options; // 选项列表
  final ValueChanged<String>? onChanged; // 选中变化回调

  const TextRadioButtonGroup({super.key, required this.options, this.onChanged});

  @override
  State<TextRadioButtonGroup> createState() => _TextRadioButtonGroupState();
}

class _TextRadioButtonGroupState extends State<TextRadioButtonGroup> {
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
    return Column(
      children:
          widget.options.map((option) {
            return TextRadioButton(
              label: option,
              isSelected: _selectedValue == option,
              onTap: () {
                setState(() => _selectedValue = option);
                widget.onChanged?.call(option);
              },
            );
          }).toList(),
    );
  }
}
