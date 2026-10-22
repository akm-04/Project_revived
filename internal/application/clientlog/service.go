// Package clientlog ingests stock client log uploads and keeps the per-uid
// request journal (I85_CLIENT_LOG_INGEST_V1, I85_REQUEST_JOURNAL_V1,
// I85_LOG_RETENTION_V1). Nothing here touches game state.
package clientlog

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"sync"
	"time"

	domain "gxb.local/backend/v2/internal/domain/clientlog"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
)

// Attribution names how an upload was tied to a uid (R2, R3).
type Attribution string

const (
	AttributedByCapability Attribution = "CAPABILITY"
	AttributedByToken      Attribution = "TOKEN"
	UnattributedMissing    Attribution = "UNATTRIBUTED_MISSING"
	UnattributedUnknown    Attribution = "UNATTRIBUTED_UNKNOWN"
	UnattributedExpired    Attribution = "UNATTRIBUTED_EXPIRED"
)

// Grant is a stored log capability (D44).
type Grant struct {
	Digest          [32]byte
	AccountUID      string
	PlayerID        int64
	LogicalServerID int32
	SessionRef      string
	IssuedAt        time.Time
	ExpiresAt       time.Time
}

// Owner is the uid an upload is attributed to.
type Owner struct {
	AccountUID string
	PlayerID   int64
	SessionRef string
}

// Upload is one stored upload record; its rows are stored with it.
type Upload struct {
	ID                  ids.UUID
	ReceivedAt          time.Time
	Kind                domain.Kind
	Owner               *Owner
	Attribution         Attribution
	QuarantineReason    string
	Class               domain.RetentionClass
	BodyBytes           int
	AppVersion          string
	Version             string
	AttachmentName      string
	Attachment          []byte
	AttachmentTruncated bool
	Rows                []domain.Row
}

// Store is the ClientLog persistence owner.
type Store interface {
	SaveGrant(context.Context, Grant) error
	Grant(ctx context.Context, digest [32]byte) (Grant, bool, error)
	SaveUpload(context.Context, Upload) error
	SaveJournal(context.Context, []JournalRow) error
	PurgeExpired(ctx context.Context, now time.Time, batch int) (int64, error)
}

// BearerResolver resolves the type 1 form token (the stock gameplay token).
type BearerResolver interface {
	ResolveGameplayBearer(ctx context.Context, raw string, now time.Time) (identity.ActorContext, error)
}

// UploadRequest is a parsed POST to the log URL. Malformed carries the
// reason when the multipart body itself could not be read.
type UploadRequest struct {
	Capability     string
	Kind           domain.Kind
	BodyBytes      int
	Payload        []byte
	AppVersion     string
	Version        string
	Token          string
	AttachmentName string
	Attachment     []byte
	Malformed      string
}

// Quarantine reasons (R4).
const (
	QuarantineMalformedMultipart = "MALFORMED_MULTIPART"
	QuarantineOverCap            = "OVER_CAP"
	QuarantineBadCompression     = "BAD_COMPRESSION"
	QuarantineBadRows            = "BAD_ROWS"
)

// Service owns capability issue and upload ingest.
type Service struct {
	Store   Store
	Bearers BearerResolver
	Clock   clock.Clock
	BaseURL string
	limiter rateLimiter
}

// IssueLogURL returns the per-session log_url for a MID1 response. An empty
// base keeps the stock empty log_url (no uploads).
func (s *Service) IssueLogURL(ctx context.Context, owner Owner, logicalServerID int32) (string, error) {
	if s.BaseURL == "" {
		return "", nil
	}
	capability, digest, err := domain.MintCapability()
	if err != nil {
		return "", err
	}
	now := s.Clock.Now()
	grant := Grant{Digest: digest, AccountUID: owner.AccountUID, PlayerID: owner.PlayerID, LogicalServerID: logicalServerID, SessionRef: owner.SessionRef, IssuedAt: now, ExpiresAt: now.Add(domain.CapabilityLifetime)}
	if err := s.Store.SaveGrant(ctx, grant); err != nil {
		return "", err
	}
	return strings.TrimRight(s.BaseURL, "/") + "/" + capability, nil
}

// FallbackLogURL is the base URL alone: uploads still arrive, unattributed.
func (s *Service) FallbackLogURL() string { return s.BaseURL }

