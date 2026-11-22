# Vendored operator GUI assets

## Tabler 1.7.3

- Package: `@tabler/core` (npm)
- Version: `1.7.3`
- Published: 2026-10-29T12:52:57Z (at least two weeks old on the 2026-11-22 vendoring date)
- Source tarball: <https://registry.npmjs.org/@tabler/core/-/core-1.7.3.tgz>
- Registry integrity (sha512): `sha512-9PDS6U69svI987zIpd0AVLF4Gw9Uxfq1aypceVMNxye9Jp4QWYZEtzTL7z60L8qLyVQupHA+ug1AIA8gGAnYRA==`
- Licence: MIT (see `THIRD_PARTY_NOTICES` at the repository root)

Files copied from the tarball's `dist/` directory only:

| Served path | Tarball path | sha256 |
|---|---|---|
| `/gui/vendor/tabler-1.7.3/tabler.min.css` | `package/dist/css/tabler.min.css` | `00601301716c0bd97acbec6c2b6cb98f257d148063ef168aa06f902b1e7d9ea5` |
| `/gui/vendor/tabler-1.7.3/tabler.min.js` | `package/dist/js/tabler.min.js` | `4ff08167c8e5e3dbc05f424b9586c8e79778fc226950be19b74d6232e52c2f56` |

No CDN is used and no build step runs: the files are embedded in the
`gxb-operator` binary and served from the same origin as the GUI.
