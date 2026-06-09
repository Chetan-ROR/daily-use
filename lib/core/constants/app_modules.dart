import 'package:flutter/material.dart';

class AppModule {
  const AppModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.supportsAmount = false,
    this.supportsProgress = false,
    this.supportsDueDate = true,
    this.supportsReminder = true,
    this.supportsAttachments = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool supportsAmount;
  final bool supportsProgress;
  final bool supportsDueDate;
  final bool supportsReminder;
  final bool supportsAttachments;
}

class AppModules {
  static const profile = AppModule(
    id: 'profile',
    title: 'Profile',
    subtitle: 'Personal and emergency information',
    icon: Icons.person_outline,
    accent: Color(0xff6366f1),
    supportsDueDate: false,
    supportsReminder: false,
  );
  static const notes = AppModule(
    id: 'notes',
    title: 'Daily Notes',
    subtitle: 'Notes, tags, archive and attachments',
    icon: Icons.sticky_note_2_outlined,
    accent: Color(0xfff59e0b),
  );
  static const tasks = AppModule(
    id: 'tasks',
    title: 'Tasks',
    subtitle: 'Priority task management and history',
    icon: Icons.task_alt_outlined,
    accent: Color(0xff10b981),
  );
  static const reminders = AppModule(
    id: 'reminders',
    title: 'Reminders',
    subtitle: 'Smart local alerts and snooze-ready entries',
    icon: Icons.notifications_active_outlined,
    accent: Color(0xffef4444),
  );
  static const calendar = AppModule(
    id: 'calendar',
    title: 'Calendar',
    subtitle: 'Day, week and month planning context',
    icon: Icons.calendar_month_outlined,
    accent: Color(0xff3b82f6),
  );
  static const wedding = AppModule(
    id: 'wedding',
    title: 'Wedding Planner',
    subtitle: 'Guests, vendors, budget and countdown',
    icon: Icons.favorite_border,
    accent: Color(0xffec4899),
    supportsAmount: true,
    supportsProgress: true,
  );
  static const expenses = AppModule(
    id: 'expenses',
    title: 'Daily Expenses',
    subtitle: 'Quick daily spend, totals and graphs',
    icon: Icons.account_balance_wallet_outlined,
    accent: Color(0xff14b8a6),
    supportsAmount: true,
  );
  static const health = AppModule(
    id: 'health',
    title: 'Health',
    subtitle: 'Steps, water, weight and wellness trends',
    icon: Icons.health_and_safety_outlined,
    accent: Color(0xff22c55e),
    supportsAmount: true,
    supportsProgress: true,
  );
  static const habits = AppModule(
    id: 'habits',
    title: 'Habits',
    subtitle: 'Streaks, daily completions and success rate',
    icon: Icons.repeat_on_outlined,
    accent: Color(0xff8b5cf6),
    supportsProgress: true,
  );
  static const goals = AppModule(
    id: 'goals',
    title: 'Goals',
    subtitle: 'Personal, finance, fitness and career goals',
    icon: Icons.flag_outlined,
    accent: Color(0xff06b6d4),
    supportsAmount: true,
    supportsProgress: true,
  );
  static const contacts = AppModule(
    id: 'contacts',
    title: 'Contacts',
    subtitle: 'Family, friends, vendors and emergency contacts',
    icon: Icons.contacts_outlined,
    accent: Color(0xff64748b),
  );
  static const documents = AppModule(
    id: 'documents',
    title: 'Document Vault',
    subtitle: 'Documents, expiry reminders and attachments',
    icon: Icons.folder_copy_outlined,
    accent: Color(0xff0ea5e9),
    supportsAttachments: true,
  );
  static const reports = AppModule(
    id: 'reports',
    title: 'Reports',
    subtitle: 'PDF and XLSX exports',
    icon: Icons.analytics_outlined,
    accent: Color(0xff7c3aed),
    supportsDueDate: false,
  );
  static const history = AppModule(
    id: 'history',
    title: 'History',
    subtitle: 'Completed and archived activity',
    icon: Icons.history_outlined,
    accent: Color(0xff475569),
    supportsDueDate: false,
  );
  static const settings = AppModule(
    id: 'settings',
    title: 'Settings',
    subtitle: 'Theme, security, backup and notifications',
    icon: Icons.settings_outlined,
    accent: Color(0xff334155),
    supportsDueDate: false,
  );
  static const notifications = AppModule(
    id: 'notifications',
    title: 'Notification Center',
    subtitle: 'Reminder history, alerts and actions',
    icon: Icons.mark_email_unread_outlined,
    accent: Color(0xfff97316),
  );

  static const modules = <AppModule>[
    profile,
    notes,
    tasks,
    reminders,
    calendar,
    wedding,
    expenses,
    health,
    habits,
    goals,
    contacts,
    documents,
    reports,
    history,
    settings,
    notifications,
  ];

  static const quickActions = <AppModule>[
    notes,
    tasks,
    reminders,
    expenses,
    wedding,
    documents,
  ];
  static const primaryNavigation = <AppModule>[
    notes,
    tasks,
    calendar,
    expenses,
    wedding,
  ];

  static AppModule byId(String id) =>
      modules.firstWhere((module) => module.id == id, orElse: () => notes);
}
