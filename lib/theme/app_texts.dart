enum AppLanguage { hu, en }

class AppTexts {
  const AppTexts._();

  static AppLanguage _language = AppLanguage.hu;

  static AppLanguage get language => _language;

  static void setLanguage(AppLanguage lang) {
    _language = lang;
  }

  static bool get isHungarian => _language == AppLanguage.hu;
  static bool get isEnglish => _language == AppLanguage.en;

  // Global & Navigation
  static String get appTitle => 'TERKA';
  static String get search => isHungarian ? 'Keresés' : 'Search';
  static String get home => isHungarian ? 'Főoldal' : 'Home';
  static String get news => isHungarian ? 'Hírek' : 'News';
  static String get map => isHungarian ? 'Térkép' : 'Map';
  static String get profile => isHungarian ? 'Profil' : 'Profile';
  static String get back => isHungarian ? 'Vissza' : 'Back';
  static String get menu => isHungarian ? 'Menü' : 'Menu';
  static String get lists => isHungarian ? 'Listázások' : 'Lists';
  static String get stops => isHungarian ? 'Megállók' : 'Stops';
  static String get lines => isHungarian ? 'Vonalak' : 'Lines';
  static String get mavNews => isHungarian ? 'MÁV Hírek' : 'MÁV News';

  static String get myTickets => isHungarian ? 'Jegyeim' : 'My Tickets';
  static String get addTicket => isHungarian ? 'Jegy hozzáadása' : 'Add Ticket';
  static String get logout => isHungarian ? 'Kijelentkezés' : 'Logout';
  static String get login => isHungarian ? 'Bejelentkezés' : 'Login';
  static String get register => isHungarian ? 'Regisztráció' : 'Register';
  static String get retry => isHungarian ? 'Újrapróbálás' : 'Retry';
  static String get save => isHungarian ? 'Mentés' : 'Save';
  static String get saving => isHungarian ? 'Mentés...' : 'Saving...';
  static String get processInProgress =>
      isHungarian ? 'Folyamatban...' : 'In progress...';
  static String get failed => isHungarian ? 'Sikertelen' : 'Failed';
  static String get success => isHungarian ? 'Sikeres' : 'Success';
  static String get error => isHungarian ? 'Hiba' : 'Error';
  static String get unknown => isHungarian ? 'Ismeretlen' : 'Unknown';
  static String get unknownVehicle =>
      isHungarian ? 'ismeretlen jármű' : 'unknown vehicle';
  static String get estimatedPosition =>
      isHungarian ? 'Becsült pozíció' : 'Estimated position';
  static String get railReplacementBus =>
      isHungarian ? 'vonatpótló busz' : 'rail replacement bus';
  static String get noData =>
      isHungarian ? 'Nincs megjeleníthető adat.' : 'No data to display.';
  static String get system => isHungarian ? 'Rendszer' : 'System';
  static String get appearance => isHungarian ? 'Megjelenés' : 'Appearance';
  static String get lightMode => isHungarian ? 'Világos' : 'Light';
  static String get darkMode => isHungarian ? 'Sötét' : 'Dark';
  static String get systemMode => isHungarian ? 'Rendszer' : 'System';
  static String get languageLabel => isHungarian ? 'Nyelv' : 'Language';

  // About Screen
  static String get aboutTitle => isHungarian ? 'Névjegy' : 'About';
  static String get aboutAppName => isHungarian ? 'Alkalmazás' : 'Application';
  static String aboutDescription(String appName) => isHungarian
      ? '$appName - Teljesen Részletes Közlekedési Adatbázis'
      : '$appName - Fully Detailed Transport Database';
  static String version(String version) =>
      isHungarian ? 'Verzió: $version' : 'Version: $version';
  static String get aboutCreatedBy => isHungarian
      ? 'Készítette: Baranyai Brúnó (R150)\n\nProbléma esetén írj ide: info.railway150@gmail.com'
      : 'Created by: Brúnó Baranyai (R150)\n\nIn case of problems, write to: info.railway150@gmail.com';
  static String get specialThanks => isHungarian
      ? 'Nagy-Pálóczi Regőnek - "Ismeretlen járművek típusainak azonosításában nyújtott segitségéért"'
      : 'To Regő Nagy-Pálóczi - "For his help in identifying unknown vehicle types"';
  static String get specialThanksTitle =>
      isHungarian ? 'Külön köszönet' : 'Special thanks';

