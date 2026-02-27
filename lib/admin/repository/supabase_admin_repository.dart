// lib/admin/repository/supabase_admin_repository.dart
//
// Production Supabase implementation of IAdminRepository.
//
// Schema notes:
//   special_poojas : id, title, description, significance (→ category),
//                    price (numeric rupees), duration_minutes, is_active, created_at
//   profiles        : id, full_name, role, is_active, rating, phone, created_at
//   pandit_details  : id(pk→profiles.id), specialties text[], languages text[],
//                     experience_years, consultation_enabled
//   consultation_rates: id, pandit_id, duration_minutes, price (rupees), is_active
//   bookings        : user:profiles!user_id, pandit:profiles!pandit_id
//   consultations   : user:profiles!user_id, pandit:profiles!pandit_id

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../booking/models/booking_status.dart';
import '../models/admin_models.dart';
import 'admin_repository.dart';

class SupabaseAdminRepository implements IAdminRepository {
  const SupabaseAdminRepository(this._client);

  final SupabaseClient _client;

  // ═══════════════════════════════════════════════════════════════
  // POOJAS  (special_poojas table)
  // ═══════════════════════════════════════════════════════════════

  static const _kPoojaSelect =
      'id, title, description, significance, price, duration_minutes, is_active, created_at';

  @override
  Future<List<AdminPooja>> fetchPoojas() async {
    try {
      final rows = await _client
          .from('special_poojas')
          .select(_kPoojaSelect)
          .order('created_at', ascending: false)
          .range(0, 99);
      return (rows as List)
          .map((r) => _poojaFromRow(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('fetchPoojas failed: ${e.message}');
    }
  }

  @override
  Future<AdminPooja> createPooja(AdminPooja pooja) async {
    try {
      final rows = await _client
          .from('special_poojas')
          .insert({
            'title': pooja.title,
            'description': pooja.description,
            'significance': pooja.category.isEmpty ? null : pooja.category,
            'price': pooja.basePrice,
            'duration_minutes': pooja.durationMinutes,
            'is_active': pooja.isActive,
          })
          .select(_kPoojaSelect);
      final list = rows as List;
      if (list.isEmpty) throw Exception('createPooja: no row returned');
      final row = list.first as Map<String, dynamic>;
      return _poojaFromRow(row);
    } on PostgrestException catch (e) {
      throw Exception('createPooja failed: ${e.message}');
    }
  }

  @override
  Future<AdminPooja> updatePooja(AdminPooja pooja) async {
    try {
      final rows = await _client
          .from('special_poojas')
          .update({
            'title': pooja.title,
            'description': pooja.description,
            'significance': pooja.category.isEmpty ? null : pooja.category,
            'price': pooja.basePrice,
            'duration_minutes': pooja.durationMinutes,
            'is_active': pooja.isActive,
          })
          .eq('id', pooja.id)
          .select(_kPoojaSelect);
      final list = rows as List;
      if (list.isEmpty) throw Exception('updatePooja: no row returned');
      final row = list.first as Map<String, dynamic>;
      return _poojaFromRow(row);
    } on PostgrestException catch (e) {
      throw Exception('updatePooja failed: ${e.message}');
    }
  }

  @override
  Future<void> deletePooja(String id) async {
    try {
      await _client.from('special_poojas').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('deletePooja failed: ${e.message}');
    }
  }

  @override
  Future<AdminPooja> togglePooja(String id, {required bool isActive}) async {
    try {
      final rows = await _client
          .from('special_poojas')
          .update({'is_active': isActive})
          .eq('id', id)
          .select(_kPoojaSelect);
      final list = rows as List;
      if (list.isEmpty) throw Exception('togglePooja: no row returned');
      final row = list.first as Map<String, dynamic>;
      return _poojaFromRow(row);
    } on PostgrestException catch (e) {
      throw Exception('togglePooja failed: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PANDITS  (pandit_details JOIN profiles JOIN consultation_rates)
  // ═══════════════════════════════════════════════════════════════

  static const _kPanditSelect = '''
    id,
    specialties,
    languages,
    experience_years,
    consultation_enabled,
    profiles!id(full_name, is_active, phone, created_at, rating),
    consultation_rates!pandit_id(duration_minutes, price, is_active)
  ''';

  @override
  Future<List<AdminPandit>> fetchPandits() async {
    try {
      final rows = await _client
          .from('pandit_details')
          .select(_kPanditSelect)
          .order('experience_years', ascending: false)
          .range(0, 99);

      final panditsRows = (rows as List).cast<Map<String, dynamic>>();
      final ids = panditsRows.map((r) => r['id'] as String).toList();
      if (ids.isEmpty) return [];

      // Fetch booking counts per pandit (one query, no N+1)
      final bookingRows = await _client
          .from('bookings')
          .select('pandit_id')
          .inFilter('pandit_id', ids);

      final bookingCounts = <String, int>{};
      for (final r in (bookingRows as List)) {
        final pid = (r as Map<String, dynamic>)['pandit_id'] as String;
        bookingCounts[pid] = (bookingCounts[pid] ?? 0) + 1;
      }

      // Fetch consultation counts per pandit
      final sessionRows = await _client
          .from('consultations')
          .select('pandit_id')
          .inFilter('pandit_id', ids);

      final sessionCounts = <String, int>{};
      for (final r in (sessionRows as List)) {
        final pid = (r as Map<String, dynamic>)['pandit_id'] as String;
        sessionCounts[pid] = (sessionCounts[pid] ?? 0) + 1;
      }

      return panditsRows
          .map((r) => _panditFromRow(
                r,
                totalBookings: bookingCounts[r['id'] as String] ?? 0,
                totalSessions: sessionCounts[r['id'] as String] ?? 0,
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('fetchPandits failed: ${e.message}');
    }
  }

  @override
  Future<AdminPandit> updatePandit(AdminPandit pandit) async {
    try {
      await _client.from('profiles').update({
        'full_name': pandit.name,
      }).eq('id', pandit.id);

      await _client.from('pandit_details').update({
        'specialties':      pandit.specialties,
        'languages':        pandit.languages,
        'experience_years': pandit.yearsExperience,
      }).eq('id', pandit.id);

      // Return stable copy — counts unchanged by this edit
      return pandit;
    } on PostgrestException catch (e) {
      throw Exception('updatePandit failed: ${e.message}');
    }
  }

  @override
  Future<AdminPandit> togglePandit(String id, {required bool isActive}) async {
    try {
      await _client
          .from('profiles')
          .update({'is_active': isActive})
          .eq('id', id);
      final all = await fetchPandits();
      return all.firstWhere((p) => p.id == id);
    } on PostgrestException catch (e) {
      throw Exception('togglePandit failed: ${e.message}');
    }
  }

  @override
  Future<AdminPandit> toggleConsultation(
      String id, {required bool enabled}) async {
    try {
      await _client
          .from('pandit_details')
          .update({'consultation_enabled': enabled})
          .eq('id', id);
      final all = await fetchPandits();
      return all.firstWhere((p) => p.id == id);
    } on PostgrestException catch (e) {
      throw Exception('toggleConsultation failed: ${e.message}');
    }
  }

  @override
  Future<AdminPandit> updateConsultationRates(
      String id, List<AdminRate> rates) async {
    try {
      // Replace all rates atomically: delete then insert
      await _client
          .from('consultation_rates')
          .delete()
          .eq('pandit_id', id);

      if (rates.isNotEmpty) {
        await _client.from('consultation_rates').insert(
          rates
              .map((r) => {
                    'pandit_id':       id,
                    'duration_minutes': r.durationMinutes,
                    // DB stores rupees (numeric 10,2); model stores paise
                    'price':           r.pricePaise / 100.0,
                    'is_active':       true,
                  })
              .toList(),
        );
      }

      final all = await fetchPandits();
      return all.firstWhere((p) => p.id == id);
    } on PostgrestException catch (e) {
      throw Exception('updateConsultationRates failed: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BOOKINGS
  // ═══════════════════════════════════════════════════════════════

  static const _kBookingSelect = '''
    id,
    package_title,
    booking_date,
    status,
    amount,
    is_paid,
    location,
    user:profiles!user_id(full_name),
    pandit:profiles!pandit_id(full_name)
  ''';

  @override
  Future<List<AdminBookingRow>> fetchBookings() async {
    try {
      final rows = await _client
          .from('bookings')
          .select(_kBookingSelect)
          .order('created_at', ascending: false)
          .range(0, 99);
      return (rows as List)
          .map((r) => _bookingFromRow(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('fetchBookings failed: ${e.message}');
    }
  }

  @override
  Future<AdminBookingRow> updateBookingStatus(
      String id, BookingStatus status) async {
    try {
      final result = await _client.rpc('update_booking_status', params: {
        'p_booking_id': id,
        'p_new_status': status.dbValue,
      });
      final data = result as Map<String, dynamic>;
      if (data['error'] != null) {
        throw Exception(data['error'] as String);
      }

      final rows = await _client
          .from('bookings')
          .select(_kBookingSelect)
          .eq('id', id);
      final list = rows as List;
      if (list.isEmpty) throw Exception('updateBookingStatus: no row returned');
      final row = list.first as Map<String, dynamic>;
      return _bookingFromRow(row);
    } on PostgrestException catch (e) {
      throw Exception('updateBookingStatus failed: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CONSULTATIONS
  // ═══════════════════════════════════════════════════════════════

  static const _kConsultSelect = '''
    id,
    status,
    duration_minutes,
    price,
    start_ts,
    user:profiles!user_id(full_name),
    pandit:profiles!pandit_id(full_name)
  ''';

  @override
  Future<List<AdminConsultationRow>> fetchConsultations() async {
    try {
      final rows = await _client
          .from('consultations')
          .select(_kConsultSelect)
          .order('start_ts', ascending: false)
          .range(0, 99);
      return (rows as List)
          .map((r) => _consultFromRow(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('fetchConsultations failed: ${e.message}');
    }
  }

  @override
  Future<void> endSession(String id) async {
    try {
      await _client.rpc('end_consultation_session', params: {
        'p_session_id': id,
        'p_reason':     'admin',
      });
    } on PostgrestException catch (e) {
      throw Exception('endSession failed: ${e.message}');
    }
  }

  @override
  Future<AdminConsultationRow> refundOverride(String id) async {
    try {
      // Mark as refunded (session_status enum includes 'refunded') and clear payment.
      await _client.from('consultations').update({
        'status':  'refunded',
        'is_paid': false,
      }).eq('id', id);

      final rows = await _client
          .from('consultations')
          .select(_kConsultSelect)
          .eq('id', id);
      final list = rows as List;
      if (list.isEmpty) throw Exception('refundOverride: no row returned');
      final row = list.first as Map<String, dynamic>;
      return _consultFromRow(row);
    } on PostgrestException catch (e) {
      throw Exception('refundOverride failed: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // REPORTS
  // ═══════════════════════════════════════════════════════════════

  @override
  Future<AdminReport> fetchReport() async {
    try {
      final stats =
          await _client.rpc('get_admin_stats') as Map<String, dynamic>;
      if (stats['error'] != null) {
        throw Exception(stats['error'] as String);
      }

      // Top pandits: aggregate completed booking counts + revenue
      final topRaw = await _client
          .from('bookings')
          .select('pandit_id, amount, pandit:profiles!pandit_id(full_name, rating)')
          .eq('status', 'completed')
          .not('pandit_id', 'is', null)
          .range(0, 499);

      final accum = <String, _PanditAccum>{};
      for (final r in (topRaw as List)) {
        final row    = r as Map<String, dynamic>;
        final pid    = row['pandit_id'] as String;
        final prof   = row['pandit']   as Map<String, dynamic>? ?? {};
        final name   = prof['full_name'] as String? ?? '';
        final rating = (prof['rating'] as num?)?.toDouble() ?? 0.0;
        final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
        accum.putIfAbsent(pid, () => _PanditAccum(name: name, rating: rating));
        final a = accum[pid]!;
        a.bookings++;
        a.revenuePaise += (amount * 100).toInt();
      }

      final topList = accum.entries.toList()
        ..sort((a, b) => b.value.bookings.compareTo(a.value.bookings));

      return AdminReport(
        totalBookings:        _toInt(stats['total_bookings']),
        monthlyBookings:      _toInt(stats['monthly_bookings']),
        totalConsultations:   _toInt(stats['total_consultations']),
        monthlyConsultations: _toInt(stats['monthly_consultations']),
        monthlyRevenuePaise:  _toRupeesAsPaise(stats['monthly_revenue']),
        totalRevenuePaise:    _toRupeesAsPaise(stats['total_revenue']),
        activeUsers:          _toInt(stats['active_users']),
        totalUsers:           _toInt(stats['total_users']),
        activePandits:        _toInt(stats['active_pandits']),
        topPandits: topList.take(5).map((e) => TopPandit(
              name:         e.value.name,
              bookings:     e.value.bookings,
              revenuePaise: e.value.revenuePaise,
              rating:       e.value.rating,
            )).toList(),
        // Revenue history requires a date-range aggregate query.
        // Returns empty list here; implement a separate chart RPC if needed.
        revenueHistory: const [],
      );
    } on PostgrestException catch (e) {
      throw Exception('fetchReport failed: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Row → Domain mappers
  // ═══════════════════════════════════════════════════════════════

  static AdminPooja _poojaFromRow(Map<String, dynamic> row) {
    return AdminPooja(
      id:              row['id']          as String,
      title:           row['title']       as String,
      // significance repurposed as category (no category column in special_poojas)
      category:        row['significance'] as String? ?? '',
      description:     row['description'] as String? ?? '',
      basePrice:       (row['price'] as num).toDouble(),
      durationMinutes: row['duration_minutes'] as int? ?? 60,
      isActive:        row['is_active']   as bool?   ?? true,
      // is_online_available and tags are not stored in special_poojas
      isOnlineAvailable: false,
      tags:            const [],
      createdAt:       DateTime.parse(row['created_at'] as String),
    );
  }

  static AdminPandit _panditFromRow(
    Map<String, dynamic> row, {
    required int totalBookings,
    required int totalSessions,
  }) {
    final profile   = row['profiles']     as Map<String, dynamic>? ?? {};
    final ratesList = (row['consultation_rates'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return AdminPandit(
      id:     row['id'] as String,
      name:   profile['full_name']  as String? ?? '',
      specialties: (row['specialties'] as List? ?? []).cast<String>(),
      languages:   (row['languages']   as List? ?? []).cast<String>(),
      rating:      (profile['rating']  as num?)?.toDouble() ?? 0.0,
      totalBookings:  totalBookings,
      totalSessions:  totalSessions,
      isActive:            profile['is_active']           as bool? ?? true,
      consultationEnabled: row['consultation_enabled']    as bool? ?? false,
      consultationRates: ratesList
          .where((r) => r['is_active'] as bool? ?? true)
          .map((r) => AdminRate(
                durationMinutes: r['duration_minutes'] as int,
                pricePaise:
                    ((r['price'] as num).toDouble() * 100).toInt(),
              ))
          .toList(),
      yearsExperience: row['experience_years'] as int? ?? 0,
      joinedAt: DateTime.tryParse(
              profile['created_at'] as String? ?? '') ??
          DateTime.now(),
      phone: profile['phone'] as String?,
    );
  }

  static AdminBookingRow _bookingFromRow(Map<String, dynamic> row) {
    final user       = row['user']   as Map<String, dynamic>? ?? {};
    final panditMap  = row['pandit'] as Map<String, dynamic>?;
    final locationJ  = row['location'] as Map<String, dynamic>?;
    final isOnline   = locationJ?['is_online'] as bool? ?? false;

    return AdminBookingRow(
      id:           row['id']            as String,
      packageTitle: row['package_title'] as String? ?? '',
      clientName:   user['full_name']    as String? ?? '',
      panditName:   panditMap?['full_name'] as String?,
      status:       _parseBookingStatus(row['status'] as String? ?? 'pending'),
      amount:       (row['amount'] as num).toDouble(),
      isPaid:       row['is_paid']       as bool? ?? false,
      isOnline:     isOnline,
      scheduledAt:  DateTime.tryParse(
              row['booking_date'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static AdminConsultationRow _consultFromRow(Map<String, dynamic> row) {
    final user   = row['user']   as Map<String, dynamic>? ?? {};
    final pandit = row['pandit'] as Map<String, dynamic>? ?? {};

    return AdminConsultationRow(
      id:             row['id']               as String,
      panditName:     pandit['full_name']     as String? ?? '',
      clientName:     user['full_name']       as String? ?? '',
      status:         _parseSessionStatus(row['status'] as String? ?? 'ended'),
      durationMinutes: row['duration_minutes'] as int?   ?? 0,
      // price stored as rupees in DB; model needs paise
      amountPaise:    (((row['price'] as num?)?.toDouble() ?? 0.0) * 100)
          .toInt(),
      startedAt:      DateTime.tryParse(row['start_ts'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Enum parsers + numeric helpers
  // ═══════════════════════════════════════════════════════════════

  static BookingStatus _parseBookingStatus(String s) => BookingStatus.values
      .firstWhere((v) => v.name == s, orElse: () => BookingStatus.pending);

  static AdminSessionStatus _parseSessionStatus(String s) {
    switch (s) {
      case 'active':   return AdminSessionStatus.active;
      case 'expired':  return AdminSessionStatus.expired;
      case 'refunded': return AdminSessionStatus.refunded;
      default:         return AdminSessionStatus.ended;
    }
  }

  static int _toInt(dynamic v) => (v as num?)?.toInt() ?? 0;

  /// Converts a rupees numeric field from the Stats RPC to paise (int).
  static int _toRupeesAsPaise(dynamic v) =>
      (((v as num?)?.toDouble() ?? 0.0) * 100).toInt();
}

// ── Internal accumulator for top-pandits aggregation ─────────────────────────

class _PanditAccum {
  _PanditAccum({required this.name, required this.rating});
  final String name;
  final double rating;
  int bookings     = 0;
  int revenuePaise = 0;
}