// Ingest stores an upload and returns the HTTP status for the stock poster:
// 200 once durable (including quarantine), 429 when rate limited, 503 when
// the store failed (the poster keeps its rows and retries).
func (s *Service) Ingest(ctx context.Context, request UploadRequest) int {
	now := s.Clock.Now()
	owner, attribution, err := s.attribute(ctx, request, now)
	if err != nil {
		return http.StatusServiceUnavailable
	}
	if attribution == AttributedByCapability && !s.limiter.allow(request.Capability, now) {
		return http.StatusTooManyRequests
	}
	id, err := ids.NewUUID()
	if err != nil {
		return http.StatusServiceUnavailable
	}
	upload := Upload{ID: id, ReceivedAt: now, Kind: request.Kind, Owner: owner, Attribution: attribution, BodyBytes: request.BodyBytes,
		AppVersion: request.AppVersion, Version: request.Version, AttachmentName: request.AttachmentName, Attachment: request.Attachment}
	upload.QuarantineReason, upload.Rows = parseUpload(request)
	if upload.QuarantineReason != "" && request.Kind == domain.KindErrorLog {
		upload.Attachment, upload.AttachmentTruncated = boundedCopy(request.Payload, domain.MaxErrorLogBodyBytes)
	}
	upload.Class = uploadClass(upload)
	if err := s.Store.SaveUpload(ctx, upload); err != nil {
		return http.StatusServiceUnavailable
	}
	return http.StatusOK
}

func parseUpload(request UploadRequest) (string, []domain.Row) {
	if request.Malformed != "" {
		return request.Malformed, nil
	}
	if request.Kind == domain.KindCrash {
		return "", nil
	}
	inflated, err := domain.Inflate(request.Payload)
	if errors.Is(err, domain.ErrOverCap) {
		return QuarantineOverCap, nil
	}
	if err != nil {
		return QuarantineBadCompression, nil
	}
	rows, err := domain.ParseRows(inflated)
	if errors.Is(err, domain.ErrOverCap) {
		return QuarantineOverCap, nil
	}
	if err != nil {
		return QuarantineBadRows, nil
	}
	return "", rows
}

func uploadClass(upload Upload) domain.RetentionClass {
	attributed := upload.Owner != nil
	quarantined := upload.QuarantineReason != ""
	if upload.Kind == domain.KindCrash && attributed && !quarantined {
		return domain.Error
	}
	return domain.UploadClass(upload.Rows, attributed, quarantined)
}

func boundedCopy(data []byte, limit int) ([]byte, bool) {
	if len(data) <= limit {
		return append([]byte(nil), data...), false
	}
	return append([]byte(nil), data[:limit]...), true
}

func (s *Service) attribute(ctx context.Context, request UploadRequest, now time.Time) (*Owner, Attribution, error) {
	owner, attribution, err := s.byCapability(ctx, request.Capability, now)
	if err != nil {
		return nil, "", err
	}
	if request.Kind != domain.KindCrash || request.Token == "" || s.Bearers == nil {
		return owner, attribution, nil
	}
	actor, err := s.Bearers.ResolveGameplayBearer(ctx, request.Token, now)
	if err != nil {
		return owner, attribution, nil
	}
	tokenOwner := &Owner{AccountUID: string(actor.AccountUID), PlayerID: int64(actor.PlayerID), SessionRef: domain.SessionReference(actor.SessionID.UUID().String())}
	if owner != nil && owner.AccountUID == tokenOwner.AccountUID {
		return owner, attribution, nil
	}
	return tokenOwner, AttributedByToken, nil
}

func (s *Service) byCapability(ctx context.Context, capability string, now time.Time) (*Owner, Attribution, error) {
	if capability == "" {
		return nil, UnattributedMissing, nil
	}
	digest, valid := domain.CapabilityDigest(capability)
	if !valid {
		return nil, UnattributedUnknown, nil
	}
	grant, found, err := s.Store.Grant(ctx, digest)
	if err != nil {
		return nil, "", err
	}
	if !found {
		return nil, UnattributedUnknown, nil
	}
	if !now.Before(grant.ExpiresAt) {
		return nil, UnattributedExpired, nil
	}
	return &Owner{AccountUID: grant.AccountUID, PlayerID: grant.PlayerID, SessionRef: grant.SessionRef}, AttributedByCapability, nil
}

// rateLimiter is a fixed one-minute window per capability (R5, D47).
// shortcut: per-process counts; a multi-replica gxb-api needs a shared limiter (I12).
type rateLimiter struct {
	mutex  sync.Mutex
	window time.Time
	counts map[string]int
}

func (l *rateLimiter) allow(capability string, now time.Time) bool {
	l.mutex.Lock()
	defer l.mutex.Unlock()
	window := now.Truncate(time.Minute)
	if !window.Equal(l.window) {
		l.window, l.counts = window, map[string]int{}
	}
	l.counts[capability]++
	return l.counts[capability] <= domain.UploadsPerMinute
}

// Purge deletes expired rows in bounded batches until a short batch (D43).
func (s *Service) Purge(ctx context.Context) (int64, error) {
	const batch = 5000
	var total int64
	for {
		deleted, err := s.Store.PurgeExpired(ctx, s.Clock.Now(), batch)
		total += deleted
		if err != nil || deleted < batch {
			return total, err
		}
	}
}
