// Package heroforce is the shared "best hero force" projection: the sum of a
// player's strongest heroes' qualified public force.
package heroforce

import (
	"context"
	"math"
	"slices"
	"strconv"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BestCount is the number of heroes the stock team windows sum.
const BestCount = 15

type Roster interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

type Stats interface {
	HeroTx(context.Context, ca.CoherentReadScope, character.HeroRef, publicstats.View) (publicstats.Result, error)
}

// Best15 sums the public force of the player's fifteen strongest heroes.
func Best15(c context.Context, sc gen.TimedScope, roster Roster, stats Stats, player identity.PlayerID, revision string, at time.Time) (int64, error) {
	detail := map[string]any{}
	if err := roster.OverlayMID1(c, sc.Tx, identity.ActorContext{PlayerID: player}, false, at, detail); err != nil {
		return 0, err
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	partners := make([]int64, 0, len(rows))
	for key := range rows {
		partnerID, err := strconv.ParseInt(key, 10, 64)
		if err != nil {
			return 0, err
		}
		partners = append(partners, partnerID)
	}
	return Best(c, BestCount, sc, stats, player, revision, at, partners)
}

// Best sums the public force of the count strongest heroes among partners.
func Best(c context.Context, count int, sc gen.TimedScope, stats Stats, player identity.PlayerID, revision string, at time.Time, partners []int64) (int64, error) {
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, revision, at)
	if err != nil {
		return 0, err
	}
	forces := make([]int64, 0, len(partners))
	for _, partnerID := range partners {
		result, err := stats.HeroTx(c, scope, character.HeroRef{PlayerID: player, PartnerID: partnerID}, publicstats.View{Kind: publicstats.Self, Viewer: player})
		if err != nil {
			return 0, err
		}
		forces = append(forces, int64(math.Round(result.Stats.Force)))
	}
	slices.Sort(forces)
	total := int64(0)
	for _, force := range forces[max(0, len(forces)-count):] {
		total += force
	}
	return total, nil
}
