import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'config/constants.dart';
import 'config/theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/farm_controller.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/farm/farm_list_screen.dart';
import 'screens/farm/farm_add_screen.dart';
import 'screens/farm/farm_detail_screen.dart';
import 'screens/farm/farm_edit_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 색상 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 반응형 레이아웃을 위한 화면 방향 설정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Firebase 앱이 아직 초기화되지 않았다면 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase app already initialized');
    } else {
      rethrow;
    }
  }

  // GetX 컨트롤러 초기화
  Get.put(AuthController());
  Get.put(FarmController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '농가 및 작업 관리',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // 반응형 UI를 위한 설정
      builder: (context, child) {
        // 텍스트 크기 설정 고정 (접근성 설정에 영향 받지 않도록)
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SplashWrapper()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        // 농가 관련 라우트
        GetPage(name: '/farm/list', page: () => const FarmListScreen()),
        GetPage(name: '/farm/add', page: () => const FarmAddScreen()),
        GetPage(
          name: '/farm/detail/:id',
          page: () => FarmDetailScreen(
            farmId: Get.parameters['id'] ?? '',
          ),
        ),
        GetPage(
          name: '/farm/edit/:id',
          page: () => FarmEditScreen(
            farmId: Get.parameters['id'] ?? '',
          ),
        ),
      ],
      home: const SplashWrapper(),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  final AuthController _authController = Get.find<AuthController>();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 첫 실행 여부 확인
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isFirstRun = prefs.getBool(AppConstants.keyIsFirstRun) ?? true;

      // 로그인 상태 확인
      bool isLoggedIn = _authController.firebaseUser.value != null;

      setState(() {
        _initialized = true;
      });

      // 화면 이동
      if (isLoggedIn) {
        Get.offAll(() => const HomeScreen());
      } else if (isFirstRun) {
        Get.offAll(() => const SplashScreen());
      } else {
        Get.offAll(() => const LoginScreen());
      }
    } catch (e) {
      print('App initialization error: $e');

      // 오류 발생 시 로그인 화면으로 이동
      setState(() {
        _initialized = true;
      });
      Get.off(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: !_initialized
            ? const CircularProgressIndicator()
            : const Text('앱을 초기화하는 중입니다...'),
      ),
    );
  }
}
