package mentor

import "testing"

func TestResolveMissionsHighWaterAndHiddenRows(t *testing.T) {
	missions := []Mission{
		{ID: 100001, GiftID: 90008004, Type: MissionTypeMentor, Category: CategoryGraduated, Condition: 1},
		{ID: 100002, GiftID: 90008005, Type: MissionTypeMentor, Category: CategoryGraduated, Condition: 2},
		{ID: 100005, GiftID: 90008008, Type: MissionTypeMentor, Category: CategoryStudentLevel, Condition: 1000000, IsHide: 1},
		{ID: 100007, GiftID: 90008010, Type: MissionTypeMentor, Category: CategoryStudentLevel, Condition: 30},
		{ID: 100019, GiftID: 90008022, Type: MissionTypeMentor, Category: CategoryBond, Condition: 1000},
		{ID: 100022, GiftID: 90008025, Type: MissionTypeStudent, Category: CategoryJoinClass, Condition: 1},
		{ID: 100023, GiftID: 90008026, Type: MissionTypeStudent, Category: CategoryOwnLevel, Condition: 60},
		{ID: 100025, GiftID: 90008028, Type: MissionTypeStudent, Category: CategoryGraduationTest, Condition: 1},
	}
	mentorStates, err := ResolveMissions(missions, MissionTypeMentor, MissionFacts{Graduated: 2, HighestStudentLevel: 45, HighestBond: 1200})
	if err != nil {
		t.Fatal(err)
	}
	if len(mentorStates) != 4 {
		t.Fatalf("visible mentor missions %d", len(mentorStates))
	}
	byID := map[int64]MissionState{}
	for _, state := range mentorStates {
		byID[state.Mission.ID] = state
	}
	if !byID[100002].Complete || byID[100002].Progress != 2 {
		t.Fatalf("graduated %+v", byID[100002])
	}
	if byID[100007].Progress != 45 || !byID[100007].Complete {
		t.Fatalf("student level %+v", byID[100007])
	}
	if !byID[100019].Complete {
		t.Fatalf("bond %+v", byID[100019])
	}
	if _, hidden := byID[100005]; hidden {
		t.Fatal("hidden mission leaked")
	}
	studentStates, err := ResolveMissions(missions, MissionTypeStudent, MissionFacts{JoinedClass: true, OwnLevel: 60, GraduationTestPassed: true})
	if err != nil {
		t.Fatal(err)
	}
	if len(studentStates) != 3 || !studentStates[0].Complete || !studentStates[1].Complete || !studentStates[2].Complete {
		t.Fatalf("student missions %+v", studentStates)
	}
}

func TestApplyIntimacyDailyAndCap(t *testing.T) {
	if next, changed := ApplyIntimacy(0, 100, 3000, "", "2026-11-07"); next != 100 || !changed {
		t.Fatalf("first day %d %v", next, changed)
	}
	if next, changed := ApplyIntimacy(100, 100, 3000, "2026-11-07", "2026-11-07"); next != 100 || changed {
		t.Fatalf("same day %d %v", next, changed)
	}
	if next, changed := ApplyIntimacy(100, 100, 3000, "2026-11-06", "2026-11-07"); next != 200 || !changed {
		t.Fatalf("next day %d %v", next, changed)
	}
	if next, changed := ApplyIntimacy(2950, 100, 3000, "2026-11-06", "2026-11-07"); next != 3000 || !changed {
		t.Fatalf("cap %d %v", next, changed)
	}
}
