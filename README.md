# Wave Function Collapse in Dart

This repository contains a Dart implementation of the [Wave Function Collapse](https://github.com/mxgmn/WaveFunctionCollapse) algorithm, originally written in C# by mxgmn. Wave Function Collapse (WFC) is a constraint-solving algorithm often used for procedural content generation, such as creating bitmaps, maps, or levels.

## Acknowledgments

This project is a reimplementation of the [Wave Function Collapse algorithm](https://github.com/mxgmn/WaveFunctionCollapse) created by [mxgmn](https://github.com/mxgmn). The original C# version serves as the foundation and inspiration for this Dart implementation.

The purpose of this project is to make the algorithm accessible to developers working in Dart, including those building cross-platform applications with [Flutter](https://flutter.dev/).

All credit for the core ideas and concepts of WFC goes to mxgmn. This repository focuses on translating the implementation into Dart while adhering to Dart-specific conventions and idioms.

## Features

- A Dart-based reimplementation of the Wave Function Collapse algorithm.
- Designed for compatibility with Flutter and other Dart applications.
- Reads tile configurations from XML and JSON files, similar to the original implementation.
- Customizable logging with support for user-defined log handlers.
- A custom logger has been provided as an example:

```
  import 'package:wfc/src/logging/logger.dart'; // in other projects if you'd like to try it
```

- Includes helper classes for bitmap manipulation and procedural content generation.

## Usage

1. **Clone the repository**:

```bash
   git clone https://github.com/rick-dalley/wfc.git
   cd wfc
```

2. **Install dependencies**:
   Ensure you have Dart installed on your system. Install dependencies by running:

```
   dart pub get
```

3. **Run the project**:
   To execute the example provided in main.dart, use:

````
   dart run
````

4. **Input files**:
   Place your XML configuration files in the appropriate directory (e.g., lib/tilesets).
   Modify the sample JSON file (samples.json) to include your tile configurations.

5. **Output**:
   Generated bitmaps and optional text outputs will be saved in the output/ directory. Samples of the output can be found in the [output folder](https://github.com/rick-dalley/wfc/tree/master/output)

## Importing the Package

To use the `wfc` package, in your own projects, import the public API (look in example/example.dart or ./main.dart to see examples):

````
   dart
   import 'package:wfc/wfc.dart';
````

## Code Structure

- `lib/src/`:
  - `base_model.dart`: Defines the abstract base model for Wave Function Collapse.
  - `simple_tile_model.dart`: Implements the tile-based WFC algorithm.
  - `logging/logger.dart`: Provides logging functionality with customizable log levels.
  - `tile.dart`: Represents tile configurations.
  - `bitmap_helper.dart`: Contains utility functions for bitmap manipulation.
- `main.dart`: Example usage of the algorithm, which reads all inputs and creates multiple outputs to give an idea of the breadth of the functionality
- `example/example.dart`: Example usage that demonstrates an output
- `output/`: Directory where generated outputs are saved.

6. **Contributing**

Contributions are welcome! If you find a bug or have a suggestion for improvement, feel free to open an issue or submit a pull request.

### Steps to Contribute:

1. Fork this repository.
2. Create a new branch for your changes:

```
git checkout -b feature/my-feature
```

3. Commit your changes:

```
git commit -m "Add my feature"
```

4. Push to your branch:

```
git push origin feature/my-feature
```

5. Open a pull request.
   Make sure to follow the existing coding style and include tests where applicable.

6. **License**

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

The original C# implementation by mxgmn is also licensed under the MIT License.
