# Graph Report - projects/keystone  (2026-05-21)

## Corpus Check
- Large corpus: 477 files · ~232,418 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder, or use --no-semantic to run AST-only.

## Summary
- 2035 nodes · 2421 edges · 337 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output


## Input Scope
- Requested: auto
- Resolved: committed (source: default-auto)
- Included files: 477 · Candidates: 779
- Excluded: 0 untracked · 7576 ignored · 5 sensitive · 0 missing committed
- Recommendation: Use --scope all or graphify.yaml inputs.corpus for a knowledge-base folder.

## Graph Freshness
- Built from Git commit: `c55b306`
- Compare this hash to `git rev-parse HEAD` before trusting freshness-sensitive graph output.
## God Nodes (most connected - your core abstractions)
1. `public.users` - 8 edges
2. `public.jobs` - 6 edges
3. `auth.users` - 6 edges
4. `ONLY` - 5 edges
5. `public.jobs` - 5 edges
6. `KeyCodeEntryModel` - 4 edges
7. `NoteJobLinkModel` - 4 edges
8. `public.key_code_history` - 4 edges
9. `auth.users` - 4 edges
10. `public.jobs` - 4 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "Community 0"
Cohesion: 0.08
Nodes (19): _applyTemplate(), _confirmDiscard(), dispose(), _ExpenseRow, _HardwareRow, _inferMediaType(), initState(), _ItemRow (+11 more)

### Community 1 - "Community 1"
Cohesion: 0.15
Nodes (24): _AnalyticsBody, AnalyticsScreen, _CustomerRetentionSection, _DayOfWeekSection, _EmptyRow, _ErrorView, _ExpenseBreakdownSection, _ExpenseRow (+16 more)

### Community 2 - "Community 2"
Cohesion: 0.16
Nodes (22): addJob(), AdminRequestsNotifier, approve(), archive(), clearFilters(), CustomerHistorySuggestions, dispose(), JobDetailData (+14 more)

### Community 3 - "Community 3"
Cohesion: 0.18
Nodes (19): addNote(), AddNoteNotifier, AddNoteState, archiveNote(), dispose(), EditNoteNotifier, EditNoteState, filterByCategory() (+11 more)

### Community 4 - "Community 4"
Cohesion: 0.2
Nodes (17): addCustomer(), AddCustomerNotifier, AddCustomerState, CustomerListNotifier, CustomerListState, decrementJobCount(), dispose(), incrementJobCount() (+9 more)

### Community 5 - "Community 5"
Cohesion: 0.16
Nodes (14): _bulkArchive(), _bulkExport(), dispose(), _FilterSection, _FilterSectionDynamic, initState(), _JobFilterSheet, _JobFilterSheetState (+6 more)

### Community 6 - "Community 6"
Cohesion: 0.2
Nodes (15): archiveJob(), createJob(), editJob(), _getFieldValue(), _getInternalUserId(), getJobById(), JobRepositoryImpl, saveExpenses() (+7 more)

### Community 7 - "Community 7"
Cohesion: 0.13
Nodes (1): InternalAuthService

### Community 8 - "Community 8"
Cohesion: 0.13
Nodes (1): SecureVaultService

### Community 9 - "Community 9"
Cohesion: 0.21
Nodes (11): _addHardwareItem(), _addServiceItem(), EditJobScreen, _EditJobScreenState, _initFromJob(), _loadHardware(), _loadParts(), _loadServices() (+3 more)

### Community 10 - "Community 10"
Cohesion: 0.23
Nodes (14): _addPhoto(), _AudioPlayerWidget, _AudioPlayerWidgetState, _deletePhoto(), dispose(), _formatChanges(), _formatDuration(), initState() (+6 more)

### Community 11 - "Community 11"
Cohesion: 0.25
Nodes (13): archiveJob(), createJob(), editJob(), getJobById(), JobRepository, saveExpenses(), saveHardwareItems(), saveParts() (+5 more)

### Community 12 - "Community 12"
Cohesion: 0.26
Nodes (12): AuthNotifier, AuthUiState, bypassOtp(), clearError(), completeOnboarding(), logout(), requestOtp(), reset() (+4 more)

### Community 13 - "Community 13"
Cohesion: 0.14
Nodes (13): MockAuthRepository, MockConnectivityService, MockCustomerRepository, MockFollowUpRepository, MockJobLocalDatasource, MockJobRemoteDatasource, MockJobRepository, MockKnowledgeNoteRepository (+5 more)

### Community 14 - "Community 14"
Cohesion: 0.31
Nodes (13): public.activity_events, public.customer_audit_entries, public.customers, public.job_audit_log, public.job_parts, public.job_photos, public.jobs, public.key_code_history (+5 more)

### Community 15 - "Community 15"
Cohesion: 0.28
Nodes (11): AnalyticsNotifier, _DowAccumulator, _LeadAccumulator, loadAnalytics(), _PartsAccumulator, reset(), setCustomRange(), setPeriod() (+3 more)

### Community 16 - "Community 16"
Cohesion: 0.22
Nodes (8): _CustomerFilterSheet, _CustomerFilterSheetState, CustomerListScreen, _CustomerListScreenState, dispose(), initState(), _onTabTapped(), _showFilterSheet()

### Community 17 - "Community 17"
Cohesion: 0.27
Nodes (10): _confirmDelete(), dispose(), initState(), InventoryScreen, _InventoryScreenState, _loadItems(), _showHistoryDialog(), _showItemDialog() (+2 more)

### Community 18 - "Community 18"
Cohesion: 0.15
Nodes (4): _ErrorBoundary, _ErrorBoundaryState, KeystoneApp, _KeystoneAppState

### Community 19 - "Community 19"
Cohesion: 0.15
Nodes (2): CloudinaryConfig, CloudinaryService

### Community 20 - "Community 20"
Cohesion: 0.28
Nodes (11): _CustomerTile, dispose(), initState(), _JobTile, _NoResults, _NoteTile, _Results, _SearchHint (+3 more)

### Community 21 - "Community 21"
Cohesion: 0.3
Nodes (10): AnalyticsState, DayOfWeekData, ExpenseCategoryBreakdown, LeadSourceBreakdown, PartsUsage, PaymentHealthData, _pct(), RevenueTrendPoint (+2 more)

### Community 22 - "Community 22"
Cohesion: 0.3
Nodes (10): _confirmDiscard(), dispose(), EditProfileScreen, _EditProfileScreenState, _initFromProfile(), initState(), _listEquals(), _onPickPhoto() (+2 more)

### Community 23 - "Community 23"
Cohesion: 0.33
Nodes (9): AddCustomerScreen, _AddCustomerScreenState, _checkDuplicate(), _confirmDiscard(), dispose(), initState(), _nextStep(), _onSave() (+1 more)

### Community 24 - "Community 24"
Cohesion: 0.33
Nodes (9): _confirmDelete(), CustomerDetailScreen, _CustomerDetailScreenState, dispose(), initState(), _KeyCodesTab, _leadSourceLabel(), _PropertyBadge (+1 more)

### Community 25 - "Community 25"
Cohesion: 0.33
Nodes (9): addItem(), adjustStock(), archiveItem(), deleteItem(), InventoryNotifier, loadItems(), restockItem(), unarchiveItem() (+1 more)

### Community 26 - "Community 26"
Cohesion: 0.25
Nodes (7): dispose(), initState(), _NotesFilterSheet, _NotesFilterSheetState, NotesListScreen, _NotesListScreenState, _showFilterSheet()

### Community 27 - "Community 27"
Cohesion: 0.18
Nodes (1): RouteNames

