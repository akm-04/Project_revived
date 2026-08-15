local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("ElementEquipTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.element_ = {}
	arg_1_0.equipType_ = {}
	arg_1_0.equipDsc_ = {}
	arg_1_0.strthDsc_ = {}
	arg_1_0.attr_ = {}
	arg_1_0.skillIDs_ = {}
	arg_1_0.buffIDs_ = {}
	arg_1_0.base_ = {}
	arg_1_0.strth_ = {}
	arg_1_0.battleBase_ = {}
	arg_1_0.battleStrth_ = {}
	arg_1_0.active_ = {}
	arg_1_0.activeSP_ = {}
	arg_1_0.partnerID_ = {}
	arg_1_0.strthDscSuffix_ = {}
	arg_1_0.isHide_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("element_equip.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("element_equip", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)
	local var_2_1 = tonumber(arg_2_1.item_id)

	arg_2_0.id_[var_2_1] = var_2_0
	arg_2_0.itemID_[var_2_0] = var_2_1
	arg_2_0.element_[var_2_1] = tonumber(arg_2_1.element)
	arg_2_0.equipType_[var_2_1] = tonumber(arg_2_1.equip_type)
	arg_2_0.equipDsc_[var_2_1] = arg_2_1.equip_dsc
	arg_2_0.strthDsc_[var_2_1] = arg_2_1.strth_dsc
	arg_2_0.attr_[var_2_1] = tonumber(arg_2_1.attr)
	arg_2_0.skillIDs_[var_2_1] = var_0_1.splitToNumber(arg_2_1.skill_id, "|") or {}
	arg_2_0.buffIDs_[var_2_1] = var_0_1.splitToNumber(arg_2_1.buff_id, "|") or {}
	arg_2_0.base_[var_2_1] = tonumber(arg_2_1.nums)
	arg_2_0.strth_[var_2_1] = var_0_1.splitToNumber(arg_2_1.strth, "|") or {}
	arg_2_0.battleBase_[var_2_1] = arg_2_1.battle_nums
	arg_2_0.battleStrth_[var_2_1] = var_0_1.split(arg_2_1.battle_strth, "|") or {}
	arg_2_0.active_[var_2_1] = tonumber(arg_2_1.active)
	arg_2_0.activeSP_[var_2_1] = tonumber(arg_2_1.active_sp)
	arg_2_0.partnerID_[var_2_1] = tonumber(arg_2_1.partner_id)
	arg_2_0.strthDscSuffix_[var_2_1] = tostring(arg_2_1.strth_dsc_suffix)
	arg_2_0.isHide_[var_2_1] = tonumber(arg_2_1.is_hide)
end

function var_0_2.id(arg_3_0, arg_3_1)
	return arg_3_0.id_[arg_3_1] or 0
end

function var_0_2.all_id(arg_4_0)
	return arg_4_0.id_ or {}
end

function var_0_2.all_itemid(arg_5_0)
	return arg_5_0.itemID_ or {}
end

function var_0_2.itemID(arg_6_0, arg_6_1)
	return arg_6_0.itemID_[arg_6_1] or 0
end

function var_0_2.element(arg_7_0, arg_7_1)
	return arg_7_0.element_[arg_7_1] or 0
end

function var_0_2.equipType(arg_8_0, arg_8_1)
	return arg_8_0.equipType_[arg_8_1] or 0
end

function var_0_2.equipDsc(arg_9_0, arg_9_1)
	return arg_9_0.equipDsc_[arg_9_1] or ""
end

function var_0_2.strthDsc(arg_10_0, arg_10_1)
	return arg_10_0.strthDsc_[arg_10_1] or ""
end

function var_0_2.attr(arg_11_0, arg_11_1)
	return arg_11_0.attr_[arg_11_1] or 0
end

function var_0_2.skillIDs(arg_12_0, arg_12_1)
	return arg_12_0.skillIDs_[arg_12_1] or {}
end

function var_0_2.buffIDs(arg_13_0, arg_13_1)
	return arg_13_0.buffIDs_[arg_13_1] or {}
end

function var_0_2.base(arg_14_0, arg_14_1)
	return arg_14_0.base_[arg_14_1] or 0
end

function var_0_2.strth(arg_15_0, arg_15_1, arg_15_2)
	return arg_15_0.strth_[arg_15_1][arg_15_2] or 0
end

function var_0_2.battleAttr(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = string.find(arg_16_0.battleBase_[arg_16_1], "p")

	if var_16_0 then
		local var_16_1 = tonumber(arg_16_0.battleBase_[arg_16_1]:sub(1, var_16_0 - 1) or 0) / var_0_1.DECIMAL_BASE
		local var_16_2 = 0

		if arg_16_2 > 0 then
			local var_16_3 = string.find(arg_16_0.battleStrth_[arg_16_1][arg_16_2], "p")

			var_16_2 = tonumber(arg_16_0.battleStrth_[arg_16_1][arg_16_2]:sub(1, var_16_3 - 1) or 0) / var_0_1.DECIMAL_BASE
		end

		return var_16_1 + var_16_2, true
	else
		local var_16_4 = tonumber(arg_16_0.battleBase_[arg_16_1]) or 0
		local var_16_5 = 0

		if arg_16_2 > 0 then
			var_16_5 = tonumber(arg_16_0.battleStrth_[arg_16_1][arg_16_2])
		end

		return var_16_4 + var_16_5, false
	end
end

function var_0_2.active(arg_17_0, arg_17_1)
	return arg_17_0.active_[arg_17_1] or 1
end

function var_0_2.activeSP(arg_18_0, arg_18_1)
	return arg_18_0.activeSP_[arg_18_1] or 1
end

function var_0_2.partnerID(arg_19_0, arg_19_1)
	return arg_19_0.partnerID_[arg_19_1] or 0
end

function var_0_2.strthDscSuffix(arg_20_0, arg_20_1)
	return arg_20_0.strthDscSuffix_[arg_20_1]
end

function var_0_2.isHide(arg_21_0, arg_21_1)
	return arg_21_0.isHide_[arg_21_1]
end

return var_0_2
