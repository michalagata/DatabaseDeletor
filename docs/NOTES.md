## Why this layout?
Heavy, rarely changing layers go **below** frequently changing ones to maximize cache hits.
- `base` — OS and core tools change seldom.
- `lang` — SDKs/runtimes pin major versions; change less often than app code.
- `deps` — resolved package sets (lockfiles) change on dependency bumps.
- `build` — changes with source code.
- `runtime` — thin, secure final image.

## Header contract
Each Dockerfile declares:
```
# IMAGE_NAME=...
# IMAGE_TAG=...
# IMAGE_DEPS=...   # optional explicit ordering
```
The build script uses these and `FROM` lines to derive a DAG.

## Security & size
- Add `hadolint`, `trivy`, and SBOM (`syft`) to your CI for policy gates.
- Strip build caches; keep runtime minimal and non-root.
