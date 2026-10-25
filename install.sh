#!/usr/bin/env bash
# Agent Harness Kit installer. Works on any project, with or without OpenSpec. bash 3.2+ (macOS ok).
#
#   ./install.sh <target-dir> [options]
#
#   --spec auto|openspec|native|none   planning mode (auto: openspec if openspec/ exists, else native)
#   --stacks auto|a,b,c                ios android react-native flutter frontend backend library generic
#   --tools auto|claude,copilot|none   which agent-tool wrappers to install
#   --ci auto|github|none              CI workflow + PR template
#   --setup-openspec                   run scripts/harness/setup-openspec.sh after install (openspec mode)
#   --upgrade                          refresh kit files you have not modified; changed files get *.harness-new
#   --force                            overwrite existing files (your edits are lost)
#   --dry-run                          show what would happen, write nothing
#   --uninstall                        remove unmodified kit files recorded in harness/.kit-manifest
#
# Existing files are never overwritten by default: a differing file gets a sibling <file>.harness-new.
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
SRC="$KIT/kit"
TARGET=""; SPEC=auto; STACKS=auto; TOOLS=auto; CI=auto
SETUP=0; UPGRADE=0; FORCE=0; DRY=0; UNINSTALL=0
VALID_STACKS="ios android react-native flutter frontend backend library generic"

while [ $# -gt 0 ]; do
  case "$1" in
    --spec) SPEC="${2:?}"; shift 2 ;;
    --stacks) STACKS="${2:?}"; shift 2 ;;
    --tools) TOOLS="${2:?}"; shift 2 ;;
    --ci) CI="${2:?}"; shift 2 ;;
    --setup-openspec) SETUP=1; shift ;;
    --upgrade) UPGRADE=1; shift ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    -*) echo "unknown option $1 (see --help)"; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done
[ -n "$TARGET" ] && [ -d "$TARGET" ] || { echo "usage: $0 <target-dir> [options]   (see --help)"; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"
MANIFEST="$TARGET/harness/.kit-manifest"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi; }
mf_get() { [ -f "$MANIFEST" ] && awk -v p="$1" '$2==p {print $1}' "$MANIFEST" | head -1 || true; }
mf_set() { [ "$DRY" -eq 1 ] && return 0; mkdir -p "$(dirname "$MANIFEST")"; touch "$MANIFEST"
           grep -v "  $1\$" "$MANIFEST" > "$TMP/mf" || true; echo "$2  $1" >> "$TMP/mf"; sort -k2 "$TMP/mf" > "$MANIFEST"; }

# ------------------------------------------------------------------ uninstall
if [ "$UNINSTALL" -eq 1 ]; then
  [ -f "$MANIFEST" ] || { echo "no manifest at $MANIFEST; nothing to uninstall"; exit 1; }
  removed=0; kept=0
  while read -r h p; do
    f="$TARGET/$p"; [ -f "$f" ] || continue
    if [ "$(sha "$f")" = "$h" ]; then [ "$DRY" -eq 1 ] || rm -f "$f"; removed=$((removed+1)); else echo "kept (modified): $p"; kept=$((kept+1)); fi
  done < "$MANIFEST"
  [ "$DRY" -eq 1 ] || { find "$TARGET" -type d -empty -not -path '*/.git/*' -delete 2>/dev/null || true; rm -f "$MANIFEST"; }
  echo "Uninstalled: $removed file(s) removed, $kept modified file(s) kept. harness/stacks.list and .gitignore were left as they are."
  exit 0
fi

# ------------------------------------------------------------------ detection
PRUNE='\( -name node_modules -o -name .git -o -name Pods -o -name build -o -name dist -o -name .gradle -o -name vendor -o -name .dart_tool -o -name DerivedData -o -name .harness \) -prune'
find_all() { eval "find \"\$TARGET\" -maxdepth 6 $PRUNE -o \( -name \"\$1\" \) -type f -print 2>/dev/null | head -20" || true; }
find_dirs() { eval "find \"\$TARGET\" -maxdepth 6 $PRUNE -o \( -name \"\$1\" \) -type d -print 2>/dev/null | head -20" || true; }
rel_dir() { local d="${1#$TARGET}"; d="${d#/}"; [ -n "$d" ] && echo "$d" || echo "."; }
first_pkg_matching() { # <regex> [<exclude-regex>] -> dir of first package.json that matches
  local f
  for f in $(find_all package.json); do
    grep -qE "$1" "$f" 2>/dev/null || continue
    [ -n "${2:-}" ] && grep -qE "$2" "$f" 2>/dev/null && continue
    dirname "$f"; return 0
  done; return 1
}

