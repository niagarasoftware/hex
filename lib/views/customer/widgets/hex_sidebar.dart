import 'package:flutter/material.dart';
import '../../../models/customer/site_model.dart';
import '../../../models/user_model.dart';
import '../../../utils/constants.dart';
import '../../common/user_profile/user_profile.dart';
import '../help_support.dart';

class HexSidebarItem {
  final int index;
  final String title;
  final IconData icon;

  const HexSidebarItem({
    required this.index,
    required this.title,
    required this.icon,
  });
}

class HexSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final MasterControllerModel master;
  final UserModel? loggedInUser;
  final UserModel? viewedCustomer;
  final String? userName;
  final String? userMobile;
  final VoidCallback? onHelpTap;
  final VoidCallback? onProfileTap;
  final bool isCollapsible;
  final bool initiallyExpanded;

  const HexSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.master,
    this.loggedInUser,
    this.viewedCustomer,
    this.userName,
    this.userMobile,
    this.onHelpTap,
    this.onProfileTap,
    this.isCollapsible = false,
    this.initiallyExpanded = true,
  });

  /// Build list of items dynamically matching the active model
  static List<HexSidebarItem> buildItems(MasterControllerModel master) {
    int idx = 0;
    final items = <HexSidebarItem>[];

    // 0: Dashboard
    items.add(HexSidebarItem(
      index: idx++,
      title: 'Dashboard',
      icon: Icons.grid_view_rounded,
    ));

    // 1: All My Devices
    items.add(HexSidebarItem(
      index: idx++,
      title: 'All My Devices',
      icon: Icons.developer_board_outlined,
    ));

    // 2: Send & Received
    items.add(HexSidebarItem(
      index: idx++,
      title: 'Send & Received',
      icon: Icons.swap_horiz_rounded,
    ));

    // 3: Controller Log (conditional)
    if ([
      ...AppConstants.gemModelList,
      ...AppConstants.ecoGemModelList,
      ...AppConstants.omsGemList,
    ].contains(master.modelId)) {
      items.add(HexSidebarItem(
        index: idx++,
        title: 'Controller Log',
        icon: Icons.description_outlined,
      ));
    }

    // 4: Settings
    items.add(HexSidebarItem(
      index: idx++,
      title: 'Settings',
      icon: Icons.settings_outlined,
    ));

    // 5: Configuration
    items.add(HexSidebarItem(
      index: idx++,
      title: 'Configuration',
      icon: Icons.tune_rounded,
    ));

    // 6: Service Request
    items.add(HexSidebarItem(
      index: idx++,
      title: 'Service Request',
      icon: Icons.build_outlined,
    ));

    // 7: Weather (conditional)
    if ([...AppConstants.gemModelList].contains(master.modelId) &&
        ![...AppConstants.aquacultureModelList].contains(master.modelId)) {
      items.add(HexSidebarItem(
        index: idx++,
        title: 'Weather',
        icon: Icons.wb_sunny_outlined,
      ));
    }

    // 8: Geography (conditional)
    if ([...AppConstants.aquacultureModelList].contains(master.modelId) ||
        [...AppConstants.gemModelList].contains(master.modelId)) {
      items.add(HexSidebarItem(
        index: idx++,
        title: 'Geography',
        icon: Icons.location_on_outlined,
      ));
    }

    return items;
  }

  @override
  State<HexSidebar> createState() => _HexSidebarState();
}

class _HexSidebarState extends State<HexSidebar> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  String _getUserInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'U';
  }

  void _defaultHelpAction() {
    if (widget.onHelpTap != null) {
      widget.onHelpTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DashboardHelpPage()),
    );
  }

  void _defaultProfileAction() {
    if (widget.onProfileTap != null) {
      widget.onProfileTap!();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.84,
        widthFactor: 0.75,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: const UserProfile(isNarrow: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = HexSidebar.buildItems(widget.master);

    final String displayName = (widget.userName != null && widget.userName!.trim().isNotEmpty)
        ? widget.userName!.trim()
        : (widget.viewedCustomer?.name != null && widget.viewedCustomer!.name.trim().isNotEmpty)
            ? widget.viewedCustomer!.name.trim()
            : (widget.loggedInUser?.name != null && widget.loggedInUser!.name.trim().isNotEmpty)
                ? widget.loggedInUser!.name.trim()
                : 'User';

    final String displayMobile = (widget.userMobile != null && widget.userMobile!.trim().isNotEmpty)
        ? widget.userMobile!.trim()
        : (widget.viewedCustomer?.mobileNo != null && widget.viewedCustomer!.mobileNo.trim().isNotEmpty)
            ? widget.viewedCustomer!.mobileNo.trim()
            : (widget.loggedInUser?.mobileNo != null && widget.loggedInUser!.mobileNo.trim().isNotEmpty)
                ? widget.loggedInUser!.mobileNo.trim()
                : '';

    final initials = _getUserInitials(displayName);

    final sidebarWidth = _isExpanded ? 240.0 : 72.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------------
          // Header: Brand Logo & Title
          // -------------------------------------------------------------------
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 18.0 : 16.0,
              vertical: 20.0,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.hexagon_rounded,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Text(
                    'HEX',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // Nav Items List
          // -------------------------------------------------------------------
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: _isExpanded ? 14.0 : 10.0,
                vertical: 4.0,
              ),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = widget.selectedIndex == item.index;

                final tile = Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => widget.onDestinationSelected(item.index),
                    hoverColor: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerLow,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(
                        horizontal: _isExpanded ? 14.0 : 0.0,
                        vertical: 10.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: _isExpanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.outline,
                          ),
                          if (_isExpanded) ...[
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );

                if (!_isExpanded) {
                  return Tooltip(
                    message: item.title,
                    preferBelow: false,
                    child: tile,
                  );
                }

                return tile;
              },
            ),
          ),

          // -------------------------------------------------------------------
          // Bottom Section: Help + Divider + User Profile
          // -------------------------------------------------------------------
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 14.0 : 10.0,
              vertical: 8.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Help button
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _defaultHelpAction,
                    hoverColor: colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isExpanded ? 14.0 : 0.0,
                        vertical: 10.0,
                      ),
                      child: Row(
                        mainAxisAlignment: _isExpanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 20,
                            color: colorScheme.outline,
                          ),
                          if (_isExpanded) ...[
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Help',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant,
                  ),
                ),

                // User Profile Tile
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _defaultProfileAction,
                    hoverColor: colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isExpanded ? 8.0 : 0.0,
                        vertical: 6.0,
                      ),
                      child: Row(
                        mainAxisAlignment: _isExpanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: colorScheme.tertiary,
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: colorScheme.onTertiary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_isExpanded) ...[
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (displayMobile.isNotEmpty) ...[
                                    const SizedBox(height: 1.5),
                                    Text(
                                      displayMobile,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
