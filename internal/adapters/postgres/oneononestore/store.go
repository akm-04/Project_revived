// Package oneononestore exclusively owns 1 on 1 persistence. The competition
// root row is the lock rank 602 serialization point; every competition
// mutation bumps it.
package oneononestore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/oneonone"
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
	MasterCount     int64     `json:"masters"`
	SeniorCount     int64     `json:"seniors"`
	SettledThrough  int64     `json:"settled"`
	OpenedThrough   int64     `json:"opened"`
	ClosedThrough   int64     `json:"closed"`
	StateVersion    int64     `json:"version"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

const competitionObject = `jsonb_build_object('id',competition_id,'revision',content_revision,'masters',master_count,'seniors',senior_count,'settled',settled_through,'opened',opened_through,'closed',closed_through,'version',state_version,'created_at',created_at,'updated_at',updated_at)::text`

func (Store) ReadCompetitionTx(c context.Context, q tx.Queryer, lock bool) (d.Competition, bool, error) {
	sql := `SELECT ` + competitionObject + ` FROM one_on_one_competitions WHERE competition_id=$1`
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
	return one(t.Exec(c, `INSERT INTO one_on_one_competitions(competition_id,content_revision,policy_id,master_count,senior_count,settled_through,opened_through,closed_through,state_version,created_at,updated_at)VALUES($1,$2,$3,$4,$5,$6,$7,$8,1,$9,$9) ON CONFLICT(competition_id) DO NOTHING`,
		r.ID, r.ContentRevision, d.PolicyID, r.MasterCount, r.SeniorCount, r.SettledThrough, r.OpenedThrough, r.ClosedThrough, r.CreatedAt))
}

func (Store) SaveCompetitionTx(c context.Context, t tx.Tx, r d.Competition, old int64) error {
	if t == nil || r.Validate() != nil || r.StateVersion != old+1 {
		return d.ErrConflict
	}
	return one(t.Exec(c, `UPDATE one_on_one_competitions SET master_count=$3,senior_count=$4,settled_through=$5,opened_through=$6,closed_through=$7,state_version=$8,updated_at=$9 WHERE competition_id=$1 AND state_version=$2`,
		r.ID, old, r.MasterCount, r.SeniorCount, r.SettledThrough, r.OpenedThrough, r.ClosedThrough, r.StateVersion, r.UpdatedAt))
}

type playerRow struct {
	PlayerID        identity.PlayerID        `json:"player_id"`
	Server          identity.LogicalServerID `json:"server"`
	ContentRevision string                   `json:"revision"`
	Level           int64                    `json:"level"`
	Slot            int64                    `json:"slot"`
	Points          int64                    `json:"points"`
	PointsAt        time.Time                `json:"points_at"`
	TriesDay        int64                    `json:"tries_day"`
	TriesLeft       int64                    `json:"tries_left"`
	Purchases       int64                    `json:"purchases"`
	LastFightAt     *time.Time               `json:"last_fight_at"`
	Teams           []d.Team                 `json:"teams"`
	OfferedDay      int64                    `json:"offered_day"`
	Refreshes       int64                    `json:"refreshes"`
	Offered         []identity.PlayerID      `json:"offered"`
	Mode            int64                    `json:"mode"`
	PromotionWeek   int64                    `json:"promotion_week"`
	Candidates      []identity.PlayerID      `json:"candidates"`
	Opponent        identity.PlayerID        `json:"opponent"`
	Challenges      int64                    `json:"challenges"`
	PromotionWins   int64                    `json:"promotion_wins"`
	LastPromotionAt *time.Time               `json:"last_promotion_at"`
	WinStreak       int64                    `json:"win_streak"`
	Fights          int64                    `json:"fights"`
	Wins            int64                    `json:"wins"`
	StateVersion    int64                    `json:"version"`
	CreatedAt       time.Time                `json:"created_at"`
	UpdatedAt       time.Time                `json:"updated_at"`
}

func (r playerRow) player() (d.Player, d.Totals, error) {
	p := d.Player{PlayerID: r.PlayerID, Server: r.Server, ContentRevision: r.ContentRevision, Position: d.Position{Level: r.Level, Slot: r.Slot, Points: r.Points, PointsAt: r.PointsAt},
		TriesDay: r.TriesDay, TriesLeft: r.TriesLeft, Purchases: r.Purchases, LastFightAt: r.LastFightAt, Teams: r.Teams, OfferedDay: r.OfferedDay, Refreshes: r.Refreshes,
		Offered: r.Offered, Mode: r.Mode, PromotionWeek: r.PromotionWeek, Candidates: r.Candidates, Opponent: r.Opponent, Challenges: r.Challenges, PromotionWins: r.PromotionWins,
		LastPromotionAt: r.LastPromotionAt, WinStreak: r.WinStreak, StateVersion: r.StateVersion, CreatedAt: r.CreatedAt, UpdatedAt: r.UpdatedAt}
	return p, d.Totals{Fights: r.Fights, Wins: r.Wins}, p.Validate()
}

const playerObject = `jsonb_build_object('player_id',player_id,'server',logical_server_id,'revision',content_revision,'level',level,'slot',COALESCE(slot,0),'points',points,'points_at',points_at,'tries_day',tries_day,'tries_left',tries_left,'purchases',purchases,'last_fight_at',last_fight_at,'teams',teams,'offered_day',offered_day,'refreshes',refreshes,'offered',offered,'mode',mode,'promotion_week',promotion_week,'candidates',candidates,'opponent',COALESCE(opponent,0),'challenges',challenges,'promotion_wins',promotion_wins,'last_promotion_at',last_promotion_at,'win_streak',win_streak,'fights',fights,'wins',wins,'version',state_version,'created_at',created_at,'updated_at',updated_at)`

func (Store) ReadPlayerTx(c context.Context, q tx.Queryer, pid identity.PlayerID, lock bool) (d.Player, d.Totals, bool, error) {
	sql := `SELECT ` + playerObject + `::text FROM one_on_one_players WHERE player_id=$1`
	if lock {
		sql += ` FOR UPDATE`
	}
	var r playerRow
	found, e := readJSON(c, q, sql, &r, int64(pid))
	if e != nil || !found {
		return d.Player{}, d.Totals{}, found, e
	}
	p, totals, e := r.player()
	return p, totals, true, e
}

// PromotingTx lists players in promotion mode, locked in player order.
func (Store) PromotingTx(c context.Context, q tx.Queryer) ([]identity.PlayerID, error) {
	var out []identity.PlayerID
	_, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(player_id ORDER BY player_id),'[]'::jsonb)::text FROM one_on_one_players WHERE mode=2`, &out)
	return out, e
}

