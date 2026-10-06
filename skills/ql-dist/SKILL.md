---
name: ql-dist
description: Use a dist repo built with gh-ql-dist (a Quicklisp dist generated from git tags by GitHub Actions). Use to release a new project version, add or remove a project, rotate the notify token, check or re-run a dist build, or debug a failed dist run or notify job.
---

# ql-dist

Tags in a project repo become releases in the dist repo. Tarballs live in the dist repo's GitHub Releases, metadata on its `dist` branch, served by Pages at `https://<owner>.github.io/<dist-repo>/dist/<name>.txt`. The tool is `takeiteasy/gh-ql-dist@v1`.

Placeholders below: `<owner>`, `<dist-repo>` (the repo made from `example/`), `<name>` (the dist name, the repo name unless `QL_DIST_NAME` is set), `<project>`. Ask the user for any value that is not obvious from the checkout.

| Thing | Where |
|---|---|
| Allow list | `projects.txt` in the dist repo: `name git-url ref` |
| Dist workflow | `<dist-repo>/.github/workflows/dist.yml` |
| Per-project notifier | `<project>/.github/workflows/ql-dist.yml`, secret `QL_DIST_TOKEN` |
| Triggers | `projects.txt` push, manual; project tag push needs repo variable `QL_DIST_DISPATCH=true`; nightly poll needs `QL_DIST_POLL=true` |

Only tags are built. Branch and commit refs fail unless the workflow call sets `allow-untagged: true`; do not enable it unless asked.

## Release a new version

1. Bump `:version` in the project's `.asd` (every `defsystem` that has one).
2. Commit, then tag `v<version>`, matching the `.asd`.
3. Push the branch and tag. Push every remote the user keeps in sync.
4. The tag push notifies the dist repo; confirm:

```sh
git tag v0.2.0 && git push origin <branch> v0.2.0
gh run list --repo <owner>/<dist-repo> --limit 3
gh release list --repo <owner>/<dist-repo> | grep <project>
```

The dist version is `YYYY-MM-DD`, then `YYYY-MM-DD-2`, `-3` for further changes the same day. A project version is built once; its tarball never changes.

## Add a project

1. The project needs a `.asd` at the top level or one directory down, a `:version`, and a repo name equal to the project name.
2. Tag it (`v<asd version>`) and push the tag.
3. For tag-triggered builds, add `.github/workflows/ql-dist.yml` to it:

```yaml
name: ql-dist
on:
  push:
    tags: ['*']
jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - uses: takeiteasy/gh-ql-dist/notify@v1
        with:
          repo: <owner>/<dist-repo>
          project: ${{ github.event.repository.name }}
          token: ${{ secrets.QL_DIST_TOKEN }}
```

4. Set the secret (see Token).
5. Add `<project> https://github.com/<owner>/<project> tags` to `projects.txt`, commit, push. The push runs the build.

## Remove or pin

- Remove: delete its line from `projects.txt` and push. Old releases stay.
- Pin: replace `tags` with a tag name such as `v0.1.0`. Pinned tags change only by editing the manifest.

## Token

The notifier uses a fine-grained PAT: resource owner `<owner>`, repository `<owner>/<dist-repo>` only, **Contents: Read and write**. It expires; set the secret on every notifier project again after rotating. Read the token from the user's token file by redirecting it to `gh`; never print or `cat` it. Ask for the file path.

```sh
for p in $(awk '!/^#/ && NF {print $1}' projects.txt); do
  gh secret set QL_DIST_TOKEN --repo <owner>/$p < "$TOKEN_FILE"
done
```

## Run or repair

| Need | Do |
|---|---|
| Rebuild now | `gh workflow run dist --repo <owner>/<dist-repo>` (a manual run also redeploys Pages) |
| Re-run a failed notify | `gh run rerun <id> --repo <owner>/<project>` |
| Watch a run | `gh run watch <id> --repo <owner>/<dist-repo>` |
| Wipe broken metadata | `git push origin --delete dist` in the dist repo, then run the workflow. Only if nobody installed the broken version |

## Failures

| Symptom | Cause |
|---|---|
| Notify: `HTTP 401` | Secret empty or token expired. Set it again from the file |
| Notify: `HTTP 403 ... not accessible by personal access token` | Token lacks Contents write on the dist repo, or the repo is not selected |
| Notify succeeds, no build | Project name not in `projects.txt`, or `QL_DIST_DISPATCH` is not `true` |
| `... is not a tag` | A branch or sha ref in the manifest; use a tag |
| `no .asd files` | The tag has no `.asd` at the top level or one directory down |
| Deploy step fails | Pages source must be GitHub Actions |
| `Unknown scheme` when installing | Stock Quicklisp needs [ql-https](https://github.com/rudolfochrist/ql-https) |
| `sha1 mismatch` when installing | `content-sha1` must be the sha1 of file contents in path order, not of the tar stream |

## Notes

- Archives come from `git archive`, so git submodules are not included.
- Delete an unwanted release with `gh release delete <project>-<version> --cleanup-tag --repo <owner>/<dist-repo>`.
