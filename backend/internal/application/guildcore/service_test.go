package guildcore

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"sync"
	"testing"
	"time"

	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type testTag int64

func (t testTag) RowsAffected() int64 { return int64(t) }

type testRow struct{}

func (testRow) Scan(...any) error { return nil }

type testTx struct{}

func (*testTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return testTag(1), nil }
func (*testTx) QueryRow(context.Context, string, ...any) tx.Row             { return testRow{} }
func (*testTx) Commit(context.Context) error                                { return nil }
func (*testTx) Rollback(context.Context) error                              { return nil }

type testDB struct{}

func (testDB) Begin(context.Context, tx.Options) (tx.Tx, error) { return &testTx{}, nil }

type staticTime struct{ at time.Time }

func (s staticTime) Now(context.Context) (time.Time, error) { return s.at, nil }

type testFence struct{}

type rootPort struct {
	before func([]identity.PlayerID) bool
}

func (p rootPort) LockPlayerRootsTx(_ context.Context, _ tx.Tx, server identity.LogicalServerID, ids []identity.PlayerID) ([]playerroot.Root, error) {
	canon, err := playerroot.CanonicalPlayerIDs(ids)
	if err != nil {
		return nil, err
	}
	if p.before != nil && !p.before(canon) {
		return nil, errors.New("player root lock ordering violated")
	}
	out := make([]playerroot.Root, len(canon))
	for i, id := range canon {
		out[i] = playerroot.Root{PlayerID: id, LogicalServerID: server}
	}
	return out, nil
}

func (testFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type receiptMem struct {
	mu sync.Mutex
	m  map[string]receipt.Receipt
}

func rkey(i receipt.Identity) string {
	return i.OwnerKind + "|" + i.OwnerKey + "|" + i.Domain + "|" + i.Operation + "|" + i.SemanticKey
}
func (r *receiptMem) PutTx(_ context.Context, _ tx.Tx, v receipt.Receipt) (receipt.PutResult, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.m == nil {
		r.m = map[string]receipt.Receipt{}
	}
	k := rkey(v.Identity)
	if old, ok := r.m[k]; ok {
		return receipt.PutResult{Receipt: old, Inserted: false}, nil
	}
	r.m[k] = v
	return receipt.PutResult{Receipt: v, Inserted: true}, nil
}
func (r *receiptMem) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	v, ok := r.m[rkey(id)]
	return v, ok, nil
}
func (r *receiptMem) Find(_ context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	return r.FindTx(context.Background(), nil, id)
}

type memStore struct {
	next        int64
	nextEventID int64
	guilds      map[guild.ID]guild.Guild
	members     map[identity.PlayerID]guild.Membership
	apps        map[string]guild.Application
	invites     map[string]guild.Invite
	events      []guild.MembershipEvent
	audits      []string
	roleSaves   []identity.PlayerID
	locks       []string
}

