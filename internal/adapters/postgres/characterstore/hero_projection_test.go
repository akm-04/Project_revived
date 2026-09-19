package characterstore

import (
	"context"
	"encoding/json"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
)

type heroBootstrapRow struct {
	scan func(...any) error
}

func (r heroBootstrapRow) Scan(dest ...any) error { return r.scan(dest...) }

type heroBootstrapQueryer struct {
	root   character.HeroRoot
	heroes []character.Hero
	calls  int
}

func (q *heroBootstrapQueryer) QueryRow(_ context.Context, query string, _ ...any) tx.Row {
	q.calls++
	switch query {
	case characterqueries.ReadHeroRoot:
		return heroBootstrapRow{scan: func(dest ...any) error {
			*(dest[0].(*int64)) = int64(q.root.PlayerID)
			*(dest[1].(*int64)) = q.root.NextPartnerID
			*(dest[2].(*int64)) = q.root.SortType
			*(dest[3].(*int64)) = q.root.StateVersion
			*(dest[4].(*time.Time)) = q.root.CreatedAt
			*(dest[5].(*time.Time)) = q.root.UpdatedAt
			return nil
		}}
	case characterqueries.ListPlayerHeroes:
		return heroBootstrapRow{scan: func(dest ...any) error {
			type row struct {
				PlayerID                int64     `json:"player_id"`
				PartnerID               int64     `json:"partner_id"`
				TableID                 int64     `json:"table_id"`
				OriginTableID           int64     `json:"origin_table_id"`
				Star                    int64     `json:"star"`
				Level                   int64     `json:"level"`
				Exp                     int64     `json:"exp"`
				Color                   int64     `json:"color"`
				Equip1                  int64     `json:"equip_1"`
				Equip2                  int64     `json:"equip_2"`
				Equip3                  int64     `json:"equip_3"`
				Equip4                  int64     `json:"equip_4"`
				Equip5                  int64     `json:"equip_5"`
				Equip6                  int64     `json:"equip_6"`
				Fumo1                   int64     `json:"fumo_1"`
				Fumo2                   int64     `json:"fumo_2"`
				Fumo3                   int64     `json:"fumo_3"`
				Fumo4                   int64     `json:"fumo_4"`
				Fumo5                   int64     `json:"fumo_5"`
				Fumo6                   int64     `json:"fumo_6"`
				PracticeStr             int64     `json:"practice_str"`
				PracticeInt             int64     `json:"practice_int"`
				PracticeAgi             int64     `json:"practice_agi"`
				StateVersion            int64     `json:"state_version"`
				CreationContentRevision string    `json:"creation_content_revision"`
				CreatedAt               time.Time `json:"created_at"`
				UpdatedAt               time.Time `json:"updated_at"`
			}
			rows := make([]row, 0, len(q.heroes))
			for _, h := range q.heroes {
				rows = append(rows, row{PlayerID: int64(h.PlayerID), PartnerID: h.PartnerID, TableID: h.TableID, OriginTableID: h.OriginTableID, Star: h.Star, Level: h.Level, Exp: h.Exp, Color: h.Color,
					Equip1: h.Equipment[0], Equip2: h.Equipment[1], Equip3: h.Equipment[2], Equip4: h.Equipment[3], Equip5: h.Equipment[4], Equip6: h.Equipment[5],
					Fumo1: h.Fumo[0], Fumo2: h.Fumo[1], Fumo3: h.Fumo[2], Fumo4: h.Fumo[3], Fumo5: h.Fumo[4], Fumo6: h.Fumo[5],
					PracticeStr: h.Practice[0], PracticeInt: h.Practice[1], PracticeAgi: h.Practice[2], StateVersion: h.StateVersion,
					CreationContentRevision: h.CreationContentRevision, CreatedAt: h.CreatedAt, UpdatedAt: h.UpdatedAt})
			}
			b, err := json.Marshal(rows)
			if err != nil {
				return err
			}
			*(dest[0].(*string)) = string(b)
			return nil
		}}
	default:
		return heroBootstrapRow{scan: func(...any) error { return errors.New("unexpected query") }}
	}
}

type heroBootstrapContent struct {
	revision  string
	core      bool
	equipment bool
	fumo      bool
	err       error
	kind      character.HeroKind
}

func (c heroBootstrapContent) HeroCoreActiveTx(context.Context, tx.Queryer) (string, bool, error) {
	if c.err != nil {
		return "", false, c.err
	}
	return c.revision, c.core, nil
}
func (c heroBootstrapContent) HeroEquipmentRevisionTx(context.Context, tx.Queryer, string) (bool, error) {
	if c.err != nil {
		return false, c.err
	}
	return c.equipment, nil
}
func (c heroBootstrapContent) HeroFumoRevisionTx(context.Context, tx.Queryer, string) (bool, error) {
	if c.err != nil {
		return false, c.err
	}
	return c.fumo, nil
}
func (c heroBootstrapContent) HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error) {
	if c.err != nil {
		return "", c.err
	}
	return c.kind, nil
}
func (heroBootstrapContent) HeroEquipmentPositionTx(context.Context, tx.Queryer, string, int64, int64, int64) (character.HeroEquipmentPosition, error) {
	return character.HeroEquipmentPosition{}, errors.New("unexpected equipment lookup")
}
func (heroBootstrapContent) HeroFumoTargetTx(context.Context, tx.Queryer, string, character.EquipmentTemplateID) (character.HeroFumoTarget, error) {
	return character.HeroFumoTarget{}, errors.New("unexpected Fumo lookup")
}

