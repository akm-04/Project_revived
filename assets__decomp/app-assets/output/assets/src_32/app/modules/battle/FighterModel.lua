local var_0_0 = class("FighterModel", function(arg_1_0, arg_1_1)
	return display.newNode()
end)
local var_0_1 = class("HeroHeaderView", function()
	return display.newNode()
end)
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd

function var_0_0.ctor(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	arg_3_0.hero_ = arg_3_1
	arg_3_0.tableID_ = arg_3_1:getTableID()
	arg_3_0.modelID_ = arg_3_1:getModelID()
	arg_3_0.modelIDs_ = arg_3_1:getModelIDs()

	if arg_3_1.isSkinOn_ then
		local var_3_0 = var_0_3.tables.skinSkill:getSkinID()

		for iter_3_0, iter_3_1 in pairs(var_3_0) do
			if var_0_3.tables.skinSkill:getModelID(iter_3_1) == arg_3_0.modelID_ and (var_0_3.tables.skinSkill:getHeroID(iter_3_1) == arg_3_0.tableID_ or var_0_3.tables.skinSkill:getHeroID(iter_3_1) == arg_3_1:beforeAwakenID()) then
				arg_3_0.modelIDs_ = var_0_3.tables.skinSkill:getModelIDs(iter_3_1)
			end
		end
	end

	arg_3_0.scale_ = arg_3_2 or 1

	arg_3_0:setupHeroAnimation()

	arg_3_0.filterBuff_ = nil
	arg_3_0.playFloat = var_0_3.BattleType.CreateReport ~= ngx.ctx.battle.battleType
end

function var_0_0.setupHeroAnimation(arg_4_0)
	arg_4_0.models = {}
	arg_4_0.currentModel = 1

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.modelIDs_) do
		local var_4_0 = iter_4_0 == 1 and arg_4_0.modelID_ or iter_4_1
		local var_4_1 = var_0_3.HeroAnimation.new(arg_4_0.tableID_, var_4_0, arg_4_0.scale_, {
			loadAttackEffect = true
		})

		var_4_1:addTo(arg_4_0, 1)
		var_4_1:hide()
		table.insert(arg_4_0.models, var_4_1)
	end

	arg_4_0.models[1]:show()
	arg_4_0:size(arg_4_0.models[1]:getContentSize())
	arg_4_0:getBuffLayer()
end

function var_0_0.hideLayers(arg_5_0)
	arg_5_0:getEffectLayer():hide()
end

function var_0_0.getBuffLayer(arg_6_0)
	if not arg_6_0.buffLayer then
		arg_6_0.buffLayer = display.newNode()

		arg_6_0.buffLayer:size(arg_6_0:getContentSize())
		arg_6_0.buffLayer:addTo(arg_6_0, 10)
		arg_6_0.buffLayer:setName("buff_layer")
	end

	return arg_6_0.buffLayer
end

function var_0_0.getBuffLayerBack(arg_7_0)
	if not arg_7_0.buffLayerBack then
		arg_7_0.buffLayerBack = display.newNode()

		arg_7_0.buffLayerBack:size(arg_7_0:getContentSize())
		arg_7_0.buffLayerBack:addTo(arg_7_0, 0)
		arg_7_0.buffLayerBack:setName("buff_layer_back")
	end

	return arg_7_0.buffLayerBack
end

function var_0_0.getFloatLayer(arg_8_0)
	if not arg_8_0.floatLayer_ then
		arg_8_0.floatLayer_ = display.newNode()

		arg_8_0.floatLayer_:size(arg_8_0:getContentSize())
		arg_8_0.floatLayer_:addTo(arg_8_0, 11)
		arg_8_0.floatLayer_:setName("float_layer")
	end

	return arg_8_0.floatLayer_
end

function var_0_0.getEffectLayer(arg_9_0)
	if not arg_9_0.effectLayer_ then
		arg_9_0.effectLayer_ = display.newNode()

		arg_9_0.effectLayer_:size(arg_9_0:getContentSize())
		arg_9_0.effectLayer_:addTo(arg_9_0, -2)
		arg_9_0.effectLayer_:setName("effect_layer")
	end

	return arg_9_0.effectLayer_
end

function var_0_0.getHeroAnimation(arg_10_0)
	return arg_10_0.models[arg_10_0.currentModel]
end

function var_0_0.updateModelVisible(arg_11_0)
	for iter_11_0, iter_11_1 in ipairs(arg_11_0.models) do
		arg_11_0.models[iter_11_0]:setVisible(iter_11_0 == arg_11_0.currentModel)
	end
end

