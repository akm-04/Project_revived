package characterhero

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type heroBaseQ struct{}

func (heroBaseQ) QueryRow(context.Context, string, ...any) tx.Row { return nil }

type heroBaseStore struct{ h character.Hero }

func (s heroBaseStore) ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error) {
	return s.h, nil
}

type heroBaseContent struct {
	rev   string
	table int64
	kind  character.HeroKind
}

func (c *heroBaseContent) HeroKindTx(_ context.Context, _ tx.Queryer, rev string, table int64) (character.HeroKind, error) {
	c.rev, c.table = rev, table
	return c.kind, nil
}

func TestHeroBaseObservationUsesCreationRevisionForKindAndExcludesLaterFamilies(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	rev := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	h := character.Hero{PlayerID: 7, PartnerID: 9, TableID: 1001, OriginTableID: 1001, Star: 2, Level: 3, Exp: 4, Color: 5, Equipment: character.HeroEquipmentSlots{1}, Fumo: character.HeroFumoSlots{9}, Practice: character.PracticeAttrs{1, 2, 3}, CurrentSkinID: 77, IllusionSkinID: -1, CreationContentRevision: rev, StateVersion: 12, CreatedAt: now, UpdatedAt: now}
	c := &heroBaseContent{kind: character.NormalHero}
	got, err := (BaseObservationReader{Store: heroBaseStore{h: h}, Content: c}).HeroBaseObservationTx(context.Background(), heroBaseQ{}, 7, 9)
	if err != nil {
		t.Fatal(err)
	}
	if c.rev != rev || c.table != h.TableID {
		t.Fatalf("kind lookup=%q/%d", c.rev, c.table)
	}
	if got.Ref != h.Ref() || got.TableID != h.TableID || got.StateVersion != 12 || got.Kind != character.NormalHero || got.CreationContentRevision != rev {
		t.Fatalf("got=%+v", got)
	}
}

func TestHeroBaseObservationRejectsUnresolvedKind(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	rev := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	h := character.Hero{PlayerID: 7, PartnerID: 9, TableID: 1001, OriginTableID: 1001, Star: 1, Level: 1, Color: 1, IllusionSkinID: -1, CreationContentRevision: rev, StateVersion: 1, CreatedAt: now, UpdatedAt: now}
	_, err := (BaseObservationReader{Store: heroBaseStore{h: h}, Content: &heroBaseContent{kind: "UNKNOWN"}}).HeroBaseObservationTx(context.Background(), heroBaseQ{}, 7, 9)
	if err == nil {
		t.Fatal("unresolved kind accepted")
	}
	if errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
}
