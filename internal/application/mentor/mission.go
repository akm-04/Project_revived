package mentor

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func deriveMissions(catalog builtin.MentorInputCatalog, actor identity.PlayerID, level int64, relations []domain.Relationship, progress []MissionProgress, at time.Time) ([]domain.MissionState, []domain.MissionState, error) {
	missions := missionsFromCatalog(catalog)
	stored := make(map[int64]MissionProgress, len(progress))
	for _, row := range progress {
		stored[row.MissionID] = row
	}
	mentorFacts := domain.MissionFacts{}
	studentFacts := domain.MissionFacts{OwnLevel: level}
	for _, row := range progress {
		mission, ok := missionByID(missions, row.MissionID)
		if !ok {
			continue
		}
		switch mission.Category {
		case domain.CategoryGraduated:
			mentorFacts.Graduated = domain.AdvanceHighWater(mentorFacts.Graduated, row.Progress)
		case domain.CategoryStudentLevel:
			mentorFacts.HighestStudentLevel = domain.AdvanceHighWater(mentorFacts.HighestStudentLevel, row.Progress)
		case domain.CategoryStudentBG:
			mentorFacts.HighestStudentBGs = domain.AdvanceHighWater(mentorFacts.HighestStudentBGs, row.Progress)
		case domain.CategoryBond:
			mentorFacts.HighestBond = domain.AdvanceHighWater(mentorFacts.HighestBond, row.Progress)
		case domain.CategoryJoinClass:
			studentFacts.JoinedClass = studentFacts.JoinedClass || row.Progress > 0
		case domain.CategoryGraduationTest:
			studentFacts.GraduationTestPassed = studentFacts.GraduationTestPassed || row.Progress > 0
		}
	}
	for _, relation := range relations {
		if relation.Student == actor {
			studentFacts.JoinedClass = true
		}
	}
	mentorStates, err := domain.ResolveMissions(missions, domain.MissionTypeMentor, mentorFacts)
	if err != nil {
		return nil, nil, err
	}
	studentStates, err := domain.ResolveMissions(missions, domain.MissionTypeStudent, studentFacts)
	if err != nil {
		return nil, nil, err
	}
	applyStored := func(states []domain.MissionState) {
		for index := range states {
			if row, ok := stored[states[index].Mission.ID]; ok {
				if row.Progress > states[index].Progress {
					states[index].Progress = row.Progress
					states[index].Complete = row.Progress >= states[index].Mission.Condition
				}
				if row.AwardedAt != nil {
					states[index].Awarded = true
					states[index].AwardedAt = row.AwardedAt
				}
			}
		}
	}
	applyStored(mentorStates)
	applyStored(studentStates)
	return mentorStates, studentStates, nil
}

func missionByID(missions []domain.Mission, identifier int64) (domain.Mission, bool) {
	for _, mission := range missions {
		if mission.ID == identifier {
			return mission, true
		}
	}
	return domain.Mission{}, false
}

// advanceMissionCategoryTx moves every visible mission of one category to at
// least candidate and records completion. High-water never regresses.
func advanceMissionCategoryTx(ctx context.Context, t tx.Tx, store Store, player identity.PlayerID, missions []domain.Mission, missionType, category, candidate int64, at time.Time) error {
	if candidate < 0 {
		return domain.ErrMission
	}
	for _, mission := range domain.MissionsForCategories(missions, missionType, category) {
		if err := advanceMissionTx(ctx, t, store, player, mission, candidate, at); err != nil {
			return err
		}
	}
	return nil
}

func advanceMissionTx(ctx context.Context, t tx.Tx, store Store, player identity.PlayerID, mission domain.Mission, candidate int64, at time.Time) error {
	previous, found, err := store.LockMissionProgressTx(ctx, t, player, mission.ID)
	if err != nil {
		return err
	}
	next := previous
	if !found {
		next = MissionProgress{PlayerID: player, MissionID: mission.ID, Version: 1}
	} else {
		next.Version = advance(previous.Version)
	}
	progress := domain.AdvanceHighWater(next.Progress, candidate)
	changed := !found || progress != next.Progress
	next.Progress = progress
	if progress >= mission.Condition && next.CompletedAt == nil {
		completed := at.UTC()
		next.CompletedAt = &completed
		changed = true
	}
	if !changed {
		return nil
	}
	var previousPointer *MissionProgress
	if found {
		previousCopy := previous
		previousPointer = &previousCopy
	}
	return store.PutMissionProgressTx(ctx, t, previousPointer, next)
}

func completedMissionTx(ctx context.Context, t tx.Tx, store Store, player identity.PlayerID, mission domain.Mission, progress int64, at time.Time) (MissionProgress, bool, error) {
	if progress < mission.Condition {
		return MissionProgress{}, false, nil
	}
	previous, found, err := store.LockMissionProgressTx(ctx, t, player, mission.ID)
	if err != nil {
		return MissionProgress{}, false, err
	}
	next := previous
	if !found {
		next = MissionProgress{PlayerID: player, MissionID: mission.ID, Version: 1}
	} else {
		next.Version = advance(previous.Version)
	}
	next.Progress = domain.AdvanceHighWater(next.Progress, progress)
	if next.CompletedAt == nil {
		completed := at.UTC()
		next.CompletedAt = &completed
	}
	if !found || next.Progress != previous.Progress || next.CompletedAt != previous.CompletedAt {
		var previousPointer *MissionProgress
		if found {
			previousCopy := previous
			previousPointer = &previousCopy
		}
		if err := store.PutMissionProgressTx(ctx, t, previousPointer, next); err != nil {
			return MissionProgress{}, false, err
		}
	}
	return next, true, nil
}
