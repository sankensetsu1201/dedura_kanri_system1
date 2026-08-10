// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

// widgets
import 'widgets/admin_only_route.dart';
import 'widgets/attendance_summary_page.dart';

// pages - auth / home
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/home/home_page.dart';

// pages - admin
import 'pages/admin/admin_home.dart';
import 'pages/admin/admin_dashboard.dart';
import 'pages/admin/admin_add_worker_page.dart';
import 'pages/admin/user_list_page.dart';
import 'pages/admin/user_detail_page.dart';
import 'pages/admin/user_edit_page.dart';
import 'pages/admin/month_summary_my_page.dart';
import 'pages/admin/demen_month_page.dart';
import 'pages/admin/genba_month_page.dart';
import 'pages/admin/admin_settings.dart';
import 'pages/admin/worker_month_page.dart';

// pages - genba
import 'pages/genba/genba_add_page.dart';
import 'package:demen_app/pages/genba/genba_list_page.dart';


// pages - demen (一般)
import 'pages/demen/demen_today_page.dart';
import 'pages/demen/demen_add_page.dart';
import 'pages/demen/my_demen_page.dart';
import 'pages/demen/my_month_summary_page.dart';
import 'package:demen_app/pages/demen/demen_list_page.dart';

import 'pages/demen/demen_by_genba_page.dart';
import 'pages/demen/demen_by_worker_page.dart';

// ⭐ 正しいファイル名に修正済み

import 'pages/demen/genba_summary_month_page.dart';

import 'pages/demen/today_genba_summary_page.dart';
import 'pages/demen/today_worker_summary_page.dart';
import 'pages/demen/worker_summary_page.dart';

// ⭐ 一般ユーザー用の詳細・編集ページ
import 'pages/demen/demen_detail_page.dart' as user;
import 'pages/demen/demen_edit_page.dart' as user;

// pages - worker
import 'pages/worker/demen_input_page.dart';
import 'pages/worker/worker_list_page.dart';

import 'package:demen_app/pages/admin/demen_summary_page.dart';
import 'package:demen_app/pages/admin/month_summary_all_page.dart';

import 'splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '出面管理システム',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange,
        fontFamily: 'NotoSansJP',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      locale: const Locale('ja', 'JP'),
      home: const LoginPage(),

      routes: {
        // -------------------------
        // 認証
        // -------------------------
        "/login": (_) => const LoginPage(),
        "/register": (_) => const RegisterPage(),

        // -------------------------
        // ホーム（一般）
        // -------------------------
        "/home": (_) => const HomePage(),

        // -------------------------
        // 出面（一般）
        // -------------------------
        "/demen_today": (_) => const DemenTodayPage(),
        "/demen_add": (_) => const DemenAddPage(),
        "/my_demen": (_) => const MyDemenPage(),
        "/attendance_summary": (_) => const AttendanceSummaryPage(),

        "/my_month_summary": (context) {
          final workerId = ModalRoute.of(context)!.settings.arguments as String;
          return MyMonthSummaryPage(workerId: workerId);
        },

        "/demen_list": (_) => const DemenListPage(),

        "/demen_by_genba": (context) {
          final genbaId = ModalRoute.of(context)!.settings.arguments as String;
          return DemenByGenbaPage(genbaId: genbaId);
        },

        "/demen_by_worker": (context) {
          final workerId = ModalRoute.of(context)!.settings.arguments as String;
          return DemenByWorkerPage(workerId: workerId);
        },

        "/month_summary": (context) {
         return const MonthSummaryMyPage();
        },
        "/demen_summary": (_) => const DemenSummaryPage(),

        // ⭐ 月次の現場別集計（修正済み）
        "/genba_summary_month": (_) => const GenbaSummaryMonthPage(),

        "/today_genba_summary": (_) => const TodayGenbaSummaryPage(),
        "/today_worker_summary": (_) => const TodayWorkerSummaryPage(),
        "/worker_summary": (_) => const WorkerSummaryPage(),

        "/demen_input": (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String?;
          return DemenInputPage(workerId: id);
        },

        "/worker_list": (_) => const WorkerListPage(),

        // ⭐ 一般ユーザー用の詳細ページ
        "/demen_detail": (context) {
          final docId = ModalRoute.of(context)!.settings.arguments as String;
          return user.DemenDetailPage(docId: docId);
        },

        // ⭐ 一般ユーザー用の編集ページ
        "/demen_edit": (context) {
          final docId = ModalRoute.of(context)!.settings.arguments as String;
          return user.DemenEditPage(docId: docId);
        },
        "/admin/month_summary_all": (_) => const MonthSummaryAllPage(),

        // -------------------------
        // 管理者専用ページ（admin）
        // -------------------------
        "/admin/home": (_) => AdminOnlyRoute(child: const AdminHomePage()),
        "/admin/dashboard": (_) => AdminOnlyRoute(child: const AdminDashboardPage()),
        "/admin/add_worker": (_) => AdminOnlyRoute(child: const AdminAddWorkerPage()),
        "/admin/user_list": (_) => AdminOnlyRoute(child: const UserListPage()),

        "/admin/user_detail": (context) {
          final workerId = ModalRoute.of(context)!.settings.arguments as String;
          return AdminOnlyRoute(child: UserDetailPage(workerId: workerId));
        },

        "/admin/user_edit": (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AdminOnlyRoute(
            child: UserEditPage(
              uid: args['uid'],
              initialData: args['initialData'],
            ),
          );
        },

        // ⭐ admin の demen_edit_page は削除したので消す（エラー解決）
        // "/admin/demen_edit": (_) => AdminOnlyRoute(child: DemenEditPage()),

        "/admin/settings": (_) => AdminOnlyRoute(child: const AdminSettingsPage()),
        "/admin/worker_month": (_) => AdminOnlyRoute(child: const WorkerMonthPage()),
        "/admin/demen_month": (_) => AdminOnlyRoute(child: const DemenMonthPage()),
        "/admin/genba_month": (_) => AdminOnlyRoute(child: const GenbaMonthPage()),
        "/admin/month_summary": (_) => AdminOnlyRoute(child: const MonthSummaryMyPage()),
        "/admin/genba/add": (_) => AdminOnlyRoute(child: const GenbaAddPage()),
        "/admin/genba/list": (_) => AdminOnlyRoute(child: const GenbaListPage()),
      },
    );
  }
}
