package guildcore

import (
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
)

// I6C lock ranks are frozen by Pass498. PlayerRootRank is owned by I4 and must
// remain between Guild root and GuildMembership. I5 ranks begin later (mail
// namespace 610; economy/progression/scalar 700/710/720).
const (
	LockRankAllocator   uint16 = 300
	LockRankGuild       uint16 = 310
	LockRankMembership  uint16 = 320
	LockRankApplication uint16 = 330
	LockRankInvite      uint16 = 340
	LockRankAudit       uint16 = 350
)

var ErrInvalidGuildLockPlan = errors.New("invalid guild lock plan")

type LockPlan struct{ Keys []lockkey.Key }

// NewLockPlan constructs the complete known Guild/I4 portion of a shared
// transaction before owner mutation. Dynamic child generations are fenced by
// their parent Guild/PlayerRoot keys; I5-owned keys are entered only by typed
// I5 ports after this lower-rank plan has been exhausted.
func NewLockPlan(server identity.LogicalServerID, gid guild.ID, players []identity.PlayerID, includeAllocator bool, applicationPlayers, invitePlayers []identity.PlayerID) (LockPlan, error) {
	if !server.Valid() || (gid != 0 && int64(gid)/1_000_000 != int64(server)) {
		return LockPlan{}, ErrInvalidGuildLockPlan
	}
	var keys []lockkey.Key
	add := func(rank uint16, owner string, id lockkey.Identity) error {
		k, err := lockkey.New(rank, owner, id)
		if err != nil {
			return err
		}
		keys = append(keys, k)
		return nil
	}
	if includeAllocator {
		if err := add(LockRankAllocator, "guild.allocator", lockkey.Int64(int64(server))); err != nil {
			return LockPlan{}, err
		}
	}
	if gid != 0 {
		if err := add(LockRankGuild, "guild.root", lockkey.Int64(int64(gid))); err != nil {
			return LockPlan{}, err
		}
	}
	pids, err := playerroot.CanonicalPlayerIDs(players)
	if err != nil && len(players) > 0 {
		return LockPlan{}, err
	}
	for _, pid := range pids {
		k, err := playerroot.LockKey(pid)
		if err != nil {
			return LockPlan{}, err
		}
		keys = append(keys, k)
	}
	for _, pid := range pids {
		if err := add(LockRankMembership, "guild.membership", lockkey.Int64(int64(pid))); err != nil {
			return LockPlan{}, err
		}
	}
	apps, err := playerroot.CanonicalPlayerIDs(applicationPlayers)
	if err != nil && len(applicationPlayers) > 0 {
		return LockPlan{}, err
	}
	for _, pid := range apps {
		if gid == 0 {
			return LockPlan{}, ErrInvalidGuildLockPlan
		}
		if err := add(LockRankApplication, "guild.application", lockkey.String(fmt.Sprintf("%d:%d", gid, pid))); err != nil {
			return LockPlan{}, err
		}
	}
	invs, err := playerroot.CanonicalPlayerIDs(invitePlayers)
	if err != nil && len(invitePlayers) > 0 {
		return LockPlan{}, err
	}
	for _, pid := range invs {
		if gid == 0 {
			return LockPlan{}, ErrInvalidGuildLockPlan
		}
		if err := add(LockRankInvite, "guild.invite", lockkey.String(fmt.Sprintf("%d:%d", gid, pid))); err != nil {
			return LockPlan{}, err
		}
	}
	if gid != 0 {
		if err := add(LockRankAudit, "guild.audit-ledger", lockkey.Int64(int64(gid))); err != nil {
			return LockPlan{}, err
		}
	}
	canonical, err := lockkey.Canonical(keys)
	if err != nil {
		return LockPlan{}, err
	}
	return LockPlan{Keys: canonical}, nil
}