type playerArgs struct {
	teams, offered, candidates string
	opponent                   any
}

func argsOf(p d.Player) (playerArgs, error) {
	var a playerArgs
	var e error
	if a.teams, e = encode(p.Teams); e != nil {
		return a, e
	}
	if a.offered, e = encode(p.Offered); e != nil {
		return a, e
	}
	if a.candidates, e = encode(p.Candidates); e != nil {
		return a, e
	}
	if p.Opponent != 0 {
		a.opponent = int64(p.Opponent)
	}
	return a, nil
}

func (Store) InsertPlayerTx(c context.Context, t tx.Tx, p d.Player) error {
	if t == nil || p.Validate() != nil || p.StateVersion != 1 {
		return d.ErrConflict
	}
	a, e := argsOf(p)
	if e != nil {
		return e
	}
	return one(t.Exec(c, `INSERT INTO one_on_one_players(player_id,logical_server_id,competition_id,content_revision,level,slot,points,points_at,tries_day,tries_left,purchases,last_fight_at,teams,offered_day,refreshes,offered,mode,promotion_week,candidates,opponent,challenges,promotion_wins,last_promotion_at,win_streak,fights,wins,state_version,created_at,updated_at)VALUES($1,$2,$3,$4,$5,NULLIF($6,0),$7,$8,$9,$10,$11,$12,$13::jsonb,$14,$15,$16::jsonb,$17,$18,$19::jsonb,$20,$21,$22,$23,$24,0,0,1,$25,$25)`,
		int64(p.PlayerID), int64(p.Server), d.CompetitionID, p.ContentRevision, p.Level, p.Slot, p.Points, p.PointsAt, p.TriesDay, p.TriesLeft, p.Purchases, p.LastFightAt, a.teams, p.OfferedDay, p.Refreshes, a.offered,
		p.Mode, p.PromotionWeek, a.candidates, a.opponent, p.Challenges, p.PromotionWins, p.LastPromotionAt, p.WinStreak, p.CreatedAt))
}

