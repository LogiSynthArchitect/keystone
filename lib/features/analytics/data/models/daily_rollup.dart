/// Pre-computed daily analytics rollup — a lightweight, schema-versioned
/// aggregate of every job, part, expense, and customer event for a single day.
///
/// Design:
/// - One record per calendar date, keyed by ISO date string ("2026-05-29")
/// - Stored as a raw Map in the `analytics_daily_rollups` Hive box
/// - Summing N rollups gives period-level metrics without touching job data
/// - Breakdown maps (service type, parts usage, etc.) are small per day (1-5 entries)
///   but merge across 30 days to produce the full period breakdown
/// - `dirty` flag + `sourceJobIds` enable targeted day-level recomputation
///   when a job from that date is edited/deleted
/// - `schemaVersion` enables one-time migration when new metrics are added
class DailyRollup {
  final String dateKey; // "2026-05-29"
  final int schemaVersion;
  final bool dirty;

  // ── Core financials ──
  final int revenue; // sum of amountCharged (non-deleted, non-archived jobs)
  final int partsCost; // sum of (qty * unitPrice) across all job parts
  final int expensesCost; // sum of expense amounts
  final int jobCount; // count of non-deleted, non-archived jobs
  final int completedJobCount; // status == 'completed' or 'invoiced'

  // ── Leaking revenue (jobs stuck in quoted/in_progress > 7 days from dateKey) ──
  final int uninvoicedValue; // amountCharged of jobs not yet invoiced

  // ── Payment health ──
  final int unpaidAmount;
  final int partialAmount;
  final int paidAmount;
  final int unpaidCount;
  final int partialCount;
  final int paidCount;

  // ── Customers ──
  final int newCustomerCount; // customers whose first-ever job is this date
  final Map<String, int> customerRevenue; // {customerId: revenue}

  // ── Service type breakdowns ──
  final Map<String, int> stRevenue; // {serviceType: revenue}
  final Map<String, int> stJobs; // {serviceType: jobCount}
  final Map<String, int> stPartsCost; // {serviceType: partsCost}

  // ── Parts usage ──
  final Map<String, int> partsUsage; // {partName: quantity}

  // ── Expense categories ──
  final Map<String, int> expenseCategories; // {category: amount}

  // ── Lead sources ──
  final Map<String, int> leadSourceRevenue; // {source: revenue}
  final Map<String, int> leadSourceJobs; // {source: jobCount}

  // ── Location (Tier 2) ──
  final Map<String, int> locationRevenue; // {location: revenue}
  final Map<String, int> locationJobs; // {location: jobCount}

  // ── Property type (Tier 2) ──
  final Map<String, int> propertyTypeRevenue; // {type: revenue}
  final Map<String, int> propertyTypeJobs; // {type: jobCount}

  // ── Payment method (Tier 2) ──
  final Map<String, int> paymentMethodRevenue; // {method: revenue}
  final Map<String, int> paymentMethodJobs; // {method: jobCount}

  // ── Job status (Tier 2) ──
  final Map<String, int> statusRevenue; // {status: revenue}
  final Map<String, int> statusJobs; // {status: jobCount}

  // ── Job origin (Tier 2) ──
  final int recurringRevenue; // from generatedFromScheduleId != null
  final int recurringJobs;
  final int oneOffRevenue; // from generatedFromScheduleId == null
  final int oneOffJobs;

  // ── Source job IDs (for invalidation tracing) ──
  final List<String> sourceJobIds;

  const DailyRollup({
    required this.dateKey,
    this.schemaVersion = 2,
    this.dirty = false,
    this.revenue = 0,
    this.partsCost = 0,
    this.expensesCost = 0,
    this.jobCount = 0,
    this.completedJobCount = 0,
    this.uninvoicedValue = 0,
    this.unpaidAmount = 0,
    this.partialAmount = 0,
    this.paidAmount = 0,
    this.unpaidCount = 0,
    this.partialCount = 0,
    this.paidCount = 0,
    this.newCustomerCount = 0,
    this.customerRevenue = const {},
    this.stRevenue = const {},
    this.stJobs = const {},
    this.stPartsCost = const {},
    this.partsUsage = const {},
    this.expenseCategories = const {},
    this.leadSourceRevenue = const {},
    this.leadSourceJobs = const {},
    this.locationRevenue = const {},
    this.locationJobs = const {},
    this.propertyTypeRevenue = const {},
    this.propertyTypeJobs = const {},
    this.paymentMethodRevenue = const {},
    this.paymentMethodJobs = const {},
    this.statusRevenue = const {},
    this.statusJobs = const {},
    this.recurringRevenue = 0,
    this.recurringJobs = 0,
    this.oneOffRevenue = 0,
    this.oneOffJobs = 0,
    this.sourceJobIds = const [],
  });

