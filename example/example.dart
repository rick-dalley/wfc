import 'dart:io';
import 'dart:math';

import 'package:wfc/base_model.dart';

import '../wfc.dart';

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