// SavePlayerTx advances one player version; totals is the history increment.
func (Store) SavePlayerTx(c context.Context, t tx.Tx, p d.Player, old int64, totals d.Totals) error {
	if t == nil || p.Validate() != nil || p.StateVersion != old+1 || totals.Fights < 0 || totals.Wins < 0 || totals.Wins > totals.Fights {
		return d.ErrConflict
	}
	a, e := argsOf(p)
	if e != nil {
		return e
	}
	return one(t.Exec(c, `UPDATE one_on_one_players SET level=$3,slot=NULLIF($4,0),points=$5,points_at=$6,tries_day=$7,tries_left=$8,purchases=$9,last_fight_at=$10,teams=$11::jsonb,offered_day=$12,refreshes=$13,offered=$14::jsonb,mode=$15,promotion_week=$16,candidates=$17::jsonb,opponent=$18,challenges=$19,promotion_wins=$20,last_promotion_at=$21,win_streak=$22,fights=fights+$23,wins=wins+$24,state_version=$25,updated_at=$26 WHERE player_id=$1 AND state_version=$2`,
		int64(p.PlayerID), old, p.Level, p.Slot, p.Points, p.PointsAt, p.TriesDay, p.TriesLeft, p.Purchases, p.LastFightAt, a.teams, p.OfferedDay, p.Refreshes, a.offered, p.Mode, p.PromotionWeek, a.candidates,
		a.opponent, p.Challenges, p.PromotionWins, p.LastPromotionAt, p.WinStreak, totals.Fights, totals.Wins, p.StateVersion, p.UpdatedAt))
}

// StandingsTx lists every competitor's place; HasDefense means at least one saved team.
func (Store) StandingsTx(c context.Context, q tx.Queryer) ([]d.Standing, error) {
	var rows []struct {
		Player     identity.PlayerID        `json:"player"`
		Server     identity.LogicalServerID `json:"server"`
		HasDefense bool                     `json:"defense"`
		Level      int64                    `json:"level"`
		Slot       int64                    `json:"slot"`
		Points     int64                    `json:"points"`
		PointsAt   time.Time                `json:"points_at"`
	}
	if _, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player',player_id,'server',logical_server_id,'defense',jsonb_array_length(teams)>0,'level',level,'slot',COALESCE(slot,0),'points',points,'points_at',points_at) ORDER BY player_id),'[]'::jsonb)::text FROM one_on_one_players`, &rows); e != nil {
		return nil, e
	}
	out := make([]d.Standing, 0, len(rows))
	for _, r := range rows {
		out = append(out, d.Standing{Player: r.Player, Server: r.Server, HasDefense: r.HasDefense, Position: d.Position{Level: r.Level, Slot: r.Slot, Points: r.Points, PointsAt: r.PointsAt}})
	}
	return out, nil
}

