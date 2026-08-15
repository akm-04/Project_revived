local var_0_0 = class("DMonsterTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.name_ = {}
	arg_1_0.hp_ = {}
	arg_1_0.ad_ = {}
	arg_1_0.ap_ = {}
	arg_1_0.hujia_ = {}
	arg_1_0.mokang_ = {}
	arg_1_0.DHujia_ = {}
	arg_1_0.DMokang_ = {}
	arg_1_0.xixue_ = {}
	arg_1_0.shanbi_ = {}
	arg_1_0.mingzhong_ = {}
	arg_1_0.ADBaoji_ = {}
	arg_1_0.ADBaijiHarm_ = {}
	arg_1_0.reHp_ = {}
	arg_1_0.reMp_ = {}
	arg_1_0.DMp_ = {}
	arg_1_0.getMp_ = {}
	arg_1_0.speed_ = {}
	arg_1_0.interval_ = {}
	arg_1_0.APBaoji_ = {}
	arg_1_0.APBaojiHarm_ = {}
	arg_1_0.distance_ = {}
	arg_1_0.circle_ = {}
	arg_1_0.skill_ = {}
	arg_1_0.modelId_ = {}
	arg_1_0.lv_ = {}
	arg_1_0.attributes_ = {}
	arg_1_0.cure_ = {}
	arg_1_0.buffSkill_ = {}
	arg_1_0.scale_ = {}

	import("app.common.tables.TableParser").parse("monster.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.hp_[var_2_0] = tonumber(arg_2_0.hp)
		arg_1_0.ad_[var_2_0] = tonumber(arg_2_0.ad)
		arg_1_0.ap_[var_2_0] = tonumber(arg_2_0.ap)
		arg_1_0.hujia_[var_2_0] = tonumber(arg_2_0.hujia)
		arg_1_0.mokang_[var_2_0] = tonumber(arg_2_0.mokang)
		arg_1_0.DHujia_[var_2_0] = tonumber(arg_2_0.DHujia)
		arg_1_0.DMokang_[var_2_0] = tonumber(arg_2_0.DMokang)
		arg_1_0.xixue_[var_2_0] = tonumber(arg_2_0.xixue)
		arg_1_0.shanbi_[var_2_0] = tonumber(arg_2_0.shanbi)
		arg_1_0.mingzhong_[var_2_0] = tonumber(arg_2_0.mingzhong)
		arg_1_0.ADBaoji_[var_2_0] = tonumber(arg_2_0.ADBaoji)
		arg_1_0.ADBaijiHarm_[var_2_0] = tonumber(arg_2_0.ADBaijiHarm)
		arg_1_0.reHp_[var_2_0] = tonumber(arg_2_0.reHp)
		arg_1_0.reMp_[var_2_0] = tonumber(arg_2_0.reMp)
		arg_1_0.DMp_[var_2_0] = tonumber(arg_2_0.DMp)
		arg_1_0.getMp_[var_2_0] = tonumber(arg_2_0.getMp)
		arg_1_0.speed_[var_2_0] = tonumber(arg_2_0.speed)
		arg_1_0.interval_[var_2_0] = tonumber(arg_2_0.interval)
		arg_1_0.APBaoji_[var_2_0] = tonumber(arg_2_0.APBaoji)
		arg_1_0.APBaojiHarm_[var_2_0] = tonumber(arg_2_0.APBaojiHarm)
		arg_1_0.distance_[var_2_0] = tonumber(arg_2_0.distance)
		arg_1_0.skill_[var_2_0] = tonumber(arg_2_0.skill)
		arg_1_0.modelId_[var_2_0] = tonumber(arg_2_0.modelId)
		arg_1_0.cure_[var_2_0] = tonumber(arg_2_0.cure)
		arg_1_0.circle_[var_2_0] = {}
		arg_1_0.scale_[var_2_0] = tonumber(arg_2_0.scale)

		for iter_2_0, iter_2_1 in pairs(arg_1_0:lua_string_split(arg_2_0.circle, "|")) do
			table.insert(arg_1_0.circle_[var_2_0], tonumber(iter_2_1))
		end

		arg_1_0.lv_[var_2_0] = tonumber(arg_2_0.lv)
		arg_1_0.buffSkill_[var_2_0] = tonumber(arg_2_0.buffSkill)
		arg_1_0.attributes_[var_2_0] = {}
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.HP] = tonumber(arg_2_0.hp)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.AD] = tonumber(arg_2_0.ad)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.AP] = tonumber(arg_2_0.ap)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.HUJIA] = tonumber(arg_2_0.hujia)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.MOKANG] = tonumber(arg_2_0.mokang)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.D_HUJIA] = tonumber(arg_2_0.DHujia)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.D_MOKANG] = tonumber(arg_2_0.DMokang)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.XIXUE] = tonumber(arg_2_0.xixue)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.SHANBI] = tonumber(arg_2_0.shanbi)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.MINGZHONG] = tonumber(arg_2_0.mingzhong)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.AD_BAOJI] = tonumber(arg_2_0.ADBaoji)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.AD_BAOJIHARM] = tonumber(arg_2_0.ADBaojiHarm)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.REHP] = tonumber(arg_2_0.reHp)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.REMP] = tonumber(arg_2_0.reMp)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.D_MP] = tonumber(arg_2_0.DMp)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.GETMP] = tonumber(arg_2_0.getMp)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.SPEED] = tonumber(arg_2_0.speed)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.INTERVAL] = tonumber(arg_2_0.interval)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.AP_BAOJI] = tonumber(arg_2_0.APBaoji)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.AP_BAOJIHARM] = tonumber(arg_2_0.APBaojiHarm)
		arg_1_0.attributes_[var_2_0][xyd.MonsterAttribute.CURE] = tonumber(arg_2_0.cure)
	end)
