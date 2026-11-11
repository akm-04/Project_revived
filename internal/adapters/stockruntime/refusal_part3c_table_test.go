package stockruntime

import (
	"net/http"
	"testing"

	sr "gxb.local/backend/v2/internal/application/sharedroom"
	exchange "gxb.local/backend/v2/internal/application/socialexchange"
	invite "gxb.local/backend/v2/internal/application/socialinvite"
	appmentor "gxb.local/backend/v2/internal/application/mentor"
	appcourse "gxb.local/backend/v2/internal/application/course"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/combat"
	course "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/economy"
	gmquestion "gxb.local/backend/v2/internal/domain/gmquestion"
	herorecommend "gxb.local/backend/v2/internal/domain/herorecommend"
	illusion "gxb.local/backend/v2/internal/domain/illusion"
	march "gxb.local/backend/v2/internal/domain/march"
	domainmentor "gxb.local/backend/v2/internal/domain/mentor"
	occult "gxb.local/backend/v2/internal/domain/occult"
	socialexchange "gxb.local/backend/v2/internal/domain/socialexchange"
	socialinvite "gxb.local/backend/v2/internal/domain/socialinvite"
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

func TestPart3CLibraryUnservedRefusal(t *testing.T) {	assertPart2FailureCases(t, []part2FailureCase{
		{"unserved", unservedLibraryRefusal(), http.StatusConflict, unprovenRefusalCode, ""},
	})
}

func TestPart3CMarchFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid", marchFailure(march.ErrInvalid), http.StatusBadRequest, 0, "march_invalid_parameter"},
		{"conflict", marchFailure(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"loan refused", marchFailure(combat.ErrLoanRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"refused", marchFailure(march.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"start conflict", marchFailure(combat.ErrStartConflict), http.StatusConflict, unprovenRefusalCode, ""},
		{"unavailable", marchFailure(march.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart3CMentorFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"stock refusal", mentorFailure(&appmentor.Refusal{Code: 34011}), http.StatusConflict, 34011, ""},
		{"zero refusal", mentorFailure(&appmentor.Refusal{}), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"conflict", mentorFailure(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"relationship changed", mentorFailure(domainmentor.ErrRelationshipConflict), http.StatusConflict, staleConflictCode, ""},
		{"relationship", mentorFailure(domainmentor.ErrRelationship), http.StatusConflict, unprovenRefusalCode, ""},
		{"application", mentorFailure(domainmentor.ErrApplication), http.StatusConflict, unprovenRefusalCode, ""},
		{"mission", mentorFailure(domainmentor.ErrMission), http.StatusConflict, unprovenRefusalCode, ""},
		{"invalid", mentorFailure(appmentor.ErrInvalid), http.StatusBadRequest, 0, "invalid_mentor_request"},
		{"unavailable", mentorFailure(appmentor.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"missing service", mentorUnavailable(), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart3COccultFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid", failOccult(occult.ErrInvalid), http.StatusBadRequest, 0, "occult_invalid_parameter"},
		{"conflict", failOccult(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"refused", failOccult(occult.ErrRefused), http.StatusConflict, occultRoomRefusedCode, ""},
		{"no scrolls", failOccult(economy.ErrInsufficientBalance), http.StatusConflict, occultNoScrollsCode, ""},
		{"not in room", failOccult(sr.ErrNotInRoom), http.StatusConflict, occultRoomRefusedCode, ""},
		{"room full", failOccult(room.ErrFull), http.StatusConflict, occultRoomRefusedCode, ""},
		{"unavailable", failOccult(occult.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart3CSocialExchangeFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"product off", failSocialExchange(exchange.ErrProductOff), http.StatusConflict, unprovenRefusalCode, ""},
		{"count", failSocialExchange(socialexchange.ErrCount), http.StatusConflict, unprovenRefusalCode, ""},
		{"unknown product", failSocialExchange(socialexchange.ErrUnknownProduct), http.StatusConflict, unprovenRefusalCode, ""},
		{"conflict", failSocialExchange(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"balance diamonds", failSocialExchange(economy.InsufficientBalance("crystal")), http.StatusConflict, insufficientDiamondCode, ""},
		{"stack capacity", failSocialExchange(economy.ErrStackCapacity), http.StatusConflict, unprovenRefusalCode, ""},
		{"unavailable", failSocialExchange(exchange.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func failSocialExchange(err error) httpedge.Response {
	return failureFromRows(socialExchangeFailureRows, err)
}

func TestPart3CSocialInviteFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"same account", failSocialInvite(socialinvite.ErrSameAccount), http.StatusConflict, sameAccountInviteCode, ""},
		{"bind refused", failSocialInvite(invite.ErrBindRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"claim refused", failSocialInvite(invite.ErrClaimRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"facts", failSocialInvite(invite.ErrFacts), http.StatusConflict, unprovenRefusalCode, ""},
		{"conflict", failSocialInvite(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"unavailable", failSocialInvite(invite.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"missing service", inviteUnavailable(), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func failSocialInvite(err error) httpedge.Response {
	return failureFromRows(socialInviteFailureRows, err)
}
