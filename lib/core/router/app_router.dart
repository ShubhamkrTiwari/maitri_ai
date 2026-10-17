import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/avatar/presentation/screens/avatar_builder_screen.dart';
import '../../features/topics/presentation/screens/topic_picker_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/memory/presentation/screens/memory_manager_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../services/supabase_service.dart';
import '../widgets/main_shell_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = SupabaseService.isAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';

      if (isSplash) return null;

      if (!isLoggedIn && !isLogin) {
        return '/login';
      }

      if (isLoggedIn && isLogin) {
        return '/chat';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/avatar-builder',
            builder: (context, state) => const AvatarBuilderScreen(),
          ),
          GoRoute(
            path: '/topic-picker',
            builder: (context, state) => const TopicPickerScreen(),
          ),
          GoRoute(
            path: '/memories',
            builder: (context, state) => const MemoryManagerScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
