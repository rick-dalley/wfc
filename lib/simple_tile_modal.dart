import 'dart:io';
import 'package:wfc/bitmap_helper.dart';
import 'package:wfc/base_model.dart';
import 'package:wfc/logging/logger.dart';
import 'package:wfc/tile.dart';
import 'package:xml/xml.dart';

// SimpleTiledModel
// extends the base class - Model with features to read the tile featurs from xml
// and produce the bitmap using wave function collapse on the base
// each instance must have an accompanying xml file describing the intention
class SimpleTiledModel extends Model {
  // the log handler
  late final LogHandler logHandler;

  List<List<int>> tiles = [];
  List<String> tilenames = [];
  int tilesize = 0;
  bool blackBackground = false;

  // SimpleTiledModel - constructor
  // accepts the tile specified by the user, with the location of the description
  // and an optional logger.  If none is supplied the default is used
  // Inputs
  // Tile tile              - a description of the tile from the JSON
  // String tileSetPath     - the location of the xml file describing how  to manipulate and use the bitmap
  // LogHandler LogHandler  - {optional} logs events that occur
  SimpleTiledModel(Tile tile, String tileSetPath, {LogHandler? logHandler})
      : logHandler = logHandler ?? Logger().log,
        super(tile) {
    //set the background preference for having a blackBackground
    blackBackground = tile.blackBackground;

    //load the xml description
    Result<XmlDocument> document = _loadXmlDocument(tileSetPath, tile.name);
    if (document.failed) {
      throw Exception("Could not load the XML document for ${tile.name}");
    }

    // assign xroot from the document
    var xroot = document.value!.rootElement;
    //get the property unique
    var unique = xroot.getAttribute('unique') == 'True';

    // if a subset was specified - load the subset values as a list of strings
    List<String>? subset;
    if (tile.subset != "") {
      Result result = _createSubset(tile, xroot);
      if (result.failed) {
        throw Exception(result.error);
      }
      subset = result.value;
    }

    // make a list of integegers for the tiles
    List<int> makeTiles(Function(int x, int y) f, int size) {
      return List.generate(size * size, (i) {
        int x = i % size;
        int y = i ~/ size;
        return f(x, y);
      });
    }

    // rotate the values
    List<int> rotate(List<int> array, int size) => makeTiles((x, y) => array[size - 1 - y + x * size], size);

    //reflect the values
    List<int> reflect(List<int> array, int size) => makeTiles((x, y) => array[size - 1 - x + y * size], size);

    List<double> weightList = [];
    List<List<int>> action = [];
    Map<String, int> firstOccurrence = {};

    // iterate through the xml elements capturing the behaviour expected
    for (var xtile in xroot.findElements('tiles').expand((e) => e.findElements('tile'))) {
      //get the name of the tile
      String tilename = xtile.getAttribute('name')!;
      // check if there is a subset with the name of the tile
      if (subset != null && !subset.contains(tilename)) {
        continue;
      }

      // assign a function based on the symmetry required
      int Function(int) a, b;
      int cardinality;

      var sym = xtile.getAttribute('symmetry') ?? 'X';
      if (sym == 'L') {
        cardinality = 4;
        a = (i) => (i + 1) % 4;
        b = (i) => i % 2 == 0 ? i + 1 : i - 1;
      } else if (sym == 'T') {
        cardinality = 4;
        a = (i) => (i + 1) % 4;
        b = (i) => i % 2 == 0 ? i : 4 - i;
      } else if (sym == 'I') {
        cardinality = 2;
        a = (i) => 1 - i;
        b = (i) => i;
      } else if (sym == '\\') {
        cardinality = 2;
        a = (i) => 1 - i;
        b = (i) => 1 - i;
      } else if (sym == 'F') {
        cardinality = 8;
        a = (i) => i < 4 ? (i + 1) % 4 : 4 + (i - 1) % 4;
        b = (i) => i < 4 ? i + 4 : i - 4;
      } else {
        cardinality = 1;
        a = (i) => i;
        b = (i) => i;
      }

      T = action.length;
      firstOccurrence[tilename] = T;

      // iterate for cardinality (based on the symmetry)
      // ans assign a map of functions
      Matrix<int> map = Matrix(cardinality, 8, 0);
      for (int t = 0; t < cardinality; t++) {
        map[t][0] = t;
        map[t][1] = a(t);
        map[t][2] = a(a(t));
        map[t][3] = a(a(a(t)));
        map[t][4] = b(t);
        map[t][5] = b(a(t));
        map[t][6] = b(a(a(t)));
        map[t][7] = b(a(a(a(t))));

        for (int s = 0; s < 8; s++) {
          map[t][s] += T;
        }

        // add the map for this tile
        action.add(map[t]);
      }

      // if unique was specified
      if (unique) {
        // iterate throough the cardinality and load the bitamps
        for (int t = 0; t < cardinality; t++) {
          String tilesetFileName = "$tilename $t.png";
          String bitmapLocation = "$tileSetPath/${tile.name}/$tilesetFileName";
          BitmapResult bitmapResult = BitmapHelper.loadBitmap(bitmapLocation);
          tilesize = bitmapResult.width;
          tiles.add(bitmapResult.bitmap);
          tilenames.add('$tilename $t');
        }
      } else {
        // otherwise load the bitmap
        String bitmapLocation = "$tileSetPath/${tile.name}/$tilename.png";
        BitmapResult bitmapResult = BitmapHelper.loadBitmap(bitmapLocation);
        tilesize = bitmapResult.width;
        tiles.add(bitmapResult.bitmap);
        tilenames.add('$tilename 0');

        // and conditionally add rotations and reflections of the original
        for (int t = 1; t < cardinality; t++) {
          if (t <= 3) tiles.add(rotate(tiles[T + t - 1], tilesize));
          if (t >= 4) tiles.add(reflect(tiles[T + t - 4], tilesize));
          tilenames.add('$tilename $t');
        }
      }

      // add the specified weight to apply to the list of weights (based on cardinality)
      for (int t = 0; t < cardinality; t++) {
        weightList.add(double.parse(xtile.getAttribute('weight') ?? '1.0'));
      }
    }

    // get the length of the iterations
    T = action.length;
    weights = weightList; // and the widghts

    Matrix3D<bool> densePropagator = Matrix3D<bool>(4, T, T, false);
    propagator = Matrix3D<int>(4, T, T, 0);

    // find the neighbours
    for (var xneighbor in xroot.findElements('neighbors').expand((e) => e.findElements('neighbor'))) {
      List<String> left = xneighbor.getAttribute('left')!.split(' ').where((item) => item.isNotEmpty).toList();
      List<String> right = xneighbor.getAttribute('right')!.split(' ').where((item) => item.isNotEmpty).toList();

      if (subset != null && (!subset.contains(left[0]) || !subset.contains(right[0]))) {
        continue;
      }

      // apply the actions
      int firstLeftOccurence = firstOccurrence[left[0]]!;
      int firstRightOccurrence = firstOccurrence[right[0]]!;

      int L = action[firstLeftOccurence][left.length == 1 ? 0 : int.parse(left[1])];
      int D = action[L][1];
      int R = action[firstRightOccurrence][right.length == 1 ? 0 : int.parse(right[1])];
      int U = action[R][1];

      densePropagator[0][R][L] = true;
      densePropagator[0][action[R][6]][action[L][6]] = true;
      densePropagator[0][action[L][4]][action[R][4]] = true;
      densePropagator[0][action[L][2]][action[R][2]] = true;

      densePropagator[1][U][D] = true;
      densePropagator[1][action[D][6]][action[U][6]] = true;
      densePropagator[1][action[U][4]][action[D][4]] = true;
      densePropagator[1][action[D][2]][action[U][2]] = true;
    }

    for (int t2 = 0; t2 < T; t2++) {
      for (int t1 = 0; t1 < T; t1++) {
        densePropagator[2][t2][t1] = densePropagator[0][t1][t2];
        densePropagator[3][t2][t1] = densePropagator[1][t1][t2];
      }
    }

    // Initialize the sparsePropagator
    Matrix3D<int> sparsePropagator = Matrix3D<int>(4, T, T, 0);

    for (int d = 0; d < 4; d++) {
      for (int t1 = 0; t1 < T; t1++) {
        List<int> sp = []; // Temporary list for compatible patterns
        for (int t2 = 0; t2 < T; t2++) {
          if (densePropagator[d][t1][t2]) {
            sp.add(t2);
          }
        }

        int sT = sp.length;
        if (sT == 0) {
          logHandler!("tile ${tilenames[t1]} has no neighbors in this direction: $d", level: LogLevel.error);
        }

        // Store the compatible patterns in the sparse propagator
        sparsePropagator[d][t1] = sp;
      }
    }

    // Assign sparsePropagator data to propagator
    for (int d = 0; d < 4; d++) {
      for (int t1 = 0; t1 < T; t1++) {
        propagator![d][t1] = sparsePropagator[d][t1];
      }
    }
  }

