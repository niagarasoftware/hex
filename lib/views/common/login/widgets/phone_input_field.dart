import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../../../view_models/login_view_model.dart';

class PhoneInputField extends StatelessWidget {
  const PhoneInputField({super.key, required this.isWeb});
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LoginViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            'Mobile Number',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        IntlPhoneField(
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          dropdownTextStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Enter mobile number',
            hintStyle: TextStyle(
              fontSize: 13.5,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            suffixIcon: viewModel.mobileNoController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.close_rounded,
                  size: 18, color: colorScheme.error),
              onPressed: () => viewModel.mobileNoController.clear(),
            )
                : null,
          ),
          languageCode: "en",
          initialCountryCode: 'IN',
          controller: viewModel.mobileNoController,
          onChanged: (phone) {},
          onCountryChanged: (country) =>
          viewModel.countryCode = country.dialCode,
        ),
      ],
    );
  }
}
