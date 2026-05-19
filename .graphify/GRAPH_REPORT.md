# Graph Report - /home/cybocrime/workspace/projects/keystone/lib/features  (2026-05-19)

## Corpus Check
- Large corpus: 238 files · ~85,936 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder, or use --no-semantic to run AST-only.

## Summary
- 1204 nodes · 968 edges · 235 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## God Nodes (most connected - your core abstractions)
1. `KeyCodeEntryModel` - 2 edges
2. `NoteJobLinkModel` - 2 edges
3. `TimelineEvent` - 1 edges
4. `TimelineState` - 1 edges
5. `TimelineNotifier` - 1 edges
6. `TimelineScreen` - 1 edges
7. `_EventList` - 1 edges
8. `_DateLabel` - 1 edges
9. `_EventTile` - 1 edges
10. `_EmptyState` - 1 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "Analytics Screen Widgets"
Cohesion: 0.08
Nodes (24): _AnalyticsBody, AnalyticsScreen, _CustomerRetentionSection, _DayOfWeekSection, _EmptyRow, _ErrorView, _ExpenseBreakdownSection, _ExpenseRow (+16 more)

### Community 1 - "Job Providers & Notifiers"
Cohesion: 0.09
Nodes (8): AdminRequestsNotifier, CustomerHistorySuggestions, JobDetailData, JobListFilters, JobListNotifier, JobListState, LogJobNotifier, LogJobState

### Community 2 - "Notes Providers & Notifiers"
Cohesion: 0.1
Nodes (6): AddNoteNotifier, AddNoteState, EditNoteNotifier, EditNoteState, NotesListNotifier, NotesListState

### Community 3 - "Log Job Screen"
Cohesion: 0.11
Nodes (6): _ExpenseRow, _HardwareRow, LogJobScreen, _LogJobScreenState, _PartRow, _ServiceRow

### Community 4 - "Customer Providers & Notifiers"
Cohesion: 0.11
Nodes (4): AddCustomerNotifier, AddCustomerState, CustomerListNotifier, CustomerListState

### Community 5 - "Job List Screen UI"
Cohesion: 0.11
Nodes (8): _FilterSection, _FilterSectionDynamic, _JobFilterSheet, _JobFilterSheetState, JobListScreen, _JobListScreenState, _Stat, _SummaryStrip

### Community 6 - "Job Repository Implementation"
Cohesion: 0.13
Nodes (1): JobRepositoryImpl

### Community 7 - "Job Detail Media & Photos"
Cohesion: 0.13
Nodes (4): _AudioPlayerWidget, _AudioPlayerWidgetState, JobDetailScreen, _LinkedNotesList

### Community 8 - "Job Repository Interface"
Cohesion: 0.14
Nodes (1): JobRepository

### Community 9 - "Auth Notifier & State"
Cohesion: 0.15
Nodes (2): AuthNotifier, AuthUiState

### Community 10 - "Analytics Data Providers"
Cohesion: 0.17
Nodes (7): AnalyticsNotifier, _DowAccumulator, _LeadAccumulator, _PartsAccumulator, _StAccumulator, _TopAccumulator, _TrendAccumulator

### Community 11 - "Customer List Screen UI"
Cohesion: 0.17
Nodes (4): _CustomerFilterSheet, _CustomerFilterSheetState, CustomerListScreen, _CustomerListScreenState

### Community 12 - "Edit Job Screen"
Cohesion: 0.17
Nodes (2): EditJobScreen, _EditJobScreenState

### Community 13 - "Shared Customer/Job Tiles"
Cohesion: 0.17
Nodes (9): _CustomerTile, _JobTile, _NoResults, _NoteTile, _Results, _SearchHint, SearchScreen, _SearchScreenState (+1 more)

### Community 14 - "Analytics Data Models"
Cohesion: 0.18
Nodes (9): AnalyticsState, DayOfWeekData, ExpenseCategoryBreakdown, LeadSourceBreakdown, PartsUsage, PaymentHealthData, RevenueTrendPoint, ServiceTypeBreakdown (+1 more)

### Community 15 - "Community 15"
Cohesion: 0.18
Nodes (2): InventoryScreen, _InventoryScreenState

### Community 16 - "Community 16"
Cohesion: 0.18
Nodes (2): EditProfileScreen, _EditProfileScreenState

### Community 17 - "Community 17"
Cohesion: 0.2
Nodes (2): AddCustomerScreen, _AddCustomerScreenState

### Community 18 - "Community 18"
Cohesion: 0.2
Nodes (5): CustomerDetailScreen, _CustomerDetailScreenState, _KeyCodesTab, _PropertyBadge, _ServiceHistoryTab

### Community 19 - "Community 19"
Cohesion: 0.2
Nodes (1): InventoryNotifier

### Community 20 - "Community 20"
Cohesion: 0.2
Nodes (4): _NotesFilterSheet, _NotesFilterSheetState, NotesListScreen, _NotesListScreenState

### Community 21 - "Community 21"
Cohesion: 0.22
Nodes (1): CustomerRepositoryImpl

### Community 22 - "Community 22"
Cohesion: 0.22
Nodes (1): CustomerRepository

### Community 23 - "Community 23"
Cohesion: 0.22
Nodes (2): AddNoteScreen, _AddNoteScreenState

### Community 24 - "Community 24"
Cohesion: 0.25
Nodes (5): _DateLabel, _EmptyState, _EventList, _EventTile, TimelineScreen

