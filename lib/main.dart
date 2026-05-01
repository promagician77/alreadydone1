import 'dart:async';
import 'dart:math' as math;

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/revenuecat_service.dart';
import '/services/fcm_service.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flutter_flow/nav/nav.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '/env_loader.dart';
import '/services/app_toast.dart';
import '/services/server_toast.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import '/services/sleep_mode_notifier.dart';
import '/services/nav_lock_notifier.dart';
import '/services/library_coachmark_notifier.dart';
import '/widgets/pressable.dart';
import 'index.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> _initializeAppCritical() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await FlutterFlowTheme.initialize();

  try {
    await loadEnv();
  } catch (e) {
    debugPrint('dotenv load failed: $e');
    rethrow;
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseUrl.isEmpty || supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    throw Exception('SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env');
  }
  debugPrint('🔍 Initializing Supabase...');
  await SupabaseService.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  debugPrint('✅ Supabase initialized successfully');

  BackendClient.initialize(baseUrl: dotenv.env['BACKEND_URL']);

  debugPrint('🔍 Initializing AuthListener...');
  AppStateNotifier.instance.initAuthListener();
  debugPrint('✅ AuthListener initialized successfully');
}

/// Slow init (Firebase, RevenueCat, backend check, FCM). Run after first frame to avoid blocking splash.
Future<void> _initializeAppDeferred() async {
  debugPrint('🔍 Deferred: Firebase...');
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  } catch (e, st) {
    debugPrint('❌ Firebase initialization failed: $e');
    debugPrint('$st');
  }

  debugPrint('🔍 Deferred: RevenueCat...');
  try {
    RevenueCatService.logFlow('Startup', 'deferred configure() (anonymous until auth)');
    await RevenueCatService.instance.configure();
    RevenueCatService.logFlow(
      'Startup',
      'deferred configure finished isConfigured=${RevenueCatService.instance.isConfigured}',
    );
    debugPrint('✅ RevenueCat initialized successfully');
  } catch (e, st) {
    RevenueCatService.logFlow('Startup', 'deferred configure FAILED: $e');
    debugPrint('RevenueCat configure error: $e');
    debugPrint('$st');
  }

  debugPrint('🔍 Deferred: Backend connection check...');
  try {
    final connected = await BackendClient.checkConnection();
    if (connected) {
      debugPrint('Backend connected at ${BackendClient.baseUrl}');
    } else {
      debugPrint('Backend unreachable at ${BackendClient.baseUrl}');
    }
  } catch (e) {
    debugPrint('Backend check failed: $e');
  }

  if (!kIsWeb && firebaseInitialized) {
    debugPrint('🔍 Deferred: FCM...');
    try {
      await FcmService.initialize();
      debugPrint('✅ FCM initialized successfully');
    } catch (e) {
      debugPrint('FCM init failed: $e');
    }
  }
}

void main() async {
  runZonedGuarded(() async {
    await _initializeAppCritical();
    runApp(MyApp());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppDeferred();
    });
  }, (error, stack) {
    debugPrint('Uncaught error in main: $error');
    debugPrint('$stack');
    // Keep the app running; show a friendly toast instead of an error screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ServerToast.show();
    });
  });
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.message, required this.stack});

  final String message;
  final String stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Startup error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(message, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 24),
                  const Text('Stack trace:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SelectableText(stack, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    _initAuthDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      FcmService.onAppResumed();
    }
  }

  void _initAuthDeepLinks() {
    final appLinks = AppLinks();
    void handleLink(Uri? uri) async {
      if (uri == null) return;
      try {
        if (!uri.toString().contains('auth/callback')) return;
        final userIdStr = uri.queryParameters['userId'];
        final userId = userIdStr != null && userIdStr.isNotEmpty
            ? int.tryParse(userIdStr)
            : null;

        final newEmail = await SupabaseService.handleAuthCallbackUrl(uri.toString());
        if (newEmail == null) return;

        if (userId != null) {
          try {
            await BackendClient.updateUserProfile(userId, email: newEmail);
          } catch (_) {}
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = appNavigatorKey.currentContext;
          if (ctx != null) {
            AppToast.success(ctx, 'Email updated successfully!');
            GoRouter.of(ctx).go('/');
          }
        });
      } catch (_) {}
    }

    appLinks.getInitialLink().then(handleLink);
    appLinks.uriLinkStream.listen(handleLink);
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Already Done',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}

