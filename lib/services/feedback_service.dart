import 'package:flutter/material.dart';

class FeedbackService extends ChangeNotifier {
  String? _message;
  String? get message => _message;

  void updateFeedback(String newMessage) {
    if (_message == newMessage) return;
    _message = newMessage;
    notifyListeners();
  }

  void clear() {
    if (_message == null) return;
    _message = null;
    notifyListeners();
  }
}