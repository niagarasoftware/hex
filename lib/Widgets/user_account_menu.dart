import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../flavors.dart';
import '../providers/user_provider.dart';
import '../view_models/base_header_view_model.dart';
import '../views/common/user_profile/user_profile.dart';

class UserAccountMenu extends StatelessWidget {
  const UserAccountMenu({super.key, required this.isNarrow});
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final showLogo = (!F.appFlavor!.name.contains('oro') && !F.appFlavor!.name.contains('agritel'));
    final customer = Provider.of<UserProvider>(context).viewedCustomer;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (showLogo)
          Image.asset(
            "assets/png/lk_logo_white.png",
            width: 140,
            fit: BoxFit.fitWidth,
          ),
        const SizedBox(width: 10),
        isNarrow ? Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTapDown: (details) => _showUserMenu(context, details, customer?.name ?? ''),
            child: Icon(Icons.account_circle_outlined, color: colorScheme.onPrimary),
          ),
        ) :
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapDown: (details) => _showUserMenu(context, details, customer?.name ?? ''),
            child: Container(
              width: 230,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 2),
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage("assets/png/user_thumbnail.png"),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    customer?.name ?? 'User',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down_sharp, color: colorScheme.onSurface),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onMenuSelected(BuildContext context, String? value) async {
    final colorScheme = Theme.of(context).colorScheme;
    switch (value) {
      case 'profile':
        isNarrow ? Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserProfile(isNarrow: true)),
        ):
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => FractionallySizedBox(
            heightFactor: 0.84,
            widthFactor: 0.75,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: const UserProfile(isNarrow: false),
            ),
          ),
        );
        break;
      case 'logout':
        final viewModel = Provider.of<BaseHeaderViewModel>(context, listen: false);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await viewModel.logout(context);
        });
        break;
    }
  }

  void _showUserMenu(BuildContext context, TapDownDetails details, String userName) {
    final colorScheme = Theme.of(context).colorScheme;
    final offset = details.globalPosition;
    showMenu<String>(
      context: context,
      color: colorScheme.surface,
      position: RelativeRect.fromLTRB(offset.dx, offset.dy, offset.dx, 0),
      items: [
        if (isNarrow) ...[
          PopupMenuItem<String>(
            enabled: false,
            child: Text(
              userName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Text('Profile Settings', style: TextStyle(color: colorScheme.onSurface)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: colorScheme.error),
              const SizedBox(width: 5),
              Text('Logout', style: TextStyle(color: colorScheme.error)),
            ],
          ),
        ),
      ],
    ).then((value) => _onMenuSelected(context, value));
  }
}