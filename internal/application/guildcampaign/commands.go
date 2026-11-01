package guildcampaign

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// summaryPolicy is C8's versioned bound. The absolute damage ceiling is only a
// sanity bound; settlement clamps against the frozen copy waves.
//
// shortcut: the attestation policy is family-wide, not per-copy, so the frozen
// wave clamp runs in applyResult; a per-copy bound waits for a policy field.
var summaryPolicy = cd.SummaryPolicy{ID: "GUILD_CAMPAIGN_SUMMARY_V1", Version: 1, MaxStar: 3, WinFromStar: true, MaxDamage: 1 << 60}

// Fight is the 604 request as the wire decoded it.
type Fight struct {
	ChapterID     int64
	CopyID        int64
	CampaignType  int64
	Formation     string
	PetID         int64
	RentPlayer    int64
	RentFormation int64
	RentPetPlayer int64
	RentPetID     int64
}

// Result is the 610 request.
type Result struct {
	ChapterID    int64
	CopyID       int64
	CurrentIndex int64
	Formation    string
	PetID        int64
	TotalDamage  int64
	Star         int64
	Enemies      []ResultEnemy
}

// ResultEnemy is one enemy_status entry of the settled wave.
type ResultEnemy struct {
	HeroID   int64
	HP       int64
	IsReborn int64
	Index    int64
}

func locator(a identity.ActorContext) cd.Locator {
	return cd.Locator{DomainKind: "GUILD_CAMPAIGN", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprintf("player:%d", a.PlayerID)}
}

func generationRef(chapterID, copyID int64) string {
	return fmt.Sprintf("guild_campaign/%d/%d", chapterID, copyID)
}

func fingerprint(a identity.ActorContext, request Fight, formation []int64) string {
	fields := map[string]any{"policy": "I9_GUILD_CAMPAIGN_V1", "player": int64(a.PlayerID), "chapter": request.ChapterID, "copy": request.CopyID,
		"formation": formation, "pet": request.PetID, "rent_player": request.RentPlayer, "rent_formation": request.RentFormation,
		"rent_pet_player": request.RentPetPlayer, "rent_pet_id": request.RentPetID}
	raw, _ := json.Marshal(fields)
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

// parseFormation reads the stock "id|id" string into slot order, 0 for empty.
func parseFormation(raw string) ([]int64, error) {
	parts := strings.Split(raw, "|")
	out := make([]int64, 0, len(parts))
	for _, part := range parts {
		if part == "" {
			out = append(out, 0)
			continue
		}
		value, err := strconv.ParseInt(part, 10, 64)
		if err != nil || value < 0 {
			return nil, d.ErrRefused
		}
		out = append(out, value)
	}
	return out, nil
}

func secondsOfDay(at time.Time) int64 {
	return (at.Unix() + 8*3600) % 86400
}

func windowSeconds(settings Settings, stage int64) int64 {
	if stage == d.StageFight {
		return settings.BattleSeconds
	}
	return settings.PrepareSeconds
}

// holderLive reports whether a claim is still running at at.
func holderLive(copy d.Copy, settings Settings, at time.Time) bool {
	if copy.HolderID == 0 {
		return false
	}
	var since *time.Time
	switch copy.HolderStage {
	case d.StagePrepare:
		since = copy.LastFightTime
	case d.StageFight:
		since = copy.StartFightTime
	default:
		return false
	}
	if since == nil {
		return false
	}
	return at.Before(since.Add(time.Duration(windowSeconds(settings, copy.HolderStage)) * time.Second))
}

func currentIndex(copy d.Copy) int64 {
	if copy.CurrentIndex < 1 {
		return 1
	}
	if copy.CurrentIndex > 3 {
		return 3
	}
	return copy.CurrentIndex
}

func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}
}

