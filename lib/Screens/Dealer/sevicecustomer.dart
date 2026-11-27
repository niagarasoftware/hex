// lib/screens/service_request/ticket_home_page.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/servicecustomermodel.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/snack_bar.dart';
import 'package:hex/utils/helpers/log_print.dart';

// colors used in the design
const _primary = Color(0xff10294E);
const _teal = Color(0xff0E6B7A);
const _tealSoft = Color(0xffDDF1F3);
const _field = Color(0xffF3F7F9);
const _ink = Color(0xff0F1B2D);
const _muted = Color(0xff6B7280);
const _border = Color(0xffE9E6F1);

class TicketHomePage extends StatefulWidget {
  final int userId, controllerId;
  const TicketHomePage({
    super.key,
    required this.userId,
    required this.controllerId,
  });

  @override
  State<TicketHomePage> createState() => _TicketHomePageState();
}

class _TicketHomePageState extends State<TicketHomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController otherstextctrl = TextEditingController();
  final TextEditingController searchctrl = TextEditingController();

  RequestType _selectedCategory = RequestType();
  DateFormat dateFormat = DateFormat("yyyy-MM-dd");
  DateFormat timeformat = DateFormat("HH:mm:ss");
  DateFormat exceptDateFormat = DateFormat("yyyy-MM-dd");

  ServicecustomerModel _servicecustomerModel = ServicecustomerModel();
  String dropdownvalue = 'Controller Regarding';

  // new (UI only)
  int _tab = 0; // 0 All, 1 In progress, 2 Closed
  int _selected = 0;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchData();
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.getUserServiceRequest({
        "userId": widget.userId,
        "controllerId": widget.controllerId
      });

      AppLog.log("userId ${widget.userId} controllerId ${widget.controllerId}");

      if (getUserDetails.statusCode == 200) {
        var jsonData = jsonDecode(getUserDetails.body);
        if (!mounted) return;
        setState(() {
          _servicecustomerModel = ServicecustomerModel.fromJson(jsonData);
        });
      }
    } catch (e, stackTrace) {
      AppLog.log(' Error overAll getData => ${e.toString()}');
      AppLog.log(' trace overAll getData  => $stackTrace');
    }
  }

  Future<void> updateData(
      int requestTypeId,
      String requestDate,
      String requestDescription,
      String requestTime,
      int responsibleUser,
      String estimatedDate,
      ) async {
    AppLog.log('call update');
    otherstextctrl.clear();

    Map<String, Object> body = {
      "userId": widget.userId,
      "controllerId": widget.controllerId,
      "requestTypeId": requestTypeId,
      "requestDescription": requestDescription,
      "requestDate": requestDate,
      "requestTime": requestTime,
      "responsibleUser": responsibleUser,
      "estimatedDate": estimatedDate,
      "siteLocation": '',
      "createUser": widget.userId
    };

    final Repository repository = Repository(HttpService());
    var response = await repository.createUserServiceRequest(body);
    var jsonData = jsonDecode(response.body);
    AppLog.log('jsonData:$jsonData');

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        GlobalSnackBar.show(context, jsonData['message'], response.statusCode);
        fetchData();
      });
    } else {
      GlobalSnackBar.show(context, jsonData['message'], response.statusCode);
    }
  }

  @override
  void dispose() {
    otherstextctrl.dispose();
    searchctrl.dispose();
    super.dispose();
  }

  // ───────────── small helpers ─────────────
  bool _isClosed(dynamic status) {
    final v = '${status ?? ''}'.toLowerCase().trim();
    return v == 'completed' || v == 'closed' || v == 'resolved';
  }

  // "SR-1005". If your model field name is different, change it here.
  String _ticketNo(dynamic r) {
    try {
      final v = r.serviceRequestId;
      if (v != null) return 'SR-$v';
    } catch (_) {}
    return 'SR';
  }

  String _hm(dynamic t) {
    final s = '${t ?? ''}';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  // indexes of tickets after search + tab filter
  List<int> _visible() {
    final all = _servicecustomerModel.data!.serviceRequest ?? [];
    final q = searchctrl.text.trim().toLowerCase();
    final out = <int>[];
    for (var i = 0; i < all.length; i++) {
      final r = all[i];
      final closed = _isClosed(r.status);
      if (_tab == 1 && closed) continue;
      if (_tab == 2 && !closed) continue;
      if (q.isNotEmpty &&
          !'${r.requestType} ${r.requestDescription} ${_ticketNo(r)}'
              .toLowerCase()
              .contains(q)) {
        continue;
      }
      out.add(i);
    }
    return out;
  }

  // ───────────── build ─────────────
  @override
  Widget build(BuildContext context) {
    if (_servicecustomerModel.data == null) {
      return const Center(
        child: Text(
          'Currently no repository Request available ',
          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
        ),
      );
    } else if (_servicecustomerModel.data!.dataDefault!.requestType!.isEmpty) {
      return const Center(
        child: Text(
          'Currently repository Request Not available in your Account',
          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
        ),
      );
    }

    final all = _servicecustomerModel.data!.serviceRequest ?? [];
    final total = all.length;
    final closedCount = all.where((r) => _isClosed(r.status)).length;
    final visible = _visible();
    final active = visible.isEmpty
        ? null
        : (visible.contains(_selected) ? _selected : visible.first);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: kIsWeb ? null : AppBar(title: const Text('Service Request')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 900;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Support desk',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: _ink)),
                        SizedBox(height: 2),
                        Text("Raise a request and follow it until it's resolved.",
                            style: TextStyle(fontSize: 12, color: _muted)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openNewTicket,
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text('New ticket',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // stat cards
              Row(
                children: [
                  Expanded(
                      child: _statCard(Icons.confirmation_number_outlined,
                          '$total', 'Total tickets')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(Icons.schedule,
                          '${total - closedCount}', 'In progress')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(Icons.check_circle_outline,
                          '$closedCount', 'Closed')),
                ],
              ),
              const SizedBox(height: 14),

              // list + detail
              Expanded(
                child: wide
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _listPanel(visible, active)),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                          child: _detailPanel(active, true)),
                    ),
                  ],
                )
                    : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                          height: 380,
                          child: _listPanel(visible, active)),
                      const SizedBox(height: 12),
                      _detailPanel(active, false),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ───────────── pieces ─────────────
  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: _border),
    boxShadow: [
      BoxShadow(
          offset: const Offset(0, 4),
          blurRadius: 12,
          color: Colors.black.withOpacity(0.03)),
    ],
  );

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _box(),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
                color: _tealSoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _teal, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        height: 1.1)),
                Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listPanel(List<int> visible, int? active) {
    final all = _servicecustomerModel.data!.serviceRequest ?? [];
    return Container(
      decoration: _box(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: searchctrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search tickets',
                    hintStyle: const TextStyle(fontSize: 13, color: _muted),
                    filled: true,
                    fillColor: _field,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _teal)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  _tabBtn('All', 0),
                  _tabBtn('In progress', 1),
                  _tabBtn('Closed', 2),
                ]),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          Expanded(
            child: visible.isEmpty
                ? const Center(
                child: Text('No tickets found',
                    style: TextStyle(fontSize: 12, color: _muted)))
                : ListView.builder(
              padding: const EdgeInsets.all(6),
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final idx = visible[i];
                final r = all[idx];
                final sel = idx == active;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _selected = idx),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xffE8F5F6)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                          left: BorderSide(
                              color: sel ? _teal : Colors.transparent,
                              width: 3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${r.requestType}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: _ink)),
                              const SizedBox(height: 2),
                              Text('${r.requestDescription}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11, color: _muted)),
                              const SizedBox(height: 2),
                              Text('${_ticketNo(r)} · ${r.requestDate}',
                                  style: const TextStyle(
                                      fontSize: 10, color: _muted)),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(
                            color: _isClosed(r.status)
                                ? const Color(0xff2FB67C)
                                : const Color(0xffE8A33D),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int value) {
    final sel = _tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = value),
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: sel ? _tealSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? _teal : _muted)),
        ),
      ),
    );
  }

  Widget _detailPanel(int? active, bool wide) {
    if (active == null) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: _box(),
        child: const Text('Select a ticket to see its details',
            style: TextStyle(fontSize: 12, color: _muted)),
      );
    }

    final r = _servicecustomerModel.data!.serviceRequest![active];
    final closed = _isClosed(r.status);

    final boxes = [
      _infoBox('Raised', '${r.requestDate} ${_hm(r.requestTime)}'),
      _infoBox('Expected by', '${r.estimatedDate}'),
      _infoBox('Handled by', '${r.responsibleUserName}'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_ticketNo(r),
                        style: const TextStyle(fontSize: 10, color: _muted)),
                    const SizedBox(height: 3),
                    Text('${r.requestType}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: closed
                      ? const Color(0xffDCF5E7)
                      : const Color(0xffFDF0D5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('${r.status}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: closed
                            ? const Color(0xff15803D)
                            : const Color(0xffB45309))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: _field, borderRadius: BorderRadius.circular(10)),
            child: Text('${r.requestDescription}',
                style: const TextStyle(fontSize: 13, color: _ink)),
          ),
          const SizedBox(height: 10),
          wide
              ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: boxes[0]),
                const SizedBox(width: 8),
                Expanded(child: boxes[1]),
                const SizedBox(width: 8),
                Expanded(child: boxes[2]),
              ],
            ),
          )
              : Column(children: [
            SizedBox(width: double.infinity, child: boxes[0]),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: boxes[1]),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: boxes[2]),
          ]),
          const SizedBox(height: 18),
          const Text('Progress',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 12),

          // timeline  (state: 0 done, 1 current, 2 pending)
          _timelineRow('Ticket raised',
              '${r.requestDate} ${_hm(r.requestTime)}', 0, false),
          _timelineRow('Assigned to ${r.responsibleUserName}',
              'Expected by ${r.estimatedDate}', 0, false),
          _timelineRow(
              'Being worked on',
              closed ? 'Work completed' : 'The team is looking into it',
              closed ? 0 : 1,
              false),
          _timelineRow('Closed', closed ? 'Resolved' : 'Waiting for resolution',
              closed ? 0 : 2, true),

          if (!closed) ...[
            const SizedBox(height: 6),
            OutlinedButton(
              // TODO: connect your "resolve ticket" API here
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: _border),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Mark as resolved',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: _muted)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
        ],
      ),
    );
  }

  Widget _timelineRow(String title, String sub, int state, bool isLast) {
    Widget dot;
    if (state == 0) {
      dot = Container(
          height: 16,
          width: 16,
          decoration:
          const BoxDecoration(color: _teal, shape: BoxShape.circle));
    } else if (state == 1) {
      dot = Container(
        height: 22,
        width: 22,
        decoration: BoxDecoration(
            color: _teal.withOpacity(0.15), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Container(
          height: 14,
          width: 14,
          decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _teal, width: 2.5)),
        ),
      );
    } else {
      dot = Container(
          height: 16,
          width: 16,
          decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 2)));
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(children: [
              dot,
              if (!isLast) Expanded(child: Container(width: 2, color: _border)),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: state == 2 ? _muted : _ink)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(fontSize: 11, color: _muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── New ticket popup (old form inside a dialog) ─────────────
  void _openNewTicket() {
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                        child: Text('New ticket',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _ink)),
                      ),
                      IconButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          icon: const Icon(Icons.close, color: _muted, size: 20)),
                    ]),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: _field,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _border)),
                      child: DropdownButton(
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        iconSize: 28,
                        dropdownColor: Colors.white,
                        style: const TextStyle(fontSize: 13, color: _ink),
                        value: dropdownvalue,
                        icon: const Icon(Icons.arrow_drop_down_sharp),
                        items: _servicecustomerModel
                            .data!.dataDefault!.requestType!
                            .map((items) {
                          return DropdownMenuItem(
                            value: items.requestType,
                            child: Text(items.requestType!),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setDialog(() {
                            dropdownvalue = newValue!;
                            _selectedCategory = _servicecustomerModel
                                .data!.dataDefault!.requestType!
                                .firstWhere((e) => e.requestType == newValue);
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      keyboardType: TextInputType.multiline,
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 5) {
                          return 'Please Enter a Valid Reason';
                        }
                        return null;
                      },
                      maxLength: 200,
                      controller: otherstextctrl,
                      minLines: 3,
                      maxLines: 5,
                      autofocus: true,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _field,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        labelText: _selectedCategory.requestType,
                        hintText: 'Explain here',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState != null &&
                              _formKey.currentState!.validate()) {
                            Navigator.pop(dialogCtx);
                            updateData(
                              _selectedCategory.requestTypeId ?? 3,
                              dateFormat.format(DateTime.now()),
                              otherstextctrl.text,
                              timeformat.format(DateTime.now()),
                              _servicecustomerModel
                                  .data!.dataDefault!.dealer![0].userId!,
                              exceptDateFormat.format(
                                DateTime.now().add(const Duration(days: 2)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Raise Ticket',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