### Community 25 - "Community 25"
Cohesion: 0.25
Nodes (5): BiometricEnrollPage, BiometricEnrollSheet, _OptionTile, _PinSetupDialog, _PinSetupDialogState

### Community 26 - "Community 26"
Cohesion: 0.25
Nodes (2): OnboardingScreen, _OnboardingScreenState

### Community 27 - "Community 27"
Cohesion: 0.25
Nodes (2): PinEntryScreen, _PinEntryScreenState

### Community 28 - "Community 28"
Cohesion: 0.25
Nodes (4): SetupScreen, _SetupScreenState, _StepIndicator, _StepView

### Community 29 - "Community 29"
Cohesion: 0.25
Nodes (2): UpgradeAccountScreen, _UpgradeAccountScreenState

### Community 30 - "Community 30"
Cohesion: 0.25
Nodes (2): MergeCustomerSheet, _MergeCustomerSheetState

### Community 31 - "Community 31"
Cohesion: 0.25
Nodes (1): JobLocalDatasource

### Community 32 - "Community 32"
Cohesion: 0.25
Nodes (1): ProfileRemoteDatasource

### Community 33 - "Community 33"
Cohesion: 0.25
Nodes (1): InventoryRepositoryImpl

### Community 34 - "Community 34"
Cohesion: 0.25
Nodes (1): InventoryRepository

### Community 35 - "Community 35"
Cohesion: 0.25
Nodes (2): KeyCodeNotifier, KeyCodeState

### Community 36 - "Community 36"
Cohesion: 0.25
Nodes (2): EditNoteScreen, _EditNoteScreenState

### Community 37 - "Community 37"
Cohesion: 0.25
Nodes (1): ServiceTypeNotifier

### Community 38 - "Community 38"
Cohesion: 0.25
Nodes (1): ProfileRepository

### Community 39 - "Community 39"
Cohesion: 0.25
Nodes (1): ProfileRepositoryImpl

### Community 40 - "Community 40"
Cohesion: 0.25
Nodes (3): FollowUpButton, _FollowUpButtonState, _StatusChip

### Community 41 - "Community 41"
Cohesion: 0.29
Nodes (1): AuthRemoteDatasource

### Community 42 - "Community 42"
Cohesion: 0.29
Nodes (1): AuthRepositoryImpl

### Community 43 - "Community 43"
Cohesion: 0.29
Nodes (1): AuthRepository

### Community 44 - "Community 44"
Cohesion: 0.29
Nodes (2): OtpVerifyScreen, _OtpVerifyScreenState

### Community 45 - "Community 45"
Cohesion: 0.29
Nodes (2): PhoneEntryScreen, _PhoneEntryScreenState

### Community 46 - "Community 46"
Cohesion: 0.29
Nodes (4): FadeInDelayed, _FadeInDelayedState, TransitionScreen, _TransitionScreenState

### Community 47 - "Community 47"
Cohesion: 0.29
Nodes (1): InventoryLocalDatasource

### Community 48 - "Community 48"
Cohesion: 0.29
Nodes (1): KeyCodeRepositoryImpl

### Community 49 - "Community 49"
Cohesion: 0.29
Nodes (1): KnowledgeNoteRepositoryImpl

### Community 50 - "Community 50"
Cohesion: 0.29
Nodes (1): KnowledgeNoteRepository

### Community 51 - "Community 51"
Cohesion: 0.29
Nodes (1): NoteLinkNotifier

### Community 52 - "Community 52"
Cohesion: 0.29
Nodes (2): FollowUpNotifier, FollowUpState

### Community 53 - "Community 53"
Cohesion: 0.29
Nodes (2): ProfileNotifier, ProfileState

### Community 54 - "Community 54"
Cohesion: 0.29
Nodes (2): SearchNotifier, SearchResults

### Community 55 - "Community 55"
Cohesion: 0.33
Nodes (3): TimelineEvent, TimelineNotifier, TimelineState

### Community 56 - "Community 56"
Cohesion: 0.33
Nodes (2): ForgotAccessScreen, _ForgotAccessScreenState

### Community 57 - "Community 57"
Cohesion: 0.33
Nodes (1): CustomerLocalDatasource

### Community 58 - "Community 58"
Cohesion: 0.33
Nodes (1): CustomerRemoteDatasource

### Community 59 - "Community 59"
Cohesion: 0.33
Nodes (2): EditCustomerScreen, _EditCustomerScreenState

### Community 60 - "Community 60"
Cohesion: 0.33
Nodes (2): ContactImportSheet, _ContactImportSheetState

### Community 61 - "Community 61"
Cohesion: 0.33
Nodes (1): JobExpensesLocalDatasource

### Community 62 - "Community 62"
Cohesion: 0.33
Nodes (1): JobHardwareLocalDatasource

### Community 63 - "Community 63"
Cohesion: 0.33
Nodes (1): JobPartsLocalDatasource

### Community 64 - "Community 64"
Cohesion: 0.33
Nodes (1): JobServicesLocalDatasource

### Community 65 - "Community 65"
Cohesion: 0.33
Nodes (1): KnowledgeNoteLocalDatasource

### Community 66 - "Community 66"
Cohesion: 0.33
Nodes (1): ServiceTypeLocalDatasource

### Community 67 - "Community 67"
Cohesion: 0.33
Nodes (2): JobTemplatesScreen, _JobTemplatesScreenState

### Community 68 - "Community 68"
Cohesion: 0.33
Nodes (2): EditKeyCodeScreen, _EditKeyCodeScreenState

