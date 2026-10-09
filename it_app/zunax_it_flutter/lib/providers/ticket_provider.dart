import 'package:flutter/foundation.dart';
import '../models/ticket_model.dart';
import '../models/department_model.dart';
import '../models/subject_model.dart';
import '../services/api_service.dart';

class TicketProvider with ChangeNotifier {
  final ApiService apiService;

  List<TicketModel> _tickets = [];
  List<DepartmentModel> _departments = [];
  List<SubjectModel> _subjects = [];
  ChatterMessage? _lastMessage;
  List<ChatterMessage> _chatterMessages = [];

  bool _isLoading = false;
  bool _isActionLoading = false;
  String _currentStageFilter = 'all';
  String _searchQuery = '';
  String? _errorMessage;

  TicketProvider(this.apiService);

  List<TicketModel> get tickets => _tickets;
  List<DepartmentModel> get departments => _departments;
  List<SubjectModel> get subjects => _subjects;
  List<ChatterMessage> get chatterMessages => _chatterMessages;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String get currentStageFilter => _currentStageFilter;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  int get totalCount => _tickets.length;
  int get newCount => _tickets.where((t) => t.stage == 'new' || t.stage == 'draft').length;
  int get inProgressCount => _tickets.where((t) => t.stage == 'in_progress').length;
  int get resolvedCount => _tickets.where((t) => t.stage == 'resolved').length;

  Future<void> fetchMetadata() async {
    try {
      _departments = await apiService.getDepartments();
      _subjects = await apiService.getSubjects();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createDepartment(String name, {String emailAlias = ''}) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await apiService.createDepartment(name, emailAlias: emailAlias);
      await fetchMetadata();
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDepartment(int id, String name, {String emailAlias = ''}) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await apiService.updateDepartment(id, name, emailAlias: emailAlias);
      await fetchMetadata();
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchTickets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tickets = await apiService.getTickets(stage: _currentStageFilter, query: _searchQuery);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('fetchTickets error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilterStage(String stage) {
    _currentStageFilter = stage;
    fetchTickets();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchTickets();
  }

  Future<bool> createTicket({
    required String name,
    required int departmentId,
    int? subjectId,
    String priority = '1',
    String description = '',
    String email = '',
    String phone = '',
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      await apiService.createTicket(
        name: name,
        departmentId: departmentId,
        subjectId: subjectId,
        priority: priority,
        description: description,
        email: email,
        phone: phone,
      );
      await fetchTickets();
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitTicket(int id) async {
    return _performAction(() => apiService.submitTicket(id));
  }

  Future<bool> startProgress(int id) async {
    return _performAction(() => apiService.startProgress(id));
  }

  Future<bool> resolveTicket(int id, String notes) async {
    return _performAction(() => apiService.resolveTicket(id, notes));
  }

  Future<bool> cancelTicket(int id, String reason) async {
    return _performAction(() => apiService.cancelTicket(id, reason));
  }

  Future<bool> _performAction(Future<dynamic> Function() action) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      await action();
      await fetchTickets();
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchChatter(int ticketId) async {
    try {
      _chatterMessages = await apiService.getChatter(ticketId);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> postComment(int ticketId, String comment) async {
    try {
      final success = await apiService.postComment(ticketId, comment);
      if (success) {
        await fetchChatter(ticketId);
      }
      return success;
    } catch (_) {
      return false;
    }
  }
}