// Claim is 614 (C6). A free or expired copy is claimed at stage 1; another
// holder's live claim is read back without a write.
func (m Mode) Claim(c context.Context, a identity.ActorContext, copyID int64, op operation.Context) (ClaimView, error) {
	if !m.ready() || copyID <= 0 {
		return ClaimView{}, ErrUnavailable
	}
	chapterID, known := m.Content.ChapterOfCopy(copyID)
	if !known {
		return ClaimView{}, d.ErrRefused
	}
	var out ClaimView
	var guildID int64
	_, err := m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc tx.Scope) error {
		at := op.StartedAt.UTC()
		if err := m.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		if _, err := m.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); err != nil {
			return err
		}
		membership, joined, err := m.Service.Guilds.ReadMembership(c, a.PlayerID)
		if err != nil {
			return err
		}
		if !joined {
			return d.ErrRefused
		}
		guildID = int64(membership.GuildID)
		registered, err := m.ModeStore.IsRegisteredTx(c, sc.Tx, guildID, chapterID, a.PlayerID)
		if err != nil {
			return err
		}
		if !registered {
			return d.ErrRefused
		}
		chapter, open, err := m.Service.Store.LockChapterTx(c, sc.Tx, guildID, chapterID)
		if err != nil {
			return err
		}
		if !open || chapter.Win {
			return d.ErrRefused
		}
		copy, found, err := m.ModeStore.LockCopyTx(c, sc.Tx, guildID, chapterID, copyID)
		if err != nil {
			return err
		}
		if !found || copy.Win {
			return d.ErrRefused
		}
		if !holderLive(copy, m.Settings, at) {
			copy.HolderID = int64(a.PlayerID)
			copy.HolderStage = d.StagePrepare
			copy.LastFightTime = &at
			copy.StartFightTime = nil
			if err := m.ModeStore.SaveCopyTx(c, sc.Tx, copy); err != nil {
				return err
			}
		}
		holder := identity.PlayerID(copy.HolderID)
		view, err := m.profileTx(c, sc.Tx, holder)
		if err != nil {
			return err
		}
		out = ClaimView{Stage: copy.HolderStage, HolderID: copy.HolderID, LastFight: copy.LastFightTime, StartFight: copy.StartFightTime, FightInfo: view}
		return nil
	})
	if err != nil {
		return ClaimView{}, err
	}
	if m.Notifier != nil {
		_ = m.Notifier.Notify(c, guildID, chapterID, copyID, a.PlayerID)
	}
	return out, nil
}

// Start is 604 (C4-C7, C9).
func (m Mode) Start(c context.Context, a identity.ActorContext, request Fight, op operation.Context) (Started, error) {
	if !m.ready() || request.CopyID <= 0 || request.ChapterID <= 0 || request.CampaignType != 7 {
		return Started{}, ErrUnavailable
	}
	formation, err := parseFormation(request.Formation)
	if err != nil {
		return Started{}, err
	}
	info, known := m.Content.CopyInfo(request.ChapterID, request.CopyID)
	if !known {
		return Started{}, d.ErrRefused
	}
	var out Started
	var guildID int64
	_, err = m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc tx.Scope) error {
		at := op.StartedAt.UTC()
		if m.Settings.InRestWindow(secondsOfDay(at)) {
			return d.ErrRefused
		}
		if err := m.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		if _, err := m.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); err != nil {
			return err
		}
		day := modes.Day(at)
		clears, err := m.ModeStore.MemberClearsTx(c, sc.Tx, a.PlayerID, request.ChapterID, day)
		if err != nil {
			return err
		}
		if clears >= m.Settings.AttemptsPerChapterDay {
			return d.ErrRefused
		}
		membership, joined, err := m.Service.Guilds.ReadMembership(c, a.PlayerID)
		if err != nil {
			return err
		}
		if !joined {
			return d.ErrRefused
		}
		guildID = int64(membership.GuildID)
		registered, err := m.ModeStore.IsRegisteredTx(c, sc.Tx, guildID, request.ChapterID, a.PlayerID)
		if err != nil {
			return err
		}
		if !registered {
			return d.ErrRefused
		}
		chapter, open, err := m.Service.Store.LockChapterTx(c, sc.Tx, guildID, request.ChapterID)
		if err != nil {
			return err
		}
		if !open || chapter.Win {
			return d.ErrRefused
		}
		locked, found, err := m.ModeStore.LockCopyTx(c, sc.Tx, guildID, request.ChapterID, request.CopyID)
		if err != nil {
			return err
		}
		if !found || locked.Win {
			return d.ErrRefused
		}
		if holderLive(locked, m.Settings, at) && locked.HolderID != int64(a.PlayerID) {
			return ErrHolder
		}
		locked.HolderID = int64(a.PlayerID)
		locked.HolderStage = d.StageFight
		locked.StartFightTime = &at
		locked.LastFightTime = &at
		revision, _ := sc.Operation.Policies.Get("content")
		scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation, Attempt: sc.Attempt, Options: sc.Options}, revision, at)
		if err != nil {
			return err
		}
		started, err := m.Combat.StartTx(c, sc.Tx, scope, combat.StartRequest{Actor: a, Locator: locator(a), GenerationRef: generationRef(request.ChapterID, request.CopyID),
			StartFingerprint: fingerprint(a, request, formation), ResultDeadline: at.Add(time.Duration(m.Settings.BattleSeconds) * time.Second),
			Battle: battleRequest(a, info, formation, request), TrustProfile: cd.ClientSummaryAttested, Replay: cd.ReplaySpec{Response: cd.ReplayOK},
			Package: func(*cd.Stream) (any, error) { return map[string]any{}, nil }})
		if err != nil {
			return err
		}
		locked.AttemptGeneration = started.Attempt.ID.String()
		if err := m.ModeStore.SaveCopyTx(c, sc.Tx, locked); err != nil {
			return err
		}
		out = Started{CopyID: request.CopyID, CurrentIndex: currentIndex(locked), Waves: wavesOf(info)}
		return nil
	})
	if err != nil {
		return Started{}, err
	}
	if m.Notifier != nil {
		_ = m.Notifier.Notify(c, guildID, request.ChapterID, request.CopyID, a.PlayerID)
	}
	return out, nil
}