### Community 69 - "Community 69"
Cohesion: 0.33
Nodes (3): _TagChip, TagInputField, _TagInputFieldState

### Community 70 - "Community 70"
Cohesion: 0.33
Nodes (2): RemindersNotifier, RemindersState

### Community 71 - "Community 71"
Cohesion: 0.33
Nodes (1): ReminderRepositoryImpl

### Community 72 - "Community 72"
Cohesion: 0.33
Nodes (1): ReminderRepository

### Community 73 - "Community 73"
Cohesion: 0.33
Nodes (1): FollowUpRepository

### Community 74 - "Community 74"
Cohesion: 0.33
Nodes (1): FollowUpRepositoryImpl

### Community 75 - "Community 75"
Cohesion: 0.33
Nodes (1): ServiceTypeRepository

### Community 76 - "Community 76"
Cohesion: 0.33
Nodes (1): ServiceTypeRepositoryImpl

### Community 77 - "Community 77"
Cohesion: 0.33
Nodes (2): ServiceTypesScreen, _ServiceTypeTile

### Community 78 - "Community 78"
Cohesion: 0.4
Nodes (2): InitialSyncScreen, _InitialSyncScreenState

### Community 79 - "Community 79"
Cohesion: 0.4
Nodes (2): StaleDataScreen, _StaleDataScreenState

### Community 80 - "Community 80"
Cohesion: 0.4
Nodes (1): FollowUpLocalDatasource

### Community 81 - "Community 81"
Cohesion: 0.4
Nodes (1): FollowUpRemoteDatasource

### Community 82 - "Community 82"
Cohesion: 0.4
Nodes (1): InventoryRemoteDatasource

### Community 83 - "Community 83"
Cohesion: 0.4
Nodes (1): InventoryRestocksLocalDatasource

### Community 84 - "Community 84"
Cohesion: 0.4
Nodes (1): InventoryStockAdjustmentsLocalDatasource

### Community 85 - "Community 85"
Cohesion: 0.4
Nodes (1): JobPhotosLocalDatasource

### Community 86 - "Community 86"
Cohesion: 0.4
Nodes (1): JobPhotosRemoteDatasource

### Community 87 - "Community 87"
Cohesion: 0.4
Nodes (1): JobRemoteDatasource

### Community 88 - "Community 88"
Cohesion: 0.4
Nodes (1): JobTemplateLocalDatasource

### Community 89 - "Community 89"
Cohesion: 0.4
Nodes (1): KeyCodeRemoteDatasource

### Community 90 - "Community 90"
Cohesion: 0.4
Nodes (1): KnowledgeNoteRemoteDatasource

### Community 91 - "Community 91"
Cohesion: 0.4
Nodes (1): ProfileLocalDatasource

### Community 92 - "Community 92"
Cohesion: 0.4
Nodes (1): ServiceTypeRemoteDatasource

### Community 93 - "Community 93"
Cohesion: 0.4
Nodes (1): CorrectionRequestRepositoryImpl

### Community 94 - "Community 94"
Cohesion: 0.4
Nodes (1): CorrectionRequestRepository

### Community 95 - "Community 95"
Cohesion: 0.4
Nodes (2): AdminRequestsScreen, _RequestCard

### Community 96 - "Community 96"
Cohesion: 0.4
Nodes (1): JobTemplateNotifier

### Community 97 - "Community 97"
Cohesion: 0.4
Nodes (1): KeyCodeRepository

### Community 98 - "Community 98"
Cohesion: 0.4
Nodes (2): KeyCodesScreen, _KeyCodeTile

### Community 99 - "Community 99"
Cohesion: 0.4
Nodes (2): EditableFollowUpNotifier, EditableFollowUpState

### Community 100 - "Community 100"
Cohesion: 0.4
Nodes (1): RecurringScheduleNotifier

### Community 101 - "Community 101"
Cohesion: 0.4
Nodes (2): PricingScreen, _PricingScreenState

### Community 102 - "Community 102"
Cohesion: 0.4
Nodes (1): PublicProfileScreen

### Community 103 - "Community 103"
Cohesion: 0.5
Nodes (2): RequestOtpParams, RequestOtpUsecase

### Community 104 - "Community 104"
Cohesion: 0.5
Nodes (2): VerifyOtpParams, VerifyOtpUsecase

### Community 105 - "Community 105"
Cohesion: 0.5
Nodes (2): LockedScreen, _LockedScreenState

### Community 106 - "Community 106"
Cohesion: 0.5
Nodes (2): CreateCustomerParams, CreateCustomerUsecase

### Community 107 - "Community 107"
Cohesion: 0.5
Nodes (2): MergeCustomersParams, MergeCustomersUsecase

### Community 108 - "Community 108"
Cohesion: 0.5
Nodes (2): UpdateCustomerParams, UpdateCustomerUsecase

### Community 109 - "Community 109"
Cohesion: 0.5
Nodes (1): JobAuditLocalDatasource

### Community 110 - "Community 110"
Cohesion: 0.5
Nodes (1): JobAuditRemoteDatasource

### Community 111 - "Community 111"
Cohesion: 0.5
Nodes (1): JobExpensesRemoteDatasource

### Community 112 - "Community 112"
Cohesion: 0.5
Nodes (1): JobHardwareRemoteDatasource

### Community 113 - "Community 113"
Cohesion: 0.5
Nodes (1): JobPartsRemoteDatasource

### Community 114 - "Community 114"
Cohesion: 0.5
Nodes (1): JobServicesRemoteDatasource

