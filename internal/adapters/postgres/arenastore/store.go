// Package arenastore exclusively owns Arena persistence. The competition root
// row is the lock rank 603 serialization point for settlements.
package arenastore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	d "gxb.local/backend/v2/internal/domain/arena"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

func readJSON(c context.Context, q tx.Queryer, sql string, dst any, args ...any) (bool, error) {
	if q == nil {
		return false, d.ErrUnavailable
	}
	var raw *string
	e := q.QueryRow(c, sql, args...).Scan(&raw)
	if errors.Is(e, kernelstore.ErrNoRows) || (e == nil && raw == nil) {
		return false, nil
	}
	if e != nil {
		return false, e
	}
	return true, json.Unmarshal([]byte(*raw), dst)
}

func one(tag tx.CommandTag, e error) error {
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}

func encode(v any) (string, error) {
	raw, e := json.Marshal(v)
	return string(raw), e
}

type competitionRow struct {
	ID              string    `json:"id"`
	ContentRevision string    `json:"revision"`
	SettledThrough  int64     `json:"settled"`
	StateVersion    int64     `json:"version"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

func (Store) ReadCompetitionTx(c context.Context, q tx.Queryer, lock bool) (d.Competition, bool, error) {
	sql := `SELECT jsonb_build_object('id',competition_id,'revision',content_revision,'settled',settled_through,'version',state_version,'created_at',created_at,'updated_at',updated_at)::text FROM arena_competitions WHERE competition_id=$1`
	if lock {
		sql += ` FOR UPDATE`
	}
	var r competitionRow
	found, e := readJSON(c, q, sql, &r, d.CompetitionID)
	if e != nil || !found {
		return d.Competition{}, found, e
	}
	root := d.Competition(r)
	return root, true, root.Validate()
}

// CreateCompetitionTx inserts the root once; a concurrent first creation
// surfaces as a RepeatableRead serialization failure, which retries.
func (Store) CreateCompetitionTx(c context.Context, t tx.Tx, r d.Competition) error {
	if t == nil || r.Validate() != nil || r.StateVersion != 1 {
		return d.ErrConflict
	}
	return one(t.Exec(c, `INSERT INTO arena_competitions(competition_id,content_revision,policy_id,settled_through,state_version,created_at,updated_at)VALUES($1,$2,$3,$4,1,$5,$5) ON CONFLICT(competition_id) DO NOTHING`,
		r.ID, r.ContentRevision, d.PolicyID, r.SettledThrough, r.CreatedAt))
}

func (Store) SaveCompetitionTx(c context.Context, t tx.Tx, r d.Competition, old int64) error {
	if t == nil || r.Validate() != nil || r.StateVersion != old+1 {
		return d.ErrConflict
	}
	return one(t.Exec(c, `UPDATE arena_competitions SET settled_through=$3,state_version=$4,updated_at=$5 WHERE competition_id=$1 AND state_version=$2`, r.ID, old, r.SettledThrough, r.StateVersion, r.UpdatedAt))
}

type playerRow struct {
	PlayerID      identity.PlayerID        `json:"player_id"`
	Server        identity.LogicalServerID `json:"server"`
	Season        int64                    `json:"season"`
	Star          int64                    `json:"star"`
	Point         int64                    `json:"point"`
	StarAt        time.Time                `json:"star_at"`
	TotalFight    int64                    `json:"total_fight"`
	WinTimes      int64                    `json:"win_times"`
	KeepWin       int64                    `json:"keep_win"`
	DefenseWins   int64                    `json:"defense_wins"`
	DefenseLosses int64                    `json:"defense_losses"`
	DailyDay      int64                    `json:"daily_day"`
	DailyFights   int64                    `json:"daily_fights"`
	Defense       d.Lineup                 `json:"defense"`
	Opponent      identity.PlayerID        `json:"opponent"`
	Practice      bool                     `json:"practice"`
	MatchCounter  int64                    `json:"match_counter"`
	Missions      []d.MissionSlot          `json:"missions"`
	MissionTime   time.Time                `json:"mission_time"`
	MissionDraws  int64                    `json:"mission_draws"`
	ExchangeTimes [3]int64                 `json:"exchange_times"`
	Awards        []d.Award                `json:"awards"`
	StateVersion  int64                    `json:"version"`
	CreatedAt     time.Time                `json:"created_at"`
	UpdatedAt     time.Time                `json:"updated_at"`
}

const playerObject = `jsonb_build_object('player_id',player_id,'server',logical_server_id,'season',season,'star',star,'point',point,'star_at',star_at,'total_fight',total_fight,'win_times',win_times,'keep_win',keep_win,'defense_wins',defense_wins,'defense_losses',defense_losses,'daily_day',daily_day,'daily_fights',daily_fights,'defense',defense,'opponent',COALESCE(opponent,0),'practice',practice,'match_counter',match_counter,'missions',missions,'mission_time',mission_time,'mission_draws',mission_draws,'exchange_times',jsonb_build_array(exchange_star,exchange_awaken,exchange_summon),'awards',awards,'version',state_version,'created_at',created_at,'updated_at',updated_at)`

func (Store) ReadPlayerTx(c context.Context, q tx.Queryer, pid identity.PlayerID, lock bool) (d.Player, bool, error) {
	sql := `SELECT ` + playerObject + `::text FROM arena_players WHERE player_id=$1`
	if lock {
		sql += ` FOR UPDATE`
	}
	var r playerRow
	found, e := readJSON(c, q, sql, &r, int64(pid))
	if e != nil || !found {
		return d.Player{}, found, e
	}
	p := d.Player(r)
	return p, true, p.Validate()
}

type playerArgs struct {
	defense, missions, awards string
	opponent                  any
}

func argsOf(p d.Player) (playerArgs, error) {
	var a playerArgs
	var e error
	if a.defense, e = encode(p.Defense); e != nil {
		return a, e
	}
	if a.missions, e = encode(p.Missions); e != nil {
		return a, e
	}
	if a.awards, e = encode(p.Awards); e != nil {
		return a, e
	}
	if p.Opponent != 0 {
		a.opponent = int64(p.Opponent)
	}
	return a, nil
}

func (Store) InsertPlayerTx(c context.Context, t tx.Tx, p d.Player, revision string) error {
	if t == nil || p.Validate() != nil || p.StateVersion != 1 {
		return d.ErrConflict
	}
	a, e := argsOf(p)
	if e != nil {
		return e
	}
	return one(t.Exec(c, `INSERT INTO arena_players(player_id,logical_server_id,competition_id,content_revision,season,star,point,star_at,total_fight,win_times,keep_win,defense_wins,defense_losses,daily_day,daily_fights,defense,opponent,practice,match_counter,missions,mission_time,mission_draws,exchange_star,exchange_awaken,exchange_summon,awards,state_version,created_at,updated_at)VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16::jsonb,$17,$18,$19,$20::jsonb,$21,$22,$23,$24,$25,$26::jsonb,1,$27,$27)`,
		int64(p.PlayerID), int64(p.Server), d.CompetitionID, revision, p.Season, p.Star, p.Point, p.StarAt, p.TotalFight, p.WinTimes, p.KeepWin, p.DefenseWins, p.DefenseLosses, p.DailyDay, p.DailyFights,
		a.defense, a.opponent, p.Practice, p.MatchCounter, a.missions, p.MissionTime, p.MissionDraws, p.ExchangeTimes[0], p.ExchangeTimes[1], p.ExchangeTimes[2], a.awards, p.CreatedAt))
}

// SavePlayerTx advances one player version.
func (Store) SavePlayerTx(c context.Context, t tx.Tx, p d.Player, old int64) error {
	if t == nil || p.Validate() != nil || p.StateVersion != old+1 {
		return d.ErrConflict
	}
	a, e := argsOf(p)
	if e != nil {
		return e
	}
	return one(t.Exec(c, `UPDATE arena_players SET season=$3,star=$4,point=$5,star_at=$6,total_fight=$7,win_times=$8,keep_win=$9,defense_wins=$10,defense_losses=$11,daily_day=$12,daily_fights=$13,defense=$14::jsonb,opponent=$15,practice=$16,match_counter=$17,missions=$18::jsonb,mission_time=$19,mission_draws=$20,exchange_star=$21,exchange_awaken=$22,exchange_summon=$23,awards=$24::jsonb,state_version=$25,updated_at=$26 WHERE player_id=$1 AND state_version=$2`,
		int64(p.PlayerID), old, p.Season, p.Star, p.Point, p.StarAt, p.TotalFight, p.WinTimes, p.KeepWin, p.DefenseWins, p.DefenseLosses, p.DailyDay, p.DailyFights,
		a.defense, a.opponent, p.Practice, p.MatchCounter, a.missions, p.MissionTime, p.MissionDraws, p.ExchangeTimes[0], p.ExchangeTimes[1], p.ExchangeTimes[2], a.awards, p.StateVersion, p.UpdatedAt))
}

// StandingsTx lists every competitor's place in the season; rows of an older
// season count as that season's reset state (zero stars and fights).
func (Store) StandingsTx(c context.Context, q tx.Queryer, season int64) ([]d.Standing, error) {
	var rows []struct {
		PlayerID   identity.PlayerID        `json:"player"`
		Server     identity.LogicalServerID `json:"server"`
		Star       int64                    `json:"star"`
		Point      int64                    `json:"point"`
		StarAt     time.Time                `json:"star_at"`
		TotalFight int64                    `json:"total_fight"`
		WinTimes   int64                    `json:"win_times"`
		Defended   bool                     `json:"defended"`
	}
	sql := `SELECT COALESCE(jsonb_agg(jsonb_build_object('player',player_id,'server',logical_server_id,'star',CASE WHEN season=$1 THEN star ELSE 0 END,'point',CASE WHEN season=$1 THEN point ELSE 0 END,'star_at',star_at,'total_fight',CASE WHEN season=$1 THEN total_fight ELSE 0 END,'win_times',CASE WHEN season=$1 THEN win_times ELSE 0 END,'defended',jsonb_array_length(defense->'heroes')=5) ORDER BY player_id),'[]'::jsonb)::text FROM arena_players WHERE season<=$1`
	if _, e := readJSON(c, q, sql, &rows, season); e != nil {
		return nil, e
	}
	out := make([]d.Standing, 0, len(rows))
	for _, r := range rows {
		out = append(out, d.Standing(r))
	}
	return out, nil
}

type matchRow struct {
	ID            ids.UUID          `json:"id"`
	Attacker      identity.PlayerID `json:"attacker"`
	Defender      identity.PlayerID `json:"defender"`
	Season        int64             `json:"season"`
	Practice      bool              `json:"practice"`
	DefenseHeroes []d.Fighter       `json:"defense_heroes"`
	DefensePet    int64             `json:"defense_pet"`
	StartedAt     time.Time         `json:"started_at"`
	Formation     []d.Fighter       `json:"formation"`
	AttackPet     int64             `json:"attack_pet"`
	AttemptID     *ids.UUID         `json:"attempt_id"`
	Fingerprint   string            `json:"fingerprint"`
	Status        string            `json:"status"`
	Outcome       *d.Outcome        `json:"outcome"`
	SettledAt     *time.Time        `json:"settled_at"`
	StateVersion  int64             `json:"version"`
}

func (r matchRow) match() (d.Match, error) {
	m := d.Match{ID: r.ID, Attacker: r.Attacker, Defender: r.Defender, Season: r.Season, Practice: r.Practice, DefenseHeroes: r.DefenseHeroes, DefensePet: r.DefensePet,
		StartedAt: r.StartedAt, Formation: r.Formation, AttackPet: r.AttackPet, Fingerprint: r.Fingerprint, Status: r.Status, Outcome: r.Outcome, SettledAt: r.SettledAt, StateVersion: r.StateVersion}
	if r.AttemptID != nil {
		m.AttemptID = *r.AttemptID
	}
	return m, m.Validate()
}

const matchObject = `jsonb_build_object('id',match_id,'attacker',attacker_id,'defender',defender_id,'season',season,'practice',practice,'defense_heroes',defense_heroes,'defense_pet',defense_pet,'started_at',started_at,'formation',COALESCE(formation,'[]'::jsonb),'attack_pet',attack_pet,'attempt_id',attempt_id,'fingerprint',COALESCE(fingerprint,''),'status',status,'outcome',outcome,'settled_at',settled_at,'version',state_version)`

func (Store) readMatch(c context.Context, q tx.Queryer, sql string, args ...any) (d.Match, bool, error) {
	var r matchRow
	found, e := readJSON(c, q, sql, &r, args...)
	if e != nil || !found {
		return d.Match{}, found, e
	}
	m, e := r.match()
	return m, true, e
}

func (s Store) ReadMatchTx(c context.Context, q tx.Queryer, id ids.UUID, lock bool) (d.Match, bool, error) {
	sql := `SELECT ` + matchObject + `::text FROM arena_matches WHERE match_id=$1`
	if lock {
		sql += ` FOR UPDATE`
	}
	return s.readMatch(c, q, sql, id.String())
}

// LatestMatchTx is the attacker's most recent match, open or finished.
func (s Store) LatestMatchTx(c context.Context, q tx.Queryer, attacker identity.PlayerID) (d.Match, bool, error) {
	return s.readMatch(c, q, `SELECT `+matchObject+`::text FROM arena_matches WHERE attacker_id=$1 ORDER BY started_at DESC,match_id LIMIT 1`, int64(attacker))
}

// OpenMatchesTx lists started or fighting match ids started before the instant, oldest first.
func (Store) OpenMatchesTx(c context.Context, q tx.Queryer, before time.Time, limit int) ([]ids.UUID, error) {
	var out []ids.UUID
	_, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(match_id ORDER BY started_at),'[]'::jsonb)::text FROM (SELECT match_id,started_at FROM arena_matches WHERE status IN ('STARTED','FIGHTING') AND started_at<$1 ORDER BY started_at LIMIT $2) x`, &out, before, limit)
	return out, e
}

