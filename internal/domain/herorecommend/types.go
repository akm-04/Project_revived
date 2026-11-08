// Package herorecommend owns the derived Hero Recommendation snapshot and the
// private policy that turns bounded owner surfaces into recommendation rows.
// The six source modes remain the only gameplay authority.
package herorecommend

import (
	"encoding/json"
	"errors"
	"time"
)

const (
	PolicyID = "I9_10_HERO_RECOMMEND_PRIVATE_POLICY_V1"
	Schema   = 1

	TopFloor   int64 = 1
	OneOnOne   int64 = 2
	Arena      int64 = 3
	Fantasy    int64 = 4
	GuildEvent int64 = 5
	Champion   int64 = 6
)

// Private caps. Every source surface is bounded; these are the PRIVATE_POLICY
// caps recorded in docs/i9/I9_HERO_RECOMMEND_PRIVATE_POLICY_V1.json.
const (
	MaxSourceScan       = 100
	MaxSourceFormations = 20
	MaxCategoryHeroes   = 50
	MaxTotalHeroes      = 50
	MaxForceRows        = 50
	MaxDetailFormations = 3
	MaxCandidateOwners  = 64
)

var ErrUnavailable = errors.New("herorecommend: unavailable provider")
var ErrRefused = errors.New("herorecommend: refused")

// Popularity is one source-observed hero frequency. TableID is set when the
// source already stores a hero table id (Arena); otherwise PartnerID is the
// owner-local partner id that the producer resolves through that player's
// stock roster.
type Popularity struct {
	PlayerID  int64 `json:"player_id"`
	PartnerID int64 `json:"partner_id"`
	TableID   int64 `json:"table_id"`
	Score     int64 `json:"score"`
}

// Formation is one source formation. PartnerIDs is the stored team order;
// TableIDs is set instead when the source already stores table ids. Weight is
// the source performance signal used to order formations.
type Formation struct {
	PlayerID   int64
	PartnerIDs []int64
	TableIDs   []int64
	PetID      int64
	ParadiseID int64
	ChapterID  int64
	Weight     int64
}

// Source is one owner's bounded recommendation surface.
type Source struct {
	Popularity []Popularity
	Formations []Formation
}

// PlayerCard is the stock player face used by the detail and rank windows.
type PlayerCard struct {
	PlayerID      int64  `json:"player_id"`
	Name          string `json:"player_name"`
	Level         int64  `json:"lev"`
	ConquerLevel  int64  `json:"conquer_lev"`
	ConquerLoopID int64  `json:"conquer_loop_id"`
	AvatarID      int64  `json:"avatar_id"`
	AvatarFrameID int64  `json:"avatar_frame_id"`
	Region        int64  `json:"region"`
	GuildID       int64  `json:"guild_id"`
	GuildName     string `json:"guild_name,omitempty"`
}

// ForceRow is one owner on the per-hero force board.
type ForceRow struct {
	Player PlayerCard `json:"player"`
	Force  int64      `json:"force"`
}

// Overview is the 2497 body.
type Overview struct {
	SubRankList   map[string][]int64 `json:"sub_rank_list"`
	TotalRankList []map[string]any   `json:"total_rank_list"`
}

// Detail is the per-hero 2498 body without viewer-specific fields, plus the
// stored force board used by 2499. Formations already have the client's
// category-dependent shape: a single object except categories 4 and 5, which
// are arrays.
type Detail struct {
	Score      int64          `json:"recommend_score"`
	TopPlayer  PlayerCard     `json:"top_player_info"`
	TopHero    map[string]any `json:"top_hero_info"`
	Formations map[string]any `json:"recommend_formations"`
	ForceRows  []ForceRow     `json:"force_rows"`
}

// Snapshot is one logical server's weekly derived recommendation state.
type Snapshot struct {
	Schema     int               `json:"schema"`
	Server     int64             `json:"server"`
	Generation int64             `json:"generation"`
	Revision   string            `json:"revision"`
	ObservedAt time.Time         `json:"observed_at"`
	Digest     string            `json:"digest"`
	Overview   Overview          `json:"overview"`
	Details    map[string]Detail `json:"details"`
}

func (s Snapshot) Validate() error {
	if s.Schema != Schema || s.Server <= 0 || s.Generation <= 0 || s.ObservedAt.IsZero() || s.Digest == "" {
		return ErrUnavailable
	}
	return nil
}

// Encode returns the persisted payload. Digest is filled by the caller.
func (s Snapshot) Encode() ([]byte, error) { return json.Marshal(s) }
