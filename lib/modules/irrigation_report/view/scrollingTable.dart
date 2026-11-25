import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:hex/modules/irrigation_report/view/widgets/pump_ct_card.dart';
import '../model/data_parsing_and_sorting_model.dart';
import 'reason_lookup.dart';

class ScrollingTable extends StatefulWidget {
  final String fixedColumn;
  final List<dynamic> fixedColumnData;
  final List<dynamic> generalColumn;
  final List<dynamic> generalColumnData;
  final List<dynamic> waterColumn;
  final List<dynamic> waterColumnData;
  final List<dynamic> centralFilterColumn;
  final List<dynamic> centralFilterColumnData;
  final List<dynamic> localFilterColumn;
  final List<dynamic> localFilterColumnData;
  final List<dynamic> filterColumn;
  final List<dynamic> filterColumnData;
  final List<dynamic> prePostColumn;
  final List<dynamic> prePostColumnData;
  final List<dynamic> centralEcPhColumn;
  final List<dynamic> centralEcPhColumnData;
  final List<dynamic> centralChannel1Column;
  final List<dynamic> centralChannel1ColumnData;
  final List<dynamic> centralChannel2Column;
  final List<dynamic> centralChannel2ColumnData;
  final List<dynamic> centralChannel3Column;
  final List<dynamic> centralChannel3ColumnData;
  final List<dynamic> centralChannel4Column;
  final List<dynamic> centralChannel4ColumnData;
  final List<dynamic> centralChannel5Column;
  final List<dynamic> centralChannel5ColumnData;
  final List<dynamic> centralChannel6Column;
  final List<dynamic> centralChannel6ColumnData;
  final List<dynamic> centralChannel7Column;
  final List<dynamic> centralChannel7ColumnData;
  final List<dynamic> centralChannel8Column;
  final List<dynamic> centralChannel8ColumnData;
  final List<dynamic> localEcPhColumn;
  final List<dynamic> localEcPhColumnData;
  final List<dynamic> localChannel1Column;
  final List<dynamic> localChannel1ColumnData;
  final List<dynamic> localChannel2Column;
  final List<dynamic> localChannel2ColumnData;
  final List<dynamic> localChannel3Column;
  final List<dynamic> localChannel3ColumnData;
  final List<dynamic> localChannel4Column;
  final List<dynamic> localChannel4ColumnData;
  final List<dynamic> localChannel5Column;
  final List<dynamic> localChannel5ColumnData;
  final List<dynamic> localChannel6Column;
  final List<dynamic> localChannel6ColumnData;
  final List<dynamic> localChannel7Column;
  final List<dynamic> localChannel7ColumnData;
  final List<dynamic> localChannel8Column;
  final List<dynamic> localChannel8ColumnData;
  final List<dynamic> graphData;
  final void Function(String sequenceName)? onSequenceClicked;
  final bool showSensorReport;

  /// Optional pill tabs shown above the table (Date / Program / Line / ...).
  /// The tab bar is only drawn when [onGroupChanged] is provided; the selected
  /// tab is the one that matches [fixedColumn].
  final List<String> groupOptions;
  final ValueChanged<String>? onGroupChanged;

  const ScrollingTable({
    super.key,
    required this.fixedColumn,
    required this.fixedColumnData,
    required this.generalColumn,
    required this.generalColumnData,
    required this.waterColumn,
    required this.waterColumnData,
    this.centralFilterColumn = const [],
    this.centralFilterColumnData = const [],
    this.localFilterColumn = const [],
    this.localFilterColumnData = const [],
    required this.filterColumn,
    required this.filterColumnData,
    required this.prePostColumn,
    required this.prePostColumnData,
    required this.centralEcPhColumn,
    required this.centralEcPhColumnData,
    required this.centralChannel1Column,
    required this.centralChannel1ColumnData,
    required this.centralChannel2Column,
    required this.centralChannel2ColumnData,
    required this.centralChannel3Column,
    required this.centralChannel3ColumnData,
    required this.centralChannel4Column,
    required this.centralChannel4ColumnData,
    required this.centralChannel5Column,
    required this.centralChannel5ColumnData,
    required this.centralChannel6Column,
    required this.centralChannel6ColumnData,
    required this.centralChannel7Column,
    required this.centralChannel7ColumnData,
    required this.centralChannel8Column,
    required this.centralChannel8ColumnData,
    required this.localEcPhColumn,
    required this.localEcPhColumnData,
    required this.localChannel1Column,
    required this.localChannel1ColumnData,
    required this.localChannel2Column,
    required this.localChannel2ColumnData,
    required this.localChannel3Column,
    required this.localChannel3ColumnData,
    required this.localChannel4Column,
    required this.localChannel4ColumnData,
    required this.localChannel5Column,
    required this.localChannel5ColumnData,
    required this.localChannel6Column,
    required this.localChannel6ColumnData,
    required this.localChannel7Column,
    required this.localChannel7ColumnData,
    required this.localChannel8Column,
    required this.localChannel8ColumnData,
    required this.graphData,
    this.onSequenceClicked,
    this.showSensorReport = true,
    this.groupOptions = const ['Date', 'Program', 'Line', 'Valve', 'Status'],
    this.onGroupChanged,
  });

