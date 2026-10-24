package championsleague

import (
	"time"
)

type EnemyView struct {
	Player Player
	Face   Face
	Rank   int64
	Heroes []map[string]any
	Pet    map[string]any
}
type InfoView struct {
	Player  Player
	Rank    int64
	At      time.Time
	Active  bool
	Final   Placement
	Defense EnemyView
	Enemies []EnemyView
}
type Item struct {
	TableID int64 `json:"table_id"`
	ItemNum int64 `json:"item_num"`
}
type Reply struct {
	Kind    string
	Info    InfoView
	Enemy   EnemyView
	Match   Match
	Awards  []Item
	Records []Match
	Report  []byte
	Honor   []SettlementRow
}
