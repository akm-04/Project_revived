//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type positiveAwakening struct{ publicstats.Awakening }

func (a positiveAwakening) RawAwakeningTx(c context.Context, scope ca.CoherentReadScope, ref character.HeroRef) (publicstats.AwakeningObservation, error) {
	observation, err := a.Awakening.RawAwakeningTx(c, scope, ref)
	observation.RawStage = 1
	return observation, err
}

// injectedRoster adds a key to every Hero roster row, as an enabled producer
// the registry does not support would.
type injectedRoster struct {
	combat.Roster
	key string
}

func (r injectedRoster) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, full bool, at time.Time, detail map[string]any) error {
	if err := r.Roster.OverlayMID1(c, q, a, full, at, detail); err != nil {
		return err
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	for _, row := range rows {
		row.(map[string]any)[r.key] = []any{}
	}
	return nil
}

func ownedRequest(a identity.ActorContext, ref character.HeroRef, scope, name string) combat.StartRequest {
	locator := d.Locator{DomainKind: "i8-3a-fixture-mode", AuthorityScope: scope, DomainLocator: fmt.Sprintf("%d/%s", a.PlayerID, name)}
	return combat.StartRequest{Actor: a, Locator: locator, GenerationRef: "g", StartFingerprint: fingerprint(scope + name), Battle: combat.BattleRequest{CampaignType: 1,
		TeamA:  []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: ref.PartnerID}},
		WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
}

// I8-3A D05: an enabled producer the pinned registry does not support refuses
// START before anything is written.
func TestI8_3AUnsupportedProducerRefusesStartNative(t *testing.T) {
	pool := pool(t)
	server := rankingServer(t, pool)
	a, rev, ref := combatOwner(t, pool, server)
	base := combatService(t, pool)
	cases := map[string]func(combat.Service) combat.Service{
		"positive-twice-awake": func(s combat.Service) combat.Service {
			s.Inputs.Awakening = positiveAwakening{s.Inputs.Awakening}
			return s
		},
		"declared-inactive-buffs": func(s combat.Service) combat.Service {
			s.Inputs.Heroes = injectedRoster{s.Inputs.Heroes, "buffs"}
			return s
		},
		"unregistered-key": func(s combat.Service) combat.Service {
			s.Inputs.Heroes = injectedRoster{s.Inputs.Heroes, "rune_items"}
			return s
		},
	}
	for name, service := range cases {
		before := combatRows(t, pool)
		_, err := fixtureStart(t, service(base), rev, ownedRequest(a, ref, "refusals", name), pool)
		if !errors.Is(err, d.ErrProviderUnavailable) {
			t.Fatalf("%s: %v", name, err)
		}
		if combatRows(t, pool) != before {
			t.Fatalf("%s wrote combat rows", name)
		}
	}
	started, err := fixtureStart(t, base, rev, ownedRequest(a, ref, "refusals", "control"), pool)
	if err != nil || started.Attempt.ID.IsZero() {
		t.Fatal("registered producers refused", err)
	}
}

func frozenSkin(t *testing.T, raw []byte, hash string) (current float64, skins string) {
	t.Helper()
	snapshot, err := d.DecodeSnapshot(raw, hash)
	if err != nil {
		t.Fatal(err)
	}
	var params map[string]any
	if err = json.Unmarshal(snapshot.Battle.TeamA[0].Params, &params); err != nil {
		t.Fatal(err)
	}
	encoded, _ := json.Marshal(params["skin_ids"])
	current, _ = params["current_skin_id"].(float64)
	return current, string(encoded)
}

// AUDIT-PROFILE-02: a timed worn skin is frozen at START; its later expiry
// changes neither the stored snapshot nor the resolution, and only a new START
// sees the expired appearance (current_skin_id 0, skin absent).
func TestI8_3ATimedSkinFrozenAtStartNative(t *testing.T) {
	pool := pool(t)
	server := rankingServer(t, pool)
	a, rev, ref := combatOwner(t, pool, server)
	s := combatService(t, pool)
	// Source skin item 50001409 -> model 40001001 (Hero 10001001).
	exec(t, pool, `INSERT INTO player_hero_skin_entitlements(player_id,partner_id,model_id,expires_at)VALUES($1,$2,40001001,clock_timestamp()+interval '1 day')`, int64(a.PlayerID), ref.PartnerID)
	exec(t, pool, `UPDATE player_heroes SET current_skin_id=40001001,state_version=state_version+1 WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), ref.PartnerID)
	started, err := fixtureStart(t, s, rev, ownedRequest(a, ref, "timed-skin", "before-expiry"), pool)
	if err != nil {
		t.Fatal(err)
	}
	raw, err := (combatstore.Store{}).ReadSnapshotTx(ctx, pool, started.Attempt.SnapshotHash)
	if err != nil {
		t.Fatal(err)
	}
	if current, skins := frozenSkin(t, raw, started.Attempt.SnapshotHash); current != 40001001 || !strings.Contains(skins, "40001001") {
		t.Fatal("timed skin not frozen", current, skins)
	}
	// Moving expires_at into the past is the same EffectiveAt outcome as the clock passing it.
	exec(t, pool, `UPDATE player_hero_skin_entitlements SET expires_at=clock_timestamp()-interval '1 second' WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), ref.PartnerID)
	resolved, err := s.Resolve(ctx, op(), started.Attempt.ID)
	if err != nil {
		t.Fatal(err)
	}
	stored, _ := (combatstore.Store{}).ReadSnapshotTx(ctx, pool, started.Attempt.SnapshotHash)
	if string(stored) != string(raw) || resolved.Attempt.State != d.ResolutionReady || resolved.Resolution.SnapshotHash != started.Attempt.SnapshotHash {
		t.Fatal("expiry changed the frozen attempt", resolved.Attempt)
	}
	again, err := s.Resolve(ctx, op(), started.Attempt.ID)
	if err != nil || again.Resolution.ReportSHA256 != resolved.Resolution.ReportSHA256 {
		t.Fatal("resolution changed after expiry", err)
	}
	later, err := fixtureStart(t, s, rev, ownedRequest(a, ref, "timed-skin", "after-expiry"), pool)
	if err != nil {
		t.Fatal(err)
	}
	expired, _ := (combatstore.Store{}).ReadSnapshotTx(ctx, pool, later.Attempt.SnapshotHash)
	if current, skins := frozenSkin(t, expired, later.Attempt.SnapshotHash); current != 0 || strings.Contains(skins, "40001001") {
		t.Fatal("expired skin frozen by a later START", current, skins)
	}
}
