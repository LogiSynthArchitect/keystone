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

  // ── Source job IDs (for invalidation tracing) ──
  final List<String> sourceJobIds;

  const DailyRollup({
    required this.dateKey,
    this.schemaVersion = 1,
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
