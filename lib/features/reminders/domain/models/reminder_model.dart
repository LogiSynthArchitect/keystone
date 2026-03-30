enum ReminderType {
  unpaidJob,
  stuckInProgress,
  followUpPending,
  followUpNoResponse,
}

extension ReminderTypeLabel on ReminderType {
  String get label {
    switch (this) {
      case ReminderType.unpaidJob:       return 'UNPAID JOB';
      case ReminderType.stuckInProgress: return 'JOB IN PROGRESS';
      case ReminderType.followUpPending: return 'FOLLOW-UP NEEDED';
      case ReminderType.followUpNoResponse: return 'AWAITING RESPONSE';
    }
  }

  String get description {
    switch (this) {
      case ReminderType.unpaidJob:       return 'Payment not yet collected';
      case ReminderType.stuckInProgress: return 'Job still in progress';
      case ReminderType.followUpPending: return 'Follow-up not sent yet';
      case ReminderType.followUpNoResponse: return 'Awaiting customer response';
    }
  }
}

class Reminder {
  final String jobId;
  final String jobServiceType;
  final DateTime jobDate;
  final ReminderType type;
  final int? amountCharged;  // pesewas
  final bool isDismissed;

  const Reminder({
    required this.jobId,
    required this.jobServiceType,
    required this.jobDate,
    required this.type,
    this.amountCharged,
    this.isDismissed = false,
  });

  Reminder copyWith({bool? isDismissed}) => Reminder(
    jobId: jobId,
    jobServiceType: jobServiceType,
    jobDate: jobDate,
    type: type,
    amountCharged: amountCharged,
    isDismissed: isDismissed ?? this.isDismissed,
  );
}
