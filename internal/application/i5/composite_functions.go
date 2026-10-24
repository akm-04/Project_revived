package i5

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Composite function gates (D91, I9_MODE_FOUNDATION_V1 MF6) are read from the compiled raw_open_value: the catalog keeps
// gate_kind UNSUPPORTED_COMPOSITE so the content revision every stored row is pinned to does not move (D95).

// stageClearGate reads kind 2 "2|S": the first clear of Normal campaign stage S opens the function.
func stageClearGate(raw string) (int64, bool) {
	fields := strings.Split(raw, "|")
	if len(fields) != 2 || fields[0] != "2" {
		return 0, false
	}
	stage, err := strconv.ParseInt(fields[1], 10, 64)
	return stage, err == nil && stage > 0
}

// levelAndVIPGate reads kind 3 "3|L|V": level L and VIP V (the client keeps VIP in the second field).
func levelAndVIPGate(raw string) (level, vip int64, ok bool) {
	fields := strings.Split(raw, "|")
	if len(fields) != 3 || fields[0] != "3" {
		return 0, 0, false
	}
	level, levelErr := strconv.ParseInt(fields[1], 10, 64)
	vip, vipErr := strconv.ParseInt(fields[2], 10, 64)
	return level, vip, levelErr == nil && vipErr == nil && level > 0 && vip >= 0
}

// levelAndVIPEligibility is every kind-3 gate open at level and VIP.
func levelAndVIPEligibility(policy FunctionGatePolicy, pid identity.PlayerID, level, vip int64, now time.Time) []player.FunctionEligibility {
	out := make([]player.FunctionEligibility, 0)
	for _, gate := range policy.Gates {
		requiredLevel, requiredVIP, ok := levelAndVIPGate(gate.RawOpenValue)
		if !ok || requiredLevel > level || requiredVIP > vip {
			continue
		}
		out = append(out, player.FunctionEligibility{PlayerID: pid, FunctionID: gate.FunctionID, ContentRevision: policy.Revision, SourceFactKey: gate.SourceFactKey, EligibleAt: now.UTC()})
	}
	return out
}

// reachesLevelAndVIPGate tells whether any kind-3 gate's level part is met, so VIP is read only when it can matter.
func reachesLevelAndVIPGate(policy FunctionGatePolicy, level int64) bool {
	for _, gate := range policy.Gates {
		requiredLevel, _, ok := levelAndVIPGate(gate.RawOpenValue)
		if ok && requiredLevel <= level {
			return true
		}
	}
	return false
}

func (s Service) vipLevelTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, now time.Time) (int64, error) {
	if s.Privileges == nil {
		return 0, errors.New("privilege snapshot provider unavailable")
	}
	snapshot, err := s.Privileges.SnapshotTx(ctx, q, pid, now)
	return snapshot.VIPLevel, err
}

// insertOpeningsTx writes eligibility and unlock rows for composite openings under an already locked function state; every
// composite gate announces NONE, so eligible means open.
func insertOpeningsTx(ctx context.Context, store Store, t tx.Tx, pid identity.PlayerID, version int64, eligible []player.FunctionEligibility, sourcePrefix string, now time.Time) ([]int64, error) {
	opened := make([]int64, 0, len(eligible))
	changed := false
	for _, e := range eligible {
		e.SourceFactKey = fmt.Sprintf("%s:%d:%d", sourcePrefix, pid, e.FunctionID)
		insertedEligibility, err := store.InsertFunctionEligibilityTx(ctx, t, e)
		if err != nil {
			return nil, err
		}
		insertedUnlock, err := store.InsertFunctionUnlockTx(ctx, t, player.FunctionUnlock{PlayerID: pid, FunctionID: e.FunctionID, OpenedAt: now.UTC(), SourceFactKey: e.SourceFactKey, StateVersion: 1})
		if err != nil {
			return nil, err
		}
		changed = changed || insertedEligibility || insertedUnlock
		if insertedUnlock {
			opened = append(opened, e.FunctionID)
		}
	}
	if !changed {
		return opened, nil
	}
	return opened, store.AdvanceFunctionStateTx(ctx, t, pid, version, now)
}

// OpenStageFunctionsTx opens the kind-2 functions of a Normal campaign stage the player just cleared; I9-3 settlement calls it
// inside its own transaction. It returns the newly opened function ids (also recorded in the request change set).
func (s Service) OpenStageFunctionsTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, contentRevision string, stage int64, now time.Time) ([]int64, error) {
	if s.Store == nil || s.Content == nil || t == nil || !pid.Valid() || contentRevision == "" || stage <= 0 || now.IsZero() {
		return nil, errors.New("invalid stage function opening")
	}
	policy, err := s.Content.ResolveFunctionGatePolicyTx(ctx, t, contentRevision)
	if err != nil {
		return nil, err
	}
	eligible := make([]player.FunctionEligibility, 0)
	for _, gate := range policy.Gates {
		gateStage, ok := stageClearGate(gate.RawOpenValue)
		if ok && gateStage == stage {
			eligible = append(eligible, player.FunctionEligibility{PlayerID: pid, FunctionID: gate.FunctionID, ContentRevision: policy.Revision, SourceFactKey: gate.SourceFactKey, EligibleAt: now.UTC()})
		}
	}
	if len(eligible) == 0 {
		return nil, nil
	}
	version, err := s.Store.LockFunctionStateTx(ctx, t, pid)
	if err != nil {
		return nil, err
	}
	return insertOpeningsTx(ctx, s.Store, t, pid, version, eligible, "i9-2:function-stage:v1", now)
}