  // Tickets Screen
  static String get ticketsTitle => isHungarian ? 'Jegyeim' : 'My Tickets';
  static String get ticketsLoadFailed => isHungarian
      ? 'Nem sikerült lekérni a jegyeket.'
      : 'Failed to retrieve tickets.';
  static String get ticketsEmpty => isHungarian
      ? 'Nincs még jegyed. A Profil -> Jegy hozzáadása gombbal tudsz felvenni.'
      : 'You don\'t have any tickets yet. Add one in Profile -> Add Ticket.';
  static String get ticketsModify => isHungarian ? 'Módosítás' : 'Modify';
  static String get ticketsDelete => isHungarian ? 'Törlés' : 'Delete';
  static String get ticketsDeleteConfirmTitle =>
      isHungarian ? 'Jegy törlése' : 'Delete Ticket';
  static String ticketsDeleteConfirmContent(String name) => isHungarian
      ? 'Biztosan törölni szeretnéd a következő jegyet?\n\n$name'
      : 'Are you sure you want to delete the following ticket?\n\n$name';
  static String get ticketsCancel => isHungarian ? 'Mégse' : 'Cancel';
  static String get ticketsDeleteSuccess =>
      isHungarian ? 'Jegy sikeresen törölve!' : 'Ticket successfully deleted!';
  static String get ticketsDeleteFailed => isHungarian
      ? 'Nem sikerült törölni a jegyet.'
      : 'Failed to delete ticket.';
  static String ticketsType(String type) =>
      isHungarian ? 'Típus: $type' : 'Type: $type';
  static String ticketsStart(String start) =>
      isHungarian ? 'Kezdet: $start' : 'Start: $start';
  static String ticketsEnd(String end) =>
      isHungarian ? 'Lejárat: $end' : 'Expiry: $end';
  static String ticketsQuantity(String qty) =>
      isHungarian ? 'Mennyiség: $qty' : 'Quantity: $qty';
  static String ticketsMissingFor(String agencies) => isHungarian
      ? 'Nincs jegyed a következőhöz: $agencies'
      : 'No tickets for: $agencies';

  // Add/Edit Ticket Screen
  static String get addTicketTitle =>
      isHungarian ? 'Jegy hozzáadása' : 'Add Ticket';
  static String get editTicketTitle =>
      isHungarian ? 'Jegy módosítása' : 'Edit Ticket';
  static String get addTicketTypeLabel =>
      isHungarian ? 'Jegy típusa:' : 'Ticket Type:';
  static String get addTicketTypeSingle =>
      isHungarian ? 'Vonaljegy' : 'Single Ticket';
  static String get addTicketTypePass => isHungarian ? 'Bérlet' : 'Pass';
  static String get addTicketAgencyLabel =>
      isHungarian ? 'Szolgáltató' : 'Agency';
  static String get addTicketAgencyValidator =>
      isHungarian ? 'Válassz szolgáltatót.' : 'Please select an agency.';
  static String get addTicketQuantityLabel =>
      isHungarian ? 'Mennyiség' : 'Quantity';
  static String get addTicketQuantityEmpty =>
      isHungarian ? 'Add meg a mennyiséget.' : 'Please enter the quantity.';
  static String get addTicketQuantityPositive => isHungarian
      ? 'Pozitív egész számot adj meg.'
      : 'Please enter a positive integer.';
  static String get addTicketPassTypeLabel =>
      isHungarian ? 'Bérlettípus' : 'Pass Type';
  static String get addTicketPassTypeValidator =>
      isHungarian ? 'Válassz bérlettípust.' : 'Please select a pass type.';
  static String get addTicketValidityStartLabel =>
      isHungarian ? 'Érvényesség kezdete' : 'Validity Start';
  static String get addTicketValidityStartValidator =>
      isHungarian ? 'Add meg a kezdő dátumot.' : 'Please enter the start date.';
  static String get addTicketSave => isHungarian ? 'Mentés' : 'Save';
  static String get addTicketAdd => isHungarian ? 'Hozzáadás' : 'Add';
  static String get addTicketFailed => isHungarian
      ? 'Nem sikerült hozzáadni a jegyet.'
      : 'Failed to add ticket.';
  static String get addTicketSuccess =>
      isHungarian ? 'Jegy hozzáadva!' : 'Ticket added!';
  static String get addTicketOptionsLoadFailed => isHungarian
      ? 'Nem sikerült betölteni az opciókat.'
      : 'Failed to load options.';

