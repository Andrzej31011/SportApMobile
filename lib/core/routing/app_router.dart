import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_ap_mobile/features/auth/screens/login_screen.dart';
import 'package:sport_ap_mobile/features/auth/screens/register_screen.dart';
import 'package:sport_ap_mobile/features/auth/screens/splash_screen.dart';
import 'package:sport_ap_mobile/features/auth/state/auth_controller.dart';
import 'package:sport_ap_mobile/features/auth/state/auth_state.dart';
import 'package:sport_ap_mobile/features/events/screens/event_detail_screen.dart';
import 'package:sport_ap_mobile/features/events/screens/create_event_screen.dart';
import 'package:sport_ap_mobile/features/events/screens/events_screen.dart';
import 'package:sport_ap_mobile/features/home/screens/home_shell_screen.dart';
import 'package:sport_ap_mobile/features/map/screens/map_screen.dart';
import 'package:sport_ap_mobile/features/profile/screens/edit_profile_screen.dart';
import 'package:sport_ap_mobile/features/profile/screens/profile_screen.dart';
import 'package:sport_ap_mobile/features/sport_facilities/screens/create_sport_facility_screen.dart';
import 'package:sport_ap_mobile/features/sport_facilities/screens/sport_facilities_screen.dart';
import 'package:sport_ap_mobile/features/sport_facilities/screens/sport_facility_detail_screen.dart';
import 'package:sport_ap_mobile/features/team_challenges/screens/team_challenge_detail_screen.dart';
import 'package:sport_ap_mobile/features/team_challenges/screens/create_team_challenge_screen.dart';
import 'package:sport_ap_mobile/features/team_challenges/screens/team_challenges_screen.dart';
import 'package:sport_ap_mobile/features/teams/screens/create_team_screen.dart';
import 'package:sport_ap_mobile/features/teams/screens/team_detail_screen.dart';
import 'package:sport_ap_mobile/features/teams/screens/teams_screen.dart';
import 'package:sport_ap_mobile/features/user_challenges/screens/create_user_challenge_screen.dart';
import 'package:sport_ap_mobile/features/user_challenges/screens/user_challenge_detail_screen.dart';
import 'package:sport_ap_mobile/features/user_challenges/screens/user_challenges_screen.dart';
import 'package:sport_ap_mobile/features/users/screens/user_detail_screen.dart';
import 'package:sport_ap_mobile/features/users/screens/users_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final status = authState.status;
      final location = state.uri.path;

      final isAuthRoute = location.startsWith('/auth');
      final isSplashRoute = location == '/splash';

      if (status == AuthStatus.unknown) {
        return isSplashRoute ? null : '/splash';
      }

      if (status == AuthStatus.unauthenticated) {
        return isAuthRoute ? null : '/auth/login';
      }

      if (status == AuthStatus.authenticated) {
        if (isAuthRoute || isSplashRoute || location == '/') {
          return '/map';
        }
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return HomeShellScreen(location: state.uri.path, child: child);
        },
        routes: <RouteBase>[
          GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateEventScreen(),
              ),
              GoRoute(
                path: ':eventId',
                builder: (context, state) {
                  final id = state.pathParameters['eventId'] ?? '';
                  return EventDetailScreen(eventId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/teams',
            builder: (context, state) => const TeamsScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateTeamScreen(),
              ),
              GoRoute(
                path: ':teamId',
                builder: (context, state) {
                  final id = state.pathParameters['teamId'] ?? '';
                  return TeamDetailScreen(teamId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/challenges',
            builder: (context, state) => const UserChallengesScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final userId = state.uri.queryParameters['userId'];
                  return CreateUserChallengeScreen(
                    initialChallengedUserId: userId,
                  );
                },
              ),
              GoRoute(
                path: ':challengeId',
                builder: (context, state) {
                  final id = state.pathParameters['challengeId'] ?? '';
                  return UserChallengeDetailScreen(challengeId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'edit',
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/facilities',
            builder: (context, state) => const SportFacilitiesScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateSportFacilityScreen(),
              ),
              GoRoute(
                path: ':facilityId',
                builder: (context, state) {
                  final id = state.pathParameters['facilityId'] ?? '';
                  return SportFacilityDetailScreen(facilityId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: ':userId',
                builder: (context, state) {
                  final id = state.pathParameters['userId'] ?? '';
                  return UserDetailScreen(userId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/team-challenges',
            builder: (context, state) => const TeamChallengesScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final opponentId = state.uri.queryParameters['opponentId'];
                  return CreateTeamChallengeScreen(
                    initialOpponentId: opponentId,
                  );
                },
              ),
              GoRoute(
                path: ':challengeId',
                builder: (context, state) {
                  final id = state.pathParameters['challengeId'] ?? '';
                  return TeamChallengeDetailScreen(challengeId: id);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
