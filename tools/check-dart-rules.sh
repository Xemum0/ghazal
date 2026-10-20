#!/usr/bin/env bash
# Dart guardrails (docs/engineering/flutter-build-plan.md section 5, ADR 0022 K, ADR 0036 item 6).
#   tools/check-dart-rules.sh [--fix-hints] [path...]      (default: apps and the six packages/ghazal_* packages)
# Exit 1 with `file:line: [rule] text` lines when a rule is broken. Fast: one grep per rule. Generated l10n, build output and
# the tokens folder (for the colour rules) are exempt. Rules:
#   no-framework-material   package:flutter/material.dart or cupertino.dart imported anywhere
#   ui-only-material-ui     package:material_ui / cupertino_ui imported outside packages/ghazal_ui
#   no-raw-color            Color(0x or Colors. outside packages/ghazal_ui/lib/src/tokens/
#   no-physical-direction   EdgeInsets.only(left|right, Alignment.centerLeft|..., Positioned(left|right, TextAlign.left|right
#   no-text-literal         a string literal directly inside Text( (outside tests and ghazal_testing)
#   no-letter-spacing       letterSpacing other than 0 (Arabic-capable styles must be 0; Latin tracking goes through tokens)
#   no-heavy-layers         BackdropFilter / ImageFiltered / Opacity( outside allow-list files
#   no-cross-feature-import apps/*/lib/features/<a>/ importing features/<b>/ (the routes file of another feature is also banned)
set -u
cd "$(dirname "$0")/.." || exit 2
HINTS=0
ROOTS=()
for a in "$@"; do
  case "$a" in
    --fix-hints) HINTS=1 ;;
    *) ROOTS+=("$a") ;;
  esac
