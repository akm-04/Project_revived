package guildcore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

var ErrPublicView = errors.New("invalid current Guild public view")

type PublicViewStore interface {
	ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error)
	ReadGuildTx(context.Context, tx.Queryer, guild.ID) (guild.Guild, bool, error)
	ReadInviteIssueIDTx(context.Context, tx.Queryer, guild.ID, identity.PlayerID) (ids.UUID, error)
}
type PublicView struct {
	PlayerID                                    identity.PlayerID
	GuildID                                     guild.ID
	Name                                        string
	Role                                        guild.Role
	GuildVersion, MembershipVersion, InviteTime int64
	ObservedAt                                  time.Time
	ContentRevision                             string
}
type PublicViewReader struct {
	Store   PublicViewStore
	Invites guildinvite.ImmutableReader
}

// Guild remains the durable owner. The caller supplies its existing coherent
// transaction; source validity never depends on a recipient notice projection.
func (r PublicViewReader) ReadPublicGuildTx(c context.Context, sc tx.Scope, actor, target identity.PlayerID, rev string, at time.Time) (PublicView, error) {
	out := PublicView{PlayerID: target, ContentRevision: rev, ObservedAt: at}
	if r.Store == nil || sc.Tx == nil || sc.Operation.ID.IsZero() || sc.Attempt < 1 || (sc.Options.Isolation != tx.RepeatableRead && sc.Options.Isolation != tx.Serializable) || !actor.Valid() || !target.Valid() || len(rev) != 64 || at.IsZero() {
		return out, ErrPublicView
	}
	readMember := func(pid identity.PlayerID) (guild.Membership, bool, error) {
		m, ok, e := r.Store.ReadMembershipTx(c, sc.Tx, pid)
		if e != nil {
			return m, ok, e
		}
		if ok && (m.Validate() != nil || m.PlayerID != pid) {
			return m, ok, ErrPublicView
		}
		return m, ok, nil
	}
	m, ok, e := readMember(target)
	if e != nil {
		return out, e
	}
	if ok {
		g, present, e := r.Store.ReadGuildTx(c, sc.Tx, m.GuildID)
		if e != nil {
			return out, e
		}
		if !present || g.Validate() != nil || g.ID != m.GuildID || g.RetiredAt != nil {
			return out, ErrPublicView
		}
		out.GuildID = g.ID
		out.Name = g.Name
		out.Role = m.Role
		out.GuildVersion = g.StateVersion
		out.MembershipVersion = m.MembershipVersion
	}
	if actor == target || ok {
		return out, nil
	}
	am, yes, e := readMember(actor)
	if e != nil {
		return out, e
	}
	if !yes {
		return out, nil
	}
	ag, present, e := r.Store.ReadGuildTx(c, sc.Tx, am.GuildID)
	if e != nil {
		return out, e
	}
	if !present || ag.Validate() != nil || ag.ID != am.GuildID || ag.RetiredAt != nil {
		return out, ErrPublicView
	}
	id, e := r.Store.ReadInviteIssueIDTx(c, sc.Tx, ag.ID, target)
	if e != nil {
		return out, e
	}
	if id.IsZero() {
		return out, nil
	}
	if r.Invites == nil {
		return out, ErrPublicView
	}
	snapshot, e := r.Invites.ReadInviteSnapshotTx(c, sc.Tx, id)
	if e != nil {
		return out, e
	}
	if snapshot.Issue.Operation.ID != id || snapshot.Issue.Tuple.GuildID != ag.ID || snapshot.Issue.Tuple.Recipient != target {
		return out, ErrPublicView
	}
	eligible, e := snapshot.Eligible(at)
	if e != nil {
		return out, e
	}
	if eligible {
		out.InviteTime = snapshot.Issue.DecisionAt.Unix()
	}
	return out, nil
}
