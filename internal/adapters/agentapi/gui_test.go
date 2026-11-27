package agentapi

import (
	"encoding/json"
	"io/fs"
	"net/http"
	"net/http/httptest"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

// guiScriptFiles returns the GUI's own ES modules (the vendored Tabler bundle
// is not one of them).
func guiScriptFiles(t *testing.T) map[string]string {
	t.Helper()
	scripts := map[string]string{}
	err := fs.WalkDir(guiAssets, "guiassets", func(name string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() || strings.Contains(name, "/vendor/") || path.Ext(name) != ".js" {
			return nil
		}
		contents, readErr := guiAssets.ReadFile(name)
		if readErr != nil {
			return readErr
		}
		scripts[name] = string(contents)
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(scripts) == 0 {
		t.Fatal("no GUI scripts are embedded")
	}
	return scripts
}

func TestGUIIndexAndAssetsCarryTheStrictPolicy(t *testing.T) {
	handler, _, _ := newForwardingHandler(t)
	cases := map[string]string{
		"/":            "text/html; charset=utf-8",
		"/gui/app.css": "text/css; charset=utf-8",
		"/gui/app.js":  "text/javascript; charset=utf-8",
	}
	for targetPath, contentType := range cases {
		recorder := serveAgent(handler, http.MethodGet, targetPath, "", "")
		if recorder.Code != http.StatusOK {
			t.Fatalf("%s: status = %d, body = %s", targetPath, recorder.Code, recorder.Body)
		}
		if recorder.Header().Get("Content-Security-Policy") != contentSecurityPolicy {
			t.Fatalf("%s: policy = %q", targetPath, recorder.Header().Get("Content-Security-Policy"))
		}
		if recorder.Header().Get("X-Content-Type-Options") != "nosniff" {
			t.Fatalf("%s: missing nosniff", targetPath)
		}
		if recorder.Header().Get("Content-Type") != contentType {
			t.Fatalf("%s: content type = %q", targetPath, recorder.Header().Get("Content-Type"))
		}
		if recorder.Body.Len() == 0 {
			t.Fatalf("%s: empty body", targetPath)
		}
	}
	index := serveAgent(handler, http.MethodGet, "/", "", "")
	for _, reference := range []string{`/gui/app.css`, `/gui/app.js`} {
		if !strings.Contains(index.Body.String(), reference) {
			t.Fatalf("index does not reference %s", reference)
		}
	}
}

func TestGUIIndexRefusesUnknownAndNonGet(t *testing.T) {
	handler, _, session := newForwardingHandler(t)
	for _, target := range []string{
		"/gui/missing.js",
		"/gui/../app.js",
		"/gui/%2e%2e/app.js",
		"/gui/..%2Fapp.js",
		"/gui/vendor/../../app.js",
		"/gui/README.md",
	} {
		if recorder := serveAgent(handler, http.MethodGet, target, session, ""); recorder.Code != http.StatusNotFound {
			t.Fatalf("%s: status = %d", target, recorder.Code)
		}
	}
	if recorder := serveAgent(handler, http.MethodPost, "/", session, `{}`); recorder.Code != http.StatusNotFound {
		t.Fatalf("POST index: %d", recorder.Code)
	}
}

func newGUIResHandler(t *testing.T) (Handler, string) {
	t.Helper()
	handler, _, session := newForwardingHandler(t)
	otaRoot := t.TempDir()
	resRoot := t.TempDir()
	settings, err := json.Marshal(map[string]any{"lazy_fetch": "auto", "res_path": resRoot})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(otaRoot, "settings.json"), settings, 0o600); err != nil {
		t.Fatal(err)
	}
	handler.OTARoot = otaRoot
	return handler, session
}

func writePicture(t *testing.T, directory, relative string) string {
	t.Helper()
	path := filepath.Join(directory, filepath.FromSlash(relative))
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte{0x89, 'P', 'N', 'G'}, 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestGUIResServesAnImageForASession(t *testing.T) {
	handler, session := newGUIResHandler(t)
	roots, err := handler.resRoots()
	if err != nil {
		t.Fatal(err)
	}
	writePicture(t, roots[0], "res/web/images/item.png")

	if recorder := serveAgent(handler, http.MethodGet, "/agent/v1/res/res/web/images/item.png", "", ""); recorder.Code != http.StatusUnauthorized {
		t.Fatalf("without a session: %d %s", recorder.Code, recorder.Body)
	}
	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/res/res/web/images/item.png", session, "")
	if recorder.Code != http.StatusOK {
		t.Fatalf("with a session: %d %s", recorder.Code, recorder.Body)
	}
	if recorder.Header().Get("Content-Type") != "image/png" {
		t.Fatalf("content type = %q", recorder.Header().Get("Content-Type"))
	}
	if recorder.Header().Get("Content-Security-Policy") != contentSecurityPolicy {
		t.Fatalf("res route has no strict policy")
	}
	if recorder.Body.String() != string([]byte{0x89, 'P', 'N', 'G'}) {
		t.Fatalf("body = %q", recorder.Body)
	}
}

func TestGUIResRefusesEscapesAndNonImages(t *testing.T) {
	handler, session := newGUIResHandler(t)
	roots, err := handler.resRoots()
	if err != nil {
		t.Fatal(err)
	}
	resRoot := roots[0]
	writePicture(t, resRoot, "res/good.png")
	writePicture(t, resRoot, "res/notes.txt")
	outside := t.TempDir()
	outsidePicture := writePicture(t, outside, "outside.png")
	if err := os.Symlink(outsidePicture, filepath.Join(resRoot, "res", "escaped.png")); err != nil {
		t.Fatal(err)
	}

	cases := []struct {
		name   string
		target string
		status int
	}{
		{name: "parent traversal", target: "/agent/v1/res/../secret.png", status: http.StatusBadRequest},
		{name: "encoded traversal", target: "/agent/v1/res/%2e%2e/secret.png", status: http.StatusBadRequest},
		{name: "encoded slash traversal", target: "/agent/v1/res/..%2Fsecret.png", status: http.StatusBadRequest},
		{name: "backslash traversal", target: "/agent/v1/res/..%5Csecret.png", status: http.StatusBadRequest},
		{name: "absolute", target: "/agent/v1/res//etc/passwd", status: http.StatusBadRequest},
		{name: "symlink out", target: "/agent/v1/res/res/escaped.png", status: http.StatusNotFound},
		{name: "missing", target: "/agent/v1/res/res/missing.png", status: http.StatusNotFound},
		{name: "not an image", target: "/agent/v1/res/res/notes.txt", status: http.StatusBadRequest},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			recorder := serveAgent(handler, http.MethodGet, testCase.target, session, "")
			if recorder.Code != testCase.status {
				t.Fatalf("%s: status = %d, body = %s", testCase.target, recorder.Code, recorder.Body)
			}
			if strings.Contains(recorder.Body.String(), "outside") {
				t.Fatalf("%s leaked an outside file", testCase.target)
			}
		})
	}
}

func newGUIResHandlerWithApk(t *testing.T) (Handler, string, string, string) {
	t.Helper()
	handler, _, session := newForwardingHandler(t)
	otaRoot := t.TempDir()
	resRoot := t.TempDir()
	apkRoot := t.TempDir()
	settings, err := json.Marshal(map[string]any{"lazy_fetch": "auto", "res_path": resRoot, "apk_res_path": apkRoot})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(otaRoot, "settings.json"), settings, 0o600); err != nil {
		t.Fatal(err)
	}
	handler.OTARoot = otaRoot
	return handler, session, resRoot, apkRoot
}

