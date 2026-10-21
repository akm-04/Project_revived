// Package topfloorstore exclusively owns Top Floor persistence. The ladder root
// row is the lock rank 601 serialization point; every ladder mutation bumps it.
package topfloorstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
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

type ladderRow struct {
	Server          identity.LogicalServerID `json:"server"`
	ContentRevision string                   `json:"revision"`
	Size            int64                    `json:"size"`
	SettledDay      int64                    `json:"settled_day"`
	StateVersion    int64                    `json:"version"`
	CreatedAt       time.Time                `json:"created_at"`
	UpdatedAt       time.Time                `json:"updated_at"`
}

const ladderObject = `jsonb_build_object('server',logical_server_id,'revision',content_revision,'size',size,'settled_day',settled_day,'version',state_version,'created_at',created_at,'updated_at',updated_at)::text`

func (Store) ReadLadderTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, lock bool) (d.Ladder, bool, error) {
	sql := `SELECT ` + ladderObject + ` FROM top_floor_ladders WHERE logical_server_id=$1`
	if lock {
		sql += ` FOR UPDATE`
	}
	var r ladderRow
	found, e := readJSON(c, q, sql, &r, int64(server))
	if e != nil || !found {
		return d.Ladder{}, found, e
	}
	l := d.Ladder(r)
	return l, true, l.Validate()
}

// CreateLadderTx seeds the root and the private-policy robot ranks. A concurrent
// first seeding surfaces as a RepeatableRead serialization failure, which retries.
func (Store) CreateLadderTx(c context.Context, t tx.Tx, l d.Ladder) error {
	if t == nil || l.Validate() != nil || l.Size != d.RobotTeams || l.StateVersion != 1 {
		return d.ErrConflict
	}
	if e := one(t.Exec(c, `INSERT INTO top_floor_ladders(logical_server_id,content_revision,policy_id,size,settled_day,state_version,created_at,updated_at)VALUES($1,$2,$3,$4,$5,1,$6,$6) ON CONFLICT(logical_server_id) DO NOTHING`, int64(l.Server), l.ContentRevision, d.PolicyID, l.Size, l.SettledDay, l.CreatedAt)); e != nil {
		return e
	}
	tag, e := t.Exec(c, `INSERT INTO top_floor_ranks(logical_server_id,rank,robot_team)SELECT $1,r,$2+1-r FROM generate_series(1,$2::bigint) r`, int64(l.Server), int64(d.RobotTeams))
	if e != nil {
		return e
	}
	if tag.RowsAffected() != d.RobotTeams {
		return d.ErrConflict
	}
	return nil
}

func (Store) SaveLadderTx(c context.Context, t tx.Tx, l d.Ladder, old int64) error {
	if t == nil || l.Validate() != nil || l.StateVersion != old+1 {
		return d.ErrConflict
	}
	return one(t.Exec(c, `UPDATE top_floor_ladders SET size=$3,settled_day=$4,state_version=$5,updated_at=$6 WHERE logical_server_id=$1 AND state_version=$2`, int64(l.Server), old, l.Size, l.SettledDay, l.StateVersion, l.UpdatedAt))
}

type rankedRow struct {
	Rank   int64             `json:"rank"`
	Robot  int64             `json:"robot"`
	Player identity.PlayerID `json:"player"`
}

func toRanked(rows []rankedRow) ([]d.Ranked, error) {
	out := make([]d.Ranked, 0, len(rows))
	for _, r := range rows {
		o := d.Occupant{Robot: r.Robot, Player: r.Player}
		if !o.Valid() || r.Rank < 1 {
			return nil, d.ErrConflict
		}
		out = append(out, d.Ranked{Rank: r.Rank, Occupant: o})
	}
	return out, nil
}

const rankedAgg = `COALESCE(jsonb_agg(jsonb_build_object('rank',rank,'robot',COALESCE(robot_team,0),'player',COALESCE(player_id,0)) ORDER BY rank),'[]'::jsonb)::text`

// RangeTx lists the occupants of ranks low..high in rank order.
func (Store) RangeTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, low, high int64) ([]d.Ranked, error) {
	var rows []rankedRow
	if _, e := readJSON(c, q, `SELECT `+rankedAgg+` FROM top_floor_ranks WHERE logical_server_id=$1 AND rank BETWEEN $2 AND $3`, &rows, int64(server), low, high); e != nil {
		return nil, e
	}
	return toRanked(rows)
}

