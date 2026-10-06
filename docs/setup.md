# Setup

Three steps: create the repo, enable Pages, list projects.

## 1. Create the dist repo

Copy [`example/`](../example) into a new repo:

```sh
git clone --depth 1 https://github.com/takeiteasy/gh-ql-dist
gh repo create me/ql-dist --public --clone
cp -R gh-ql-dist/example/. ql-dist/
```

## 2. Enable Pages

Settings → Pages → Source: **GitHub Actions**. Or:

```sh
gh api repos/me/ql-dist/pages -X POST -f build_type=workflow
```

## 3. List projects and push

Edit `projects.txt` ([format](manifest.md)), then commit and push. The run creates one release per project version, a `dist` branch holding the metadata, and the Pages site.

Install with:

```lisp
(ql-dist:install-dist "https://me.github.io/ql-dist/dist/<name>.txt")
```

Stock Quicklisp only fetches `http://`, and GitHub redirects to HTTPS, so users need [ql-https](https://github.com/rudolfochrist/ql-https).[^1]

[^1]: `content-sha1` in `releases.txt` is the sha1 of the archive's file contents in path order, which ql-https and recent clients verify.

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