### Community 28 - "Community 28"
Cohesion: 0.27
Nodes (10): auth.users, if, ONLY, public.app_events, public.customers, public.follow_ups, public.jobs, public.knowledge_notes (+2 more)

### Community 29 - "Community 29"
Cohesion: 0.36
Nodes (8): createCustomer(), CustomerRepositoryImpl, deleteCustomer(), getCustomerById(), getCustomerByPhone(), mergeCustomers(), syncPendingCustomers(), updateCustomer()

### Community 30 - "Community 30"
Cohesion: 0.36
Nodes (8): createCustomer(), CustomerRepository, deleteCustomer(), getCustomerById(), getCustomerByPhone(), mergeCustomers(), syncPendingCustomers(), updateCustomer()

### Community 31 - "Community 31"
Cohesion: 0.36
Nodes (8): AddNoteScreen, _AddNoteScreenState, _confirmDiscard(), dispose(), initState(), _nextStep(), _onSave(), _previousStep()

### Community 32 - "Community 32"
Cohesion: 0.47
Nodes (9): auth.users, public.app_events, public.correction_requests, public.customers, public.follow_ups, public.jobs, public.knowledge_notes, public.profiles (+1 more)

### Community 33 - "Community 33"
Cohesion: 0.2
Nodes (9): atApiKey, atUsername, code, expiresAt, firstOfMonth, now, { phone }, RequestBody (+1 more)

### Community 34 - "Community 34"
Cohesion: 0.39
Nodes (7): _DateLabel, _EmptyState, _EventList, _EventTile, _sameDay(), TimelineScreen, _timeString()

### Community 35 - "Community 35"
Cohesion: 0.39
Nodes (7): BiometricEnrollPage, BiometricEnrollSheet, dispose(), enrollPin(), _OptionTile, _PinSetupDialog, _PinSetupDialogState

### Community 36 - "Community 36"
Cohesion: 0.39
Nodes (7): dispose(), initState(), OnboardingScreen, _OnboardingScreenState, _onContinue(), _onNameChanged(), _toggleService()

### Community 37 - "Community 37"
Cohesion: 0.39
Nodes (7): dispose(), initState(), _onDelete(), _onDigit(), PinEntryScreen, _PinEntryScreenState, _verifyPin()

### Community 38 - "Community 38"
Cohesion: 0.39
Nodes (7): _complete(), dispose(), _next(), SetupScreen, _SetupScreenState, _StepIndicator, _StepView

### Community 39 - "Community 39"
Cohesion: 0.39
Nodes (7): dispose(), initState(), _onSkip(), _onUpgrade(), UpgradeAccountScreen, _UpgradeAccountScreenState, _upgradeWasActuallyApplied()

### Community 40 - "Community 40"
Cohesion: 0.39
Nodes (7): dispose(), initState(), _loadCustomers(), MergeCustomerSheet, _MergeCustomerSheetState, _onSearch(), _selectSource()

### Community 41 - "Community 41"
Cohesion: 0.39
Nodes (7): cascadeCustomerId(), cascadeJobId(), deleteJob(), getJob(), JobLocalDatasource, saveJob(), updateSyncStatus()

### Community 42 - "Community 42"
Cohesion: 0.39
Nodes (7): createProfile(), getProfile(), getProfileByPhone(), getPublicProfile(), ProfileRemoteDatasource, updateProfile(), uploadPhoto()

### Community 43 - "Community 43"
Cohesion: 0.39
Nodes (7): adjustStock(), createItem(), deleteItem(), InventoryRepositoryImpl, restockItem(), syncItems(), updateItem()

### Community 44 - "Community 44"
Cohesion: 0.39
Nodes (7): adjustStock(), createItem(), deleteItem(), InventoryRepository, restockItem(), syncItems(), updateItem()

### Community 45 - "Community 45"
Cohesion: 0.39
Nodes (7): create(), delete(), KeyCodeNotifier, KeyCodeState, loadForCustomer(), reset(), update()

### Community 46 - "Community 46"
Cohesion: 0.39
Nodes (7): _confirmDiscard(), dispose(), EditNoteScreen, _EditNoteScreenState, _initFrom(), _onSave(), _pickPhoto()

### Community 47 - "Community 47"
Cohesion: 0.22
Nodes (1): DataExportService

### Community 48 - "Community 48"
Cohesion: 0.22
Nodes (6): for, KsFilterChip, KsFilterChipGroup, KsFilterOption, KsFilterSheet, _KsFilterSheetState

### Community 49 - "Community 49"
Cohesion: 0.39
Nodes (7): createServiceType(), deleteServiceType(), loadServiceTypes(), reset(), ServiceTypeNotifier, updateServiceType(), updateServiceTypePrice()

### Community 50 - "Community 50"
Cohesion: 0.39
Nodes (7): createProfile(), getProfile(), getProfileByPhone(), getPublicProfile(), ProfileRepositoryImpl, updateProfile(), uploadPhoto()

### Community 51 - "Community 51"
Cohesion: 0.39
Nodes (7): createProfile(), getProfile(), getProfileByPhone(), getPublicProfile(), ProfileRepository, updateProfile(), uploadPhoto()

### Community 52 - "Community 52"
Cohesion: 0.39
Nodes (7): FollowUpButton, _FollowUpButtonState, initState(), _openWhatsApp(), _resendFollowUp(), _sendFollowUp(), _StatusChip

### Community 53 - "Community 53"
Cohesion: 0.43
Nodes (6): AuthRemoteDatasource, createUser(), getCurrentUser(), logout(), requestOtp(), verifyOtp()

### Community 54 - "Community 54"
Cohesion: 0.43
Nodes (6): AuthRepositoryImpl, createUser(), getCurrentUser(), requestOtp(), signOut(), verifyOtp()

### Community 55 - "Community 55"
Cohesion: 0.43
Nodes (6): AuthRepository, createUser(), getCurrentUser(), requestOtp(), signOut(), verifyOtp()

### Community 56 - "Community 56"
Cohesion: 0.43
Nodes (6): dispose(), initState(), _onVerify(), OtpVerifyScreen, _OtpVerifyScreenState, _startCooldown()

### Community 57 - "Community 57"
Cohesion: 0.43
Nodes (6): initState(), _onContinue(), _onDevBypass(), _onPhoneChanged(), PhoneEntryScreen, _PhoneEntryScreenState

### Community 58 - "Community 58"
Cohesion: 0.43
Nodes (6): dispose(), FadeInDelayed, _FadeInDelayedState, initState(), TransitionScreen, _TransitionScreenState

### Community 59 - "Community 59"
Cohesion: 0.43
Nodes (6): clear(), deleteItem(), getById(), InventoryLocalDatasource, saveAll(), saveItem()

### Community 60 - "Community 60"
Cohesion: 0.25
Nodes (1): PinService

### Community 61 - "Community 61"
Cohesion: 0.43
Nodes (6): createKeyCode(), _decrypt(), deleteKeyCode(), _encrypt(), KeyCodeRepositoryImpl, updateKeyCode()

### Community 62 - "Community 62"
Cohesion: 0.43
Nodes (6): archiveNote(), createNote(), getNoteById(), KnowledgeNoteRepositoryImpl, syncPendingNotes(), updateNote()

### Community 63 - "Community 63"
Cohesion: 0.43
Nodes (6): archiveNote(), createNote(), getNoteById(), KnowledgeNoteRepository, syncPendingNotes(), updateNote()

### Community 64 - "Community 64"
Cohesion: 0.25
Nodes (5): InvoiceData, InvoiceHardware, InvoicePart, InvoicePdfGenerator, InvoiceService

