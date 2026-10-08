// Package socialprojection composes typed owner reads in one caller transaction.
// It owns finite selection policy, not Player, Presence or relation truth.
package socialprojection

import (
	"errors"
	dm "gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"time"
	"unicode/utf8"
)

var (
	ErrInvalidRead     = errors.New("invalid social projection read")
	ErrAmbiguousSearch = errors.New("ambiguous legacy social search")
	ErrSearchSaturated = errors.New("exact-name social search saturated")
)

type ListKind uint8

const (
	Friend ListKind = iota + 1
	Request
	Blacklist
	Notice
)

type SearchMode uint8

const (
	Modern SearchMode = iota + 1
	Legacy
)

type SearchQuery struct {
	Mode SearchMode
	Term string
}

func (q SearchQuery) Validate() error {
	if (q.Mode != Modern && q.Mode != Legacy) || !utf8.ValidString(q.Term) || utf8.RuneCountInString(q.Term) > 20 {
		return ErrInvalidRead
	}
	return nil
}

type Player struct {
	Presentation    playerpresentation.Projected
	OutgoingPending bool
}
type Requested struct {
	Player   Player
	Relation socialrelation.FriendRequest
}
type Notified struct {
	Player Player
	Notice socialinbox.Notice
}

// ScanStats describes only this ephemeral attempt; it has no durable authority.
type ScanStats struct {
	Pivot              int64
	Fetched, Evaluated int
	Wrapped            bool
}
type Result struct {
	PrivateMessages          []dm.Projection
	ObservedAt               time.Time
	Friends, Blocks, Players []Player
	Requests                 []Requested
	Notices                  []Notified
	Scan                     ScanStats
}

func emptyResult() Result {
	return Result{Friends: []Player{}, Blocks: []Player{}, Players: []Player{}, Requests: []Requested{}, Notices: []Notified{}}
}
