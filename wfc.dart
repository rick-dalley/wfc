import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:wfc/base_model.dart';
import 'package:wfc/logging/logger.dart';
import 'package:wfc/tile.dart';

Logger logger = Logger();

Future<List<Tile>> parseTilesFromFile(String filePath) async {
  final fileContent = await File(filePath).readAsString();

  // Parse the JSON content
  final List<dynamic> jsonList = jsonDecode(fileContent);

  // Map JSON elements to Tile objects
  List<Tile> tileList = [];
  for (var tileMap in jsonList) {
    try {
      var parsedTile = Tile.fromJSON(tileMap as Map<String, dynamic>);
      tileList.add(parsedTile);
    } catch (e) {
      logger.log('Error parsing tile: $tileMap, Error: $e');
    }
  }
  return tileList;
}

void prepareOutputDestination(String pathToOutput) {
  final folder = Directory(pathToOutput);
  if (!folder.existsSync()) {
    folder.createSync();
  }

  // Iterate through files in the directory and delete them
  folder.listSync().whereType<File>().forEach((file) {
    file.deleteSync();
  });
}

void main() async {
  //intitialize location values
  final String currentDirectory = Directory.current.path;
  final String jsonPath = "$currentDirectory/lib/samples.json";
  final String loggingPath = "$currentDirectory/lib/logging/config.json";

  // start the logger
  logger.startWith(loggingPath);

  // ensure we have a clean "output" directory
  prepareOutputDestination("output");

  final random = Random();

  // start the stop watch
  Stopwatch sw = Stopwatch()..start();

  // Load the JSON document and get the list of tiles
  final tiles = await parseTilesFromFile(jsonPath);
  // Iterate over elements "overlapping" and "simpletiled"
  for (Tile tile in tiles) {
    logger.log("Collapsing ${tile.name}");
    final model = createModel(tile, currentDirectory, logHandler: logger.log);
    for (int i = 0; i < tile.screenshots; i++) {
      for (int k = 0; k < 10; k++) {
        int seed = random.nextInt(1 << 32); // Generate a random seed
        if (model.run(seed, tile.limit)) {
          model.save("$currentDirectory/output/", tile, seed);
          logger.log("... done: $seed.");
          break;
        } else {
          logger.log("... contradiction occurred.");
        }
      }
    }
  }

  //stop the stop watch
  sw.stop();

  //show the elapsed time
  logger.log("time = ${sw.elapsedMilliseconds}");
}
