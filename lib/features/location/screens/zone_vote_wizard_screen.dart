import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';

class ZoneVoteWizardScreen extends StatefulWidget {
  const ZoneVoteWizardScreen({super.key});

  @override
  State<ZoneVoteWizardScreen> createState() => _ZoneVoteWizardScreenState();
}

class _ZoneVoteWizardScreenState extends State<ZoneVoteWizardScreen> {
  static const int _totalSteps = 4;

  // Local queue (fallback)
  static const String _queueKey = 'zone_vote_queue_v1';
  static const int _maxQueue = 20;

  // Stable identifiers for guests/devices
  static const String _deviceIdKey = 'zone_vote_device_id_v1';
  static const String _guestIdKey = 'zone_vote_guest_id_v1';

  static const String _authReturnTag = 'zone_vote';

  final PageController _pc = PageController();
  int _step = 0;

  bool _isNavigating = false;

  // Submit state
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _showAuthCta = false;

  // UX status message (inline, no snackbar)
  String? _statusText;

  // If user submitted as guest, we keep vote and wait for auth to "link"
  bool _pendingAuthLink = false;

  // Data (MVP)
  bool notifyMe = true;

  // Service types: user can add ANY text
  final Set<String> serviceTypes = <String>{};
  final TextEditingController serviceTypeCtrl = TextEditingController();

  final TextEditingController shopNamesCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  // ✅ New: optional location clarification for humans (street/landmark/etc.)
  final TextEditingController locationDetailsCtrl = TextEditingController();

  // Optional suggestions (not limiting)
  final List<String> suggestedTypes = const [
    'Restaurant',
    'Grocery',
    'Pharmacy',
    'Coffee',
    'Bakery',
    'Flowers',
    'Pet store',
    'Electronics',
    'Supermarket',
    'Butcher',
    'Veg & Fruits',
    'Beauty',
  ];

  // args (from navigation)
  String? get lat => (Get.arguments is Map && (Get.arguments as Map)['lat'] != null)
      ? (Get.arguments as Map)['lat'].toString()
      : Get.parameters['lat'];

  String? get lng => (Get.arguments is Map && (Get.arguments as Map)['lng'] != null)
      ? (Get.arguments as Map)['lng'].toString()
      : Get.parameters['lng'];

  String? get address => (Get.arguments is Map && (Get.arguments as Map)['address'] != null)
      ? (Get.arguments as Map)['address'].toString()
      : Get.parameters['address'];

  // Optional extras if available from caller
  String? get countryCode => (Get.arguments is Map && (Get.arguments as Map)['country_code'] != null)
      ? (Get.arguments as Map)['country_code'].toString()
      : Get.parameters['country_code'];

  String? get state => (Get.arguments is Map && (Get.arguments as Map)['state'] != null)
      ? (Get.arguments as Map)['state'].toString()
      : Get.parameters['state'];

  String? get city => (Get.arguments is Map && (Get.arguments as Map)['city'] != null)
      ? (Get.arguments as Map)['city'].toString()
      : Get.parameters['city'];

  String? get district => (Get.arguments is Map && (Get.arguments as Map)['district'] != null)
      ? (Get.arguments as Map)['district'].toString()
      : Get.parameters['district'];

  bool get _isLoggedIn => AuthHelper.isLoggedIn();

  @override
  void dispose() {
    _pc.dispose();
    serviceTypeCtrl.dispose();
    shopNamesCtrl.dispose();
    notesCtrl.dispose();
    locationDetailsCtrl.dispose();
    super.dispose();
  }

  String _titleForStep(int s) {
    switch (s) {
      case 0:
        return 'Confirm area';
      case 1:
        return 'What do you need?';
      case 2:
        return 'Notify me';
      case 3:
        return 'Review';
      default:
        return 'Zone vote';
    }
  }

  IconData _iconForStep(int s) {
    switch (s) {
      case 0:
        return Icons.place_outlined;
      case 1:
        return Icons.storefront_outlined;
      case 2:
        return Icons.notifications_active_outlined;
      case 3:
        return Icons.fact_check_outlined;
      default:
        return Icons.how_to_vote_outlined;
    }
  }

  Future<void> _goToStep(int target) async {
    if (_isNavigating) return;
    if (target < 0 || target >= _totalSteps) return;
    if (!_pc.hasClients) return;

    _isNavigating = true;
    try {
      await _pc.animateToPage(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );

      if (mounted) setState(() => _step = target);
    } finally {
      _isNavigating = false;
      if (mounted) setState(() {});
    }
  }

