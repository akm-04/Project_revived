package eventcentre

import (
	"encoding/json"
	"errors"
	"math/big"
	"sort"
	"strconv"
	"time"

	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
)

var (
	ErrInvalid     = errors.New("event centre: invalid transition")
	ErrUnqualified = errors.New("event centre: unqualified facts")
	ErrStaleTime   = errors.New("event centre: stale observation time")
)

const (
	PolicyVersion   = "I9_10A_EVENT_CENTRE_V1"
	ResultSchema    = "gxb.eventcentre.command.v1"
	OperationClass  = "I9_10A_EVENT_CENTRE"
	MaxAdminPerPair = 60
	DeskBuilding    = int64(2)
	RecycleBuilding = int64(3)
	AdminBuilding   = int64(5)
	PetRoomBuilding = int64(7)
)

// PRIVATE_POLICY I9-10A: unrecovered original-server laws adopted as named values.
const (
	RecycleInitialEnergyPolicy = "ZERO_AT_FIRST_MATERIALIZATION"
	RecycleCritPolicy          = "CRIT_PARAM_PLUS_BUILDING_CRIT_UP_ONE_ROLL_PER_RESOLVED_RESOURCE"
	MakeCancelRefundPolicy     = "PRORATED_FLOOR_PER_COST_LINE"
	MakeConfirmOutputPolicy    = "ONE_MADE_ITEM_PER_CONFIRM"
	AdminResetPolicy           = "COUNTER_RESET_AT_GAME_DAY_0500_GMT8"
	AdminCounterPolicy         = "SIXTY_CONVERSIONS_PER_ORDERED_SOURCE_DESTINATION_PAIR"
)

var (
	scalarResourceKeys = map[int64]string{1: "mana", 2: "crystal", 11: "magic_dust", 12: "magic_liquid", 13: "magic_energy", 14: "magic_exp"}
	adminSources       = []int64{1, 2, 11, 12, 13}
	adminDestinations  = []int64{11, 12, 13}
)

func ScalarResourceKey(identifier int64) (string, bool) {
	key, ok := scalarResourceKeys[identifier]
	return key, ok
}

type ResourceAmount struct {
	ID, Amount int64
}

type Recipe struct {
	ItemID        int64
	Make, Resolve []ResourceAmount
	MakeTime      int64
	ResolveEnergy int64
}

type DeskRule struct {
	Level       int64
	CutMaketime int64
	Craftable   []int64
}

type RecycleRule struct {
	Level         int64
	EnergyLimit   int64
	CutCostEnergy *big.Rat
	CritUp        *big.Rat
	Recount       []int64
}

type AdminRule struct {
	Destination, Ordinal, Credit int64
	Costs                        map[int64]int64
}

type Misc struct {
	CritParam                 *big.Rat
	CritMultiplier            int64
	SaturationInit            int64
	SaturationSeconds         int64
	AccelerateItemID          int64
	AccelerateSeconds         int64
	PetColorAccelerateSeconds int64
	PetCostItemIDs            []int64
}

type Catalog struct {
	Desk         map[int64]DeskRule
	Recycle      map[int64]RecycleRule
	Admin        map[[2]int64]AdminRule
	AdminLevels  map[int64][]int64
	Recipes      map[int64]Recipe
	PetCrafting  map[int64][][]int64
	Misc         Misc
	Board        map[int64]BoardRule
	Missions     map[int64]MissionRule
	HeroProfiles map[int64]HeroProfileRule
	Awards       map[int64]AwardRule
}

func ParseDecimal(value string) (*big.Rat, error) {
	rat, ok := new(big.Rat).SetString(value)
	if !ok || rat.Sign() < 0 {
		return nil, ErrUnqualified
	}
	return rat, nil
}

func (c Catalog) Validate() error {
	if len(c.Desk) != 8 || len(c.Recycle) != 6 || len(c.Admin) != 180 || len(c.AdminLevels) != 5 || len(c.Recipes) == 0 || len(c.PetCrafting) != 54 {
		return ErrUnqualified
	}
	if len(c.Board) != 5 || len(c.Missions) != 273 || len(c.HeroProfiles) != 91 || len(c.Awards) != 29 {
		return ErrUnqualified
	}
	if err := c.validateBoard(); err != nil {
		return err
	}
	if c.Misc.CritParam == nil || c.Misc.CritParam.Sign() < 0 || c.Misc.CritMultiplier < 1 || c.Misc.SaturationInit <= 0 || c.Misc.SaturationSeconds <= 0 || c.Misc.AccelerateItemID <= 0 || c.Misc.AccelerateSeconds <= 0 || c.Misc.PetColorAccelerateSeconds < 0 || len(c.Misc.PetCostItemIDs) != 2 {
		return ErrUnqualified
	}
	if err := c.validateDesk(); err != nil {
		return err
	}
	if err := c.validateRecycle(); err != nil {
		return err
	}
	if err := c.validateAdmin(); err != nil {
		return err
	}
	return c.validateRecipes()
}

