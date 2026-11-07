package libraryforum

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/libraryforum"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const LifecyclePolicy = "I9_LIBRARY_FORUM_V1"
const ResultSchema = "gxb.libraryforum.command.v1"
const OperationClass = "I9_10B_LIBRARY_FORUM"

const (
	Like    = "LIBRARY_FORUM_LIKE"
	Comment = "LIBRARY_FORUM_COMMENT"
)

var (
	ErrRequest     = errors.New("library forum: invalid request")
	ErrRejected    = errors.New("library forum: rejected")
	ErrUnavailable = errors.New("library forum: unavailable")
	ErrProof       = errors.New("library forum: invalid operation proof")
)

// Command is the validated intent of 833 or 834. Comment leaves TableID and
// Author empty because the actor's owned instance resolves both.
type Command struct {
	Family    string
	ForumType int64
	TableID   int64
	Author    int64
	Instance  int64
	Text      string
}

func (c Command) Validate() error {
	if c.ForumType != d.HeroForum && c.ForumType != d.PetForum {
		return ErrRequest
	}
	switch c.Family {
	case Like:
		if c.TableID <= 0 || c.Author <= 0 || c.Instance != 0 || c.Text != "" {
			return ErrRequest
		}
	case Comment:
		if c.TableID != 0 || c.Author != 0 || c.Instance <= 0 || !d.ValidText(c.Text) {
			return ErrRejected
		}
	default:
		return ErrRequest
	}
	return nil
}

// PageQuery is 832's 1-based inclusive page.
type PageQuery struct {
	ForumType int64
	TableID   int64
	Start     int64
	End       int64
}

func (q PageQuery) Validate() error {
	if (q.ForumType != d.HeroForum && q.ForumType != d.PetForum) || q.TableID <= 0 || q.Start < 1 || q.End < q.Start || q.End-q.Start+1 > d.MaxPageRows {
		return ErrRequest
	}
	return nil
}

// Row is one composed forum comment row. Only the active forum type's level,
// color and star fields are filled, matching the stock windows.
type Row struct {
	PlayerID      int64
	PlayerName    string
	AvatarID      int64
	AvatarFrameID int64
	Region        int64
	PlayerLevel   int64
	ConquerLevel  int64
	ConquerLoopID int64
	HeroLevel     int64
	HeroColor     int64
	HeroStar      int64
	PetLevel      int64
	PetColor      int64
	PetStar       int64
	Comment       string
	Likes         int64
	ViewerLiked   bool
	TableID       int64
}

type Page struct {
	Rows []Row
}

// Result is the durable terminal of one forum command.
type Result struct {
	Schema      string
	Command     Command
	Actor       DurableActor
	OperationID ids.UUID
	Entropy     [32]byte
	DecisionAt  time.Time
	TableID     int64
	Rows        []Row
}

// DurableActor retains identity references and epochs, never credentials.
// (Shape copied from librarylocal; both packages keep their own receipt proof.)
type DurableActor struct {
	Account, Session, Context                          ids.UUID
	AccountUID                                         string
	Server                                             int32
	Player, Generation, SessionVersion, ContextVersion int64
}

func actorRecord(a identity.ActorContext) DurableActor {
	return DurableActor{a.AccountID.UUID(), a.SessionID.UUID(), a.ContextID.UUID(), string(a.AccountUID), int32(a.LogicalServerID), int64(a.PlayerID), a.ContextGeneration, a.SessionLivenessVersion, a.ContextLivenessVersion}
}

func (d DurableActor) Actor() (identity.ActorContext, error) {
	a := identity.ActorContext{AccountUID: identity.AccountUID(d.AccountUID), LogicalServerID: identity.LogicalServerID(d.Server), PlayerID: identity.PlayerID(d.Player), ContextGeneration: d.Generation, SessionLivenessVersion: d.SessionVersion, ContextLivenessVersion: d.ContextVersion}
	var e error
	if a.AccountID, e = identity.AccountIDFrom(d.Account); e != nil {
		return a, e
	}
	if a.SessionID, e = identity.SessionIDFrom(d.Session); e != nil {
		return a, e
	}
	if a.ContextID, e = identity.ContextIDFrom(d.Context); e != nil {
		return a, e
	}
	return a, nil
}

