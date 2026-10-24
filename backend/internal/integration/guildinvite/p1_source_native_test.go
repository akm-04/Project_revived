//go:build postgres && river

package guildinvite_test

import (
	"context"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strings"
	"testing"
	"time"
)

// This tests actual owner stores and full receipt/source evidence with a finite
// test-only policy reader. It is not producer/API/worker readiness or a gate.
type pinnedPolicy struct{ rev, core string }

func (p pinnedPolicy) ActiveRevision(context.Context, tx.Queryer) (string, error) { return p.rev, nil }
func (p pinnedPolicy) ReadInvitePolicy(_ context.Context, _ tx.Queryer, rev string) (app.ContentPolicy, bool, error) {
	return app.ContentPolicy{Revision: rev, GuildCoreRevision: p.core, PolicyID: gi.PolicyID}, rev == p.rev, nil
}

func TestWorkingP1JSONBSourceScalarReceiptBindingAndCursorRollback(t *testing.T) {
	c, p := database(t)
	w := seedWorld(t, c, p)
	inviter, recipient := w.actors[4].PlayerID, w.actors[3].PlayerID
	tr, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(c)
	gs := guildstore.Store{}
	store := guildinvitestore.Store{}
	k := kernelstore.Store{}
	g, ok, e := gs.LockGuildTx(c, tr, w.guildB)
	if e != nil || !ok {
		t.Fatal(g, ok, e)
	}
	refs, e := policy.NewSet(policy.Ref{Name: "guild-core", Version: g.PolicyRevision}, policy.Ref{Name: "content", Version: strings.Repeat("a", 64)}, policy.Ref{Name: "guild-invite", Version: gi.PolicyID})
	if e != nil {
		t.Fatal(e)
	}
	op := mustOp(t, refs)
	var at time.Time
	if e = tr.QueryRow(c, `SELECT clock_timestamp()`).Scan(&at); e != nil {
		t.Fatal(e)
	}
	at = at.UTC()
	current, version, e := store.LockCursorTx(c, tr, g.ID, recipient)
	if e != nil || current != 0 || version != 0 {
		t.Fatal(current, version, e)
	}
	if e = store.PrepareScopeTx(c, tr, g.ID); e != nil {
		t.Fatal(e)
	}
	serial, e := store.NextIssueSerialTx(c, tr)
	if e != nil {
		t.Fatal(e)
	}
	send, e := gs.AppendInviteSendReturningTx(c, tr, g.ID, inviter, recipient, at, g.PolicyRevision, op.ID)
	if e != nil {
		t.Fatal(e)
	}
	join, joined, e := gs.LatestJoinTx(c, tr, recipient)
	if e != nil {
		t.Fatal(e)
	}
	cid, _ := ids.NewUUID()
	rid := receipt.Identity{OwnerKind: "guild", OwnerKey: fmt.Sprint(g.ID), Domain: "guild", Operation: "invite", SemanticKey: fmt.Sprintf("actorver:1:target:%d:gen:1", recipient)}
	rr, e := receipt.New(op, rid, "I6C_GUILD", "gxb.i6c.guild.invite.v1", json.RawMessage(fmt.Sprintf(`{"guild_id":%d}`, g.ID)), [32]byte{1})
	if e != nil {
		t.Fatal(e)
	}
	rr.ActorAccountUID = "p1-native-fixture"
	rr.ContextID = cid
	rr.PolicyVersion = g.PolicyRevision
	put, e := k.PutTx(c, tr, rr)
	if e != nil {
		t.Fatal(e)
	}
	rr = put.Receipt
	s := gi.Issue{Operation: op, Tuple: gi.Tuple{GuildID: g.ID, Recipient: recipient, Generation: 1}, Serial: serial, Server: g.LogicalServerID, Inviter: inviter, ActorAccountUID: rr.ActorAccountUID, DecisionAt: at, ExpiresAt: at.Add(time.Hour), GuildName: g.Name, SendEventID: send, ContentRevision: strings.Repeat("a", 64), GuildCoreRevision: g.PolicyRevision, PolicyID: gi.PolicyID, Core: gi.CoreReceipt{ID: rr.ID, OwnerKind: rid.OwnerKind, OwnerKey: rid.OwnerKey, Domain: rid.Domain, Operation: rid.Operation, SemanticKey: rid.SemanticKey, Schema: rr.ResultSchema, Fingerprint: rr.RequestFingerprint, OperationClass: rr.OperationClass, PolicyVersion: rr.PolicyVersion, ActorAccountUID: rr.ActorAccountUID, ContextID: rr.ContextID, OperationStartedAt: rr.OperationStartedAt, OperationPolicyRefs: rr.OperationPolicyRefs}}
	if joined {
		s.LastJoinEventID = join.EventID
		s.LastJoinedAt = join.OccurredAt.UTC()
	}
	inv := guild.Invite{GuildID: g.ID, InvitedPlayerID: recipient, Generation: 1, InviterPlayerID: inviter, CreatedAt: at, ExpiresAt: s.ExpiresAt, StateVersion: 1}
	if e = gs.UpsertInviteTx(c, tr, inv); e != nil {
		t.Fatal(e)
	}
	if e = store.AdvanceCursorTx(c, tr, s.Tuple, version, at); e != nil {
		t.Fatal(e)
	}
	d := gi.Delivery{SourceID: op.ID, Recipient: recipient, State: gi.Pending, LastEnqueueAt: at, NextWakeupAt: at.Add(time.Minute)}
	if e = store.InsertIssueTx(c, tr, s, d); e != nil {
		t.Fatal(e)
	}
	if e = gs.BindInviteIssueTx(c, tr, s); e != nil {
		t.Fatal(e)
	}
	reader := app.SourceReader{Store: store, Bindings: gs, Receipts: k, Content: pinnedPolicy{rev: s.ContentRevision, core: g.PolicyRevision}}
	got, e := reader.ReadIssueEvidenceTx(c, tr, op.ID)
	if e != nil {
		t.Fatal(e)
	}
	fp, _ := s.Fingerprint()
	gotfp, _ := got.Fingerprint()
	if fp != gotfp || got.Operation.StartedAt.Nanosecond() != op.StartedAt.Nanosecond() {
		t.Fatal("JSONB lost complete exact source context")
	}
	snap, e := reader.ReadInviteSnapshotTx(c, tr, op.ID)
	if e != nil {
		t.Fatal(e)
	}
	if eligible, e := snap.Eligible(at); e != nil || eligible {
		t.Fatal("existing member eligible", eligible, e)
	}
	if _, e = tr.Exec(c, `UPDATE guild_invite_projection_sources SET source_payload=source_payload||'{"unrecognizedAuthority":true}'::jsonb WHERE source_id=$1::uuid`, op.ID.String()); e != nil {
		t.Fatal(e)
	}
	if _, _, e = store.ReadIssueTx(c, tr, op.ID); e == nil {
		t.Fatal("unknown source evidence field accepted")
	}
	if e = tr.Rollback(c); e != nil {
		t.Fatal(e)
	}
	if _, ok, e = store.ReadIssueTx(c, p, op.ID); e != nil || ok {
		t.Fatal("aborted source visible", ok, e)
	}
	var count int64
	if e = p.QueryRow(c, `SELECT count(*) FROM guild_invite_projection_cursors WHERE guild_id=$1`, int64(g.ID)).Scan(&count); e != nil || count != 0 {
		t.Fatal("abort advanced retained cursor", count, e)
	}
}
