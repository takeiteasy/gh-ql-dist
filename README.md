# gh-ql-dist

Build a [Quicklisp](https://www.quicklisp.org/) dist from a list of git repos, automatically, with GitHub Actions.

Edit `projects.txt`, push, and the dist regenerates. Tarballs go to GitHub Releases and the dist metadata to GitHub Pages.

```lisp
(ql-dist:install-dist "https://<owner>.github.io/<dist-repo>/dist/<name>.txt")
```

## Use it

Create a repo from [ql-dist-template](https://github.com/takeiteasy/ql-dist-template) and follow [docs/setup.md](docs/setup.md).

| Page | Covers |
|---|---|
| [docs/setup.md](docs/setup.md) | One-time setup |
| [docs/manifest.md](docs/manifest.md) | `projects.txt` format |
| [docs/triggers.md](docs/triggers.md) | Push, per-repo tag, nightly polling |
| [docs/development.md](docs/development.md) | The generator, tests |

## License

MIT