### Community 65 - "Community 65"
Cohesion: 0.25
Nodes (2): PendingMediaUpload, PendingMediaUploadService

### Community 66 - "Community 66"
Cohesion: 0.25
Nodes (1): HiveService

### Community 67 - "Community 67"
Cohesion: 0.25
Nodes (1): DateFormatter

### Community 68 - "Community 68"
Cohesion: 0.43
Nodes (6): createLink(), deleteLink(), loadForJob(), loadForNote(), NoteLinkNotifier, reset()

### Community 69 - "Community 69"
Cohesion: 0.43
Nodes (6): clear(), dispose(), _runSearch(), search(), SearchNotifier, SearchResults

### Community 70 - "Community 70"
Cohesion: 0.43
Nodes (6): load(), ProfileNotifier, ProfileState, shareProfile(), update(), uploadPhoto()

### Community 71 - "Community 71"
Cohesion: 0.43
Nodes (6): buildPreview(), FollowUpNotifier, FollowUpState, reset(), send(), updateStatus()

### Community 72 - "Community 72"
Cohesion: 0.5
Nodes (7): auth.users, public.job_audit_log, public.job_parts, public.jobs, public.knowledge_notes, public.note_job_links, public.service_types

### Community 73 - "Community 73"
Cohesion: 0.25
Nodes (6): _FakeUser, MockCustomerLocal, MockCustomerRemote, MockGoTrueClient, MockJobLocal, MockSupabaseClient

### Community 74 - "Community 74"
Cohesion: 0.48
Nodes (5): _buildDescription(), load(), TimelineEvent, TimelineNotifier, TimelineState

### Community 75 - "Community 75"
Cohesion: 0.48
Nodes (5): dispose(), ForgotAccessScreen, _ForgotAccessScreenState, initState(), _onSendCode()

### Community 76 - "Community 76"
Cohesion: 0.48
Nodes (5): CustomerLocalDatasource, deleteCustomer(), getCustomer(), saveCustomer(), tombstoneCustomer()

### Community 77 - "Community 77"
Cohesion: 0.48
Nodes (5): createCustomer(), CustomerRemoteDatasource, deleteCustomer(), getCustomerById(), updateCustomer()

### Community 78 - "Community 78"
Cohesion: 0.48
Nodes (5): dispose(), EditCustomerScreen, _EditCustomerScreenState, _initFrom(), _onSave()

### Community 79 - "Community 79"
Cohesion: 0.48
Nodes (5): ContactImportSheet, _ContactImportSheetState, _importSelected(), initState(), _loadContacts()

### Community 80 - "Community 80"
Cohesion: 0.48
Nodes (5): deleteExpense(), deleteExpensesForJob(), JobExpensesLocalDatasource, saveAll(), saveExpense()

### Community 81 - "Community 81"
Cohesion: 0.48
Nodes (5): deleteHardware(), deleteHardwareForJob(), JobHardwareLocalDatasource, saveAll(), saveHardware()

### Community 82 - "Community 82"
Cohesion: 0.48
Nodes (5): deletePart(), deletePartsForJob(), JobPartsLocalDatasource, saveAll(), savePart()

### Community 83 - "Community 83"
Cohesion: 0.48
Nodes (5): deleteService(), deleteServicesForJob(), JobServicesLocalDatasource, saveAll(), saveService()

### Community 84 - "Community 84"
Cohesion: 0.48
Nodes (5): deleteNote(), KnowledgeNoteLocalDatasource, saveNote(), saveNotes(), updateSyncStatus()

### Community 85 - "Community 85"
Cohesion: 0.48
Nodes (5): clear(), deleteServiceType(), saveServiceType(), saveServiceTypes(), ServiceTypeLocalDatasource

### Community 86 - "Community 86"
Cohesion: 0.48
Nodes (5): Function(), initState(), JobTemplatesScreen, _JobTemplatesScreenState, _showSaveDialog()

### Community 87 - "Community 87"
Cohesion: 0.48
Nodes (5): dispose(), EditKeyCodeScreen, _EditKeyCodeScreenState, initState(), _onSave()

### Community 88 - "Community 88"
Cohesion: 0.48
Nodes (5): _addTag(), dispose(), _TagChip, TagInputField, _TagInputFieldState

### Community 89 - "Community 89"
Cohesion: 0.29
Nodes (2): AuthNotifier, AuthState

### Community 90 - "Community 90"
Cohesion: 0.48
Nodes (5): createReminder(), dismissReminder(), ReminderRepositoryImpl, resolveReminder(), snoozeReminder()

### Community 91 - "Community 91"
Cohesion: 0.48
Nodes (5): createReminder(), dismissReminder(), ReminderRepository, resolveReminder(), snoozeReminder()

### Community 92 - "Community 92"
Cohesion: 0.48
Nodes (5): _compute(), dismiss(), refresh(), RemindersNotifier, RemindersState

### Community 93 - "Community 93"
Cohesion: 0.48
Nodes (5): createServiceType(), deleteServiceType(), ServiceTypeRepositoryImpl, syncServiceTypes(), updateServiceType()

### Community 94 - "Community 94"
Cohesion: 0.48
Nodes (5): createServiceType(), deleteServiceType(), ServiceTypeRepository, syncServiceTypes(), updateServiceType()

### Community 95 - "Community 95"
Cohesion: 0.43
Nodes (4): dispose(), initState(), PricingScreen, _PricingScreenState

### Community 96 - "Community 96"
Cohesion: 0.48
Nodes (5): ServiceTypesScreen, _ServiceTypeTile, _showAddDialog(), _showDeleteConfirm(), _showEditDialog()

### Community 97 - "Community 97"
Cohesion: 0.48
Nodes (5): createFollowUp(), FollowUpRepositoryImpl, getFollowUpByJobId(), updateJobId(), updateResponseStatus()

### Community 98 - "Community 98"
Cohesion: 0.48
Nodes (5): createFollowUp(), FollowUpRepository, getFollowUpByJobId(), updateJobId(), updateResponseStatus()

### Community 99 - "Community 99"
Cohesion: 0.52
Nodes (6): public.customer_audit_entries, public.customers, public.job_photos, public.jobs, public.reminders, public.users

### Community 100 - "Community 100"
Cohesion: 0.52
Nodes (6): auth.users, public.customers, public.follow_ups, public.inventory_restocks, public.inventory_stock_adjustments, public.jobs

### Community 101 - "Community 101"
Cohesion: 0.53
Nodes (4): _doInitialSync(), InitialSyncScreen, _InitialSyncScreenState, initState()

### Community 102 - "Community 102"
Cohesion: 0.53
Nodes (4): _skipProceed(), StaleDataScreen, _StaleDataScreenState, _verify()

### Community 103 - "Community 103"
Cohesion: 0.33
Nodes (2): DashboardScreen, _DashboardScreenState

### Community 104 - "Community 104"
Cohesion: 0.53
Nodes (4): cascadeJobId(), FollowUpLocalDatasource, saveFollowUp(), updateResponseStatus()

### Community 105 - "Community 105"
Cohesion: 0.53
Nodes (4): createFollowUp(), FollowUpRemoteDatasource, getFollowUpByJobId(), updateResponseStatus()

### Community 106 - "Community 106"
Cohesion: 0.53
Nodes (4): create(), delete(), InventoryRemoteDatasource, update()

### Community 107 - "Community 107"
Cohesion: 0.53
Nodes (4): deleteForItem(), InventoryRestocksLocalDatasource, save(), saveAll()

### Community 108 - "Community 108"
Cohesion: 0.53
Nodes (4): deleteForItem(), InventoryStockAdjustmentsLocalDatasource, save(), saveAll()

