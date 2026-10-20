package arena

import (
	"context"
	"errors"
	"fmt"
	"maps"
	"strconv"
	"time"

	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Service) templates(c context.Context, q tx.Queryer) (d.Templates, error) {
	revision, err := s.Content.ActiveRevision(c, q)
	if err != nil {
		return nil, err
	}
	return s.Content.ArenaTemplatesTx(c, q, revision)
}

func (s Service) heroRows(c context.Context, q tx.Queryer, pid identity.PlayerID, at time.Time) (map[string]any, error) {
	detail := map[string]any{}
	if err := s.Heroes.OverlayMID1(c, q, identity.ActorContext{PlayerID: pid}, false, at, detail); err != nil {
		return nil, err
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	return rows, nil
}

func (s Service) petRows(c context.Context, q tx.Queryer, pid identity.PlayerID, at time.Time) (map[string]map[string]any, error) {
	detail := map[string]any{}
	if err := s.Pets.OverlayMID1(c, q, identity.ActorContext{PlayerID: pid}, false, at, detail); err != nil {
		return nil, err
	}
	body, _ := detail["780"].(map[string]any)
	raw, _ := body["pets"].([]any)
	out := map[string]map[string]any{}
	for _, x := range raw {
		if row, ok := x.(map[string]any); ok {
			out[fmt.Sprint(row["pet_id"])] = row
		}
	}
	return out, nil
}

func number(v any) int64 {
	n, _ := strconv.ParseInt(fmt.Sprint(v), 10, 64)
	return n
}

// strongest is the owned copy of the girl (same base id) with the most stars,
// then the highest level, then the lowest partner id (C5D policy; the wire
// names girls by table id).
func strongest(roster map[string]any, templates d.Templates, tableID int64) (map[string]any, bool) {
	var best map[string]any
	for _, raw := range roster {
		row, ok := raw.(map[string]any)
		if !ok || templates.Base(number(row["table_id"])) != templates.Base(tableID) {
			continue
		}
		better := best == nil || number(row["star"]) > number(best["star"]) ||
			number(row["star"]) == number(best["star"]) && (number(row["lev"]) > number(best["lev"]) ||
				number(row["lev"]) == number(best["lev"]) && number(row["partner_id"]) < number(best["partner_id"]))
		if better {
			best = row
		}
	}
	return best, best != nil
}

// available resolves a girl for a lineup: the strongest owned copy, or nil
// for a girl summoned this season.
func (s Service) available(p d.Player, roster map[string]any, templates d.Templates, tableID int64) (map[string]any, bool) {
	if row, owned := strongest(roster, templates, tableID); owned {
		return row, true
	}
	award, _ := p.Award(templates.Base(tableID))
	_, known := templates[tableID]
	return nil, known && award.Summon
}

// summoned is a girl the player does not own, as the client builds it
// (Hero.initUnCollected): initial star, level 1, default skills and gear.
func summoned(templates d.Templates, tableID int64) map[string]any {
	return map[string]any{"player_id": 0, "partner_id": tableID, "table_id": tableID, "star": templates[tableID].InitialStar, "lev": 1, "color": 1,
		"skin_ids": map[string]any{}, "current_skin_id": 0, "illusion_skin_id": -1, "spirit_equip": []any{}, "spirit_item": []any{}, "practice_attr": []any{0, 0, 0},
		"equips": []any{0, 0, 0, 0, 0, 0}, "fumos": []any{0, 0, 0, 0, 0, 0}, "skills": []any{1, 1, 1, 1, 1, 1}}
}

// lineupRows shows a frozen lineup as the defender's current rows with the
// season awards applied (star, awakened table id); girls no longer available
// are left out.
func (s Service) lineupRows(c context.Context, q tx.Queryer, pid identity.PlayerID, lineup []d.Fighter, at time.Time) ([]map[string]any, error) {
	templates, err := s.templates(c, q)
	if err != nil {
		return nil, err
	}
	roster, err := s.heroRows(c, q, pid, at)
	if err != nil {
		return nil, err
	}
	out := []map[string]any{}
	for _, f := range lineup {
		row, owned := strongest(roster, templates, f.TableID)
		if !owned && !f.Summon {
			continue
		}
		if !owned {
			row = summoned(templates, f.TableID)
		}
		row = maps.Clone(row)
		row["star"] = min(number(row["star"])+f.AddStar, d.MaxStars(templates[f.TableID].Super))
		if f.Awake {
			for id, t := range templates {
				if t.Base == templates.Base(f.TableID) && t.Awakened {
					row["table_id"] = id
				}
			}
		}
		out = append(out, row)
	}
	return out, nil
}

func (s Service) face(c context.Context, q tx.Queryer, pid identity.PlayerID) (d.Face, error) {
	profile, found, err := s.Directory.ProfileTx(c, q, pid)
	if err != nil || !found {
		return d.Face{}, errors.Join(err, d.ErrUnavailable)
	}
	server := identity.LogicalServerID(int64(pid) / 100000)
	name, err := s.Servers.ServerNameTx(c, q, server)
	if err != nil {
		return d.Face{}, err
	}
	f := d.Face{Player: pid, Name: profile.Name, Level: profile.Level, AvatarID: profile.AvatarID, FrameID: profile.AvatarFrameID, ConquerLevel: profile.ConquerLevel,
		ConquerLoop: profile.ConquerLoopID, Server: server, ServerName: name}
	membership, member, err := s.Guilds.ReadMembershipTx(c, q, pid)
	if err != nil || !member {
		return f, err
	}
	g, found, err := s.Guilds.ReadGuildTx(c, q, membership.GuildID)
	if err == nil && found {
		f.GuildName = g.Name
	}
	return f, err
}