func (c Catalog) validateDesk() error {
	for level := int64(1); level <= 8; level++ {
		rule, ok := c.Desk[level]
		if !ok || rule.Level != level || rule.CutMaketime < 0 || len(rule.Craftable) == 0 {
			return ErrUnqualified
		}
		for _, itemID := range rule.Craftable {
			recipe, exists := c.Recipes[itemID]
			if !exists || len(recipe.Make) == 0 || recipe.MakeTime <= 0 {
				return ErrUnqualified
			}
		}
	}
	return nil
}

func (c Catalog) validateRecycle() error {
	for level := int64(1); level <= 6; level++ {
		rule, ok := c.Recycle[level]
		if !ok || rule.Level != level || rule.EnergyLimit < 0 || rule.CutCostEnergy == nil || rule.CostRate().Cmp(new(big.Rat).SetInt64(1)) > 0 || rule.CritUp == nil || rule.CritUp.Sign() < 0 || len(rule.Recount) == 0 {
			return ErrUnqualified
		}
		for _, itemID := range rule.Recount {
			recipe, exists := c.Recipes[itemID]
			if !exists || len(recipe.Resolve) == 0 || recipe.ResolveEnergy <= 0 {
				return ErrUnqualified
			}
		}
	}
	return nil
}

func (c Catalog) validateAdmin() error {
	destinations := map[int64]bool{}
	for _, destination := range adminDestinations {
		destinations[destination] = true
	}
	for _, destination := range adminDestinations {
		for ordinal := int64(1); ordinal <= MaxAdminPerPair; ordinal++ {
			rule, ok := c.Admin[[2]int64{destination, ordinal}]
			if !ok || rule.Destination != destination || rule.Ordinal != ordinal || rule.Credit <= 0 || len(rule.Costs) != 4 {
				return ErrUnqualified
			}
			for source, amount := range rule.Costs {
				if source == destination || !validAdminSource(source) || amount <= 0 {
					return ErrUnqualified
				}
			}
		}
	}
	for level := int64(1); level <= 5; level++ {
		unlock, ok := c.AdminLevels[level]
		if !ok || len(unlock) == 0 {
			return ErrUnqualified
		}
		seen := map[int64]bool{}
		for _, source := range unlock {
			if !validAdminSource(source) || seen[source] {
				return ErrUnqualified
			}
			seen[source] = true
		}
		if len(seen) != len(unlock) {
			return ErrUnqualified
		}
	}
	if len(c.AdminLevels[5]) != len(adminSources) {
		return ErrUnqualified
	}
	return nil
}

func (c Catalog) validateRecipes() error {
	for itemID, recipe := range c.Recipes {
		if itemID <= 0 || recipe.ItemID != itemID || recipe.MakeTime < 0 || recipe.ResolveEnergy < 0 || (len(recipe.Make) == 0) != (recipe.MakeTime == 0) || (len(recipe.Resolve) == 0) != (recipe.ResolveEnergy == 0) {
			return ErrUnqualified
		}
		if !validAmounts(recipe.Make) || !validAmounts(recipe.Resolve) {
			return ErrUnqualified
		}
	}
	for tableID, levels := range c.PetCrafting {
		if tableID <= 0 || len(levels) != 5 {
			return ErrUnqualified
		}
		for _, level := range levels {
			if len(level) == 0 {
				return ErrUnqualified
			}
			for _, itemID := range level {
				recipe, ok := c.Recipes[itemID]
				if !ok || len(recipe.Make) == 0 || recipe.MakeTime <= 0 {
					return ErrUnqualified
				}
			}
		}
	}
	return nil
}

func validAmounts(lines []ResourceAmount) bool {
	seen := map[int64]bool{}
	for _, line := range lines {
		if line.ID <= 0 || line.Amount <= 0 || seen[line.ID] {
			return false
		}
		seen[line.ID] = true
	}
	return true
}

func validAdminSource(source int64) bool {
	for _, known := range adminSources {
		if source == known {
			return true
		}
	}
	return false
}

