import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FeedbackService extends ChangeNotifier {
  String? _message;
  String? get message => _message;

  /// Actualiza el mensaje de feedback y notifica a los widgets.
  void updateFeedback(String newMessage) {
    if (_message != newMessage) {
      _message = newMessage;
      notifyListeners();
    }
  }

  /// Limpia el mensaje actual.
  void clear() {
    if (_message != null) {
      _message = null;
      notifyListeners();
    }
  }

  // --- Métodos Estáticos para Haptics ---

  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void vibrate() {
    HapticFeedback.vibrate();
  }
}