func (Store) InsertMatchTx(c context.Context, t tx.Tx, m d.Match) error {
	if t == nil || m.Validate() != nil || m.Status != d.StatusStarted || m.StateVersion != 1 {
		return d.ErrConflict
	}
	defense, e := encode(m.DefenseHeroes)
	if e != nil {
		return e
	}
	return one(t.Exec(c, `INSERT INTO arena_matches(match_id,attacker_id,defender_id,season,practice,defense_heroes,defense_pet,started_at,attack_pet,status,state_version)VALUES($1,$2,$3,$4,$5,$6::jsonb,$7,$8,0,'STARTED',1)`,
		m.ID.String(), int64(m.Attacker), int64(m.Defender), m.Season, m.Practice, defense, m.DefensePet, m.StartedAt))
}

// SaveMatchTx advances an open match: STARTED -> FIGHTING (formation and
// attempt) or STARTED/FIGHTING -> SETTLED/CLOSED.
func (Store) SaveMatchTx(c context.Context, t tx.Tx, m d.Match, old int64) error {
	if t == nil || m.Validate() != nil || m.Status == d.StatusStarted || m.StateVersion != old+1 {
		return d.ErrConflict
	}
	var formation, outcome, attempt, fingerprint any
	if len(m.Formation) > 0 {
		raw, e := encode(m.Formation)
		if e != nil {
			return e
		}
		formation = raw
	}
	if m.Outcome != nil {
		raw, e := encode(m.Outcome)
		if e != nil {
			return e
		}
		outcome = raw
	}
	if !m.AttemptID.IsZero() {
		attempt, fingerprint = m.AttemptID.String(), m.Fingerprint
	}
	return one(t.Exec(c, `UPDATE arena_matches SET formation=$3::jsonb,attack_pet=$4,attempt_id=$5,fingerprint=$6,status=$7,outcome=$8::jsonb,settled_at=$9,state_version=$10 WHERE match_id=$1 AND state_version=$2 AND status IN ('STARTED','FIGHTING')`,
		m.ID.String(), old, formation, m.AttackPet, attempt, fingerprint, m.Status, outcome, m.SettledAt, m.StateVersion))
}

