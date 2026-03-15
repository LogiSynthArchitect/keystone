// This file acts as the official bridge for inter-feature communication
// It strictly enforces Document 13 Rule 4 by preventing direct sibling imports

export '../../features/customer_history/presentation/providers/customer_providers.dart'
    show createCustomerUsecaseProvider, getCustomerByPhoneUsecaseProvider, customerDetailProvider;
export '../../features/customer_history/domain/usecases/create_customer_usecase.dart'
    show CreateCustomerUsecase, CreateCustomerParams;
export '../../features/customer_history/domain/usecases/get_customer_by_phone_usecase.dart'
    show GetCustomerByPhoneUsecase;
