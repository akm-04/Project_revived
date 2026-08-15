local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("ItemTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.names_ = {}
	arg_1_0.desc1s_ = {}
	arg_1_0.desc2s_ = {}
	arg_1_0.types_ = {}
	arg_1_0.subTypes_ = {}
	arg_1_0.levels_ = {}
	arg_1_0.attrIds_ = {}
	arg_1_0.attrValues_ = {}
	arg_1_0.attrValByKey_ = {}
	arg_1_0.attrBattle_ = {}
	arg_1_0.attrBattleValByKey_ = {}
	arg_1_0.fumoManas_ = {}
	arg_1_0.fumos_ = {}
	arg_1_0.fumoValues_ = {}
	arg_1_0.fumoValuesByKey_ = {}
	arg_1_0.fumoValuesByLevel_ = {}
	arg_1_0.composes_ = {}
	arg_1_0.composeNums_ = {}
	arg_1_0.composeItems_ = {}
	arg_1_0.canComposes_ = {}
	arg_1_0.itemNums_ = {}
	arg_1_0.composeManas_ = {}
	arg_1_0.manas_ = {}
	arg_1_0.resolveResType_ = {}
	arg_1_0.resolveResNum_ = {}
	arg_1_0.resolveEnergy_ = {}
	arg_1_0.makeResType_ = {}
	arg_1_0.makeResNum_ = {}
	arg_1_0.makeTime_ = {}
	arg_1_0.priceManas_ = {}
	arg_1_0.crystals_ = {}
	arg_1_0.priceCrystals_ = {}
	arg_1_0.energys_ = {}
	arg_1_0.magicEnergys_ = {}
	arg_1_0.magicLiquids_ = {}
	arg_1_0.magicDusts_ = {}
	arg_1_0.monengs_ = {}
	arg_1_0.exps_ = {}
	arg_1_0.proficiency_ = {}
	arg_1_0.gainType_ = {}
	arg_1_0.maps_ = {}
	arg_1_0.heros_ = {}
	arg_1_0.stacks_ = {}
	arg_1_0.qualitys_ = {}
	arg_1_0.icons_ = {}
	arg_1_0.transparentIcons_ = {}
	arg_1_0.smallIcons_ = {}
	arg_1_0.heroIDs_ = {}
	arg_1_0.petIDs_ = {}
	arg_1_0.isDeleteAwakePiece_ = {}
	arg_1_0.awakePiece_ = {}
	arg_1_0.awakeCompose_ = {}
	arg_1_0.isAwakenItem_ = {}
	arg_1_0.isAwakenPiece_ = {}
	arg_1_0.isAwakeTwiceItem_ = {}
	arg_1_0.glue_ = {}
	arg_1_0.stackMail_ = {}
	arg_1_0.typeItems = {}
	arg_1_0.level_visibles_ = {}
	arg_1_0.canExchangeItems_ = {}
	arg_1_0.exchangeNeedItems_ = {}
	arg_1_0.exchangeNeedItemNums_ = {}
	arg_1_0.canExchangeItems_ = {}
	arg_1_0.exchangeNeedItems_ = {}
	arg_1_0.exchangeNeedItemNums_ = {}
	arg_1_0.skinModel_ = {}
	arg_1_0.skinPartner_ = {}
	arg_1_0.skinLastTime_ = {}
	arg_1_0.stylePet_ = {}
	arg_1_0.gifts_ = {}
	arg_1_0.chooseGift_ = {}
	arg_1_0.petUseItems_ = {}
	arg_1_0.fatigue_ = {}
	arg_1_0.fatigueArr = {}
	arg_1_0.expArr = {}
	arg_1_0.isScreen_ = {}
	arg_1_0.inscriptId_ = {}
	arg_1_0.inscript_suit_id_ = {}
	arg_1_0.amour_ = {}
	arg_1_0.skillId_ = {}
	arg_1_0.isEquipment_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("item.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("item", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end

	table.sort(arg_1_0.fatigueArr, function(arg_2_0, arg_2_1)
		return arg_2_0.num < arg_2_1.num
	end)
	table.sort(arg_1_0.expArr, function(arg_3_0, arg_3_1)
		return arg_3_0.num < arg_3_1.num
	end)

	for iter_1_0, iter_1_1 in ipairs(arg_1_0.fatigueArr) do
		table.insert(arg_1_0.petUseItems_, iter_1_1.id)
	end

	for iter_1_2, iter_1_3 in ipairs(arg_1_0.expArr) do
		table.insert(arg_1_0.petUseItems_, iter_1_3.id)
	end

	arg_1_0:initCanComposes()
end

function var_0_2.parse(arg_4_0, arg_4_1)
	local var_4_0 = tonumber(arg_4_1.id)

	if arg_4_0.names_[var_4_0] then
		error("item id is duplicated " .. var_4_0)
	end

	arg_4_0.names_[var_4_0] = arg_4_1.name
	arg_4_0.desc1s_[var_4_0] = arg_4_1.desc1
	arg_4_0.desc2s_[var_4_0] = arg_4_1.desc2
	arg_4_0.types_[var_4_0] = tonumber(arg_4_1.type)
	arg_4_0.subTypes_[var_4_0] = tonumber(arg_4_1.sub_type)
	arg_4_0.levels_[var_4_0] = tonumber(arg_4_1.level)
	arg_4_0.level_visibles_[var_4_0] = tonumber(arg_4_1.level_visible)
	arg_4_0.attrIds_[var_4_0] = var_0_1.splitToNumber(arg_4_1.attr_ids, "|") or {}
	arg_4_0.attrValues_[var_4_0] = var_0_1.splitToNumber(arg_4_1.attr_values, "|") or {}
	arg_4_0.attrBattle_[var_4_0] = var_0_1.splitToNumber(arg_4_1.attr_battle, "|") or {}
	arg_4_0.attrValByKey_[var_4_0] = {}
	arg_4_0.attrBattle_[var_4_0] = var_0_1.splitToNumber(arg_4_1.attr_battle, "|") or {}
	arg_4_0.attrBattleValByKey_[var_4_0] = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.attrIds_[var_4_0]) do
		if not arg_4_0.attrBattle_[var_4_0][iter_4_0] then
			error("item attr id does not match attr " .. var_4_0)
		end

		arg_4_0.attrBattleValByKey_[var_4_0][iter_4_1] = arg_4_0.attrBattle_[var_4_0][iter_4_0]
	end

	for iter_4_2, iter_4_3 in ipairs(arg_4_0.attrIds_[var_4_0]) do
		if not arg_4_0.attrValues_[var_4_0][iter_4_2] then
			error("item attr id does not match attr " .. var_4_0)
		end

		arg_4_0.attrValByKey_[var_4_0][iter_4_3] = arg_4_0.attrValues_[var_4_0][iter_4_2]
	end

	arg_4_0.attrBattleValByKey_[var_4_0] = {}

	for iter_4_4, iter_4_5 in ipairs(arg_4_0.attrIds_[var_4_0]) do
		if not arg_4_0.attrBattle_[var_4_0][iter_4_4] then
			error("item attr id does not match attr " .. var_4_0)
		end

		arg_4_0.attrBattleValByKey_[var_4_0][iter_4_5] = arg_4_0.attrBattle_[var_4_0][iter_4_4]
	end

	arg_4_0.composeManas_[var_4_0] = tonumber(arg_4_1.compose_mana)
	arg_4_0.composeItems_[var_4_0] = tonumber(arg_4_1.compose_item)
	arg_4_0.canComposes_[var_4_0] = {}
	arg_4_0.itemNums_[var_4_0] = tonumber(arg_4_1.item_num)
	arg_4_0.manas_[var_4_0] = tonumber(arg_4_1.mana)
	arg_4_0.resolveResType_[var_4_0] = var_0_1.splitToNumber(arg_4_1.resolve_res_type, "|")
	arg_4_0.resolveResNum_[var_4_0] = var_0_1.splitToNumber(arg_4_1.resolve_res_num, "|")
	arg_4_0.resolveEnergy_[var_4_0] = tonumber(arg_4_1.resolve_energy)
	arg_4_0.makeResType_[var_4_0] = var_0_1.splitToNumber(arg_4_1.make_res_type, "|")
	arg_4_0.makeResNum_[var_4_0] = var_0_1.splitToNumber(arg_4_1.make_res_num, "|")
	arg_4_0.makeTime_[var_4_0] = tonumber(arg_4_1.make_time)
	arg_4_0.priceManas_[var_4_0] = tonumber(arg_4_1.price_mana)
	arg_4_0.crystals_[var_4_0] = tonumber(arg_4_1.crystal)
	arg_4_0.priceCrystals_[var_4_0] = tonumber(arg_4_1.price_crystal)
	arg_4_0.energys_[var_4_0] = tonumber(arg_4_1.energy)
	arg_4_0.magicEnergys_[var_4_0] = tonumber(arg_4_1.magic_energy)
	arg_4_0.magicDusts_[var_4_0] = tonumber(arg_4_1.magic_dust)
	arg_4_0.magicLiquids_[var_4_0] = tonumber(arg_4_1.magic_liquid)
	arg_4_0.monengs_[var_4_0] = tonumber(arg_4_1.moneng)
	arg_4_0.exps_[var_4_0] = tonumber(arg_4_1.exp)
	arg_4_0.proficiency_[var_4_0] = tonumber(arg_4_1.proficiency)
	arg_4_0.gainType_[var_4_0] = var_0_1.splitToNumber(arg_4_1.gain_type, "|")
	arg_4_0.glue_[var_4_0] = tonumber(arg_4_1.glue)
	arg_4_0.stackMail_[var_4_0] = tonumber(arg_4_1.stack_exceed_mail)
	arg_4_0.maps_[var_4_0] = var_0_1.splitToNumber(arg_4_1.map, "|")
	arg_4_0.heros_[var_4_0] = var_0_1.splitToNumber(arg_4_1.hero, "|")
	arg_4_0.stacks_[var_4_0] = tonumber(arg_4_1.stack)
	arg_4_0.qualitys_[var_4_0] = tonumber(arg_4_1.quality)
	arg_4_0.fumos_[var_4_0] = var_0_1.splitToNumber(arg_4_1.fumo, "|")
	arg_4_0.fumoManas_[var_4_0] = arg_4_1.fumo_mana
	arg_4_0.isDeleteAwakePiece_[var_4_0] = tonumber(arg_4_1.delete_piece)
	arg_4_0.awakePiece_[var_4_0] = tonumber(arg_4_1.awaken_piece)
	arg_4_0.awakeCompose_[var_4_0] = tonumber(arg_4_1.awaken_equip)
	arg_4_0.isAwakenItem_[var_4_0] = tonumber(arg_4_1.is_awaken_item)
	arg_4_0.isAwakenPiece_[var_4_0] = tonumber(arg_4_1.is_awaken_piece)
	arg_4_0.isAwakeTwiceItem_[var_4_0] = tonumber(arg_4_1.is_bloodline_item)
	arg_4_0.canExchangeItems_[var_4_0] = var_0_1.splitToNumber(arg_4_1.can_exchange_item, "|")
	arg_4_0.exchangeNeedItems_[var_4_0] = var_0_1.splitToNumber(arg_4_1.exchange_item, "|")
	arg_4_0.exchangeNeedItemNums_[var_4_0] = var_0_1.splitToNumber(arg_4_1.exchange_num, "|")
	arg_4_0.fumoValues_[var_4_0] = {}

	table.insert(arg_4_0.fumoValues_[var_4_0], var_0_1.splitToNumber(arg_4_1.fumo_value1, "|") or {})
	table.insert(arg_4_0.fumoValues_[var_4_0], var_0_1.splitToNumber(arg_4_1.fumo_value2, "|") or {})
	table.insert(arg_4_0.fumoValues_[var_4_0], var_0_1.splitToNumber(arg_4_1.fumo_value3, "|") or {})
	table.insert(arg_4_0.fumoValues_[var_4_0], var_0_1.splitToNumber(arg_4_1.fumo_value4, "|") or {})
	table.insert(arg_4_0.fumoValues_[var_4_0], var_0_1.splitToNumber(arg_4_1.fumo_value5, "|") or {})

	arg_4_0.fumoValuesByKey_[var_4_0] = {}

	for iter_4_6, iter_4_7 in ipairs(arg_4_0.fumoValues_[var_4_0]) do
		if next(iter_4_7) == nil then
			break
		end

		local var_4_1 = {}

		for iter_4_8, iter_4_9 in pairs(arg_4_0.attrIds_[var_4_0]) do
			var_4_1[iter_4_9] = iter_4_7[iter_4_8]
		end

		table.insert(arg_4_0.fumoValuesByKey_[var_4_0], var_4_1)
	end

	arg_4_0.fumoValuesByLevel_[var_4_0] = {}

	for iter_4_10 = 1, #arg_4_0.fumoValuesByKey_[var_4_0] do
		arg_4_0.fumoValuesByLevel_[var_4_0][iter_4_10] = {}

		if iter_4_10 == 1 then
			for iter_4_11, iter_4_12 in pairs(arg_4_0.fumoValuesByKey_[var_4_0][iter_4_10]) do
				arg_4_0.fumoValuesByLevel_[var_4_0][iter_4_10][iter_4_11] = iter_4_12
			end
		else
			for iter_4_13, iter_4_14 in pairs(arg_4_0.fumoValuesByKey_[var_4_0][iter_4_10]) do
				arg_4_0.fumoValuesByLevel_[var_4_0][iter_4_10][iter_4_13] = iter_4_14 + arg_4_0.fumoValuesByLevel_[var_4_0][iter_4_10 - 1][iter_4_13]
			end
		end
	end

	arg_4_0.composes_[var_4_0] = var_0_1.splitToNumber(arg_4_1.compose, "|")
	arg_4_0.composeNums_[var_4_0] = var_0_1.splitToNumber(arg_4_1.compose_num, "|")
	arg_4_0.icons_[var_4_0] = arg_4_1.icon
	arg_4_0.transparentIcons_[var_4_0] = arg_4_1.transparent_icon
	arg_4_0.smallIcons_[var_4_0] = arg_4_1.small_icon
	arg_4_0.heroIDs_[var_4_0] = tonumber(arg_4_1.partner_id)
	arg_4_0.petIDs_[var_4_0] = tonumber(arg_4_1.pet_id)
	arg_4_0.skinModel_[var_4_0] = tonumber(arg_4_1.skin_model)
	arg_4_0.skinPartner_[var_4_0] = tonumber(arg_4_1.skin_partner)
	arg_4_0.skinLastTime_[var_4_0] = tonumber(arg_4_1.skin_last_time)
	arg_4_0.fatigue_[var_4_0] = tonumber(arg_4_1.fatigue)
	arg_4_0.inscriptId_[var_4_0] = tonumber(arg_4_1.inscript_id)
	arg_4_0.stylePet_[var_4_0] = tonumber(arg_4_1.style_pet)

	local var_4_2 = tonumber(arg_4_1.type)

	if arg_4_0.typeItems[var_4_2] == nil then
		arg_4_0.typeItems[var_4_2] = {}
	end

	table.insert(arg_4_0.typeItems[var_4_2], var_4_0)

	if arg_4_1.gifts == "0" then
		arg_4_0.gifts_[var_4_0] = {}
	else
		arg_4_0.gifts_[var_4_0] = var_0_1.splitToNumber(arg_4_1.gifts, "|")

		if arg_4_1.one_in_more == "0" then
			arg_4_0.chooseGift_[var_4_0] = {}
		else
			arg_4_0.chooseGift_[var_4_0] = var_0_1.splitToNumber(arg_4_1.one_in_more, "|")
		end
	end

	if arg_4_0.subTypes_[var_4_0] == var_0_1.ConsumeItemType.PET_DRINK_ITEM then
		local var_4_3 = {
			id = var_4_0
		}

		if arg_4_0.fatigue_[var_4_0] > 0 then
			var_4_3.num = arg_4_0.fatigue_[var_4_0]

			table.insert(arg_4_0.fatigueArr, var_4_3)
		else
			var_4_3.num = arg_4_0.exps_[var_4_0]

			table.insert(arg_4_0.expArr, var_4_3)
		end
	end

	arg_4_0.isScreen_[var_4_0] = tonumber(arg_4_1.is_screen)
	arg_4_0.inscript_suit_id_[var_4_0] = tonumber(arg_4_1.inscript_suit_id)
	arg_4_0.amour_[var_4_0] = tonumber(arg_4_1.amour)
	arg_4_0.skillId_[var_4_0] = tonumber(arg_4_1.skill_id)
	arg_4_0.isEquipment_[var_4_0] = tonumber(arg_4_1.is_equipment)
end

function var_0_2.initCanComposes(arg_5_0)
	for iter_5_0, iter_5_1 in pairs(arg_5_0.composes_) do
		local var_5_0 = {}

		for iter_5_2, iter_5_3 in pairs(iter_5_1) do
			if iter_5_3 > 0 then
				if arg_5_0.canComposes_[iter_5_3] == nul then
					arg_5_0.canComposes_[iter_5_3] = {}
				end

				if var_5_0[iter_5_3] == nil then
					table.insert(arg_5_0.canComposes_[iter_5_3], iter_5_0)

					var_5_0[iter_5_3] = true
				end
			end
		end
	end
end

function var_0_2.name(arg_6_0, arg_6_1)
	return arg_6_0.names_[arg_6_1] or ""
end

function var_0_2.desc1(arg_7_0, arg_7_1)
	return arg_7_0.desc1s_[arg_7_1]
end

function var_0_2.desc2(arg_8_0, arg_8_1)
	return arg_8_0.desc2s_[arg_8_1]
end

function var_0_2.type(arg_9_0, arg_9_1)
	return arg_9_0.types_[arg_9_1]
end

function var_0_2.subType(arg_10_0, arg_10_1)
	return arg_10_0.subTypes_[arg_10_1]
end

function var_0_2.level(arg_11_0, arg_11_1)
	return arg_11_0.levels_[arg_11_1]
end

function var_0_2.level_visible(arg_12_0, arg_12_1)
	return arg_12_0.level_visibles_[arg_12_1]
end

function var_0_2.attrIds(arg_13_0, arg_13_1)
	return arg_13_0.attrIds_[arg_13_1] or {}
end

function var_0_2.attrValues(arg_14_0, arg_14_1)
	return arg_14_0.attrValues_[arg_14_1] or {}
end

function var_0_2.attrsBattle(arg_15_0, arg_15_1)
	return arg_15_0.attrBattleValByKey_[arg_15_1] or {}
end

function var_0_2.attrs(arg_16_0, arg_16_1)
	return arg_16_0.attrValByKey_[arg_16_1] or {}
end

function var_0_2.attrsBattle(arg_17_0, arg_17_1)
	return arg_17_0.attrBattleValByKey_[arg_17_1] or {}
end

function var_0_2.fumo(arg_18_0, arg_18_1)
	return arg_18_0.fumos_[arg_18_1] or {}
end

function var_0_2.fumoValues(arg_19_0, arg_19_1, arg_19_2)
	if arg_19_2 then
		return arg_19_0.fumoValues_[arg_19_1][arg_19_2]
	else
		return arg_19_0.fumoValues_[arg_19_1]
	end
end

function var_0_2.fumoValuesByKey(arg_20_0, arg_20_1, arg_20_2)
	if arg_20_2 then
		return arg_20_0.fumoValuesByKey_[arg_20_1][arg_20_2]
	else
		return arg_20_0.fumoValuesByKey_[arg_20_1]
	end
end

function var_0_2.fumoValuesByLevel(arg_21_0, arg_21_1, arg_21_2)
	if arg_21_2 then
		return arg_21_0.fumoValuesByLevel_[arg_21_1][arg_21_2]
	end

	return arg_21_0.fumoValuesByLevel_[arg_21_1]
end

function var_0_2.compose(arg_22_0, arg_22_1, arg_22_2)
	if arg_22_2 then
		return arg_22_0.composes_[arg_22_1][arg_22_2]
	end

	return arg_22_0.composes_[arg_22_1] or {}
end

function var_0_2.composeItem(arg_23_0, arg_23_1)
	return arg_23_0.composeItems_[arg_23_1]
end

function var_0_2.itemNum(arg_24_0, arg_24_1)
	return arg_24_0.itemNums_[arg_24_1]
end

function var_0_2.composeNum(arg_25_0, arg_25_1, arg_25_2)
	if arg_25_2 then
		return arg_25_0.composeNums_[arg_25_1][arg_25_2]
	end

	return arg_25_0.composeNums_[arg_25_1] or {}
end

function var_0_2.composeMana(arg_26_0, arg_26_1)
	return arg_26_0.composeManas_[arg_26_1]
end

function var_0_2.canCompose(arg_27_0, arg_27_1)
	return arg_27_0.canComposes_[arg_27_1] or {}
end

function var_0_2.isAwakenPiece(arg_28_0, arg_28_1)
	return arg_28_0.isAwakenPiece_[arg_28_1] or 0
end

function var_0_2.mana(arg_29_0, arg_29_1)
	return arg_29_0.manas_[arg_29_1]
end

function var_0_2.resolveResType(arg_30_0, arg_30_1)
	return arg_30_0.resolveResType_[arg_30_1] or {}
end

function var_0_2.resolveResNum(arg_31_0, arg_31_1)
	return arg_31_0.resolveResNum_[arg_31_1] or {}
end

function var_0_2.resolveEnergy(arg_32_0, arg_32_1)
	return arg_32_0.resolveEnergy_[arg_32_1]
end

function var_0_2.makeResType(arg_33_0, arg_33_1)
	return arg_33_0.makeResType_[arg_33_1] or {}
end

function var_0_2.makeResNum(arg_34_0, arg_34_1)
	return arg_34_0.makeResNum_[arg_34_1] or {}
end

function var_0_2.makeTime(arg_35_0, arg_35_1)
	return arg_35_0.makeTime_[arg_35_1]
end

function var_0_2.priceMana(arg_36_0, arg_36_1)
	return arg_36_0.priceManas_[arg_36_1]
end

function var_0_2.crystal(arg_37_0, arg_37_1)
	return arg_37_0.crystals_[arg_37_1] or 0
end

function var_0_2.priceCrystal(arg_38_0, arg_38_1)
	return arg_38_0.priceCrystals_[arg_38_1]
end

function var_0_2.energy(arg_39_0, arg_39_1)
	return arg_39_0.energys_[arg_39_1]
end

function var_0_2.magicEnergy(arg_40_0, arg_40_1)
	return arg_40_0.magicEnergys_[arg_40_1]
end

function var_0_2.magicDust(arg_41_0, arg_41_1)
	return arg_41_0.magicDusts_[arg_41_1]
end

function var_0_2.magicLiquid(arg_42_0, arg_42_1)
	return arg_42_0.magicLiquids_[arg_42_1]
end

function var_0_2.moneng(arg_43_0, arg_43_1)
	return arg_43_0.monengs_[arg_43_1]
end

function var_0_2.exp(arg_44_0, arg_44_1)
	return arg_44_0.exps_[arg_44_1]
end

function var_0_2.proficiency(arg_45_0, arg_45_1)
	return arg_45_0.proficiency_[arg_45_1] or 0
end

function var_0_2.fatigue(arg_46_0, arg_46_1)
	return arg_46_0.fatigue_[arg_46_1]
end

function var_0_2.gainType(arg_47_0, arg_47_1)
	return arg_47_0.gainType_[arg_47_1] or {}
end

function var_0_2.map(arg_48_0, arg_48_1)
	return arg_48_0.maps_[arg_48_1] or {}
end

function var_0_2.hero(arg_49_0, arg_49_1)
	return arg_49_0.heros_[arg_49_1] or {}
end

function var_0_2.stack(arg_50_0, arg_50_1)
	return arg_50_0.stacks_[arg_50_1]
end

function var_0_2.quality(arg_51_0, arg_51_1)
	return arg_51_0.qualitys_[arg_51_1] or 0
end

function var_0_2.icon(arg_52_0, arg_52_1)
	return arg_52_0.icons_[arg_52_1]
end

function var_0_2.transparentIcon(arg_53_0, arg_53_1)
	return arg_53_0.transparentIcons_[arg_53_1]
end

function var_0_2.smallIcon(arg_54_0, arg_54_1)
	return arg_54_0.smallIcons_[arg_54_1]
end

function var_0_2.heroID(arg_55_0, arg_55_1)
	return arg_55_0.heroIDs_[arg_55_1] or 0
end

function var_0_2.petID(arg_56_0, arg_56_1)
	return arg_56_0.petIDs_[arg_56_1] or 0
end

function var_0_2.fumoMana(arg_57_0, arg_57_1)
	return arg_57_0.fumoManas_[arg_57_1] or 0
end

function var_0_2.isDeleteAwakePiece(arg_58_0, arg_58_1)
	return arg_58_0.isDeleteAwakePiece_[arg_58_1] or 0
end

function var_0_2.awakePiece(arg_59_0, arg_59_1)
	return arg_59_0.awakePiece_[arg_59_1] or 0
end

function var_0_2.awakeCompose(arg_60_0, arg_60_1)
	return arg_60_0.awakeCompose_[arg_60_1] or 0
end

function var_0_2.isAwakenItem(arg_61_0, arg_61_1)
	return arg_61_0.isAwakenItem_[arg_61_1] or 0
end

function var_0_2.isAwakeTwiceItem(arg_62_0, arg_62_1)
	return arg_62_0.isAwakeTwiceItem_[arg_62_1] or 0
end

function var_0_2.getItemsByTypes(arg_63_0, arg_63_1)
	return arg_63_0.typeItems[arg_63_1] or {}
end

function var_0_2.canExchangeItem(arg_64_0, arg_64_1)
	return arg_64_0.canExchangeItems_[arg_64_1] or {}
end

function var_0_2.exchangeNeedItem(arg_65_0, arg_65_1)
	return arg_65_0.exchangeNeedItems_[arg_65_1] or {}
end

function var_0_2.exchangeNeedItemNum(arg_66_0, arg_66_1)
	return arg_66_0.exchangeNeedItemNums_[arg_66_1] or {}
end

function var_0_2.canExchangeItem(arg_67_0, arg_67_1)
	return arg_67_0.canExchangeItems_[arg_67_1] or {}
end

function var_0_2.exchangeNeedItem(arg_68_0, arg_68_1)
	return arg_68_0.exchangeNeedItems_[arg_68_1] or {}
end

function var_0_2.exchangeNeedItemNum(arg_69_0, arg_69_1)
	return arg_69_0.exchangeNeedItemNums_[arg_69_1] or {}
end

function var_0_2.skinModel(arg_70_0, arg_70_1)
	return arg_70_0.skinModel_[arg_70_1] or 0
end

function var_0_2.skinPartner(arg_71_0, arg_71_1)
	return arg_71_0.skinPartner_[arg_71_1] or 0
end

function var_0_2.skinLastTime(arg_72_0, arg_72_1)
	return arg_72_0.skinLastTime_[arg_72_1] or 0
end

function var_0_2.stylePet(arg_73_0, arg_73_1)
	return arg_73_0.stylePet_[arg_73_1] or 0
end

function var_0_2.gifts(arg_74_0, arg_74_1)
	return arg_74_0.gifts_[arg_74_1] or {}
end

function var_0_2.chooseGift(arg_75_0, arg_75_1)
	return arg_75_0.chooseGift_[arg_75_1] or {}
end

function var_0_2.inscriptId(arg_76_0, arg_76_1)
	return arg_76_0.inscriptId_[arg_76_1] or 0
end

function var_0_2.getPetUseItems(arg_77_0)
	return arg_77_0.petUseItems_
end

function var_0_2.isScreen(arg_78_0, arg_78_1)
	if arg_78_0.isScreen_[arg_78_1] == 1 then
		return true
	end

	return false
end

function var_0_2.inscriptSuitId(arg_79_0, arg_79_1)
	return arg_79_0.inscript_suit_id_[arg_79_1] or 0
end

function var_0_2.getAmour(arg_80_0, arg_80_1)
	return arg_80_0.amour_[arg_80_1] or 0
end

function var_0_2.glue(arg_81_0, arg_81_1)
	return arg_81_0.glue_[arg_81_1] or 0
end

function var_0_2.stackMail(arg_82_0, arg_82_1)
	return arg_82_0.stackMail_[arg_82_1] or 0
end

function var_0_2.skillId(arg_83_0, arg_83_1)
	return arg_83_0.skillId_[arg_83_1] or 0
end

function var_0_2.isEquipment(arg_84_0, arg_84_1)
	return arg_84_0.isEquipment_[arg_84_1] or 0
end

return var_0_2