func (r RecycleRule) CostRate() *big.Rat {
	if r.CutCostEnergy == nil {
		return new(big.Rat)
	}
	return r.CutCostEnergy
}

func (c Catalog) EnergyLimit(level int64) (int64, error) {
	rule, ok := c.Recycle[level]
	if !ok {
		return 0, ErrUnqualified
	}
	return c.Misc.SaturationInit + rule.EnergyLimit, nil
}

func (c Catalog) RecycleAllowed(level, itemID int64) bool {
	for current := int64(1); current <= level; current++ {
		rule, ok := c.Recycle[current]
		if !ok {
			return false
		}
		for _, candidate := range rule.Recount {
			if candidate == itemID {
				return true
			}
		}
	}
	return false
}

func ceilRational(value *big.Rat) (int64, error) {
	if value.Sign() <= 0 {
		return 0, nil
	}
	floor := new(big.Int).Quo(value.Num(), value.Denom())
	if new(big.Int).Mul(floor, value.Denom()).Cmp(value.Num()) != 0 {
		floor.Add(floor, big.NewInt(1))
	}
	if !floor.IsInt64() {
		return 0, ErrUnqualified
	}
	return floor.Int64(), nil
}

func checkedMultiply(left, right int64) (int64, error) {
	if left < 0 || right < 0 || (left != 0 && right > (1<<63-1)/left) {
		return 0, ErrUnqualified
	}
	return left * right, nil
}

// RecycleEnergyCost returns ceil(resolve_energy*(1-cut_cost_energy))*item_num.
func (c Catalog) RecycleEnergyCost(level, itemID, itemNum int64) (int64, error) {
	if itemNum <= 0 || !c.RecycleAllowed(level, itemID) {
		return 0, ErrInvalid
	}
	recipe, ok := c.Recipes[itemID]
	if !ok || recipe.ResolveEnergy <= 0 {
		return 0, ErrUnqualified
	}
	rate := c.Recycle[level].CostRate()
	remaining := new(big.Rat).Sub(new(big.Rat).SetInt64(1), rate)
	value := new(big.Rat).Mul(new(big.Rat).SetInt64(recipe.ResolveEnergy), remaining)
	perItem, err := ceilRational(value)
	if err != nil {
		return 0, err
	}
	return checkedMultiply(perItem, itemNum)
}

func (c Catalog) RecycleAwards(itemID, itemNum int64) ([]ResourceAmount, error) {
	recipe, ok := c.Recipes[itemID]
	if !ok || len(recipe.Resolve) == 0 || itemNum <= 0 {
		return nil, ErrInvalid
	}
	out := make([]ResourceAmount, 0, len(recipe.Resolve))
	for _, line := range recipe.Resolve {
		amount, err := checkedMultiply(line.Amount, itemNum)
		if err != nil {
			return nil, err
		}
		out = append(out, ResourceAmount{ID: line.ID, Amount: amount})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].ID < out[j].ID })
	return out, nil
}

func (c Catalog) RecycleCritChance(level int64) (*big.Rat, error) {
	rule, ok := c.Recycle[level]
	if !ok || rule.CritUp == nil {
		return nil, ErrUnqualified
	}
	return new(big.Rat).Add(c.Misc.CritParam, rule.CritUp), nil
}

func (c Catalog) MakeCost(itemID int64) ([]ResourceAmount, error) {
	recipe, ok := c.Recipes[itemID]
	if !ok || len(recipe.Make) == 0 {
		return nil, ErrInvalid
	}
	out := append([]ResourceAmount(nil), recipe.Make...)
	sort.Slice(out, func(i, j int) bool { return out[i].ID < out[j].ID })
	return out, nil
}

func (c Catalog) MakeDuration(buildingType, level, itemID, petColor int64) (int64, error) {
	recipe, ok := c.Recipes[itemID]
	if !ok || len(recipe.Make) == 0 || recipe.MakeTime <= 0 {
		return 0, ErrInvalid
	}
	var duration int64
	switch buildingType {
	case DeskBuilding:
		rule, exists := c.Desk[level]
		if !exists {
			return 0, ErrUnqualified
		}
		duration = recipe.MakeTime - rule.CutMaketime
	case PetRoomBuilding:
		if petColor < 1 {
			return 0, ErrInvalid
		}
		duration = recipe.MakeTime - (petColor-1)*c.Misc.PetColorAccelerateSeconds
	default:
		return 0, ErrInvalid
	}
	if duration < 0 {
		duration = 0
	}
	return duration, nil
}

