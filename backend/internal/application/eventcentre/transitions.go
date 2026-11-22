package eventcentre

import (
	"context"
	"encoding/binary"
	gen "gxb.local/backend/v2/internal/application/generation"
	"math/big"
	"reflect"
	"sort"
	"strconv"
	"time"

	appbook "gxb.local/backend/v2/internal/application/bookskill"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/economy"
	ec "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Service) apply(ctx context.Context, sc tx.Scope, a identity.ActorContext, d Admission) (map[string]any, error) {
	t := sc.Tx
	at := d.DecisionAt
	root, exists, err := s.Owner.LockRootTx(ctx, t, a.PlayerID)
	if err != nil {
		return nil, err
	}
	if !exists {
		if err = s.Owner.EnsureRootTx(ctx, t, a.PlayerID, d.ContentRevision, at); err != nil {
			return nil, err
		}
		root, exists, err = s.Owner.LockRootTx(ctx, t, a.PlayerID)
		if err != nil {
			return nil, err
		}
		if !exists {
			return nil, ErrUnavailable
		}
	}
	catalog, err := s.Content.WorkshopInputsTx(ctx, t, d.ContentRevision)
	if err != nil {
		return nil, err
	}
	inputs, err := s.Book.BookInputsTx(ctx, t, appbook.InputScope{Player: a.PlayerID, ContentRevision: d.ContentRevision, ObservedAt: at})
	if err != nil {
		return nil, err
	}
	state := root.Facts.Clone()
	if err = state.SettleMakes(at); err != nil {
		return nil, err
	}
	valueop := d.Operation
	valueop.StartedAt = at
	var body map[string]any
	switch d.Command.Family {
	case Recycle:
		body, err = s.applyRecycle(ctx, t, a, d, catalog, inputs, &state, valueop)
	case Make:
		body, err = s.applyMake(ctx, t, a, d, catalog, inputs, &state, valueop)
	case CancelMake:
		body, err = s.applyCancelMake(ctx, t, a, d, &state, valueop)
	case ConfirmMake:
		body, err = s.applyConfirmMake(ctx, t, a, d, &state, valueop)
	case AccelerateMake:
		body, err = s.applyAccelerateMake(ctx, t, a, d, catalog, &state, valueop)
	case AdminExchange:
		body, err = s.applyAdminExchange(ctx, t, a, d, catalog, inputs, &state, valueop)
	case BoardReceive, BoardGiveUp, BoardConfirm:
		body, err = s.applyBoard(ctx, sc, a, d, catalog, inputs, &state, valueop)
	default:
		return nil, ErrUnqualified
	}
	if err != nil {
		return nil, err
	}
	if err = state.Validate(); err != nil {
		return nil, err
	}
	if !reflect.DeepEqual(root.Facts, state) {
		previous := root.Version
		root.Version++
		root.Facts = state
		root.UpdatedAt = gen.EffectiveObservation(at, root.UpdatedAt, root.CreatedAt)
		if err = s.Owner.SaveRootTx(ctx, t, root, previous); err != nil {
			return nil, err
		}
	}
	return body, nil
}

func (s Service) applyRecycle(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, catalog Catalog, inputs appbook.Inputs, state *State, valueop operation.Context) (map[string]any, error) {
	level := buildingLevel(inputs, RecycleBuilding)
	limit, err := catalog.EnergyLimit(level)
	if err != nil {
		return nil, err
	}
	if err = ec.SettleRecycle(&state.Recycle, limit, catalog.Misc.SaturationSeconds, d.DecisionAt); err != nil {
		return nil, err
	}
	energyCost, err := catalog.RecycleEnergyCost(level, d.Command.ItemID, d.Command.ItemNum)
	if err != nil {
		return nil, err
	}
	if state.Recycle.Energy < energyCost {
		return nil, economy.ErrInsufficientBalance
	}
	awards, err := catalog.RecycleAwards(d.Command.ItemID, d.Command.ItemNum)
	if err != nil {
		return nil, err
	}
	chance, err := catalog.RecycleCritChance(level)
	if err != nil {
		return nil, err
	}
	awards, types, numbers, crits, err := applyCrit(d.Operation, catalog.Misc.CritMultiplier, chance, awards)
	if err != nil {
		return nil, err
	}
	if err = s.debit(ctx, t, a, []ResourceAmount{{ID: d.Command.ItemID, Amount: d.Command.ItemNum}}, valueop); err != nil {
		return nil, err
	}
	if err = s.grant(ctx, t, a, d, "recycle", awards, valueop); err != nil {
		return nil, err
	}
	state.Recycle.Energy -= energyCost
	return map[string]any{
		"energy":        state.Recycle.Energy,
		"energy_time":   state.Recycle.EnergyAt.Unix(),
		"resolve_types": types,
		"resolve_nums":  numbers,
		"resolve_crits": crits,
	}, nil
}