function var_0_0.transformModel(arg_12_0, arg_12_1)
	if arg_12_1 > #arg_12_0.models then
		error("model index is invalid " .. arg_12_1)
	end

	arg_12_0.currentModel = arg_12_1

	arg_12_0:updateModelVisible()
end

function var_0_0.playTargetCircle(arg_13_0, arg_13_1)
	if not arg_13_0.targetCircle_ then
		if not arg_13_1 then
			return
		end

		local var_13_0 = "skeletons/ui_effect/common_effect_aim/common_effect_aim"

		arg_13_0.targetCircle_ = var_0_2.new(var_13_0 .. ".json", var_13_0 .. ".atlas")

		arg_13_0.targetCircle_:addTo(arg_13_0:getEffectLayer())
		arg_13_0.targetCircle_:play(nil, true)
		arg_13_0.targetCircle_:pos(0, 0)
	end

	if arg_13_1 then
		arg_13_0.targetCircle_:show()
	else
		arg_13_0.targetCircle_:hide()
	end
end

function var_0_0.playDuskEffect(arg_14_0, arg_14_1)
	if not arg_14_0.duskEffect_ then
		local var_14_0 = "skeletons/ui_effect/effect_skill/effect_skill2"

		arg_14_0.duskEffect_ = var_0_2.new(var_14_0 .. ".json", var_14_0 .. ".atlas")

		arg_14_0.duskEffect_:addTo(arg_14_0:getEffectLayer()):align(display.CENTER, 0, 0)
	end

	if arg_14_1 then
		arg_14_0.duskEffect_:play(nil, true)
		arg_14_0.duskEffect_:show()
	else
		arg_14_0.duskEffect_:hide()
		arg_14_0.duskEffect_:stop()
	end
end

function var_0_0.addBuffs(arg_15_0, arg_15_1, arg_15_2)
	arg_15_0.buffs_ = arg_15_0.buffs_ or {}

	for iter_15_0, iter_15_1 in ipairs(arg_15_1) do
		local var_15_0 = false

		for iter_15_2, iter_15_3 in ipairs(arg_15_0.buffs_) do
			if iter_15_3:getTableID() == iter_15_1:getTableID() then
				local var_15_1 = true

				arg_15_0:removeBuffs({
					iter_15_3
				}, arg_15_2)

				break
			end
		end

		table.insert(arg_15_0.buffs_, iter_15_1)

		if iter_15_1:getResource() then
			local var_15_2 = "texiao"

			if iter_15_1:isAct() then
				var_15_2 = var_15_2 .. string.format("%02d", iter_15_1:actNum())
			end

			iter_15_1:getResource():setAnimation(0, var_15_2, true)

			local var_15_3 = iter_15_1:isBack() and arg_15_0:getBuffLayerBack() or arg_15_0:getBuffLayer()

			iter_15_1:getResource():addTo(var_15_3)

			if iter_15_1.target and not iter_15_1:ignoreFlip() then
				iter_15_1:getResource():setFlipX(iter_15_1.target:getFlipX())
			end

			if iter_15_1:position() == var_0_3.BuffPosition.Head then
				iter_15_1:getResource():align(display.CENTER_BOTTOM, arg_15_0:getHeroAnimation().headPoint.x, arg_15_0:getHeroAnimation().headPoint.y)
			elseif iter_15_1:position() == var_0_3.BuffPosition.Foot then
				iter_15_1:getResource():align(display.CENTER_BOTTOM, arg_15_0:getHeroAnimation().footPoint.x, arg_15_0:getHeroAnimation().footPoint.y)
			else
				iter_15_1:getResource():align(display.CENTER_BOTTOM, arg_15_0:getHeroAnimation().chestPoint.x, arg_15_0:getHeroAnimation().chestPoint.y)
			end
		end

		local var_15_4 = iter_15_1:getFilter()

		if var_15_4 and var_15_4.transparent then
			arg_15_0:getHeroAnimation():setOpacity(var_15_4.transparent)
			arg_15_0:hideHeaderView()
		end

		if var_15_4 and var_15_4.color then
			arg_15_0.filterBuff_ = iter_15_1

			local var_15_5 = var_15_4.color

			arg_15_0:getHeroAnimation():setMaskColor(var_15_5)
		end

		if iter_15_1:pause() then
			arg_15_0:getHeroAnimation():pause()
			arg_15_0:getHeroAnimation():setGrayScale(0.7)
		end

		if iter_15_1:getFloatText() and iter_15_1.target then
			arg_15_0:playBuffFloat(iter_15_1:getFloatText(), iter_15_1.target:getTeamType(), callback)
		end
	end

	arg_15_0:updateBuffEffects_()
end

