import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';

import '../../../../repository/repository.dart';
import '../../../../services/http_service.dart';
import '../../../../view_models/customer/notification_view_model.dart';

const _pageBg = Color(0xFFF5F3FA);
const _tileBg = Color(0xFFFAFAFC);
const _tileBorder = Color(0xFFEDEDF2);
const _mutedText = Color(0xFF9A9AA8);
const _labelText = Color(0xFF3A3A4A);

class NotificationWide extends StatelessWidget {
  const NotificationWide({
    super.key,
    required this.customerId,
    required this.controllerId,
    required this.userId,
  });

  final int customerId;
  final int controllerId;
  final int userId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationViewModel(Repository(HttpService()))
        ..getNotificationList(customerId, controllerId),
      child: Consumer<NotificationViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.loadingState) {
            return Scaffold(body: _buildLoadingIndicator(context));
          }

          final list = viewModel.notificationList;

          return Scaffold(
            backgroundColor: _pageBg,
            body: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _tileBorder),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NotificationSection(
                      title: "Notification On/Off",
                      itemCount: list.length,
                      nameAt: (i) => list[i].notificationName,
                      valueAt: (i) => list[i].pushNotification,
                      onChanged: (i, value) => viewModel
                          .toggleNotification(i, value, isPush: true),
                    ),
                    const SizedBox(height: 32),
                    _NotificationSection(
                      title: "Save to (Send & Receive)",
                      itemCount: list.length,
                      nameAt: (i) => list[i].notificationName,
                      valueAt: (i) => list[i].sendAndReceive,
                      onChanged: (i, value) => viewModel
                          .toggleNotification(i, value, isPush: false),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: ElevatedButton(
              onPressed: () => viewModel.updateNotificationList(
                  context, customerId, controllerId, userId),
              child: const Text("Update", style: TextStyle(color: Colors.white)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 50,
        height: 50,
        child: LoadingIndicator(indicatorType: Indicator.ballPulse),
      ),
    );
  }
}

/// One section: icon + title + "x of y active" + divider + 3-column tile grid.
class _NotificationSection extends StatelessWidget {
  const _NotificationSection({
    required this.title,
    required this.itemCount,
    required this.nameAt,
    required this.valueAt,
    required this.onChanged,
  });

  final String title;
  final int itemCount;
  final String Function(int index) nameAt;
  final bool Function(int index) valueAt;
  final void Function(int index, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final activeCount =
        List.generate(itemCount, valueAt).where((v) => v).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.monitor_heart_outlined,
                  color: primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$activeCount of $itemCount active",
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: _mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: _tileBorder),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 44,
            crossAxisSpacing: 32,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) => _NotificationTile(
            name: nameAt(index),
            value: valueAt(index),
            onChanged: (v) => onChanged(index, v),
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.name,
    required this.value,
    required this.onChanged,
  });

  final String name;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _tileBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _tileBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, color: _labelText),
                ),
              ),
              Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: Theme.of(context).colorScheme.primary,
                side: const BorderSide(color: Color(0xFF8E8E9A), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