func (s Service) applyMake(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, catalog Catalog, inputs appbook.Inputs, state *State, valueop operation.Context) (map[string]any, error) {
	buildingType := d.Command.BuildingType
	building := inputs.Applied.Buildings[buildingType]
	level := buildingLevel(inputs, buildingType)
	if level < 1 || building.Job != nil {
		return nil, ErrInvalid
	}
	section := &state.Desk
	if buildingType == PetRoomBuilding {
		section = &state.Pet
	}
	if section.Job != nil || section.PendingItem != 0 {
		return nil, ErrInvalid
	}
	petColor, petTableID, petID := int64(1), int64(0), int64(0)
	if buildingType == PetRoomBuilding {
		pet, found, err := s.Pets.FindPetByIDTx(ctx, t, a.PlayerID, d.Command.PetID)
		if err != nil {
			return nil, err
		}
		if !found || !pet.PlayerID.Valid() || pet.Color < 1 {
			return nil, ErrInvalid
		}
		petColor, petTableID, petID = pet.Color, pet.TableID, pet.PetID
		section.PetID = petID
	}
	if !catalog.Craftable(buildingType, level, d.Command.ItemID, petTableID) {
		return nil, ErrInvalid
	}
	duration, err := catalog.MakeDuration(buildingType, level, d.Command.ItemID, petColor)
	if err != nil {
		return nil, err
	}
	cost, err := catalog.MakeCost(d.Command.ItemID)
	if err != nil {
		return nil, err
	}
	if err = s.debit(ctx, t, a, cost, valueop); err != nil {
		return nil, err
	}
	section.Job = &MakeJob{Occurrence: d.Operation.ID.String(), ItemID: d.Command.ItemID, PetID: petID, StartedAt: d.DecisionAt, Duration: duration, Cost: cost}
	return MakeWire(buildingType, *section, d.DecisionAt)
}

func (s Service) applyCancelMake(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, state *State, valueop operation.Context) (map[string]any, error) {
	buildingType, section, err := makeSection(state, d.Command.BuildingType)
	if err != nil {
		return nil, err
	}
	if section.Job == nil {
		return nil, ErrInvalid
	}
	left, err := ec.Remaining(section.Job, d.DecisionAt)
	if err != nil {
		return nil, err
	}
	if left <= 0 {
		return nil, ErrInvalid
	}
	refund, err := ec.Refund(section.Job, left)
	if err != nil {
		return nil, err
	}
	if err = s.grant(ctx, t, a, d, "make-refund", refund, valueop); err != nil {
		return nil, err
	}
	section.Job = nil
	body, err := MakeWire(buildingType, *section, d.DecisionAt)
	if err != nil {
		return nil, err
	}
	types, numbers := amountVectors(refund)
	body["make_res_type"], body["make_res_num"] = types, numbers
	return body, nil
}

func (s Service) applyConfirmMake(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, state *State, valueop operation.Context) (map[string]any, error) {
	_, section, err := makeSection(state, d.Command.BuildingType)
	if err != nil {
		return nil, err
	}
	if section.Job != nil || section.PendingItem <= 0 {
		return nil, ErrInvalid
	}
	itemID := section.PendingItem
	if err = s.grant(ctx, t, a, d, "make-confirm", []ResourceAmount{{ID: itemID, Amount: 1}}, valueop); err != nil {
		return nil, err
	}
	section.PendingItem = 0
	return map[string]any{"items": []map[string]any{{"table_id": itemID, "item_num": int64(1)}}}, nil
}

