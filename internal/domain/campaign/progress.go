package campaign

import (
	"encoding/json"
	"fmt"

	"gxb.local/backend/v2/internal/domain/modes"
)

// NodeState is one played node; a node without a state is unplayed (star 0).
type NodeState struct {
	CampaignID int64
	Star       int64
	// Wins and Resets are the Super daily_limit spend and elite resets of the game day (F7).
	Wins        modes.Counter
	Resets      modes.Counter
	PartnerDrop bool
}

type Progress struct {
	Nodes         map[int64]NodeState
	NormalBonusID int64
	SuperBonusID  int64
}

func (p Progress) State(id int64) NodeState {
	if s, ok := p.Nodes[id]; ok {
		return s
	}
	return NodeState{CampaignID: id}
}

func (p Progress) with(s NodeState) Progress {
	nodes := make(map[int64]NodeState, len(p.Nodes)+1)
	for id, n := range p.Nodes {
		nodes[id] = n
	}
	nodes[s.CampaignID] = s
	p.Nodes = nodes
	return p
}

// Record is the player's campaign state, the drops frozen by the open FIGHT, and the
// last settled FIGHT_RESULT, which a duplicate 114 of the same generation replays (F4e).
type Record struct {
	Progress          Progress
	PendingGeneration string
	PendingItems      []Item
	LastGeneration    string
	LastResult        json.RawMessage
	StateVersion      int64
}

// Opened is the opened prefix of a Normal or Super chain: every cleared node and
// the first uncleared one (C1, C3). Super rows are visible once function 31 is
// open and advance by Super clears; the related Normal clear gates the fight, not
// the row (V1 Pass128, D104).
func (c Catalog) Opened(p Progress, kind int64, superOpen bool) []int64 {
	// shortcut: Challenge rows stay empty until I9-3D projects its branching graph.
	if kind == Challenge || kind == Super && !superOpen {
		return nil
	}
	var out []int64
	for _, id := range c.Chain(kind) {
		out = append(out, id)
		if p.State(id).Star == 0 {
			break
		}
	}
	return out
}

func (c Catalog) isOpened(p Progress, kind, id int64, superOpen bool) bool {
	for _, opened := range c.Opened(p, kind, superOpen) {
		if opened == id {
			return true
		}
	}
	return false
}

// Remaining is the wire daily_limit: Super spends its source limit per game day;
// Normal has no limit and answers the source value floored at 0 (V1).
func (c Catalog) Remaining(p Progress, n Node, day int64) int64 {
	if n.Type != Super {
		return max(0, n.DailyLimit)
	}
	return n.DailyLimit - p.State(n.ID).Wins.In(day).Used
}

// Admit applies the 113 node guards of MapDetailWindow (F6): wire type, opened,
// level, and for Super the related Normal clear and the daily limit.
func (c Catalog) Admit(p Progress, kind, id, level, day int64, superOpen bool) (Node, error) {
	n, ok := c.Node(id)
	if !ok || n.Type != kind || kind != Normal && kind != Super {
		return Node{}, fmt.Errorf("%w: campaign %d type %d", ErrInvalid, id, kind)
	}
	if !c.isOpened(p, kind, id, superOpen) || level < n.OpenLevel {
		return Node{}, fmt.Errorf("%w: campaign %d closed", ErrRefused, id)
	}
	if kind == Super && (p.State(n.Related).Star == 0 || c.Remaining(p, n, day) <= 0) {
		return Node{}, fmt.Errorf("%w: super campaign %d unavailable", ErrRefused, id)
	}
	return n, nil
}

// BattleBox is the dropbox a fight draws from: init_dropbox on the first clear,
// dropbox on repeats (C6).
func (n Node) BattleBox(p Progress) int64 {
	if p.State(n.ID).Star == 0 {
		return n.FirstBox
	}
	return n.RepeatBox
}
