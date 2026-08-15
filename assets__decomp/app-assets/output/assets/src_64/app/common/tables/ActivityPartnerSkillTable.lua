local var_0_0 = class("ActivityPartnerSkillTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.skillIDs_ = {}
	arg_1_0.type_ = {}
	arg_1_0.from_ = {}
	arg_1_0.distanceType_ = {}
	arg_1_0.partnerReq_ = {}

	import("app.common.tables.TableParser").parse("activity_partner_skill.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.skill_id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.from_[var_2_0] = tonumber(arg_2_0.from)
		arg_1_0.distanceType_[var_2_0] = tonumber(arg_2_0.distance_type)
		arg_1_0.partnerReq_[var_2_0] = tonumber(arg_2_0.partner_req)

		table.insert(arg_1_0.skillIDs_, var_2_0)
	end)
end

function var_0_0.skillIDs(arg_3_0)
	return arg_3_0.skillIDs_ or {}
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_0.from(arg_5_0, arg_5_1)
	return arg_5_0.from_[arg_5_1] or 0
end

function var_0_0.distanceType(arg_6_0, arg_6_1)
	return arg_6_0.distanceType_[arg_6_1] or 0
end

function var_0_0.partnerReq(arg_7_0, arg_7_1)
	return arg_7_0.partnerReq_[arg_7_1] or 0
end

return var_0_0