function var_0_0.removeBuffs(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	arg_16_0.buffs_ = arg_16_0.buffs_ or {}

	for iter_16_0, iter_16_1 in ipairs(arg_16_1) do
		for iter_16_2 = #arg_16_0.buffs_, 1, -1 do
			local var_16_0 = arg_16_0.buffs_[iter_16_2]

			if var_16_0 == iter_16_1 then
				if var_16_0:getResource() then
					var_16_0:getResource():removeSelf()
				end

				local var_16_1 = var_16_0:getFilter()

				if var_16_1 and var_16_1.transparent and tonumber(arg_16_0:getHeroAnimation():getOpacity()) == var_16_1.transparent then
					arg_16_0:getHeroAnimation():setOpacity(255)
					arg_16_0:hideHeaderView(true)
				end

				if var_16_1 and var_16_1.color and arg_16_0.filterBuff_ == var_16_0 then
					arg_16_0:getHeroAnimation():unsetMaskColor()

					arg_16_0.filterBuff_ = nil
				end

				if var_16_0:pause() then
					arg_16_0:getHeroAnimation():resume()
					arg_16_0:getHeroAnimation():unsetGrayScale()
				end

				table.remove(arg_16_0.buffs_, iter_16_2)

				break
			end
		end
	end

	arg_16_0:updateBuffEffects_()
end

function var_0_0.cleanAllBuffs(arg_17_0)
	arg_17_0.buffs_ = arg_17_0.buffs_ or {}

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.buffs_) do
		if iter_17_1:getResource() then
			iter_17_1:getResource():removeSelf()
		end

		local var_17_0 = iter_17_1:getFilter()

		if var_17_0 and var_17_0.transparent and tonumber(arg_17_0:getHeroAnimation():getOpacity()) == var_17_0.transparent then
			arg_17_0:getHeroAnimation():setOpacity(255)
			arg_17_0:hideHeaderView(true)
		end

		if var_17_0 and var_17_0.color and arg_17_0.filterBuff_ == iter_17_1 then
			arg_17_0:getHeroAnimation():unsetMaskColor()

			arg_17_0.filterBuff_ = nil
		end

		if iter_17_1:pause() then
			arg_17_0:getHeroAnimation():resume()
			arg_17_0:getHeroAnimation():unsetGrayScale()
		end
	end

	arg_17_0.buffs_ = {}
end

function var_0_0.updateBuffEffects_(arg_18_0)
	for iter_18_0 = 1, #arg_18_0.buffs_ do
		if arg_18_0.buffs_[iter_18_0]:getResource() then
			arg_18_0.buffs_[iter_18_0]:getResource():setVisible(true)
		end
	end
end