// InsertRecordTx appends one side's record and keeps only the newest keep records of that owner.
func (Store) InsertRecordTx(c context.Context, t tx.Tx, r d.Record, keep int64) error {
	if t == nil || !r.Owner.Valid() || r.MatchID.IsZero() || keep < 1 {
		return d.ErrConflict
	}
	if e := one(t.Exec(c, `INSERT INTO arena_records(owner_player_id,match_id,is_attack,win,recorded_at)VALUES($1,$2,$3,$4,$5)`, int64(r.Owner), r.MatchID.String(), r.Attack, r.Win, r.At)); e != nil {
		return e
	}
	_, e := t.Exec(c, `DELETE FROM arena_records WHERE owner_player_id=$1 AND record_id NOT IN (SELECT record_id FROM arena_records WHERE owner_player_id=$1 ORDER BY record_id DESC LIMIT $2)`, int64(r.Owner), keep)
	return e
}

// RecordsTx lists the owner's retained records, newest first.
func (Store) RecordsTx(c context.Context, q tx.Queryer, owner identity.PlayerID) ([]d.Record, error) {
	var rows []struct {
		ID      int64             `json:"id"`
		Owner   identity.PlayerID `json:"owner"`
		MatchID ids.UUID          `json:"match_id"`
		Attack  bool              `json:"attack"`
		Win     bool              `json:"win"`
		At      time.Time         `json:"at"`
	}
	if _, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(jsonb_build_object('id',record_id,'owner',owner_player_id,'match_id',match_id,'attack',is_attack,'win',win,'at',recorded_at) ORDER BY record_id DESC),'[]'::jsonb)::text FROM arena_records WHERE owner_player_id=$1`, &rows, int64(owner)); e != nil {
		return nil, e
	}
	out := make([]d.Record, 0, len(rows))
	for _, r := range rows {
		out = append(out, d.Record(r))
	}
	return out, nil
}

// ChampionSettlementsTx lists the settled seasons the player won as champion.
func (Store) ChampionSettlementsTx(c context.Context, q tx.Queryer, pid identity.PlayerID) ([]d.ChampionSettlement, error) {
	var rows []d.ChampionSettlement
	if _, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(jsonb_build_object('season',s.season,'settled_at',s.settled_at) ORDER BY s.season),'[]'::jsonb)::text FROM arena_settlement_ranks r JOIN arena_settlements s USING(season) WHERE r.player_id=$1 AND r.champion`, &rows, int64(pid)); e != nil {
		return nil, e
	}
	return rows, nil
}

