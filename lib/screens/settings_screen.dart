import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/navigation_state.dart';

/// Settings screen for accessibility and condition preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Consumer<NavigationState>(
        builder: (context, state, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Accessibility section
              _buildSectionHeader('Accessibility'),
              const SizedBox(height: 12),
              _buildAccessibilityOptions(state),
              const SizedBox(height: 32),

              // Conditions section
              _buildSectionHeader('Active Conditions'),
              const SizedBox(height: 12),
              _buildConditionOptions(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildAccessibilityOptions(NavigationState state) {
    return Column(
      children: [
        _buildAccessibilityTile(
          state,
          AccessibilityProfile.normal,
          'Normal',
          'Standard route preferences',
          Icons.directions_walk,
          Colors.blue,
        ),
        _buildAccessibilityTile(
          state,
          AccessibilityProfile.wheelchair,
          'Wheelchair',
          'Avoid stairs, prefer lifts',
          Icons.accessible,
          Colors.purple,
        ),
        _buildAccessibilityTile(
          state,
          AccessibilityProfile.assisted,
          'Assisted',
          'Easier routes, fewer stairs',
          Icons.elderly,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildAccessibilityTile(
    NavigationState state,
    AccessibilityProfile profile,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = state.accessibilityProfile == profile;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => state.setAccessibilityProfile(profile),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionOptions(NavigationState state) {
    return Column(
      children: [
        _buildConditionTile(
          state,
          ActiveCondition.normal,
          'Normal',
          'Standard building conditions',
          Icons.check_circle_outline,
          Colors.green,
        ),
        _buildConditionTile(
          state,
          ActiveCondition.emergency,
          'Emergency',
          'Emergency routes active',
          Icons.warning,
          Colors.red,
        ),
        _buildConditionTile(
          state,
          ActiveCondition.maintenance,
          'Maintenance',
          'Some areas under maintenance',
          Icons.construction,
          Colors.orange,
        ),
        _buildConditionTile(
          state,
          ActiveCondition.congestion,
          'High Traffic',
          'Avoid congested areas',
          Icons.groups,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildConditionTile(
    NavigationState state,
    ActiveCondition condition,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isActive = state.activeConditions.contains(condition);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isActive ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            if (condition == ActiveCondition.normal) {
              // Normal clears all other conditions
              state.setActiveConditions({ActiveCondition.normal});
            } else {
              if (isActive) {
                state.removeCondition(condition);
                if (state.activeConditions.isEmpty) {
                  state.addCondition(ActiveCondition.normal);
                }
              } else {
                state.removeCondition(ActiveCondition.normal);
                state.addCondition(condition);
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive ? color : Colors.grey.shade200,
                width: isActive ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (value) {
                    if (condition == ActiveCondition.normal) {
                      state.setActiveConditions({ActiveCondition.normal});
                    } else {
                      if (value) {
                        state.removeCondition(ActiveCondition.normal);
                        state.addCondition(condition);
                      } else {
                        state.removeCondition(condition);
                        if (state.activeConditions.isEmpty) {
                          state.addCondition(ActiveCondition.normal);
                        }
                      }
                    }
                  },
                  activeColor: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
