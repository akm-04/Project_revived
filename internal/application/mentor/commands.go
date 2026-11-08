package mentor

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Apply implements MID 1857 APPLY_RELATION.
func (service Service) Apply(ctx context.Context, actor identity.ActorContext, target identity.PlayerID, relationType int64, message string, op operation.Context) (map[string]any, error) {
	if !service.validForMutation() || !target.Valid() || target == actor.PlayerID || relationType != 1 && relationType != 2 {
		return nil, ErrInvalid
	}
	if logicalserver.PlayerRegion(target) != actor.LogicalServerID {
		return nil, refusal(34018)
	}
	catalog, err := service.catalog()
	if err != nil {
		return nil, err
	}
	rules := rulesFromCatalog(catalog)
	var body map[string]any
	err = service.runReceipted(ctx, actor, op, "apply", map[string]any{"target": int64(target), "relation_type": relationType, "message": message}, &body, func(ctx context.Context, t tx.Tx, at time.Time) error {
		if err := lockPlayerRoots(ctx, service.Players, t, actor.LogicalServerID, actor.PlayerID, target); err != nil {
			return err
		}
		state, err := service.Store.LockStateTx(ctx, t, actor.PlayerID, actor.LogicalServerID, at)
		if err != nil {
			return err
		}
		actorLevel, err := playerLevel(ctx, service.Directory, t, actor.PlayerID)
		if err != nil {
			return err
		}
		targetProfile, found, err := service.Directory.ProfileTx(ctx, t, target)
		if err != nil {
			return err
		}
		if !found {
			return refusal(34014)
		}
		if domain.BreakCooldownActive(rules, state.BrokeAt, at) {
			return refusal(34002)
		}
		actorRelations, err := service.Store.LockRelationshipsTx(ctx, t, actor.PlayerID, actor.LogicalServerID)
		if err != nil {
			return err
		}
		targetRelations, err := service.Store.LockRelationshipsTx(ctx, t, target, actor.LogicalServerID)
		if err != nil {
			return err
		}
		candidateState, err := service.Store.CandidateStatesTx(ctx, t, actor.LogicalServerID, []identity.PlayerID{target})
		if err != nil {
			return err
		}
		targetState := candidateState[target]
		if domain.BreakCooldownActive(rules, targetState.BrokeAt, at) {
			return refusal(34003)
		}
		if relationType == 1 && hasSlot(actorRelations, actor.PlayerID, domain.SlotMentor) {
			return refusal(34015)
		}
		if relationType == 2 && hasSlot(actorRelations, actor.PlayerID, domain.SlotStudent) {
			return refusal(34016)
		}
		plan, err := domain.PlanApplication(domain.ApplicationFacts{
			Applicant:         domain.PlayerState{PlayerID: actor.PlayerID, LogicalServerID: actor.LogicalServerID, AcademyLevel: actorLevel},
			Recipient:         domain.PlayerState{PlayerID: target, LogicalServerID: actor.LogicalServerID, AcademyLevel: targetProfile.Level},
			ApplicantGateOpen: true, RecipientGateOpen: true, Seeking: domain.Slot(relationType),
		}, rules)
		if err != nil {
			studentLevel := actorLevel
			if relationType == 2 {
				studentLevel = targetProfile.Level
			}
			return applicationRefusal(err, studentLevel, rules)
		}
		_ = targetRelations
		application, exists, err := service.Store.LockApplicationTx(ctx, t, actor.PlayerID, target)
		if err != nil {
			return err
		}
		if exists && application.Status == ApplicationPending && application.ExpiresAt.After(at) {
			return refusal(34010)
		}
		next := Application{Applicant: actor.PlayerID, Target: target, Server: actor.LogicalServerID, RecipientSlot: plan.RecipientSlot, Message: message, CreatedAt: at.UTC(), ExpiresAt: at.UTC().Add(rules.ApplicationTTL), Status: ApplicationPending, Version: 1}
		count := int64(0)
		if relationType == 1 {
			count = state.CountMentor
		} else {
			count = state.CountStudent
		}
		if !sameDay(state.ApplyDay, at) {
			count = 0
		}
		if !domain.UnderDailyLimit(rules, count) {
			return refusal(34008)
		}
		updated := state
		updated.ApplyDay = at.UTC()
		updated.CountMentor = state.CountMentor
		updated.CountStudent = state.CountStudent
		if !sameDay(state.ApplyDay, at) {
			updated.CountMentor = 0
			updated.CountStudent = 0
		}
		if relationType == 1 {
			updated.CountMentor++
		} else {
			updated.CountStudent++
		}
		updated.Version = advance(state.Version)
		if err := service.Store.WriteStateTx(ctx, t, state, updated); err != nil {
			return err
		}
		var previous *Application
		if exists {
			previousCopy := application
			previous = &previousCopy
			next.Version = advance(application.Version)
		}
		if err := service.Store.PutApplicationTx(ctx, t, previous, next); err != nil {
			return err
		}
		facts, err := service.readClassFacts(ctx, t, actor.PlayerID, at, catalog, rules)
		if err != nil {
			return err
		}
		body = BuildClassInfo(facts)
		return nil
	})
	if err != nil {
		return nil, err
	}
	return body, nil
}

