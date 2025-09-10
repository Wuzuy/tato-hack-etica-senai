import 'package:flutter/material.dart';

class AppTheme {
  static Color getPrimaryColor(String colorScheme) {
    switch (colorScheme) {
      case 'Alto Contraste':
        return Colors.black;
      case 'Protanopia':
        return const Color.fromRGBO(85, 148, 179, 1);
      case 'Deuteranopia':
        return const Color.fromRGBO(179, 148, 85, 1);
      case 'Tritanopia':
        return const Color.fromRGBO(148, 85, 179, 1);
      case 'Modo Escuro':
        return Colors.blueGrey[800]!;
      default:
        return const Color.fromRGBO(0, 69, 118, 1);
    }
  }

  static Color getScaffoldBackgroundColor(String colorScheme) {
    switch (colorScheme) {
      case 'Alto Contraste':
        return Colors.white;
      case 'Protanopia':
        return const Color.fromRGBO(220, 240, 250, 1);
      case 'Deuteranopia':
        return const Color.fromRGBO(250, 240, 220, 1);
      case 'Tritanopia':
        return const Color.fromRGBO(240, 220, 250, 1);
      case 'Modo Escuro':
        return Colors.grey[900]!;
      default:
        return Colors.white;
    }
  }

  static Color getMessageTextColor(String colorScheme, bool isSender) {
    if (isSender) {
      return Colors.white;
    } else {
      switch (colorScheme) {
        case 'Alto Contraste':
          return Colors.black;
        case 'Protanopia':
          return const Color.fromRGBO(0, 69, 118, 1);
        case 'Deuteranopia':
          return const Color.fromRGBO(118, 69, 0, 1);
        case 'Tritanopia':
          return const Color.fromRGBO(69, 0, 118, 1);
        case 'Modo Escuro':
          return Colors.white;
        default:
          return Colors.black;
      }
    }
  }

  static Color getMessageBubbleColor(String colorScheme, bool isSender) {
    if (isSender) {
      switch (colorScheme) {
        case 'Alto Contraste':
          return Colors.black;
        case 'Protanopia':
          return const Color.fromRGBO(85, 148, 179, 1);
        case 'Deuteranopia':
          return const Color.fromRGBO(179, 148, 85, 1);
        case 'Tritanopia':
          return const Color.fromRGBO(148, 85, 179, 1);
        case 'Modo Escuro':
          return Colors.blueGrey[800]!;
        default:
          return const Color.fromRGBO(0, 69, 118, 1);
      }
    } else {
      switch (colorScheme) {
        case 'Alto Contraste':
          return Colors.grey[300]!;
        case 'Protanopia':
          return const Color.fromRGBO(200, 220, 230, 1);
        case 'Deuteranopia':
          return const Color.fromRGBO(230, 220, 200, 1);
        case 'Tritanopia':
          return const Color.fromRGBO(220, 200, 230, 1);
        case 'Modo Escuro':
          return Colors.grey[800]!;
        default:
          return Colors.grey[200]!;
      }
    }
  }
}
