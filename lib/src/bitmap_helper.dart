import 'dart:io';

import 'package:image/image.dart' as img;

// Pair = stores the result of a function that needs to return two values as a tuple
class Pair<T> {
  final T x;
  final T y;

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

// Matrix<T> - handles a two dimensional array of T
class Matrix<T> {
  final List<List<T>> _matrix;

  // Constructor that accepts rows and optional initial columns with a default value
  Matrix(int rows, [int initialCols = 0, T? defaultValue])
      : _matrix = List.generate(
          rows,
          (_) => initialCols == 0
              ? [] // Empty row
              : List.generate(initialCols, (_) => defaultValue as T),
        );

  // Getter for the number of rows
  int get length => _matrix.length;

  // Override [] to access elements directly (for a row or a specific element)
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

  // Override []= to modify elements or rows
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

  // Method to print the matrix for debugging
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

// Matrix3D<T> handles a 3D array of T
class Matrix3D<T> {
  final List<List<List<T>>> _matrix;

  //constructors
  // supply all dimensions
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

  //only supply the first 2 dimensions
  Matrix3D.twoD(int layers, int rows, T? defaultValue)
      : _matrix = List.generate(
          layers,
          (_) => List.generate(
            rows,
            (_) => [], // Third dimension initialized as empty lists
          ),
        );
  // Access or dynamically grow a specific layer
  List<List<T>> operator [](int layerIndex) {
    // Ensure layer-level growth
    while (_matrix.length <= layerIndex) {
      _matrix.add([]); // Add empty layers dynamically
    }
    return _matrix[layerIndex];
  }

  // Replace a layer
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

// this class is not used anywhere
// you can comment it out if you like
// it was included in the original source code in C#
class Helper {
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

  int toPower(int a, int n) {
    int product = 1;
    for (int i = 0; i < n; i++) {
      product *= a;
    }
    return product;
  }
}

// BitmapResult holds the reulst of creating a bitmap
// bitmap - the data of the bitmap as an array of ints
// width - the width as an integer
// height - the height as an integer
class BitmapResult {
  final List<int> bitmap;
  final int width;
  final int height;

  BitmapResult(this.bitmap, this.width, this.height);
}

// BitmapHelper - a utility class to load and save bitmaps
class BitmapHelper {
  // load a bitmap from a given location
  static BitmapResult loadBitmap(String filename) {
    // Load the image from file as a byte list
    final bytes = File(filename).readAsBytesSync();
    final image =
        img.decodeImage(bytes)!; // Decode the image from the byte list

    int width = image.width;
    int height = image.height;

    // Convert the image pixels to a List<int> (BGRA32 equivalent)
    List<int> result = List<int>.generate(width * height, (i) {
      int pixel = image.getPixel(i % width, i ~/ width);
      // Assuming BGRA32 format
      return (pixel & 0xFF00FF00) |
          ((pixel & 0xFF0000) >> 16) |
          ((pixel & 0xFF) << 16);
    });

    return BitmapResult(result, width, height);
  }

  // saveBitmap
  // save a list of ints as a bitmap at a specified location with the specified dimensions
  // as a png
  static void saveBitmap(
      List<int> data, int width, int height, String fileName) {
    // Create an empty image
    final image = img.Image(width, height);
    // Convert BGRA32 format back to the image pixels
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int index = y * width + x;
        int pixel = data[index];
        // Assuming BGRA32 format
        image.setPixel(
            x,
            y,
            img.getColor(
                (pixel & 0xFF0000) >> 16, (pixel & 0xFF00) >> 8, pixel & 0xFF));
      }
    }

    // Save the image as a PNG
    File(fileName).writeAsBytesSync(img.encodePng(image));
  }

  // rotate
  // Rotate the bitmap 90 degrees clockwise
  static BitmapResult rotate(BitmapResult bitmapResult, int size) {
    List<int> rotatedBitmap = List<int>.filled(size * size, 0);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        rotatedBitmap[x + y * size] =
            bitmapResult.bitmap[(size - 1 - y) + x * size];
      }
    }
    return BitmapResult(rotatedBitmap, bitmapResult.width, bitmapResult.height);
  }

  // reflect
  // Reflect the bitmap horizontally
  static BitmapResult reflect(BitmapResult bitmapResult, int size) {
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