// TestGUIResFallsBackToApkResPath proves the second root serves icons the OTA
// res tree does not carry, res_path wins when both have the path, and the
// symlink escape rule covers the second root too.
func TestGUIResFallsBackToApkResPath(t *testing.T) {
	handler, session, resRoot, apkRoot := newGUIResHandlerWithApk(t)
	writePicture(t, apkRoot, "res/icons/from_apk.png")
	if err := os.MkdirAll(filepath.Join(resRoot, "res", "icons"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(resRoot, "res", "icons", "both.png"), []byte("res-path"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(apkRoot, "res", "icons", "both.png"), []byte("apk-path"), 0o600); err != nil {
		t.Fatal(err)
	}
	outside := writePicture(t, t.TempDir(), "outside.png")
	if err := os.Symlink(outside, filepath.Join(apkRoot, "res", "icons", "escaped.png")); err != nil {
		t.Fatal(err)
	}

	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/res/res/icons/from_apk.png", session, "")
	if recorder.Code != http.StatusOK {
		t.Fatalf("apk root fallback: %d %s", recorder.Code, recorder.Body)
	}
	recorder = serveAgent(handler, http.MethodGet, "/agent/v1/res/res/icons/both.png", session, "")
	if recorder.Code != http.StatusOK || recorder.Body.String() != "res-path" {
		t.Fatalf("res_path must win: %d %q", recorder.Code, recorder.Body)
	}
	if recorder = serveAgent(handler, http.MethodGet, "/agent/v1/res/res/icons/escaped.png", session, ""); recorder.Code != http.StatusNotFound {
		t.Fatalf("apk root symlink out: %d", recorder.Code)
	}
}

// TestGUIResServesTheWritableWebAlias proves a lazily downloaded file under
// res/web/<rest> is served for the catalogue path <rest>, the plain file wins
// when both exist, and the escape guard covers the alias too (G33).
func TestGUIResServesTheWritableWebAlias(t *testing.T) {
	handler, session := newGUIResHandler(t)
	roots, err := handler.resRoots()
	if err != nil {
		t.Fatal(err)
	}
	resRoot := roots[0]
	writePicture(t, resRoot, "web/images/icon/item.png")
	if err := os.MkdirAll(filepath.Join(resRoot, "images", "icon"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(resRoot, "web", "images", "icon"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(resRoot, "images", "icon", "plain.png"), []byte("plain"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(resRoot, "web", "images", "icon", "plain.png"), []byte("alias"), 0o600); err != nil {
		t.Fatal(err)
	}
	outside := writePicture(t, t.TempDir(), "outside.png")
	if err := os.Symlink(outside, filepath.Join(resRoot, "web", "images", "icon", "escaped.png")); err != nil {
		t.Fatal(err)
	}

	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/res/images/icon/item.png", session, "")
	if recorder.Code != http.StatusOK || recorder.Body.String() != string([]byte{0x89, 'P', 'N', 'G'}) {
		t.Fatalf("web alias: %d %q", recorder.Code, recorder.Body)
	}
	recorder = serveAgent(handler, http.MethodGet, "/agent/v1/res/images/icon/plain.png", session, "")
	if recorder.Code != http.StatusOK || recorder.Body.String() != "plain" {
		t.Fatalf("plain path must win: %d %q", recorder.Code, recorder.Body)
	}
	recorder = serveAgent(handler, http.MethodGet, "/agent/v1/res/images/icon/escaped.png", session, "")
	if recorder.Code != http.StatusNotFound {
		t.Fatalf("web alias symlink out: %d", recorder.Code)
	}
}

func TestGUIResUnconfiguredResPathIsNotFound(t *testing.T) {
	handler, session := newGUIResHandler(t)
	handler.OTARoot = t.TempDir()
	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/res/res/good.png", session, "")
	if recorder.Code != http.StatusNotFound {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
}

func TestSameOriginBrowserRequestIsAllowed(t *testing.T) {
	handler, _, _ := newForwardingHandler(t)
	request := httptest.NewRequest(http.MethodPost, "/agent/v1/login", strings.NewReader(`{"password":"test password"}`))
	request.Host = handler.Listen
	request.RemoteAddr = "127.0.0.1:5000"
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("Origin", "http://"+handler.Listen)
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusOK {
		t.Fatalf("same-origin login: %d %s", recorder.Code, recorder.Body)
	}
	if !strings.Contains(recorder.Body.String(), `"token"`) {
		t.Fatalf("login body = %s", recorder.Body)
	}
}

func TestGUIIndexHasTheAccountMenuPasswordModalAndLogout(t *testing.T) {
	contents, err := guiAssets.ReadFile("guiassets/index.html")
	if err != nil {
		t.Fatal(err)
	}
	index := string(contents)
	for _, identifier := range []string{
		`id="account-menu"`,
		`id="account-button"`,
		`id="change-password-button"`,
		`id="logout-button"`,
		`id="password-modal"`,
		`id="password-form"`,
		`id="current-password"`,
		`id="new-password"`,
		`id="repeat-password"`,
	} {
		if !strings.Contains(index, identifier) {
			t.Fatalf("index.html lacks %s", identifier)
		}
	}
}

func TestEmbeddedGUIBuildsEveryModuleCommandAndRead(t *testing.T) {
	scripts := guiScriptFiles(t)
	fragments := []string{
		"for (const module of modules)",
		"for (const command of commands)",
		"for (const read of reads)",
		"for (const field of command.fields || [])",
		"for (const field of read.fields || [])",
		"field.required",
		"field.enum",
		"field.minimum",
		"field.maximum",
		"command.class === \"maintenance\"",
	}
	for _, fragment := range fragments {
		found := false
		for _, script := range scripts {
			if strings.Contains(script, fragment) {
				found = true
				break
			}
		}
		if !found {
			t.Fatalf("the GUI no longer derives its forms from the registry: missing %q", fragment)
		}
	}
}

func TestEmbeddedGUIRefersOnlyToAgentEndpoints(t *testing.T) {
	scripts := guiScriptFiles(t)
	requestPattern := regexp.MustCompile(`(?:fetch|request)\(\s*"([^"]*)"`)
	namedEndpoint := false
	for name, script := range scripts {
		for _, match := range requestPattern.FindAllStringSubmatch(script, -1) {
			namedEndpoint = true
			if !strings.HasPrefix(match[1], "/agent/v1/") {
				t.Fatalf("%s calls %q, which is not an agent endpoint", name, match[1])
			}
		}
	}
	if !namedEndpoint {
		t.Fatal("the GUI scripts name no agent endpoint")
	}
	index, err := guiAssets.ReadFile("guiassets/index.html")
	if err != nil {
		t.Fatal(err)
	}
	// The inline SVG namespace is a name, not a fetched resource (G37).
	const svgNamespace = "http://www.w3.org/2000/svg"
	for name, script := range scripts {
		script = strings.ReplaceAll(script, svgNamespace, "")
		for _, forbidden := range []string{"http://", "https://", "//cdn."} {
			if strings.Contains(script, forbidden) {
				t.Fatalf("%s references an external resource: %s", name, forbidden)
			}
		}
	}
	for _, forbidden := range []string{"http://", "https://", "//cdn."} {
		if strings.Contains(string(index), forbidden) {
			t.Fatalf("the GUI page references an external resource: %s", forbidden)
		}
	}
}

// TestGUIVendoredAssetsAreEmbeddedAndServed proves every vendored stylesheet and
// script is compiled in, reachable at its /gui/ path and carries the strict
// policy. A vendored file may be referenced by the page or by a page module
// that loads it on demand.
func TestGUIVendoredAssetsAreEmbeddedAndServed(t *testing.T) {
	handler, _, _ := newForwardingHandler(t)
	index, err := guiAssets.ReadFile("guiassets/index.html")
	if err != nil {
		t.Fatal(err)
	}
	references := string(index)
	for _, script := range guiScriptFiles(t) {
		references += script
	}
	served := 0
	err = fs.WalkDir(guiAssets, "guiassets/vendor", func(name string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			return nil
		}
		contentType, serveable := guiContentTypes[strings.ToLower(path.Ext(name))]
		if !serveable {
			return nil
		}
		targetPath := "/gui/" + strings.TrimPrefix(name, guiAssetsRoot)
		if !strings.Contains(references, targetPath) {
			t.Fatalf("no GUI page or module references the vendored file %s", targetPath)
		}
		recorder := serveAgent(handler, http.MethodGet, targetPath, "", "")
		if recorder.Code != http.StatusOK {
			t.Fatalf("%s: status = %d", targetPath, recorder.Code)
		}
		if recorder.Header().Get("Content-Security-Policy") != contentSecurityPolicy {
			t.Fatalf("%s: missing the strict policy", targetPath)
		}
		if recorder.Header().Get("Content-Type") != contentType {
			t.Fatalf("%s: content type = %q", targetPath, recorder.Header().Get("Content-Type"))
		}
		if recorder.Body.Len() == 0 {
			t.Fatalf("%s: empty body", targetPath)
		}
		served++
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if served < 2 {
		t.Fatalf("expected the vendored Tabler css and js, served %d files", served)
	}
}

// TestGUIComponentsAreEmbeddedAndServed proves the shared components and their
// test page are compiled in, reachable under /gui/ and carry the strict policy.
func TestGUIComponentsAreEmbeddedAndServed(t *testing.T) {
	handler, _, _ := newForwardingHandler(t)
	required := []string{
		"guiassets/components.html",
		"guiassets/components/confirm_action.js",
		"guiassets/components/demo.js",
		"guiassets/components/duration_picker.js",
		"guiassets/components/modal.js",
		"guiassets/components/path_picker.js",
		"guiassets/components/player_picker.js",
		"guiassets/components/resource_picker.js",
		"guiassets/components/server_picker.js",
	}
	for _, name := range required {
		if _, err := guiAssets.ReadFile(name); err != nil {
			t.Fatalf("the GUI no longer embeds %s", name)
		}
	}
	served := 0
	err := fs.WalkDir(guiAssets, "guiassets/components", func(name string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() {
			return nil
		}
		contentType, serveable := guiContentTypes[strings.ToLower(path.Ext(name))]
		if !serveable {
			t.Fatalf("%s has no serveable content type", name)
		}
		targetPath := "/gui/" + strings.TrimPrefix(name, guiAssetsRoot)
		recorder := serveAgent(handler, http.MethodGet, targetPath, "", "")
		if recorder.Code != http.StatusOK {
			t.Fatalf("%s: status = %d", targetPath, recorder.Code)
		}
		if recorder.Header().Get("Content-Security-Policy") != contentSecurityPolicy {
			t.Fatalf("%s: missing the strict policy", targetPath)
		}
		if recorder.Header().Get("Content-Type") != contentType {
			t.Fatalf("%s: content type = %q", targetPath, recorder.Header().Get("Content-Type"))
		}
		if recorder.Body.Len() == 0 {
			t.Fatalf("%s: empty body", targetPath)
		}
		served++
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if served < len(required)-1 {
		t.Fatalf("served %d component files, want at least %d", served, len(required)-1)
	}

	recorder := serveAgent(handler, http.MethodGet, "/gui/components.html", "", "")
	if recorder.Code != http.StatusOK {
		t.Fatalf("components page: status = %d", recorder.Code)
	}
	if recorder.Header().Get("Content-Security-Policy") != contentSecurityPolicy {
		t.Fatalf("components page: missing the strict policy")
	}
	if recorder.Header().Get("Content-Type") != "text/html; charset=utf-8" {
		t.Fatalf("components page: content type = %q", recorder.Header().Get("Content-Type"))
	}
	page := recorder.Body.String()
	for _, reference := range []string{"/gui/app.css", "/gui/components/demo.js", "/gui/vendor/tabler-1.7.3/tabler.min.css"} {
		if !strings.Contains(page, reference) {
			t.Fatalf("components page does not reference %s", reference)
		}
	}
	for _, identifier := range []string{
		`id="components-view"`, `id="login-form"`,
		`id="open-server-picker"`, `id="server-output"`,
		`id="open-player-picker"`, `id="player-output"`,
		`id="open-resource-picker"`, `id="resource-output"`,
		`id="open-duration-picker"`, `id="duration-output"`,
		`id="open-confirm-action"`, `id="confirm-output"`,
	} {
		if !strings.Contains(page, identifier) {
			t.Fatalf("components page lacks %s", identifier)
		}
	}
	if len(regexp.MustCompile(`<script[^>]*>`).FindAllString(page, -1)) == 0 {
		t.Fatal("the components page carries no script")
	}
	for _, tag := range regexp.MustCompile(`<script[^>]*>`).FindAllString(page, -1) {
		if !strings.Contains(tag, "src=") {
			t.Fatalf("the components page carries an inline script tag: %s", tag)
		}
	}
}

// TestGUIPagesAreEmbeddedAndServed proves every page module is compiled in,
// reachable under /gui/pages/ with its content type and the strict policy, and
// exports the renderPage entry the shell loads.
func TestGUIPagesAreEmbeddedAndServed(t *testing.T) {
	handler, _, _ := newForwardingHandler(t)
	required := []string{
		"guiassets/pages/backups.js",
		"guiassets/pages/dashboard.js",
		"guiassets/pages/events.js",
		"guiassets/pages/gm.js",
		"guiassets/pages/logs.js",
		"guiassets/pages/mail.js",
		"guiassets/pages/notices.js",
		"guiassets/pages/ota.js",
		"guiassets/pages/players.js",
		"guiassets/pages/rewards.js",
		"guiassets/pages/server.js",
		"guiassets/pages/settings.js",
	}
	for _, name := range required {
		contents, err := guiAssets.ReadFile(name)
		if err != nil {
			t.Fatalf("the GUI no longer embeds %s", name)
		}
		if !strings.Contains(string(contents), "export function renderPage(container") {
			t.Fatalf("%s does not export renderPage(container, ...)", name)
		}
	}
	served := 0
	err := fs.WalkDir(guiAssets, "guiassets/pages", func(name string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() {
			return nil
		}
		contentType, serveable := guiContentTypes[strings.ToLower(path.Ext(name))]
		if !serveable {
			t.Fatalf("%s has no serveable content type", name)
		}
		targetPath := "/gui/" + strings.TrimPrefix(name, guiAssetsRoot)
		recorder := serveAgent(handler, http.MethodGet, targetPath, "", "")
		if recorder.Code != http.StatusOK {
			t.Fatalf("%s: status = %d", targetPath, recorder.Code)
		}
		if recorder.Header().Get("Content-Security-Policy") != contentSecurityPolicy {
			t.Fatalf("%s: missing the strict policy", targetPath)
		}
		if recorder.Header().Get("Content-Type") != contentType {
			t.Fatalf("%s: content type = %q", targetPath, recorder.Header().Get("Content-Type"))
		}
		if recorder.Body.Len() == 0 {
			t.Fatalf("%s: empty body", targetPath)
		}
		served++
		return nil
	})
	if err != nil {
		t.Fatalf("walk the pages: %v", err)
	}
	if served < len(required) {
		t.Fatalf("served %d page files, want at least %d", served, len(required))
	}
}

// TestGUIOTAPublishAndBackupControlsKeepTheirFix proves the four owner-reported
// operator glitches stay wired: the publish hint and active style, the page
// reload after a lane action, the exclusive restore/select controls, and the
// streaming restore request.
func TestGUIOTAPublishAndBackupControlsKeepTheirFix(t *testing.T) {
	ota, err := guiAssets.ReadFile("guiassets/pages/ota.js")
	if err != nil {
		t.Fatal(err)
	}
	for _, fragment := range []string{"ota-publish-hint-", "btn-warning", "refreshPublish", "reloadPage"} {
		if !strings.Contains(string(ota), fragment) {
			t.Fatalf("ota.js lost %q", fragment)
		}
	}
	backups, err := guiAssets.ReadFile("guiassets/pages/backups.js")
	if err != nil {
		t.Fatal(err)
	}
	for _, fragment := range []string{"stream: true", "input[type=checkbox]", "input[type=radio]"} {
		if !strings.Contains(string(backups), fragment) {
			t.Fatalf("backups.js lost %q", fragment)
		}
	}
	styles, err := guiAssets.ReadFile("guiassets/app.css")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(styles), "cursor: not-allowed") {
		t.Fatal("app.css lost the disabled-button cursor")
	}
}

// TestGUIIndexReferencesOnlySameOriginAssets keeps the page free of a CDN and
// of inline script, so the CSP stays self-only.
func TestGUIIndexReferencesOnlySameOriginAssets(t *testing.T) {
	contents, err := guiAssets.ReadFile("guiassets/index.html")
	if err != nil {
		t.Fatal(err)
	}
	index := string(contents)
	references := regexp.MustCompile(`(?:src|href)="([^"]*)"`).FindAllStringSubmatch(index, -1)
	if len(references) == 0 {
		t.Fatal("the page references no scripts or stylesheets")
	}
	for _, reference := range references {
		if !strings.HasPrefix(reference[1], "/") || strings.HasPrefix(reference[1], "//") {
			t.Fatalf("the page references %q outside the agent origin", reference[1])
		}
	}
	for _, tag := range regexp.MustCompile(`<script[^>]*>`).FindAllString(index, -1) {
		if !strings.Contains(tag, "src=") {
			t.Fatalf("the page carries an inline script tag: %s", tag)
		}
	}
	if strings.Contains(scriptDirective(contentSecurityPolicy), "unsafe-inline") {
		t.Fatal("the GUI policy allows inline script")
	}
	if !strings.Contains(contentSecurityPolicy, "style-src 'self' 'unsafe-inline'") {
		t.Fatalf("the GUI policy lost the xterm style exception: %s", contentSecurityPolicy)
	}
	if !strings.Contains(contentSecurityPolicy, "script-src 'self'") {
		t.Fatalf("the GUI policy is not self-only for scripts: %s", contentSecurityPolicy)
	}
}

// scriptDirective returns the script-src directive of a policy string.
func scriptDirective(policy string) string {
	start := strings.Index(policy, "script-src")
	if start < 0 {
		return ""
	}
	directive := policy[start:]
	if end := strings.Index(directive, ";"); end >= 0 {
		directive = directive[:end]
	}
	return directive
}
