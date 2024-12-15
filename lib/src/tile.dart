enum Heuristic { unassigned, entropy, scanline, mrv }

Map<String, Heuristic> heuristicFromString = {
  "Scanline": Heuristic.scanline,
  "Entropy": Heuristic.entropy,
  "MRV": Heuristic.mrv,
};

enum Category { simpletiled, overlapping }

Map<String, Category> categoryFromString = {
  "simpletiled": Category.simpletiled,
  "overlapping": Category.overlapping,
};

class Tile {
  // members
  int size = 24;
  int width = 0;
  int height = 0;
  bool periodic = false;
  Category category = Category.overlapping;
  String name = "";
  Heuristic heuristic = Heuristic.unassigned;
  String subset = "";
  bool blackBackground = true;
  int N = 3;
  bool periodicInput = false;
  int symmetry = 8;
  bool ground = true;
  int limit = -1;
  int screenshots = 2;
  bool textOutput = false;

  //constructors

  //default
  Tile();

  //fromJSON
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
