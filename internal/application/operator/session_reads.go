package operator

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	defaultOnlineLimit = 50
	maxOnlineLimit     = 200
)

// OnlineSessionFilter is the bounded session.online query.
type OnlineSessionFilter struct {
	ServerID *int64
	After    string
	Limit    int
}

// OnlineSession is one live player session from the session owner. Online is
// false for a live session whose device stopped polling.
type OnlineSession struct {
	SessionID  string
	PlayerID   int64
	ServerID   int64
	StartedAt  time.Time
	LastSeenAt time.Time
	Online     bool
}

// OnlineSessionRow is one session.online row.
type OnlineSessionRow struct {
	PlayerID   int64     `json:"player_id"`
	Name       string    `json:"name"`
	ServerID   int64     `json:"server_id"`
	StartedAt  time.Time `json:"started_at"`
	LastSeenAt time.Time `json:"last_seen_at"`
	Online     bool      `json:"online"`
}

// OnlineSessionPage is the session.online reply, session id ascending.
type OnlineSessionPage struct {
	Sessions  []OnlineSessionRow `json:"sessions"`
	NextAfter string             `json:"next_after,omitempty"`
}

// OnlineSessionReader is identitylifecycle's live-session read port.
type OnlineSessionReader interface {
	ListOnlineSessionsTx(context.Context, tx.Queryer, OnlineSessionFilter) ([]OnlineSession, error)
}

// PlayerNames is I4's bounded player-name read port.
type PlayerNames interface {
	PlayerNamesTx(context.Context, tx.Queryer, []int64) (map[int64]string, error)
}

// SessionReadService answers session.online in one read-only transaction. The
// session owner supplies player id and timestamps; I4 supplies the name.
type SessionReadService struct {
	Runner     tx.Runner
	Operations operation.Factory
	Sessions   OnlineSessionReader
	Players    PlayerNames
}

func (s SessionReadService) Online(ctx context.Context, filter OnlineSessionFilter) (OnlineSessionPage, error) {
	if s.Sessions == nil || s.Players == nil || s.Runner.DB == nil {
		return OnlineSessionPage{}, ErrUnavailable
	}
	if filter.Limit == 0 {
		filter.Limit = defaultOnlineLimit
	}
	if filter.Limit < 1 || filter.Limit > maxOnlineLimit {
		return OnlineSessionPage{}, Refuse(CodeReadInvalid, fmt.Sprintf("limit must be between 1 and %d", maxOnlineLimit), nil)
	}
	if filter.ServerID != nil && *filter.ServerID <= 0 {
		return OnlineSessionPage{}, Refuse(CodeReadInvalid, "server_id must be a positive id", nil)
	}
	if filter.After != "" {
		if _, err := ids.ParseUUID(filter.After); err != nil {
			return OnlineSessionPage{}, Refuse(CodeReadInvalid, "after must be the session id of the previous page", nil)
		}
	}
	requested := filter.Limit
	filter.Limit = requested + 1
	current, err := s.Operations.New(policy.Set{})
	if err != nil {
		return OnlineSessionPage{}, err
	}
	var rows []OnlineSession
	var names map[int64]string
	_, err = s.Runner.Run(ctx, current, readProfile("operator-session-online-v1"), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, readErr := s.Sessions.ListOnlineSessionsTx(ctx, scope.Tx, filter)
		if readErr != nil {
			return readErr
		}
		rows = loaded
		ids := make([]int64, 0, len(rows))
		for _, row := range rows {
			ids = append(ids, row.PlayerID)
		}
		loadedNames, nameErr := s.Players.PlayerNamesTx(ctx, scope.Tx, ids)
		if nameErr != nil {
			return nameErr
		}
		names = loadedNames
		return nil
	})
	if err != nil {
		return OnlineSessionPage{}, err
	}
	page := OnlineSessionPage{Sessions: make([]OnlineSessionRow, 0, min(len(rows), requested))}
	if len(rows) > requested {
		rows = rows[:requested]
		page.NextAfter = rows[len(rows)-1].SessionID
	}
	for _, row := range rows {
		page.Sessions = append(page.Sessions, OnlineSessionRow{
			PlayerID: row.PlayerID, Name: names[row.PlayerID], ServerID: row.ServerID,
			StartedAt: row.StartedAt.UTC(), LastSeenAt: row.LastSeenAt.UTC(), Online: row.Online,
		})
	}
	return page, nil
}