func newMemStore() *memStore {
	return &memStore{next: 1, nextEventID: 1, guilds: map[guild.ID]guild.Guild{}, members: map[identity.PlayerID]guild.Membership{}, apps: map[string]guild.Application{}, invites: map[string]guild.Invite{}}
}
func appKey(g guild.ID, p identity.PlayerID) string { return fmt.Sprintf("%d/%d", g, p) }
func (s *memStore) LockAllocatorTx(context.Context, tx.Tx, identity.LogicalServerID, time.Time) (int64, int64, error) {
	s.locks = append(s.locks, "allocator")
	return s.next, 1, nil
}
func (s *memStore) AdvanceAllocatorTx(_ context.Context, _ tx.Tx, _ identity.LogicalServerID, old, _ int64, _ time.Time) error {
	if s.next != old {
		return errors.New("allocator drift")
	}
	s.next++
	return nil
}
func (s *memStore) InsertGuildTx(_ context.Context, _ tx.Tx, g guild.Guild) error {
	if _, ok := s.guilds[g.ID]; ok {
		return errors.New("duplicate guild")
	}
	s.guilds[g.ID] = g
	return nil
}
func (s *memStore) LockGuildTx(_ context.Context, _ tx.Tx, id guild.ID) (guild.Guild, bool, error) {
	s.locks = append(s.locks, "guild")
	g, ok := s.guilds[id]
	return g, ok, nil
}
func (s *memStore) ReadGuild(_ context.Context, id guild.ID) (guild.Guild, bool, error) {
	g, ok := s.guilds[id]
	return g, ok, nil
}
func (s *memStore) GuildNameInUseTx(_ context.Context, _ tx.Queryer, server identity.LogicalServerID, name string, exclude guild.ID) (bool, error) {
	for id, g := range s.guilds {
		if id != exclude && g.LogicalServerID == server && g.RetiredAt == nil && g.Name == name {
			return true, nil
		}
	}
	return false, nil
}
func (s *memStore) LockMembershipTx(_ context.Context, _ tx.Tx, p identity.PlayerID) (guild.Membership, bool, error) {
	m, ok := s.members[p]
	return m, ok, nil
}
func (s *memStore) ReadMembership(_ context.Context, p identity.PlayerID) (guild.Membership, bool, error) {
	m, ok := s.members[p]
	return m, ok, nil
}
func (s *memStore) InsertMembershipTx(_ context.Context, _ tx.Tx, m guild.Membership) error {
	if _, ok := s.members[m.PlayerID]; ok {
		return errors.New("duplicate membership")
	}
	s.members[m.PlayerID] = m
	return nil
}
func (s *memStore) SaveMembershipRoleTx(_ context.Context, _ tx.Tx, m guild.Membership, _ int64) error {
	s.roleSaves = append(s.roleSaves, m.PlayerID)
	s.members[m.PlayerID] = m
	return nil
}
func (s *memStore) DeleteMembershipTx(_ context.Context, _ tx.Tx, p identity.PlayerID, _ guild.ID, _ int64) error {
	delete(s.members, p)
	return nil
}
func (s *memStore) CountMembersTx(_ context.Context, _ tx.Queryer, gid guild.ID) (int64, error) {
	var n int64
	for _, m := range s.members {
		if m.GuildID == gid {
			n++
		}
	}
	return n, nil
}
func (s *memStore) CountRoleTx(_ context.Context, _ tx.Queryer, gid guild.ID, role guild.Role) (int64, error) {
	var n int64
	for _, m := range s.members {
		if m.GuildID == gid && m.Role == role {
			n++
		}
	}
	return n, nil
}
func (s *memStore) AppendMembershipEventTx(_ context.Context, _ tx.Tx, e guild.MembershipEvent, _ ids.UUID) error {
	if e.EventID <= 0 {
		e.EventID = s.nextEventID
		s.nextEventID++
	} else if e.EventID >= s.nextEventID {
		s.nextEventID = e.EventID + 1
	}
	s.events = append(s.events, e)
	return nil
}
func (s *memStore) LatestMembershipEventTx(_ context.Context, _ tx.Queryer, p identity.PlayerID) (guild.MembershipEvent, bool, error) {
	var out guild.MembershipEvent
	found := false
	for _, e := range s.events {
		if e.PlayerID == p && (!found || e.EventID > out.EventID) {
			out = e
			found = true
		}
	}
	return out, found, nil
}
func (s *memStore) CountJoinsSinceTx(_ context.Context, _ tx.Queryer, p identity.PlayerID, since time.Time) (int64, error) {
	var n int64
	for _, e := range s.events {
		if e.PlayerID == p && e.Kind == guild.EventJoin && !e.OccurredAt.Before(since) {
			n++
		}
	}
	return n, nil
}
func (s *memStore) LastDepartureTx(_ context.Context, _ tx.Queryer, p identity.PlayerID) (guild.ID, guild.MembershipEventKind, time.Time, bool, error) {
	for i := len(s.events) - 1; i >= 0; i-- {
		e := s.events[i]
		if e.PlayerID == p && (e.Kind == guild.EventLeave || e.Kind == guild.EventKick || e.Kind == guild.EventDissolve) {
			return e.GuildID, e.Kind, e.OccurredAt, true, nil
		}
	}
	return 0, "", time.Time{}, false, nil
}
func (s *memStore) MembershipEpochTx(_ context.Context, _ tx.Queryer, p identity.PlayerID) (int64, error) {
	var n int64
	for _, e := range s.events {
		if e.PlayerID == p {
			n++
		}
	}
	return n + 1, nil
}
func (s *memStore) FindApplicationTx(_ context.Context, _ tx.Queryer, g guild.ID, p identity.PlayerID) (guild.Application, bool, error) {
	a, ok := s.apps[appKey(g, p)]
	return a, ok, nil
}
func (s *memStore) InsertApplicationTx(_ context.Context, _ tx.Tx, a guild.Application) error {
	s.apps[appKey(a.GuildID, a.PlayerID)] = a
	return nil
}
func (s *memStore) DeleteApplicationTx(_ context.Context, _ tx.Tx, g guild.ID, p identity.PlayerID) error {
	delete(s.apps, appKey(g, p))
	return nil
}
func (s *memStore) DeleteApplicationsForPlayerTx(_ context.Context, _ tx.Tx, p identity.PlayerID) error {
	for k, a := range s.apps {
		if a.PlayerID == p {
			delete(s.apps, k)
		}
	}
	return nil
}
func (s *memStore) DeleteGuildApplicationsTx(_ context.Context, _ tx.Tx, g guild.ID) error {
	for k, a := range s.apps {
		if a.GuildID == g {
			delete(s.apps, k)
		}
	}
	return nil
}
func (s *memStore) DeleteGuildInvitesTx(_ context.Context, _ tx.Tx, g guild.ID) error {
	for k, i := range s.invites {
		if i.GuildID == g {
			delete(s.invites, k)
		}
	}
	return nil
}
func (s *memStore) CountOutgoingApplicationsTx(_ context.Context, _ tx.Queryer, p identity.PlayerID) (int64, error) {
	var n int64
	for _, a := range s.apps {
		if a.PlayerID == p {
			n++
		}
	}
	return n, nil
}
func (s *memStore) CountGuildApplicationsTx(_ context.Context, _ tx.Queryer, g guild.ID) (int64, error) {
	var n int64
	for _, a := range s.apps {
		if a.GuildID == g {
			n++
		}
	}
	return n, nil
}
func (s *memStore) SaveGuildTx(_ context.Context, _ tx.Tx, g guild.Guild, _ int64) error {
	s.guilds[g.ID] = g
	return nil
}
func (s *memStore) ListGuilds(_ context.Context, server identity.LogicalServerID, _ int) ([]guild.Guild, error) {
	out := []guild.Guild{}
	for _, g := range s.guilds {
		if g.LogicalServerID == server && g.RetiredAt == nil {
			out = append(out, g)
		}
	}
	return out, nil
}
func (s *memStore) LockApplicationTx(ctx context.Context, q tx.Tx, g guild.ID, p identity.PlayerID) (guild.Application, bool, error) {
	return s.FindApplicationTx(ctx, q, g, p)
}
func (s *memStore) ListGuildApplications(_ context.Context, g guild.ID) ([]guild.Application, error) {
	out := []guild.Application{}
	for _, a := range s.apps {
		if a.GuildID == g {
			out = append(out, a)
		}
	}
	return out, nil
}
func (s *memStore) ListPlayerApplications(_ context.Context, p identity.PlayerID) ([]guild.Application, error) {
	out := []guild.Application{}
	for _, a := range s.apps {
		if a.PlayerID == p {
			out = append(out, a)
		}
	}
	return out, nil
}
func (s *memStore) FindInviteTx(_ context.Context, _ tx.Queryer, g guild.ID, p identity.PlayerID) (guild.Invite, bool, error) {
	i, ok := s.invites[appKey(g, p)]
	return i, ok, nil
}
func (s *memStore) LockInviteTx(ctx context.Context, q tx.Tx, g guild.ID, p identity.PlayerID) (guild.Invite, bool, error) {
	return s.FindInviteTx(ctx, q, g, p)
}
func (s *memStore) UpsertInviteTx(_ context.Context, _ tx.Tx, i guild.Invite) error {
	s.invites[appKey(i.GuildID, i.InvitedPlayerID)] = i
	return nil
}
func (s *memStore) DeleteInviteTx(_ context.Context, _ tx.Tx, g guild.ID, p identity.PlayerID) error {
	delete(s.invites, appKey(g, p))
	return nil
}
func (s *memStore) CountInvitesSinceTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, _ time.Time) (int64, error) {
	return 0, nil
}
func (s *memStore) AppendInviteSendTx(_ context.Context, _ tx.Tx, _ guild.ID, _, _ identity.PlayerID, _ time.Time, _ string, _ ids.UUID) error {
	return nil
}
func (s *memStore) ListMemberships(_ context.Context, g guild.ID) ([]guild.Membership, error) {
	out := []guild.Membership{}
	for _, m := range s.members {
		if m.GuildID == g {
			out = append(out, m)
		}
	}
	return out, nil
}
func (s *memStore) AppendAuditTx(_ context.Context, _ tx.Tx, _ guild.ID, k string, _ identity.PlayerID, _ identity.PlayerID, _ time.Time, _ string, _ ids.UUID, _ string) error {
	s.audits = append(s.audits, k)
	return nil
}

