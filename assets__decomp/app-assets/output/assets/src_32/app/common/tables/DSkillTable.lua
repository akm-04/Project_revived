local var_0_0 = class("DSkillTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.name_ = {}
	arg_1_0.pretime_ = {}
	arg_1_0.distance_ = {}
	arg_1_0.scope_ = {}
	arg_1_0.selectType_ = {}
	arg_1_0.type_ = {}
	arg_1_0.skillType_ = {}
	arg_1_0.beMiss_ = {}
	arg_1_0.ad_ = {}
	arg_1_0.ap_ = {}
	arg_1_0.init_ = {}
	arg_1_0.buffs_ = {}
	arg_1_0.unitNum_ = {}
	arg_1_0.interval_ = {}
	arg_1_0.attackIndex_ = {}
	arg_1_0.lv_ = {}
	arg_1_0.hurtEffect_ = {}
	arg_1_0.remp_ = {}
	arg_1_0.xixue_ = {}
	arg_1_0.speed_ = {}
	arg_1_0.unitImage_ = {}
	arg_1_0.unitEffect_ = {}
	arg_1_0.effectResource_ = {}
	arg_1_0.effectPlace_ = {}
	arg_1_0.timeout_ = {}
	arg_1_0.sound_ = {}

	import("app.common.tables.TableParser").parse("skill.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.pretime_[var_2_0] = tonumber(arg_2_0.pretime)
		arg_1_0.distance_[var_2_0] = tonumber(arg_2_0.distance)
		arg_1_0.scope_[var_2_0] = tonumber(arg_2_0.scope)
		arg_1_0.selectType_[var_2_0] = tonumber(arg_2_0.selectType)
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.skillType_[var_2_0] = tonumber(arg_2_0.skillType)
		arg_1_0.beMiss_[var_2_0] = tonumber(arg_2_0.beMiss)
		arg_1_0.ad_[var_2_0] = tonumber(arg_2_0.ad)
		arg_1_0.ap_[var_2_0] = tonumber(arg_2_0.ap)
		arg_1_0.init_[var_2_0] = tonumber(arg_2_0.init)
		arg_1_0.unitNum_[var_2_0] = tonumber(arg_2_0.unitNum)
		arg_1_0.interval_[var_2_0] = tonumber(arg_2_0.interval)
		arg_1_0.attackIndex_[var_2_0] = tonumber(arg_2_0.attackIndex)
		arg_1_0.lv_[var_2_0] = tonumber(arg_2_0.lv)
		arg_1_0.remp_[var_2_0] = tonumber(arg_2_0.remp)
		arg_1_0.hurtEffect_[var_2_0] = tonumber(arg_2_0.hurtEffect)
		arg_1_0.xixue_[var_2_0] = tonumber(arg_2_0.xixue)
		arg_1_0.speed_[var_2_0] = tonumber(arg_2_0.speed)
		arg_1_0.unitImage_[var_2_0] = arg_2_0.unitImage
		arg_1_0.unitEffect_[var_2_0] = arg_2_0.unitEffect
		arg_1_0.buffs_[var_2_0] = {}

		for iter_2_0, iter_2_1 in pairs(arg_1_0:lua_string_split(arg_2_0.buffs, "|")) do
			if tonumber(iter_2_1) ~= 0 then
				table.insert(arg_1_0.buffs_[var_2_0], tonumber(iter_2_1))
			end
		end

		arg_1_0.effectResource_[var_2_0] = {
			arg_2_0.json,
			arg_2_0.atlas
		}
		arg_1_0.effectPlace_[var_2_0] = tonumber(arg_2_0.effectPlace)
		arg_1_0.timeout_[var_2_0] = tonumber(arg_2_0.timeout)
		arg_1_0.sound_[var_2_0] = arg_2_0.sound
	end)
end

function var_0_0.hasSkill(arg_3_0, arg_3_1)
	return arg_3_0.names_[arg_3_1] ~= nil
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or 0
end

function var_0_0.pretime(arg_5_0, arg_5_1)
	return arg_5_0.pretime_[arg_5_1] or 0
end

function var_0_0.distance(arg_6_0, arg_6_1)
	return arg_6_0.distance_[arg_6_1] or 0
end

function var_0_0.scope(arg_7_0, arg_7_1)
	return arg_7_0.scope_[arg_7_1] or 0
end

function var_0_0.selectType(arg_8_0, arg_8_1)
	return arg_8_0.selectType_[arg_8_1] or 0
end

function var_0_0.beMiss(arg_9_0, arg_9_1)
	return arg_9_0.beMiss_[arg_9_1] or 0
end

function var_0_0.type(arg_10_0, arg_10_1)
	return arg_10_0.type_[arg_10_1] or 0
end

function var_0_0.skillType(arg_11_0, arg_11_1)
	return arg_11_0.skillType_[arg_11_1] or 0
end

function var_0_0.ad(arg_12_0, arg_12_1)
	return arg_12_0.ad_[arg_12_1] or 0
end

function var_0_0.ap(arg_13_0, arg_13_1)
	return arg_13_0.ap_[arg_13_1] or 0
end

function var_0_0.init(arg_14_0, arg_14_1)
	return arg_14_0.init_[arg_14_1] or 0
end

function var_0_0.buffs(arg_15_0, arg_15_1)
	return arg_15_0.buffs_[arg_15_1] or {}
end

function var_0_0.unitNum(arg_16_0, arg_16_1)
	return arg_16_0.unitNum_[arg_16_1] or 0
end

function var_0_0.interval(arg_17_0, arg_17_1)
	return arg_17_0.interval_[arg_17_1] or 0
end

function var_0_0.attackIndex(arg_18_0, arg_18_1)
	return arg_18_0.attackIndex_[arg_18_1] or 0
end

function var_0_0.lv(arg_19_0, arg_19_1)
	return arg_19_0.lv_[arg_19_1] or 0
end

function var_0_0.reMP(arg_20_0, arg_20_1)
	return arg_20_0.remp_[arg_20_1] or 0
end

function var_0_0.hurtEffect(arg_21_0, arg_21_1)
	return arg_21_0.hurtEffect_[arg_21_1] or 0
end

function var_0_0.xixue(arg_22_0, arg_22_1)
	return arg_22_0.xixue_[arg_22_1] or 0
end

function var_0_0.speed(arg_23_0, arg_23_1)
	return arg_23_0.speed_[arg_23_1] or 0
end

function var_0_0.unitImage(arg_24_0, arg_24_1)
	return arg_24_0.unitImage_[arg_24_1] or ""
end

function var_0_0.unitEffect(arg_25_0, arg_25_1)
	return arg_25_0.unitEffect_[arg_25_1]
end

function var_0_0.effectResource(arg_26_0, arg_26_1)
	return unpack(arg_26_0.effectResource_[arg_26_1] or {})
end

function var_0_0.effectPlace(arg_27_0, arg_27_1)
	return arg_27_0.effectPlace_[arg_27_1]
end

function var_0_0.timeout(arg_28_0, arg_28_1)
	return arg_28_0.timeout_[arg_28_1]
end

function var_0_0.sound(arg_29_0, arg_29_1)
	return arg_29_0.sound_[arg_29_1]
end

function var_0_0.lua_string_split(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0 = {}

	while true do
		local var_30_1 = string.find(arg_30_1, arg_30_2)

		if not var_30_1 then
			var_30_0[#var_30_0 + 1] = arg_30_1

			break
		end

		local var_30_2 = string.sub(arg_30_1, 1, var_30_1 - 1)

		var_30_0[#var_30_0 + 1] = var_30_2
		arg_30_1 = string.sub(arg_30_1, var_30_1 + 1, #arg_30_1)
	end

	return var_30_0
end

return var_0_0
