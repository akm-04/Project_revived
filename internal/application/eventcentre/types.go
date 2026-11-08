package eventcentre

import (
	"time"

	book "gxb.local/backend/v2/internal/domain/bookskill"
	ec "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/modes"
)

type (
	Catalog        = ec.Catalog
	State          = ec.State
	Root           = ec.Root
	MakeState      = ec.MakeState
	MakeJob        = ec.MakeJob
	RecycleState   = ec.RecycleState
	AdminRule      = ec.AdminRule
	ResourceAmount = ec.ResourceAmount
	Recipe         = ec.Recipe
)

const (
	PolicyVersion   = ec.PolicyVersion
	ResultSchema    = ec.ResultSchema
	OperationClass  = ec.OperationClass
	MaxAdminPerPair = ec.MaxAdminPerPair
	DeskBuilding    = ec.DeskBuilding
	RecycleBuilding = ec.RecycleBuilding
	AdminBuilding   = ec.AdminBuilding
	PetRoomBuilding = ec.PetRoomBuilding
)

var (
	ErrInvalid     = ec.ErrInvalid
	ErrUnqualified = ec.ErrUnqualified
	ErrStaleTime   = ec.ErrStaleTime
)

func Seed() State { return ec.Seed() }

func AdminKey(source, destination int64) string { return ec.AdminKey(source, destination) }

func BookBuildingWire(building book.Building) map[string]any { return ec.BuildingInfo(building) }

func RecycleWire(state State, limit, seconds int64, at time.Time) (map[string]any, error) {
	return ec.RecycleWire(state, limit, seconds, at)
}

func MakeWire(buildingType int64, state MakeState, at time.Time) (map[string]any, error) {
	return ec.MakeWire(buildingType, state, at)
}

func modesDay(at time.Time) int64 { return modes.Day(at) }

var adminSources = ec.AdminSources()
var adminDestinations = ec.AdminDestinations()