  /// Loads and parses the XML document. Returns a Result containing the document or an error.
  Result<XmlDocument> _loadXmlDocument(String tileSetPath, String tileName) {
    final filePath = '$tileSetPath/$tileName.xml';
    final file = File(filePath);

    if (!file.existsSync()) {
      return Result.failure('Tile file not found: $filePath');
    }

    try {
      final content = file.readAsStringSync();
      final document = XmlDocument.parse(content);
      return Result.success(document);
    } catch (e) {
      return Result.failure('Failed to parse XML document: $e');
    }
  }

  // return the subset from the xml
  Result<List<String>> _createSubset(Tile tile, XmlElement xroot) {
    if (tile.subset.isEmpty) {
      return Result.failure("the subset is empty");
    }

    try {
      final xsubset = xroot
          .findElements('subsets')
          .expand((e) => e.findElements('subset'))
          .firstWhere((x) => x.getAttribute('name') == tile.subset);

      return Result.success(xsubset.findElements('tile').map((x) => x.getAttribute('name')!).toList());
    } catch (e) {
      return Result.failure("Subset '${tile.subset}' not found");
    }
  }

  // assemble and save the bitmap
  @override
  void save(String path, Tile tile, int seed) {
    List<int> bitmapData = List.generate(mX * mY * tilesize * tilesize, (index) => 0);

    if (observed[0] >= 0) {
      for (int x = 0; x < mX; x++) {
        for (int y = 0; y < mY; y++) {
          List<int> tile = tiles[observed[x + y * mX]];
          for (int dy = 0; dy < tilesize; dy++) {
            for (int dx = 0; dx < tilesize; dx++) {
              bitmapData[x * tilesize + dx + (y * tilesize + dy) * mX * tilesize] = tile[dx + dy * tilesize];
            }
          }
        }
      }
    } else {
      for (int i = 0; i < wave!.length; i++) {
        int x = i % mX, y = i ~/ mX;
        if (blackBackground && sumsOfOnes[i] == T) {
          for (int yt = 0; yt < tilesize; yt++) {
            for (int xt = 0; xt < tilesize; xt++) {
              bitmapData[x * tilesize + xt + (y * tilesize + yt) * mX * tilesize] = 0xff000000;
            }
          }
        } else {
          List<bool> w = wave![i];
          double normalization = sumsOfWeights[i] > 0 ? 1.0 / sumsOfWeights[i] : 0.0;
          for (int yt = 0; yt < tilesize; yt++) {
            for (int xt = 0; xt < tilesize; xt++) {
              int idi = x * tilesize + xt + (y * tilesize + yt) * mX * tilesize;
              double r = 0, g = 0, b = 0;
              for (int t = 0; t < T; t++) {
                if (w[t]) {
                  int argb = tiles[t][xt + yt * tilesize];
                  r += ((argb & 0xff0000) >> 16) * weights[t] * normalization;
                  g += ((argb & 0xff00) >> 8) * weights[t] * normalization;
                  b += (argb & 0xff) * weights[t] * normalization;
                }
              }
              r = r.clamp(0, 255);
              g = g.clamp(0, 255);
              b = b.clamp(0, 255);
              bitmapData[idi] = (0xff000000 | (r.toInt() << 16) | (g.toInt() << 8) | b.toInt()) & 0xFFFFFFFF;
            }
          }
        }
      }
    }

    // attempt to save the bitmpap and log any failures
    try {
      BitmapHelper.saveBitmap(bitmapData, mX * tilesize, mY * tilesize, "$path$tileName $seed.png");
      if (!tile.textOutput) {
        File('$path$tileName $seed.txt').writeAsStringSync(textOutput());
      }
    } catch (e) {
      logHandler(e.toString(), level: LogLevel.error);
    }
  }

  String textOutput() {
    StringBuffer stringBuffer = StringBuffer();
    for (int y = 0; y < mY; y++) {
      for (int x = 0; x < mX; x++) {
        stringBuffer.write('${tilenames[observed[x + y * mX]]}, ');
      }
      stringBuffer.writeln();
    }
    return stringBuffer.toString();
  }
}
