import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../models/department_model.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  late TextEditingController _dbController;
  late TextEditingController _apiKeyController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _urlController = TextEditingController(text: auth.apiService.baseUrl);
    _dbController = TextEditingController(text: auth.apiService.db);
    _apiKeyController = TextEditingController(text: auth.apiService.apiKey);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _dbController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _showDepartmentDialog(BuildContext context, {DepartmentModel? department}) {
    final nameController = TextEditingController(text: department?.name ?? '');
    final aliasController = TextEditingController(text: department?.emailAlias ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(department == null ? 'Add IT Department' : 'Edit Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Department Name *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aliasController,
              decoration: const InputDecoration(
                labelText: 'Email Alias (Optional)',
                hintText: 'e.g. hardware-support',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();

              final ticketProvider = context.read<TicketProvider>();
              bool success;
              if (department == null) {
                success = await ticketProvider.createDepartment(name, emailAlias: aliasController.text.trim());
              } else {
                success = await ticketProvider.updateDepartment(department.id, name, emailAlias: aliasController.text.trim());
              }

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(department == null ? 'Department added!' : 'Department updated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(department == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _saveConnectionSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    
    try {
      await auth.apiService.saveConfig(
        _urlController.text.trim(),
        _dbController.text.trim(),
        demo: auth.apiService.isDemoMode,
        key: _apiKeyController.text.trim(),
      );

      // Verify connection to check if Odoo sync activates successfully
      final response = await auth.apiService.syncApiCredentials();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved & verified! Active database: ${auth.apiService.db}'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh department and ticket list now that integration key is unlocked!
        context.read<TicketProvider>().fetchMetadata();
        context.read<TicketProvider>().fetchTickets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final ticketProvider = context.watch<TicketProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile & Server'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFF4F46E5),
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'User Profile',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Staff Role', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              user?.isManager == true
                                  ? 'Manager'
                                  : user?.isSupportStaff == true
                                      ? 'Support Staff'
                                      : 'Employee',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5)),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('UID', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('#${user?.id ?? '--'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Manage IT Departments Card (Only visible to Managers & Support Staff)
            if (user?.isManager == true || user?.isSupportStaff == true) ...[
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: const Icon(Icons.business_rounded, color: Color(0xFF4F46E5)),
                  title: const Text('Manage IT Departments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${ticketProvider.departments.length} active departments', style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF4F46E5)),
                    onPressed: () => _showDepartmentDialog(context),
                    tooltip: 'Add Department',
                  ),
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ticketProvider.departments.length,
                      itemBuilder: (context, index) {
                        final dept = ticketProvider.departments[index];
                        return ListTile(
                          dense: true,
                          title: Text(dept.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: dept.emailAlias.isNotEmpty ? Text('Alias: ${dept.emailAlias}') : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _showDepartmentDialog(context, department: dept),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Manage Connection & API Settings (Visible to Managers)
            if (user?.isManager == true) ...[
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: const Icon(Icons.dns_outlined, color: Color(0xFF4F46E5)),
                  title: const Text('Odoo Server Connection Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    auth.apiService.isDemoMode
                        ? 'Offline Test / Demo Mode'
                        : auth.apiService.baseUrl.isEmpty
                            ? 'Not Configured'
                            : 'Host: ${auth.apiService.baseUrl}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _urlController,
                              decoration: const InputDecoration(
                                labelText: 'Odoo Server URL *',
                                hintText: 'e.g. http://localhost:8067',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Server URL required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _dbController,
                              decoration: const InputDecoration(
                                labelText: 'Target Database Name *',
                                hintText: 'e.g. odoo_db',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Database name required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _apiKeyController,
                              decoration: const InputDecoration(
                                labelText: 'API Integration Key (Secret)',
                                hintText: 'Paste it_sec_... key from Odoo panel',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _isSaving ? null : _saveConnectionSettings,
                              child: _isSaving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Save & Verify Sync Connection', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