  // Manage Pass Types Screen
  static String get managePassTypesTitle =>
      isHungarian ? 'Bérlettípusok kezelése' : 'Manage Pass Types';
  static String get managePassTypesNew =>
      isHungarian ? 'Új bérlettípus' : 'New Pass Type';
  static String get managePassTypesEmpty =>
      isHungarian ? 'Nincsenek bérlettípusok.' : 'No pass types found.';
  static String managePassTypesDuration(String duration) =>
      isHungarian ? 'Érvényesség: $duration' : 'Validity: $duration';
  static String managePassTypesAgencies(List<String> agencies) {
    if (agencies.isEmpty) {
      return isHungarian ? 'Érvényes szolgáltatók: -' : 'Valid agencies: -';
    }
    if (agencies.length <= 3) {
      final joined = agencies.join(", ");
      return isHungarian
          ? 'Érvényes szolgáltatók: $joined'
          : 'Valid agencies: $joined';
    } else {
      final firstThree = agencies.take(3).join(", ");
      final additional = agencies.length - 3;
      return isHungarian
          ? 'Érvényes szolgáltatók: $firstThree és $additional további'
          : 'Valid agencies: $firstThree and $additional more';
    }
  }
  static String get managePassTypesDeleteTitle =>
      isHungarian ? 'Bérlettípus törlése' : 'Delete Pass Type';
  static String managePassTypesDeleteContent(String name) => isHungarian
      ? 'Biztosan törölni szeretnéd a(z) "$name" bérlettípust?'
      : 'Are you sure you want to delete "$name" pass type?';
  static String get managePassTypesDeleteButton =>
      isHungarian ? 'Törlés' : 'Delete';
  static String get managePassTypesEditTitle =>
      isHungarian ? 'Bérlettípus módosítása' : 'Edit Pass Type';
  static String get managePassTypesNewTitle =>
      isHungarian ? 'Új bérlettípus' : 'New Pass Type';
  static String get managePassTypesNameLabel =>
      isHungarian ? 'Bérlet neve' : 'Pass Name';
  static String get managePassTypesNameValidator =>
      isHungarian ? 'Add meg a bérlet nevét.' : 'Please enter the pass name.';
  static String get managePassTypesDurationTypeLabel =>
      isHungarian ? 'Érvényesség időtartama:' : 'Validity Duration:';
  static String get managePassTypesDurationMonth =>
      isHungarian ? '1 hónap' : '1 month';
  static String get managePassTypesDurationCustom =>
      isHungarian ? 'Egyéni (nap)' : 'Custom (days)';
  static String get managePassTypesCustomDaysLabel =>
      isHungarian ? 'Érvényes napok száma' : 'Number of valid days';
  static String get managePassTypesCustomDaysEmpty => isHungarian
      ? 'Add meg a napok számát.'
      : 'Please enter the number of days.';
  static String get managePassTypesCustomDaysPositive => isHungarian
      ? 'Pozitív egész számot adj meg.'
      : 'Please enter a positive integer.';
  static String get managePassTypesSelectedAgencies =>
      isHungarian ? 'Kiválasztott szolgáltatók:' : 'Selected Agencies:';
  static String get managePassTypesSearchAgency =>
      isHungarian ? 'Szolgáltató keresése...' : 'Search agency...';
  static String get managePassTypesAgenciesList =>
      isHungarian ? 'Szolgáltatók listája:' : 'List of Agencies:';
  static String get managePassTypesNoAgenciesFound =>
      isHungarian ? 'Nincs találat' : 'No results found';
  static String get managePassTypesSavePassType =>
      isHungarian ? 'Bérlettípus mentése' : 'Save Pass Type';
  static String get managePassTypesSelectMinOneAgency => isHungarian
      ? 'Válassz legalább egy szolgáltatót.'
      : 'Please select at least one agency.';
  static String get managePassTypesLoadAgenciesFailed => isHungarian
      ? 'Nem sikerült betölteni a szolgáltatókat.'
      : 'Failed to load agencies.';