done
[ ${#ROOTS[@]} -eq 0 ] && ROOTS=(apps packages/ghazal_ui packages/ghazal_core packages/ghazal_domain packages/ghazal_api packages/ghazal_mock_api packages/ghazal_testing)

# allow-list for heavy-layer widgets (one path per line; add a file only with a comment explaining why)
HEAVY_ALLOW=("packages/ghazal_ui/lib/src/effects/")

FILES=$(find "${ROOTS[@]}" -name '*.dart' -not -path '*/build/*' -not -path '*/.dart_tool/*' -not -path '*/lib/l10n/generated/*' \
  -not -path '*/android/*' -not -path '*/ios/*' -not -name '*.g.dart' 2>/dev/null | sort)
[ -z "$FILES" ] && { echo "check-dart-rules: no Dart files"; exit 0; }

TMP=$(mktemp -t gzrules.XXXXXX)
OUT=$(mktemp -t gzrules-out.XXXXXX)
trap 'rm -f "$TMP" "$OUT"' EXIT

report() { # rule, hint, then grep -n lines on stdin as file:line:text
  local rule="$1" hint="$2" n=0 line
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    # a trailing `// gz-rules-ok` on the line silences a deliberate exception
    case "$line" in *"gz-rules-ok"*) continue ;; esac
    echo "$line" | sed -E "s#^([^:]+:[0-9]+):(.*)#\1: [$rule] \2#" | cut -c1-220 | tee -a "$OUT"
    n=$((n + 1))
  done
  if [ "$n" -gt 0 ] && [ "$HINTS" = 1 ]; then
    echo "    hint [$rule]: $hint" | tee -a "$OUT"
  fi
  return 0
}

# grep over FILES (xargs keeps argv short); -H with -n for file:line
g() { echo "$FILES" | xargs grep -HnE "$@" 2>/dev/null; }
# same but excluding some path patterns from the file list
gx() { local excl="$1"; shift; echo "$FILES" | grep -Ev "$excl" | xargs grep -HnE "$@" 2>/dev/null; }

g "^\s*(import|export)\s+'package:flutter/(material|cupertino)\.dart'" |
  report no-framework-material "import package:flutter/widgets.dart in apps; in ghazal_ui import package:material_ui/material_ui.dart (or cupertino_ui)"

gx '^packages/ghazal_ui/' "^\s*(import|export)\s+'package:(material_ui|cupertino_ui)/" |
  report ui-only-material-ui "apps and other packages import package:ghazal_ui/ghazal_ui.dart and flutter/widgets.dart; add the Gz component to ghazal_ui (requests.md)"

gx '^packages/ghazal_ui/lib/src/tokens/' '(\bColor\(0x|\bColors\.[a-zA-Z])' |
  report no-raw-color "use a semantic token (GzColors) from ghazal_ui; ask for a missing value in docs/engineering/requests.md"

g '(EdgeInsets\.only\([^)]*\b(left|right)\s*:|Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)\b|Positioned\(\s*[^)]*\b(left|right)\s*:|TextAlign\.(left|right)\b|BorderRadius\.only\([^)]*\b(topLeft|topRight|bottomLeft|bottomRight)\s*:|Radius\.circular.*topLeft)' |
  report no-physical-direction "EdgeInsetsDirectional.only(start/end), AlignmentDirectional.centerStart, PositionedDirectional(start/end), TextAlign.start/end, BorderRadiusDirectional.only"

gx '(^|/)test/|^packages/ghazal_testing/' "\bText\(\s*(const\s+)?['\"]" |
  report no-text-literal "read the string from AppL10n / GzL10n (gen_l10n); never a literal, never a hand-typed number"

gx '(^|/)test/|^packages/ghazal_testing/|^packages/ghazal_ui/lib/src/tokens/' '\bletterSpacing\s*:\s*[-0-9.]*[1-9]' |
  report no-letter-spacing "letterSpacing is 0 for Arabic; Latin tracking comes from the type token"

HEAVY_RE=$(printf '%s|' "${HEAVY_ALLOW[@]}" | sed 's/|$//')
gx "^($HEAVY_RE)" '\b(BackdropFilter|ImageFiltered|Opacity)\(' |
  report no-heavy-layers "use alpha colours (Color.withValues(alpha:)), AnimatedOpacity on leaf widgets via an allow-listed ghazal_ui helper, never blur"

# cross-feature imports (apps only): features/<a>/... importing features/<b>/... for b != a (package: and relative imports)
echo "$FILES" | grep -E '^apps/[^/]+/lib/features/' | while IFS= read -r f; do
  grep -HnE "^\s*(import|export)\s+'[^']+'" "$f" 2>/dev/null |
    awk -v file="$f" -F"'" '
      BEGIN { n = split(file, fp, "/"); for (k = 1; k < n; k++) dir[k] = fp[k]; depth = n - 1
              match(file, /features\/[^\/]+/); feat = substr(file, RSTART + 9, RLENGTH - 9) }
      { p = $2; target = ""
        if (p ~ /^package:/) { if (p ~ /\/features\//) { split(p, a, "/features/"); split(a[2], b, "/"); target = b[1] } }
        else if (p !~ /^dart:/) {
          m = split(p, seg, "/"); d = depth; for (k = 1; k <= depth; k++) cur[k] = dir[k]
          for (k = 1; k < m; k++) { if (seg[k] == "..") d--; else if (seg[k] != ".") { d++; cur[d] = seg[k] } }
          for (k = 1; k < d; k++) if (cur[k] == "features") { target = cur[k + 1]; break }
        }
        if (target != "" && target != feat) print $0 }'
done > "$TMP"
report no-cross-feature-import "share through ghazal_ui / ghazal_core / ghazal_domain, a provider in lib/app, or navigate by route name (context.goNamed('CL-XXXX-NN'))" < "$TMP"

if [ -s "$OUT" ]; then
  echo "check-dart-rules: FAILED"
  exit 1
fi
echo "check-dart-rules: ok ($(echo "$FILES" | wc -l | tr -d ' ') Dart files)"
