import 'package:flutter/material.dart';

class DebugState extends ChangeNotifier {
  static final DebugState instance = DebugState._internal();
  DebugState._internal();

  bool _isDebugEnabled = false;
  bool get isDebugEnabled => _isDebugEnabled;

  void toggleDebugMode() {
    _isDebugEnabled = !_isDebugEnabled;
    notifyListeners();
  }
}