### Community 115 - "Community 115"
Cohesion: 0.5
Nodes (1): KeyCodeLocalDatasource

### Community 116 - "Community 116"
Cohesion: 0.5
Nodes (1): NoteLinkLocalDatasource

### Community 117 - "Community 117"
Cohesion: 0.5
Nodes (1): NoteLinkRemoteDatasource

### Community 118 - "Community 118"
Cohesion: 0.5
Nodes (1): RecurringScheduleLocalDatasource

### Community 119 - "Community 119"
Cohesion: 0.5
Nodes (2): CreateInventoryItemParams, CreateInventoryItemUsecase

### Community 120 - "Community 120"
Cohesion: 0.5
Nodes (2): DeleteInventoryItemParams, DeleteInventoryItemUsecase

### Community 121 - "Community 121"
Cohesion: 0.5
Nodes (2): UpdateInventoryItemParams, UpdateInventoryItemUsecase

### Community 122 - "Community 122"
Cohesion: 0.5
Nodes (2): EditJobParams, EditJobUsecase

### Community 123 - "Community 123"
Cohesion: 0.5
Nodes (2): LogJobParams, LogJobUsecase

### Community 124 - "Community 124"
Cohesion: 0.5
Nodes (2): LogJobWithCustomerParams, LogJobWithCustomerUsecase

### Community 125 - "Community 125"
Cohesion: 0.5
Nodes (2): RequestCorrectionParams, RequestCorrectionUsecase

### Community 126 - "Community 126"
Cohesion: 0.5
Nodes (2): UpdateJobParams, UpdateJobUsecase

### Community 127 - "Community 127"
Cohesion: 0.5
Nodes (2): UpdatePaymentStatusParams, UpdatePaymentStatusUsecase

### Community 128 - "Community 128"
Cohesion: 0.5
Nodes (2): _CustomBadge, JobCard

### Community 129 - "Community 129"
Cohesion: 0.5
Nodes (1): JobTemplateRepositoryImpl

### Community 130 - "Community 130"
Cohesion: 0.5
Nodes (1): JobTemplateRepository

### Community 131 - "Community 131"
Cohesion: 0.5
Nodes (2): CreateKeyCodeParams, CreateKeyCodeUsecase

### Community 132 - "Community 132"
Cohesion: 0.5
Nodes (2): CreateNoteParams, CreateNoteUsecase

### Community 133 - "Community 133"
Cohesion: 0.5
Nodes (2): UpdateNoteParams, UpdateNoteUsecase

### Community 134 - "Community 134"
Cohesion: 0.5
Nodes (1): NoteLinkRepositoryImpl

### Community 135 - "Community 135"
Cohesion: 0.5
Nodes (1): NoteLinkRepository

### Community 136 - "Community 136"
Cohesion: 0.5
Nodes (2): CreateNoteLinkParams, CreateNoteLinkUsecase

### Community 137 - "Community 137"
Cohesion: 0.5
Nodes (2): RecurringSchedulesScreen, _RecurringSchedulesScreenState

### Community 138 - "Community 138"
Cohesion: 0.5
Nodes (2): ReminderSettingsScreen, _ReminderSettingsScreenState

### Community 139 - "Community 139"
Cohesion: 0.5
Nodes (3): _EmptyState, _ReminderCard, RemindersScreen

### Community 140 - "Community 140"
Cohesion: 0.5
Nodes (2): CreateServiceTypeParams, CreateServiceTypeUsecase

### Community 141 - "Community 141"
Cohesion: 0.5
Nodes (2): UpdateServiceTypeParams, UpdateServiceTypeUsecase

### Community 142 - "Community 142"
Cohesion: 0.5
Nodes (2): BuildFollowupMessageParams, BuildFollowupMessageUsecase

### Community 143 - "Community 143"
Cohesion: 0.5
Nodes (2): SendFollowupParams, SendFollowupUsecase

### Community 144 - "Community 144"
Cohesion: 0.5
Nodes (2): FollowUpMessagePreview, _FollowUpMessagePreviewState

### Community 145 - "Community 145"
Cohesion: 0.67
Nodes (1): LogoutUsecase

### Community 146 - "Community 146"
Cohesion: 0.67
Nodes (1): KeyCodeEntryModel

### Community 147 - "Community 147"
Cohesion: 0.67
Nodes (1): DeleteCustomerUsecase

### Community 148 - "Community 148"
Cohesion: 0.67
Nodes (1): GetCustomerByPhoneUsecase

### Community 149 - "Community 149"
Cohesion: 0.67
Nodes (1): GetCustomerUsecase

### Community 150 - "Community 150"
Cohesion: 0.67
Nodes (1): SyncOfflineCustomersUsecase

### Community 151 - "Community 151"
Cohesion: 0.67
Nodes (1): InventoryRestocksRemoteDatasource

### Community 152 - "Community 152"
Cohesion: 0.67
Nodes (1): InventoryStockAdjustmentsRemoteDatasource

### Community 153 - "Community 153"
Cohesion: 0.67
Nodes (2): GetInventoryItemsParams, GetInventoryItemsUsecase

### Community 154 - "Community 154"
Cohesion: 0.67
Nodes (1): ArchiveJobUsecase

### Community 155 - "Community 155"
Cohesion: 0.67
Nodes (1): GetJobUsecase

### Community 156 - "Community 156"
Cohesion: 0.67
Nodes (2): GetJobsParams, GetJobsUsecase

### Community 157 - "Community 157"
Cohesion: 0.67
Nodes (1): SyncOfflineJobsUsecase

