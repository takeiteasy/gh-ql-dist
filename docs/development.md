# Development

| Path | Purpose |
|---|---|
| `scripts/ql-dist` | Generator: manifest in, dist tree and new tarballs out |
| `scripts/parse-asd.lisp` | Reads `defsystem` forms with sbcl |
| `action.yml` | Runs the generator in a workflow |
| `.github/workflows/build.yml` | Reusable workflow: generate, release, commit, deploy |
| `notify/action.yml` | Per-repo tag notifier |
| `example/` | Files to copy into a new dist repo |
| `skills/ql-dist/` | Claude Code skill: copy to `~/.claude/skills/` |
| `tests/run.sh` | Fixture tests with local git repos |

## Run the tests

Needs `git` and `sbcl`.

```sh
tests/run.sh
```

## Run the generator

```sh
scripts/ql-dist --manifest projects.txt --name mydist \
  --site-url https://me.github.io/ql-dist \
  --release-url https://github.com/me/ql-dist/releases/download \
  --dir out --tarballs tarballs
```

`--check` verifies `--dir`; `--fetch` also downloads tarballs missing from `--tarballs`.

## Format

Files follow the Quicklisp index format: whitespace is a single space, system files in `systems.txt` omit `.asd`, and the dist version directory holds `distinfo.txt`, `releases.txt` and `systems.txt`.
