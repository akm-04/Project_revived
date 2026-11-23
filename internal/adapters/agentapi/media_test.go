package agentapi

import (
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/application/operatormedia"
)

func agentMediaHandler(t *testing.T) (Handler, string) {
	t.Helper()
	handler, _, session := newForwardingHandler(t)
	handler.Media = &operatormedia.Service{MediaPath: t.TempDir(), PublicEngineURL: "https://game.example/engine"}
	return handler, session
}

func testPNG() []byte {
	return []byte{0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 13, 'I', 'H', 'D', 'R', 0, 0, 0, 2, 0, 0, 0, 3}
}

func uploadBody(t *testing.T, data []byte) string {
	t.Helper()
	encoded, err := json.Marshal(map[string]string{"data_base64": base64.StdEncoding.EncodeToString(data)})
	if err != nil {
		t.Fatal(err)
	}
	return string(encoded)
}

func TestMediaUploadListAndPreview(t *testing.T) {
	handler, session := agentMediaHandler(t)
	recorder := serveAgent(handler, http.MethodPost, mediaUploadPath, session, uploadBody(t, testPNG()))
	if recorder.Code != http.StatusOK {
		t.Fatalf("upload: %d %s", recorder.Code, recorder.Body)
	}
	var stored operatormedia.Stored
	if err := json.Unmarshal(recorder.Body.Bytes(), &stored); err != nil {
		t.Fatal(err)
	}
	if !strings.HasSuffix(stored.Name, ".png") || !strings.HasPrefix(stored.URL, "https://game.example/media/") {
		t.Fatalf("stored = %+v", stored)
	}

	recorder = serveAgent(handler, http.MethodGet, mediaListPath, session, "")
	if recorder.Code != http.StatusOK {
		t.Fatalf("list: %d %s", recorder.Code, recorder.Body)
	}

	recorder = serveAgent(handler, http.MethodGet, mediaFilePrefix+stored.Name, session, "")
	if recorder.Code != http.StatusOK || recorder.Header().Get("Content-Type") != "image/png" {
		t.Fatalf("preview: %d %q", recorder.Code, recorder.Header().Get("Content-Type"))
	}
}

func TestMediaUploadAcceptsADataURLAndRefusesNonPictures(t *testing.T) {
	handler, session := agentMediaHandler(t)
	dataURL, err := json.Marshal(map[string]string{"data_base64": "data:image/png;base64," + base64.StdEncoding.EncodeToString(testPNG())})
	if err != nil {
		t.Fatal(err)
	}
	if recorder := serveAgent(handler, http.MethodPost, mediaUploadPath, session, string(dataURL)); recorder.Code != http.StatusOK {
		t.Fatalf("data URL: %d %s", recorder.Code, recorder.Body)
	}
	refused := serveAgent(handler, http.MethodPost, mediaUploadPath, session, uploadBody(t, []byte("<html>")))
	if refused.Code != http.StatusConflict || !strings.Contains(refused.Body.String(), operatormedia.CodeTypeUnsupported) {
		t.Fatalf("non-picture: %d %s", refused.Code, refused.Body)
	}
}

func TestMediaImportRefusesALocalAddress(t *testing.T) {
	handler, session := agentMediaHandler(t)
	recorder := serveAgent(handler, http.MethodPost, mediaImportPath, session, `{"url":"http://127.0.0.1/p.png"}`)
	if recorder.Code != http.StatusConflict || !strings.Contains(recorder.Body.String(), operatormedia.CodeURLInvalid) {
		t.Fatalf("import: %d %s", recorder.Code, recorder.Body)
	}
}

func TestMediaRoutesRefuseBadNamesAndNoSession(t *testing.T) {
	handler, session := agentMediaHandler(t)
	for _, target := range []string{
		mediaFilePrefix + "../0123456789abcdef.png",
		mediaFilePrefix + "0123456789abcdef.png/extra",
		mediaFilePrefix + "not-a-name.png",
	} {
		if recorder := serveAgent(handler, http.MethodGet, target, session, ""); recorder.Code != http.StatusNotFound {
			t.Fatalf("%s: status = %d", target, recorder.Code)
		}
	}
	if recorder := serveAgent(handler, http.MethodGet, mediaListPath, "", ""); recorder.Code != http.StatusUnauthorized {
		t.Fatalf("without a session: %d", recorder.Code)
	}
}

func TestMediaRoutesWithoutAStoreAreUnavailable(t *testing.T) {
	handler, _, session := newForwardingHandler(t)
	if recorder := serveAgent(handler, http.MethodGet, mediaListPath, session, ""); recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("list: %d", recorder.Code)
	}
}
