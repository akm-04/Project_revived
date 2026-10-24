package socialinbox

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"sort"
	"strconv"
	"strings"
	"time"
)

var ErrRelationNoticeConflict = errors.New("relation notice immutable source conflict")

type RelationEvent uint8

const (
	AcceptRelationRequest RelationEvent = iota + 1
	DenyRelationRequest
	DeleteRelationFriendship
)

// RelationTransition is a finite canonical source identity, never client JSON.
type RelationTransition struct {
	Event            RelationEvent
	First, Second    identity.PlayerID
	Generation       int64
	Actor, Recipient identity.PlayerID
	At               time.Time
}

func (e RelationTransition) Descriptor() (Notice, error) {
	if !e.First.Valid() || !e.Second.Valid() || e.First == e.Second || e.Generation < 1 || e.At.IsZero() {
		return Notice{}, ErrInvalidNotice
	}
	n := Notice{RecipientPlayerID: e.Recipient, RelatedPlayerID: e.Actor, NoticeTime: e.At.UTC()}
	switch e.Event {
	case AcceptRelationRequest, DenyRelationRequest:
		if e.Actor != e.Second || e.Recipient != e.First {
			return Notice{}, ErrInvalidNotice
		}
		action := "ACCEPT"
		n.NoticeType = 1
		if e.Event == DenyRelationRequest {
			action = "DENY"
			n.NoticeType = 2
		}
		n.Source = SourceKey{Kind: "social-relation.request.v1", Key: fmt.Sprintf("%d:%d:%d:%s", e.First, e.Second, e.Generation, action)}
	case DeleteRelationFriendship:
		if e.First >= e.Second || (e.Actor != e.First && e.Actor != e.Second) {
			return Notice{}, ErrInvalidNotice
		}
		other := e.First
		if e.Actor == e.First {
			other = e.Second
		}
		if e.Recipient != other {
			return Notice{}, ErrInvalidNotice
		}
		n.NoticeType = 3
		n.Source = SourceKey{Kind: "social-relation.friendship.v1", Key: fmt.Sprintf("%d:%d:%d:DELETE", e.First, e.Second, e.Generation)}
	default:
		return Notice{}, ErrInvalidNotice
	}
	return n, nil
}

type RecipientFence struct {
	PlayerID     identity.PlayerID
	StateVersion int64
}
type PreparedRelationNotice struct {
	descriptor Notice
	existing   *Notice
	caller     tx.Tx
	prepared   bool
}

func (p PreparedRelationNotice) Recipient() identity.PlayerID { return p.descriptor.RecipientPlayerID }
func (p PreparedRelationNotice) ExistingNotice() (Notice, bool) {
	if p.existing == nil {
		return Notice{}, false
	}
	return copyNotice(*p.existing), true
}

// copyNotice isolates nullable lifecycle pointers from the private prepared plan.
func copyNotice(n Notice) Notice {
	if n.DismissedAt != nil {
		at := *n.DismissedAt
		n.DismissedAt = &at
	}
	return n
}

func sameCaller(a, b tx.Tx) bool {
	av, bv := reflect.ValueOf(a), reflect.ValueOf(b)
	return av.IsValid() && bv.IsValid() && av.Type() == bv.Type() && av.Comparable() && av.Equal(bv)
}

// ValidateRelationDescriptor restricts this persistence seam to finite relation sources.
func ValidateRelationDescriptor(n Notice) error {
	parts := strings.Split(n.Source.Key, ":")
	if len(parts) != 4 {
		return ErrInvalidNotice
	}
	first, e1 := strconv.ParseInt(parts[0], 10, 64)
	second, e2 := strconv.ParseInt(parts[1], 10, 64)
	generation, e3 := strconv.ParseInt(parts[2], 10, 64)
	if e1 != nil || e2 != nil || e3 != nil {
		return ErrInvalidNotice
	}
	e := RelationTransition{First: identity.PlayerID(first), Second: identity.PlayerID(second), Generation: generation, Actor: n.RelatedPlayerID, Recipient: n.RecipientPlayerID, At: n.NoticeTime}
	switch {
	case n.NoticeType == 1 && parts[3] == "ACCEPT":
		e.Event = AcceptRelationRequest
	case n.NoticeType == 2 && parts[3] == "DENY":
		e.Event = DenyRelationRequest
	case n.NoticeType == 3 && parts[3] == "DELETE":
		e.Event = DeleteRelationFriendship
	default:
		return ErrInvalidNotice
	}
	canonical, err := e.Descriptor()
	if err != nil {
		return err
	}
	if canonical.Source != n.Source {
		return ErrInvalidNotice
	}
	return nil
}