class _NavColors {
  static const surface = Color(0xFFFEFDFB);
  static const ink = Color(0xFF1C1917);
  static const inkSoft = Color(0xFF78716C);
  static const gold = Color(0xFFB8861E);  
  static const sleepSurface = Color(0xFF1A1F3A);
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.active, required this.sleepStyle});

  final IconData icon;
  final bool active;
  final bool sleepStyle;

  @override
  Widget build(BuildContext context) {
    final color = sleepStyle
        ? (active ? const Color(0xFFC4B5FD) : Colors.white.withValues(alpha: 0.5))
        : (active ? _NavColors.gold : _NavColors.inkSoft);
    return Icon(icon, size: 20, color: color);
  }
}

class NavBarPage extends StatefulWidget {
  NavBarPage({
    Key? key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  }) : super(key: key);

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage> with SingleTickerProviderStateMixin {
  String _currentPageName = 'HomeDashboard';
  late Widget? _currentPage;

  static const String _doneLibraryCoachmarkKeyPrefix =
      'done_library_coachmark_v1_';

  late final AnimationController _coachmarkPulseController;
  bool _showDoneLibraryCoachmark = false;

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
    _coachmarkPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    libraryCoachmarkRequestNotifier.addListener(_onLibraryCoachmarkRequest);
  }

  void _onLibraryCoachmarkRequest() {
    if (!libraryCoachmarkRequestNotifier.value) return;
    libraryCoachmarkRequestNotifier.value = false;
    if (mounted) {
      setState(() => _showDoneLibraryCoachmark = true);
    }
  }

  @override
  void dispose() {
    libraryCoachmarkRequestNotifier.removeListener(_onLibraryCoachmarkRequest);
    _coachmarkPulseController.dispose();
    super.dispose();
  }

  String _doneLibraryCoachmarkStorageKey() {
    final user = SupabaseService.currentUser;
    final userKey = user?.id.toLowerCase() ?? 'guest';
    return '$_doneLibraryCoachmarkKeyPrefix$userKey';
  }

  Future<void> _dismissDoneLibraryCoachmark() async {
    if (!_showDoneLibraryCoachmark) return;
    setState(() => _showDoneLibraryCoachmark = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doneLibraryCoachmarkStorageKey(), true);
  }

