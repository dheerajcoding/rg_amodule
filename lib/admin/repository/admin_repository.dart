// lib/admin/repository/admin_repository.dart
//
// Repository interface + in-memory mock implementation for the Admin module.

import 'dart:async';
import '../../booking/models/booking_status.dart';
import '../models/admin_models.dart';

// ── Abstract interface ────────────────────────────────────────────────────────

abstract class IAdminRepository {
  // Poojas
  Future<List<AdminPooja>> fetchPoojas();
  Future<AdminPooja> createPooja(AdminPooja pooja);
  Future<AdminPooja> updatePooja(AdminPooja pooja);
  Future<void> deletePooja(String id);
  Future<AdminPooja> togglePooja(String id, {required bool isActive});

  // Pandits
  Future<List<AdminPandit>> fetchPandits();
  Future<AdminPandit> updatePandit(AdminPandit pandit);
  Future<AdminPandit> togglePandit(String id, {required bool isActive});
  Future<AdminPandit> toggleConsultation(
      String id, {required bool enabled});
  Future<AdminPandit> updateConsultationRates(
      String id, List<AdminRate> rates);

  // Bookings
  Future<List<AdminBookingRow>> fetchBookings();
  Future<AdminBookingRow> updateBookingStatus(
      String id, BookingStatus status);

  // Consultations
  Future<List<AdminConsultationRow>> fetchConsultations();
  Future<void> endSession(String id);
  Future<AdminConsultationRow> refundOverride(String id);

  // Reports
  Future<AdminReport> fetchReport();
}

// ── Mock implementation ───────────────────────────────────────────────────────

class MockAdminRepository implements IAdminRepository {
  MockAdminRepository() {
    _poojas = List.from(_kSeedPoojas);
    _pandits = List.from(_kSeedPandits);
    _bookings = List.from(_kSeedBookings);
    _consultations = List.from(_kSeedConsultations);
  }

  late List<AdminPooja> _poojas;
  late List<AdminPandit> _pandits;
  late List<AdminBookingRow> _bookings;
  late List<AdminConsultationRow> _consultations;

  static const _delay = Duration(milliseconds: 400);

  // ────────────────── Poojas ──────────────────────────────────────────────────

  @override
  Future<List<AdminPooja>> fetchPoojas() async {
    await Future.delayed(_delay);
    return List.unmodifiable(_poojas);
  }

  @override
  Future<AdminPooja> createPooja(AdminPooja pooja) async {
    await Future.delayed(_delay);
    _poojas.add(pooja);
    return pooja;
  }

  @override
  Future<AdminPooja> updatePooja(AdminPooja pooja) async {
    await Future.delayed(_delay);
    final idx = _poojas.indexWhere((p) => p.id == pooja.id);
    if (idx != -1) _poojas[idx] = pooja;
    return pooja;
  }

  @override
  Future<void> deletePooja(String id) async {
    await Future.delayed(_delay);
    _poojas.removeWhere((p) => p.id == id);
  }

