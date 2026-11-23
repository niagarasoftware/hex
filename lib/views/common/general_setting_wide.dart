import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import '../../StateManagement/customer_provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/constants.dart';
import '../../utils/enums.dart';
import '../../view_models/customer/general_setting_view_model.dart';
import 'user_profile/create_account.dart';

class GeneralSettingWide extends StatefulWidget {
  const GeneralSettingWide({
    super.key,
    required this.customerId,
    required this.controllerId,
    required this.userId,
    required this.isSubUser,
  });
  final int customerId, controllerId, userId;
  final bool isSubUser;

  @override
  State<GeneralSettingWide> createState() => _GeneralSettingWideState();
}

class _GeneralSettingWideState extends State<GeneralSettingWide> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider(
      key: ValueKey(Provider.of<CustomerProvider>(context).controllerId),
      create: (_) => GeneralSettingViewModel(Repository(HttpService()))
        ..initIds(
          customerId: widget.customerId,
          controllerId: widget.controllerId,
          userId: widget.userId,
          isSubUser: widget.isSubUser,
        )
        ..getControllerInfo()
        ..getSubUserList(),
      child: Consumer<GeneralSettingViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: colorScheme.surfaceContainerLowest,
            body: viewModel.isLoading
                ? buildLoadingIndicator(context, true, MediaQuery.sizeOf(context).width)
                : generalSetting(context, viewModel),
          );
        },
      ),
    );
  }

  Widget buildLoadingIndicator(BuildContext context, bool isVisible, double width) {
    final colorScheme = Theme.of(context).colorScheme;

    return Visibility(
      visible: isVisible,
      child: Container(
        color: colorScheme.surfaceContainerLowest,
        padding: EdgeInsets.symmetric(horizontal: width / 2 - 25),
        child: LoadingIndicator(
          indicatorType: Indicator.ballPulse,
          colors: [colorScheme.primary],
        ),
      ),
    );
  }

  Widget getSettingTile(BuildContext context, int index) {
    final viewModel = Provider.of<GeneralSettingViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;

    switch (index) {
      case 0:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          title: Text('Farm Name',
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          subtitle: Text(viewModel.farmName,
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
          leading: Icon(Icons.label_outline, color: colorScheme.primary),
          trailing: IconButton(
            onPressed: () {
              showEditControllerDialog(
                  context, 'Farm Name', viewModel.farmName, (newName) {
                viewModel.updateMasterDetails(context);
              });
            },
            icon: Icon(Icons.edit, color: colorScheme.onSurfaceVariant),
          ),
        );
      case 1:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          title: Text('Controller Name',
              style: TextStyle(color: colorScheme.onSurface)),
          subtitle: Text(viewModel.controllerCategory,
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          leading: Icon(Icons.developer_board, color: colorScheme.primary),
          trailing: IconButton(
            onPressed: () {
              showEditControllerDialog(
                  context, 'Controller Name', viewModel.farmName, (newName) {
                viewModel.updateMasterDetails(context);
              });
            },
            icon: Icon(Icons.edit, color: colorScheme.onSurfaceVariant),
          ),
        );
      case 2:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          title: Text('Device Category',
              style: TextStyle(color: colorScheme.onSurface)),
          subtitle: Text(viewModel.categoryName,
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          leading: Icon(Icons.category, color: colorScheme.primary),
        );
      case 3:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          title: Text('Device Model',
              style: TextStyle(color: colorScheme.onSurface)),
          subtitle: Text(viewModel.modelName,
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          leading: Icon(Icons.model_training, color: colorScheme.primary),
        );
      case 4:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          title: Text('Device ID',
              style: TextStyle(color: colorScheme.onSurface)),
          subtitle: SelectableText(
            viewModel.deviceId,
            style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          leading: Icon(Icons.numbers_outlined, color: colorScheme.primary),
        );
      case 5:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          title: Text('Controller Version',
              style: TextStyle(color: colorScheme.onSurface)),
          subtitle: Text(viewModel.controllerVersion,
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          leading: Icon(Icons.developer_board, color: colorScheme.primary),
          trailing: IconButton(
              onPressed: () {},
              icon: Icon(Icons.update, color: colorScheme.onSurfaceVariant)),
        );
      case 6:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          leading: Icon(Icons.timer_outlined, color: colorScheme.primary),
          title: Text('UTC',
              style: TextStyle(color: colorScheme.onSurface)),
          subtitle: Text('Time zone setting',
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
          trailing: SizedBox(
            width: 175,
            child: DropdownButton<String>(
              hint: Text('Select Time Zone',
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
              value: viewModel.selectedTimeZone,
              dropdownColor: colorScheme.surface,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  viewModel.updateCurrentDateTime(newValue);
                }
              },
              items: viewModel.timeZones
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value,
                      style: TextStyle(color: colorScheme.onSurface)),
                );
              }).toList(),
            ),
          ),
        );
      case 7:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          leading: Icon(Icons.date_range, color: colorScheme.primary),
          title: Text('Current Date',
              style: TextStyle(color: colorScheme.onSurface)),
          subtitle: Text('Date from controller',
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
          trailing: Text(
            viewModel.currentDate,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
        );
      case 8:
        return ListTile(
          title: Text('Location',
              style: TextStyle(color: colorScheme.onSurface)),
          subtitle: Text('Controller location',
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
          leading: Icon(Icons.location_on_outlined, color: colorScheme.primary),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(viewModel.controllerLocation,
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  showEditControllerDialog(
                      context, 'Location', viewModel.controllerLocation, (newName) {
                    viewModel.updateMasterDetails(context);
                  });
                },
                icon: Icon(Icons.edit, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      case 9:
        return ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          isThreeLine: true,
          leading: Icon(Icons.access_time, color: colorScheme.primary),
          title: Text('Current UTC Time',
              style: TextStyle(color: colorScheme.onSurface)),
          subtitle: Text('Time from controller',
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
          trailing: Text(
            viewModel.currentTime,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
        );
      case 10:
        return ListTile(
          title: Text('Time Format',
              style: TextStyle(color: colorScheme.onSurface)),
          leading: Icon(Icons.av_timer, color: colorScheme.primary),
          trailing: Text(
            '24 Hrs',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
        );
      case 11:
        return ListTile(
          title: Text('Unit',
              style: TextStyle(color: colorScheme.onSurface)),
          leading: Icon(Icons.ac_unit_rounded, color: colorScheme.primary),
          trailing: Text(
            'm3',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _panel(BuildContext context, {required Widget child, EdgeInsetsGeometry? padding}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _heading(BuildContext context, IconData icon, String title, {String? subtitle}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 19),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _field(BuildContext context, String label, Widget content, {VoidCallback? onEdit}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          constraints: const BoxConstraints(minHeight: 45),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Expanded(child: content),
              if (onEdit != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  color: colorScheme.onSurfaceVariant,
                  tooltip: 'Edit $label',
                  visualDensity: VisualDensity.compact,
                  constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _value(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _metric(BuildContext context, IconData icon, String label, String value, String detail) {
    final colorScheme = Theme.of(context).colorScheme;

    return _panel(
      context,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(icon, size: 18, color: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionFooter(GeneralSettingViewModel viewModel, BuildContext context, bool isCompact) {
    final colorScheme = Theme.of(context).colorScheme;

    final restart = OutlinedButton.icon(
      onPressed: () async {}, // Existing restart callback is intentionally empty.
      icon: const Icon(Icons.restart_alt, size: 18),
      label: const Text('Restart the controller'),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.error,
        side: BorderSide(color: colorScheme.error),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      ),
    );
    final save = FilledButton.icon(
      onPressed: () => viewModel.updateMasterDetails(context),
      icon: const Icon(Icons.check, size: 17),
      label: const Text('Save changes'),
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 28, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isCompact
              ? Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: [restart, save])
              : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [restart, save]),
        ),
      ),
    );
  }

  Widget generalSetting(BuildContext context, GeneralSettingViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 850;
    final hasSim = [...AppConstants.ecoGemModelList, ...AppConstants.pumpList]
        .contains(viewModel.modelId);
    final hasUnit =
    [...AppConstants.gemModelList].contains(viewModel.modelId);

    final details = _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(context, Icons.perm_device_information_outlined, 'Controller details',
              subtitle: 'Names and location shown across the dashboard.'),
          const SizedBox(height: 21),
          _field(context, 'Farm name', _value(context, viewModel.farmName), onEdit: () {
            showEditControllerDialog(
                context, 'Farm Name', viewModel.farmName, (farmName) {
              viewModel.farmName = farmName;
              viewModel.updateMasterDetails(context);
            });
          }),
          const SizedBox(height: 15),
          _field(context, 'Controller name', _value(context, viewModel.controllerCategory),
              onEdit: () {
                showEditControllerDialog(
                    context, 'Controller Name', viewModel.controllerCategory,
                        (category) {
                      viewModel.controllerCategory = category;
                      viewModel.updateMasterDetails(context);
                    });
              }),
          const SizedBox(height: 15),
          _field(context, 'Controller location', _value(context, viewModel.controllerLocation),
              onEdit: () {
                showEditControllerDialog(
                    context, 'Location', viewModel.controllerLocation,
                        (location) {
                      viewModel.controllerLocation = location;
                      viewModel.updateMasterDetails(context);
                    });
              }),
          if (hasSim) ...[
            const SizedBox(height: 15),
            _field(
                context,
                'SIM card number',
                _value(context,
                    '${viewModel.countryCode} - ${viewModel.simNumber}'),
                onEdit: () {
                  showSimEditControllerDialog(
                      context,
                      'SIM card Number',
                      viewModel.countryCode ?? '91',
                      viewModel.simNumber ?? '0', (cCode, sNumber) {
                    viewModel.countryCode = cCode;
                    viewModel.simNumber = sNumber;
                    viewModel.updateMasterDetails(context);
                  });
                }),
          ],
        ],
      ),
    );

    final clock = _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(context, Icons.schedule_outlined, 'Date & time',
              subtitle: 'How the controller keeps time.'),
          const SizedBox(height: 21),
          _field(
            context,
            'Time zone',
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text('Select Time Zone',
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
                value: viewModel.selectedTimeZone,
                dropdownColor: colorScheme.surface,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    viewModel.updateCurrentDateTime(newValue);
                  }
                },
                items: viewModel.timeZones
                    .map<DropdownMenuItem<String>>((String value) =>
                    DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,
                            style: TextStyle(color: colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis)))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 15),
          LayoutBuilder(builder: (context, constraints) {
            final date =
            _field(context, 'Current date', _value(context, viewModel.currentDate));
            final time = _field(
                context, 'Current UTC time', _value(context, viewModel.currentTime));
            final format = _field(context, 'Time format', _value(context, '24 Hrs'));
            if (constraints.maxWidth < 460) {
              return Column(children: [
                date,
                const SizedBox(height: 12),
                time,
                const SizedBox(height: 12),
                format
              ]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: date),
                const SizedBox(width: 10),
                Expanded(child: time),
                const SizedBox(width: 10),
                Expanded(child: format),
              ],
            );
          }),
        ],
      ),
    );

    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 14 : 28, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _panel(
                        context,
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                viewModel.farmName.isNotEmpty
                                    ? viewModel.farmName[0].toUpperCase()
                                    : 'F',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    viewModel.farmName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${viewModel.controllerCategory}  •  ${viewModel.controllerLocation}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isCompact) ...[
                              const SizedBox(width: 12),
                              Flexible(
                                child: _pill(context,
                                    'Version: ${viewModel.controllerVersion}'),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: _pill(context,
                                    '${viewModel.currentDate} · ${viewModel.currentTime} UTC'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(builder: (context, constraints) {
                        final cards = [
                          _metric(context, Icons.category_outlined,
                              'Device category', viewModel.categoryName, 'Controller category'),
                          _metric(context, Icons.memory_outlined,
                              'Model identifier', viewModel.modelName, 'Controller model'),
                          _metric(context, Icons.key_outlined,
                              'Device ID', viewModel.deviceId, 'Controller identifier'),
                          _metric(context, Icons.straighten_outlined,
                              'Unit', hasUnit ? 'm³' : '—', 'Flow measurement'),
                        ];
                        final count = constraints.maxWidth >= 850
                            ? 4
                            : (constraints.maxWidth >= 470 ? 2 : 1);
                        const gap = 12.0;
                        final itemWidth =
                            (constraints.maxWidth - gap * (count - 1)) / count;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final card in cards)
                              SizedBox(width: itemWidth, child: card),
                          ],
                        );
                      }),
                      if (viewModel.controllerVersion != viewModel.newVersion) ...[
                        const SizedBox(height: 10),
                        AnimatedOpacity(
                          opacity: viewModel.opacity,
                          duration: const Duration(seconds: 2),
                          child: Text(
                            'New Version available - ${viewModel.newVersion}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (isCompact) ...[
                        details,
                        const SizedBox(height: 16),
                        clock,
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: details),
                            const SizedBox(width: 16),
                            Expanded(child: clock),
                          ],
                        ),
                      if (!widget.isSubUser) ...[
                        const SizedBox(height: 18),
                        _panel(
                          context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _heading(
                                      context,
                                      Icons.groups_outlined,
                                      'My sub users',
                                      subtitle:
                                      'Manage users and controller access permissions.',
                                    ),
                                  ),
                                  if (widget.userId != 0) ...[
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (context) {
                                            return FractionallySizedBox(
                                              heightFactor: 0.84,
                                              widthFactor: 0.75,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius: const BorderRadius.vertical(
                                                      top: Radius.circular(16)),
                                                ),
                                                child: CreateAccount(
                                                  userId: widget.userId,
                                                  role: UserRole.subUser,
                                                  customerId: widget.customerId,
                                                  onAccountCreated:
                                                  viewModel.updateCustomerList,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.add, size: 17),
                                      label: Text(isCompact ? 'Add' : 'Add sub user'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: colorScheme.primary,
                                        side: BorderSide(color: colorScheme.outlineVariant),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 17),
                              Divider(color: colorScheme.outlineVariant),
                              if (viewModel.subUsers.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 36),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                          colorScheme.primaryContainer,
                                          child: Icon(Icons.group_outlined,
                                              color: colorScheme.primary),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No sub users yet',
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'No sub user is available for this controller.',
                                          style: TextStyle(
                                              color: colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else ...[
                                if (!isCompact)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            'USER & CONTACT',
                                            style: TextStyle(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'MOBILE NUMBER',
                                            style: TextStyle(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 150,
                                          child: Text(
                                            'ACTIONS',
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                for (final user in viewModel.subUsers) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 9, horizontal: 6),
                                    child: isCompact
                                        ? Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                          colorScheme.primaryContainer,
                                          child: Text(
                                            (user['userName']
                                                ?.toString()
                                                .isNotEmpty ??
                                                false)
                                                ? user['userName']
                                                .toString()
                                                .substring(0, 1)
                                                .toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                                color: colorScheme.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              _value(context,
                                                  user['userName'].toString()),
                                              Text(
                                                '+${user['countryCode']} ${user['mobileNumber']}',
                                                style: TextStyle(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'User Permission',
                                          icon: Icon(
                                              Icons.manage_accounts_outlined,
                                              color: colorScheme.primary),
                                          onPressed: () => _showAlertDialog(
                                              context,
                                              viewModel,
                                              user['userName'],
                                              user['userId']),
                                        ),
                                      ],
                                    )
                                        : Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                          colorScheme.primaryContainer,
                                          child: Text(
                                            (user['userName']
                                                ?.toString()
                                                .isNotEmpty ??
                                                false)
                                                ? user['userName']
                                                .toString()
                                                .substring(0, 1)
                                                .toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                                color: colorScheme.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          flex: 3,
                                          child: _value(context,
                                              user['userName'].toString()),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '+${user['countryCode']} ${user['mobileNumber']}',
                                            style: TextStyle(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 12),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 150,
                                          child: TextButton.icon(
                                            onPressed: () => _showAlertDialog(
                                                context,
                                                viewModel,
                                                user['userName'],
                                                user['userId']),
                                            icon: const Icon(
                                                Icons.manage_accounts_outlined,
                                                size: 17),
                                            label: const Text('Permissions'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                      height: 1,
                                      color: colorScheme.outlineVariant),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _actionFooter(viewModel, context, isCompact),
        ],
      ),
    );
  }

  Future<void> _showAlertDialog(
      BuildContext pntContext, GeneralSettingViewModel vm, String cName, int suId) async {
    final colorScheme = Theme.of(context).colorScheme;
    List<UserGroup> userGroups = [];
    Map<String, Object> body = {
      "userId": widget.customerId,
      "sharedUserId": suId,
    };
    final deviceList = await vm.getSubUserSharedDeviceList(body);
    if (deviceList != null) {
      setState(() {
        userGroups = deviceList.map((i) => UserGroup.fromJson(i)).toList();
      });
    } else {
      debugPrint("No devices found.");
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('$cName - Permissions', style: TextStyle(color: colorScheme.onSurface)),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Scaffold(
              backgroundColor: colorScheme.surface,
              body: ListView.builder(
                itemCount: userGroups.length,
                itemBuilder: (context, index) {
                  return UserGroupWidget(group: userGroups[index]);
                },
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              child: const Text('Submit'),
              onPressed: () async {
                List<MasterItem> masterList = [];

                for (int gix = 0; gix < userGroups.length; gix++) {
                  for (int mix = 0; mix < userGroups[gix].master.length; mix++) {
                    final master = userGroups[gix].master[mix];
                    masterList.add(
                      MasterItem(
                        id: master.controllerId,
                        action: master.isSharedDevice,
                        userPermission: master.userPermission,
                        linePermission: master.linePermission,
                      ),
                    );
                  }
                }

                Map<String, Object> body = {
                  "userId": widget.customerId,
                  "sharedUser": suId,
                  "masterList": masterList.map((item) => item.toMap()).toList(),
                  "createUser": widget.userId,
                };

                vm.updatedSubUserPermission(body, suId, pntContext);
              },
            ),
          ],
        );
      },
    );
  }

  void showEditControllerDialog(BuildContext context, String currentTitle, String currentName, Function(String) onSave) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('Edit $currentTitle', style: TextStyle(color: colorScheme.onSurface)),
          content: TextField(
            controller: nameController,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: currentTitle,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: colorScheme.error)),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name cannot be empty')),
                  );
                  return;
                }
                onSave(name);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void showSimEditControllerDialog(BuildContext context, String currentTitle,
      String cCode, String simNo, Function(String, String) onSave) {
    final TextEditingController cCodeController = TextEditingController(text: cCode);
    final TextEditingController mobileNoController = TextEditingController(text: simNo);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('Edit $currentTitle', style: TextStyle(color: colorScheme.onSurface)),
          content: IntlPhoneField(
            decoration: InputDecoration(
              hintText: 'Enter SIM number',
              suffixIcon: IconButton(
                icon: Icon(Icons.clear, color: colorScheme.error),
                onPressed: () => mobileNoController.clear(),
              ),
              icon: Icon(Icons.phone_outlined, color: colorScheme.primary),
            ),
            style: TextStyle(color: colorScheme.onSurface),
            languageCode: "en",
            initialCountryCode: 'IN',
            controller: mobileNoController,
            onChanged: (phone) {},
            onCountryChanged: (country) {
              cCodeController.text = country.dialCode;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: colorScheme.error)),
            ),
            FilledButton(
              onPressed: () {
                onSave(cCodeController.text, mobileNoController.text.trim());
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class UserGroup {
  final int userGroupId;
  final String groupName;
  final bool active;
  final List<Master> master;

  UserGroup({required this.userGroupId, required this.groupName, required this.active, required this.master});

  factory UserGroup.fromJson(Map<String, dynamic> json) {
    var list = json['master'] as List;
    List<Master> masterList = list.map((i) => Master.fromJson(i)).toList();
    return UserGroup(
      userGroupId: json['userGroupId'],
      groupName: json['groupName'],
      active: json['active'] == '1',
      master: masterList,
    );
  }
}

class Master {
  final int controllerId;
  final String deviceId;
  final String deviceName;
  bool isSharedDevice;
  final List<UserPermission> userPermission;
  final List<LinePermission> linePermission;

  Master({
    required this.controllerId,
    required this.deviceId,
    required this.deviceName,
    required this.isSharedDevice,
    required this.userPermission,
    required this.linePermission
  });

  factory Master.fromJson(Map<String, dynamic> json) {
    var list = json['userPermission'] as List;
    List<UserPermission> userPermissionList = list.map((i) => UserPermission.fromJson(i)).toList();

    List<LinePermission> linePermissionListData = [];
    if (json['linePermission'] != null) {
      var linePermissionList = json['linePermission'] as List;
      linePermissionListData = linePermissionList.map((i) => LinePermission.fromJson(i)).toList();
    }

    return Master(
      controllerId: json['controllerId'],
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      isSharedDevice: json['isSharedDevice'] ?? false,
      userPermission: userPermissionList,
      linePermission: linePermissionListData,
    );
  }
}

class UserPermission {
  final int sNo;
  final String name;
  bool status;

  UserPermission({required this.sNo, required this.name, required this.status});

  Map<String, dynamic> toMap() {
    return {
      'sNo': sNo,
      'name': name,
      'status': status,
    };
  }

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      sNo: json['sNo'],
      name: json['name'],
      status: json['status'] ?? false,
    );
  }
}

class LinePermission {
  final double sNo;
  final String name;
  bool status;

  LinePermission({required this.sNo, required this.name, required this.status});

  Map<String, dynamic> toMap() {
    return {
      'sNo': sNo,
      'name': name,
      'status': status,
    };
  }

  factory LinePermission.fromJson(Map<String, dynamic> json) {
    return LinePermission(
      sNo: (json['sNo'] as num).toDouble(),
      name: json['name'],
      status: json['status'] ?? false,
    );
  }
}

class UserGroupWidget extends StatefulWidget {
  final UserGroup group;
  const UserGroupWidget({super.key, required this.group});

  @override
  _UserGroupWidgetState createState() => _UserGroupWidgetState();
}

class _UserGroupWidgetState extends State<UserGroupWidget> {
  void toggleGroup(UserGroup group, bool? value) {
    if (value == null) return;
    setState(() {
      for (var master in group.master) {
        master.isSharedDevice = value;
        for (var permission in master.userPermission) {
          permission.status = value;
        }
        for (var linePermission in master.linePermission) {
          linePermission.status = value;
        }
      }
    });
  }

  void toggleMaster(Master master, bool? value) {
    if (value == null) return;
    setState(() {
      master.isSharedDevice = value;
      for (var permission in master.userPermission) {
        permission.status = value;
      }
      for (var linePermission in master.linePermission) {
        linePermission.status = value;
      }
    });
  }

  void toggleUserPermission(Master master, UserPermission permission, bool? value) {
    if (value == null) return;
    setState(() {
      permission.status = value;

      bool anyPermissionSelected = master.userPermission.any((p) => p.status) ||
          master.linePermission.any((lp) => lp.status);
      master.isSharedDevice = anyPermissionSelected;
    });
  }

  void toggleLinePermission(Master master, LinePermission permission, bool? value) {
    if (value == null) return;
    setState(() {
      permission.status = value;

      bool anyPermissionSelected = master.userPermission.any((p) => p.status) ||
          master.linePermission.any((lp) => lp.status);
      master.isSharedDevice = anyPermissionSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: colorScheme.surface,
      elevation: 1,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            Checkbox(
              value: widget.group.master.every((m) => m.isSharedDevice),
              onChanged: (value) => toggleGroup(widget.group, value),
            ),
            Expanded(
              child: Text(
                widget.group.groupName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        children: widget.group.master.map((master) {
          return ExpansionTile(
            initiallyExpanded: true,
            title: Row(
              children: [
                Checkbox(
                  value: master.isSharedDevice,
                  onChanged: (value) => toggleMaster(master, value),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        master.deviceName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        master.deviceId,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              if (master.userPermission.isNotEmpty) ...[
                ...master.userPermission.map((permission) {
                  return ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: permission.status,
                      onChanged: (value) =>
                          toggleUserPermission(master, permission, value),
                    ),
                    title: Text(
                      permission.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  );
                }),
              ],
              if (master.linePermission.isNotEmpty) ...[
                ...master.linePermission.map((permission) {
                  return ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: permission.status,
                      onChanged: (value) =>
                          toggleLinePermission(master, permission, value),
                    ),
                    title: Text(
                      permission.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class MasterItem {
  final int id;
  final bool action;
  final List<UserPermission> userPermission;
  final List<LinePermission> linePermission;

  MasterItem({
    required this.id,
    required this.action,
    required this.userPermission,
    required this.linePermission,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'userPermission': userPermission.map((perm) => perm.toMap()).toList(),
      'linePermission': linePermission.map((perm) => perm.toMap()).toList(),
    };
  }

  factory MasterItem.fromJson(Map<String, dynamic> json) {
    return MasterItem(
      id: json['id'],
      action: json['action'],
      userPermission: List<UserPermission>.from(
          json['userPermission'].map((x) => UserPermission.fromJson(x))),
      linePermission: json['linePermission'] != null
          ? List<LinePermission>.from(
          json['linePermission'].map((x) => LinePermission.fromJson(x)))
          : [],
    );
  }
}