  // News Screen
  static String get newsTitle => isHungarian ? 'MÁV Hírek' : 'MÁV News';
  static String get newsLoadFailed => isHungarian
      ? 'Nem sikerült betölteni a híreket.'
      : 'Failed to load news.';
  static String get newsLoadError => isHungarian
      ? 'Hiba történt a hírek betöltése közben.'
      : 'An error occurred while loading news.';
  static String get newsEmpty =>
      isHungarian ? 'Nincsenek elérhető hírek.' : 'No news available.';
  static String get newsLinkOpenFailed => isHungarian
      ? 'A hír linkje nem nyitható meg.'
      : 'The link to the news cannot be opened.';
  static String get newsInstruction => isHungarian
      ? 'Kattints egy címre a cikk megnyitásához.'
      : 'Click on a title to open the article.';
  static String get newsLanguageWarning => isHungarian
      ? 'A hírek többnyire magyar nyelven érhetőek el.'
      : 'News are mostly available in Hungarian.';

  // Profile Screen
  static String get profileLabelAppearance =>
      isHungarian ? 'Megjelenés' : 'Appearance';
  static String get profileAppearanceVilagos =>
      isHungarian ? 'Világos' : 'Light';
  static String get profileAppearanceSotet => isHungarian ? 'Sötét' : 'Dark';
  static String get profileAppearanceRendszer =>
      isHungarian ? 'Rendszer' : 'System';
  static String get profileMyTickets => isHungarian ? 'Jegyeim' : 'My Tickets';
  static String get profileAddTicket =>
      isHungarian ? 'Jegy hozzáadása' : 'Add Ticket';
  static String get profileManagePassTypes =>
      isHungarian ? 'Bérlettípusok kezelése' : 'Manage Pass Types';
  static String get profileAboutApp =>
      isHungarian ? 'Alkalmazás névjegye' : 'About Application';
  static String get profileLanguage => isHungarian ? 'Nyelv' : 'Language';

  // Main Screen
  static String get mainDefaultPlanResponse =>
      isHungarian ? 'Még nincs lekérdezés.' : 'No queries yet.';
  static String get mainLoadMoreFailed => isHungarian
      ? 'Nem sikerült további találatokat betölteni.'
      : 'Failed to load more results.';
  static String mainLoadMoreHttpFailed(String status) => isHungarian
      ? 'További betöltés sikertelen (HTTP $status).'
      : 'Further loading failed (HTTP $status).';
  static String get mainRoutePlanning =>
      isHungarian ? 'Útvonaltervezés' : 'Route Planning';
  static String get mainMavNews => isHungarian ? 'MÁV Hírek' : 'MÁV News';
  static String get mainMap => isHungarian ? 'Térkép' : 'Map';
  static String get mainProfile => isHungarian ? 'Profil' : 'Profile';
  static String get mainHome => isHungarian ? 'Főoldal' : 'Home';
  static String get mainNews => isHungarian ? 'Hírek' : 'News';
  static String get mainRouteOnMap =>
      isHungarian ? 'Útvonal térképen' : 'Route on Map';

  // Route Plan Form
  static String get formDeparture => isHungarian ? 'Indulás' : 'Departure';
  static String get formHintCharCount => isHungarian
      ? 'Írj be legalább 3 karaktert...'
      : 'Type at least 3 characters...';
  static String get formArrival => isHungarian ? 'Érkezés' : 'Arrival';
  static String get formSwap => isHungarian ? 'Megfordítás' : 'Swap';
  static String get formDepartNow =>
      isHungarian ? 'Indulás most' : 'Depart now';
  static String get formDepartLater =>
      isHungarian ? 'Indulás később' : 'Depart later';
  static String get formDate => isHungarian ? 'Dátum' : 'Date';
  static String get formPickDate =>
      isHungarian ? 'Válassz dátumot' : 'Select date';
  static String get formDepartureTime =>
      isHungarian ? 'Indulás (idő)' : 'Departure time';
  static String get formArrivalTime =>
      isHungarian ? 'Érkezés (idő)' : 'Arrival time';
  static String get formPickTime =>
      isHungarian ? 'Válassz időt' : 'Select time';
  static String get formSearch => isHungarian ? 'Keresés' : 'Search';
  static String get formHideAdvanced =>
      isHungarian ? 'További beállítások elrejtése' : 'Hide advanced settings';
  static String get formShowAdvanced =>
      isHungarian ? 'További beállítások' : 'Advanced settings';
  static String get formTransfers => isHungarian ? 'Átszállások' : 'Transfers';
  static String get formWalking => isHungarian ? 'Gyaloglás' : 'Walking';
  static String get formTransportModes =>
      isHungarian ? 'Közlekedési módok' : 'Transport Modes';
  static String get formTicketWatch =>
      isHungarian ? 'Jegyfigyelés' : 'Ticket Tracking';