// RankedPlayersTx lists the ladder's player occupants in rank order.
func (Store) RankedPlayersTx(c context.Context, q tx.Queryer, server identity.LogicalServerID) ([]d.Ranked, error) {
	var rows []rankedRow
	if _, e := readJSON(c, q, `SELECT `+rankedAgg+` FROM top_floor_ranks WHERE logical_server_id=$1 AND player_id IS NOT NULL`, &rows, int64(server)); e != nil {
		return nil, e
	}
	return toRanked(rows)
}

func (Store) RankOfTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, o d.Occupant) (int64, bool, error) {
	if q == nil || !o.Valid() {
		return 0, false, d.ErrInvalid
	}
	var rank int64
	var e error
	if o.IsRobot() {
		e = q.QueryRow(c, `SELECT rank FROM top_floor_ranks WHERE logical_server_id=$1 AND robot_team=$2`, int64(server), o.Robot).Scan(&rank)
	} else {
		e = q.QueryRow(c, `SELECT rank FROM top_floor_ranks WHERE logical_server_id=$1 AND player_id=$2`, int64(server), int64(o.Player)).Scan(&rank)
	}
	if errors.Is(e, kernelstore.ErrNoRows) {
		return 0, false, nil
	}
	return rank, e == nil, e
}

func (Store) AppendPlayerTx(c context.Context, t tx.Tx, server identity.LogicalServerID, rank int64, pid identity.PlayerID) error {
	if t == nil {
		return d.ErrUnavailable
	}
	return one(t.Exec(c, `INSERT INTO top_floor_ranks(logical_server_id,rank,player_id)VALUES($1,$2,$3)`, int64(server), rank, int64(pid)))
}

// SwapTx exchanges two occupants; the deferred uniqueness constraints hold at commit.
func (Store) SwapTx(c context.Context, t tx.Tx, server identity.LogicalServerID, a, b d.Ranked) error {
	if t == nil || a.Rank == b.Rank {
		return d.ErrConflict
	}
	for _, move := range [][2]d.Ranked{{a, b}, {b, a}} {
		at, to := move[0], move[1]
		robot, player := any(nil), any(nil)
		if to.Occupant.IsRobot() {
			robot = to.Occupant.Robot
		} else {
			player = int64(to.Occupant.Player)
		}
		if e := one(t.Exec(c, `UPDATE top_floor_ranks SET robot_team=$3,player_id=$4 WHERE logical_server_id=$1 AND rank=$2 AND COALESCE(robot_team,0)=$5 AND COALESCE(player_id,0)=$6`, int64(server), at.Rank, robot, player, at.Occupant.Robot, int64(at.Occupant.Player))); e != nil {
			return e
		}
	}
	return nil
}

type playerRow struct {
	PlayerID        identity.PlayerID        `json:"player_id"`
	Server          identity.LogicalServerID `json:"server"`
	ContentRevision string                   `json:"revision"`
	BestRank        int64                    `json:"best_rank"`
	TicketDay       int64                    `json:"ticket_day"`
	TicketsLeft     int64                    `json:"tickets_left"`
	Purchases       int64                    `json:"purchases"`
	LastMatchAt     *time.Time               `json:"last_match_at"`
	RefreshCount    int64                    `json:"refresh_count"`
	OfferedDay      int64                    `json:"offered_day"`
	Offered         []d.Occupant             `json:"offered"`
	Defense         []int64                  `json:"defense"`
	DefensePet      int64                    `json:"defense_pet"`
	DefenseSetAt    *time.Time               `json:"defense_set_at"`
	Fights          int64                    `json:"fights"`
	Wins            int64                    `json:"wins"`
	StateVersion    int64                    `json:"version"`
	CreatedAt       time.Time                `json:"created_at"`
	UpdatedAt       time.Time                `json:"updated_at"`
}

