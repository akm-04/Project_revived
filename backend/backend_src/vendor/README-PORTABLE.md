# Optional portable vendor prefixes

The backend does not require opaque vendored server binaries. For development,
`gxb-dev.sh` can nevertheless use user-supplied extracted toolchains so the
workspace can run without installing project files or services into root-owned
locations.

Recognized layouts:

```text
vendor/python/bin/python3
vendor/postgresql/bin/{postgres,initdb,pg_ctl,psql,createdb,pg_isready}
vendor/nginx/sbin/nginx
vendor/openresty/bin/openresty
vendor/openresty/nginx/sbin/nginx
```

You can place extracted binary distributions at those prefixes, or point to
another location with `GXB_PYTHON`, `GXB_PG_BINDIR`, or `GXB_PROXY_BIN`.

Do not assume an arbitrary OpenResty/PostgreSQL source `.tar.gz` is directly
runnable: source archives still require compilation and their normal build
dependencies. Prefer distro packages for the binaries when convenient while
keeping the actual GXB database/config/runtime state in the workspace.