  DailyRollup copyWith({
    String? dateKey,
    int? schemaVersion,
    bool? dirty,
    int? revenue,
    int? partsCost,
    int? expensesCost,
    int? jobCount,
    int? completedJobCount,
    int? uninvoicedValue,
    int? unpaidAmount,
    int? partialAmount,
    int? paidAmount,
    int? unpaidCount,
    int? partialCount,
    int? paidCount,
    int? newCustomerCount,
    Map<String, int>? customerRevenue,
    Map<String, int>? stRevenue,
    Map<String, int>? stJobs,
    Map<String, int>? stPartsCost,
    Map<String, int>? partsUsage,
    Map<String, int>? expenseCategories,
    Map<String, int>? leadSourceRevenue,
    Map<String, int>? leadSourceJobs,
    Map<String, int>? locationRevenue,
    Map<String, int>? locationJobs,
    Map<String, int>? propertyTypeRevenue,
    Map<String, int>? propertyTypeJobs,
    Map<String, int>? paymentMethodRevenue,
    Map<String, int>? paymentMethodJobs,
    Map<String, int>? statusRevenue,
    Map<String, int>? statusJobs,
    int? recurringRevenue,
    int? recurringJobs,
    int? oneOffRevenue,
    int? oneOffJobs,
    List<String>? sourceJobIds,
  }) {
    return DailyRollup(
      dateKey: dateKey ?? this.dateKey,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      dirty: dirty ?? this.dirty,
      revenue: revenue ?? this.revenue,
      partsCost: partsCost ?? this.partsCost,
      expensesCost: expensesCost ?? this.expensesCost,
      jobCount: jobCount ?? this.jobCount,
      completedJobCount: completedJobCount ?? this.completedJobCount,
      uninvoicedValue: uninvoicedValue ?? this.uninvoicedValue,
      unpaidAmount: unpaidAmount ?? this.unpaidAmount,
      partialAmount: partialAmount ?? this.partialAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      unpaidCount: unpaidCount ?? this.unpaidCount,
      partialCount: partialCount ?? this.partialCount,
      paidCount: paidCount ?? this.paidCount,
      newCustomerCount: newCustomerCount ?? this.newCustomerCount,
      customerRevenue: customerRevenue ?? this.customerRevenue,
      stRevenue: stRevenue ?? this.stRevenue,
      stJobs: stJobs ?? this.stJobs,
      stPartsCost: stPartsCost ?? this.stPartsCost,
      partsUsage: partsUsage ?? this.partsUsage,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      leadSourceRevenue: leadSourceRevenue ?? this.leadSourceRevenue,
      leadSourceJobs: leadSourceJobs ?? this.leadSourceJobs,
      locationRevenue: locationRevenue ?? this.locationRevenue,
      locationJobs: locationJobs ?? this.locationJobs,
      propertyTypeRevenue: propertyTypeRevenue ?? this.propertyTypeRevenue,
      propertyTypeJobs: propertyTypeJobs ?? this.propertyTypeJobs,
      paymentMethodRevenue: paymentMethodRevenue ?? this.paymentMethodRevenue,
      paymentMethodJobs: paymentMethodJobs ?? this.paymentMethodJobs,
      statusRevenue: statusRevenue ?? this.statusRevenue,
      statusJobs: statusJobs ?? this.statusJobs,
      recurringRevenue: recurringRevenue ?? this.recurringRevenue,
      recurringJobs: recurringJobs ?? this.recurringJobs,
      oneOffRevenue: oneOffRevenue ?? this.oneOffRevenue,
      oneOffJobs: oneOffJobs ?? this.oneOffJobs,
      sourceJobIds: sourceJobIds ?? this.sourceJobIds,
    );
  }

  // ── Serialization ──

  Map<String, dynamic> toJson() => {
    'date_key': dateKey,
    'schema_version': schemaVersion,
    'dirty': dirty,
    'revenue': revenue,
    'parts_cost': partsCost,
    'expenses_cost': expensesCost,
    'job_count': jobCount,
    'completed_job_count': completedJobCount,
    'uninvoiced_value': uninvoicedValue,
    'unpaid_amount': unpaidAmount,
    'partial_amount': partialAmount,
    'paid_amount': paidAmount,
    'unpaid_count': unpaidCount,
    'partial_count': partialCount,
    'paid_count': paidCount,
    'new_customer_count': newCustomerCount,
    'customer_revenue': customerRevenue,
    'st_revenue': stRevenue,
    'st_jobs': stJobs,
    'st_parts_cost': stPartsCost,
    'parts_usage': partsUsage,
    'expense_categories': expenseCategories,
    'lead_source_revenue': leadSourceRevenue,
    'lead_source_jobs': leadSourceJobs,
    'location_revenue': locationRevenue,
    'location_jobs': locationJobs,
    'property_type_revenue': propertyTypeRevenue,
    'property_type_jobs': propertyTypeJobs,
    'payment_method_revenue': paymentMethodRevenue,
    'payment_method_jobs': paymentMethodJobs,
    'status_revenue': statusRevenue,
    'status_jobs': statusJobs,
    'recurring_revenue': recurringRevenue,
    'recurring_jobs': recurringJobs,
    'one_off_revenue': oneOffRevenue,
    'one_off_jobs': oneOffJobs,
    'source_job_ids': sourceJobIds,
  };