### Community 158 - "Community 158"
Cohesion: 0.67
Nodes (1): DeleteKeyCodeUsecase

### Community 159 - "Community 159"
Cohesion: 0.67
Nodes (1): UpdateKeyCodeUsecase

### Community 160 - "Community 160"
Cohesion: 0.67
Nodes (1): NoteJobLinkModel

### Community 161 - "Community 161"
Cohesion: 0.67
Nodes (1): ArchiveNoteUsecase

### Community 162 - "Community 162"
Cohesion: 0.67
Nodes (1): SyncPendingNotesUsecase

### Community 163 - "Community 163"
Cohesion: 0.67
Nodes (2): _LinkedJobsList, NoteDetailScreen

### Community 164 - "Community 164"
Cohesion: 0.67
Nodes (2): NoteCard, _TagChip

### Community 165 - "Community 165"
Cohesion: 0.67
Nodes (1): ReminderThresholds

### Community 166 - "Community 166"
Cohesion: 0.67
Nodes (1): DeleteNoteLinkUsecase

### Community 167 - "Community 167"
Cohesion: 0.67
Nodes (2): NoteJobLinkScreen, _NoteJobLinkScreenState

### Community 168 - "Community 168"
Cohesion: 0.67
Nodes (1): PermissionsScreen

### Community 169 - "Community 169"
Cohesion: 0.67
Nodes (1): DeleteServiceTypeUsecase

### Community 170 - "Community 170"
Cohesion: 0.67
Nodes (1): SeedDefaultServiceTypesUseCase

### Community 171 - "Community 171"
Cohesion: 0.67
Nodes (1): GetProfileUsecase

### Community 172 - "Community 172"
Cohesion: 0.67
Nodes (1): ShareProfileUsecase

### Community 173 - "Community 173"
Cohesion: 0.67
Nodes (1): UpdateProfileUsecase

### Community 174 - "Community 174"
Cohesion: 1
Nodes (1): UserModel

### Community 175 - "Community 175"
Cohesion: 1
Nodes (1): UserEntity

### Community 176 - "Community 176"
Cohesion: 1
Nodes (1): LandingScreen

### Community 177 - "Community 177"
Cohesion: 1
Nodes (1): MinVersionGateScreen

### Community 178 - "Community 178"
Cohesion: 1
Nodes (1): AuthHeader

### Community 179 - "Community 179"
Cohesion: 1
Nodes (1): NameStepView

### Community 180 - "Community 180"
Cohesion: 1
Nodes (1): OnboardingBottomBar

### Community 181 - "Community 181"
Cohesion: 1
Nodes (1): OnboardingStepIndicator

### Community 182 - "Community 182"
Cohesion: 1
Nodes (1): CustomerModel

### Community 183 - "Community 183"
Cohesion: 1
Nodes (1): CustomerAuditEntryEntity

### Community 184 - "Community 184"
Cohesion: 1
Nodes (1): CustomerEntity

### Community 185 - "Community 185"
Cohesion: 1
Nodes (1): KeyCodeEntryEntity

### Community 186 - "Community 186"
Cohesion: 1
Nodes (1): GetCustomersUsecase

### Community 187 - "Community 187"
Cohesion: 1
Nodes (1): CustomerCard

### Community 188 - "Community 188"
Cohesion: 1
Nodes (1): DashboardScreen

### Community 189 - "Community 189"
Cohesion: 1
Nodes (1): CorrectionRequestEntity

### Community 190 - "Community 190"
Cohesion: 1
Nodes (1): FollowUpEntity

### Community 191 - "Community 191"
Cohesion: 1
Nodes (1): InventoryItemEntity

### Community 192 - "Community 192"
Cohesion: 1
Nodes (1): JobAuditEntryEntity

### Community 193 - "Community 193"
Cohesion: 1
Nodes (1): JobEntity

### Community 194 - "Community 194"
Cohesion: 1
Nodes (1): JobExpenseEntity

### Community 195 - "Community 195"
Cohesion: 1
Nodes (1): JobHardwareEntity

### Community 196 - "Community 196"
Cohesion: 1
Nodes (1): JobPartEntity

### Community 197 - "Community 197"
Cohesion: 1
Nodes (1): JobPhotoEntity

### Community 198 - "Community 198"
Cohesion: 1
Nodes (1): JobServiceEntity

### Community 199 - "Community 199"
Cohesion: 1
Nodes (1): JobTemplateEntity

### Community 200 - "Community 200"
Cohesion: 1
Nodes (1): KnowledgeNoteEntity

### Community 201 - "Community 201"
Cohesion: 1
Nodes (1): NoteJobLinkEntity

### Community 202 - "Community 202"
Cohesion: 1
Nodes (1): ProfileEntity

### Community 203 - "Community 203"
Cohesion: 1
Nodes (1): RecurringScheduleEntity

### Community 204 - "Community 204"
Cohesion: 1
Nodes (1): ReminderEntity

### Community 205 - "Community 205"
Cohesion: 1
Nodes (1): RestockEntity

### Community 206 - "Community 206"
Cohesion: 1
Nodes (1): ServiceTypeEntity

### Community 207 - "Community 207"
Cohesion: 1
Nodes (1): StockAdjustmentEntity

### Community 208 - "Community 208"
Cohesion: 1
Nodes (1): HubScreen

### Community 209 - "Community 209"
Cohesion: 1
Nodes (1): InventoryItemModel

### Community 210 - "Community 210"
Cohesion: 1
Nodes (1): RestockModel