func (s Service) applyAccelerateMake(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, catalog Catalog, state *State, valueop operation.Context) (map[string]any, error) {
	buildingType, section, err := makeSection(state, d.Command.BuildingType)
	if err != nil {
		return nil, err
	}
	if section.Job == nil {
		return nil, ErrInvalid
	}
	left, err := ec.Remaining(section.Job, d.DecisionAt)
	if err != nil {
		return nil, err
	}
	if left <= 0 {
		return nil, ErrInvalid
	}
	seconds := catalog.Misc.AccelerateSeconds
	maxSpeed := (left + seconds - 1) / seconds
	if d.Command.SpeedNum <= 0 || d.Command.SpeedNum > maxSpeed {
		return nil, ErrInvalid
	}
	if err = s.debit(ctx, t, a, []ResourceAmount{{ID: catalog.Misc.AccelerateItemID, Amount: d.Command.SpeedNum}}, valueop); err != nil {
		return nil, err
	}
	gained := d.Command.SpeedNum * seconds
	shifted := section.Job.StartedAt.Add(time.Duration(gained) * time.Second)
	if shifted.After(d.DecisionAt) {
		shifted = d.DecisionAt.Add(-time.Duration(section.Job.Duration) * time.Second)
	}
	section.Job.StartedAt = shifted
	if err = state.SettleMakes(d.DecisionAt); err != nil {
		return nil, err
	}
	return MakeWire(buildingType, *section, d.DecisionAt)
}

func (s Service) applyAdminExchange(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, catalog Catalog, inputs appbook.Inputs, state *State, valueop operation.Context) (map[string]any, error) {
	building := inputs.Applied.Buildings[AdminBuilding]
	level := buildingLevel(inputs, AdminBuilding)
	if level < 1 || building.Job != nil {
		return nil, ErrInvalid
	}
	day := modesDay(d.DecisionAt)
	if state.AdminDay != day {
		state.Admin = map[string]int64{}
		state.AdminDay = day
	}
	if !catalog.AdminAllowedSource(level, d.Command.FromType) {
		return nil, ErrInvalid
	}
	key := AdminKey(d.Command.FromType, d.Command.ToType)
	count := state.Admin[key]
	if count >= MaxAdminPerPair {
		return nil, ErrInvalid
	}
	rule, ok := catalog.AdminRule(d.Command.ToType, count+1)
	if !ok {
		return nil, ErrUnqualified
	}
	cost := rule.Costs[d.Command.FromType]
	if cost <= 0 {
		return nil, ErrInvalid
	}
	if err := s.debit(ctx, t, a, []ResourceAmount{{ID: d.Command.FromType, Amount: cost}}, valueop); err != nil {
		return nil, err
	}
	if err := s.grant(ctx, t, a, d, "admin-credit", []ResourceAmount{{ID: d.Command.ToType, Amount: rule.Credit}}, valueop); err != nil {
		return nil, err
	}
	state.Admin[key] = count + 1
	return map[string]any{}, nil
}

func makeSection(state *State, buildingType int64) (int64, *MakeState, error) {
	switch buildingType {
	case DeskBuilding:
		return DeskBuilding, &state.Desk, nil
	case PetRoomBuilding:
		return PetRoomBuilding, &state.Pet, nil
	default:
		return 0, nil, ErrInvalid
	}
}

func (s Service) debit(ctx context.Context, t tx.Tx, a identity.ActorContext, lines []ResourceAmount, valueop operation.Context) error {
	material := materialCost(lines)
	if len(material.Scalars)+len(material.Stacks) == 0 {
		return nil
	}
	prepared, err := s.Costs.PrepareMaterialDebitTx(ctx, t, a.PlayerID, material, valueop)
	if err != nil {
		return err
	}
	_, err = s.Costs.ApplyMaterialDebitTx(ctx, t, prepared)
	return err
}

