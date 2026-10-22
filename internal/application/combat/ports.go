// Package combat composes the Combat owner: START freezes an immutable snapshot
// and durable attempt inside the mode's caller transaction, Resolve runs the
// isolated worker outside locks and persists the resolution once, and
// TerminalTx settles the attempt once inside the mode's terminal transaction.
// Combat never reads mode tables or owns mode rewards, ranks or calendars.
package combat

import (
	"context"
	"fmt"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/combat"
	cq "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Rules is the embedded rules corpus (content/combatcorpus.Corpus).
type Rules interface {
	ID() string
	SourceArchiveSHA256() string
	FighterClass(table string, id int64) (class string, present bool, known bool)
	BattleLineup(fightID int64) (waves [][]int64, assistPartners []int64, err error)
}

// Keys is the configured entropy key ring. Retired versions stay readable for
// historical reconstruction; a missing version fails closed.
type Keys interface {
	Current() (version string, key []byte, err error)
	Key(version string) ([]byte, error)
}

type WorkerOutput struct {
	CorpusID       string
	Outcome        d.Outcome
	Report         []byte
	EntropyDraws   uint64
	EntropyReseeds uint64
}

// ErrWorkerSaturated refuses an attempt before any worker ran it
// (I8_WORKER_ADMISSION_V1); the attempt stays untouched and runnable.
var ErrWorkerSaturated = fmt.Errorf("%w: worker admission saturated", d.ErrResolverRetryable)

// Worker resolves one snapshot in an isolated process. Errors wrap
// d.ErrResolverRetryable or d.ErrResolverPermanent; ErrWorkerSaturated means
// no worker ran.
type Worker interface {
	Resolve(ctx context.Context, snapshot []byte, snapshotHash string, root [32]byte) (WorkerOutput, error)
}

type Store interface {
	LockLocatorTx(context.Context, tx.Tx, d.Locator) error
	FindUnresolvedTx(context.Context, tx.Queryer, d.Locator) (d.Attempt, bool, error)
	FindTerminalTx(context.Context, tx.Queryer, d.Locator, string) (d.Attempt, bool, error)
	InsertSnapshotTx(context.Context, tx.Tx, string, []byte) error
	ReadSnapshotTx(context.Context, tx.Queryer, string) ([]byte, error)
	InsertAttemptTx(context.Context, tx.Tx, d.Attempt) error
	ReadAttemptTx(context.Context, tx.Queryer, ids.UUID) (d.Attempt, bool, error)
	LockAttemptTx(context.Context, tx.Tx, ids.UUID) (d.Attempt, error)
	SaveAttemptTx(context.Context, tx.Tx, d.Attempt, int64) error
	InsertResolutionTx(context.Context, tx.Tx, string, d.Resolution, []byte) error
	ReadResolutionTx(context.Context, tx.Queryer, string) (d.Resolution, []byte, error)
	InsertStartPackageTx(context.Context, tx.Tx, d.StartPackage) error
	ReadStartPackageTx(context.Context, tx.Queryer, ids.UUID) (d.StartPackage, bool, error)
	InsertAttestationTx(context.Context, tx.Tx, d.Attestation) error
	ReadAttestationTx(context.Context, tx.Queryer, ids.UUID) (d.Attestation, error)
	InsertMembersTx(context.Context, tx.Tx, ids.UUID, []int64) error
	ReadMembersTx(context.Context, tx.Queryer, ids.UUID) ([]int64, error)
	InsertMemberSettlementTx(context.Context, tx.Tx, d.MemberSettlement) error
	FindMemberSettlementTx(context.Context, tx.Queryer, ids.UUID, int64) (d.MemberSettlement, bool, error)
}

// Content reports the active revision and its manifest source archive.
type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	SourceArchiveTx(context.Context, tx.Queryer, string) (string, error)
}

// Roster is the existing stock roster composer (MID1 key 49 Heroes, 780 Pets);
// combat reuses its serializers instead of a second owner mapping.
type Roster interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

type Stats interface {
	HeroTx(context.Context, ca.CoherentReadScope, character.HeroRef, publicstats.View) (publicstats.Result, error)
	PetTx(context.Context, ca.CoherentReadScope, character.PetRef, publicstats.View) (publicstats.Result, error)
}

type Collection interface {
	PlayerCollectionInputsTx(context.Context, tx.Queryer, lib.InputScope) (lib.CollectionInputs, error)
}

type Conquer interface {
	FactsTx(context.Context, ca.CoherentReadScope, identity.PlayerID) (cq.Observation, error)
}

type Stacks interface {
	ListStacksTx(context.Context, tx.Queryer, identity.PlayerID) ([]economy.StackState, error)
}

// Loan asks a lending capability for one lender-owned Hero or Pet to fight for
// the borrower in the attempt at Locator (stock rent_player_id/rent_formation,
// rent_pet_player_id/rent_pet_id).
type Loan struct {
	Borrower identity.PlayerID
	Lender   identity.PlayerID
	Kind     d.ActorKind
	Identity int64
	Locator  d.Locator
}

// Lending is the capability owner of loans (GUILD_RENTAL and activity owners;
// I8 binds fixtures only). LendTx checks the offer, eligibility and cost under
// its own fences and commits the use in the START transaction, or refuses with
// d.ErrLoanRefused. A replayed START never calls it.
type Lending interface {
	LendTx(context.Context, tx.Tx, ca.CoherentReadScope, Loan) (d.Provenance, error)
}

// Admission is a START's member roster at its locator, convener first.
type Admission struct {
	Convener identity.PlayerID
	Members  []identity.PlayerID
	Locator  d.Locator
}

// Rooms is the SHARED_ROOM_CORE capability owner of member rosters (I9 binds
// rooms; I8 binds fixtures only). AdmitTx confirms the roster inside the START
// transaction before any member read, or refuses with d.ErrRoomRefused. A
// replayed START never calls it.
type Rooms interface {
	AdmitTx(context.Context, tx.Tx, ca.CoherentReadScope, Admission) error
}

// Inputs are the canonical owner read ports used to freeze owned actors.
type Inputs struct {
	Heroes     Roster
	Pets       Roster
	Stats      Stats
	Awakening  publicstats.Awakening
	Collection Collection
	Conquer    Conquer
	Stacks     Stacks
	// Lending admits BORROWED actors; without it START refuses them.
	Lending Lending
	// Rooms admits a member roster; without it START refuses one.
	Rooms Rooms
}

type Service struct {
	Rules   Rules
	Keys    Keys
	Worker  Worker
	Store   Store
	Content Content
	Inputs  Inputs
	Runner  tx.Runner
	Fresh   tx.Queryer
}
