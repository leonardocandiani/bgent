#!/usr/bin/env bash
# bgent release helper.
#
# Bumps the version in both plugin manifests and prepends a CHANGELOG section,
# then stages the changes. It does NOT commit or push — you fill in the changelog
# notes and run the printed git commands yourself, so publishing stays in your hands.
#
# Usage: ./release.sh <new-version>      e.g.  ./release.sh 1.1.0
set -euo pipefail
cd "$(dirname "$0")"

NEW="${1:-}"
[ -z "$NEW" ] && { echo "usage: ./release.sh <new-version>  (e.g. 1.1.0)"; exit 1; }
echo "$NEW" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo "error: version must be semver X.Y.Z"; exit 1; }

PLUGIN=".claude-plugin/plugin.json"
MARKET=".claude-plugin/marketplace.json"
CHANGELOG="CHANGELOG.md"

OLD=$(python3 -c "import json;print(json.load(open('$PLUGIN'))['version'])")
[ "$OLD" = "$NEW" ] && { echo "error: $NEW is already the current version"; exit 1; }
echo "bumping $OLD -> $NEW"

# bump version in both manifests
python3 - "$NEW" <<'PY'
import json, sys
new = sys.argv[1]
p = json.load(open(".claude-plugin/plugin.json")); p["version"] = new
json.dump(p, open(".claude-plugin/plugin.json", "w"), indent=2, ensure_ascii=False)
open(".claude-plugin/plugin.json", "a").write("\n")
m = json.load(open(".claude-plugin/marketplace.json"))
m["metadata"]["version"] = new
for pl in m.get("plugins", []): pl["version"] = new
json.dump(m, open(".claude-plugin/marketplace.json", "w"), indent=2, ensure_ascii=False)
open(".claude-plugin/marketplace.json", "a").write("\n")
PY

# prepend a dated stub section to the changelog (fill it before committing)
DATE=$(date +%Y-%m-%d)
TMP=$(mktemp)
{
  head -n 5 "$CHANGELOG"
  printf '## [%s] - %s\n\n### Changed\n- TODO: describe the changes\n\n' "$NEW" "$DATE"
  tail -n +6 "$CHANGELOG"
} > "$TMP" && mv "$TMP" "$CHANGELOG"

git add "$PLUGIN" "$MARKET" "$CHANGELOG"

cat <<EOF

staged v$NEW. next:
  1. edit $CHANGELOG and fill the v$NEW notes
  2. git commit -m "release: v$NEW"
  3. git tag v$NEW
  4. git push && git push --tags
EOF
