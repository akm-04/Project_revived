package i5

import (
	"context"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type AwakeningStore interface {
	ReadAwakeningTx(context.Context, tx.Queryer, identity.PlayerID) (objective.AwakeRoot, error)
	LockAwakeningTx(context.Context, tx.Tx, identity.PlayerID) (objective.AwakeRoot, error)
	SaveAwakeningTx(context.Context, tx.Tx, identity.PlayerID, objective.AwakeRoot, int64) error
}
type AwakeningContent interface {
	AwakeningCatalogTx(context.Context, tx.Queryer, string) (objective.AwakeCatalog, error)
}
type AwakeningHero struct {
	Hero character.Hero
	Raw  *character.RawAwakeningBirth
}
type AwakeningHeroes interface {
	HasAwakeningHeroEquipmentTx(context.Context, tx.Queryer, character.Hero, objective.AwakeDefinition, string) (bool, error)
	AwakeningHeroesTx(context.Context, tx.Queryer, identity.PlayerID, string) ([]AwakeningHero, error)
	LockAwakeningHeroesTx(context.Context, tx.Tx, identity.PlayerID, string) ([]AwakeningHero, error)
	ApplyAwakeningHeroLockedTx(context.Context, tx.Tx, AwakeningHero, objective.AwakeDefinition, objective.AwakeInstance, string, operation.Context, time.Time) (AwakeningHero, error)
}
type AwakeningPets interface {
	HasAwakeningPetEquipmentTx(context.Context, tx.Queryer, character.Pet, objective.AwakeDefinition, string) (bool, error)
	AwakeningPetsTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Pet, error)
	LockAwakeningPetsTx(context.Context, tx.Tx, identity.PlayerID) ([]character.Pet, error)
	FinishAwakeningPetLockedTx(context.Context, tx.Tx, character.Pet, objective.AwakeDefinition, string, operation.Context, time.Time) error
}
type AwakeningStacks interface {
	ListStacksTx(context.Context, tx.Queryer, identity.PlayerID) ([]economy.StackState, error)
}
type AwakeningRuntime struct {
	Stacks  AwakeningStacks
	Costs   TxMaterialCostDebiter
	Store   AwakeningStore
	Content AwakeningContent
	Heroes  AwakeningHeroes
	Pets    AwakeningPets
}