type Admission struct {
	Operation  operation.Context
	DecisionAt time.Time
	Actor      DurableActor
	Command    Command
}

type Service struct {
	Timed      gen.TimedRunner
	Reads      tx.Runner
	Store      Store
	Players    PlayerRoots
	Fence      ActorFence
	Receipts   receipt.Store
	Directory  DirectoryPort
	Characters CharacterPort
}

func Profile() tx.Profile {
	return tx.Profile{Name: "I9_10B_LIBRARY_FORUM", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 15 * time.Second}
}

func (s Service) complete() bool {
	return s.Timed.Binder.Time != nil && s.Timed.Runner.DB != nil && s.Reads.DB != nil && s.Store != nil && s.Players != nil && s.Fence != nil && s.Receipts != nil && s.Directory != nil && s.Characters != nil
}

func receiptID(d Admission) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(d.Actor.Player, 10), Domain: "library-forum", Operation: d.Command.Family, SemanticKey: d.Operation.ID.String()}
}

func fingerprint(c Command) ([32]byte, error) {
	return receipt.FingerprintRequest(map[string]any{"family": c.Family, "forum_type": c.ForumType, "table_id": c.TableID, "author": c.Author, "instance": c.Instance, "comment": c.Text, "policy": LifecyclePolicy})
}

func (s Service) proof(ctx context.Context, q tx.Queryer, d Admission) (Result, bool, error) {
	var out Result
	r, ok, e := s.Receipts.FindTx(ctx, q, receiptID(d))
	if e != nil || !ok {
		return out, ok, e
	}
	fp, e := fingerprint(d.Command)
	if e != nil {
		return out, true, e
	}
	if r.Validate() != nil || r.Identity != receiptID(d) || r.RequestFingerprint != fp || r.OperationClass != OperationClass || r.ResultSchema != ResultSchema || r.ActorAccountUID != d.Actor.AccountUID || r.ContextID != d.Actor.Context || r.PolicyVersion != LifecyclePolicy || r.OperationStartedAt.UnixMicro() != d.Operation.StartedAt.UnixMicro() {
		return out, true, ErrProof
	}
	for _, ref := range d.Operation.Policies.Refs() {
		if v, ok := r.OperationPolicyRefs.Get(ref.Name); !ok || v != ref.Version {
			return out, true, ErrProof
		}
	}
	dec := json.NewDecoder(bytes.NewReader(r.ResultPayload))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&out); e != nil {
		return out, true, e
	}
	var trailing any
	if dec.Decode(&trailing) != io.EOF {
		return out, true, ErrProof
	}
	if !d.DecisionAt.IsZero() && out.DecisionAt.UnixMicro() != d.DecisionAt.UnixMicro() {
		return out, true, ErrProof
	}
	if out.Schema != ResultSchema || out.Command != d.Command || out.Actor != d.Actor || out.OperationID != d.Operation.ID || out.Entropy != d.Operation.EntropySeed || out.DecisionAt.IsZero() || out.DecisionAt.After(r.RecordedAt) {
		return out, true, ErrProof
	}
	return out, true, nil
}

func (s Service) putReceipt(ctx context.Context, t tx.Tx, d Admission, out Result) error {
	raw, e := json.Marshal(out)
	if e != nil {
		return e
	}
	fp, e := fingerprint(d.Command)
	if e != nil {
		return e
	}
	r, e := receipt.New(d.Operation, receiptID(d), OperationClass, ResultSchema, raw, fp)
	if e != nil {
		return e
	}
	r.ActorAccountUID = d.Actor.AccountUID
	r.ContextID = d.Actor.Context
	r.PolicyVersion = LifecyclePolicy
	r.RecordedAt = d.DecisionAt
	put, e := s.Receipts.PutTx(ctx, t, r)
	if e != nil {
		return e
	}
	if !put.Inserted {
		return ErrProof
	}
	return nil
}

