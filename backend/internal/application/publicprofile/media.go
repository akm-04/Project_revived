package publicprofile

import (
	"context"
	"fmt"
	"net/url"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/profileasset"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const MediaURLPolicy = "I7B_PROFILE_MEDIA_URL_V1"
const MediaSchema = "gxb.public-profile.media.v1"
const MediaCommand = "custom-avatar"
const MediaClass = "I7B5B_MEDIA_ASSIGNMENT"

type MediaURL struct{ origin string }

// The selected client recognizes literal http:// only and sends no auth headers.
// This immutable capability URL does not promise revocation of downloaded bytes.
func NewMediaURL(origin string) (MediaURL, error) {
	u, e := url.Parse(origin)
	if e != nil || u.Scheme != "http" || u.Host == "" || u.User != nil || u.RawQuery != "" || u.Fragment != "" || (u.Path != "" && u.Path != "/") || u.Opaque != "" || u.RawPath != "" {
		return MediaURL{}, ErrCommand
	}
	if strings.ContainsAny(origin, "\r\n\t ") {
		return MediaURL{}, ErrCommand
	}
	return MediaURL{origin: strings.TrimSuffix(origin, "/")}, nil
}
func (u MediaURL) Reference(op ids.UUID, d profileasset.Descriptor) (MediaReference, error) {
	if u.origin == "" || op.IsZero() || d.Validate() != nil {
		return MediaReference{}, ErrCommand
	}
	return MediaReference{Operation: op, Asset: d, URL: fmt.Sprintf("%s/profile-media/%s/%s.png", u.origin, op.String(), d.SHA256)}, nil
}

type MediaReference struct {
	Operation ids.UUID                `json:"operation"`
	Asset     profileasset.Descriptor `json:"asset"`
	URL       string                  `json:"url"`
}

func (r MediaReference) Validate() error {
	if r.Operation.IsZero() || r.Asset.Validate() != nil {
		return profileasset.ErrIntegrity
	}
	u, e := url.Parse(r.URL)
	if e != nil || u.Scheme != "http" || u.Host == "" || u.User != nil || u.RawQuery != "" || u.Fragment != "" || u.RawPath != "" || u.Path != "/profile-media/"+r.Operation.String()+"/"+r.Asset.SHA256+".png" {
		return profileasset.ErrIntegrity
	}
	return nil
}

type MediaHistory struct {
	Operation   ids.UUID                 `json:"operation"`
	PlayerID    identity.PlayerID        `json:"player_id"`
	Server      identity.LogicalServerID `json:"server"`
	Reference   MediaReference           `json:"reference"`
	RootVersion int64                    `json:"root_version"`
	DecisionAt  time.Time                `json:"decision_at"`
}

func (h MediaHistory) Validate() error {
	if h.Operation.IsZero() || !h.PlayerID.Valid() || !h.Server.Valid() || h.Reference.Validate() != nil || h.RootVersion <= 0 || h.DecisionAt.IsZero() {
		return profileasset.ErrIntegrity
	}
	return nil
}

type MediaCurrent struct {
	PlayerID  identity.PlayerID `json:"player_id"`
	Operation ids.UUID          `json:"operation"`
}
type MediaInventory struct {
	Current []MediaCurrent `json:"current"`
	History []MediaHistory `json:"history"`
}
type MediaStore interface {
	ReadCurrentMediaTx(context.Context, tx.Queryer, identity.PlayerID) (MediaHistory, bool, error)
	ReadMediaHistoryTx(context.Context, tx.Queryer, ids.UUID) (MediaHistory, bool, error)
	InsertMediaHistoryTx(context.Context, tx.Tx, MediaHistory) error
	SetCurrentMediaTx(context.Context, tx.Tx, identity.PlayerID, ids.UUID) error
	InventoryMediaTx(context.Context, tx.Queryer) (MediaInventory, error)
}

// Caller supplies the witnessed coherent scope, not an independently opened
// transaction or freshly discovered clock/content revision. Privacy/discovery
// belongs to the enclosing qualified PublicProfile reader at stage6.
func (s RootService) ReadMediaTx(c context.Context, sc tx.Scope, store MediaStore, pid identity.PlayerID, revision string, at time.Time) (MediaHistory, bool, error) {
	snap, e := s.ReadSnapshotTx(c, sc, pid, revision, at)
	if e != nil || store == nil {
		return MediaHistory{}, false, ErrInvalidState
	}
	h, ok, e := store.ReadCurrentMediaTx(c, sc.Tx, pid)
	if e != nil || !ok {
		return h, ok, e
	}
	if h.Validate() != nil || h.PlayerID != pid || !snap.Present || snap.Root.StateVersion < h.RootVersion {
		return h, false, profileasset.ErrIntegrity
	}
	return h, true, nil
}
