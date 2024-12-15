import 'dart:convert';
import 'dart:io';

enum LogLevel { debug, info, warning, error, none }

typedef LogHandler = void Function(String message, {LogLevel level});

class Logger {
  Map<LogLevel, LogConfig>? levelConfig;
  final LogHandler logHandler;
  bool notified = false;
  Logger({this.logHandler = defaultLogHandler});

  Logger.startWith(String configPath, {LogHandler? logHandler})
      : levelConfig = _readConfig(configPath),
        logHandler = logHandler ?? defaultLogHandler;

  void startWith(String configPath) {
    levelConfig = _readConfig(configPath);
  }

  static void defaultLogHandler(String message,
      {LogLevel level = LogLevel.info}) {
    print(message);
  }

  void log(String message, {LogLevel level = LogLevel.info}) {
    if (levelConfig == null) {
      if (!notified) {
        logHandler(
            'The logger needs a JSON onfiguration file to configure how it operates.\nIt should be located in the logging directory and be named config.json: (working directory)\\logging\\config.json\n and follow the format:\n [ \n {\n "logLevel": "error",\n    "output": {\n      "type": "file",\n      "path": "logging/logs/app.log"\n    }\n  },');
        notified = true;
      }

      // Default behavior: log everything to the console
      logHandler('[${level.name}] $message');
      return;
    }

    final config = levelConfig![level];
    if (config == null || !config.enabled) return;

    final formattedMessage = '[${level.name}] $message';

    switch (config.outputType) {
      case 'console':
        logHandler(formattedMessage);
        break;
      case 'file':
        if (config.filePath != null) {
          _writeToFile(formattedMessage, config.filePath!);
        }
        break;
      case 'service':
        _sendToService(formattedMessage, config.serviceUri);
        break;
      default:
        throw UnsupportedError('Unsupported output type: ${config.outputType}');
    }
  }

  void _writeToFile(String message, String path) {
    final file = File(path);
    file.writeAsStringSync('$message\n', mode: FileMode.append);
  }

  void _sendToService(String message, Uri? serviceUri) {
    if (serviceUri != null) {
      logHandler('Sent to service [$serviceUri]: $message',
          level: LogLevel.info);
    }
  }

  static Map<LogLevel, LogConfig> _readConfig(String path) {
    final file = File(path);
    final contents = file.readAsStringSync();
    final configList = List<Map<String, dynamic>>.from(jsonDecode(contents));
    return {
      for (var config in configList)
        LogLevel.values.firstWhere(
            (lvl) => lvl.name.toLowerCase() == config['logLevel'].toLowerCase(),
            orElse: () => LogLevel.none): LogConfig.fromMap(config)
    };
  }
}

class LogConfig {
  final bool enabled;
  final String outputType;
  final String? filePath;
  final Uri? serviceUri;

  LogConfig({
    required this.enabled,
    required this.outputType,
    this.filePath,
    this.serviceUri,
  });

  factory LogConfig.fromMap(Map<String, dynamic> map) {
    return LogConfig(
      enabled: map['enabled'] ?? true,
      outputType: map['output']['type'],
      filePath: map['output']['type'] == 'file' ? map['output']['path'] : null,
      serviceUri: map['output']['type'] == 'service'
          ? Uri.parse(map['output']['uri'])
          : null,
    );
  }
}

extension LogLevelExtension on LogLevel {
  String get name {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.none:
        return 'NONE';
    }
  }
}
