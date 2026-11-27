import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../Screens/Dealer/controllerverssionupdate.dart';
import '../../../Screens/planning/FactoryReset.dart';
import '../../../flavors.dart';
import '../../../models/customer/site_model.dart';
import '../../../models/user_model.dart';
import '../../../modules/UserChat/view/user_chat.dart';
import '../../../user_manual_stub.dart';
import '../../../utils/constants.dart';
import '../../../utils/enums.dart';
import '../../../utils/routes.dart';
import '../../../utils/shared_preferences_helper.dart';
import '../../common/user_profile/user_profile.dart';
import '../app_info.dart';
import '../help_support.dart';
import 'app_bar_action.dart';

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
  bool _isHelpExpanded = false;

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

  void _defaultProfileAction(BuildContext context) {
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

  void _handleLogout(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PreferenceHelper.clearAll();
      const route = Routes.login;
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          route,
          (route) => false,
        );
      }
    }
  }

  Widget _buildHelpAndSupportMenu(
      BuildContext context,
      String displayName,
      String displayMobile,
      bool showControllerInfo,
      bool showFactoryReset) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                if (!_isExpanded) _isExpanded = true;
                _isHelpExpanded = !_isHelpExpanded;
              });
            },
            hoverColor: colorScheme.surfaceContainerLow,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                horizontal: _isExpanded ? 12.0 : 0.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: _isHelpExpanded
                    ? colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: _isExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.live_help_outlined,
                    size: 20,
                    color: _isHelpExpanded
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.outline,
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Help & Support',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: _isHelpExpanded
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _isHelpExpanded
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _isHelpExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: _isHelpExpanded
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.outline,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (_isHelpExpanded && _isExpanded) ...[
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSubMenuItem(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'App info',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppInfo()),
                    );
                  },
                ),
                _buildSubMenuItem(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                  onTap: () {
                    if (widget.master.userManualLink?.isNotEmpty == true) {
                      final pdfUrl = AppConstants.buildUserManualUrl(widget.master.userManualLink);
                      if (pdfUrl.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserManualWeb(pdfUrl: pdfUrl),
                          ),
                        );
                        return;
                      }
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardHelpPage(),
                      ),
                    );
                  },
                ),
                if (showControllerInfo)
                  _buildSubMenuItem(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'Controller info',
                    onTap: () async {
                      final loggedUser = widget.loggedInUser;
                      if (loggedUser != null && loggedUser.role == UserRole.admin) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResetVerssion(
                              userId: widget.viewedCustomer?.id ?? loggedUser.id,
                              controllerId: widget.master.controllerId,
                              deviceID: widget.master.deviceId,
                              modeID: widget.master.modelId,
                              createUser: loggedUser.id,
                            ),
                          ),
                        );
                      } else {
                        showPasswordDialog(
                          context,
                          F.name.toLowerCase().contains('oro')
                              ? 'Oro@321'
                              : F.name.toLowerCase().contains('smart')
                              ? 'LK@321'
                              : F.name.toLowerCase().contains('agritel')
                              ? 'Agritel@321'
                              : 'Oro@321',
                          widget.viewedCustomer?.id ?? loggedUser?.id ?? 0,
                          widget.master.controllerId,
                          widget.master.deviceId,
                          widget.master.modelId,
                          1,
                        );
                      }
                    },
                  ),
                if (showFactoryReset)
                  _buildSubMenuItem(
                    context: context,
                    icon: Icons.restore,
                    title: 'Factory Reset',
                    onTap: () async {
                      final loggedUser = widget.loggedInUser;
                      if (loggedUser != null && loggedUser.role == UserRole.admin) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResetAccumalationScreen(
                              userId: widget.viewedCustomer?.id ?? loggedUser.id,
                              controllerId: widget.master.controllerId,
                              deviceID: widget.master.deviceId,
                              createUser: loggedUser.id,
                            ),
                          ),
                        );
                      } else {
                        showPasswordDialog(
                          context,
                          'Oro@321',
                          widget.viewedCustomer?.id ?? loggedUser?.id ?? 0,
                          widget.master.controllerId,
                          widget.master.deviceId,
                          widget.master.modelId,
                          2,
                        );
                      }
                    },
                  ),
                _buildSubMenuItem(
                  context: context,
                  icon: Icons.feedback_outlined,
                  title: 'Send feedback',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserChatScreen(
                          userId: widget.viewedCustomer?.id ?? widget.loggedInUser?.id ?? 0,
                          userName: displayName,
                          phoneNumber: displayMobile,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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

    final hasConfigPermission = widget.loggedInUser?.configPermission ?? false;
    final isExcludedModel = [...AppConstants.shine2V, ...AppConstants.shine4V, ...AppConstants.elite10V, ...AppConstants.pumpList]
        .contains(widget.master.modelId);

    final showControllerInfo = !hasConfigPermission && !isExcludedModel;
    final showFactoryReset = !hasConfigPermission;

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
          // Header: VIOM Automation Brand SVG Logo
          Padding(
            padding: EdgeInsetsGeometry.all(20),
            child: Center(
              child: SvgPicture.asset(
                'assets/svg_images/oro_logo.svg',
                width: _isExpanded ? 180.0 : 44.0,
                height: _isExpanded ? 65.0 : 44.0,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Nav Items List
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

          // Bottom Section: Help & Support (Expandable) + Divider + User Profile
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _isExpanded ? 14.0 : 10.0,
                vertical: 8.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHelpAndSupportMenu(
                    context,
                    displayName,
                    displayMobile,
                    showControllerInfo,
                    showFactoryReset,
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

                  // User Profile Tile Row
                  Row(
                    children: [
                      // Clickable Profile Section (Avatar + Name + Mobile)
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _defaultProfileAction(context),
                            hoverColor: colorScheme.surfaceContainerLow,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: _isExpanded ? 6.0 : 0.0,
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
                                    const SizedBox(width: 10),
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
                      ),
                      if (_isExpanded) const SizedBox(width: 6),
                      // Permanent Logout Action Button
                      if (_isExpanded)
                        Tooltip(
                          message: 'Logout',
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: () => _handleLogout(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.logout_rounded,
                                  size: 16,
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