  static String localizeTransportMode(String mode) {
    switch (mode) {
      case 'Helyi busz':
        return isHungarian ? 'Helyi busz' : 'Local bus';
      case 'Helyközi busz':
        return isHungarian ? 'Helyközi busz' : 'Regional bus';
      case 'Vonat':
        return isHungarian ? 'Vonat' : 'Train';
      case 'Metró':
        return isHungarian ? 'Metró' : 'Subway';
      case 'Troli':
        return isHungarian ? 'Troli' : 'Trolleybus';
      case 'Villamos':
        return isHungarian ? 'Villamos' : 'Tram';
      case 'Hajó':
        return isHungarian ? 'Hajó' : 'Ferry';
      case 'Busz':
        return isHungarian ? 'Busz' : 'Bus';
      default:
        return mode;
    }
  }

  // Stop Details Screen
  static String stopErrorUpdate(String msg) =>
      isHungarian ? 'Nem sikerült a frissítés: $msg' : 'Update failed: $msg';
  static String get stopInvalidResponse =>
      isHungarian ? 'Érvénytelen válasz formátum.' : 'Invalid response format.';
  static String get stopDetailsNotAvailable => isHungarian
      ? 'A megálló adatai nem érhetők el.'
      : 'Stop details not available.';
  static String get stopNoData =>
      isHungarian ? 'Nincs megjeleníthető adat.' : 'No data to display.';
  static String get stopPrevDay => isHungarian ? 'Előző nap' : 'Previous day';
  static String get stopNextDay => isHungarian ? 'Következő nap' : 'Next day';
  static String stopDateLabel(String date) =>
      isHungarian ? 'Dátum: $date' : 'Date: $date';
  static String get stopToday => isHungarian ? 'Ma' : 'Today';
  static String get stopHidePast =>
      isHungarian ? 'Korábbi járatok elrejtése' : 'Hide past departures';
  static String get stopShowPast =>
      isHungarian ? 'Korábbi járatok mutatása' : 'Show past departures';
  static String get stopArrivals => isHungarian ? 'Érkezik' : 'Arrivals';
  static String get stopDepartures => isHungarian ? 'Indulások' : 'Departures';
  static String get stopSchedule => isHungarian ? 'Menetrend' : 'Schedule';
  static String get stopArrivalDeparture =>
      isHungarian ? 'Érkezik/Indul' : 'Arrival/Departure';
  static String get stopTimeLabel => isHungarian ? 'Időpont' : 'Time';
  static String stopPlatform(String platform) =>
      isHungarian ? 'Kocsiállás: $platform' : 'Platform: $platform';
  static String get stopSwipeInstruction => isHungarian
      ? 'Pöccintsd fel a részletes indulásokhoz'
      : 'Swipe up for detailed departures';
  static String get stopNoArrivals =>
      isHungarian ? 'Nincs megjeleníthető érkezés.' : 'No arrivals to display.';
  static String get stopNoDepartures => isHungarian
      ? 'Nincs megjeleníthető indulás.'
      : 'No departures to display.';
  static String get stopDetailsLabel =>
      isHungarian ? 'Megálló adatai' : 'Stop details';
  static String get stopLineFilterTitle =>
      isHungarian ? 'Vonal-választó' : 'Line Selector';
  static String get stopLineFilterReset =>
      isHungarian ? 'Alaphelyzet' : 'Reset';

  // Trip Details Screen
  static String get trip => isHungarian ? 'Járat' : 'Trip';
  static String get tripRouteOnMap =>
      isHungarian ? 'Járat térképen' : 'Route on Map';
  static String get tripDetails =>
      isHungarian ? 'Járat adatai' : 'Trip Details';
  static String get tripDetailsNotAvailable => isHungarian
      ? 'A járat adatai nem érhetők el.'
      : 'Trip details not available.';
  static String get tripStopColumn => isHungarian ? 'Megálló' : 'Stop';
  static String get tripArrivalColumn => isHungarian ? 'Érk.' : 'Arr.';
  static String get tripDepartureColumn => isHungarian ? 'Ind.' : 'Dep.';
  static String get tripSwipeInstruction => isHungarian
      ? 'Pöccintsd fel az összes időadathoz'
      : 'Swipe up for all times';
  static String get tripDelayNa => isHungarian ? 'késés: n/a' : 'delay: n/a';
  static String tripDelayMinutes(String mins) =>
      isHungarian ? 'késés: $mins p' : 'delay: $mins m';
  static String get tripDelayZero => isHungarian ? 'késés: 0p' : 'delay: 0m';
  static String get tripNoVehicle =>
      isHungarian ? 'Nem található jármű' : 'No vehicle found';
  static String get tripNextStopPrefix => isHungarian ? 'köv: ' : 'next: ';
  static String get tripNextStopStoppedAt =>
      isHungarian ? 'Itt állt meg: ' : 'Stopped at: ';
  static String get tripNextStopIncomingAt => isHungarian ? 'Ide érkezik: ' : 'Incoming at: ';
  static String get delayNa => 'n/a';
  static String get delayMinutesUnit => isHungarian ? 'p' : 'm';
  static String get delayZero => isHungarian ? '0p' : '0m';
  static String get delayPrefix => isHungarian ? 'késés: ' : 'delay: ';

