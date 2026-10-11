package profilefeedback

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/profilefeedback"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"reflect"
	"time"
)

// TouchTx is the shared392 child mutation seam. Reads and intrinsic no-ops do
// not call it. The prepared token belongs to the exact caller transaction.
func (s RootService) TouchTx(c context.Context, t tx.Tx, p PreparedRoot, at time.Time) (d.Root, error) {
	a, b := reflect.ValueOf(t), reflect.ValueOf(p.caller)
	if s.Store == nil || !a.IsValid() || !b.IsValid() || a.Type() != b.Type() || !a.Comparable() || !a.Equal(b) || at.IsZero() || p.root.StateVersion == math.MaxInt64 {
		return d.Root{}, ErrInvalid
	}
	fresh, ok, e := s.Store.ReadRootTx(c, t, p.root.PlayerID)
	if e != nil {
		return d.Root{}, e
	}
	if ok != p.present || (ok && fresh.StateVersion != p.root.StateVersion) {
		return d.Root{}, ErrConflict
	}
	r := p.root
	r.StateVersion++
	r.UpdatedAt = at.UTC()
	if p.present {
		if r.UpdatedAt.Before(p.root.UpdatedAt) {
			r.UpdatedAt = p.root.UpdatedAt
		}
		e = s.Store.UpdateRootTx(c, t, p.root, r)
	} else {
		r.CreatedAt = r.UpdatedAt
		e = s.Store.InsertRootTx(c, t, r)
	}
	return r, e
}

type CommentCommand struct {
	Kind      string            `json:"kind"`
	Target    identity.PlayerID `json:"target"`
	CommentID int64             `json:"comment_id"`
	Content   string            `json:"content"`
}

func (q CommentCommand) Validate(a identity.ActorContext) error {
	switch q.Kind {
	case "post":
		if !q.Target.Valid() || int64(q.Target) > d.MaxWireCommentID || q.Target == a.PlayerID || q.CommentID != 0 {
			return ErrRequest
		}
		if _, e := d.ModerateComment(q.Content, nil); e != nil {
			return ErrRequest
		}
	case "react":
		if !q.Target.Valid() || q.Target == a.PlayerID || int64(q.Target) > d.MaxWireCommentID || q.CommentID <= 0 || q.CommentID > d.MaxWireCommentID || q.Content != "" {
			return ErrRequest
		}
	case "delete":
		if q.Target != 0 || q.CommentID <= 0 || q.CommentID > d.MaxWireCommentID || q.Content != "" {
			return ErrRequest
		}
	default:
		return ErrRequest
	}
	return nil
}

// Journal retains every internal identity, including definite cancellation.
// Admission is control, separate from the one semantic gameplay transaction.
type CommentAdmission struct {
	Operation        operation.Context
	Actor, Target    identity.PlayerID
	Account, Context string
	Server           identity.LogicalServerID
	Command          CommentCommand
	Fingerprint      [32]byte
	DecisionAt       time.Time
	Revision, State  string
}
type CommentStore interface {
	FindCommentTx(context.Context, tx.Queryer, int64, identity.PlayerID) (d.Comment, bool, error)
	InsertCommentTx(context.Context, tx.Tx, d.Comment) (d.Comment, error)
	DeleteCommentTx(context.Context, tx.Tx, d.Comment, time.Time, int64) error
	FindReactionTx(context.Context, tx.Queryer, int64, identity.PlayerID) (d.CommentReaction, bool, error)
	InsertReactionTx(context.Context, tx.Tx, d.CommentReaction) error
	CountCommentsTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error)
	ListCommentsTx(context.Context, tx.Queryer, identity.PlayerID, identity.PlayerID, int64, int64, bool) ([]d.Comment, error)
	ReadAdmissionTx(context.Context, tx.Queryer, string, bool) (CommentAdmission, bool, error)
	PendingAdmissionTx(context.Context, tx.Tx, identity.PlayerID) (CommentAdmission, bool, error)
	InsertAdmissionTx(context.Context, tx.Tx, CommentAdmission) error
	SetAdmissionStateTx(context.Context, tx.Tx, string, string, string) error
}
type CommentService struct {
	Base  Service
	Store CommentStore
}
type CommentRow = d.CommentRow
type CommentPage = d.CommentObservation
type CommentResult struct {
	Terminal CommentTerminal
	Current  CommentPage
	Affected *CommentRow
}

func (r CommentResult) Wire() map[string]any {
	switch r.Terminal.Kind {
	case "post":
		return r.Current.Wire()
	case "react":
		return map[string]any{"best_comments": r.Current.Best, "comment_info": r.Affected}
	default:
		return map[string]any{}
	}
}