type levelPort struct {
	level  int64
	before func() bool
}

func (p levelPort) PlayerLevelTx(context.Context, tx.Tx, identity.PlayerID) (int64, error) {
	if p.before != nil && !p.before() {
		return 0, errors.New("lower-ranked guild row not established before level lock")
	}
	return p.level, nil
}

type scalarPort struct{}

func (scalarPort) DebitScalarTx(context.Context, tx.Tx, identity.PlayerID, string, int64, time.Time) (economy.ScalarBalance, error) {
	return economy.ScalarBalance{}, nil
}

type combinedPort struct {
	level  int64
	calls  int
	before func() bool
}

func (p *combinedPort) AuthorizeLevelAndDebitScalarTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, min int64, _ string, _ int64, at time.Time) (int64, economy.ScalarBalance, error) {
	p.calls++
	if p.before != nil && !p.before() {
		return 0, economy.ScalarBalance{}, errors.New("guild rows not established before I5 locks")
	}
	if p.level < min {
		return p.level, economy.ScalarBalance{}, errors.New("low")
	}
	return p.level, economy.ScalarBalance{PlayerID: pid, ResourceKey: "crystal", Amount: 500, StateVersion: 2, UpdatedAt: at}, nil
}

func actorFixture(t *testing.T, pid identity.PlayerID) identity.ActorContext {
	t.Helper()
	mk := func(b byte) ids.UUID { var u ids.UUID; u[15] = b; return u }
	aid, _ := identity.AccountIDFrom(mk(1))
	sid, _ := identity.SessionIDFrom(mk(2))
	cid, _ := identity.ContextIDFrom(mk(3))
	return identity.ActorContext{AccountID: aid, AccountUID: "uid", SessionID: sid, ContextID: cid, LogicalServerID: 1, PlayerID: pid, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func opFixtureSeed(t *testing.T, at time.Time, seed byte) operation.Context {
	t.Helper()
	op, err := (operation.Factory{Clock: clock.Fixed{T: at}, Random: bytes.NewReader(bytes.Repeat([]byte{seed}, 256))}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	return op
}
func opFixture(t *testing.T, at time.Time) operation.Context {
	return opFixtureSeed(t, at, 7)
}
func serviceFixture(t *testing.T, st *memStore, level LevelReader, combined LevelAndScalarDebiter) (Service, *receiptMem) {
	t.Helper()
	p := PolicyBinding{Revision: "test-guild-policy-v1", Policy: Policy{
		CreateLevel: 32, CreateCrystalCost: 500, RenameCrystalCost: 500,
		GuildApplicantCap: 50, NameMinChars: 1, NameMaxChars: 10,
		JoinOtherAfterLeaveSeconds: 3600, ReapplyPreviousGuildSeconds: 172800,
		JoinLevelMin: 32, JoinLevelMax: 80, JoinsLimit: 3, OutgoingApplicationCap: 3,
		BulletinMinChars: 0, BulletinMaxChars: 40, MemberCap: 50, DeputyLimit: 5, InitialVitality: 20000,
		InviteSendLimit: 10, InviteLifetimeSeconds: 172800, GuildIcons: []int64{20010001, 20010002, 30010001},
	}}
	if err := p.Validate(); err != nil {
		t.Fatal(err)
	}
	rm := &receiptMem{m: map[string]receipt.Receipt{}}
	timed := appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: staticTime{at: time.Unix(2000, 0).UTC()}}, Runner: tx.Runner{DB: testDB{}}}
	return Service{Timed: timed, Store: st, Fencer: testFence{}, PlayerRoots: rootPort{}, Level: level, Scalar: scalarPort{}, LevelAndScalar: combined, Receipts: rm, ReceiptRead: rm, Policy: p}, rm
}

func TestCreateEstablishesGuildRowsBeforeI5AndConvergesStockRetry(t *testing.T) {
	st := newMemStore()
	actor := actorFixture(t, 100001)
	cp := &combinedPort{level: 50}
	cp.before = func() bool { _, m := st.members[actor.PlayerID]; _, g := st.guilds[guild.ID(1000001)]; return m && g }
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, cp)
	req := CreateRequest{Name: "Alpha", Icon: 20010001, IconFrame: 0}
	got, err := svc.Create(context.Background(), actor, req, opFixture(t, time.Unix(1000, 0).UTC()))
	if err != nil {
		t.Fatal(err)
	}
	if got.GuildID != 1000001 || got.Role != int16(guild.Leader) || cp.calls != 1 {
		t.Fatalf("got=%+v debitCalls=%d", got, cp.calls)
	}
	again, err := svc.Create(context.Background(), actor, req, opFixture(t, time.Unix(1001, 0).UTC()))
	if err != nil {
		t.Fatal(err)
	}
	if !again.Replayed || again.GuildID != got.GuildID || cp.calls != 1 {
		t.Fatalf("retry=%+v debitCalls=%d", again, cp.calls)
	}
}

