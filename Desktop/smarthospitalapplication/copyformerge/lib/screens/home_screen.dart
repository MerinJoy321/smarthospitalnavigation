import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models.dart';
import '../services.dart';
import '../providers/auth_provider.dart';
import '../services/digital_twin_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.mapRepository,
    required this.routingService,
    required this.updatesService,
    required this.authProvider,
    this.digitalTwinService,
  });

  final MapRepository mapRepository;
  final RoutingService routingService;
  final UpdatesService updatesService;
  final AuthProvider authProvider;
  final DigitalTwinService? digitalTwinService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocationNode? _start;
  LocationNode? _destination;
  static const int _groundFloor = 1;
  final TextEditingController _destinationController = TextEditingController();

  HospitalMap get _map =>
      widget.mapRepository.getMapForFloor(_groundFloor) ??
      widget.mapRepository.defaultMap;

  @override
  void initState() {
    super.initState();
    final groundFloor = widget.mapRepository.getMapForFloor(_groundFloor);
    if (groundFloor != null && groundFloor.nodes.isNotEmpty) {
      _start = groundFloor.nodes.firstWhere(
        (n) => n.id == 'consultation_rooms',
        orElse: () => groundFloor.nodes.first,
      );
    }
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

  // Navigation temporarily disabled - will be connected after merge
  void _startNavigation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Navigation feature coming soon.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showDestinationPicker() async {
    // Show all departments from all floors
    final allDepartments = <LocationNode>[];
    for (final floor in widget.mapRepository.availableFloors) {
      final map = widget.mapRepository.getMapForFloor(floor);
      if (map != null) {
        allDepartments.addAll(map.departmentNodes);
      }
    }

    if (allDepartments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No departments available. Route maps will be added in the next steps.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<LocationNode>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                const SizedBox(height: 20),
                Text(
                  'Where do you need to go?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a department or facility',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: allDepartments.length,
                    itemBuilder: (context, index) {
                      final node = allDepartments[index];
                      final floorName = node.level == 1
                          ? 'Ground Floor'
                          : node.level == 2
                          ? 'First Floor'
                          : node.level == 3
                          ? 'Second Floor'
                          : 'Third Floor';
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.place_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          node.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          floorName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
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

  void _showSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.support_agent_rounded, color: Theme.of(ctx).colorScheme.primary, size: 26),
                const SizedBox(width: 12),
                Text(
                  'Support',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Need help navigating the hospital? Our support team is available.\n\n'
              '• Call: +1 (555) 123-4567\n'
              '• Email: support@hospital.org\n'
              '• In-person: Reception, Ground Floor',
              style: GoogleFonts.plusJakartaSans(height: 1.6, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _showContact(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_support_rounded, color: Theme.of(ctx).colorScheme.primary, size: 26),
                const SizedBox(width: 12),
                Text(
                  'Contact',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'General enquiries:\n\n'
              '• Main: +1 (555) 000-1234\n'
              '• App feedback: feedback@hospital.org',
              style: GoogleFonts.plusJakartaSans(height: 1.6, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergency(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.red.shade50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency_rounded, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Emergency',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'In case of emergency:\n\n'
              '• Dial 911 (or local emergency number)\n'
              '• Emergency Dept: Ground Floor, follow signs\n'
              '• First aid: Available at Reception',
              style: GoogleFonts.plusJakartaSans(height: 1.6, fontSize: 15, color: Colors.red.shade900),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _MenuTile(
                icon: Icons.support_agent,
                label: 'Support',
                onTap: () {
                  Navigator.pop(ctx);
                  _showSupport(context);
                },
              ),
              _MenuTile(
                icon: Icons.contact_support,
                label: 'Contact',
                onTap: () {
                  Navigator.pop(ctx);
                  _showContact(context);
                },
              ),
              _MenuTile(
                icon: Icons.emergency,
                label: 'Emergency',
                onTap: () {
                  Navigator.pop(ctx);
                  _showEmergency(context);
                },
              ),
              _MenuTile(
                icon: Icons.info_outline,
                label: 'About',
                onTap: () {
                  Navigator.pop(ctx);
                  _showAbout(context);
                },
              ),
              const Divider(height: 32),
              _MenuTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                onTap: () async {
                  Navigator.pop(ctx);
                  await _handleLogout(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.plusJakartaSans(),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await widget.authProvider.signOut();
        // Navigation will happen automatically via AuthWrapper
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to sign out: ${e.toString()}',
                style: GoogleFonts.plusJakartaSans(),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Theme.of(ctx).colorScheme.primary, size: 26),
                const SizedBox(width: 12),
                Text(
                  'About',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Smart Hospital Navigator helps patients, visitors, and staff find their way with step-by-step routes, visual guidance, and live updates. Works fully offline.',
              style: GoogleFonts.plusJakartaSans(height: 1.6, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveUpdates(BuildContext context, int alertsCount) {
    final alerts = widget.updatesService.currentAlerts
        .where((a) => a.isActive)
        .toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_rounded, color: Theme.of(ctx).colorScheme.primary, size: 26),
                const SizedBox(width: 12),
                Text(
                  'Live Updates',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (alerts.isEmpty)
              Text('No active notices at this time.', style: GoogleFonts.plusJakartaSans(fontSize: 15))
            else
              ...alerts.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(a.description, style: GoogleFonts.plusJakartaSans(height: 1.4, fontSize: 14)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final alertsCount = widget.updatesService.currentAlerts
        .where((a) => a.isActive)
        .length;
    const primaryTeal = Color(0xFF00695C);

    // Responsive breakpoints: compact (phone) < 600, medium (tablet) 600–900, expanded (desktop) >= 900
    final isCompact = width < 600;
    final isMedium = width >= 600 && width < 900;
    final isExpanded = width >= 900;

    // Scale factors (compact = 1.0)
    final paddingScale = isCompact ? 1.0 : (isMedium ? 1.15 : 1.3);
    final padH = (24 * paddingScale).clamp(16.0, 32.0);
    final padV = (36 * paddingScale).clamp(24.0, 48.0);
    final topPad = (76 * paddingScale).clamp(64.0, 100.0);

    // Responsive font sizes
    final titleFontSize = (width * 0.09).clamp(32.0, 52.0); // 44 at ~490px
    final appBarFontSize = (width * 0.045).clamp(16.0, 26.0);
    final taglineFontSize = (width * 0.035).clamp(13.0, 16.0);
    final maxContentWidth = isExpanded ? 560.0 : double.infinity;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final showIcon = width > 360;
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showIcon) ...[
                  Container(
                    padding: EdgeInsets.all(isCompact ? 5 : 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.medical_services_rounded,
                      size: isCompact ? 18 : 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: isCompact ? 8 : 10),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Smart Hospital Navigator',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: appBarFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white,
          size: isCompact ? 22 : 24,
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _showMenu(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/hospital_bg.png'),
                fit: BoxFit.cover,
                onError: (_, __) {},
              ),
            ),
          ),
          // Gradient overlay for readability
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padH, topPad, padH, padV),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero heading
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: (12 * paddingScale).clamp(10.0, 16.0),
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryTeal.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryTeal.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'INDOOR NAVIGATION',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isCompact ? 10 : 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 12 : 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isCompact ? 8 : 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.explore_rounded,
                              color: Colors.white,
                              size: isCompact ? 24 : 28,
                            ),
                          ),
                          SizedBox(width: isCompact ? 12 : 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Find Your Way',
                                  style: GoogleFonts.outfit(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 2),
                                      ),
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 24,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Step-by-step directions from Ground Floor. Select your destination and go.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: taglineFontSize,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.92),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryTeal, primaryTeal.withValues(alpha: 0.6)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: isCompact ? 24 : 32),
                  // Route form card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: EdgeInsets.all(isCompact ? 20 : 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 32,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: primaryTeal.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.route_rounded, size: 20, color: primaryTeal),
                                const SizedBox(width: 8),
                                Text(
                                  'Plan your route',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: primaryTeal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Start from (Ground Floor)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<LocationNode>(
                              value: _start,
                              items: _map.nodes
                                  .map(
                                    (n) => DropdownMenuItem(
                                      value: n,
                                      child: Text(
                                        n.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (node) {
                                setState(() {
                                  _start = node;
                                });
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: primaryTeal.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: primaryTeal.withValues(alpha: 0.25),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: primaryTeal,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Destination',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _destinationController,
                              readOnly: true,
                              onTap: _showDestinationPicker,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: 22,
                                  color: primaryTeal,
                                ),
                                hintText: 'e.g. X-Ray, Pharmacy, Emergency',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: primaryTeal.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: primaryTeal.withValues(alpha: 0.25),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: primaryTeal,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: primaryTeal,
                                    size: 28,
                                  ),
                                  onPressed: _showDestinationPicker,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Navigation button - temporarily disabled
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton.icon(
                                onPressed: _startNavigation,
                                icon: const Icon(Icons.directions_rounded, size: 24),
                                label: Text(
                                  'Show route',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryTeal.withValues(alpha: 0.5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 24 : 32),
                  Row(
                    children: [
                      Icon(
                        Icons.flash_on_rounded,
                        size: isCompact ? 18 : 20,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      SizedBox(width: isCompact ? 6 : 8),
                      Text(
                        'Quick access',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isCompact ? 15 : 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 12 : 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(right: padH),
                    child: Row(
                      children: [
                        _QuickChip(
                          icon: Icons.support_agent_rounded,
                          label: 'Support',
                          theme: theme,
                          onTap: () => _showSupport(context),
                          primaryTeal: primaryTeal,
                        ),
                        const SizedBox(width: 10),
                        _QuickChip(
                          icon: Icons.contact_support_rounded,
                          label: 'Contact',
                          theme: theme,
                          onTap: () => _showContact(context),
                          primaryTeal: primaryTeal,
                        ),
                        const SizedBox(width: 10),
                        _QuickChip(
                          icon: Icons.emergency_rounded,
                          label: 'Emergency',
                          theme: theme,
                          onTap: () => _showEmergency(context),
                          primaryTeal: primaryTeal,
                        ),
                        const SizedBox(width: 10),
                        _QuickChip(
                          icon: Icons.campaign_rounded,
                          label: 'Updates',
                          badge: alertsCount > 0 ? '$alertsCount' : null,
                          theme: theme,
                          onTap: () => _showLiveUpdates(context, alertsCount),
                          primaryTeal: primaryTeal,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ), // SafeArea
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15)),
      onTap: onTap,
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.theme,
    this.badge,
    required this.onTap,
    required this.primaryTeal,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final ThemeData theme;
  final VoidCallback onTap;
  final Color primaryTeal;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: primaryTeal),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                  fontSize: 14,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryTeal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

