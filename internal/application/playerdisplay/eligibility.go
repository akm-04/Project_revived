package playerdisplay

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (s Service) origins(c context.Context, t tx.Queryer, pid identity.PlayerID, family, rev string, at time.Time) ([]Origin, error) {
	if s.External == nil {
		return nil, ErrUnavailable
	}
	o, e := s.External.ReadDisplayOriginsTx(c, t, pid, family, rev, at)
	if e != nil {
		return nil, e
	}
	if !o.Qualified || o.PlayerID != pid || o.Family != family || o.Revision != rev || !o.ObservedAt.Equal(at) {
		return nil, ErrUnavailable
	}
	for _, x := range o.Origins {
		if x.Validate() != nil || x.PlayerID != pid || x.Family != family {
			return nil, ErrConflict
		}
	}
	return o.Origins, nil
}
func (s Service) eligible(c context.Context, t tx.Queryer, pid identity.PlayerID, v player.Cosmetic, category, unique int64, rev string, at time.Time, p player.DisplayCatalog) ([]Origin, []HeroFacet, error) {
	if v.Family == "avatar" && v.Type == 1 || v.Family == "frame" && v.Type == 1 || v.Family == "bubble" && v.ID == p.DefaultBubble {
		return []Origin{}, nil, nil
	}
	vipKnown := false
	if v.Family == "frame" && v.Type == 6 && s.CosmeticPrivileges != nil {
		x, e := s.CosmeticPrivileges.ReadCosmeticPrivilegeTx(c, t, pid, rev, at)
		if e != nil && !errors.Is(e, privilege.ErrUnavailable) {
			return nil, nil, e
		}
		if e == nil {
			if x.Validate(pid, rev, at) != nil {
				return nil, nil, ErrUnavailable
			}
			vipKnown = true
			if x.State.VIPLevel >= v.VIP {
				return []Origin{}, nil, nil
			}
		}
	}
	if v.Family == "avatar" && (v.Type == 2 || v.Type == 3 || v.Type == 7 || v.Type == 11) {
		if s.Characters == nil {
			return nil, nil, ErrUnavailable
		}
		hs, e := s.Characters.ReadDisplayHeroesTx(c, t, pid, rev, at)
		if e != nil {
			return nil, nil, e
		}
		matched := HeroEligibility(v, category, hs, p)
		if len(matched) > 0 {
			return []Origin{}, matched, nil
		}
		if v.Type == 2 || v.Type == 3 {
			return nil, nil, ErrRequest
		}
	}
	// Ordinary canonical stacks qualify only the source permanent branch. They
	// contain no qualified timed startTime, irrespective of AcquiredAt.
	if (v.Family == "avatar" || v.Family == "frame") && v.Days == -1 {
		stacks, e := s.Store.ListStacksTx(c, t, pid)
		if e != nil {
			return nil, nil, e
		}
		for _, x := range stacks {
			if x.ItemID == v.ID && x.Quantity > 0 && x.Validate() == nil {
				return []Origin{{PlayerID: pid, Key: "ordinary-stack", Owner: "i5", Family: v.Family, CatalogID: v.ID, Revision: rev, StateVersion: x.StateVersion}}, nil, nil
			}
		}
	}
	if v.Family == "avatar" && (v.Type == 7 || v.Type == 11) {
		return nil, nil, ErrRequest
	}
	if v.Family == "frame" && v.Type == 6 {
		if vipKnown {
			return nil, nil, ErrRequest
		}
		return nil, nil, ErrUnavailable
	}

	origins, e := s.origins(c, t, pid, v.Family, rev, at)
	if e != nil {
		return nil, nil, e
	}
	for _, x := range origins {
		if x.CatalogID != v.ID || x.UniqueID != unique {
			continue
		}
		originCatalog, e := s.Content.ReadPlayerDisplayCatalogTx(c, t, x.Revision)
		if e != nil {
			return nil, nil, e
		}
		original, ok := originCatalog.Find(x.Family, x.CatalogID)
		if !ok {
			return nil, nil, ErrConflict
		}
		end, e := original.EndTime(x.StartsAt, x.EndTime)
		if e != nil {
			return nil, nil, e
		}
		if player.EligibleAt(end, at) {
			x.EndTime = end
			return []Origin{x}, nil, nil
		}
	}
	return nil, nil, ErrRequest
}

// ObserveTx contributes exact effective display plus versions at a caller's
// pinned time. Expiry changes presentation without deleting ownership.
func (s Service) ObserveTx(c context.Context, t tx.Queryer, pid identity.PlayerID, rev string, at time.Time) (Observation, error) {
	out := Observation{PlayerID: pid, Revision: rev, ObservedAt: at, Origins: []Origin{}}
	if t == nil || !pid.Valid() || at.IsZero() || len(rev) != 64 {
		return out, ErrRequest
	}
	p, e := s.Content.ReadPlayerDisplayCatalogTx(c, t, rev)
	if e != nil {
		return out, e
	}
	state, e := s.Store.ReadDisplayStateTx(c, t, pid, false)
	if e != nil {
		return out, e
	}
	if state.Validate() != nil {
		return out, ErrConflict
	}
	out.ProfileVersion = state.Basis.Profile.StateVersion
	out.ProgressionVersion = state.Basis.Progression.StateVersion
	out.AvatarID = state.Basis.Profile.AvatarID
	out.FrameID = state.Basis.Profile.AvatarFrameID
	out.TitleID = state.Selection.TitleID
	out.TitleUniqueID = state.Selection.TitleUniqueID
	out.BubbleID = state.Selection.BubbleID
	check := func(f string, id, cat, unique int64) error {
		v, ok := p.Find(f, id)
		if !ok {
			return ErrConflict
		}
		os, hs, e := s.eligible(c, t, pid, v, cat, unique, rev, at, p)
		if e == ErrRequest {
			switch f {
			case "avatar":
				v, _ := p.Find("avatar", p.DefaultAvatar)
				out.AvatarID = v.Icon
			case "frame":
				out.FrameID = p.DefaultFrame
			case "title":
				out.TitleID = 0
				out.TitleUniqueID = 0
			case "bubble":
				out.BubbleID = p.DefaultBubble
			}
			return nil
		}
		if e != nil {
			return e
		}
		if len(os) > 0 {
			if f == "title" {
				out.TitleEndTime = os[0].EndTime
			}
			if f == "bubble" {
				out.BubbleEndTime = os[0].EndTime
			}
		}
		out.Origins = append(out.Origins, os...)
		out.HeroVersions = append(out.HeroVersions, hs...)
		return nil
	}
	if state.Selection.AvatarTableID > 0 {
		if e = check("avatar", state.Selection.AvatarTableID, state.Selection.AvatarCategory, 0); e != nil {
			return out, e
		}
	}
	if out.FrameID > 0 {
		if e = check("frame", out.FrameID, 0, 0); e != nil {
			return out, e
		}
	}
	if out.TitleID > 0 {
		if e = check("title", out.TitleID, 0, out.TitleUniqueID); e != nil {
			return out, e
		}
	}
	if out.BubbleID == 0 {
		out.BubbleID = p.DefaultBubble
	}
	if e = check("bubble", out.BubbleID, 0, 0); e != nil {
		return out, e
	}
	return out, nil
}