  @override
  State<ScrollingTable> createState() => _ScrollingTableState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens (taken from the reference screenshot)
// ─────────────────────────────────────────────────────────────────────────────
const Color _kPageBg = Color(0xffEEF4F4);
const Color _kBannerBg = Color(0xffE2EFF0);
const Color _kGroupBg = Color(0xffF3F6F7);
const Color _kHeaderBg = Color(0xffF4F8F9);
const Color _kTeal = Color(0xff0B5D6B);
const Color _kHeaderText = Color(0xff5F6F76);
const Color _kBodyText = Color(0xff1F2D33);
const Color _kMutedText = Color(0xff9AA8AE);
const Color _kSectionLine = Color(0xffC5D8DC);
const Color _kLine = Color(0xffE6ECEE);
// value cells only
const Color _kValueText = Color(0xff3E4552); // line, valves, times, reasons
const Color _kSubValueText = Color(0xff7B8391); // sequence label, duration

const double _kPinnedWidth = 170;
const double _kSensorWidth = 170;
// Set to true to show the top section-title row (General / Water / Filter ...).
const bool _kShowBanner = false;
const double _kBannerHeight = _kShowBanner ? 40 : 0;
const double _kHeaderHeight = 42;
const double _kGroupHeight = 34;
const double _kCycleHeight = 38; // height of one irrigation cycle inside a row

const BoxDecoration _kRowDecoration = BoxDecoration(
  border: Border(bottom: BorderSide(color: _kLine)),
);

/// One horizontal block of columns (General, Water, Filter, ...).
class _Section {
  final String title;
  final List<dynamic> columns;
  final List<dynamic> data;
  final double colWidth;
  final double width; // contentWidth + divider
  final double left; // x position of the section inside the scroll content
  final bool divider; // thin line on the left edge (all but the first section)
  final bool isGeneral;

  const _Section({
    required this.title,
    required this.columns,
    required this.data,
    required this.colWidth,
    required this.width,
    required this.left,
    required this.divider,
    this.isGeneral = false,
  });
}

/// A date (or other group) block of consecutive rows.
class _GroupInfo {
  final String? key; // null = no grouping (plain rows)
  final int count;
  final dynamic totalTime;
  final int start;
  final int end;

  const _GroupInfo(
      {required this.key,
        required this.count,
        required this.totalTime,
        required this.start,
        required this.end});

  String get summary => totalTime == null ? '' : '$totalTime H:M:S total';
}

/// Pinned (sticky) group header – the sliver machinery makes the current
/// header stay on top and lets the next one push it out (and back).
class _GroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _GroupHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: height, child: child);

  @override
  bool shouldRebuild(covariant _GroupHeaderDelegate oldDelegate) => true;
}

class _StatusStyle {
  final Color bg;
  final Color fg;
  final Color dot;
  const _StatusStyle(this.bg, this.fg, this.dot);
}

/// One visible column of the General block (composite or plain).
class _GCol {
  final String label;
  final double width;
  final Widget Function(int row, double height) cell;
  const _GCol(this.label, this.width, this.cell);
}

class _GeneralLayout {
  final List<_GCol> cols;
  final int startIdx;
  final int endIdx;
  const _GeneralLayout(this.cols, this.startIdx, this.endIdx);
  double get width => cols.fold<double>(0, (a, c) => a + c.width);
}

class _ScrollingTableState extends State<ScrollingTable> {
  late LinkedScrollControllerGroup _scrollable1;
  late ScrollController _verticalScroll1;
  late ScrollController _verticalScroll2;
  late ScrollController _verticalScroll3;
  late LinkedScrollControllerGroup _scrollable2;
  late ScrollController _horizontalScroll1;
  late ScrollController _horizontalScroll2;
  bool _compact = false; // phone-sized screen
  late _GeneralLayout _gl;
  final Set<String> _collapsed = {};
  String _lastColumnsLog = '';

  static const List<String> _pumpCtColumns = [
    'Pump CT Average',
    'Pump CT Maximum',
    'Pump CT Minimum',
    'PumpCtAverage',
    'PumpCtMaximum',
    'PumpCtMinimum',
  ];
  static const List<String> _pressureColumns = [
    'Pressure Average',
    'Pressure Maximum',
    'Pressure Minimum',
    'PressureAverage',
    'PressureMaximum',
    'PressureMinimum',
  ];
  static const List<String> _timeColumns = [
    'Actual Start Time',
    'Actual End Time',
  ];
  static const List<String> _reasonColumns = [
    'Actual Start Reason',
    'Actual Stop Reason',
  ];

  /// Header labels shown in the screenshot.
  static const Map<String, String> _labels = {
    'Actual Start Time': 'Start time',
    'Actual End Time': 'End time',
    'Actual Start Reason': 'Start reason',
    'Actual Stop Reason': 'Stop reason',
  };

  @override
  void initState() {
    super.initState();
    _scrollable1 = LinkedScrollControllerGroup();
    _verticalScroll1 = _scrollable1.addAndGet();
    _verticalScroll2 = _scrollable1.addAndGet();
    _verticalScroll3 = _scrollable1.addAndGet();
    _scrollable2 = LinkedScrollControllerGroup();
    _horizontalScroll1 = _scrollable2.addAndGet();
    _horizontalScroll2 = _scrollable2.addAndGet();
  }

  @override
  void dispose() {
    _verticalScroll1.dispose();
    _verticalScroll2.dispose();
    _verticalScroll3.dispose();
    _horizontalScroll1.dispose();
    _horizontalScroll2.dispose();
    super.dispose();
  }

  // ───────────────────────────── build ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    _compact = MediaQuery.of(context).size.width < 600;
    _gl = _buildGeneralLayout();
    final groups = _buildGroups();
    final sections = _buildSections();