  @override
  Future<AdminPooja> togglePooja(String id, {required bool isActive}) async {
    await Future.delayed(_delay);
    final idx = _poojas.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _poojas[idx] = _poojas[idx].copyWith(isActive: isActive);
    }
    return _poojas[idx];
  }

  // ────────────────── Pandits ─────────────────────────────────────────────────

  @override
  Future<List<AdminPandit>> fetchPandits() async {
    await Future.delayed(_delay);
    return List.unmodifiable(_pandits);
  }

  @override
  Future<AdminPandit> updatePandit(AdminPandit pandit) async {
    await Future.delayed(_delay);
    final idx = _pandits.indexWhere((p) => p.id == pandit.id);
    if (idx != -1) _pandits[idx] = pandit;
    return pandit;
  }

  @override
  Future<AdminPandit> togglePandit(String id,
      {required bool isActive}) async {
    await Future.delayed(_delay);
    final idx = _pandits.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _pandits[idx] = _pandits[idx].copyWith(isActive: isActive);
    }
    return _pandits[idx];
  }

  @override
  Future<AdminPandit> toggleConsultation(String id,
      {required bool enabled}) async {
    await Future.delayed(_delay);
    final idx = _pandits.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _pandits[idx] =
          _pandits[idx].copyWith(consultationEnabled: enabled);
    }
    return _pandits[idx];
  }

  @override
  Future<AdminPandit> updateConsultationRates(
      String id, List<AdminRate> rates) async {
    await Future.delayed(_delay);
    final idx = _pandits.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _pandits[idx] = _pandits[idx].copyWith(consultationRates: rates);
    }
    return _pandits[idx];
  }

  // ────────────────── Bookings ────────────────────────────────────────────────

  @override
  Future<List<AdminBookingRow>> fetchBookings() async {
    await Future.delayed(_delay);
    return List.unmodifiable(_bookings);
  }

  @override
  Future<AdminBookingRow> updateBookingStatus(
      String id, BookingStatus status) async {
    await Future.delayed(_delay);
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final b = _bookings[idx];
      _bookings[idx] = AdminBookingRow(
        id: b.id,
        packageTitle: b.packageTitle,
        clientName: b.clientName,
        panditName: b.panditName,
        status: status,
        amount: b.amount,
        isPaid: b.isPaid,
        isOnline: b.isOnline,
        scheduledAt: b.scheduledAt,
      );
    }
    return _bookings[idx];
  }

  // ────────────────── Consultations ───────────────────────────────────────────

  @override
  Future<List<AdminConsultationRow>> fetchConsultations() async {
    await Future.delayed(_delay);
    return List.unmodifiable(_consultations);
  }

  @override
  Future<void> endSession(String id) async {
    await Future.delayed(_delay);
    final idx = _consultations.indexWhere((c) => c.id == id);
    if (idx != -1 &&
        _consultations[idx].status == AdminSessionStatus.active) {
      final c = _consultations[idx];
      _consultations[idx] = AdminConsultationRow(
        id: c.id,
        panditName: c.panditName,
        clientName: c.clientName,
        status: AdminSessionStatus.ended,
        durationMinutes: c.durationMinutes,
        amountPaise: c.amountPaise,
        startedAt: c.startedAt,
      );
    }
  }

  @override
  Future<AdminConsultationRow> refundOverride(String id) async {
    await Future.delayed(_delay);
    final idx = _consultations.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final c = _consultations[idx];
      _consultations[idx] = AdminConsultationRow(
        id: c.id,
        panditName: c.panditName,
        clientName: c.clientName,
        status: AdminSessionStatus.refunded,
        durationMinutes: c.durationMinutes,
        amountPaise: c.amountPaise,
        startedAt: c.startedAt,
      );
    }
    return _consultations[idx];
  }

  // ────────────────── Reports ─────────────────────────────────────────────────

  @override
  Future<AdminReport> fetchReport() async {
    await Future.delayed(_delay);
    final completedBookings =
        _bookings.where((b) => b.status == BookingStatus.completed).length;
    final monthlyRevenue = _bookings
        .where((b) =>
            b.status == BookingStatus.completed &&
            b.isPaid &&
            b.scheduledAt.month == DateTime.now().month)
        .fold<double>(0, (acc, b) => acc + b.amount);
    return AdminReport(
      totalBookings: _bookings.length,
      monthlyBookings: _bookings
          .where((b) => b.scheduledAt.month == DateTime.now().month)
          .length,
      totalConsultations: _consultations.length,
      monthlyConsultations: _consultations
          .where((c) => c.startedAt.month == DateTime.now().month)
          .length,
      monthlyRevenuePaise: (monthlyRevenue * 100).toInt(),
      totalRevenuePaise: (_bookings
                  .where((b) =>
                      b.status == BookingStatus.completed && b.isPaid)
                  .fold<double>(0, (acc, b) => acc + b.amount) *
              100)
          .toInt(),
      activeUsers: 1240,
      totalUsers: 3870,
      activePandits:
          _pandits.where((p) => p.isActive).length,
      topPandits: [
        const TopPandit(
            name: 'Pt. Ramesh Sharma',
            bookings: 142,
            revenuePaise: 1240000,
            rating: 4.9),
        const TopPandit(
            name: 'Pt. Suresh Kumar',
            bookings: 98,
            revenuePaise: 870000,
            rating: 4.7),
        const TopPandit(
            name: 'Pt. Mahesh Tiwari',
            bookings: 84,
            revenuePaise: 740000,
            rating: 4.8),
        const TopPandit(
            name: 'Pt. Arun Joshi',
            bookings: 67,
            revenuePaise: 580000,
            rating: 4.6),
        const TopPandit(
            name: 'Pt. Dinesh Pande',
            bookings: 55,
            revenuePaise: 420000,
            rating: 4.5),
      ],
      revenueHistory: [
        const MonthlyPoint(month: 'Sep', revenuePaise: 5200000, bookings: 62),
        const MonthlyPoint(month: 'Oct', revenuePaise: 6800000, bookings: 78),
        const MonthlyPoint(month: 'Nov', revenuePaise: 7400000, bookings: 88),
        const MonthlyPoint(month: 'Dec', revenuePaise: 9400000, bookings: 110),
        const MonthlyPoint(month: 'Jan', revenuePaise: 8100000, bookings: 96),
        MonthlyPoint(
            month: 'Feb', revenuePaise: completedBookings * 150000, bookings: completedBookings),
      ],
    );
  }

  // ── Seed data ────────────────────────────────────────────────────────────────

  static final _kSeedPoojas = <AdminPooja>[
    AdminPooja(
      id: 'pj_001',
      title: 'Satyanarayan Puja',
      category: 'Prosperity',
      description:
          'A sacred Vaishnava ritual performed for blessings, prosperity, and fulfilment of wishes. Ideal for housewarming, marriage, and special occasions.',
      basePrice: 2100,
      durationMinutes: 90,
      isActive: true,
      isOnlineAvailable: true,
      tags: ['prosperity', 'blessings', 'family'],
      createdAt: DateTime(2024, 1, 10),
    ),
    AdminPooja(
      id: 'pj_002',
      title: 'Griha Pravesh',
      category: 'Housewarming',
      description:
          'Traditional housewarming ceremony to purify the new home, invite positive energy, and seek blessings from Vastu Devta.',
      basePrice: 5100,
      durationMinutes: 120,
      isActive: true,
      isOnlineAvailable: false,
      tags: ['housewarming', 'vastu', 'new home'],
      createdAt: DateTime(2024, 1, 15),
    ),
    AdminPooja(
      id: 'pj_003',
      title: 'Navgraha Shanti',
      category: 'Vedic',
      description:
          'Planetary peace puja to harmonise the nine planets (navagrahas) and neutralise malefic influences in the birth chart.',
      basePrice: 3100,
      durationMinutes: 150,
      isActive: true,
      isOnlineAvailable: true,
      tags: ['planets', 'vedic', 'shanti'],
      createdAt: DateTime(2024, 2, 5),
    ),
    AdminPooja(
      id: 'pj_004',
      title: 'Havan Ceremony',
      category: 'Fire Ritual',
      description:
          'Sacred fire offering (yagna) with specific mantras for purification, removing obstacles, and attracting divine blessings.',
      basePrice: 4500,
      durationMinutes: 180,
      isActive: true,
      isOnlineAvailable: false,
      tags: ['havan', 'fire', 'purification'],
      createdAt: DateTime(2024, 2, 20),
    ),
    AdminPooja(
      id: 'pj_005',
      title: 'Ganesh Puja',
      category: 'Beginning',
      description:
          'Invocation of Lord Ganesha to remove obstacles, bestow wisdom, and ensure success at the start of any important venture.',
      basePrice: 1100,
      durationMinutes: 45,
      isActive: true,
      isOnlineAvailable: true,
      tags: ['ganesh', 'success', 'new beginning'],
      createdAt: DateTime(2024, 3, 1),
    ),
    AdminPooja(
      id: 'pj_006',
      title: 'Lakshmi Puja',
      category: 'Prosperity',
      description:
          'Worship of Goddess Lakshmi for wealth, prosperity, and abundance. Traditionally performed on Fridays and Diwali.',
      basePrice: 1500,
      durationMinutes: 60,
      isActive: true,
      isOnlineAvailable: true,
      tags: ['lakshmi', 'wealth', 'diwali'],
      createdAt: DateTime(2024, 3, 10),
    ),
    AdminPooja(
      id: 'pj_007',
      title: 'Mundan Ceremony',
      category: 'Samskara',
      description:
          'First head-shaving samskara for infants (typically 1–3 years), marking the first significant milestone in a child\'s life.',
      basePrice: 3500,
      durationMinutes: 60,
      isActive: true,
      isOnlineAvailable: false,
      tags: ['mundan', 'children', 'samskara'],
      createdAt: DateTime(2024, 4, 1),
    ),
    AdminPooja(
      id: 'pj_008',
      title: 'Navaratri Special Havan',
      category: 'Festival',
      description:
          'Elaborate nine-night festival puja with daily archana, kumkuma, and the grand havan on Ashtami or Navami.',
      basePrice: 8500,
      durationMinutes: 240,
      isActive: false,
      isOnlineAvailable: false,
      tags: ['navaratri', 'durga', 'festival'],
      createdAt: DateTime(2024, 5, 1),
    ),
    AdminPooja(
      id: 'pj_009',
      title: 'Rudrabhishek',
      category: 'Shaivism',
      description:
          'Vedic bathing of Shivalinga with panchamrita and sacred offerings accompanied by chanting of complete Rudrashtadhyayi.',
      basePrice: 6000,
      durationMinutes: 150,
      isActive: true,
      isOnlineAvailable: true,
      tags: ['shiva', 'rudrabhishek', 'shaivism'],
      createdAt: DateTime(2024, 5, 20),
    ),
    AdminPooja(
      id: 'pj_010',
      title: 'Vivah Puja',
      category: 'Wedding',
      description:
          'Complete wedding rituals including Ganesh Puja, Saptapadi, Kanyadaan, and Mangalsutra ceremony performed by qualified purohit.',
      basePrice: 15000,
      durationMinutes: 360,
      isActive: true,
      isOnlineAvailable: false,
      tags: ['wedding', 'marriage', 'vivah'],
      createdAt: DateTime(2024, 6, 1),
    ),
  ];

  static final _now = DateTime.now();

  static final _kSeedPandits = <AdminPandit>[
    AdminPandit(
      id: 'p001',
      name: 'Pt. Ramesh Sharma',
      specialties: ['Griha Pravesh', 'Satyanarayan', 'Vaishnavism'],
      languages: ['Hindi', 'English', 'Sanskrit'],
      rating: 4.9,
      totalBookings: 1240,
      totalSessions: 318,
      isActive: true,
      consultationEnabled: true,
      consultationRates: const [
        AdminRate(durationMinutes: 10, pricePaise: 30000),
        AdminRate(durationMinutes: 15, pricePaise: 42000),
        AdminRate(durationMinutes: 20, pricePaise: 52000),
      ],
      yearsExperience: 18,
      joinedAt: DateTime(2023, 6, 1),
      email: 'ramesh.sharma@example.com',
      phone: '+91 99123 45678',
    ),
    AdminPandit(
      id: 'p002',
      name: 'Pt. Suresh Kumar',
      specialties: ['Havan', 'Navgraha Shanti', 'Vedic Rituals'],
      languages: ['Hindi', 'Sanskrit'],
      rating: 4.7,
      totalBookings: 840,
      totalSessions: 210,
      isActive: true,
      consultationEnabled: true,
      consultationRates: const [
        AdminRate(durationMinutes: 10, pricePaise: 25000),
        AdminRate(durationMinutes: 15, pricePaise: 35000),
      ],
      yearsExperience: 14,
      joinedAt: DateTime(2023, 8, 15),
      email: 'suresh.kumar@example.com',
      phone: '+91 88234 56789',
    ),
    AdminPandit(
      id: 'p003',
      name: 'Pt. Mahesh Tiwari',
      specialties: ['Rudrabhishek', 'Shaivism', 'Havan'],
      languages: ['Hindi', 'Bhojpuri', 'Sanskrit'],
      rating: 4.8,
      totalBookings: 720,
      totalSessions: 185,
      isActive: true,
      consultationEnabled: false,
      consultationRates: const [
        AdminRate(durationMinutes: 15, pricePaise: 40000),
        AdminRate(durationMinutes: 30, pricePaise: 70000),
      ],
      yearsExperience: 16,
      joinedAt: DateTime(2023, 9, 10),
      email: 'mahesh.tiwari@example.com',
      phone: '+91 77345 67890',
    ),
    AdminPandit(
      id: 'p004',
      name: 'Pt. Arun Joshi',
      specialties: ['Vivah', 'Mundan', 'Samskara'],
      languages: ['Hindi', 'Marathi', 'Sanskrit'],
      rating: 4.6,
      totalBookings: 560,
      totalSessions: 90,
      isActive: true,
      consultationEnabled: false,
      consultationRates: const [],
      yearsExperience: 12,
      joinedAt: DateTime(2023, 11, 1),
      email: 'arun.joshi@example.com',
      phone: '+91 66456 78901',
    ),
    AdminPandit(
      id: 'p005',
      name: 'Pt. Dinesh Pande',
      specialties: ['Navaratri', 'Durga Puja', 'Festival Rituals'],
      languages: ['Hindi', 'Bengali', 'Sanskrit'],
      rating: 4.5,
      totalBookings: 410,
      totalSessions: 74,
      isActive: false,
      consultationEnabled: false,
      consultationRates: const [],
      yearsExperience: 9,
      joinedAt: DateTime(2024, 1, 20),
      email: 'dinesh.pande@example.com',
      phone: '+91 55567 89012',
    ),
    AdminPandit(
      id: 'p006',
      name: 'Pt. Vinod Mishra',
      specialties: ['Ganesh Puja', 'Lakshmi Puja', 'Prosperity'],
      languages: ['Hindi', 'English'],
      rating: 4.4,
      totalBookings: 280,
      totalSessions: 52,
      isActive: true,
      consultationEnabled: true,
      consultationRates: const [
        AdminRate(durationMinutes: 10, pricePaise: 20000),
        AdminRate(durationMinutes: 15, pricePaise: 28000),
      ],
      yearsExperience: 7,
      joinedAt: DateTime(2024, 3, 5),
      email: 'vinod.mishra@example.com',
      phone: '+91 44678 90123',
    ),
  ];

  static final _kSeedBookings = <AdminBookingRow>[
    AdminBookingRow(
      id: 'bk_001',
      packageTitle: 'Satyanarayan Puja',
      clientName: 'Ravi Gupta',
      panditName: 'Pt. Ramesh Sharma',
      status: BookingStatus.completed,
      amount: 2100,
      isPaid: true,
      isOnline: false,
      scheduledAt: _now.subtract(const Duration(days: 15)),
    ),
    AdminBookingRow(
      id: 'bk_002',
      packageTitle: 'Griha Pravesh',
      clientName: 'Priya Singh',
      panditName: 'Pt. Suresh Kumar',
      status: BookingStatus.confirmed,
      amount: 5100,
      isPaid: true,
      isOnline: false,
      scheduledAt: _now.add(const Duration(days: 3)),
    ),
    AdminBookingRow(
      id: 'bk_003',
      packageTitle: 'Navgraha Shanti',
      clientName: 'Amit Patel',
      panditName: 'Pt. Mahesh Tiwari',
      status: BookingStatus.assigned,
      amount: 3100,
      isPaid: true,
      isOnline: true,
      scheduledAt: _now.add(const Duration(days: 1)),
    ),
    AdminBookingRow(
      id: 'bk_004',
      packageTitle: 'Havan Ceremony',
      clientName: 'Sunita Rao',
      panditName: null,
      status: BookingStatus.pending,
      amount: 4500,
      isPaid: false,
      isOnline: false,
      scheduledAt: _now.add(const Duration(days: 7)),
    ),
    AdminBookingRow(
      id: 'bk_005',
      packageTitle: 'Ganesh Puja',
      clientName: 'Krishna Nair',
      panditName: 'Pt. Arun Joshi',
      status: BookingStatus.completed,
      amount: 1100,
      isPaid: true,
      isOnline: true,
      scheduledAt: _now.subtract(const Duration(days: 5)),
    ),
    AdminBookingRow(
      id: 'bk_006',
      packageTitle: 'Lakshmi Puja',
      clientName: 'Deepa Mehta',
      panditName: 'Pt. Vinod Mishra',
      status: BookingStatus.completed,
      amount: 1500,
      isPaid: true,
      isOnline: true,
      scheduledAt: _now.subtract(const Duration(days: 8)),
    ),
    AdminBookingRow(
      id: 'bk_007',
      packageTitle: 'Rudrabhishek',
      clientName: 'Sunil Verma',
      panditName: 'Pt. Ramesh Sharma',
      status: BookingStatus.confirmed,
      amount: 6000,
      isPaid: true,
      isOnline: false,
      scheduledAt: _now.add(const Duration(days: 5)),
    ),
    AdminBookingRow(
      id: 'bk_008',
      packageTitle: 'Vivah Puja',
      clientName: 'Ananya & Rohan',
      panditName: 'Pt. Suresh Kumar',
      status: BookingStatus.assigned,
      amount: 15000,
      isPaid: true,
      isOnline: false,
      scheduledAt: _now.add(const Duration(days: 14)),
    ),
    AdminBookingRow(
      id: 'bk_009',
      packageTitle: 'Mundan Ceremony',
      clientName: 'Meera Sharma',
      panditName: null,
      status: BookingStatus.pending,
      amount: 3500,
      isPaid: false,
      isOnline: false,
      scheduledAt: _now.add(const Duration(days: 10)),
    ),
    AdminBookingRow(
      id: 'bk_010',
      packageTitle: 'Satyanarayan Puja',
      clientName: 'Arjun Das',
      panditName: 'Pt. Mahesh Tiwari',
      status: BookingStatus.cancelled,
      amount: 2100,
      isPaid: false,
      isOnline: true,
      scheduledAt: _now.subtract(const Duration(days: 3)),
    ),
    AdminBookingRow(
      id: 'bk_011',
      packageTitle: 'Navgraha Shanti',
      clientName: 'Rekha Kulkarni',
      panditName: 'Pt. Arun Joshi',
      status: BookingStatus.completed,
      amount: 3100,
      isPaid: true,
      isOnline: true,
      scheduledAt: _now.subtract(const Duration(days: 12)),
    ),
    AdminBookingRow(
      id: 'bk_012',
      packageTitle: 'Havan Ceremony',
      clientName: 'Aditya Kapoor',
      panditName: 'Pt. Vinod Mishra',
      status: BookingStatus.completed,
      amount: 4500,
      isPaid: true,
      isOnline: false,
      scheduledAt: _now.subtract(const Duration(days: 20)),
    ),
  ];

  static final _kSeedConsultations = <AdminConsultationRow>[
    AdminConsultationRow(
      id: 'cs_001',
      panditName: 'Pt. Ramesh Sharma',
      clientName: 'Ravi Gupta',
      status: AdminSessionStatus.active,
      durationMinutes: 15,
      amountPaise: 42000,
      startedAt: _now.subtract(const Duration(minutes: 6)),
    ),
    AdminConsultationRow(
      id: 'cs_002',
      panditName: 'Pt. Suresh Kumar',
      clientName: 'Priya Singh',
      status: AdminSessionStatus.ended,
      durationMinutes: 20,
      amountPaise: 52000,
      startedAt: _now.subtract(const Duration(hours: 2)),
    ),
    AdminConsultationRow(
      id: 'cs_003',
      panditName: 'Pt. Ramesh Sharma',
      clientName: 'Krishna Nair',
      status: AdminSessionStatus.ended,
      durationMinutes: 10,
      amountPaise: 30000,
      startedAt: _now.subtract(const Duration(hours: 5)),
    ),
    AdminConsultationRow(
      id: 'cs_004',
      panditName: 'Pt. Vinod Mishra',
      clientName: 'Deepa Mehta',
      status: AdminSessionStatus.expired,
      durationMinutes: 10,
      amountPaise: 20000,
      startedAt: _now.subtract(const Duration(hours: 3)),
    ),
    AdminConsultationRow(
      id: 'cs_005',
      panditName: 'Pt. Suresh Kumar',
      clientName: 'Amit Patel',
      status: AdminSessionStatus.active,
      durationMinutes: 15,
      amountPaise: 35000,
      startedAt: _now.subtract(const Duration(minutes: 4)),
    ),
    AdminConsultationRow(
      id: 'cs_006',
      panditName: 'Pt. Ramesh Sharma',
      clientName: 'Sunita Rao',
      status: AdminSessionStatus.refunded,
      durationMinutes: 20,
      amountPaise: 52000,
      startedAt: _now.subtract(const Duration(days: 1)),
    ),
    AdminConsultationRow(
      id: 'cs_007',
      panditName: 'Pt. Mahesh Tiwari',
      clientName: 'Sunil Verma',
      status: AdminSessionStatus.ended,
      durationMinutes: 15,
      amountPaise: 40000,
      startedAt: _now.subtract(const Duration(days: 1, hours: 3)),
    ),
    AdminConsultationRow(
      id: 'cs_008',
      panditName: 'Pt. Vinod Mishra',
      clientName: 'Meera Sharma',
      status: AdminSessionStatus.ended,
      durationMinutes: 10,
      amountPaise: 20000,
      startedAt: _now.subtract(const Duration(days: 2)),
    ),
  ];
}
