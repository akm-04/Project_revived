package stockruntime

import (
	"context"
	"errors"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	auth "gxb.local/backend/v2/internal/application/realtimeauth"
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

type ProfileMediaDispatcher struct {
	Authority auth.GameplayAuthorityPort
	Service   app.MediaService
}

func (d ProfileMediaDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	fail := func(status int, msg string) httpedge.Response {
		return httpedge.Response{HTTPStatus: status, Body: map[string]any{"error_code": 1, "error": msg}}
	}
	if r.Envelope.MID != 1844 || d.Authority == nil || d.Service.Blobs == nil || r.Upload == nil || r.Upload.TempPath == "" {
		return fail(400, "invalid_media_upload")
	}
	token := r.Envelope.Claims.Token
	if token == "" {
		return fail(401, "unauthorized")
	}
	ac, e := d.Authority.ResolveGameplayBearer(c, token, r.Envelope.ReceivedAt)
	if e != nil {
		return fail(401, "unauthorized")
	}
	if r.Envelope.Claims.Region != int64(ac.LogicalServerID) {
		return fail(403, "region_mismatch")
	}
	for _, key := range []string{"to_player_id", "player_id", "target_player_id"} {
		if _, ok := r.Envelope.Params[key]; ok {
			return fail(400, "self_edit_only")
		}
	}
	f, e := os.Open(r.Upload.TempPath)
	if e != nil {
		return fail(503, "upload_unavailable")
	}
	prepareCtx, cancel := context.WithTimeout(c, 30*time.Second)
	p, e := d.Service.Blobs.Prepare(prepareCtx, f, asset.Reservation{Operation: r.Envelope.Operation.ID, Actor: ac.PlayerID, Server: ac.LogicalServerID})
	f.Close()
	cancel()
	if e != nil {
		if errors.Is(e, asset.ErrInvalid) {
			return fail(400, "invalid_png")
		}
		return fail(503, "media_unavailable")
	}
	desc, e := p.Descriptor()
	if e != nil {
		_ = p.Close(asset.DefiniteAbort)
		return fail(503, "media_unavailable")
	}
	out, e, cleanup := d.Service.Publish(c, ac, desc, p, r.Envelope.Operation)
	if cleanup != nil {
		log.Printf("profile media protection cleanup requires reconciliation: %v", cleanup)
	}
	if e != nil {
		if errors.Is(e, app.ErrCommand) {
			return fail(400, "invalid_media_command")
		}
		if errors.Is(e, app.ErrInvalidState) || errors.Is(e, app.ErrConflict) {
			return fail(409, "media_conflict")
		}
		return fail(503, "media_unavailable")
	}
	return httpedge.Response{HTTPStatus: 200, Body: out.Wire()}
}

// MediaGET exposes only committed immutable capabilities. The read completes
// before OpenValidated; no filesystem read is performed under database locks.
type ProfileMediaGET struct{ Service app.MediaService }

func (h ProfileMediaGET) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if h.Service.Media == nil || h.Service.Blobs == nil || h.Service.Commands.Fresh == nil {
		http.Error(w, "media_unavailable", 503)
		return
	}
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		w.Header().Set("Allow", "GET, HEAD")
		http.Error(w, "method_not_allowed", 405)
		return
	}
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/profile-media/"), "/")
	if !strings.HasPrefix(r.URL.Path, "/profile-media/") || len(parts) != 2 || r.URL.RawQuery != "" || !strings.HasSuffix(parts[1], ".png") {
		http.NotFound(w, r)
		return
	}
	op, e := ids.ParseUUID(parts[0])
	if e != nil || op.IsZero() || parts[0] != op.String() {
		http.NotFound(w, r)
		return
	}
	hist, ok, e := h.Service.Media.ReadMediaHistoryTx(r.Context(), h.Service.Commands.Fresh, op)
	if e != nil {
		http.Error(w, "media_integrity", 500)
		return
	}
	if !ok || hist.Reference.Operation != op || parts[1] != hist.Reference.Asset.SHA256+".png" {
		http.NotFound(w, r)
		return
	}
	f, e := h.Service.Blobs.OpenValidated(r.Context(), hist.Reference.Asset)
	if e != nil {
		http.Error(w, "media_integrity", 500)
		return
	}
	defer f.Close()
	w.Header().Set("Content-Type", "image/png")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
	w.Header().Set("ETag", `"`+hist.Reference.Asset.SHA256+`"`)
	http.ServeContent(w, r, "avatar.png", time.Time{}, f)
}
