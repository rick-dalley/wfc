import 'dart:io';
import 'package:image/image.dart' as img;

/// Pair = stores the result of a function that needs to return two values as a tuple
class Pair<T> {
  /// any pair x of type T
  final T x;

  /// any pair y of type T
  final T y;

  /// Constructior
  Pair(this.x, this.y);

  // Override == operator to compare Pair objects
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pair<T> && other.x == x && other.y == y);

  // Override hashCode to ensure correct behavior in collections
  @override
  int get hashCode =>
      Object.hash(x, y); // Use Object.hash for better combination
}

/// Matrix - handles a two dimensional array of T
class Matrix<T> {
  final List<List<T>> _matrix;

  /// Constructor that accepts rows and optional initial columns with a default value
  Matrix(int rows, [int initialCols = 0, T? defaultValue])
      : _matrix = List.generate(
          rows,
          (_) => initialCols == 0
              ? [] // Empty row
              : List.generate(initialCols, (_) => defaultValue as T),
        );

  /// Getter for the number of rows
  int get length => _matrix.length;

  /// Override [] to access elements directly (for a row or a specific element)
  dynamic operator [](var index) {
    if (index is List<int>) {
      // Accessing a specific element with [row, col]
      int row = index[0];
      int col = index[1];
      if (row >= 0 && row < length && col >= 0 && col < _matrix[row].length) {
        return _matrix[row][col];
      } else {
        throw RangeError('Index out of bounds');
      }
    } else if (index is int) {
      // Accessing a specific row with [row]
      if (index >= 0 && index < length) {
        return _matrix[index]; // Returns the entire row (List<T>)
      } else {
        throw RangeError('Index out of bounds');
      }
    } else {
      throw ArgumentError('Invalid index type');
    }
  }

  /// Override []= to modify elements or rows
  void operator []=(var index, dynamic value) {
    if (index is List<int>) {
      // Modifying a specific element with [row, col]
      int row = index[0];
      int col = index[1];
      if (row >= 0 && row < length && col >= 0 && col < _matrix[row].length) {
        if (value is T) {
          _matrix[row][col] = value;
        } else {
          throw ArgumentError('Value must be of type $T');
        }
      } else {
        throw RangeError('Index out of bounds');
      }
    } else if (index is int) {
      // Modifying a specific row with [row]
      if (index >= 0 && index < length) {
        if (value is List<T>) {
          _matrix[index] = value; // Replace the row
        } else {
          throw ArgumentError('Value must be a List<$T>');
        }
      } else {
        throw RangeError('Index out of bounds');
      }
    } else {
      throw ArgumentError('Invalid index type');
    }
  }

  /// Method to print the matrix for debugging
  @override
  String toString() {
    String matrixString = "";
    for (var row in _matrix) {
      for (int i = 0; i < row.length; i++) {
        matrixString += "${row[i]}, ";
      }
      matrixString = matrixString.substring(0, matrixString.length - 1);
      matrixString += "| ";
    }
    return matrixString;
  }
}

/// Matrix3D handles a 3D array of T
class Matrix3D<T> {
  final List<List<List<T>>> _matrix;

  /// Constructors
  /// Matrix3D - all dimensions
  Matrix3D([int layers = 0, int rows = 0, int cols = 0, T? defaultValue])
      : _matrix = List.generate(
          layers,
          (_) => rows > 0
              ? List.generate(
                  rows,
                  (_) => cols > 0
                      ? List.generate(cols, (_) => defaultValue as T)
                      : [],
                )
              : [],
        );

  /// Matrix3D.twoD - only supply the first 2 dimensions
  Matrix3D.twoD(int layers, int rows, T? defaultValue)
      : _matrix = List.generate(
          layers,
          (_) => List.generate(
            rows,
            (_) => [], // Third dimension initialized as empty lists
          ),
        );

  /// Access or dynamically grow a specific layer
  List<List<T>> operator [](int layerIndex) {
    // Ensure layer-level growth
    while (_matrix.length <= layerIndex) {
      _matrix.add([]); // Add empty layers dynamically
    }
    return _matrix[layerIndex];
  }

