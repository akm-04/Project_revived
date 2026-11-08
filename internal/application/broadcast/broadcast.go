// Package broadcast owns the lobby scrolling announcements the stock client
// receives on SYSTEM_BROADCAST (4101) and ACTIVITY_BROADCAST (4096).
package broadcast

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Route carries one queued announcement id. The realtime handler reads and
// removes the row; the wakeup reference itself carries no gameplay value.
const Route = "broadcast.announce.v1"

const (
	SystemMID   uint16 = 4101
	ActivityMID uint16 = 4096

	SXHero          int64 = 3001
	ArenaWins       int64 = 3002
	ArenaTop3       int64 = 3003
	Married         int64 = 3004
	ConquerSchool   int64 = 3005
	TreasureDiamond int64 = 3006
	GetDormKey      int64 = 3008
	GetDormKeyNew   int64 = 3009
	UnlockCG        int64 = 3010
	DormExpand      int64 = 3011
	SuperPartner    int64 = 3012
)

var ErrInvalidMessage = errors.New("invalid broadcast message")

// Fields are the source-named numeric arguments each announce row formats.
// The handler sends only the fields the client callback for MsgType indexes.
type Fields struct {
	Region        int64 `json:"region,omitempty"`
	HeroTableID   int64 `json:"hero_table_id,omitempty"`
	KeepWinTimes  int64 `json:"keep_win_times,omitempty"`
	Rank          int64 `json:"rank,omitempty"`
	ConquerLoopID int64 `json:"conquer_loop_id,omitempty"`
	ConquerLev    int64 `json:"conquer_lev,omitempty"`
	CrystalAward  int64 `json:"crystal_award,omitempty"`
	KeyItem       int64 `json:"key_item,omitempty"`
	CGID          int64 `json:"cg_id,omitempty"`
	TableID       int64 `json:"table_id,omitempty"`
}

type Message struct {
	MID     uint16
	MsgType int64
	Server  identity.LogicalServerID
	Player  identity.PlayerID
	Enemy   identity.PlayerID
	Fields  Fields
}

func (m Message) Validate() error {
	if !m.Server.Valid() || !m.Player.Valid() || m.Fields.Region < 0 {
		return ErrInvalidMessage
	}
	switch m.MsgType {
	case SXHero:
		return requireSystem(m, m.Fields.HeroTableID > 0)
	case ArenaWins:
		return requireSystem(m, m.Fields.KeepWinTimes > 0)
	case ArenaTop3:
		return requireSystem(m, m.Enemy.Valid() && m.Fields.Rank > 0)
	case Married:
		return requireSystem(m, m.Fields.HeroTableID > 0)
	case ConquerSchool:
		return requireSystem(m, m.Fields.Region > 0 && m.Fields.ConquerLoopID > 0 && m.Fields.ConquerLev > 0)
	case TreasureDiamond:
		return requireSystem(m, m.Fields.CrystalAward > 0)
	case GetDormKey, GetDormKeyNew:
		return requireSystem(m, m.Fields.KeyItem > 0)
	case UnlockCG:
		return requireSystem(m, m.Fields.CGID > 0)
	case SuperPartner:
		return requireSystem(m, m.Fields.TableID > 0)
	case DormExpand:
		if m.MID != ActivityMID {
			return ErrInvalidMessage
		}
		return nil
	default:
		return ErrInvalidMessage
	}
}

func requireSystem(m Message, valid bool) error {
	if m.MID != SystemMID || !valid {
		return ErrInvalidMessage
	}
	return nil
}

// Emitter queues one announcement through the caller's gameplay transaction.
// A nil Emitter means the owning feature has no broadcast wiring.
type Emitter interface {
	EmitTx(context.Context, tx.Tx, Message) error
}
