/// Heuristic
/// defines the type of Heuristic to use when performing the wfc
enum Heuristic {
  /// unassigned
  unassigned,

  /// entropy
  entropy,

  /// scanline
  scanline,

  /// mrv
  mrv
}

/// get the heuristic from a string
Map<String, Heuristic> heuristicFromString = {
  "Scanline": Heuristic.scanline,
  "Entropy": Heuristic.entropy,
  "MRV": Heuristic.mrv,
};

/// Category
/// the two types of output
enum Category {
  /// simple tiled output
  simpletiled,

  ///overlapping output
  overlapping
}

/// get the category from a string - i.e. from reading xml
Map<String, Category> categoryFromString = {
  "simpletiled": Category.simpletiled,
  "overlapping": Category.overlapping,
};

/// Tile
/// The description of the input bitmap to use, and
/// what the wfc algorithm should do with it
class Tile {
  // members
  /// size - dimensions of the tile
  int size = 24;

  /// width - usually the size
  int width = 0;

  /// height - usually the size
  int height = 0;

  /// is it periodic
  bool periodic = false;

  /// what category of tile is this
  Category category = Category.overlapping;

  /// the name of the tile
  String name = "";

  /// what heuristice to use
  Heuristic heuristic = Heuristic.unassigned;

  /// subset
  String subset = "";

  /// black background
  bool blackBackground = true;

  /// the dimensions in tiels
  int N = 3;

  /// periodic input
  bool periodicInput = false;

  /// symmetry
  int symmetry = 8;

  /// ground
  bool ground = true;

  /// limit
  int limit = -1;

  /// number of screenshots to make
  int screenshots = 2;

  /// textOuptut to accompany the bitmap
  bool textOutput = false;

  //constructors

  /// Tile
  Tile();

  /// fromJSON
  Tile.fromJSON(Map<String, dynamic> tileJSONMap) {
    String categoryName = tileJSONMap["type"] ?? "overlapping";
    category = categoryFromString[categoryName] ?? Category.overlapping;
    String heuristicName = tileJSONMap["heuristic"] ?? "entropy";
    heuristic = heuristicFromString[heuristicName] ?? Heuristic.entropy;

    name = tileJSONMap["name"] ?? "";
    periodic = tileJSONMap["periodic"] ?? true;
    subset = tileJSONMap["subset"] ?? "";
    blackBackground = tileJSONMap["blackBackground"] ?? true;
    textOutput = tileJSONMap["textOutput"] ?? true;
    size = tileJSONMap["size"] ?? 24;
    if (category == Category.overlapping) {
      size = 48;
      N = tileJSONMap["N"] ?? 3;
      periodicInput = tileJSONMap["periodicInput"] != false;
      symmetry = tileJSONMap["symmetry"] ?? 8;
      ground = tileJSONMap["ground"] == true;
      screenshots = tileJSONMap["screenshots"] ?? 2;
      limit = tileJSONMap["limit"] ?? -1;
    }
    width = tileJSONMap["width"] ?? size;
    height = tileJSONMap["height"] ?? size;
  }
}
