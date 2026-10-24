package socialrelation

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"time"
	"unicode/utf8"
)

var (
	ErrInvalidCommand    = errors.New("invalid social relation command")
	ErrNotEligible       = errors.New("social relation command not eligible")
	ErrStaleDecisionTime = errors.New("social relation decision time predates canonical state")
	ErrStateConflict     = errors.New("social relation canonical state conflict")
	ErrCounterOverflow   = errors.New("social relation counter overflow")
	ErrPolicyDrift       = errors.New("social relation policy drift")
)

// StockError contains only selected source-qualified/compatibility codes.
type StockError struct{ Code int64 }

func (e *StockError) Error() string { return "social relation semantic rejection" }

// CommandKind is a semantic owner operation, independent of transport MID.
type CommandKind uint8

const (
	RequestFriend CommandKind = iota + 1
	DenyRequests
	IgnoreRequests
	AcceptRequest
	DeleteFriend
	AcceptAllRequests
	AddBlock
	RemoveBlock
	ClearBlocks
)

type Command struct {
	Kind    CommandKind
	Targets []identity.PlayerID
	Message string
}

func (c Command) validate() error {
	switch c.Kind {
	case DenyRequests, IgnoreRequests, AcceptAllRequests:
	case ClearBlocks:
		if len(c.Targets) != 0 {
			return ErrInvalidCommand
		}
	case RequestFriend, AcceptRequest, DeleteFriend, AddBlock, RemoveBlock:
		if len(c.Targets) != 1 {
			return ErrInvalidCommand
		}
	default:
		return ErrInvalidCommand
	}
	if !utf8.ValidString(c.Message) || len([]rune(c.Message)) > 26 || (c.Kind != RequestFriend && c.Message != "") {
		return ErrInvalidCommand
	}
	for _, pid := range c.Targets {
		if _, err := CanonicalServer(pid); err != nil {
			return err
		}
	}
	return nil
}
func CanonicalServer(pid identity.PlayerID) (identity.LogicalServerID, error) {
	if !pid.Valid() {
		return 0, ErrInvalidCommand
	}
	q := int64(pid) / 100000
	if q < 1 || q > math.MaxInt32 {
		return 0, ErrInvalidCommand
	}
	return identity.LogicalServerID(q), nil
}

const (
	RequestDayPolicy              = "SOCIAL_REQUEST_DAY_V1"
	RelationPolicy                = "SOCIAL_RELATION_MUTATIONS_V1"
	StaleTimePolicy               = "SOCIAL_DECISION_NOT_STALE_V1"
	QualifiedSourceRevision       = "c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf"
	FriendCapacity          int64 = 80
	RequestQuota            int64 = 9
)

func bindPolicies(op operation.Context) (operation.Context, error) {
	refs := op.Policies.Refs()
	for _, r := range []policy.Ref{{Name: "social.relation", Version: RelationPolicy + ":" + QualifiedSourceRevision}, {Name: "social.request.day", Version: RequestDayPolicy}, {Name: "social.time", Version: StaleTimePolicy}} {
		if v, ok := op.Policies.Get(r.Name); ok {
			if v != r.Version {
				return op, ErrPolicyDrift
			}
		} else {
			refs = append(refs, r)
		}
	}
	p, err := policy.NewSet(refs...)
	if err != nil {
		return op, err
	}
	op.Policies = p
	return op, nil
}
func RequestDay(at time.Time) (int64, time.Time, error) {
	if at.IsZero() {
		return 0, time.Time{}, ErrInvalidCommand
	}
	s := at.UTC().Unix()
	if s > math.MaxInt64-28800 || s < -28800 {
		return 0, time.Time{}, ErrInvalidCommand
	}
	day := (s + 28800) / 86400
	return day, time.Unix(day*86400-28800, 0).UTC(), nil
}
func increment(x int64) (int64, error) {
	if x < 0 || x == math.MaxInt64 {
		return 0, ErrCounterOverflow
	}
	return x + 1, nil
}

type Change struct {
	PlayerID                           identity.PlayerID
	Friendship, Request, Block, Notice bool
}

// Result carries typed post-commit projection/hint inputs. No wire or socket I/O.
type Result struct {
	Players playerpresentation.Batch
	Changes []Change
	Reloads []ReloadReference
	NoOp    bool
}

// CommandStore extends accepted foundation reads with only owner-local effects.
type CommandStore interface {
	Store
	CountActiveFriendsTx(context.Context, tx.Tx, identity.PlayerID) (int64, error)
	ActiveBlockTargetsTx(context.Context, tx.Tx, identity.PlayerID) ([]identity.PlayerID, error)
	TouchRootTx(context.Context, tx.Tx, Root, time.Time) error
	PutFriendshipTx(context.Context, tx.Tx, *Friendship, Friendship) error
	PutRequestTx(context.Context, tx.Tx, *FriendRequest, FriendRequest) error
	PutBlockTx(context.Context, tx.Tx, *Block, Block) error
	PutRequestEpochTx(context.Context, tx.Tx, *RequestEpoch, RequestEpoch) error
}