type matchRow struct {
	ID           ids.UUID          `json:"id"`
	Attacker     identity.PlayerID `json:"attacker"`
	Defender     identity.PlayerID `json:"defender"`
	Mode         int64             `json:"mode"`
	Fingerprint  string            `json:"fingerprint"`
	AttackTeams  []d.Team          `json:"attack_teams"`
	DefenseTeams []d.Team          `json:"defense_teams"`
	Rounds       []*ids.UUID       `json:"rounds"`
	StartedAt    time.Time         `json:"started_at"`
	Status       string            `json:"status"`
	Outcome      *d.Outcome        `json:"outcome"`
	SettledAt    *time.Time        `json:"settled_at"`
	StateVersion int64             `json:"version"`
}

func (r matchRow) match() (d.Match, error) {
	m := d.Match{ID: r.ID, Attacker: r.Attacker, Defender: r.Defender, Mode: r.Mode, Fingerprint: r.Fingerprint, AttackTeams: r.AttackTeams, DefenseTeams: r.DefenseTeams,
		StartedAt: r.StartedAt, Status: r.Status, Outcome: r.Outcome, SettledAt: r.SettledAt, StateVersion: r.StateVersion}
	for _, a := range r.Rounds {
		round := d.Round{}
		if a != nil {
			round.AttemptID = *a
		}
		m.Rounds = append(m.Rounds, round)
	}
	return m, m.Validate()
}

const matchObject = `jsonb_build_object('id',m.match_id,'attacker',m.attacker_id,'defender',m.defender_id,'mode',m.mode,'fingerprint',m.start_fingerprint,'attack_teams',m.attack_teams,'defense_teams',m.defense_teams,'rounds',(SELECT jsonb_agg(r.attempt_id ORDER BY r.round) FROM one_on_one_rounds r WHERE r.match_id=m.match_id),'started_at',m.started_at,'status',m.status,'outcome',m.outcome,'settled_at',m.settled_at,'version',m.state_version)`

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
	sql := `SELECT ` + matchObject + `::text FROM one_on_one_matches m WHERE m.match_id=$1`
	if lock {
		sql += ` FOR UPDATE OF m`
	}
	return s.readMatch(c, q, sql, id.String())
}

// LatestMatchTx is the attacker's most recent match, open or finished.
func (s Store) LatestMatchTx(c context.Context, q tx.Queryer, attacker identity.PlayerID) (d.Match, bool, error) {
	return s.readMatch(c, q, `SELECT `+matchObject+`::text FROM one_on_one_matches m WHERE m.attacker_id=$1 ORDER BY m.started_at DESC,m.match_id LIMIT 1`, int64(attacker))
}

