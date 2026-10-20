package ranking

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"math"
	"sort"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

// These are private-server policies, not recovered original-server algorithms.
// New tuning requires a new policy identity; stored generations keep this one.
const GirlsPolicy = "C4C_PRIVATE_GIRLS_SERVER_RANKING_V1"
const AchievementPointPolicy = "C4F_PRIVATE_AP_SERVER_RANKING_V1"
const SkinsPolicy = "C4F_PRIVATE_SKINS_SERVER_RANKING_V1"
const ServerCohort = "I4_SERVER_ALL_PLAYERS_V1"
const BoardTitleDuration int64 = 604800
const BoardLockRank uint16 = 600

var ErrSnapshot = errors.New("ranking: invalid or unavailable canonical board snapshot")

// Board is one private weekly server board over one public-profile metric.
// Every board shares the cohort, ordering, UTC week and title duration.
type Board struct {
	Name, Policy, SourceOwner, SourcePolicy, SourceSemantics string
	FieldID, SubType, TitleType, TitledRanks                 int64
	// Titles[i] goes to rank i+1; the last title covers the remaining titled ranks.
	Titles []int64
	// RowValue is the rank_info row field NewRankWindow.initInfoText reads for
	// the rank table type: info_val for RankType.Power (2001), score for DEV_PARTNER_NUM.
	RowValue string
}

var GirlsBoard = Board{Name: "girls", Policy: GirlsPolicy, SourceOwner: "CharacterHero", SourcePolicy: "C4C_PRIVATE_CURRENT_ROSTER_V1", SourceSemantics: "CURRENT_DISTINCT_ORIGIN_HERO_PET_STARS_BEFORE_AWAKEN_V1", FieldID: 1001, SubType: 37, TitleType: 8, TitledRanks: 20, Titles: []int64{100059, 100060, 100061, 100062}, RowValue: "score"}

// AchievementPointBoard is rank 2001 "All girls' AP" (user Q3/Q4): metric 1007, No.1 title only.
var AchievementPointBoard = Board{Name: "achievement-point", Policy: AchievementPointPolicy, SourceOwner: "CharacterHero", SourcePolicy: "C4F_ALL_GIRLS_AP_V1", SourceSemantics: "CURRENT_SUM_OWNED_HERO_PUBLIC_FORCE_SELF_V1", FieldID: 1007, SubType: 8, TitleType: 1, TitledRanks: 1, Titles: []int64{100001}, RowValue: "info_val"}

// SkinsBoard is rank 38 (user Q4: the Girls ranking policy) over skin collection 1003.
var SkinsBoard = Board{Name: "skins", Policy: SkinsPolicy, SourceOwner: "PlayerDisplay", SourcePolicy: "C4F_SKIN_COLLECTION_V1", SourceSemantics: "CURRENT_SKIN_FRAME_AVATAR_COLLECTION_V1", FieldID: 1003, SubType: 38, TitleType: 9, TitledRanks: 20, Titles: []int64{100063, 100064, 100065, 100066}, RowValue: "score"}

var Boards = []Board{GirlsBoard, AchievementPointBoard, SkinsBoard}

func BoardOf(policy string) (Board, bool) {
	for _, b := range Boards {
		if b.Policy == policy {
			return b, true
		}
	}
	return Board{}, false
}
func BoardOfSubType(subtype int64) (Board, bool) {
	for _, b := range Boards {
		if b.SubType == subtype {
			return b, true
		}
	}
	return Board{}, false
}
func BoardOfTitle(title int64) (Board, bool) {
	for _, b := range Boards {
		if b.HasTitle(title) {
			return b, true
		}
	}
	return Board{}, false
}
func (b Board) HasTitle(title int64) bool {
	for _, v := range b.Titles {
		if v == title {
			return true
		}
	}
	return false
}
func (b Board) title(rank int64) int64 {
	if rank > int64(len(b.Titles)) {
		return b.Titles[len(b.Titles)-1]
	}
	return b.Titles[rank-1]
}

var ErrStale = errors.New("ranking: bound observation precedes durable state")

func digest(v any) string {
	b, e := json.Marshal(v)
	if e != nil {
		return ""
	}
	h := sha256.Sum256(b)
	return hex.EncodeToString(h[:])
}
func revision(s string) bool {
	b, e := hex.DecodeString(s)
	return e == nil && len(b) == 32 && hex.EncodeToString(b) == s
}

type ScoreRun struct {
	Score    int64
	Since    time.Time
	Revision string
}
type BoardRoot struct {
	Server                       identity.LogicalServerID
	Policy                       string
	NextGeneration, StateVersion int64
	CreatedAt, UpdatedAt         time.Time
	Runs                         map[identity.PlayerID]ScoreRun
}

