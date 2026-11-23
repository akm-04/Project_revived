package agentapi

import (
	"encoding/json"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"testing"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

func fileListHandler(t *testing.T) (Handler, string, string) {
	t.Helper()
	handler, _, session := newForwardingHandler(t)
	root := t.TempDir()
	if err := os.Mkdir(filepath.Join(root, "folder"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "a.txt"), []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	handler.Files = &operatoragent.FileBrowser{Root: root}
	return handler, session, root
}

func TestFileListReadNeedsTheAgentSession(t *testing.T) {
	handler, _, _ := fileListHandler(t)
	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/reads/agent.fs.list", "", "")
	if recorder.Code != http.StatusUnauthorized || refusalCodeOf(t, recorder) != operatoragent.CodeUnauthorized {
		t.Fatalf("anonymous listing: %d %s", recorder.Code, recorder.Body)
	}
}

func TestFileListReadListsFoldersAndFilesFromTheAgentRoot(t *testing.T) {
	handler, session, root := fileListHandler(t)
	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/reads/agent.fs.list", session, "")
	if recorder.Code != http.StatusOK {
		t.Fatalf("listing: %d %s", recorder.Code, recorder.Body)
	}
	var listing operatoragent.FileListing
	if err := json.Unmarshal(recorder.Body.Bytes(), &listing); err != nil {
		t.Fatalf("body %s: %v", recorder.Body, err)
	}
	if listing.Path != root || len(listing.Entries) != 1 || listing.Entries[0].Name != "folder" || !listing.Entries[0].IsDir {
		t.Fatalf("folder listing = %+v", listing)
	}

	withFiles := serveAgent(handler, http.MethodGet, "/agent/v1/reads/agent.fs.list?path="+url.QueryEscape(root)+"&show_files=true", session, "")
	if withFiles.Code != http.StatusOK {
		t.Fatalf("file listing: %d %s", withFiles.Code, withFiles.Body)
	}
	if err := json.Unmarshal(withFiles.Body.Bytes(), &listing); err != nil {
		t.Fatalf("body %s: %v", withFiles.Body, err)
	}
	if len(listing.Entries) != 2 || listing.Entries[0].Name != "folder" || listing.Entries[1].Name != "a.txt" || listing.Entries[1].IsDir {
		t.Fatalf("file listing = %+v", listing.Entries)
	}
}

func TestFileListReadRefusesAMissingFolderWith409(t *testing.T) {
	handler, session, root := fileListHandler(t)
	missing := url.QueryEscape(filepath.Join(root, "missing"))
	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/reads/agent.fs.list?path="+missing, session, "")
	if recorder.Code != http.StatusConflict || refusalCodeOf(t, recorder) != operatoragent.CodePathUnreadable {
		t.Fatalf("missing folder: %d %s", recorder.Code, recorder.Body)
	}
}
