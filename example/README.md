# My Quicklisp dist

A [Quicklisp](https://www.quicklisp.org/) dist built by [gh-ql-dist](https://github.com/takeiteasy/gh-ql-dist).

```lisp
(ql-dist:install-dist "https://<owner>.github.io/<repo>/dist/<repo>.txt")
```

Stock Quicklisp only fetches `http://`, so users need [ql-https](https://github.com/rudolfochrist/ql-https).

The dist is named after the repo; set the repo variable `QL_DIST_NAME` to change it.
