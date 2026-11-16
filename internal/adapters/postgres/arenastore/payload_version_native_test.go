//go:build postgres

package arenastore_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type arenaFixture struct {
	transaction tx.Tx
	revision    string
}

func newArenaFixture(t *testing.T) *arenaFixture {
	t.Helper()
	dsn := os.Getenv("GXB_R8_MANIFEST_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_MANIFEST_DSN required")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = transaction.Rollback(ctx) })
	fixture := &arenaFixture{transaction: transaction}
	if err := transaction.QueryRow(ctx, `SELECT revision_id FROM gxb_content_revisions ORDER BY installed_at DESC LIMIT 1`).Scan(&fixture.revision); err != nil {
		t.Fatal("content revision required:", err)
	}
	fixture.insertPlayer(t, 190001)
	fixture.insertPlayer(t, 190002)
	if _, err := transaction.Exec(ctx, `INSERT INTO arena_competitions(competition_id,content_revision,policy_id,settled_through,state_version,created_at,updated_at)VALUES('GLOBAL',$1,'C5D_ARENA_PRIVATE_POLICY_V1',0,1,now(),now()) ON CONFLICT(competition_id) DO NOTHING`, fixture.revision); err != nil {
		t.Fatal(err)
	}
	return fixture
}

func newIdentifier(t *testing.T) ids.UUID {
	t.Helper()
	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return identifier
}

