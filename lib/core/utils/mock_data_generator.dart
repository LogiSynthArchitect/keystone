import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../features/job_logging/data/models/job_model.dart';
import '../../features/job_logging/data/models/job_part_model.dart';
import '../../features/customer_history/data/models/customer_model.dart';
import '../../features/knowledge_base/data/models/knowledge_note_model.dart';
import '../storage/hive_service.dart';
import '../../features/job_logging/presentation/providers/job_providers.dart';
import '../../features/customer_history/presentation/providers/customer_providers.dart';
import '../../features/analytics/presentation/providers/analytics_provider.dart';
import '../../features/knowledge_base/presentation/providers/notes_providers.dart';
import '../providers/auth_provider.dart';
import '../constants/app_enums.dart';

class MockDataGenerator {
  static Future<void> generate(WidgetRef ref) async {
    final user = await ref.read(currentUserProvider.future);
    final userId = user?.id ?? 'mock-user-id';
    
    final r = Random();
    const uuid = Uuid();
    
    // Generate 50 Customers
    final customers = <CustomerModel>[];
    final customerIds = <String>[];
    
    final locations = ['Accra Central', 'Osu', 'Cantonments', 'East Legon', 'Airport Residential', 'Labone', 'Dzorwulu', 'Spintex', 'Tema', 'Kumasi'];
    final names = ['Kwame Mensah', 'Abena Osei', 'Kojo Yeboah', 'Akosua Asare', 'Yaw Appiah', 'Ama Boakye', 'Kofi Danquah', 'Yaa Frimpong', 'Kwabena Owusu', 'Efua Agyemang'];
    
    for (int i = 0; i < 50; i++) {
      final id = uuid.v4();
      customerIds.add(id);
      
      final name = '${names[r.nextInt(names.length)]} ${r.nextInt(1000)}';
      
      customers.add(CustomerModel(
        id: id,
        userId: userId,
        fullName: name,
        phoneNumber: '055${r.nextInt(9999999).toString().padLeft(7, '0')}',
        location: locations[r.nextInt(locations.length)],
        totalJobs: 0, 
        syncStatus: SyncStatus.synced,
        propertyType: ['residential', 'commercial', 'automotive'][r.nextInt(3)],
        leadSource: ['referral', 'google', 'walk_in', 'social_media', 'other'][r.nextInt(5)],
        createdAt: DateTime.now().subtract(Duration(days: 90 + r.nextInt(100))).toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
    }
    
    // Generate 300 Jobs
    final jobs = <JobModel>[];
    final jobParts = <JobPartModel>[];
    
    final serviceTypes = [
      'car_lock_programming',
      'door_lock_installation',
      'door_lock_repair',
      'smart_lock_installation'
    ];
    
    final partNames = ['Mortise Lock', 'Key Blank', 'Smart Hub', 'Battery', 'Deadbolt', 'Transponder Key', 'Cylinder', 'Strike Plate'];
    final customerJobCounts = <String, int>{};
    final customerLastJob = <String, DateTime>{};
    
    for (int i = 0; i < 300; i++) {
      final id = uuid.v4();
      final cId = customerIds[r.nextInt(customerIds.length)];
      
      // Skew dates more towards recent
      final daysAgo = r.nextDouble() < 0.7 ? r.nextInt(30) : r.nextInt(90);
      final date = DateTime.now().subtract(Duration(days: daysAgo, hours: r.nextInt(24)));
      
      final st = serviceTypes[r.nextInt(serviceTypes.length)];
      final isCompleted = r.nextDouble() > 0.1; // 90% completed
      final status = isCompleted ? 'completed' : ['in_progress', 'quoted', 'invoiced'][r.nextInt(3)];
      
      final amt = r.nextInt(200000) + 5000; // 50 to 2050 GHS
      
      String payStatus = 'unpaid';
      if (status == 'completed' || status == 'invoiced') {
        final payRand = r.nextDouble();
        if (payRand > 0.4) {
          payStatus = 'paid';
        } else if (payRand > 0.2) {
          payStatus = 'partial';
        }
      }
      
      jobs.add(JobModel(
        id: id,
        userId: userId,
        customerId: cId,
        serviceType: st,
        jobDate: date,
        location: customers.firstWhere((c) => c.id == cId).location,
        amountCharged: status == 'quoted' ? null : amt,
        quotedPrice: amt,
        followUpSent: r.nextBool(),
        syncStatus: 'synced',
        isArchived: false,
        status: status,
        paymentStatus: payStatus,
        paymentMethod: payStatus == 'unpaid' ? null : ['cash', 'mobile_money', 'bank_transfer'][r.nextInt(3)],
        hardwareBrand: ['Yale', 'Schlage', 'Kwikset', 'Assa Abloy', 'Mul-T-Lock'][r.nextInt(5)],
        createdAt: date.toIso8601String(),
        updatedAt: date.toIso8601String(),
      ));
      
      // Update customer stats tracking
      customerJobCounts[cId] = (customerJobCounts[cId] ?? 0) + 1;
      if (customerLastJob[cId] == null || date.isAfter(customerLastJob[cId]!)) {
        customerLastJob[cId] = date;
      }
      
      // Generate Job Parts for completed jobs
      if (status == 'completed' && r.nextDouble() > 0.3) {
        int numParts = r.nextInt(3) + 1;
        for (int p = 0; p < numParts; p++) {
          jobParts.add(JobPartModel(
            id: uuid.v4(),
            jobId: id,
            partName: partNames[r.nextInt(partNames.length)],
            quantity: r.nextInt(3) + 1,
            unitPrice: (r.nextInt(500) + 50) * 100, // 50 to 550 GHS
            createdAt: date.toIso8601String(),
          ));
        }
      }
    }
    
    // Update customers with actual stats
    for (int i = 0; i < customers.length; i++) {
      final cId = customers[i].id;
      if (customerJobCounts.containsKey(cId)) {
        customers[i] = customers[i].copyWith(
          totalJobs: customerJobCounts[cId],
          lastJobAt: customerLastJob[cId]?.toIso8601String(),
        );
      }
    }

    // Generate Knowledge Notes
    final notes = <KnowledgeNoteModel>[];
    for (int i = 0; i < 20; i++) {
      notes.add(KnowledgeNoteModel(
        id: uuid.v4(),
        userId: userId,
        title: 'Mock Note ${i + 1}: How to fix ${partNames[r.nextInt(partNames.length)]}',
        description: 'This is a demo note showcasing technical knowledge about ${serviceTypes[r.nextInt(serviceTypes.length)]}. Make sure to test the voltage first.',
        tags: ['demo', 'mock_data', serviceTypes[r.nextInt(serviceTypes.length)].split('_').first],
        serviceType: serviceTypes[r.nextInt(serviceTypes.length)],
        isArchived: false,
        createdAt: DateTime.now().subtract(Duration(days: r.nextInt(30))).toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        syncStatus: 'synced',
      ));
    }
    
    // Save to Hive
    final cMap = {for (var c in customers) c.id: c.toJson()};
    await HiveService.customers.putAll(cMap);
    
    final jMap = {for (var j in jobs) j.id: j.toJson()};
    await HiveService.jobs.putAll(jMap);
    
    final pMap = {for (var p in jobParts) p.id: p.toJson()};
    await HiveService.jobParts.putAll(pMap);

    final nMap = {for (var n in notes) n.id: n.toJson()};
    await HiveService.notes.putAll(nMap);
    
    // Refresh providers
    ref.invalidate(jobListProvider);
    ref.invalidate(customerListProvider);
    ref.invalidate(analyticsProvider);
    ref.invalidate(notesListProvider);
  }
  
  static Future<void> clearMockData(WidgetRef ref) async {
    // Only clearing what we mocked, but technically it clears everything local.
    // Given the user wants it to be temporary, we just wipe the boxes.
    await HiveService.jobs.clear();
    await HiveService.customers.clear();
    await HiveService.jobParts.clear();
    await HiveService.notes.clear();

    ref.invalidate(jobListProvider);
    ref.invalidate(customerListProvider);
    ref.invalidate(analyticsProvider);
    ref.invalidate(notesListProvider);
  }
}
