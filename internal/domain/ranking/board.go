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
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/ids"
)

// These are private-server policies, not recovered original-server algorithms.
// New tuning requires a new policy identity; stored generations keep this one.
const GirlsPolicy = "C4C_PRIVATE_GIRLS_SERVER_RANKING_V1"
const AchievementPointPolicy = "C4F_PRIVATE_AP_SERVER_RANKING_V1"
const SkinsPolicy = "C4F_PRIVATE_SKINS_SERVER_RANKING_V1"
const DormComfortPolicy = "I9_10C_PRIVATE_DORM_COMFORT_RANKING_V1"
const DormComfortSourcePolicy = "I9_10C_PRIVATE_DORM_COMFORT_FACT_V1"
const DormComfortSemantics = "CURRENT_SUM_OWNED_ROOMS_INCLUDING_LOUNGE_V1"
const StarCountPolicy = "I9_10D_PRIVATE_STAR_COUNT_SERVER_RANKING_V1"
const AwakenCountPolicy = "I9_10D_PRIVATE_AWAKEN_COUNT_SERVER_RANKING_V1"
const TopForcePolicy = "I9_10E_PRIVATE_TOP_FIVE_FORCE_SERVER_RANKING_V1"
const TopForceSourcePolicy = "I9_10E_PRIVATE_TOP_FIVE_FORCE_V1"
const TopForceSemantics = "CURRENT_SUM_TOP_FIVE_OWNED_HERO_PUBLIC_FORCE_SELF_V1"
const RosterMetricSourcePolicy = "C4C_PRIVATE_CURRENT_ROSTER_V1"
const RosterMetricSourceSemantics = "CURRENT_DISTINCT_ORIGIN_HERO_PET_STARS_BEFORE_AWAKEN_V1"
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
	// Limit truncates the published top entries; zero publishes the whole cohort.
	Limit int64
}

var GirlsBoard = Board{Name: "girls", Policy: GirlsPolicy, SourceOwner: "CharacterHero", SourcePolicy: "C4C_PRIVATE_CURRENT_ROSTER_V1", SourceSemantics: "CURRENT_DISTINCT_ORIGIN_HERO_PET_STARS_BEFORE_AWAKEN_V1", FieldID: 1001, SubType: 37, TitleType: 8, TitledRanks: 20, Titles: []int64{100059, 100060, 100061, 100062}, RowValue: "score"}

// AchievementPointBoard is rank 2001 "All girls' AP" (user Q3/Q4): metric 1007, No.1 title only.
var AchievementPointBoard = Board{Name: "achievement-point", Policy: AchievementPointPolicy, SourceOwner: "CharacterHero", SourcePolicy: "C4F_ALL_GIRLS_AP_V1", SourceSemantics: "CURRENT_SUM_OWNED_HERO_PUBLIC_FORCE_SELF_V1", FieldID: 1007, SubType: 8, TitleType: 1, TitledRanks: 1, Titles: []int64{100001}, RowValue: "info_val"}

// SkinsBoard is rank 38 (user Q4: the Girls ranking policy) over skin collection 1003.
var SkinsBoard = Board{Name: "skins", Policy: SkinsPolicy, SourceOwner: "PlayerDisplay", SourcePolicy: "C4F_SKIN_COLLECTION_V1", SourceSemantics: "CURRENT_SKIN_FRAME_AVATAR_COLLECTION_V1", FieldID: 1003, SubType: 38, TitleType: 9, TitledRanks: 20, Titles: []int64{100063, 100064, 100065, 100066}, RowValue: "score"}

// DormComfortBoard is rank 301 subtype 34. The score owner is DormHouse; this
// board only orders the typed facts. It grants no titles.
var DormComfortBoard = Board{Name: "dorm-comfort", Policy: DormComfortPolicy, SourceOwner: "DormHouse", SourcePolicy: DormComfortSourcePolicy, SourceSemantics: DormComfortSemantics, FieldID: 2001, SubType: 34, Titles: []int64{}, RowValue: "comfort", Limit: 100}

// StarCountBoard is rank 2003 "BG Star Rank" (subtype 10): the sum of the
// current owned heroes' stars. It ranks the existing roster metric 1008.
var StarCountBoard = Board{Name: "star-count", Policy: StarCountPolicy, SourceOwner: "CharacterHero", SourcePolicy: RosterMetricSourcePolicy, SourceSemantics: RosterMetricSourceSemantics, FieldID: 1008, SubType: 10, RowValue: "info_val"}