// OpenMatchesTx lists unsettled match ids started before the instant, oldest first.
func (Store) OpenMatchesTx(c context.Context, q tx.Queryer, before time.Time, limit int) ([]ids.UUID, error) {
	var out []ids.UUID
	_, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(match_id ORDER BY started_at),'[]'::jsonb)::text FROM (SELECT match_id,started_at FROM one_on_one_matches WHERE status='STARTED' AND started_at<$1 ORDER BY started_at LIMIT $2) x`, &out, before, limit)
	return out, e
}

func (Store) InsertMatchTx(c context.Context, t tx.Tx, m d.Match) error {
	if t == nil || m.Validate() != nil || m.Status != d.StatusStarted || m.StateVersion != 1 {
		return d.ErrConflict
	}
	attack, e := encode(m.AttackTeams)
	if e != nil {
		return e
	}
	defense, e := encode(m.DefenseTeams)
	if e != nil {
		return e
	}
	if e = one(t.Exec(c, `INSERT INTO one_on_one_matches(match_id,attacker_id,defender_id,mode,start_fingerprint,attack_teams,defense_teams,started_at,status,state_version)VALUES($1,$2,$3,$4,$5,$6::jsonb,$7::jsonb,$8,'STARTED',1)`,
		m.ID.String(), int64(m.Attacker), int64(m.Defender), m.Mode, m.Fingerprint, attack, defense, m.StartedAt)); e != nil {
		return e
	}
	for i, r := range m.Rounds {
		var attempt any
		if !r.Forfeit() {
			attempt = r.AttemptID.String()
		}
		if e = one(t.Exec(c, `INSERT INTO one_on_one_rounds(match_id,round,attempt_id)VALUES($1,$2,$3)`, m.ID.String(), i+1, attempt)); e != nil {
			return e
		}
	}
	return nil
}

func (Store) FinishMatchTx(c context.Context, t tx.Tx, m d.Match, old int64) error {
	if t == nil || m.Validate() != nil || m.Status == d.StatusStarted || m.StateVersion != old+1 {
		return d.ErrConflict
	}
	var outcome any
	if m.Outcome != nil {
		raw, e := encode(m.Outcome)
		if e != nil {
			return e
		}
		outcome = raw
	}
	return one(t.Exec(c, `UPDATE one_on_one_matches SET status=$3,outcome=$4::jsonb,settled_at=$5,state_version=$6 WHERE match_id=$1 AND state_version=$2 AND status='STARTED'`, m.ID.String(), old, m.Status, outcome, m.SettledAt, m.StateVersion))
}

// InsertRecordTx appends one side's record and keeps only the newest keep records of that owner.
func (Store) InsertRecordTx(c context.Context, t tx.Tx, r d.Record, keep int64) error {
	if t == nil || !r.Owner.Valid() || r.MatchID.IsZero() || keep < 1 {
		return d.ErrConflict
	}
	if e := one(t.Exec(c, `INSERT INTO one_on_one_records(owner_player_id,match_id,is_attack,win,mode,recorded_at)VALUES($1,$2,$3,$4,$5,$6)`, int64(r.Owner), r.MatchID.String(), r.Attack, r.Win, r.Mode, r.At)); e != nil {
		return e
	}
	_, e := t.Exec(c, `DELETE FROM one_on_one_records WHERE owner_player_id=$1 AND record_id NOT IN (SELECT record_id FROM one_on_one_records WHERE owner_player_id=$1 ORDER BY record_id DESC LIMIT $2)`, int64(r.Owner), keep)
	return e
}

type recordRow struct {
	ID      int64             `json:"id"`
	Owner   identity.PlayerID `json:"owner"`
	MatchID ids.UUID          `json:"match_id"`
	Attack  bool              `json:"attack"`
	Win     bool              `json:"win"`
	Mode    int64             `json:"mode"`
	At      time.Time         `json:"at"`
}

const recordObject = `jsonb_build_object('id',record_id,'owner',owner_player_id,'match_id',match_id,'attack',is_attack,'win',win,'mode',mode,'at',recorded_at)`

// RecordsTx lists the owner's retained records, newest first.
func (Store) RecordsTx(c context.Context, q tx.Queryer, owner identity.PlayerID) ([]d.Record, error) {
	var rows []recordRow
	if _, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(`+recordObject+` ORDER BY record_id DESC),'[]'::jsonb)::text FROM one_on_one_records WHERE owner_player_id=$1`, &rows, int64(owner)); e != nil {
		return nil, e
	}
	out := make([]d.Record, 0, len(rows))
	for _, r := range rows {
		out = append(out, d.Record(r))
	}
	return out, nil
}

func (Store) RecordTx(c context.Context, q tx.Queryer, id int64) (d.Record, bool, error) {
	var r recordRow
	found, e := readJSON(c, q, `SELECT `+recordObject+`::text FROM one_on_one_records WHERE record_id=$1`, &r, id)
	return d.Record(r), found, e
}

// RetainedRoundTx reports whether a retained record still references the attempt's match.
func (Store) RetainedRoundTx(c context.Context, q tx.Queryer, attempt ids.UUID) (bool, error) {
	if q == nil {
		return false, d.ErrUnavailable
	}
	var retained bool
	e := q.QueryRow(c, `SELECT EXISTS(SELECT 1 FROM one_on_one_rounds r JOIN one_on_one_records x ON x.match_id=r.match_id WHERE r.attempt_id=$1)`, attempt.String()).Scan(&retained)
	return retained, e
}

