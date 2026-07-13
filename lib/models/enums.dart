enum ItemCategory { appliance, vehicle, house, warrantyDocument, other }

enum ItemStatus { active, paused, archived }

enum MaintenanceType {
  cleaning,
  inspection,
  replacement,
  repairRecord,
  expiryReminder,
  constructionRecord,
}

enum RiskLevel { low, medium, high, unknown }

enum CycleType { daily, weekly, monthly, quarterly, semiAnnual, yearly, custom }

enum ScheduleStatus { active, paused, ended }

enum TaskStatus { pending, completed, overdue, postponed, canceled }

enum RecordType {
  regularMaintenance,
  failure,
  repair,
  partsReplacement,
  expiryHandled,
  construction,
  other,
}
