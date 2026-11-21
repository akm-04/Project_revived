//go:build postgres

package publicshowcase_test

import (
	"fmt"
	"strings"
	"sync"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/profileasset"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

// The media tables reference the root, so this runs after a preference write
// creates it; that root keeps is_first_time 0 for the first read to claim.
// A published avatar keeps the sub_type 1 reply complete for the generated
// obligations.
func seedProfileMedia(t *testing.T, p *pg.Pool, a identity.ActorContext) {
	t.Helper()
	operation, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	digest := strings.Repeat("a", 64)
	md5Digest := strings.Repeat("b", 32)
	reference := app.MediaReference{
		Operation: operation,
		Asset:     profileasset.Descriptor{Policy: profileasset.Policy, SHA256: digest, MD5: md5Digest, Size: 1024, Width: 64, Height: 64},
		URL:       "http://profile.test/profile-media/" + operation.String() + "/" + digest + ".png",
	}
	history := app.MediaHistory{Operation: operation, PlayerID: a.PlayerID, Server: a.LogicalServerID, Reference: reference, RootVersion: 1, DecisionAt: at}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	store := publicprofilestore.Store{}
	if e = store.InsertMediaHistoryTx(ctx, tr, history); e != nil {
		t.Fatal(e)
	}
	if e = store.SetCurrentMediaTx(ctx, tr, a.PlayerID, operation); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
}

func firstTimeOf(t *testing.T, out map[string]any) int16 {
	t.Helper()
	value, ok := out["is_first_time"].(int16)
	if !ok {
		t.Fatalf("is_first_time has type %T", out["is_first_time"])
	}
	return value
}

func TestFirstSeenMID1829SelfReadClaimsOnce(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := profileActor(t, p)
	assign(t, p, a, app.Command{Kind: app.IntroCommand, Intro: "seeded"}, op())
	seedProfileMedia(t, p, a)
	d := stockruntime.PublicProfileReadDispatcher{Authority: bookmarkAuthority{a}, Service: composer(t, p)}
	request := bookmarkRequest(1829, a, map[string]any{"to_player_id": int64(a.PlayerID), "sub_type": 1})
	first := d.Dispatch(ctx, request)
	if first.HTTPStatus != 200 {
		t.Fatalf("first self read refused: %+v", first)
	}
	if violations := (replyconformance.Checker{}).CheckRequest(1829, request.Envelope.Params, first.Body); len(violations) != 0 {
		t.Fatalf("first self read reply conformance: %v", violations)
	}
	if got := firstTimeOf(t, first.Body); got != 1 {
		t.Fatalf("first self read is_first_time=%d, want 1", got)
	}
	stored, present := root(t, p, a.PlayerID)
	if !present || stored.Preferences.IsFirstTime != 1 {
		t.Fatalf("first self read stored root %+v present=%v", stored, present)
	}
	second := d.Dispatch(ctx, request)
	if second.HTTPStatus != 200 {
		t.Fatalf("second self read refused: %+v", second)
	}
	if got := firstTimeOf(t, second.Body); got != 0 {
		t.Fatalf("second self read is_first_time=%d, want 0", got)
	}
	b := profileActor(t, p)
	other, e := composer(t, p).Read(ctx, a, app.ReadRequest{MID: 1829, Target: b.PlayerID, Subtype: 1}, op())
	if e != nil {
		t.Fatal(e)
	}
	if got := firstTimeOf(t, other); got != 0 {
		t.Fatalf("other target is_first_time=%d, want 0", got)
	}
	if _, present := root(t, p, b.PlayerID); present {
		t.Fatal("other target materialized a root")
	}
}

func TestFirstSeenMID1829ConcurrentSelfReadsClaimOnce(t *testing.T) {
	p := pool(t)
	installed(t, p)
	s := composer(t, p)
	readTwice := func(a identity.ActorContext) []int16 {
		t.Helper()
		var wait sync.WaitGroup
		values := make(chan int16, 2)
		failures := make(chan error, 2)
		for range 2 {
			wait.Add(1)
			go func() {
				defer wait.Done()
				out, e := s.Read(ctx, a, app.ReadRequest{MID: 1829, Target: a.PlayerID, Subtype: 1}, op())
				if e != nil {
					failures <- e
					return
				}
				value, ok := out["is_first_time"].(int16)
				if !ok {
					failures <- fmt.Errorf("is_first_time has type %T", out["is_first_time"])
					return
				}
				values <- value
			}()
		}
		wait.Wait()
		close(values)
		close(failures)
		for e := range failures {
			t.Fatalf("concurrent self read failed: %v", e)
		}
		var got []int16
		for value := range values {
			got = append(got, value)
		}
		return got
	}
	claims := func(a identity.ActorContext) {
		t.Helper()
		values := readTwice(a)
		count := 0
		for _, value := range values {
			if value == 1 {
				count++
			}
		}
		if len(values) != 2 || count != 1 {
			t.Fatalf("player %d concurrent self reads=%d claims=%d, want 2/1", a.PlayerID, len(values), count)
		}
		stored, present := root(t, p, a.PlayerID)
		if !present || stored.Preferences.IsFirstTime != 1 {
			t.Fatalf("player %d stored root %+v present=%v", a.PlayerID, stored, present)
		}
	}
	// No root yet: the first insert wins the PK and the loser yields.
	first := profileActor(t, p)
	claims(first)
	// Existing root with is_first_time 0: the loser retries after the update.
	existing := profileActor(t, p)
	assign(t, p, existing, app.Command{Kind: app.IntroCommand, Intro: "existing"}, op())
	claims(existing)
}
