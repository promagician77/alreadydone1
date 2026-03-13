import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

import '/main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

import '/index.dart';
import '/services/backend_client.dart';
import '/services/fcm_service.dart';
import '/services/revenuecat_service.dart';
import '/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;
import '/services/onboarding_service.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// True if user profile (Supabase/backend) has active subscription: plan is weekly or monthly
/// and rc_subscription_status is not canceled.
Future<bool> _hasActiveSubscriptionFromProfile() async {
  try {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) return false;
    final profile = await BackendClient.getUserProfile(userId);
    final plan = (profile['rc_subscription_plan'] ?? profile['rc_subscription_Plan'])
        ?.toString()
        .toLowerCase()
        .trim();
    final status = (profile['rc_subscription_status'] ?? profile['rc_subscription_Status'])
        ?.toString()
        .toLowerCase()
        .trim();
    if (status == 'canceled') return false;
    return plan == 'weekly' || plan == 'monthly';
  } catch (_) {
    return false;
  }
}

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  bool showSplashImage = true;

  bool get isAuthenticated => SupabaseService.isAuthenticated;

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }

  void initAuthListener() {
    final sub = SupabaseService.authStateChanges.listen((state) async {
      final isSignedIn = state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.initialSession;
      if (isSignedIn && state.session != null) {
        await SupabaseService.ensureUserProfileFromAuth();
        await FcmService.onUserSignedIn();
      }
      notifyListeners();
    });
    sub.onError((Object e, StackTrace st) async {
      debugPrint('Auth state error (e.g. invalid refresh token): $e');
      try {
        await SupabaseService.client.auth.signOut();
      } catch (_) {}
      notifyListeners();
    });
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      redirect: (context, state) async {
        final isAuth = appStateNotifier.isAuthenticated;
        final path = state.uri.path;
        final isAuthRoute = path == LoginWidget.routePath ||
            path == SignUpWidget.routePath ||
            path == PasswordResetWidget.routePath ||
            path == EmailVerificationWidget.routePath;
        final isOnboardingRoute = path.startsWith('/onboarding');

        if (!isAuth && !isAuthRoute) {
          return LoginWidget.routePath;
        }
        if (isAuth && isAuthRoute) {
          // Subscribed users skip onboarding and go straight to home
          if (RevenueCatService.instance.isSupported) {
            final subscribed = await RevenueCatService.instance.isSubscribed();
            if (subscribed) return path == LoginWidget.routePath ? '/?fromLogin=1' : '/';
          }
          // Check Supabase/backend profile: active weekly or monthly and not canceled -> go home
          final hasActiveSubscriptionFromProfile = await _hasActiveSubscriptionFromProfile();
          if (hasActiveSubscriptionFromProfile) {
            return path == LoginWidget.routePath ? '/?fromLogin=1' : '/';
          }
          final completed = await OnboardingService.hasCompletedOnboarding();
          if (!completed) return OnboardingSplashWidget.routePath;
          return path == LoginWidget.routePath ? '/?fromLogin=1' : '/';
        }
        if (isAuth && !isOnboardingRoute) {
          // Subscribed users stay on current route (e.g. home); others must complete onboarding
          if (RevenueCatService.instance.isSupported) {
            final subscribed = await RevenueCatService.instance.isSubscribed();
            if (subscribed) return null;
          }
          final hasActiveSubscriptionFromProfile = await _hasActiveSubscriptionFromProfile();
          if (hasActiveSubscriptionFromProfile) return null;
          final completed = await OnboardingService.hasCompletedOnboarding();
          if (!completed) return OnboardingSplashWidget.routePath;
        }
        if (isAuth && isOnboardingRoute) {
          final completed = await OnboardingService.hasCompletedOnboarding();
          if (completed && path == OnboardingSplashWidget.routePath) {
            return '/';
          }
        }
        return null;
      },
      // Show routing errors explicitly instead of silently sending users home.
      errorBuilder: (context, state) {
        debugPrint('GoRouter error: ${state.error} at ${state.uri}');
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Something went wrong while opening this page.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${state.error ?? 'Unknown routing error'}\n\nPath: ${state.uri}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      routes: [
        FFRoute(
          name: HomeDashboardWidget.routeName,
          path: HomeDashboardWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'HomeDashboard')
              : HomeDashboardWidget(),
        ),
        FFRoute(
          name: DesiresWidget.routeName,
          path: DesiresWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'Desires')
              : DesiresWidget(),
        ),
        FFRoute(
          name: PlayerWidget.routeName,
          path: PlayerWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'Player')
              : NavBarPage(
                  initialPage: 'Player',
                  page: PlayerWidget(
                    storyId: params.getParam('storyId', ParamType.int) as int?,
                    categoryLabel: params.getParam('categoryLabel', ParamType.String),
                    title: params.getParam('title', ParamType.String),
                    subtitle: params.getParam('subtitle', ParamType.String),
                    durationLabel: params.getParam('durationLabel', ParamType.String),
                    playUrl: params.getParam('playUrl', ParamType.String),
                    storyPreview: params.getParam('storyPreview', ParamType.String),
                    voiceId: params.getParam('voiceId', ParamType.String),
                  ),
                ),
        ),
        FFRoute(
          name: ProfileWidget.routeName,
          path: ProfileWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'Profile')
              : ProfileWidget(),
        ),
        FFRoute(
          name: SignUpWidget.routeName,
          path: SignUpWidget.routePath,
          builder: (context, params) => SignUpWidget(),
        ),
        FFRoute(
          name: LoginWidget.routeName,
          path: LoginWidget.routePath,
          builder: (context, params) => LoginWidget(),
        ),
        FFRoute(
          name: PasswordResetWidget.routeName,
          path: PasswordResetWidget.routePath,
          builder: (context, params) => PasswordResetWidget(),
        ),
        FFRoute(
          name: EmailVerificationWidget.routeName,
          path: EmailVerificationWidget.routePath,
          builder: (context, params) {
            final userIdStr = params.getParam('userId', ParamType.String);
            final userId = userIdStr != null && userIdStr.isNotEmpty
                ? int.tryParse(userIdStr)
                : null;
            return EmailVerificationWidget(
              email: params.getParam('email', ParamType.String) ?? '',
              isEmailChange: params.getParam('changeEmail', ParamType.String) == '1',
              userId: userId,
            );
          },
        ),
        FFRoute(
          name: OnboardingVoiceWidget.routeName,
          path: OnboardingVoiceWidget.routePath,
          builder: (context, params) => OnboardingVoiceWidget(),
        ),
        FFRoute(
          name: OnboardingPlayerWidget.routeName,
          path: OnboardingPlayerWidget.routePath,
          builder: (context, params) => OnboardingPlayerWidget(),
        ),
        FFRoute(
          name: OnboardingDesireWidget.routeName,
          path: OnboardingDesireWidget.routePath,
          builder: (context, params) => OnboardingDesireWidget(
            fromDesires: params.state.extraMap['fromDesires'] == true,
          ),
        ),
        FFRoute(
          name: OnboardingPersonalizeWidget.routeName,
          path: OnboardingPersonalizeWidget.routePath,
          builder: (context, params) => OnboardingPersonalizeWidget(),
        ),
        FFRoute(
          name: OnboardingVoiceSelectionWidget.routeName,
          path: OnboardingVoiceSelectionWidget.routePath,
          builder: (context, params) => OnboardingVoiceSelectionWidget(),
        ),
        FFRoute(
          name: OnboardingSplashWidget.routeName,
          path: OnboardingSplashWidget.routePath,
          builder: (context, params) => OnboardingSplashWidget(),
        ),
        FFRoute(
          name: SubscriptionWidget.routeName,
          path: SubscriptionWidget.routePath,
          builder: (context, params) => SubscriptionWidget(),
        ),
        // Root path last so prefix matching doesn't catch /onboarding/complete etc.
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => NavBarPage(),
        ),
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