DETECTED=""   # lines: stack|root
add_detected() { case "$DETECTED" in *"$1|"*) ;; *) DETECTED="$DETECTED$1|$2
" ;; esac; }
detect_stacks() {
  local d f m g
  d=$(first_pkg_matching '"(react-native|expo)"') && add_detected react-native "$(rel_dir "$d")"
  for f in $(find_all pubspec.yaml); do grep -qE '^[[:space:]]*flutter:' "$f" && { add_detected flutter "$(rel_dir "$(dirname "$f")")"; break; }; done
  case "$DETECTED" in *react-native*|*flutter*) ;; *)
    f=$( { find_dirs "*.xcodeproj"; find_dirs "*.xcworkspace"; } | { grep -v "/Pods/" || true; } | head -1 )
    if [ -n "$f" ]; then add_detected ios "$(rel_dir "$(dirname "$f")")"
    else f=$( { find_all Podfile; find_all project.yml; find_all Project.swift; } | head -1 ); [ -n "$f" ] && add_detected ios "$(rel_dir "$(dirname "$f")")"; fi
    m=$(find_all AndroidManifest.xml | head -1)
    if [ -n "$m" ]; then
      g=$(dirname "$m"); while [ "$g" != "$TARGET" ] && [ "$g" != "/" ] && [ ! -f "$g/settings.gradle" ] && [ ! -f "$g/settings.gradle.kts" ]; do g=$(dirname "$g"); done
      add_detected android "$(rel_dir "$g")"
    fi ;;
  esac
  d=$(first_pkg_matching '"(react-dom|next|vue|svelte|@angular/core|vite)"' '"(react-native|expo)"') && add_detected frontend "$(rel_dir "$d")"
  d=$(first_pkg_matching '"(express|fastify|@nestjs/core|koa|hono)"' '"(react-native|expo)"') && add_detected backend "$(rel_dir "$d")"
  for m in go.mod pom.xml Gemfile '*.csproj' requirements.txt Dockerfile docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
    f=$(find_all "$m" | head -1); [ -n "$f" ] && { add_detected backend "$(rel_dir "$(dirname "$f")")"; break; }
  done
  case "$DETECTED" in *backend*) ;; *)
    for m in pyproject.toml Cargo.toml setup.py Package.swift; do
      f=$(find_all "$m" | head -1); [ -n "$f" ] && { case "$DETECTED" in *ios*) ;; *) add_detected library "$(rel_dir "$(dirname "$f")")" ;; esac; break; }
    done ;;
  esac
  [ -n "$DETECTED" ] || add_detected generic "."
}

# ---- spec mode
if [ "$SPEC" = auto ]; then if [ -d "$TARGET/openspec" ]; then SPEC=openspec; else SPEC=native; fi; SPEC_NOTE=" (auto)"; else SPEC_NOTE=""; fi
case "$SPEC" in openspec|native|none) ;; *) echo "--spec must be auto, openspec, native or none"; exit 2 ;; esac
case "$SPEC" in openspec) GATE=fail ;; native) GATE=warn ;; none) GATE=off ;; esac

# ---- stacks
if [ "$STACKS" = auto ]; then detect_stacks; STACK_NOTE=" (auto-detected)"
else
  STACK_NOTE=""; IFS=',' read -ra _s <<<"$STACKS"
  for s in "${_s[@]}"; do case " $VALID_STACKS " in *" $s "*) add_detected "$s" "." ;; *) echo "unknown stack '$s' (valid: $VALID_STACKS)"; exit 2 ;; esac; done
fi
STACK_LIST=$(printf '%s' "$DETECTED" | awk -F'|' 'NF{print $1}')