// AwakenCountBoard is rank 5001 "Awaken" (subtype 12): the count of owned
// heroes that have awakened. It ranks the existing roster metric 1009.
var AwakenCountBoard = Board{Name: "awaken-count", Policy: AwakenCountPolicy, SourceOwner: "CharacterHero", SourcePolicy: RosterMetricSourcePolicy, SourceSemantics: RosterMetricSourceSemantics, FieldID: 1009, SubType: 12, RowValue: "info_val"}

// TopForceBoard is rank 2002 "TF AP Rank" (subtype 9): the total public force
// of the five strongest owned heroes. The count is a private tunable in
// docs/i9/I9_10E_TOP_FIVE_FORCE_POLICY_V1.json.
var TopForceBoard = Board{Name: "top-five-force", Policy: TopForcePolicy, SourceOwner: "CharacterHero", SourcePolicy: TopForceSourcePolicy, SourceSemantics: TopForceSemantics, FieldID: 1012, SubType: 9, RowValue: "info_val"}

var Boards = []Board{GirlsBoard, AchievementPointBoard, SkinsBoard, DormComfortBoard, StarCountBoard, AwakenCountBoard, TopForceBoard}

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

// ServedEmptySubTypes are the client's visible rank tabs whose owner is not
// delivered. They answer a shaped empty rank_list and never a score (N8 user
// ruling 2026-11-16); no score source exists for them.
var ServedEmptySubTypes = []int64{5, 13, 14, 28, 29, 35, 36, 40, 41}

func IsServedEmptySubType(subtype int64) bool {
	for _, served := range ServedEmptySubTypes {
		if served == subtype {
			return true
		}
	}
	return false
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
	// Runs is legacy read-only state: old roots seed the one-time backfill.
	// New roots leave it empty and nothing writes score runs here any more.
	Runs map[identity.PlayerID]ScoreRun `json:"Runs,omitempty"`
}

