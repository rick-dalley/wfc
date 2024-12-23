import 'dart:math';

import 'package:wfc/src/logging/logger.dart';
import 'package:wfc/src/overlapping_model.dart';
import 'package:wfc/src/simple_tiled_model.dart';

import 'bitmap_helper.dart';
import 'tile.dart';

/// Result
/// Used to store a result that can be tested for pass or fail, and if failed
/// provide an error explanation
class Result<T> {
  /// a result of any type
  final T? value;

  /// a string description of the error
  final String? error;

  /// a boolean indicated whether the result is ok
  final bool ok;

  /// success
  Result.success(this.value)
      : error = null,
        ok = true;

  /// failuer
  Result.failure(this.error)
      : value = null,
        ok = false;

  /// a helper failed instead of explicityly testing for !ok
  bool get failed => !ok;
}

/// enforce saving with a path, tile, and seed
abstract class Saveable {
  /// save should implement saving a bitmap to the path based on the tile, and a random seed to differentiate output files
  void save(String path, Tile tile, int seed);
}

/// Model
/// Is the base model for the classes that perform initialization of the two types
/// of map input
/// Is constructed from a Tile class and performs a run method to produce the bitmap
/// and a save to persist it.
class Model implements Saveable {
  //members

  /// dx
  static List<int> dx = [-1, 0, 1, 0];

  /// dy
  static List<int> dy = [0, 1, 0, -1];

  /// opposite
  static List<int> opposite = [2, 3, 0, 1];

  /// the wave a matrix to guide the collapse
  Matrix<bool>? wave;

  ///propogator
  Matrix3D<int>? propagator;

  ///compatible
  Matrix3D<int>? compatible;

  ///observed
  List<int> observed = [];

  /// stack
  List<Pair<int>> stack = [];

  /// stacksize
  int stacksize = 0;

  ///observed so far
  int observedSoFar = 0;

  /// mx the tile width
  int mX = 0;

  /// the tile height
  int mY = 0;

  /// T
  int T = 0;

  /// N
  int N = 0;

  /// periodice
  bool periodic = false;

  ///ground
  bool ground = false;

  ///weights
  List<double> weights = [];

  ///weightLogWeights
  List<double> weightLogWeights = [];

  ///distribution
  List<double> distribution = [];

  ///sumOfOnes
  List<int> sumsOfOnes = [];

  /// sumOfWeights
  double sumOfWeights = 0.0;

  /// sumOfWeightLogWeights
  double sumOfWeightLogWeights = 0.0;

  /// startingEntropy
  double startingEntropy = 0.0;

  /// sumOfWeights
  List<double> sumsOfWeights = [];

  /// sumOfWeightLogWeights
  List<double> sumsOfWeightLogWeights = [];

  ///entropies
  List<double> entropies = [];

  ///heuristic
  Heuristic heuristic = Heuristic.unassigned;

  ///tileName
  String tileName = "";

  /// Constructors

  /// Model
  /// paramater (Tile)
  Model(Tile tile) {
    mX = tile.width;
    mY = tile.height;
    N = tile.N;
    periodic = tile.periodic;
    heuristic = tile.heuristic;
    tileName = tile.name;
  }

  /// init - setup the members to perform the wfc
  void init() {
    wave = Matrix<bool>(mX * mY, T, false);
    compatible = Matrix3D(wave!.length, T, 4, 0);

    distribution = List.generate(T, (_) => 0.0);
    observed = List.generate(mX * mY, (_) => 0);
    weightLogWeights = List.generate(T, (_) => 0.0);
    sumOfWeights = 0;
    sumOfWeightLogWeights = 0;

    for (int t = 0; t < T; t++) {
      weightLogWeights[t] = weights[t] * log(weights[t]);
      sumOfWeights += weights[t];
      sumOfWeightLogWeights += weightLogWeights[t];
    }

    startingEntropy = log(sumOfWeights) - sumOfWeightLogWeights / sumOfWeights;

    sumsOfOnes = List.generate(mX * mY, (_) => 0);
    sumsOfWeights = List.generate(mX * mY, (_) => 0.0);
    sumsOfWeightLogWeights = List.generate(mX * mY, (_) => 0.0);
    entropies = List.generate(mX * mY, (_) => 0.0);

    stack = List.generate(wave!.length * T, (index) => Pair(0, 0));
    stacksize = 0;
  }

  /// run performs the wave function collapse
  bool run(int seed, int limit) {
    if (wave == null) {
      init();
    }

    clear();
    Random random = Random(seed);

    for (int l = 0; l < limit || limit < 0; l++) {
      int node = nextUnobservedNode(random);
      if (node >= 0) {
        observe(node, random);
        if (!propagate()) {
          return false;
        }
      } else {
        for (int i = 0; i < wave!.length; i++) {
          for (int t = 0; t < T; t++) {
            if (wave![i][t]) {
              observed[i] = t;
              break;
            }
          }
        }
        return true;
      }
    }

    return true;
  }

