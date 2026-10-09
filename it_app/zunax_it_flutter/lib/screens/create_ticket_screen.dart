import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ticket_provider.dart';
import '../providers/auth_provider.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({Key? key}) : super(key: key);

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  int? _selectedDeptId;
  int? _selectedSubjectId;
  String _selectedPriority = '1';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _emailController.text = user.workEmail ?? user.email;
      _phoneController.text = user.mobilePhone ?? '';
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an IT Department')),
      );
      return;
    }

    final ticketProvider = context.read<TicketProvider>();
    final subjects = ticketProvider.subjects;
    String ticketTitle = '';
    if (_selectedSubjectId != null) {
      final match = subjects.firstWhere((s) => s.id == _selectedSubjectId, orElse: () => subjects.first);
      ticketTitle = match.name;
    } else if (_descController.text.trim().isNotEmpty) {
      ticketTitle = _descController.text.trim().split('\n').first;
      if (ticketTitle.length > 60) ticketTitle = '${ticketTitle.substring(0, 57)}...';
    } else {
      ticketTitle = 'IT Support Ticket';
    }

    final success = await ticketProvider.createTicket(
      name: ticketTitle,
      departmentId: _selectedDeptId!,
      subjectId: _selectedSubjectId,
      priority: _selectedPriority,
      description: _descController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ticketProvider.errorMessage ?? 'Failed to submit ticket'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final departments = ticketProvider.departments;
    final subjects = ticketProvider.subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raise IT Support Ticket'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket Subject Dropdown
              DropdownButtonFormField<int>(
                value: _selectedSubjectId,
                decoration: const InputDecoration(
                  labelText: 'Ticket Subject',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: subjects.map((s) {
                  return DropdownMenuItem<int>(
                    value: s.id,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSubjectId = val;
                    if (val != null) {
                      final match = subjects.firstWhere((element) => element.id == val);
                      if (match.departmentId != null) {
                        _selectedDeptId = match.departmentId;
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Department Dropdown
              DropdownButtonFormField<int>(
                value: _selectedDeptId,
                decoration: const InputDecoration(
                  labelText: 'IT Department *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: departments.map((d) {
                  return DropdownMenuItem<int>(
                    value: d.id,
                    child: Text(d.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedDeptId = val),
              ),
              const SizedBox(height: 16),

              // Priority Dropdown
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority Level',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: '0', child: Text('Low')),
                  DropdownMenuItem(value: '1', child: Text('Medium')),
                  DropdownMenuItem(value: '2', child: Text('High')),
                  DropdownMenuItem(value: '3', child: Text('Urgent')),
                ],
                onChanged: (val) => setState(() => _selectedPriority = val ?? '1'),
              ),
              const SizedBox(height: 16),

              // Description Multi-line
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Issue Description & Steps to Reproduce',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Contact Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),

              // Contact Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone / Mobile',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: ticketProvider.isActionLoading ? null : _submit,
                  icon: ticketProvider.isActionLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  label: const Text('Submit Ticket to Odoo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
