import 'package:flutter/services.dart';

// 전화번호 형식 포맷터 (010-1234-5678)
class PhoneNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // 숫자만 추출
    String digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

    // 최대 11자리까지만 유효하게 처리
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }

    // 번호 형식 지정 (010-xxxx-xxxx)
    String formattedValue = '';
    if (digitsOnly.length <= 3) {
      formattedValue = digitsOnly;
    } else if (digitsOnly.length <= 7) {
      formattedValue =
          '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
    } else {
      formattedValue =
          '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
    }

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(
        offset: formattedValue.length,
      ),
    );
  }
}

// 주민등록번호 형식 포맷터 (123456-1234567)
class PersonalIdInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // 숫자만 추출
    String digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

    // 최대 13자리까지만 유효하게 처리
    if (digitsOnly.length > 13) {
      digitsOnly = digitsOnly.substring(0, 13);
    }

    // 주민번호 형식 지정 (123456-1234567)
    String formattedValue = '';
    if (digitsOnly.length <= 6) {
      formattedValue = digitsOnly;
    } else {
      formattedValue =
          '${digitsOnly.substring(0, 6)}-${digitsOnly.substring(6)}';
    }

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(
        offset: formattedValue.length,
      ),
    );
  }
}

// 계좌번호 형식 포맷터 (은행마다 다른 형식을 가질 수 있음)
class AccountNumberInputFormatter extends TextInputFormatter {
  final String bankName;

  AccountNumberInputFormatter({required this.bankName});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // 숫자만 추출
    String digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

    // 은행별 포맷 지정
    String formattedValue = '';
    switch (bankName) {
      case '국민은행':
        // 국민은행 형식 (예: 012-34-5678)
        if (digitsOnly.length <= 3) {
          formattedValue = digitsOnly;
        } else if (digitsOnly.length <= 5) {
          formattedValue =
              '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
        } else {
          int dashIndex = 5;
          if (digitsOnly.length > dashIndex) {
            formattedValue =
                '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, dashIndex)}-${digitsOnly.substring(dashIndex)}';
          } else {
            formattedValue =
                '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
          }
        }
        break;
      case '신한은행':
        // 신한은행 형식 (예: 123-456-78-9)
        if (digitsOnly.length <= 3) {
          formattedValue = digitsOnly;
        } else if (digitsOnly.length <= 6) {
          formattedValue =
              '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
        } else if (digitsOnly.length <= 8) {
          formattedValue =
              '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
        } else {
          formattedValue =
              '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6, 8)}-${digitsOnly.substring(8)}';
        }
        break;
      case '우리은행':
        // 우리은행 형식 (예: 1234-567-89)
        if (digitsOnly.length <= 4) {
          formattedValue = digitsOnly;
        } else if (digitsOnly.length <= 7) {
          formattedValue =
              '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4)}';
        } else {
          formattedValue =
              '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4, 7)}-${digitsOnly.substring(7)}';
        }
        break;
      case '농협은행':
        // 농협은행 형식 (예: 123-4567-89-0)
        if (digitsOnly.length <= 3) {
          formattedValue = digitsOnly;
        } else if (digitsOnly.length <= 7) {
          formattedValue =
              '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
        } else if (digitsOnly.length <= 9) {
          formattedValue =
              '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
        } else {
          formattedValue =
              '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7, 9)}-${digitsOnly.substring(9)}';
        }
        break;
      default:
        // 기본 형식 (4자리마다 하이픈)
        StringBuffer buffer = StringBuffer();
        for (int i = 0; i < digitsOnly.length; i++) {
          if (i > 0 && i % 4 == 0) {
            buffer.write('-');
          }
          buffer.write(digitsOnly[i]);
        }
        formattedValue = buffer.toString();
    }

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(
        offset: formattedValue.length,
      ),
    );
  }
}

// 차량번호 형식 포맷터 (12가 3456)
class VehicleNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // 정규식을 사용하여 형식 지정
    String result = text;

    // 숫자 부분 (앞)
    if (RegExp(r'^[0-9]{2,3}$').hasMatch(text)) {
      result = '$text ';
    }
    // 숫자 + 한글
    else if (RegExp(r'^[0-9]{2,3}\s[가-힣]{1}$').hasMatch(text)) {
      result = '$text ';
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: result.length,
      ),
    );
  }
}

// 돈 형식 포맷터 (1,234,567원)
class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // 숫자만 추출
    String digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

    // 천 단위로 콤마 추가
    final formatDigits = _addCommas(digitsOnly);

    return TextEditingValue(
      text: formatDigits,
      selection: TextSelection.collapsed(
        offset: formatDigits.length,
      ),
    );
  }

  String _addCommas(String value) {
    String result = '';
    int count = 0;

    // 뒤에서부터 3자리마다 콤마 추가
    for (int i = value.length - 1; i >= 0; i--) {
      result = value[i] + result;
      count++;

      if (count % 3 == 0 && i > 0) {
        result = ',$result';
      }
    }

    return result;
  }
}
