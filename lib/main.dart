import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/fcm_service.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flutter_flow/nav/nav.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '/services/app_toast.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import '/services/sleep_mode_notifier.dart';
import '/widgets/pressable.dart';
import 'index.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await FlutterFlowTheme.initialize();
  await dotenv.load(fileName: ".env");

  await SupabaseService.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!, 
  );

  BackendClient.initialize(baseUrl: dotenv.env['BACKEND_URL']);

  final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']?.trim();
  if (stripeKey != null && stripeKey.isNotEmpty) {
    Stripe.publishableKey = stripeKey;
    await Stripe.instance.applySettings();
  } else {
    debugPrint('Stripe: STRIPE_PUBLISHABLE_KEY not set in .env — payment sheet will not work until you add it.');
  }

  final connected = await BackendClient.checkConnection();
  if (connected) {
    debugPrint('Backend connected at ${BackendClient.baseUrl}');
  } else {
    debugPrint('Backend unreachable at ${BackendClient.baseUrl} — is the server running?');
  }

  AppStateNotifier.instance.initAuthListener();

  await FcmService.initialize();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
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

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    _initAuthDeepLinks();
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
      title: 'Already App',
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

/// Nav bar design tokens (matches _AppColors)
class _NavColors {
  static const surface = Color(0xFFFEFDFB);
  static const inkSoft = Color(0xFF78716C);
  static const gold = Color(0xFFB8861E);
  /// Matches player sleep mode content (0xFF1A1F3A)
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

class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'HomeDashboard';
  late Widget? _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
  }

  void _onNavTap(int index) {
    final tabKeys = ['HomeDashboard', 'Player', 'Desires', 'Profile'];
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
    VoidCallback onTap,
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
        final useSleepStyle = isPlayerSleepMode && sleepMode;
        final barColor = useSleepStyle ? _NavColors.sleepSurface : _NavColors.surface;
        final selectedColor = useSleepStyle ? const Color(0xFFC4B5FD) : _NavColors.gold;
        final unselectedColor = useSleepStyle ? Colors.white.withValues(alpha: 0.5) : _NavColors.inkSoft;

        return Scaffold(
          resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
          body: Column(
            children: [
              Expanded(child: _currentPage ?? tabs[_currentPageName]!),
              _buildNavBar(context, barColor, currentIndex, useSleepStyle),
            ],
          ),
        );
          },
    );
  }

  Widget _buildNavBar(BuildContext context, Color barColor, int currentIndex, bool useSleepStyle) {
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
                  _buildNavItem(context, Icons.home_rounded, 'Home', 0, currentIndex, useSleepStyle, () => _onNavTap(0)),
                  _buildNavItem(context, Icons.play_arrow, 'Player', 1, currentIndex, useSleepStyle, () => _onNavTap(1)),
                  _buildNavItem(context, Icons.check, 'Done', 2, currentIndex, useSleepStyle, () => _onNavTap(2)),
                  _buildNavItem(context, Icons.density_medium, 'Profile', 3, currentIndex, useSleepStyle, () => _onNavTap(3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
