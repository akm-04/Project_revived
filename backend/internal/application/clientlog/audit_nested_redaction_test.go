package clientlog

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"testing"

	domain "gxb.local/backend/v2/internal/domain/clientlog"
)

func TestAuditA073IngestRedactsNestedSecrets(t *testing.T) {
	for _, metadata := range []string{
		`{"capability":"synthetic-audit-value","keep":"ok"}`,
		`[{"log_url":"https://invalid.example/client-log/synthetic-audit-value","keep":"ok"}]`,
		`"log_url=https://invalid.example/client-log/synthetic-audit-value"`,
	} {
		service, store, _ := newService()
		capability := issue(t, service)
		payload := deflate(t, `[{"log":"failure","metadata":`+metadata+`}]`)
		status := service.Ingest(context.Background(), UploadRequest{Capability: capability, Kind: domain.KindErrorLog, Payload: payload})
		if status != http.StatusOK || len(store.uploads) != 1 || len(store.uploads[0].Rows) != 1 {
			t.Fatalf("upload did not reach SaveUpload: status=%d", status)
		}
		raw, err := json.Marshal(store.uploads[0].Rows[0].Extras)
		if err != nil {
			t.Fatal(err)
		}
		if strings.Contains(string(raw), "synthetic-audit-value") {
			t.Error("nested secret reached SaveUpload")
		}
		if metadata[0] != '"' && !strings.Contains(string(raw), `"keep":"ok"`) {
			t.Error("non-secret nested value was dropped")
		}
	}
}
