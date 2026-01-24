/// Demo scenario model
class DemoScenario {
  final String id;
  final String name;
  final String description;
  final String startNode;
  final String destinationNode;
  final String accessibility;
  final List<String> conditions;

  DemoScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.startNode,
    required this.destinationNode,
    required this.accessibility,
    required this.conditions,
  });

  factory DemoScenario.fromJson(Map<String, dynamic> json) {
    return DemoScenario(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      startNode: json['startNode'] as String,
      destinationNode: json['destinationNode'] as String,
      accessibility: json['accessibility'] as String,
      conditions: List<String>.from(json['conditions']),
    );
  }
}
