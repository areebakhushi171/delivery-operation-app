import 'package:flutter/material.dart';

import '../data/models/enums.dart';

class AppIcons {
  AppIcons._();

  static IconData forReason(ExceptionReason r) {
    switch (r) {
      case ExceptionReason.customerNotAvailable:
        return Icons.person_off_outlined;
      case ExceptionReason.wrongAddress:
        return Icons.wrong_location_outlined;
      case ExceptionReason.refusedDelivery:
        return Icons.block_outlined;
      case ExceptionReason.damagedPackage:
        return Icons.broken_image_outlined;
      case ExceptionReason.weatherTraffic:
        return Icons.traffic_outlined;
      case ExceptionReason.other:
        return Icons.help_outline;
    }
  }

  static IconData forNotification(NotificationType t) {
    switch (t) {
      case NotificationType.assignment:
        return Icons.assignment_turned_in_outlined;
      case NotificationType.routeChange:
        return Icons.alt_route;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.exceptionUpdate:
        return Icons.report_problem_outlined;
      case NotificationType.announcement:
        return Icons.campaign_outlined;
    }
  }
}