  // Dummy Table
  static String get tableResults => isHungarian ? 'Találatok' : 'Results';
  static String get tableSegmentNotAvailable => isHungarian
      ? 'Szakasz adatok nem elérhetők.'
      : 'Segment details not available.';
  static String get tableWalk => isHungarian ? 'SÉTA' : 'WALK';
  static String get tableTransit => isHungarian ? 'JÁRAT' : 'TRANSIT';
  static String get tableWalkDetails =>
      isHungarian ? 'GYALOGLÁS RÉSZLETEI' : 'WALK DETAILS';
  static String get tableTransitDetails =>
      isHungarian ? 'UTAZÁS RÉSZLETEI' : 'TRIP DETAILS';
  static String get tableShowOnMap =>
      isHungarian ? 'Mutasd térképen!' : 'Show on Map!';
  static String get tableLoadMore =>
      isHungarian ? 'További járatok betöltése' : 'Load more trips';
  static String get tableDurationHeader => isHungarian
      ? 'MENETIDŐ, INDULÁS ÉS ÉRKEZÉS'
      : 'DURATION, DEPARTURE AND ARRIVAL';
  static String get tableTransitHeader => isHungarian ? 'JÁRATOK' : 'TRIPS';
  static String get tableWalkMode => isHungarian ? 'Gyalogos' : 'Walking';
  static String tableWaitThen(String mins) =>
      isHungarian ? 'majd $mins perc várakozás' : 'then $mins mins waiting';
  static String get tableWalkSubtitle => isHungarian ? 'gyaloglás' : 'walking';
  static String tableTripId(String id) =>
      isHungarian ? 'Járat azonosító: $id' : 'Trip ID: $id';
  static String get tableDirect => isHungarian ? 'Közvetlen' : 'Direct';
  static String tableTransfersCount(String count) =>
      isHungarian ? '$count átszállás' : '$count transfers';
  static String tableSubtitle(
    String duration,
    String transfers,
    String start,
    String end,
  ) => isHungarian
      ? 'Időtartam: $duration • Átszállás: $transfers • $start–$end'
      : 'Duration: $duration • Transfers: $transfers • $start–$end';
  static String tableResultsHeader(String from, String to) =>
      isHungarian ? 'Találatok: $from ▶ $to' : 'Results: $from ▶ $to';
  static String tableMinutes(String mins) =>
      isHungarian ? '$mins perc' : '$mins mins';
  static String tableHoursMinutes(String hours, String mins) =>
      isHungarian ? '$hours ó $mins perc' : '$hours h $mins mins';

  // Stations Table
  static String get stationsTitle => isHungarian ? 'Megállók' : 'Stops';
  static String get stationsName => isHungarian ? 'Megálló neve' : 'Stop name';
  static String get stationsCity => isHungarian ? 'Város' : 'City';
  static String get stationsZone => isHungarian ? 'Zóna' : 'Zone';
  static String get stationsType => isHungarian ? 'Típus' : 'Type';
  static String get stationsLat => isHungarian ? 'Szélesség' : 'Latitude';
  static String get stationsLon => isHungarian ? 'Hosszúság' : 'Longitude';