  factory DailyRollup.fromJson(Map<String, dynamic> json) {
    final stRevRaw = json['st_revenue'];
    final stJobsRaw = json['st_jobs'];
    final stPartsRaw = json['st_parts_cost'];
    final partsRaw = json['parts_usage'];
    final expCatRaw = json['expense_categories'];
    final lsRevRaw = json['lead_source_revenue'];
    final lsJobsRaw = json['lead_source_jobs'];
    final locRevRaw = json['location_revenue'];
    final locJobsRaw = json['location_jobs'];
    final ptRevRaw = json['property_type_revenue'];
    final ptJobsRaw = json['property_type_jobs'];
    final pmRevRaw = json['payment_method_revenue'];
    final pmJobsRaw = json['payment_method_jobs'];
    final stRevRaw2 = json['status_revenue'];
    final stJobsRaw2 = json['status_jobs'];
    final custRevRaw = json['customer_revenue'];
    final srcIdsRaw = json['source_job_ids'];

    return DailyRollup(
      dateKey: json['date_key'] as String? ?? '',
      schemaVersion: json['schema_version'] as int? ?? 1,
      dirty: json['dirty'] as bool? ?? false,
      revenue: json['revenue'] as int? ?? 0,
      partsCost: json['parts_cost'] as int? ?? 0,
      expensesCost: json['expenses_cost'] as int? ?? 0,
      jobCount: json['job_count'] as int? ?? 0,
      completedJobCount: json['completed_job_count'] as int? ?? 0,
      uninvoicedValue: json['uninvoiced_value'] as int? ?? 0,
      unpaidAmount: json['unpaid_amount'] as int? ?? 0,
      partialAmount: json['partial_amount'] as int? ?? 0,
      paidAmount: json['paid_amount'] as int? ?? 0,
      unpaidCount: json['unpaid_count'] as int? ?? 0,
      partialCount: json['partial_count'] as int? ?? 0,
      paidCount: json['paid_count'] as int? ?? 0,
      newCustomerCount: json['new_customer_count'] as int? ?? 0,
      customerRevenue: custRevRaw is Map ? Map<String, int>.from(custRevRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      stRevenue: stRevRaw is Map ? Map<String, int>.from(stRevRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      stJobs: stJobsRaw is Map ? Map<String, int>.from(stJobsRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      stPartsCost: stPartsRaw is Map ? Map<String, int>.from(stPartsRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      partsUsage: partsRaw is Map ? Map<String, int>.from(partsRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      expenseCategories: expCatRaw is Map ? Map<String, int>.from(expCatRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      leadSourceRevenue: lsRevRaw is Map ? Map<String, int>.from(lsRevRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      leadSourceJobs: lsJobsRaw is Map ? Map<String, int>.from(lsJobsRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      locationRevenue: locRevRaw is Map ? Map<String, int>.from(locRevRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      locationJobs: locJobsRaw is Map ? Map<String, int>.from(locJobsRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      propertyTypeRevenue: ptRevRaw is Map ? Map<String, int>.from(ptRevRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      propertyTypeJobs: ptJobsRaw is Map ? Map<String, int>.from(ptJobsRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      paymentMethodRevenue: pmRevRaw is Map ? Map<String, int>.from(pmRevRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      paymentMethodJobs: pmJobsRaw is Map ? Map<String, int>.from(pmJobsRaw.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      statusRevenue: stRevRaw2 is Map ? Map<String, int>.from(stRevRaw2.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      statusJobs: stJobsRaw2 is Map ? Map<String, int>.from(stJobsRaw2.map((k, v) => MapEntry(k.toString(), _toInt(v)))) : const {},
      recurringRevenue: json['recurring_revenue'] as int? ?? 0,
      recurringJobs: json['recurring_jobs'] as int? ?? 0,
      oneOffRevenue: json['one_off_revenue'] as int? ?? 0,
      oneOffJobs: json['one_off_jobs'] as int? ?? 0,
      sourceJobIds: srcIdsRaw is List ? List<String>.from(srcIdsRaw.map((e) => e.toString())) : const [],
    );
  }

  static int _toInt(Object? v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
