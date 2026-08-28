# TERKA - Teljesen Részletes Közlekedési Adatbázis / Fully Detailed Transport Database

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

A **TERKA** egy Flutter alapú közösségi közlekedési alkalmazás, amely részletes utazástervezést, valós idejű térképes nyomon követést, menetrendeket, jegy- és bérletkezelést, valamint a MÁV friss híreit biztosítja a felhasználók számára.

**TERKA** is a Flutter-based public transit application providing detailed trip planning, real-time map tracking, schedules, ticket and pass management, and up-to-date MÁV (Hungarian State Railways) news.

---

## Tartalomjegyzék / Table of Contents
- [📱 Letöltés / Download](#-letöltés--download)
- [Magyar leírás](#magyar-leírás)
  - [Főbb Funkciók](#főbb-funkciók)
  - [Technológiai Stack](#technológiai-stack)
- [English Description](#english-description)
  - [Key Features](#key-features)
  - [Technology Stack](#technology-stack)
- [Telepítés & Futtatás / Installation & Running](#telepítés--futtatás--installation--running)
- [Készítők / Credits](#készítők--credits)

---

## 📱 Letöltés / Download

### Magyar
[![Latest Release](https://img.shields.io/github/v/release/Eszteban/terka-ui?label=Legfrissebb%20verzi%C3%B3&color=success)](../../releases/latest)

Az előre lefordított Android alkalmazást (APK) bármikor letöltheted a fenti jelvényre kattintva, vagy közvetlenül a **[Legfrissebb verzió elérése](../../releases/latest)** linken keresztül (ez a hivatkozás mindig a mindenkori legújabb kiadásra mutat).

### English
The pre-compiled Android application (APK) can be downloaded at any time by clicking the badge above, or directly via the **[Access Latest Release](../../releases/latest)** link (this link always redirects to the latest available release).

---

# Magyar leírás

## Főbb Funkciók

### 1. Útvonaltervezés (Route Planning)
- **Részletes tervezés**: Indulási és érkezési helyszínek kiválasztása intelligens keresővel.
- **Speciális szűrők**:
  - Átszállások számának korlátozása csúszkával.
  - Maximális gyaloglási távolság beállítása.
  - Közlekedési módok egyéni szűrése (Helyi/Helyközi busz, Vonat, Metró, Trolibusz, Villamos, Hajó).
- **Jegyfigyelés (Ticket Tracking)**: Figyelmeztet, ha a tervezett útvonalhoz nem rendelkezel érvényes jeggyel vagy bérlettel az adott szolgáltatónál.
- **Részletes találati lista**: Menetidők, átszállások, gyaloglási és utazási szakaszok lebontása, valamint a kiválasztott útvonal megjelenítése a térképen.

### 2. Interaktív Térkép (Map Integration)
- **Térképes követés**: OpenStreetMap-alapú interaktív térkép (`flutter_map`).
- **Valós idejű járatadatok**: Útvonalak, megállóhelyek kirajzolása és az aktuális járművek pozíciójának, késésének (valós idejű) jelölése.
- **Megállóhelyi gyorsinfó**: A térképen lévő megállókra kattintva láthatóak az ott áthaladó járatok jelzései és színei.

### 3. Megállóhelyi és Járat Menetrendek (Stop & Trip Details)
- **Megállóhelyi indulások/érkezések**: Élő és menetrendi adatok megjelenítése. Lehetőség van napok közötti váltásra és a korábbi járatok elrejtésére.
- **Járat részletei**: A járat összes megállója, tervezett és valós érkezési/indulási idejei, késések kijelzése.
- **Intelligens görgetés**: A mobil nézetben lévő részletező panelek könnyen felhúzhatók a drag-handle segítségével, miközben a menetrendi lista tetszőleges panelmagasságnál önállóan és finoman görgethető.

### 4. Jegyek és Bérlettípusok Kezelése (Ticket & Pass Management)
- **Jegyeim**: Digitális jegyek és bérletek nyilvántartása (szolgáltató, érvényesség kezdete és lejárata, mennyiség, típus).
- **Bérlettípusok kezelése**: Egyéni bérletek definiálása névvel, érvényességi időtartammal (1 hónap vagy egyéni napszám) és a hozzá tartozó elfogadott szolgáltatók listájával.
- **Felhő szinkronizáció**: Integrált backend kapcsolat az érvényes jegyek biztonságos mentéséhez és szinkronizálásához.

### 5. MÁV Hírek (MÁV News Feed)
- Valós idejű RSS-hírcsatorna a MÁV-csoport weboldaláról.
- Hírek publikálási időpontjának formázott kijelzése.
- Nyelvi figyelmeztetés: Angol nyelvű alkalmazás esetén jelzi a felhasználónak, hogy a hírek többnyire csak magyar nyelven érhetőek el.
- Cikkek megnyitása külső böngészőben egyetlen kattintással.

### 6. Testreszabás & Felhasználói élmény
- **Sötét/Világos/Rendszer téma**: Premium sötét mód mély antracit tónusokkal.
- **Kétnyelvűség**: Teljes magyar és angol lokalizáció.
- **Bento-Grid elrendezés**: Modern, reszponzív felület, amely asztali és táblagép méretben is igazodik a képernyőhöz.

## Technológiai Stack
- **Keretrendszer**: Flutter (Dart)
- **Térkép**: `flutter_map` (OpenStreetMap) és `latlong2`
- **Hálózat**: `http`, `graphql` API kommunikáció
- **Helymeghatározás**: `geolocator`
- **XML feldolgozás**: `xml` (RSS feed elemzéshez)
- **Perzisztens tárolás**: `shared_preferences`

---

# English Description

## Key Features

### 1. Route Planning
- **Detailed Planning**: Search and plan trips between selected origin and destination stations.
- **Advanced Settings**:
  - Limit the number of transfers via slider.
  - Set maximum walking distance limits.
  - Filter by specific transportation modes (Local/Regional bus, Train, Subway, Trolleybus, Tram, Ferry).
- **Ticket Tracking**: Notifies you if your planned route requires a ticket or pass you do not currently possess for the service providers involved.
- **Detailed Itineraries**: Breakdown of durations, transfers, walking and transit legs, with the option to display selected routes on the map.

### 2. Interactive Map
- **OSM-based Maps**: Interactive map using `flutter_map` with OpenStreetMap.
- **Real-time Transit Data**: Shows routes, stops, and real-time vehicle positions with live delay tracking.
- **Quick Stop Info**: Click on any map stop to see passing routes, colors, and line codes.

### 3. Stop & Trip Details (Schedules)
- **Stop Departures & Arrivals**: View scheduled and real-time transit timetables. Filter by date, or toggle the visibility of past departures.
- **Trip Details**: View a comprehensive list of stops, scheduled vs. real-time arrival/departure times, and delay offsets.
- **Optimized Mobile Sheet Scrolling**: A layout split between the draggable header and the list content allows users to scroll stop times and departures smoothly at any height.

### 4. Ticket & Pass Management
- **My Tickets**: Register digital tickets and passes (agency, validity start/expiry, quantity, type).
- **Pass Type Management**: Define custom pass types with names, validity durations (1 month or custom days), and assigned agencies.
- **Backend Syncing**: Fully integrated with a backend server using `AuthApiService` for secure CRUD ticket tracking.

### 5. MÁV News Feed
- Real-time MÁV Inform RSS feed parser.
- Displayed publication dates formatted to local timezones.
- Localization warning: Alerts English-speaking users that news articles are primarily written in Hungarian.
- External link launcher to read full articles in the browser.

### 6. Customization & UI/UX
- **Dark/Light/System Theme**: Premium dark theme using rich warm anthracite colors.
- **Multilingual**: Complete native support for English and Hungarian languages.
- **Bento-Grid Layout**: Modern, responsive layout adapting gracefully to desktops, tablets, and mobile devices.

## Technology Stack
- **Framework**: Flutter (Dart)
- **Map Visuals**: `flutter_map` & `latlong2`
- **Networking**: `http` & `graphql` clients
- **Location Services**: `geolocator`
- **XML Parsing**: `xml` package (for RSS processing)
- **Local Storage**: `shared_preferences`

---

## Telepítés & Futtatás / Installation & Running

A futtatáshoz Flutter SDK szükséges a gépeden.
To run this project, make sure you have the Flutter SDK installed.

```bash
# Függőségek letöltése / Get dependencies
flutter pub get

# Alkalmazás futtatása (alapértelmezett beállításokkal) / Run the application (default)
flutter run
```

### Carto Térkép API Kulcs Konfiguráció / Carto Basemap API Key Setup

Az alkalmazás a Carto alaptérképeit használja. Saját `CARTO_API_KEY` megadásához az alábbi lehetőségek állnak rendelkezésre:

#### 1. Futtatás parancssorból (CLI):
```bash
flutter run --dart-define=CARTO_API_KEY=your_key_here
```

#### 2. Futtatás VS Code-ból:
1. Másold át a `.vscode/launch.json.example` fájlt `.vscode/launch.json` néven:
   ```bash
   cp .vscode/launch.json.example .vscode/launch.json
   ```
2. Cseréld ki a `your_carto_api_key_here` értéket a saját Carto API kulcsodra.
3. Indítsd el az alkalmazást az `F5` billentyűvel vagy a *Run and Debug* menüből.

*(Megjegyzés: Ha a `CARTO_API_KEY` nincs megadva, az alkalmazás automatikusan fallback módban fut az alapértelmezett URL-ekkel.)*

---

#### English: Running with a Custom Carto API Key

The app uses Carto basemaps. To provide your own `CARTO_API_KEY`:

- **From Command Line:**
  ```bash
  flutter run --dart-define=CARTO_API_KEY=your_key_here
  ```
- **From VS Code:**
  1. Copy `.vscode/launch.json.example` to `.vscode/launch.json`.
  2. Replace `your_carto_api_key_here` with your API key.
  3. Start debugging with `F5` or via the *Run and Debug* panel.

*(Note: If `CARTO_API_KEY` is omitted, the app falls back to standard public URLs.)*