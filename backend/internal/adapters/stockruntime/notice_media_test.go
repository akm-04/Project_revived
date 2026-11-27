package stockruntime

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
)

func writeNoticePicture(t *testing.T, root, name string) {
	t.Helper()
	if err := os.WriteFile(filepath.Join(root, name), []byte{0x89, 'P', 'N', 'G'}, 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestNoticeMediaServesAStoredName(t *testing.T) {
	root := t.TempDir()
	const name = "0123456789abcdef.png"
	writeNoticePicture(t, root, name)
	handler := NoticeMediaGET{Root: root}
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/media/"+name, nil))
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	if recorder.Header().Get("Content-Type") != "image/png" {
		t.Fatalf("content type = %q", recorder.Header().Get("Content-Type"))
	}
	if recorder.Header().Get("X-Content-Type-Options") != "nosniff" {
		t.Fatalf("missing nosniff")
	}
	if recorder.Header().Get("Cache-Control") != "public, max-age=31536000, immutable" {
		t.Fatalf("cache control = %q", recorder.Header().Get("Cache-Control"))
	}
}

func TestNoticeMediaRefusesEverythingElse(t *testing.T) {
	root := t.TempDir()
	writeNoticePicture(t, root, "0123456789abcdef.png")
	if err := os.Mkdir(filepath.Join(root, "sub"), 0o755); err != nil {
		t.Fatal(err)
	}
	handler := NoticeMediaGET{Root: root}
	cases := []struct {
		method string
		target string
		status int
	}{
		{http.MethodGet, "/media/../0123456789abcdef.png", http.StatusNotFound},
		{http.MethodGet, "/media/%2e%2e/0123456789abcdef.png", http.StatusNotFound},
		{http.MethodGet, "/media/0123456789abcdef.jpeg", http.StatusNotFound},
		{http.MethodGet, "/media/0123456789abcdef.png/extra", http.StatusNotFound},
		{http.MethodGet, "/media/0123456789abcdef.png?download=1", http.StatusNotFound},
		{http.MethodGet, "/media/sub", http.StatusNotFound},
		{http.MethodGet, "/media/", http.StatusNotFound},
		{http.MethodGet, "/media/0123456789ABCDEF.png", http.StatusNotFound},
		{http.MethodPost, "/media/0123456789abcdef.png", http.StatusMethodNotAllowed},
	}
	for _, testCase := range cases {
		recorder := httptest.NewRecorder()
		handler.ServeHTTP(recorder, httptest.NewRequest(testCase.method, testCase.target, nil))
		if recorder.Code != testCase.status {
			t.Fatalf("%s %s: status = %d, want %d", testCase.method, testCase.target, recorder.Code, testCase.status)
		}
	}
}

func TestNoticeMediaWithoutRootIsNotFound(t *testing.T) {
	recorder := httptest.NewRecorder()
	NoticeMediaGET{}.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/media/0123456789abcdef.png", nil))
	if recorder.Code != http.StatusNotFound {
		t.Fatalf("status = %d", recorder.Code)
	}
}