### Community 211 - "Community 211"
Cohesion: 1
Nodes (1): StockAdjustmentModel

### Community 212 - "Community 212"
Cohesion: 1
Nodes (1): CorrectionRequestModel

### Community 213 - "Community 213"
Cohesion: 1
Nodes (1): JobAuditEntryModel

### Community 214 - "Community 214"
Cohesion: 1
Nodes (1): JobExpenseModel

### Community 215 - "Community 215"
Cohesion: 1
Nodes (1): JobHardwareModel

### Community 216 - "Community 216"
Cohesion: 1
Nodes (1): JobModel

### Community 217 - "Community 217"
Cohesion: 1
Nodes (1): JobPartModel

### Community 218 - "Community 218"
Cohesion: 1
Nodes (1): JobPhotoModel

### Community 219 - "Community 219"
Cohesion: 1
Nodes (1): JobServiceModel

### Community 220 - "Community 220"
Cohesion: 1
Nodes (1): ServiceTypePicker

### Community 221 - "Community 221"
Cohesion: 1
Nodes (1): JobTemplateModel

### Community 222 - "Community 222"
Cohesion: 1
Nodes (1): GetKeyCodesUsecase

### Community 223 - "Community 223"
Cohesion: 1
Nodes (1): KnowledgeNoteModel

### Community 224 - "Community 224"
Cohesion: 1
Nodes (1): GetNotesUsecase

### Community 225 - "Community 225"
Cohesion: 1
Nodes (1): FollowUpModel

### Community 226 - "Community 226"
Cohesion: 1
Nodes (1): ProfileModel

### Community 227 - "Community 227"
Cohesion: 1
Nodes (1): ReminderModel

### Community 228 - "Community 228"
Cohesion: 1
Nodes (1): Reminder

### Community 229 - "Community 229"
Cohesion: 1
Nodes (1): ServiceTypeModel

### Community 230 - "Community 230"
Cohesion: 1
Nodes (1): GetLinksForJobUsecase

### Community 231 - "Community 231"
Cohesion: 1
Nodes (1): GetLinksForNoteUsecase

### Community 232 - "Community 232"
Cohesion: 1
Nodes (1): ProfileScreen

### Community 233 - "Community 233"
Cohesion: 1
Nodes (1): GetServiceTypesUsecase

### Community 234 - "Community 234"
Cohesion: 1
Nodes (1): ServiceTypePickerV2

