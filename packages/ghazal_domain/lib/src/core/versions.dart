/// The `ETag` / `If-Match` form of a document version: `"v7"` (api-conventions section 8). Bookings and settings documents carry `version`.
String versionTag(int version) => '"v$version"';
