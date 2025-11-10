import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class CommonHelper {
  // ===================== Movie Status =====================
  static const List<String> movieStatuses = [
    "Idea Stage",
    "Pre-Production",
    "Funding Open",
    "Funding Closed",
    "Production",
    "Post-Production",
    "Trailer Released",
    "Coming Soon",
    "Released",
    "Box Office Running",
    "Profit Distribution",
    "Archived",
    "On Hold",
    "Cancelled",
  ];

  static Color getMovieStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'idea stage':
        return Colors.grey;
      case 'pre-production':
        return Colors.blueGrey;
      case 'funding open':
        return Colors.green;
      case 'funding closed':
        return Colors.redAccent;
      case 'production':
        return Colors.orange;
      case 'post-production':
        return Colors.teal;
      case 'trailer released':
        return Colors.purple;
      case 'coming soon':
        return Colors.lightBlue;
      case 'released':
        return Colors.greenAccent.shade700;
      case 'box office running':
        return Colors.deepOrange;
      case 'profit distribution':
        return Colors.indigo;
      case 'archived':
        return Colors.black45;
      case 'on hold':
        return Colors.yellow.shade800;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static Widget movieStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getMovieStatusColor(status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static String formatAmount(num amount) {
    if (amount >= 10000000) {
      // Crores
      double value = amount / 10000000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} Cr';
    } else if (amount >= 100000) {
      // Lakhs
      double value = amount / 100000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} L';
    } else if (amount >= 1000) {
      // Thousands
      double value = amount / 1000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} K';
    } else {
      // Normal number with commas
      final formatter = NumberFormat('#,##0');
      return formatter.format(amount);
    }
  }

  // ===================== Add other common helper methods here =====================
  // Example: format currency, build custom buttons, etc.
}
