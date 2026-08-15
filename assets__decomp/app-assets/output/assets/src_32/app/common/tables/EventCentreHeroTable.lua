local var_0_0 = class("EventCentreHeroTable")

function EventCentreHeroTable.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.icon_ = {}

	import("app.common.tables.TableParser").parse("event_centre_hero.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.hero_id)

		arg_1_0.partner_[id] = arg_2_0.partner
		arg_1_0.upperLimitFighting_[id] = arg_2_0.upper_limit_fighting
		arg_1_0.missionId_ = arg_2_0.mission_id
	end)
end

function EventCentreHeroTable.partner(arg_3_0, arg_3_1)
	return arg_3_0.partner_[arg_3_1] or ""
end

function EventCentreHeroTable.icon(arg_4_0, arg_4_1)
	return arg_4_0.upperLimitFighting_[arg_4_1] or ""
end

function EventCentreHeroTable.missionId(arg_5_0, arg_5_1)
	return arg_5_0.missionId_[arg_5_1] or ""
end

return EventCentreHeroTable
