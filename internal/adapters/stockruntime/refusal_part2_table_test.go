package stockruntime

import (
	"errors"
	"net/http"
	"testing"

	appachievement "gxb.local/backend/v2/internal/application/achievement"
	apparena "gxb.local/backend/v2/internal/application/arena"
	"gxb.local/backend/v2/internal/application/characterasset"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	appsavedpreset "gxb.local/backend/v2/internal/application/charactersavedpreset"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	appelement "gxb.local/backend/v2/internal/application/elementequipment"
	appevolution "gxb.local/backend/v2/internal/application/heroevolution"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	appinscription "gxb.local/backend/v2/internal/application/inscription"
	applibrary "gxb.local/backend/v2/internal/application/librarylocal"
	appspirit "gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/elementequipment"
	"gxb.local/backend/v2/internal/domain/heroevolution"
	"gxb.local/backend/v2/internal/domain/inscription"
	"gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/domain/spirit"
	"gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type part2FailureCase struct {
	name      string
	got       httpedge.Response
	want      int
	code      int64
	errorBody string
}

func assertPart2FailureCases(t *testing.T, cases []part2FailureCase) {
	t.Helper()
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if tc.got.HTTPStatus != tc.want {
				t.Fatalf("status=%d want=%d body=%#v", tc.got.HTTPStatus, tc.want, tc.got.Body)
			}
			if tc.code != 0 {
				if tc.got.Body["error_code"] != tc.code {
					t.Fatalf("error_code=%#v want=%d", tc.got.Body["error_code"], tc.code)
				}
				if tc.got.Body["error_msg"] != "" {
					t.Fatalf("error_msg=%#v want empty", tc.got.Body["error_msg"])
				}
				return
			}
			if tc.want == http.StatusBadRequest {
				if tc.got.Body["error_code"] != unprovenRefusalCode {
					t.Fatalf("malformed error_code=%#v want=%d", tc.got.Body["error_code"], unprovenRefusalCode)
				}
				if tc.got.Body["error_msg"] != "" {
					t.Fatalf("malformed error_msg=%#v want empty", tc.got.Body["error_msg"])
				}
				if tc.errorBody != "" && tc.got.Body["error"] != tc.errorBody {
					t.Fatalf("error=%#v want=%q", tc.got.Body["error"], tc.errorBody)
				}
				return
			}
			if _, hasCode := tc.got.Body["error_code"]; hasCode {
				t.Fatalf("unexpected error_code in %#v", tc.got.Body)
			}
			if tc.errorBody != "" && tc.got.Body["error"] != tc.errorBody {
				t.Fatalf("error=%#v want=%q", tc.got.Body["error"], tc.errorBody)
			}
		})
	}
}

func TestInsufficientBalanceMapsResourceCodes(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"diamonds", failArena(economy.InsufficientBalance("crystal")), http.StatusConflict, insufficientDiamondCode, ""},
		{"coins", failArena(economy.InsufficientBalance("mana")), http.StatusConflict, insufficientCoinCode, ""},
		{"stamina", failArena(economy.InsufficientBalance("energy")), http.StatusConflict, insufficientStaminaCode, ""},
		{"other resource", failArena(economy.InsufficientBalance("guild_coin")), http.StatusConflict, unprovenRefusalCode, ""},
	})
}