function var_0_0.playNumberFloat_(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	if not arg_19_0.playFloat then
		return
	end

	local function var_19_0()
		if arg_19_2 ~= nil then
			arg_19_2()
		end
	end

	arg_19_3 = arg_19_3 or 0

	local var_19_1 = var_0_3.tables.battleConfig.floatAnimationDuration
	local var_19_2 = var_0_3.tables.battleConfig.floatAnimationDeltaY
	local var_19_3 = var_0_3.tables.battleConfig.battleFloatScaleDuration

	local function var_19_4(arg_21_0, arg_21_1)
		local var_21_0 = arg_21_0:getScale()

		arg_21_0:setAnchorPoint(cc.p(0.5, 0.5))
		arg_21_0:addTo(arg_19_0:getFloatLayer())
		var_0_3.setCascadeOpacityEnabled(arg_21_0, true)
		arg_21_0:scale(0)

		local var_21_1 = {}

		table.insert(var_21_1, cc.ScaleTo:create(var_19_3, 1.4 * var_21_0, 1.4 * var_21_0))
		table.insert(var_21_1, cc.ScaleTo:create(var_19_3 / 2, var_21_0, var_21_0))

		local var_21_2 = cc.Spawn:create({
			cc.MoveBy:create(var_19_1, cc.p(0, var_19_2)),
			cc.FadeOut:create(var_19_1)
		})

		table.insert(var_21_1, var_21_2)
		arg_21_0:setGlobalZOrder(1)
		arg_21_0:runActionOnce(transition.sequence(var_21_1), true, arg_21_1, arg_19_3)
	end

	local var_19_5 = {}
	local var_19_6 = var_0_3.tables.battleConfig.floatAnimationInternal

	for iter_19_0, iter_19_1 in ipairs(arg_19_1) do
		iter_19_1:retain()

		local var_19_7

		var_19_7 = iter_19_0 == #arg_19_1

		local function var_19_8()
			var_19_4(iter_19_1, function()
				iter_19_1:release()

				if iter_19_0 == #arg_19_1 then
					var_19_0()
				end
			end)
		end

		if #var_19_5 > 0 then
			table.insert(var_19_5, cc.DelayTime:create(var_19_6))
		end

		table.insert(var_19_5, cc.CallFunc:create(var_19_8))
	end

	if #var_19_5 <= 0 then
		var_19_0()
	else
		arg_19_0:runAction(transition.sequence(var_19_5))
	end
end

function var_0_0.playFloatAnimations_(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	if not arg_24_0.playFloat then
		return
	end

	local function var_24_0()
		if arg_24_2 ~= nil then
			arg_24_2()
		end
	end

	arg_24_3 = arg_24_3 or 0

	local var_24_1 = var_0_3.tables.battleConfig.floatAnimationDuration
	local var_24_2 = var_0_3.tables.battleConfig.floatAnimationDeltaY
	local var_24_3 = var_0_3.tables.battleConfig.battleFloatScaleDuration
	local var_24_4 = var_0_3.tables.battleConfig.floatFadeOutDelay

	local function var_24_5(arg_26_0, arg_26_1)
		local var_26_0 = arg_26_0:getScale()

		arg_26_0:setAnchorPoint(cc.p(0.5, 0.5))
		arg_26_0:addTo(arg_24_0:getFloatLayer())
		var_0_3.setCascadeOpacityEnabled(arg_26_0, true)
		arg_26_0:scale(0)
		arg_26_0:setGlobalZOrder(1)

		local var_26_1 = {}

		table.insert(var_26_1, cc.ScaleTo:create(var_24_3, 1.2 * var_26_0, 1.2 * var_26_0))
		table.insert(var_26_1, cc.ScaleTo:create(var_24_3, var_26_0, var_26_0))
		table.insert(var_26_1, cc.DelayTime:create(var_24_4))
		table.insert(var_26_1, cc.FadeOut:create(var_24_1 - var_24_4))
		arg_26_0:runActionOnce(transition.sequence(var_26_1), true, arg_26_1, arg_24_3)
	end

	local var_24_6 = {}
	local var_24_7 = var_0_3.tables.battleConfig.floatAnimationInternal

	for iter_24_0, iter_24_1 in ipairs(arg_24_1) do
		iter_24_1:retain()

		local var_24_8

		var_24_8 = iter_24_0 == #arg_24_1

		local function var_24_9()
			var_24_5(iter_24_1, function()
				iter_24_1:release()

				if iter_24_0 == #arg_24_1 then
					var_24_0()
				end
			end)
		end

		if #var_24_6 > 0 then
			table.insert(var_24_6, cc.DelayTime:create(var_24_7))
		end

		table.insert(var_24_6, cc.CallFunc:create(var_24_9))
	end

	if #var_24_6 <= 0 then
		var_24_0()
	else
		arg_24_0:runAction(transition.sequence(var_24_6))
	end
end

function var_0_0.playFloatText(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	arg_29_2 = arg_29_2 or 1

	local var_29_0 = {}

	for iter_29_0, iter_29_1 in ipairs(arg_29_1) do
		local var_29_1 = "images/battle/float_text/"
		local var_29_2 = true

		if iter_29_1 == var_0_3.BattleFloatType.MISS then
			var_29_1 = var_29_1 .. "word_miss.png"
		elseif iter_29_1 == var_0_3.BattleFloatType.BUFF_MISS then
			var_29_1 = var_29_1 .. "word_miss.png"
		else
			var_29_2 = false
		end

		if var_29_2 then
			local var_29_3 = var_0_3.AssetLoader.get():loadSprite(var_29_1)

			table.insert(var_29_0, var_29_3)

			local var_29_4 = arg_29_0:getHeroAnimation().headPoint

			var_29_3:align(display.CENTER, var_29_4.x, var_29_4.y + 70)
		end
	end

	if #var_29_0 <= 0 then
		if arg_29_3 ~= nil then
			arg_29_3()
		end
	else
		arg_29_0:playFloatAnimations_(var_29_0, arg_29_3)
	end
end

function var_0_0.playBuffFloat(arg_30_0, arg_30_1, arg_30_2, arg_30_3)
	return
end

function var_0_0.playHPDeltas(arg_31_0, arg_31_1, arg_31_2, arg_31_3)
	local var_31_0 = {}

	arg_31_3 = arg_31_3 or var_0_3.AttackType.None

	for iter_31_0, iter_31_1 in ipairs(arg_31_1) do
		local var_31_1 = iter_31_1[1]
		local var_31_2 = iter_31_1[2]
		local var_31_3 = ""
		local var_31_4 = ""

		if arg_31_3 == var_0_3.AttackType.AD or arg_31_3 == var_0_3.AttackType.None then
			var_31_3 = "battle_float_physical"
			var_31_4 = string.format("%d", math.abs(var_31_1))

			if var_31_2 then
				var_31_3 = "battle_float_physical_baoji"
				var_31_4 = string.format("%s%d", "#", math.abs(var_31_1))
			end
		elseif arg_31_3 == var_0_3.AttackType.AP then
			var_31_3 = "battle_float_magic"
			var_31_4 = string.format("%d", math.abs(var_31_1))

			if var_31_2 then
				var_31_3 = "battle_float_magic_baoji"
				var_31_4 = string.format("%s%d", "#", math.abs(var_31_1))
			end
		elseif arg_31_3 == var_0_3.AttackType.CURE then
			var_31_3 = "battle_float_cure"
			var_31_4 = string.format("%d", math.abs(var_31_1))
		end

		local var_31_5 = arg_31_0:getHeroAnimation().headPoint
		local var_31_6 = var_0_3.AssetLoader.get():loadLabel({
			text = var_31_4
		}, var_31_1 > 0 and "battle_float_cure" or var_31_3):align(display.CENTER, var_31_5.x, var_31_5.y)

		table.insert(var_31_0, var_31_6)
	end

	arg_31_0:playNumberFloat_(var_31_0, arg_31_2)
end

function var_0_0.playEnergyFloat(arg_32_0, arg_32_1)
	local var_32_0 = arg_32_0:getHeroAnimation().headPoint
	local var_32_1 = var_0_3.AssetLoader.get():loadLabel({
		text = string.format("%d", math.abs(arg_32_1))
	}, arg_32_1 > 0 and "battle_float_energy" or "battle_float_d_energy"):align(display.CENTER, var_32_0.x, var_32_0.y)

	arg_32_0:playNumberFloat_({
		var_32_1
	}, callback)
end

function var_0_0.playManaDrop(arg_33_0, arg_33_1)
	local var_33_0 = arg_33_0:getHeroAnimation().headPoint
	local var_33_1 = var_0_3.AssetLoader.get():loadLabel({
		text = string.format("%s%d%s", "+", arg_33_1, "G")
	}, "battle_float_gold"):align(display.CENTER, var_33_0.x, var_33_0.y + 20)

	arg_33_0:playNumberFloat_({
		var_33_1
	}, callback)
end

function var_0_0.playReHPMPFloat(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = arg_34_0:getHeroAnimation().headPoint
	local var_34_1 = {}
	local var_34_2 = var_0_3.AssetLoader.get():loadLabel({
		text = string.format("%d", math.abs(arg_34_1))
	}, "battle_float_cure"):align(display.CENTER, var_34_0.x, var_34_0.y)
	local var_34_3 = var_0_3.AssetLoader.get():loadLabel({
		text = string.format("%d", math.abs(arg_34_2))
	}, "battle_float_energy"):align(display.CENTER, var_34_0.x, var_34_0.y)

	if arg_34_1 > 0 then
		table.insert(var_34_1, var_34_2)
	end

	if arg_34_2 > 0 then
		table.insert(var_34_1, var_34_3)
	end

	arg_34_0:playNumberFloat_(var_34_1, callback)
end

function var_0_0.updateStateNumber(arg_35_0, arg_35_1, arg_35_2, arg_35_3)
	local function var_35_0(arg_36_0)
		local var_36_0 = arg_35_0:getHeroAnimation().headPoint
		local var_36_1 = var_0_3.AssetLoader.get():loadLabel({
			text = string.format("%d", arg_36_0)
		}, "rankFonts"):align(display.CENTER, 30, 20)

		var_36_1:width(var_36_1:getStringLength() * 20)
		var_36_1:height(20)

		if arg_35_2 then
			var_36_1:setScale(arg_35_2)
		end

		return var_36_1
	end

	if arg_35_0.stateView_ and not tolua.isnull(arg_35_0.stateView_) then
		transition.stopTarget(arg_35_0.stateView_)
		arg_35_0.stateView_:removeSelf()
	end

	if not arg_35_1 then
		return
	end

	arg_35_0.stateView_ = var_35_0(arg_35_1)

	arg_35_0.stateView_:addTo(arg_35_0:getFloatLayer())

	if not arg_35_3 then
		local var_35_1 = arg_35_2 or 1
		local var_35_2 = cc.Sequence:create(cc.ScaleTo:create(0.5, 1.5 * var_35_1), cc.ScaleTo:create(0.3, 0.8 * var_35_1), cc.ScaleTo:create(0.2, 1 * var_35_1))

		arg_35_0.stateView_:runActionOnce(var_35_2, false, function()
			local var_37_0 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))
			local var_37_1 = cc.RepeatForever:create(var_37_0)

			arg_35_0.stateView_:runAction(var_37_1)
		end)
	end
end

function var_0_0.initHeaderView(arg_38_0, arg_38_1, arg_38_2)
	if arg_38_0.headerView_ then
		arg_38_0.headerView_:removeSelf()

		arg_38_0.headerView_ = nil
	end

	arg_38_0.headerView_ = var_0_1.new():addTo(arg_38_0, 0)

	arg_38_0.headerView_:setColorType(arg_38_1)
	arg_38_0.headerView_:setHPProgress(0)
	arg_38_0.headerView_:setBuffProgress(0)
	arg_38_0.headerView_:setBuffProgressVisible(false)
	arg_38_0.headerView_:size(90, 30)
	var_0_3.setCascadeOpacityEnabled(arg_38_0, true)
	arg_38_0.headerView_:align(display.CENTER_BOTTOM, arg_38_0:getHeroAnimation().headPoint.x, arg_38_0:getHeroAnimation().headPoint.y)
	arg_38_0.headerView_:setVisible(true)
	arg_38_0.headerView_:setCount(arg_38_2)
end

function var_0_0.hideHeaderView(arg_39_0, arg_39_1)
	if arg_39_0.headerView_ ~= nil then
		arg_39_0.headerView_:setVisible(arg_39_1)
	end
end

function var_0_0.setHPProgress(arg_40_0, arg_40_1, arg_40_2, arg_40_3, arg_40_4)
	if not arg_40_0.headerView_ then
		return
	end

	arg_40_0.headerView_:setHPProgress(arg_40_1, arg_40_2, arg_40_3)

	if arg_40_4 then
		arg_40_0.headerView_:setCount(arg_40_4 + 60)
	end
end

function var_0_0.setBuffProgress(arg_41_0, arg_41_1, arg_41_2, arg_41_3)
	if not arg_41_0.headerView_ then
		return
	end

	arg_41_0.headerView_:setBuffProgress(arg_41_1, arg_41_2, arg_41_3)
end

function var_0_0.updateHeaderViewTime(arg_42_0, arg_42_1, arg_42_2)
	arg_42_0.headerView_:updateTime(arg_42_1, arg_42_2)
end

function var_0_0.updateHeroHeaderView(arg_43_0, arg_43_1, arg_43_2)
	arg_43_0.headerView_:update(arg_43_1, arg_43_2)
end

function var_0_0.setBackMaskColor(arg_44_0, arg_44_1)
	local var_44_0 = arg_44_0:getBuffLayer():getChildren()

	for iter_44_0, iter_44_1 in ipairs(var_44_0) do
		iter_44_1:setMaskColor(arg_44_1)
	end

	local var_44_1 = arg_44_0:getBuffLayerBack():getChildren()

	for iter_44_2, iter_44_3 in ipairs(var_44_1) do
		iter_44_3:setMaskColor(arg_44_1)
	end

	arg_44_0.headerView_:setDuskMask()
end

function var_0_0.setMaskColor(arg_45_0, arg_45_1)
	arg_45_0:getHeroAnimation():setMaskColor(arg_45_1)
	arg_45_0:setBackMaskColor(arg_45_1)
end

function var_0_0.unsetBackMaskColor(arg_46_0)
	local var_46_0 = arg_46_0:getBuffLayer():getChildren()

	for iter_46_0, iter_46_1 in ipairs(var_46_0) do
		iter_46_1:unsetMaskColor()
	end

	local var_46_1 = arg_46_0:getBuffLayerBack():getChildren()

	for iter_46_2, iter_46_3 in ipairs(var_46_1) do
		iter_46_3:unsetMaskColor()
	end

	arg_46_0.headerView_:unsetDuskMask()
end

function var_0_0.unsetMaskColor(arg_47_0)
	arg_47_0:getHeroAnimation():unsetMaskColor()
	arg_47_0:unsetBackMaskColor()
end

function var_0_0.setGrayScale(arg_48_0, arg_48_1)
	arg_48_0:getHeroAnimation():setGrayScale(arg_48_1)

	local var_48_0 = arg_48_0:getBuffLayer():getChildren()

	for iter_48_0, iter_48_1 in ipairs(var_48_0) do
		iter_48_1:setGrayScale(arg_48_1)
	end

	local var_48_1 = arg_48_0:getBuffLayerBack():getChildren()

	for iter_48_2, iter_48_3 in ipairs(var_48_1) do
		iter_48_3:setGrayScale(arg_48_1)
	end
end

function var_0_0.unsetGrayScale(arg_49_0)
	arg_49_0:getHeroAnimation():unsetGrayScale()

	local var_49_0 = arg_49_0:getBuffLayer():getChildren()

	for iter_49_0, iter_49_1 in ipairs(var_49_0) do
		iter_49_1:unsetGrayScale()
	end

	local var_49_1 = arg_49_0:getBuffLayerBack():getChildren()

	for iter_49_2, iter_49_3 in ipairs(var_49_1) do
		iter_49_3:unsetGrayScale()
	end
end

function var_0_0.setLeader(arg_50_0)
	if not arg_50_0.leaderEffect_ then
		arg_50_0.leaderEffect_ = var_0_3.AssetLoader.get():loadSprite("images/battle_manual_1_2.png")

		arg_50_0.leaderEffect_:addTo(arg_50_0:getEffectLayer())
		arg_50_0.leaderEffect_:align(display.CENTER, 0, 0)
		arg_50_0.leaderEffect_:setOpacity(150)
	end
end

function var_0_1.ctor(arg_51_0)
	return
end

function var_0_1.setColorType(arg_52_0, arg_52_1)
	arg_52_0.color_ = arg_52_1
end

function var_0_1.setDuskMask(arg_53_0)
	if arg_53_0.hpProgress_ then
		arg_53_0.hpProgress_.duskMask = true
	end

	if arg_53_0.buffProgress_ then
		arg_53_0.buffProgress_.duskMask = true
	end

	arg_53_0:setHPProgressVisible(arg_53_0.hpProgress_:isVisible())
	arg_53_0:setBuffProgressVisible(arg_53_0.buffProgress_:isVisible())
end

function var_0_1.unsetDuskMask(arg_54_0)
	if arg_54_0.hpProgress_ then
		arg_54_0.hpProgress_.duskMask = nil
	end

	if arg_54_0.buffProgress_ then
		arg_54_0.buffProgress_.duskMask = nil
	end

	arg_54_0:setHPProgressVisible(arg_54_0.hpProgress_:isVisible())
	arg_54_0:setBuffProgressVisible(arg_54_0.buffProgress_:isVisible())
end

function var_0_1.setHPProgress(arg_55_0, arg_55_1, arg_55_2, arg_55_3)
	if arg_55_0.hpProgress_ == nil then
		arg_55_0.hpBackSp = var_0_3.AssetLoader.get():loadSprite("images/battle_bar_bg.png")

		local var_55_0 = var_0_3.AssetLoader.get():loadSprite("images/battle_hp_bar2.png")
		local var_55_1 = arg_55_0.color_ and arg_55_0.color_ > 0 and "images/battle_hp_bar3.png" or "images/battle_hp_bar1.png"
		local var_55_2 = "images/bar_dusk.png"
		local var_55_3 = var_0_3.AssetLoader.get():loadSprite(var_55_1)

		arg_55_0.duskMask = var_0_3.AssetLoader.get():loadSprite(var_55_2)
		arg_55_0.hpProgress_ = display.newProgressTimer(var_55_3, display.PROGRESS_TIMER_BAR):align(display.LEFT_TOP, 0, 30):addTo(arg_55_0, -1)

		arg_55_0.hpProgress_:setMidpoint(cc.p(0, 0))
		arg_55_0.hpProgress_:setBarChangeRate(cc.p(1, 0))
		arg_55_0.hpProgress_:setPercentage(0)

		arg_55_0.easeProgress_ = display.newProgressTimer(var_55_0, display.PROGRESS_TIMER_BAR):align(display.LEFT_TOP, 0, 30):addTo(arg_55_0, -2)

		arg_55_0.easeProgress_:setMidpoint(cc.p(0, 0))
		arg_55_0.easeProgress_:setBarChangeRate(cc.p(1, 0))
		arg_55_0.easeProgress_:setPercentage(0)
		arg_55_0.hpBackSp:align(display.LEFT_TOP, 0, 30):addTo(arg_55_0, -3)
		arg_55_0.duskMask:align(display.LEFT_TOP, 0, 30):addTo(arg_55_0, 0)
		arg_55_0.duskMask:hide()
	end

	local var_55_4 = arg_55_0.hpProgress_:getPercentage() < arg_55_1 * 100

	arg_55_0:setBarProgress_(arg_55_0.hpProgress_, arg_55_1, var_55_4)
	arg_55_0:setBarProgress_(arg_55_0.easeProgress_, arg_55_1, arg_55_2, function()
		if arg_55_1 == 0 then
			arg_55_0:setHPProgressVisible(false)
			arg_55_0:setBuffProgressVisible(false)
		end

		if arg_55_3 ~= nil then
			arg_55_3()
		end
	end)
end

function var_0_1.setBuffProgress(arg_57_0, arg_57_1, arg_57_2, arg_57_3)
	if arg_57_0.buffProgress_ == nil then
		local var_57_0 = var_0_3.AssetLoader.get():loadSprite("images/battle_buff_bar.png")

		arg_57_0.buffSpDusk = var_0_3.AssetLoader.get():loadSprite("images/bar_dusk.png")
		arg_57_0.buffBackSp_ = var_0_3.AssetLoader.get():loadSprite("images/battle_bar_bg.png")
		arg_57_0.buffProgress_ = display.newProgressTimer(var_57_0, display.PROGRESS_TIMER_BAR):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_57_0, -1)

		arg_57_0.buffProgress_:setMidpoint(cc.p(0, 0))
		arg_57_0.buffProgress_:setBarChangeRate(cc.p(1, 0))
		arg_57_0.buffProgress_:setPercentage(0)
		arg_57_0.buffBackSp_:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_57_0, -3)
		arg_57_0.buffSpDusk:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_57_0, 0):hide()
	end

	arg_57_0:setBarProgress_(arg_57_0.buffProgress_, arg_57_1, arg_57_2, arg_57_3)
