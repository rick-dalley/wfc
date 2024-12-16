import 'dart:convert';
import 'dart:io';

/// LogLevel
/// Controls the verbosity and location of logging
enum LogLevel {
  /// debug level
  debug,

  /// info for the user
  info,

  /// warning - unusual
  warning,

  /// error - a problem
  error,

  /// none - no level has been supplied
  none
}

/// LogHandler function declaration
typedef LogHandler = void Function(String message, {LogLevel level});

/// Logger
/// a custom logger
class Logger {
  /// levelConfig a map of the types of logging
  Map<LogLevel, LogConfig>? levelConfig;

  /// the function that will do the logging
  final LogHandler logHandler;

  /// notified
  bool notified = false;

  ///Constructors
  ///Logger
  Logger({this.logHandler = defaultLogHandler});

  /// Logger.startWith - lets you initialize with a path and a handler
  Logger.startWith(String configPath, {LogHandler? logHandler})
      : levelConfig = _readConfig(configPath),
        logHandler = logHandler ?? defaultLogHandler;

  /// startWith - if unavailable at construction let's you set the configPath after you've constructed the log handler
  void startWith(String configPath) {
    levelConfig = _readConfig(configPath);
  }

  /// defaultLogHandler - provide a simple logger for writing to the screen
  static void defaultLogHandler(String message,
      {LogLevel level = LogLevel.info}) {
    print(message);
  }

  /// log - log a message of a particular level
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

/// LogConfig
/// Takes the log type and relates it to a user defined output destincation
/// defaults to the screen.
class LogConfig {
  /// enabled
  final bool enabled;

  /// type of outpuyt
  final String outputType;

  ///local location of output
  final String? filePath;

  /// URI
  final Uri? serviceUri;

  ///LogConfig
  /// param - (bool) enable - enable the output
  /// parame - (String)  outputType - the destination of the output
  /// param - (String)  filePath - if a local drive - the path
  /// param - (Uri)  serviceUri - if elsewhere the Uri
  LogConfig({
    required this.enabled,
    required this.outputType,
    this.filePath,
    this.serviceUri,
  });

  /// construct from the config map
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

/// an extension to provide strings for the logging level
extension LogLevelExtension on LogLevel {
  /// name - the string representation
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
