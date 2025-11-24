import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';
import 'onboarding_providers.dart';
import '../../widgets/location_selector.dart';

/// Root onboarding flow page that switches between steps based on [OnboardingState.stepIndex].
class OnboardingFlowPage extends ConsumerWidget {
  const OnboardingFlowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final onboardingState = ref.watch(onboardingProvider);

    return userProfileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Initialize onboarding state once from the profile.
        if (onboardingState == null) {
          // Delay provider modification until after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(onboardingProvider.notifier).loadFromProfile(profile);
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final state = ref.watch(onboardingProvider);
        if (state == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        Widget stepBody;
        switch (state.stepIndex) {
          case 0:
            stepBody = _WelcomeStep(
              onNext: () {
                ref.read(onboardingProvider.notifier).nextStep();
              },
            );
            break;
          case 1:
            stepBody = _LocationPermissionStep(
              onSkip: () {
                ref.read(onboardingProvider.notifier).nextStep();
              },
              onGranted: () {
                ref
                    .read(onboardingProvider.notifier)
                    .setLocationPermissionGranted(true);
                ref.read(onboardingProvider.notifier).nextStep();
              },
            );
            break;
          case 2:
            stepBody = _LocationSelectorStep(
              onNext: () {
                ref.read(onboardingProvider.notifier).nextStep();
              },
              onBack: () {
                ref.read(onboardingProvider.notifier).prevStep();
              },
            );
            break;
          case 3:
            stepBody = _InterestsStep(
              onNext: () {
                ref.read(onboardingProvider.notifier).nextStep();
              },
              onBack: () {
                ref.read(onboardingProvider.notifier).prevStep();
              },
            );
            break;
          case 4:
            stepBody = _NotificationsStep(
              onNext: () {
                ref.read(onboardingProvider.notifier).nextStep();
              },
              onBack: () {
                ref.read(onboardingProvider.notifier).prevStep();
              },
            );
            break;
          case 5:
          default:
            stepBody = _CompleteStep(
              profile: profile,
              onFinish: () async {
                await _completeOnboarding(context, ref, profile);
              },
              onBack: () {
                ref.read(onboardingProvider.notifier).prevStep();
              },
            );
        }

        return Scaffold(
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: stepBody,
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error loading profile: $e')),
      ),
    );
  }

  Future<void> _completeOnboarding(
    BuildContext context,
    WidgetRef ref,
    UserProfile initialProfile,
  ) async {
    final state = ref.read(onboardingProvider);
    if (state == null) return;

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      // Fallback: sign in anonymously and create basic profile.
      final cred = await auth.signInAnonymously();
      final uid = cred.user!.uid;
      final profile = UserProfile.initial(uid).copyWith(
        hasCompletedOnboarding: true,
        defaultStateId: state.stateId,
        defaultMetroId: state.metroId,
        defaultAreaId: state.areaId,
        interests: state.interests,
        defaultSection: state.defaultSection,
        notifGeneral: state.notifGeneral,
        notifEvents: state.notifEvents,
        notifEatDrink: state.notifEatDrink,
        notifClubs: state.notifClubs,
        notifSavedPlaces: state.notifSavedPlaces,
      );
      await UserProfileService.saveProfile(profile);
      if (context.mounted) {
        context.go('/');
      }
      return;
    }

    final updated = initialProfile.copyWith(
      hasCompletedOnboarding: true,
      defaultStateId: state.stateId,
      defaultMetroId: state.metroId,
      defaultAreaId: state.areaId,
      interests: state.interests,
      defaultSection: state.defaultSection,
      notifGeneral: state.notifGeneral,
      notifEvents: state.notifEvents,
      notifEatDrink: state.notifEatDrink,
      notifClubs: state.notifClubs,
      notifSavedPlaces: state.notifSavedPlaces,
    );

    await UserProfileService.saveProfile(updated);

    if (context.mounted) {
      context.go('/'); // go to home (or your shell route)
    }
  }
}

