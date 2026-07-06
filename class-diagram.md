classDiagram
class TerkaApp
TerkaApp : +createState() State<TerkaApp>
StatefulWidget <|-- TerkaApp

class _TerkaAppState
_TerkaAppState : -_themeModePreferenceKey$ String
_TerkaAppState : -_languagePreferenceKey$ String
_TerkaAppState : -_themeMode ThemeMode
_TerkaAppState o-- ThemeMode
_TerkaAppState : -_language AppLanguage
_TerkaAppState o-- AppLanguage
_TerkaAppState : +initState() void
_TerkaAppState : -_loadLanguage() dynamic
_TerkaAppState : -_setLanguage() dynamic
_TerkaAppState : -_loadThemeMode() dynamic
_TerkaAppState : -_setThemeMode() dynamic
_TerkaAppState : -_themeModeFromString() ThemeMode
_TerkaAppState : -_themeModeToString() String
_TerkaAppState : +build() Widget
State <|-- _TerkaAppState

class MapState
MapState : +routeOverlayData RouteMapData
MapState o-- RouteMapData
MapState : +routeVehicleMarker RouteVehicleMarker?
MapState o-- RouteVehicleMarker
MapState : +selectedMapPayload SelectedItineraryMapPayload?
MapState o-- SelectedItineraryMapPayload
MapState : +copyWith() MapState

class MapCubit
MapCubit : +showDesktopRouteOnBackgroundMap() void
MapCubit : +clearDesktopRouteSelection() void
Cubit <|-- MapCubit

class NavigationState
NavigationState : +currentSection MainSection
NavigationState o-- MainSection
NavigationState : +history List~MainSection~
NavigationState : +copyWith() NavigationState

class NavigationCubit
NavigationCubit : +navigateTo() void
NavigationCubit : +handleBackNavigation() bool
Cubit <|-- NavigationCubit

class MainSection
<<enumeration>> MainSection
MainSection : +index int
MainSection : +values$ List~MainSection~
MainSection : +home$ MainSection
MainSection o-- MainSection
MainSection : +table$ MainSection
MainSection o-- MainSection
MainSection : +map$ MainSection
MainSection o-- MainSection
MainSection : +news$ MainSection
MainSection o-- MainSection
MainSection : +profile$ MainSection
MainSection o-- MainSection
MainSection : +tickets$ MainSection
MainSection o-- MainSection
MainSection : +addTicket$ MainSection
MainSection o-- MainSection
MainSection : +editTicket$ MainSection
MainSection o-- MainSection
MainSection : +managePassTypes$ MainSection
MainSection o-- MainSection
MainSection : +passTypeEditor$ MainSection
MainSection o-- MainSection
MainSection : +about$ MainSection
MainSection o-- MainSection
MainSection : +tripDetails$ MainSection
MainSection o-- MainSection
MainSection : +stopDetails$ MainSection
MainSection o-- MainSection
Enum <|.. MainSection

class PlanResponseController
PlanResponseController : +extractPlan()$ Map<String, dynamic>?
PlanResponseController : +extractNextPageCursor()$ String?

class RoutePlannerState
RoutePlannerState : +planResponseJson Map~String, dynamic~?
RoutePlannerState : +planResponseText String
RoutePlannerState : +lastPlanQuery String
RoutePlannerState : +lastPlanVariables Map~String, dynamic~?
RoutePlannerState : +isPlanLoading bool
RoutePlannerState : +isLoadingMore bool
RoutePlannerState : +nextPageCursor String?
RoutePlannerState : +hasMeaningfulPlanResponse bool
RoutePlannerState : +copyWith() RoutePlannerState

class RoutePlannerCubit
RoutePlannerCubit : -_transitRepository TransitRepository
RoutePlannerCubit o-- TransitRepository
RoutePlannerCubit : +setPlanResult() void
RoutePlannerCubit : +setLoading() void
RoutePlannerCubit : +clearSearch() void
RoutePlannerCubit : +loadMorePlans() dynamic
Cubit <|-- RoutePlannerCubit

class AgencyGroup
AgencyGroup : +name String
AgencyGroup : +agencyIds List~String~
AgencyGroup : +toJson() Map<String, dynamic>
AgencyGroup : +getPrebakedGroups()$ List<AgencyGroup>

class AuthLoginResult
AuthLoginResult : +ok bool
AuthLoginResult : +error String?
AuthLoginResult : +session AuthSession?
AuthLoginResult o-- AuthSession

class AuthActionResult
AuthActionResult : +ok bool
AuthActionResult : +error String?
AuthActionResult : +message String?

class TicketFormOptionsResult
TicketFormOptionsResult : +ok bool
TicketFormOptionsResult : +error String?
TicketFormOptionsResult : +agencies List~TicketAgencyOption~
TicketFormOptionsResult : +ticketTypes List~TicketTypeOption~

class TicketsResult
TicketsResult : +ok bool
TicketsResult : +error String?
TicketsResult : +tickets List~TicketItem~

class AuthProfileUpdateResult
AuthProfileUpdateResult : +ok bool
AuthProfileUpdateResult : +error String?
AuthProfileUpdateResult : +message String?
AuthProfileUpdateResult : +passwordChangeConfirmationRequired bool
AuthProfileUpdateResult : +updatedSession AuthSession?
AuthProfileUpdateResult o-- AuthSession

class AuthSession
AuthSession : +token String
AuthSession : +userId int
AuthSession : +username String
AuthSession : +email String
AuthSession : +toJson() Map<String, dynamic>

class NewsItem
NewsItem : +title String
NewsItem : +link String
NewsItem : +pubDate DateTime?
NewsItem : +rawPubDate String?

class PassType
PassType : +id String
PassType : +name String
PassType : +agencyIds List~String~
PassType : +agencyNames List~String~
PassType : +durationType String
PassType : +durationDays int?
PassType : +toJson() Map<String, dynamic>
PassType : +getPrebakedPassTypes()$ List<PassType>

class StopPoint
StopPoint : +id String
StopPoint : +name String
StopPoint : +platformCode String
StopPoint : +lat double?
StopPoint : +lon double?
StopPoint : +alerts List~dynamic~?

class TicketItem
TicketItem : +id int
TicketItem : +agencyId String
TicketItem : +agencyName String
TicketItem : +agencyIds List~String~?
TicketItem : +agencyNames List~String~?
TicketItem : +ticketType String
TicketItem : +ticketStart String?
TicketItem : +ticketEnd String?
TicketItem : +quantity int?
TicketItem : +toJson() Map<String, dynamic>
TicketItem : +hasValidTicketsForItinerary()$ bool
TicketItem : +getMissingTicketAgencies()$ List<String>
TicketItem : -_agencyMatches()$ bool
TicketItem : -_normalizeAgencyName()$ String

class TicketAgencyOption
TicketAgencyOption : +id String
TicketAgencyOption : +name String

class TicketTypeOption
TicketTypeOption : +value String
TicketTypeOption : +label String

class TripStopQuickRoute
TripStopQuickRoute : +id String
TripStopQuickRoute : +label String
TripStopQuickRoute : +usesSpanFont bool
TripStopQuickRoute : +backgroundColor Color
TripStopQuickRoute o-- Color
TripStopQuickRoute : +textColor Color
TripStopQuickRoute o-- Color

class TripStopQuickInfo
TripStopQuickInfo : +stopId String
TripStopQuickInfo : +stopName String
TripStopQuickInfo : +lines List~TripStopQuickRoute~

class TripStopTime
TripStopTime : +stop StopPoint
TripStopTime o-- StopPoint
TripStopTime : +scheduledArrival int?
TripStopTime : +realtimeArrival int?
TripStopTime : +arrivalDelay int?
TripStopTime : +scheduledDeparture int?
TripStopTime : +realtimeDeparture int?
TripStopTime : +departureDelay int?
TripStopTime : +isRealtime bool

class HttpPassTypeRepository
HttpPassTypeRepository : -_apiService PassTypeApiService
HttpPassTypeRepository o-- PassTypeApiService
HttpPassTypeRepository : +fetchPassTypes() dynamic
HttpPassTypeRepository : +savePassType() dynamic
HttpPassTypeRepository : +deletePassType() dynamic
PassTypeRepository <|.. HttpPassTypeRepository

class HttpTicketRepository
HttpTicketRepository : -_apiService TicketApiService
HttpTicketRepository o-- TicketApiService
HttpTicketRepository : +fetchTickets() dynamic
HttpTicketRepository : +fetchTicketFormOptions() dynamic
HttpTicketRepository : +addTicket() dynamic
HttpTicketRepository : +updateTicket() dynamic
HttpTicketRepository : +deleteTicket() dynamic
TicketRepository <|.. HttpTicketRepository

class HttpTransitRepository
HttpTransitRepository : -_apiService TransitApiService
HttpTransitRepository o-- TransitApiService
HttpTransitRepository : +fetchTripDetails() dynamic
HttpTransitRepository : +fetchStopQuickInfo() dynamic
HttpTransitRepository : +fetchStopDetails() dynamic
HttpTransitRepository : +loadMorePlans() dynamic
TransitRepository <|.. HttpTransitRepository

class NewsRepository
<<abstract>> NewsRepository
NewsRepository : +fetchNews()* dynamic

class PassTypeRepository
<<abstract>> PassTypeRepository
PassTypeRepository : +fetchPassTypes()* dynamic
PassTypeRepository : +savePassType()* dynamic
PassTypeRepository : +deletePassType()* dynamic

class RssNewsRepository
RssNewsRepository : -_rssUrl$ String
RssNewsRepository : -_unescape HtmlUnescape
RssNewsRepository o-- HtmlUnescape
RssNewsRepository : +fetchNews() dynamic
RssNewsRepository : -_parseRssDate() DateTime?
NewsRepository <|.. RssNewsRepository

class TicketRepository
<<abstract>> TicketRepository
TicketRepository : +fetchTickets()* dynamic
TicketRepository : +fetchTicketFormOptions()* dynamic
TicketRepository : +addTicket()* dynamic
TicketRepository : +updateTicket()* dynamic
TicketRepository : +deleteTicket()* dynamic

class TransitRepository
<<abstract>> TransitRepository
TransitRepository : +fetchTripDetails()* dynamic
TransitRepository : +fetchStopQuickInfo()* dynamic
TransitRepository : +fetchStopDetails()* dynamic
TransitRepository : +loadMorePlans()* dynamic

class AboutScreen
AboutScreen : +onBack void Function?
AboutScreen o-- void Function
AboutScreen : +createState() State<AboutScreen>
StatefulWidget <|-- AboutScreen

class _AboutScreenState
_AboutScreenState : -_version String
_AboutScreenState : -_appName String
_AboutScreenState : +initState() void
_AboutScreenState : -_loadPackageInfo() dynamic
_AboutScreenState : +build() Widget
State <|-- _AboutScreenState

class AddTicketScreen
AddTicketScreen : +ticket TicketItem?
AddTicketScreen o-- TicketItem
AddTicketScreen : +onBack void Function?
AddTicketScreen o-- void Function
AddTicketScreen : +onSaved void Function?
AddTicketScreen o-- void Function
AddTicketScreen : +createState() State<AddTicketScreen>
StatefulWidget <|-- AddTicketScreen

