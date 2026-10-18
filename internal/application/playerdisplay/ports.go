// Package playerdisplay owns Player display composition under I5. Other owners
// contribute qualified caller-Tx facts; catalog rows never establish ownership.
package playerdisplay

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/directorysync"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

var ErrRequest = player.ErrDisplay
var ErrUnavailable = player.ErrDisplayUnavailable
var ErrConflict = errors.New("player display operation conflict")
var ErrUnresolved = errors.New("player display prior value attempt unresolved")

type State struct {
	Basis     i5.PublicPlayerBasis
	Selection player.DisplaySelection
	Present   bool
}

func (s State) Validate() error {
	if s.Basis.Validate() != nil || s.Selection.Validate() != nil {
		return ErrConflict
	}
	return nil
}

type Origin struct {
	PlayerID     identity.PlayerID `json:"player_id"`
	Key          string            `json:"key"`
	Owner        string            `json:"owner"`
	Family       string            `json:"family"`
	CatalogID    int64             `json:"catalog_id"`
	UniqueID     int64             `json:"unique_id"`
	StartsAt     *time.Time        `json:"starts_at"`
	EndTime      int64             `json:"end_time"`
	Revision     string            `json:"revision"`
	StateVersion int64             `json:"state_version"`
}

func (o Origin) Validate() error {
	if !o.PlayerID.Valid() || o.Key == "" || o.Owner == "" || o.CatalogID <= 0 || o.UniqueID < 0 || len(o.Revision) != 64 || o.StateVersion < 1 {
		return ErrConflict
	}
	if o.Family != "avatar" && o.Family != "frame" && o.Family != "title" && o.Family != "bubble" {
		return ErrConflict
	}
	return nil
}

// External owner must distinguish a qualified empty result from unavailable.
// This interface never discovers a clock/revision or starts a transaction.
type OriginObservation struct {
	PlayerID         identity.PlayerID
	Family, Revision string
	ObservedAt       time.Time
	Qualified        bool
	Origins          []Origin
}
type ExternalOrigins interface {
	ReadDisplayOriginsTx(context.Context, tx.Queryer, identity.PlayerID, string, string, time.Time) (OriginObservation, error)
}
type HeroFacet struct {
	PlayerID                                               identity.PlayerID
	PartnerID, TableID, BeforeAwaken, Version, Color, Star int64
	Super, Awakened                                        bool
	Skins                                                  []int64
}
type CharacterReader interface {
	ReadDisplayHeroesTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) ([]HeroFacet, error)
	PrepareDisplayHeroesTx(context.Context, tx.Tx, identity.PlayerID) error
}
type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	ReadPlayerDisplayCatalogTx(context.Context, tx.Queryer, string) (player.DisplayCatalog, error)
}
type Command struct {
	Kind     string `json:"kind"`
	Name     string `json:"name"`
	ID       int64  `json:"id"`
	Icon     int64  `json:"icon"`
	Category int64  `json:"category"`
	UniqueID int64  `json:"unique_id"`
}

func (q Command) Validate() error {
	if q.ID < 0 || q.Icon < 0 || q.Category < 0 || q.UniqueID < 0 || q.ID > 9007199254740991 || q.UniqueID > 9007199254740991 {
		return ErrRequest
	}
	switch q.Kind {
	case "rename":
		if q.Name == "" || q.ID != 0 || q.Icon != 0 || q.Category != 0 || q.UniqueID != 0 {
			return ErrRequest
		}
	case "avatar":
		if q.Name != "" || q.ID == 0 || q.Icon == 0 || q.Category < 1 || q.Category > 5 || q.UniqueID != 0 {
			return ErrRequest
		}
	case "frame", "bubble", "purchase":
		if q.Name != "" || q.ID == 0 || q.Icon != 0 || q.Category != 0 || q.UniqueID != 0 {
			return ErrRequest
		}
	case "title":
		if q.Name != "" || q.Icon != 0 || q.Category != 0 || (q.ID == 0 && q.UniqueID != 0) {
			return ErrRequest
		}
	default:
		return ErrRequest
	}
	return nil
}

type Admission struct {
	Operation  operation.Context
	Actor      identity.ActorContext `json:"-"`
	Command    Command
	Revision   string
	DecisionAt time.Time
	State      string
}
type Store interface {
	ReadDisplayStateTx(context.Context, tx.Queryer, identity.PlayerID, bool) (State, error)
	SaveDisplayStateTx(context.Context, tx.Tx, State, State, time.Time) error
	ReadDisplayEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, string) ([]Origin, error)
	PutDisplayEntitlementTx(context.Context, tx.Tx, Origin) error
	ListStacksTx(context.Context, tx.Queryer, identity.PlayerID) ([]economy.StackState, error)
	ReadDisplayAdmissionTx(context.Context, tx.Queryer, string, bool) (Admission, bool, error)
	PendingDisplayAdmissionTx(context.Context, tx.Tx, identity.PlayerID) (Admission, bool, error)
	InsertDisplayAdmissionTx(context.Context, tx.Tx, Admission) error
	SetDisplayAdmissionTx(context.Context, tx.Tx, string, string, string) error
}

// PreparedValue retains I5-owned locked resources. Planning precedes every
// mutation, including directory740; Apply performs no new lock discovery.
type PreparedValue = i5.PreparedDisplayValue
type ValuePort = i5.DisplayValuePort
type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type Service struct {
	Runner             tx.Runner
	Fresh              tx.Queryer
	Time               gen.TimeAuthority
	Players            playerroot.TxLocker
	Fence              Fence
	Store              Store
	Content            Content
	Receipts           receipt.Store
	Characters         CharacterReader
	Privileges         i5.PrivilegeSnapshotProvider
	CosmeticPrivileges CosmeticPrivilegeReader
	Population         CharacterPopulationReader
	Inventory          InventoryReader
	External           ExternalOrigins
	CatalogExternal    CatalogExternalOrigins
	Values             ValuePort
	Directory          directorysync.Reconciler
}
type Observation struct {
	TitleEndTime, BubbleEndTime                         int64
	PlayerID                                            identity.PlayerID
	Revision                                            string
	ObservedAt                                          time.Time
	ProfileVersion, ProgressionVersion                  int64
	AvatarID, FrameID, TitleID, TitleUniqueID, BubbleID int64
	Origins                                             []Origin
	HeroVersions                                        []HeroFacet
}