func (s Service) grant(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, operationTag string, lines []ResourceAmount, valueop operation.Context) error {
	if len(lines) == 0 {
		return nil
	}
	plan := grant.Plan{
		PlayerID: a.PlayerID,
		Source:   grant.SourceIdentity{Domain: "event-centre", Operation: operationTag, BusinessKey: strconv.FormatInt(int64(a.PlayerID), 10), Occurrence: d.Operation.ID.String(), PolicyVersion: PolicyVersion},
		Lines:    grantLines(lines),
	}
	_, err := s.Grants.SettleGrantTx(ctx, t, a, plan, valueop, i5.GrantTxOptions{AllowOverflowMail: true})
	return err
}

func materialCost(lines []ResourceAmount) i5.MaterialCost {
	material := i5.MaterialCost{}
	for _, line := range lines {
		if line.Amount <= 0 {
			continue
		}
		if key, scalar := ec.ScalarResourceKey(line.ID); scalar {
			material.Scalars = append(material.Scalars, i5.ScalarMaterialCost{ResourceKey: key, Amount: line.Amount})
		} else {
			material.Stacks = append(material.Stacks, i5.StackMaterialCost{ItemID: line.ID, Amount: line.Amount})
		}
	}
	sort.Slice(material.Scalars, func(i, j int) bool { return material.Scalars[i].ResourceKey < material.Scalars[j].ResourceKey })
	sort.Slice(material.Stacks, func(i, j int) bool { return material.Stacks[i].ItemID < material.Stacks[j].ItemID })
	return material
}

func grantLines(lines []ResourceAmount) []grant.Line {
	out := make([]grant.Line, 0, len(lines))
	for _, line := range lines {
		if line.Amount <= 0 {
			continue
		}
		if key, scalar := ec.ScalarResourceKey(line.ID); scalar {
			out = append(out, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: key, Amount: line.Amount})
		} else {
			out = append(out, grant.Line{Kind: grant.StackItem, ItemID: line.ID, Amount: line.Amount})
		}
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].Kind != out[j].Kind {
			return out[i].Kind < out[j].Kind
		}
		if out[i].ResourceKey != out[j].ResourceKey {
			return out[i].ResourceKey < out[j].ResourceKey
		}
		return out[i].ItemID < out[j].ItemID
	})
	return out
}

func amountVectors(lines []ResourceAmount) ([]int64, []int64) {
	types := make([]int64, 0, len(lines))
	numbers := make([]int64, 0, len(lines))
	for _, line := range lines {
		types = append(types, line.ID)
		numbers = append(numbers, line.Amount)
	}
	return types, numbers
}

func applyCrit(op operation.Context, multiplier int64, chance *big.Rat, lines []ResourceAmount) ([]ResourceAmount, []int64, []int64, []int64, error) {
	awards := make([]ResourceAmount, 0, len(lines))
	types := make([]int64, 0, len(lines))
	numbers := make([]int64, 0, len(lines))
	crits := make([]int64, 0, len(lines))
	for index, line := range lines {
		amount := line.Amount
		crit := int64(1)
		if rollCrit(chance, op.Derive("i9-10a-recycle-crit", uint64(index))) {
			if amount > (1<<63-1)/multiplier {
				return nil, nil, nil, nil, ErrUnqualified
			}
			amount *= multiplier
			crit = multiplier
		}
		awards = append(awards, ResourceAmount{ID: line.ID, Amount: amount})
		types = append(types, line.ID)
		numbers = append(numbers, amount)
		crits = append(crits, crit)
	}
	return awards, types, numbers, crits, nil
}

func rollCrit(chance *big.Rat, entropy [32]byte) bool {
	if chance == nil || chance.Sign() <= 0 {
		return false
	}
	one := big.NewRat(1, 1)
	if chance.Cmp(one) >= 0 {
		return true
	}
	threshold := new(big.Int).Mul(chance.Num(), new(big.Int).Lsh(big.NewInt(1), 64))
	threshold.Quo(threshold, chance.Denom())
	value := new(big.Int).SetUint64(binary.BigEndian.Uint64(entropy[:8]))
	return value.Cmp(threshold) < 0
}
