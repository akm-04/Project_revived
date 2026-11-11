package stockruntime

import (
	"net/http"
	"testing"

	sr "gxb.local/backend/v2/internal/application/sharedroom"
	appcourse "gxb.local/backend/v2/internal/application/course"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/combat"
	course "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/economy"
	gmquestion "gxb.local/backend/v2/internal/domain/gmquestion"
	herorecommend "gxb.local/backend/v2/internal/domain/herorecommend"
	illusion "gxb.local/backend/v2/internal/domain/illusion"
	privilege "gxb.local/backend/v2/internal/domain/privilege"
	room "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func TestPart3CAdventureFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid", failAdventure(d.ErrInvalid), http.StatusBadRequest, 0, "adventure_invalid_parameter"},
		{"expired", failAdventure(d.ErrExpired), http.StatusConflict, adventureExpired, ""},
		{"refused", failAdventure(d.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"not in room", failAdventure(sr.ErrNotInRoom), http.StatusConflict, unprovenRefusalCode, ""},
		{"room full", failAdventure(room.ErrFull), http.StatusConflict, unprovenRefusalCode, ""},
		{"balance diamonds", failAdventure(economy.InsufficientBalance("crystal")), http.StatusConflict, insufficientDiamondCode, ""},
		{"balance coins", failAdventure(economy.InsufficientBalance("mana")), http.StatusConflict, insufficientCoinCode, ""},
		{"balance stamina", failAdventure(economy.InsufficientBalance("energy")), http.StatusConflict, insufficientStaminaCode, ""},
		{"balance other", failAdventure(economy.InsufficientBalance("guild_coin")), http.StatusConflict, unprovenRefusalCode, ""},
		{"unknown resource", failAdventure(economy.ErrUnknownResource), http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"unavailable", failAdventure(d.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart3CCampaignFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid", failCampaign(campaign.ErrInvalid), http.StatusBadRequest, 0, "campaign_invalid_parameter"},
		{"conflict", failCampaign(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"loan refused", failCampaign(combat.ErrLoanRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"refused", failCampaign(campaign.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"unavailable", failCampaign(campaign.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart3CChargeFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"charge refused", failCharge(privilege.ErrChargeRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"conflict", failCharge(privilege.ErrConflict), http.StatusConflict, staleConflictCode, ""},
		{"receipt conflict", failCharge(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"unavailable", failCharge(privilege.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart3CCourseFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"rejected", failCourse(appcourse.ErrRejected), http.StatusConflict, unprovenRefusalCode, ""},
		{"stale", failCourse(appcourse.ErrStale), http.StatusConflict, staleConflictCode, ""},
		{"retired", failCourse(appcourse.ErrRetired), http.StatusConflict, unprovenRefusalCode, ""},
		{"actor", failCourse(appcourse.ErrActor), http.StatusConflict, unprovenRefusalCode, ""},
		{"invalid", failCourse(course.ErrInvalid), http.StatusBadRequest, 0, "invalid_course_request"},
		{"unqualified", failCourse(course.ErrUnqualified), http.StatusConflict, unprovenRefusalCode, ""},
		{"stale time", failCourse(course.ErrStaleTime), http.StatusConflict, staleConflictCode, ""},
		{"conflict", failCourse(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"balance diamonds", failCourse(economy.InsufficientBalance("crystal")), http.StatusConflict, insufficientDiamondCode, ""},
		{"balance other", failCourse(economy.InsufficientBalance("guild_coin")), http.StatusConflict, unprovenRefusalCode, ""},
		{"unavailable", failCourse(appcourse.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart3CGMQuestionFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"question refused", failQuestionRows(gmquestion.ErrQuestion), http.StatusConflict, unprovenRefusalCode, ""},
		{"conflict", failQuestionRows(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"unavailable", questionUnavailable(nil), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func failQuestionRows(err error) httpedge.Response {
	return failureFromRows(gmQuestionFailureRows, err)
}

func TestPart3CHeroRecommendFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"refused", failHeroRecommend(herorecommend.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"conflict", failHeroRecommend(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"unavailable", failHeroRecommend(herorecommend.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart3CIllusionFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid", failIllusion(illusion.ErrInvalid), http.StatusBadRequest, 0, "illusion_invalid_parameter"},
		{"conflict", failIllusion(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"refused", failIllusion(illusion.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"loan refused", failIllusion(combat.ErrLoanRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"balance diamonds", failIllusion(economy.InsufficientBalance("crystal")), http.StatusConflict, insufficientDiamondCode, ""},
		{"balance other", failIllusion(economy.InsufficientBalance("guild_coin")), http.StatusConflict, unprovenRefusalCode, ""},
		{"unavailable", failIllusion(illusion.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart3CIllusionRoomFailureRows(t *testing.T) {	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid", failIllusionRoom(illusion.ErrInvalid), http.StatusBadRequest, 0, "illusion_invalid_parameter"},
		{"room invalid", failIllusionRoom(room.ErrInvalid), http.StatusBadRequest, 0, "illusion_invalid_parameter"},
		{"conflict", failIllusionRoom(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"refused", failIllusionRoom(illusion.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"not in room", failIllusionRoom(sr.ErrNotInRoom), http.StatusConflict, unprovenRefusalCode, ""},
		{"room changed", failIllusionRoom(sr.ErrConflict), http.StatusConflict, staleConflictCode, ""},
		{"room full", failIllusionRoom(room.ErrFull), http.StatusConflict, unprovenRefusalCode, ""},
		{"unavailable", failIllusionRoom(illusion.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart3CLibraryUnservedRefusal(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"unserved", unservedLibraryRefusal(), http.StatusConflict, unprovenRefusalCode, ""},
	})
}
