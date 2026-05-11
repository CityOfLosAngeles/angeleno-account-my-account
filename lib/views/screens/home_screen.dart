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

  late StatefulNavigationShell navigationShell;
  late Auth0UserApi auth0UserApi;
  late UserProvider userProvider;
  late OverlayProvider overlayProvider;
  late User user;

  final ValueNotifier<int> _secondsLeft = ValueNotifier<int>(0);
  DateTime _lastActivityTime = DateTime.now();
  Timer? _periodicCheckTimer;
  bool _isWarningDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _startPeriodicCheck();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userProvider = Provider.of<UserProvider>(context);
    overlayProvider = context.watch<OverlayProvider>();
    auth0UserApi = Auth0UserApi(userProvider);
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
    _periodicCheckTimer =
        Timer.periodic(const Duration(seconds: 1), (final timer) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastActivityTime);
      const totalTimeout = Duration(minutes: 15);
      final secondsLeft = totalTimeout.inSeconds - elapsed.inSeconds;
      _secondsLeft.value = secondsLeft > 0 ? secondsLeft : 0;

      if (elapsed >= totalTimeout) {
        _handleAutoLogout();
      } else if (elapsed >= const Duration(minutes: 15 - 2) &&
          !_isWarningDialogVisible) {
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
              ValueListenableBuilder<int>(
                valueListenable: _secondsLeft,
                builder: (final context, final secondsLeft, final _) {
                  final minutes =
                      (secondsLeft ~/ 60).toString().padLeft(2, '0');
                  final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
                  return Text(
                    'For your security, we will sign you out\nin $minutes:$seconds unless you tell us otherwise.',
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ],
          ),
          actions: [
            OutlinedButton(
                onPressed: () {
                  userProvider.logout();
                },
                child: const Text('Sign me out')),
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
        switch (index) {
          case 3:
            await launchUrl(Uri.parse('https://account.lacity.gov/'));
            break;
          case 4:
            await launchUrl(Uri.parse('https://account.lacity.gov/services'));
            break;
          case 5:
            await launchUrl(Uri.parse('https://account.lacity.gov/help'));
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
    final bool isSmallScreen = screenWidth < smallScreenWidthBreakpoint ||
        screenHeight < smallScreenWidthBreakpoint;

    navigationShell = widget.navigationShell;

    if (userProvider.user != null) {
      user = userProvider.user!;
      userEmail = user.email;
    } else {
      return Center(
          child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: const LinearProgressIndicator(),
      ));
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
                      child: screens[navigationShell.currentIndex]))
            ],
          ),
        )),
        if (overlayProvider.isLoading)
          Center(
              child: Container(
            alignment: Alignment.topCenter,
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 1280),
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            color: Colors.black.withValues(alpha: 0.25),
            child: const LinearProgressIndicator(),
          )),
      ],
    );

    return Listener(
        onPointerDown: (final _) => _updateActivityTime(),
        child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _updateActivityTime,
            child: Container(
                margin: const EdgeInsets.fromLTRB(0, 47.0, 0, 0),
                child:
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (environment != 'production')
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            color: const Color.fromRGBO(139, 10, 33, 1),
                            child: const DefaultTextStyle(
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                child: Text('TEST SITE - Do not use real personal information (demo purposes only) - TEST SITE')),
                          ),
                        Flexible(
                          child: RumUserActionDetector(
                              rum: DatadogSdk.instance.rum,
                              child: Scaffold(
                                  key: scaffoldKey,
                                  appBar: isSmallScreen
                                      ? AppBar(
                                      leadingWidth: 100,
                                      leading: Padding(
                                        padding: const EdgeInsets.all(7.5),
                                        child: FilledButton(
                                          onPressed: () {
                                            scaffoldKey.currentState!
                                                .openDrawer();
                                          },
                                          child: const Text('Menu',
                                              style: TextStyle()),
                                        ),
                                      ),
                                      title: const Text(
                                        'Angeleno Account',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ))
                                      : null,
                                  drawer: isSmallScreen
                                      ? NavigationDrawer(
                                    onDestinationSelected: _navigationSelected,
                                    selectedIndex: navigationShell.currentIndex,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            28, 16, 16, 10),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Angeleno Account',
                                              style: headerStyle,
                                            ),
                                            Text(
                                              userEmail,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            )
                                          ],
                                        ),
                                      ),
                                      const NavigationDrawerDestination(
                                          label: Text('Profile',
                                              semanticsLabel:
                                              'Navigate to profile page'),
                                          icon: Icon(Icons.person)),
                                      const NavigationDrawerDestination(
                                          label: Text('Password',
                                              semanticsLabel:
                                              'Navigate to password page'),
                                          icon: Icon(Icons.password)),
                                      const NavigationDrawerDestination(
                                          label: Text(
                                              'Multi-factor authentication',
                                              semanticsLabel:
                                              'Navigate to multi-factor authentication page'),
                                          icon: Icon(Icons.security)),
                                      const Divider(),
                                      const NavigationDrawerDestination(
                                          label: Text('Home',
                                              semanticsLabel:
                                              'Link to angeleno home page'),
                                          icon: Icon(Icons.open_in_new)),
                                      const NavigationDrawerDestination(
                                          label: Text('Partner Services',
                                              semanticsLabel:
                                              'Link to angeleno partner services page'),
                                          icon: Icon(Icons.open_in_new)),
                                      const NavigationDrawerDestination(
                                          label: Text('Help',
                                              semanticsLabel:
                                              'Link to angeleno help page'),
                                          icon: Icon(Icons.open_in_new)),
                                      const Padding(
                                        padding:
                                        EdgeInsets.fromLTRB(28, 16, 28, 10),
                                        child: Divider(),
                                      ),
                                      const NavigationDrawerDestination(
                                          label: Text('Logout',
                                              semanticsLabel: 'Logout'),
                                          icon: Icon(Icons.logout))
                                    ],
                                  )
                                      : null,
                                  body: isSmallScreen
                                      ? body
                                      : Flex(
                                    direction: Axis.horizontal,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ConstrainedBox(
                                        constraints:
                                        const BoxConstraints(maxWidth: 280),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            const Center(
                                              child: Text(
                                                'Angeleno Account',
                                                style: headerStyle,
                                              ),
                                            ),
                                            Padding(
                                                padding:
                                                const EdgeInsets.fromLTRB(
                                                    10, 0, 10, 0),
                                                child: Row(children: [
                                                  Expanded(
                                                    child: Text(
                                                      style: const TextStyle(
                                                          fontWeight:
                                                          FontWeight.bold),
                                                      userEmail,
                                                      softWrap: true,
                                                      maxLines: 2,
                                                      overflow:
                                                      TextOverflow.ellipsis,
                                                      textAlign:
                                                      TextAlign.center,
                                                    ),
                                                  )
                                                ])),
                                            const SizedBox(height: 20),
                                            NavigationButton(
                                                icon: const Icon(Icons.person),
                                                text: const Text('Profile',
                                                    semanticsLabel:
                                                    'Navigate to profile page'),
                                                onPressed: () {
                                                  _navigationSelected(0);
                                                },
                                                isActive: navigationShell
                                                    .currentIndex ==
                                                    0),
                                            const SizedBox(height: 10),
                                            NavigationButton(
                                              icon: const Icon(Icons.password),
                                              text: const Text('Password',
                                                  semanticsLabel:
                                                  'Navigate to password page'),
                                              onPressed: () {
                                                _navigationSelected(1);
                                              },
                                              isActive: navigationShell
                                                  .currentIndex ==
                                                  1,
                                            ),
                                            const SizedBox(height: 10),
                                            NavigationButton(
                                                icon:
                                                const Icon(Icons.security),
                                                text: const Text(
                                                    'Multi-factor authentication',
                                                    softWrap: true,
                                                    semanticsLabel:
                                                    'Navigate to MFA page'),
                                                onPressed: () {
                                                  _navigationSelected(2);
                                                },
                                                isActive: navigationShell
                                                    .currentIndex ==
                                                    2),
                                            const Spacer(),
                                            Padding(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  10, 0, 10, 10),
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  TextButton(
                                                      onPressed: () {
                                                        _navigationSelected(3);
                                                      },
                                                      child: const Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text('Home'),
                                                              SizedBox(
                                                                  width: 8),
                                                              Icon(Icons
                                                                  .open_in_new)
                                                            ],
                                                          ),
                                                        ],
                                                      )),
                                                  const SizedBox(height: 5),
                                                  TextButton(
                                                      onPressed: () {
                                                        _navigationSelected(4);
                                                      },
                                                      child: const Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                'Partner Services',
                                                                softWrap: true,
                                                                maxLines: 2,
                                                              ),
                                                              SizedBox(
                                                                  width: 8),
                                                              Icon(Icons
                                                                  .open_in_new)
                                                            ],
                                                          ),
                                                        ],
                                                      )),
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
                                                              SizedBox(
                                                                  width: 8),
                                                              Icon(Icons
                                                                  .open_in_new)
                                                            ],
                                                          ),
                                                        ],
                                                      )),
                                                  const SizedBox(height: 5),
                                                  OutlinedButton(
                                                      onPressed: () {
                                                        _navigationSelected(6);
                                                      },
                                                      child: const Column(
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                            children: [
                                                              Text('Logout'),
                                                              SizedBox(
                                                                  width: 8),
                                                              Icon(
                                                                  Icons.logout),
                                                            ],
                                                          ),
                                                        ],
                                                      ))
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      screenWidth > 1580
                                          ? body
                                          : Expanded(child: body)
                                    ],
                                  ),
                                  bottomNavigationBar: Container(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          const Text('City of Los Angeles. '),
                                          TextButton(
                                              style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  overlayColor: Colors.transparent),
                                              onPressed: () async {
                                                await launchUrl(Uri.parse(
                                                    'https://disclaimer.lacity.org/disclaimer.htm'));
                                              },
                                              child: const Text('Disclaimer')),
                                          const Text(' | '),
                                          TextButton(
                                              style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  overlayColor: Colors.transparent),
                                              onPressed: () async {
                                                await launchUrl(Uri.parse(
                                                    'https://disclaimer.lacity.org/privacy.htm'));
                                              },
                                              child: const Text('Privacy Policy')),
                                        ],
                                      )))),
                        )
                      ],
                    )
                )
        )
    );
  }
}
