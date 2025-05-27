/*
 *     Copyright (C) 2025 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/logger_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/widgets/mini_player.dart';

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({super.key, required this.child});

  final StatefulNavigationShell child;

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

enum MenuItem { home, search, library, settings }

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  ({List<NavigationDestination> destinations, int selectedIndex})
  _getNavigationDestinations(
    BuildContext context,
    bool isOffline,
    int currentBranchIndex,
  ) {
    final allDestinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(FluentIcons.home_24_regular),
        selectedIcon: const Icon(FluentIcons.home_24_filled),
        label: context.l10n?.home ?? 'Home',
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.search_24_regular),
        selectedIcon: const Icon(FluentIcons.search_24_filled),
        label: context.l10n?.search ?? 'Search',
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.book_24_regular),
        selectedIcon: const Icon(FluentIcons.book_24_filled),
        label: context.l10n?.library ?? 'Library',
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.settings_24_regular),
        selectedIcon: const Icon(FluentIcons.settings_24_filled),
        label: context.l10n?.settings ?? 'Settings',
      ),
    ];

    final menuLabels = allDestinations.map((d) => d.label).toList();
    // Default selected index, since offline mode can only be changed in settings
    final settingLabel = context.l10n?.settings ?? 'Settings';
    // Only difference in labels for offline mode
    final searchLabel = context.l10n?.search ?? 'Search';

    final destinations = allDestinations;
    late final int selectedIndex;
    final currentDestination = allDestinations.firstWhere(
      (d) => d.label == menuLabels[currentBranchIndex],
      orElse:
          () => allDestinations.firstWhere(
            (d) => d.label == settingLabel,
            orElse: () => allDestinations.first,
          ),
    );
    if (isOffline) {
      destinations.removeWhere((d) => d.label == searchLabel);
      if (currentDestination.label == searchLabel) {
        // If the current destination is search, fallback to home
        selectedIndex = destinations.indexOf(
          allDestinations.firstWhere(
            (d) => d.label == settingLabel,
            orElse: () => allDestinations.first,
          ),
        );
      } else {
        selectedIndex = destinations.indexOf(currentDestination);
      }
    }
    return (destinations: destinations, selectedIndex: selectedIndex);
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: offlineMode,
      builder: (context, isOffline, _) {
        final navData = _getNavigationDestinations(
          context,
          isOffline,
          widget.child.currentIndex,
        );
        final destinations = navData.destinations;
        final selectedVisibleIndex = navData.selectedIndex;
        return LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = _isLargeScreen(context);
            return Scaffold(
              body: Row(
                children: [
                  if (isLargeScreen)
                    NavigationRail(
                      labelType: NavigationRailLabelType.selected,
                      destinations:
                          destinations
                              .map(
                                (destination) => NavigationRailDestination(
                                  icon: destination.icon,
                                  selectedIcon: destination.selectedIcon,
                                  label: Text(destination.label),
                                ),
                              )
                              .toList(),
                      selectedIndex: selectedVisibleIndex,
                      onDestinationSelected: (index) {
                        widget.child.goBranch(
                          index,
                          initialLocation: index != widget.child.currentIndex,
                        );
                        setState(() {});
                      },
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: widget.child),
                        StreamBuilder<MediaItem?>(
                          stream: audioHandler.mediaItem.distinct((prev, curr) {
                            if (prev == null || curr == null) return false;
                            return prev.id == curr.id &&
                                prev.title == curr.title &&
                                prev.artist == curr.artist &&
                                prev.artUri == curr.artUri;
                          }),
                          builder: (context, snapshot) {
                            final metadata = snapshot.data;
                            if (metadata == null) {
                              return const SizedBox.shrink();
                            }
                            return MiniPlayer(metadata: metadata);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar:
                  !isLargeScreen
                      ? NavigationBar(
                        selectedIndex: selectedVisibleIndex,
                        labelBehavior:
                            languageSetting == const Locale('en', '')
                                ? NavigationDestinationLabelBehavior
                                    .onlyShowSelected
                                : NavigationDestinationLabelBehavior.alwaysHide,
                        onDestinationSelected: (index) {
                          widget.child.goBranch(
                            index,
                            initialLocation: index != widget.child.currentIndex,
                          );
                          setState(() {});
                        },
                        destinations: destinations,
                      )
                      : null,
            );
          },
        );
      },
    );
  }
}