func TestApplyWorkflowCreatesApplicationBeforeI5LevelLock(t *testing.T) {
	st := newMemStore()
	g := guild.Guild{ID: 1000009, LogicalServerID: 1, Name: "G", Icon: 20010001, ApplyType: guild.ApplyByApplication, MinAllowLevel: 32, Vitality: 1, PolicyRevision: "p", StateVersion: 1, CreatedAt: time.Unix(1, 0).UTC(), UpdatedAt: time.Unix(1, 0).UTC()}
	st.guilds[g.ID] = g
	actor := actorFixture(t, 100002)
	lvl := levelPort{level: 50, before: func() bool { _, ok := st.apps[appKey(g.ID, actor.PlayerID)]; return ok }}
	cp := &combinedPort{level: 50}
	svc, _ := serviceFixture(t, st, lvl, cp)
	got, err := svc.ApplyOrJoin(context.Background(), actor, g.ID, opFixture(t, time.Unix(1000, 0).UTC()))
	if err != nil {
		t.Fatal(err)
	}
	if !got.Applied || got.Joined {
		t.Fatalf("got=%+v", got)
	}
	again, err := svc.ApplyOrJoin(context.Background(), actor, g.ID, opFixture(t, time.Unix(1001, 0).UTC()))
	if err != nil {
		t.Fatal(err)
	}
	if !again.Applied || !again.Replayed {
		t.Fatalf("retry=%+v", again)
	}
}

func TestImmediateJoinCreatesMembershipBeforeI5LevelLock(t *testing.T) {
	st := newMemStore()
	g := guild.Guild{ID: 1000010, LogicalServerID: 1, Name: "G", Icon: 20010001, ApplyType: guild.ApplyImmediate, MinAllowLevel: 32, Vitality: 1, PolicyRevision: "p", StateVersion: 1, CreatedAt: time.Unix(1, 0).UTC(), UpdatedAt: time.Unix(1, 0).UTC()}
	st.guilds[g.ID] = g
	actor := actorFixture(t, 100003)
	lvl := levelPort{level: 50, before: func() bool { m, ok := st.members[actor.PlayerID]; return ok && m.GuildID == g.ID }}
	cp := &combinedPort{level: 50}
	svc, _ := serviceFixture(t, st, lvl, cp)
	got, err := svc.ApplyOrJoin(context.Background(), actor, g.ID, opFixture(t, time.Unix(1000, 0).UTC()))
	if err != nil {
		t.Fatal(err)
	}
	if !got.Joined || got.Applied {
		t.Fatalf("got=%+v", got)
	}
}

type countScalar struct{ calls int }

func (p *countScalar) DebitScalarTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, key string, amount int64, at time.Time) (economy.ScalarBalance, error) {
	p.calls++
	return economy.ScalarBalance{PlayerID: pid, ResourceKey: key, Amount: 1000 - amount, StateVersion: int64(p.calls + 1), UpdatedAt: at}, nil
}

func guildFixture(id guild.ID) guild.Guild {
	return guild.Guild{ID: id, LogicalServerID: 1, Name: "Guild", Icon: 20010001, IconFrame: 0, Description: "", ApplyType: guild.ApplyByApplication, MinAllowLevel: 32, Vitality: 20000, PolicyRevision: "p", StateVersion: 1, CreatedAt: time.Unix(1, 0).UTC(), UpdatedAt: time.Unix(1, 0).UTC()}
}
func memberFixture(pid identity.PlayerID, gid guild.ID, role guild.Role) guild.Membership {
	return guild.Membership{PlayerID: pid, GuildID: gid, Role: role, JoinedAt: time.Unix(2, 0).UTC(), MembershipVersion: 1, StateVersion: 1, UpdatedAt: time.Unix(2, 0).UTC()}
}
func (s *memStore) seedMembership(m guild.Membership) {
	s.members[m.PlayerID] = m
	e := guild.MembershipEvent{PlayerID: m.PlayerID, GuildID: m.GuildID, Kind: guild.EventJoin, OccurredAt: m.JoinedAt, ActorPlayerID: m.PlayerID, PolicyRevision: "p"}
	if err := s.AppendMembershipEventTx(context.Background(), nil, e, ids.UUID{}); err != nil {
		panic(err)
	}
}

func TestLeaderTransferDemotesCurrentLeaderBeforePromotingTarget(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000020)
	st.guilds[gid] = guildFixture(gid)
	leader := identity.PlayerID(100010)
	target := identity.PlayerID(100011)
	st.seedMembership(memberFixture(leader, gid, guild.Leader))
	st.seedMembership(memberFixture(target, gid, guild.Deputy))
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	_, err := svc.SetRole(context.Background(), actorFixture(t, leader), RoleRequest{MemberID: target, Role: guild.Leader}, opFixture(t, time.Unix(1000, 0).UTC()))
	if err != nil {
		t.Fatal(err)
	}
	if got := st.members[leader].Role; got != guild.Member {
		t.Fatalf("old leader role=%v", got)
	}
	if got := st.members[target].Role; got != guild.Leader {
		t.Fatalf("target role=%v", got)
	}
	if len(st.roleSaves) < 2 || st.roleSaves[0] != leader || st.roleSaves[1] != target {
		t.Fatalf("save order=%v", st.roleSaves)
	}
}

