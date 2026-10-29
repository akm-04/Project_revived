package arenastore

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/postgres"
	app "gxb.local/backend/v2/internal/application/arena"
	wake "gxb.local/backend/v2/internal/application/realtimewakeup"
	"time"

	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) PreviousSeasonRanksTx(requestContext context.Context, query tx.Queryer, season int64) ([]d.TournamentEnrollment, error) {
	var rows []d.TournamentEnrollment
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'previous_season_rank',season_rank) ORDER BY season_rank),'[]'::jsonb)::text FROM arena_settlement_ranks WHERE season=$1 AND season_rank BETWEEN 1 AND 50`, &rows, season)
	return rows, err
}

func (Store) ReadTournamentTx(requestContext context.Context, query tx.Queryer, season int64, lock bool) (d.TournamentPeriod, bool, error) {
	statement := `SELECT payload::text FROM arena_tournament_periods WHERE season=$1`
	if lock {
		statement += ` FOR UPDATE`
	}
	var period d.TournamentPeriod
	found, err := readJSON(requestContext, query, statement, &period, season)
	if err != nil || !found {
		return period, found, err
	}
	return period, true, period.Validate()
}

func (Store) SaveTournamentTx(requestContext context.Context, transaction tx.Tx, period d.TournamentPeriod, previousVersion int64) error {
	if transaction == nil || period.Validate() != nil || period.StateVersion != previousVersion+1 {
		return d.ErrConflict
	}
	payload, err := encode(period)
	if err != nil {
		return err
	}
	if previousVersion == 0 {
		return one(transaction.Exec(requestContext, `INSERT INTO arena_tournament_periods(season,content_revision,payload,state_version) VALUES($1,$2,$3::jsonb,1)`, period.Season, period.ContentRevision, payload))
	}
	return one(transaction.Exec(requestContext, `UPDATE arena_tournament_periods SET payload=$3::jsonb,state_version=$4 WHERE season=$1 AND state_version=$2 AND content_revision=$5`, period.Season, previousVersion, payload, period.StateVersion, period.ContentRevision))
}

func (Store) ReadTournamentRoomTx(requestContext context.Context, query tx.Queryer, identifier ids.UUID, lock bool) (d.TournamentRoom, bool, error) {
	statement := `SELECT payload::text FROM arena_tournament_rooms WHERE room_id=$1`
	if lock {
		statement += ` FOR UPDATE`
	}
	var room d.TournamentRoom
	found, err := readJSON(requestContext, query, statement, &room, identifier.String())
	if err != nil || !found {
		return room, found, err
	}
	return room, true, room.Validate()
}

func (Store) SaveTournamentRoomTx(requestContext context.Context, transaction tx.Tx, room d.TournamentRoom, previousVersion int64) error {
	if transaction == nil || room.Validate() != nil || room.StateVersion != previousVersion+1 {
		return d.ErrConflict
	}
	oldNotice := int64(0)
	if previousVersion > 0 {
		previous, found, err := (Store{}).ReadTournamentRoomTx(requestContext, transaction, room.Identifier, false)
		if err != nil || !found {
			return d.ErrConflict
		}
		oldNotice = previous.NoticeVersion
	}
	if room.NoticeVersion > oldNotice {
		if err := (Store{}).WakeTournamentRoomTx(requestContext, transaction, room.Identifier); err != nil {
			return err
		}
	}
	payload, err := encode(room)
	if err != nil {
		return err
	}
	if previousVersion == 0 {
		var season, weekDay, friendInvitation any
		if room.IsFriendFight() {
			friendInvitation = room.FriendInvitation.String()
		} else if room.Casual {
			weekDay = room.CasualWeekDay
		} else {
			season = room.Season
		}
		return one(transaction.Exec(requestContext, `INSERT INTO arena_tournament_rooms(room_id,season,casual_week_day,friend_invitation_id,first_player,second_player,status,starts_at,state_version,payload) VALUES($1,$2,$3,$4,$5,$6,$7,$8,1,$9::jsonb)`, room.Identifier.String(), season, weekDay, friendInvitation, int64(room.Selection.Players[0]), int64(room.Selection.Players[1]), room.Status, room.StartsAt, payload))
	}
	return one(transaction.Exec(requestContext, `UPDATE arena_tournament_rooms SET payload=$3::jsonb,state_version=$4,status=$5 WHERE room_id=$1 AND state_version=$2 AND first_player=$6 AND second_player=$7 AND starts_at=$8`, room.Identifier.String(), previousVersion, payload, room.StateVersion, room.Status, int64(room.Selection.Players[0]), int64(room.Selection.Players[1]), room.StartsAt))
}

func (Store) TournamentRoomsTx(requestContext context.Context, query tx.Queryer, season int64, player identity.PlayerID, casual bool) ([]d.TournamentRoom, error) {
	var rooms []d.TournamentRoom
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(payload ORDER BY starts_at,room_id),'[]'::jsonb)::text FROM arena_tournament_rooms WHERE (($1::boolean AND casual_week_day=$2) OR (NOT $1::boolean AND season=$2)) AND ($3::bigint=0 OR first_player=$3 OR second_player=$3)`, &rooms, casual, season, int64(player))
	if err != nil {
		return nil, err
	}
	for _, room := range rooms {
		if room.Validate() != nil {
			return nil, d.ErrConflict
		}
	}
	return rooms, nil
}