  /// Replace a layer
  void operator []=(int layerIndex, List<List<T>> newLayer) {
    // Ensure the layer exists before replacing it
    while (_matrix.length <= layerIndex) {
      _matrix.add([]);
    }
    _matrix[layerIndex] = newLayer;
  }

  @override
  String toString() {
    String matrixString = "";
    for (var layer in _matrix) {
      for (var row in layer) {
        for (int i = 0; i < row.length; i++) {
          matrixString += "${row[i]}, ";
        }
        matrixString = matrixString.substring(0, matrixString.length - 1);
        matrixString += "| ";
      }
      matrixString += "\n";
    }
    return matrixString;
  }
}

/// Helper
class Helper {
  /// random - provide a random number based on a list of weights
  int random(List<double> weights, double r) {
    double sum = 0;
    for (int i = 0; i < weights.length; i++) {
      sum += weights[i];
    }
    double threshold = r * sum;

    double partialSum = 0;
    for (int i = 0; i < weights.length; i++) {
      partialSum += weights[i];
      if (partialSum >= threshold) return i;
    }
    return 0;
  }

  /// toPower
  int toPower(int a, int n) {
    int product = 1;
    for (int i = 0; i < n; i++) {
      product *= a;
    }
    return product;
  }
}

/// BitmapResult
/// holds the reulst of creating a bitmap
/// bitmap - the data of the bitmap as an array of ints
/// width - the width as an integer
/// height - the height as an integer
class BitmapResult {
  /// bitmap - the bitmap data
  final List<int> bitmap;

  /// width - the number of pixels wide
  final int width;

  /// height - the number of pixels high
  final int height;

  /// BitmapResult constructor
  BitmapResult(this.bitmap, this.width, this.height);
}

/// BitmapHelper
// - a utility class to load and save bitmaps
class BitmapHelper {
  /// load a bitmap from a given location
  static BitmapResult loadBitmap(String filename) {
    // Load the image from file as a byte list
    // Load and decode the image from file
    final bytes = File(filename).readAsBytesSync();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Unable to decode image: $filename');
    }

    final width = image.width;
    final height = image.height;

    // Convert the image pixels to a List<int> (BGRA32 equivalent)
    final result = <int>[];

    for (var pixel in image) {
      final bgra32 = ((pixel.r.toInt()) << 16) |
          ((pixel.g.toInt()) << 8) |
          (pixel.b.toInt()) |
          ((pixel.a.toInt()) << 24);

      result.add(bgra32);
    }

    return BitmapResult(result, width, height);
  }

  /// saveBitmap
  /// save a list of ints as a bitmap at a specified location with the specified dimensions
  /// as a png
  void saveBitmap(List<int> data, int width, int height, String fileName) {
    // Create an empty image
    final image = img.Image(width: width, height: height);

    // Convert BGRA32 format back to the image pixels
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int index = y * width + x;
        int pixel = data[index];
        // Extract RGBA components from BGRA32
        int r = (pixel & 0xFF0000) >> 16;
        int g = (pixel & 0xFF00) >> 8;
        int b = pixel & 0xFF;
        int a = (pixel & 0xFF000000) >> 24;

        // Manually set the pixel color in RGBA format
        image.setPixelRgba(x, y, r, g, b, a);
      }
    }

    // Save the image as a PNG
    File(fileName).writeAsBytesSync(img.encodePng(image));
  }

  /// rotate
  /// Rotate the bitmap 90 degrees clockwise
  BitmapResult rotate(BitmapResult bitmapResult, int size) {
    List<int> rotatedBitmap = List<int>.filled(size * size, 0);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        rotatedBitmap[x + y * size] =
            bitmapResult.bitmap[(size - 1 - y) + x * size];
      }
    }
    return BitmapResult(rotatedBitmap, bitmapResult.width, bitmapResult.height);
  }

  /// reflect
  /// Reflect the bitmap horizontally
  BitmapResult reflect(BitmapResult bitmapResult, int size) {
    List<int> reflectedBitmap = List<int>.filled(size * size, 0);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        reflectedBitmap[x + y * size] =
            bitmapResult.bitmap[(size - 1 - x) + y * size];
      }
    }
    return BitmapResult(
        reflectedBitmap, bitmapResult.width, bitmapResult.height);
  }
}
