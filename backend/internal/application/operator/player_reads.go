package operator

import (
	"context"
	"fmt"
	"time"
	"unicode/utf8"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	CodePlayerUnknown = "OPERATOR_PLAYER_UNKNOWN"

	defaultPlayerFindLimit = 20
	maxPlayerFindLimit     = 50
)

// PlayerRow is one player.find row.
type PlayerRow struct {
	PlayerID        int64  `json:"player_id"`
	AccountUID      string `json:"account_uid"`
	Name            string `json:"name"`
	Level           int64  `json:"level"`
	LogicalServerID int64  `json:"logical_server_id"`
}

// PlayerFindPage is the player.find reply.
type PlayerFindPage struct {
	Players   []PlayerRow `json:"players"`
	Truncated bool        `json:"truncated"`
}

// PlayerSummary is the player.summary reply: identity facts from I4 and the
// wallet facts from I5.
type PlayerSummary struct {
	PlayerRow
	VIPLevel  int64      `json:"vip_level"`
	Gold      int64      `json:"gold"`
	Crystals  int64      `json:"crystals"`
	CreatedAt time.Time  `json:"created_at"`
	LastLogin *time.Time `json:"last_login"`
}

// PlayerReadService answers the bounded player reads in one read-only
// transaction through the owner ports.
type PlayerReadService struct {
	Runner     tx.Runner
	Operations operation.Factory
	Directory  playerdirectory.OperatorReader
	Wallet     appi5.OperatorWalletReader
	Clock      func() time.Time
}

func (s PlayerReadService) now() time.Time {
	if s.Clock == nil {
		return time.Now().UTC()
	}
	return s.Clock().UTC()
}

// Find applies the uid/name-prefix/server filter. At least one of uid and name
// prefix is required so the read cannot enumerate the directory.
func (s PlayerReadService) Find(ctx context.Context, filter playerdirectory.OperatorFind) (PlayerFindPage, error) {
	if s.Directory == nil || s.Runner.DB == nil {
		return PlayerFindPage{}, ErrUnavailable
	}
	if err := validatePlayerFind(filter); err != nil {
		return PlayerFindPage{}, err
	}
	if filter.Limit == 0 {
		filter.Limit = defaultPlayerFindLimit
	}
	filter.Limit++
	var rows []playerdirectory.OperatorPlayer
	current, err := s.Operations.New(policy.Set{})
	if err != nil {
		return PlayerFindPage{}, err
	}
	_, err = s.Runner.Run(ctx, current, readProfile("operator-player-find-v1"), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, readErr := s.Directory.FindPlayersTx(ctx, scope.Tx, filter)
		if readErr == nil {
			rows = loaded
		}
		return readErr
	})
	if err != nil {
		return PlayerFindPage{}, err
	}
	page := PlayerFindPage{Players: make([]PlayerRow, 0, len(rows))}
	if len(rows) > filter.Limit-1 {
		rows = rows[:filter.Limit-1]
		page.Truncated = true
	}
	for _, row := range rows {
		page.Players = append(page.Players, rowOf(row))
	}
	return page, nil
}

// Summary reads one player's identity and wallet facts.
func (s PlayerReadService) Summary(ctx context.Context, playerID int64) (PlayerSummary, error) {
	if s.Directory == nil || s.Wallet == nil || s.Runner.DB == nil {
		return PlayerSummary{}, ErrUnavailable
	}
	if playerID <= 0 {
		return PlayerSummary{}, Refuse(CodeReadInvalid, "player_id must be a positive id", nil)
	}
	at := s.now()
	var summary PlayerSummary
	current, err := s.Operations.New(policy.Set{})
	if err != nil {
		return PlayerSummary{}, err
	}
	found := false
	_, err = s.Runner.Run(ctx, current, readProfile("operator-player-summary-v1"), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		player, exists, readErr := s.Directory.OperatorPlayerTx(ctx, scope.Tx, identity.PlayerID(playerID))
		if readErr != nil || !exists {
			return readErr
		}
		wallet, walletErr := s.Wallet.OperatorWalletTx(ctx, scope.Tx, identity.PlayerID(playerID), at)
		if walletErr != nil {
			return walletErr
		}
		summary = PlayerSummary{PlayerRow: rowOf(player), VIPLevel: wallet.VIPLevel, Gold: wallet.Gold, Crystals: wallet.Crystals, CreatedAt: player.CreatedAt, LastLogin: player.LastLoginAt}
		found = true
		return nil
	})
	if err != nil {
		return PlayerSummary{}, err
	}
	if !found {
		return PlayerSummary{}, Refuse(CodePlayerUnknown, "the player does not exist", map[string]int64{"player_id": playerID})
	}
	return summary, nil
}

func validatePlayerFind(filter playerdirectory.OperatorFind) error {
	if filter.UID == "" && filter.NamePrefix == "" {
		return Refuse(CodeReadInvalid, "uid or name_prefix is required", nil)
	}
	if utf8.RuneCountInString(filter.UID) > 128 {
		return Refuse(CodeReadInvalid, "uid is too long", nil)
	}
	if utf8.RuneCountInString(filter.NamePrefix) > 64 {
		return Refuse(CodeReadInvalid, "name_prefix is too long", nil)
	}
	if filter.ServerID != nil && *filter.ServerID <= 0 {
		return Refuse(CodeReadInvalid, "server_id must be a positive id", nil)
	}
	if filter.Limit < 0 || filter.Limit > maxPlayerFindLimit {
		return Refuse(CodeReadInvalid, fmt.Sprintf("limit must be between 1 and %d", maxPlayerFindLimit), nil)
	}
	return nil
}

func rowOf(player playerdirectory.OperatorPlayer) PlayerRow {
	return PlayerRow{PlayerID: int64(player.PlayerID), AccountUID: player.AccountUID, Name: player.Name, Level: player.Level, LogicalServerID: int64(player.LogicalServerID)}
}
