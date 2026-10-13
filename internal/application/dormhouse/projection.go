package dormhouse

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"strconv"
	"time"
)

func heroWire(f dorm.HeroFacts, rooms map[int64]dorm.Room) map[string]any {
	r := rooms[f.HouseID]
	return map[string]any{"house_id": f.HouseID, "house_table_id": r.TableID, "house_comfort": r.Comfort, "house_expand_lev": r.ExpansionLevel, "house_equips": f.Equipment}
}
func roomWire(r dorm.Room, heroes map[int64]character.Hero, facts map[int64]dorm.HeroFacts) map[string]any {
	residents := []any{}
	for _, p := range r.Residents {
		h := heroes[p]
		row := map[string]any{"partner_id": p, "table_id": h.TableID, "star": h.Star, "color": h.Color, "lev": h.Level, "exp": h.Exp, "skills": h.RawSkills.Levels, "skill_ids": h.RawSkills.ChoiceIDs, "equips": h.Equipment, "fumos": h.Fumo, "practice_attr": h.Practice, "is_like": h.IsLike, "current_skin_id": h.CurrentSkinID, "illusion_skin_id": h.IllusionSkinID, "twice_awake_stage": 0, "house_id": r.ID, "house_table_id": r.TableID, "house_comfort": r.Comfort, "house_expand_lev": r.ExpansionLevel, "house_equips": facts[p].Equipment}
		if h.Kind == character.SuperHero {
			row["partner_type"] = 2
		}
		residents = append(residents, row)
	}
	start, last := int64(0), int64(0)
	if r.Pending != nil {
		start = r.Pending.StartedAt.Unix()
	}
	if !r.LastEnterAt.IsZero() {
		last = r.LastEnterAt.Unix()
	}
	return map[string]any{"house_id": r.ID, "table_id": r.TableID, "floor": r.Floor, "pos": r.Position, "comfort": r.Comfort, "expand_lev": r.ExpansionLevel, "expand_start_time": start, "last_enter_time": last, "partner_infos": residents, "house_name": "", "is_hide": 0, "praise_num": 0, "is_has_praise": 0}
}
func listWire(rooms map[int64]dorm.Room, heroes map[int64]character.Hero, facts map[int64]dorm.HeroFacts) [][]any {
	out := [][]any{{}, {}, {}, {}}
	ids := []int64{}
	for id := range rooms {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	for _, id := range ids {
		r := rooms[id]
		out[r.MainType-1] = append(out[r.MainType-1], roomWire(r, heroes, facts))
	}
	return out
}

// Read owns its one captured DB decision instant. Foreign reads are strictly
// observational; only the owner-detail route can settle EXP/expansion.
func (s Service) Read(ctx context.Context, a identity.ActorContext, op operation.Context, mid uint16, host, house int64) (map[string]any, error) {
	if !s.complete() || (mid != 2512 && mid != 2514) {
		return nil, ErrUnavailable
	}
	if host == 0 {
		host = int64(a.PlayerID)
	}
	pid := identity.PlayerID(host)
	if !pid.Valid() || host > dorm.MaxWireID {
		return nil, dorm.ErrInvalidFacts
	}
	rev, active, e := s.Content.DormInputsActive(ctx)
	if e != nil {
		return nil, e
	}
	if !active {
		return nil, ErrUnavailable
	}
	var body map[string]any
	isolation := tx.RepeatableRead
	attempts := 1
	own := pid == a.PlayerID && mid == 2514
	if own {
		isolation = tx.Serializable
		attempts = 3
	}
	_, res, e := s.Timed.Run(ctx, op, Profile(), tx.Options{Isolation: isolation}, tx.RetryPolicy{MaxAttempts: attempts, RetryDefiniteAbort: own}, nil, func(ctx context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if own {
			if e := s.lockPlan(ctx, sc.Tx, a, Command{}, at); e != nil {
				return e
			}
		} else {
			if e := s.Fence.FenceActorTx(ctx, sc.Tx, a, at); e != nil {
				return e
			}
		}
		root, e := s.Owner.ReadRootTx(ctx, sc.Tx, pid)
		if e != nil {
			return e
		}
		if at.Before(root.UpdatedAt) {
			return ErrStale
		}
		catalog, e := s.Content.DormCatalogTx(ctx, sc.Tx, rev)
		if e != nil {
			return e
		}
		rooms, e := s.Owner.ListRoomsTx(ctx, sc.Tx, pid)
		if e != nil {
			return e
		}
		heroes, e := s.Heroes.ListHeroesTx(ctx, sc.Tx, pid)
		if e != nil {
			return e
		}
		hm := map[int64]character.Hero{}
		facts := map[int64]dorm.HeroFacts{}
		for _, h := range heroes {
			rule, e := s.Content.HeroTemplateProgressionTx(ctx, sc.Tx, rev, h.TableID)
			if e != nil {
				return e
			}
			h.Kind = rule.Kind
			hm[h.PartnerID] = h
			f, e := s.Owner.ReadHeroTx(ctx, sc.Tx, h.Ref())
			if e != nil {
				return e
			}
			facts[h.PartnerID] = f
		}
		values, e := s.Values.ReadDormPlayerStateTx(ctx, sc.Tx, pid, at)
		if e != nil {
			return e
		}
		if _, ok := values.Functions[71]; !ok {
			return dorm.ErrUnqualified
		}
		body = map[string]any{}
		if mid == 2512 {
			functions := []int64{}
			for id := int64(71); id <= 74; id++ {
				if _, ok := values.Functions[id]; ok {
					functions = append(functions, id)
				}
			}
			body["house_list"] = listWire(rooms, hm, facts)
			body["open_functions"] = functions
			return nil
		}
		r, ok := rooms[house]
		if !ok {
			return dorm.ErrInvalidFacts
		}
		if at.Before(r.UpdatedAt) {
			return ErrStale
		}
		if own {
			values, e = s.Values.LockDormPlayerStateTx(ctx, sc.Tx, pid, at)
			if e != nil {
				return e
			}
			mutated := false
			if r.MainType == dorm.LoungeType && len(r.Residents) > 0 {
				if e = s.settleLounge(ctx, sc.Tx, r, hm, facts, values.Level, rev, at, body); e != nil {
					return e
				}
				mutated = true
			}
			if r.Pending != nil {
				due, e := r.Pending.Deadline()
				if e != nil {
					return e
				}
				if !at.Before(due) {
					if _, e = s.Content.DormCatalogTx(ctx, sc.Tx, r.Pending.ContentRevision); e != nil {
						return e
					}
					old := r.StateVersion
					r.StateVersion++
					r.ExpansionLevel = r.Pending.NextLevel
					r.Pending = nil
					r.UpdatedAt = at
					rooms[r.ID] = r
					if e = s.Owner.SaveRoomTx(ctx, sc.Tx, r, old); e != nil {
						return e
					}
					mutated = true
				}
			}
			if mutated {
				old := root.StateVersion
				root.StateVersion++
				root.UpdatedAt = at
				if e = s.Owner.SaveRootTx(ctx, sc.Tx, root, old); e != nil {
					return e
				}
			}
		}
		used := map[string]int64{}
		for _, r := range rooms {
			v, e := catalog.ValidateLayout(r.TableID, r.ExpansionLevel, r.Layout)
			if e != nil {
				return e
			}
			for item, n := range v.Used {
				used[strconv.FormatInt(item, 10)] += n
			}
		}
		body["house_info"] = roomWire(r, hm, facts)
		body["house_detail"] = map[string]any{"house_id": r.ID, "record": r.Layout}
		body["item_record"] = used
		if own {
			changed := map[string]any{}
			for _, p := range r.Residents {
				changed[strconv.FormatInt(p, 10)] = heroWire(facts[p], rooms)
			}
			body["changed_heroes"] = changed
		}
		return nil
	})
	if e != nil {
		return nil, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	return body, nil
}

// These are raw, qualified caller-snapshot ports for I7C-3B/6, never roster
// projections or new transactions. No-room is a canonical facet with HouseID0.
type InputScope struct {
	Player          identity.PlayerID
	ContentRevision string
	ObservedAt      time.Time
}
type HeroInputs struct {
	Hero                               character.Hero
	Facts                              dorm.HeroFacts
	Room                               *dorm.Room
	PopulationVersion, DormRootVersion int64
	ContentRevision                    string
	ObservedAt                         time.Time
	GrowthBP                           dorm.AttributesBP
}

func (s Service) DormHouseInputsTx(ctx context.Context, q tx.Queryer, scope InputScope, ref character.HeroRef) (HeroInputs, error) {
	var out HeroInputs
	if q == nil || ref.Validate() != nil || ref.PlayerID != scope.Player || !dorm.ValidRevision(scope.ContentRevision) || scope.ObservedAt.IsZero() {
		return out, dorm.ErrUnqualified
	}
	catalog, e := s.Content.DormCatalogTx(ctx, q, scope.ContentRevision)
	if e != nil {
		return out, e
	}
	hr, e := s.Heroes.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	dr, e := s.Owner.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, q, scope.Player, ref.PartnerID)
	if e != nil {
		return out, e
	}
	f, e := s.Owner.ReadHeroTx(ctx, q, ref)
	if e != nil {
		return out, e
	}
	if scope.ObservedAt.Before(h.UpdatedAt) || scope.ObservedAt.Before(f.UpdatedAt) || scope.ObservedAt.Before(dr.UpdatedAt) || scope.ObservedAt.Before(hr.UpdatedAt) {
		return out, dorm.ErrUnqualified
	}
	out = HeroInputs{Hero: h, Facts: f, PopulationVersion: hr.StateVersion, DormRootVersion: dr.StateVersion, ContentRevision: scope.ContentRevision, ObservedAt: scope.ObservedAt}
	if f.HouseID != 0 {
		r, e := s.Owner.ReadRoomTx(ctx, q, scope.Player, f.HouseID)
		if e != nil {
			return out, e
		}
		if scope.ObservedAt.Before(r.UpdatedAt) {
			return out, dorm.ErrUnqualified
		}
		out.Room = &r
		if r.MainType != dorm.LoungeType {
			out.GrowthBP, e = catalog.GrowthBP(r.TableID, r.Comfort, r.ExpansionLevel)
			if e != nil {
				return out, e
			}
		}
	}
	return out, nil
}

type VillaInputs struct {
	Count, PopulationVersion, DormRootVersion int64
	ContentRevision                           string
	ObservedAt                                time.Time
}

func (s Service) VillaCountTx(ctx context.Context, q tx.Queryer, scope InputScope) (VillaInputs, error) {
	var out VillaInputs
	if q == nil || !scope.Player.Valid() || !dorm.ValidRevision(scope.ContentRevision) || scope.ObservedAt.IsZero() {
		return out, dorm.ErrUnqualified
	}
	if _, e := s.Content.DormCatalogTx(ctx, q, scope.ContentRevision); e != nil {
		return out, e
	}
	hr, e := s.Heroes.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	dr, e := s.Owner.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	rooms, e := s.Owner.ListRoomsTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	if scope.ObservedAt.Before(dr.UpdatedAt) || scope.ObservedAt.Before(hr.UpdatedAt) {
		return out, dorm.ErrUnqualified
	}
	out = VillaInputs{PopulationVersion: hr.StateVersion, DormRootVersion: dr.StateVersion, ContentRevision: scope.ContentRevision, ObservedAt: scope.ObservedAt}
	for _, r := range rooms {
		if scope.ObservedAt.Before(r.UpdatedAt) {
			return out, dorm.ErrUnqualified
		}
		if r.MainType == 4 {
			out.Count++
		}
	}
	return out, nil
}
func (s Service) OverlayRosterTx(ctx context.Context, q tx.Queryer, a identity.ActorContext, rev string, at time.Time, body map[string]any) error {
	active, e := s.Content.DormInputsRevisionTx(ctx, q, rev)
	if e != nil {
		return e
	}
	if !active {
		return nil
	}
	rows, ok := body["heros"].(map[string]any)
	if !ok {
		return dorm.ErrUnqualified
	}
	for key, raw := range rows {
		p, e := strconv.ParseInt(key, 10, 64)
		if e != nil {
			return e
		}
		row, ok := raw.(map[string]any)
		if !ok {
			return dorm.ErrUnqualified
		}
		v, e := s.DormHouseInputsTx(ctx, q, InputScope{a.PlayerID, rev, at}, character.HeroRef{PlayerID: a.PlayerID, PartnerID: p})
		if e != nil {
			return e
		}
		rooms := map[int64]dorm.Room{}
		if v.Room != nil {
			rooms[v.Room.ID] = *v.Room
		}
		for k, x := range heroWire(v.Facts, rooms) {
			row[k] = x
		}
	}
	return nil
}