class _AddTicketScreenState
_AddTicketScreenState : -_formKey GlobalKey~FormState~
_AddTicketScreenState o-- GlobalKey~FormState~
_AddTicketScreenState : -_quantityController TextEditingController
_AddTicketScreenState o-- TextEditingController
_AddTicketScreenState : -_ticketStartController TextEditingController
_AddTicketScreenState o-- TextEditingController
_AddTicketScreenState : -_ticketRepository TicketRepository
_AddTicketScreenState o-- TicketRepository
_AddTicketScreenState : -_passTypeRepository PassTypeRepository
_AddTicketScreenState o-- PassTypeRepository
_AddTicketScreenState : -_isLoadingOptions bool
_AddTicketScreenState : -_isSubmitting bool
_AddTicketScreenState : -_error String?
_AddTicketScreenState : -_agencies List~TicketAgencyOption~
_AddTicketScreenState : -_passTypes List~PassType~
_AddTicketScreenState : -_selectedAgency String?
_AddTicketScreenState : -_selectedTicketType String
_AddTicketScreenState : -_selectedPassType String?
_AddTicketScreenState : -_isPass bool
_AddTicketScreenState : +initState() void
_AddTicketScreenState : +dispose() void
_AddTicketScreenState : -_loadOptions() dynamic
_AddTicketScreenState : -_findMatchingPassType() String?
_AddTicketScreenState : -_normalize() String
_AddTicketScreenState : -_pickDateTime() dynamic
_AddTicketScreenState : -_calculatePassEndDateStr() String
_AddTicketScreenState : -_submit() dynamic
_AddTicketScreenState : +build() Widget
State <|-- _AddTicketScreenState

class MainScreen
MainScreen : +selectedThemeMode ThemeMode
MainScreen o-- ThemeMode
MainScreen : +onThemeModeChanged void FunctionThemeMode
MainScreen o-- void FunctionThemeMode
MainScreen : +selectedLanguage AppLanguage
MainScreen o-- AppLanguage
MainScreen : +onLanguageChanged void FunctionAppLanguage
MainScreen o-- void FunctionAppLanguage
MainScreen : +createState() State<MainScreen>
StatefulWidget <|-- MainScreen

class _MainScreenState
_MainScreenState : -_emptyRouteMapData$ RouteMapData
_MainScreenState o-- RouteMapData
_MainScreenState : -_searchController1 TextEditingController
_MainScreenState o-- TextEditingController
_MainScreenState : -_searchController2 TextEditingController
_MainScreenState o-- TextEditingController
_MainScreenState : -_selectedDate DateTime?
_MainScreenState : -_editingTicket TicketItem?
_MainScreenState o-- TicketItem
_MainScreenState : -_editingPassType PassType?
_MainScreenState o-- PassType
_MainScreenState : -_activeTripId String?
_MainScreenState : -_activeTripServiceDay String?
_MainScreenState : -_activeStopId String?
_MainScreenState : -_activeStopName String?
_MainScreenState : -_activeStopPoint LatLng?
_MainScreenState o-- LatLng
_MainScreenState : -_activeGroupedStopIds List~String~?
_MainScreenState : -_currentSliderValue double
_MainScreenState : -_currentWalkingValue double
_MainScreenState : -_selectedKozlekedes Set~String~
_MainScreenState : -_jegyfigyeles bool
_MainScreenState : -_tickets List~TicketItem~
_MainScreenState : -_navigationCubit NavigationCubit
_MainScreenState o-- NavigationCubit
_MainScreenState : -_routePlannerCubit RoutePlannerCubit
_MainScreenState o-- RoutePlannerCubit
_MainScreenState : -_mapCubit MapCubit
_MainScreenState o-- MapCubit
_MainScreenState : -_showMap bool
_MainScreenState : -_showNews bool
_MainScreenState : -_showProfile bool
_MainScreenState : -_hasMeaningfulPlanResponse bool
_MainScreenState : -_planResponseText String
_MainScreenState : -_planResponseJson Map~String, dynamic~?
_MainScreenState : -_hasPlannerResultsPayload bool
_MainScreenState : +initState() void
_MainScreenState : -_loadTickets() dynamic
_MainScreenState : -_showMainScreen() void
_MainScreenState : -_showMapScreen() void
_MainScreenState : -_showNewsScreen() void
_MainScreenState : -_showProfileScreen() void
_MainScreenState : -_pickDate() dynamic
_MainScreenState : -_handleBackNavigation() bool
_MainScreenState : -_toggleTransportMode() void
_MainScreenState : -_currentMobileTab() _MobileTab
_MainScreenState : -_currentMobileSectionTitle() String
_MainScreenState : -_currentDesktopTabIndex() int
_MainScreenState : -_showDesktopRouteOnBackgroundMap() void
_MainScreenState : -_clearDesktopRouteSelection() void
_MainScreenState : -_buildStopRouteMapData() RouteMapData
_MainScreenState : -_buildPlannerContent() Widget
_MainScreenState : -_buildSidebarContent() Widget
_MainScreenState : +build() Widget
_MainScreenState : -_mobileTabIndex() int
_MainScreenState : -_buildRotatedNavBar() Widget
State <|-- _MainScreenState

class _MobileTab
<<enumeration>> _MobileTab
_MobileTab : +index int
_MobileTab : +values$ List~_MobileTab~
_MobileTab : +home$ _MobileTab
_MobileTab o-- _MobileTab
_MobileTab : +news$ _MobileTab
_MobileTab o-- _MobileTab
_MobileTab : +map$ _MobileTab
_MobileTab o-- _MobileTab
_MobileTab : +profile$ _MobileTab
_MobileTab o-- _MobileTab
Enum <|.. _MobileTab

class MainDesktopMapLayout
MainDesktopMapLayout : +showMap bool
MainDesktopMapLayout : +showResultCard bool
MainDesktopMapLayout : +desktopRouteOverlayData RouteMapData
MainDesktopMapLayout o-- RouteMapData
MainDesktopMapLayout : +desktopRouteVehicleMarker RouteVehicleMarker?
MainDesktopMapLayout o-- RouteVehicleMarker
MainDesktopMapLayout : +desktopSelectedMapPayload SelectedItineraryMapPayload?
MainDesktopMapLayout o-- SelectedItineraryMapPayload
MainDesktopMapLayout : +sidebarContent Widget
MainDesktopMapLayout o-- Widget
MainDesktopMapLayout : +onClearDesktopRouteSelection void Function
MainDesktopMapLayout o-- void Function
MainDesktopMapLayout : +onShowTripOnBackgroundMap dynamic FunctionRouteMapData, RouteVehicleMarker?
MainDesktopMapLayout o-- dynamic FunctionRouteMapData, RouteVehicleMarker
MainDesktopMapLayout : +onOpenTripDetailsRequested dynamic FunctionString, String?
MainDesktopMapLayout o-- dynamic FunctionString, String
MainDesktopMapLayout : +onOpenStopDetailsRequested dynamic FunctionString, String?, LatLng?, List~String~??
MainDesktopMapLayout o-- dynamic FunctionString, String, LatLng, List~String~
MainDesktopMapLayout : +hideGeneralStopsAndVehicles bool
MainDesktopMapLayout : -_buildDesktopOverlayPanel() Widget
MainDesktopMapLayout : +build() Widget
StatelessWidget <|-- MainDesktopMapLayout

class MainPlannerContent
MainPlannerContent : +isDesktop bool
MainPlannerContent : +ticketWatch bool
MainPlannerContent : +tickets List~TicketItem~
MainPlannerContent : +onOpenTripDetailsRequested dynamic FunctionString, String?
MainPlannerContent o-- dynamic FunctionString, String
MainPlannerContent : +fromController TextEditingController
MainPlannerContent o-- TextEditingController
MainPlannerContent : +toController TextEditingController
MainPlannerContent o-- TextEditingController
MainPlannerContent : +selectedDate DateTime?
MainPlannerContent : +transfers double
MainPlannerContent : +maxWalk double
MainPlannerContent : +selectedTransportModes Set~String~
MainPlannerContent : +onSearch void FunctionPlanSearchResult
MainPlannerContent o-- void FunctionPlanSearchResult
MainPlannerContent : +onLoadingChanged void Functionbool
MainPlannerContent o-- void Functionbool
MainPlannerContent : +onPickDate void Function
MainPlannerContent o-- void Function
MainPlannerContent : +onTransfersChanged void Functiondouble
MainPlannerContent o-- void Functiondouble
MainPlannerContent : +onMaxWalkChanged void Functiondouble
MainPlannerContent o-- void Functiondouble
MainPlannerContent : +onTransportModeToggle void FunctionString
MainPlannerContent o-- void FunctionString
MainPlannerContent : +onTicketWatchChanged void Functionbool
MainPlannerContent o-- void Functionbool
MainPlannerContent : +build() Widget
StatelessWidget <|-- MainPlannerContent

class MainPlanLoadingView
MainPlanLoadingView : +createState() State<MainPlanLoadingView>
StatefulWidget <|-- MainPlanLoadingView

class _MainPlanLoadingViewState
_MainPlanLoadingViewState : -_controller AnimationController
_MainPlanLoadingViewState o-- AnimationController
_MainPlanLoadingViewState : +initState() void
_MainPlanLoadingViewState : +dispose() void
_MainPlanLoadingViewState : +build() Widget
_MainPlanLoadingViewState : -_buildSkeletonTile() Widget
State <|-- _MainPlanLoadingViewState
SingleTickerProviderStateMixin <|-- _MainPlanLoadingViewState

class MainSelectedMapResultCard
MainSelectedMapResultCard : -_legTileExtent$ double
MainSelectedMapResultCard : -_maxVisibleLegs$ int
MainSelectedMapResultCard : +payload SelectedItineraryMapPayload?
MainSelectedMapResultCard o-- SelectedItineraryMapPayload
MainSelectedMapResultCard : +onBack void Function
MainSelectedMapResultCard o-- void Function
MainSelectedMapResultCard : +build() Widget
StatelessWidget <|-- MainSelectedMapResultCard

class SelectedItineraryMapScreen
SelectedItineraryMapScreen : +payload SelectedItineraryMapPayload
SelectedItineraryMapScreen o-- SelectedItineraryMapPayload
SelectedItineraryMapScreen : +build() Widget
StatelessWidget <|-- SelectedItineraryMapScreen

class ManagePassTypesScreen
ManagePassTypesScreen : +onBack void Function?
ManagePassTypesScreen o-- void Function
ManagePassTypesScreen : +onOpenPassTypeEditor void FunctionPassType??
ManagePassTypesScreen o-- void FunctionPassType
ManagePassTypesScreen : +createState() State<ManagePassTypesScreen>
StatefulWidget <|-- ManagePassTypesScreen

