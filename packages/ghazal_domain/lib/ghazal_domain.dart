/// Entities (the wire models generated from the OpenAPI contract), repository interfaces and client-visible helpers. Pure Dart: no Flutter.
///
/// Repositories throw `ApiProblem` of `ghazal_core` (raised by `ghazal_api`: problem+json, or its `offline` / `timeout` form).
///
/// Source of truth: `packages/contracts/openapi/ghazal.v1.yaml`. Regenerate with `node tools/gen-dart-models.mjs` (never edit `*.g.dart`).
library;

export 'src/core/core.dart';
export 'src/domain_version.dart';
export 'src/models/models.g.dart';
export 'src/repositories/repositories.g.dart';