### Community 109 - "Community 109"
Cohesion: 0.53
Nodes (4): deletePhoto(), deletePhotosForJob(), JobPhotosLocalDatasource, savePhoto()

### Community 110 - "Community 110"
Cohesion: 0.53
Nodes (4): createPhotoRecord(), deletePhoto(), JobPhotosRemoteDatasource, uploadMedia()

### Community 111 - "Community 111"
Cohesion: 0.53
Nodes (4): createJob(), fetchServerUpdatedAt(), JobRemoteDatasource, updateJob()

### Community 112 - "Community 112"
Cohesion: 0.53
Nodes (4): clear(), deleteTemplate(), JobTemplateLocalDatasource, saveTemplate()

### Community 113 - "Community 113"
Cohesion: 0.53
Nodes (4): create(), delete(), KeyCodeRemoteDatasource, update()

### Community 114 - "Community 114"
Cohesion: 0.53
Nodes (4): archiveNote(), createNote(), KnowledgeNoteRemoteDatasource, updateNote()

### Community 115 - "Community 115"
Cohesion: 0.53
Nodes (4): clearProfile(), getProfile(), ProfileLocalDatasource, saveProfile()

### Community 116 - "Community 116"
Cohesion: 0.53
Nodes (4): createServiceType(), deleteServiceType(), ServiceTypeRemoteDatasource, updateServiceType()

### Community 117 - "Community 117"
Cohesion: 0.33
Nodes (5): authHeaders, dbPhone, existing, sessionData, tempPassword

### Community 118 - "Community 118"
Cohesion: 0.33
Nodes (1): BiometricService

### Community 119 - "Community 119"
Cohesion: 0.53
Nodes (4): approveRequest(), CorrectionRequestRepositoryImpl, createRequest(), rejectRequest()

### Community 120 - "Community 120"
Cohesion: 0.53
Nodes (4): approveRequest(), CorrectionRequestRepository, createRequest(), rejectRequest()

### Community 121 - "Community 121"
Cohesion: 0.53
Nodes (4): AdminRequestsScreen, _RequestCard, _showApproveDialog(), _showRejectDialog()

### Community 122 - "Community 122"
Cohesion: 0.53
Nodes (4): deleteTemplate(), JobTemplateNotifier, loadTemplates(), saveTemplate()

### Community 123 - "Community 123"
Cohesion: 0.53
Nodes (4): createKeyCode(), deleteKeyCode(), KeyCodeRepository, updateKeyCode()

### Community 124 - "Community 124"
Cohesion: 0.53
Nodes (4): _confirmDelete(), KeyCodesScreen, _KeyCodeTile, _openEdit()

### Community 125 - "Community 125"
Cohesion: 0.33
Nodes (5): UnlockLocked, UnlockNeedsNetwork, UnlockNeedsOnline, UnlockResult, UnlockSuccess

### Community 126 - "Community 126"
Cohesion: 0.33
Nodes (1): LocalNotificationService

### Community 127 - "Community 127"
Cohesion: 0.33
Nodes (2): KsSearchBar, _KsSearchBarState

### Community 128 - "Community 128"
Cohesion: 0.33
Nodes (2): PrivacyOverlay, _PrivacyOverlayState

### Community 129 - "Community 129"
Cohesion: 0.53
Nodes (4): add(), delete(), load(), RecurringScheduleNotifier

### Community 130 - "Community 130"
Cohesion: 0.53
Nodes (4): _callPhone(), _openWhatsApp(), PublicProfileScreen, _serviceLabel()

### Community 131 - "Community 131"
Cohesion: 0.53
Nodes (4): dispose(), EditableFollowUpNotifier, EditableFollowUpState, initialize()

### Community 132 - "Community 132"
Cohesion: 0.33
Nodes (4): MockPostgrestFilterBuilder, MockPostgrestTransformBuilder, MockSupabaseClient, MockSupabaseQueryBuilder

### Community 133 - "Community 133"
Cohesion: 0.33
Nodes (5): atApiKey, atUsername, body, otp, phone

### Community 134 - "Community 134"
Cohesion: 0.6
Nodes (3): call(), RequestOtpParams, RequestOtpUsecase

### Community 135 - "Community 135"
Cohesion: 0.6
Nodes (3): call(), VerifyOtpParams, VerifyOtpUsecase

### Community 136 - "Community 136"
Cohesion: 0.6
Nodes (3): LockedScreen, _LockedScreenState, _retryConnection()

### Community 137 - "Community 137"
Cohesion: 0.4
Nodes (1): KeyCodeEntryModel

### Community 138 - "Community 138"
Cohesion: 0.6
Nodes (3): call(), CreateCustomerParams, CreateCustomerUsecase

### Community 139 - "Community 139"
Cohesion: 0.6
Nodes (3): call(), MergeCustomersParams, MergeCustomersUsecase

### Community 140 - "Community 140"
Cohesion: 0.6
Nodes (3): call(), UpdateCustomerParams, UpdateCustomerUsecase

### Community 141 - "Community 141"
Cohesion: 0.6
Nodes (3): JobAuditLocalDatasource, saveAll(), saveEntry()

### Community 142 - "Community 142"
Cohesion: 0.6
Nodes (3): insertAll(), insertEntry(), JobAuditRemoteDatasource

### Community 143 - "Community 143"
Cohesion: 0.6
Nodes (3): createExpense(), deleteExpense(), JobExpensesRemoteDatasource

### Community 144 - "Community 144"
Cohesion: 0.6
Nodes (3): createHardware(), deleteHardware(), JobHardwareRemoteDatasource

### Community 145 - "Community 145"
Cohesion: 0.6
Nodes (3): createPart(), deletePart(), JobPartsRemoteDatasource

### Community 146 - "Community 146"
Cohesion: 0.6
Nodes (3): createService(), deleteService(), JobServicesRemoteDatasource

### Community 147 - "Community 147"
Cohesion: 0.6
Nodes (3): delete(), KeyCodeLocalDatasource, save()

### Community 148 - "Community 148"
Cohesion: 0.6
Nodes (3): delete(), NoteLinkLocalDatasource, save()

### Community 149 - "Community 149"
Cohesion: 0.6
Nodes (3): create(), delete(), NoteLinkRemoteDatasource

### Community 150 - "Community 150"
Cohesion: 0.6
Nodes (3): delete(), RecurringScheduleLocalDatasource, save()

### Community 151 - "Community 151"
Cohesion: 0.6
Nodes (3): call(), CreateInventoryItemParams, CreateInventoryItemUsecase

### Community 152 - "Community 152"
Cohesion: 0.6
Nodes (3): call(), DeleteInventoryItemParams, DeleteInventoryItemUsecase

### Community 153 - "Community 153"
Cohesion: 0.6
Nodes (3): call(), UpdateInventoryItemParams, UpdateInventoryItemUsecase

### Community 154 - "Community 154"
Cohesion: 0.6
Nodes (3): call(), EditJobParams, EditJobUsecase

### Community 155 - "Community 155"
Cohesion: 0.6
Nodes (3): call(), LogJobParams, LogJobUsecase

### Community 156 - "Community 156"
Cohesion: 0.6
Nodes (3): call(), LogJobWithCustomerParams, LogJobWithCustomerUsecase

### Community 157 - "Community 157"
Cohesion: 0.6
Nodes (3): call(), RequestCorrectionParams, RequestCorrectionUsecase

### Community 158 - "Community 158"
Cohesion: 0.6
Nodes (3): call(), UpdateJobParams, UpdateJobUsecase

