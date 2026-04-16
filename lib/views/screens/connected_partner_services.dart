import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/auth0_user_api_implementation.dart';
import '../../controllers/user_provider.dart';
import '../../models/connected_applications_model.dart';
import '../../utils/constants.dart';

class ConnectedPartnerServices extends StatefulWidget {
  const ConnectedPartnerServices
      ({super.key});

  @override
  State<ConnectedPartnerServices> createState() => _ConnectedPartnerServicesState();
}

class _ConnectedPartnerServicesState extends State<ConnectedPartnerServices> {

  bool _isInitialized = false;
  bool _isFetching = false;
  bool _hasFetched = false;
  List<Service> _connectedApps = [];
  final Set<String> _expandedServices = {}; // Track which services have expanded scopes

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
    print('didChangeDependencies called in ConnectedPartnerServices');
    if (!_isInitialized) {
      userProvider = Provider.of(context, listen: false);
      auth0UserApi = Auth0UserApi(userProvider);

      _userListener = () {
        if (mounted && !_hasFetched && !_isFetching && userProvider.user != null) {
          print('Hello');
          _fetchConsentedApps();
        }
      };

      userProvider.removeListener(_userListener);
      userProvider.addListener(_userListener);

      if (userProvider.user != null && !_hasFetched && !_isFetching) {
        print('Howdy');
        _fetchConsentedApps();
      }
      _isInitialized = true;
    }

  }

  Future<void> _fetchConsentedApps() async {
    if (_isFetching || _hasFetched) return;

    // setState(() {
      _isFetching = true;
    // });

    final consentedAppIds = userProvider.user!.consentedApps.keys.join(',');

    await auth0UserApi.getConnectedApps(userProvider.user!.userId, consentedAppIds)
      .then((final response) {
        final bool success = response.statusCode == HttpStatus.ok;

        if (success) {
          final String jsonString = response.body;
          final json = jsonDecode(jsonString) as Map<String, dynamic>;

          final List<Service> services = (json['services'] as List<dynamic>)
              .map((final serviceJson) => Service.fromJson(serviceJson as Map<String, dynamic>))
              .toList();

          if (mounted) {
            setState(() {
              _connectedApps = services;
              _hasFetched = true;
              _isFetching = false;
            });
          }
        } else {
          if (mounted) {
            // setState(() {
              _isFetching = false;
            // });
          }
        }
      }).catchError((final Object error) {
        log('Error fetching consented apps: $error');
        if (mounted) {
          // setState(() {
            _isFetching = false;
          // });
        }
      });

  }

  Future<void> removeConnection(final String id) async {
    final consentData = userProvider.user!.appMetadata.remove('consent') as Map<String, dynamic>? ?? {};
    final appMetadataCopy = Map<String, dynamic>.from(consentData);
    appMetadataCopy.remove(id);
    userProvider.user!.appMetadata.addAll({'consent': appMetadataCopy});

    final response = await auth0UserApi.removeConnection(userProvider.user!.userId, userProvider.user!.appMetadata);

    if (response.statusCode == HttpStatus.ok) {
      if (mounted) {
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
  }

  @override
  Widget build(final BuildContext context) {
    // This isn't right

    if (_isFetching && _connectedApps.isEmpty) {
      return const Center(child: LinearProgressIndicator());
    }

    if (_connectedApps.isEmpty && _hasFetched) {
      return const Center(child: Text('No connected partner services found.'));
    }

    print('Rebuilding from connected partner services');

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: const Text(
              'Your connected partner services',
              textAlign: TextAlign.left,
              style: headerStyle
            )
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate how many cards can fit in a row
                    const double minCardWidth = 300.0;
                    const double spacing = 16.0;

                    final availableWidth = constraints.maxWidth;
                    final cardsPerRow = (availableWidth + spacing) ~/ (minCardWidth + spacing);
                    final actualCardsPerRow = cardsPerRow > 0 ? cardsPerRow : 1;

                    // Calculate the actual card width to fill available space evenly
                    final double cardWidth = (availableWidth - (spacing * (actualCardsPerRow - 1))) / actualCardsPerRow;

                    return Wrap(
                        spacing: spacing, // horizontal spacing between cards
                        runSpacing: spacing, // vertical spacing between rows
                        children: _connectedApps.map((service) => Card.outlined(
                              margin: EdgeInsets.zero,
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  width: cardWidth,
                                  height: _expandedServices.contains(service.id) ? 400 : 180, // Smaller when collapsed
                                  child: ClipRRect(
                                    child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          service.loginUri.isNotEmpty ?
                                              InkWell(
                                                onTap: () => launchUrl(Uri.parse(service.loginUri)),
                                                child: Text(
                                                  service.name,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ) :
                                            Text(service.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Connected on: ${Constants.formatDate(userProvider.user!.consentedApps[service.id]?['date'] ?? 0)}',
                                        ),
                                        // Toggle button for scopes
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (_expandedServices.contains(service.id)) {
                                                _expandedServices.remove(service.id);
                                              } else {
                                                _expandedServices.add(service.id);
                                              }
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _expandedServices.contains(service.id)
                                                    ? Icons.expand_less
                                                    : Icons.expand_more,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                const Expanded(

                                                  child: Text(
                                                    'See what access you\'ve given to this partner service',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Collapsible scopes list
                                        if (_expandedServices.contains(service.id)) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            constraints: const BoxConstraints(
                                              maxHeight: 200, // Limit height to prevent card overflow
                                            ),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  ...(userProvider.user?.consentedApps[service.id]?['scopes'] as String?)
                                                      ?.split(',')
                                                      .map((scope) => Padding(
                                                            padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 2.0),
                                                            child: Row(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                                                Expanded(
                                                                  child: Text(scope.trim())
                                                                ),
                                                              ],
                                                            ),
                                                          )) ?? [],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                        
                                        // Add some spacing before button
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FilledButton.tonal(
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
                                          )
                                        )
                                      ],
                                    ),
                                  )
                                  )
                              )
                              )
                          )).toList()
                    );
                  }
                )
            )
          )
        ],
      ),
    );
  }
}
