// Copyright (C) 2016 Maxim Gumin, The MIT License (MIT)

import 'dart:typed_data';

import 'package:wfc/src/logging/logger.dart';
import 'package:wfc/src/tile.dart';

import 'package:wfc/src/bitmap_helper.dart';
import 'package:wfc/src/base_model.dart';

/// OverlappingModel
/// extends the base class Model
/// loads a bitmap to be manipulated
/// initializes the sample and color values to make them available for manipulation
/// by the base class
/// overrides the save method to store the created bitmap to a specified location
class OverlappingModel extends Model {
  /// list of collors
  late List<int> colors;

  ///list of patterns
  late List<Uint8List> patterns;

  /// what to use for handling logging
  late final LogHandler logHandler;

  /// constructor
  /// OverlappingModel - extends Model to handle manipulating a loaded bitmap
  /// Inputs
  /// Tile tile              - the description of the tile taken from the JSON file
  /// String bitmapLocation  - where to find the bitmap to work on
  /// LogHandler logHandler  - {optional} - used to log events
  OverlappingModel(Tile tile, String bitmapLocation, {LogHandler? logHandler})
      : logHandler = logHandler ?? Logger().log,
        super(tile) {
    //define the location of the bitmap
    // Load bitmap and dimensions
    BitmapResult bitmapResult = BitmapHelper.loadBitmap(bitmapLocation);
    List<int> bitmap = bitmapResult.bitmap;
    int sX = bitmapResult.width;
    int sY = bitmapResult.height;

    // Initialize `sample` and `colors`
    List<int> sample = List.generate(bitmap.length, (_) => 0);
    colors = [];

    for (int i = 0; i < sample.length; i++) {
      int color = bitmap[i];
      int k = colors.indexOf(color);
      if (k == -1) {
        colors.add(color);
        k = colors.length - 1;
      }
      sample[i] = k;
    }

    // Helper functions
    Uint8List pattern(Function(int, int) f, int N) {
      var result = Uint8List(N * N);
      for (int y = 0; y < N; y++) {
        for (int x = 0; x < N; x++) {
          result[x + y * N] = f(x, y);
        }
      }
      return result;
    }

    Uint8List rotate(Uint8List p, int N) =>
        pattern((x, y) => p[N - 1 - y + x * N], N);

    Uint8List reflect(Uint8List p, int N) =>
        pattern((x, y) => p[N - 1 - x + y * N], N);

    int hash(Uint8List p, int C) {
      int result = 0, power = 1;
      for (int i = 0; i < p.length; i++) {
        result += p[p.length - 1 - i] * power;
        power *= C;
      }
      return result;
    }

    // Main initialization logic
    patterns = [];
    Map<int, int> patternIndices = {};
    List<double> weightList = [];

    int C = colors.length;
    int xmax = tile.periodicInput ? sX : sX - N + 1;
    int ymax = tile.periodicInput ? sY : sY - N + 1;

    // iterate though the x and y coordiantes applying the
    // roation and reflection
    for (int y = 0; y < ymax; y++) {
      for (int x = 0; x < xmax; x++) {
        List<Uint8List> ps = List.generate(8, (_) => Uint8List(N * N));
        ps[0] =
            pattern((dx, dy) => sample[(x + dx) % sX + (y + dy) % sY * sX], N);
        ps[1] = reflect(ps[0], N);
        ps[2] = rotate(ps[0], N);
        ps[3] = reflect(ps[2], N);
        ps[4] = rotate(ps[2], N);
        ps[5] = reflect(ps[4], N);
        ps[6] = rotate(ps[4], N);
        ps[7] = reflect(ps[6], N);

        // determine and store the weights based
        // on the requested tile symmetry
        for (int k = 0; k < tile.symmetry; k++) {
          Uint8List p = ps[k];
          int h = hash(p, C);
          if (patternIndices.containsKey(h)) {
            weightList[patternIndices[h]!] += 1.0;
          } else {
            patternIndices[h] = weightList.length;
            weightList.add(1.0);
            patterns.add(p);
          }
        }
      }
    }

    // set the base values for the weights
    weights = weightList;
    T = weights.length;
    ground = tile.ground;

    // closure to iterate through the x and y coordinates and detect if they 'agree'
    bool agrees(Uint8List p1, Uint8List p2, int dx, int dy, int N) {
      int xmin = dx < 0 ? 0 : dx;
      int xmax = dx < 0 ? dx + N : N;
      int ymin = dy < 0 ? 0 : dy;
      int ymax = dy < 0 ? dy + N : N;

      for (int y = ymin; y < ymax; y++) {
        for (int x = xmin; x < xmax; x++) {
          if (p1[x + N * y] != p2[x - dx + N * (y - dy)]) {
            return false;
          }
        }
      }
      return true;
    }

    // iterate though the directions and values and propagate (add to the propogate matrix) where there is agreement
    propagator = Matrix3D.twoD(4, T, 0);
    if (propagator != null) {
      for (int d = 0; d < 4; d++) {
        for (int t = 0; t < T; t++) {
          List<int> list = [];
          for (int t2 = 0; t2 < T; t2++) {
            if (agrees(
                patterns[t], patterns[t2], Model.dx[d], Model.dy[d], N)) {
              list.add(t2);
            }
          }
          propagator![d][t] = list;
        }
      }
    }
  }

  // save - saves the bitmap data to a specified location with its number seed
  @override
  void save(String path, Tile tile, int seed) {
    List<int> bitmap = List.generate(mX * mY, (index) => 0);

    if (observed[0] >= 0) {
      for (int y = 0; y < mY; y++) {
        int dy = y < mY - N + 1 ? 0 : N - 1;
        for (int x = 0; x < mX; x++) {
          int dx = x < mX - N + 1 ? 0 : N - 1;
          bitmap[x + y * mX] =
              colors[patterns[observed[x - dx + (y - dy) * mX]][dx + dy * N]];
        }
      }
    } else {
      for (int i = 0; i < wave!.length; i++) {
        int contributors = 0, r = 0, g = 0, b = 0;
        int x = i % mX, y = i ~/ mX;

        for (int dy = 0; dy < N; dy++) {
          for (int dx = 0; dx < N; dx++) {
            int sx = x - dx;
            if (sx < 0) {
              sx += mX;
            }

            int sy = y - dy;
            if (sy < 0) {
              sy += mY;
            }

            int s = sx + sy * mX;

            if (!periodic && (sx + N > mX || sy + N > mY || sx < 0 || sy < 0)) {
              continue;
            }

            for (int t = 0; t < T; t++) {
              if (wave![s][t]) {
                contributors++;
                int argb = colors[patterns[t][dx + dy * N]];
                r += (argb & 0xff0000) >> 16;
                g += (argb & 0xff00) >> 8;
                b += argb & 0xff;
              }
            }
          }
        }

        bitmap[i] = (0xff000000 |
                ((r ~/ contributors) << 16).toInt() |
                ((g ~/ contributors) << 8).toInt() |
                (b ~/ contributors).toInt())
            .toSigned(32); // Ensure a signed 32-bit integer
      }
    }

    // attempt to save the file and log any failures
    try {
      BitmapHelper bitmapHelper = BitmapHelper();
      bitmapHelper.saveBitmap(bitmap, mX, mY, "$path$tileName $seed.png");
    } catch (e) {
      logHandler(e.toString(), level: LogLevel.error);
    }
  }
}