# ---- tools
if [ "$TOOLS" = auto ]; then
  TOOLS=""
  [ -d "$TARGET/.claude" ] && TOOLS="claude"
  { [ -d "$TARGET/.github/prompts" ] || [ -d "$TARGET/.github/agents" ] || [ -f "$TARGET/.github/copilot-instructions.md" ]; } && TOOLS="$TOOLS copilot"
  [ -n "$TOOLS" ] || TOOLS="claude copilot"; TOOLS_NOTE=" (auto)"
else TOOLS_NOTE=""; [ "$TOOLS" = none ] && TOOLS=""; TOOLS="${TOOLS//,/ }"; fi
for t in $TOOLS; do case "$t" in claude|copilot) ;; *) echo "unknown tool '$t' (claude, copilot)"; exit 2 ;; esac; done
has_tool() { case " $TOOLS " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# ---- ci
if [ "$CI" = auto ]; then
  if [ -d "$TARGET/.github" ]; then CI=github
  elif [ -f "$TARGET/.gitlab-ci.yml" ] || [ -d "$TARGET/.circleci" ] || [ -f "$TARGET/Jenkinsfile" ] || [ -f "$TARGET/azure-pipelines.yml" ] || [ -f "$TARGET/bitbucket-pipelines.yml" ]; then CI=none
  else CI=github; fi; CI_NOTE=" (auto)"
else CI_NOTE=""; fi
case "$CI" in github|none) ;; *) echo "--ci must be auto, github or none"; exit 2 ;; esac

echo "Target:  $TARGET"
echo "Spec:    $SPEC$SPEC_NOTE     CI spec gate: $GATE"
echo "Stacks:  $(printf '%s' "$DETECTED" | awk -F'|' 'NF{printf "%s(%s) ", $1, $2}')$STACK_NOTE"
echo "Tools:   ${TOOLS:-none}$TOOLS_NOTE     CI: $CI$CI_NOTE"
[ "$DRY" -eq 1 ] && echo "(dry run: nothing will be written)"
[ "$SPEC" = openspec ] && [ ! -d "$TARGET/openspec" ] && echo "NOTE: openspec/ not found. Run 'openspec init' in the project (npm i -g @fission-ai/openspec)."
echo