func NewBoardRoot(b Board, server identity.LogicalServerID, at time.Time) (BoardRoot, error) {
	r := BoardRoot{Server: server, Policy: b.Policy, NextGeneration: 1, StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC(), Runs: map[identity.PlayerID]ScoreRun{}}
	return r, r.Validate()
}
func (r BoardRoot) Validate() error {
	if _, ok := BoardOf(r.Policy); !ok {
		return ErrSnapshot
	}
	if !r.Server.Valid() || r.NextGeneration < 1 || r.StateVersion < 1 || r.CreatedAt.Unix() <= 0 || r.UpdatedAt.Before(r.CreatedAt) || r.Runs == nil {
		return ErrSnapshot
	}
	for id, v := range r.Runs {
		if !id.Valid() || v.Score < 0 || v.Score > 9007199254740991 || v.Since.Before(r.CreatedAt) || v.Since.After(r.UpdatedAt) || !revision(v.Revision) {
			return ErrSnapshot
		}
	}
	return nil
}

// BoardMetric is retained canonical provenance, not a second count authority.
// The application obtains it only from the witnessed public-profile provider.
type BoardMetric struct {
	Player                                               identity.PlayerID
	Owner, Policy, Semantics, Revision, PopulationDigest string
	FieldID, Value, SourceVersion, PopulationVersion     int64
	ObservedAt                                           time.Time
}

func (m BoardMetric) valid(b Board, at time.Time, rev string) bool {
	return m.Player.Valid() && m.Owner == b.SourceOwner && m.Policy == b.SourcePolicy && m.Semantics == b.SourceSemantics && m.Revision == rev && m.FieldID == b.FieldID && m.Value >= 0 && m.Value <= 9007199254740991 && m.SourceVersion > 0 && m.PopulationVersion == m.SourceVersion && revision(m.PopulationDigest) && m.ObservedAt.Equal(at)
}

// Presentation is a snapshot of I4's derived directory; it never establishes a
// score, cohort membership, title eligibility or authoritative Conquer state.
type BoardPresentation struct {
	Player                                                identity.PlayerID
	Name                                                  string
	Level, AvatarID, FrameID, ConquerLevel, ConquerLoopID int64
}

func (p BoardPresentation) valid(id identity.PlayerID) bool {
	return p.Player == id && p.Level >= 1 && p.AvatarID >= 0 && p.FrameID >= 0 && p.ConquerLevel >= 0 && p.ConquerLoopID >= 0
}

type BoardInput struct {
	Metric  BoardMetric
	Display BoardPresentation
}
type BoardEntry struct {
	Metric     BoardMetric
	Display    BoardPresentation
	ScoreSince time.Time
}
type BoardSnapshot struct {
	Server               identity.LogicalServerID
	Policy, Revision     string
	Generation           int64
	OperationID          ids.UUID
	ObservedAt           time.Time
	Entries              []BoardEntry
	CohortDigest, Digest string
}

