import 'package:angeleno_project/controllers/overlay_provider.dart';
import 'package:angeleno_project/utils/constants.dart';
import 'package:angeleno_project/views/screens/mfa_screen.dart';
import 'package:angeleno_project/views/screens/password_screen.dart';
import 'package:angeleno_project/views/screens/profile_screen.dart';

import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../../controllers/auth0_user_api_implementation.dart';
import '../../controllers/user_provider.dart';
import '../../models/user.dart';
import '../../widgets/navigation_button.dart';

class MyHomePage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MyHomePage(this.navigationShell, {super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final Auth0UserApi auth0UserApi = Auth0UserApi();
  final ValueNotifier<int> _secondsLeft = ValueNotifier<int>(0);
  DateTime _lastActivityTime = DateTime.now();

  late StatefulNavigationShell navigationShell;
  late UserProvider userProvider;
  late User user;
  late OverlayProvider overlayProvider;

  Timer? _periodicCheckTimer;
  bool _isWarningDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    super.dispose();
  }

  void _updateActivityTime() {
    _lastActivityTime = DateTime.now();
    if (_isWarningDialogVisible) {
      Navigator.of(context).pop();
      _isWarningDialogVisible = false;
    }
  }

  void _startPeriodicCheck() {
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastActivityTime);
      const totalTimeout = Duration(minutes: 3);
      final secondsLeft = totalTimeout.inSeconds - elapsed.inSeconds;
      _secondsLeft.value = secondsLeft > 0 ? secondsLeft : 0;

      if (elapsed >= totalTimeout) {
        _handleAutoLogout();
      } else if (elapsed >= const Duration(minutes: 1) && !_isWarningDialogVisible) {
        _showInactivityWarning();
      }
    });
  }

  void _showInactivityWarning() {
    if (!_isWarningDialogVisible) {
      _isWarningDialogVisible = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (final context) => AlertDialog(
          // title: const Text('Inactivity Warning'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Need more time?', style: headerStyle),
                const Icon(Icons.horizontal_rule),
              StreamBuilder<int>(
                stream: null, // Remove the StreamBuilder
                builder: (final context, final snapshot) => ValueListenableBuilder<int>(
                  valueListenable: _secondsLeft,
                  builder: (final context, final secondsLeft, final _) {
                    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
                    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
                    return Text(
                      'For your security, we will sign you out\nin $minutes:$seconds unless you tell us otherwise.',
                      textAlign: TextAlign.center,
                    );
                  },
                  ),
              )
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                userProvider.logout();
              }, 
              child: const Text('Sign me out')
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _isWarningDialogVisible = false;
                _updateActivityTime();
              },
              child: const Text('Stay logged in'),
            )
          ],
        ),
      );
    }
  }

  void _handleAutoLogout() {
    if (_isWarningDialogVisible) {
      Navigator.of(context).pop();
      _isWarningDialogVisible = false;
    }
    userProvider.logout();
  }

  Future<void> _unsavedDataDialog(final int futureIndex) async =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (final BuildContext context) => AlertDialog(
        title: const Text('You have unsaved changes'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Your changes have not been saved. Discard changes?')
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
              userProvider.toggleEditing();
              _navigationSelected(futureIndex);
            },
          ),
        ],
      ),
    );

  Future<void> _navigationSelected(final int index) async {

    if (userProvider.isEditing && index != 0) {
      _unsavedDataDialog(index);
    } else {
      // Could use a cleaner implementation
      if ([3, 4, 5, 6].contains(index)) {
        switch(index) {
          case 3:
            await launchUrl(
              Uri.parse('https://account.lacity.gov/')
            );
            break;
          case 4:
            await launchUrl(
              Uri.parse('https://account.lacity.gov/services')
            );
            break;
          case 5:
            await launchUrl(
              Uri.parse('https://account.lacity.gov/help')
            );
            break;
          case 6:
            userProvider.logout();
            break;
        }
      } else {
        navigationShell.goBranch(index);
      }
    }

    scaffoldKey.currentState!.closeDrawer();
  }

  List<Widget> get screens => <Widget>[
    const ProfileScreen(),
    const PasswordScreen(),
    const AdvancedSecurityScreen()
  ];

  @override
  Widget build(final BuildContext context) {
    var userEmail = '';

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenWidth < smallScreenWidthBreakpoint || screenHeight < smallScreenWidthBreakpoint;

    overlayProvider = context.watch<OverlayProvider>();
    userProvider = context.watch<UserProvider>();
    navigationShell = widget.navigationShell;

    if (userProvider.user != null) {
      user = userProvider.user!;
      userEmail = user.email;
    } else {
      return Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: const LinearProgressIndicator(),
          )
      );
    }

    final body = Stack(
      children: [
        Center(
            child: Container(
              transformAlignment: Alignment.center,
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: screens[navigationShell.currentIndex])
                  )
                ],
              ),
            )
        ),
        if (overlayProvider.isLoading)
          Center(
              child: Container(
                alignment: Alignment.topCenter,
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 1280),
                padding: const EdgeInsets.fromLTRB(
                    10, 0, 10, 0
                ),
                color: Colors.black.withValues(alpha: 0.25),
                child: const LinearProgressIndicator(),
              )
          ),
      ],
    );

    return Listener(
      onPointerDown: (final _) => _updateActivityTime(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _updateActivityTime,
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 47.0, 0, 0),
          child: RumUserActionDetector(
            rum: DatadogSdk.instance.rum,
            child: Scaffold(
              key: scaffoldKey,
              appBar: isSmallScreen ? AppBar(
                leadingWidth: 50,
                leading:  IconButton(
                    key: const Key('menuButton'),
                    onPressed: () { scaffoldKey.currentState!.openDrawer(); },
                    icon: const Icon(Icons.menu, semanticLabel: 'Menu button',),
                ),
                title: const Text('Angeleno Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              ) : null,
              drawer: isSmallScreen ? NavigationDrawer(
                onDestinationSelected: _navigationSelected,
                selectedIndex: navigationShell.currentIndex,
                children:  <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
                    child: Text('My Account - $userEmail'),
                  ),
                  const NavigationDrawerDestination(
                      label: Text('Profile', semanticsLabel: 'Navigate to profile page'),
                      icon: Icon(Icons.person)
                  ),
                  const NavigationDrawerDestination(
                      label: Text('Password', semanticsLabel: 'Navigate to password page'),
                      icon: Icon(Icons.password)
                  ),
                  const NavigationDrawerDestination(
                      label: Text('Security', semanticsLabel: 'Navigate to security page'),
                      icon: Icon(Icons.security)
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
                    child: Text('Angeleno'),
                  ),
                  const NavigationDrawerDestination(
                      label: Text('Home', semanticsLabel: 'Link to angeleno home page'),
                      icon: Icon(Icons.home)
                  ),
                  const NavigationDrawerDestination(
                      label: Text('Services', semanticsLabel: 'Link to angeleno partner services page'),
                      icon: Icon(Icons.grid_view)
                  ),
                  const NavigationDrawerDestination(
                      label: Text('Help', semanticsLabel: 'Link to angeleno help page'),
                      icon: Icon(Icons.question_mark)
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
                    child: Divider(),
                  ),
                  const NavigationDrawerDestination(
                      label: Text('Logout', semanticsLabel: 'Logout'),
                      icon: Icon(Icons.logout)
                  )
                ],
              ) : null,
              body: isSmallScreen ? body : Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 250
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                          child:
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  userEmail,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              )
                              ]
                          )
                        ),
                        const SizedBox(height: 20),
                        NavigationButton(
                          icon: const Icon(Icons.person),
                          text: const Text('Profile', semanticsLabel: 'Navigate to profile page'),
                          onPressed: () {
                            _navigationSelected(0);
                          },
                          isActive: navigationShell.currentIndex == 0
                        ),
                        const SizedBox(height: 10),
                        NavigationButton(
                          icon: const Icon(Icons.password),
                          text: const Text('Password', semanticsLabel: 'Navigate to password page'),
                          onPressed: () {
                            _navigationSelected(1);
                          },
                          isActive: navigationShell.currentIndex == 1,
                        ),
                        const SizedBox(height: 10),
                        NavigationButton(
                          icon: const Icon(Icons.security),
                          text: const Text('Multi factor\nauthentication',
                            softWrap: true,
                            semanticsLabel: 'Navigate to MFA page'
                          ),
                          onPressed: () {
                            _navigationSelected(2);
                          },
                          isActive: navigationShell.currentIndex == 2
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _navigationSelected(3);
                                },
                                child: const Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text('Angeleno Home'),
                                        SizedBox(width: 8),
                                        Icon(Icons.open_in_new)
                                      ],
                                    ),
                                  ],
                                )
                              ),
                              const SizedBox(height: 5),
                              TextButton(
                                onPressed: () {
                                  _navigationSelected(4);
                                },
                                child: const Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text('Services', softWrap: true, maxLines: 2,),
                                        SizedBox(width: 8),
                                        Icon(Icons.open_in_new)
                                      ],
                                    ),
                                  ],
                                )
                              ),
                              const SizedBox(height: 5),
                              TextButton(
                                onPressed: () {
                                  _navigationSelected(5);
                                },
                                child: const Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text('Help'),
                                        SizedBox(width: 8),
                                        Icon(Icons.open_in_new)
                                      ],
                                    ),
                                  ],
                                )
                              ),
                              const SizedBox(height: 5),
                              OutlinedButton(
                                onPressed: () {
                                  _navigationSelected(6);
                                },
                                child: const Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Logout'),
                                        SizedBox(width: 8),
                                        Icon(Icons.logout),
                                      ],
                                    ),
                                  ],
                                )
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(child: body)
                ],
              ),
              bottomNavigationBar: Container(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                        'City of Los Angeles. '
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        overlayColor: Colors.transparent
                      ),
                      onPressed: () async {
                        await launchUrl(
                          Uri.parse('https://disclaimer.lacity.org/disclaimer.htm')
                        );
                      },
                      child: const Text('Disclaimer')
                    ),
                    const Text(' | '),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        overlayColor: Colors.transparent
                      ),
                      onPressed: () async {
                        await launchUrl(
                          Uri.parse('https://disclaimer.lacity.org/privacy.htm')
                        );
                      },
                      child: const Text('Privacy Policy')
                    ),
                  ],
                )
              )
            )
          )
        )
      )
    );
  }
}

class CustomNavButton extends StatelessWidget {
  const CustomNavButton({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  /// The icon to display when the button is not selected.
  final Widget icon;

  /// The icon to display when the button is selected.
  final Widget selectedIcon;

  /// The text label to display below the icon.
  final String label;

  /// Whether this button is currently selected.
  final bool isSelected;

  /// The callback that is called when the button is tapped.
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    // Get the colors from the current theme
    final Color selectedColor = Theme.of(context).colorScheme.primary;
    final Color unselectedColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    // Determine the active color and icon based on the isSelected state
    final Color activeColor = isSelected ? selectedColor : unselectedColor;
    final Widget activeIcon = isSelected ? selectedIcon : icon;

    return InkWell(
      onTap: onTap,
      // Use a circular splash effect for a cleaner look
      // customBorder: const CircleBorder(),
      child: Padding(
        // Standard padding to mimic NavigationRailDestination
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use IconTheme to apply the active color to the icon
            IconTheme(
              data: IconThemeData(color: activeColor),
              child: activeIcon,
            ),
            const SizedBox(width: 4.0),
            Text(
              label,
              // Use the theme's label text style and override the color
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: activeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}