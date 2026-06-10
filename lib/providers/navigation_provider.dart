import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationState {
  final String activeTab; // 'create', 'produce', 'release', 'messages', 'calendar', 'team', 'earnings', 'catalog', 'industry'
  final String activeSubSection; // sub-section of the selected tab

  NavigationState({
    required this.activeTab,
    required this.activeSubSection,
  });

  NavigationState copyWith({
    String? activeTab,
    String? activeSubSection,
  }) {
    return NavigationState(
      activeTab: activeTab ?? this.activeTab,
      activeSubSection: activeSubSection ?? this.activeSubSection,
    );
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier()
      : super(NavigationState(
          activeTab: 'create',
          activeSubSection: 'lyrics', // Default to lyrics in Create Sandbox
        ));

  void selectTab(String tab) {
    String defaultSub = '';
    switch (tab) {
      case 'create':
        defaultSub = 'lyrics';
        break;
      case 'produce':
        defaultSub = 'song_sandbox';
        break;
      case 'release':
        defaultSub = 'legal';
        break;
      case 'earnings':
        defaultSub = 'overview';
        break;
      default:
        defaultSub = '';
    }
    state = NavigationState(activeTab: tab, activeSubSection: defaultSub);
  }

  void selectSubSection(String sub) {
    state = state.copyWith(activeSubSection: sub);
  }
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});
