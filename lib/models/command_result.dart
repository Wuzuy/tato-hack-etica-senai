// lib/models/command_result.dart

class CommandResult {
  final String intent;
  final Map<String, dynamic> parameters;
  final bool success;

  CommandResult({
    required this.intent,
    required this.parameters,
    this.success = true,
  });

  /// Um construtor de fábrica para criar um resultado de falha facilmente.
  factory CommandResult.failure() {
    return CommandResult(intent: 'unknown', parameters: {}, success: false);
  }
}
