package i5store

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"time"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
	backpackproj "gxb.local/backend/v2/internal/projection/backpack"
)

// BootstrapProjection contributes only domains implemented by I5. The frozen
// Wave-S baseline continues to own not-yet-implemented fields.
type BootstrapSpiritInventory interface {
	InventoryForBootstrapTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) ([]map[string]any, error)
}
type BootstrapProjection struct {
	Spirit       BootstrapSpiritInventory
	Display      appi5.TxEffectivePlayerDisplayReader
	Content      appi5.ContentRuntime
	Privileges   appi5.PrivilegeSnapshotProvider
	MaxHeroColor appi5.MaxHeroColorPolicyProvider
}

func (BootstrapProjection) Name() string { return "i5.player-core-economy-mail-r5" }
func (b BootstrapProjection) Claims() []string {
	claims := []string{
		"17.player_name", "17.player_type", "17.avatar_id", "17.avatar_frame_id",
		"17.lev", "17.exp", "17.max_lev", "17.max_color", "17.story_id", "17.story_state", "17.guide_id",
		"17.func_ids", "17.guide_function_ids", "17.guide_return_id",
		"17.energy_time", "17.max_energy", "17.spirit_energy_time", "17.skill_time",
		"81", "368",
	}
	if b.Display != nil {
		claims = append(claims, "17.title_info", "17.bubble_info")
	}
	keys := make([]string, 0, len(stockEconomyFields))
	for key := range stockEconomyFields {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		claims = append(claims, "17."+key)
	}
	return claims
}

func (b BootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, created bool, now time.Time, detail map[string]any) error {
	pid := actor.PlayerID
	if q == nil || !pid.Valid() || now.IsZero() || detail == nil || b.Content == nil || b.Privileges == nil || b.MaxHeroColor == nil {
		return errors.New("invalid I5 R5 bootstrap projection input")
	}
	core, err := loadPlayerCore(ctx, q, pid)
	if err != nil {
		return err
	}
	owned, err := core.MID17OwnedFields()
	if err != nil {
		return err
	}
	mid17, ok := detail["17"].(map[string]any)
	if !ok {
		return errors.New("MID17 frozen baseline missing")
	}
	for k, v := range owned {
		mid17[k] = v
	}
	if b.Display != nil {
		rev, e := b.Content.ActiveRevision(ctx, q)
		if e != nil {
			return e
		}
		d, e := b.Display.ReadEffectivePlayerDisplayTx(ctx, q, pid, rev, now.UTC())
		if e != nil {
			return e
		}
		if d.ProfileVersion != core.Profile.StateVersion || d.ProgressionVersion != core.Progression.StateVersion || d.ContentRevision != rev || !d.ObservedAt.Equal(now.UTC()) {
			return errors.New("display observation drift")
		}
		mid17["avatar_id"] = d.AvatarID
		mid17["avatar_frame_id"] = d.AvatarFrameID
		mid17["title_info"] = d.TitleInfo
		mid17["bubble_info"] = d.BubbleInfo
	}
	mid17["max_color"] = b.MaxHeroColor.MaxHeroColor()
	if err := b.overlayEconomy(ctx, q, pid, core.Progression, now.UTC(), mid17); err != nil {
		return err
	}
	stacks, err := (Store{}).ListStacksTx(ctx, q, pid)
	if err != nil {
		return err
	}
	backpackWire, err := backpackproj.Build(stacks)
	if err != nil {
		return err
	}
	if b.Spirit != nil {
		rev, e := b.Content.ActiveRevision(ctx, q)
		if e != nil {
			return e
		}
		rows, e := b.Spirit.InventoryForBootstrapTx(ctx, q, pid, rev, now.UTC())
		if e != nil {
			return e
		}
		backpackWire["spirit_list"] = rows
	}
	detail["81"] = backpackWire
	if !created {
		records, total, fresh, err := (Store{}).ListMailTx(ctx, q, pid, now.UTC(), 20)
		if err != nil {
			return err
		}
		wire := make([]any, 0, len(records))
		for _, r := range records {
			v, err := r.WireProjection()
			if err != nil {
				return err
			}
			wire = append(wire, v)
		}
		detail["368"] = map[string]any{"mail_list": wire, "total": total, "new_mail_total": fresh}
	}
	return nil
}

