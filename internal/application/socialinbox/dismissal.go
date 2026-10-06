package socialinbox

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
	"strings"
	"time"
)

type DismissStore interface {
	LockNoticeTx(context.Context, tx.Tx, identity.PlayerID, NoticeID) (Notice, bool, error)
	DismissNoticeTx(context.Context, tx.Tx, Notice, time.Time) error
}
type SourceReader interface {
	ReadNoticeSourceTx(context.Context, tx.Tx, identity.PlayerID, SourceKey) (Notice, bool, error)
}

func RelationFamily(s SourceKey) bool {
	return s.Kind == "social-relation.request.v1" || s.Kind == "social-relation.friendship.v1"
}

// ValidateRelationLifecycle recognizes an immutable source after its related
// player FK became NULL. It derives no current profile or entitlement.
func ValidateRelationLifecycle(n Notice) error {
	if n.Validate() != nil {
		return ErrInvalidNotice
	}
	if n.RelatedPlayerID == 0 {
		if !n.RelatedPlayerDeleted {
			return ErrInvalidNotice
		}
		p := strings.Split(n.Source.Key, ":")
		if len(p) != 4 {
			return ErrInvalidNotice
		}
		a, e := strconv.ParseInt(p[0], 10, 64)
		if e != nil {
			return ErrInvalidNotice
		}
		b, e := strconv.ParseInt(p[1], 10, 64)
		if e != nil {
			return ErrInvalidNotice
		}
		switch n.Source.Kind {
		case "social-relation.request.v1":
			n.RelatedPlayerID = identity.PlayerID(b)
		case "social-relation.friendship.v1":
			if n.RecipientPlayerID == identity.PlayerID(a) {
				n.RelatedPlayerID = identity.PlayerID(b)
			} else if n.RecipientPlayerID == identity.PlayerID(b) {
				n.RelatedPlayerID = identity.PlayerID(a)
			} else {
				return ErrInvalidNotice
			}
		default:
			return ErrInvalidNotice
		}
	}
	return ValidateRelationDescriptor(n)
}