func TestDeputyCannotSetRoles(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000021)
	st.guilds[gid] = guildFixture(gid)
	actor := identity.PlayerID(100012)
	target := identity.PlayerID(100013)
	st.seedMembership(memberFixture(actor, gid, guild.Deputy))
	st.seedMembership(memberFixture(target, gid, guild.Member))
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	_, err := svc.SetRole(context.Background(), actorFixture(t, actor), RoleRequest{MemberID: target, Role: guild.Deputy}, opFixture(t, time.Unix(1000, 0).UTC()))
	if !errors.Is(err, ErrGuildPermission) {
		t.Fatalf("err=%v", err)
	}
}

func TestAcceptApplicationCreatesCanonicalMembership(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000022)
	st.guilds[gid] = guildFixture(gid)
	leader := identity.PlayerID(100014)
	target := identity.PlayerID(100015)
	st.seedMembership(memberFixture(leader, gid, guild.Leader))
	st.apps[appKey(gid, target)] = guild.Application{GuildID: gid, PlayerID: target, Generation: 7, CreatedAt: time.Unix(3, 0).UTC(), StateVersion: 1}
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	got, err := svc.AcceptApplication(context.Background(), actorFixture(t, leader), target, opFixture(t, time.Unix(1000, 0).UTC()))
	if err != nil {
		t.Fatal(err)
	}
	if got.GuildID != int64(gid) {
		t.Fatalf("got=%+v", got)
	}
	m, ok := st.members[target]
	if !ok || m.GuildID != gid || m.Role != guild.Member {
		t.Fatalf("membership=%+v ok=%v", m, ok)
	}
	if _, ok := st.apps[appKey(gid, target)]; ok {
		t.Fatal("application not cleared")
	}
}

func TestInviteThenAcceptInvite(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000023)
	st.guilds[gid] = guildFixture(gid)
	leader := identity.PlayerID(100016)
	target := identity.PlayerID(100017)
	st.seedMembership(memberFixture(leader, gid, guild.Leader))
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	if _, err := svc.Invite(context.Background(), actorFixture(t, leader), target, opFixture(t, time.Unix(1000, 0).UTC())); err != nil {
		t.Fatal(err)
	}
	if _, ok := st.invites[appKey(gid, target)]; !ok {
		t.Fatal("invite missing")
	}
	if _, err := svc.AcceptInvite(context.Background(), actorFixture(t, target), gid, opFixture(t, time.Unix(1001, 0).UTC())); err != nil {
		t.Fatal(err)
	}
	m, ok := st.members[target]
	if !ok || m.GuildID != gid {
		t.Fatalf("membership=%+v ok=%v", m, ok)
	}
	if _, ok := st.invites[appKey(gid, target)]; ok {
		t.Fatal("invite not consumed")
	}
}

func TestLeaderCannotLeave(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000024)
	st.guilds[gid] = guildFixture(gid)
	pid := identity.PlayerID(100018)
	st.seedMembership(memberFixture(pid, gid, guild.Leader))
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	_, err := svc.Leave(context.Background(), actorFixture(t, pid), opFixture(t, time.Unix(1000, 0).UTC()))
	if !errors.Is(err, ErrCannotLeaveLeader) {
		t.Fatalf("err=%v", err)
	}
}

func TestRenameDebitsOnceAndRetryConverges(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000025)
	g := guildFixture(gid)
	st.guilds[gid] = g
	pid := identity.PlayerID(100019)
	st.seedMembership(memberFixture(pid, gid, guild.Leader))
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	cs := &countScalar{}
	svc.Scalar = cs
	req := SettingsRequest{Name: "Renamed", Icon: g.Icon, IconFrame: 0, MinAllowLevel: 32, ApplyType: guild.ApplyByApplication}
	if _, err := svc.UpdateSettings(context.Background(), actorFixture(t, pid), req, opFixture(t, time.Unix(1000, 0).UTC())); err != nil {
		t.Fatal(err)
	}
	if cs.calls != 1 {
		t.Fatalf("debits=%d", cs.calls)
	}
	got, err := svc.UpdateSettings(context.Background(), actorFixture(t, pid), req, opFixture(t, time.Unix(1001, 0).UTC()))
	if err != nil {
		t.Fatal(err)
	}
	if !got.Replayed || cs.calls != 1 {
		t.Fatalf("got=%+v debits=%d", got, cs.calls)
	}
}

func TestCreateRejectsDuplicateActiveNameWithinLogicalServer(t *testing.T) {
	st := newMemStore()
	cp := &combinedPort{level: 50}
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, cp)
	req := CreateRequest{Name: "Alpha", Icon: 20010001, IconFrame: 0}
	if _, err := svc.Create(context.Background(), actorFixture(t, 100030), req, opFixture(t, time.Unix(1000, 0).UTC())); err != nil {
		t.Fatal(err)
	}
	_, err := svc.Create(context.Background(), actorFixture(t, 100031), req, opFixture(t, time.Unix(1001, 0).UTC()))
	if !errors.Is(err, ErrGuildNameTaken) {
		t.Fatalf("err=%v", err)
	}
	if cp.calls != 1 {
		t.Fatalf("duplicate create reached I5 debit: calls=%d", cp.calls)
	}
	if len(st.guilds) != 1 {
		t.Fatalf("guilds=%d", len(st.guilds))
	}
}

func TestCreateAllowsSameNameOnDifferentLogicalServerByI6CPolicy(t *testing.T) {
	st := newMemStore()
	cp := &combinedPort{level: 50}
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, cp)
	req := CreateRequest{Name: "Alpha", Icon: 20010001, IconFrame: 0}
	if _, err := svc.Create(context.Background(), actorFixture(t, 100032), req, opFixture(t, time.Unix(1000, 0).UTC())); err != nil {
		t.Fatal(err)
	}
	actor2 := actorFixture(t, 200032)
	actor2.LogicalServerID = 2
	got, err := svc.Create(context.Background(), actor2, req, opFixture(t, time.Unix(1001, 0).UTC()))
	if err != nil {
		t.Fatal(err)
	}
	if got.GuildID/1_000_000 != 2 {
		t.Fatalf("guild id=%d", got.GuildID)
	}
}

