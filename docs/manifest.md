# Manifest

`projects.txt` is the allow list: only listed projects are built or published.

```
# name       git-url                                  ref
cl-earcut    https://github.com/me/cl-earcut          tags
cl-nuklear   https://github.com/me/cl-nuklear         v0.2.0
cl-foo       https://github.com/me/cl-foo             main
```

## Refs

Only tags are built by default.

| ref | Version | Changes when |
|---|---|---|
| `tags` | Newest tag by version sort | A newer tag exists |
| a tag | The tag | The manifest is edited |
| a branch[^2] | First 7 characters of the head sha | The branch moves |
| a sha[^2] | First 7 characters | The manifest is edited |

## Releases

- A project version is built once. Its tarball, size and hashes never change[^1].
- A project's archive is `git archive` of the ref, rooted at `<project>-<version>/`.
- Systems come from `.asd` files at the top level and one directory down.

## Removing a project

Delete its line. The next dist omits it; its releases stay.

[^1]: Quicklisp clients verify the hashes in `releases.txt`, so a published tarball must never be rebuilt.
[^2]: Branch and sha refs fail unless the workflow call sets `allow-untagged: true` (`--allow-untagged` for the script).