func battleRequest(a identity.ActorContext, info CopyInfo, formation []int64, request Fight) combat.BattleRequest {
	battle := combat.BattleRequest{CampaignType: 7, BattleID: info.FightID, Formation: formation}
	for _, partner := range formation {
		if partner > 0 {
			battle.TeamA = append(battle.TeamA, combat.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: partner})
		}
	}
	if request.PetID > 0 {
		battle.PetsA = append(battle.PetsA, combat.Participant{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: a.PlayerID, Identity: request.PetID})
	}
	if request.RentPlayer > 0 && request.RentFormation > 0 {
		battle.TeamA = append(battle.TeamA, combat.Participant{Origin: cd.Borrowed, Kind: cd.HeroActor, Player: identity.PlayerID(request.RentPlayer), Identity: request.RentFormation})
	}
	if request.RentPetPlayer > 0 && request.RentPetID > 0 {
		battle.PetsA = append(battle.PetsA, combat.Participant{Origin: cd.Borrowed, Kind: cd.PetActor, Player: identity.PlayerID(request.RentPetPlayer), Identity: request.RentPetID})
	}
	for wave := int64(1); wave <= 3; wave++ {
		participants := []combat.Participant{}
		for _, enemy := range info.Waves[wave] {
			participants = append(participants, combat.Participant{Origin: cd.Template, Kind: cd.HeroActor, Identity: enemy.TableID, TemplateParams: map[string]any{"table_id": enemy.TableID}})
		}
		battle.WavesB = append(battle.WavesB, participants)
	}
	return battle
}

func wavesOf(info CopyInfo) map[int64][]EnemyRow {
	out := map[int64][]EnemyRow{}
	for wave := int64(1); wave <= 3; wave++ {
		out[wave] = info.Waves[wave]
	}
	return out
}

