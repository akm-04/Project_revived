package registry

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrStaleActivation = errors.New("content registry: stale activation predecessor")

func DefaultWriteProfile() tx.Profile {
	return tx.Profile{
		Name:               "R4_CONTENT_WRITE",
		AcquireTimeout:     5 * time.Second,
		LockTimeout:        10 * time.Second,
		StatementTimeout:   30 * time.Second,
		TransactionTimeout: 45 * time.Second,
		CleanupTimeout:     5 * time.Second,
		ReconcileTimeout:   10 * time.Second,
		OperationTimeout:   60 * time.Second,
	}
}
func DefaultRetryPolicy() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: false}
}

type Service struct {
	Runner    tx.Runner
	Repo      Repository
	Fresh     tx.Queryer
	Providers ProviderSet
	Profile   tx.Profile
	Retry     tx.RetryPolicy
}

func (s Service) normalized() (Service, error) {
	if s.Runner.DB == nil {
		return s, errors.New("content registry: nil transaction runner DB")
	}
	if s.Repo == nil {
		return s, errors.New("content registry: nil repository")
	}
	if s.Fresh == nil {
		return s, errors.New("content registry: nil fresh queryer")
	}
	if len(s.Providers.names) == 0 {
		return s, errors.New("content registry: explicit provider set required")
	}
	if s.Profile.Name == "" {
		s.Profile = DefaultWriteProfile()
	}
	if s.Retry.MaxAttempts == 0 {
		s.Retry = DefaultRetryPolicy()
	}
	if s.Retry.AllowReplayAfterAuthoritativeNegative {
		return s, errors.New("content registry: authoritative-negative replay must remain disabled")
	}
	return s, nil
}

func (s Service) validateTarget(b Bundle) error {
	if err := b.Validate(); err != nil {
		return err
	}
	if b.SchemaVersion() != builtin.SchemaVersion {
		return fmt.Errorf("content registry: unsupported target schema %d", b.SchemaVersion())
	}
	if err := s.Providers.SupportsAll(b.manifest.EnabledCapabilities); err != nil {
		return err
	}
	return nil
}