const playerObject = `jsonb_build_object('player_id',player_id,'server',logical_server_id,'revision',content_revision,'best_rank',best_rank,'ticket_day',ticket_day,'tickets_left',tickets_left,'purchases',purchases,'last_match_at',last_match_at,'refresh_count',refresh_count,'offered_day',offered_day,'offered',offered,'defense',defense,'defense_pet',defense_pet,'defense_set_at',defense_set_at,'fights',fights,'wins',wins,'version',state_version,'created_at',created_at,'updated_at',updated_at)::text`

func (Store) ReadPlayerTx(c context.Context, q tx.Queryer, pid identity.PlayerID, lock bool) (d.Player, bool, error) {
	sql := `SELECT ` + playerObject + ` FROM top_floor_players WHERE player_id=$1`
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

// DefendedTx reports which of the players have saved a non-empty defense.
func (Store) DefendedTx(c context.Context, q tx.Queryer, players []identity.PlayerID) (map[identity.PlayerID]bool, error) {
	out := map[identity.PlayerID]bool{}
	if len(players) == 0 {
		return out, nil
	}
	raw := make([]int64, 0, len(players))
	for _, p := range players {
		raw = append(raw, int64(p))
	}
	var defended []identity.PlayerID
	if _, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(player_id),'[]'::jsonb)::text FROM top_floor_players WHERE player_id=ANY($1) AND jsonb_array_length(defense)>0`, &defended, raw); e != nil {
		return nil, e
	}
	for _, p := range defended {
		out[p] = true
	}
	return out, nil
}

func playerArgs(p d.Player) ([]byte, []byte, error) {
	offered, e := json.Marshal(p.Offered)
	if e != nil {
		return nil, nil, e
	}
	defense, e := json.Marshal(p.Defense)
	return offered, defense, e
}

func (Store) InsertPlayerTx(c context.Context, t tx.Tx, p d.Player) error {
	if t == nil || p.Validate() != nil || p.StateVersion != 1 {
		return d.ErrConflict
	}
	offered, defense, e := playerArgs(p)
	if e != nil {
		return e
	}
	return one(t.Exec(c, `INSERT INTO top_floor_players(player_id,logical_server_id,content_revision,best_rank,ticket_day,tickets_left,purchases,last_match_at,refresh_count,offered_day,offered,defense,defense_pet,defense_set_at,fights,wins,state_version,created_at,updated_at)VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11::jsonb,$12::jsonb,$13,$14,$15,$16,1,$17,$17)`,
		int64(p.PlayerID), int64(p.Server), p.ContentRevision, p.BestRank, p.TicketDay, p.TicketsLeft, p.Purchases, p.LastMatchAt, p.RefreshCount, p.OfferedDay, string(offered), string(defense), p.DefensePet, p.DefenseSetAt, p.Fights, p.Wins, p.CreatedAt))
}

func (Store) SavePlayerTx(c context.Context, t tx.Tx, p d.Player, old int64) error {
	if t == nil || p.Validate() != nil || p.StateVersion != old+1 {
		return d.ErrConflict
	}
	offered, defense, e := playerArgs(p)
	if e != nil {
		return e
	}
	return one(t.Exec(c, `UPDATE top_floor_players SET best_rank=$3,ticket_day=$4,tickets_left=$5,purchases=$6,last_match_at=$7,refresh_count=$8,offered_day=$9,offered=$10::jsonb,defense=$11::jsonb,defense_pet=$12,defense_set_at=$13,fights=$14,wins=$15,state_version=$16,updated_at=$17 WHERE player_id=$1 AND state_version=$2`,
		int64(p.PlayerID), old, p.BestRank, p.TicketDay, p.TicketsLeft, p.Purchases, p.LastMatchAt, p.RefreshCount, p.OfferedDay, string(offered), string(defense), p.DefensePet, p.DefenseSetAt, p.Fights, p.Wins, p.StateVersion, p.UpdatedAt))
}

type fightRow struct {
	AttemptID      ids.UUID                 `json:"attempt_id"`
	Server         identity.LogicalServerID `json:"server"`
	Challenger     identity.PlayerID        `json:"challenger"`
	DefenderRobot  int64                    `json:"defender_robot"`
	DefenderPlayer identity.PlayerID        `json:"defender_player"`
	Avenge         bool                     `json:"avenge"`
	Fingerprint    string                   `json:"fingerprint"`
	Formation      []int64                  `json:"formation"`
	PetID          int64                    `json:"pet_id"`
	ChallengerRank int64                    `json:"challenger_rank"`
	DefenderRank   int64                    `json:"defender_rank"`
	StartedAt      time.Time                `json:"started_at"`
	Status         string                   `json:"status"`
	Outcome        *d.Outcome               `json:"outcome"`
	SettledAt      *time.Time               `json:"settled_at"`
	StateVersion   int64                    `json:"version"`
}

func (r fightRow) fight() (d.Fight, error) {
	f := d.Fight{AttemptID: r.AttemptID, Server: r.Server, Challenger: r.Challenger, Defender: d.Occupant{Robot: r.DefenderRobot, Player: r.DefenderPlayer}, Avenge: r.Avenge, Fingerprint: r.Fingerprint, Formation: r.Formation, PetID: r.PetID,
		ChallengerRank: r.ChallengerRank, DefenderRank: r.DefenderRank, StartedAt: r.StartedAt, Status: r.Status, Outcome: r.Outcome, SettledAt: r.SettledAt, StateVersion: r.StateVersion}
	return f, f.Validate()
}

const fightObject = `jsonb_build_object('attempt_id',attempt_id,'server',logical_server_id,'challenger',challenger_id,'defender_robot',COALESCE(defender_robot,0),'defender_player',COALESCE(defender_player,0),'avenge',is_avenge,'fingerprint',start_fingerprint,'formation',formation,'pet_id',pet_id,'challenger_rank',challenger_rank,'defender_rank',defender_rank,'started_at',started_at,'status',status,'outcome',outcome,'settled_at',settled_at,'version',state_version)`

func (Store) readFight(c context.Context, q tx.Queryer, sql string, args ...any) (d.Fight, bool, error) {
	var r fightRow
	found, e := readJSON(c, q, sql, &r, args...)
	if e != nil || !found {
		return d.Fight{}, found, e
	}
	f, e := r.fight()
	return f, true, e
}

func (s Store) ReadFightTx(c context.Context, q tx.Queryer, attempt ids.UUID, lock bool) (d.Fight, bool, error) {
	sql := `SELECT ` + fightObject + `::text FROM top_floor_fights WHERE attempt_id=$1`
	if lock {
		sql += ` FOR UPDATE`
	}
	return s.readFight(c, q, sql, attempt.String())
}

// LatestFightTx is the challenger's most recent fight, open or finished.
func (s Store) LatestFightTx(c context.Context, q tx.Queryer, challenger identity.PlayerID) (d.Fight, bool, error) {
	return s.readFight(c, q, `SELECT `+fightObject+`::text FROM top_floor_fights WHERE challenger_id=$1 ORDER BY started_at DESC,attempt_id LIMIT 1`, int64(challenger))
}

// OpenFightsTx lists unsettled fights started before the instant, oldest first.
func (Store) OpenFightsTx(c context.Context, q tx.Queryer, before time.Time, limit int) ([]d.Fight, error) {
	var rows []fightRow
	if _, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(o ORDER BY o->>'started_at'),'[]'::jsonb)::text FROM (SELECT `+fightObject+` o FROM top_floor_fights WHERE status='STARTED' AND started_at<$1 ORDER BY started_at LIMIT $2) x`, &rows, before, limit); e != nil {
		return nil, e
	}
	out := make([]d.Fight, 0, len(rows))
	for _, r := range rows {
		f, e := r.fight()
		if e != nil {
			return nil, e
		}
		out = append(out, f)
	}
	return out, nil
}