// Settle is 610 (C1, C8, C9, C10, C11) in C2's order: member day 605, chapter
// 606, copy 607, server records 608, Combat 609, payout mail 610, grants 700+,
// then the fact.
func (m Mode) Settle(c context.Context, a identity.ActorContext, request Result, op operation.Context) (Settled, error) {
	if !m.ready() || request.CopyID <= 0 || request.ChapterID <= 0 {
		return Settled{}, ErrUnavailable
	}
	formation, err := parseFormation(request.Formation)
	if err != nil {
		return Settled{}, err
	}
	info, known := m.Content.CopyInfo(request.ChapterID, request.CopyID)
	if !known {
		return Settled{}, d.ErrRefused
	}
	chapterInfo, known := m.Content.ChapterInfo(request.ChapterID)
	if !known {
		return Settled{}, d.ErrRefused
	}
	var out Settled
	var guildID int64
	_, err = m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc tx.Scope) error {
		at := op.StartedAt.UTC()
		if err := m.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		if _, err := m.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); err != nil {
			return err
		}
		membership, joined, err := m.Service.Guilds.ReadMembership(c, a.PlayerID)
		if err != nil {
			return err
		}
		if !joined {
			return d.ErrRefused
		}
		guildID = int64(membership.GuildID)
		day := modes.Day(at)
		if _, err := m.ModeStore.MemberClearsTx(c, sc.Tx, a.PlayerID, request.ChapterID, day); err != nil {
			return err
		}
		registered, err := m.ModeStore.IsRegisteredTx(c, sc.Tx, guildID, request.ChapterID, a.PlayerID)
		if err != nil {
			return err
		}
		if !registered {
			return d.ErrRefused
		}
		chapter, open, err := m.Service.Store.LockChapterTx(c, sc.Tx, guildID, request.ChapterID)
		if err != nil {
			return err
		}
		if !open || chapter.Win {
			return ErrLate
		}
		copy, found, err := m.ModeStore.LockCopyTx(c, sc.Tx, guildID, request.ChapterID, request.CopyID)
		if err != nil {
			return err
		}
		if !found {
			return ErrLate
		}
		if copy.HolderID == 0 && copy.AttemptGeneration != "" && (copy.Win || request.CurrentIndex < currentIndex(copy)) {
			out = duplicateBody()
			return nil
		}
		if !holderLive(copy, m.Settings, at) || copy.HolderID != int64(a.PlayerID) || copy.HolderStage != d.StageFight {
			return ErrLate
		}
		summary := cd.Summary{Star: clampStar(request.Star), Win: request.Star > 0, Damage: maxDamage(request.TotalDamage), Alive: int64(len(nonZero(formation))),
			Formation: formation, Pet: request.PetID, Enemies: summaryEnemies(request.Enemies)}
		attested, err := m.Combat.AttestSummaryTx(c, sc.Tx, combat.SummaryRequest{Locator: locator(a), GenerationRef: generationRef(request.ChapterID, request.CopyID),
			TerminalKind: combatKind, At: at, Policy: summaryPolicy, Summary: summary})
		if err != nil {
			return err
		}
		if attested.Drained {
			out = duplicateBody()
			return nil
		}
		if attested.Attempt.TerminalKind == cd.RejectedKind {
			return d.ErrRefused
		}
		result, err := m.applyResult(c, sc.Tx, a, op, guildID, chapter, chapterInfo, copy, info, request, at)
		if err != nil {
			return err
		}
		out = result
		return nil
	})
	if err != nil {
		return Settled{}, err
	}
	if m.Notifier != nil && !out.Duplicate && !out.Late {
		_ = m.Notifier.Notify(c, guildID, request.ChapterID, request.CopyID, a.PlayerID)
	}
	return out, nil
}

func clampStar(star int64) int64 {
	if star < 0 {
		return 0
	}
	if star > 3 {
		return 3
	}
	return star
}

func maxDamage(damage int64) int64 {
	if damage < 0 {
		return 0
	}
	return damage
}

func nonZero(values []int64) []int64 {
	out := []int64{}
	for _, value := range values {
		if value != 0 {
			out = append(out, value)
		}
	}
	return out
}

func summaryEnemies(enemies []ResultEnemy) []cd.EnemyStatus {
	out := make([]cd.EnemyStatus, 0, len(enemies))
	for _, enemy := range enemies {
		out = append(out, cd.EnemyStatus{Identity: enemy.HeroID, HP: enemy.HP})
	}
	return out
}

func duplicateBody() Settled {
	return Settled{Duplicate: true, Body: map[string]any{
		"error_code":  int64(30005),
		"rank_award":  map[string]any{"crystal": int64(0), "guild_coin": int64(0)},
		"normal_drop": []any{}, "guild_drop": []any{}, "coin_award": int64(0), "exps": []any{},
	}}
}

