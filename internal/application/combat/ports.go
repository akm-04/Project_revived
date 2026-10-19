// Package combat composes the Combat owner: START freezes an immutable snapshot
// and durable attempt inside the mode's caller transaction, Resolve runs the
// isolated worker outside locks and persists the resolution once, and
// TerminalTx settles the attempt once inside the mode's terminal transaction.
// Combat never reads mode tables or owns mode rewards, ranks or calendars.
package combat

import (
	"context"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	conquer "gxb.local/backend/v2/internal/application/conquerschool"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/combat"
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

// Worker resolves one snapshot in an isolated process. Errors wrap
// d.ErrResolverRetryable or d.ErrResolverPermanent.
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
	FactsTx(context.Context, ca.CoherentReadScope, identity.PlayerID) (conquer.Observation, error)
}

type Stacks interface {
	ListStacksTx(context.Context, tx.Queryer, identity.PlayerID) ([]economy.StackState, error)
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