func (c Catalog) Craftable(buildingType, level, itemID, petTableID int64) bool {
	if level < 1 {
		return false
	}
	switch buildingType {
	case DeskBuilding:
		if level > 8 {
			level = 8
		}
		for current := int64(1); current <= level; current++ {
			for _, candidate := range c.Desk[current].Craftable {
				if candidate == itemID {
					return true
				}
			}
		}
	case PetRoomBuilding:
		if level > 5 {
			level = 5
		}
		levels, ok := c.PetCrafting[petTableID]
		if !ok || int(level) > len(levels) {
			return false
		}
		for current := int64(0); current < level; current++ {
			for _, candidate := range levels[current] {
				if candidate == itemID {
					return true
				}
			}
		}
	}
	return false
}

func (c Catalog) AdminAllowedSource(level, source int64) bool {
	for _, candidate := range c.AdminLevels[level] {
		if candidate == source {
			return true
		}
	}
	return false
}

func (c Catalog) AdminRule(destination, ordinal int64) (AdminRule, bool) {
	rule, ok := c.Admin[[2]int64{destination, ordinal}]
	return rule, ok
}

type MakeJob struct {
	Occurrence string
	ItemID     int64
	PetID      int64
	StartedAt  time.Time
	Duration   int64
	Cost       []ResourceAmount
}

type MakeState struct {
	Job         *MakeJob
	PendingItem int64
	PetID       int64
}

type RecycleState struct {
	Energy   int64
	EnergyAt time.Time
}

type State struct {
	Recycle  RecycleState
	Desk     MakeState
	Pet      MakeState
	Admin    map[string]int64
	AdminDay int64
	Board    BoardState
}

func Seed() State {
	return State{Admin: map[string]int64{}, Board: BoardState{NextReportID: 1}}
}

func (s State) Clone() State {
	raw, _ := json.Marshal(s)
	var out State
	_ = json.Unmarshal(raw, &out)
	if out.Admin == nil {
		out.Admin = map[string]int64{}
	}
	if out.Board.NextReportID < 1 {
		out.Board.NextReportID = 1
	}
	return out
}

func validJob(job *MakeJob) bool {
	if job == nil {
		return true
	}
	if job.Occurrence == "" || job.ItemID <= 0 || job.PetID < 0 || job.StartedAt.IsZero() || job.Duration < 0 || len(job.Cost) == 0 {
		return false
	}
	return validAmounts(job.Cost)
}

func (s State) Validate() error {
	if s.Recycle.Energy < 0 || s.Recycle.EnergyAt.IsZero() && s.Recycle.Energy != 0 || !validJob(s.Desk.Job) || !validJob(s.Pet.Job) || s.Desk.PendingItem < 0 || s.Pet.PendingItem < 0 || s.Desk.PetID != 0 || s.Pet.PetID < 0 || s.AdminDay < 0 {
		return ErrUnqualified
	}
	if s.Desk.Job != nil && s.Desk.PendingItem != 0 || s.Pet.Job != nil && s.Pet.PendingItem != 0 || s.Desk.Job != nil && s.Desk.Job.PetID != 0 {
		return ErrUnqualified
	}
	if s.Admin == nil {
		return ErrUnqualified
	}
	if err := s.Board.Validate(); err != nil {
		return err
	}
	for key, count := range s.Admin {
		source, destination, ok := ParseAdminKey(key)
		if !ok || !validAdminSource(source) || !validAdminDestination(destination) || source == destination || count < 0 || count > MaxAdminPerPair {
			return ErrUnqualified
		}
	}
	return nil
}

func AdminSources() []int64 {
	return append([]int64(nil), adminSources...)
}

func AdminDestinations() []int64 {
	return append([]int64(nil), adminDestinations...)
}

func validAdminDestination(destination int64) bool {
	for _, candidate := range adminDestinations {
		if candidate == destination {
			return true
		}
	}
	return false
}

func AdminKey(source, destination int64) string {
	return strconv.FormatInt(source, 10) + strconv.FormatInt(destination, 10)
}

func ParseAdminKey(key string) (int64, int64, bool) {
	if len(key) < 3 {
		return 0, 0, false
	}
	destination, err := strconv.ParseInt(key[len(key)-2:], 10, 64)
	if err != nil {
		return 0, 0, false
	}
	source, err := strconv.ParseInt(key[:len(key)-2], 10, 64)
	if err != nil {
		return 0, 0, false
	}
	return source, destination, true
}

