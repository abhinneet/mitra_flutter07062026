// ═══════════════════════════════════════════════════════
// MITRA API Service — Dio client with auth + auto-refresh
// Mirrors services/api.ts from Expo project
// ═══════════════════════════════════════════════════════

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

// ── Dio singleton ──────────────────────────────────────
class ApiService {
  ApiService._();
  static final ApiService _instance = ApiService._();
  static ApiService get instance => _instance;

  late final Dio _dio;

  void init() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _dio = Dio(BaseOptions(
      baseUrl:        baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // ── Request interceptor: attach JWT ──────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'mitra_access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },

      // ── Response interceptor: auto-refresh on 401 ──
      onError: (error, handler) async {
        final response = error.response;
        if (response?.statusCode == 401) {
          final code = response?.data?['code'];

          if (code == 'ACCOUNT_INACTIVE') {
            await _storage.delete(key: 'mitra_access_token');
            await _storage.delete(key: 'mitra_refresh_token');
            handler.reject(error);
            return;
          }

          // Try silent token refresh
          try {
            final refreshToken = await _storage.read(key: 'mitra_refresh_token');
            final refreshDio = Dio();
            final res = await refreshDio.post(
              '$baseUrl/api/auth/refresh',
              data: {'refreshToken': refreshToken},
            );
            final newToken = res.data['accessToken'] as String;
            await _storage.write(key: 'mitra_access_token', value: newToken);

            // Retry original request with new token
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newToken';
            final retryRes = await _dio.fetch(opts);
            handler.resolve(retryRes);
            return;
          } catch (_) {
            await _storage.delete(key: 'mitra_access_token');
            await _storage.delete(key: 'mitra_refresh_token');
          }
        }
        handler.reject(error);
      },
    ));
  }

  Dio get dio => _dio;
}

// ── Convenience getter ─────────────────────────────────
Dio get api => ApiService.instance.dio;

// ═══════════════════════════════════════════════════════
// API Methods by Domain — mirrors Expo authAPI, usersAPI, etc.
// ═══════════════════════════════════════════════════════

class AuthAPI {
  static Future<Response> login(String phone, String role) =>
      api.post('/api/auth/login', data: {'phone': phone, 'role': role});

  static Future<Response> verifyOTP(String phone, String otp, String role) =>
      api.post('/api/auth/verify-otp', data: {'phone': phone, 'otp': otp, 'role': role});

  static Future<Response> me() => api.get('/api/auth/me');

  static Future<Response> logout() => api.post('/api/auth/logout');

  static Future<Response> refresh(String refreshToken) =>
      api.post('/api/auth/refresh', data: {'refreshToken': refreshToken});
}

class UsersAPI {
  static Future<Response> me() => api.get('/api/users/me');

  static Future<Response> update(String id, Map<String, dynamic> data) =>
      api.put('/api/users/$id', data: data);
}

class CurriculumAPI {
  static Future<Response> tree() => api.get('/api/curriculum/tree');

  static Future<Response> arTopics(Map<String, String> params) =>
      api.get('/api/curriculum/ar-topics', queryParameters: params);

  static Future<Response> hierarchy(String stateCode) =>
      api.get('/api/curriculum/hierarchy/$stateCode');
}

class ArAPI {
  static Future<Response> assets(Map<String, String> params) =>
      api.get('/api/ar/assets', queryParameters: params);

  static Future<Response> asset(String id) => api.get('/api/ar/assets/$id');

  static Future<Response> links(String nodeId) => api.get('/api/ar/links/$nodeId');
}

class QuizAPI {
  static Future<Response> list(Map<String, String> params) =>
      api.get('/api/quiz', queryParameters: params);

  static Future<Response> questions(String id) => api.get('/api/quiz/$id/questions');

  static Future<Response> submit(Map<String, dynamic> payload) =>
      api.post('/api/quiz/attempts', data: payload);
}

class TelemetryAPI {
  static Future<Response> send(Map<String, dynamic> payload) =>
      api.post('/api/analytics/telemetry', data: payload);
}

class AdsAPI {
  static Future<Response> list(Map<String, String> params) =>
      api.get('/api/ads', queryParameters: params);

  static Future<Response> impression(Map<String, dynamic> payload) =>
      api.post('/api/ads/impressions', data: payload);
}

class NotificationsAPI {
  static Future<Response> list({String? status}) =>
      api.get('/api/notifications',
          queryParameters: status != null ? {'status': status} : null);
}

class DashboardAPI {
  static Future<Response> summary() => api.get('/api/dashboard/summary');

  static Future<Response> overview(Map<String, String> params) =>
      api.get('/api/analytics/overview', queryParameters: params);

  static Future<Response> classroom(Map<String, String> params) =>
      api.get('/api/analytics/classroom', queryParameters: params);
}
