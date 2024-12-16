import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:wfc/wfc.dart';

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
  // Set up paths
  final String currentDirectory = Directory.current.path;
  final String jsonPath = "$currentDirectory/assets/samples.json";
  final String outputPath = "$currentDirectory/example_output/";

  // Clean the output directory
  final outputDirectory = Directory(outputPath);
  if (!outputDirectory.existsSync()) {
    outputDirectory.createSync();
  } else {
    outputDirectory.listSync().whereType<File>().forEach((file) => file.deleteSync());
  }

  // Load the sample tile data
  final tiles = await parseTilesFromFile(jsonPath);

  // Create a random seed
  final random = Random();
  int seed = random.nextInt(1 << 32);

  // Pick the first tile to demonstrate
  if (tiles.isNotEmpty) {
    final tile = tiles.first;

    // Create a model from the tile
    final model = createModel(tile, currentDirectory);

    // Run the algorithm and save the output
    if (model.run(seed, tile.limit)) {
      model.save(outputPath, tile, seed);
      print("Example completed successfully. Output saved to $outputPath");
    } else {
      print("A contradiction occurred while running the algorithm.");
    }
  } else {
    print("No tiles found in $jsonPath.");
  }
}