### Community 159 - "Community 159"
Cohesion: 0.6
Nodes (3): call(), UpdatePaymentStatusParams, UpdatePaymentStatusUsecase

### Community 160 - "Community 160"
Cohesion: 0.6
Nodes (3): _CustomBadge, JobCard, _serviceLabel()

### Community 161 - "Community 161"
Cohesion: 0.6
Nodes (3): deleteTemplate(), JobTemplateRepositoryImpl, saveTemplate()

### Community 162 - "Community 162"
Cohesion: 0.6
Nodes (3): deleteTemplate(), JobTemplateRepository, saveTemplate()

### Community 163 - "Community 163"
Cohesion: 0.6
Nodes (3): call(), CreateKeyCodeParams, CreateKeyCodeUsecase

### Community 164 - "Community 164"
Cohesion: 0.4
Nodes (1): NoteJobLinkModel

### Community 165 - "Community 165"
Cohesion: 0.6
Nodes (3): call(), CreateNoteParams, CreateNoteUsecase

### Community 166 - "Community 166"
Cohesion: 0.6
Nodes (3): call(), UpdateNoteParams, UpdateNoteUsecase

### Community 167 - "Community 167"
Cohesion: 0.4
Nodes (2): StaggeredFadeIn, _StaggeredFadeInState

### Community 168 - "Community 168"
Cohesion: 0.4
Nodes (1): DemoDataService

### Community 169 - "Community 169"
Cohesion: 0.4
Nodes (3): NoParams, NoParamsUseCase, UseCase

### Community 170 - "Community 170"
Cohesion: 0.4
Nodes (2): CurrencyFormatter, CurrencyInputFormatter

### Community 171 - "Community 171"
Cohesion: 0.4
Nodes (1): PhoneFormatter

### Community 172 - "Community 172"
Cohesion: 0.4
Nodes (2): KsSkeletonLoader, _KsSkeletonLoaderState

### Community 173 - "Community 173"
Cohesion: 0.6
Nodes (3): createLink(), deleteLink(), NoteLinkRepositoryImpl

### Community 174 - "Community 174"
Cohesion: 0.6
Nodes (3): createLink(), deleteLink(), NoteLinkRepository

### Community 175 - "Community 175"
Cohesion: 0.6
Nodes (3): call(), CreateNoteLinkParams, CreateNoteLinkUsecase

### Community 176 - "Community 176"
Cohesion: 0.6
Nodes (3): initState(), RecurringSchedulesScreen, _RecurringSchedulesScreenState

### Community 177 - "Community 177"
Cohesion: 0.6
Nodes (3): initState(), ReminderSettingsScreen, _ReminderSettingsScreenState

### Community 178 - "Community 178"
Cohesion: 0.6
Nodes (3): _EmptyState, _ReminderCard, RemindersScreen

### Community 179 - "Community 179"
Cohesion: 0.6
Nodes (3): call(), CreateServiceTypeParams, CreateServiceTypeUsecase

### Community 180 - "Community 180"
Cohesion: 0.6
Nodes (3): call(), UpdateServiceTypeParams, UpdateServiceTypeUsecase

### Community 181 - "Community 181"
Cohesion: 0.6
Nodes (3): BuildFollowupMessageParams, BuildFollowupMessageUsecase, call()

### Community 182 - "Community 182"
Cohesion: 0.6
Nodes (3): call(), SendFollowupParams, SendFollowupUsecase

### Community 183 - "Community 183"
Cohesion: 0.6
Nodes (3): FollowUpMessagePreview, _FollowUpMessagePreviewState, initState()

### Community 184 - "Community 184"
Cohesion: 0.7
Nodes (4): auth.users, public.customers, public.jobs, public.key_code_history

### Community 185 - "Community 185"
Cohesion: 0.8
Nodes (4): auth.users, public.inventory_items, public.inventory_restocks, public.inventory_stock_adjustments

### Community 186 - "Community 186"
Cohesion: 0.4
Nodes (2): MockSupabaseClient, _TestServiceTypeNotifier

### Community 187 - "Community 187"
Cohesion: 0.67
Nodes (2): call(), LogoutUsecase

### Community 188 - "Community 188"
Cohesion: 0.5
Nodes (1): WhatsAppConstants

### Community 189 - "Community 189"
Cohesion: 0.67
Nodes (2): call(), DeleteCustomerUsecase

### Community 190 - "Community 190"
Cohesion: 0.67
Nodes (2): call(), GetCustomerByPhoneUsecase

### Community 191 - "Community 191"
Cohesion: 0.67
Nodes (2): call(), GetCustomerUsecase

### Community 192 - "Community 192"
Cohesion: 0.67
Nodes (2): call(), SyncOfflineCustomersUsecase

### Community 193 - "Community 193"
Cohesion: 0.67
Nodes (2): create(), InventoryRestocksRemoteDatasource

### Community 194 - "Community 194"
Cohesion: 0.67
Nodes (2): create(), InventoryStockAdjustmentsRemoteDatasource

### Community 195 - "Community 195"
Cohesion: 0.5
Nodes (2): MockConnectivityService, MockSupabaseClient

### Community 196 - "Community 196"
Cohesion: 0.67
Nodes (2): GetInventoryItemsParams, GetInventoryItemsUsecase

### Community 197 - "Community 197"
Cohesion: 0.67
Nodes (2): ArchiveJobUsecase, call()

### Community 198 - "Community 198"
Cohesion: 0.67
Nodes (2): call(), GetJobUsecase

### Community 199 - "Community 199"
Cohesion: 0.67
Nodes (2): GetJobsParams, GetJobsUsecase

### Community 200 - "Community 200"
Cohesion: 0.67
Nodes (2): call(), SyncOfflineJobsUsecase

### Community 201 - "Community 201"
Cohesion: 0.67
Nodes (2): call(), DeleteKeyCodeUsecase

### Community 202 - "Community 202"
Cohesion: 0.67
Nodes (2): call(), UpdateKeyCodeUsecase

### Community 203 - "Community 203"
Cohesion: 0.67
Nodes (2): ArchiveNoteUsecase, call()

### Community 204 - "Community 204"
Cohesion: 0.67
Nodes (2): call(), SyncPendingNotesUsecase

### Community 205 - "Community 205"
Cohesion: 0.67
Nodes (2): _LinkedJobsList, NoteDetailScreen

### Community 206 - "Community 206"
Cohesion: 0.67
Nodes (2): NoteCard, _TagChip

### Community 207 - "Community 207"
Cohesion: 0.5
Nodes (1): ThemeModeNotifier

### Community 208 - "Community 208"
Cohesion: 0.5
Nodes (2): ReceiptData, ReceiptPdfGenerator

### Community 209 - "Community 209"
Cohesion: 0.5
Nodes (1): MockDataGenerator

### Community 210 - "Community 210"
Cohesion: 0.67
Nodes (2): call(), DeleteNoteLinkUsecase

### Community 211 - "Community 211"
Cohesion: 0.67
Nodes (2): NoteJobLinkScreen, _NoteJobLinkScreenState

### Community 212 - "Community 212"
Cohesion: 0.67
Nodes (2): ReminderThresholds, save()

### Community 213 - "Community 213"
Cohesion: 0.67
Nodes (2): call(), DeleteServiceTypeUsecase

### Community 214 - "Community 214"
Cohesion: 0.67
Nodes (2): call(), SeedDefaultServiceTypesUseCase

### Community 215 - "Community 215"
Cohesion: 0.67
Nodes (2): call(), GetProfileUsecase

### Community 216 - "Community 216"
Cohesion: 0.67
Nodes (2): call(), ShareProfileUsecase

