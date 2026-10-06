# Setup

Three steps: create the repo, enable Pages, list projects.

## 1. Create the dist repo

Use [ql-dist-template](https://github.com/takeiteasy/ql-dist-template) ("Use this template"), or:

```sh
gh repo create me/ql-dist --template takeiteasy/ql-dist-template --public
```

## 2. Enable Pages

Settings → Pages → Source: **GitHub Actions**. Or:

```sh
gh api repos/me/ql-dist/pages -X POST -f build_type=workflow
```

## 3. List projects and push

Edit `projects.txt` ([format](manifest.md)), set `name:` in `.github/workflows/dist.yml`, push. The run creates one release per project version, a `dist` branch holding the metadata, and the Pages site.

Install with:

```lisp
(ql-dist:install-dist "https://me.github.io/ql-dist/dist/<name>.txt")
```

## Outputs

| What | Where |
|---|---|
| Tarballs | Release `<project>-<version>`, asset `<project>-<version>.tgz` |
| Metadata | `dist` branch, served by Pages under `/dist/` |
| Dist versions | `YYYY-MM-DD`, then `YYYY-MM-DD-2`, `-3` for further changes the same day |

## Private repos

A private dist repo can call this workflow once the tool repo allows it:

```sh
gh api -X PUT repos/takeiteasy/gh-ql-dist/actions/permissions/access -f access_level=user
```

Release downloads and Pages are not publicly fetchable until the dist repo is public.