func (s Service) EnsureBuiltinInstalled(ctx context.Context, op operation.Context, b Bundle) (tx.Result, error) {
	var err error
	s, err = s.normalized()
	if err != nil {
		return tx.Result{}, err
	}
	if err := s.validateTarget(b); err != nil {
		return tx.Result{}, err
	}
	resolver := resolverFunc(func(rctx context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
		v, err := s.Repo.VerifyRevision(rctx, s.Fresh, b)
		if err != nil {
			return tx.Resolution{State: tx.ResolutionUnknown}, err
		}
		if v.Matches(b) {
			return tx.Resolution{State: tx.ResolutionCommitted, Evidence: map[string]any{"revision_id": b.RevisionID(), "exact": true}}, nil
		}
		return tx.Resolution{State: tx.ResolutionUnknown, Evidence: map[string]any{"revision_id": b.RevisionID(), "exact": false}}, nil
	})
	return s.Runner.Run(ctx, op, s.Profile, tx.Options{Isolation: tx.Serializable}, s.Retry, resolver, func(tctx context.Context, scope tx.Scope) error {
		if err := s.Repo.LockRegistry(tctx, scope.Tx); err != nil {
			return err
		}
		inserted, err := s.Repo.TryInsertRevision(tctx, scope.Tx, b)
		if err != nil {
			return err
		}
		if inserted {
			wantR, wantP, wantF, wantO, wantH, wantPet, wantPetAcquisition, wantPetProgression, wantEquipmentPrimitives, wantHeroEquipment, wantSuperEquipment, wantHeroFumoTargets, wantHeroFumoMaterials, wantRestorationEquipment, wantRestorationFractions, wantRestorationDenominations, wantPetEquipment, wantPetRestorationEquipment, wantPractice, wantAppearance := b.ExpectedCounts()
			gotR, err := s.Repo.InsertResources(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotR != wantR {
				return fmt.Errorf("content registry: resource insert count=%d want=%d", gotR, wantR)
			}
			gotP, err := s.Repo.InsertProgression(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotP != wantP {
				return fmt.Errorf("content registry: progression insert count=%d want=%d", gotP, wantP)
			}
			gotF, err := s.Repo.InsertFunctionGates(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotF != wantF {
				return fmt.Errorf("content registry: function insert count=%d want=%d", gotF, wantF)
			}
			gotO, err := s.Repo.InsertObjectives(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotO != wantO {
				return fmt.Errorf("content registry: objective insert count=%d want=%d", gotO, wantO)
			}
			gotH, err := s.Repo.InsertHeroCore(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotH != wantH {
				return fmt.Errorf("content registry: Hero insert count=%d want=%d", gotH, wantH)
			}
			gotPet, err := s.Repo.InsertPetCore(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotPet != wantPet {
				return fmt.Errorf("content registry: Pet insert count=%d want=%d", gotPet, wantPet)
			}
			gotPetAcquisition, err := s.Repo.InsertPetAcquisition(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotPetAcquisition != wantPetAcquisition {
				return fmt.Errorf("content registry: Pet acquisition insert count=%d want=%d", gotPetAcquisition, wantPetAcquisition)
			}
			gotPetProgression, err := s.Repo.InsertPetProgression(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotPetProgression != wantPetProgression {
				return fmt.Errorf("content registry: Pet progression insert count=%d want=%d", gotPetProgression, wantPetProgression)
			}
			gotEquipmentPrimitives, err := s.Repo.InsertEquipmentPrimitives(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotEquipmentPrimitives != wantEquipmentPrimitives {
				return fmt.Errorf("content registry: equipment primitive insert count=%d want=%d", gotEquipmentPrimitives, wantEquipmentPrimitives)
			}
			gotHeroEquipment, err := s.Repo.InsertHeroEquipment(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotHeroEquipment != wantHeroEquipment {
				return fmt.Errorf("content registry: Hero equipment insert count=%d want=%d", gotHeroEquipment, wantHeroEquipment)
			}
			gotSuperEquipment, err := s.Repo.InsertSuperEquipment(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotSuperEquipment != wantSuperEquipment {
				return fmt.Errorf("content registry: Super equipment insert count=%d want=%d", gotSuperEquipment, wantSuperEquipment)
			}
			gotHeroFumoTargets, gotHeroFumoMaterials, err := s.Repo.InsertHeroFumo(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotHeroFumoTargets != wantHeroFumoTargets || gotHeroFumoMaterials != wantHeroFumoMaterials {
				return fmt.Errorf("content registry: Hero Fumo insert counts targets=%d/%d materials=%d/%d", gotHeroFumoTargets, wantHeroFumoTargets, gotHeroFumoMaterials, wantHeroFumoMaterials)
			}
			gotRestorationEquipment, gotRestorationFractions, gotRestorationDenominations, err := s.Repo.InsertHeroPromotionRestoration(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotRestorationEquipment != wantRestorationEquipment || gotRestorationFractions != wantRestorationFractions || gotRestorationDenominations != wantRestorationDenominations {
				return fmt.Errorf("content registry: Hero promotion restoration insert counts equipment=%d/%d fractions=%d/%d denominations=%d/%d", gotRestorationEquipment, wantRestorationEquipment, gotRestorationFractions, wantRestorationFractions, gotRestorationDenominations, wantRestorationDenominations)
			}
			gotPetEquipment, err := s.Repo.InsertPetEquipment(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotPetEquipment != wantPetEquipment {
				return fmt.Errorf("content registry: Pet equipment insert count=%d want=%d", gotPetEquipment, wantPetEquipment)
			}
			gotPetRestorationEquipment, err := s.Repo.InsertPetPromotionRestoration(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotPetRestorationEquipment != wantPetRestorationEquipment {
				return fmt.Errorf("content registry: Pet promotion restoration insert count=%d want=%d", gotPetRestorationEquipment, wantPetRestorationEquipment)
			}
			gotPractice, err := s.Repo.InsertPractice(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotPractice != wantPractice {
				return fmt.Errorf("content registry: Practice insert count=%d want=%d", gotPractice, wantPractice)
			}
			gotAppearance, err := s.Repo.InsertAppearance(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotAppearance != wantAppearance {
				return fmt.Errorf("content registry: appearance insert count=%d want=%d", gotAppearance, wantAppearance)
			}
			gotBook, err := s.Repo.InsertBookInputs(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotBook != 1 {
				return errors.New("content registry: Book payload count drift")
			}
			gotDorm, err := s.Repo.InsertDormInputs(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotDorm != 1 {
				return errors.New("content registry: Dorm payload count drift")
			}
			gotLibrary, err := s.Repo.InsertLibraryInputs(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotLibrary != 1 {
				return errors.New("content registry: library payload count drift")
			}
			gotDisplay, err := s.Repo.InsertPlayerDisplay(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotDisplay != 1 {
				return errors.New("content registry: display count drift")
			}
			gotShowcase, err := s.Repo.InsertPublicShowcase(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotShowcase != 1 {
				return errors.New("content registry: showcase payload count drift")
			}
			gotProfile, err := s.Repo.InsertPublicProfile(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotProfile != 1 {
				return errors.New("content registry: profile payload count drift")
			}
			gotInvite, err := s.Repo.InsertGuildInvite(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotInvite != 1 {
				return errors.New("content registry: Guild Invite payload count drift")
			}
			gotBroadcast, err := s.Repo.InsertGuildBroadcast(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotBroadcast != 1 {
				return errors.New("content registry: Guild broadcast payload count drift")
			}
			gotGift, err := s.Repo.InsertSocialGift(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotGift != 1 {
				return errors.New("content registry: SocialGift payload count drift")
			}
			gotEmoticons, err := s.Repo.InsertEmoticons(tctx, scope.Tx, b)
			if err != nil {
				return err
			}
			if gotEmoticons != 85 {
				return fmt.Errorf("content registry: emoticon count=%d want85", gotEmoticons)
			}
		}
		v, err := s.Repo.VerifyRevision(tctx, scope.Tx, b)
		if err != nil {
			return err
		}
		if !v.Matches(b) {
			return fmt.Errorf("content registry: immutable revision %s failed exact verification (%+v)", b.RevisionID(), v)
		}
		return nil
	})
}

func (s Service) BootstrapActivationIfMissing(ctx context.Context, op operation.Context, b Bundle) (tx.Result, error) {
	var err error
	s, err = s.normalized()
	if err != nil {
		return tx.Result{}, err
	}
	if err := s.validateTarget(b); err != nil {
		return tx.Result{}, err
	}
	resolver := resolverFunc(func(rctx context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
		summary, ok, err := s.Repo.ReadActiveSummary(rctx, s.Fresh)
		if err != nil {
			return tx.Resolution{State: tx.ResolutionUnknown}, err
		}
		if !ok {
			return tx.Resolution{State: tx.ResolutionUnknown, Evidence: "activation absent"}, nil
		}
		if err := s.validateActiveSummary(summary); err != nil {
			return tx.Resolution{State: tx.ResolutionUnknown, Evidence: err.Error()}, nil
		}
		return tx.Resolution{State: tx.ResolutionCommitted, Evidence: summary.Activation}, nil
	})
	res, err := s.Runner.Run(ctx, op, s.Profile, tx.Options{Isolation: tx.Serializable}, s.Retry, resolver, func(tctx context.Context, scope tx.Scope) error {
		if err := s.Repo.LockRegistry(tctx, scope.Tx); err != nil {
			return err
		}
		v, err := s.Repo.VerifyRevision(tctx, scope.Tx, b)
		if err != nil {
			return err
		}
		if !v.Matches(b) {
			return fmt.Errorf("content registry: bootstrap target %s is not exact", b.RevisionID())
		}
		_, err = s.Repo.BootstrapActivation(tctx, scope.Tx, b.RevisionID(), scope.Operation.StartedAt.UTC(), BootstrapActor)
		return err
	})
	if err != nil {
		return res, err
	}
	if _, err := s.ValidateActiveReadiness(ctx); err != nil {
		return res, err
	}
	return res, nil
}

func (s Service) ActivateBuiltin(ctx context.Context, op operation.Context, b Bundle, expected ActivationIdentity, actor string) (tx.Result, error) {
	var err error
	s, err = s.normalized()
	if err != nil {
		return tx.Result{}, err
	}
	if err := s.validateTarget(b); err != nil {
		return tx.Result{}, err
	}
	actor = strings.TrimSpace(actor)
	if actor == "" {
		return tx.Result{}, errors.New("content registry: activation actor required")
	}
	if err := expected.Validate(); err != nil {
		return tx.Result{}, err
	}
	resolver := resolverFunc(func(rctx context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
		cur, ok, err := s.Repo.ReadActivation(rctx, s.Fresh)
		if err != nil {
			return tx.Resolution{State: tx.ResolutionUnknown}, err
		}
		if !ok || cur.RevisionID != b.RevisionID() {
			return tx.Resolution{State: tx.ResolutionUnknown, Evidence: cur}, nil
		}
		v, err := s.Repo.VerifyRevision(rctx, s.Fresh, b)
		if err != nil {
			return tx.Resolution{State: tx.ResolutionUnknown}, err
		}
		if !v.Matches(b) {
			return tx.Resolution{State: tx.ResolutionUnknown, Evidence: "target active but immutable verification failed"}, nil
		}
		return tx.Resolution{State: tx.ResolutionCommitted, Evidence: cur}, nil
	})
	res, err := s.Runner.Run(ctx, op, s.Profile, tx.Options{Isolation: tx.Serializable}, s.Retry, resolver, func(tctx context.Context, scope tx.Scope) error {
		if err := s.Repo.LockRegistry(tctx, scope.Tx); err != nil {
			return err
		}
		cur, ok, err := s.Repo.ReadActivation(tctx, scope.Tx)
		if err != nil {
			return err
		}
		if !ok {
			return errors.New("content registry: activation slot absent; bootstrap required")
		}
		v, err := s.Repo.VerifyRevision(tctx, scope.Tx, b)
		if err != nil {
			return err
		}
		if !v.Matches(b) {
			return fmt.Errorf("content registry: activation target %s is not exact", b.RevisionID())
		}
		if cur.RevisionID == b.RevisionID() {
			return nil
		}
		if cur.RevisionID != expected.RevisionID || cur.Version != expected.Version {
			return ErrStaleActivation
		}
		updated, err := s.Repo.ActivateCAS(tctx, scope.Tx, b.RevisionID(), scope.Operation.StartedAt.UTC(), actor, expected)
		if err != nil {
			return err
		}
		if !updated {
			return ErrStaleActivation
		}
		return nil
	})
	if err != nil {
		return res, err
	}
	if _, err := s.ValidateActiveReadiness(ctx); err != nil {
		return res, err
	}
	return res, nil
}

func (s Service) ValidateActiveReadiness(ctx context.Context) (ActiveSummary, error) {
	var err error
	s, err = s.normalized()
	if err != nil {
		return ActiveSummary{}, err
	}
	summary, ok, err := s.Repo.ReadActiveSummary(ctx, s.Fresh)
	if err != nil {
		return ActiveSummary{}, err
	}
	if !ok {
		return ActiveSummary{}, errors.New("content registry: active content missing")
	}
	if err := s.validateActiveSummary(summary); err != nil {
		return ActiveSummary{}, err
	}
	return summary, nil
}

func (s Service) validateActiveSummary(summary ActiveSummary) error {
	if err := summary.Activation.Validate(); err != nil {
		return err
	}
	if summary.SchemaVersion != builtin.SchemaVersion {
		return fmt.Errorf("content registry: unsupported active schema %d", summary.SchemaVersion)
	}
	m, err := DecodeManifestStrict(summary.ManifestJSON)
	if err != nil {
		return err
	}
	if m.RevisionID != summary.Activation.RevisionID {
		return errors.New("content registry: active manifest/revision mismatch")
	}
	if m.SchemaVersion != summary.SchemaVersion {
		return errors.New("content registry: active manifest/schema mismatch")
	}
	if err := s.Providers.SupportsAll(m.EnabledCapabilities); err != nil {
		return err
	}
	return nil
}

type resolverFunc func(context.Context, tx.ResolutionRequest) (tx.Resolution, error)

func (f resolverFunc) Resolve(ctx context.Context, r tx.ResolutionRequest) (tx.Resolution, error) {
	return f(ctx, r)
}
