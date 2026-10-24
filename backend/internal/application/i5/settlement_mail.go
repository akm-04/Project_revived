package i5

import (
	"context"
	"errors"
	"reflect"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrSettlementMailConflict = errors.New("i5: settlement mail source already delivered with different content")

// Source kinds owned by I5 itself or other producers are never accepted here.
var reservedMailSources = map[string]bool{"ADMIN": true, "GRANT_OVERFLOW": true, "GUILD_BROADCAST": true}

type SettlementMailStore interface {
	LockMailNamespaceCounterTx(context.Context, tx.Tx, identity.PlayerID, mail.Namespace) error
	AllocateMailWireIDTx(context.Context, tx.Tx, identity.PlayerID, mail.Namespace) (int64, error)
	InsertMailTx(context.Context, tx.Tx, mail.Record) error
	ReadSourceMailTx(context.Context, tx.Queryer, identity.PlayerID, string, string) (mail.Record, bool, error)
}

type SettlementMailRequest struct {
	Recipient     identity.PlayerID
	SourceKind    string
	SourceKey     string
	Title         string
	Sender        string
	Body          string
	PolicyVersion string
	Lines         []grant.Line
	At            time.Time
}

// SettlementMail is the narrow producer seam (scoped I7C-5B amendment): one
// mail with grant attachments per (recipient, source kind, source key) inside
// the caller's transaction, under the namespace lock (rank 610). Attachments
// are granted only when the recipient claims the mail.
type SettlementMail struct {
	Store SettlementMailStore
}

// DeliverTx returns the delivered mail and whether it already existed.
func (m SettlementMail) DeliverTx(ctx context.Context, t tx.Tx, r SettlementMailRequest) (mail.Record, bool, error) {
	if m.Store == nil || t == nil || !r.Recipient.Valid() || strings.TrimSpace(r.SourceKind) == "" || reservedMailSources[r.SourceKind] || strings.TrimSpace(r.SourceKey) == "" || strings.TrimSpace(r.PolicyVersion) == "" || len(r.Lines) == 0 || r.At.IsZero() {
		return mail.Record{}, false, errors.New("i5: settlement mail request incomplete")
	}
	for _, line := range r.Lines {
		if err := line.Validate(); err != nil {
			return mail.Record{}, false, err
		}
	}
	if err := m.Store.LockMailNamespaceCounterTx(ctx, t, r.Recipient, mail.Normal); err != nil {
		return mail.Record{}, false, err
	}
	prior, found, err := m.Store.ReadSourceMailTx(ctx, t, r.Recipient, r.SourceKind, r.SourceKey)
	if err != nil {
		return mail.Record{}, false, err
	}
	if found {
		if !sameSettlementMail(prior, r) {
			return mail.Record{}, true, ErrSettlementMailConflict
		}
		return prior, true, nil
	}
	created, err := createMailTx(ctx, t, m.Store, r.Recipient, mail.Normal, r.SourceKind, r.SourceKey, r.Title, r.Sender, r.Body, r.Lines, r.At, nil, r.PolicyVersion)
	return created, false, err
}

func sameSettlementMail(m mail.Record, r SettlementMailRequest) bool {
	if m.Title != r.Title || m.Sender != r.Sender || m.Body != r.Body || m.CompatibilityPolicyVersion != r.PolicyVersion || len(m.Attachments) != len(r.Lines) {
		return false
	}
	for i, a := range m.Attachments {
		want := r.Lines[i]
		if a.Line.Kind != want.Kind || a.Line.ResourceKey != want.ResourceKey || a.Line.ItemID != want.ItemID || a.Line.Amount != want.Amount || len(a.Line.Metadata)+len(want.Metadata) > 0 && !reflect.DeepEqual(a.Line.Metadata, want.Metadata) {
			return false
		}
	}
	return true
}