  // Plan Map View / Map View
  static String get mapLocationDisabled => isHungarian
      ? 'A helymeghatározás nincs bekapcsolva.'
      : 'Location services are disabled.';
  static String get mapPermissionRequired => isHungarian
      ? 'A helyhozzáférés engedély szükséges.'
      : 'Location permission is required.';
  static String get mapTimeout => isHungarian
      ? 'A pozíció lekérése túl sokáig tartott.'
      : 'Retrieving location timed out.';
  static String get mapPluginNotLoaded => isHungarian
      ? 'A lokáció plugin nincs betöltve. Indítsd újra az appot.'
      : 'Location plugin not loaded. Please restart the app.';
  static String get mapLocationFailed => isHungarian
      ? 'A lokáció lekérése nem sikerült.'
      : 'Failed to retrieve location.';
  static String get mapLoadFailed =>
      isHungarian ? 'A térképet nem sikerült betölteni' : 'Failed to load map.';
  static String get mapNoTripId => isHungarian
      ? 'Ehhez a járathoz nincs trip azonosító.'
      : 'No trip ID for this trip.';
  static String get mapTooltipMyLocation =>
      isHungarian ? 'Tartózkodási hely' : 'Current location';

  // Auth API Service & Network Errors
  static String get authSessionExpired => isHungarian
      ? 'Nincs aktív munkamenet. Jelentkezz be újra.'
      : 'Session expired. Please sign in again.';
  static String get authResponseIncomplete => isHungarian
      ? 'A szerver válasza hiányos.'
      : 'Server response is incomplete.';
  static String get authResponseInvalid => isHungarian
      ? 'A szerver válasza érvénytelen.'
      : 'Server response is invalid.';
  static String get authPassTypeMonth => isHungarian ? '1 hónap' : '1 month';
  static String authPassTypeDays(String days) =>
      isHungarian ? '$days nap' : '$days days';
  static String authLoadTicketsFailed(String msg) => isHungarian
      ? 'Hiba a jegyek betöltésekor: $msg'
      : 'Error loading tickets: $msg';
  static String get authNetworkTimeout => isHungarian
      ? 'A szerver nem válaszol időben. Ellenőrizd az internetet vagy próbáld újra később.'
      : 'The server did not respond in time. Check your internet or try again later.';
  static String get authNetworkBackendUnavailable => isHungarian
      ? 'Nem érhető el a backend. Ellenőrizd az internetkapcsolatot és hogy fut-e a szerver.'
      : 'Backend is unavailable. Check your internet connection and if the server is running.';
  static String get authNetworkGeneralError => isHungarian
      ? 'Hálózati hiba történt. Kérlek, próbáld újra.'
      : 'A network error occurred. Please try again.';
  static String authLoginFailedHttp(String status) => isHungarian
      ? 'Sikertelen bejelentkezés (HTTP $status).'
      : 'Login failed (HTTP $status).';
  static String get authLoginFailed =>
      isHungarian ? 'Sikertelen bejelentkezés.' : 'Login failed.';
  static String get authServerResponseIncomplete => isHungarian
      ? 'A szerver válasza hiányos.'
      : 'Server response is incomplete.';
  static String get authServerResponseInvalid => isHungarian
      ? 'A szerver válasza érvénytelen.'
      : 'Server response is invalid.';
  static String authRegistrationFailedHttp(String status) => isHungarian
      ? 'Sikertelen regisztráció (HTTP $status).'
      : 'Registration failed (HTTP $status).';
  static String get authRegistrationFailed =>
      isHungarian ? 'Sikertelen regisztráció.' : 'Registration failed.';
  static String get authRegistrationSuccess =>
      isHungarian ? 'Sikeres regisztráció.' : 'Registration successful.';
  static String authActivationFailedHttp(String status) => isHungarian
      ? 'Sikertelen aktiválás (HTTP $status).'
      : 'Activation failed (HTTP $status).';
  static String get authActivationSuccess => isHungarian
      ? 'A fiók sikeresen aktiválva.'
      : 'Account successfully activated.';
  static String authProfileUpdateFailedHttp(String status) => isHungarian
      ? 'Sikertelen profilmódosítás (HTTP $status).'
      : 'Profile update failed (HTTP $status).';
  static String get authProfileUpdateSuccess => isHungarian
      ? 'Profil sikeresen frissítve.'
      : 'Profile successfully updated.';
  static String authPasswordConfirmFailedHttp(String status) => isHungarian
      ? 'Sikertelen jelszó-megerősítés (HTTP $status).'
      : 'Password confirmation failed (HTTP $status).';
  static String get authPasswordConfirmSuccess => isHungarian
      ? 'Jelszó módosítva, jelentkezz be újra.'
      : 'Password changed, please sign in again.';
  static String get authTicketNotFound =>
      isHungarian ? 'A jegy nem található.' : 'Ticket not found.';
  static String get authAddTicketSuccess =>
      isHungarian ? 'Jegy sikeresen hozzáadva!' : 'Ticket successfully added!';
  static String authAddTicketError(String e) =>
      isHungarian ? 'Hiba a jegy hozzáadásakor: $e' : 'Error adding ticket: $e';
  static String get authUpdateTicketSuccess => isHungarian
      ? 'Jegy sikeresen módosítva!'
      : 'Ticket successfully updated!';
  static String authUpdateTicketError(String e) => isHungarian
      ? 'Hiba a jegy módosításakor: $e'
      : 'Error updating ticket: $e';
  static String get authDeleteTicketSuccess =>
      isHungarian ? 'Jegy sikeresen törölve!' : 'Ticket successfully deleted!';
  static String authDeleteTicketError(String e) =>
      isHungarian ? 'Hiba a jegy törlésekor: $e' : 'Error deleting ticket: $e';

