//go:build postgres

package main

import (
	"context"
	"strconv"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/adventurestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	apparena "gxb.local/backend/v2/internal/application/arena"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	appwakeup "gxb.local/backend/v2/internal/application/realtimewakeup"
	apptopfloor "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func canonicalAdventure(p *pg.Pool, r tx.Runner, content contentstore.Store, values i5store.Store, owner i5.Service, fight combat.Service, opponents appadventure.Opponents) appadventure.Mode {
	return appadventure.Mode{
		Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r},
		Fresh: p, Store: adventurestore.Store{}, Content: content,
		Functions: values, Directory: i4store.PlayerDirectoryReader{}, Heroes: fight.Inputs.Heroes, Combat: fight,
		Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Grants: owner,
		Opponents: opponents, Wake: adventureWakeup{},
	}
}

// adventureOpponents joins the two read-only opponent sources: Arena standings
// inside the Adventure section, then a Top Floor robot team.
type adventureOpponents struct {
	Arena    apparena.Service
	TopFloor apptopfloor.Service
}

func (o adventureOpponents) ArenaOpponentTx(c context.Context, q tx.Queryer, player identity.PlayerID, section int64, ordinal uint64) (appadventure.Opponent, bool, error) {
	defense, found, err := o.Arena.AdventureOpponentTx(c, q, player, section, ordinal)
	if err != nil || !found {
		return appadventure.Opponent{}, found, err
	}
	return appadventure.Opponent{PlayerID: defense.PlayerID, Heroes: defense.Heroes, PetID: defense.PetID}, true, nil
}

func (o adventureOpponents) RobotOpponentTx(c context.Context, q tx.Queryer, ordinal uint64) (appadventure.Opponent, bool, error) {
	robot, found, err := o.TopFloor.AdventureRobotTx(c, q, ordinal)
	if err != nil || !found {
		return appadventure.Opponent{}, found, err
	}
	return appadventure.Opponent{TemplateHeroes: robot.Heroes}, true, nil
}

// adventureWakeup emits the commit-coupled wakeup that carries notices 33/34.
type adventureWakeup struct{}

func (adventureWakeup) WakeAdventureNotice(c context.Context, exec tx.Execer, player identity.PlayerID) error {
	return pg.EmitRealtimeWakeup(c, exec, appwakeup.Envelope{Version: 1, Route: appadventure.NoticeRoute, Ref: strconv.FormatInt(int64(player), 10)})
}
