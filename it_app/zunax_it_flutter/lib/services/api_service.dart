import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_model.dart';
import '../models/department_model.dart';
import '../models/subject_model.dart';
import '../models/user_model.dart';

class ApiService {
  String baseUrl = '';
  String db = '';
  String sessionId = '';
  int? uid;
  String apiKey = '';
  bool isDemoMode = false;

  // Completes when SharedPreferences has been loaded
  late final Future<void> initialized;

  ApiService() {
    initialized = _loadConfig();
  }

  String _sanitizeUrl(String url) {
    String clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.isEmpty) return 'http://localhost:8067';

    // Already has a valid scheme — just strip trailing slashes
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    // No scheme: strip any accidental partial scheme chars and add http://
    clean = clean.replaceAll(RegExp(r'^(https?:/*|/+)'), '').trim();
    if (clean.isEmpty || clean == 'localhost' || RegExp(r'^localhost:\d+').hasMatch(clean)) {
      return 'http://localhost:8067';
    }
    return 'http://$clean';
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('odoo_url') ?? '';
    baseUrl = _sanitizeUrl(savedUrl);
    db = prefs.getString('odoo_db') ?? '';
    sessionId = prefs.getString('odoo_session_id') ?? '';
    apiKey = prefs.getString('odoo_api_key') ?? '';
    uid = prefs.getInt('odoo_uid');
    isDemoMode = prefs.getBool('odoo_demo_mode') ?? false;
  }

  Future<void> saveConfig(String url, String database, {bool demo = false, String key = ''}) async {
    baseUrl = _sanitizeUrl(url);
    db = database.trim();
    isDemoMode = demo;
    if (key.isNotEmpty) apiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('odoo_url', baseUrl);
    await prefs.setString('odoo_db', db);
    await prefs.setBool('odoo_demo_mode', isDemoMode);
    if (apiKey.isNotEmpty) await prefs.setString('odoo_api_key', apiKey);
  }

  Future<void> saveSession(String sid, int userId) async {
    sessionId = sid;
    uid = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('odoo_session_id', sid);
    await prefs.setInt('odoo_uid', userId);
  }

  Future<void> clearSession() async {
    sessionId = '';
    uid = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('odoo_session_id');
    await prefs.remove('odoo_uid');
  }

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (sessionId.isNotEmpty) {
      headers['X-Openerp-Session-Id'] = sessionId;
    }
    if (apiKey.isNotEmpty) {
      headers['X-API-Key'] = apiKey;
    }
    return headers;
  }

  // ---------------------------------------------------------------------------
  // REST helper – tries proxy first, falls back to direct baseUrl candidates
  // ---------------------------------------------------------------------------

  Future<dynamic> _restFetch(String method, String path,
      {Map<String, dynamic>? body}) async {
    final bodyBytes = body != null ? jsonEncode(body) : null;

    String targetBase = baseUrl.trim();
    if (targetBase.isEmpty || targetBase == 'http://' || targetBase == 'https://') {
      targetBase = 'http://localhost:8067';
    }

    http.Response? response;

    // 1) Try CORS proxy (required for Flutter Web — bypasses browser CORS policy)
    //    The proxy server at localhost:8085 forwards requests to the configured Odoo URL.
    //    Run: node proxy/server.js <odoo-url>
    try {
      final proxyUrl = Uri.parse('http://localhost:8085/proxy$path');
      switch (method) {
        case 'GET':
          response = await http.get(proxyUrl, headers: _headers()).timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          response = await http.post(proxyUrl, headers: _headers(), body: bodyBytes).timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await http.put(proxyUrl, headers: _headers(), body: bodyBytes).timeout(const Duration(seconds: 15));
          break;
      }
      // Accept any HTTP response from the proxy (including 4xx errors from Odoo — those are valid)
      if (response != null && response.statusCode >= 200 && response.statusCode < 600) {
        return _parseResponse(response);
      }
    } catch (_) {
      response = null; // Proxy not running → fall through to direct connection
    }

    // 2) Direct connection: works on Android/iOS and when Odoo has CORS enabled
    final candidates = [
      targetBase,
      if (targetBase != 'http://localhost:8067') 'http://localhost:8067',
      if (targetBase != 'http://localhost:8068') 'http://localhost:8068',
    ].toSet().toList();

    for (final base in candidates) {
      try {
        final directUrl = Uri.parse('$base$path');
        switch (method) {
          case 'GET':
            response = await http.get(directUrl, headers: _headers());
            break;
          case 'POST':
            response = await http.post(directUrl, headers: _headers(), body: bodyBytes);
            break;
          case 'PUT':
            response = await http.put(directUrl, headers: _headers(), body: bodyBytes);
            break;
        }
        if (response != null &&
            (response.statusCode >= 200 && response.statusCode < 600)) {
          if (base != targetBase) baseUrl = base;
          break;
        }
      } catch (_) {
        response = null;
      }
    }

    if (response == null) {
      throw Exception(
          'Cannot connect to Odoo server at ($targetBase).\n'
          'On Flutter Web, start the CORS proxy:\n'
          '  node proxy/server.js $targetBase\n'
          'Then refresh the browser.');
    }

    return _parseResponse(response);
  }

  dynamic _parseResponse(http.Response response) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final errJson = jsonDecode(response.body);
        final errMsg = errJson['error'] ?? 'Server error ${response.statusCode}';
        throw Exception(errMsg);
      } catch (parseErr) {
        if (parseErr is Exception) rethrow;
        throw Exception('Server error ${response.statusCode}');
      }
    }
    final json = jsonDecode(response.body);
    if (json is Map && json['success'] == false) {
      throw Exception(json['error'] ?? 'API request failed');
    }
    return json['data'] ?? json;
  }

  // ---------------------------------------------------------------------------
  // Auth API
  // ---------------------------------------------------------------------------

  Future<UserModel> login(String login, String password, String database) async {
    if (isDemoMode) {
      await saveSession('demo_session_123', 2);
      return UserModel(
        id: 2,
        name: login.contains('@') ? login.split('@')[0] : login,
        login: login,
        email: login,
        isSupportStaff: true,
        isManager: false,
        employeeName: 'Demo Employee',
      );
    }

    final targetDb = database.isNotEmpty ? database : db;
    final payload = <String, dynamic>{
      'login': login,
      'password': password,
    };
    if (targetDb.isNotEmpty) {
      payload['db'] = targetDb;
    }

    await saveConfig(baseUrl, targetDb, demo: false);
    final data = await _restFetch('POST', '/api/v1/auth/login', body: payload);

    final sid = data['session_id'] ?? '';
    final userId = (data['uid'] ?? 0) as int;
    final resolvedDb = (data['db']?.toString() ?? targetDb).trim();
    if (sid.isEmpty) throw Exception('Login succeeded but no token returned.');

    // Save the dynamically resolved DB name into local configuration
    await saveConfig(baseUrl, resolvedDb, demo: false);
    await saveSession(sid, userId);

    return UserModel.fromJson(data['user'] ?? {});
  }

  Future<void> logout() async {
    if (!isDemoMode && sessionId.isNotEmpty) {
      try {
        await _restFetch('POST', '/api/v1/auth/logout');
      } catch (_) {}
    }
    await clearSession();
  }

  Future<String> resetPassword(String login, {String? newPassword, String? database}) async {
    if (isDemoMode) {
      return 'Demo mode: Password reset link sent to $login.';
    }
    final targetDb = (database != null && database.isNotEmpty) ? database : db;
    final payload = <String, dynamic>{
      'login': login,
    };
    if (newPassword != null && newPassword.isNotEmpty) {
      payload['new_password'] = newPassword;
    }
    if (targetDb.isNotEmpty) payload['db'] = targetDb;
    final data = await _restFetch('POST', '/api/v1/auth/reset-password', body: payload);
    if (data is Map && data.containsKey('message')) {
      return data['message'].toString();
    }
    return 'Password reset link sent successfully.';
  }

  Future<Map<String, dynamic>> syncApiCredentials() async {
    if (isDemoMode) {
      return {'name': 'Demo Key', 'api_key': 'demo_secret_key_123', 'allow_anonymous_login': true};
    }
    final data = await _restFetch('GET', '/api/v1/auth/credentials');
    if (data is Map) {
      final key = data['api_key']?.toString() ?? '';
      if (key.isNotEmpty) {
        apiKey = key;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('odoo_api_key', apiKey);
      }
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  /// Returns null if the token is invalid/expired (caller should redirect to login).
  Future<UserModel?> getProfile() async {
    if (isDemoMode) {
      return UserModel(
        id: 2,
        name: 'Alex Rivera',
        login: 'alex.rivera@zunax.com',
        email: 'alex.rivera@zunax.com',
        isSupportStaff: true,
        isManager: true,
        employeeId: 10,
        employeeName: 'Alex Rivera',
        workEmail: 'alex.rivera@zunax.com',
        mobilePhone: '+1 (555) 234-5678',
      );
    }
    // Let exceptions propagate — AuthProvider catches them to clear stale tokens
    final data = await _restFetch('GET', '/api/v1/auth/me');
    return UserModel.fromJson(data);
  }

  // ---------------------------------------------------------------------------
  // Master Data API
  // ---------------------------------------------------------------------------

  Future<List<DepartmentModel>> getDepartments() async {
    if (isDemoMode) {
      return [
        DepartmentModel(id: 1, name: 'IT Hardware & Support'),
        DepartmentModel(id: 2, name: 'Software & Cloud Services'),
        DepartmentModel(id: 3, name: 'Network & Connectivity'),
        DepartmentModel(id: 4, name: 'ERP & Odoo Administration'),
      ];
    }
    final data = await _restFetch('GET', '/api/v1/departments');
    if (data is List) return data.map((d) => DepartmentModel.fromJson(d)).toList();
    return [];
  }

  Future<DepartmentModel> createDepartment(String name, {String emailAlias = ''}) async {
    if (isDemoMode) {
      return DepartmentModel(id: 10 + DateTime.now().second, name: name, emailAlias: emailAlias);
    }
    final data = await _restFetch('POST', '/api/v1/departments', body: {
      'name': name,
      'email_alias': emailAlias,
    });
    return DepartmentModel.fromJson(data);
  }

  Future<DepartmentModel> updateDepartment(int deptId, String name, {String emailAlias = ''}) async {
    if (isDemoMode) {
      return DepartmentModel(id: deptId, name: name, emailAlias: emailAlias);
    }
    final data = await _restFetch('PUT', '/api/v1/departments/$deptId', body: {
      'name': name,
      'email_alias': emailAlias,
    });
    return DepartmentModel.fromJson(data);
  }

  Future<List<SubjectModel>> getSubjects({int? departmentId}) async {
    if (isDemoMode) {
      return [
        SubjectModel(id: 1, name: 'Hardware Repair / Laptop Issue', departmentId: 1, departmentName: 'IT Hardware & Support'),
        SubjectModel(id: 2, name: 'Password Reset / Account Unlock', departmentId: 2, departmentName: 'Software & Cloud Services'),
        SubjectModel(id: 3, name: 'WiFi / Network Connection Drop', departmentId: 3, departmentName: 'Network & Connectivity'),
        SubjectModel(id: 4, name: 'Odoo Permission / Module Access', departmentId: 4, departmentName: 'ERP & Odoo Administration'),
      ];
    }
    String path = '/api/v1/subjects';
    if (departmentId != null) path += '?department_id=$departmentId';
    final data = await _restFetch('GET', path);
    if (data is List) return data.map((s) => SubjectModel.fromJson(s)).toList();
    return [];
  }

  // ---------------------------------------------------------------------------
  // Tickets API
  // ---------------------------------------------------------------------------

  Future<List<TicketModel>> getTickets({String stage = 'all', String query = ''}) async {
    if (isDemoMode) return _getDemoTickets(stage, query);

    String path = '/api/v1/tickets?limit=100';
    if (stage != 'all') path += '&stage=$stage';

    final data = await _restFetch('GET', path);
    List rawTickets = [];
    if (data is Map && data['tickets'] is List) {
      rawTickets = data['tickets'];
    } else if (data is List) {
      rawTickets = data;
    }

    var tickets = rawTickets.map((t) => TicketModel.fromJson(t)).toList();
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      tickets = tickets
          .where((t) =>
              t.name.toLowerCase().contains(q) ||
              t.ticketNumber.toLowerCase().contains(q))
          .toList();
    }
    return tickets;
  }

  Future<TicketModel> createTicket({
    required String name,
    required int departmentId,
    int? subjectId,
    String priority = '1',
    String description = '',
    String email = '',
    String phone = '',
  }) async {
    if (isDemoMode) return _createDemoTicket(name, departmentId, description, priority);

    final body = {
      'name': name,
      'department_id': departmentId,
      'priority': priority,
      'description': description,
      'email': email,
      'phone': phone,
      'stage': 'new',
    };
    if (subjectId != null) body['subject_id'] = subjectId;

    final data = await _restFetch('POST', '/api/v1/tickets', body: body);
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> submitTicket(int ticketId) async {
    if (isDemoMode) return (await _getDemoTickets('all', '')).first;
    final data = await _restFetch('POST', '/api/v1/tickets/$ticketId/submit');
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> startProgress(int ticketId) async {
    if (isDemoMode) return (await _getDemoTickets('all', '')).first;
    final data = await _restFetch('POST', '/api/v1/tickets/$ticketId/start-progress');
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> resolveTicket(int ticketId, String notes) async {
    if (isDemoMode) return (await _getDemoTickets('all', '')).first;
    final data = await _restFetch('POST', '/api/v1/tickets/$ticketId/resolve', body: {
      'resolution_notes': notes,
    });
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> cancelTicket(int ticketId, String reason) async {
    if (isDemoMode) return (await _getDemoTickets('all', '')).first;
    final data = await _restFetch('POST', '/api/v1/tickets/$ticketId/cancel', body: {
      'reason': reason,
    });
    return TicketModel.fromJson(data);
  }

  // ---------------------------------------------------------------------------
  // Chatter – uses JSON-RPC directly to Odoo (no REST wrapper)
  // ---------------------------------------------------------------------------

  Future<List<ChatterMessage>> getChatter(int ticketId) async {
    if (isDemoMode) {
      return [
        ChatterMessage(id: 1, authorName: 'System Auto-Router', body: '<p>Ticket created and auto-assigned to IT Hardware team.</p>', date: '2026-07-30 10:15:00'),
        ChatterMessage(id: 2, authorName: 'IT Support Engineer', body: '<p>Hello, we received your ticket and are investigating the issue.</p>', date: '2026-07-30 10:45:00'),
      ];
    }

    final rpcBody = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': 'mail.message',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'domain': [
            ['res_id', '=', ticketId],
            ['model', '=', 'it.ticket']
          ],
          'fields': ['id', 'author_id', 'body', 'date'],
          'limit': 30,
          'order': 'id asc',
        }
      },
      'id': 1
    };

    final url = Uri.parse('$baseUrl/web/dataset/call_kw');
    final response = await http.post(url, headers: _headers(), body: jsonEncode(rpcBody));
    final json = jsonDecode(response.body);
    if (json['result'] is List) {
      return (json['result'] as List).map((m) => ChatterMessage.fromJson(m)).toList();
    }
    return [];
  }

  Future<bool> postComment(int ticketId, String bodyText) async {
    if (isDemoMode) return true;

    final rpcBody = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': 'it.ticket',
        'method': 'message_post',
        'args': [[ticketId]],
        'kwargs': {
          'body': bodyText,
          'message_type': 'comment',
          'subtype_xmlid': 'mail.mt_comment',
        }
      },
      'id': 1
    };

    final url = Uri.parse('$baseUrl/web/dataset/call_kw');
    final response = await http.post(url, headers: _headers(), body: jsonEncode(rpcBody));
    return response.statusCode == 200;
  }

  // ---------------------------------------------------------------------------
  // Demo data
  // ---------------------------------------------------------------------------

  List<TicketModel>? _demoTickets;

  Future<List<TicketModel>> _getDemoTickets(String stage, String query) async {
    _demoTickets ??= [
      TicketModel(id: 101, ticketNumber: 'IT00084', name: 'Docking station display flickers on dual monitors', stage: 'in_progress', priority: '2', description: 'Whenever I plug in my dual 4K monitors through USB-C dock, display turns off.', createDate: '2026-07-30 09:30:12', departmentId: 1, departmentName: 'IT Hardware & Support', employeeId: 10, employeeName: 'Alex Rivera', assignedUserId: 3, assignedUserName: 'Sarah Connor'),
      TicketModel(id: 102, ticketNumber: 'IT00082', name: 'Odoo 18 Sales module access permission required', stage: 'resolved', priority: '1', description: 'Need read access to Sales and Quotations for quarterly reporting.', resolutionNotes: 'Granted Sales User / Manager security group.', createDate: '2026-07-28 14:20:00', dateResolved: '2026-07-28 16:45:00', departmentId: 4, departmentName: 'ERP & Odoo Administration', employeeId: 10, employeeName: 'Alex Rivera', assignedUserId: 2, assignedUserName: 'Odoo Admin'),
      TicketModel(id: 103, ticketNumber: 'IT00079', name: 'VPN credentials expired during remote travel', stage: 'new', priority: '3', description: 'Unable to connect to company Cisco AnyConnect VPN.', createDate: '2026-07-30 11:05:00', departmentId: 3, departmentName: 'Network & Connectivity', employeeId: 10, employeeName: 'Alex Rivera'),
    ];
    var list = [..._demoTickets!];
    if (stage != 'all') list = list.where((t) => t.stage == stage).toList();
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((t) => t.name.toLowerCase().contains(q) || t.ticketNumber.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<TicketModel> _createDemoTicket(String name, int deptId, String desc, String priority) async {
    final newId = 100 + (_demoTickets?.length ?? 0) + 1;
    final t = TicketModel(id: newId, ticketNumber: 'IT000$newId', name: name, stage: 'new', priority: priority, description: desc, departmentId: deptId, departmentName: 'IT Department', employeeId: 10, employeeName: 'Alex Rivera', createDate: DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' '));
    _demoTickets?.insert(0, t);
    return t;
  }
}
