package combat

import (
	"context"
	"encoding/json"
	"fmt"
	"sort"
	"strconv"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/combat"
	cq "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Participant names one actor. Owned actors are read from their owners at the
// decision instant; TEMPLATE actors carry a mode-versioned source params row.
type Participant struct {
	Origin         d.Origin
	Kind           d.ActorKind
	Player         identity.PlayerID
	Identity       int64
	TemplateParams map[string]any
	// Transform is the actor's parameter object for the battle's registered
	// mode transform (Arena season awards); it never enters populate params.
	Transform map[string]int64
}

type BattleRequest struct {
	CampaignType int64
	BattleID     int64
	TeamA        []Participant
	PetsA        []Participant
	WavesB       [][]Participant
	PetsB        []Participant
	// Context names the registered resolver transform of the mode (I8-2C).
	Context *d.BattleContext
	// Formation is the stock slot-ordered formation a client-summary START
	// freezes for its RESULT validator (0 = empty slot).
	Formation []int64
}

type freezer struct {
	service Service
	t       tx.Tx
	scope   ca.CoherentReadScope
	starter identity.PlayerID
	heroes  map[identity.PlayerID]map[string]any
	pets    map[identity.PlayerID][]any
	players map[identity.PlayerID]*playerInputs
}

type playerInputs struct {
	context d.PlayerContext
	conquer cq.Progress
}

func (s Service) newFreezer(t tx.Tx, scope ca.CoherentReadScope, actor identity.PlayerID) *freezer {
	return &freezer{service: s, t: t, scope: scope, starter: actor, heroes: map[identity.PlayerID]map[string]any{}, pets: map[identity.PlayerID][]any{}, players: map[identity.PlayerID]*playerInputs{}}
}

// freeze snapshots one battle; a freezer shared by several battles keeps each
// owner's inputs read once, and each snapshot lists only its own battle's players.
func (f *freezer) freeze(ctx context.Context, locator d.Locator, request BattleRequest, challenge *d.Challenge, profile d.TrustProfile) (d.Snapshot, error) {
	s, scope := f.service, f.scope
	battle := d.Battle{CampaignType: request.CampaignType, BattleID: request.BattleID, PetsA: []d.Actor{}, PetsB: []d.Actor{}, Context: request.Context, Formation: request.Formation}
	var err error
	if battle.TeamA, err = f.actors(ctx, locator, request.TeamA, d.HeroActor); err != nil {
		return d.Snapshot{}, err
	}
	if battle.PetsA, err = f.actors(ctx, locator, request.PetsA, d.PetActor); err != nil {
		return d.Snapshot{}, err
	}
	for _, wave := range request.WavesB {
		actors, err := f.actors(ctx, locator, wave, d.HeroActor)
		if err != nil {
			return d.Snapshot{}, err
		}
		battle.WavesB = append(battle.WavesB, actors)
	}
	if battle.PetsB, err = f.actors(ctx, locator, request.PetsB, d.PetActor); err != nil {
		return d.Snapshot{}, err
	}
	players := []d.PlayerContext{}
	for pid, p := range f.players {
		if battlePlayer(request, pid) {
			players = append(players, p.context)
		}
	}
	sort.Slice(players, func(i, j int) bool { return players[i].Player < players[j].Player })
	snapshot := d.Snapshot{Schema: d.SnapshotSchema, Contract: d.ContractID, ContentRevision: scope.ContentRevision, CorpusID: s.Rules.ID(), SourceArchiveSHA256: s.Rules.SourceArchiveSHA256(),
		TrustProfile: profile.ID, EntropyPolicy: d.EntropyPolicyVersion, AdapterPolicy: d.AdapterPolicyVersion, CollectionPolicy: d.CollectionPolicy, DecidedAt: scope.ObservedAt.UTC(), Battle: battle, Players: players,
		Challenge: challenge}
	if challenge == nil {
		snapshot.ProducerProfile = d.ProducerProfileID
	}
	return snapshot, snapshot.Validate()
}

func battlePlayer(request BattleRequest, pid identity.PlayerID) bool {
	for _, group := range append([][]Participant{request.TeamA, request.PetsA, request.PetsB}, request.WavesB...) {
		for _, p := range group {
			if p.Origin != d.Template && p.Player == pid {
				return true
			}
		}
	}
	return false
}

func (f *freezer) actors(ctx context.Context, locator d.Locator, participants []Participant, kind d.ActorKind) ([]d.Actor, error) {
	out := []d.Actor{}
	for _, p := range participants {
		if p.Kind != kind {
			return nil, d.ErrInvalid
		}
		a, err := f.actor(ctx, locator, p)
		if err != nil {
			return nil, err
		}
		out = append(out, a)
	}
	return out, nil
}

func (f *freezer) actor(ctx context.Context, locator d.Locator, p Participant) (d.Actor, error) {
	if p.Origin == d.Template {
		return f.template(p)
	}
	ownedSelf := p.Origin == d.OwnedSelf && p.Player == f.starter
	ownedForeign := p.Origin == d.OwnedForeign && p.Player != f.starter
	borrowed := p.Origin == d.Borrowed && p.Player != f.starter
	if !p.Player.Valid() || p.Identity <= 0 || p.TemplateParams != nil || !(ownedSelf || ownedForeign || borrowed) {
		return d.Actor{}, d.ErrInvalid
	}
	var provenance *d.Provenance
	if borrowed {
		loan, err := f.lend(ctx, locator, p)
		if err != nil {
			return d.Actor{}, err
		}
		provenance = &loan
	}
	if err := f.player(ctx, p.Player); err != nil {
		return d.Actor{}, err
	}
	// D3 owner-scoped policy: every owned actor is evaluated in its owner's own view.
	view := publicstats.View{Kind: publicstats.Self, Viewer: p.Player}
	var params map[string]any
	var result publicstats.Result
	var err error
	if p.Kind == d.HeroActor {
		if result, err = f.service.Inputs.Stats.HeroTx(ctx, f.scope, character.HeroRef{PlayerID: p.Player, PartnerID: p.Identity}, view); err != nil {
			return d.Actor{}, fmt.Errorf("%w: hero stats: %v", d.ErrProviderUnavailable, err)
		}
		params, err = f.heroParams(ctx, p, result.OwnerStateVersion)
	} else {
		if result, err = f.service.Inputs.Stats.PetTx(ctx, f.scope, character.PetRef{PlayerID: p.Player, PetID: p.Identity}, view); err != nil {
			return d.Actor{}, fmt.Errorf("%w: pet stats: %v", d.ErrProviderUnavailable, err)
		}
		params, err = f.petParams(ctx, p)
	}
	if err != nil {
		return d.Actor{}, err
	}
	totals, err := d.CanonicalJSON(map[string]any{"profile": result.Profile, "model": result.Stats.Model, "total": result.Stats.Total, "force": result.Stats.Force})
	if err != nil {
		return d.Actor{}, err
	}
	a, err := f.build(p, params)
	if err != nil {
		return d.Actor{}, err
	}
	if err = d.CurrentProducerProfile().CheckOwned(a.Kind, a.Params); err != nil {
		return d.Actor{}, fmt.Errorf("%w: %v", d.ErrProviderUnavailable, err)
	}
	a.OwnerStateVersion, a.BattleTotals, a.Provenance = result.OwnerStateVersion, totals, provenance
	return a, nil
}

// lend asks the lending capability before any lender read, so a refused loan
// (H-40) touches no owner state.
func (f *freezer) lend(ctx context.Context, locator d.Locator, p Participant) (d.Provenance, error) {
	if f.service.Inputs.Lending == nil {
		return d.Provenance{}, fmt.Errorf("%w: no lending capability", d.ErrProviderUnavailable)
	}
	provenance, err := f.service.Inputs.Lending.LendTx(ctx, f.t, f.scope, Loan{Borrower: f.starter, Lender: p.Player, Kind: p.Kind, Identity: p.Identity, Locator: locator})
	if err != nil {
		return d.Provenance{}, err
	}
	if !provenance.Valid() {
		return d.Provenance{}, fmt.Errorf("%w: lending provenance", d.ErrProviderUnavailable)
	}
	return provenance, nil
}

func (f *freezer) template(p Participant) (d.Actor, error) {
	if p.Player != 0 || p.TemplateParams == nil {
		return d.Actor{}, d.ErrInvalid
	}
	if v, ok := p.TemplateParams["player_id"]; ok && fmt.Sprint(v) != "0" {
		return d.Actor{}, d.ErrInvalid
	}
	return f.build(p, p.TemplateParams)
}

func (f *freezer) build(p Participant, params map[string]any) (d.Actor, error) {
	raw, err := d.CanonicalJSON(params)
	if err != nil {
		return d.Actor{}, d.ErrInvalid
	}
	var transform json.RawMessage
	if len(p.Transform) > 0 {
		if transform, err = d.CanonicalJSON(p.Transform); err != nil {
			return d.Actor{}, d.ErrInvalid
		}
	}
	var shape struct {
		TableID   json.Number `json:"table_id"`
		PartnerID json.Number `json:"partner_id"`
		PetID     json.Number `json:"pet_id"`
	}
	if err = json.Unmarshal(raw, &shape); err != nil {
		return d.Actor{}, d.ErrInvalid
	}
	identity := shape.PartnerID
	if p.Kind == d.PetActor {
		identity = shape.PetID
	}
	tableID, err := shape.TableID.Int64()
	if err != nil || tableID <= 0 || identity.String() != strconv.FormatInt(p.Identity, 10) {
		return d.Actor{}, d.ErrInvalid
	}
	tables := []string{"partner", "super_partner", "activity_partner"}
	if p.Kind == d.PetActor {
		tables = []string{"pet"}
	}
	for _, table := range tables {
		class, present, known := f.service.Rules.FighterClass(table, tableID)
		if !known {
			continue
		}
		if !present {
			return d.Actor{}, fmt.Errorf("%w: %s %d class %q", d.ErrClassUnavailable, table, tableID, class)
		}
		return d.Actor{Origin: p.Origin, Kind: p.Kind, Player: int64(p.Player), Identity: p.Identity, TableID: tableID, FighterClass: class, Params: raw, Transform: transform}, nil
	}
	return d.Actor{}, fmt.Errorf("%w: no source row for table_id %d", d.ErrClassUnavailable, tableID)
}

func (f *freezer) heroParams(ctx context.Context, p Participant, stateVersion int64) (map[string]any, error) {
	rows, ok := f.heroes[p.Player]
	if !ok {
		detail := map[string]any{}
		if err := f.service.Inputs.Heroes.OverlayMID1(ctx, f.scope.Queryer(), identity.ActorContext{PlayerID: p.Player}, false, f.scope.ObservedAt, detail); err != nil {
			return nil, fmt.Errorf("%w: hero roster: %v", d.ErrProviderUnavailable, err)
		}
		body, _ := detail["49"].(map[string]any)
		rows, _ = body["heros"].(map[string]any)
		if rows == nil {
			return nil, fmt.Errorf("%w: hero roster inactive", d.ErrProviderUnavailable)
		}
		f.heroes[p.Player] = rows
	}
	row, ok := rows[strconv.FormatInt(p.Identity, 10)].(map[string]any)
	if !ok {
		return nil, fmt.Errorf("%w: hero %d not in roster", d.ErrProviderUnavailable, p.Identity)
	}
	// No roster overlay emits twice_awake_stage; its canonical owner is the
	// Character raw awakening observation (COMPLETE is stage 3).
	ref := character.HeroRef{PlayerID: p.Player, PartnerID: p.Identity}
	awakening, err := f.service.Inputs.Awakening.RawAwakeningTx(ctx, f.scope, ref)
	if err != nil {
		return nil, fmt.Errorf("%w: raw awakening: %v", d.ErrProviderUnavailable, err)
	}
	if !awakening.Known || awakening.Ref != ref || awakening.StateVersion != stateVersion || awakening.ContentRevision != f.scope.ContentRevision || !awakening.ObservedAt.Equal(f.scope.ObservedAt) || awakening.RawStage < 0 || awakening.RawStage > 3 {
		return nil, fmt.Errorf("%w: raw awakening unqualified", d.ErrProviderUnavailable)
	}
	params := map[string]any{"player_id": int64(p.Player)}
	for k, v := range row {
		params[k] = v
	}
	params["twice_awake_stage"] = awakening.RawStage
	// NormalHero.toParams emits conquer keys only when positive.
	progress := f.players[p.Player].conquer
	if progress.Level > 0 {
		params["conquer_lev"] = progress.Level
	}
	if progress.Loop > 0 {
		params["conquer_loop_id"] = progress.Loop
	}
	return params, nil
}

func (f *freezer) petParams(ctx context.Context, p Participant) (map[string]any, error) {
	rows, ok := f.pets[p.Player]
	if !ok {
		detail := map[string]any{}
		if err := f.service.Inputs.Pets.OverlayMID1(ctx, f.scope.Queryer(), identity.ActorContext{PlayerID: p.Player}, false, f.scope.ObservedAt, detail); err != nil {
			return nil, fmt.Errorf("%w: pet roster: %v", d.ErrProviderUnavailable, err)
		}
		body, _ := detail["780"].(map[string]any)
		rows, _ = body["pets"].([]any)
		if rows == nil {
			return nil, fmt.Errorf("%w: pet roster inactive", d.ErrProviderUnavailable)
		}
		f.pets[p.Player] = rows
	}
	for _, raw := range rows {
		row, ok := raw.(map[string]any)
		if ok && fmt.Sprint(row["pet_id"]) == strconv.FormatInt(p.Identity, 10) && fmt.Sprint(row["player_id"]) == strconv.FormatInt(int64(p.Player), 10) {
			return row, nil
		}
	}
	return nil, fmt.Errorf("%w: pet %d not in roster", d.ErrProviderUnavailable, p.Identity)
}

// player freezes the per-player server-branch inputs once per participant owner.
func (f *freezer) player(ctx context.Context, player identity.PlayerID) error {
	if _, ok := f.players[player]; ok {
		return nil
	}
	scope, q := f.scope, f.scope.Queryer()
	unavailable := func(what string, err error) error {
		return fmt.Errorf("%w: %s for player %d: %v", d.ErrProviderUnavailable, what, player, err)
	}
	collection, err := f.service.Inputs.Collection.PlayerCollectionInputsTx(ctx, q, lib.InputScope{Player: player, ContentRevision: scope.ContentRevision, ObservedAt: scope.ObservedAt})
	if err != nil {
		return unavailable("collection", err)
	}
	if collection.Player != player || collection.ContentRevision != scope.ContentRevision || !collection.ObservedAt.Equal(scope.ObservedAt) || collection.LibraryRootVersion < 1 || collection.PopulationVersion < 1 {
		return unavailable("collection", d.ErrStale)
	}
	album := map[string]int64{}
	for attr, value := range collection.Contributions {
		if attr < 1 || attr > 49 {
			return unavailable("collection", d.ErrInvalid)
		}
		album[strconv.FormatInt(attr, 10)] = value
	}
	observation, err := f.service.Inputs.Conquer.FactsTx(ctx, scope, player)
	if err != nil {
		return unavailable("conquer", err)
	}
	if observation.Facts.Player != player || observation.ContentRevision != scope.ContentRevision || !observation.ObservedAt.Equal(scope.ObservedAt) || !observation.Facts.Known() {
		return unavailable("conquer", d.ErrStale)
	}
	stacks, err := f.service.Inputs.Stacks.ListStacksTx(ctx, q, player)
	if err != nil {
		return unavailable("stacks", err)
	}
	books := map[string]int64{}
	for _, stack := range stacks {
		if stack.Validate() != nil || stack.PlayerID != player || scope.ObservedAt.Before(stack.UpdatedAt) {
			return unavailable("stacks", d.ErrStale)
		}
		if stack.ItemID >= d.ExclusiveBookFirst && stack.ItemID <= d.ExclusiveBookLast && stack.Quantity > 0 {
			books[strconv.FormatInt(stack.ItemID, 10)] = stack.Quantity
		}
	}
	f.players[player] = &playerInputs{
		context: d.PlayerContext{Player: int64(player), CollectionHundredths: album, ExclusiveBooks: books,
			StateVersions: map[string]int64{"library_root": collection.LibraryRootVersion, "hero_population": collection.PopulationVersion, "conquer": observation.Facts.Version}},
		conquer: *observation.Facts.Payload.Progress,
	}
	return nil
}
