/// Development surface of ghazal_ui for galleries and tests (ghazal_testing, the foundation gallery). Apps never import this:
/// components read semantic roles (GzColors) only; the reference ramps are not part of the product API (ADR 0023 D7).
library;

export 'src/tokens/generated/gz_colors.g.dart' show GzRefColors;