type RelationNoticeStore interface {
	LockNoticeSourceTx(context.Context, tx.Tx, identity.PlayerID, SourceKey) (Notice, bool, error)
	InsertRelationNoticeTx(context.Context, tx.Tx, Notice) (Notice, error)
}
type RelationMaterializer interface {
	PrepareRelationsTx(context.Context, tx.Tx, []RecipientFence, []RelationTransition) ([]PreparedRelationNotice, error)
	ApplyRelationsTx(context.Context, tx.Tx, []PreparedRelationNotice) ([]Notice, error)
}
type RelationService struct{ Store RelationNoticeStore }

func (s RelationService) PrepareRelationsTx(ctx context.Context, t tx.Tx, fences []RecipientFence, events []RelationTransition) ([]PreparedRelationNotice, error) {
	if t == nil || s.Store == nil {
		return nil, ErrInvalidNotice
	}
	held := map[identity.PlayerID]bool{}
	for _, f := range fences {
		if !f.PlayerID.Valid() || f.StateVersion < 1 {
			return nil, ErrInvalidNotice
		}
		held[f.PlayerID] = true
	}
	plans := make([]PreparedRelationNotice, 0, len(events))
	keys := make([]lockkey.Key, 0, len(events))
	by := map[string]bool{}
	for _, e := range events {
		n, err := e.Descriptor()
		if err != nil {
			return nil, err
		}
		if !held[n.RecipientPlayerID] {
			return nil, ErrInvalidNotice
		}
		k, err := NoticeSourceLockKey(n.RecipientPlayerID, n.Source)
		if err != nil {
			return nil, err
		}
		id := fmt.Sprint(n.RecipientPlayerID) + ":" + n.Source.Kind + ":" + n.Source.Key
		if by[id] {
			return nil, ErrRelationNoticeConflict
		}
		by[id] = true
		keys = append(keys, k)
		plans = append(plans, PreparedRelationNotice{descriptor: n, caller: t, prepared: true})
	}
	order := make([]int, len(plans))
	for i := range order {
		order[i] = i
	}
	sort.Slice(order, func(i, j int) bool { return lockkey.Compare(keys[order[i]], keys[order[j]]) < 0 })
	ordered := make([]PreparedRelationNotice, 0, len(plans))
	for _, i := range order {
		p := plans[i]
		n, ok, err := s.Store.LockNoticeSourceTx(ctx, t, p.descriptor.RecipientPlayerID, p.descriptor.Source)
		if err != nil {
			return nil, err
		}
		if ok {
			if err := sameRelationNotice(n, p.descriptor); err != nil {
				return nil, err
			}
			copy := copyNotice(n)
			p.existing = &copy
		}
		ordered = append(ordered, p)
	}
	return ordered, nil
}
func sameRelationNotice(n, w Notice) error {
	if err := n.Validate(); err != nil {
		return err
	}
	if n.RecipientPlayerID != w.RecipientPlayerID || n.Source != w.Source || n.NoticeType != w.NoticeType || n.RelatedPlayerID != w.RelatedPlayerID || !n.NoticeTime.Equal(w.NoticeTime) {
		return ErrRelationNoticeConflict
	}
	return nil
}
func (s RelationService) ApplyRelationsTx(ctx context.Context, t tx.Tx, plans []PreparedRelationNotice) ([]Notice, error) {
	if t == nil || s.Store == nil {
		return nil, ErrInvalidNotice
	}
	out := make([]Notice, 0, len(plans))
	for _, p := range plans {
		if !p.prepared || !sameCaller(t, p.caller) {
			return nil, ErrInvalidNotice
		}
		if err := ValidateRelationDescriptor(p.descriptor); err != nil {
			return nil, err
		}
		if p.existing != nil {
			if !p.existing.NoticeID.WireSafe() {
				return nil, ErrInvalidNotice
			}
			if err := sameRelationNotice(*p.existing, p.descriptor); err != nil {
				return nil, err
			}
			out = append(out, copyNotice(*p.existing))
			continue
		}
		n, err := s.Store.InsertRelationNoticeTx(ctx, t, p.descriptor)
		if err != nil {
			return nil, err
		}
		if err := sameRelationNotice(n, p.descriptor); err != nil {
			return nil, err
		}
		if !n.NoticeID.WireSafe() {
			return nil, ErrInvalidNotice
		}
		out = append(out, n)
	}
	return out, nil
}

var _ RelationMaterializer = RelationService{}
