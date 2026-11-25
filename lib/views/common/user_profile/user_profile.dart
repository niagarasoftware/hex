import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_provider.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../utils/snack_bar.dart';
import '../../../view_models/account_setting_view_model.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key, required this.isNarrow});
  final bool isNarrow;

  String _getUserInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loggedInUser = context.read<UserProvider>().loggedInUser;
    final viewedCustomer = context.read<UserProvider>().viewedCustomer!;
    final initials = _getUserInitials(viewedCustomer.name);

    return ChangeNotifierProvider(
      create: (_) => UserSettingViewModel(
        Repository(HttpService()),
        viewedCustomer.name,
        viewedCustomer.countryCode,
        viewedCustomer.mobileNo,
        viewedCustomer.email,
        viewedCustomer.role.name,
      ),
      child: Consumer<UserSettingViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: colorScheme.surfaceContainerLowest,
            appBar: AppBar(
              title: const Text('Account Management'),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
            ),
            body: Form(
              key: viewModel.formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // ---------------------------------------------------
                          // Hero Profile Header
                          // ---------------------------------------------------
                          Container(
                            width: double.infinity,
                            color: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1000),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 36,
                                      backgroundColor: colorScheme.secondary,
                                      child: Text(
                                        initials,
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            viewedCustomer.name,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.onPrimary.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  viewedCustomer.role.name.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.onPrimary,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              if (viewedCustomer.mobileNo.isNotEmpty)
                                                Flexible(
                                                  child: Text(
                                                    viewedCustomer.mobileNo,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: colorScheme.onPrimary.withOpacity(0.85),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ---------------------------------------------------
                          // Main Body Content (Max Width 1000px)
                          // ---------------------------------------------------
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1000),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isDesktop = constraints.maxWidth >= 700;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // -------------------------------------
                                        // Section 1: Personal Information
                                        // -------------------------------------
                                        _buildSectionCard(
                                          context: context,
                                          title: 'Personal Information',
                                          subtitle: 'Update your account name, mobile number, and email address',
                                          child: isDesktop
                                              ? Column(
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Expanded(child: _buildNameField(context, viewModel)),
                                                        const SizedBox(width: 16),
                                                        Expanded(child: _buildPhoneField(context, viewModel)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Row(
                                                      children: [
                                                        Expanded(child: _buildEmailField(context, viewModel)),
                                                      ],
                                                    ),
                                                  ],
                                                )
                                              : Column(
                                                  children: [
                                                    _buildNameField(context, viewModel),
                                                    const SizedBox(height: 16),
                                                    _buildPhoneField(context, viewModel),
                                                    const SizedBox(height: 16),
                                                    _buildEmailField(context, viewModel),
                                                  ],
                                                ),
                                        ),

                                        const SizedBox(height: 24),

                                        // -------------------------------------
                                        // Section 2: Security & Password
                                        // -------------------------------------
                                        _buildSectionCard(
                                          context: context,
                                          title: 'Security & Password',
                                          subtitle: 'Modify your current login password',
                                          child: isDesktop
                                              ? Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(child: _buildNewPasswordField(context, viewModel)),
                                                    const SizedBox(width: 16),
                                                    Expanded(child: _buildConfirmPasswordField(context, viewModel)),
                                                  ],
                                                )
                                              : Column(
                                                  children: [
                                                    _buildNewPasswordField(context, viewModel),
                                                    const SizedBox(height: 16),
                                                    _buildConfirmPasswordField(context, viewModel),
                                                  ],
                                                ),
                                        ),

                                        if (viewModel.errorMsg.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Text(
                                            viewModel.errorMsg,
                                            style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
                                          ),
                                        ],

                                        const SizedBox(height: 32),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // -----------------------------------------------------------
                  // Bottom Action Dock
                  // -----------------------------------------------------------
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.onSurface,
                                side: BorderSide(color: colorScheme.outlineVariant),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCEL'),
                            ),
                            const SizedBox(width: 14),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.secondary,
                                foregroundColor: colorScheme.onSecondary,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final response = await viewModel.updateUserProfile(
                                  context,
                                  viewedCustomer.id,
                                  loggedInUser.id,
                                );

                                if (response != null) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    GlobalSnackBar.show(context, response["message"], response["code"]);
                                  }
                                } else {
                                  if (context.mounted) {
                                    GlobalSnackBar.show(context, 'profile update cancelled', 400);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  title.contains('Personal') ? Icons.person_outline_rounded : Icons.shield_outlined,
                  color: colorScheme.secondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(BuildContext context, UserSettingViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: viewModel.controllerUsrName,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Full Name',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.account_circle_outlined, color: colorScheme.secondary),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField(BuildContext context, UserSettingViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return IntlPhoneField(
      focusNode: FocusNode(),
      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Mobile Number',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.phone_outlined, color: colorScheme.secondary),
        suffixIcon: IconButton(
          icon: Icon(Icons.clear, color: colorScheme.error),
          onPressed: () => viewModel.controllerMblNo.clear(),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      languageCode: "en",
      initialCountryCode: 'IN',
      controller: viewModel.controllerMblNo,
      onChanged: (phone) {
        debugPrint(phone.completeNumber);
      },
      onCountryChanged: (country) => viewModel.countryCode = country.dialCode,
    );
  }

  Widget _buildEmailField(BuildContext context, UserSettingViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: viewModel.controllerEmail,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Email Address',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.email_outlined, color: colorScheme.secondary),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email address';
        }
        return null;
      },
    );
  }

  Widget _buildNewPasswordField(BuildContext context, UserSettingViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: viewModel.controllerNewPwd,
      obscureText: viewModel.isObscureNpw,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'New Password',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.lock_outline_rounded, color: colorScheme.secondary),
        suffixIcon: IconButton(
          icon: Icon(
            viewModel.isObscureNpw ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: () => viewModel.onIsObscureChangedToNpw(),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      autofillHints: const [AutofillHints.newPassword],
      keyboardType: TextInputType.visiblePassword,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField(BuildContext context, UserSettingViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: viewModel.controllerConfirmPwd,
      obscureText: viewModel.isObscureCpw,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.lock_outline_rounded, color: colorScheme.secondary),
        suffixIcon: IconButton(
          icon: Icon(
            viewModel.isObscureCpw ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: () => viewModel.onIsObscureChangedToCpw(),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      autofillHints: const [AutofillHints.newPassword],
      keyboardType: TextInputType.visiblePassword,
      validator: (value) {
        if (viewModel.controllerNewPwd.text.isNotEmpty ||
            (value != null && value.isNotEmpty)) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          } else if (value.length < 6) {
            return 'Password must be at least 6 characters';
          } else if (value != viewModel.controllerNewPwd.text) {
            return 'Passwords do not match';
          }
        }
        return null;
      },
    );
  }
}
