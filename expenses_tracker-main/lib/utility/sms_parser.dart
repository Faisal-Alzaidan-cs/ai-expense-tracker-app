import 'package:flutter/material.dart';
import 'dart:math';

class SmsParser {
  /// Parses bank transaction SMS messages and extracts expense data
  static Map<String, dynamic> parseTransactionMessage(String message) {
    String? cardNumber, cardType, merchant, date;
    double? amount;

    try {
      debugPrint(
          "Parsing message: ${message.substring(0, min(50, message.length))}...");

      // Check if the first line contains "شراء" (purchase)
      final firstLine = message.split('\n').first.trim();
      if (!firstLine.contains("شراء")) {
        debugPrint("First line does not contain 'شراء', discarding message");
        return {};
      }

      // Check if this is a transaction message
      bool isTransactionMsg = message.contains("مبلغ:SAR") ||
          (message.contains("SAR") && message.contains("بطاقة"));

      if (!isTransactionMsg) {
        debugPrint("Not a transaction message");
        return {};
      }

      // Extract card details
      cardNumber = _extractCardNumber(message);
      cardType = _extractCardType(message, cardNumber);

      // Extract amount
      amount = _extractAmount(message);

      // Extract merchant
      merchant = _extractMerchant(message);

      // Extract date
      date = _extractDate(message);

      debugPrint(
          "Parsed details - Merchant: $merchant, Amount: $amount, Date: $date");
    } catch (e) {
      debugPrint("❌ Error parsing message: $e");
    }

    if (amount == null) {
      return {};
    }

    return {
      'merchant': merchant ?? 'Unknown',
      'date': date ?? 'N/A',
      'cardNumber': cardNumber ?? 'N/A',
      'cardType': cardType ?? 'N/A',
      'amount': amount,
    };
  }

  static String? _extractCardNumber(String message) {
    final cardDetailsMatch =
        RegExp(r"بطاقة:([^;]+);([^;\n]+)").firstMatch(message);
    if (cardDetailsMatch != null) {
      return cardDetailsMatch.group(1)?.trim();
    } else {
      // Try alternate pattern
      final altCardMatch = RegExp(r"بطاقة\s*[:#]\s*(\d+)").firstMatch(message);
      if (altCardMatch != null) {
        return altCardMatch.group(1)?.trim();
      }
    }
    return null;
  }

  static String? _extractCardType(String message, String? cardNumber) {
    final cardDetailsMatch =
        RegExp(r"بطاقة:([^;]+);([^;\n]+)").firstMatch(message);
    if (cardDetailsMatch != null) {
      return cardDetailsMatch.group(2)?.trim();
    } else if (cardNumber != null) {
      return "Card"; // Default value if type is not specified
    }
    return null;
  }

  static double? _extractAmount(String message) {
    RegExp amountRegexes =
        RegExp(r"مبلغ:SAR ([\d\.]+)|SAR\s*([\d,\.]+)|(\d+[\d\.,]+)\s*ريال");
    final amountMatch = amountRegexes.firstMatch(message);
    if (amountMatch != null) {
      String? amountStr =
          (amountMatch.group(1) ?? amountMatch.group(2) ?? amountMatch.group(3))
              ?.trim();
      if (amountStr != null) {
        // Remove any commas from the amount string
        amountStr = amountStr.replaceAll(',', '');
        return double.tryParse(amountStr);
      }
    }
    return null;
  }

  static String? _extractMerchant(String message) {
    final merchantMatches = [
      RegExp(r"لدى:([^\n]+)").firstMatch(message),
    ];

    for (var match in merchantMatches) {
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  static String? _extractDate(String message) {
    final dateMatches = [
      RegExp(r"في:([^\n]+)").firstMatch(message),
    ];

    for (var match in dateMatches) {
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  /// Determines if a message is likely to be a bank transaction
  static bool isLikelyBankMessage(String body, String sender) {
    body = body.toLowerCase();
    sender = sender.toLowerCase();

    return sender.contains('bank') ||
        sender.contains('rajhi') ||
        body.contains('purchase') ||
        body.contains('transaction') ||
        body.contains('debit') ||
        body.contains('credit') ||
        body.contains('atm') ||
        body.contains('شراء') ||
        body.contains('مبلغ') ||
        body.contains('sar') ||
        body.contains('بطاقة');
  }
}
