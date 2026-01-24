import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/digital_twin_service.dart';
import '../services/admin_auth_service.dart';
import '../models/digital_twin_models.dart';
import '../models.dart';
import '../services.dart';

/// Admin Dashboard - Digital Twin Control Panel
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.digitalTwinService,
    required this.adminAuthService,
    required this.mapRepository,
    required this.onLogout,
  });

  final DigitalTwinService digitalTwinService;
  final AdminAuthService adminAuthService;
  final MapRepository mapRepository;
  final VoidCallback onLogout;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to sign out from the admin panel?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sign Out', style: GoogleFonts.plusJakartaSans()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.adminAuthService.signOut();
      widget.onLogout();
    }
  }

  void _handleResetAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reset Hospital State',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will clear all blocks, triage zones, and congestion settings. Are you sure?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Reset All', style: GoogleFonts.plusJakartaSans()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.digitalTwinService.resetHospitalState();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hospital state reset to default', style: GoogleFonts.plusJakartaSans()),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const adminOrange = Color(0xFFE65100);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: adminOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dashboard_rounded, size: 24),
            const SizedBox(width: 8),
            Text(
              'Admin Panel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset All',
            onPressed: _handleResetAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.location_on), text: 'Location'),
            Tab(icon: Icon(Icons.route), text: 'Route'),
            Tab(icon: Icon(Icons.warning), text: 'Triage'),
            Tab(icon: Icon(Icons.schedule), text: 'Congestion'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.digitalTwinService,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _NodesTab(
                digitalTwinService: widget.digitalTwinService,
                mapRepository: widget.mapRepository,
              ),
              _EdgesTab(
                digitalTwinService: widget.digitalTwinService,
                mapRepository: widget.mapRepository,
              ),
              _TriageZonesTab(
                digitalTwinService: widget.digitalTwinService,
              ),
              _CongestionTab(
                digitalTwinService: widget.digitalTwinService,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Nodes Tab - Toggle node availability
class _NodesTab extends StatelessWidget {
  const _NodesTab({
    required this.digitalTwinService,
    required this.mapRepository,
  });

  final DigitalTwinService digitalTwinService;
  final MapRepository mapRepository;

  @override
  Widget build(BuildContext context) {
    final allNodes = <LocationNode>[];
    for (final floor in mapRepository.availableFloors) {
      final map = mapRepository.getMapForFloor(floor);
      if (map != null) {
        allNodes.addAll(map.nodes);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          title: 'Hospital Locations',
          subtitle: 'Toggle to block/unblock locations',
          actionLabel: 'Clear All Blocks',
          onAction: () => digitalTwinService.resetNodeEdgeBlocks(),
        ),
        const SizedBox(height: 12),
        ...allNodes.map((node) {
          final isBlocked = digitalTwinService.isNodeBlocked(node.id);
          final congestion = digitalTwinService.getNodeCongestionMultiplier(node.id);
          
          return _ToggleCard(
            title: node.name,
            subtitle: _getFloorName(node.level),
            icon: _getNodeIcon(node),
            isActive: !isBlocked,
            congestionMultiplier: congestion,
            onToggle: (active) {
              digitalTwinService.setNodeBlocked(
                node.id,
                !active,
                reason: active ? null : 'Manually blocked',
              );
            },
          );
        }),
      ],
    );
  }

  String _getFloorName(int level) {
    switch (level) {
      case 1: return 'Ground Floor';
      case 2: return 'First Floor';
      case 3: return 'Second Floor';
      case 4: return 'Third Floor';
      default: return 'Floor $level';
    }
  }

  IconData _getNodeIcon(LocationNode node) {
    if (node.isLift) return Icons.elevator;
    if (node.isStairs) return Icons.stairs;
    if (node.isEntrance) return Icons.door_front_door;
    if (node.isDepartment) return Icons.medical_services;
    return Icons.location_on;
  }
}

/// Edges Tab - Toggle corridor/connection availability
class _EdgesTab extends StatelessWidget {
  const _EdgesTab({
    required this.digitalTwinService,
    required this.mapRepository,
  });

  final DigitalTwinService digitalTwinService;
  final MapRepository mapRepository;

  @override
  Widget build(BuildContext context) {
    final allEdges = <_EdgeInfo>[];
    for (final floor in mapRepository.availableFloors) {
      final map = mapRepository.getMapForFloor(floor);
      if (map != null) {
        for (final edge in map.edges) {
          final fromNode = map.findNodeById(edge.fromId);
          final toNode = map.findNodeById(edge.toId);
          if (fromNode != null && toNode != null) {
            allEdges.add(_EdgeInfo(
              fromId: edge.fromId,
              toId: edge.toId,
              fromName: fromNode.name,
              toName: toNode.name,
              level: map.level,
              distance: edge.distance,
            ));
          }
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          title: 'Corridors & Connections',
          subtitle: 'Toggle to block/unblock pathways',
          actionLabel: 'Clear All Blocks',
          onAction: () => digitalTwinService.resetNodeEdgeBlocks(),
        ),
        const SizedBox(height: 12),
        ...allEdges.map((edge) {
          final isBlocked = digitalTwinService.isEdgeBlocked(edge.fromId, edge.toId);
          final congestion = digitalTwinService.getEdgeCongestionMultiplier(edge.fromId, edge.toId);
          
          return _ToggleCard(
            title: '${edge.fromName} → ${edge.toName}',
            subtitle: '${_getFloorName(edge.level)} · ${edge.distance.toInt()}m',
            icon: Icons.timeline,
            isActive: !isBlocked,
            congestionMultiplier: congestion,
            onToggle: (active) {
              digitalTwinService.setEdgeBlocked(
                edge.fromId,
                edge.toId,
                !active,
                reason: active ? null : 'Manually blocked',
              );
            },
          );
        }),
      ],
    );
  }

  String _getFloorName(int level) {
    switch (level) {
      case 1: return 'Ground Floor';
      case 2: return 'First Floor';
      case 3: return 'Second Floor';
      case 4: return 'Third Floor';
      default: return 'Floor $level';
    }
  }
}

class _EdgeInfo {
  final String fromId;
  final String toId;
  final String fromName;
  final String toName;
  final int level;
  final double distance;

  _EdgeInfo({
    required this.fromId,
    required this.toId,
    required this.fromName,
    required this.toName,
    required this.level,
    required this.distance,
  });
}

/// Triage Zones Tab
class _TriageZonesTab extends StatelessWidget {
  const _TriageZonesTab({required this.digitalTwinService});

  final DigitalTwinService digitalTwinService;

  @override
  Widget build(BuildContext context) {
    final zones = digitalTwinService.triageZones.values.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          title: 'Triage Zones',
          subtitle: 'Activate emergency zones to block multiple areas',
          actionLabel: 'Clear All Zones',
          onAction: () => digitalTwinService.clearAllTriageZones(),
        ),
        const SizedBox(height: 12),
        ...zones.map((zone) {
          return _TriageZoneCard(
            zone: zone,
            onToggle: (active) {
              digitalTwinService.toggleTriageZone(zone.id, active);
            },
          );
        }),
      ],
    );
  }
}

