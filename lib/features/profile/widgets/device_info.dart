import 'package:flutter/material.dart';

class DeviceInfo {
  final String name;
  final String location;
  final String os;
  final String? lastActive;
  final IconData icon;
  final bool isCurrentDevice;

  DeviceInfo({
    required this.name,
    required this.location,
    required this.os,
    required this.icon,
    this.lastActive,
    this.isCurrentDevice = false,
  });
}