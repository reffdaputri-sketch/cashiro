import 'dart:convert';
import 'package:crypto/crypto.dart';

class QrisHelper {
  /// Injects an amount into a Static QRIS payload and returns a Dynamic QRIS payload.
  static String generateDynamicQris(String staticQris, double amount) {
    if (staticQris.isEmpty) return staticQris;

    // Remove the CRC part at the end (tag 63). Tag 63 is always the last tag.
    // It looks like "6304" followed by 4 characters of CRC.
    int index63 = staticQris.lastIndexOf("6304");
    if (index63 == -1) {
      return staticQris; // Invalid QRIS
    }

    String payloadWithoutCrc = staticQris.substring(0, index63);
    
    // Convert Point of Initiation Method from Static (11) to Dynamic (12)
    // Tag 01, Length 02, Value 11 -> 010211. Change to 010212.
    if (payloadWithoutCrc.contains("010211")) {
      payloadWithoutCrc = payloadWithoutCrc.replaceFirst("010211", "010212");
    } else if (!payloadWithoutCrc.contains("010212")) {
      // If tag 01 doesn't exist, we might append it after tag 00 (Payload Format Indicator)
      // Standard QRIS starts with 000201
      if (payloadWithoutCrc.startsWith("000201")) {
        payloadWithoutCrc = "000201010212" + payloadWithoutCrc.substring(6);
      }
    }

    // Now, insert the amount (Tag 54)
    // Tag 54 usually comes after Tag 53 (Transaction Currency) which is always "5303360" for IDR.
    int index53 = payloadWithoutCrc.indexOf("5303360");
    
    String amountStr = amount.toInt().toString();
    String lengthStr = amountStr.length.toString().padLeft(2, '0');
    String tag54 = "54" + lengthStr + amountStr;

    if (index53 != -1) {
      // Insert right after 5303360
      int insertIndex = index53 + 7;
      
      String before = payloadWithoutCrc.substring(0, insertIndex);
      String after = payloadWithoutCrc.substring(insertIndex);
      
      // Only insert if 54 is not already there right after 53
      if (!after.startsWith("54")) {
        payloadWithoutCrc = before + tag54 + after;
      }
    } else {
      // If for some reason tag 53 is missing, just append before tag 58 (Country Code, "5802ID")
      int index58 = payloadWithoutCrc.indexOf("5802ID");
      if (index58 != -1) {
        String before = payloadWithoutCrc.substring(0, index58);
        String after = payloadWithoutCrc.substring(index58);
        payloadWithoutCrc = before + tag54 + after;
      } else {
        // Fallback: just append it at the end of the payload
        payloadWithoutCrc = payloadWithoutCrc + tag54;
      }
    }

    // Now append the start of the CRC tag
    String payloadWithCrcTag = payloadWithoutCrc + "6304";
    
    // Calculate CRC16-CCITT for payloadWithCrcTag
    String crcHex = _calculateCrc16(payloadWithCrcTag);
    
    return payloadWithCrcTag + crcHex.toUpperCase();
  }

  /// Calculates the CRC16-CCITT (polynomial 0x1021, initial value 0xFFFF, no XOR out, false reverse input/output)
  static String _calculateCrc16(String input) {
    int crc = 0xFFFF;
    int polynomial = 0x1021;

    for (int i = 0; i < input.length; i++) {
      int b = input.codeUnitAt(i);
      for (int j = 0; j < 8; j++) {
        bool bit = ((b >> (7 - j)) & 1) == 1;
        bool c15 = ((crc >> 15) & 1) == 1;
        crc <<= 1;
        if (c15 ^ bit) {
          crc ^= polynomial;
        }
      }
    }
    crc &= 0xFFFF;
    return crc.toRadixString(16).padLeft(4, '0');
  }
}