func (f *arenaFixture) insertPlayer(t *testing.T, pid identity.PlayerID) {
	t.Helper()
	ctx := context.Background()
	account := newIdentifier(t)
	if _, err := f.transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',now())`, account.String(), account.String()); err != nil {
		t.Fatal(err)
	}
	if _, err := f.transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,now(),'payload-version-probe')`, int64(pid), account.String()); err != nil {
		t.Fatal(err)
	}
}

func arenaActor(t *testing.T, pid identity.PlayerID) identity.ActorContext {
	t.Helper()
	account := newIdentifier(t)
	session := newIdentifier(t)
	contextIdentifier := newIdentifier(t)
	accountID, err := identity.AccountIDFrom(account)
	if err != nil {
		t.Fatal(err)
	}
	sessionID, err := identity.SessionIDFrom(session)
	if err != nil {
		t.Fatal(err)
	}
	contextID, err := identity.ContextIDFrom(contextIdentifier)
	if err != nil {
		t.Fatal(err)
	}
	return identity.ActorContext{AccountID: accountID, AccountUID: identity.AccountUID(account.String()), SessionID: sessionID, ContextID: contextID,
		LogicalServerID: 1, PlayerID: pid, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}

func (f *arenaFixture) storedPayload(t *testing.T, sql string, args ...any) (string, int16) {
	t.Helper()
	var raw string
	var version int16
	if err := f.transaction.QueryRow(context.Background(), sql, args...).Scan(&raw, &version); err != nil {
		t.Fatal(err)
	}
	return raw, version
}

func requireVersionOne(t *testing.T, version int16) {
	t.Helper()
	if version != payload.Current {
		t.Fatalf("payload_version = %d, want %d", version, payload.Current)
	}
}

// requireSameJSON compares stored jsonb text with json.Marshal of the written value.
// jsonb canonicalises object key order, so the comparison is semantic.
func requireSameJSON(t *testing.T, raw string, value any) {
	t.Helper()
	expected, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	var storedValue, expectedValue any
	if err := json.Unmarshal([]byte(raw), &storedValue); err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(expected, &expectedValue); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(storedValue, expectedValue) {
		t.Fatalf("stored payload differs from written value\n got: %s\nwant: %s", raw, expected)
	}
}

func requireDecodes[T any](t *testing.T, table string, version int16, raw []byte, want T) T {
	t.Helper()
	var value T
	if err := payload.Decode(table, version, raw, &value); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(value, want) {
		t.Fatalf("%s decoded value differs: got %+v want %+v", table, value, want)
	}
	return value
}

func newPlayer(pid, opponent identity.PlayerID, now time.Time) d.Player {
	return d.Player{PlayerID: pid, Server: 1, Season: 1, StarAt: now,
		Defense:      d.Lineup{Heroes: []int64{10001001, 10001002, 10001003, 10001004, 10001005}, Pet: 10002001},
		RecentOffers: []d.Offer{{Opponent: opponent, Practice: true}}, MatchCounter: 1,
		Missions:    []d.MissionSlot{{MissionID: 1, Current: 1, Complete: false}},
		MissionTime: now, Awards: []d.Award{{TableID: 10001001, AddStar: 1, Awake: false, Summon: false, Picks: 2}},
		StateVersion: 1, CreatedAt: now, UpdatedAt: now}
}

func TestPayloadVersionRoundTripArenaPlayers(t *testing.T) {
	ctx := context.Background()
	fixture := newArenaFixture(t)
	now := time.Now().UTC().Truncate(time.Second)
	store := arenastore.Store{}
	player := newPlayer(190001, 190002, now)
	if err := store.InsertPlayerTx(ctx, fixture.transaction, player, fixture.revision); err != nil {
		t.Fatal(err)
	}
	defense, missions, offers, awards, version := "", "", "", "", int16(0)
	if err := fixture.transaction.QueryRow(ctx, `SELECT defense::text,missions::text,recent_offers::text,awards::text,payload_version FROM arena_players WHERE player_id=$1`, 190001).Scan(&defense, &missions, &offers, &awards, &version); err != nil {
		t.Fatal(err)
	}
	requireVersionOne(t, version)
	requireSameJSON(t, defense, player.Defense)
	requireSameJSON(t, missions, player.Missions)
	requireSameJSON(t, offers, player.RecentOffers)
	requireSameJSON(t, awards, player.Awards)
	stored, found, err := store.ReadPlayerTx(ctx, fixture.transaction, 190001, false)
	if err != nil || !found {
		t.Fatal("ReadPlayerTx", found, err)
	}
	if !reflect.DeepEqual(stored.Defense, player.Defense) || !reflect.DeepEqual(stored.Missions, player.Missions) || !reflect.DeepEqual(stored.RecentOffers, player.RecentOffers) || !reflect.DeepEqual(stored.Awards, player.Awards) {
		t.Fatal("ReadPlayerTx payloads differ")
	}
	source, err := store.HeroRecommendSourceTx(ctx, fixture.transaction, 1, now, 10)
	if err != nil {
		t.Fatal("HeroRecommendSourceTx", err)
	}
	if len(source.Formations) == 0 || len(source.Formations[0].TableIDs) != len(player.Defense.Heroes) || source.Formations[0].PetID != player.Defense.Pet {
		t.Fatalf("recommend formation %+v", source.Formations)
	}
	player.Star, player.Point, player.StateVersion, player.UpdatedAt = 1, 5, 2, now.Add(time.Minute)
	if err := store.SavePlayerTx(ctx, fixture.transaction, player, 1); err != nil {
		t.Fatal(err)
	}
	updated, found, err := store.ReadPlayerTx(ctx, fixture.transaction, 190001, false)
	if err != nil || !found || updated.Star != 1 || updated.StateVersion != 2 {
		t.Fatal("SavePlayerTx read back", found, err)
	}
	_, updateVersion := fixture.storedPayload(t, `SELECT defense::text,payload_version FROM arena_players WHERE player_id=$1`, 190001)
	requireVersionOne(t, updateVersion)
}

func TestPayloadVersionRoundTripArenaMatches(t *testing.T) {
	ctx := context.Background()
	fixture := newArenaFixture(t)
	now := time.Now().UTC().Truncate(time.Second)
	store := arenastore.Store{}
	for _, pair := range [][2]identity.PlayerID{{190001, 190002}, {190002, 190001}} {
		if err := store.InsertPlayerTx(ctx, fixture.transaction, newPlayer(pair[0], pair[1], now), fixture.revision); err != nil {
			t.Fatal(err)
		}
	}
	match := d.Match{ID: newIdentifier(t), Attacker: 190001, Defender: 190002, Season: 1,
		DefenseHeroes: []d.Fighter{{TableID: 10001001, AddStar: 0}, {TableID: 10001002}}, DefensePet: 10002001,
		StartedAt: now, Status: d.StatusStarted, StateVersion: 1}
	if err := store.InsertMatchTx(ctx, fixture.transaction, match); err != nil {
		t.Fatal(err)
	}
	defense, version := fixture.storedPayload(t, `SELECT defense_heroes::text,payload_version FROM arena_matches WHERE match_id=$1`, match.ID.String())
	requireVersionOne(t, version)
	requireSameJSON(t, defense, match.DefenseHeroes)
	settledAt := now.Add(time.Minute)
	match.Formation = []d.Fighter{{TableID: 10003001}, {TableID: 10003002}}
	match.Outcome = &d.Outcome{Win: true, Star: 1, Point: 5, Coins: 3, Kills: 5, Damage: 1000}
	match.Status, match.SettledAt, match.StateVersion = d.StatusSettled, &settledAt, 2
	if err := store.SaveMatchTx(ctx, fixture.transaction, match, 1); err != nil {
		t.Fatal(err)
	}
	var formation, outcome string
	if err := fixture.transaction.QueryRow(ctx, `SELECT formation::text,outcome::text,payload_version FROM arena_matches WHERE match_id=$1`, match.ID.String()).Scan(&formation, &outcome, &version); err != nil {
		t.Fatal(err)
	}
	requireVersionOne(t, version)
	requireSameJSON(t, formation, match.Formation)
	requireSameJSON(t, outcome, match.Outcome)
	stored, found, err := store.ReadMatchTx(ctx, fixture.transaction, match.ID, false)
	if err != nil || !found {
		t.Fatal("ReadMatchTx", found, err)
	}
	if !reflect.DeepEqual(stored.Formation, match.Formation) || !reflect.DeepEqual(stored.Outcome, match.Outcome) || !reflect.DeepEqual(stored.DefenseHeroes, match.DefenseHeroes) {
		t.Fatalf("ReadMatchTx payloads differ: %+v", stored)
	}
}

func newCasualSession(t *testing.T, revision string) d.CasualSession {
	t.Helper()
	period := d.CasualPeriodAt(time.Now().UTC().Truncate(time.Second))
	return d.CasualSession{Period: period, ContentRevision: revision, StateVersion: 1}
}

func TestPayloadVersionRoundTripArenaCasualEntries(t *testing.T) {
	ctx := context.Background()
	fixture := newArenaFixture(t)
	store := arenastore.Store{}
	session := newCasualSession(t, fixture.revision)
	if err := store.SaveCasualSessionTx(ctx, fixture.transaction, session, 0); err != nil {
		t.Fatal(err)
	}
	admittedAt := session.Period.OpensAt.Add(time.Minute)
	entry := d.CasualEntry{Identifier: newIdentifier(t), WeekDay: session.Period.WeekDay, Actor: d.AdmissionFrom(arenaActor(t, 190001)),
		Status: d.QueueWaiting, AdmittedAt: admittedAt, ExpiresAt: admittedAt.Add(time.Minute), StateVersion: 1}
	if err := store.SaveCasualEntryTx(ctx, fixture.transaction, entry, 0); err != nil {
		t.Fatal(err)
	}
	raw, version := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM arena_casual_entries WHERE entry_id=$1`, entry.Identifier.String())
	requireVersionOne(t, version)
	requireSameJSON(t, raw, entry)
	requireDecodes(t, "arena_casual_entries", version, []byte(raw), entry)
	stored, found, err := store.ActiveCasualEntryTx(ctx, fixture.transaction, 190001)
	if err != nil || !found || !reflect.DeepEqual(stored, entry) {
		t.Fatal("ActiveCasualEntryTx", found, err)
	}
	waiting, err := store.WaitingCasualEntriesTx(ctx, fixture.transaction, entry.WeekDay)
	if err != nil || len(waiting) != 1 || !reflect.DeepEqual(waiting[0], entry) {
		t.Fatal("WaitingCasualEntriesTx", err)
	}
	entry.Status, entry.StateVersion = d.QueueCancelled, 2
	if err := store.SaveCasualEntryTx(ctx, fixture.transaction, entry, 1); err != nil {
		t.Fatal(err)
	}
	_, updateVersion := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM arena_casual_entries WHERE entry_id=$1`, entry.Identifier.String())
	requireVersionOne(t, updateVersion)
}

func TestPayloadVersionRoundTripArenaCasualSessions(t *testing.T) {
	ctx := context.Background()
	fixture := newArenaFixture(t)
	store := arenastore.Store{}
	session := newCasualSession(t, fixture.revision)
	if err := store.SaveCasualSessionTx(ctx, fixture.transaction, session, 0); err != nil {
		t.Fatal(err)
	}
	raw, version := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM arena_casual_sessions WHERE week_day=$1`, session.Period.WeekDay)
	requireVersionOne(t, version)
	requireSameJSON(t, raw, session)
	requireDecodes(t, "arena_casual_sessions", version, []byte(raw), session)
	stored, found, err := store.ReadCasualSessionTx(ctx, fixture.transaction, session.Period.WeekDay, false)
	if err != nil || !found || !reflect.DeepEqual(stored, session) {
		t.Fatal("ReadCasualSessionTx", found, err)
	}
	session.Settled, session.StateVersion = true, 2
	if err := store.SaveCasualSessionTx(ctx, fixture.transaction, session, 1); err != nil {
		t.Fatal(err)
	}
	_, updateVersion := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM arena_casual_sessions WHERE week_day=$1`, session.Period.WeekDay)
	requireVersionOne(t, updateVersion)
}

func TestPayloadVersionRoundTripArenaFriendInvitations(t *testing.T) {
	ctx := context.Background()
	fixture := newArenaFixture(t)
	store := arenastore.Store{}
	createdAt := time.Now().UTC().Truncate(time.Second)
	invitation := d.FriendInvitation{Identifier: newIdentifier(t), Inviter: d.AdmissionFrom(arenaActor(t, 190001)), Recipient: 190002,
		Mode: 1, GameType: 1, Status: d.FriendInvitationPending, CreatedAt: createdAt, ExpiresAt: createdAt.Add(d.FriendFightInvitationLifetime), Sequence: 1, StateVersion: 1}
	if err := store.SaveFriendInvitationTx(ctx, fixture.transaction, invitation, 0); err != nil {
		t.Fatal(err)
	}
	raw, version := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM arena_friend_invitations WHERE invitation_id=$1`, invitation.Identifier.String())
	requireVersionOne(t, version)
	requireSameJSON(t, raw, invitation)
	requireDecodes(t, "arena_friend_invitations", version, []byte(raw), invitation)
	stored, found, err := store.ReadFriendInvitationTx(ctx, fixture.transaction, invitation.Identifier, false)
	if err != nil || !found || !reflect.DeepEqual(stored, invitation) {
		t.Fatal("ReadFriendInvitationTx", found, err)
	}
	latest, found, err := store.LatestFriendInvitationTx(ctx, fixture.transaction, 190001, 190002)
	if err != nil || !found || !reflect.DeepEqual(latest, invitation) {
		t.Fatal("LatestFriendInvitationTx", found, err)
	}
	pending, err := store.PendingFriendInvitationsForPlayersTx(ctx, fixture.transaction, 190001, 190002)
	if err != nil || len(pending) != 1 || !reflect.DeepEqual(pending[0], invitation) {
		t.Fatal("PendingFriendInvitationsForPlayersTx", err)
	}
	invitation.Status, invitation.StateVersion = d.FriendInvitationRejected, 2
	if err := store.SaveFriendInvitationTx(ctx, fixture.transaction, invitation, 1); err != nil {
		t.Fatal(err)
	}
	_, updateVersion := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM arena_friend_invitations WHERE invitation_id=$1`, invitation.Identifier.String())
	requireVersionOne(t, updateVersion)
}

func newTournamentPeriod(t *testing.T, season int64, revision string, now time.Time) d.TournamentPeriod {
	t.Helper()
	calendar := d.TournamentCalendar{Season: season}
	for index := range calendar.Stages {
		calendar.Stages[index] = now.Add(time.Duration(index+1) * time.Hour)
	}
	return d.TournamentPeriod{Season: season, ContentRevision: revision, Calendar: calendar, StateVersion: 1}
}

func TestPayloadVersionRoundTripArenaTournamentPeriods(t *testing.T) {
	ctx := context.Background()
	fixture := newArenaFixture(t)
	now := time.Now().UTC().Truncate(time.Second)
	season := int64(91001)
	if _, err := fixture.transaction.Exec(ctx, `INSERT INTO arena_settlements(season,cutoff_at,settled_at,competition_version,content_revision,recipients)VALUES($1,$2,$3,1,$4,0)`, season, now.Add(-2*time.Hour), now.Add(-time.Hour), fixture.revision); err != nil {
		t.Fatal(err)
	}
	store := arenastore.Store{}
	period := newTournamentPeriod(t, season, fixture.revision, now)
	if err := store.SaveTournamentTx(ctx, fixture.transaction, period, 0); err != nil {
		t.Fatal(err)
	}
	raw, version := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM arena_tournament_periods WHERE season=$1`, season)
	requireVersionOne(t, version)
	requireSameJSON(t, raw, period)
	requireDecodes(t, "arena_tournament_periods", version, []byte(raw), period)
	stored, found, err := store.ReadTournamentTx(ctx, fixture.transaction, season, false)
	if err != nil || !found || !reflect.DeepEqual(stored, period) {
		t.Fatal("ReadTournamentTx", found, err)
	}
	period.StateVersion = 2
	if err := store.SaveTournamentTx(ctx, fixture.transaction, period, 1); err != nil {
		t.Fatal(err)
	}
	_, updateVersion := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM arena_tournament_periods WHERE season=$1`, season)
	requireVersionOne(t, updateVersion)
}

func TestPayloadVersionRoundTripArenaTournamentRooms(t *testing.T) {
	ctx := context.Background()
	fixture := newArenaFixture(t)
	now := time.Now().UTC().Truncate(time.Second)
	store := arenastore.Store{}
	selection, err := d.NewSelectionRoom(190001, 190002, now)
	if err != nil {
		t.Fatal(err)
	}
	period := d.CasualPeriodAt(now)
	room := d.TournamentRoom{Identifier: newIdentifier(t), Casual: true, CasualWeekDay: period.WeekDay,
		Actors:    [2]d.AdmissionContext{d.AdmissionFrom(arenaActor(t, 190001)), d.AdmissionFrom(arenaActor(t, 190002))},
		Selection: selection, Status: d.RoomSelecting, StartsAt: now, ContentRevision: fixture.revision, Contest: 1, StateVersion: 1, NoticeVersion: 1}
	if err := store.SaveTournamentRoomTx(ctx, fixture.transaction, room, 0); err != nil {
		t.Fatal(err)
	}
	raw, version := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM arena_tournament_rooms WHERE room_id=$1`, room.Identifier.String())
	requireVersionOne(t, version)
	requireSameJSON(t, raw, room)
	requireDecodes(t, "arena_tournament_rooms", version, []byte(raw), room)
	stored, found, err := store.ReadTournamentRoomTx(ctx, fixture.transaction, room.Identifier, false)
	if err != nil || !found || !reflect.DeepEqual(stored, room) {
		t.Fatal("ReadTournamentRoomTx", found, err)
	}
	rooms, err := store.TournamentRoomsTx(ctx, fixture.transaction, room.CasualWeekDay, 190001, true)
	if err != nil || len(rooms) != 1 || !reflect.DeepEqual(rooms[0], room) {
		t.Fatal("TournamentRoomsTx", err)
	}
	room.NoticeVersion, room.StateVersion = 2, 2
	if err := store.SaveTournamentRoomTx(ctx, fixture.transaction, room, 1); err != nil {
		t.Fatal(err)
	}
	_, updateVersion := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM arena_tournament_rooms WHERE room_id=$1`, room.Identifier.String())
	requireVersionOne(t, updateVersion)
}
