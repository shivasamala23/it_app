import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import 'stage_badge.dart';
import 'priority_badge.dart';

class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;

  const TicketCard({
    Key? key,
    required this.ticket,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ticket.ticketNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                      fontSize: 13,
                    ),
                  ),
                  StageBadge(stage: ticket.stage),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.business_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.departmentName ?? 'General IT',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PriorityBadge(priority: ticket.priority),
                  const SizedBox(width: 8),
                  if (ticket.createDate != null) ...[
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 2),
                    Text(
                      ticket.createDate!.length > 10
                          ? ticket.createDate!.substring(5, 10)
                          : ticket.createDate!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
