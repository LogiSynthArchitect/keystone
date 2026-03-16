import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/job_logging/domain/repositories/job_repository.dart';
import 'package:keystone/features/customer_history/domain/repositories/customer_repository.dart';
import 'package:keystone/features/knowledge_base/domain/repositories/knowledge_note_repository.dart';
import 'package:keystone/features/whatsapp_followup/domain/repositories/follow_up_repository.dart';
import 'package:keystone/features/auth/domain/repositories/auth_repository.dart';
import 'package:keystone/features/technician_profile/domain/repositories/profile_repository.dart';
import 'package:keystone/features/job_logging/data/datasources/job_remote_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_local_datasource.dart';
import 'package:keystone/core/network/connectivity_service.dart';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockJobRepository extends Mock implements JobRepository {}
class MockCustomerRepository extends Mock implements CustomerRepository {}
class MockKnowledgeNoteRepository extends Mock implements KnowledgeNoteRepository {}
class MockFollowUpRepository extends Mock implements FollowUpRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockJobRemoteDatasource extends Mock implements JobRemoteDatasource {}
class MockJobLocalDatasource extends Mock implements JobLocalDatasource {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockUrlLauncher extends Mock with MockPlatformInterfaceMixin implements UrlLauncherPlatform {}
