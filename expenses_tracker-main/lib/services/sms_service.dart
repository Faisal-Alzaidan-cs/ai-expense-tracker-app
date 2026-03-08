import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utility/sms_parser.dart';

class SmsService {
  final SmsQuery _smsQuery = SmsQuery();

  /// Request SMS permission and return status
  Future<bool> requestSmsPermission() async {
    var permissionStatus = await Permission.sms.status;
    if (!permissionStatus.isGranted) {
      permissionStatus = await Permission.sms.request();
    }
    return permissionStatus.isGranted;
  }

  /// Fetch bank SMS messages that contain expense data
  Future<List<SmsMessage>> fetchBankSmsMessages({int count = 50}) async {
    if (!await requestSmsPermission()) {
      debugPrint("❌ SMS permission not granted");
      return [];
    }

    // Try to get SMS messages from AlRajhiBank first
    List<SmsMessage> messages = await _smsQuery.querySms(
      kinds: [SmsQueryKind.inbox],
      address: "AlRajhiBank",
      count: count,
    );

    if (messages.isEmpty) {
      // If no messages found with specific sender, try a broader search
      messages = await _smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
        count: count,
      );

      debugPrint("📱 Found ${messages.length} total SMS messages");

      // Filter for bank messages only
      messages = messages.where((msg) {
        final String body = msg.body?.toLowerCase() ?? '';
        final String sender = msg.address?.toLowerCase() ?? '';

        return SmsParser.isLikelyBankMessage(body, sender);
      }).toList();
    }

    debugPrint("🏦 Found ${messages.length} potential bank messages");
    return messages;
  }

  /// Extract expense data from bank SMS messages
  /// Returns a list of expenses with transaction data
  Future<List<Map<String, dynamic>>> extractExpensesFromSms({
    required Set<String> processedSmsIds,
  }) async {
    List<SmsMessage> bankMessages = await fetchBankSmsMessages();

    if (bankMessages.isEmpty) {
      debugPrint("📭 No bank SMS messages found");
      return [];
    }

    List<Map<String, dynamic>> extractedExpenses = [];

    for (var msg in bankMessages) {
      if (msg.body != null && msg.id != null) {
        String smsId = msg.id.toString();

        // Skip messages that have already been processed
        if (processedSmsIds.contains(smsId)) {
          continue;
        }

        Map<String, dynamic> extractedData =
            SmsParser.parseTransactionMessage(msg.body!);
        if (extractedData.isNotEmpty) {
          extractedData['smsId'] = smsId;
          extractedData['timestamp'] = msg.date ?? DateTime.now();
          extractedData['rawMessage'] = msg.body;
          extractedData['sender'] = msg.address ?? 'Unknown';

          extractedExpenses.add(extractedData);
        }
      }
    }

    debugPrint("✅ Extracted ${extractedExpenses.length} expenses from SMS");
    return extractedExpenses;
  }
}