func defenderArgs(o d.Occupant) (any, any) {
	if o.IsRobot() {
		return o.Robot, nil
	}
	return nil, int64(o.Player)
}

func (Store) InsertFightTx(c context.Context, t tx.Tx, f d.Fight) error {
	if t == nil || f.Validate() != nil || f.Status != d.StatusStarted || f.StateVersion != 1 {
		return d.ErrConflict
	}
	formation, e := json.Marshal(f.Formation)
	if e != nil {
		return e
	}
	robot, player := defenderArgs(f.Defender)
	return one(t.Exec(c, `INSERT INTO top_floor_fights(attempt_id,logical_server_id,challenger_id,defender_robot,defender_player,is_avenge,start_fingerprint,formation,pet_id,challenger_rank,defender_rank,started_at,status,state_version)VALUES($1,$2,$3,$4,$5,$6,$7,$8::jsonb,$9,$10,$11,$12,'STARTED',1)`,
		f.AttemptID.String(), int64(f.Server), int64(f.Challenger), robot, player, f.Avenge, f.Fingerprint, string(formation), f.PetID, f.ChallengerRank, f.DefenderRank, f.StartedAt))
}

func (Store) FinishFightTx(c context.Context, t tx.Tx, f d.Fight, old int64) error {
	if t == nil || f.Validate() != nil || f.Status == d.StatusStarted || f.StateVersion != old+1 {
		return d.ErrConflict
	}
	var outcome any
	if f.Outcome != nil {
		raw, e := json.Marshal(f.Outcome)
		if e != nil {
			return e
		}
		outcome = string(raw)
	}
	return one(t.Exec(c, `UPDATE top_floor_fights SET status=$3,outcome=$4::jsonb,settled_at=$5,state_version=$6 WHERE attempt_id=$1 AND state_version=$2 AND status='STARTED'`, f.AttemptID.String(), old, f.Status, outcome, f.SettledAt, f.StateVersion))
}

