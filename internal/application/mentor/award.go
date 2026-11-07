package mentor

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	giftOperation    = "mission_award"
	examOperation    = "graduation_exam"
	examFightRefusal = 30005
)

// Claim implements MID 1862 GET_CLASS_MISSION_AWARD.
func (service Service) Claim(ctx context.Context, actor identity.ActorContext, missionID int64, op operation.Context) (map[string]any, error) {
	if !service.validForMutation() || missionID <= 0 || service.Grants == nil {
		return nil, ErrInvalid
	}
	catalog, err := service.catalog()
	if err != nil {
		return nil, err
	}
	missions := missionsFromCatalog(catalog)
	mission, ok := missionByID(missions, missionID)
	if !ok || mission.IsHide != 0 {
		return nil, refusal(34010)
	}
	var body map[string]any
	err = service.run(ctx, actor, op, true, func(ctx context.Context, t tx.Tx, at time.Time) error {
		players := []identity.PlayerID{actor.PlayerID}
		if missionID == catalog.Rules.FinishMissionID {
			existing, err := service.Store.ReadRelationshipsTx(ctx, t, actor.PlayerID, actor.LogicalServerID)
			if err != nil {
				return err
			}
			for _, relation := range existing {
				if relation.Student == actor.PlayerID {
					players = append(players, relation.Mentor)
				}
			}
		}
		if err := lockPlayerRoots(ctx, service.Players, t, actor.LogicalServerID, players...); err != nil {
			return err
		}
		level, err := playerLevel(ctx, service.Directory, t, actor.PlayerID)
		if err != nil {
			return err
		}
		progress, found, err := service.Store.LockMissionProgressTx(ctx, t, actor.PlayerID, missionID)
		if err != nil {
			return err
		}
		if found && progress.AwardedAt != nil {
			return refusal(33002)
		}
		complete, err := service.missionCompleteTx(ctx, t, actor.PlayerID, level, mission, progress, found, catalog, at)
		if err != nil {
			return err
		}
		if !complete {
			return refusal(1)
		}
		var mentorRelation *domain.Relationship
		if missionID == catalog.Rules.FinishMissionID {
			relations, err := service.Store.LockRelationshipsTx(ctx, t, actor.PlayerID, actor.LogicalServerID)
			if err != nil {
				return err
			}
			for index := range relations {
				if relations[index].Student == actor.PlayerID {
					mentorRelation = &relations[index]
					break
				}
			}
			if mentorRelation == nil {
				return refusal(34004)
			}
		}
		next := progress
		if !found {
			next = MissionProgress{PlayerID: actor.PlayerID, MissionID: missionID, Version: 1}
		} else {
			next.Version = advance(progress.Version)
		}
		next.Progress = domain.AdvanceHighWater(next.Progress, progressValue(mission, level, complete))
		if next.CompletedAt == nil {
			completed := at.UTC()
			next.CompletedAt = &completed
		}
		awarded := at.UTC()
		next.AwardedAt = &awarded
		var previousPointer *MissionProgress
		if found {
			previousCopy := progress
			previousPointer = &previousCopy
		}
		if err := service.Store.PutMissionProgressTx(ctx, t, previousPointer, next); err != nil {
			return err
		}
		gift, ok := giftFor(catalog, mission.GiftID)
		if !ok {
			return ErrUnavailable
		}
		plan := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "mentor", Operation: giftOperation, BusinessKey: fmt.Sprintf("%d:%d", int64(actor.PlayerID), missionID), PolicyVersion: MentorPolicyVersion}, Lines: giftLines(gift)}
		if plan.Validate() != nil {
			return ErrInvalid
		}
		result, err := service.Grants.SettleGrantTx(ctx, t, actor, plan, op, i5.GrantTxOptions{AllowOverflowMail: true})
		if err != nil {
			return err
		}
		if mentorRelation != nil {
			if err := service.graduateTx(ctx, t, catalog, *mentorRelation, at); err != nil {
				return err
			}
		}
		body = map[string]any{"awards": i5.StockRepresentableBulkAwards(result.Awards)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return body, nil
}

func (service Service) missionCompleteTx(ctx context.Context, t tx.Tx, player identity.PlayerID, level int64, mission domain.Mission, progress MissionProgress, found bool, catalog Catalog, at time.Time) (bool, error) {
	switch mission.Type {
	case domain.MissionTypeMentor:
		if !found {
			return false, nil
		}
		return progress.Progress >= mission.Condition, nil
	case domain.MissionTypeStudent:
		switch mission.Category {
		case domain.CategoryJoinClass:
			if found && progress.Progress >= mission.Condition {
				return true, nil
			}
			relations, err := service.Store.LockRelationshipsTx(ctx, t, player, identity.LogicalServerID(player/100000))
			if err != nil {
				return false, err
			}
			for _, relation := range relations {
				if relation.Student == player {
					return true, nil
				}
			}
			return false, nil
		case domain.CategoryOwnLevel:
			return level >= mission.Condition, nil
		case domain.CategoryGraduationTest:
			_, ok, err := service.Store.ReadExamReceiptTx(ctx, t, player, mission.ID)
			if err != nil {
				return false, err
			}
			return ok, nil
		}
	}
	return false, nil
}

func progressValue(mission domain.Mission, level int64, complete bool) int64 {
	switch mission.Category {
	case domain.CategoryOwnLevel:
		return level
	}
	if complete {
		return mission.Condition
	}
	return 0
}

func giftFor(catalog Catalog, giftID int64) (CatalogGift, bool) {
	for _, gift := range catalog.Gifts {
		if gift.ID == giftID {
			return gift, true
		}
	}
	return CatalogGift{}, false
}

func giftLines(gift CatalogGift) []grant.Line {
	lines := make([]grant.Line, 0, len(gift.Items)+2)
	if gift.Crystal > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: gift.Crystal})
	}
	if gift.Exp > 0 {
		lines = append(lines, grant.Line{Kind: grant.PlayerExp, Amount: gift.Exp})
	}
	for _, item := range gift.Items {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item.ItemID, Amount: item.Quantity})
	}
	return lines
}