/// Congestion Tab
class _CongestionTab extends StatelessWidget {
  const _CongestionTab({required this.digitalTwinService});

  final DigitalTwinService digitalTwinService;

  @override
  Widget build(BuildContext context) {
    final schedules = digitalTwinService.congestionSchedules.values.toList();
    final useSimulated = digitalTwinService.useSimulatedTime;
    final currentTime = digitalTwinService.currentTime;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          title: 'Congestion Scheduling',
          subtitle: 'Set time-based congestion multipliers',
          actionLabel: 'Reset Schedules',
          onAction: () => digitalTwinService.clearAllCongestionSchedules(),
        ),
        const SizedBox(height: 12),
        
        // Time simulation card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Time Simulation',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Switch(
                      value: useSimulated,
                      onChanged: (v) => digitalTwinService.toggleSimulatedTime(v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Current time: ${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (useSimulated) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _TimeButton(label: '09:00', onTap: () => digitalTwinService.setSimulatedTime(
                        DateTime(2024, 1, 1, 9, 0),
                      )),
                      _TimeButton(label: '12:30', onTap: () => digitalTwinService.setSimulatedTime(
                        DateTime(2024, 1, 1, 12, 30),
                      )),
                      _TimeButton(label: '15:00', onTap: () => digitalTwinService.setSimulatedTime(
                        DateTime(2024, 1, 1, 15, 0),
                      )),
                      _TimeButton(label: '18:00', onTap: () => digitalTwinService.setSimulatedTime(
                        DateTime(2024, 1, 1, 18, 0),
                      )),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        ...schedules.map((schedule) {
          final isActiveNow = schedule.isActiveAt(currentTime);
          
          return _CongestionScheduleCard(
            schedule: schedule,
            isActiveNow: isActiveNow,
            onToggle: (enabled) {
              digitalTwinService.toggleCongestionSchedule(schedule.id, enabled);
            },
          );
        }),
      ],
    );
  }
}