func (Store) DueTournamentRoomsTx(requestContext context.Context, query tx.Queryer, at time.Time, limit int) ([]ids.UUID, error) {
	var rooms []ids.UUID
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(room_id),'[]'::jsonb)::text FROM (SELECT room_id FROM arena_tournament_rooms WHERE (status='PREPARING' AND starts_at-interval '30 seconds'<=$1) OR (status='SELECTING' AND (payload->'selection'->>'deadline')::timestamptz<=$1) OR status='FIGHTING' ORDER BY starts_at,room_id LIMIT $2) due`, &rooms, at, limit)
	return rooms, err
}

func (Store) ActiveCasualEntryTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID) (d.CasualEntry, bool, error) {
	var entry d.CasualEntry
	found, err := readJSON(requestContext, query, `SELECT payload::text FROM arena_casual_entries WHERE player_id=$1 AND status IN ('WAITING','MATCHED')`, &entry, int64(player))
	if err != nil || !found {
		return entry, found, err
	}
	return entry, true, entry.Validate()
}

func (Store) WaitingCasualEntriesTx(requestContext context.Context, query tx.Queryer, weekDay int64) ([]d.CasualEntry, error) {
	var entries []d.CasualEntry
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(payload ORDER BY admitted_at,entry_id),'[]'::jsonb)::text FROM arena_casual_entries WHERE week_day=$1 AND status='WAITING'`, &entries, weekDay)
	if err != nil {
		return nil, err
	}
	for _, entry := range entries {
		if entry.Validate() != nil {
			return nil, d.ErrConflict
		}
	}
	return entries, nil
}

func (Store) SaveCasualEntryTx(requestContext context.Context, transaction tx.Tx, entry d.CasualEntry, previousVersion int64) error {
	if transaction == nil || entry.Validate() != nil || entry.StateVersion != previousVersion+1 {
		return d.ErrConflict
	}
	payload, err := encode(entry)
	if err != nil {
		return err
	}
	var room any
	if !entry.Room.IsZero() {
		room = entry.Room.String()
	}
	if previousVersion == 0 {
		return one(transaction.Exec(requestContext, `INSERT INTO arena_casual_entries(entry_id,player_id,week_day,status,room_id,admitted_at,expires_at,state_version,payload) VALUES($1,$2,$3,$4,$5,$6,$7,1,$8::jsonb)`, entry.Identifier.String(), int64(entry.Actor.PlayerID), entry.WeekDay, entry.Status, room, entry.AdmittedAt, entry.ExpiresAt, payload))
	}
	return one(transaction.Exec(requestContext, `UPDATE arena_casual_entries SET status=$3,room_id=$4,payload=$5::jsonb,state_version=$6 WHERE entry_id=$1 AND state_version=$2 AND player_id=$7 AND week_day=$8 AND admitted_at=$9 AND expires_at=$10`, entry.Identifier.String(), previousVersion, entry.Status, room, payload, entry.StateVersion, int64(entry.Actor.PlayerID), entry.WeekDay, entry.AdmittedAt, entry.ExpiresAt))
}