class _ManagePassTypesScreenState
_ManagePassTypesScreenState : -_passTypeRepository PassTypeRepository
_ManagePassTypesScreenState o-- PassTypeRepository
_ManagePassTypesScreenState : -_passTypes List~PassType~
_ManagePassTypesScreenState : -_isLoading bool
_ManagePassTypesScreenState : +initState() void
_ManagePassTypesScreenState : -_loadPassTypes() dynamic
_ManagePassTypesScreenState : -_openPassTypeEditor() dynamic
_ManagePassTypesScreenState : -_confirmDelete() dynamic
_ManagePassTypesScreenState : +build() Widget
State <|-- _ManagePassTypesScreenState

class NewsScreen
NewsScreen : +createState() State<NewsScreen>
StatefulWidget <|-- NewsScreen

class _NewsScreenState
_NewsScreenState : -_newsFuture dynamic
_NewsScreenState : -_openLink() dynamic
_NewsScreenState : +build() Widget
State <|-- _NewsScreenState

class _NewsLoadingView
_NewsLoadingView : +createState() State<_NewsLoadingView>
StatefulWidget <|-- _NewsLoadingView

class _NewsLoadingViewState
_NewsLoadingViewState : -_controller AnimationController
_NewsLoadingViewState o-- AnimationController
_NewsLoadingViewState : +initState() void
_NewsLoadingViewState : +dispose() void
_NewsLoadingViewState : +build() Widget
State <|-- _NewsLoadingViewState
SingleTickerProviderStateMixin <|-- _NewsLoadingViewState

class PassTypeEditorScreen
PassTypeEditorScreen : +passType PassType?
PassTypeEditorScreen o-- PassType
PassTypeEditorScreen : +onBack void Function?
PassTypeEditorScreen o-- void Function
PassTypeEditorScreen : +onSaved void Function?
PassTypeEditorScreen o-- void Function
PassTypeEditorScreen : +createState() State<PassTypeEditorScreen>
StatefulWidget <|-- PassTypeEditorScreen

class _PassTypeEditorScreenState
_PassTypeEditorScreenState : -_formKey GlobalKey~FormState~
_PassTypeEditorScreenState o-- GlobalKey~FormState~
_PassTypeEditorScreenState : -_nameController TextEditingController
_PassTypeEditorScreenState o-- TextEditingController
_PassTypeEditorScreenState : -_daysController TextEditingController
_PassTypeEditorScreenState o-- TextEditingController
_PassTypeEditorScreenState : -_searchController TextEditingController
_PassTypeEditorScreenState o-- TextEditingController
_PassTypeEditorScreenState : -_passTypeRepository PassTypeRepository
_PassTypeEditorScreenState o-- PassTypeRepository
_PassTypeEditorScreenState : -_ticketRepository TicketRepository
_PassTypeEditorScreenState o-- TicketRepository
_PassTypeEditorScreenState : -_isLoading bool
_PassTypeEditorScreenState : -_error String?
_PassTypeEditorScreenState : -_agencies List~TicketAgencyOption~
_PassTypeEditorScreenState : -_selectedAgencies Set~String~
_PassTypeEditorScreenState : -_durationType String
_PassTypeEditorScreenState : -_searchQuery String
_PassTypeEditorScreenState : +initState() void
_PassTypeEditorScreenState : +dispose() void
_PassTypeEditorScreenState : -_onSearchChanged() void
_PassTypeEditorScreenState : -_loadAgencies() dynamic
_PassTypeEditorScreenState : -_normalize() String
_PassTypeEditorScreenState : -_save() dynamic
_PassTypeEditorScreenState : +build() Widget
State <|-- _PassTypeEditorScreenState

class ProfileScreen
ProfileScreen : +selectedThemeMode ThemeMode
ProfileScreen o-- ThemeMode
ProfileScreen : +onThemeModeChanged void FunctionThemeMode
ProfileScreen o-- void FunctionThemeMode
ProfileScreen : +selectedLanguage AppLanguage
ProfileScreen o-- AppLanguage
ProfileScreen : +onLanguageChanged void FunctionAppLanguage
ProfileScreen o-- void FunctionAppLanguage
ProfileScreen : +onOpenTickets void Function?
ProfileScreen o-- void Function
ProfileScreen : +onOpenAddTicket void Function?
ProfileScreen o-- void Function
ProfileScreen : +onOpenManagePassTypes void Function?
ProfileScreen o-- void Function
ProfileScreen : +onOpenAbout void Function?
ProfileScreen o-- void Function
ProfileScreen : +createState() State<ProfileScreen>
StatefulWidget <|-- ProfileScreen

class _ProfileScreenState
_ProfileScreenState : -_desktopBreakpoint$ double
_ProfileScreenState : -_openTickets() dynamic
_ProfileScreenState : -_openAddTicket() dynamic
_ProfileScreenState : -_openManagePassTypes() dynamic
_ProfileScreenState : -_openAbout() dynamic
_ProfileScreenState : -_showDesktopSurface() dynamic
_ProfileScreenState : +build() Widget
State <|-- _ProfileScreenState

class _ProfileActionButton
_ProfileActionButton : +icon IconData
_ProfileActionButton o-- IconData
_ProfileActionButton : +label String
_ProfileActionButton : +onTap void Function
_ProfileActionButton o-- void Function
_ProfileActionButton : +build() Widget
StatelessWidget <|-- _ProfileActionButton

class StopDetailsScreen
StopDetailsScreen : +desktopBreakpoint$ double
StopDetailsScreen : +stopId String
StopDetailsScreen : +initialStopName String?
StopDetailsScreen : +initialStopPoint LatLng?
StopDetailsScreen o-- LatLng
StopDetailsScreen : +groupedStopIds List~String~?
StopDetailsScreen : +onShowTripOnBackgroundMap void FunctionRouteMapData, RouteVehicleMarker??
StopDetailsScreen o-- void FunctionRouteMapData, RouteVehicleMarker
StopDetailsScreen : +onOpenTripDetailsRequested void FunctionString, String?
StopDetailsScreen o-- void FunctionString, String
StopDetailsScreen : +closeAfterOpenTripRequest bool
StopDetailsScreen : +onCloseRequested void Function?
StopDetailsScreen o-- void Function
StopDetailsScreen : +createState() State<StopDetailsScreen>
StatefulWidget <|-- StopDetailsScreen

class _StopDetailsScreenState
_StopDetailsScreenState : -_spanFontFamily$ String
_StopDetailsScreenState : -_spanFontScale$ double
_StopDetailsScreenState : -_isLoading bool
_StopDetailsScreenState : -_isUpdating bool
_StopDetailsScreenState : -_isFetching bool
_StopDetailsScreenState : -_showPastDepartures bool
_StopDetailsScreenState : -_selectedDate DateTime
_StopDetailsScreenState : -_error String?
_StopDetailsScreenState : -_stop Map~String, dynamic~?
_StopDetailsScreenState : -_transitRepository TransitRepository
_StopDetailsScreenState o-- TransitRepository
_StopDetailsScreenState : -_refreshTimer Timer?
_StopDetailsScreenState o-- Timer
_StopDetailsScreenState : -_selectedLines Set~String~
_StopDetailsScreenState : -_useMobileMapSheet bool
_StopDetailsScreenState : +didUpdateWidget() void
_StopDetailsScreenState : -_getUniqueLines() List<Map<String, dynamic>>
_StopDetailsScreenState : +initState() void
_StopDetailsScreenState : +dispose() void
_StopDetailsScreenState : -_loadStopDetails() dynamic
_StopDetailsScreenState : -_extractStopTimesFromStop() List<Map<String, dynamic>>
_StopDetailsScreenState : -_isSameDate() bool
_StopDetailsScreenState : -_formatSelectedDate() String
_StopDetailsScreenState : -_pickDate() dynamic
_StopDetailsScreenState : -_updateSelectedDate() dynamic
_StopDetailsScreenState : -_stepSelectedDate() dynamic
_StopDetailsScreenState : -_isOnSelectedDate() bool
_StopDetailsScreenState : +build() Widget
_StopDetailsScreenState : -_buildBody() Widget
_StopDetailsScreenState : -_openTripDetails() dynamic
State <|-- _StopDetailsScreenState

class StopDetailsMobileSheet
StopDetailsMobileSheet : -_mobileSheetMinSize$ double
StopDetailsMobileSheet : -_mobileSheetInitialSize$ double
StopDetailsMobileSheet : -_mobileSheetMaxSize$ double
StopDetailsMobileSheet : -_mobileStopFocusZoom$ double
StopDetailsMobileSheet : +stop Map~String, dynamic~
StopDetailsMobileSheet : +initialStopPoint LatLng?
StopDetailsMobileSheet o-- LatLng
StopDetailsMobileSheet : +initialStopName String?
StopDetailsMobileSheet : +now DateTime
StopDetailsMobileSheet : +hasPast bool
StopDetailsMobileSheet : +visibleArrivals List~Map~String, dynamic~~
StopDetailsMobileSheet : +visibleDepartures List~Map~String, dynamic~~
StopDetailsMobileSheet : +selectedDate DateTime
StopDetailsMobileSheet : +showPastDepartures bool
StopDetailsMobileSheet : +onPickDate void Function
StopDetailsMobileSheet o-- void Function
StopDetailsMobileSheet : +onTogglePastDepartures void Function
StopDetailsMobileSheet o-- void Function
StopDetailsMobileSheet : +onStepSelectedDate void Functionint
StopDetailsMobileSheet o-- void Functionint
StopDetailsMobileSheet : +onGoToToday void Function
StopDetailsMobileSheet o-- void Function
StopDetailsMobileSheet : +onOpenTripDetails void Function{required String serviceDay, required String tripId}
StopDetailsMobileSheet o-- void Function{required String serviceDay, required String tripId}
StopDetailsMobileSheet : +selectedLines Set~String~
StopDetailsMobileSheet : +uniqueLines List~Map~String, dynamic~~
StopDetailsMobileSheet : +onLineSelected void FunctionString, bool
StopDetailsMobileSheet o-- void FunctionString, bool
StopDetailsMobileSheet : +onClearLineSelection void Function
StopDetailsMobileSheet o-- void Function
StopDetailsMobileSheet : +createState() State<StopDetailsMobileSheet>
StatefulWidget <|-- StopDetailsMobileSheet

class _StopDetailsMobileSheetState
_StopDetailsMobileSheetState : -_mobileSelectedTabIndex int
_StopDetailsMobileSheetState : -_isSameDate() bool
_StopDetailsMobileSheetState : -_formatSelectedDate() String
_StopDetailsMobileSheetState : -_buildStopMapRouteData() RouteMapData
_StopDetailsMobileSheetState : +build() Widget
_StopDetailsMobileSheetState : -_buildStopDetailsSheetList() Widget
State <|-- _StopDetailsMobileSheetState

