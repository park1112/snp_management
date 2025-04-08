class Validators {
  // 이름 유효성 검사
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요';
    }
    if (value.trim().length < 2) {
      return '이름은 최소 2자 이상이어야 합니다';
    }
    return null;
  }

  // 전화번호 유효성 검사
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '전화번호를 입력해주세요';
    }

    // 하이픈 제거하고 숫자만 추출
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    // 핸드폰 번호 형식 검증 (010으로 시작하는 10-11자리)
    if (!RegExp(r'^010\d{7,8}$').hasMatch(digits)) {
      return '올바른 전화번호 형식이 아닙니다 (예: 010-1234-5678)';
    }
    return null;
  }

  // 주민등록번호 유효성 검사
  static String? validatePersonalId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // 선택 사항
    }

    // 하이픈 제거하고 숫자만 추출
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    // 13자리 검증
    if (digits.length != 13) {
      return '주민등록번호는 13자리여야 합니다';
    }

    // 앞 6자리와 뒷 7자리 검증
    if (!RegExp(r'^\d{6}[1-4]\d{6}$').hasMatch(digits)) {
      return '올바른 주민등록번호 형식이 아닙니다';
    }

    // TODO: 실제 주민등록번호 유효성 체크 알고리즘 구현 (필요시)

    return null;
  }

  // 계좌번호 유효성 검사
  static String? validateAccountNumber(String? value, String? bankName) {
    if ((value == null || value.trim().isEmpty) &&
        (bankName == null || bankName.isEmpty)) {
      return null; // 은행과 계좌번호 모두 비어있으면 선택 사항으로 간주
    }

    if (value == null || value.trim().isEmpty) {
      return '계좌번호를 입력해주세요';
    }

    if (bankName == null || bankName.isEmpty) {
      return '은행을 선택해주세요';
    }

    // 숫자만 추출
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    // 일반적인 계좌번호 길이 검증 (10-16자리)
    if (digits.length < 10 || digits.length > 16) {
      return '계좌번호는 일반적으로 10-16자리입니다';
    }

    return null;
  }

  // 면단위 유효성 검사
  static String? validateSubdistrict(String? value) {
    if (value == null || value.isEmpty) {
      return '면단위를 선택해주세요';
    }
    return null;
  }

  // 결제소속 유효성 검사
  static String? validatePaymentGroup(String? value) {
    if (value == null || value.isEmpty) {
      return '결제소속을 선택해주세요';
    }
    return null;
  }

  // 주소 유효성 검사
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // 선택 사항
    }
    if (value.trim().length < 5) {
      return '올바른 주소를 입력해주세요';
    }
    return null;
  }

  // 농지 면적 유효성 검사
  static String? validateArea(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '면적을 입력해주세요';
    }

    try {
      double area = double.parse(value.trim());
      if (area <= 0) {
        return '0보다 큰 값을 입력해주세요';
      }
    } catch (e) {
      return '숫자만 입력 가능합니다';
    }

    return null;
  }

  // 작물 종류 유효성 검사
  static String? validateCropType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '작물 종류를 입력해주세요';
    }
    return null;
  }

  // 필수 입력 유효성 검사
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName을(를) 입력해주세요';
    }
    return null;
  }

  // 은행명 유효성 검사
  static String? validateBankName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '은행을 선택해주세요';
    }
    return null;
  }
}
