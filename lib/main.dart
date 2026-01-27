import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // iOS-specific initialization
  if (Platform.isIOS) {
    WebView.platform = CupertinoWebView();
  }
  
  runApp(const RSTweaksApp());
}

class RSTweaksApp extends StatelessWidget {
  const RSTweaksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'RS Tweaks',
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemBlue,
        barBackgroundColor: CupertinoColors.systemBackground,
        scaffoldBackgroundColor: CupertinoColors.systemBackground,
        textTheme: CupertinoTextThemeData(
          navLargeTitleTextStyle: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
      home: const RSTweaksHomeScreen(),
    );
  }
}

class RSTweaksHomeScreen extends StatefulWidget {
  const RSTweaksHomeScreen({super.key});

  @override
  State<RSTweaksHomeScreen> createState() => _RSTweaksHomeScreenState();
}

class _RSTweaksHomeScreenState extends State<RSTweaksHomeScreen> {
  late WebViewController _webViewController;
  final RefreshController _refreshController = RefreshController();
  final String _targetUrl = 'https://i.alsh3la991.workers.dev/';
  
  // Tab State
  int _selectedIndex = 0;
  bool _showLoading = true;
  bool _isOnline = true;
  
  // App Sections based on website content
  final List<Map<String, dynamic>> _appSections = [
    {
      'title': 'Dashboard',
      'icon': CupertinoIcons.house_fill,
      'url': 'https://i.alsh3la991.workers.dev/',
    },
    {
      'title': 'RS Vault',
      'icon': CupertinoIcons.lock_fill,
      'url': 'https://i.alsh3la991.workers.dev/#vault',
    },
    {
      'title': 'Toolkit',
      'icon': CupertinoIcons.wrench_fill,
      'url': 'https://i.alsh3la991.workers.dev/#toolkit',
    },
    {
      'title': 'Notes',
      'icon': CupertinoIcons.doc_text_fill,
      'url': 'https://i.alsh3la991.workers.dev/#notes',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initWebView();
    _checkConnectivity();
  }

  void _initWebView() {
    if (Platform.isIOS) {
      final platform = WebViewPlatform.instance as WebKitWebViewPlatform?;
      final params = WebKitWebViewPlatformCreationParams(
        allowsInlineMediaPlayback: true,
        allowsBackForwardNavigationGestures: true,
        limitsNavigationsToAppBoundDomains: false,
      );
      
      _webViewController = WebViewController.fromPlatformCreationParams(
        platform?.creationParams ?? params,
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              setState(() => _showLoading = true);
            },
            onPageFinished: (url) {
              setState(() => _showLoading = false);
              _refreshController.refreshCompleted();
              
              // Inject custom CSS for better mobile experience
              _injectCustomCSS();
            },
            onWebResourceError: (error) {
              setState(() => _showLoading = false);
              _refreshController.refreshFailed();
            },
            onNavigationRequest: (request) {
              // Handle external links
              if (!request.url.contains('alsh3la991.workers.dev')) {
                _launchExternalUrl(request.url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(_targetUrl));
    }
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
    
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() => _isOnline = result != ConnectivityResult.none);
      if (_isOnline && _showLoading) {
        _webViewController.reload();
      }
    });
  }

  Future<void> _injectCustomCSS() async {
    await _webViewController.runJavaScript('''
      // Improve mobile UI
      const style = document.createElement('style');
      style.textContent = \`
        * {
          -webkit-tap-highlight-color: transparent;
        }
        body {
          padding-top: env(safe-area-inset-top);
          padding-bottom: env(safe-area-inset-bottom);
          background: #000 !important;
          color: #fff !important;
        }
        a, button {
          min-height: 44px;
          min-width: 44px;
        }
        @media (max-width: 768px) {
          .desktop-only { display: none !important; }
        }
      \`;
      document.head.append(style);
    ''');
  }

  Future<void> _launchExternalUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _shareApp() async {
    await Share.share(
      'Check out RS Tweaks app!',
      subject: 'RS Tweaks',
    );
  }

  Widget _buildLoadingOverlay() {
    if (!_showLoading) return const SizedBox();
    
    return Positioned.fill(
      child: Container(
        color: CupertinoColors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(
              radius: 20,
              animating: true,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading RS Tweaks...',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    if (_isOnline) return const SizedBox();
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: CupertinoColors.systemRed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.wifi_slash, size: 16, color: CupertinoColors.white),
            const SizedBox(width: 8),
            Text(
              'No Internet Connection',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: _appSections.map((section) {
          return BottomNavigationBarItem(
            icon: Icon(section['icon'] as IconData),
            label: section['title'] as String,
          );
        }).toList(),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _webViewController.loadRequest(
            Uri.parse(_appSections[index]['url'] as String),
          );
        },
        backgroundColor: CupertinoColors.systemBackground,
        activeColor: CupertinoColors.systemBlue,
        inactiveColor: CupertinoColors.systemGrey,
        border: const Border(
          top: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
        ),
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: Text(
                  _appSections[index]['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.share, size: 22),
                      onPressed: _shareApp,
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.only(left: 8),
                      child: const Icon(CupertinoIcons.arrow_clockwise, size: 22),
                      onPressed: () => _webViewController.reload(),
                    ),
                  ],
                ),
                backgroundColor: CupertinoColors.systemBackground.withOpacity(0.95),
                border: null,
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Main WebView
                    SmartRefresher(
                      enablePullDown: true,
                      enablePullUp: false,
                      header: const ClassicHeader(
                        idleIcon: Icon(CupertinoIcons.arrow_down, color: CupertinoColors.systemGrey),
                        releaseIcon: Icon(CupertinoIcons.arrow_up, color: CupertinoColors.systemBlue),
                        completeIcon: Icon(CupertinoIcons.checkmark_alt, color: CupertinoColors.systemGreen),
                        failedIcon: Icon(CupertinoIcons.xmark, color: CupertinoColors.systemRed),
                        height: 60,
                      ),
                      controller: _refreshController,
                      onRefresh: () => _webViewController.reload(),
                      child: WebViewWidget(controller: _webViewController),
                    ),
                    
                    // Loading Overlay
                    _buildLoadingOverlay(),
                    
                    // Offline Banner
                    _buildOfflineBanner(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
}