### Community 217 - "Community 217"
Cohesion: 0.67
Nodes (2): call(), UpdateProfileUsecase

### Community 218 - "Community 218"
Cohesion: 0.67
Nodes (2): PermissionsScreen, _save()

### Community 219 - "Community 219"
Cohesion: 0.5
Nodes (2): KeystoneWebLite, _WebGatewayScreen

### Community 220 - "Community 220"
Cohesion: 0.83
Nodes (3): public.correction_requests, public.jobs, public.users

### Community 221 - "Community 221"
Cohesion: 0.83
Nodes (3): public.job_hardware, public.job_services, public.jobs

### Community 222 - "Community 222"
Cohesion: 0.83
Nodes (3): auth.users, public.customers, public.recurring_job_schedules

### Community 223 - "Community 223"
Cohesion: 0.5
Nodes (2): MockKeyCodeLocal, MockKeyCodeRemote

### Community 224 - "Community 224"
Cohesion: 0.5
Nodes (2): MockNoteLinkLocal, MockNoteLinkRemote

### Community 225 - "Community 225"
Cohesion: 0.5
Nodes (2): MockServiceTypeLocal, MockServiceTypeRemote

### Community 226 - "Community 226"
Cohesion: 0.5
Nodes (3): { phone, code, newPassword }, RequestBody, supabase

### Community 227 - "Community 227"
Cohesion: 0.5
Nodes (2): FakeFollowUp, FakeLaunchOptions

### Community 228 - "Community 228"
Cohesion: 0.5
Nodes (2): MockCustomerRepository, MockJobRepository

### Community 229 - "Community 229"
Cohesion: 0.67
Nodes (1): KsAnalytics

### Community 230 - "Community 230"
Cohesion: 0.67
Nodes (1): UserModel

### Community 231 - "Community 231"
Cohesion: 0.67
Nodes (1): UserEntity

### Community 232 - "Community 232"
Cohesion: 0.67
Nodes (1): LandingScreen

### Community 233 - "Community 233"
Cohesion: 0.67
Nodes (1): MinVersionGateScreen

### Community 234 - "Community 234"
Cohesion: 0.67
Nodes (1): AuthHeader

### Community 235 - "Community 235"
Cohesion: 0.67
Nodes (1): NameStepView

### Community 236 - "Community 236"
Cohesion: 0.67
Nodes (1): OnboardingBottomBar

### Community 237 - "Community 237"
Cohesion: 0.67
Nodes (1): OnboardingStepIndicator

### Community 238 - "Community 238"
Cohesion: 0.67
Nodes (1): CustomerModel

### Community 239 - "Community 239"
Cohesion: 0.67
Nodes (1): CustomerAuditEntryEntity

### Community 240 - "Community 240"
Cohesion: 0.67
Nodes (1): CustomerEntity

### Community 241 - "Community 241"
Cohesion: 0.67
Nodes (1): KeyCodeEntryEntity

### Community 242 - "Community 242"
Cohesion: 0.67
Nodes (1): GetCustomersUsecase

### Community 243 - "Community 243"
Cohesion: 0.67
Nodes (1): CustomerCard

### Community 244 - "Community 244"
Cohesion: 0.67
Nodes (1): CorrectionRequestEntity

### Community 245 - "Community 245"
Cohesion: 0.67
Nodes (1): FollowUpEntity

### Community 246 - "Community 246"
Cohesion: 0.67
Nodes (1): InventoryItemEntity

### Community 247 - "Community 247"
Cohesion: 0.67
Nodes (1): JobAuditEntryEntity

### Community 248 - "Community 248"
Cohesion: 0.67
Nodes (1): JobEntity

### Community 249 - "Community 249"
Cohesion: 0.67
Nodes (1): JobExpenseEntity

### Community 250 - "Community 250"
Cohesion: 0.67
Nodes (1): JobHardwareEntity

### Community 251 - "Community 251"
Cohesion: 0.67
Nodes (1): JobPartEntity

### Community 252 - "Community 252"
Cohesion: 0.67
Nodes (1): JobPhotoEntity

### Community 253 - "Community 253"
Cohesion: 0.67
Nodes (1): JobServiceEntity

### Community 254 - "Community 254"
Cohesion: 0.67
Nodes (1): JobTemplateEntity

### Community 255 - "Community 255"
Cohesion: 0.67
Nodes (1): KnowledgeNoteEntity

### Community 256 - "Community 256"
Cohesion: 0.67
Nodes (1): NoteJobLinkEntity

### Community 257 - "Community 257"
Cohesion: 0.67
Nodes (1): ProfileEntity

### Community 258 - "Community 258"
Cohesion: 0.67
Nodes (1): RecurringScheduleEntity

### Community 259 - "Community 259"
Cohesion: 0.67
Nodes (1): ReminderEntity

### Community 260 - "Community 260"
Cohesion: 0.67
Nodes (1): RestockEntity

### Community 261 - "Community 261"
Cohesion: 0.67
Nodes (1): ServiceTypeEntity

### Community 262 - "Community 262"
Cohesion: 0.67
Nodes (1): StockAdjustmentEntity

### Community 263 - "Community 263"
Cohesion: 0.67
Nodes (1): AppException

### Community 264 - "Community 264"
Cohesion: 0.67
Nodes (1): HubScreen

### Community 265 - "Community 265"
Cohesion: 0.67
Nodes (1): InventoryItemModel

### Community 266 - "Community 266"
Cohesion: 0.67
Nodes (1): RestockModel

### Community 267 - "Community 267"
Cohesion: 0.67
Nodes (1): StockAdjustmentModel

### Community 268 - "Community 268"
Cohesion: 0.67
Nodes (1): CorrectionRequestModel

### Community 269 - "Community 269"
Cohesion: 0.67
Nodes (1): JobAuditEntryModel

### Community 270 - "Community 270"
Cohesion: 0.67
Nodes (1): JobExpenseModel

### Community 271 - "Community 271"
Cohesion: 0.67
Nodes (1): JobHardwareModel

### Community 272 - "Community 272"
Cohesion: 0.67
Nodes (1): JobModel

### Community 273 - "Community 273"
Cohesion: 0.67
Nodes (1): JobPartModel

### Community 274 - "Community 274"
Cohesion: 0.67
Nodes (1): JobPhotoModel

### Community 275 - "Community 275"
Cohesion: 0.67
Nodes (1): JobServiceModel

### Community 276 - "Community 276"
Cohesion: 0.67
Nodes (1): ServiceTypePicker

### Community 277 - "Community 277"
Cohesion: 0.67
Nodes (1): JobTemplateModel

### Community 278 - "Community 278"
Cohesion: 0.67
Nodes (1): GetKeyCodesUsecase

### Community 279 - "Community 279"
Cohesion: 0.67
Nodes (1): KnowledgeNoteModel

### Community 280 - "Community 280"
Cohesion: 0.67
Nodes (1): GetNotesUsecase

### Community 281 - "Community 281"
Cohesion: 0.67
Nodes (1): ConnectivityService

### Community 282 - "Community 282"
Cohesion: 0.67
Nodes (1): SlugGenerator

### Community 283 - "Community 283"
Cohesion: 0.67
Nodes (1): WhatsAppLauncher

### Community 284 - "Community 284"
Cohesion: 0.67
Nodes (1): KsConfirmDialog

### Community 285 - "Community 285"
Cohesion: 0.67
Nodes (1): KsSnackbar

### Community 286 - "Community 286"
Cohesion: 0.67
Nodes (1): GetLinksForJobUsecase

