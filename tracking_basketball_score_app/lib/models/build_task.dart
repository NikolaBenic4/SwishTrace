import 'package:flutter/material.dart';

class BuildTask {
  const BuildTask({
    required this.title,
    required this.status,
    required this.area,
    required this.priority,
    required this.note,
    required this.icon,
  });

  final String title;
  final String status;
  final String area;
  final String priority;
  final String note;
  final IconData icon;
}