// Accept implements MID 1859 ACCEPT_TEACH_APPLY.
func (service Service) Accept(ctx context.Context, actor identity.ActorContext, from identity.PlayerID, op operation.Context) (map[string]any, error) {
	if !service.validForMutation() || !from.Valid() || from == actor.PlayerID {
		return nil, ErrInvalid
	}
	catalog, err := service.catalog()
	if err != nil {
		return nil, err
	}
	rules := rulesFromCatalog(catalog)
	var body map[string]any
	err = service.runReceipted(ctx, actor, op, "accept", map[string]any{"from": int64(from)}, &body, func(ctx context.Context, t tx.Tx, at time.Time) error {
		if err := lockPlayerRoots(ctx, service.Players, t, actor.LogicalServerID, actor.PlayerID, from); err != nil {
			return err
		}
		if _, err := service.Friendships.EnsureFriendshipTx(ctx, t, actor.PlayerID, from, at); err != nil {
			return err
		}
		actorState, err := service.Store.LockStateTx(ctx, t, actor.PlayerID, actor.LogicalServerID, at)
		if err != nil {
			return err
		}
		applicantState, err := service.Store.LockStateTx(ctx, t, from, actor.LogicalServerID, at)
		if err != nil {
			return err
		}
		actorLevel, err := playerLevel(ctx, service.Directory, t, actor.PlayerID)
		if err != nil {
			return err
		}
		applicantLevel, err := playerLevel(ctx, service.Directory, t, from)
		if err != nil {
			return err
		}
		if domain.BreakCooldownActive(rules, actorState.BrokeAt, at) {
			return refusal(34002)
		}
		if domain.BreakCooldownActive(rules, applicantState.BrokeAt, at) {
			return refusal(34003)
		}
		application, found, err := service.Store.LockApplicationTx(ctx, t, from, actor.PlayerID)
		if err != nil {
			return err
		}
		if !found || application.Status != ApplicationPending {
			return refusal(34010)
		}
		if !application.ExpiresAt.After(at) {
			return refusal(34002)
		}
		actorRelations, err := service.Store.LockRelationshipsTx(ctx, t, actor.PlayerID, actor.LogicalServerID)
		if err != nil {
			return err
		}
		applicantRelations, err := service.Store.LockRelationshipsTx(ctx, t, from, actor.LogicalServerID)
		if err != nil {
			return err
		}
		if hasSlot(actorRelations, actor.PlayerID, application.RecipientSlot) {
			return refusal(34004)
		}
		applicantSlot := domain.Slot(0)
		if application.RecipientSlot == domain.SlotMentor {
			applicantSlot = domain.SlotStudent
		} else {
			applicantSlot = domain.SlotMentor
		}
		if hasSlot(applicantRelations, from, applicantSlot) {
			return refusal(34005)
		}
		plan, err := domain.PlanApplication(domain.ApplicationFacts{
			Applicant:         domain.PlayerState{PlayerID: from, LogicalServerID: actor.LogicalServerID, AcademyLevel: applicantLevel},
			Recipient:         domain.PlayerState{PlayerID: actor.PlayerID, LogicalServerID: actor.LogicalServerID, AcademyLevel: actorLevel},
			ApplicantGateOpen: true, RecipientGateOpen: true, Seeking: applicantSlot,
		}, rules)
		if err != nil {
			studentLevel := applicantLevel
			if applicantSlot == domain.SlotStudent {
				studentLevel = actorLevel
			}
			return applicationRefusal(err, studentLevel, rules)
		}
		revision, err := service.Content.ActiveRevision(ctx, t)
		if err != nil || len(revision) != 64 {
			return ErrUnavailable
		}
		relationID, err := ids.NewUUID()
		if err != nil {
			return err
		}
		baseline := int64(0)
		if service.Backgrounds != nil {
			baseline, err = service.Backgrounds.BackgroundCountTx(ctx, t, plan.Student)
			if err != nil {
				return err
			}
		}
		relation := domain.Relationship{ID: relationID, Mentor: plan.Mentor, Student: plan.Student, Server: actor.LogicalServerID, ContentRevision: revision, PolicyVersion: MentorPolicyVersion, AcceptedAt: at.UTC(), Version: 1, BackgroundBaseline: baseline}
		if relation.Validate() != nil {
			return domain.ErrRelationship
		}
		if err := service.Store.InsertRelationshipTx(ctx, t, relation); err != nil {
			return err
		}
		accepted := application
		accepted.Status = ApplicationAccepted
		accepted.Version = advance(application.Version)
		previous := application
		if err := service.Store.PutApplicationTx(ctx, t, &previous, accepted); err != nil {
			return err
		}
		missions := missionsFromCatalog(catalog)
		studentLevel := applicantLevel
		if plan.Student == actor.PlayerID {
			studentLevel = actorLevel
		}
		if err := advanceMissionCategoryTx(ctx, t, service.Store, plan.Mentor, missions, domain.MissionTypeMentor, domain.CategoryStudentLevel, studentLevel, at); err != nil {
			return err
		}
		joinMissions := domain.MissionsForCategories(missions, domain.MissionTypeStudent, domain.CategoryJoinClass)
		if len(joinMissions) == 1 {
			if _, _, err := completedMissionTx(ctx, t, service.Store, plan.Student, joinMissions[0], 1, at); err != nil {
				return err
			}
		}
		facts, err := service.readClassFacts(ctx, t, actor.PlayerID, at, catalog, rules)
		if err != nil {
			return err
		}
		body = BuildClassInfo(facts)
		return nil
	})
	if err != nil {
		return nil, err
	}
	return body, nil
}

