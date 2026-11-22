package mentor

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type giftBaseStore struct {
	Store
	relations []domain.Relationship
}

func (s giftBaseStore) ReadStateTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID) (State, bool, error) {
	return State{}, false, nil
}

func (s giftBaseStore) ReadRelationshipsTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID) ([]domain.Relationship, error) {
	return s.relations, nil
}

func (giftBaseStore) ListApplicationsToTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID, time.Time) ([]Application, error) {
	return nil, nil
}

func (giftBaseStore) ReadMissionProgressTx(context.Context, tx.Queryer, identity.PlayerID) ([]MissionProgress, error) {
	return nil, nil
}

type giftBaseCards struct {
	players map[identity.PlayerID]playerpresentation.Projected
}

func (c giftBaseCards) batch(ids []identity.PlayerID) playerpresentation.Batch {
	out := playerpresentation.Batch{Players: map[identity.PlayerID]playerpresentation.Projected{}}
	for _, id := range ids {
		out.Players[id] = c.players[id]
	}
	return out
}

func (c giftBaseCards) ReadManyTx(_ context.Context, _ tx.Tx, ids []identity.PlayerID) (playerpresentation.Batch, error) {
	return c.batch(ids), nil
}

func (c giftBaseCards) ReadManyAtTx(_ context.Context, _ tx.Tx, ids []identity.PlayerID, _ time.Time) (playerpresentation.Batch, error) {
	return c.batch(ids), nil
}

type giftBaseTx struct{}

func (giftBaseTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (giftBaseTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return nil, nil }
func (giftBaseTx) Commit(context.Context) error                                { return nil }
func (giftBaseTx) Rollback(context.Context) error                              { return nil }

type giftBaseContent struct{ catalog Catalog }

func (c giftBaseContent) MentorCatalog() (Catalog, error) { return c.catalog, nil }

func (giftBaseContent) ActiveRevision(context.Context, tx.Queryer) (string, error) { return "", nil }

func giftBaseService(relations []domain.Relationship) Service {
	actor := playerdirectory.Profile{PlayerID: 100001, Name: "student", Level: 20, AvatarID: 110001001}
	partner := playerdirectory.Profile{PlayerID: 100002, Name: "teacher", Level: 60, AvatarID: 110001001}
	return Service{
		Store:     giftBaseStore{relations: relations},
		Directory: filterDirectory{byID: map[identity.PlayerID]playerdirectory.Profile{actor.PlayerID: actor, partner.PlayerID: partner}},
		Cards: giftBaseCards{players: map[identity.PlayerID]playerpresentation.Projected{
			partner.PlayerID: {Minimal: playerpresentation.Minimal{PlayerID: partner.PlayerID, Name: partner.Name, Level: partner.Level, AvatarID: partner.AvatarID}},
		}},
		Content: giftBaseContent{},
	}
}

func TestGiftBaseInfoTxProjectsActivePair(t *testing.T) {
	at := time.Date(2026, 11, 19, 12, 0, 0, 0, time.UTC)
	relations := []domain.Relationship{{Mentor: 100002, Student: 100001, AcceptedAt: at.Add(-time.Hour), Intimacy: 100}}
	body, linked, err := giftBaseService(relations).GiftBaseInfoTx(context.Background(), giftBaseTx{}, 100001, 100002, at)
	if err != nil || !linked || body == nil {
		t.Fatalf("linked %v body %#v err %v", linked, body, err)
	}
	intimacies, ok := body["intimacies"].([]any)
	if !ok || len(intimacies) != 2 || intimacies[0] != int64(100) {
		t.Fatalf("intimacies %#v", body["intimacies"])
	}
}

func TestGiftBaseInfoTxOmitsNonClassPair(t *testing.T) {
	at := time.Date(2026, 11, 19, 12, 0, 0, 0, time.UTC)
	relations := []domain.Relationship{{Mentor: 100003, Student: 100001, AcceptedAt: at.Add(-time.Hour), Intimacy: 100}}
	body, linked, err := giftBaseService(relations).GiftBaseInfoTx(context.Background(), giftBaseTx{}, 100001, 100002, at)
	if err != nil || linked || body != nil {
		t.Fatalf("linked %v body %#v err %v", linked, body, err)
	}
}
