package publicprofile

import (
	"context"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/profile"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type RelationReader interface {
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (socialrelation.Root, bool, error)
	LockFriendshipTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID) (socialrelation.Friendship, bool, error)
	LockBlockTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID) (socialrelation.Block, bool, error)
	CandidateStatesTx(context.Context, tx.Tx, identity.PlayerID, []identity.PlayerID) ([]socialrelation.CandidateState, error)
}
type BasicIdentity struct {
	PlayerID                                  identity.PlayerID
	Server                                    identity.LogicalServerID
	Name                                      string
	AvatarID, FrameID, PlayerType, Level, Exp int64
}
type BasicResult struct {
	Identity                                                 BasicIdentity
	Relation                                                 socialrelation.CandidateState
	Intro                                                    string
	Functions                                                []int64
	ActorBlocked                                             bool
	SelfPreferences                                          *profile.Preferences
	Eligible                                                 map[int16]bool
	ProfileVersion, PlayerProfileVersion, ProgressionVersion int64
	ContentRevision                                          string
	ObservedAt                                               time.Time
}
type BasicReader struct {
	Roots       RootService
	Players     playerroot.TxLocker
	Fence       ActorFencer
	PlayerBasis i5.PublicPlayerBasisReader
	Relations   RelationReader
	Content     ContentReader
}

// Caller owns this witnessed coherent transaction, pinned revision and instant.
// No roots are ensured, no preferences changed, and no rich wire DTO activated.
func (s BasicReader) ReadBasicTx(c context.Context, sc tx.Scope, a identity.ActorContext, target identity.PlayerID, rev string, at time.Time) (BasicResult, error) {
	var out BasicResult
	if sc.Tx == nil || sc.Operation.ID.IsZero() || sc.Operation.StartedAt.IsZero() || sc.Attempt < 1 || (sc.Options.Isolation != tx.Serializable && sc.Options.Isolation != tx.RepeatableRead) || s.Roots.Store == nil || s.Players == nil || s.Fence == nil || s.PlayerBasis == nil || s.Relations == nil || s.Content == nil || at.IsZero() {
		return out, ErrInvalidState
	}
	actorServer, e := socialrelation.CanonicalServer(a.PlayerID)
	if e != nil || actorServer != a.LogicalServerID {
		return out, ErrInvalidState
	}
	targetServer, e := socialrelation.CanonicalServer(target)
	if e != nil {
		return out, ErrInvalidState
	}
	if e = s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
		return out, e
	}
	ids, e := playerroot.CanonicalPlayerIDs([]identity.PlayerID{a.PlayerID, target})
	if e != nil {
		return out, e
	}
	roots := map[identity.PlayerID]playerroot.Root{}
	for _, pid := range ids {
		srv, e := socialrelation.CanonicalServer(pid)
		if e != nil {
			return out, e
		}
		rs, e := s.Players.LockPlayerRootsTx(c, sc.Tx, srv, []identity.PlayerID{pid})
		if e != nil || len(rs) != 1 {
			return out, ErrInvalidState
		}
		roots[pid] = rs[0]
	}
	for _, pid := range ids {
		r, ok, e := s.Relations.LockRootTx(c, sc.Tx, pid)
		if e != nil {
			return out, e
		}
		if ok && (r.Validate() != nil || r.PlayerID != pid) {
			return out, ErrInvalidState
		}
	}
	actorBlocked := false
	rel := socialrelation.CandidateState{PlayerID: target}
	if target != a.PlayerID {
		if _, _, e = s.Relations.LockFriendshipTx(c, sc.Tx, a.PlayerID, target); e != nil {
			return out, e
		}
		type directed struct {
			from, to identity.PlayerID
			k        lockkey.Key
		}
		k1, _ := socialrelation.BlockLockKey(a.PlayerID, target)
		k2, _ := socialrelation.BlockLockKey(target, a.PlayerID)
		pairs := []directed{{a.PlayerID, target, k1}, {target, a.PlayerID, k2}}
		if lockkey.Compare(k1, k2) > 0 {
			pairs[0], pairs[1] = pairs[1], pairs[0]
		}
		for _, pair := range pairs {
			block, found, e := s.Relations.LockBlockTx(c, sc.Tx, pair.from, pair.to)
			if e != nil {
				return out, e
			}
			if found && pair.from == a.PlayerID {
				actorBlocked = block.Active
			}
		}
		states, e := s.Relations.CandidateStatesTx(c, sc.Tx, a.PlayerID, []identity.PlayerID{target})
		if e != nil || len(states) != 1 || states[0].PlayerID != target {
			return out, ErrInvalidState
		}
		rel = states[0]
	}
	if _, e = s.Roots.PrepareRootTx(c, sc.Tx, roots[target]); e != nil {
		return out, e
	}
	p, e := s.Content.ReadPublicProfilePolicy(c, sc.Tx, rev)
	if e != nil || p.Validate() != nil || p.Revision != rev {
		return out, ErrContent
	}
	snapshot, e := s.Roots.ReadSnapshotTx(c, sc, target, rev, at)
	if e != nil {
		return out, e
	}
	basis, e := s.PlayerBasis.ReadPublicPlayerBasisTx(c, sc.Tx, target)
	if e != nil || basis.Validate() != nil || basis.Profile.PlayerID != target {
		return out, ErrContent
	}
	out = BasicResult{Identity: BasicIdentity{PlayerID: target, Server: targetServer, Name: basis.Profile.DisplayName, AvatarID: basis.Profile.AvatarID, FrameID: basis.Profile.AvatarFrameID, PlayerType: int64(basis.Profile.PlayerType), Level: basis.Progression.Level, Exp: basis.Progression.Exp}, Relation: rel, ActorBlocked: actorBlocked, Eligible: map[int16]bool{}, ProfileVersion: snapshot.Root.StateVersion, PlayerProfileVersion: basis.Profile.StateVersion, ProgressionVersion: basis.Progression.StateVersion, ContentRevision: rev, ObservedAt: at.UTC()}
	out.Functions = make([]int64, len(basis.Functions))
	for i, f := range basis.Functions {
		out.Functions[i] = f.FunctionID
	}
	self := a.PlayerID == target
	protected := self || !rel.Blocked
	for _, sub := range []int16{1, 2, 3, 4, 6} {
		out.Eligible[sub] = protected
	}
	out.Eligible[6] = self
	out.Eligible[5] = false
	if !self {
		for _, sub := range snapshot.Root.Preferences.HideSubtypes {
			out.Eligible[sub] = false
		}
	}
	if protected {
		out.Intro = snapshot.Root.Preferences.Intro
	}
	if self {
		prefs := snapshot.Root.Preferences.Clone()
		out.SelfPreferences = &prefs
	}
	return out, nil
}