// Deny implements MID 1860 DENY_TEACH_APPLY.
func (service Service) Deny(ctx context.Context, actor identity.ActorContext, from identity.PlayerID, denyAll bool, op operation.Context) (map[string]any, error) {
	if !service.validForMutation() || (!denyAll && (!from.Valid() || from == actor.PlayerID)) {
		return map[string]any{}, ErrInvalid
	}
	body := map[string]any{}
	err := service.runReceipted(ctx, actor, op, "deny", map[string]any{"from": int64(from), "deny_all": denyAll}, &body, func(ctx context.Context, t tx.Tx, at time.Time) error {
		players := []identity.PlayerID{actor.PlayerID}
		if !denyAll {
			players = append(players, from)
		}
		if err := lockPlayerRoots(ctx, service.Players, t, actor.LogicalServerID, players...); err != nil {
			return err
		}
		targets := []identity.PlayerID{from}
		if denyAll {
			applications, err := service.Store.ListApplicationsToTx(ctx, t, actor.PlayerID, actor.LogicalServerID, at)
			if err != nil {
				return err
			}
			targets = targets[:0]
			for _, application := range applications {
				targets = append(targets, application.Applicant)
			}
		}
		for _, applicant := range targets {
			application, found, err := service.Store.LockApplicationTx(ctx, t, applicant, actor.PlayerID)
			if err != nil {
				return err
			}
			if !found || application.Status != ApplicationPending {
				if denyAll {
					continue
				}
				return refusal(34010)
			}
			next := application
			next.Status = ApplicationDenied
			next.Version = advance(application.Version)
			previous := application
			if err := service.Store.PutApplicationTx(ctx, t, &previous, next); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return body, nil
}

// Terminate implements MID 1861 TERMINATE_RELATION. Only the raiser is punished.
func (service Service) Terminate(ctx context.Context, actor identity.ActorContext, relationType int64, op operation.Context) (map[string]any, error) {
	if !service.validForMutation() || relationType != 1 && relationType != 2 {
		return nil, ErrInvalid
	}
	catalog, err := service.catalog()
	if err != nil {
		return nil, err
	}
	rules := rulesFromCatalog(catalog)
	var body map[string]any
	err = service.runReceipted(ctx, actor, op, "terminate", map[string]any{"relation_type": relationType}, &body, func(ctx context.Context, t tx.Tx, at time.Time) error {
		existing, err := service.Store.ReadRelationshipsTx(ctx, t, actor.PlayerID, actor.LogicalServerID)
		if err != nil {
			return err
		}
		relation, found := relationForSlot(existing, actor.PlayerID, domain.Slot(relationType))
		if !found {
			return refusal(34010)
		}
		other := relation.Mentor
		if other == actor.PlayerID {
			other = relation.Student
		}
		if err := lockPlayerRoots(ctx, service.Players, t, actor.LogicalServerID, actor.PlayerID, other); err != nil {
			return err
		}
		state, err := service.Store.LockStateTx(ctx, t, actor.PlayerID, actor.LogicalServerID, at)
		if err != nil {
			return err
		}
		relations, err := service.Store.LockRelationshipsTx(ctx, t, actor.PlayerID, actor.LogicalServerID)
		if err != nil {
			return err
		}
		locked, found := relationForSlot(relations, actor.PlayerID, domain.Slot(relationType))
		if !found {
			return refusal(34010)
		}
		if !domain.TerminateAllowed(rules, locked.AcceptedAt, at) {
			return refusal(34012)
		}
		if err := service.Store.EndRelationshipTx(ctx, t, locked, at); err != nil {
			return err
		}
		updated := state
		updated.BrokeAt = utcTime(at)
		updated.Version = advance(state.Version)
		if err := service.Store.WriteStateTx(ctx, t, state, updated); err != nil {
			return err
		}
		if err := service.sampleStudentFactsTx(ctx, t, catalog, rules, locked, at); err != nil {
			return err
		}
		facts, err := service.readClassFacts(ctx, t, actor.PlayerID, at, catalog, rules)
		if err != nil {
			return err
		}
		body = BuildClassInfo(facts)
		return nil
	})
	if err != nil {
		return nil, err
	}
	return body, nil
}

func (service Service) sampleStudentFactsTx(ctx context.Context, t tx.Tx, catalog Catalog, rules domain.Rules, relation domain.Relationship, at time.Time) error {
	missions := missionsFromCatalog(catalog)
	studentLevel, err := playerLevel(ctx, service.Directory, t, relation.Student)
	if err != nil {
		return err
	}
	if err := advanceMissionCategoryTx(ctx, t, service.Store, relation.Mentor, missions, domain.MissionTypeMentor, domain.CategoryStudentLevel, studentLevel, at); err != nil {
		return err
	}
	if err := advanceMissionCategoryTx(ctx, t, service.Store, relation.Mentor, missions, domain.MissionTypeMentor, domain.CategoryBond, relation.Intimacy, at); err != nil {
		return err
	}
	if service.Backgrounds == nil {
		return nil
	}
	current, err := service.Backgrounds.BackgroundCountTx(ctx, t, relation.Student)
	if err != nil {
		return err
	}
	added := current - relation.BackgroundBaseline
	if added < 0 {
		added = 0
	}
	return advanceMissionCategoryTx(ctx, t, service.Store, relation.Mentor, missions, domain.MissionTypeMentor, domain.CategoryStudentBG, added, at)
}

func applicationRefusal(err error, studentLevel int64, rules domain.Rules) error {
	switch {
	case errors.Is(err, domain.ErrServerMismatch):
		return refusal(34018)
	case errors.Is(err, domain.ErrSamePersonBothRoles):
		return refusal(34019)
	case errors.Is(err, domain.ErrSlotFilled):
		return refusal(34005)
	case errors.Is(err, domain.ErrLevel):
		if studentLevel >= rules.StudentLevelLimit {
			return refusal(34001)
		}
		return refusal(34009)
	default:
		return ErrInvalid
	}
}

func hasSlot(relations []domain.Relationship, player identity.PlayerID, slot domain.Slot) bool {
	_, found := relationForSlot(relations, player, slot)
	return found
}

func relationForSlot(relations []domain.Relationship, player identity.PlayerID, slot domain.Slot) (domain.Relationship, bool) {
	for _, relation := range relations {
		if slot == domain.SlotMentor && relation.Student == player || slot == domain.SlotStudent && relation.Mentor == player {
			return relation, true
		}
	}
	return domain.Relationship{}, false
}

func utcTime(at time.Time) *time.Time {
	utc := at.UTC()
	return &utc
}