func loadPlayerCore(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (player.Core, error) {
	var c player.Core
	var profilePID, progressionPID, storyPID, guidePID int64
	err := q.QueryRow(ctx, `SELECT p.player_id,p.display_name,p.avatar_id,p.avatar_frame_id,p.player_type,p.state_version,p.created_at,p.updated_at,
 pr.player_id,pr.level,pr.exp,pr.state_version,pr.updated_at,
 s.player_id,s.story_id,s.story_state,s.guide_id,s.state_version,s.updated_at,
 g.player_id,g.guide_return_id,g.guide_function_ids,g.state_version,g.updated_at
 FROM player_profiles p JOIN player_progression pr USING(player_id) JOIN player_story_cursors s USING(player_id) JOIN player_guide_return_state g USING(player_id)
 WHERE p.player_id=$1`, int64(pid)).Scan(
		&profilePID, &c.Profile.DisplayName, &c.Profile.AvatarID, &c.Profile.AvatarFrameID, &c.Profile.PlayerType, &c.Profile.StateVersion, &c.Profile.CreatedAt, &c.Profile.UpdatedAt,
		&progressionPID, &c.Progression.Level, &c.Progression.Exp, &c.Progression.StateVersion, &c.Progression.UpdatedAt,
		&storyPID, &c.Story.StoryID, &c.Story.StoryState, &c.Story.GuideID, &c.Story.StateVersion, &c.Story.UpdatedAt,
		&guidePID, &c.GuideReturn.GuideReturnID, &c.GuideReturn.GuideFunctionIDs, &c.GuideReturn.StateVersion, &c.GuideReturn.UpdatedAt,
	)
	if err != nil {
		return player.Core{}, err
	}
	if profilePID != int64(pid) || progressionPID != int64(pid) || storyPID != int64(pid) || guidePID != int64(pid) {
		return player.Core{}, errors.New("player core owner join mismatch")
	}
	c.Profile.PlayerID, c.Progression.PlayerID, c.Story.PlayerID, c.GuideReturn.PlayerID = pid, pid, pid, pid
	var raw string
	if err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('function_id',function_id,'opened_at',opened_at,'source_fact_key',source_fact_key,'state_version',state_version) ORDER BY function_id),'[]'::jsonb)::text FROM player_function_unlocks WHERE player_id=$1`, int64(pid)).Scan(&raw); err != nil {
		return player.Core{}, err
	}
	var fs []struct {
		FunctionID    int64     `json:"function_id"`
		OpenedAt      time.Time `json:"opened_at"`
		SourceFactKey string    `json:"source_fact_key"`
		StateVersion  int64     `json:"state_version"`
	}
	if err := json.Unmarshal([]byte(raw), &fs); err != nil {
		return player.Core{}, err
	}
	for _, f := range fs {
		c.Functions = append(c.Functions, player.FunctionUnlock{PlayerID: pid, FunctionID: f.FunctionID, OpenedAt: f.OpenedAt.UTC(), SourceFactKey: f.SourceFactKey, StateVersion: f.StateVersion})
	}
	return c, c.Validate()
}

// stockEconomyFields omits invitation: see the lobby MID17 shape.
var stockEconomyFields = map[string]struct{}{
	"mana": {}, "crystal": {}, "lucky_coin": {}, "arena_coin": {}, "march_coin": {}, "top_coin": {}, "guild_coin": {}, "region_coin": {},
	"king_coin": {}, "honor_coin": {}, "god_war_coin": {}, "friendship_coin": {}, "friend_medal": {}, "summon_coin": {}, "skin_fragment": {}, "glue": {},
	"lvbu_coin": {}, "paradise_coin": {}, "team_dungeon_coin": {}, "ice_core": {}, "spirit_stone": {}, "energy": {}, "spirit_energy": {}, "skill_point": {},
	"social": {}, "glory": {}, "magic_energy": {}, "magic_dust": {}, "magic_liquid": {}, "magic_exp": {}, "degree_cer": {}, "graduate_cer": {}, "patent_cer": {}, "occult_ticket": {}, "tutor_coin": {}, "skin_coin": {},
}

func stockAnchor(a *time.Time) int64 {
	if a == nil {
		return 0
	}
	return a.UTC().Unix()
}

func (b BootstrapProjection) overlayEconomy(ctx context.Context, q tx.Queryer, pid identity.PlayerID, progression player.Progression, now time.Time, out map[string]any) error {
	// I5 already owns these canonical scalar identities. Absence is canonical zero,
	// not permission to retain a frozen-baseline placeholder.
	out["mana"], out["crystal"] = int64(0), int64(0)
	var scalarRaw string
	if err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_object_agg(resource_key,amount),'{}'::jsonb)::text FROM player_currency_balances WHERE player_id=$1`, int64(pid)).Scan(&scalarRaw); err != nil {
		return err
	}
	var scalars map[string]int64
	if err := json.Unmarshal([]byte(scalarRaw), &scalars); err != nil {
		return err
	}
	for key, amount := range scalars {
		if _, ok := stockEconomyFields[key]; ok {
			out[key] = amount
		}
	}

	activeRevision, err := b.Content.ActiveRevision(ctx, q)
	if err != nil {
		return fmt.Errorf("MID1 active content: %w", err)
	}
	activeProgression, err := b.Content.ResolveProgressionPolicyTx(ctx, q, activeRevision)
	if err != nil {
		return fmt.Errorf("MID1 max-level policy: %w", err)
	}
	out["max_lev"] = activeProgression.MaxLevel()

	var temporalRaw string
	qsql := `SELECT COALESCE(jsonb_agg(jsonb_build_object('resource_key',r.resource_key,'stored_amount',r.stored_amount,'regen_anchor_at',r.regen_anchor_at,'policy_version',r.policy_version,'content_revision',COALESCE(r.content_revision,''),'state_version',r.state_version,'updated_at',r.updated_at) ORDER BY r.resource_key),'[]'::jsonb)::text FROM player_temporal_resources r WHERE r.player_id=$1`
	if err := q.QueryRow(ctx, qsql, int64(pid)).Scan(&temporalRaw); err != nil {
		return err
	}
	var rows []struct {
		ResourceKey     string     `json:"resource_key"`
		StoredAmount    int64      `json:"stored_amount"`
		RegenAnchorAt   *time.Time `json:"regen_anchor_at"`
		PolicyVersion   string     `json:"policy_version"`
		ContentRevision string     `json:"content_revision"`
		StateVersion    int64      `json:"state_version"`
		UpdatedAt       time.Time  `json:"updated_at"`
	}
	if err := json.Unmarshal([]byte(temporalRaw), &rows); err != nil {
		return err
	}
	for _, r := range rows {
		if _, ok := stockEconomyFields[r.ResourceKey]; !ok {
			continue
		}
		state := economy.TemporalState{PlayerID: pid, ResourceKey: r.ResourceKey, StoredAmount: r.StoredAmount, RegenAnchorAt: r.RegenAnchorAt, PolicyVersion: r.PolicyVersion, ContentRevision: r.ContentRevision, StateVersion: r.StateVersion, UpdatedAt: r.UpdatedAt.UTC()}
		var policy economy.TemporalPolicy
		if r.ContentRevision == "" {
			rp, err := (Store{}).ResolveLegacyTemporalPolicyTx(ctx, q, r.ResourceKey, r.PolicyVersion)
			if err != nil || rp.Temporal == nil {
				if err == nil {
					err = economy.ErrUnknownResource
				}
				return fmt.Errorf("temporal projection %s legacy policy: %w", r.ResourceKey, err)
			}
			policy = *rp.Temporal
		} else {
			line := grant.Line{Kind: grant.Temporal, ResourceKey: r.ResourceKey, Amount: 1}
			rp, err := b.Content.ResolveResourceTx(ctx, q, r.ContentRevision, line)
			if err != nil || rp.Descriptor == nil {
				if err == nil {
					err = economy.ErrUnknownResource
				}
				return fmt.Errorf("temporal projection %s exact descriptor: %w", r.ResourceKey, err)
			}
			pp, err := b.Content.ResolveProgressionPolicyTx(ctx, q, r.ContentRevision)
			if err != nil {
				return fmt.Errorf("temporal projection %s progression: %w", r.ResourceKey, err)
			}
			policy, _, err = appi5.ResolveTemporalPolicyTx(ctx, q, pid, *rp.Descriptor, pp, progression.Level, now, b.Privileges)
			if err != nil {
				return fmt.Errorf("temporal projection %s dynamic policy: %w", r.ResourceKey, err)
			}
		}
		m, err := state.Materialize(now, policy)
		if err != nil {
			return fmt.Errorf("temporal projection %s: %w", r.ResourceKey, err)
		}
		out[r.ResourceKey] = m.Amount
		switch r.ResourceKey {
		case "energy":
			out["energy_time"], out["max_energy"] = stockAnchor(m.State.RegenAnchorAt), policy.NaturalCap
		case "spirit_energy":
			out["spirit_energy_time"] = stockAnchor(m.State.RegenAnchorAt)
		case "skill_point":
			out["skill_time"] = stockAnchor(m.State.RegenAnchorAt)
		}
	}
	return nil
}

var _ appboot.MID1DetailContributor = BootstrapProjection{}