// ==================== HELPER WIDGETS ====================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.onToggle,
    this.congestionMultiplier = 1.0,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final double congestionMultiplier;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final isCongested = congestionMultiplier > 1.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isActive ? Colors.white : Colors.red.shade50,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive 
                ? (isCongested ? Colors.orange.shade100 : Colors.green.shade100)
                : Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isActive 
                ? (isCongested ? Colors.orange.shade700 : Colors.green.shade700)
                : Colors.red.shade700,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(fontSize: 12),
            ),
            if (isCongested) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '×${congestionMultiplier.toStringAsFixed(1)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Switch(
          value: isActive,
          onChanged: onToggle,
          activeColor: Colors.green,
        ),
      ),
    );
  }
}

class _TriageZoneCard extends StatelessWidget {
  const _TriageZoneCard({
    required this.zone,
    required this.onToggle,
  });

  final TriageZone zone;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final typeColor = _getZoneColor(zone.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: zone.isActive ? typeColor.withValues(alpha: 0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: zone.isActive ? typeColor : Colors.grey.shade200,
          width: zone.isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getZoneIcon(zone.type),
                    color: typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (zone.isActive)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: zone.isActive,
                  onChanged: onToggle,
                  activeColor: typeColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              zone.description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Affects: ${zone.nodeIds.length} locations, ${zone.edgeKeys.length} corridors',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getZoneColor(TriageZoneType type) {
    switch (type) {
      case TriageZoneType.emergencySurge: return Colors.red;
      case TriageZoneType.traumaResponse: return Colors.deepOrange;
      case TriageZoneType.icuIsolation: return Colors.purple;
      case TriageZoneType.quarantine: return Colors.amber.shade800;
      case TriageZoneType.general: return Colors.blue;
    }
  }

  IconData _getZoneIcon(TriageZoneType type) {
    switch (type) {
      case TriageZoneType.emergencySurge: return Icons.emergency;
      case TriageZoneType.traumaResponse: return Icons.local_hospital;
      case TriageZoneType.icuIsolation: return Icons.monitor_heart;
      case TriageZoneType.quarantine: return Icons.coronavirus;
      case TriageZoneType.general: return Icons.warning;
    }
  }
}

class _CongestionScheduleCard extends StatelessWidget {
  const _CongestionScheduleCard({
    required this.schedule,
    required this.isActiveNow,
    required this.onToggle,
  });

  final CongestionSchedule schedule;
  final bool isActiveNow;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isActiveNow ? Colors.orange.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: isActiveNow ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        schedule.timeRangeString,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActiveNow)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Switch(
                  value: schedule.isEnabled,
                  onChanged: onToggle,
                  activeColor: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Congestion: ×${schedule.congestionMultiplier.toStringAsFixed(1)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Affects: ${schedule.affectedNodeIds.length} areas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
    );
  }
}
