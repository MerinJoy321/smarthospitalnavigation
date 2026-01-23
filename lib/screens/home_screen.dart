import 'package:flutter/material.dart';

import '../models.dart';
import '../services.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.mapRepository,
    required this.routingService,
    required this.updatesService,
  });

  final MapRepository mapRepository;
  final RoutingService routingService;
  final UpdatesService updatesService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocationNode? _start;
  LocationNode? _destination;
  final TextEditingController _destinationController = TextEditingController();

  HospitalMap get _map => widget.mapRepository.defaultMap;

  @override
  void initState() {
    super.initState();
    // Default start at main entrance if available.
    _start = _map.nodes.firstWhere(
      (n) => n.isEntrance,
      orElse: () => _map.nodes.first,
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  void _onPickDestination(LocationNode node) {
    setState(() {
      _destination = node;
      _destinationController.text = node.name;
    });
  }

  void _startNavigation() {
    if (_start == null || _destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start point and a destination.'),
        ),
      );
      return;
    }

    final route = widget.routingService.findRoute(
      map: _map,
      start: _start!,
      destination: _destination!,
    );

    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No route found. Please try a different destination.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapScreen(
          navigationRoute: route,
          updatesService: widget.updatesService,
        ),
      ),
    );
  }

  Future<void> _showDestinationPicker() async {
    final selected = await showModalBottomSheet<LocationNode>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final departments = _map.departmentNodes;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Where do you need to go?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: departments.length,
                    itemBuilder: (context, index) {
                      final node = departments[index];
                      return ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(node.name),
                        subtitle: Text('Level ${node.level}'),
                        onTap: () => Navigator.of(context).pop(node),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      _onPickDestination(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertsCount = widget.updatesService.currentAlerts
        .where((a) => a.isActive)
        .length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Smart Hospital Navigator'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Find your way with confidence',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Step‑by‑step routes, visual guidance, and live updates for patients, visitors, and staff.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              _HeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start from',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<LocationNode>(
                      initialValue: _start,
                      items: _map.nodes
                          .map(
                            (n) => DropdownMenuItem(
                              value: n,
                              child: Text(n.name),
                            ),
                          )
                          .toList(),
                      onChanged: (node) {
                        setState(() {
                          _start = node;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Destination',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _destinationController,
                      readOnly: true,
                      onTap: _showDestinationPicker,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search e.g. “X-Ray Department”',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_drop_down),
                          onPressed: _showDestinationPicker,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _startNavigation,
                        icon: const Icon(Icons.directions),
                        label: const Text('Show route'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Works fully offline with built‑in maps. Visual “Street View” guidance available on the next screen.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HeroCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.photo_camera_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scan paper map',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Future enhancement: capture a map photo to calibrate routes.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _HeroCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live hospital updates',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alertsCount > 0
                                ? '$alertsCount active notice(s) about construction and ward changes.'
                                : 'No active notices right now.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: child,
    );
  }
}