func heroBootstrapFixture() (character.HeroRoot, character.Hero) {
	now := time.Unix(100, 0).UTC()
	rev := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	root := character.HeroRoot{PlayerID: 7, NextPartnerID: 2, SortType: 3, StateVersion: 4, CreatedAt: now, UpdatedAt: now}
	h := character.Hero{PlayerID: 7, PartnerID: 1, TableID: 10001001, OriginTableID: 10001001, Star: 1, Level: 1, Color: 1,
		Practice: character.PracticeAttrs{11, 22, 33}, CreationContentRevision: rev, StateVersion: 5, CreatedAt: now, UpdatedAt: now}
	return root, h
}

func TestHeroBootstrapProjectionActiveOverlaysCanonicalMID49(t *testing.T) {
	root, h := heroBootstrapFixture()
	q := &heroBootstrapQueryer{root: root, heroes: []character.Hero{h}}
	content := heroBootstrapContent{revision: h.CreationContentRevision, core: true, equipment: true, fumo: true, kind: character.SuperHero}
	detail := map[string]any{"49": map[string]any{"sort_type": int64(0), "heros": map[string]any{}}}
	p := HeroBootstrapProjection{Content: content}
	if err := p.OverlayMID1(context.Background(), q, identity.ActorContext{PlayerID: 7}, false, time.Unix(200, 0).UTC(), detail); err != nil {
		t.Fatal(err)
	}
	body := detail["49"].(map[string]any)
	if body["sort_type"] != int64(3) {
		t.Fatalf("sort_type=%v", body["sort_type"])
	}
	heroes := body["heros"].(map[string]any)
	wire := heroes["1"].(map[string]any)
	got := wire["practice_attr"].([]any)
	if len(got) != 3 || got[0] != int64(11) || got[1] != int64(22) || got[2] != int64(33) {
		t.Fatalf("practice_attr=%v", got)
	}
	if wire["partner_type"] != int64(2) {
		t.Fatalf("partner_type=%v", wire["partner_type"])
	}
}

func TestHeroBootstrapProjectionInactivePreservesFrozenBaselineWithoutOwnerReads(t *testing.T) {
	root, h := heroBootstrapFixture()
	for _, tc := range []heroBootstrapContent{
		{revision: h.CreationContentRevision, core: false, equipment: true, fumo: true, kind: character.NormalHero},
		{revision: h.CreationContentRevision, core: true, equipment: false, fumo: true, kind: character.NormalHero},
		{revision: h.CreationContentRevision, core: true, equipment: true, fumo: false, kind: character.NormalHero},
	} {
		q := &heroBootstrapQueryer{root: root, heroes: []character.Hero{h}}
		baseline := map[string]any{"sort_type": int64(0), "heros": map[string]any{}}
		detail := map[string]any{"49": baseline}
		if err := (HeroBootstrapProjection{Content: tc}).OverlayMID1(context.Background(), q, identity.ActorContext{PlayerID: 7}, false, time.Unix(200, 0).UTC(), detail); err != nil {
			t.Fatal(err)
		}
		if !reflect.DeepEqual(detail["49"], baseline) {
			t.Fatal("inactive capability replaced frozen key49 baseline")
		}
		if q.calls != 0 {
			t.Fatalf("inactive capability performed owner reads: %d", q.calls)
		}
	}
}

func TestHeroBootstrapProjectionDoesNotMaskCapabilityErrorsAsInactivity(t *testing.T) {
	boom := errors.New("manifest corrupt")
	q := &heroBootstrapQueryer{}
	detail := map[string]any{"49": map[string]any{}}
	err := (HeroBootstrapProjection{Content: heroBootstrapContent{err: boom}}).OverlayMID1(context.Background(), q, identity.ActorContext{PlayerID: 7}, false, time.Unix(200, 0).UTC(), detail)
	if !errors.Is(err, boom) {
		t.Fatalf("err=%v", err)
	}
}

func TestHeroBootstrapProjectionMatchesDirectMID49StockProjection(t *testing.T) {
	root, h := heroBootstrapFixture()
	h.Kind = character.NormalHero
	q := &heroBootstrapQueryer{root: root, heroes: []character.Hero{h}}
	content := heroBootstrapContent{revision: h.CreationContentRevision, core: true, equipment: true, fumo: true, kind: character.NormalHero}
	detail := map[string]any{"49": map[string]any{"sort_type": int64(0), "heros": map[string]any{}}}
	if err := (HeroBootstrapProjection{Content: content}).OverlayMID1(context.Background(), q, identity.ActorContext{PlayerID: 7}, false, time.Unix(200, 0).UTC(), detail); err != nil {
		t.Fatal(err)
	}
	wantHero := h
	wantHero.Kind = character.NormalHero
	want, err := heroproj.StockRosterView(root.SortType, []heroproj.RosterHeroView{{Hero: wantHero}})
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(detail["49"], want) {
		t.Fatalf("MID1 key49 != direct stock projection\n got=%#v\nwant=%#v", detail["49"], want)
	}
}