type resolver struct {
	s Service
	d Admission
}

func (r resolver) Resolve(ctx context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	var out Result
	found := false
	actor, e := r.d.Actor.Actor()
	if e != nil {
		return tx.Resolution{}, e
	}
	at, e := r.s.Timed.Binder.Time.Now(ctx)
	if e != nil {
		return tx.Resolution{}, e
	}
	res, e := r.s.Reads.Run(ctx, r.d.Operation, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		if e := r.s.Fence.FenceActorTx(ctx, sc.Tx, actor, at); e != nil {
			return e
		}
		var e error
		out, found, e = r.s.proof(ctx, sc.Tx, r.d)
		return e
	})
	if e != nil || res.Outcome != tx.DefiniteCommit {
		return tx.Resolution{}, e
	}
	if !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: out}, nil
}

// Read serves 832. It takes no locks and advances no state.
func (s Service) Read(ctx context.Context, a identity.ActorContext, q PageQuery, op operation.Context) (Page, error) {
	if !s.complete() || q.Validate() != nil || op.ID.IsZero() || op.StartedAt.IsZero() {
		return Page{}, ErrRequest
	}
	key := d.Key{ForumType: q.ForumType, TableID: q.TableID}
	if key.Validate() != nil {
		return Page{}, ErrRequest
	}
	var out Page
	res, e := s.Reads.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		var e error
		out, e = s.pageTx(ctx, sc.Tx, a.PlayerID, key, q.Start, q.End)
		return e
	})
	if e != nil {
		return Page{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return Page{}, ErrUnavailable
	}
	return out, nil
}

// Command serves 833 and 834 in one serializable transaction: actor fence, I4
// player root, forum row, receipt. It has no I5 settlement.
func (s Service) Command(ctx context.Context, a identity.ActorContext, c Command, op operation.Context) (Result, error) {
	if !s.complete() || op.ID.IsZero() || op.StartedAt.IsZero() {
		return Result{}, ErrUnavailable
	}
	if e := c.Validate(); e != nil {
		return Result{}, e
	}
	refs := op.Policies.Refs()
	if v, ok := op.Policies.Get("forum"); ok {
		if v != LifecyclePolicy {
			return Result{}, ErrProof
		}
	} else {
		refs = append(refs, policy.Ref{Name: "forum", Version: LifecyclePolicy})
	}
	var e error
	if op.Policies, e = policy.NewSet(refs...); e != nil {
		return Result{}, e
	}
	timed, e := s.Timed.Binder.Bind(ctx, op)
	if e != nil {
		return Result{}, e
	}
	admission := Admission{Operation: op, DecisionAt: timed.DecisionAt(), Actor: actorRecord(a), Command: c}
	var out Result
	res, e := s.Timed.Runner.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}, resolver{s, admission}, func(ctx context.Context, sc tx.Scope) error {
		if e := s.Fence.FenceActorTx(ctx, sc.Tx, a, admission.DecisionAt); e != nil {
			return e
		}
		roots, e := s.Players.LockPlayerRootsTx(ctx, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID})
		if e != nil {
			return e
		}
		if len(roots) != 1 || roots[0].PlayerID != a.PlayerID {
			return ErrRejected
		}
		prior, found, e := s.proof(ctx, sc.Tx, replayLookup(admission))
		if e != nil {
			return e
		}
		if found {
			out = prior
			return nil
		}
		out, e = s.commitTx(ctx, sc.Tx, a, admission)
		if e != nil {
			return e
		}
		return s.putReceipt(ctx, sc.Tx, admission, out)
	})
	if e != nil {
		return Result{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return Result{}, ErrUnavailable
	}
	if res.Reconciled {
		v, ok := res.Evidence.(Result)
		if !ok {
			return Result{}, ErrProof
		}
		return v, nil
	}
	return out, nil
}