class StopDetailsTabs
StopDetailsTabs : +now DateTime
StopDetailsTabs : +hasPast bool
StopDetailsTabs : +visibleArrivals List~Map~String, dynamic~~
StopDetailsTabs : +visibleDepartures List~Map~String, dynamic~~
StopDetailsTabs : +selectedDate DateTime
StopDetailsTabs : +showPastDepartures bool
StopDetailsTabs : +stop Map~String, dynamic~?
StopDetailsTabs : +onPickDate void Function
StopDetailsTabs o-- void Function
StopDetailsTabs : +onTogglePastDepartures void Function
StopDetailsTabs o-- void Function
StopDetailsTabs : +onStepSelectedDate void Functionint
StopDetailsTabs o-- void Functionint
StopDetailsTabs : +onGoToToday void Function
StopDetailsTabs o-- void Function
StopDetailsTabs : +onOpenTripDetails void Function{required String serviceDay, required String tripId}
StopDetailsTabs o-- void Function{required String serviceDay, required String tripId}
StopDetailsTabs : +selectedLines Set~String~
StopDetailsTabs : +uniqueLines List~Map~String, dynamic~~
StopDetailsTabs : +onLineSelected void FunctionString, bool
StopDetailsTabs o-- void FunctionString, bool
StopDetailsTabs : +onClearLineSelection void Function
StopDetailsTabs o-- void Function
StopDetailsTabs : -_isSameDate() bool
StopDetailsTabs : -_formatSelectedDate() String
StopDetailsTabs : +build() Widget
StatelessWidget <|-- StopDetailsTabs

class StopDetailsTimesList
StopDetailsTimesList : +items List~Map~String, dynamic~~
StopDetailsTimesList : +now DateTime
StopDetailsTimesList : +emptyMessage String
StopDetailsTimesList : +onOpenTripDetails void Function{required String serviceDay, required String tripId}?
StopDetailsTimesList o-- void Function{required String serviceDay, required String tripId}
StopDetailsTimesList : +build() Widget
StatelessWidget <|-- StopDetailsTimesList

class StopLineSelector
StopLineSelector : +uniqueLines List~Map~String, dynamic~~
StopLineSelector : +selectedLines Set~String~
StopLineSelector : +onLineSelected void FunctionString, bool
StopLineSelector o-- void FunctionString, bool
StopLineSelector : +onClearSelection void Function
StopLineSelector o-- void Function
StopLineSelector : +createState() State<StopLineSelector>
StatefulWidget <|-- StopLineSelector

class _StopLineSelectorState
_StopLineSelectorState : -_scrollController ScrollController
_StopLineSelectorState o-- ScrollController
_StopLineSelectorState : +dispose() void
_StopLineSelectorState : +build() Widget
State <|-- _StopLineSelectorState

class TicketsScreen
TicketsScreen : +onBack void Function?
TicketsScreen o-- void Function
TicketsScreen : +onEditTicket void FunctionTicketItem?
TicketsScreen o-- void FunctionTicketItem
TicketsScreen : +createState() State<TicketsScreen>
StatefulWidget <|-- TicketsScreen

class _TicketsScreenState
_TicketsScreenState : -_ticketRepository TicketRepository
_TicketsScreenState o-- TicketRepository
_TicketsScreenState : -_tickets List~TicketItem~
_TicketsScreenState : -_passTypes List~PassType~
_TicketsScreenState : -_isLoading bool
_TicketsScreenState : -_error String?
_TicketsScreenState : +initState() void
_TicketsScreenState : -_loadTickets() dynamic
_TicketsScreenState : -_editTicket() dynamic
_TicketsScreenState : -_confirmDeleteTicket() dynamic
_TicketsScreenState : -_formatDateTime() String
_TicketsScreenState : +build() Widget
State <|-- _TicketsScreenState

class TripDetailsScreen
TripDetailsScreen : +tripId String
TripDetailsScreen : +serviceDay String
TripDetailsScreen : +onShowOnBackgroundMap void FunctionRouteMapData, RouteVehicleMarker??
TripDetailsScreen o-- void FunctionRouteMapData, RouteVehicleMarker
TripDetailsScreen : +onCloseRequested void Function?
TripDetailsScreen o-- void Function
TripDetailsScreen : +onOpenTripDetailsRequested void FunctionString, String?
TripDetailsScreen o-- void FunctionString, String
TripDetailsScreen : +onOpenStopDetailsRequested void FunctionString, String?
TripDetailsScreen o-- void FunctionString, String
TripDetailsScreen : +createState() State<TripDetailsScreen>
StatefulWidget <|-- TripDetailsScreen

class _TripDetailsScreenState
_TripDetailsScreenState : -_desktopBreakpoint$ double
_TripDetailsScreenState : -_transitRepository TransitRepository
_TripDetailsScreenState o-- TransitRepository
_TripDetailsScreenState : -_isLoading bool
_TripDetailsScreenState : -_isFetching bool
_TripDetailsScreenState : -_showMap bool
_TripDetailsScreenState : -_error String?
_TripDetailsScreenState : -_trip Map~String, dynamic~?
_TripDetailsScreenState : -_refreshTimer Timer?
_TripDetailsScreenState o-- Timer
_TripDetailsScreenState : -_isDesktopBackgroundMapMode bool
_TripDetailsScreenState : -_useMobileMapSheet bool
_TripDetailsScreenState : +initState() void
_TripDetailsScreenState : +dispose() void
_TripDetailsScreenState : -_loadTrip() dynamic
_TripDetailsScreenState : +build() Widget
_TripDetailsScreenState : -_buildBody() Widget
_TripDetailsScreenState : -_openStopDetails() dynamic
_TripDetailsScreenState : -_showTripOnBackgroundMap() void
_TripDetailsScreenState : -_buildMapView() Widget
State <|-- _TripDetailsScreenState

class TripDetailsBottomCard
TripDetailsBottomCard : +trip Map~String, dynamic~
TripDetailsBottomCard : +routeColor Color
TripDetailsBottomCard o-- Color
TripDetailsBottomCard : +routeTextColor Color
TripDetailsBottomCard o-- Color
TripDetailsBottomCard : +onBack void Function
TripDetailsBottomCard o-- void Function
TripDetailsBottomCard : +build() Widget
StatelessWidget <|-- TripDetailsBottomCard

class TripDetailsMobileSheet
TripDetailsMobileSheet : -_mobileSheetMinSize$ double
TripDetailsMobileSheet : -_mobileSheetInitialSize$ double
TripDetailsMobileSheet : -_mobileSheetMaxSize$ double
TripDetailsMobileSheet : +trip Map~String, dynamic~
TripDetailsMobileSheet : +tripId String
TripDetailsMobileSheet : +serviceDay String
TripDetailsMobileSheet : +onStopTap void Function{required LatLng? initialStopPoint, required String stopId, required String stopName}
TripDetailsMobileSheet o-- void Function{required LatLng initialStopPoint, required String stopId, required String stopName}
TripDetailsMobileSheet : +stopInfoCardBuilder Widget FunctionBuildContext, RouteStopMarker
TripDetailsMobileSheet o-- Widget FunctionBuildContext, RouteStopMarker
TripDetailsMobileSheet : +build() Widget
StatelessWidget <|-- TripDetailsMobileSheet

class TripDetailsStopCard
TripDetailsStopCard : +stop RouteStopMarker
TripDetailsStopCard o-- RouteStopMarker
TripDetailsStopCard : +onOpenStopDetails void Function{required LatLng? initialStopPoint, required String stopId, required String stopName}
TripDetailsStopCard o-- void Function{required LatLng initialStopPoint, required String stopId, required String stopName}
TripDetailsStopCard : +createState() State<TripDetailsStopCard>
StatefulWidget <|-- TripDetailsStopCard

class _TripDetailsStopCardState
_TripDetailsStopCardState : -_transitRepository TransitRepository
_TripDetailsStopCardState o-- TransitRepository
_TripDetailsStopCardState : -_selectedStopQuickInfo TripStopQuickInfo?
_TripDetailsStopCardState o-- TripStopQuickInfo
_TripDetailsStopCardState : -_isLoadingSelectedStopQuickInfo bool
_TripDetailsStopCardState : -_selectedStopQuickInfoStopId String?
_TripDetailsStopCardState : +initState() void
_TripDetailsStopCardState : +didUpdateWidget() void
_TripDetailsStopCardState : -_loadInfo() dynamic
_TripDetailsStopCardState : +build() Widget
State <|-- _TripDetailsStopCardState

class TripDetailsTableView
TripDetailsTableView : +trip Map~String, dynamic~
TripDetailsTableView : +serviceDay String
TripDetailsTableView : +onStopTap void Function{required LatLng? initialStopPoint, required String stopId, required String stopName}
TripDetailsTableView o-- void Function{required LatLng initialStopPoint, required String stopId, required String stopName}
TripDetailsTableView : +build() Widget
StatelessWidget <|-- TripDetailsTableView

class AgencyGroupApiService
AgencyGroupApiService : +fetchCustomAgencyGroups() dynamic
AgencyGroupApiService : +saveCustomAgencyGroup() dynamic

class GraphqlResponse
GraphqlResponse : +statusCode int
GraphqlResponse : +rawBody String
GraphqlResponse : +json Map~String, dynamic~?
GraphqlResponse : +isSuccess bool

class GraphqlClient
GraphqlClient : +execute() dynamic

class PassTypeApiService
PassTypeApiService : +fetchPassTypes() dynamic
PassTypeApiService : +savePassType() dynamic
PassTypeApiService : +deletePassType() dynamic

class TicketApiService
TicketApiService : +fetchTickets() dynamic
TicketApiService : +fetchTicketFormOptions() dynamic
TicketApiService : +addTicket() dynamic
TicketApiService : +updateTicket() dynamic
TicketApiService : +deleteTicket() dynamic

class TransitApiService
TransitApiService : -_graphqlClient GraphqlClient
TransitApiService o-- GraphqlClient
TransitApiService : +fetchTripDetails() dynamic
TransitApiService : +fetchStopQuickInfo() dynamic
TransitApiService : +fetchStopDetails() dynamic
TransitApiService : +loadMorePlans() dynamic