    return Expanded(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            if (widget.onGroupChanged != null) _buildGroupTabs(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildMainCard(groups, sections)),
                  if (widget.showSensorReport &&
                      widget.onSequenceClicked != null)
                    _buildSensorCard(groups),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────── tabs ─────────────────────────────

  Widget _buildGroupTabs() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xffDCE5E7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (final opt in widget.groupOptions) _buildTab(opt)],
        ),
      ),
    );
  }

  Widget _buildTab(String option) {
    final selected = option.toLowerCase() == widget.fixedColumn.toLowerCase();
    return Material(
      color: selected ? _kTeal : Colors.transparent,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => widget.onGroupChanged?.call(option),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          child: Text(
            option,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : const Color(0xff4F5F66),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────── main (left) card ───────────────────────

  Widget _buildMainCard(List<_GroupInfo> groups, List<_Section> sections) {
    final contentWidth = sections.fold<double>(0, (a, s) => a + s.width);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final w = contentWidth > c.maxWidth ? contentWidth : c.maxWidth;
              return SizedBox(
                width: c.maxWidth,
                height: _kBannerHeight + _kHeaderHeight,
                child: SingleChildScrollView(
                  controller: _horizontalScroll1,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: w,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final s in sections) _sectionHeader(s),
                        if (w > contentWidth)
                          Expanded(
                            child: Column(
                              children: [
                                if (_kShowBanner)
                                  Container(
                                    height: _kBannerHeight,
                                    color: _kBannerBg,
                                  ),
                                Container(
                                  height: _kHeaderHeight,
                                  color: _kHeaderBg,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = contentWidth > c.maxWidth ? contentWidth : c.maxWidth;
                return Scrollbar(
                  controller: _horizontalScroll2,
                  thumbVisibility: !_compact,
                  child: SingleChildScrollView(
                    controller: _horizontalScroll2,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: w,
                      child: CustomScrollView(
                        controller: _verticalScroll2,
                        slivers: _groupSlivers(
                          groups,
                          _mainGroupHeader,
                              (a, b) => _mainRows(sections, a, b,
                              w: w, contentWidth: contentWidth),
                        ),
                      ),
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

  /// One sliver group per date: pinned header + that date's rows.
  List<Widget> _groupSlivers(
      List<_GroupInfo> groups,
      Widget Function(_GroupInfo g) header,
      Widget Function(int start, int end) body,
      ) {
    return [
      for (final g in groups)
        if (g.key == null)
          SliverToBoxAdapter(child: body(g.start, g.end))
        else
          SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _GroupHeaderDelegate(
                  height: _kGroupHeight,
                  child: header(g),
                ),
              ),
              if (!_collapsed.contains(g.key))
                SliverToBoxAdapter(child: body(g.start, g.end)),
            ],
          ),
    ];
  }

  Widget _mainRows(List<_Section> sections, int a, int b,
      {double? w, double? contentWidth}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in sections)
          SizedBox(
            width: s.width,
            child: Column(
              children: [for (var i = a; i < b; i++) _sectionEntry(s, i)],
            ),
          ),
        if (w != null && contentWidth != null && w > contentWidth)
          Expanded(
            child: Column(
              children: [
                for (var i = a; i < b; i++)
                  Container(
                    height: _rowHeight(i),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _kLine)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _toggleGroup(String? key) {
    if (key == null) return;
    setState(() {
      if (!_collapsed.remove(key)) _collapsed.add(key);
    });
  }

  Widget _groupLabel(_GroupInfo g) {
    final open = !_collapsed.contains(g.key);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
            size: 16, color: _kHeaderText),
        const SizedBox(width: 6),
        Text(
          g.key ?? '',
          maxLines: 1,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: ['Courier New', 'Courier'],
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _kBodyText,
          ),
        ),
      ],
    );
  }

  /// Date header of the main table. The text follows the horizontal scroll so
  /// it is always visible at the left edge. Tap to collapse / expand.
  Widget _mainGroupHeader(_GroupInfo g) {
    return Material(
      color: _kGroupBg,
      child: InkWell(
        onTap: () => _toggleGroup(g.key),
        child: Container(
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: _kLine),
              bottom: BorderSide(color: _kLine),
            ),
          ),
          child: AnimatedBuilder(
            animation: _horizontalScroll2,
            builder: (context, _) {
              final dx = _horizontalScroll2.hasClients
                  ? _horizontalScroll2.offset
                  : 0.0;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: _groupLabel(g),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sensorGroupHeader(_GroupInfo g) {
    return Material(
      color: _kGroupBg,
      child: InkWell(
        onTap: () => _toggleGroup(g.key),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: _kLine),
              bottom: BorderSide(color: _kLine),
            ),
          ),
        ),
      ),
    );
  }

  /// Section name that stays visible (at the left of the visible part of its
  /// section) while the table is scrolled sideways.
  Widget _bannerTitle(_Section s) {
    return AnimatedBuilder(
      animation: _horizontalScroll1,
      builder: (context, _) {
        final off =
        _horizontalScroll1.hasClients ? _horizontalScroll1.offset : 0.0;
        final maxDx = s.width > 140 ? s.width - 140 : 0.0;
        final dx = (off - s.left).clamp(0.0, maxDx).toDouble();
        return Align(
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                s.title,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kTeal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _headerCell(String label, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(left: 16, right: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xff3D4E56),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _sectionHeader(_Section s) {
    final Border? divider =
    s.divider ? const Border(left: BorderSide(color: _kSectionLine)) : null;
    final List<Widget> headerCells = s.isGeneral
        ? [for (final gc in _gl.cols) _headerCell(gc.label, gc.width)]
        : [
      for (final c in s.columns.where((c) => c != 'Name'))
        _headerCell(_labelFor('$c'), s.colWidth)
    ];
    return SizedBox(
      width: s.width,
      child: Column(
        children: [
          if (_kShowBanner)
            Container(
              height: _kBannerHeight,
              decoration: BoxDecoration(color: _kBannerBg, border: divider),
              child: _bannerTitle(s),
            ),
          Container(
            height: _kHeaderHeight,
            decoration: BoxDecoration(
              color: _kHeaderBg,
              border: Border(
                left: s.divider
                    ? const BorderSide(color: _kSectionLine)
                    : BorderSide.none,
                bottom: const BorderSide(color: _kLine),
              ),
            ),
            child: Row(children: headerCells),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── rows ─────────────────────────

  BoxDecoration _rowDecorationFor(_Section s) => BoxDecoration(
    border: Border(
      left: s.divider
          ? const BorderSide(color: _kSectionLine)
          : BorderSide.none,
      bottom: const BorderSide(color: _kLine),
    ),
  );

  Widget _sectionEntry(_Section s, int i) {
    final h = _rowHeight(i);

    if (s.isGeneral) {
      return Container(
        width: s.width,
        height: h,
        decoration: _rowDecorationFor(s),
        child: Row(
          children: [for (final gc in _gl.cols) gc.cell(i, h)],
        ),
      );
    }

    final List rowData =
    (i < s.data.length && s.data[i] is List) ? s.data[i] as List : const [];
    final visibleCount = s.columns.where((c) => c != 'Name').length;
    return Container(
      width: s.width,
      height: h,
      decoration: _rowDecorationFor(s),
      child: Row(
        children: [
          for (var j = 0; j < rowData.length && j < visibleCount; j++)
            Container(
              width: s.colWidth,
              padding: const EdgeInsets.only(left: 16, right: 8),
              alignment: Alignment.centerLeft,
              child: _textValue(rowData[j]),
            ),
        ],
      ),
    );
  }

  /// A single cell of the General section (or the pinned first column).
  /// Display only – nothing in here is tappable.
  Widget _generalCell(int i, int j, double h, {bool pinned = false}) {
    final name = '${widget.generalColumn[j]}';
    final row = widget.generalColumnData[i];
    final dynamic value = (row is List && j < row.length) ? row[j] : null;
    final double width = pinned ? _kPinnedWidth : _generalWidth(name);

    Widget child;
    Alignment alignment = Alignment.centerLeft;
    EdgeInsets padding = EdgeInsets.only(left: pinned ? 18 : 16, right: 8);

    if (name == 'Status') {
      child = _statusChip(value);
    } else if (_pumpCtColumns.contains(name)) {
      alignment = Alignment.center;
      padding = const EdgeInsets.symmetric(horizontal: 4);
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [Flexible(child: buildPumpCtCard('${value ?? '-'}'))],
      );
    } else if (name == 'Valve' || name == 'Valves') {
      child = _valveCell(value);
    } else if (_reasonColumns.contains(name)) {
      child = reasonCell('${value ?? '-'}', h);
    } else {
      child = _textValue(value, bold: pinned);
    }

    return Container(
      width: width,
      height: h,
      padding: padding,
      alignment: alignment,
      child: child,
    );
  }

  /// Valve column: up to 3 valves are listed; with more, the first 3 are shown
  /// followed by a tappable "..." that opens a hint listing every valve.
  Widget _valveCell(dynamic value) {
    final text = value == null ? '' : '$value';
    if (_isBlank(text)) return _textValue(value);

    final valves = text
        .split(RegExp(r'[,\n]'))
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (valves.length <= 3) return _textValue(value);

    return Row(
      children: [
        Flexible(
          child: Text(
            valves.take(3).join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, color: _kValueText),
          ),
        ),
        const SizedBox(width: 4),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: valves.join('\n'),
            triggerMode: TooltipTriggerMode.tap,
            showDuration: const Duration(seconds: 5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kSectionLine),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kBodyText,
              height: 1.5,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _kBannerBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kTeal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textValue(dynamic value, {bool bold = false}) {
    final text = value == null ? '' : '$value';
    if (_isBlank(text)) {
      return const Text(
        '–',
        style: TextStyle(fontSize: 13.5, color: _kMutedText),
      );
    }
    return Tooltip(
      message: text,
      child: Text(
        text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: bold ? _kBodyText : _kValueText,
        ),
      ),
    );
  }

  Widget _statusChip(dynamic raw) {
    final label = '${getStatus(raw)['status']}';
    final style = _statusStyle(label);

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: style.dot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: style.fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(String label) {
    final l = label.toLowerCase();
    if (l.contains('pend') || l.contains('wait') || l.contains('pause')) {
      return const _StatusStyle(
          Color(0xffFDEFCF), Color(0xff8A5A00), Color(0xffD98A00));
    }
    if (l.contains('run') || l.contains('progress') || l.contains('active')) {
      return const _StatusStyle(
          Color(0xffDDF3E4), Color(0xff1E7A3C), Color(0xff2E9E4F));
    }
    if (l.contains('stop') ||
        l.contains('skip') ||
        l.contains('fail') ||
        l.contains('error') ||
        l.contains('abort')) {
      return const _StatusStyle(
          Color(0xffFDE3E1), Color(0xffB3261E), Color(0xffD93025));
    }
    // Completed / anything else
    return const _StatusStyle(
        Color(0xffE4EBEF), Color(0xff3D4E56), Color(0xff55666E));
  }

  // ───────────────────── sensor report (right card) ─────────────────────

  Widget _buildSensorCard(List<_GroupInfo> groups) {
    return Container(
      width: _compact ? 120 : _kSensorWidth,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: _kLine)),
      ),
      child: Column(
        children: [
          if (_kShowBanner) Container(height: _kBannerHeight, color: _kBannerBg),
          Container(
            height: _kHeaderHeight,
            padding: EdgeInsets.only(right: _compact ? 10 : 20),
            decoration: const BoxDecoration(
              color: _kHeaderBg,
              border: Border(bottom: BorderSide(color: _kLine)),
            ),
            alignment: Alignment.centerRight,
            child: const Text(
              'Sensor report',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xff3D4E56),
              ),
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _verticalScroll3,
              thumbVisibility: !_compact,
              child: CustomScrollView(
                controller: _verticalScroll3,
                slivers: _groupSlivers(
                  groups,
                  _sensorGroupHeader,
                      (a, b) => Column(
                    children: [for (var i = a; i < b; i++) _sensorRow(i)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensorRow(int i) {
    final h = _rowHeight(i);
    final enabled = _rowHasRun(i);
    final fg = enabled ? _kTeal : _kMutedText;
    return Container(
      height: h,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: _compact ? 10 : 20),
      decoration: _kRowDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? () => _openSensors(i) : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: _compact ? 8 : 12, vertical: 7),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xffE8F4F5) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? const Color(0xffB5D6DA) : const Color(0xffE3E9EC),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monitor_heart_outlined, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                'Sensors',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Only the "Sensors" button calls this – table cells / rows are not tappable.
  void _openSensors(int rowIndex) {
    if (widget.onSequenceClicked == null ||
        widget.generalColumnData.length <= rowIndex) {
      return;
    }
    String seqName = '';
    final row = widget.generalColumnData[rowIndex];
    for (int j = 0; j < widget.generalColumn.length; j++) {
      if (['Sequence', 'Valves', 'Valve', 'SequenceData']
          .contains(widget.generalColumn[j])) {
        if (row != null && j < row.length) {
          seqName = row[j]?.toString() ?? '';
          break;
        }
      }
    }
    if (seqName.isEmpty && widget.fixedColumnData.length > rowIndex) {
      seqName = widget.fixedColumnData[rowIndex]?.toString() ?? '';
    }
    if (seqName.isNotEmpty) {
      widget.onSequenceClicked!(seqName);
    }
  }

  // ───────────────────────── General block (new layout) ─────────────────────────

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  dynamic _val(int i, int k) {
    if (k < 0 || i >= widget.generalColumnData.length) return null;
    final row = widget.generalColumnData[i];
    return (row is List && k < row.length) ? row[k] : null;
  }

  List<String> _lines(dynamic v) => v == null ? <String>[] : '$v'.split('\n');

  Widget _cell(double width, double h, Widget child,
      {Alignment alignment = Alignment.centerLeft}) {
    return Container(
      width: width,
      height: h,
      padding: const EdgeInsets.only(left: 16, right: 8),
      alignment: alignment,
      child: child,
    );
  }

  _GeneralLayout _buildGeneralLayout() {
    final names = widget.generalColumn.map((c) => '$c').toList();
    if (kDebugMode) {
      final log = names.join(' | ');
      if (log != _lastColumnsLog) {
        _lastColumnsLog = log;
        // ignore: avoid_print
        print('[ScrollingTable] fixedColumn=${widget.fixedColumn} generalColumn: $log');
      }
    }
    final normed = names.map(_norm).toList();
    int find(List<String> candidates, {int exclude = -1}) {
      for (final c in candidates) {
        final k = normed.indexOf(c);
        if (k >= 0 && k != exclude) return k;
      }
      return -1;
    }

    int findWhere(bool Function(String n, int k) test) {
      for (var k = 0; k < normed.length; k++) {
        if (test(normed[k], k)) return k;
      }
      return -1;
    }

    var programIdx = find(['program', 'programname']);
    if (programIdx < 0) {
      programIdx = findWhere((n, k) =>
      n.startsWith('program') &&
          !n.contains('category') &&
          !n.contains('sno') &&
          !n.contains('no'));
    }
    final statusIdx = find(['status']);
    final lineIdx = find(['line', 'linename', 'headunit']);
    final valvesIdx = find(['valves', 'valve', 'sequence', 'sequencedata']);
    var seqIdx =
    find(['zonename', 'zone', 'sequencename', 'sequence'], exclude: valvesIdx);
    if (seqIdx < 0) {
      seqIdx = findWhere((n, k) =>
      k != valvesIdx && (n.contains('sequence') || n.contains('zone')));
    }
    final startIdx = find(['actualstarttime', 'starttime']);
    final endIdx = find(['actualendtime', 'endtime']);
    final startReasonIdx = find(['actualstartreason', 'startreason']);
    final stopReasonIdx = find(['actualstopreason', 'stopreason']);

    final used = <int>{
      programIdx,
      seqIdx,
      statusIdx,
      lineIdx,
      valvesIdx,
      startIdx,
      endIdx,
      startReasonIdx,
      stopReasonIdx,
    }..remove(-1);

    final cols = <_GCol>[];

    if (programIdx >= 0 || seqIdx >= 0) {
      cols.add(_GCol('Program & Sequence', 165, (i, h) {
        return _cell(165, h, _programCell(i, programIdx, seqIdx));
      }));
    }
    if (statusIdx >= 0) {
      cols.add(_GCol('Status', 125, (i, h) {
        return _cell(125, h, _statusCell(_val(i, statusIdx)));
      }));
    }
    if (lineIdx >= 0) {
      cols.add(_GCol('Line', 145, (i, h) {
        return _cell(145, h, _textValue(_val(i, lineIdx)));
      }));
    }
    if (valvesIdx >= 0) {
      cols.add(_GCol('Valves', 185, (i, h) {
        return _cell(185, h, _valvesCell(_val(i, valvesIdx)));
      }));
    }
    if (startIdx >= 0 || endIdx >= 0) {
      cols.add(_GCol('Run window', 250, (i, h) {
        return _cell(250, h, _runWindowCell(i));
      }));
    }
    if (startReasonIdx >= 0 || stopReasonIdx >= 0) {
      cols.add(_GCol('Trigger & Outcome', 200, (i, h) {
        return _cell(200, h,
            _triggerCell(i, startReasonIdx, stopReasonIdx, statusIdx));
      }));
    }

    // every other General column keeps its old name and look (Pump, Pump CT, Method ...)
    for (var j = 0; j < names.length; j++) {
      if (used.contains(j)) continue;
      final jj = j;
      cols.add(_GCol(_labelFor(names[j]), _generalWidth(names[j]),
              (i, h) => _generalCell(i, jj, h)));
    }

    return _GeneralLayout(cols, startIdx, endIdx);
  }

  int _cycleCount(int i) {
    int n = 1;
    if (i >= widget.generalColumnData.length) return n;
    final row = widget.generalColumnData[i];
    if (row is List) {
      for (final c in row) {
        if (c == null) continue;
        final k = '$c'.split('\n').length;
        if (k > n) n = k;
      }
    }
    return n;
  }

  bool _rowHasRun(int i) {
    if (_gl.startIdx < 0) return true;
    return _lines(_val(i, _gl.startIdx)).any((l) => !_isBlank(l));
  }

  Widget _programCell(int i, int programIdx, int seqIdx) {
    String first(dynamic v) {
      final t = _lines(v);
      return t.isEmpty ? '' : t.first.trim();
    }

    final name = first(_val(i, programIdx));
    final seq = first(_val(i, seqIdx));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: name,
          child: Text(
            _isBlank(name) ? '–' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: _kBodyText,
            ),
          ),
        ),
        if (!_isBlank(seq)) ...[
          const SizedBox(height: 2),
          Text(
            seq,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11.5, height: 1.2, color: _kSubValueText),
          ),
        ],
      ],
    );
  }

  String _statusKey(String label) =>
      label.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  static const Color _cGreen = Color(0xff12A150);
  static const Color _cRed = Color(0xffE5484D);
  static const Color _cOrange = Color(0xffD9730D);

  /// Completed = green, Postponed = red, Pending = orange (plus the rest).
  Color _statusColor(String label) {
    final l = _statusKey(label);
    if (l.contains('complet')) return _cGreen;
    if (l.contains('postpon') || l.contains('post')) return _cRed;
    if (l.contains('pend')) return _cOrange;
    if (l.contains('skip')) return _cOrange;
    if (l.contains('stop') ||
        l.contains('fail') ||
        l.contains('error') ||
        l.contains('abort')) {
      return _cRed;
    }
    if (l.contains('pause') || l.contains('wait')) {
      return const Color(0xffD98A00);
    }
    if (l.contains('run') || l.contains('progress') || l.contains('active')) {
      return const Color(0xff1565C0);
    }
    return const Color(0xff55666E);
  }

  IconData _statusIcon(String label) {
    final l = _statusKey(label);
    if (l.contains('complet')) return Icons.check_circle_outline;
    if (l.contains('postpon') || l.contains('post')) return Icons.event_busy_outlined;
    if (l.contains('pend')) return Icons.schedule;
    if (l.contains('skip')) return Icons.skip_next_outlined;
    if (l.contains('stop') ||
        l.contains('fail') ||
        l.contains('error') ||
        l.contains('abort')) {
      return Icons.cancel_outlined;
    }
    if (l.contains('pause') || l.contains('wait')) {
      return Icons.pause_circle_outline;
    }
    if (l.contains('run') || l.contains('progress') || l.contains('active')) {
      return Icons.play_circle_outline;
    }
    return Icons.help_outline;
  }

  Widget _statusCell(dynamic raw) {
    final label = '${getStatus(raw)['status']}';
    final color = _statusColor(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_statusIcon(label), size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }

  /// Shows the first 2 valves, the rest as a tappable "+N more" with a hint.
  Widget _valvesCell(dynamic value) {
    final text = value == null ? '' : '$value';
    if (_isBlank(text)) return _textValue(value);
    final valves = text
        .split(RegExp(r'[,\n]'))
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (valves.length <= 2) return _textValue(valves.join(', '));
    return Row(
      children: [
        Flexible(
          child: Text(
            valves.take(2).join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, color: _kValueText),
          ),
        ),
        const SizedBox(width: 6),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: valves.join('\n'),
            triggerMode: TooltipTriggerMode.tap,
            showDuration: const Duration(seconds: 5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kSectionLine),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kBodyText,
              height: 1.5,
            ),
            child: Text(
              '+${valves.length - 2} more',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xff1E8E7E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int? _toSeconds(String raw) {
    final m = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?').firstMatch(raw);
    if (m == null) return null;
    return int.parse(m.group(1)!) * 3600 +
        int.parse(m.group(2)!) * 60 +
        (m.group(3) != null ? int.parse(m.group(3)!) : 0);
  }

  String _fmtTime(String raw) {
    if (_isBlank(raw)) return '–';
    final m = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?').firstMatch(raw);
    if (m == null) return raw.trim();
    final h = int.parse(m.group(1)!);
    final mm = m.group(2)!;
    final ss = m.group(3) ?? '00';
    final period = h >= 12 ? 'PM' : 'AM';
    var h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '${h12.toString().padLeft(2, '0')}:$mm:$ss $period';
  }

  String? _fmtDuration(String start, String end) {
    if (_isBlank(start) || _isBlank(end)) return null;
    final a = _toSeconds(start);
    final b = _toSeconds(end);
    if (a == null || b == null) return null;
    var d = b - a;
    if (d < 0) d += 86400;
    final h = d ~/ 3600;
    final m = (d % 3600) ~/ 60;
    final sec = d % 60;
    final ss = sec.toString().padLeft(2, '0');
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m ${ss}s';
    if (m > 0) return '${m}m ${ss}s';
    return '${sec}s';
  }

  Widget _runWindowCell(int i) {
    final starts = _lines(_val(i, _gl.startIdx));
    final ends = _lines(_val(i, _gl.endIdx));
    final n = _cycleCount(i);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < n; c++)
          SizedBox(
            height: _kCycleHeight,
            child: ClipRect(
              child: _runWindowLine(
                c < starts.length ? starts[c] : '',
                c < ends.length ? ends[c] : '',
              ),
            ),
          ),
      ],
    );
  }

  Widget _runWindowLine(String start, String end) {
    if (_isBlank(start) && _isBlank(end)) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('–', style: TextStyle(fontSize: 13.5, color: _kMutedText)),
      );
    }
    const timeStyle = TextStyle(
      height: 1.2,
      fontFamily: 'monospace',
      fontFamilyFallback: ['Courier New', 'Courier'],
      fontSize: 12,
      color: _kValueText,
    );
    final duration = _fmtDuration(start, end);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_fmtTime(start), style: timeStyle),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, size: 12, color: _kMutedText),
            ),
            Text(_fmtTime(end), style: timeStyle),
          ],
        ),
        if (duration != null) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule, size: 12, color: _kMutedText),
              const SizedBox(width: 4),
              Text(duration,
                  style: const TextStyle(
                    height: 1.2,
                    fontFamily: 'monospace',
                    fontFamilyFallback: ['Courier New', 'Courier'],
                    fontSize: 11.5,
                    color: _kSubValueText,
                  )),
            ],
          ),
        ],
      ],
    );
  }

  Widget _triggerCell(
      int i, int startReasonIdx, int stopReasonIdx, int statusIdx) {
    final statusLabel =
    statusIdx >= 0 ? '${getStatus(_val(i, statusIdx))['status']}' : '';
    final starts = _lines(_val(i, startReasonIdx));
    final stops = _lines(_val(i, stopReasonIdx));
    final n = _cycleCount(i);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < n; c++)
          SizedBox(
            height: _kCycleHeight,
            child: ClipRect(
              child: _triggerLine(
                c < starts.length ? starts[c].trim() : '',
                c < stops.length ? stops[c].trim() : '',
                statusLabel,
              ),
            ),
          ),
      ],
    );
  }

  Widget _triggerLine(
      String startReason, String stopReason, String statusLabel) {
    final sBlank = _isBlank(startReason);
    final eBlank = _isBlank(stopReason);
    final skipped = _statusKey(statusLabel).contains('skip');
    // 2nd line takes the colour of the row status (green / orange / red ...)
    final outcomeColor = statusLabel.isNotEmpty
        ? _statusColor(statusLabel)
        : reasonColor(stopReason);

    if (sBlank && eBlank) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('–', style: TextStyle(fontSize: 13, color: _kMutedText)),
      );
    }
    if (sBlank != eBlank) {
      final only = sBlank ? stopReason : startReason;
      final Color c =
      skipped ? _kSubValueText : (sBlank ? outcomeColor : _kValueText);
      return Align(
        alignment: Alignment.centerLeft,
        child: Tooltip(
          message: only,
          child: Text(
            only,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, height: 1.2, color: c),
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: startReason,
            child: Text(
              startReason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, height: 1.2, color: _kValueText),
            ),
          ),
          const SizedBox(height: 2),
          Tooltip(
            message: stopReason,
            child: Text(
              stopReason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
              TextStyle(fontSize: 11.5, height: 1.2, color: outcomeColor),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── data helpers ─────────────────────────

  double _rowHeight(int i) {
    double h1 = getBoxHeight(widget.centralFilterColumnData, i) - 10;
    double h2 = getBoxHeight(widget.localFilterColumnData, i) - 10;
    double h3 = getBoxHeight(widget.filterColumnData, i) - 10;
    double h4 = 16.0 + _cycleCount(i) * _kCycleHeight;
    return [h1, h2, h3, h4].reduce((a, b) => a > b ? a : b);
  }

  String _labelFor(String name) => _labels[name] ?? name;

  double _generalWidth(String name) {
    if (name == 'Status') return 160;
    if (name == 'Line') return 170;
    if (name == 'Sequence' || name == 'SequenceData' || name == 'Valves') {
      return 160;
    }
    if (name == 'Valve') return 150;
    if (_timeColumns.contains(name)) return 130;
    if (_reasonColumns.contains(name) ||
        _pumpCtColumns.contains(name) ||
        _pressureColumns.contains(name)) {
      return 200;
    }
    return 130;
  }

  String _groupKey(int i) =>
      i < widget.fixedColumnData.length ? '${widget.fixedColumnData[i]}' : '';

  dynamic _totalTimeFor(String key) {
    for (final item in widget.graphData) {
      if (item is Map &&
          '${item['name']}' == key &&
          item['totalTime'] != null) {
        return item['totalTime'];
      }
    }
    return null;
  }

  /// Consecutive rows with the same group value (e.g. the same date).
  List<_GroupInfo> _buildGroups() {
    final n = widget.generalColumnData.length;
    if (n == 0) return const [];
    if (widget.fixedColumnData.isEmpty) {
      return [
        _GroupInfo(key: null, count: n, totalTime: null, start: 0, end: n)
      ];
    }
    final groups = <_GroupInfo>[];
    var i = 0;
    while (i < n) {
      final key = _groupKey(i);
      var end = i;
      while (end < n && _groupKey(end) == key) {
        end++;
      }
      groups.add(_GroupInfo(
        key: key,
        count: end - i,
        totalTime: _totalTimeFor(key),
        start: i,
        end: end,
      ));
      i = end;
    }
    return groups;
  }

  List<_Section> _buildSections() {
    final sections = <_Section>[];
    double left = 0;

    void add(String title, List<dynamic> columns, List<dynamic> data,
        double colWidth,
        {bool isGeneral = false}) {
      if (columns.isEmpty) return;
      double content = 0;
      if (isGeneral) {
        content = _gl.width;
      } else {
        content = columns.where((c) => c != 'Name').length * colWidth;
      }
      final divider = sections.isNotEmpty;
      final width = content + (divider ? 1 : 0);
      sections.add(_Section(
        title: title,
        columns: columns,
        data: data,
        colWidth: colWidth,
        width: width,
        left: left,
        divider: divider,
        isGeneral: isGeneral,
      ));
      left += width;
    }

    add('General', widget.generalColumn, widget.generalColumnData, 0,
        isGeneral: true);
    add('Water', widget.waterColumn, widget.waterColumnData, 100);
    if (widget.centralFilterColumn.isNotEmpty) {
      add('Central Filter', widget.centralFilterColumn, widget.centralFilterColumnData, 200);
    }
    if (widget.localFilterColumn.isNotEmpty) {
      add('Local Filter', widget.localFilterColumn, widget.localFilterColumnData, 200);
    }
    if (widget.centralFilterColumn.isEmpty &&
        widget.localFilterColumn.isEmpty &&
        widget.filterColumn.isNotEmpty) {
      add('Central Filter', widget.filterColumn, widget.filterColumnData, 200);
    }
    add('Pre Post', widget.prePostColumn, widget.prePostColumnData, 100);

    add('<C-EC-PH>', widget.centralEcPhColumn, widget.centralEcPhColumnData,
        100);
    final centralChannels = [
      [widget.centralChannel1Column, widget.centralChannel1ColumnData],
      [widget.centralChannel2Column, widget.centralChannel2ColumnData],
      [widget.centralChannel3Column, widget.centralChannel3ColumnData],
      [widget.centralChannel4Column, widget.centralChannel4ColumnData],
      [widget.centralChannel5Column, widget.centralChannel5ColumnData],
      [widget.centralChannel6Column, widget.centralChannel6ColumnData],
      [widget.centralChannel7Column, widget.centralChannel7ColumnData],
      [widget.centralChannel8Column, widget.centralChannel8ColumnData],
    ];
    for (var n = 0; n < centralChannels.length; n++) {
      add('<C-CH${n + 1}>', centralChannels[n][0], centralChannels[n][1], 100);
    }

    add('<L-EC-PH>', widget.localEcPhColumn, widget.localEcPhColumnData, 100);
    final localChannels = [
      [widget.localChannel1Column, widget.localChannel1ColumnData],
      [widget.localChannel2Column, widget.localChannel2ColumnData],
      [widget.localChannel3Column, widget.localChannel3ColumnData],
      [widget.localChannel4Column, widget.localChannel4ColumnData],
      [widget.localChannel5Column, widget.localChannel5ColumnData],
      [widget.localChannel6Column, widget.localChannel6ColumnData],
      [widget.localChannel7Column, widget.localChannel7ColumnData],
      [widget.localChannel8Column, widget.localChannel8ColumnData],
    ];
    for (var n = 0; n < localChannels.length; n++) {
      add('<L-CH${n + 1}>', localChannels[n][0], localChannels[n][1], 100);
    }

    return sections;
  }
}

bool _isBlank(String text) {
  final t = text.trim();
  return t.isEmpty || t == '-';
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers (kept public – other files may use them)
// ─────────────────────────────────────────────────────────────────────────────

const int _kBoxHeightCharsPerLine = 20;

int _estimatedLinesFor(String text) {
  int lines = 0;
  for (var segment in text.split('\n')) {
    if (segment.isEmpty) {
      lines += 1;
    } else if (segment.contains(', ')) {
      // Wrapping text (e.g. "13.001, 13.002, 13.003" in the Valves/Sequence
      // columns) - estimate how many lines it needs instead of clipping.
      lines += (segment.length / _kBoxHeightCharsPerLine).ceil().clamp(1, 3);
    } else {
      lines += 1;
    }
  }
  return lines;
}

Color reasonColor(String reason) {
  final r = reason.trim().toLowerCase();
  if (r.isEmpty || r == '-') return Colors.black45;
  if (r.contains('stopped')) return const Color(0xffC62828);
  if (r.contains('skipped')) return const Color(0xffD84315);
  if (r.contains('paused')) return const Color(0xffEF6C00);
  if (r.contains('completed')) return const Color(0xff2E7D32);
  if (r.contains('resumed')) return const Color(0xff00838F);
  if (r.contains('started')) return const Color(0xff1565C0);
  return const Color(0xff424242);
}

IconData reasonIcon(String reason) {
  final r = reason.trim().toLowerCase();
  if (r.isEmpty || r == '-') return Icons.remove;
  if (r.contains('stopped')) return Icons.stop_circle_outlined;
  if (r.contains('skipped')) return Icons.skip_next_rounded;
  if (r.contains('paused')) return Icons.pause_circle_outline;
  if (r.contains('completed')) return Icons.check_circle_outline;
  if (r.contains('resumed')) return Icons.play_circle_outline;
  if (r.contains('started')) return Icons.play_arrow_rounded;
  return Icons.fiber_manual_record;
}

/// Renders a multi-line reason string (one reason per irrigation cycle,
/// separated by '\n') as plain text lines, matching the reference design
/// ("Schedule", "Timer ended", "Manual stop", ...).
Widget reasonCell(String raw, double height) {
  final lines = raw.split('\n');
  return SizedBox(
    height: height,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Tooltip(
              message: line,
              child: _isBlank(line)
                  ? const Text(
                '–',
                style: TextStyle(fontSize: 13.5, color: _kMutedText),
              )
                  : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: reasonColor(line),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

double getBoxHeight(dynamic filterColumnData, int i,
    [dynamic generalColumnData]) {
  int maxLines = 1;

  if (generalColumnData != null &&
      i < generalColumnData.length &&
      generalColumnData[i] is List) {
    for (var item in generalColumnData[i]) {
      if (item != null) {
        int lines = _estimatedLinesFor(item.toString());
        if (lines > maxLines) maxLines = lines;
      }
    }
  }

  if (filterColumnData != null &&
      i < filterColumnData.length &&
      filterColumnData[i] is List &&
      filterColumnData[i].isNotEmpty) {
    for (var item in filterColumnData[i]) {
      if (item != null) {
        int lines = _estimatedLinesFor(item.toString());
        if (lines > maxLines) maxLines = lines;
      }
    }
  }

  return (64 + ((maxLines - 1) * 17)).toDouble();
}

Widget getColumnDotLine() {
  return SizedBox(
    width: 0,
    height: 50,
    child: CustomPaint(
      painter: VerticalDotBorder(),
      size: const Size(0, 50),
    ),
  );
}

class VerticalDotBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint border = Paint();
    border.color = Colors.black;
    border.strokeWidth = 0.5;
    const double dashWidth = 5;
    const double dashSpace = 5;
    double currentY = 0;

    while (currentY < size.height) {
      canvas.drawLine(
          Offset(0, currentY), Offset(0, currentY + dashWidth), border);
      currentY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
