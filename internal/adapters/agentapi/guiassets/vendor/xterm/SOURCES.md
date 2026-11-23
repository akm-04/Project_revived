# Vendored terminal libraries (G42)

Both packages are copied unmodified from the npm registry tarballs. The agent
serves them from its own origin through the embedded GUI asset route
(`/gui/vendor/xterm/`); there is no CDN reference.

## @xterm/xterm 5.5.0

- Tarball: https://registry.npmjs.org/@xterm/xterm/-/xterm-5.5.0.tgz
- Registry `dist.integrity`: `sha512-hqJHYaQb5OptNunnyAnkHyM8aCjZ1MEIDTQu1iIbbTD/xops91NB5yq1ZK/dC2JDbVWtF23zUtl9JE2NqwT87A==`
- Verified tarball sha512: `sha512-hqJHYaQb5OptNunnyAnkHyM8aCjZ1MEIDTQu1iIbbTD/xops91NB5yq1ZK/dC2JDbVWtF23zUtl9JE2NqwT87A==`
- Copied: `package/lib/xterm.js` -> `xterm.js`, `package/css/xterm.css` -> `xterm.css`, `package/LICENSE` -> `LICENSE`

## @xterm/addon-fit 0.10.0

- Tarball: https://registry.npmjs.org/@xterm/addon-fit/-/addon-fit-0.10.0.tgz
- Registry `dist.integrity`: `sha512-UFYkDm4HUahf2lnEyHvio51TNGiLK66mqP2JoATy7hRZeXaGMRDr00JiSF7m63vR5WKATF605yEggJKsw0JpMQ==`
- Verified tarball sha512: `sha512-UFYkDm4HUahf2lnEyHvio51TNGiLK66mqP2JoATy7hRZeXaGMRDr00JiSF7m63vR5WKATF605yEggJKsw0JpMQ==`
- Copied: `package/lib/addon-fit.js` -> `addon-fit.js`, `package/LICENSE` -> `LICENSE.addon-fit`

Both licenses are MIT; `LICENSE` is the xterm.js notice and `LICENSE.addon-fit`
the addon notice.

The CSP in `gui.go` allows inline styles (`style-src 'self' 'unsafe-inline'`)
because xterm's default DOM renderer writes `<style>` rules and `style`
attributes at runtime. Scripts stay `script-src 'self'`.