func NewBoardRoot(b Board, server identity.LogicalServerID, at time.Time) (BoardRoot, error) {
	r := BoardRoot{Server: server, Policy: b.Policy, NextGeneration: 1, StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC()}
	return r, r.Validate()
}
func (r BoardRoot) Validate() error {
	if _, ok := BoardOf(r.Policy); !ok {
		return ErrSnapshot
	}
	if !r.Server.Valid() || r.NextGeneration < 1 || r.StateVersion < 1 || r.CreatedAt.Unix() <= 0 || r.UpdatedAt.Before(r.CreatedAt) {
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

// ScoreRow is one durable board score. Server is the board scope; the writer
// fills it on the first row because NextScoreRow only knows the metric.
type ScoreRow struct {
	Policy     string
	Server     identity.LogicalServerID
	Player     identity.PlayerID
	Score      int64
	ScoreSince time.Time
	Revision   string
	Metric     BoardMetric
	UpdatedAt  time.Time
}

func (r ScoreRow) Validate() error {
	b, ok := BoardOf(r.Policy)
	if !ok || !r.Server.Valid() || !r.Player.Valid() || r.Score < 0 || r.Score > 9007199254740991 || !revision(r.Revision) || r.ScoreSince.Unix() <= 0 || r.ScoreSince.After(r.UpdatedAt) || r.UpdatedAt.Unix() <= 0 {
		return ErrSnapshot
	}
	if r.Metric.Player != r.Player || r.Metric.Value != r.Score || !r.Metric.valid(b, r.Metric.ObservedAt, r.Revision) || r.Metric.ObservedAt.Unix() <= 0 || r.Metric.ObservedAt.After(r.UpdatedAt) {
		return ErrSnapshot
	}
	return nil
}

func boardOfMetric(m BoardMetric) (Board, bool) {
	for _, b := range Boards {
		if b.SourceOwner == m.Owner && b.SourcePolicy == m.Policy && b.SourceSemantics == m.Semantics && b.FieldID == m.FieldID {
			return b, true
		}
	}
	return Board{}, false
}

// NextScoreRow keeps the current-value run while score and revision are
// unchanged.
func NextScoreRow(prev *ScoreRow, m BoardMetric, at time.Time) (ScoreRow, error) {
	b, ok := boardOfMetric(m)
	if !ok || at.Unix() <= 0 || !m.valid(b, at, m.Revision) {
		return ScoreRow{}, ErrSnapshot
	}
	since := at.UTC()
	if prev != nil && prev.Score == m.Value && prev.Revision == m.Revision {
		since = prev.ScoreSince
	}
	row := ScoreRow{Policy: b.Policy, Player: m.Player, Score: m.Value, ScoreSince: since, Revision: m.Revision, Metric: m, UpdatedAt: at.UTC()}
	if prev != nil {
		row.Server = prev.Server
	}
	return row, nil
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

// Valid checks the presentation fields without a caller-supplied subject id.
func (p BoardPresentation) Valid() bool { return p.valid(p.Player) }

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

func beginBoardSnapshot(r BoardRoot, at time.Time, rev string, op ids.UUID) (BoardSnapshot, Board, error) {
	var out BoardSnapshot
	if r.Validate() != nil || !revision(rev) || op.IsZero() || at.Unix() <= 0 {
		return out, Board{}, ErrSnapshot
	}
	observedAt := at
	if r.UpdatedAt.After(observedAt) {
		observedAt = r.UpdatedAt
	}
	if r.StateVersion == math.MaxInt64 || r.NextGeneration == math.MaxInt64 {
		return out, Board{}, ErrSnapshot
	}
	b, _ := BoardOf(r.Policy)
	return BoardSnapshot{Server: r.Server, Policy: r.Policy, Revision: rev, Generation: r.NextGeneration, OperationID: op, ObservedAt: observedAt.UTC(), Entries: []BoardEntry{}}, b, nil
}

func finishBoardSnapshot(r BoardRoot, out BoardSnapshot, byID map[int64]BoardEntry, at time.Time) (BoardRoot, BoardSnapshot, error) {
	b, _ := BoardOf(r.Policy)
	ordered, e := out.ordered()
	if e != nil {
		return BoardRoot{}, BoardSnapshot{}, e
	}
	out.Entries = []BoardEntry{}
	for _, v := range ordered {
		out.Entries = append(out.Entries, byID[v.SubjectID])
	}
	if b.Limit > 0 && int64(len(out.Entries)) > b.Limit {
		out.Entries = out.Entries[:b.Limit]
	}
	out.CohortDigest = out.cohortDigest()
	out.Digest = out.hash()
	next := r
	next.NextGeneration++
	next.StateVersion++
	next.UpdatedAt = at.UTC()
	if next.Validate() != nil || out.Validate() != nil {
		return BoardRoot{}, BoardSnapshot{}, ErrSnapshot
	}
	return next, out, nil
}

// FreezeBoardSnapshot settles stored score rows. Each entry keeps the
// ScoreSince a row recorded; nothing derives or invents a new run time.
func FreezeBoardSnapshot(root BoardRoot, at time.Time, rev string, op ids.UUID, entries []BoardEntry) (BoardRoot, BoardSnapshot, error) {
	out, b, e := beginBoardSnapshot(root, at, rev, op)
	if e != nil {
		return BoardRoot{}, BoardSnapshot{}, e
	}
	observedAt := out.ObservedAt
	byID := map[int64]BoardEntry{}
	for _, v := range entries {
		m := v.Metric
		if !m.valid(b, observedAt, rev) || !v.Display.valid(m.Player) || v.ScoreSince.IsZero() || v.ScoreSince.After(observedAt) {
			return BoardRoot{}, BoardSnapshot{}, ErrSnapshot
		}
		if _, dup := byID[int64(m.Player)]; dup {
			return BoardRoot{}, BoardSnapshot{}, ErrSnapshot
		}
		v.ScoreSince = v.ScoreSince.UTC()
		byID[int64(m.Player)] = v
		out.Entries = append(out.Entries, v)
	}
	return finishBoardSnapshot(root, out, byID, observedAt)
}

// BoardWeek is the canonical Monday 05:00 GMT+8 game week (I9_MODE_FRAMEWORK_V1 F7).
func BoardWeek(at time.Time) (time.Time, error) {
	if at.Unix() <= 0 {
		return time.Time{}, ErrSnapshot
	}
	return modes.DayBegins(modes.WeekStart(at)), nil
}

// LegacyBoardWeek is the pre-R3 Monday 00:00 UTC week. It exists only to bind
// and settle a period written under the old calendar that still covers at.
func LegacyBoardWeek(at time.Time) (time.Time, error) {
	if at.Unix() <= 0 {
		return time.Time{}, ErrSnapshot
	}
	u := at.UTC()
	day := time.Date(u.Year(), u.Month(), u.Day(), 0, 0, 0, 0, time.UTC)
	offset := (int(u.Weekday()) + 6) % 7
	return day.AddDate(0, 0, -offset), nil
}

// BindWeek keeps the switch week on an unsettled old UTC period that still
// covers the snapshot, so that period is neither duplicated nor skipped.
func BindWeek(at time.Time, legacyUnsettled bool) (time.Time, error) {
	week, err := BoardWeek(at)
	if err != nil || !legacyUnsettled {
		return week, err
	}
	legacy, err := LegacyBoardWeek(at)
	if err != nil || legacy.Equal(week) {
		return week, err
	}
	return legacy, nil
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