  void _next() => _goToStep(_step + 1);
  void _back() => _goToStep(_step - 1);

  void _addServiceType(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return;

    final normalized = v.replaceAll(RegExp(r'\s+'), ' ');
    setState(() {
      serviceTypes.add(normalized);
      serviceTypeCtrl.clear();
    });
  }

  String _prettyPlaceLabel() {
    final a = (address ?? '').trim();

    // If the caller passed a nice address, show it.
    if (a.isNotEmpty) return a;

    // Otherwise fallback to city/state/country if they exist.
    final parts = <String>[
      (district ?? '').trim(),
      (city ?? '').trim(),
      (state ?? '').trim(),
      (countryCode ?? '').trim(),
    ].where((e) => e.isNotEmpty).toList();

    if (parts.isNotEmpty) return parts.join(' • ');

    return 'Selected location';
  }

  double? _parseDouble(String? s) {
    if (s == null) return null;
    return double.tryParse(s.trim());
  }

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  String _randomId(String prefix) {
    final r = Random();
    final n1 = DateTime.now().millisecondsSinceEpoch;
    final n2 = r.nextInt(1 << 20);
    return '$prefix-$n1-$n2';
  }

  Future<String> _getOrCreateStableId(String key, String prefix) async {
    final p = await _prefs();
    final existing = p.getString(key);
    if (existing != null && existing.trim().isNotEmpty) return existing.trim();
    final created = _randomId(prefix);
    await p.setString(key, created);
    return created;
  }

