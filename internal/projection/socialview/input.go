package socialview

import (
	"errors"
	"time"
	"unicode/utf8"
)

// Inputs are ephemeral presentation values assembled by the composition edge.
// No owner reader, actor authority, relation source or selection policy enters
// this package, preserving the established I0 layer direction.
var ErrInvalidRead = errors.New("invalid social view input")

type ListKind uint8

const (
	FriendList ListKind = iota + 1
	RequestList
	BlacklistList
	NoticeList
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

type Minimal struct {
	PlayerID                                                                int64
	Name                                                                    string
	Level, AvatarID, AvatarFrameID, ConquerLevel, ConquerLoopID, PlayerType int64
}
type Presence struct {
	IsOnline                      bool
	LastSeenAt, LatestConnectedAt *time.Time
}
type Player struct {
	Minimal         Minimal
	Presence        Presence
	OutgoingPending bool
}
type Requested struct {
	Player  Player
	Message string
	At      time.Time
}
type Notified struct {
	Player Player
	ID     int64
	Type   int16
	At     time.Time
}
type Result struct {
	ObservedAt               time.Time
	Friends, Blocks, Players []Player
	Requests                 []Requested
	Notices                  []Notified
}