func decodeWaves(raw []byte) (map[int64][]EnemyRow, error) {
	out := map[int64][]EnemyRow{}
	if len(raw) == 0 {
		return out, nil
	}
	if err := json.Unmarshal(raw, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func encodeWaves(waves map[int64][]EnemyRow) ([]byte, error) {
	return json.Marshal(waves)
}

// applyResult writes the settled wave, the member day, the rank and server
// records, and the chapter end with its payout and grants.
func (m Mode) applyResult(c context.Context, t tx.Tx, a identity.ActorContext, op operation.Context, guildID int64, chapter d.Chapter, chapterInfo ChapterInfo, copy d.Copy, info CopyInfo, request Result, at time.Time) (Settled, error) {
	waves, err := decodeWaves(copy.Waves)
	if err != nil {
		return Settled{}, err
	}
	cleared := request.Star > 0
	index := currentIndex(copy)
	waves, damage := clampWaves(waves, info, index, request.Enemies, cleared)
	copy.Waves, _ = encodeWaves(waves)
	if cleared {
		copy.CurrentIndex = index + 1
		if copy.CurrentIndex > 3 {
			copy.CurrentIndex = 3
			copy.Win = true
		}
		copy.Percent = float64(copy.CurrentIndex-1) / 3
		if copy.Win {
			copy.Percent = 1
		}
	}
	copy.HolderID = 0
	copy.HolderStage = d.StageFree
	copy.LastFightTime = &at
	copy.StartFightTime = nil
	if err := m.ModeStore.SaveCopyTx(c, t, copy); err != nil {
		return Settled{}, err
	}
	day := modes.Day(at)
	if cleared {
		if err := m.ModeStore.DeleteOldMemberDaysTx(c, t, a.PlayerID, request.ChapterID, day); err != nil {
			return Settled{}, err
		}
		if err := m.ModeStore.BumpMemberClearsTx(c, t, a.PlayerID, request.ChapterID, day); err != nil {
			return Settled{}, err
		}
	}
	rankDamage := damage
	if cleared && lastEnemyDead(waves[index]) {
		rankDamage = damage * m.Settings.BossRankFactor
	}
	if err := m.ModeStore.UpsertDamageTx(c, t, guildID, request.ChapterID, chapter.Run, int64(a.PlayerID), rankDamage, at); err != nil {
		return Settled{}, err
	}
	if err := m.ModeStore.UpsertServerRecordTx(c, t, a.LogicalServerID, request.CopyID, int64(a.PlayerID), guildID, damage, []byte("[]"), at); err != nil {
		return Settled{}, err
	}
	if copy.Win {
		elapsed := int64(at.Sub(chapter.StartTime).Seconds())
		if _, _, err := m.ModeStore.ServerKillTx(c, t, a.LogicalServerID, request.CopyID, int64(a.PlayerID), guildID, at, elapsed); err != nil {
			return Settled{}, err
		}
	}
	return m.finishCopy(c, t, a, op, guildID, chapter, chapterInfo, copy, info, damage, at)
}

// clampWaves applies the client's enemy HP to the current wave only. Cleared
// waves keep their stored state, and a stored partial HP never rises.
func clampWaves(waves map[int64][]EnemyRow, info CopyInfo, index int64, enemies []ResultEnemy, cleared bool) (map[int64][]EnemyRow, int64) {
	damage := int64(0)
	if len(waves) == 0 {
		for wave := int64(1); wave <= 3; wave++ {
			waves[wave] = append([]EnemyRow(nil), info.Waves[wave]...)
		}
	}
	current := waves[index]
	for _, enemy := range enemies {
		if enemy.Index != index {
			continue
		}
		if enemy.HP > 0 {
			damage += enemy.HP
		}
		for position := range current {
			if current[position].TableID != enemy.HeroID {
				continue
			}
			hp := enemy.HP
			if hp < 0 {
				hp = 0
			}
			if current[position].HP > 0 && hp > current[position].HP {
				hp = current[position].HP
			}
			current[position].HP = hp
			current[position].Reborn = enemy.IsReborn
			if hp == 0 {
				current[position].Health = 1
			}
			break
		}
	}
	if cleared {
		for position := range current {
			current[position].Health = 1
			current[position].HP = 0
		}
	}
	waves[index] = current
	return waves, damage
}

func lastEnemyDead(wave []EnemyRow) bool {
	if len(wave) == 0 {
		return false
	}
	last := wave[len(wave)-1]
	return last.Health != 0 || last.HP == 0
}

// finishCopy writes the chapter progress, the clear payout and awards, and the
// per-challenge grants and fact, in C2's remaining order.
func (m Mode) finishCopy(c context.Context, t tx.Tx, a identity.ActorContext, op operation.Context, guildID int64, chapter d.Chapter, chapterInfo ChapterInfo, copy d.Copy, info CopyInfo, damage int64, at time.Time) (Settled, error) {
	copies, err := m.ModeStore.ListCopiesTx(c, t, guildID, chapter.ChapterID)
	if err != nil {
		return Settled{}, err
	}
	wins, total := 0, len(copies)
	for _, row := range copies {
		if row.Win {
			wins++
		}
	}
	percent := 0.0
	if total > 0 {
		percent = float64(wins) / float64(total)
	}
	chapterWon := total > 0 && wins == total
	var end *time.Time
	if chapterWon {
		percent = 1
		end = &at
	}
	if err := m.ModeStore.SaveChapterProgressTx(c, t, guildID, chapter.ChapterID, chapter.Run, percent, chapterWon, end); err != nil {
		return Settled{}, err
	}
	registered, err := m.ModeStore.ListRegisteredTx(c, t, guildID, chapter.ChapterID)
	if err != nil {
		return Settled{}, err
	}
	if chapterWon {
		if err := m.Service.Store.AppendLogTx(c, t, guildID, d.LogFinalHit, a.PlayerID, chapter.ChapterID, at); err != nil {
			return Settled{}, err
		}
		if err := m.seedAwards(c, t, guildID, chapter.ChapterID, chapter.Run, chapterInfo, len(info.Waves[1]), at); err != nil {
			return Settled{}, err
		}
		if m.Service.Payout != nil {
			won := chapter
			won.Win = true
			won.Percent = 1
			won.EndTime = end
			if err := m.Service.Payout.PayRunTx(c, t, won, registered, at); err != nil {
				return Settled{}, err
			}
		}
	}
	gold := damage * m.Settings.RewardParamPerMille / 1000
	lines := []grant.Line{}
	if gold > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: goldResource, Amount: gold})
	}
	if chapterWon && m.Settings.FirstRewardCoin > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: dungeonCoinResource, Amount: m.Settings.FirstRewardCoin})
	}
	timed, err := gen.NewTimedOperation(op, at)
	if err != nil {
		return Settled{}, err
	}
	attempt := copy.AttemptGeneration
	if attempt == "" {
		attempt = "none"
	}
	prepared, err := m.Facts.PrepareTx(c, t, a.PlayerID, timed)
	if err != nil {
		return Settled{}, err
	}
	if len(lines) > 0 {
		plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "guildcampaign", Operation: "result",
			BusinessKey: fmt.Sprintf("guild_campaign:%d:%d:%s", chapter.ChapterID, copy.CopyID, attempt), Occurrence: attempt, PolicyVersion: "I9_GUILD_CAMPAIGN_V1"}, Lines: lines}
		if _, err := m.Grants.SettleGrantTx(c, t, a, plan, timed.Operation(), i5.GrantTxOptions{AllowOverflowMail: true}); err != nil {
			return Settled{}, err
		}
	}
	fact := objective.Fact{PlayerID: a.PlayerID, SourceDomain: "guildcampaign",
		SourceBusinessKey: fmt.Sprintf("guild_campaign:%d:%d:%s", chapter.ChapterID, copy.CopyID, attempt), Kind: factKind, Delta: 1}
	if err := m.Facts.RecordTx(prepared, t, timed.Operation(), fact); err != nil {
		return Settled{}, err
	}
	return Settled{Body: map[string]any{
		"rank_award":  map[string]any{"crystal": int64(0), "guild_coin": int64(0)},
		"normal_drop": []any{}, "guild_drop": []any{}, "coin_award": gold, "exps": []any{},
	}}, nil
}