## Knowledge Gaps
- **402 isolated node(s):** `TimelineEvent`, `TimelineState`, `TimelineNotifier`, `TimelineScreen`, `_EventList` (+397 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Job Repository Implementation`** (1 nodes): `JobRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Job Repository Interface`** (1 nodes): `JobRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Auth Notifier & State`** (2 nodes): `AuthNotifier`, `AuthUiState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Edit Job Screen`** (2 nodes): `EditJobScreen`, `_EditJobScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 15`** (2 nodes): `InventoryScreen`, `_InventoryScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 16`** (2 nodes): `EditProfileScreen`, `_EditProfileScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 17`** (2 nodes): `AddCustomerScreen`, `_AddCustomerScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 19`** (1 nodes): `InventoryNotifier`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 21`** (1 nodes): `CustomerRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 22`** (1 nodes): `CustomerRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 23`** (2 nodes): `AddNoteScreen`, `_AddNoteScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 26`** (2 nodes): `OnboardingScreen`, `_OnboardingScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 27`** (2 nodes): `PinEntryScreen`, `_PinEntryScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 29`** (2 nodes): `UpgradeAccountScreen`, `_UpgradeAccountScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 30`** (2 nodes): `MergeCustomerSheet`, `_MergeCustomerSheetState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 31`** (1 nodes): `JobLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 32`** (1 nodes): `ProfileRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 33`** (1 nodes): `InventoryRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 34`** (1 nodes): `InventoryRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 35`** (2 nodes): `KeyCodeNotifier`, `KeyCodeState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 36`** (2 nodes): `EditNoteScreen`, `_EditNoteScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 37`** (1 nodes): `ServiceTypeNotifier`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 38`** (1 nodes): `ProfileRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 39`** (1 nodes): `ProfileRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 41`** (1 nodes): `AuthRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 42`** (1 nodes): `AuthRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 43`** (1 nodes): `AuthRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 44`** (2 nodes): `OtpVerifyScreen`, `_OtpVerifyScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 45`** (2 nodes): `PhoneEntryScreen`, `_PhoneEntryScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 47`** (1 nodes): `InventoryLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 48`** (1 nodes): `KeyCodeRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 49`** (1 nodes): `KnowledgeNoteRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 50`** (1 nodes): `KnowledgeNoteRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 51`** (1 nodes): `NoteLinkNotifier`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 52`** (2 nodes): `FollowUpNotifier`, `FollowUpState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 53`** (2 nodes): `ProfileNotifier`, `ProfileState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 54`** (2 nodes): `SearchNotifier`, `SearchResults`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 56`** (2 nodes): `ForgotAccessScreen`, `_ForgotAccessScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 57`** (1 nodes): `CustomerLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 58`** (1 nodes): `CustomerRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 59`** (2 nodes): `EditCustomerScreen`, `_EditCustomerScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 60`** (2 nodes): `ContactImportSheet`, `_ContactImportSheetState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 61`** (1 nodes): `JobExpensesLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 62`** (1 nodes): `JobHardwareLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 63`** (1 nodes): `JobPartsLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 64`** (1 nodes): `JobServicesLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 65`** (1 nodes): `KnowledgeNoteLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 66`** (1 nodes): `ServiceTypeLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 67`** (2 nodes): `JobTemplatesScreen`, `_JobTemplatesScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 68`** (2 nodes): `EditKeyCodeScreen`, `_EditKeyCodeScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 70`** (2 nodes): `RemindersNotifier`, `RemindersState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 71`** (1 nodes): `ReminderRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 72`** (1 nodes): `ReminderRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 73`** (1 nodes): `FollowUpRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 74`** (1 nodes): `FollowUpRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 75`** (1 nodes): `ServiceTypeRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 76`** (1 nodes): `ServiceTypeRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 77`** (2 nodes): `ServiceTypesScreen`, `_ServiceTypeTile`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 78`** (2 nodes): `InitialSyncScreen`, `_InitialSyncScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 79`** (2 nodes): `StaleDataScreen`, `_StaleDataScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 80`** (1 nodes): `FollowUpLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 81`** (1 nodes): `FollowUpRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 82`** (1 nodes): `InventoryRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 83`** (1 nodes): `InventoryRestocksLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 84`** (1 nodes): `InventoryStockAdjustmentsLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 85`** (1 nodes): `JobPhotosLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 86`** (1 nodes): `JobPhotosRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 87`** (1 nodes): `JobRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 88`** (1 nodes): `JobTemplateLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 89`** (1 nodes): `KeyCodeRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 90`** (1 nodes): `KnowledgeNoteRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 91`** (1 nodes): `ProfileLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 92`** (1 nodes): `ServiceTypeRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 93`** (1 nodes): `CorrectionRequestRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 94`** (1 nodes): `CorrectionRequestRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 95`** (2 nodes): `AdminRequestsScreen`, `_RequestCard`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 96`** (1 nodes): `JobTemplateNotifier`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 97`** (1 nodes): `KeyCodeRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 98`** (2 nodes): `KeyCodesScreen`, `_KeyCodeTile`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 99`** (2 nodes): `EditableFollowUpNotifier`, `EditableFollowUpState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 100`** (1 nodes): `RecurringScheduleNotifier`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 101`** (2 nodes): `PricingScreen`, `_PricingScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 102`** (1 nodes): `PublicProfileScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 103`** (2 nodes): `RequestOtpParams`, `RequestOtpUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 104`** (2 nodes): `VerifyOtpParams`, `VerifyOtpUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 105`** (2 nodes): `LockedScreen`, `_LockedScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 106`** (2 nodes): `CreateCustomerParams`, `CreateCustomerUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 107`** (2 nodes): `MergeCustomersParams`, `MergeCustomersUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 108`** (2 nodes): `UpdateCustomerParams`, `UpdateCustomerUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 109`** (1 nodes): `JobAuditLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 110`** (1 nodes): `JobAuditRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 111`** (1 nodes): `JobExpensesRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 112`** (1 nodes): `JobHardwareRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 113`** (1 nodes): `JobPartsRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 114`** (1 nodes): `JobServicesRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 115`** (1 nodes): `KeyCodeLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 116`** (1 nodes): `NoteLinkLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 117`** (1 nodes): `NoteLinkRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 118`** (1 nodes): `RecurringScheduleLocalDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 119`** (2 nodes): `CreateInventoryItemParams`, `CreateInventoryItemUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 120`** (2 nodes): `DeleteInventoryItemParams`, `DeleteInventoryItemUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 121`** (2 nodes): `UpdateInventoryItemParams`, `UpdateInventoryItemUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 122`** (2 nodes): `EditJobParams`, `EditJobUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 123`** (2 nodes): `LogJobParams`, `LogJobUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 124`** (2 nodes): `LogJobWithCustomerParams`, `LogJobWithCustomerUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 125`** (2 nodes): `RequestCorrectionParams`, `RequestCorrectionUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 126`** (2 nodes): `UpdateJobParams`, `UpdateJobUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 127`** (2 nodes): `UpdatePaymentStatusParams`, `UpdatePaymentStatusUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 128`** (2 nodes): `_CustomBadge`, `JobCard`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 129`** (1 nodes): `JobTemplateRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 130`** (1 nodes): `JobTemplateRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 131`** (2 nodes): `CreateKeyCodeParams`, `CreateKeyCodeUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 132`** (2 nodes): `CreateNoteParams`, `CreateNoteUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 133`** (2 nodes): `UpdateNoteParams`, `UpdateNoteUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 134`** (1 nodes): `NoteLinkRepositoryImpl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 135`** (1 nodes): `NoteLinkRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 136`** (2 nodes): `CreateNoteLinkParams`, `CreateNoteLinkUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 137`** (2 nodes): `RecurringSchedulesScreen`, `_RecurringSchedulesScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 138`** (2 nodes): `ReminderSettingsScreen`, `_ReminderSettingsScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 140`** (2 nodes): `CreateServiceTypeParams`, `CreateServiceTypeUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 141`** (2 nodes): `UpdateServiceTypeParams`, `UpdateServiceTypeUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 142`** (2 nodes): `BuildFollowupMessageParams`, `BuildFollowupMessageUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 143`** (2 nodes): `SendFollowupParams`, `SendFollowupUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 144`** (2 nodes): `FollowUpMessagePreview`, `_FollowUpMessagePreviewState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 145`** (1 nodes): `LogoutUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 146`** (1 nodes): `KeyCodeEntryModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 147`** (1 nodes): `DeleteCustomerUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 148`** (1 nodes): `GetCustomerByPhoneUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 149`** (1 nodes): `GetCustomerUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 150`** (1 nodes): `SyncOfflineCustomersUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 151`** (1 nodes): `InventoryRestocksRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 152`** (1 nodes): `InventoryStockAdjustmentsRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 153`** (2 nodes): `GetInventoryItemsParams`, `GetInventoryItemsUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 154`** (1 nodes): `ArchiveJobUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 155`** (1 nodes): `GetJobUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 156`** (2 nodes): `GetJobsParams`, `GetJobsUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 157`** (1 nodes): `SyncOfflineJobsUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 158`** (1 nodes): `DeleteKeyCodeUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 159`** (1 nodes): `UpdateKeyCodeUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 160`** (1 nodes): `NoteJobLinkModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 161`** (1 nodes): `ArchiveNoteUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 162`** (1 nodes): `SyncPendingNotesUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 163`** (2 nodes): `_LinkedJobsList`, `NoteDetailScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 164`** (2 nodes): `NoteCard`, `_TagChip`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 165`** (1 nodes): `ReminderThresholds`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 166`** (1 nodes): `DeleteNoteLinkUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 167`** (2 nodes): `NoteJobLinkScreen`, `_NoteJobLinkScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 168`** (1 nodes): `PermissionsScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 169`** (1 nodes): `DeleteServiceTypeUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 170`** (1 nodes): `SeedDefaultServiceTypesUseCase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 171`** (1 nodes): `GetProfileUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 172`** (1 nodes): `ShareProfileUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 173`** (1 nodes): `UpdateProfileUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 174`** (1 nodes): `UserModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 175`** (1 nodes): `UserEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 176`** (1 nodes): `LandingScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 177`** (1 nodes): `MinVersionGateScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 178`** (1 nodes): `AuthHeader`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 179`** (1 nodes): `NameStepView`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 180`** (1 nodes): `OnboardingBottomBar`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 181`** (1 nodes): `OnboardingStepIndicator`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 182`** (1 nodes): `CustomerModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 183`** (1 nodes): `CustomerAuditEntryEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 184`** (1 nodes): `CustomerEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 185`** (1 nodes): `KeyCodeEntryEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 186`** (1 nodes): `GetCustomersUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 187`** (1 nodes): `CustomerCard`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 188`** (1 nodes): `DashboardScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 189`** (1 nodes): `CorrectionRequestEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 190`** (1 nodes): `FollowUpEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 191`** (1 nodes): `InventoryItemEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 192`** (1 nodes): `JobAuditEntryEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 193`** (1 nodes): `JobEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 194`** (1 nodes): `JobExpenseEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 195`** (1 nodes): `JobHardwareEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 196`** (1 nodes): `JobPartEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 197`** (1 nodes): `JobPhotoEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 198`** (1 nodes): `JobServiceEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 199`** (1 nodes): `JobTemplateEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 200`** (1 nodes): `KnowledgeNoteEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 201`** (1 nodes): `NoteJobLinkEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 202`** (1 nodes): `ProfileEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 203`** (1 nodes): `RecurringScheduleEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 204`** (1 nodes): `ReminderEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 205`** (1 nodes): `RestockEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 206`** (1 nodes): `ServiceTypeEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 207`** (1 nodes): `StockAdjustmentEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 208`** (1 nodes): `HubScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 209`** (1 nodes): `InventoryItemModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 210`** (1 nodes): `RestockModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 211`** (1 nodes): `StockAdjustmentModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 212`** (1 nodes): `CorrectionRequestModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 213`** (1 nodes): `JobAuditEntryModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 214`** (1 nodes): `JobExpenseModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 215`** (1 nodes): `JobHardwareModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 216`** (1 nodes): `JobModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 217`** (1 nodes): `JobPartModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 218`** (1 nodes): `JobPhotoModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 219`** (1 nodes): `JobServiceModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 220`** (1 nodes): `ServiceTypePicker`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 221`** (1 nodes): `JobTemplateModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 222`** (1 nodes): `GetKeyCodesUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 223`** (1 nodes): `KnowledgeNoteModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 224`** (1 nodes): `GetNotesUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 225`** (1 nodes): `FollowUpModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 226`** (1 nodes): `ProfileModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 227`** (1 nodes): `ReminderModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 228`** (1 nodes): `Reminder`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 229`** (1 nodes): `ServiceTypeModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 230`** (1 nodes): `GetLinksForJobUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 231`** (1 nodes): `GetLinksForNoteUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 232`** (1 nodes): `ProfileScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 233`** (1 nodes): `GetServiceTypesUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 234`** (1 nodes): `ServiceTypePickerV2`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `TimelineEvent`, `TimelineState`, `TimelineNotifier` to the rest of the system?**
  _402 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Analytics Screen Widgets` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `Job Providers & Notifiers` be split into smaller, more focused modules?**
  _Cohesion score 0.09 - nodes in this community are weakly interconnected._
- **Should `Notes Providers & Notifiers` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `Log Job Screen` be split into smaller, more focused modules?**
  _Cohesion score 0.11 - nodes in this community are weakly interconnected._
- **Should `Customer Providers & Notifiers` be split into smaller, more focused modules?**
  _Cohesion score 0.11 - nodes in this community are weakly interconnected._
- **Should `Job List Screen UI` be split into smaller, more focused modules?**
  _Cohesion score 0.11 - nodes in this community are weakly interconnected._