import 'package:angeleno_project/controllers/overlay_provider.dart';
import 'package:angeleno_project/views/screens/advanced_security_screen.dart';
import 'package:angeleno_project/views/screens/password_screen.dart';
import 'package:angeleno_project/views/screens/profile_screen.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/auth0_user_api_implementation.dart';
import '../../controllers/user_provider.dart';
import '../../models/user.dart';

class MyHomePage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MyHomePage(this.navigationShell, {super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final Auth0UserApi auth0UserApi = Auth0UserApi();

  late StatefulNavigationShell navigationShell;
  late UserProvider userProvider;
  late User user;
  late OverlayProvider overlayProvider;

  @override
  void initState() {
    super.initState();
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

     overlayProvider = context.watch<OverlayProvider>();
     userProvider = context.watch<UserProvider>();
     navigationShell = widget.navigationShell;

     if (userProvider.user != null) {
       user = userProvider.user!;
       userEmail = user.email;
     }

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 47.0, 0, 0),
      child: RumUserActionDetector(
        rum: DatadogSdk.instance.rum,
        child: userProvider.user == null ?
          const Scaffold(
            body: LinearProgressIndicator()
          )
          :
          Scaffold(
            key: scaffoldKey,
            appBar: AppBar(
                leadingWidth: 75,
                leading:  TextButton(
                    key: const Key('menuButton'),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0)
                      ),
                    ),
                    onPressed: () { scaffoldKey.currentState!.openDrawer(); },
                    child: const Text('Menu', style: TextStyle(
                      fontSize: 16,
                    ),)
                ),
                title: const Text('Angeleno Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
            ),
            drawer: NavigationDrawer(
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
                    label: Text('Password change', semanticsLabel: 'Navigate to password page'),
                    icon: Icon(Icons.password)
                ),
                const NavigationDrawerDestination(
                    label: Text('Multi-factor authentication (MFA)', semanticsLabel: 'Navigate to mfa page'),
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
            ),
            body: Stack(
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
      ),
    );
  }
}