class AppTexts
AppTexts : -_language$ AppLanguage
AppTexts o-- AppLanguage
AppTexts : +language$ AppLanguage
AppTexts o-- AppLanguage
AppTexts : +isHungarian$ bool
AppTexts : +isEnglish$ bool
AppTexts : +appTitle$ String
AppTexts : +search$ String
AppTexts : +home$ String
AppTexts : +news$ String
AppTexts : +map$ String
AppTexts : +profile$ String
AppTexts : +back$ String
AppTexts : +menu$ String
AppTexts : +lists$ String
AppTexts : +stops$ String
AppTexts : +lines$ String
AppTexts : +mavNews$ String
AppTexts : +myTickets$ String
AppTexts : +addTicket$ String
AppTexts : +logout$ String
AppTexts : +login$ String
AppTexts : +register$ String
AppTexts : +retry$ String
AppTexts : +save$ String
AppTexts : +saving$ String
AppTexts : +processInProgress$ String
AppTexts : +failed$ String
AppTexts : +success$ String
AppTexts : +error$ String
AppTexts : +unknown$ String
AppTexts : +unknownVehicle$ String
AppTexts : +estimatedPosition$ String
AppTexts : +railReplacementBus$ String
AppTexts : +noData$ String
AppTexts : +system$ String
AppTexts : +appearance$ String
AppTexts : +lightMode$ String
AppTexts : +darkMode$ String
AppTexts : +systemMode$ String
AppTexts : +languageLabel$ String
AppTexts : +aboutTitle$ String
AppTexts : +aboutAppName$ String
AppTexts : +aboutCreatedBy$ String
AppTexts : +specialThanks$ String
AppTexts : +specialThanksTitle$ String
AppTexts : +ticketsTitle$ String
AppTexts : +ticketsLoadFailed$ String
AppTexts : +ticketsEmpty$ String
AppTexts : +ticketsModify$ String
AppTexts : +ticketsDelete$ String
AppTexts : +ticketsDeleteConfirmTitle$ String
AppTexts : +ticketsCancel$ String
AppTexts : +ticketsDeleteSuccess$ String
AppTexts : +ticketsDeleteFailed$ String
AppTexts : +addTicketTitle$ String
AppTexts : +editTicketTitle$ String
AppTexts : +addTicketTypeLabel$ String
AppTexts : +addTicketTypeSingle$ String
AppTexts : +addTicketTypePass$ String
AppTexts : +addTicketAgencyLabel$ String
AppTexts : +addTicketAgencyValidator$ String
AppTexts : +addTicketQuantityLabel$ String
AppTexts : +addTicketQuantityEmpty$ String
AppTexts : +addTicketQuantityPositive$ String
AppTexts : +addTicketPassTypeLabel$ String
AppTexts : +addTicketPassTypeValidator$ String
AppTexts : +addTicketValidityStartLabel$ String
AppTexts : +addTicketValidityStartValidator$ String
AppTexts : +addTicketSave$ String
AppTexts : +addTicketAdd$ String
AppTexts : +addTicketFailed$ String
AppTexts : +addTicketSuccess$ String
AppTexts : +addTicketOptionsLoadFailed$ String
AppTexts : +managePassTypesTitle$ String
AppTexts : +managePassTypesNew$ String
AppTexts : +managePassTypesEmpty$ String
AppTexts : +managePassTypesDeleteTitle$ String
AppTexts : +managePassTypesDeleteButton$ String
AppTexts : +managePassTypesEditTitle$ String
AppTexts : +managePassTypesNewTitle$ String
AppTexts : +managePassTypesNameLabel$ String
AppTexts : +managePassTypesNameValidator$ String
AppTexts : +managePassTypesDurationTypeLabel$ String
AppTexts : +managePassTypesDurationMonth$ String
AppTexts : +managePassTypesDurationCustom$ String
AppTexts : +managePassTypesCustomDaysLabel$ String
AppTexts : +managePassTypesCustomDaysEmpty$ String
AppTexts : +managePassTypesCustomDaysPositive$ String
AppTexts : +managePassTypesSelectedAgencies$ String
AppTexts : +managePassTypesSearchAgency$ String
AppTexts : +managePassTypesAgenciesList$ String
AppTexts : +managePassTypesNoAgenciesFound$ String
AppTexts : +managePassTypesSavePassType$ String
AppTexts : +managePassTypesSelectMinOneAgency$ String
AppTexts : +managePassTypesLoadAgenciesFailed$ String
AppTexts : +newsTitle$ String
AppTexts : +newsLoadFailed$ String
AppTexts : +newsLoadError$ String
AppTexts : +newsEmpty$ String
AppTexts : +newsLinkOpenFailed$ String
AppTexts : +newsInstruction$ String
AppTexts : +newsLanguageWarning$ String
AppTexts : +profileLabelAppearance$ String
AppTexts : +profileAppearanceVilagos$ String
AppTexts : +profileAppearanceSotet$ String
AppTexts : +profileAppearanceRendszer$ String
AppTexts : +profileMyTickets$ String
AppTexts : +profileAddTicket$ String
AppTexts : +profileManagePassTypes$ String
AppTexts : +profileAboutApp$ String
AppTexts : +profileLanguage$ String
AppTexts : +mainDefaultPlanResponse$ String
AppTexts : +mainLoadMoreFailed$ String
AppTexts : +mainRoutePlanning$ String
AppTexts : +mainMavNews$ String
AppTexts : +mainMap$ String
AppTexts : +mainProfile$ String
AppTexts : +mainHome$ String
AppTexts : +mainNews$ String
AppTexts : +mainRouteOnMap$ String
AppTexts : +formDeparture$ String
AppTexts : +formHintCharCount$ String
AppTexts : +formArrival$ String
AppTexts : +formSwap$ String
AppTexts : +formDepartNow$ String
AppTexts : +formDepartLater$ String
AppTexts : +formDate$ String
AppTexts : +formPickDate$ String
AppTexts : +formDepartureTime$ String
AppTexts : +formArrivalTime$ String
AppTexts : +formPickTime$ String
AppTexts : +formSearch$ String
AppTexts : +formHideAdvanced$ String
AppTexts : +formShowAdvanced$ String
AppTexts : +formTransfers$ String
AppTexts : +formWalking$ String
AppTexts : +formTransportModes$ String
AppTexts : +formTicketWatch$ String
AppTexts : +stopInvalidResponse$ String
AppTexts : +stopDetailsNotAvailable$ String
AppTexts : +stopNoData$ String
AppTexts : +stopPrevDay$ String
AppTexts : +stopNextDay$ String
AppTexts : +stopToday$ String
AppTexts : +stopHidePast$ String
AppTexts : +stopShowPast$ String
AppTexts : +stopArrivals$ String
AppTexts : +stopDepartures$ String
AppTexts : +stopArrivalDeparture$ String
AppTexts : +stopTimeLabel$ String
AppTexts : +stopSwipeInstruction$ String
AppTexts : +stopNoArrivals$ String
AppTexts : +stopNoDepartures$ String
AppTexts : +stopDetailsLabel$ String
AppTexts : +stopLineFilterTitle$ String
AppTexts : +stopLineFilterReset$ String
AppTexts : +trip$ String
AppTexts : +tripRouteOnMap$ String
AppTexts : +tripDetails$ String
AppTexts : +tripDetailsNotAvailable$ String
AppTexts : +tripStopColumn$ String
AppTexts : +tripArrivalColumn$ String
AppTexts : +tripDepartureColumn$ String
AppTexts : +tripSwipeInstruction$ String
AppTexts : +tripDelayNa$ String
AppTexts : +tripDelayZero$ String
AppTexts : +tripNoVehicle$ String
AppTexts : +tripNextStopPrefix$ String
AppTexts : +tripNextStopStoppedAt$ String
AppTexts : +tripNextStopIncomingAt$ String
AppTexts : +delayNa$ String
AppTexts : +delayMinutesUnit$ String
AppTexts : +delayZero$ String
AppTexts : +delayPrefix$ String
AppTexts : +tableResults$ String
AppTexts : +tableSegmentNotAvailable$ String
AppTexts : +tableWalk$ String
AppTexts : +tableTransit$ String
AppTexts : +tableWalkDetails$ String
AppTexts : +tableTransitDetails$ String
AppTexts : +tableShowOnMap$ String
AppTexts : +tableLoadMore$ String
AppTexts : +tableDurationHeader$ String
AppTexts : +tableTransitHeader$ String
AppTexts : +tableWalkMode$ String
AppTexts : +tableWalkSubtitle$ String
AppTexts : +tableDirect$ String
AppTexts : +stationsTitle$ String
AppTexts : +stationsName$ String
AppTexts : +stationsCity$ String
AppTexts : +stationsZone$ String
AppTexts : +stationsType$ String
AppTexts : +stationsLat$ String
AppTexts : +stationsLon$ String
AppTexts : +mapLocationDisabled$ String
AppTexts : +mapPermissionRequired$ String
AppTexts : +mapTimeout$ String
AppTexts : +mapPluginNotLoaded$ String
AppTexts : +mapLocationFailed$ String
AppTexts : +mapLoadFailed$ String
AppTexts : +mapNoTripId$ String
AppTexts : +mapTooltipMyLocation$ String
AppTexts : +authSessionExpired$ String
AppTexts : +authResponseIncomplete$ String
AppTexts : +authResponseInvalid$ String
AppTexts : +authPassTypeMonth$ String
AppTexts : +authNetworkTimeout$ String
AppTexts : +authNetworkBackendUnavailable$ String
AppTexts : +authNetworkGeneralError$ String
AppTexts : +authLoginFailed$ String
AppTexts : +authServerResponseIncomplete$ String
AppTexts : +authServerResponseInvalid$ String
AppTexts : +authRegistrationFailed$ String
AppTexts : +authRegistrationSuccess$ String
AppTexts : +authActivationSuccess$ String
AppTexts : +authProfileUpdateSuccess$ String
AppTexts : +authPasswordConfirmSuccess$ String
AppTexts : +authTicketNotFound$ String
AppTexts : +authAddTicketSuccess$ String
AppTexts : +authUpdateTicketSuccess$ String
AppTexts : +authDeleteTicketSuccess$ String
AppTexts : +apiNoResponseBody$ String
AppTexts : +apiResponseNotJson$ String
AppTexts : +alertDefaultHeader$ String
AppTexts : +alertDetailsButton$ String
AppTexts : +setLanguage()$ void
AppTexts : +aboutDescription()$ String
AppTexts : +version()$ String
AppTexts : +ticketsDeleteConfirmContent()$ String
AppTexts : +ticketsType()$ String
AppTexts : +ticketsStart()$ String
AppTexts : +ticketsEnd()$ String
AppTexts : +ticketsQuantity()$ String
AppTexts : +ticketsMissingFor()$ String
AppTexts : +managePassTypesDuration()$ String
AppTexts : +managePassTypesAgencies()$ String
AppTexts : +managePassTypesDeleteContent()$ String
AppTexts : +mainLoadMoreHttpFailed()$ String
AppTexts : +localizeTransportMode()$ String
AppTexts : +stopErrorUpdate()$ String
AppTexts : +stopDateLabel()$ String
AppTexts : +stopPlatform()$ String
AppTexts : +tripDelayMinutes()$ String
AppTexts : +tableWaitThen()$ String
AppTexts : +tableTripId()$ String
AppTexts : +tableTransfersCount()$ String
AppTexts : +tableSubtitle()$ String
AppTexts : +tableResultsHeader()$ String
AppTexts : +tableMinutes()$ String
AppTexts : +tableHoursMinutes()$ String
AppTexts : +authPassTypeDays()$ String
AppTexts : +authLoadTicketsFailed()$ String
AppTexts : +authLoginFailedHttp()$ String
AppTexts : +authRegistrationFailedHttp()$ String
AppTexts : +authActivationFailedHttp()$ String
AppTexts : +authProfileUpdateFailedHttp()$ String
AppTexts : +authPasswordConfirmFailedHttp()$ String
AppTexts : +authAddTicketError()$ String
AppTexts : +authUpdateTicketError()$ String
AppTexts : +authDeleteTicketError()$ String
AppTexts : +apiException()$ String
AppTexts : +alertTimeRange()$ String
AppTexts : +alertStartTime()$ String
AppTexts : +alertEndTime()$ String
AppTexts : +tripScheduledTime()$ String
AppTexts : +tripScheduledTimeRange()$ String
AppTexts : +tripScheduledArrival()$ String
AppTexts : +tripScheduledDeparture()$ String

