local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("FighterModel", var_0_1.ctx.battle.getRequire("BattleBaseNode"))
local var_0_4 = var_0_0.class("HeroHeaderView")

function var_0_3.ctor(arg_1_0, arg_1_1, arg_1_2, arg_1_3)
	var_0_3.super.ctor(arg_1_0)

	arg_1_0.hero_ = arg_1_1
	arg_1_0.tableID_ = arg_1_1:getTableID()
	arg_1_0.modelID_ = arg_1_1:getModelID()
	arg_1_0.modelIDs_ = arg_1_1:getModelIDs()

	if arg_1_1.isSkinOn_ then
		local var_1_0 = var_0_2.tables.skinSkill:getSkinID()

		for iter_1_0, iter_1_1 in pairs(var_1_0) do
			if var_0_2.tables.skinSkill:getModelID(iter_1_1) == arg_1_0.modelID_ and (var_0_2.tables.skinSkill:getHeroID(iter_1_1) == arg_1_0.tableID_ or var_0_2.tables.skinSkill:getHeroID(iter_1_1) == arg_1_1:beforeAwakenID()) then
				arg_1_0.modelIDs_ = var_0_2.tables.skinSkill:getModelIDs(iter_1_1)
			end
		end
	end

	arg_1_0.scale_ = arg_1_2 or 1

	arg_1_0:setupHeroAnimation()

	arg_1_0.filterBuff_ = nil
	arg_1_0.playFloat = var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType
	arg_1_0.x_ = 0
	arg_1_0.y_ = 0
end

function var_0_3.setupHeroAnimation(arg_2_0)
	arg_2_0.models = {}
	arg_2_0.currentModel = 1

	local var_2_0 = var_0_0.import("lib.battle.HeroAnimation")

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.modelIDs_) do
		local var_2_1 = iter_2_0 == 1 and arg_2_0.modelID_ or iter_2_1
		local var_2_2 = var_2_0.new(arg_2_0.tableID_, var_2_1, arg_2_0.scale_, {
			loadAttackEffect = true
		})

		var_2_2:addTo(arg_2_0, 1)
		table.insert(arg_2_0.models, var_2_2)
	end

	arg_2_0:size(arg_2_0.models[1]:getContentSize())
	arg_2_0:getBuffLayer()
end

function var_0_3.getBuffLayer(arg_3_0)
	return
end

function var_0_3.getBuffLayerBack(arg_4_0)
	return
end

function var_0_3.getFloatLayer(arg_5_0)
	return
end

function var_0_3.getEffectLayer(arg_6_0)
	return
end

function var_0_3.hideLayers(arg_7_0)
	return
end

function var_0_3.getHeroAnimation(arg_8_0)
	return arg_8_0.models[arg_8_0.currentModel]
end

function var_0_3.updateModelVisible(arg_9_0)
	return
end

function var_0_3.transformModel(arg_10_0, arg_10_1)
	if arg_10_1 > #arg_10_0.models then
		error("model index is invalid " .. arg_10_1)
	end

	arg_10_0.currentModel = arg_10_1
end

function var_0_3.playTargetCircle(arg_11_0, arg_11_1)
	return
end

function var_0_3.playDuskEffect(arg_12_0, arg_12_1)
	return
end

function var_0_3.addBuffs(arg_13_0, arg_13_1, arg_13_2)
	return
end

function var_0_3.removeBuffs(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	return
end

function var_0_3.cleanAllBuffs(arg_15_0)
	return
end

function var_0_3.updateBuffEffects_(arg_16_0)
	return
end

function var_0_3.playNumberFloat_(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	return
end

function var_0_3.playFloatAnimations_(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	return
end

function var_0_3.playFloatText(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	return
end

function var_0_3.playBuffFloat(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	return
end

function var_0_3.playHPDeltas(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	return
end

function var_0_3.playEnergyFloat(arg_22_0, arg_22_1)
	return
end

function var_0_3.playManaDrop(arg_23_0, arg_23_1)
	return
end

function var_0_3.playReHPMPFloat(arg_24_0, arg_24_1, arg_24_2)
	return
end

function var_0_3.initHeaderView(arg_25_0, arg_25_1, arg_25_2)
	return
end

function var_0_3.hideHeaderView(arg_26_0, arg_26_1)
	return
end

function var_0_3.setHPProgress(arg_27_0, arg_27_1, arg_27_2, arg_27_3, arg_27_4)
	return
end

function var_0_3.setBuffProgress(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	return
end

function var_0_3.updateHeaderViewTime(arg_29_0, arg_29_1, arg_29_2)
	return
end

function var_0_3.updateHeroHeaderView(arg_30_0, arg_30_1, arg_30_2)
	return
end

function var_0_3.setupMaskShader(arg_31_0)
	return
end

function var_0_3.setMaskColor(arg_32_0, arg_32_1)
	return
end

function var_0_3.unsetMaskColor(arg_33_0)
	return
end

function var_0_3.setGrayScale(arg_34_0, arg_34_1)
	return
end

function var_0_3.unsetGrayScale(arg_35_0)
	return
end

function var_0_4.ctor(arg_36_0)
	return
end

function var_0_4.setColorType(arg_37_0, arg_37_1)
	return
end

function var_0_4.setHPProgress(arg_38_0, arg_38_1, arg_38_2, arg_38_3)
	return
end

function var_0_4.setBuffProgress(arg_39_0, arg_39_1, arg_39_2, arg_39_3)
	return
end

function var_0_4.setHPProgressVisible(arg_40_0, arg_40_1)
	return
end

function var_0_4.setBuffProgressVisible(arg_41_0, arg_41_1)
	return
end

function var_0_4.setBarProgress_(arg_42_0, arg_42_1, arg_42_2, arg_42_3, arg_42_4)
	return
end

function var_0_4.setCount(arg_43_0, arg_43_1)
	return
end

function var_0_4.getCount(arg_44_0)
	return
end

function var_0_4.update(arg_45_0, arg_45_1, arg_45_2)
	return
end

function var_0_4.updateTime(arg_46_0, arg_46_1, arg_46_2)
	return
end

function var_0_3.updateStateNumber(arg_47_0, arg_47_1)
	return
end

function var_0_3.setBackMaskColor(arg_48_0, arg_48_1)
	return
end

function var_0_3.unsetBackMaskColor(arg_49_0)
	return
end

return var_0_3
