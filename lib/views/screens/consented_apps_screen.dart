import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth0_user_api_implementation.dart';
import '../../controllers/user_provider.dart';
import '../../models/connected_applications_model.dart';
import '../../utils/constants.dart';

class ConsentedAppsScreen extends StatefulWidget {
  const ConsentedAppsScreen
      ({super.key});

  @override
  State<ConsentedAppsScreen> createState() => _ConsentedAppsScreenState();
}

class _ConsentedAppsScreenState extends State<ConsentedAppsScreen> {

  bool _isInitialized = false;
  List<Service> _connectedApps = [];

  late Auth0UserApi auth0UserApi;
  late UserProvider userProvider;
  late VoidCallback _userListener;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    userProvider.removeListener(_userListener);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      userProvider = Provider.of(context, listen: false);
      auth0UserApi = Auth0UserApi(userProvider);

      _userListener = () {
        if (userProvider.user != null) {
          _fetchConsentedApps();
        }
      };

      userProvider.removeListener(_userListener);
      userProvider.addListener(_userListener);

      if (userProvider.user != null) {
        _fetchConsentedApps();
      }
      _isInitialized = true;
    }

  }

  Future<void> _fetchConsentedApps() async {

    final consentedAppIds = userProvider.user!.consentedApps.keys.join(',');

    await auth0UserApi.getConnectedApps(userProvider.user!.userId, consentedAppIds)
      .then((response) {
        final bool success = response.statusCode == HttpStatus.ok;

        if (success) {
          final String jsonString = response.body;
          final json = jsonDecode(jsonString) as Map<String, dynamic>;

          final List<Service> services = (json['services'] as List<dynamic>)
              .map((final serviceJson) => Service.fromJson(serviceJson as Map<String, dynamic>))
              .toList();

          setState(() {
            _connectedApps = services;
          });
        }
      }).catchError((Object error) {
        log('Error fetching consented apps: $error');
      });

  }

  Future<void> removeConnection(final String id) async {
    final consentData = userProvider.user!.appMetadata.remove('consent') as Map<String, dynamic>? ?? {};
    final appMetadataCopy = Map<String, dynamic>.from(consentData);
    appMetadataCopy.remove(id);
    userProvider.user!.appMetadata.addAll({'consent': appMetadataCopy});

    final response = await auth0UserApi.removeConnection(userProvider.user!.userId, userProvider.user!.appMetadata);

    if (response.statusCode == HttpStatus.ok) {
      Navigator.pop(context, response.statusCode);
      setState(() {
        _connectedApps.removeWhere((final service) => service.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(
          behavior: SnackBarBehavior.floating,
          width: 280.0,
          content: Text('Service has been disconnected.')
      ));
    }
  }

  @override
  Widget build(final BuildContext context) {
    if (_connectedApps.isEmpty) {
      return const Center(child: LinearProgressIndicator());
    }

    return Align(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: const Text(
              'Connected applications',
              textAlign: TextAlign.left,
              style: headerStyle
            )
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(0),
            itemCount: _connectedApps.length,
            itemBuilder: (final BuildContext context, final int index) {
              final service = _connectedApps[index];
              return ListTile(
                contentPadding: const EdgeInsets.all(0),
                leading: service.icon.isNotEmpty ? ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.network(
                    semanticLabel: '${service.name} logo',
                    service.icon,
                    width: 50,
                    height: 50,
                    errorBuilder: (context, exception, stackTrace) => const SizedBox.shrink(),
                  ),
                ) : null,
                title: Text(service.name),
                subtitle: Text(userProvider.user!.consentedApps[service.id]!),
                trailing: TextButton(
                  onPressed: () =>
                    showDialog<int>(
                      context: context,
                      builder: (final BuildContext context) =>
                        AlertDialog(
                          title: Text('Revoke consent for ${service.name}?'),
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: SingleChildScrollView(
                              child: ListBody(
                                children: <Widget>[
                                  // ignore: avoid_escaping_inner_quotes
                                  // ignore: lines_longer_than_80_chars
                                  Text(
                                      'Your Angeleno Account information will no longer be shared with ${service
                                          .name}.',
                                      style: const TextStyle(
                                          fontWeight: FontWeight
                                              .bold)),
                                  const SizedBox(
                                      height: 10),
                                  // ignore: lines_longer_than_80_chars
                                  Text(
                                      'The information you already shared with ${service
                                          .name} will not be deleted. If you want to delete the information you shared with ${service
                                          .name}, you will need to contact ${service
                                          .name}.'),
                                  const SizedBox(
                                      height: 10),
                                  // ignore: lines_longer_than_80_chars
                                  Text('To access ${service
                                      .name} again in the future, you will need to give your consent to share your Angeleno Account information again. You can give consent again by going to the ${service
                                      .name} site and logging in.')
                                ],
                              )
                            )
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            TextButton(
                              child: const Text('Ok'),
                              onPressed: () {
                                removeConnection(service.id);
                                print('Not implemented');
                              },
                            )
                          ],
                        )
                    ),
                  child: const Text('Disconnect')
                ),
              );
            }
          )
        ],
      ),
    );
  }
}
