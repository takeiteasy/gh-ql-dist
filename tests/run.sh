#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QL_DIST="$ROOT/scripts/ql-dist"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

PASS=0 FAIL=0
ok() { PASS=$((PASS + 1)); echo "ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "FAIL $1"; }
assert() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

mkproject() { # name
  local d="$T/src/$1"
  mkdir -p "$d"
  git -C "$d" init -q -b main
  cat > "$d/$1.asd" <<EOF
(asdf:defsystem #:$1
  :depends-on (#:alexandria (:version #:split-sequence "1.0") "cl-ppcre")
  :components ((:file "$1")))
(asdf:defsystem #:$1/sub
  :depends-on (#:$1))
EOF
  echo "(in-package :cl-user)" > "$d/$1.lisp"
  git -C "$d" add -A
  git -C "$d" commit -qm init
}

run() {
  "$QL_DIST" --manifest "$T/projects.txt" --name test --site-url https://site.test/dist-repo \
    --release-url https://rel.test/download --dir "$T/dist-tree" --tarballs "$T/tarballs" "$@"
}

mkproject foo
mkproject bar
git -C "$T/src/foo" tag v0.1.0
git -C "$T/src/bar" tag v1.0.0
printf '%s\n' '# comment' "foo $T/src/foo tags  # trailing" "bar $T/src/bar v1.0.0" > "$T/projects.txt"

echo "== first build"
GITHUB_OUTPUT="$T/out1" run > "$T/log1"
V1="$(sed -n 's/^version: //p' "$T/dist-tree/dist/test.txt")"
REL="$T/dist-tree/dist/test/$V1/releases.txt"
SYS="$T/dist-tree/dist/test/$V1/systems.txt"
assert "reports changed" "grep -q '^changed=true' '$T/out1'"
assert "version is today" "[[ '$V1' == \$(date -u +%F) ]]"
assert "two release lines" "[[ \$(grep -vc '^#' '$REL') -eq 2 ]]"
assert "release url points at release asset" "grep -q 'https://rel.test/download/foo-v0.1.0/foo-v0.1.0.tgz' '$REL'"
assert "system file listed" "grep -q ' foo-v0.1.0 foo.asd\$' '$REL'"
assert "systems are space separated with deps" "grep -qx 'foo foo foo alexandria split-sequence cl-ppcre' '$SYS'"
assert "subsystem listed" "grep -qx 'foo foo foo/sub foo' '$SYS'"
assert "descriptor matches distinfo" "cmp -s '$T/dist-tree/dist/test.txt' '$T/dist-tree/dist/test/$V1/distinfo.txt'"
assert "descriptor urls" "grep -qx 'release-index-url: https://site.test/dist-repo/dist/test/$V1/releases.txt' '$T/dist-tree/dist/test.txt'"
assert "tarball has prefix dir" "tar -tzf '$T/tarballs/foo-v0.1.0.tgz' | grep -q '^foo-v0.1.0/foo.asd\$'"
assert "no .git in tarball" "! tar -tzf '$T/tarballs/foo-v0.1.0.tgz' | grep -q '\.git'"
assert "check passes" "run --check >/dev/null"

echo "== rerun with no change"
rm -rf "$T/tarballs"
GITHUB_OUTPUT="$T/out2" run > "$T/log2"
assert "reports unchanged" "grep -q '^changed=false' '$T/out2'"
assert "no new version dir" "[[ \$(ls '$T/dist-tree/dist/test' | wc -l) -eq 1 ]]"
assert "no tarballs rebuilt" "[[ -z \$(ls '$T/tarballs') ]]"

echo "== new tag"
git -C "$T/src/foo" tag v0.2.0
cp "$REL" "$T/old-releases"
GITHUB_OUTPUT="$T/out3" run > "$T/log3"
V2="$(sed -n 's/^version: //p' "$T/dist-tree/dist/test.txt")"
REL2="$T/dist-tree/dist/test/$V2/releases.txt"
assert "same-day version gets suffix" "[[ '$V2' == '$V1-2' ]]"
assert "only new tarball built" "[[ \$(ls '$T/tarballs') == foo-v0.2.0.tgz ]]"
assert "untouched release carried forward byte-identical" "[[ \$(grep '^bar ' '$REL2') == \$(grep '^bar ' '$T/old-releases') ]]"
assert "old version dir kept" "[[ -f '$REL' ]]"

echo "== --only"
git -C "$T/src/foo" tag v0.3.0
git -C "$T/src/bar" tag v1.1.0
sed -i.bak 's/ v1.0.0$/ tags/' "$T/projects.txt"
run --only foo > "$T/log4"
V3="$(sed -n 's/^version: //p' "$T/dist-tree/dist/test.txt")"
assert "only foo rebuilt" "[[ \$(ls '$T/tarballs' | sort | tr '\n' ' ') == 'foo-v0.2.0.tgz foo-v0.3.0.tgz ' ]]"
assert "bar not advanced" "grep -q '^bar .* bar-v1.0.0 ' '$T/dist-tree/dist/test/$V3/releases.txt'"
GITHUB_OUTPUT="$T/out5" run --only nope > /dev/null
assert "unlisted project ignored" "grep -q '^changed=false' '$T/out5'"

echo "== check"
assert "check passes" "run --check >/dev/null"
echo tamper >> "$T/tarballs/foo-v0.3.0.tgz"
assert "check fails on tampered tarball" "! run --check >/dev/null 2>&1"

echo "== branch and sha refs"
rm -rf "$T/dist-tree" "$T/tarballs"
SHA="$(git -C "$T/src/foo" rev-parse HEAD)"
BSHA="$(git -C "$T/src/bar" rev-parse HEAD)"
printf '%s\n' "foo $T/src/foo main" "bar $T/src/bar $BSHA" > "$T/projects.txt"
run > /dev/null
REL3="$T/dist-tree/dist/test/$(sed -n 's/^version: //p' "$T/dist-tree/dist/test.txt")/releases.txt"
assert "branch version is short sha" "grep -q ' foo-${SHA:0:7} ' '$REL3'"
assert "sha version is short sha" "grep -q ' bar-${BSHA:0:7} ' '$REL3'"

echo "== bad manifest"
printf '%s\n' "foo $T/src/foo" > "$T/projects.txt"
assert "missing ref rejected" "! run >/dev/null 2>&1"
printf '%s\n' "foo $T/src/foo tags" "foo $T/src/foo tags" > "$T/projects.txt"
assert "duplicate rejected" "! run >/dev/null 2>&1"

echo
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