func TestRenameCollisionRejectedBeforeCrystalDebit(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000030)
	other := guild.ID(1000031)
	g := guildFixture(gid)
	g.Name = "First"
	g2 := guildFixture(other)
	g2.Name = "Taken"
	st.guilds[gid], st.guilds[other] = g, g2
	pid := identity.PlayerID(100033)
	st.seedMembership(memberFixture(pid, gid, guild.Leader))
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	cs := &countScalar{}
	svc.Scalar = cs
	req := SettingsRequest{Name: "Taken", Icon: g.Icon, IconFrame: 0, MinAllowLevel: 32, ApplyType: guild.ApplyByApplication}
	_, err := svc.UpdateSettings(context.Background(), actorFixture(t, pid), req, opFixture(t, time.Unix(1000, 0).UTC()))
	if !errors.Is(err, ErrGuildNameTaken) {
		t.Fatalf("err=%v", err)
	}
	if len(st.locks) < 2 || st.locks[0] != "allocator" || st.locks[1] != "guild" {
		t.Fatalf("rename lock order=%v", st.locks)
	}
	if cs.calls != 0 {
		t.Fatalf("rename collision debited crystal: calls=%d", cs.calls)
	}
	if got := st.guilds[gid].Name; got != "First" {
		t.Fatalf("name mutated to %q", got)
	}
}

func TestSetRoleRejectsSixthDeputy(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000032)
	st.guilds[gid] = guildFixture(gid)
	leader := identity.PlayerID(100034)
	target := identity.PlayerID(100035)
	st.seedMembership(memberFixture(leader, gid, guild.Leader))
	st.seedMembership(memberFixture(target, gid, guild.Member))
	for i := int64(0); i < 5; i++ {
		pid := identity.PlayerID(100040 + i)
		st.seedMembership(memberFixture(pid, gid, guild.Deputy))
	}
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	_, err := svc.SetRole(context.Background(), actorFixture(t, leader), RoleRequest{MemberID: target, Role: guild.Deputy}, opFixture(t, time.Unix(1000, 0).UTC()))
	if !errors.Is(err, ErrDeputyLimit) {
		t.Fatalf("err=%v", err)
	}
	if got := st.members[target].Role; got != guild.Member {
		t.Fatalf("target role mutated to %v", got)
	}
}

func TestApplyByApplicationRejectsMemberFullGuildBeforeApplication(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000033)
	st.guilds[gid] = guildFixture(gid)
	for i := int64(0); i < 50; i++ {
		pid := identity.PlayerID(101000 + i)
		st.seedMembership(memberFixture(pid, gid, guild.Member))
	}
	actor := actorFixture(t, 100036)
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	_, err := svc.ApplyOrJoin(context.Background(), actor, gid, opFixture(t, time.Unix(1000, 0).UTC()))
	if !errors.Is(err, ErrGuildApplicationFull) {
		t.Fatalf("err=%v", err)
	}
	if _, ok := st.apps[appKey(gid, actor.PlayerID)]; ok {
		t.Fatal("application created for member-full guild")
	}
}

func TestApplyCooldownDistinguishesOtherAndSameGuild(t *testing.T) {
	gid := guild.ID(1000034)
	cases := []struct {
		name string
		last guild.ID
		want JoinCooldownKind
	}{
		{name: "other", last: guild.ID(1000099), want: JoinCooldownOtherGuild},
		{name: "same", last: gid, want: JoinCooldownSameGuild},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			st := newMemStore()
			st.guilds[gid] = guildFixture(gid)
			actor := actorFixture(t, 100037)
			st.events = append(st.events, guild.MembershipEvent{PlayerID: actor.PlayerID, GuildID: tc.last, Kind: guild.EventLeave, OccurredAt: time.Unix(1900, 0).UTC(), ActorPlayerID: actor.PlayerID, PolicyRevision: "p"})
			svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
			_, err := svc.ApplyOrJoin(context.Background(), actor, gid, opFixture(t, time.Unix(1000, 0).UTC()))
			var wait *CantJoinError
			if !errors.As(err, &wait) || wait.Kind != tc.want || wait.RemainingSeconds <= 0 {
				t.Fatalf("err=%v wait=%+v", err, wait)
			}
		})
	}
}

func TestF1LeaveRejoinSameGuildUsesNewMembershipIncarnation(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000100)
	st.guilds[gid] = guildFixture(gid)
	pid := identity.PlayerID(110001)
	st.seedMembership(memberFixture(pid, gid, guild.Member))
	svc, rm := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})

	if _, err := svc.Leave(context.Background(), actorFixture(t, pid), opFixtureSeed(t, time.Unix(1000, 0).UTC(), 11)); err != nil {
		t.Fatal(err)
	}
	if _, ok := st.members[pid]; ok {
		t.Fatal("first leave did not remove membership")
	}
	firstReceipts := len(rm.m)
	st.seedMembership(memberFixture(pid, gid, guild.Member))
	if _, err := svc.Leave(context.Background(), actorFixture(t, pid), opFixtureSeed(t, time.Unix(1001, 0).UTC(), 12)); err != nil {
		t.Fatal(err)
	}
	if _, ok := st.members[pid]; ok {
		t.Fatal("second leave did not remove rejoined membership")
	}
	if len(rm.m) != firstReceipts+1 {
		t.Fatalf("second membership lifecycle reused old receipt: before=%d after=%d", firstReceipts, len(rm.m))
	}
	for _, r := range rm.m {
		if r.Identity.Operation == "leave" && r.ResultSchema != "gxb.i6c.guild.leave.v2" {
			t.Fatalf("leave receipt schema=%q", r.ResultSchema)
		}
	}
}