func (Store) CasualStandingsTx(requestContext context.Context, query tx.Queryer, weekDay int64) ([]d.CasualStanding, error) {
	var standings []d.CasualStanding
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(jsonb_build_object('PlayerID',player_id,'Points',points,'PointsAt',points_at,'Battles',battles)),'[]'::jsonb)::text FROM arena_casual_scores WHERE week_day=$1`, &standings, weekDay)
	return standings, err
}

func (Store) AddCasualResultTx(requestContext context.Context, transaction tx.Tx, weekDay int64, player identity.PlayerID, won bool, at time.Time) error {
	if transaction == nil || !player.Valid() || at.IsZero() {
		return d.ErrInvalid
	}
	point := int64(0)
	if won {
		point = 1
	}
	return one(transaction.Exec(requestContext, `INSERT INTO arena_casual_scores(week_day,player_id,points,points_at,battles) VALUES($1,$2,$3,$4,1) ON CONFLICT(week_day,player_id) DO UPDATE SET points=arena_casual_scores.points+EXCLUDED.points,points_at=CASE WHEN EXCLUDED.points>0 THEN EXCLUDED.points_at ELSE arena_casual_scores.points_at END,battles=arena_casual_scores.battles+1`, weekDay, int64(player), point, at))
}

func (Store) ReadCasualSessionTx(requestContext context.Context, query tx.Queryer, weekDay int64, lock bool) (d.CasualSession, bool, error) {
	statement := `SELECT payload::text FROM arena_casual_sessions WHERE week_day=$1`
	if lock {
		statement += ` FOR UPDATE`
	}
	var session d.CasualSession
	found, err := readJSON(requestContext, query, statement, &session, weekDay)
	if err != nil || !found {
		return session, found, err
	}
	return session, true, session.Validate()
}

func (Store) SaveCasualSessionTx(requestContext context.Context, transaction tx.Tx, session d.CasualSession, previousVersion int64) error {
	if transaction == nil || session.Validate() != nil || session.StateVersion != previousVersion+1 {
		return d.ErrConflict
	}
	payload, err := encode(session)
	if err != nil {
		return err
	}
	if previousVersion == 0 {
		return one(transaction.Exec(requestContext, `INSERT INTO arena_casual_sessions(week_day,closes_at,content_revision,settled,state_version,payload)VALUES($1,$2,$3,$4,1,$5::jsonb)`, session.Period.WeekDay, session.Period.ClosesAt, session.ContentRevision, session.Settled, payload))
	}
	return one(transaction.Exec(requestContext, `UPDATE arena_casual_sessions SET settled=$3,state_version=$4,payload=$5::jsonb WHERE week_day=$1 AND state_version=$2 AND content_revision=$6 AND closes_at=$7`, session.Period.WeekDay, previousVersion, session.Settled, session.StateVersion, payload, session.ContentRevision, session.Period.ClosesAt))
}

func (Store) PendingCasualSessionsTx(requestContext context.Context, query tx.Queryer, at time.Time, limit int) ([]int64, error) {
	var periods []int64
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(week_day),'[]'::jsonb)::text FROM (SELECT week_day FROM arena_casual_sessions WHERE NOT settled AND closes_at<=$1 ORDER BY week_day LIMIT $2) due`, &periods, at, limit)
	return periods, err
}

func (Store) PendingTournamentsTx(requestContext context.Context, query tx.Queryer, limit int) ([]int64, error) {
	var seasons []int64
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(season),'[]'::jsonb)::text FROM (SELECT season FROM arena_tournament_periods WHERE NOT (payload->>'settled')::boolean ORDER BY season LIMIT $1) due`, &seasons, limit)
	return seasons, err
}

func (Store) WakeTournamentRoomTx(requestContext context.Context, transaction tx.Tx, identifier ids.UUID) error {
	return postgres.EmitRealtimeWakeup(requestContext, transaction, wake.Envelope{Version: wake.EnvelopeVersion, Route: app.TournamentNoticeRoute, Ref: identifier.String()})
}

func (Store) SettledTournamentsTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID) ([]d.TournamentPeriod, error) {
	var periods []d.TournamentPeriod
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(payload ORDER BY season),'[]'::jsonb)::text FROM arena_tournament_periods WHERE payload->>'settled'='true' AND payload->>'cancelled'='false' AND EXISTS (SELECT 1 FROM jsonb_array_elements(payload->'entrants') entrant WHERE (entrant->>'player_id')::bigint=$1 AND entrant->>'placement'='1')`, &periods, int64(player))
	if err != nil {
		return nil, err
	}
	for _, period := range periods {
		if err := period.Validate(); err != nil {
			return nil, err
		}
	}
	return periods, nil
}