  void _onNavTap(int index) {
    final tabKeys = ['HomeDashboard', 'Player', 'Desires', 'Profile'];
    if (index == 2) {
      _dismissDoneLibraryCoachmark();
    }
    safeSetState(() {
      _currentPage = null;
      _currentPageName = tabKeys[index];
    });
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    int currentIndex,
    bool sleepStyle,
    VoidCallback? onTap,
  ) {
    final selectedColor = sleepStyle ? const Color(0xFFC4B5FD) : _NavColors.gold;
    final unselectedColor = sleepStyle ? Colors.white.withValues(alpha: 0.5) : _NavColors.inkSoft;
    final active = currentIndex == index;
    final color = active ? selectedColor : unselectedColor;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabKeys = ['HomeDashboard', 'Player', 'Desires', 'Profile'];
    final tabs = {
      'HomeDashboard': HomeDashboardWidget(),
      'Player': PlayerWidget(),
      'Desires': DesiresWidget(),
      'Profile': ProfileWidget(),
    };
    final currentIndex = tabKeys.indexOf(_currentPageName);
    final isPlayerSleepMode = _currentPageName == 'Player';

    return ValueListenableBuilder<bool>(
      valueListenable: sleepModeNotifier,
      builder: (context, sleepMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: navLockNotifier,
          builder: (context, navLocked, __) {
            final useSleepStyle = isPlayerSleepMode && sleepMode;
            final barColor = useSleepStyle ? _NavColors.sleepSurface : _NavColors.surface;
            final selectedColor = useSleepStyle ? const Color(0xFFC4B5FD) : _NavColors.gold;
            final unselectedColor =
                useSleepStyle ? Colors.white.withValues(alpha: 0.5) : _NavColors.inkSoft;

            return Scaffold(
              resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
              body: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(child: _currentPage ?? tabs[_currentPageName]!),
                      _buildNavBar(context, barColor, currentIndex, useSleepStyle, navLocked),
                    ],
                  ),
                  if (_showDoneLibraryCoachmark)
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: true,
                        child: Container(
                          color: _NavColors.ink.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  if (_showDoneLibraryCoachmark)
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 92,
                      child: _DoneLibraryCoachmarkCard(
                        onGotIt: () => _dismissDoneLibraryCoachmark(),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavBar(
    BuildContext context,
    Color barColor,
    int currentIndex,
    bool useSleepStyle,
    bool navLocked,
  ) {
    final shouldHighlightDone = _showDoneLibraryCoachmark && !navLocked;
    return ColoredBox(
      color: barColor,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(useSleepStyle ? 0.2 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context,
                    Icons.home_rounded,
                    'Home',
                    0,
                    currentIndex,
                    useSleepStyle,
                    navLocked ? null : () => _onNavTap(0),
                  ),
                  _buildNavItem(
                    context,
                    Icons.play_arrow,
                    'Player',
                    1,
                    currentIndex,
                    useSleepStyle,
                    navLocked ? null : () => _onNavTap(1),
                  ),
                  AnimatedBuilder(
                    animation: _coachmarkPulseController,
                    builder: (context, child) {
                      final t = _coachmarkPulseController.value * math.pi * 2;
                      final pulse = (math.sin(t) + 1) / 2; // 0..1
                      final bgAlpha = shouldHighlightDone ? (0.28 + pulse * 0.16) : 0.0;
                      final glowAlpha = shouldHighlightDone ? (0.30 + pulse * 0.24) : 0.0;
                      return Container(
                        decoration: BoxDecoration(
                          color: shouldHighlightDone
                              ? _NavColors.gold.withValues(alpha: bgAlpha)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: shouldHighlightDone
                              ? [
                                  BoxShadow(
                                    color: _NavColors.gold.withValues(alpha: glowAlpha),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: child,
                      );
                    },
                    child: _buildNavItem(
                      context,
                      Icons.check,
                      'Done',
                      2,
                      currentIndex,
                      useSleepStyle,
                      navLocked ? null : () => _onNavTap(2),
                    ),
                  ),
                  _buildNavItem(
                    context,
                    Icons.density_medium,
                    'Profile',
                    3,
                    currentIndex,
                    useSleepStyle,
                    navLocked ? null : () => _onNavTap(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoneLibraryCoachmarkCard extends StatelessWidget {
  const _DoneLibraryCoachmarkCard({required this.onGotIt});

  final VoidCallback onGotIt;

  @override
  Widget build(BuildContext context) {
    // Match [PlayerWidget] settings coachmark (cream card, QUICK TIP, tail to Done tab).
    const cardBg = Color(0xFFFFFDF7);
    const textMuted = Color(0xFF7A6F5E);
    const labelGold = Color(0xFFB8862F);
    final goldStroke = _NavColors.gold.withValues(alpha: 0.95);
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: goldStroke, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 14),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: _NavColors.gold.withValues(alpha: 0.16),
              blurRadius: 48,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: -9,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border(
                        right: BorderSide(color: goldStroke, width: 1.5),
                        bottom: BorderSide(color: goldStroke, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK TIP',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.2,
                      height: 1.2,
                      color: labelGold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your library lives here',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      height: 1.12,
                      letterSpacing: -0.2,
                      color: _NavColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This is your library where all your manifestations are stored.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      height: 1.5,
                      color: textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: Pressable(
                      onTap: onGotIt,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: _NavColors.gold,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _NavColors.gold.withValues(alpha: 0.32),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Got it',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