// replayLookup ignores the fresh decision instant when an operation is checked
// for an already committed receipt; the stored instant is the proof.
func replayLookup(d Admission) Admission {
	d.DecisionAt = time.Time{}
	return d
}

func (s Service) commitTx(ctx context.Context, t tx.Tx, a identity.ActorContext, admission Admission) (Result, error) {
	out := Result{Schema: ResultSchema, Command: admission.Command, Actor: admission.Actor, OperationID: admission.Operation.ID, Entropy: admission.Operation.EntropySeed, DecisionAt: admission.DecisionAt}
	switch admission.Command.Family {
	case Like:
		key := d.Key{ForumType: admission.Command.ForumType, TableID: admission.Command.TableID}
		author := identity.PlayerID(admission.Command.Author)
		if key.Validate() != nil || !author.Valid() {
			return Result{}, ErrRejected
		}
		if e := s.Store.LockBoardTx(ctx, t, key); e != nil {
			return Result{}, e
		}
		if _, found, e := s.Store.LockCommentTx(ctx, t, key, author); e != nil {
			return Result{}, e
		} else if !found {
			return Result{}, ErrRejected
		}
		liked, e := s.Store.FindReactionTx(ctx, t, key, author, a.PlayerID)
		if e != nil {
			return Result{}, e
		}
		if liked {
			e = s.Store.DeleteReactionTx(ctx, t, key, author, a.PlayerID)
		} else {
			e = s.Store.InsertReactionTx(ctx, t, d.Reaction{Key: key, Author: author, Viewer: a.PlayerID, CreatedAt: admission.DecisionAt})
		}
		if e != nil {
			return Result{}, e
		}
		page, e := s.pageTx(ctx, t, a.PlayerID, key, 1, d.MaxPageRows)
		if e != nil {
			return Result{}, e
		}
		out.TableID = key.TableID
		out.Rows = page.Rows
	case Comment:
		key, e := s.resolveCommentTargetTx(ctx, t, a, admission.Command)
		if e != nil {
			return Result{}, e
		}
		comment := d.Comment{Key: key, Author: a.PlayerID, Text: admission.Command.Text, CreatedAt: admission.DecisionAt, UpdatedAt: admission.DecisionAt}
		if comment.Validate() != nil {
			return Result{}, ErrRejected
		}
		if e = s.Store.LockBoardTx(ctx, t, key); e != nil {
			return Result{}, e
		}
		previous, found, e := s.Store.LockCommentTx(ctx, t, key, a.PlayerID)
		if e != nil {
			return Result{}, e
		}
		if found {
			comment.CreatedAt = previous.CreatedAt
		} else {
			count, countError := s.Store.CountLiveCommentsTx(ctx, t, key)
			if countError != nil {
				return Result{}, countError
			}
			if count >= d.MaxLiveComments {
				if e = s.Store.RetireOldestCommentsTx(ctx, t, key, count-d.MaxLiveComments+1, admission.DecisionAt); e != nil {
					return Result{}, e
				}
			}
			if e = s.Store.ClearAuthorReactionsTx(ctx, t, key, a.PlayerID); e != nil {
				return Result{}, e
			}
		}
		if e = s.Store.UpsertCommentTx(ctx, t, comment); e != nil {
			return Result{}, e
		}
		out.TableID = key.TableID
	default:
		return Result{}, ErrRequest
	}
	return out, nil
}

func (s Service) resolveCommentTargetTx(ctx context.Context, q tx.Queryer, a identity.ActorContext, c Command) (d.Key, error) {
	key := d.Key{ForumType: c.ForumType}
	switch c.ForumType {
	case d.HeroForum:
		h, ok, e := s.Characters.FindHeroByPartnerIDTx(ctx, q, a.PlayerID, c.Instance)
		if e != nil {
			return key, e
		}
		if !ok {
			return key, ErrRejected
		}
		key.TableID = h.TableID
	case d.PetForum:
		p, ok, e := s.Characters.FindPetByIDTx(ctx, q, a.PlayerID, c.Instance)
		if e != nil {
			return key, e
		}
		if !ok {
			return key, ErrRejected
		}
		key.TableID = p.TableID
	}
	if key.Validate() != nil {
		return key, ErrRejected
	}
	return key, nil
}