// InsertRecordTx appends one side's record and keeps only the newest keep records of that owner.
func (Store) InsertRecordTx(c context.Context, t tx.Tx, r d.Record, keep int64) error {
	if t == nil || !r.Owner.Valid() || r.AttemptID.IsZero() || !r.Opponent.Valid() || keep < 1 {
		return d.ErrConflict
	}
	robot, player := defenderArgs(r.Opponent)
	if e := one(t.Exec(c, `INSERT INTO top_floor_records(owner_player_id,attempt_id,is_attack,win,opponent_robot,opponent_player,recorded_at)VALUES($1,$2,$3,$4,$5,$6,$7)`, int64(r.Owner), r.AttemptID.String(), r.Attack, r.Win, robot, player, r.At)); e != nil {
		return e
	}
	_, e := t.Exec(c, `DELETE FROM top_floor_records WHERE owner_player_id=$1 AND record_id NOT IN (SELECT record_id FROM top_floor_records WHERE owner_player_id=$1 ORDER BY record_id DESC LIMIT $2)`, int64(r.Owner), keep)
	return e
}

type recordRow struct {
	ID             int64             `json:"id"`
	Owner          identity.PlayerID `json:"owner"`
	AttemptID      ids.UUID          `json:"attempt_id"`
	Attack         bool              `json:"attack"`
	Win            bool              `json:"win"`
	OpponentRobot  int64             `json:"opponent_robot"`
	OpponentPlayer identity.PlayerID `json:"opponent_player"`
	At             time.Time         `json:"at"`
}

const recordObject = `jsonb_build_object('id',record_id,'owner',owner_player_id,'attempt_id',attempt_id,'attack',is_attack,'win',win,'opponent_robot',COALESCE(opponent_robot,0),'opponent_player',COALESCE(opponent_player,0),'at',recorded_at)`

func (r recordRow) record() d.Record {
	return d.Record{ID: r.ID, Owner: r.Owner, AttemptID: r.AttemptID, Attack: r.Attack, Win: r.Win, Opponent: d.Occupant{Robot: r.OpponentRobot, Player: r.OpponentPlayer}, At: r.At}
}