end

function var_0_0.hasMonster(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] ~= nil
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1]
end

function var_0_0.hp(arg_5_0, arg_5_1)
	return arg_5_0.hp_[arg_5_1] or 0
end

function var_0_0.ad(arg_6_0, arg_6_1)
	return arg_6_0.ad_[arg_6_1] or 0
end

function var_0_0.ap(arg_7_0, arg_7_1)
	return arg_7_0.ap_[arg_7_1] or 0
end

function var_0_0.hujia(arg_8_0, arg_8_1)
	return arg_8_0.hujia_[arg_8_1] or 0
end

function var_0_0.mokang(arg_9_0, arg_9_1)
	return arg_9_0.mokang_[arg_9_1] or 0
end

function var_0_0.DHujia(arg_10_0, arg_10_1)
	return arg_10_0.DHujia_[arg_10_1] or 0
end

function var_0_0.DMokang(arg_11_0, arg_11_1)
	return arg_11_0.DMokang_[arg_11_1] or 0
end

function var_0_0.xixue(arg_12_0, arg_12_1)
	return arg_12_0.xixue_[arg_12_1] or 0
end

function var_0_0.shanbi(arg_13_0, arg_13_1)
	return arg_13_0.shanbi_[arg_13_1] or 0
end

function var_0_0.mingzhong(arg_14_0, arg_14_1)
	return arg_14_0.mingzhong_[arg_14_1] or 0
end

function var_0_0.adBaoji(arg_15_0, arg_15_1)
	return arg_15_0.ADBaoji_[arg_15_1] or 0
end

function var_0_0.adBaijiharm(arg_16_0, arg_16_1)
	return arg_16_0.ad_baijiharm_[arg_16_1] or 0
end

function var_0_0.reHp(arg_17_0, arg_17_1)
	return arg_17_0.reHp_[arg_17_1] or 0
end

function var_0_0.reMp(arg_18_0, arg_18_1)
	return arg_18_0.reMp_[arg_18_1] or 0
end

function var_0_0.DMp(arg_19_0, arg_19_1)
	return arg_19_0.DMp_[arg_19_1] or 0
end

function var_0_0.getMp(arg_20_0, arg_20_1)
	return arg_20_0.getMp_[arg_20_1] or 0
end

function var_0_0.speed(arg_21_0, arg_21_1)
	return arg_21_0.speed_[arg_21_1] or 0
end

function var_0_0.interval(arg_22_0, arg_22_1)
	return arg_22_0.interval_[arg_22_1] or 0
end

function var_0_0.apBaoji(arg_23_0, arg_23_1)
	return arg_23_0.APBaoji_[arg_23_1] or 0
end

function var_0_0.apBaojihHarm(arg_24_0, arg_24_1)
	return arg_24_0.APBaojiHarm_[arg_24_1] or 0
end

function var_0_0.distance(arg_25_0, arg_25_1)
	return arg_25_0.distance_[arg_25_1] or 0
end

function var_0_0.circle(arg_26_0, arg_26_1)
	return arg_26_0.circle_[arg_26_1] or {}
end

function var_0_0.skill(arg_27_0, arg_27_1)
	return arg_27_0.skill_[arg_27_1] or 0
end

function var_0_0.modelId(arg_28_0, arg_28_1)
	return arg_28_0.modelId_[arg_28_1] or 0
end

function var_0_0.attributes(arg_29_0, arg_29_1)
	return arg_29_0.attributes_[arg_29_1] or {}
end

function var_0_0.lv(arg_30_0, arg_30_1)
	return arg_30_0.lv_[arg_30_1] or 0
end

function var_0_0.cure(arg_31_0, arg_31_1)
	return arg_31_0.cure_[arg_31_1] or 0
end

function var_0_0.buffSkill(arg_32_0, arg_32_1)
	return arg_32_0.buffSkill_[arg_32_1] or 0
end

function var_0_0.scale(arg_33_0, arg_33_1)
	return arg_33_0.scale_[arg_33_1] or 0
end

function var_0_0.lua_string_split(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = {}

	while true do
		local var_34_1 = string.find(arg_34_1, arg_34_2)

		if not var_34_1 then
			var_34_0[#var_34_0 + 1] = arg_34_1

			break
		end

		local var_34_2 = string.sub(arg_34_1, 1, var_34_1 - 1)

		var_34_0[#var_34_0 + 1] = var_34_2
		arg_34_1 = string.sub(arg_34_1, var_34_1 + 1, #arg_34_1)
	end

	return var_34_0
end

return var_0_0