func (s Service) pageTx(ctx context.Context, q tx.Queryer, viewer identity.PlayerID, key d.Key, start, end int64) (Page, error) {
	listed, e := s.Store.ListCommentsTx(ctx, q, key, viewer, end-start+1, start-1)
	if e != nil {
		return Page{}, e
	}
	rows := make([]Row, 0, len(listed))
	for _, item := range listed {
		row, e := s.rowTx(ctx, q, key, item)
		if e != nil {
			return Page{}, e
		}
		rows = append(rows, row)
	}
	return Page{Rows: rows}, nil
}

func (s Service) rowTx(ctx context.Context, q tx.Queryer, key d.Key, item d.Listed) (Row, error) {
	if !item.Author.Valid() || !d.ValidText(item.Text) || item.Likes < 0 || item.CreatedAt.IsZero() || !logicalserver.PlayerRegion(item.Author).Valid() {
		return Row{}, ErrRejected
	}
	profile, ok, e := s.Directory.ProfileTx(ctx, q, item.Author)
	if e != nil {
		return Row{}, e
	}
	if !ok || profile.Validate() != nil || profile.PlayerID != item.Author {
		return Row{}, ErrRejected
	}
	row := Row{PlayerID: int64(item.Author), PlayerName: profile.Name, AvatarID: profile.AvatarID, AvatarFrameID: profile.AvatarFrameID, Region: int64(logicalserver.PlayerRegion(item.Author)), PlayerLevel: profile.Level, ConquerLevel: profile.ConquerLevel, ConquerLoopID: profile.ConquerLoopID, Comment: item.Text, Likes: item.Likes, ViewerLiked: item.ViewerLiked, TableID: key.TableID}
	switch key.ForumType {
	case d.HeroForum:
		hero, ok, e := s.heroForTableTx(ctx, q, item.Author, key.TableID)
		if e != nil {
			return Row{}, e
		}
		if !ok {
			return Row{}, ErrRejected
		}
		row.HeroLevel, row.HeroColor, row.HeroStar = hero.Level, hero.Color, hero.Star
	case d.PetForum:
		pet, ok, e := s.petForTableTx(ctx, q, item.Author, key.TableID)
		if e != nil {
			return Row{}, e
		}
		if !ok {
			return Row{}, ErrRejected
		}
		row.PetLevel, row.PetColor, row.PetStar = pet.Level, pet.Color, pet.Star
	default:
		return Row{}, ErrRejected
	}
	return row, nil
}

// heroForTableTx prefers the author's current instance of the board's table and
// falls back to its origin table, so a comment survives that hero's awakening.
func (s Service) heroForTableTx(ctx context.Context, q tx.Queryer, author identity.PlayerID, tableID int64) (character.Hero, bool, error) {
	heroes, e := s.Characters.ListHeroesTx(ctx, q, author)
	if e != nil {
		return character.Hero{}, false, e
	}
	for _, h := range heroes {
		if h.TableID == tableID {
			return h, true, nil
		}
	}
	for _, h := range heroes {
		if h.OriginTableID == tableID {
			return h, true, nil
		}
	}
	return character.Hero{}, false, nil
}

func (s Service) petForTableTx(ctx context.Context, q tx.Queryer, author identity.PlayerID, tableID int64) (character.Pet, bool, error) {
	pets, e := s.Characters.ListPetsTx(ctx, q, author)
	if e != nil {
		return character.Pet{}, false, e
	}
	for _, p := range pets {
		if p.TableID == tableID {
			return p, true, nil
		}
	}
	for _, p := range pets {
		if p.OriginTableID == tableID {
			return p, true, nil
		}
	}
	return character.Pet{}, false, nil
}
