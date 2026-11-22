package i5

import (
	"context"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type bloodAwakeningStore struct {
	AwakeningStore
	root objective.AwakeRoot
}

func (s *bloodAwakeningStore) LockAwakeningTx(context.Context, tx.Tx, identity.PlayerID) (objective.AwakeRoot, error) {
	return s.root, nil
}

func (s *bloodAwakeningStore) SaveAwakeningTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, root objective.AwakeRoot, _ int64) error {
	s.root = root
	return nil
}

func TestAwakeningBloodResultCarriesWinWindowFields(t *testing.T) {
	occurrence := objective.AwakeInstance{Mission: 2001002, Type: 2, OwnerID: 7, Generation: 3, Revision: strings.Repeat("ab", 32)}
	root := objective.NewAwakeRoot()
	root.Version = 4
	root.NextGeneration = 4
	root.Active[1] = occurrence
	catalog := objective.AwakeCatalog{Definitions: []objective.AwakeDefinition{{ID: 2001002, Type: 2, Stage: 2, Target: 1}}}
	service := Service{Awakening: &AwakeningRuntime{
		Store:   &bloodAwakeningStore{root: root},
		Content: fixedAwakeningContent{catalog: catalog},
		Heroes:  struct{ AwakeningHeroes }{},
		Pets:    struct{ AwakeningPets }{},
	}}
	body, err := service.CompleteAwakeningBloodTx(context.Background(), nil, identity.PlayerID(9), occurrence)
	if err != nil {
		t.Fatal(err)
	}
	exps, ok := body["exps"].([]any)
	if !ok || len(exps) != 0 {
		t.Fatalf("exps = %#v", body["exps"])
	}
	if body["old_num"] != int64(0) || body["add_exp"] != int64(0) {
		t.Fatalf("old_num/add_exp = %#v/%#v", body["old_num"], body["add_exp"])
	}
	if body[objective.AwakeChannel(2)] == nil {
		t.Fatalf("awake channel missing: %#v", body)
	}
}