class AppLanguage
<<enumeration>> AppLanguage
AppLanguage : +index int
AppLanguage : +values$ List~AppLanguage~
AppLanguage : +hu$ AppLanguage
AppLanguage o-- AppLanguage
AppLanguage : +en$ AppLanguage
AppLanguage o-- AppLanguage
Enum <|.. AppLanguage

class AppColors
AppColors : +seed$ Color
AppColors o-- Color
AppColors : +white$ Color
AppColors o-- Color
AppColors : +lightScaffoldBackground$ Color
AppColors o-- Color
AppColors : +lightNavbarBackground$ Color
AppColors o-- Color
AppColors : +lightSurface$ Color
AppColors o-- Color
AppColors : +lightSurfaceVariant$ Color
AppColors o-- Color
AppColors : +darkScaffoldBackground$ Color
AppColors o-- Color
AppColors : +darkSurface$ Color
AppColors o-- Color
AppColors : +darkSurfaceVariant$ Color
AppColors o-- Color
AppColors : +darkOnSurface$ Color
AppColors o-- Color
AppColors : +drawerGradientStart$ Color
AppColors o-- Color
AppColors : +drawerGradientMiddle$ Color
AppColors o-- Color
AppColors : +drawerGradientEnd$ Color
AppColors o-- Color
AppColors : +darkVehicleCardBackground$ Color
AppColors o-- Color
AppColors : +darkVehicleCardActionText$ Color
AppColors o-- Color
AppColors : +lightVehicleCardBackground$ Color
AppColors o-- Color
AppColors : +lightVehicleCardActionText$ Color
AppColors o-- Color
AppColors : +getVehicleCardBackground()$ Color
AppColors : +getVehicleCardActionText()$ Color
AppColors : -_isDarkMode()$ bool
AppColors : +getScaffoldBackground()$ Color
AppColors : +getSurface()$ Color
AppColors : +getSurfaceVariant()$ Color

class AppFontSizes
AppFontSizes : +body$ double
AppFontSizes : +title$ double
AppFontSizes : +sectionTitle$ double
AppFontSizes : +drawerHeader$ double

class AppSpacing
AppSpacing : +none$ double
AppSpacing : +xs$ double
AppSpacing : +sm$ double
AppSpacing : +md$ double
AppSpacing : +lg$ double
AppSpacing : +xl$ double
AppSpacing : +xxl$ double
AppSpacing : +touchTarget$ double
AppSpacing : +dropdownOffset$ double
AppSpacing : +formMaxWidth$ double

class MainScreenUtils
MainScreenUtils : +hasItineraries()$ bool
MainScreenUtils : +mergePlanResponses()$ Map<String, dynamic>

class RouteDataUtils
RouteDataUtils : +extractItineraries()$ List<Map<String, dynamic>>
RouteDataUtils : +buildSummary()$ Map<String, String>
RouteDataUtils : +formatDuration()$ String
RouteDataUtils : +formatEpochMillis()$ String
RouteDataUtils : +nestedString()$ String?
RouteDataUtils : +durationMinutes()$ int?
RouteDataUtils : +waitingMinutesUntilNextTransit()$ int?

class RouteMappingUtils
RouteMappingUtils : +decodePolyline()$ List<LatLng>
RouteMappingUtils : +parseHexColor()$ Color?
RouteMappingUtils : +isWhiteColor()$ bool
RouteMappingUtils : +parseRouteColor()$ Color
RouteMappingUtils : +parseRouteColorForMap()$ Color
RouteMappingUtils : +parseRouteTextColor()$ Color
RouteMappingUtils : +idealTextColor()$ Color

class StopDetailsUtils
StopDetailsUtils : +asNum()$ num?
StopDetailsUtils : +containsSpanMarkup()$ bool
StopDetailsUtils : +plainText()$ String
StopDetailsUtils : +hexColor()$ Color
StopDetailsUtils : +isArrivalEntry()$ bool
StopDetailsUtils : +isDepartureEntry()$ bool
StopDetailsUtils : +isScheduledStopAction()$ bool
StopDetailsUtils : +isPastDeparture()$ bool
StopDetailsUtils : +eventSecondsOfDay()$ num?
StopDetailsUtils : +getBudapestOffsetHours()$ int
StopDetailsUtils : +toBudapestTime()$ DateTime
StopDetailsUtils : +budapestMidnightUtc()$ DateTime
StopDetailsUtils : +budapestToday()$ DateTime
StopDetailsUtils : +isSameBudapestDay()$ bool
StopDetailsUtils : +resolveDepartureInstant()$ DateTime?
StopDetailsUtils : +resolveDepartureTime()$ DateTime?
StopDetailsUtils : +serviceDayToYmd()$ String
StopDetailsUtils : +serviceDayLocalMidnight()$ DateTime?
StopDetailsUtils : +formatTime()$ String
StopDetailsUtils : +expandStopIdVariants()$ List<String>
StopDetailsUtils : +departures()$ List<Map<String, dynamic>>
StopDetailsUtils : +stopPoint()$ LatLng?
StopDetailsUtils : +distanceBetween()$ double
StopDetailsUtils : -_degToRad()$ double
StopDetailsUtils : +selectClosestStop()$ Map<String, dynamic>?

class TripDetailsUtils
TripDetailsUtils : +asNum()$ num?
TripDetailsUtils : +containsSpanMarkup()$ bool
TripDetailsUtils : +parseServiceDay()$ DateTime?
TripDetailsUtils : +resolveDateTime()$ DateTime?
TripDetailsUtils : +formatEpoch()$ String
TripDetailsUtils : +delayText()$ String
TripDetailsUtils : +plainText()$ String
TripDetailsUtils : +hexColor()$ Color
TripDetailsUtils : +isPassedStop()$ bool
TripDetailsUtils : +isWhiteLike()$ bool
TripDetailsUtils : +resolvedPolylineColor()$ Color
TripDetailsUtils : +decodePolyline()$ dynamic
TripDetailsUtils : +tripGeometryPoints()$ dynamic
TripDetailsUtils : +List()$ dynamic
TripDetailsUtils : +() dynamic
TripDetailsUtils : +>() dynamic
TripDetailsUtils : +stopPoints() dynamic
TripDetailsUtils : +firstVehicle()$ Map<String, dynamic>
TripDetailsUtils : +route()$ Map<String, dynamic>
TripDetailsUtils : +stopTimes()$ dynamic
TripDetailsUtils : +buildTripRouteMapData()$ RouteMapData
TripDetailsUtils : +buildTripVehicleMarker()$ RouteVehicleMarker?
TripDetailsUtils : +static() dynamic
TripDetailsUtils : +buildTripVehicleInfo() dynamic
TripDetailsUtils : +buildVehicleTapInfoCard()$ VehicleInfoCard

class VehicleTypeLookup
VehicleTypeLookup : +code String
VehicleTypeLookup : +vehicleTypeByUicSeries$ Map~String, String~
VehicleTypeLookup : +vehicleType String
VehicleTypeLookup : +name String
VehicleTypeLookup : +[]() String
VehicleTypeLookup : +call() String
VehicleTypeLookup : +lookup()$ String

class AlertsSection
AlertsSection : +alerts List~dynamic~?
AlertsSection : -_launchUrl() dynamic
AlertsSection : -_getTranslatedText() String
AlertsSection : -_formatTimestamp() String
AlertsSection : -_formatTimeRange() String
AlertsSection : +build() Widget
AlertsSection : +parseHtmlToTextSpans()$ List<InlineSpan>
StatelessWidget <|-- AlertsSection

class _HtmlToken
_HtmlToken : +text String
_HtmlToken : +name String
_HtmlToken : +isTag bool
_HtmlToken : +isClose bool

class DepartureCard
DepartureCard : +spanFontFamily$ String
DepartureCard : +spanFontScale$ double
DepartureCard : +departure Map~String, dynamic~
DepartureCard : +now DateTime
DepartureCard : +onTap void Function?
DepartureCard o-- void Function
DepartureCard : +build() Widget
StatelessWidget <|-- DepartureCard

class PlanSearchResult
PlanSearchResult : +hasMeaningfulResponse bool
PlanSearchResult : +responseText String
PlanSearchResult : +query String
PlanSearchResult : +requestVariables Map~String, dynamic~?
PlanSearchResult : +responseJson Map~String, dynamic~?
PlanSearchResult : +nextPageCursor String?

class _SuggestionEntry
_SuggestionEntry : +name String
_SuggestionEntry : +id String?
_SuggestionEntry : +coordinates List~double~?
_SuggestionEntry : +icons List~IconData~

class RoutePlanForm
RoutePlanForm : +fromController TextEditingController
RoutePlanForm o-- TextEditingController
RoutePlanForm : +toController TextEditingController
RoutePlanForm o-- TextEditingController
RoutePlanForm : +selectedDate DateTime?
RoutePlanForm : +transfers double
RoutePlanForm : +maxWalk double
RoutePlanForm : +selectedTransportModes Set~String~
RoutePlanForm : +ticketWatch bool
RoutePlanForm : +onSearch void FunctionPlanSearchResult
RoutePlanForm o-- void FunctionPlanSearchResult
RoutePlanForm : +onPickDate void Function
RoutePlanForm o-- void Function
RoutePlanForm : +onTransfersChanged void Functiondouble
RoutePlanForm o-- void Functiondouble
RoutePlanForm : +onMaxWalkChanged void Functiondouble
RoutePlanForm o-- void Functiondouble
RoutePlanForm : +onTransportModeToggle void FunctionString
RoutePlanForm o-- void FunctionString
RoutePlanForm : +onTicketWatchChanged void Functionbool
RoutePlanForm o-- void Functionbool
RoutePlanForm : +onLoadingChanged void Functionbool
RoutePlanForm o-- void Functionbool
RoutePlanForm : +createState() State<RoutePlanForm>
StatefulWidget <|-- RoutePlanForm