  // Additional Plan API Errors
  static String get apiNoResponseBody =>
      isHungarian ? 'Nincs válasz törzs.' : 'No response body.';
  static String get apiResponseNotJson => isHungarian
      ? 'A válasz nem JSON objektum.'
      : 'Response is not a JSON object.';
  static String apiException(String e) =>
      isHungarian ? 'Plan API kivétel: $e' : 'Plan API exception: $e';

  // Alert Details
  static String get alertDefaultHeader =>
      isHungarian ? 'Közlekedési információ' : 'Service Notice';
  static String alertTimeRange(String start, String end) =>
      isHungarian ? 'Érvényes: $start – $end' : 'Effective: $start – $end';
  static String alertStartTime(String start) =>
      isHungarian ? 'Kezdete: $start' : 'Starts: $start';
  static String alertEndTime(String end) =>
      isHungarian ? 'Vége: $end' : 'Ends: $end';
  static String get alertDetailsButton => isHungarian ? 'Részletek' : 'Details';

  // Trip details tooltip text
  static String tripScheduledTime(String time) =>
      isHungarian ? 'Menetrend szerint: $time' : 'Scheduled: $time';
  static String tripScheduledTimeRange(String arr, String dep) =>
      isHungarian ? 'Menetrend szerint: $arr - $dep' : 'Scheduled: $arr - $dep';
  static String tripScheduledArrival(String time) => isHungarian
      ? 'Menetrend szerinti érkezés: $time'
      : 'Scheduled arrival: $time';
  static String tripScheduledDeparture(String time) => isHungarian
      ? 'Menetrend szerinti indulás: $time'
      : 'Scheduled departure: $time';

  // Trip Details Additional Info
  static String get tripAdditionalInfoTitle =>
      isHungarian ? 'További információk' : 'Additional Information';
  static String get tripServiceOperatedBy =>
      isHungarian ? 'A járatot a(z) ' : 'The service is operated by ';
  static String get tripServiceOperatedSuffix =>
      isHungarian ? ' biztosítja.' : '.';
  static String tripRuns(String time) =>
      isHungarian ? 'Közlekedik: $time' : 'Runs: $time';
  static String get tripWheelchairAccessible =>
      isHungarian ? 'A járat kerekesszékkel igénybe vehető.' : 'The service is wheelchair accessible.';
  static String get tripWheelchairNotAccessible =>
      isHungarian ? 'A járat kerekesszékkel nem vehető igénybe.' : 'The service is not wheelchair accessible.';
  static String get tripWheelchairNoInfo =>
      isHungarian ? 'Nincs információ a kerekesszékes utazásról.' : 'No information about wheelchair accessibility.';
  static String get tripBikesAllowed =>
      isHungarian ? 'A járaton a kerékpárszállítás megengedett.' : 'Bicycle transport is allowed.';
  static String get tripBikesNotAllowed =>
      isHungarian ? 'A járaton a kerékpárszállítás nem megengedett.' : 'Bicycle transport is not allowed.';
  static String get tripBikesNoInfo =>
      isHungarian ? 'Nincs információ a kerékpárszállításról.' : 'No information about bicycle transport.';
  static String get boardingOnly =>
      isHungarian ? 'Csak felszállás' : 'Boarding only';
  static String get alightingOnly =>
      isHungarian ? 'Csak leszállás' : 'Alighting only';
}