func TestF1KickRejoinSameGuildUsesNewMembershipIncarnation(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000101)
	st.guilds[gid] = guildFixture(gid)
	leader := identity.PlayerID(110010)
	target := identity.PlayerID(110011)
	st.seedMembership(memberFixture(leader, gid, guild.Leader))
	st.seedMembership(memberFixture(target, gid, guild.Member))
	svc, rm := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})

	if _, err := svc.Kick(context.Background(), actorFixture(t, leader), target, opFixtureSeed(t, time.Unix(1000, 0).UTC(), 21)); err != nil {
		t.Fatal(err)
	}
	firstReceipts := len(rm.m)
	st.seedMembership(memberFixture(target, gid, guild.Member))
	if _, err := svc.Kick(context.Background(), actorFixture(t, leader), target, opFixtureSeed(t, time.Unix(1001, 0).UTC(), 22)); err != nil {
		t.Fatal(err)
	}
	if _, ok := st.members[target]; ok {
		t.Fatal("second kick did not remove rejoined target")
	}
	if len(rm.m) != firstReceipts+1 {
		t.Fatalf("second target lifecycle reused old kick receipt: before=%d after=%d", firstReceipts, len(rm.m))
	}
}

func TestF1RoleChangeAfterRejoinUsesNewMembershipIncarnation(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000102)
	st.guilds[gid] = guildFixture(gid)
	leader := identity.PlayerID(110020)
	target := identity.PlayerID(110021)
	st.seedMembership(memberFixture(leader, gid, guild.Leader))
	st.seedMembership(memberFixture(target, gid, guild.Member))
	svc, rm := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})

	if _, err := svc.SetRole(context.Background(), actorFixture(t, leader), RoleRequest{MemberID: target, Role: guild.Deputy}, opFixtureSeed(t, time.Unix(1000, 0).UTC(), 31)); err != nil {
		t.Fatal(err)
	}
	if _, err := svc.Leave(context.Background(), actorFixture(t, target), opFixtureSeed(t, time.Unix(1001, 0).UTC(), 32)); err != nil {
		t.Fatal(err)
	}
	st.seedMembership(memberFixture(target, gid, guild.Member))
	before := len(rm.m)
	if _, err := svc.SetRole(context.Background(), actorFixture(t, leader), RoleRequest{MemberID: target, Role: guild.Deputy}, opFixtureSeed(t, time.Unix(1002, 0).UTC(), 33)); err != nil {
		t.Fatal(err)
	}
	if got := st.members[target].Role; got != guild.Deputy {
		t.Fatalf("rejoined target role=%v", got)
	}
	if len(rm.m) != before+1 {
		t.Fatalf("new role intent reused receipt from prior membership lifecycle: before=%d after=%d", before, len(rm.m))
	}
}

func TestF1MembershipMutationFailsClosedWithoutCurrentJoinEvent(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000103)
	st.guilds[gid] = guildFixture(gid)
	pid := identity.PlayerID(110030)
	// Deliberately seed a corrupt membership without its append-only JOIN fact.
	st.members[pid] = memberFixture(pid, gid, guild.Member)
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	_, err := svc.Leave(context.Background(), actorFixture(t, pid), opFixtureSeed(t, time.Unix(1000, 0).UTC(), 41))
	if !errors.Is(err, ErrMembershipIncarnation) {
		t.Fatalf("err=%v", err)
	}
	if _, ok := st.members[pid]; !ok {
		t.Fatal("fail-closed incarnation error mutated membership")
	}
}

func TestF2ApplyCancelApplyCreatesNewCanonicalApplication(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000110)
	st.guilds[gid] = guildFixture(gid)
	pid := identity.PlayerID(120001)
	svc, rm := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})

	first, err := svc.ApplyOrJoin(context.Background(), actorFixture(t, pid), gid, opFixtureSeed(t, time.Unix(1000, 0).UTC(), 51))
	if err != nil || !first.Applied {
		t.Fatalf("first apply=%+v err=%v", first, err)
	}
	gen1 := st.apps[appKey(gid, pid)].Generation
	if _, err := svc.CancelApplication(context.Background(), actorFixture(t, pid), gid, opFixtureSeed(t, time.Unix(1001, 0).UTC(), 52)); err != nil {
		t.Fatal(err)
	}
	if _, ok := st.apps[appKey(gid, pid)]; ok {
		t.Fatal("cancel did not remove current application")
	}
	before := len(rm.m)
	second, err := svc.ApplyOrJoin(context.Background(), actorFixture(t, pid), gid, opFixtureSeed(t, time.Unix(1002, 0).UTC(), 53))
	if err != nil || !second.Applied || second.Replayed {
		t.Fatalf("second apply=%+v err=%v", second, err)
	}
	a2, ok := st.apps[appKey(gid, pid)]
	if !ok {
		t.Fatal("second apply acknowledged without canonical application")
	}
	if a2.Generation == gen1 {
		t.Fatalf("new application lifecycle reused generation %d", gen1)
	}
	if len(rm.m) != before+1 {
		t.Fatalf("new application lifecycle did not create a distinct v2 receipt: before=%d after=%d", before, len(rm.m))
	}
}