func (s BoardSnapshot) scope() Scope {
	return Scope{Kind: "SERVER", ServerID: int64(s.Server), Cohort: ServerCohort}
}
func (s BoardSnapshot) ordering() Profile {
	return Profile{ID: CurrentObserved, PolicyVersion: s.Policy, Generation: strconv.FormatInt(s.Generation, 10), TieBreak: StableID, Scope: s.scope(), ObservedAt: s.ObservedAt}
}
func (s BoardSnapshot) ordered() ([]Entry, error) {
	in := make([]Entry, 0, len(s.Entries))
	for _, v := range s.Entries {
		in = append(in, Entry{SubjectID: int64(v.Metric.Player), Score: v.Metric.Value, ScoreSince: v.ScoreSince, Basis: CurrentObserved, PolicyVersion: s.Policy, Generation: strconv.FormatInt(s.Generation, 10), Scope: s.scope()})
	}
	return Order(s.ordering(), in)
}
func (s BoardSnapshot) cohortDigest() string {
	ids := make([]int64, 0, len(s.Entries))
	for _, v := range s.Entries {
		ids = append(ids, int64(v.Metric.Player))
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	return digest(ids)
}
func (s BoardSnapshot) hash() string { s.Digest = ""; return digest(s) }
func (s BoardSnapshot) Validate() error {
	b, ok := BoardOf(s.Policy)
	if !ok || !s.Server.Valid() || !revision(s.Revision) || s.Generation < 1 || s.OperationID.IsZero() || s.ObservedAt.Unix() <= 0 || s.Entries == nil || !revision(s.Digest) || s.CohortDigest != s.cohortDigest() || s.Digest != s.hash() {
		return ErrSnapshot
	}
	for _, v := range s.Entries {
		if !v.Metric.valid(b, s.ObservedAt, s.Revision) || !v.Display.valid(v.Metric.Player) {
			return ErrSnapshot
		}
	}
	ordered, e := s.ordered()
	if e != nil {
		return e
	}
	for i, v := range ordered {
		if v.SubjectID != int64(s.Entries[i].Metric.Player) {
			return ErrSnapshot
		}
	}
	return nil
}

// BuildBoardSnapshot must receive the complete canonical I4 cohort. The caller
// checks cohort identity and obtains all metrics in one witnessed transaction.
// This function never manufactures historical first-reach timestamps.
func BuildBoardSnapshot(r BoardRoot, at time.Time, rev string, op ids.UUID, in []BoardInput) (BoardRoot, BoardSnapshot, error) {
	var out BoardSnapshot
	if r.Validate() != nil || !revision(rev) || op.IsZero() || at.Unix() <= 0 {
		return BoardRoot{}, out, ErrSnapshot
	}
	if at.Before(r.UpdatedAt) {
		return BoardRoot{}, out, ErrStale
	}
	if r.StateVersion == math.MaxInt64 || r.NextGeneration == math.MaxInt64 {
		return BoardRoot{}, out, ErrSnapshot
	}
	b, _ := BoardOf(r.Policy)
	out = BoardSnapshot{Server: r.Server, Policy: r.Policy, Revision: rev, Generation: r.NextGeneration, OperationID: op, ObservedAt: at.UTC(), Entries: []BoardEntry{}}
	next := r
	next.Runs = map[identity.PlayerID]ScoreRun{}
	byID := map[int64]BoardEntry{}
	for _, v := range in {
		m := v.Metric
		if !m.valid(b, at, rev) || !v.Display.valid(m.Player) {
			return BoardRoot{}, BoardSnapshot{}, ErrSnapshot
		}
		if _, dup := byID[int64(m.Player)]; dup {
			return BoardRoot{}, BoardSnapshot{}, ErrSnapshot
		}
		run := ScoreRun{Score: m.Value, Since: at.UTC(), Revision: rev}
		if old, ok := r.Runs[m.Player]; ok && old.Score == m.Value && old.Revision == rev {
			run.Since = old.Since
		}
		next.Runs[m.Player] = run
		v := BoardEntry{Metric: m, Display: v.Display, ScoreSince: run.Since}
		byID[int64(m.Player)] = v
		out.Entries = append(out.Entries, v)
	}
	ordered, e := out.ordered()
	if e != nil {
		return BoardRoot{}, BoardSnapshot{}, e
	}
	out.Entries = []BoardEntry{}
	for _, v := range ordered {
		out.Entries = append(out.Entries, byID[v.SubjectID])
	}
	out.CohortDigest = out.cohortDigest()
	out.Digest = out.hash()
	next.NextGeneration++
	next.StateVersion++
	next.UpdatedAt = at.UTC()
	if next.Validate() != nil || out.Validate() != nil {
		return BoardRoot{}, BoardSnapshot{}, ErrSnapshot
	}
	return next, out, nil
}

// BoardWeek is an explicit private UTC calendar. It does not reuse another
// mode's 05:00 reset or imply a recovered original leaderboard timetable.
func BoardWeek(at time.Time) (time.Time, error) {
	if at.Unix() <= 0 {
		return time.Time{}, ErrSnapshot
	}
	u := at.UTC()
	day := time.Date(u.Year(), u.Month(), u.Day(), 0, 0, 0, 0, time.UTC)
	offset := (int(u.Weekday()) + 6) % 7
	return day.AddDate(0, 0, -offset), nil
}

type BoardAward struct {
	Player        identity.PlayerID
	Rank, TitleID int64
	OriginKey     string
	StartsAt      time.Time
	EndTime       int64
}

func (s BoardSnapshot) Awards() ([]BoardAward, error) {
	if e := s.Validate(); e != nil {
		return nil, e
	}
	if s.ObservedAt.Unix() > 9007199254740991-BoardTitleDuration {
		return nil, ErrSnapshot
	}
	week, e := BoardWeek(s.ObservedAt)
	if e != nil {
		return nil, e
	}
	b, _ := BoardOf(s.Policy)
	out := []BoardAward{}
	for i, v := range s.Entries {
		rank := int64(i + 1)
		if rank > b.TitledRanks || v.Metric.Value == 0 {
			continue
		}
		title := b.title(rank)
		key := "ranking:" + s.Policy + ":" + strconv.FormatInt(int64(s.Server), 10) + ":" + week.Format("2006-01-02") + ":" + strconv.FormatInt(int64(v.Metric.Player), 10)
		out = append(out, BoardAward{Player: v.Metric.Player, Rank: rank, TitleID: title, OriginKey: key, StartsAt: s.ObservedAt, EndTime: s.ObservedAt.Unix() + BoardTitleDuration})
	}
	return out, nil
}