func TestPart2ArenaFailureRows(t *testing.T) {
	fallback := errors.New("arena dependency")
	assertPart2FailureCases(t, []part2FailureCase{
		{"refused", failArena(arena.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"invalid", failArena(arena.ErrInvalid), http.StatusBadRequest, 0, "arena_request_refused"},
		{"closed", failArena(arena.ErrClosed), http.StatusConflict, unprovenRefusalCode, ""},
		{"insufficient", failArena(economy.ErrInsufficientBalance), http.StatusConflict, unprovenRefusalCode, ""},
		{"fallback", failArena(fallback), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
	assertPart2FailureCases(t, []part2FailureCase{
		{"fight no team", failArenaFight(apparena.ErrNoTeam), http.StatusConflict, arenaNoTeamError, ""},
		{"fight refused", failArenaFight(arena.ErrRefused), http.StatusConflict, arenaMatchRefusedError, ""},
		{"fight closed", failArenaFight(arena.ErrClosed), http.StatusConflict, arenaClosedError, ""},
		{"fight insufficient", failArenaFight(economy.ErrInsufficientBalance), http.StatusConflict, unprovenRefusalCode, ""},
		{"fight invalid", failArenaFight(arena.ErrInvalid), http.StatusBadRequest, 0, "arena_request_refused"},
		{"fight fallback", failArenaFight(fallback), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart2ConquerLeagueFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"conquer refused", failConquer(conquerschool.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"conquer invalid", failConquer(conquerschool.ErrInvalid), http.StatusBadRequest, 0, "conquer_request_refused"},
		{"conquer insufficient", failConquer(economy.ErrInsufficientBalance), http.StatusConflict, unprovenRefusalCode, ""},
		{"conquer fallback", failConquer(errors.New("conquer dependency")), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"league refused", failLeague(championsleague.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"league invalid", failLeague(championsleague.ErrInvalid), http.StatusBadRequest, 0, "league_request_refused"},
		{"league fallback", failLeague(errors.New("league dependency")), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart2OneOnOneFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"offer stale", failOneOnOne(oneonone.ErrOfferStale), http.StatusConflict, oneOnOneRankChangedError, ""},
		{"refused", failOneOnOne(oneonone.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"invalid", failOneOnOne(oneonone.ErrInvalid), http.StatusBadRequest, 0, "one_on_one_request_refused"},
		{"insufficient", failOneOnOne(economy.ErrInsufficientBalance), http.StatusConflict, unprovenRefusalCode, ""},
		{"fallback", failOneOnOne(errors.New("one on one dependency")), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart2TopFloorFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"offer stale", failTopFloor(topfloor.ErrOfferStale), http.StatusConflict, topFloorRankChangedError, ""},
		{"defense required", failTopFloor(topfloor.ErrDefenseRequired), http.StatusConflict, unprovenRefusalCode, ""},
		{"refused", failTopFloor(topfloor.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"invalid", failTopFloor(topfloor.ErrInvalid), http.StatusBadRequest, 0, "top_floor_request_refused"},
		{"insufficient", failTopFloor(economy.ErrInsufficientBalance), http.StatusConflict, unprovenRefusalCode, ""},
		{"fallback", failTopFloor(errors.New("top floor dependency")), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"task refused", failTopFloorTask(topfloor.ErrRefused), http.StatusConflict, topFloorTaskNotOpen, ""},
		{"task invalid", failTopFloorTask(topfloor.ErrInvalid), http.StatusBadRequest, 0, "invalid_top_floor_task_parameter"},
		{"task fallback", failTopFloorTask(topfloor.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart2AchievementFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"nothing to claim", failAchievement(appachievement.ErrNothingToClaim), http.StatusConflict, unprovenRefusalCode, ""},
		{"fallback", failAchievement(errors.New("achievement dependency")), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart2DormFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"hidden", failDorm(dormhouse.ErrHidden), http.StatusConflict, unprovenRefusalCode, ""},
		{"rejected", failDorm(appdorm.ErrRejected), http.StatusConflict, unprovenRefusalCode, ""},
		{"invalid facts", failDorm(dormhouse.ErrInvalidFacts), http.StatusBadRequest, 0, "dorm_unavailable"},
		{"unqualified", failDorm(dormhouse.ErrUnqualified), http.StatusConflict, unprovenRefusalCode, ""},
		{"invalid layout", failDorm(dormhouse.ErrInvalidLayout), http.StatusBadRequest, 0, "dorm_unavailable"},
		{"fallback", failDorm(errors.New("dorm dependency")), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"social rejected", failSocialDorm(appdorm.ErrRejected), http.StatusConflict, unprovenRefusalCode, ""},
		{"social stale", failSocialDorm(appdorm.ErrStale), http.StatusConflict, staleConflictCode, ""},
		{"social retired", failSocialDorm(appdorm.ErrRetired), http.StatusConflict, unprovenRefusalCode, ""},
		{"social actor", failSocialDorm(appdorm.ErrActor), http.StatusConflict, unprovenRefusalCode, ""},
		{"social unqualified", failSocialDorm(dormhouse.ErrUnqualified), http.StatusConflict, unprovenRefusalCode, ""},
		{"social invalid facts", failSocialDorm(dormhouse.ErrInvalidFacts), http.StatusBadRequest, 0, "dorm_unavailable"},
		{"social invalid layout", failSocialDorm(dormhouse.ErrInvalidLayout), http.StatusBadRequest, 0, "dorm_unavailable"},
		{"social stale time", failSocialDorm(dormhouse.ErrStaleTime), http.StatusConflict, staleConflictCode, ""},
		{"social hidden", failSocialDorm(dormhouse.ErrHidden), http.StatusConflict, unprovenRefusalCode, ""},
		{"social fallback", failSocialDorm(errors.New("dorm social dependency")), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart2LibraryFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"rejected", failLibrary(applibrary.ErrRejected), http.StatusConflict, unprovenRefusalCode, ""},
		{"fallback", failLibrary(errors.New("library dependency")), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"mode rejected", failLibraryMode(applibrary.ErrRejected), http.StatusConflict, unprovenRefusalCode, ""},
		{"mode retired", failLibraryMode(applibrary.ErrRetired), http.StatusConflict, unprovenRefusalCode, ""},
		{"mode unqualified", failLibraryMode(librarylocal.ErrUnqualified), http.StatusConflict, unprovenRefusalCode, ""},
		{"mode dialog closed", failLibraryMode(librarylocal.ErrDialogClosed), http.StatusConflict, unprovenRefusalCode, ""},
		{"mode act locked", failLibraryMode(librarylocal.ErrActLocked), http.StatusConflict, unprovenRefusalCode, ""},
		{"mode act awarded", failLibraryMode(librarylocal.ErrActAwarded), http.StatusConflict, unprovenRefusalCode, ""},
		{"mode cg claimed", failLibraryMode(librarylocal.ErrCGClaimed), http.StatusConflict, unprovenRefusalCode, ""},
		{"mode bg owned", failLibraryMode(librarylocal.ErrBgOwned), http.StatusConflict, unprovenRefusalCode, ""},
		{"mode insufficient", failLibraryMode(economy.ErrInsufficientBalance), http.StatusConflict, unprovenRefusalCode, ""},
	})
}

func TestPart2EquipmentFamilyFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"element rejected", failElement(appelement.ErrRejected), http.StatusConflict, unprovenRefusalCode, ""},
		{"element invalid", failElement(elementequipment.ErrInvalid), http.StatusBadRequest, 0, "elementequipment_command_rejected"},
		{"element insufficient", failElement(economy.ErrInsufficientBalance), http.StatusConflict, unprovenRefusalCode, ""},
		{"element fallback", failElement(errors.New("element dependency")), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"evolution rejected", failEvolution(appevolution.ErrRejected), http.StatusConflict, unprovenRefusalCode, ""},
		{"evolution invalid", failEvolution(heroevolution.ErrInvalid), http.StatusBadRequest, 0, "heroevolution_command_rejected"},
		{"evolution insufficient", failEvolution(economy.ErrInsufficientBalance), http.StatusConflict, unprovenRefusalCode, ""},
		{"inscription rejected", failInscription(appinscription.ErrRejected), http.StatusConflict, unprovenRefusalCode, ""},
		{"inscription invalid", failInscription(inscription.ErrInvalid), http.StatusBadRequest, 0, "inscription_command_rejected"},
		{"spirit rejected", failSpirit(appspirit.ErrRejected), http.StatusConflict, unprovenRefusalCode, ""},
		{"spirit invalid", failSpirit(spirit.ErrInvalid), http.StatusBadRequest, 0, "spirit_command_rejected"},
		{"spirit insufficient", failSpirit(economy.ErrInsufficientBalance), http.StatusConflict, unprovenRefusalCode, ""},
		{"spirit fallback", failSpirit(errors.New("spirit dependency")), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart2PracticeFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"commit unknown", practiceFailure(&tx.UnknownCommitError{Cause: errors.New("ambiguous commit")}), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"receipt conflict", practiceFailure(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"actor stale", practiceFailure(apppractice.ErrActorStaleVersion), http.StatusConflict, staleConflictCode, ""},
		{"stale version", practiceFailure(apppractice.ErrStaleVersion), http.StatusConflict, staleConflictCode, ""},
		{"candidate missing", practiceFailure(apppractice.ErrCandidateMissing), http.StatusConflict, staleConflictCode, ""},
		{"admission", practiceFailure(apppractice.ErrPracticeAdmission), http.StatusConflict, unprovenRefusalCode, ""},
		{"privilege", practiceFailure(apppractice.ErrPracticePrivilege), http.StatusConflict, unprovenRefusalCode, ""},
		{"bless", practiceFailure(apppractice.ErrPracticeBless), http.StatusConflict, unprovenRefusalCode, ""},
		{"level requirement", practiceFailure(appi5.ErrLevelRequirement), http.StatusConflict, unprovenRefusalCode, ""},
		{"insufficient", practiceFailure(economy.ErrInsufficientBalance), http.StatusConflict, unprovenRefusalCode, ""},
		{"unknown resource", practiceFailure(economy.ErrUnknownResource), http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"all at cap", practiceFailure(apppractice.ErrAllPracticeAttrsAtCap), http.StatusConflict, unprovenRefusalCode, ""},
		{"invalid method", practiceFailure(apppractice.ErrInvalidPracticeMethod), http.StatusBadRequest, 0, "practice_rejected"},
		{"empty roll support", practiceFailure(apppractice.ErrEmptyRollSupport), http.StatusConflict, unprovenRefusalCode, ""},
		{"fallback", practiceFailure(errors.New("practice dependency")), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart2SavedPresetFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid command", failSavedPreset(appsavedpreset.ErrInvalidCommand), http.StatusBadRequest, 0, "saved_preset_rejected"},
		{"reference not found", failSavedPreset(characterasset.ErrReferenceNotFound), http.StatusBadRequest, 0, "saved_preset_rejected"},
		{"ambiguous delete", failSavedPreset(appsavedpreset.ErrAmbiguousLegacyDelete), http.StatusConflict, staleConflictCode, ""},
		{"stale delete", failSavedPreset(appsavedpreset.ErrStaleLegacyDelete), http.StatusConflict, staleConflictCode, ""},
		{"receipt conflict", failSavedPreset(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"commit unknown", failSavedPreset(&tx.UnknownCommitError{Cause: errors.New("ambiguous commit")}), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"fallback", failSavedPreset(errors.New("saved preset dependency")), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}
