import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import '../widgets/stage_badge.dart';
import '../widgets/priority_badge.dart';
import '../widgets/chatter_view.dart';

class TicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;

  const TicketDetailScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late TicketModel _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
  }

  void _showResolveDialog() {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Explain how the issue was resolved for the user:'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter resolution details...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final text = notesController.text.trim();
              if (text.isEmpty) return;
              Navigator.of(ctx).pop();
              final success = await context.read<TicketProvider>().resolveTicket(_ticket.id, text);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket resolved successfully!'), backgroundColor: Colors.green),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Resolve Ticket'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Reason for cancellation:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter cancellation reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final text = reasonController.text.trim();
              if (text.isEmpty) return;
              Navigator.of(ctx).pop();
              final success = await context.read<TicketProvider>().cancelTicket(_ticket.id, text);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket cancelled')),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Cancel Ticket', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String label, bool isCompleted, bool isActive) {
    Color circleColor = Colors.grey.shade300;
    Color textColor = Colors.grey;
    if (isCompleted) {
      circleColor = const Color(0xFF16A34A);
      textColor = Colors.black87;
    } else if (isActive) {
      circleColor = const Color(0xFF4F46E5);
      textColor = const Color(0xFF4F46E5);
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: circleColor,
          child: isCompleted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text(
                  isActive ? '•' : '',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: textColor),
        ),
      ],
    );
  }

  String _cleanHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final stages = ['draft', 'new', 'in_progress', 'resolved'];
    final currentIndex = stages.indexOf(_ticket.stage);

    return Scaffold(
      appBar: AppBar(
        title: Text(_ticket.ticketNumber),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StageBadge(stage: _ticket.stage),
                        PriorityBadge(priority: _ticket.priority),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _ticket.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const Divider(height: 24),

                    // Meta Details Grid
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Department', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(_ticket.departmentName ?? 'General IT', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Assigned To', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(_ticket.assignedUserName ?? 'Unassigned', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Created Date', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(_ticket.createDate ?? '--', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (_ticket.dateResolved != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Resolved Date', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(_ticket.dateResolved!, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stepper Visual Progress
            if (_ticket.stage != 'cancelled')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStep('Draft', currentIndex > 0, currentIndex == 0),
                    _buildStep('New', currentIndex > 1, currentIndex == 1),
                    _buildStep('In Progress', currentIndex > 2, currentIndex == 2),
                    _buildStep('Resolved', currentIndex >= 3, currentIndex == 3),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Description Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Issue Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  Text(_cleanHtml(_ticket.description.isEmpty ? 'No description provided.' : _ticket.description), style: const TextStyle(fontSize: 14, height: 1.4)),
                ],
              ),
            ),

            // Resolution Notes Card
            if (_ticket.resolutionNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 18),
                        SizedBox(width: 6),
                        Text('Resolution Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_cleanHtml(_ticket.resolutionNotes), style: const TextStyle(fontSize: 13, color: Color(0xFF166534))),
                  ],
                ),
              ),
            ],

            // Cancellation Reason Card
            if (_ticket.cancellationReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 6),
                        Text('Cancellation Reason', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_ticket.cancellationReason, style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons Bar
            if (_ticket.stage != 'resolved' && _ticket.stage != 'cancelled') ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_ticket.stage == 'draft')
                    ElevatedButton.icon(
                      onPressed: () async {
                        final success = await context.read<TicketProvider>().submitTicket(_ticket.id);
                        if (success && mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Submit Ticket'),
                    ),
                  if (_ticket.stage == 'new')
                    ElevatedButton.icon(
                      onPressed: () async {
                        final success = await context.read<TicketProvider>().startProgress(_ticket.id);
                        if (success && mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Progress'),
                    ),
                  if (_ticket.stage == 'in_progress')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: _showResolveDialog,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Resolve Issue', style: TextStyle(color: Colors.white)),
                    ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: _showCancelDialog,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Ticket'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Chatter Section
            ChatterView(ticketId: _ticket.id),
          ],
        ),
      ),
    );
  }
}