# ------------------------------------------------------------------ install
created=0; kept=0; upgraded=0
render() { # <src> <dst-tmp> <rel>
  case "$3" in
    harness/harness.conf) sed -e "s/__SPEC_MODE__/$SPEC/" -e "s/__CI_SPEC_GATE__/$GATE/" -e "s/__AGENT_TOOLS__/$TOOLS/" "$1" > "$2" ;;
    harness/stacks/*.env)
      local name root; name=$(basename "$3" .env); root=$(printf '%s' "$DETECTED" | awk -F'|' -v s="$name" '$1==s{print $2; exit}')
      local pm=""
      case "$name" in
        frontend|react-native)
          local rd="$TARGET/${root:-.}"
          if [ -f "$rd/pnpm-lock.yaml" ]; then pm=pnpm; elif [ -f "$rd/yarn.lock" ]; then pm=yarn
          elif [ -f "$rd/bun.lockb" ] || [ -f "$rd/bun.lock" ]; then pm=bun; else pm=npm; fi ;;
      esac
      cp "$1" "$2"
      if [ -n "$root" ] && [ "$root" != "." ]; then sed "s#^ROOT=.*#ROOT=$root#" "$2" > "$2.t" && mv "$2.t" "$2"; fi
      if [ -n "$pm" ]; then sed "s#^PM=.*#PM=$pm#" "$2" > "$2.t" && mv "$2.t" "$2"; fi ;;
    *) cp "$1" "$2" ;;
  esac
}
place() { # <src> <rel>
  local src="$1" rel="$2" dest="$TARGET/$2" r="$TMP/render" mfsha cur
  render "$src" "$r" "$rel"
  if [ ! -e "$dest" ]; then
    echo "create     $rel"; created=$((created+1))
    [ "$DRY" -eq 1 ] || { mkdir -p "$(dirname "$dest")"; cp "$r" "$dest"; [ -x "$src" ] && chmod +x "$dest"; mf_set "$rel" "$(sha "$r")"; }
  elif cmp -s "$r" "$dest"; then
    [ -n "$(mf_get "$rel")" ] || mf_set "$rel" "$(sha "$r")"
  else
    mfsha=$(mf_get "$rel"); cur=$(sha "$dest")
    if [ "$FORCE" -eq 1 ] || { [ "$UPGRADE" -eq 1 ] && [ -n "$mfsha" ] && [ "$cur" = "$mfsha" ]; }; then
      echo "update     $rel"; upgraded=$((upgraded+1))
      [ "$DRY" -eq 1 ] || { cp "$r" "$dest"; [ -x "$src" ] && chmod +x "$dest"; mf_set "$rel" "$(sha "$r")"; }
    else
      echo "exists     $rel  -> $rel.harness-new (merge by hand)"; kept=$((kept+1))
      [ "$DRY" -eq 1 ] || cp "$r" "$dest.harness-new"
    fi
  fi
}
place_tree() { # <src-dir> [<dest-prefix>]
  local sd="$1" pre="${2:-}" f
  [ -d "$sd" ] || return 0
  find "$sd" -type f | sort | while IFS= read -r f; do echo "$f"; done > "$TMP/files"
  while IFS= read -r f; do place "$f" "$pre${f#$sd/}"; done < "$TMP/files"
}

place_tree "$SRC/core"
place_tree "$SRC/modes/$SPEC"
for t in $TOOLS; do place_tree "$SRC/tools/$t"; done
[ "$CI" = github ] && place_tree "$SRC/ci/github"
for s in $STACK_LIST; do
  [ -d "$SRC/stacks/$s" ] || continue
  find "$SRC/stacks/$s" -type f -not -path "$SRC/stacks/$s/copilot/*" | sort > "$TMP/sf"
  while IFS= read -r f; do place "$f" "${f#$SRC/stacks/$s/}"; done < "$TMP/sf"
  has_tool copilot && place_tree "$SRC/stacks/$s/copilot" ".github/instructions/"
done

# stacks.list (append, never duplicate), .gitignore, permissions
if [ "$DRY" -eq 0 ]; then
  mkdir -p "$TARGET/harness"; touch "$TARGET/harness/stacks.list"
  [ -s "$TARGET/harness/stacks.list" ] || printf '# One stack per line. Each needs harness/stacks/<name>.env (copy one to add a second app of the same kind, e.g. frontend-admin).\n' > "$TARGET/harness/stacks.list"
  for s in $STACK_LIST; do grep -qxF "$s" "$TARGET/harness/stacks.list" || echo "$s" >> "$TARGET/harness/stacks.list"; done
  touch "$TARGET/.gitignore"; grep -qxF ".harness/" "$TARGET/.gitignore" || printf '\n# agent harness logs\n.harness/\n' >> "$TARGET/.gitignore"
  chmod +x "$TARGET"/scripts/harness/*.sh 2>/dev/null || true
  cp "$KIT/VERSION" "$TARGET/harness/VERSION" 2>/dev/null || true
fi

echo; echo "Done: $created created, $upgraded updated, $kept left alone (see *.harness-new)."

if [ "$DRY" -eq 0 ]; then
  if [ "$SPEC" = openspec ] && [ -d "$TARGET/openspec" ]; then
    if [ "$SETUP" -eq 1 ]; then (cd "$TARGET" && scripts/harness/setup-openspec.sh) || echo "setup-openspec.sh failed; see its message, then rerun it."
    else echo "Next (OpenSpec): scripts/harness/setup-openspec.sh   (adds review + test-plan artifacts, keeps your config keys)"; fi
  fi
  echo; echo "Health check:"; (cd "$TARGET" && scripts/harness/doctor.sh) || true
  cat <<MSG

Make it yours, in this order:
  1. harness/stacks/*.env              real build/test/lint/e2e commands and ROOT   (doctor.sh lists what is missing)
  2. ARCHITECTURE.md + harness/arch-rules/*.rules   your layers, as lint rules
  3. docs/stack-*.md, docs/testing.md  test identifiers, launch state, fixtures
  4. harness/harness.conf              spec mode, CI strictness, limits
  5. harness/roles/*.md                tune the reviewer/evaluator rubrics to your team
Then: scripts/harness/verify.sh --fast && scripts/harness/check-docs.sh, commit, and run your first change through docs/workflow.md.
Later: ./install.sh <target> --upgrade pulls kit improvements without touching files you edited.
MSG
fi
