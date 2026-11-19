import '../api/api_auth_session.dart';
import '../api/api_client.dart';
import '../models/news_item.dart';
import '../models/reward_item.dart';
import '../models/user_profile.dart';
import '../models/waste_bank.dart';
import '../models/waste_deposit.dart';

class PickupRequest {
  const PickupRequest({
    required this.material,
    required this.category,
    required this.weightKg,
    required this.address,
    required this.scheduledAt,
    this.notes,
    this.wasteBankId,
  });

  final String material;
  final String category;
  final double weightKg;
  final String address;
  final DateTime scheduledAt;
  final String? notes;
  final String? wasteBankId;
}

class QrSession {
  const QrSession({
    required this.token,
    required this.qrPayload,
    required this.expiresAt,
    required this.expiresInSeconds,
    required this.memberCode,
  });

  final String token;
  final String qrPayload;
  final DateTime expiresAt;
  final int expiresInSeconds;
  final String memberCode;

  factory QrSession.fromJson(Map<String, dynamic> json) {
    final member = Map<String, dynamic>.from(json['member'] as Map);
    return QrSession(
      token: json['token'] as String,
      qrPayload: json['qrPayload'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
      memberCode: member['memberCode'] as String? ?? '',
    );
  }
}

class DepositSummary {
  const DepositSummary({
    required this.total,
    required this.completed,
    required this.totalWeightKg,
    required this.totalPoints,
  });

  final int total;
  final int completed;
  final double totalWeightKg;
  final int totalPoints;

  factory DepositSummary.fromJson(Map<String, dynamic> json) => DepositSummary(
    total: (json['total'] as num?)?.toInt() ?? 0,
    completed: (json['completed'] as num?)?.toInt() ?? 0,
    totalWeightKg: (json['totalWeightKg'] as num?)?.toDouble() ?? 0,
    totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
  );
}

class AppRepository {
  AppRepository(this.api);

  final ApiClient api;

  Future<ApiAuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await api.post(
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
    );
    return ApiAuthSession.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<ApiAuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final json = await api.post(
      '/api/v1/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );
    return ApiAuthSession.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<void> logout() async {
    try {
      await api.post('/api/v1/auth/logout');
    } finally {
      await api.tokenStore.clear();
    }
  }

  Future<UserProfile> getProfile() async {
    final json = await api.get('/api/v1/me');
    return UserProfile.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<UserProfile> updateProfile({String? name, String? avatarUrl}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    final json = await api.patch('/api/v1/me', body: body);
    return UserProfile.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<List<NewsItem>> getNews({int limit = 10}) async {
    final json = await api.get(
      '/api/v1/news',
      query: {'page': '1', 'limit': '$limit'},
    );
    final data = (json as Map)['data'] as List;
    return data
        .map(
          (item) => NewsItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<NewsItem> getNewsDetail(String id) async {
    final json = await api.get('/api/v1/news/$id');
    return NewsItem.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<List<WasteDeposit>> getDeposits({
    String? method,
    String sort = 'newest',
    int limit = 20,
  }) async {
    final query = <String, String>{
      'page': '1',
      'limit': '$limit',
      'sort': sort,
    };
    if (method != null) query['method'] = method;
    final json = await api.get('/api/v1/deposits', query: query);
    final data = (json as Map)['data'] as List;
    return data
        .map(
          (item) =>
              WasteDeposit.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<DepositSummary> getDepositSummary() async {
    final json = await api.get('/api/v1/deposits/summary');
    return DepositSummary.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<List<WasteBank>> getWasteBanks({
    double? latitude,
    double? longitude,
    String? query,
    bool openOnly = false,
    int limit = 50,
  }) async {
    final params = <String, String>{'page': '1', 'limit': '$limit'};
    if (latitude != null && longitude != null) {
      params['lat'] = '$latitude';
      params['lng'] = '$longitude';
    }
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
    if (openOnly) params['openOnly'] = 'true';

    final json = await api.get('/api/v1/waste-banks', query: params);
    final data = (json as Map)['data'] as List;
    return data
        .map(
          (item) => WasteBank.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<QrSession> createQrSession() async {
    final json = await api.post('/api/v1/qr/session');
    return QrSession.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<WasteDeposit> createPickup(PickupRequest request) async {
    final json = await api.post(
      '/api/v1/deposits',
      body: {
        'method': 'pickup',
        'material': request.material,
        'category': request.category,
        'weightKg': request.weightKg,
        'address': request.address,
        'scheduledAt': request.scheduledAt.toUtc().toIso8601String(),
        if (request.notes != null && request.notes!.trim().isNotEmpty)
          'notes': request.notes!.trim(),
        if (request.wasteBankId != null) 'wasteBankId': request.wasteBankId,
      },
    );
    return WasteDeposit.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<void> cancelDeposit(String id) async {
    await api.post('/api/v1/deposits/$id/cancel');
  }

  Future<List<Map<String, dynamic>>> getOfficerDeposits() async {
    final json = await api.get(
      '/api/v1/officer/deposits',
      query: {'page': '1', 'limit': '50'},
    );
    final data = (json as Map)['data'] as List;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> scanDeposit({
    String? token,
    String? memberCode,
    required List<Map<String, dynamic>> items,
    String? wasteBankId,
  }) async {
    final json = await api.post(
      '/api/v1/qr/scan',
      body: {
        'token': ?token,
        'memberCode': ?memberCode,
        'items': items,
        'wasteBankId': ?wasteBankId,
      },
    );
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> completeDeposit({
    required String id,
    required List<Map<String, dynamic>> items,
    String? wasteBankId,
  }) async {
    final json = await api.post(
      '/api/v1/deposits/$id/complete',
      body: {'items': items, 'wasteBankId': ?wasteBankId},
    );
    return Map<String, dynamic>.from(json as Map);
  }

  Future<List<RewardItem>> getRewards({int limit = 50}) async {
    final json = await api.get(
      '/api/v1/rewards',
      query: {'page': '1', 'limit': '$limit'},
    );
    final data = (json as Map)['data'] as List;
    return data
        .map(
          (item) => RewardItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> redeemReward(String rewardId) async {
    await api.post('/api/v1/rewards/$rewardId/redeem');
  }
}
