// This file acts as the official bridge for inter-feature communication
// It strictly enforces Document 13 Rule 4 by preventing direct sibling imports

// Customer History - Presentation Providers
export 'package:arclock/features/customer_history/presentation/providers/customer_providers.dart'
    show 
        createCustomerUsecaseProvider, 
        getCustomerByPhoneUsecaseProvider, 
        customerDetailProvider,
        customerListProvider,
        customerRepositoryProvider,
        customerLocalDatasourceProvider,
        syncOfflineCustomersUsecaseProvider;

// Customer History - Use Cases
export 'package:arclock/features/customer_history/domain/usecases/create_customer_usecase.dart'
    show CreateCustomerUsecase, CreateCustomerParams;
export 'package:arclock/features/customer_history/domain/usecases/get_customer_by_phone_usecase.dart'
    show GetCustomerByPhoneUsecase;
export 'package:arclock/features/customer_history/domain/usecases/sync_offline_customers_usecase.dart'
    show SyncOfflineCustomersUsecase;

// Customer History - Data Sources
export 'package:arclock/features/customer_history/data/datasources/customer_local_datasource.dart'
    show CustomerLocalDatasource;

// Job Logging - Presentation Providers
export 'package:arclock/features/job_logging/presentation/providers/job_providers.dart'
    show jobDetailProvider, jobListProvider, archiveJobUsecaseProvider;

// Technician Profile - Presentation Providers
export 'package:arclock/features/technician_profile/presentation/providers/profile_provider.dart'
    show profileProvider, profileRepositoryProvider;

// Knowledge Base - Presentation Providers
export 'package:arclock/features/knowledge_base/presentation/providers/notes_providers.dart'
    show notesListProvider;

// Service Types
export 'package:arclock/features/service_types/presentation/providers/service_type_provider.dart'
    show serviceTypeProvider;