/// STEP 0 – Welcome
class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      key: const ValueKey('welcome_step'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text(
            'Welcome to Visit Haralson',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Discover local places, events, and experiences around Haralson County and beyond.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          const _Bullet(text: 'Find things to do nearby'),
          const _Bullet(text: 'Save your favorite places'),
          const _Bullet(text: 'Explore events, clubs, and more'),
          const Spacer(),
          ElevatedButton(
            onPressed: onNext,
            child: const Text('Get started'),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

/// STEP 1 – Location permission (UI only; hook up geolocator later)
class _LocationPermissionStep extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback onGranted;

  const _LocationPermissionStep({
    required this.onSkip,
    required this.onGranted,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      key: const ValueKey('location_permission_step'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.location_on, size: 80, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'Use your location?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We use your device location to show nearby places, events, and clubs.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              // TODO: integrate permission_handler or geolocator
              onGranted();
            },
            child: const Text('Enable location'),
          ),
          TextButton(
            onPressed: onSkip,
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }
}

/// STEP 2 – Home location selection
class _LocationSelectorStep extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _LocationSelectorStep({
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider)!;
    final notifier = ref.read(onboardingProvider.notifier);

    return Padding(
      key: const ValueKey('location_selector_step'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Text(
                'Choose your home area',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us show the right places and events first. You can change it later in Settings.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // 🔹 Use your shared LocationSelector
          Expanded(
            child: LocationSelector(
              initialStateId: state.stateId,
              initialMetroId: state.metroId,
              initialAreaId: state.areaId,
              onChanged: (LocationValue value) {
                notifier.updateLocation(
                  stateId: value.stateId ?? '',
                  metroId: value.metroId ?? '',
                  areaId: value.areaId ?? '',
                );
              },
              showTitle: true,
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

/// STEP 3 – Interests
class _InterestsStep extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _InterestsStep({
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider)!;
    final notifier = ref.read(onboardingProvider.notifier);

    const interestOptions = [
      ['eat', 'Eat & Drink'],
      ['events', 'Events'],
      ['outdoors', 'Outdoors & Parks'],
      ['attractions', 'Attractions'],
      ['lodging', 'Lodging'],
      ['shopping', 'Shopping'],
      ['clubs', 'Clubs & Groups'],
      ['nightlife', 'Nightlife'],
      ['family', 'Family Activities'],
      ['recreation', 'Recreation'],
      ['arts', 'Arts & Culture'],
      ['history', 'History & Landmarks'],
      ['festivals', 'Festivals'],
      ['passport', 'Local Passport / Check-ins'],
      ['trip', 'Trip Planner'],
    ];

    return Padding(
      key: const ValueKey('interests_step'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Text(
                'What are you interested in?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a few so we can personalize your experience.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in interestOptions)
                    FilterChip(
                      label: Text(option[1]),
                      selected: onboardingState.interests.contains(option[0]),
                      onSelected: (_) {
                        notifier.toggleInterest(option[0]);
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

/// STEP 4 – Notifications
class _NotificationsStep extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _NotificationsStep({
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider)!;
    final notifier = ref.read(onboardingProvider.notifier);

    return Padding(
      key: const ValueKey('notifications_step'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Text(
                'Stay in the loop?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose what you’d like to get notified about.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('General updates'),
            value: state.notifGeneral,
            onChanged: (v) => notifier.setNotifications(general: v),
          ),
          SwitchListTile(
            title: const Text('Local events'),
            value: state.notifEvents,
            onChanged: (v) => notifier.setNotifications(events: v),
          ),
          SwitchListTile(
            title: const Text('Eat & Drink specials'),
            value: state.notifEatDrink,
            onChanged: (v) => notifier.setNotifications(eatDrink: v),
          ),
          SwitchListTile(
            title: const Text('Clubs & groups'),
            value: state.notifClubs,
            onChanged: (v) => notifier.setNotifications(clubs: v),
          ),
          SwitchListTile(
            title: const Text('Updates to saved places'),
            value: state.notifSavedPlaces,
            onChanged: (v) => notifier.setNotifications(savedPlaces: v),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

/// STEP 5 – Completion
class _CompleteStep extends StatelessWidget {
  final UserProfile profile;
  final Future<void> Function() onFinish;
  final VoidCallback onBack;

  const _CompleteStep({
    required this.profile,
    required this.onFinish,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      key: const ValueKey('complete_step'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.celebration, size: 80, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'You’re all set!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We’ve set up your home area and preferences. Let’s start exploring.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await onFinish();
              },
              child: const Text('Start exploring'),
            ),
          ),
          TextButton(
            onPressed: onBack,
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}

/// Simple, self-contained location selector used only for onboarding.
/// You can later replace this with your shared `LocationSelector` widget.
class _SimpleLocationSelector extends StatefulWidget {
  final String? initialStateId;
  final String? initialMetroId;
  final String? initialAreaId;
  final void Function(String? stateId, String? metroId, String? areaId)
      onChanged;

  const _SimpleLocationSelector({
    required this.initialStateId,
    required this.initialMetroId,
    required this.initialAreaId,
    required this.onChanged,
  });

  @override
  State<_SimpleLocationSelector> createState() =>
      _SimpleLocationSelectorState();
}

class _SimpleLocationSelectorState extends State<_SimpleLocationSelector> {
  String? _stateId;
  String? _metroId;
  String? _areaId;

  @override
  void initState() {
    super.initState();
    _stateId = widget.initialStateId?.isNotEmpty == true
        ? widget.initialStateId
        : 'GA';
    _metroId = widget.initialMetroId?.isNotEmpty == true
        ? widget.initialMetroId
        : 'haralson';
    _areaId = widget.initialAreaId?.isNotEmpty == true
        ? widget.initialAreaId
        : 'tallapoosa';
  }

  void _notify() {
    widget.onChanged(_stateId, _metroId, _areaId);
  }

  @override
  Widget build(BuildContext context) {
    // For now, hard-coded simple options – later you can load from Firestore.
    const states = ['GA'];
    const metros = ['haralson'];
    const areas = ['tallapoosa', 'bremen', 'buchanan', 'waco'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'State',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _stateId,
          items: states
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _stateId = value;
            });
            _notify();
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Metro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _metroId,
          items: metros
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _metroId = value;
            });
            _notify();
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Area',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _areaId,
          items: areas
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _areaId = value;
            });
            _notify();
          },
        ),
      ],
    );
  }
}