class _RoutePlanFormState
_RoutePlanFormState : -_useLocalSearch$ bool
_RoutePlanFormState : -_deduplicateSuggestions$ bool
_RoutePlanFormState : -_showAdvancedFields bool
_RoutePlanFormState : -_planForNow bool
_RoutePlanFormState : -_fromFocusNode FocusNode
_RoutePlanFormState o-- FocusNode
_RoutePlanFormState : -_toFocusNode FocusNode
_RoutePlanFormState o-- FocusNode
_RoutePlanFormState : -_debounce Timer?
_RoutePlanFormState o-- Timer
_RoutePlanFormState : -_isLoadingSuggestions bool
_RoutePlanFormState : -_isLoadingPlan bool
_RoutePlanFormState : -_suggestions List~String~
_RoutePlanFormState : -_suggestionIcons List~List~IconData~~
_RoutePlanFormState : -_suggestionEntries List~_SuggestionEntry~
_RoutePlanFormState : -_selectedFromPlaceToken String?
_RoutePlanFormState : -_selectedToPlaceToken String?
_RoutePlanFormState : -_selectedFromCoordinates List~double~?
_RoutePlanFormState : -_selectedToCoordinates List~double~?
_RoutePlanFormState : -_departureTime TimeOfDay?
_RoutePlanFormState o-- TimeOfDay
_RoutePlanFormState : -_arrivalTime TimeOfDay?
_RoutePlanFormState o-- TimeOfDay
_RoutePlanFormState : -_activeSearchField _ActiveSearchField
_RoutePlanFormState o-- _ActiveSearchField
_RoutePlanFormState : -_graphqlClient GraphqlClient
_RoutePlanFormState o-- GraphqlClient
_RoutePlanFormState : -_localStationSuggestions$ List~String~
_RoutePlanFormState : +initState() void
_RoutePlanFormState : +dispose() void
_RoutePlanFormState : +didUpdateWidget() void
_RoutePlanFormState : -_swapRouteLocations() void
_RoutePlanFormState : -_onQueryChanged() void
_RoutePlanFormState : -_fetchSuggestions() dynamic
_RoutePlanFormState : -_submitPlanSearch() dynamic
_RoutePlanFormState : -_fetchPlanResponse() dynamic
_RoutePlanFormState : -_prettyJson() String
_RoutePlanFormState : -_twoDigits() String
_RoutePlanFormState : -_formatTimeLabel() String
_RoutePlanFormState : -_pickTime() dynamic
_RoutePlanFormState : -_toApiTransportModes() List<Map<String, String>>
_RoutePlanFormState : -_onSuggestionTap() void
_RoutePlanFormState : +build() Widget
_RoutePlanFormState : -_buildTransportChips() List<Widget>
_RoutePlanFormState : -_iconsForModes() List<IconData>
_RoutePlanFormState : -_mergeUniqueIcons() List<IconData>
_RoutePlanFormState : -_setCurrentLocation() dynamic
_RoutePlanFormState : -_formatPhotonName() String
State <|-- _RoutePlanFormState
TickerProviderStateMixin <|-- _RoutePlanFormState

class _ActiveSearchField
<<enumeration>> _ActiveSearchField
_ActiveSearchField : +index int
_ActiveSearchField : +values$ List~_ActiveSearchField~
_ActiveSearchField : +none$ _ActiveSearchField
_ActiveSearchField o-- _ActiveSearchField
_ActiveSearchField : +from$ _ActiveSearchField
_ActiveSearchField o-- _ActiveSearchField
_ActiveSearchField : +to$ _ActiveSearchField
_ActiveSearchField o-- _ActiveSearchField
Enum <|.. _ActiveSearchField

class ItineraryLegTile
ItineraryLegTile : -_spanFontFamily$ String
ItineraryLegTile : +leg Map~String, dynamic~
ItineraryLegTile : +nextLeg Map~String, dynamic~?
ItineraryLegTile : +serviceDay String
ItineraryLegTile : +desktopInlineMapMode bool
ItineraryLegTile : +desktopBreakpoint double
ItineraryLegTile : +onShowTripOnMap void FunctionRouteMapData, RouteVehicleMarker??
ItineraryLegTile o-- void FunctionRouteMapData, RouteVehicleMarker
ItineraryLegTile : +onOpenTripDetailsRequested dynamic FunctionString, String?
ItineraryLegTile o-- dynamic FunctionString, String
ItineraryLegTile : +build() Widget
ItineraryLegTile : -_openTripDetails() dynamic
ItineraryLegTile : -_todayServiceDate() String
ItineraryLegTile : -_legLineNumber() String
ItineraryLegTile : -_legTripDisplayNumber() String
ItineraryLegTile : -_iconForMode() IconData
ItineraryLegTile : -_containsSpanMarkup() bool
ItineraryLegTile : -_buildSpanAwareInlineSpans() List<InlineSpan>
StatelessWidget <|-- ItineraryLegTile

class LineBadge
LineBadge : +spanFontFamily$ String
LineBadge : +spanFontScale$ double
LineBadge : +lineLabel String
LineBadge : +routeColor Color
LineBadge o-- Color
LineBadge : +routeTextColor Color
LineBadge o-- Color
LineBadge : +useSpanFont bool
LineBadge : +build() Widget
StatelessWidget <|-- LineBadge

class MapView
MapView : +controlsBottomInset double
MapView : +showMyLocationButton bool
MapView : +showRotationControls bool
MapView : +routeOverlayData RouteMapData?
MapView o-- RouteMapData
MapView : +routeVehicleMarker RouteVehicleMarker?
MapView o-- RouteVehicleMarker
MapView : +routeFitPadding EdgeInsets
MapView o-- EdgeInsets
MapView : +showRouteStopLabels bool
MapView : +useBaseMapStopIcon bool
MapView : +onShowTripOnBackgroundMap void FunctionRouteMapData, RouteVehicleMarker??
MapView o-- void FunctionRouteMapData, RouteVehicleMarker
MapView : +onOpenTripDetailsRequested dynamic FunctionString, String?
MapView o-- dynamic FunctionString, String
MapView : +onOpenStopDetailsRequested dynamic FunctionString, String?, LatLng?, List~String~??
MapView o-- dynamic FunctionString, String, LatLng, List~String~
MapView : +hideGeneralStopsAndVehicles bool
MapView : +createState() State<MapView>
StatefulWidget <|-- MapView

class _MapViewState
_MapViewState : -_graphqlClient GraphqlClient
_MapViewState o-- GraphqlClient
_MapViewState : -_minZoom$ double
_MapViewState : -_maxZoom$ double
_MapViewState : -_coachMinZoom$ double
_MapViewState : -_localMinZoom$ double
_MapViewState : -_stopMinZoom$ double
_MapViewState : -_lastLatKey$ String
_MapViewState : -_lastLonKey$ String
_MapViewState : -_railModes$ List~String~
_MapViewState : -_coachModes$ List~String~
_MapViewState : -_localModes$ List~String~
_MapViewState : -_fallbackWhiteHexColors$ Set~String~
_MapViewState : -_spanFontFamily$ String
_MapViewState : -_spanFontScale$ double
_MapViewState : -_mapReady dynamic
_MapViewState : -_mapController MapController
_MapViewState o-- MapController
_MapViewState : -_mapEventSubscription StreamSubscription~MapEvent~
_MapViewState o-- StreamSubscription~MapEvent~
_MapViewState : -_vehicleRefreshDebounce Timer?
_MapViewState o-- Timer
_MapViewState : -_vehiclePeriodicRefresh Timer?
_MapViewState o-- Timer
_MapViewState : -_vehicleRequestNonce int
_MapViewState : -_vehicleMarkers List~_VehicleMarkerData~
_MapViewState : -_nearbyStops List~_MapStopData~
_MapViewState : -_selectedVehicleMarkerId String?
_MapViewState : -_selectedStopMarkerId String?
_MapViewState : -_selectedStopQuickInfo _StopQuickInfo?
_MapViewState o-- _StopQuickInfo
_MapViewState : -_isLoadingSelectedStopQuickInfo bool
_MapViewState : -_isRotated bool
_MapViewState : -_isLocating bool
_MapViewState : -_isLoadingVehicles bool
_MapViewState : -_isRotationGestureEnabled bool
_MapViewState : -_suppressNextMapTapClose bool
_MapViewState : -_didTryInitialGpsFocus bool
_MapViewState : -_lastStoredLocation LatLng?
_MapViewState o-- LatLng
_MapViewState : -_hasRouteOverlayContent bool
_MapViewState : -_useDesktopDialogs bool
_MapViewState : +initState() void
_MapViewState : +didUpdateWidget() void
_MapViewState : -_overlayRoutePoints() List<LatLng>
_MapViewState : -_initialOverlayCameraFit() CameraFit?
_MapViewState : -_overlayRouteFallbackCenter() LatLng?
_MapViewState : -_fitToOverlayRoute() void
_MapViewState : -_routeStopColor() Color
_MapViewState : -_buildRouteVehicleDot() Widget
_MapViewState : -_zoomBy() void
_MapViewState : -_resetNorth() void
_MapViewState : -_toggleRotationGesture() void
_MapViewState : -_moveToPosition() void
_MapViewState : -_scheduleVehicleRefresh() void
_MapViewState : -_modesForZoom() List<String>
_MapViewState : -_maxVehiclesForZoom() int
_MapViewState : -_maxStopsForZoom() int
_MapViewState : +dispose() void
_MapViewState : +build() Widget
_MapViewState : -_openTripDetails() dynamic
_MapViewState : +refreshState() void
State <|-- _MapViewState

class _VehicleMarkerData
_VehicleMarkerData : +markerId String
_VehicleMarkerData : +tripGtfsId String
_VehicleMarkerData : +serviceDate String
_VehicleMarkerData : +point LatLng
_VehicleMarkerData o-- LatLng
_VehicleMarkerData : +headingDegrees double
_VehicleMarkerData : +serviceLabel String
_VehicleMarkerData : +serviceLabelUsesSpanFont bool
_VehicleMarkerData : +routeShortName String
_VehicleMarkerData : +routeShortNameUsesSpanFont bool
_VehicleMarkerData : +tripNumber String
_VehicleMarkerData : +tripNumberUsesSpanFont bool
_VehicleMarkerData : +tripHeadsign String
_VehicleMarkerData : +tripHeadsignUsesSpanFont bool
_VehicleMarkerData : +vehicleModel String
_VehicleMarkerData : +arrivalDelaySeconds int?
_VehicleMarkerData : +nextStopName String?
_VehicleMarkerData : +mode String
_VehicleMarkerData : +markerColor Color
_VehicleMarkerData o-- Color
_VehicleMarkerData : +markerTextColor Color
_VehicleMarkerData o-- Color
_VehicleMarkerData : +markerOutlineHeadingColor Color
_VehicleMarkerData o-- Color
_VehicleMarkerData : +vehicleSpeed int
_VehicleMarkerData : +nextStopStatus String

class _MapStopData
_MapStopData : +stopId String
_MapStopData : +name String
_MapStopData : +point LatLng
_MapStopData o-- LatLng
_MapStopData : +bearing double?

class _StopQuickInfo
_StopQuickInfo : +stopName String
_StopQuickInfo : +lineCount int
_StopQuickInfo : +lines List~_StopQuickRoute~

class _StopQuickRoute
_StopQuickRoute : +id String
_StopQuickRoute : +label String
_StopQuickRoute : +usesSpanFont bool
_StopQuickRoute : +backgroundColor Color
_StopQuickRoute o-- Color
_StopQuickRoute : +textColor Color
_StopQuickRoute o-- Color