func (s *State) settleMake(section *MakeState, at time.Time) error {
	if section.Job == nil {
		return nil
	}
	left, err := Remaining(section.Job, at)
	if err != nil {
		return err
	}
	if left == 0 {
		section.PendingItem = section.Job.ItemID
		section.Job = nil
	}
	return nil
}

// SettleMakes materializes every due make job at at.
func (s *State) SettleMakes(at time.Time) error {
	if err := s.settleMake(&s.Desk, at); err != nil {
		return err
	}
	return s.settleMake(&s.Pet, at)
}

func Remaining(job *MakeJob, at time.Time) (int64, error) {
	if job == nil {
		return 0, ErrInvalid
	}
	if at.Before(job.StartedAt) {
		return 0, ErrStaleTime
	}
	elapsed := at.Unix() - job.StartedAt.Unix()
	if elapsed >= job.Duration {
		return 0, nil
	}
	return job.Duration - elapsed, nil
}

// SettleRecycle advances the energy anchor to at, capped by limit.
func SettleRecycle(recycle *RecycleState, limit, seconds int64, at time.Time) error {
	if limit < 0 || seconds <= 0 {
		return ErrUnqualified
	}
	if recycle.Energy < 0 || recycle.Energy > limit {
		recycle.Energy = limit
	}
	if recycle.EnergyAt.IsZero() {
		recycle.EnergyAt = at
		return nil
	}
	if at.Before(recycle.EnergyAt) {
		return ErrStaleTime
	}
	if recycle.Energy >= limit {
		recycle.Energy = limit
		recycle.EnergyAt = at
		return nil
	}
	intervals := (at.Unix() - recycle.EnergyAt.Unix()) / seconds
	if intervals <= 0 {
		return nil
	}
	if intervals >= limit-recycle.Energy {
		recycle.Energy = limit
		recycle.EnergyAt = at
		return nil
	}
	recycle.Energy += intervals
	recycle.EnergyAt = recycle.EnergyAt.Add(time.Duration(intervals*seconds) * time.Second)
	return nil
}

// Refund returns the floor of each cost line by left/duration.
func Refund(job *MakeJob, left int64) ([]ResourceAmount, error) {
	if job == nil || job.Duration <= 0 || left <= 0 || left > job.Duration {
		return nil, ErrInvalid
	}
	out := make([]ResourceAmount, 0, len(job.Cost))
	for _, line := range job.Cost {
		value := new(big.Int).Mul(big.NewInt(line.Amount), big.NewInt(left))
		value.Quo(value, big.NewInt(job.Duration))
		if !value.IsInt64() {
			return nil, ErrUnqualified
		}
		if value.Int64() > 0 {
			out = append(out, ResourceAmount{ID: line.ID, Amount: value.Int64()})
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].ID < out[j].ID })
	return out, nil
}

type Root struct {
	Player    identity.PlayerID
	Version   int64
	Revision  string
	Facts     State
	CreatedAt time.Time
	UpdatedAt time.Time
}

func (r Root) Validate() error {
	if !r.Player.Valid() || r.Version < 1 || !book.ValidCatalogRevision(r.Revision) || r.CreatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) {
		return ErrUnqualified
	}
	return r.Facts.Validate()
}

func BuildingInfo(building book.Building) map[string]any {
	return book.BuildingWire(building)
}

func MakeWire(buildingType int64, state MakeState, at time.Time) (map[string]any, error) {
	body := map[string]any{"is_making": int64(0), "make_item": int64(0), "making_item": int64(0), "make_need_time": int64(0), "make_start_time": int64(0)}
	if state.Job != nil {
		left, err := Remaining(state.Job, at)
		if err != nil {
			return nil, err
		}
		if left > 0 {
			body["is_making"] = int64(1)
			body["making_item"] = state.Job.ItemID
			body["make_need_time"] = state.Job.Duration
			body["make_start_time"] = state.Job.StartedAt.Unix()
			if buildingType == PetRoomBuilding {
				body["pet_id"] = state.PetID
			}
			return body, nil
		}
	}
	if state.PendingItem > 0 {
		body["make_item"] = state.PendingItem
	}
	if buildingType == PetRoomBuilding {
		body["pet_id"] = state.PetID
	}
	return body, nil
}

func RecycleWire(state State, limit, seconds int64, at time.Time) (map[string]any, error) {
	recycle := state.Recycle
	if err := SettleRecycle(&recycle, limit, seconds, at); err != nil {
		return nil, err
	}
	return map[string]any{"energy": recycle.Energy, "energy_limit": limit, "energy_time": recycle.EnergyAt.Unix()}, nil
}
