package stockruntime

import (
	unavailableappbookskill "gxb.local/backend/v2/internal/application/bookskill"
	unavailableappcourse "gxb.local/backend/v2/internal/application/course"
	unavailableappdormhouse "gxb.local/backend/v2/internal/application/dormhouse"
	unavailableappelementequipment "gxb.local/backend/v2/internal/application/elementequipment"
	unavailableappeventcentre "gxb.local/backend/v2/internal/application/eventcentre"
	unavailableappfrienddm "gxb.local/backend/v2/internal/application/frienddm"
	unavailableappgeneraldm "gxb.local/backend/v2/internal/application/generaldm"
	unavailableappgmquestion "gxb.local/backend/v2/internal/application/gmquestion"
	unavailableappguildcampaign "gxb.local/backend/v2/internal/application/guildcampaign"
	unavailableappguildrental "gxb.local/backend/v2/internal/application/guildrental"
	unavailableappguildtea "gxb.local/backend/v2/internal/application/guildtea"
	unavailableappguildview "gxb.local/backend/v2/internal/application/guildview"
	unavailableappheroevolution "gxb.local/backend/v2/internal/application/heroevolution"
	unavailableappinscription "gxb.local/backend/v2/internal/application/inscription"
	unavailableapplibraryforum "gxb.local/backend/v2/internal/application/libraryforum"
	unavailableapplibrarylocal "gxb.local/backend/v2/internal/application/librarylocal"
	unavailableappmentor "gxb.local/backend/v2/internal/application/mentor"
	unavailableappplayerdisplay "gxb.local/backend/v2/internal/application/playerdisplay"
	unavailableapppublication "gxb.local/backend/v2/internal/application/publication"
	unavailableappsharedroom "gxb.local/backend/v2/internal/application/sharedroom"
	unavailableappsocialexchange "gxb.local/backend/v2/internal/application/socialexchange"
	unavailableappsocialinvite "gxb.local/backend/v2/internal/application/socialinvite"
	unavailableappspirit "gxb.local/backend/v2/internal/application/spirit"
	unavailabledomainachievement "gxb.local/backend/v2/internal/domain/achievement"
	unavailabledomainadventure "gxb.local/backend/v2/internal/domain/adventure"
	unavailabledomainarena "gxb.local/backend/v2/internal/domain/arena"
	unavailabledomaincampaign "gxb.local/backend/v2/internal/domain/campaign"
	unavailabledomainchampionsleague "gxb.local/backend/v2/internal/domain/championsleague"
	unavailabledomaincompat "gxb.local/backend/v2/internal/domain/compat"
	unavailabledomainconquerschool "gxb.local/backend/v2/internal/domain/conquerschool"
	unavailabledomaindodgeball "gxb.local/backend/v2/internal/domain/dodgeball"
	unavailabledomaingodstrial "gxb.local/backend/v2/internal/domain/godstrial"
	unavailabledomainherorecommend "gxb.local/backend/v2/internal/domain/herorecommend"
	unavailabledomainillusion "gxb.local/backend/v2/internal/domain/illusion"
	unavailabledomainmarch "gxb.local/backend/v2/internal/domain/march"
	unavailabledomainmemoir "gxb.local/backend/v2/internal/domain/memoir"
	unavailabledomainoccult "gxb.local/backend/v2/internal/domain/occult"
	unavailabledomainoneonone "gxb.local/backend/v2/internal/domain/oneonone"
	unavailabledomainpetcampaign "gxb.local/backend/v2/internal/domain/petcampaign"
	unavailabledomainprivilege "gxb.local/backend/v2/internal/domain/privilege"
	unavailabledomainspirit "gxb.local/backend/v2/internal/domain/spirit"
	unavailabledomainsummon "gxb.local/backend/v2/internal/domain/summon"
	unavailabledomaintopfloor "gxb.local/backend/v2/internal/domain/topfloor"
	unavailabledomainworkplace "gxb.local/backend/v2/internal/domain/workplace"
	unavailabledomainworldboss "gxb.local/backend/v2/internal/domain/worldboss"
)

// unavailableSentinels are the owners' own "unavailable" errors. I9 mode
// framework F4(d) and the system contracts that follow it answer them 503 +
// 35033; an error nobody classified is a defect (500).
var unavailableSentinels = []error{
	unavailableappbookskill.ErrUnavailable,
	unavailableappcourse.ErrUnavailable,
	unavailableappdormhouse.ErrUnavailable,
	unavailableappelementequipment.ErrUnavailable,
	unavailableappeventcentre.ErrUnavailable,
	unavailableappfrienddm.ErrUnavailable,
	unavailableappgeneraldm.ErrUnavailable,
	unavailableappgmquestion.ErrUnavailable,
	unavailableappguildcampaign.ErrUnavailable,
	unavailableappguildrental.ErrUnavailable,
	unavailableappguildtea.ErrUnavailable,
	unavailableappguildview.ErrUnavailable,
	unavailableappheroevolution.ErrUnavailable,
	unavailableappinscription.ErrUnavailable,
	unavailableapplibraryforum.ErrUnavailable,
	unavailableapplibrarylocal.ErrUnavailable,
	unavailableappmentor.ErrUnavailable,
	unavailableappplayerdisplay.ErrUnavailable,
	unavailableapppublication.ErrUnavailable,
	unavailableappsharedroom.ErrUnavailable,
	unavailableappsocialexchange.ErrUnavailable,
	unavailableappsocialinvite.ErrUnavailable,
	unavailableappspirit.ErrUnavailable,
	unavailabledomainachievement.ErrUnavailable,
	unavailabledomainadventure.ErrUnavailable,
	unavailabledomainarena.ErrUnavailable,
	unavailabledomaincampaign.ErrUnavailable,
	unavailabledomainchampionsleague.ErrUnavailable,
	unavailabledomaincompat.ErrUnavailable,
	unavailabledomainconquerschool.ErrUnavailable,
	unavailabledomaindodgeball.ErrUnavailable,
	unavailabledomaingodstrial.ErrUnavailable,
	unavailabledomainherorecommend.ErrUnavailable,
	unavailabledomainillusion.ErrUnavailable,
	unavailabledomainmarch.ErrUnavailable,
	unavailabledomainmemoir.ErrUnavailable,
	unavailabledomainoccult.ErrUnavailable,
	unavailabledomainoneonone.ErrUnavailable,
	unavailabledomainpetcampaign.ErrUnavailable,
	unavailabledomainprivilege.ErrUnavailable,
	unavailabledomainspirit.ErrUnavailable,
	unavailabledomainsummon.ErrUnavailable,
	unavailabledomaintopfloor.ErrUnavailable,
	unavailabledomainworkplace.ErrUnavailable,
	unavailabledomainworldboss.ErrUnavailable,
}
