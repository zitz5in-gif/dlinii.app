import 'package:flutter/material.dart';

import 'place_design.dart';
import 'place_category_picker.dart';
import 'dlinii_motion.dart';

class DliniiPlaceEditor extends StatefulWidget {
  final double latitude, longitude;
  final bool dark, english;
  final Map<String, dynamic>? draft;
  final Future<void> Function(Map<String, dynamic>)? onSave;
  const DliniiPlaceEditor({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.dark,
    required this.english,
    this.draft,
    this.onSave,
  });
  @override
  State<DliniiPlaceEditor> createState() => _DliniiPlaceEditorState();
}

class _DliniiPlaceEditorState extends State<DliniiPlaceEditor> {
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  final _expanded = <String>{};
  String? _saveError;
  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final value = draft();
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave?.call(value);
      if (mounted)
        Navigator.pop(context, {
          ...value,
          '_action': widget.onSave == null ? 'save' : 'saved',
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _saving = false;
          _saveError = t(
            'تعذر حفظ المكان. حاول مجدداً.',
            'Could not save. Please try again.',
          );
        });
    }
  }

  late final TextEditingController _name,
      _lat,
      _lng,
      _phone,
      _website,
      _about,
      _hours,
      _address;
  late String _category;
  late String _hoursMode;
  late final TextEditingController _aliases;
  String t(String ar, String en) => widget.english ? en : ar;
  Color get ink =>
      widget.dark ? const Color(0xFFEAF3F7) : const Color(0xFF203540);
  Color get muted =>
      widget.dark ? const Color(0xFF97ABA2) : const Color(0xFF667E8B);
  Color get surface =>
      widget.dark ? const Color(0xFF09272E) : const Color(0xFFF2F6F9);
  @override
  void initState() {
    super.initState();
    final d = widget.draft ?? {};
    _aliases = TextEditingController(text: d['aliases']?.toString() ?? '');
    _hoursMode =
        d['hoursMode']?.toString() ??
        ((d['hours']?.toString() ?? '').isEmpty ? 'unspecified' : 'custom');
    _name = TextEditingController(text: d['name']?.toString() ?? '');
    _lat = TextEditingController(text: widget.latitude.toStringAsFixed(6));
    _lng = TextEditingController(text: widget.longitude.toStringAsFixed(6));
    _phone = TextEditingController(text: d['phone']?.toString() ?? '');
    _website = TextEditingController(text: d['website']?.toString() ?? '');
    _about = TextEditingController(text: d['about']?.toString() ?? '');
    _hours = TextEditingController(text: d['hours']?.toString() ?? '');
    _address = TextEditingController(text: d['address']?.toString() ?? '');
    _category = dliniiPlaceCategories.containsKey(d['category'])
        ? d['category'] as String
        : 'other';
  }

  @override
  void dispose() {
    for (final c in [
      _aliases,
      _name,
      _lat,
      _lng,
      _phone,
      _website,
      _about,
      _hours,
      _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? number(String value) {
    var s = value.trim().replaceAll('٫', '.');
    const digits = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < digits.length; i++) {
      s = s.replaceAll(digits[i], i.toString());
    }
    return double.tryParse(s);
  }

  Map<String, dynamic> draft() => {
    if (widget.draft?['publicId'] != null)
      'publicId': widget.draft!['publicId'],
    if (widget.draft?['id'] != null) 'id': widget.draft!['id'],
    if (widget.draft?['shortcut'] != null)
      'shortcut': widget.draft!['shortcut'],
    'name': _name.text.trim(),
    'category': _category,
    'lat': number(_lat.text),
    'lng': number(_lng.text),
    'phone': _phone.text.trim(),
    'website': _website.text.trim(),
    'about': _about.text.trim(),
    'hours': _hoursMode == 'all_day'
        ? t('مفتوح 24 ساعة', 'Open 24 hours')
        : _hoursMode == 'unspecified'
        ? ''
        : _hours.text.trim(),
    'hoursMode': _hoursMode,
    'aliases': _aliases.text.trim(),
    'address': _address.text.trim(),
  };
  Widget section(
    String number,
    String title,
    String subtitle,
    List<Widget> children,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 29,
              height: 29,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF23B9AD).withValues(alpha: .13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF15998F),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: Text(
            subtitle,
            style: TextStyle(color: muted, fontSize: 12, height: 1.5),
          ),
        ),
        ...children,
      ],
    ),
  );
  Widget field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool required = false,
    int lines = 1,
    int limit = 180,
    TextInputType? keyboard,
    String? Function(String?)? validate,
    bool ltr = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      maxLength: limit,
      keyboardType: keyboard,
      textDirection: ltr ? TextDirection.ltr : null,
      style: TextStyle(color: ink, fontSize: 14),
      validator:
          validate ??
          (value) => required && (value ?? '').trim().isEmpty
              ? t('هذا الحقل مطلوب', 'This field is required')
              : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted.withValues(alpha: .75)),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: muted.withValues(alpha: .13)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF23B9AD), width: 1.6),
        ),
      ),
    ),
  );
  Future<void> chooseCategory() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: widget.dark
          ? const Color(0xFF102F36)
          : const Color(0xFFF2F6F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => DliniiCategoryPicker(
        dark: widget.dark,
        english: widget.english,
        selected: _category,
      ),
    );
    if (mounted && value != null) setState(() => _category = value);
  }

  Widget optional(String title, List<Widget> children) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      onExpansionChanged: (open) => setState(() {
        if (open) {
          _expanded.add(title);
        } else {
          _expanded.remove(title);
        }
      }),
      trailing: AnimatedRotation(
        turns: _expanded.contains(title) ? .5 : 0,
        duration: const Duration(milliseconds: 180),
        child: DliniiSymbol('down', color: muted, size: 22),
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 12),
      iconColor: muted,
      collapsedIconColor: muted,
      title: Text(
        title,
        style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        t('اختياري', 'Optional'),
        style: TextStyle(color: muted, fontSize: 12),
      ),
      children: children,
    ),
  );
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: widget.english ? TextDirection.ltr : TextDirection.rtl,
    child: SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .92,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/dlinii_icon.png',
                      width: 36,
                      height: 36,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t('مكانك على دلّيني', 'Your place on Dlinii'),
                      style: TextStyle(
                        color: ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t('إلغاء', 'Cancel')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _form,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    16,
                    24,
                    24 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('الموقع على الخريطة', 'Map location'),
                        style: TextStyle(color: ink, fontSize: 17),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, {
                          ...draft(),
                          '_action': 'pick',
                        }),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          foregroundColor: const Color(0xFF1EA89B),
                        ),
                        child: Text(
                          t(
                            'تحديد الموقع من الخريطة',
                            'Choose location on the map',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: field(
                              _lat,
                              t('خط العرض', 'Latitude'),
                              ltr: true,
                              keyboard: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              validate: (v) {
                                final n = number(v ?? '');
                                return n == null || !n.isFinite || n.abs() > 90
                                    ? t('بين -90 و90', 'Between -90 and 90')
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: field(
                              _lng,
                              t('خط الطول', 'Longitude'),
                              ltr: true,
                              keyboard: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              validate: (v) {
                                final n = number(v ?? '');
                                return n == null || !n.isFinite || n.abs() > 180
                                    ? t('بين -180 و180', 'Between -180 and 180')
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      field(
                        _name,
                        t('اسم المكان', 'Place name'),
                        required: true,
                        limit: 100,
                        hint: t('مثال: مقهى النخيل', 'e.g. Palm Cafe'),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: surface,
                        borderRadius: BorderRadius.circular(20),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: DliniiPlaceBadge(_category),
                          title: Text(
                            t('التصنيف', 'Category'),
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                          subtitle: Text(
                            dliniiPlaceCategories[_category]![widget.english
                                ? 1
                                : 0],
                            style: TextStyle(color: ink, fontSize: 17),
                          ),
                          trailing: DliniiSymbol(
                            'down',
                            color: muted,
                            size: 22,
                          ),
                          onTap: chooseCategory,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        t('تفاصيل إضافية', 'Additional details'),
                        style: TextStyle(color: muted, fontSize: 15),
                      ),
                      optional(t('أسماء أخرى', 'Other names'), [
                        field(
                          _aliases,
                          t(
                            'الاسم البديل أو الإنجليزي',
                            'Alternative or English name',
                          ),
                        ),
                      ]),
                      optional(t('التواصل', 'Contact'), [
                        field(
                          _phone,
                          t('رقم الهاتف', 'Phone number'),
                          keyboard: TextInputType.phone,
                          ltr: true,
                          limit: 35,
                        ),
                        field(
                          _website,
                          t('الموقع الإلكتروني', 'Website'),
                          keyboard: TextInputType.url,
                          ltr: true,
                          limit: 400,
                          validate: (value) {
                            if (value == null || value.trim().isEmpty)
                              return null;
                            final uri = Uri.tryParse(value.trim());
                            return uri != null &&
                                    (uri.scheme == 'https' ||
                                        uri.scheme == 'http') &&
                                    uri.host.isNotEmpty
                                ? null
                                : t(
                                    'أدخل رابطاً يبدأ بـ https://',
                                    'Enter a URL starting with https://',
                                  );
                          },
                        ),
                      ]),
                      optional(t('عن المكان', 'About this place'), [
                        field(
                          _address,
                          t('العنوان أو أقرب نقطة دالة', 'Address or landmark'),
                        ),
                        field(
                          _about,
                          t('وصف المكان', 'Description'),
                          lines: 3,
                          limit: 700,
                        ),
                      ]),
                      optional(t('ساعات العمل', 'Opening hours'), [
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            style: ButtonStyle(
                              foregroundColor: WidgetStatePropertyAll(ink),
                              backgroundColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? const Color(0xFF087E76)
                                    : surface,
                              ),
                            ),
                            segments: [
                              ButtonSegment(
                                value: 'unspecified',
                                label: Text(t('غير محدد', 'Unset')),
                              ),
                              ButtonSegment(
                                value: 'all_day',
                                label: Text(t('24 ساعة', '24 hours')),
                              ),
                              ButtonSegment(
                                value: 'custom',
                                label: Text(t('مخصص', 'Custom')),
                              ),
                            ],
                            selected: {_hoursMode},
                            showSelectedIcon: false,
                            onSelectionChanged: (value) =>
                                setState(() => _hoursMode = value.first),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_hoursMode == 'custom')
                          field(
                            _hours,
                            t('الأيام والأوقات', 'Days & times'),
                            lines: 3,
                            limit: 300,
                            hint: t(
                              'السبت–الخميس: 8 ص–11 م، الجمعة مغلق',
                              'Mon–Sat: 8am–11pm; Sunday closed',
                            ),
                          ),
                        if (_hoursMode == 'all_day')
                          Text(
                            t('مفتوح طوال اليوم', 'Open all day'),
                            style: TextStyle(color: ink),
                          ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                children: [
                  if (_saveError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _saveError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.dark
                          ? const Color(0xFFF5F8F6)
                          : const Color(0xFF087E66),
                      foregroundColor: widget.dark
                          ? const Color(0xFF10241B)
                          : Colors.white,
                      minimumSize: const Size.fromHeight(58),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: _saving
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              DliniiLoader(
                                color: widget.dark
                                    ? const Color(0xFF10241B)
                                    : Colors.white,
                                label: t('جارٍ الحفظ', 'Saving'),
                              ),
                              const SizedBox(width: 10),
                              Text(t('جارٍ الحفظ…', 'Saving…')),
                            ],
                          )
                        : Text(
                            t('حفظ المكان', 'Save place'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'يُحفظ على جهازك ويمكنك تعديله أو حذفه',
                      'Saved on this device; edit or delete anytime',
                    ),
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