  Future<void> _enqueueDraft(Map<String, dynamic> draft) async {
    final prefs = await _prefs();
    final raw = prefs.getString(_queueKey);
    List<dynamic> list = [];

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) list = decoded;
      } catch (_) {
        list = [];
      }
    }

    list.add(draft);

    if (list.length > _maxQueue) {
      list = list.sublist(list.length - _maxQueue);
    }

    await prefs.setString(_queueKey, jsonEncode(list));
  }

  bool _hasAnyMeaningfulInput() {
    if (serviceTypes.isNotEmpty) return true;
    if (shopNamesCtrl.text.trim().isNotEmpty) return true;
    if (notesCtrl.text.trim().isNotEmpty) return true;
    if (locationDetailsCtrl.text.trim().isNotEmpty) return true;
    return false;
  }

  Map<String, dynamic> _buildDraft() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
      'place_label': _prettyPlaceLabel(),
      'location_details': locationDetailsCtrl.text.trim(),
      'service_types': serviceTypes.toList(),
      'requested_shops': shopNamesCtrl.text.trim(),
      'notes': notesCtrl.text.trim(),
      'notify': notifyMe,
      'created_at': DateTime.now().toIso8601String(),
      'logged_in_at_submit': _isLoggedIn,
    };
  }

  List<String> _splitShops(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return [];
    return t
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(10)
        .toList();
  }

  /// Builds the backend payload for POST /api/v1/zone-votes
  Future<Map<String, dynamic>> _buildApiPayload() async {
    final latD = _parseDouble(lat);
    final lngD = _parseDouble(lng);

    final deviceId = await _getOrCreateStableId(_deviceIdKey, 'device');
    final guestId = await _getOrCreateStableId(_guestIdKey, 'guest');

    // Combine human-friendly extra location detail into note to help admin.
    final extraLoc = locationDetailsCtrl.text.trim();
    final extraNote = notesCtrl.text.trim();

    final noteParts = <String>[];
    if (extraLoc.isNotEmpty) noteParts.add('📍 Location detail: $extraLoc');
    if (extraNote.isNotEmpty) noteParts.add(extraNote);

    final noteFinal = noteParts.isEmpty ? null : noteParts.join('\n');

    // choose a "store_type" representative (keep server simple)
    final storeType = serviceTypes.isNotEmpty ? serviceTypes.first : null;

    // suggested stores list
    final shops = _splitShops(shopNamesCtrl.text);

    // try to get FCM token if your app stored it in prefs (optional)
    String? fcmToken;
    try {
      final p = await _prefs();
      final t = p.getString('fcm_token');
      if (t != null && t.trim().isNotEmpty) fcmToken = t.trim();
    } catch (_) {}

    final payload = <String, dynamic>{
      'user_id': _isLoggedIn ? null : null, // server will accept null; if you later want, we can send real user_id
      'guest_id': _isLoggedIn ? null : guestId,
      'device_id': deviceId,

      'fcm_token': fcmToken,

      'country_code': (countryCode ?? '').trim().isEmpty ? null : countryCode!.trim(),
      'state': (state ?? '').trim().isEmpty ? null : state!.trim(),
      'city': (city ?? '').trim().isEmpty ? null : city!.trim(),
      'district': (district ?? '').trim().isEmpty ? null : district!.trim(),

      'address': _prettyPlaceLabel(),
      'latitude': latD,
      'longitude': lngD,

      'store_type': storeType,
      'suggested_stores': shops.isEmpty ? null : shops,

      'note': noteFinal,
      'notify_enabled': notifyMe ? 1 : 0,
      'notify_via': notifyMe ? ['push'] : [],

      // keep helpful meta for admin/debug
      'meta': {
        'place_label': _prettyPlaceLabel(),
        'location_details': extraLoc,
        'service_types': serviceTypes.toList(),
        'requested_shops_raw': shopNamesCtrl.text.trim(),
        'client': 'app_zone_vote_wizard_v1',
      },
    };

    // remove nulls (clean payload)
    payload.removeWhere((k, v) => v == null);
    return payload;
  }

  Map<String, String> _safeHeaders() {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
    };

    try {
      if (Get.isRegistered<ApiClient>()) {
        headers.addAll(Get.find<ApiClient>().getHeader());
      }
    } catch (_) {}

    // Ensure proper content type (some clients override it)
    headers['Accept'] = 'application/json';
    headers['Content-Type'] = 'application/json; charset=UTF-8';

    return headers;
  }

  Future<bool> _postVoteToServer(Map<String, dynamic> payload) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/zone-votes');

    try {
      final res = await http.post(
        uri,
        headers: _safeHeaders(),
        body: jsonEncode(payload),
      );

      if (kDebugMode) {
        print('🗳️ zone-vote POST status: ${res.statusCode}');
        print(res.body);
      }

      // backend returns 200/201 on success
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      if (kDebugMode) print('🗳️ zone-vote POST error: $e');
      return false;
    }
  }

  Future<void> _submitVote() async {
    if (_isSubmitting || _submitted) return;

    if (!_hasAnyMeaningfulInput()) {
      setState(() {
        _statusText = 'يرجى إضافة نوع خدمة أو اسم متجر أو تفاصيل مكان/ملاحظة قبل الإرسال.';
        _showAuthCta = !_isLoggedIn;
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final draft = _buildDraft();
      await _enqueueDraft(draft);

      final payload = await _buildApiPayload();
      final ok = await _postVoteToServer(payload);

      if (!mounted) return;

      if (ok) {
        setState(() {
          _submitted = true;
          _pendingAuthLink = !_isLoggedIn;
          _showAuthCta = !_isLoggedIn;
          _statusText = _isLoggedIn
              ? '✅ تم إرسال التصويت بنجاح. سنقوم بإبلاغك عند توفر الخدمة في هذه المنطقة.'
              : '✅ تم إرسال التصويت كضيف بنجاح. سجّل دخولك لاحقًا حتى نضمن وصول الإشعارات لك.';
        });
      } else {
        setState(() {
          _submitted = false;
          _pendingAuthLink = false;
          _showAuthCta = !_isLoggedIn;
          _statusText =
              '⚠️ لم نتمكن من إرسال التصويت للسيرفر الآن. تم حفظه محليًا وسيُعاد إرساله لاحقًا (أو جرّب مرة أخرى).';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _goAuth({required bool signUp}) async {
    final String route = signUp
        ? RouteHelper.getSignUpRoute()
        : RouteHelper.getSignInRoute(_authReturnTag);

    await Get.toNamed(route);

    if (!mounted) return;

    if (_isLoggedIn) {
      setState(() {
        _showAuthCta = false;

        if (_pendingAuthLink) {
          _pendingAuthLink = false;
          _submitted = true;
          _statusText = '✅ تم تسجيل الدخول. إذا كنت تريد، أعد إرسال التصويت للتأكد من ربطه بحسابك.';
        } else {
          _statusText ??= '✅ تم تسجيل الدخول بنجاح.';
        }
      });
    }
  }

  Widget _selectedTypeChip(String label) {
    return InputChip(
      label: Text(label),
      onDeleted: () => setState(() => serviceTypes.remove(label)),
    );
  }

  Widget _suggestedTypeChip(String label) {
    final selected = serviceTypes.contains(label);
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (v) {
        setState(() {
          if (v) {
            serviceTypes.add(label);
          } else {
            serviceTypes.remove(label);
          }
        });
      },
    );
  }

  Widget _guestCtaCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stay in the loop', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            'You are currently browsing as a guest. Create an account or log in so we can notify you when stores become available in this area.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _goAuth(signUp: false),
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Login'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _goAuth(signUp: true),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Create account'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primaryColor.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconForStep(_step), color: theme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _titleForStep(_step),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(ThemeData theme, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool isLast = _step == _totalSteps - 1;
    final bool isBeforeLast = _step == _totalSteps - 2;
    final bool disableActions = _isNavigating || _isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: disableActions
              ? null
              : () => (_step == 0) ? Get.back() : _back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _stepHeader(theme),

            // Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: List.generate(_totalSteps, (i) {
                  final active = i <= _step;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 6,
                      margin: EdgeInsets.only(right: i == _totalSteps - 1 ? 0 : 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: active ? theme.primaryColor : theme.disabledColor.withAlpha(64),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pc,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1: confirm area (NO lat/lng visible)
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selected location', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 10),

                        _card(
                          theme,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _prettyPlaceLabel(),
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'We’ll use this to prioritize onboarding stores in your area.',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),

                              // ✅ New optional field to clarify the location
                              Text(
                                'More details (optional)',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: locationDetailsCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. “Near X”, “Street Y”, “Next to Z mall”…',
                                  border: OutlineInputBorder(),
                                ),
                                minLines: 1,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        Text(
                          'Tip: add a landmark so the admin understands the exact area faster.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // Step 2: needs (NO LIMIT)
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: ListView(
                      children: [
                        Text('What do you need?', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          'Add any service types you want. Suggestions below are optional.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),

                        if (serviceTypes.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: serviceTypes.map(_selectedTypeChip).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: serviceTypeCtrl,
                                textInputAction: TextInputAction.done,
                                onSubmitted: _addServiceType,
                                decoration: const InputDecoration(
                                  hintText: 'Type any service type and tap +',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () => _addServiceType(serviceTypeCtrl.text),
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: 'Add',
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: suggestedTypes.map(_suggestedTypeChip).toList(),
                        ),

                        const SizedBox(height: 18),
                        Text('Requested shops (optional)', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextField(
                          controller: shopNamesCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. KFC, Lidl, ... (comma separated)',
                            border: OutlineInputBorder(),
                          ),
                          minLines: 2,
                          maxLines: 3,
                        ),

                        const SizedBox(height: 18),
                        Text('Notes (optional)', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. late-night delivery, prefer card payment...',
                            border: OutlineInputBorder(),
                          ),
                          minLines: 2,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),

                  // Step 3: notify
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notify me', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 10),

                        _card(
                          theme,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Get notified when service becomes available?',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: notifyMe,
                                onChanged: (v) => setState(() => notifyMe = v),
                                title: const Text('Enable notifications'),
                                subtitle: const Text('We’ll notify you when stores launch in your area.'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        Text(
                          'If notifications are enabled, the app will send your device token when available.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // Step 4: review
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: ListView(
                      children: [
                        Text('Review', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 10),

                        _card(
                          theme,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _kv('Location', _prettyPlaceLabel()),
                              _kv('More details', locationDetailsCtrl.text.trim().isEmpty ? '-' : locationDetailsCtrl.text.trim()),
                              _kv('Types', serviceTypes.isEmpty ? '-' : serviceTypes.join(', ')),
                              _kv('Requested shops', shopNamesCtrl.text.trim().isEmpty ? '-' : shopNamesCtrl.text.trim()),
                              _kv('Notes', notesCtrl.text.trim().isEmpty ? '-' : notesCtrl.text.trim()),
                              _kv('Notify', notifyMe ? 'Yes' : 'No'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (_statusText != null) ...[
                          _card(
                            theme,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _submitted ? Icons.check_circle_outline : Icons.info_outline,
                                  color: _submitted ? theme.primaryColor : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _statusText!,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (_showAuthCta && !_isLoggedIn) ...[
                          _guestCtaCard(theme),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom actions (Submit replaces Next on last step)
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: disableActions
                          ? null
                          : (_step == 0 || (isLast && _submitted))
                              ? () => Get.back(result: _submitted)
                              : _back,
                      child: Text((_step == 0 || (isLast && _submitted)) ? 'Close' : 'Back'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: disableActions
                          ? null
                          : isLast
                              ? (_submitted ? () => Get.back(result: true) : _submitVote)
                              : _next,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isLast
                                  ? (_submitted ? 'Done' : 'Submit vote')
                                  : (isBeforeLast ? 'Review' : 'Next'),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
