# 다중 로그인 템플릿 앱 (v1.2.1)

## 주요 기능
- 네이버, 페이스북, 구글 소셜 로그인
- 전화번호 인증 로그인
- 사용자 프로필 관리 (이름, 프로필 이미지)
- 로그인 기록 관리
- 자동 로그인 및 로그아웃
- 계정 삭제 (30일 보관 정책 적용)

## 버전 히스토리
- **v0.0.3**
  - 계약관리 코드구현중 카드 생성중에 멈춤

- **v0.0.2**
  - 농지 관리 페이지 추가 (아직 에러 있음 )

- **v0.0.1**
  - 농가 관리 페이지 추가 (아직 에러 있음)

- **v0.0.0**
  - 프로젝트 초기 시작 
  - 파이어베이스 변경해야함 
  







**##########################################**
- **v1.3.0**
  - 네이버 로그인삭제(버전때문에 에러계속되어서 삭제)
  - 이미지 폴더 추가. 
  
- **v1.0.0 (초기 출시)**
  - 기본 앱 구조 설정
  - Firebase 연결 및 인증 기능 구현
- **v1.1.0**
  - 소셜 로그인 기능 추가 (네이버, 페이스북)
  - 프로필 관리 기능 구현 및 UI 개선
- **v1.2.0**
  - 구글 로그인 추가
  - 전화번호 인증 개선 및 UI/UX 개선
- **v1.2.1 (현재 버전)**
  - 프로필 화면 사용자 정보 불러오기 문제 수정  
    * FirestoreService의 getUser() 메서드 수정  
    * AuthController의 데이터 로드 지연 추가  
  - 로그인 기록 표시 기능 개선
  - 사용자 삭제 기능 개선 및 예외 처리 강화
  - **계정 삭제 시, 프로필 이미지 삭제 대신 삭제 보관함(deleted_profile_images)으로 이동**  
    삭제된 파일은 30일간 보관되며, 별도의 스케줄러(예: Firebase Cloud Functions)를 통해 30일 이후 완전 삭제 예정
  - 다양한 버그 수정 및 인증 프로세스 안정성 향상
  - 계정삭제까지 완료
  - **계정 삭제 후 로그인 버튼에서 무한 로딩중인 현상 해결해야함**

## 사용자 삭제 기능 개선
- **문제점**: 로그인 후 계정 삭제 시, Firebase Storage에서 파일이 없을 경우 발생하는 `object-not-found` 예외 및 기타 삭제 관련 예외들이 발생함.
- **해결 방법**:  
  - 프로필 이미지가 존재하는 경우에만 파일 데이터를 읽어와서, `deleted_profile_images` 폴더로 복사한 후 원본 파일을 삭제합니다.
  - 삭제 보관함에 보관된 파일은 별도의 백그라운드 작업(예: Firebase Cloud Functions)을 통해 30일 후 영구 삭제됩니다.
  - Firestore, Firebase Auth의 삭제 과정에서도 발생하는 예외들을 세분화하여 처리하였습니다.

## 설치 및 설정
1. Flutter 환경 설정  
   ```bash
   flutter pub get
    ```


lib/
  ├── main.dart                   // 기존 파일
  ├── config/                     // 기존 폴더
  │   ├── constants.dart
  │   ├── theme.dart
  ├── controllers/                // 기존 폴더
  │   ├── auth_controller.dart
  │   ├── user_controller.dart
  │   ├── farm_controller.dart    // 새로 추가
  │   ├── field_controller.dart   // 새로 추가
  │   ├── worker_controller.dart  // 새로 추가
  │   ├── schedule_controller.dart// 새로 추가
  │   └── contract_controller.dart// 새로 추가
  ├── models/                     // 기존 폴더 + 신규 모델
  │   ├── user_model.dart
  │   ├── farm_model.dart        // 새로 추가
  │   ├── field_model.dart       // 새로 추가
  │   ├── worker_model.dart      // 새로 추가
  │   ├── schedule_model.dart    // 새로 추가
  │   └── contract_model.dart    // 새로 추가
  ├── services/                   // 기존 폴더 + 신규 서비스
  │   ├── auth_service.dart
  │   ├── firestore_service.dart
  │   ├── farm_service.dart      // 새로 추가
  │   ├── field_service.dart     // 새로 추가
  │   ├── worker_service.dart    // 새로 추가
  │   ├── schedule_service.dart  // 새로 추가
  │   └── contract_service.dart  // 새로 추가
  ├── screens/                    // 기존 폴더 + 신규 화면
  │   ├── auth/
  │   ├── splash/
  │   ├── home/
  │   ├── profile/
  │   ├── farm/                  // 새로 추가
  │   │   ├── farm_list_screen.dart
  │   │   ├── farm_add_screen.dart
  │   │   ├── farm_detail_screen.dart
  │   │   └── farm_edit_screen.dart
  │   ├── field/                 // 새로 추가
  │   │   ├── field_list_screen.dart
  │   │   ├── field_add_screen.dart
  │   │   ├── field_detail_screen.dart
  │   │   └── field_edit_screen.dart
  │   ├── worker/                // 새로 추가
  │   │   ├── worker_list_screen.dart
  │   │   ├── worker_add_screen.dart
  │   │   ├── worker_detail_screen.dart
  │   │   └── worker_edit_screen.dart
  │   ├── schedule/              // 새로 추가
  │   │   ├── schedule_list_screen.dart
  │   │   ├── schedule_calendar_screen.dart
  │   │   └── schedule_add_screen.dart
  │   └── contract/              // 새로 추가
  │       ├── contract_list_screen.dart
  │       ├── contract_add_screen.dart
  │       └── contract_detail_screen.dart
  ├── widgets/                    // 기존 폴더 + 신규 위젯
  │   ├── custom_button.dart
  │   ├── custom_text_field.dart
  │   ├── bottom_nav_bar.dart
  │   ├── farm/                  // 새로 추가
  │   │   ├── farm_card.dart
  │   │   ├── farm_filter.dart
  │   │   └── farm_search_bar.dart
  │   ├── field/                 // 새로 추가
  │   │   ├── field_card.dart
  │   │   └── field_map.dart
  │   ├── worker/                // 새로 추가
  │   │   ├── worker_card.dart
  │   │   └── worker_filter.dart
  │   ├── schedule/              // 새로 추가
  │   │   ├── schedule_card.dart
  │   │   └── calendar_widget.dart
  │   └── contract/              // 새로 추가
  │       ├── contract_card.dart
  │       └── payment_timeline.dart
  └── utils/                      // 기존 폴더 + 신규 유틸리티
      ├── custom_loading.dart
      ├── validators.dart        // 새로 추가
      ├── formatters.dart        // 새로 추가
      └── map_utils.dart         // 새로 추가