end

function var_0_1.setHPProgressVisible(arg_58_0, arg_58_1)
	if arg_58_0.hpProgress_ then
		arg_58_0.hpProgress_:setVisible(arg_58_1)
		arg_58_0.easeProgress_:setVisible(arg_58_1)
		arg_58_0.hpBackSp:setVisible(arg_58_1)
		arg_58_0.duskMask:setVisible(arg_58_1 and arg_58_0.hpProgress_.duskMask)
	end
end

function var_0_1.setBuffProgressVisible(arg_59_0, arg_59_1)
	if arg_59_0.buffBackSp_ then
		arg_59_0.buffBackSp_:setVisible(arg_59_1)
		arg_59_0.buffProgress_:setVisible(arg_59_1)
		arg_59_0.buffSpDusk:setVisible(arg_59_1 and arg_59_0.buffProgress_.duskMask)
	end
end

function var_0_1.setBarProgress_(arg_60_0, arg_60_1, arg_60_2, arg_60_3, arg_60_4)
	arg_60_1:stopAllActions()

	arg_60_2 = arg_60_2 * 100

	if tonumber(arg_60_3) then
		arg_60_1:runActionOnce(cc.ProgressTo:create(tonumber(arg_60_3), arg_60_2), false, arg_60_4)
	elseif arg_60_3 then
		local var_60_0 = arg_60_1:getPercentage()
		local var_60_1 = arg_60_2 - var_60_0
		local var_60_2 = var_0_3.tables.battleConfig.hpProgressMoveBase + var_0_3.tables.battleConfig.hpProgressMoveStep * math.abs(var_60_1)
		local var_60_3 = var_0_3.tables.battleConfig.hpProgressBrakeBase
		local var_60_4 = var_60_0 + var_60_1 * (1 - var_0_3.tables.battleConfig.hpProgressBrakePercent)
		local var_60_5 = arg_60_2
		local var_60_6 = cc.Sequence:create(cc.ProgressTo:create(var_60_2, var_60_4), cc.ProgressTo:create(var_60_3, var_60_5))

		arg_60_1:runActionOnce(var_60_6, false, arg_60_4)
	else
		arg_60_1:setPercentage(arg_60_2)

		if arg_60_4 ~= nil then
			arg_60_4()
		end
	end
end

function var_0_1.setCount(arg_61_0, arg_61_1)
	arg_61_0.count_ = arg_61_1 or 0
end

function var_0_1.getCount(arg_62_0)
	return arg_62_0.count_ or 0
end

function var_0_1.update(arg_63_0, arg_63_1, arg_63_2)
	if not arg_63_2 then
		arg_63_0:setBuffProgressVisible(false)
	else
		if not arg_63_0.buffProgress_:isVisible() then
			arg_63_0:setBuffProgress(0)
		end

		arg_63_0:setHPProgressVisible(true)
		arg_63_0:setBuffProgressVisible(true)

		local var_63_0 = arg_63_2:getDHarm() / arg_63_2:totalDHarm()

		arg_63_0:setBuffProgress(var_63_0, true)
	end
end

function var_0_1.updateTime(arg_64_0, arg_64_1, arg_64_2)
	if arg_64_1 > arg_64_0:getCount() and not arg_64_2 then
		arg_64_0:setHPProgressVisible(false)
	else
		arg_64_0:setHPProgressVisible(true)
	end
end

return var_0_0
