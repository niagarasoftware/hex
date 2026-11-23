import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/customer_provider.dart';
import '../../../flavors.dart';
import '../../../models/customer/sent_and_received_model.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../view_models/customer/sent_and_received_view_model.dart';

class SentAndReceived extends StatelessWidget {
  const SentAndReceived({
    super.key,
    required this.customerId,
    required this.controllerId,
    required this.isWide,
  });

  final int customerId, controllerId;
  final bool isWide;

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'TODAY';
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(date, yesterday)) return 'YESTERDAY';
    return DateFormat('dd MMM yyyy').format(date).toUpperCase();
  }

  (String, String?) _parseReceivedMessage(String rawMessage) {
    if (rawMessage.contains('\n')) {
      final lines = rawMessage.split('\n');
      return (lines[0].trim(), lines.sublist(1).join(' ').trim());
    }

    final upper = rawMessage.toUpperCase();
    const separator = ' DUE TO ';
    final idx = upper.indexOf(separator);
    if (idx != -1) {
      final title = rawMessage.substring(0, idx).trim();
      String sub = rawMessage.substring(idx + separator.length).trim();
      if (sub == sub.toUpperCase()) {
        sub = sub.toLowerCase();
        if (sub.isNotEmpty) {
          sub = sub[0].toUpperCase() + sub.substring(1);
        }
      }
      return (title, sub);
    }

    return (rawMessage.trim(), null);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(Provider.of<CustomerProvider>(context).controllerId),
      create: (_) => SentAndReceivedViewModel(Repository(HttpService()))
        ..initIds(customerId: customerId, controllerId: controllerId, isWide: isWide)
        ..getSentAndReceivedData(DateFormat('yyyy-MM-dd').format(DateTime.now())),
      child: Consumer<SentAndReceivedViewModel>(
        builder: (context, viewModel, _) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHorizontalDateSelector(context, viewModel),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              _buildTodayChip(viewModel),
              Expanded(child: _buildBody(context, viewModel)),
            ],
          );

          final canPop = ModalRoute.of(context)?.canPop ?? false;
          if (!isWide || canPop) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: const Text(
                  'Sent & Received',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0.5,
                iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
              ),
              body: content,
            );
          }

          return Container(
            color: Colors.white,
            child: content,
          );
        },
      ),
    );
  }

  Widget _buildHorizontalDateSelector(
    BuildContext context,
    SentAndReceivedViewModel viewModel,
  ) {
    final dates = List.generate(
      14,
      (i) => viewModel.windowEndDate.subtract(Duration(days: 13 - i)),
    );
    final isAtLatest = _isSameDay(viewModel.windowEndDate, DateTime.now()) ||
        viewModel.windowEndDate.isAfter(DateTime.now());

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF64748B), size: 22),
            splashRadius: 18,
            tooltip: 'Previous week',
            onPressed: () => viewModel.shiftDatesBack(7),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: dates.map((date) {
                    final isSelected =
                        _isSameDay(viewModel.selectedDay ?? DateTime.now(), date);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => viewModel.selectDate(date),
                        child: Container(
                          width: 44,
                          height: 62,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5B22B6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E').format(date).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                DateFormat('d').format(date),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isSelected)
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                const SizedBox(width: 4, height: 4),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isAtLatest ? Colors.grey.shade300 : const Color(0xFF64748B),
              size: 22,
            ),
            splashRadius: 18,
            tooltip: 'Next week',
            onPressed: isAtLatest ? null : () => viewModel.shiftDatesForward(7),
          ),
          IconButton(
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF64748B),
              size: 20,
            ),
            splashRadius: 18,
            tooltip: 'Pick date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: viewModel.selectedDay ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                viewModel.selectDate(picked);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodayChip(SentAndReceivedViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => viewModel.selectToday(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              _getDateLabel(viewModel.selectedDay ?? DateTime.now()),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SentAndReceivedViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: LoadingIndicator(
            indicatorType: Indicator.ballPulse,
            colors: [Color(0xFF5B22B6)],
          ),
        ),
      );
    }

    if (viewModel.sentAndReceivedList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 44,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),
            const Text(
              'Message not found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 16,
        vertical: 16,
      ),
      itemCount: viewModel.sentAndReceivedList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final message = viewModel.sentAndReceivedList[index];
        final isReceived = message.messageType == 'RECEIVED';

        if (isReceived) {
          return Align(
            alignment: Alignment.centerRight,
            child: _buildReceivedBubble(context, viewModel, message),
          );
        } else {
          return Align(
            alignment: Alignment.centerLeft,
            child: _buildSentBubble(context, viewModel, message),
          );
        }
      },
    );
  }

  Widget _buildSentBubble(
    BuildContext context,
    SentAndReceivedViewModel viewModel,
    SentAndReceivedModel message,
  ) {
    final timeStr = viewModel.convertTo12hrs(message.time);
    final userName = message.sentUser.isNotEmpty ? message.sentUser : 'User';

    return GestureDetector(
      onLongPress: () => _handleLongPress(context, viewModel, message),
      onTap: () {
        if (viewModel.hasPayloadViewPermission) {
          viewModel.getUserSoftwareOrHardwarePayload(
            context,
            message.sentAndReceivedId,
            'Hardware payload',
            message.message,
          );
        }
      },
      child: Container(
        constraints: BoxConstraints(
          minWidth: 160,
          maxWidth: isWide ? 400 : 290,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E7FF), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B22B6),
                  ),
                ),
                if (message.sentMobileNumber.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    message.sentMobileNumber,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedBubble(
    BuildContext context,
    SentAndReceivedViewModel viewModel,
    SentAndReceivedModel message,
  ) {
    final timeStr = viewModel.convertTo12hrs(message.time);
    final (title, subtitle) = _parseReceivedMessage(message.message);

    return GestureDetector(
      onLongPress: () => _handleLongPress(context, viewModel, message),
      onTap: () {
        if (viewModel.hasPayloadViewPermission) {
          viewModel.getUserSoftwareOrHardwarePayload(
            context,
            message.sentAndReceivedId,
            'Hardware payload',
            message.message,
          );
        }
      },
      child: Container(
        constraints: BoxConstraints(
          minWidth: 150,
          maxWidth: isWide ? 400 : 290,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF475569),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLongPress(
    BuildContext context,
    SentAndReceivedViewModel viewModel,
    SentAndReceivedModel message,
  ) {
    if (!viewModel.hasPayloadViewPermission) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This content is protected.\nPlease enter your password to\nview the payload.',
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: viewModel.passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final enteredPassword = viewModel.passwordController.text;
                  if (enteredPassword ==
                      (F.name.toLowerCase().contains('oro')
                          ? 'Oro@321'
                          : F.name.toLowerCase().contains('smart')
                          ? 'LK@321'
                          : F.name.toLowerCase().contains('agritel')
                          ? 'Agritel@321'
                          : 'Oro@321')) {
                    viewModel.hasPayloadViewPermission = true;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Access granted. Showing payload...')),
                    );
                    viewModel.getUserSoftwareOrHardwarePayload(
                      context,
                      message.sentAndReceivedId,
                      'Hardware payload',
                      message.message,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect password.')),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    }
  }
}
