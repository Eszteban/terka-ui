import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_tokens.dart';
import '../theme/app_texts.dart';
import '../widgets/layout/screen_header.dart';
import '../widgets/layout/desktop_sidebar_wrapper.dart';
import '../utils/layout_provider.dart';

class AboutScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const AboutScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 600.0);
    return DesktopSidebarWrapper(
      child: Scaffold(
        backgroundColor: isDesktop ? Colors.transparent : AppColors.getScaffoldBackground(context),
        body: SafeArea(
          child: AboutView(
            onBack: onBack,
          ),
        ),
      ),
    );
  }
}

class AboutView extends StatefulWidget {
  final VoidCallback? onBack;

  const AboutView({super.key, this.onBack});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  String _version = '';
  String _appName = '';
  int _eggCounter = 0;
  bool _showFox = false;
  bool _useComicSans = false;

  void _onLogoTap() {
    if (_showFox) return;
    _eggCounter++;
    if (_eggCounter >= 10) {
      setState(() {
        _showFox = true;
        _useComicSans = true;
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showFox = false;
            _useComicSans = false;
            _eggCounter = 0;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _appName = info.appName;
    });
  }

  Future<void> _openLink(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null) return;

    final isLaunched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!isLaunched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppTexts.newsLinkOpenFailed)));
    }
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: AppColors.getSurface(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {String? url}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 6,
            child: GestureDetector(
              onTap: url != null ? () => _openLink(url) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        color: url != null
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        decoration: url != null
                            ? TextDecoration.underline
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (url != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageChip(String name, String license) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceVariant(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.seed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              license,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A kikevert seed szín használata fehér/fekete helyett:
    final logoColor = Theme.of(context).colorScheme.primary;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: _useComicSans
            ? Theme.of(context).textTheme.apply(fontFamily: 'Comic Sans MS')
            : null,
      ),
      child: Stack(
        children: [
          Column(
            children: [
              ScreenHeader(
                title: Text(AppTexts.aboutTitle),
                onBack: widget.onBack,
              ),
              Expanded(
                child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // App Icon & Info Header
                    Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _onLogoTap,
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icons/terka_logo_monochrome.png',
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover, // A contain helyett cover, így levágja a széleket és kitölti a kört
                            color: logoColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _appName.isNotEmpty
                          ? AppTexts.aboutDescription(_appName)
                          : AppTexts.aboutAppName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppTexts.version(_version.isNotEmpty ? _version : '-'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Készítő Card
              _buildCard(
                icon: Icons.person_outline,
                title: AppTexts.aboutDeveloper,
                subtitle: '',
                children: [
                  Text(
                    AppTexts.aboutCreatedBy,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openLink(
                          'mailto:terka@eszteban.hu',
                        ),
                        icon: const Icon(Icons.email_outlined, size: 18),
                        label: Text(
                          AppTexts.aboutContactDeveloper,
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.seed.withValues(alpha: 0.1),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _openLink('https://github.com/Eszteban/terka-ui'),
                        icon: const Icon(Icons.link, size: 18),
                        label: Text(AppTexts.aboutGithub),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.seed.withValues(alpha: 0.1),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Köszönet Card
              _buildCard(
                icon: Icons.favorite_border,
                title: AppTexts.specialThanksTitle,
                subtitle: '',
                children: [
                  Text(
                    AppTexts.specialThanks,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),

              // Adatforrások Card
              _buildCard(
                icon: Icons.api_outlined,
                title: AppTexts.aboutDataSources,
                subtitle: AppTexts.aboutDataSourcesSubtitle,
                children: [
                  _buildInfoRow(
                    AppTexts.aboutMavPluszApi,
                    'mavplusz.hu',
                    url: 'https://mavplusz.hu',
                  ),
                  _buildInfoRow(
                    AppTexts.aboutPhotonGeocoder,
                    'mavplusz.hu/photon',
                    url: 'https://mavplusz.hu',
                  ),
                  _buildInfoRow(
                    AppTexts.aboutMavinformNews,
                    'mavcsoport.hu (RSS)',
                    url: 'https://www.mavcsoport.hu/mavinform',
                  ),
                ],
              ),

              // Térkép Card
              _buildCard(
                icon: Icons.map_outlined,
                title: AppTexts.aboutMapData,
                subtitle: AppTexts.aboutMapDataSubtitle,
                children: [
                  _buildInfoRow(
                    AppTexts.aboutCartoTiles,
                    'carto.com',
                    url: 'https://carto.com/attributions',
                  ),
                  _buildInfoRow(
                    AppTexts.aboutOpenStreetMap,
                    'openstreetmap.org',
                    url: 'https://www.openstreetmap.org/copyright',
                  ),
                ],
              ),

              // Betűtípus Card
              _buildCard(
                icon: Icons.font_download_outlined,
                title: AppTexts.aboutTypography,
                subtitle: '',
                children: [
                  _buildInfoRow(AppTexts.aboutFontFamilyLabel, 'MNR2007 (MÁV)'),
                  const SizedBox(height: 6),
                  Text(
                    AppTexts.aboutFontExplanation,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),

              // Szoftver licencek Card
              _buildCard(
                icon: Icons.code_outlined,
                title: AppTexts.aboutUsedLibraries,
                subtitle: AppTexts.aboutUsedLibrariesSubtitle,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPackageChip('flutter_map', 'BSD'),
                      _buildPackageChip('flutter_bloc', 'MIT'),
                      _buildPackageChip('get_it', 'MIT'),
                      _buildPackageChip('geolocator', 'MIT'),
                      _buildPackageChip('http', 'BSD'),
                      _buildPackageChip('xml', 'MIT'),
                      _buildPackageChip('url_launcher', 'BSD'),
                      _buildPackageChip('shared_preferences', 'BSD'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 600.0);
                            final icon = Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.transparent,
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icons/app_icon.png',
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );

                            if (!isDesktop) {
                              showLicensePage(
                                context: context,
                                applicationName: _appName.isNotEmpty ? _appName : AppTexts.aboutAppName,
                                applicationVersion: _version,
                                applicationIcon: icon,
                              );
                              return;
                            }

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  final licensePage = LicensePage(
                                    applicationName: _appName.isNotEmpty ? _appName : AppTexts.aboutAppName,
                                    applicationVersion: _version,
                                    applicationIcon: icon,
                                  );

                                  return DesktopSidebarWrapper(
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        scaffoldBackgroundColor: Colors.transparent,
                                      ),
                                      child: licensePage,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.seed.withValues(alpha: 0.1),
                            ),
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            backgroundColor: AppColors.seed.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppTexts.aboutViewAllLicenses,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
      ],
      ),

          IgnorePointer(
            ignoring: true,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _showFox
                    ? Image.asset(
                        'assets/pics/spinning_fox.gif',
                        key: const ValueKey('fox'),
                        width: 350,
                        height: 350,
                        fit: BoxFit.contain,
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