### Community 287 - "Community 287"
Cohesion: 0.67
Nodes (1): GetLinksForNoteUsecase

### Community 288 - "Community 288"
Cohesion: 0.67
Nodes (1): ReminderModel

### Community 289 - "Community 289"
Cohesion: 0.67
Nodes (1): Reminder

### Community 290 - "Community 290"
Cohesion: 0.67
Nodes (1): ServiceTypeModel

### Community 291 - "Community 291"
Cohesion: 0.67
Nodes (1): GetServiceTypesUsecase

### Community 292 - "Community 292"
Cohesion: 0.67
Nodes (1): ServiceTypePickerV2

### Community 293 - "Community 293"
Cohesion: 0.67
Nodes (1): ProfileModel

### Community 294 - "Community 294"
Cohesion: 0.67
Nodes (1): ProfileScreen

### Community 295 - "Community 295"
Cohesion: 0.67
Nodes (1): FollowUpModel

### Community 296 - "Community 296"
Cohesion: 1
Nodes (2): auth.users, public.inventory_items

### Community 297 - "Community 297"
Cohesion: 1
Nodes (2): public.job_expenses, public.jobs

### Community 298 - "Community 298"
Cohesion: 1
Nodes (2): auth.users, public.job_templates

### Community 299 - "Community 299"
Cohesion: 0.67
Nodes (1): FakeCustomer

### Community 300 - "Community 300"
Cohesion: 0.67
Nodes (1): FakeJob

### Community 301 - "Community 301"
Cohesion: 0.67
Nodes (1): FakeJob

### Community 302 - "Community 302"
Cohesion: 0.67
Nodes (1): FakeJob

### Community 303 - "Community 303"
Cohesion: 0.67
Nodes (1): FakeJob

### Community 304 - "Community 304"
Cohesion: 1
Nodes (1): AnalyticsEvents

### Community 305 - "Community 305"
Cohesion: 1
Nodes (1): AppConstants

### Community 306 - "Community 306"
Cohesion: 1
Nodes (1): SupabaseConstants

### Community 308 - "Community 308"
Cohesion: 1
Nodes (1): AuthException

### Community 309 - "Community 309"
Cohesion: 1
Nodes (1): DuplicateCustomerException

### Community 310 - "Community 310"
Cohesion: 1
Nodes (1): NetworkException

### Community 311 - "Community 311"
Cohesion: 1
Nodes (1): StorageException

### Community 312 - "Community 312"
Cohesion: 1
Nodes (1): ValidationException

### Community 314 - "Community 314"
Cohesion: 1
Nodes (1): UserPermissions

### Community 315 - "Community 315"
Cohesion: 1
Nodes (1): AppColors

### Community 316 - "Community 316"
Cohesion: 1
Nodes (1): AppSpacing

### Community 317 - "Community 317"
Cohesion: 1
Nodes (1): AppTextStyles

### Community 318 - "Community 318"
Cohesion: 1
Nodes (1): KsColors

### Community 319 - "Community 319"
Cohesion: 1
Nodes (1): ServiceIconMap

### Community 320 - "Community 320"
Cohesion: 1
Nodes (1): CoverImageWidget

### Community 321 - "Community 321"
Cohesion: 1
Nodes (1): KsAppBar

### Community 322 - "Community 322"
Cohesion: 1
Nodes (1): KsAvatar

### Community 323 - "Community 323"
Cohesion: 1
Nodes (1): KsBadge

### Community 324 - "Community 324"
Cohesion: 1
Nodes (1): KsBanner

### Community 325 - "Community 325"
Cohesion: 1
Nodes (1): KsBottomNav

### Community 326 - "Community 326"
Cohesion: 1
Nodes (1): KsButton

### Community 327 - "Community 327"
Cohesion: 1
Nodes (1): KsCard

### Community 328 - "Community 328"
Cohesion: 1
Nodes (1): KsDivider

### Community 329 - "Community 329"
Cohesion: 1
Nodes (1): KsEmptyState

### Community 330 - "Community 330"
Cohesion: 1
Nodes (1): KsLoadingIndicator

### Community 331 - "Community 331"
Cohesion: 1
Nodes (1): KsLogoAnimated

### Community 332 - "Community 332"
Cohesion: 1
Nodes (1): KsLogo

### Community 333 - "Community 333"
Cohesion: 1
Nodes (1): KsOfflineBanner

### Community 334 - "Community 334"
Cohesion: 1
Nodes (1): KsStepIndicator

### Community 335 - "Community 335"
Cohesion: 1
Nodes (1): KsTagChip

### Community 336 - "Community 336"
Cohesion: 1
Nodes (1): KsTextField

### Community 337 - "Community 337"
Cohesion: 1
Nodes (1): SyncStatusIndicator

### Community 339 - "Community 339"
Cohesion: 1
Nodes (1): public.app_config