// graduateTx records the mentor's graduated-student high-water and ends the
// relation. The graduate keeps no cooldown (D466/D508).
func (service Service) graduateTx(ctx context.Context, t tx.Tx, catalog Catalog, relation domain.Relationship, at time.Time) error {
	if err := service.sampleStudentFactsTx(ctx, t, catalog, rulesFromCatalog(catalog), relation, at); err != nil {
		return err
	}
	missions := missionsFromCatalog(catalog)
	graduated := int64(1)
	anchor, found, err := service.Store.LockMissionProgressTx(ctx, t, relation.Mentor, 100001)
	if err != nil {
		return err
	}
	if found {
		graduated = anchor.Progress + 1
	}
	if err := advanceMissionCategoryTx(ctx, t, service.Store, relation.Mentor, missions, domain.MissionTypeMentor, domain.CategoryGraduated, graduated, at); err != nil {
		return err
	}
	return service.Store.EndRelationshipTx(ctx, t, relation, at)
}

// Exam implements MID 1863 STUDENT_OVER_FIGHT_RESULT. The win is client-reported
// (D508); a terminal receipt makes the result idempotent.
func (service Service) Exam(ctx context.Context, actor identity.ActorContext, isWin int64, op operation.Context) (map[string]any, error) {
	if !service.validForMutation() || isWin != 1 || service.Grants == nil {
		return nil, ErrInvalid
	}
	catalog, err := service.catalog()
	if err != nil {
		return nil, err
	}
	mission, ok := missionByID(missionsFromCatalog(catalog), catalog.Rules.FinishMissionID)
	if !ok {
		return nil, ErrUnavailable
	}
	var body map[string]any
	err = service.run(ctx, actor, op, true, func(ctx context.Context, t tx.Tx, at time.Time) error {
		if err := lockPlayerRoots(ctx, service.Players, t, actor.LogicalServerID, actor.PlayerID); err != nil {
			return err
		}
		_, found, err := service.Store.LockExamReceiptTx(ctx, t, actor.PlayerID, mission.ID)
		if err != nil {
			return err
		}
		if found {
			return refusal(examFightRefusal)
		}
		relations, err := service.Store.LockRelationshipsTx(ctx, t, actor.PlayerID, actor.LogicalServerID)
		if err != nil {
			return err
		}
		var relation *domain.Relationship
		for index := range relations {
			if relations[index].Student == actor.PlayerID {
				relation = &relations[index]
				break
			}
		}
		if relation == nil {
			return refusal(34004)
		}
		level, err := playerLevel(ctx, service.Directory, t, actor.PlayerID)
		if err != nil {
			return err
		}
		if level < mission.Level {
			return refusal(34011)
		}
		plan := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "mentor", Operation: examOperation, BusinessKey: fmt.Sprintf("%d:%d", int64(actor.PlayerID), mission.ID), PolicyVersion: MentorPolicyVersion}, Lines: examLines(catalog.Exam.Items)}
		if plan.Validate() != nil {
			return ErrInvalid
		}
		result, err := service.Grants.SettleGrantTx(ctx, t, actor, plan, op, i5.GrantTxOptions{AllowOverflowMail: true})
		if err != nil {
			return err
		}
		items := make([]ExamItem, 0, len(catalog.Exam.Items))
		for _, item := range catalog.Exam.Items {
			items = append(items, ExamItem{ItemID: item.ItemID, Quantity: item.Quantity})
		}
		if err := service.Store.InsertExamReceiptTx(ctx, t, ExamReceipt{StudentID: actor.PlayerID, MissionID: mission.ID, RelationID: relation.ID, WonAt: at.UTC(), Items: items, Version: 1}); err != nil {
			return err
		}
		if _, _, err := completedMissionTx(ctx, t, service.Store, actor.PlayerID, mission, 1, at); err != nil {
			return err
		}
		body = map[string]any{"items": i5.StockMID369Rewards(result.Awards)}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return body, nil
}

func examLines(items []CatalogGiftItem) []grant.Line {
	lines := make([]grant.Line, 0, len(items))
	for _, item := range items {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item.ItemID, Amount: item.Quantity})
	}
	return lines
}
