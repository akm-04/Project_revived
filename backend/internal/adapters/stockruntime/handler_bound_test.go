package stockruntime

import (
	"context"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"

	appclientlog "gxb.local/backend/v2/internal/application/clientlog"
	blobport "gxb.local/backend/v2/internal/application/profileasset"
	publicprofile "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type blockingIngest struct {
	started chan struct{}
	release chan struct{}
}

func (b blockingIngest) Ingest(context.Context, appclientlog.UploadRequest) int {
	b.started <- struct{}{}
	<-b.release
	return http.StatusOK
}

func TestClientLogHandlerRefusesBeyondBound(t *testing.T) {
	bound, err := httpedge.NewAdmission(2)
	if err != nil {
		t.Fatal(err)
	}
	handler := ClientLogHandler{
		Ingest:   blockingIngest{started: make(chan struct{}, 8), release: make(chan struct{})},
		BasePath: "/client-log",
		Bound:    bound,
	}
	upload := handler.Ingest.(blockingIngest)
	var admitted sync.WaitGroup
	for range 2 {
		admitted.Add(1)
		go func() {
			defer admitted.Done()
			handler.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodPost, "/client-log/capability", nil))
		}()
	}
	<-upload.started
	<-upload.started

	refused := httptest.NewRecorder()
	handler.ServeHTTP(refused, httptest.NewRequest(http.MethodPost, "/client-log/capability", nil))
	if refused.Code != http.StatusServiceUnavailable {
		t.Fatalf("third upload answered %d, want %d", refused.Code, http.StatusServiceUnavailable)
	}
	if refused.Header().Get("Retry-After") != boundedRetryAfterSeconds {
		t.Fatalf("Retry-After = %q, want %q", refused.Header().Get("Retry-After"), boundedRetryAfterSeconds)
	}

	close(upload.release)
	admitted.Wait()
	recovered := httptest.NewRecorder()
	handler.ServeHTTP(recovered, httptest.NewRequest(http.MethodPost, "/client-log/capability", nil))
	if recovered.Code != http.StatusOK {
		t.Fatalf("upload after the bound released answered %d, want %d", recovered.Code, http.StatusOK)
	}
}

type blockingMediaStore struct {
	started chan struct{}
	release chan struct{}
}

func (m blockingMediaStore) ReadCurrentMediaTx(context.Context, tx.Queryer, identity.PlayerID) (publicprofile.MediaHistory, bool, error) {
	return publicprofile.MediaHistory{}, false, nil
}

func (m blockingMediaStore) ReadMediaHistoryTx(context.Context, tx.Queryer, ids.UUID) (publicprofile.MediaHistory, bool, error) {
	m.started <- struct{}{}
	<-m.release
	return publicprofile.MediaHistory{}, false, nil
}

func (blockingMediaStore) InsertMediaHistoryTx(context.Context, tx.Tx, publicprofile.MediaHistory) error {
	return nil
}

func (blockingMediaStore) SetCurrentMediaTx(context.Context, tx.Tx, identity.PlayerID, ids.UUID) error {
	return nil
}

func (blockingMediaStore) InventoryMediaTx(context.Context, tx.Queryer) (publicprofile.MediaInventory, error) {
	return publicprofile.MediaInventory{}, nil
}

type cancelledMediaStore struct{ started chan<- struct{} }

func (cancelledMediaStore) ReadCurrentMediaTx(context.Context, tx.Queryer, identity.PlayerID) (publicprofile.MediaHistory, bool, error) {
	return publicprofile.MediaHistory{}, false, nil
}

func (m cancelledMediaStore) ReadMediaHistoryTx(c context.Context, _ tx.Queryer, _ ids.UUID) (publicprofile.MediaHistory, bool, error) {
	m.started <- struct{}{}
	<-c.Done()
	return publicprofile.MediaHistory{}, false, c.Err()
}

func (cancelledMediaStore) InsertMediaHistoryTx(context.Context, tx.Tx, publicprofile.MediaHistory) error {
	return nil
}

func (cancelledMediaStore) SetCurrentMediaTx(context.Context, tx.Tx, identity.PlayerID, ids.UUID) error {
	return nil
}

func (cancelledMediaStore) InventoryMediaTx(context.Context, tx.Queryer) (publicprofile.MediaInventory, error) {
	return publicprofile.MediaInventory{}, nil
}

type unusedBlobStore struct{}

func (unusedBlobStore) Prepare(context.Context, io.Reader, asset.Reservation) (blobport.PreparedAsset, error) {
	return nil, errors.New("unused")
}

func (unusedBlobStore) OpenValidated(context.Context, asset.Descriptor) (blobport.Reader, error) {
	return nil, errors.New("unused")
}

func (unusedBlobStore) WithMaintenance(context.Context, func(blobport.Maintenance) error) error {
	return errors.New("unused")
}

type unusedQueryer struct{}

func (unusedQueryer) QueryRow(context.Context, string, ...any) tx.Row { return nil }

const mediaRequestPath = "/profile-media/11111111-1111-1111-1111-111111111111/" + "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png"

func mediaHandler(store publicprofile.MediaStore, bound *httpedge.Admission) ProfileMediaGET {
	return ProfileMediaGET{
		Service: publicprofile.MediaService{Media: store, Blobs: unusedBlobStore{}, Commands: publicprofile.CommandService{Fresh: unusedQueryer{}}},
		Bound:   bound,
	}
}

func TestProfileMediaGETRefusesBeyondBound(t *testing.T) {
	bound, err := httpedge.NewAdmission(2)
	if err != nil {
		t.Fatal(err)
	}
	store := blockingMediaStore{started: make(chan struct{}, 8), release: make(chan struct{})}
	handler := mediaHandler(store, bound)
	var admitted sync.WaitGroup
	for range 2 {
		admitted.Add(1)
		go func() {
			defer admitted.Done()
			handler.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, mediaRequestPath, nil))
		}()
	}
	<-store.started
	<-store.started

	refused := httptest.NewRecorder()
	handler.ServeHTTP(refused, httptest.NewRequest(http.MethodGet, mediaRequestPath, nil))
	if refused.Code != http.StatusServiceUnavailable {
		t.Fatalf("third avatar GET answered %d, want %d", refused.Code, http.StatusServiceUnavailable)
	}
	if refused.Header().Get("Retry-After") != boundedRetryAfterSeconds {
		t.Fatalf("Retry-After = %q, want %q", refused.Header().Get("Retry-After"), boundedRetryAfterSeconds)
	}

	close(store.release)
	admitted.Wait()
	recovered := httptest.NewRecorder()
	handler.ServeHTTP(recovered, httptest.NewRequest(http.MethodGet, mediaRequestPath, nil))
	if recovered.Code != http.StatusNotFound {
		t.Fatalf("avatar GET after the bound released answered %d, want %d", recovered.Code, http.StatusNotFound)
	}
}

func TestProfileMediaGETCancelledPoolWaitIsBusy(t *testing.T) {
	started := make(chan struct{}, 1)
	handler := mediaHandler(cancelledMediaStore{started: started}, nil)
	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		<-started
		cancel()
	}()
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, mediaRequestPath, nil).WithContext(ctx))
	if recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("cancelled avatar GET answered %d, want %d", recorder.Code, http.StatusServiceUnavailable)
	}
	if body := strings.TrimSpace(recorder.Body.String()); body != "media_unavailable" {
		t.Fatalf("cancelled avatar GET body = %q, want media_unavailable", body)
	}
}