func (Store) AddUsageTx(c context.Context, t tx.Tx, pid identity.PlayerID, uses []cd.PartnerUse) error {
	if t == nil {
		return d.ErrUnavailable
	}
	for _, u := range uses {
		if e := one(t.Exec(c, `INSERT INTO one_on_one_partner_usage(player_id,partner_id,fights,wins,kill_count,harms)VALUES($1,$2,1,$3,$4,$5::numeric) ON CONFLICT(player_id,partner_id) DO UPDATE SET fights=one_on_one_partner_usage.fights+1,wins=one_on_one_partner_usage.wins+EXCLUDED.wins,kill_count=one_on_one_partner_usage.kill_count+EXCLUDED.kill_count,harms=one_on_one_partner_usage.harms+EXCLUDED.harms`, int64(pid), u.PartnerID, u.Wins, u.Kills, u.Harms)); e != nil {
			return e
		}
	}
	return nil
}

func (Store) UsageTx(c context.Context, q tx.Queryer, pid identity.PlayerID) ([]cd.PartnerTotals, error) {
	var rows []struct {
		PartnerID int64  `json:"partner_id"`
		Fights    int64  `json:"fights"`
		Wins      int64  `json:"wins"`
		Kills     int64  `json:"kills"`
		Harms     string `json:"harms"`
	}
	if _, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(jsonb_build_object('partner_id',partner_id,'fights',fights,'wins',wins,'kills',kill_count,'harms',harms::text) ORDER BY partner_id),'[]'::jsonb)::text FROM one_on_one_partner_usage WHERE player_id=$1`, &rows, int64(pid)); e != nil {
		return nil, e
	}
	out := make([]cd.PartnerTotals, 0, len(rows))
	for _, r := range rows {
		out = append(out, cd.PartnerTotals{PartnerID: r.PartnerID, Fights: r.Fights, Wins: r.Wins, Kills: r.Kills, Harms: r.Harms})
	}
	return out, nil
}

func (Store) InsertSettlementTx(c context.Context, t tx.Tx, s d.Settlement) error {
	if t == nil || s.SettledAt.Before(s.CutoffAt) || s.CompetitionVersion < 1 {
		return d.ErrConflict
	}
	if e := one(t.Exec(c, `INSERT INTO one_on_one_settlements(day,cutoff_at,settled_at,competition_version,content_revision,recipients)VALUES($1,$2,$3,$4,$5,$6)`, s.Day, s.CutoffAt, s.SettledAt, s.CompetitionVersion, s.ContentRevision, int64(len(s.Rows)))); e != nil {
		return e
	}
	for _, r := range s.Rows {
		var mail, title, starts, end any
		if r.Mail != nil {
			mail = r.Mail.String()
		}
		if r.Title != nil {
			title, starts, end = r.Title.TitleID, s.SettledAt, r.TitleEnd
		}
		if e := one(t.Exec(c, `INSERT INTO one_on_one_settlement_ranks(day,player_id,global_rank,server_rank,mail_uuid,title_id,title_starts_at,title_end)VALUES($1,$2,$3,$4,$5,$6,$7,$8)`, s.Day, int64(r.Player), r.Global, r.ServerRank, mail, title, starts, end)); e != nil {
			return e
		}
	}
	return nil
}

// TitlesTx lists a player's settled title awards for one title id.
func (Store) TitlesTx(c context.Context, q tx.Queryer, pid identity.PlayerID, title int64) ([]d.TitleAward, error) {
	var out []d.TitleAward
	_, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(jsonb_build_object('day',day,'title_id',title_id,'starts_at',title_starts_at,'end',title_end) ORDER BY day),'[]'::jsonb)::text FROM one_on_one_settlement_ranks WHERE player_id=$1 AND title_id=$2`, &out, int64(pid), title)
	return out, e
}