func (m Mode) seedAwards(c context.Context, t tx.Tx, guildID, chapterID, run int64, chapterInfo ChapterInfo, copies int, at time.Time) error {
	if len(chapterInfo.Items) == 0 || copies <= 0 {
		return nil
	}
	slot := m.nextSlot(at)
	expires := at.Add(time.Duration(m.Settings.RewardTimeLimitSecond) * time.Second)
	seeds := make([]AwardSeed, 0, len(chapterInfo.Items))
	for _, item := range chapterInfo.Items {
		if item <= 0 {
			continue
		}
		seeds = append(seeds, AwardSeed{AwardID: item, Remaining: int64(copies), ExpiresAt: expires, NextSlot: slot})
	}
	return m.ModeStore.InsertAwardsTx(c, t, guildID, chapterID, run, seeds)
}

// nextSlot is the first dist_reward_time slot after at, never a skipped one.
func (m Mode) nextSlot(at time.Time) time.Time {
	midnight := time.Unix(at.Unix()-secondsOfDay(at), 0).UTC()
	for _, seconds := range m.Settings.DistRewardTime {
		candidate := midnight.Add(time.Duration(seconds) * time.Second)
		if candidate.After(at) {
			return candidate
		}
	}
	if len(m.Settings.DistRewardTime) == 0 {
		return at.Add(24 * time.Hour)
	}
	return midnight.Add(24*time.Hour + time.Duration(m.Settings.DistRewardTime[0])*time.Second)
}