func TestF2ApplyRefuseApplyCreatesNewCanonicalApplication(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000111)
	st.guilds[gid] = guildFixture(gid)
	leader := identity.PlayerID(120010)
	applicant := identity.PlayerID(120011)
	st.seedMembership(memberFixture(leader, gid, guild.Leader))
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})

	if _, err := svc.ApplyOrJoin(context.Background(), actorFixture(t, applicant), gid, opFixtureSeed(t, time.Unix(1000, 0).UTC(), 61)); err != nil {
		t.Fatal(err)
	}
	gen1 := st.apps[appKey(gid, applicant)].Generation
	if _, err := svc.RefuseApplication(context.Background(), actorFixture(t, leader), applicant, opFixtureSeed(t, time.Unix(1001, 0).UTC(), 62)); err != nil {
		t.Fatal(err)
	}
	second, err := svc.ApplyOrJoin(context.Background(), actorFixture(t, applicant), gid, opFixtureSeed(t, time.Unix(1002, 0).UTC(), 63))
	if err != nil || !second.Applied || second.Replayed {
		t.Fatalf("second apply=%+v err=%v", second, err)
	}
	a2, ok := st.apps[appKey(gid, applicant)]
	if !ok {
		t.Fatal("reapply after refuse acknowledged without application")
	}
	if a2.Generation == gen1 {
		t.Fatalf("reapply after refuse reused generation %d", gen1)
	}
}

func TestF2ExistingApplicationConvergesBeforeCreationOnlyCapacityGates(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000112)
	st.guilds[gid] = guildFixture(gid)
	pid := identity.PlayerID(120020)
	st.apps[appKey(gid, pid)] = guild.Application{GuildID: gid, PlayerID: pid, Generation: 77, CreatedAt: time.Unix(3, 0).UTC(), StateVersion: 1}
	// Fill both member capacity and the player's outgoing application capacity after
	// the canonical target application already exists. Neither may invalidate it.
	for i := int64(0); i < 50; i++ {
		st.seedMembership(memberFixture(identity.PlayerID(130000+i), gid, guild.Member))
	}
	for i := int64(0); i < 3; i++ {
		other := guild.ID(1100000 + i)
		st.apps[appKey(other, pid)] = guild.Application{GuildID: other, PlayerID: pid, Generation: 100 + i, CreatedAt: time.Unix(4, 0).UTC(), StateVersion: 1}
	}
	svc, _ := serviceFixture(t, st, levelPort{level: 1}, &combinedPort{level: 50})
	got, err := svc.ApplyOrJoin(context.Background(), actorFixture(t, pid), gid, opFixtureSeed(t, time.Unix(1000, 0).UTC(), 71))
	if err != nil || !got.Applied || !got.Replayed {
		t.Fatalf("existing canonical application did not converge: got=%+v err=%v", got, err)
	}
	if _, ok := st.apps[appKey(gid, pid)]; !ok {
		t.Fatal("existing application disappeared")
	}
}

func TestF2CurrentImmediateModeOverridesPendingApplicationAndClearsOutgoing(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000113)
	g := guildFixture(gid)
	g.ApplyType = guild.ApplyImmediate
	st.guilds[gid] = g
	pid := identity.PlayerID(120030)
	st.apps[appKey(gid, pid)] = guild.Application{GuildID: gid, PlayerID: pid, Generation: 80, CreatedAt: time.Unix(3, 0).UTC(), StateVersion: 1}
	other := guild.ID(1000999)
	st.apps[appKey(other, pid)] = guild.Application{GuildID: other, PlayerID: pid, Generation: 81, CreatedAt: time.Unix(3, 0).UTC(), StateVersion: 1}
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	got, err := svc.ApplyOrJoin(context.Background(), actorFixture(t, pid), gid, opFixtureSeed(t, time.Unix(1000, 0).UTC(), 81))
	if err != nil || !got.Joined || got.Applied {
		t.Fatalf("got=%+v err=%v", got, err)
	}
	if m, ok := st.members[pid]; !ok || m.GuildID != gid {
		t.Fatalf("membership=%+v ok=%v", m, ok)
	}
	for _, a := range st.apps {
		if a.PlayerID == pid {
			t.Fatalf("obsolete outgoing application survived immediate join: %+v", a)
		}
	}
}

func TestF2CurrentClosedModeOverridesPendingApplicationWithoutPurgingIt(t *testing.T) {
	st := newMemStore()
	gid := guild.ID(1000114)
	g := guildFixture(gid)
	g.ApplyType = guild.ApplyClosed
	st.guilds[gid] = g
	pid := identity.PlayerID(120040)
	want := guild.Application{GuildID: gid, PlayerID: pid, Generation: 82, CreatedAt: time.Unix(3, 0).UTC(), StateVersion: 1}
	st.apps[appKey(gid, pid)] = want
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	_, err := svc.ApplyOrJoin(context.Background(), actorFixture(t, pid), gid, opFixtureSeed(t, time.Unix(1000, 0).UTC(), 91))
	if !errors.Is(err, ErrGuildClosed) {
		t.Fatalf("err=%v", err)
	}
	if got, ok := st.apps[appKey(gid, pid)]; !ok || got.Generation != want.Generation {
		t.Fatalf("closed-mode request improperly purged pending application: got=%+v ok=%v", got, ok)
	}
}

func TestF2CreateClearsAllOutgoingApplications(t *testing.T) {
	st := newMemStore()
	pid := identity.PlayerID(120050)
	st.apps[appKey(1000200, pid)] = guild.Application{GuildID: 1000200, PlayerID: pid, Generation: 91, CreatedAt: time.Unix(3, 0).UTC(), StateVersion: 1}
	st.apps[appKey(1000201, pid)] = guild.Application{GuildID: 1000201, PlayerID: pid, Generation: 92, CreatedAt: time.Unix(3, 0).UTC(), StateVersion: 1}
	svc, _ := serviceFixture(t, st, levelPort{level: 50}, &combinedPort{level: 50})
	got, err := svc.Create(context.Background(), actorFixture(t, pid), CreateRequest{Name: "Creator", Icon: 20010001}, opFixtureSeed(t, time.Unix(1000, 0).UTC(), 101))
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := st.members[pid]; !ok || got.GuildID == 0 {
		t.Fatalf("create did not establish membership: got=%+v ok=%v", got, ok)
	}
	for _, a := range st.apps {
		if a.PlayerID == pid {
			t.Fatalf("obsolete outgoing application survived Guild Create: %+v", a)
		}
	}
}
