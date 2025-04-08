import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../profile/profile_screen.dart';
import '../farm/farm_list_screen.dart';
import '../field/field_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BottomNavController _bottomNavController =
      Get.put(BottomNavController());
  final AuthController _authController = Get.find<AuthController>();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    // 페이지 초기화
    _pages.addAll([
      _buildHomePage(),
      const ProfileScreen(),
    ]);

    // 로그인 확인 메시지 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoginSuccessMessage();
    });
  }

  void _showLoginSuccessMessage() {
    final UserModel? user = _authController.userModel.value;
    if (user != null) {
      String message = '로그인이 완료되었습니다.';

      if (user.name != null && user.name!.isNotEmpty) {
        message = '${user.name}님, 환영합니다!';
      } else if (user.email != null && user.email!.isNotEmpty) {
        message = '${user.email}님, 환영합니다!';
      } else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        message = '${user.phoneNumber}님, 환영합니다!';
      }

      Get.snackbar(
        '로그인 성공',
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => _pages[_bottomNavController.selectedIndex.value]),
      bottomNavigationBar: AppBottomNavBar(controller: _bottomNavController),
    );
  }

  // 홈 페이지 구현
  Widget _buildHomePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 600;
        bool isWebLayout = constraints.maxWidth > 900;

        return Scaffold(
          appBar: AppBar(
            title: const Text('홈'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _authController.signOut(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWebLayout ? 1200 : double.infinity,
                ),
                padding: EdgeInsets.all(isSmallScreen ? 20.0 : 40.0),
                child: Column(
                  crossAxisAlignment: isWebLayout
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    if (isWebLayout)
                      // 웹 레이아웃 - 카드와 피쳐 섹션을 나란히 배치
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: _buildWelcomeCard(isSmallScreen),
                          ),
                          const SizedBox(width: 30),
                          Expanded(
                            flex: 6,
                            child: _buildFarmManagementSection(),
                          ),
                        ],
                      )
                    else
                      // 모바일 레이아웃 - 카드와 섹션을 세로로 배치
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeCard(isSmallScreen),
                          const SizedBox(height: 30),
                          _buildFarmManagementSection(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(bool isSmallScreen) {
    return Obx(() {
      final user = _authController.userModel.value;

      String userName = '사용자';
      if (user?.name != null && user!.name!.isNotEmpty) {
        userName = user.name!;
      }

      String loginMethod = '로그인됨';
      if (user != null) {
        switch (user.loginType) {
          case LoginType.naver:
            loginMethod = '네이버 계정으로 로그인됨';
            break;
          case LoginType.facebook:
            loginMethod = '페이스북 계정으로 로그인됨';
            break;
          case LoginType.phone:
            loginMethod = '전화번호로 로그인됨';
            break;
          case LoginType.google:
            loginMethod = '구글 계정으로 로그인됨';
            break;
          default:
            loginMethod = '로그인됨';
        }
      }

      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 20.0 : 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: isSmallScreen ? 30 : 40,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Icon(
                            Icons.person,
                            size: isSmallScreen ? 30 : 40,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안녕하세요, $userName님!',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          loginMethod,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '오늘도 좋은 하루 되세요!',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // 농가 관리 섹션
  Widget _buildFarmManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '농가 및 작업 관리',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 15),

        // 농가 관리 카드
        _buildManagementCard(
          icon: Icons.agriculture,
          title: '농가 관리',
          description: '농가 정보를 등록하고 관리합니다.',
          color: Colors.green.shade600,
          onTap: () {
            Get.to(() => const FarmListScreen());
          },
        ),

        // 농지 관리 카드
        _buildManagementCard(
          icon: Icons.terrain,
          title: '농지 관리',
          description: '각 농가의 농지 정보를 등록하고 관리합니다.',
          color: Colors.brown.shade600,
          onTap: () {
            Get.to(() => const FieldListScreen());
          },
        ),

        // 작업자 관리 카드
        _buildManagementCard(
          icon: Icons.people,
          title: '작업자 관리',
          description: '작업반장 및 운송기사 정보를 관리합니다.',
          color: Colors.blue.shade600,
          onTap: () {
            // TODO: 작업자 목록 화면으로 이동
            Get.snackbar(
              '준비 중',
              '작업자 관리 기능은 다음 업데이트에서 제공됩니다.',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),

        // 작업 일정 관리 카드
        _buildManagementCard(
          icon: Icons.calendar_today,
          title: '작업 일정',
          description: '작업 일정을 등록하고 관리합니다.',
          color: Colors.orange.shade600,
          onTap: () {
            // TODO: 작업 일정 화면으로 이동
            Get.snackbar(
              '준비 중',
              '작업 일정 기능은 다음 업데이트에서 제공됩니다.',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),

        // 계약 관리 카드
        _buildManagementCard(
          icon: Icons.description,
          title: '계약 관리',
          description: '농가와의 계약 정보를 관리합니다.',
          color: Colors.purple.shade600,
          onTap: () {
            // TODO: 계약 목록 화면으로 이동
            Get.snackbar(
              '준비 중',
              '계약 관리 기능은 다음 업데이트에서 제공됩니다.',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
      ],
    );
  }

  // 관리 카드 위젯
  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
