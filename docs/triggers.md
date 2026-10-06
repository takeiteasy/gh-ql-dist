# Triggers

| Trigger | Default | Runs when |
|---|---|---|
| Manifest push | on | `projects.txt` changes on `main` |
| Manual | on | Actions → dist → Run workflow |
| Per-repo tag | off | A project repo pushes a tag |
| Nightly poll | off | 03:17 UTC daily |

A run with nothing new publishes nothing, except a manual run, which redeploys Pages.

## Enable the nightly poll

```sh
gh variable set QL_DIST_POLL --body true
```

## Enable per-repo tags

1. Create a fine-grained token limited to the dist repo with **Contents: read and write**.
2. In the dist repo: `gh variable set QL_DIST_DISPATCH --body true`.
3. In each project repo, add the token as secret `QL_DIST_TOKEN` and this workflow:

```yaml
on:
  push:
    tags: ['*']
jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - uses: takeiteasy/gh-ql-dist/notify@v1
        with:
          repo: me/ql-dist
          project: cl-earcut
          token: ${{ secrets.QL_DIST_TOKEN }}
```

The notification carries only the project name. The dist repo ignores names not in `projects.txt` and resolves the tag itself, so the token can only trigger a rebuild of listed projects. Only projects with ref `tags` change from a notification; a pinned tag changes by editing the manifest.

## Limitations

- `tags` uses `sort -V`; pre-release tags such as `v1.0-rc1` sort after `v1.0`.
- Git submodules are not included in tarballs.
- Pages URLs are `https://<owner>.github.io/<repo>`; custom domains are not supported.
