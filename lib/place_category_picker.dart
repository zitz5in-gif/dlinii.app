import 'package:flutter/material.dart';

import 'place_design.dart';

const _groups = <List<String>>[
  [
    'مطاعم ومشروبات',
    'Food & drinks',
    'restaurant',
    'fast_food',
    'cafe',
    'bakery',
    'sweets',
    'juice',
  ],
  [
    'تسوق',
    'Shopping',
    'supermarket',
    'grocery',
    'mall',
    'shopping',
    'clothes',
    'electronics',
  ],
  ['صحة', 'Health', 'pharmacy', 'hospital', 'clinic', 'dentist', 'laboratory'],
  [
    'سيارات ووقود',
    'Cars & fuel',
    'fuel',
    'charging',
    'car_wash',
    'car_service',
  ],
  [
    'بنوك ومواصلات',
    'Banking & transport',
    'bank',
    'atm',
    'bus',
    'taxi',
    'parking',
  ],
  [
    'ترفيه وإقامة',
    'Leisure & stays',
    'park',
    'gym',
    'stadium',
    'hotel',
    'guesthouse',
  ],
  [
    'معالم وتعليم',
    'Places & education',
    'tourism',
    'museum',
    'landmark',
    'mosque',
    'school',
  ],
  [
    'خدمات عامة ومهنية',
    'Public & professional',
    'government',
    'police_station',
    'post',
    'lawyer',
    'accountant',
    'engineering',
    'consulting',
    'translation',
    'printing',
  ],
  [
    'بناء وصيانة',
    'Building & repairs',
    'contractor',
    'builder',
    'decor',
    'building_materials',
    'ac',
    'electrician',
    'plumber',
    'carpenter',
    'appliance',
    'cleaning',
  ],
  [
    'خدمات أخرى',
    'More services',
    'barber',
    'beauty',
    'tailor',
    'laundry',
    'mobile',
    'software',
    'internet',
    'other',
  ],
];

class DliniiCategoryPicker extends StatefulWidget {
  final bool dark, english;
  final String selected;
  const DliniiCategoryPicker({
    super.key,
    required this.dark,
    required this.english,
    required this.selected,
  });
  @override
  State<DliniiCategoryPicker> createState() => _DliniiCategoryPickerState();
}

class _DliniiCategoryPickerState extends State<DliniiCategoryPicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final ink = widget.dark ? Colors.white : const Color(0xFF142D25);
    final card = widget.dark ? const Color(0xFF09272E) : Colors.white;
    return Directionality(
      textDirection: widget.english ? TextDirection.ltr : TextDirection.rtl,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .85,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.english ? 'Dlinii categories' : 'تصنيفات دلّيني',
                        style: TextStyle(
                          color: ink,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(widget.english ? 'Close' : 'إغلاق'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (value) =>
                      setState(() => query = value.trim().toLowerCase()),
                  style: TextStyle(color: ink),
                  decoration: InputDecoration(
                    hintText: widget.english
                        ? 'Find a category'
                        : 'ابحث عن تصنيف',
                    filled: true,
                    fillColor: card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final group in _groups)
                      if (group
                          .skip(2)
                          .any(
                            (id) => dliniiPlaceCategories[id]!
                                .take(2)
                                .any(
                                  (name) => name.toLowerCase().contains(query),
                                ),
                          )) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 16),
                          child: Text(
                            group[widget.english ? 1 : 0],
                            style: TextStyle(
                              color: ink.withValues(alpha: .65),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) => Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final id in group.skip(2))
                                if (dliniiPlaceCategories[id]!
                                    .take(2)
                                    .any(
                                      (name) =>
                                          name.toLowerCase().contains(query),
                                    ))
                                  SizedBox(
                                    width: (constraints.maxWidth - 20) / 3,
                                    child: Material(
                                      color: card,
                                      borderRadius: BorderRadius.circular(24),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(24),
                                        onTap: () => Navigator.pop(context, id),
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minHeight: 128,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 18,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            border: Border.all(
                                              color: widget.selected == id
                                                  ? const Color(0xFF58D8CC)
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              DliniiPlaceBadge(id, size: 46),
                                              const SizedBox(height: 12),
                                              Text(
                                                dliniiPlaceCategories[id]![widget
                                                        .english
                                                    ? 1
                                                    : 0],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: ink,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