// RetainedAttemptTx reports whether a retained record still references the attempt's match.
func (Store) RetainedAttemptTx(c context.Context, q tx.Queryer, attempt ids.UUID) (bool, error) {
	if q == nil {
		return false, d.ErrUnavailable
	}
	var retained bool
	e := q.QueryRow(c, `SELECT EXISTS(SELECT 1 FROM arena_matches m JOIN arena_records r ON r.match_id=m.match_id WHERE m.attempt_id=$1)`, attempt.String()).Scan(&retained)
	return retained, e
}

// AddUsageTx adds one ranked fight per girl (by table id) to the season usage.
func (Store) AddUsageTx(c context.Context, t tx.Tx, pid identity.PlayerID, season int64, uses []cd.PartnerUse) error {
	if t == nil {
		return d.ErrUnavailable
	}
	for _, u := range uses {
		if e := one(t.Exec(c, `INSERT INTO arena_partner_usage(player_id,season,table_id,fights,wins,kill_count,harms)VALUES($1,$2,$3,1,$4,$5,$6::numeric) ON CONFLICT(player_id,season,table_id) DO UPDATE SET fights=arena_partner_usage.fights+1,wins=arena_partner_usage.wins+EXCLUDED.wins,kill_count=arena_partner_usage.kill_count+EXCLUDED.kill_count,harms=arena_partner_usage.harms+EXCLUDED.harms`,
			int64(pid), season, u.TableID, u.Wins, u.Kills, u.Harms)); e != nil {
			return e
		}
	}
	return nil
}