## Knowledge Gaps
- **175 isolated node(s):** `MockSupabaseClient`, `MockConnectivityService`, `KeystoneApp`, `_KeystoneAppState`, `_ErrorBoundary` (+170 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 7`** (1 nodes): `InternalAuthService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 8`** (1 nodes): `SecureVaultService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 19`** (2 nodes): `CloudinaryConfig`, `CloudinaryService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 27`** (1 nodes): `RouteNames`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 47`** (1 nodes): `DataExportService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 60`** (1 nodes): `PinService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 65`** (2 nodes): `PendingMediaUpload`, `PendingMediaUploadService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 66`** (1 nodes): `HiveService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 67`** (1 nodes): `DateFormatter`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 89`** (2 nodes): `AuthNotifier`, `AuthState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 103`** (2 nodes): `DashboardScreen`, `_DashboardScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 118`** (1 nodes): `BiometricService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 126`** (1 nodes): `LocalNotificationService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 127`** (2 nodes): `KsSearchBar`, `_KsSearchBarState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 128`** (2 nodes): `PrivacyOverlay`, `_PrivacyOverlayState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 137`** (1 nodes): `KeyCodeEntryModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 164`** (1 nodes): `NoteJobLinkModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 167`** (2 nodes): `StaggeredFadeIn`, `_StaggeredFadeInState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 168`** (1 nodes): `DemoDataService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 170`** (2 nodes): `CurrencyFormatter`, `CurrencyInputFormatter`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 171`** (1 nodes): `PhoneFormatter`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 172`** (2 nodes): `KsSkeletonLoader`, `_KsSkeletonLoaderState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 186`** (2 nodes): `MockSupabaseClient`, `_TestServiceTypeNotifier`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 187`** (2 nodes): `call()`, `LogoutUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 188`** (1 nodes): `WhatsAppConstants`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 189`** (2 nodes): `call()`, `DeleteCustomerUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 190`** (2 nodes): `call()`, `GetCustomerByPhoneUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 191`** (2 nodes): `call()`, `GetCustomerUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 192`** (2 nodes): `call()`, `SyncOfflineCustomersUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 193`** (2 nodes): `create()`, `InventoryRestocksRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 194`** (2 nodes): `create()`, `InventoryStockAdjustmentsRemoteDatasource`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 195`** (2 nodes): `MockConnectivityService`, `MockSupabaseClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 196`** (2 nodes): `GetInventoryItemsParams`, `GetInventoryItemsUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 197`** (2 nodes): `ArchiveJobUsecase`, `call()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 198`** (2 nodes): `call()`, `GetJobUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 199`** (2 nodes): `GetJobsParams`, `GetJobsUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 200`** (2 nodes): `call()`, `SyncOfflineJobsUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 201`** (2 nodes): `call()`, `DeleteKeyCodeUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 202`** (2 nodes): `call()`, `UpdateKeyCodeUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 203`** (2 nodes): `ArchiveNoteUsecase`, `call()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 204`** (2 nodes): `call()`, `SyncPendingNotesUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 205`** (2 nodes): `_LinkedJobsList`, `NoteDetailScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 206`** (2 nodes): `NoteCard`, `_TagChip`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 207`** (1 nodes): `ThemeModeNotifier`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 208`** (2 nodes): `ReceiptData`, `ReceiptPdfGenerator`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 209`** (1 nodes): `MockDataGenerator`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 210`** (2 nodes): `call()`, `DeleteNoteLinkUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 211`** (2 nodes): `NoteJobLinkScreen`, `_NoteJobLinkScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 212`** (2 nodes): `ReminderThresholds`, `save()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 213`** (2 nodes): `call()`, `DeleteServiceTypeUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 214`** (2 nodes): `call()`, `SeedDefaultServiceTypesUseCase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 215`** (2 nodes): `call()`, `GetProfileUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 216`** (2 nodes): `call()`, `ShareProfileUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 217`** (2 nodes): `call()`, `UpdateProfileUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 218`** (2 nodes): `PermissionsScreen`, `_save()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 219`** (2 nodes): `KeystoneWebLite`, `_WebGatewayScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 223`** (2 nodes): `MockKeyCodeLocal`, `MockKeyCodeRemote`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 224`** (2 nodes): `MockNoteLinkLocal`, `MockNoteLinkRemote`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 225`** (2 nodes): `MockServiceTypeLocal`, `MockServiceTypeRemote`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 227`** (2 nodes): `FakeFollowUp`, `FakeLaunchOptions`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 228`** (2 nodes): `MockCustomerRepository`, `MockJobRepository`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 229`** (1 nodes): `KsAnalytics`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 230`** (1 nodes): `UserModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 231`** (1 nodes): `UserEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 232`** (1 nodes): `LandingScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 233`** (1 nodes): `MinVersionGateScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 234`** (1 nodes): `AuthHeader`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 235`** (1 nodes): `NameStepView`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 236`** (1 nodes): `OnboardingBottomBar`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 237`** (1 nodes): `OnboardingStepIndicator`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 238`** (1 nodes): `CustomerModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 239`** (1 nodes): `CustomerAuditEntryEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 240`** (1 nodes): `CustomerEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 241`** (1 nodes): `KeyCodeEntryEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 242`** (1 nodes): `GetCustomersUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 243`** (1 nodes): `CustomerCard`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 244`** (1 nodes): `CorrectionRequestEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 245`** (1 nodes): `FollowUpEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 246`** (1 nodes): `InventoryItemEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 247`** (1 nodes): `JobAuditEntryEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 248`** (1 nodes): `JobEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 249`** (1 nodes): `JobExpenseEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 250`** (1 nodes): `JobHardwareEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 251`** (1 nodes): `JobPartEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 252`** (1 nodes): `JobPhotoEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 253`** (1 nodes): `JobServiceEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 254`** (1 nodes): `JobTemplateEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 255`** (1 nodes): `KnowledgeNoteEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 256`** (1 nodes): `NoteJobLinkEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 257`** (1 nodes): `ProfileEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 258`** (1 nodes): `RecurringScheduleEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 259`** (1 nodes): `ReminderEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 260`** (1 nodes): `RestockEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 261`** (1 nodes): `ServiceTypeEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 262`** (1 nodes): `StockAdjustmentEntity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 263`** (1 nodes): `AppException`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 264`** (1 nodes): `HubScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 265`** (1 nodes): `InventoryItemModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 266`** (1 nodes): `RestockModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 267`** (1 nodes): `StockAdjustmentModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 268`** (1 nodes): `CorrectionRequestModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 269`** (1 nodes): `JobAuditEntryModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 270`** (1 nodes): `JobExpenseModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 271`** (1 nodes): `JobHardwareModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 272`** (1 nodes): `JobModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 273`** (1 nodes): `JobPartModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 274`** (1 nodes): `JobPhotoModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 275`** (1 nodes): `JobServiceModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 276`** (1 nodes): `ServiceTypePicker`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 277`** (1 nodes): `JobTemplateModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 278`** (1 nodes): `GetKeyCodesUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 279`** (1 nodes): `KnowledgeNoteModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 280`** (1 nodes): `GetNotesUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 281`** (1 nodes): `ConnectivityService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 282`** (1 nodes): `SlugGenerator`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 283`** (1 nodes): `WhatsAppLauncher`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 284`** (1 nodes): `KsConfirmDialog`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 285`** (1 nodes): `KsSnackbar`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 286`** (1 nodes): `GetLinksForJobUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 287`** (1 nodes): `GetLinksForNoteUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 288`** (1 nodes): `ReminderModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 289`** (1 nodes): `Reminder`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 290`** (1 nodes): `ServiceTypeModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 291`** (1 nodes): `GetServiceTypesUsecase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 292`** (1 nodes): `ServiceTypePickerV2`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 293`** (1 nodes): `ProfileModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 294`** (1 nodes): `ProfileScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 295`** (1 nodes): `FollowUpModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 296`** (2 nodes): `auth.users`, `public.inventory_items`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 297`** (2 nodes): `public.job_expenses`, `public.jobs`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 298`** (2 nodes): `auth.users`, `public.job_templates`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 299`** (1 nodes): `FakeCustomer`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 300`** (1 nodes): `FakeJob`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 301`** (1 nodes): `FakeJob`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 302`** (1 nodes): `FakeJob`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 303`** (1 nodes): `FakeJob`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 304`** (1 nodes): `AnalyticsEvents`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 305`** (1 nodes): `AppConstants`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 306`** (1 nodes): `SupabaseConstants`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 308`** (1 nodes): `AuthException`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 309`** (1 nodes): `DuplicateCustomerException`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 310`** (1 nodes): `NetworkException`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 311`** (1 nodes): `StorageException`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 312`** (1 nodes): `ValidationException`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 314`** (1 nodes): `UserPermissions`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 315`** (1 nodes): `AppColors`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 316`** (1 nodes): `AppSpacing`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 317`** (1 nodes): `AppTextStyles`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 318`** (1 nodes): `KsColors`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 319`** (1 nodes): `ServiceIconMap`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 320`** (1 nodes): `CoverImageWidget`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 321`** (1 nodes): `KsAppBar`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 322`** (1 nodes): `KsAvatar`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 323`** (1 nodes): `KsBadge`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 324`** (1 nodes): `KsBanner`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 325`** (1 nodes): `KsBottomNav`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 326`** (1 nodes): `KsButton`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 327`** (1 nodes): `KsCard`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 328`** (1 nodes): `KsDivider`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 329`** (1 nodes): `KsEmptyState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 330`** (1 nodes): `KsLoadingIndicator`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 331`** (1 nodes): `KsLogoAnimated`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 332`** (1 nodes): `KsLogo`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 333`** (1 nodes): `KsOfflineBanner`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 334`** (1 nodes): `KsStepIndicator`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 335`** (1 nodes): `KsTagChip`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 336`** (1 nodes): `KsTextField`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 337`** (1 nodes): `SyncStatusIndicator`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 339`** (1 nodes): `public.app_config`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `MockSupabaseClient`, `MockConnectivityService`, `KeystoneApp` to the rest of the system?**
  _175 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `Community 7` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._
- **Should `Community 8` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._
- **Should `Community 13` be split into smaller, more focused modules?**
  _Cohesion score 0.14 - nodes in this community are weakly interconnected._