class PlanMapView
PlanMapView : +routeData RouteMapData
PlanMapView o-- RouteMapData
PlanMapView : +fitPadding EdgeInsets
PlanMapView o-- EdgeInsets
PlanMapView : +controlsBottomInset double
PlanMapView : +initialZoom double
PlanMapView : +singlePointZoom double
PlanMapView : +showRotationControls bool
PlanMapView : +showMyLocationButton bool
PlanMapView : +showStopLabels bool
PlanMapView : +useBaseMapStopIcon bool
PlanMapView : +vehicleMarker RouteVehicleMarker?
PlanMapView o-- RouteVehicleMarker
PlanMapView : +enableVehicleInfoLabelTap bool
PlanMapView : +vehicleInfoCardBuilder Widget FunctionBuildContext?
PlanMapView o-- Widget FunctionBuildContext
PlanMapView : +enableStopInfoLabelTap bool
PlanMapView : +stopInfoCardBuilder Widget FunctionBuildContext, RouteStopMarker?
PlanMapView o-- Widget FunctionBuildContext, RouteStopMarker
PlanMapView : +createState() State<PlanMapView>
StatefulWidget <|-- PlanMapView

class _PlanMapViewState
_PlanMapViewState : -_minZoom$ double
_PlanMapViewState : -_maxZoom$ double
_PlanMapViewState : -_mapReady dynamic
_PlanMapViewState : -_mapController MapController
_PlanMapViewState o-- MapController
_PlanMapViewState : -_mapEventSubscription StreamSubscription~MapEvent~
_PlanMapViewState o-- StreamSubscription~MapEvent~
_PlanMapViewState : -_isRotated bool
_PlanMapViewState : -_isRotationGestureEnabled bool
_PlanMapViewState : -_isVehicleLabelVisible bool
_PlanMapViewState : -_isStopLabelVisible bool
_PlanMapViewState : -_selectedStopSelectionKey String?
_PlanMapViewState : -_suppressNextMapTapClose bool
_PlanMapViewState : -_isLocating bool
_PlanMapViewState : +initState() void
_PlanMapViewState : +dispose() void
_PlanMapViewState : +didUpdateWidget() void
_PlanMapViewState : -_toggleVehicleLabel() void
_PlanMapViewState : -_stopSelectionKey() String
_PlanMapViewState : -_toggleStopLabel() void
_PlanMapViewState : -_consumeNextMapTapClose() void
_PlanMapViewState : -_onMapTap() void
_PlanMapViewState : -_scheduleFitToRoute() void
_PlanMapViewState : -_collectPointsForBounds() List<LatLng>
_PlanMapViewState : -_initialCameraFit() CameraFit?
_PlanMapViewState : -_fitToRoute() void
_PlanMapViewState : -_zoomBy() void
_PlanMapViewState : -_moveToPosition() void
_PlanMapViewState : -_resetNorth() void
_PlanMapViewState : -_toggleRotationGesture() void
_PlanMapViewState : -_jumpToCurrentLocation() dynamic
_PlanMapViewState : -_markerColor() Color
_PlanMapViewState : +build() Widget
_PlanMapViewState : -_buildBaseMapStopDot() Widget
_PlanMapViewState : -_buildPinStopDot() Widget
_PlanMapViewState : -_buildStopMarkerChild() Widget
_PlanMapViewState : -_buildVehicleDot() Widget
State <|-- _PlanMapViewState

class RouteSegment
RouteSegment : +points List~LatLng~
RouteSegment : +color Color
RouteSegment o-- Color
RouteSegment : +isWalk bool
RouteSegment : +hashCode int
RouteSegment : +==() bool

class RouteStopMarker
RouteStopMarker : +point LatLng
RouteStopMarker o-- LatLng
RouteStopMarker : +label String
RouteStopMarker : +type RouteStopType
RouteStopMarker o-- RouteStopType
RouteStopMarker : +stopId String?
RouteStopMarker : +bearing double?
RouteStopMarker : +platformCode String?
RouteStopMarker : +hashCode int
RouteStopMarker : +==() bool

class RouteVehicleMarker
RouteVehicleMarker : +point LatLng
RouteVehicleMarker o-- LatLng
RouteVehicleMarker : +headingDegrees double
RouteVehicleMarker : +markerColor Color
RouteVehicleMarker o-- Color
RouteVehicleMarker : +markerTextColor Color
RouteVehicleMarker o-- Color
RouteVehicleMarker : +lineLabel String
RouteVehicleMarker : +lineLabelUsesSpanFont bool
RouteVehicleMarker : +tripShortName String
RouteVehicleMarker : +tripShortNameUsesSpanFont bool
RouteVehicleMarker : +tripHeadsign String
RouteVehicleMarker : +tripHeadsignUsesSpanFont bool
RouteVehicleMarker : +vehicleInfoText String
RouteVehicleMarker : +tripId String?
RouteVehicleMarker : +serviceDay String?
RouteVehicleMarker : +hashCode int
RouteVehicleMarker : +==() bool

class RouteMapData
RouteMapData : +segments List~RouteSegment~
RouteMapData : +stops List~RouteStopMarker~
RouteMapData : +hasContent bool
RouteMapData : +hashCode int
RouteMapData : +==() bool

class RouteStopType
<<enumeration>> RouteStopType
RouteStopType : +index int
RouteStopType : +values$ List~RouteStopType~
RouteStopType : +start$ RouteStopType
RouteStopType o-- RouteStopType
RouteStopType : +transfer$ RouteStopType
RouteStopType o-- RouteStopType
RouteStopType : +end$ RouteStopType
RouteStopType o-- RouteStopType
Enum <|.. RouteStopType

class VehicleInfoCard
VehicleInfoCard : +lineLabel String
VehicleInfoCard : +lineLabelUsesSpanFont bool
VehicleInfoCard : +tripNumberLabel String
VehicleInfoCard : +tripHeadsignLabel String
VehicleInfoCard : +serviceLabel String
VehicleInfoCard : +modelLabel String
VehicleInfoCard : +vehicleSpeed int
VehicleInfoCard : +arrivalDelaySeconds int?
VehicleInfoCard : +nextStopName String?
VehicleInfoCard : +markerColor Color
VehicleInfoCard o-- Color
VehicleInfoCard : +markerTextColor Color
VehicleInfoCard o-- Color
VehicleInfoCard : +nextStopStatus String
VehicleInfoCard : +onTap void Function?
VehicleInfoCard o-- void Function
VehicleInfoCard : -_spanFontFamily$ String
VehicleInfoCard : -_spanFontScale$ double
VehicleInfoCard : -_formatDelayValue() String
VehicleInfoCard : -_delayColor() Color
VehicleInfoCard : +build() Widget
StatelessWidget <|-- VehicleInfoCard

class DesktopDropdownButton
DesktopDropdownButton : +title String
DesktopDropdownButton : +items List~String~
DesktopDropdownButton : +onSelected void FunctionString?
DesktopDropdownButton o-- void FunctionString
DesktopDropdownButton : +build() Widget
StatelessWidget <|-- DesktopDropdownButton

class MainMobileDrawer
MainMobileDrawer : +build() Widget
StatelessWidget <|-- MainMobileDrawer

class TopNavbar
TopNavbar : +isDesktop bool
TopNavbar : +onHomeTap void Function
TopNavbar o-- void Function
TopNavbar : +onNewsTap void Function
TopNavbar o-- void Function
TopNavbar : +onProfileTap void Function
TopNavbar o-- void Function
TopNavbar : +selectedDesktopTabIndex int
TopNavbar : +mobileCurrentSectionTitle String
TopNavbar : -_buildDesktopNavButton() Widget
TopNavbar : +build() Widget
StatelessWidget <|-- TopNavbar

class RealtimeTimeText
RealtimeTimeText : +scheduled num?
RealtimeTimeText : +realtime num?
RealtimeTimeText : +delay num?
RealtimeTimeText : +isRealtime bool
RealtimeTimeText : +passedStop bool
RealtimeTimeText : +serviceDay String
RealtimeTimeText : +suffix String?
RealtimeTimeText : +tooltipType String
RealtimeTimeText : +customTooltip String?
RealtimeTimeText : +build() Widget
StatelessWidget <|-- RealtimeTimeText

class SelectedItineraryMapPayload
SelectedItineraryMapPayload : +routeData RouteMapData
SelectedItineraryMapPayload o-- RouteMapData
SelectedItineraryMapPayload : +title String
SelectedItineraryMapPayload : +subtitle String
SelectedItineraryMapPayload : +legDetails List~SelectedItineraryLegDetail~

class SelectedItineraryLegDetail
SelectedItineraryLegDetail : +icon IconData
SelectedItineraryLegDetail o-- IconData
SelectedItineraryLegDetail : +fromName String
SelectedItineraryLegDetail : +toName String
SelectedItineraryLegDetail : +subtitle String

class RoutePlannerResultsView
RoutePlannerResultsView : -_spanFontFamily$ String
RoutePlannerResultsView : -_desktopBreakpoint$ double
RoutePlannerResultsView : +responseText String
RoutePlannerResultsView : +onShowOnMap void FunctionSelectedItineraryMapPayload
RoutePlannerResultsView o-- void FunctionSelectedItineraryMapPayload
RoutePlannerResultsView : +onShowTripOnMap void FunctionRouteMapData, RouteVehicleMarker??
RoutePlannerResultsView o-- void FunctionRouteMapData, RouteVehicleMarker
RoutePlannerResultsView : +desktopInlineMapMode bool
RoutePlannerResultsView : +hasDesktopMapSelection bool
RoutePlannerResultsView : +canLoadMore bool
RoutePlannerResultsView : +isLoadingMore bool
RoutePlannerResultsView : +onLoadMore dynamic Function?
RoutePlannerResultsView o-- dynamic Function
RoutePlannerResultsView : +ticketWatch bool
RoutePlannerResultsView : +tickets List~TicketItem~
RoutePlannerResultsView : +onOpenTripDetailsRequested dynamic FunctionString, String?
RoutePlannerResultsView o-- dynamic FunctionString, String
RoutePlannerResultsView : +build() Widget
RoutePlannerResultsView : -_buildBentoHeader() Widget
RoutePlannerResultsView : -_buildLegTiles() List<Widget>
RoutePlannerResultsView : -_buildLineBadges() List<Widget>
RoutePlannerResultsView : -_buildRouteMapData() RouteMapData
RoutePlannerResultsView : -_buildMapPayload() SelectedItineraryMapPayload
RoutePlannerResultsView : -_buildResultsHeader() String
RoutePlannerResultsView : -_buildLegDetails() List<SelectedItineraryLegDetail>
RoutePlannerResultsView : -_extractLegPoints() List<LatLng>
RoutePlannerResultsView : -_extractPoint() LatLng?
RoutePlannerResultsView : -_legLineNumber() String
RoutePlannerResultsView : -_iconForMode() IconData
RoutePlannerResultsView : -_containsSpanMarkup() bool
StatelessWidget <|-- RoutePlannerResultsView

class TripStopTimesList
TripStopTimesList : +stopTimes List~TripStopTime~
TripStopTimesList : +serviceDay String
TripStopTimesList : +onStopTap void Function{required LatLng? initialStopPoint, required String stopId, required String stopName}
TripStopTimesList o-- void Function{required LatLng initialStopPoint, required String stopId, required String stopName}
TripStopTimesList : +build() Widget
TripStopTimesList : -_showStopAlertsDialog() void
StatelessWidget <|-- TripStopTimesList
