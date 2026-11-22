package agentapi

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

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
	if recorder := serveAgent(handler, http.MethodGet, "/gui/missing.js", session, ""); recorder.Code != http.StatusNotFound {
		t.Fatalf("unknown asset: %d", recorder.Code)
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
	resRoot, err := handler.resRoot()
	if err != nil {
		t.Fatal(err)
	}
	writePicture(t, resRoot, "res/web/images/item.png")

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
	resRoot, err := handler.resRoot()
	if err != nil {
		t.Fatal(err)
	}
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

func TestEmbeddedGUIBuildsEveryModuleCommandAndRead(t *testing.T) {
	script, err := guiAssets.ReadFile("guiassets/app.js")
	if err != nil {
		t.Fatal(err)
	}
	fragments := []string{
		"for (const module of state.modules)",
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
		if !strings.Contains(string(script), fragment) {
			t.Fatalf("the GUI no longer derives its forms from the registry: missing %q", fragment)
		}
	}
}

func TestEmbeddedGUIRefersOnlyToAgentEndpoints(t *testing.T) {
	script, err := guiAssets.ReadFile("guiassets/app.js")
	if err != nil {
		t.Fatal(err)
	}
	requestPattern := regexp.MustCompile(`(?:fetch|agentRequest)\(\s*"([^"]*)"`)
	matches := requestPattern.FindAllStringSubmatch(string(script), -1)
	if len(matches) == 0 {
		t.Fatal("the GUI script names no agent endpoint")
	}
	for _, match := range matches {
		if !strings.HasPrefix(match[1], "/agent/v1/") {
			t.Fatalf("the GUI script calls %q, which is not an agent endpoint", match[1])
		}
	}
	for _, forbidden := range []string{"http://", "https://", "//cdn."} {
		if strings.Contains(string(script), forbidden) {
			t.Fatalf("the GUI script references an external resource: %s", forbidden)
		}
		index, readErr := guiAssets.ReadFile("guiassets/index.html")
		if readErr != nil {
			t.Fatal(readErr)
		}
		if strings.Contains(string(index), forbidden) {
			t.Fatalf("the GUI page references an external resource: %s", forbidden)
		}
	}
}