func (Store) UsageTx(c context.Context, q tx.Queryer, pid identity.PlayerID, season int64) ([]d.Usage, error) {
	var out []d.Usage
	_, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(jsonb_build_object('table_id',table_id,'fights',fights,'wins',wins,'kills',kill_count,'harms',harms::text) ORDER BY table_id),'[]'::jsonb)::text FROM arena_partner_usage WHERE player_id=$1 AND season=$2`, &out, int64(pid), season)
	return out, e
}

func (Store) InsertSettlementTx(c context.Context, t tx.Tx, s d.Settlement) error {
	if t == nil || s.SettledAt.Before(s.CutoffAt) || s.CompetitionVersion < 1 {
		return d.ErrConflict
	}
	if e := one(t.Exec(c, `INSERT INTO arena_settlements(season,cutoff_at,settled_at,competition_version,content_revision,recipients)VALUES($1,$2,$3,$4,$5,$6)`, s.Season, s.CutoffAt, s.SettledAt, s.CompetitionVersion, s.ContentRevision, int64(len(s.Rows)))); e != nil {
		return e
	}
	for _, r := range s.Rows {
		var mail any
		if r.Mail != nil {
			mail = r.Mail.String()
		}
		if e := one(t.Exec(c, `INSERT INTO arena_settlement_ranks(season,player_id,season_rank,level,star,point,champion,mail_uuid)VALUES($1,$2,$3,$4,$5,$6,$7,$8)`, s.Season, int64(r.Player), r.Rank, r.Level, r.Star, r.Point, r.Champion, mail)); e != nil {
			return e
		}
	}
	return nil
}