  /// nextUnobservedNode(closure) picks a random node to compare
  int nextUnobservedNode(Random random) {
    if (heuristic == Heuristic.scanline) {
      for (int i = observedSoFar; i < wave!.length; i++) {
        if (!periodic && (i % mX + N > mX || i / mX + N > mY)) {
          continue;
        }
        if (sumsOfOnes[i] > 1) {
          observedSoFar = i + 1;
          return i;
        }
      }
      return -1;
    }

    double min = 1E+4;
    int argmin = -1;
    for (int i = 0; i < wave!.length; i++) {
      if (!periodic && (i % mX + N > mX || i / mX + N > mY)) {
        continue;
      }
      int remainingValues = sumsOfOnes[i];
      num entropy =
          heuristic == Heuristic.entropy ? entropies[i] : remainingValues;
      if (remainingValues > 1 && entropy <= min) {
        double noise = 1E-6 * random.nextDouble();
        if (entropy + noise < min) {
          min = entropy + noise;
          argmin = i;
        }
      }
    }
    return argmin;
  }

  /// Weighted random selection function
  int weightedRandomSelection(List<double> distribution, double randomValue) {
    // Step 1: Calculate cumulative sum
    List<double> cumulative = [];
    double total = 0.0;
    for (double weight in distribution) {
      total += weight;
      cumulative.add(total);
    }

    // Step 2: Scale the random value to the range [0, total)
    double target = randomValue * total;

    // Step 3: Find the index where the random value falls
    for (int i = 0; i < cumulative.length; i++) {
      if (target < cumulative[i]) {
        return i;
      }
    }

    // Fallback: Return the last index
    return cumulative.length - 1;
  }

  /// observe
  void observe(int node, Random random) {
    List<bool> w = wave![node];
    for (int t = 0; t < T; t++) {
      distribution[t] = w[t] ? weights[t] : 0.0;
    }
    // int r = (random.nextDouble() * T).floor();
    int r = weightedRandomSelection(distribution, random.nextDouble());
    for (int t = 0; t < T; t++) {
      if (w[t] != (t == r)) {
        ban(node, t);
      }
    }
  }

  ///propogate
  bool propagate() {
    while (stacksize > 0) {
      Pair stackItem = stack[stacksize - 1];
      stacksize--;
      int i1 = stackItem.x;
      int t1 = stackItem.y;
      int x1 = i1 % mX;
      int y1 = i1 ~/ mX;

      for (int d = 0; d < 4; d++) {
        int x2 = x1 + dx[d];
        int y2 = y1 + dy[d];
        if (!periodic && (x2 < 0 || y2 < 0 || x2 + N > mX || y2 + N > mY)) {
          continue;
        }

        if (x2 < 0) {
          x2 += mX;
        } else if (x2 >= mX) {
          x2 -= mX;
        }
        if (y2 < 0) {
          y2 += mY;
        } else if (y2 >= mY) {
          y2 -= mY;
        }

        int i2 = x2 + y2 * mX;
        List<int> p = propagator![d][t1];
        List<List<int>> compat = compatible![i2];

        for (int l = 0; l < p.length; l++) {
          int t2 = p[l];
          List<int> comp = compat[t2];

          comp[d]--;
          if (comp[d] == 0) {
            ban(i2, t2);
          }
        }
      }
    }
    return sumsOfOnes[0] > 0;
  }

  /// ban
  void ban(int i, int t) {
    wave![i][t] = false;

    List<int> comp = compatible![i][t];
    for (int d = 0; d < 4; d++) {
      comp[d] = 0;
    }
    stack[stacksize] = Pair<int>(i, t);
    stacksize++;

    sumsOfOnes[i] -= 1;
    sumsOfWeights[i] -= weights[t];
    sumsOfWeightLogWeights[i] -= weightLogWeights[t];

    double sum = sumsOfWeights[i];
    entropies[i] = log(sum) - sumsOfWeightLogWeights[i] / sum;
  }

  /// clear
  void clear() {
    for (int i = 0; i < wave!.length; i++) {
      for (int t = 0; t < T; t++) {
        wave![i][t] = true;

        for (int d = 0; d < 4; d++) {
          compatible![i][t][d] = propagator![opposite[d]][t].length;
        }
      }

      sumsOfOnes[i] = weights.length;
      sumsOfWeights[i] = sumOfWeights;
      sumsOfWeightLogWeights[i] = sumOfWeightLogWeights;
      entropies[i] = startingEntropy;
      observed[i] = -1;
    }
    observedSoFar = 0;

    if (ground) {
      for (int x = 0; x < mX; x++) {
        for (int t = 0; t < T - 1; t++) {
          ban(x + (mY - 1) * mX, t);
        }
        for (int y = 0; y < mY - 1; y++) {
          ban(x + y * mX, T - 1);
        }
      }
      propagate();
    }
  }

  @override
  void save(String path, Tile tile, int seed) {}
}

/// createModel
/// factory method to create a model depending on the tile category : overlapping or simple_tiled
Model createModel(Tile tile, String basePath, {LogHandler? logHandler}) {
  final log =
      logHandler ?? Logger().log; // Use the provided logger or the default one
  if (tile.category == Category.overlapping) {
    return OverlappingModel(tile, "$basePath/assets/samples/${tile.name}.png",
        logHandler: log);
  } else {
    return SimpleTiledModel(tile, "$basePath/assets/tilesets", logHandler: log);
  }
}
