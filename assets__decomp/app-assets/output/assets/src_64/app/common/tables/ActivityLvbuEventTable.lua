local var_0_0 = class("ActivityLvbuEventTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.eventId_ = {}
	arg_1_0.rate_ = {}
	arg_1_0.tip_ = {}
	arg_1_0.story_ = {}
	arg_1_0.dollars_ = {}
	arg_1_0.walk_ = {}

	import("app.common.tables.TableParser").parse("activity_lvbu_event.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.eventId_[var_2_0] = tonumber(arg_2_0.event_id)
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.tip_[var_2_0] = arg_2_0.tip
		arg_1_0.story_[var_2_0] = tonumber(arg_2_0.story)
		arg_1_0.dollars_[var_2_0] = tonumber(arg_2_0.dollars)
		arg_1_0.walk_[var_2_0] = tonumber(arg_2_0.walk)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.eventId(arg_4_0, arg_4_1)
	return arg_4_0.eventId_[arg_4_1] or 0
end

function var_0_0.rate(arg_5_0, arg_5_1)
	return arg_5_0.rate_[arg_5_1] or 0
end

function var_0_0.tip(arg_6_0, arg_6_1)
	return arg_6_0.tip_[arg_6_1] or ""
end

function var_0_0.story(arg_7_0, arg_7_1)
	return arg_7_0.story_[arg_7_1] or 0
end

function var_0_0.dollars(arg_8_0, arg_8_1)
	return arg_8_0.dollars_[arg_8_1] or 0
end

function var_0_0.walk(arg_9_0, arg_9_1)
	return arg_9_0.walk_[arg_9_1] or 0
end

function var_0_0.isStory(arg_10_0, arg_10_1)
	if arg_10_0:story(arg_10_1) > 0 then
		return true
	end

	return false
end

return var_0_0