// RecordsTx lists the owner's retained records, newest first.
func (Store) RecordsTx(c context.Context, q tx.Queryer, owner identity.PlayerID) ([]d.Record, error) {
	var rows []recordRow
	if _, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(`+recordObject+` ORDER BY record_id DESC),'[]'::jsonb)::text FROM top_floor_records WHERE owner_player_id=$1`, &rows, int64(owner)); e != nil {
		return nil, e
	}
	out := make([]d.Record, 0, len(rows))
	for _, r := range rows {
		out = append(out, r.record())
	}
	return out, nil
}

func (Store) RecordTx(c context.Context, q tx.Queryer, id int64) (d.Record, bool, error) {
	var r recordRow
	found, e := readJSON(c, q, `SELECT `+recordObject+`::text FROM top_floor_records WHERE record_id=$1`, &r, id)
	return r.record(), found, e
}

// Retained reports whether any retained record still references the fight.
func (Store) RetainedTx(c context.Context, q tx.Queryer, attempt ids.UUID) (bool, error) {
	if q == nil {
		return false, d.ErrUnavailable
	}
	var retained bool
	e := q.QueryRow(c, `SELECT EXISTS(SELECT 1 FROM top_floor_records WHERE attempt_id=$1)`, attempt.String()).Scan(&retained)
	return retained, e
}

// LostDefenseTx reports whether the owner retains a lost defense record against the attacker.
func (Store) LostDefenseTx(c context.Context, q tx.Queryer, owner, attacker identity.PlayerID) (bool, error) {
	if q == nil {
		return false, d.ErrUnavailable
	}
	var found bool
	e := q.QueryRow(c, `SELECT EXISTS(SELECT 1 FROM top_floor_records WHERE owner_player_id=$1 AND opponent_player=$2 AND NOT is_attack AND NOT win)`, int64(owner), int64(attacker)).Scan(&found)
	return found, e
}

func (Store) AddUsageTx(c context.Context, t tx.Tx, pid identity.PlayerID, uses []cd.PartnerUse) error {
	if t == nil {
		return d.ErrUnavailable
	}
	for _, u := range uses {
		if e := one(t.Exec(c, `INSERT INTO top_floor_partner_usage(player_id,partner_id,fights,wins,kill_count,harms)VALUES($1,$2,1,$3,$4,$5::numeric) ON CONFLICT(player_id,partner_id) DO UPDATE SET fights=top_floor_partner_usage.fights+1,wins=top_floor_partner_usage.wins+EXCLUDED.wins,kill_count=top_floor_partner_usage.kill_count+EXCLUDED.kill_count,harms=top_floor_partner_usage.harms+EXCLUDED.harms`, int64(pid), u.PartnerID, u.Wins, u.Kills, u.Harms)); e != nil {
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
	if _, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(jsonb_build_object('partner_id',partner_id,'fights',fights,'wins',wins,'kills',kill_count,'harms',harms::text) ORDER BY partner_id),'[]'::jsonb)::text FROM top_floor_partner_usage WHERE player_id=$1`, &rows, int64(pid)); e != nil {
		return nil, e
	}
	out := make([]cd.PartnerTotals, 0, len(rows))
	for _, r := range rows {
		out = append(out, cd.PartnerTotals{PartnerID: r.PartnerID, Fights: r.Fights, Wins: r.Wins, Kills: r.Kills, Harms: r.Harms})
	}
	return out, nil
}

func (Store) InsertDaySettlementTx(c context.Context, t tx.Tx, s d.DaySettlement) error {
	if t == nil || !s.Server.Valid() || s.SettledAt.Before(s.CutoffAt) || s.LadderVersion < 1 {
		return d.ErrConflict
	}
	if e := one(t.Exec(c, `INSERT INTO top_floor_day_settlements(logical_server_id,day,cutoff_at,settled_at,ladder_version,content_revision,recipients)VALUES($1,$2,$3,$4,$5,$6,$7)`, int64(s.Server), s.Day, s.CutoffAt, s.SettledAt, s.LadderVersion, s.ContentRevision, int64(len(s.Ranks)))); e != nil {
		return e
	}
	for _, r := range s.Ranks {
		var mail any
		if r.Mail != nil {
			mail = r.Mail.String()
		}
		if e := one(t.Exec(c, `INSERT INTO top_floor_day_ranks(logical_server_id,day,player_id,rank,mail_uuid)VALUES($1,$2,$3,$4,$5)`, int64(s.Server), s.Day, int64(r.Player), r.Rank, mail)); e != nil {
			return e
		}
	}
	return nil
}

// DueServersTx lists ladders that still owe a settlement for a cutoff day at or before day.
func (Store) DueServersTx(c context.Context, q tx.Queryer, day int64) ([]identity.LogicalServerID, error) {
	var out []identity.LogicalServerID
	_, e := readJSON(c, q, `SELECT COALESCE(jsonb_agg(logical_server_id ORDER BY logical_server_id),'[]'::jsonb)::text FROM top_floor_ladders WHERE settled_day<$1`, &out, day)
	return out, e
}
