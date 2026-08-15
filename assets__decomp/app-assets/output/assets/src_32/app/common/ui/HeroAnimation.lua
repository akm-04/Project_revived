local var_0_0 = class("HeroAnimation", function(arg_1_0, arg_1_1, arg_1_2)
	return (display.newNode())
end)
local var_0_1 = class("HeroHeaderView", function()
	return display.newNode()
end)
local var_0_2 = xyd.tables.skill
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4)
	arg_3_0.handler = cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.PRELOAD_MODEL_SUCCESS, function(arg_4_0)
		if arg_3_0 and not tolua.isnull(arg_3_0) and not arg_3_0.isChange and arg_3_2 == arg_4_0.modelID then
			local var_4_0, var_4_1 = xyd.tables.model:resource(arg_3_2)

			if not xyd.assetDownloadErrorLog(var_4_0) then
				return
			end

			local var_4_2 = sp.SkeletonAnimation:create(var_4_0, var_4_1, arg_3_3 or 1)

			arg_3_0.isChange = true

			if arg_3_0.hasDefault then
				local var_4_3 = cc.Sequence:create({
					cc.Spawn:create({
						cc.ScaleTo:create(1, 0),
						cc.FadeTo:create(1, 0)
					}),
					cc.CallFunc:create(function()
						arg_3_0:removeChildByName("common")
					end)
				})

				arg_3_0.model:runActionOnce(var_4_3)

				if arg_3_0.label and not tolua.isnull(arg_3_0.label) then
					arg_3_0.label:removeSelf()

					arg_3_0.label = nil
				end
			end

			arg_3_0:addChild(var_4_2)
			var_4_2:setName("model")
			arg_3_0:setContentSize(var_4_2:getContentSize())

			arg_3_0.model = arg_3_0:getChildByName("model")

			if arg_3_0.hasDefault then
				var_4_2:setOpacity(0)

				local var_4_4 = cc.Sequence:create({
					cc.Spawn:create({
						cc.FadeTo:create(1, 255)
					})
				})

				arg_3_0.model:runActionOnce(var_4_4)
			end

			arg_3_0.numberOfAttackAnimations = arg_3_0:getNumberOfAttackAnimations_()

			arg_3_0:setupPoints_()

			arg_3_0.attackEffects_ = {}

			if arg_3_4 ~= nil and arg_3_4.loadAttackEffect then
				arg_3_0:setupAttackEffects_()
				arg_3_0:setupEnergyEffect_()
			end

			arg_3_0:setFlipX(arg_3_0.isFlip or false)
			arg_3_0:updateTo(0)
			arg_3_0:clearTracks()

			if arg_3_0.currentAnimation_ then
				if arg_3_0.currentAnimation_ == "dead" then
					arg_3_0:playAnimation_(arg_3_0.currentAnimation_, false)
				else
					arg_3_0:playAnimation_(arg_3_0.currentAnimation_, true)
				end
			else
				arg_3_0:idle()
			end

			if arg_3_0.headerView_ then
				arg_3_0.headerView_:align(display.CENTER_BOTTOM, arg_3_0.headPoint.x, arg_3_0.headPoint.y)
			end
		end
	end)

	local var_3_0, var_3_1 = xyd.tables.model:resource(arg_3_2)

	xyd.AssetLoader.get():loadSkeletonAnimation(arg_3_0, arg_3_2)

	if not arg_3_0.isChange then
		local var_3_2 = "skeletons/common_model/effect_tongyong"
		local var_3_3 = var_3_2 .. ".json"
		local var_3_4 = var_3_2 .. ".atlas"
		local var_3_5 = sp.SkeletonAnimation:create(var_3_3, var_3_4, arg_3_3 or 1)

		var_3_5:addTo(arg_3_0)
		var_3_5:setName("common")
		arg_3_0:setContentSize(var_3_5:getContentSize())

		arg_3_0.model = arg_3_0:getChildByName("common")
		arg_3_0.hasDefault = true

		local var_3_6 = {
			size = 28,
			color = cc.c3b(255, 255, 255)
		}

		arg_3_0.label = xyd.AssetLoader.get():loadLabel(var_3_6)

		arg_3_0.label:setMaxLineWidth(50)
		arg_3_0.label:addTo(arg_3_0)
		arg_3_0.label:setName("progress")
		arg_3_0.label:setAnchorPoint(0.5, 0.5)
		arg_3_0.label:setPosition(0, 100 * (arg_3_3 or 1))
		arg_3_0.label:setString("")
		arg_3_0.label:enableOutline(cc.c4b(136, 15, 0, 255), 1)
	end

	arg_3_0.tableID_ = arg_3_1
	arg_3_0.modelID_ = arg_3_2
	arg_3_0.scale_ = arg_3_3 or 1
	arg_3_0.numberOfAttackAnimations = arg_3_0:getNumberOfAttackAnimations_()

	arg_3_0:setupPoints_()

	arg_3_0.attackEffects_ = {}
	arg_3_0.isFlip = false

	if arg_3_4 ~= nil and arg_3_4.loadAttackEffect then
		arg_3_0:setupAttackEffects_()
		arg_3_0:setupEnergyEffect_()
	end

	arg_3_0.currentAnimation_ = nil

	arg_3_0:idle()
	arg_3_0.model:updateTo(0)
	arg_3_0.model:clearTracks()
	xyd.setCascadeOpacityEnabled(arg_3_0.model, true)
end

function var_0_0.setPercent(arg_6_0, arg_6_1)
	if arg_6_0.label and not tolua.isnull(arg_6_0.label) and arg_6_1 then
		arg_6_0.label:setVisible(true)
		arg_6_0.label:setString(arg_6_1 .. "%")
		arg_6_0.label:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	end
end

function var_0_0.updateTo(arg_7_0, arg_7_1)
	return arg_7_0.model:updateTo(arg_7_1)
end

function var_0_0.clearTracks(arg_8_0)
	return arg_8_0.model:clearTracks()
end

function var_0_0.flipX(arg_9_0, arg_9_1)
	arg_9_0:setFlipX(arg_9_1)

	if arg_9_1 ~= arg_9_0:getFlipX() then
		for iter_9_0, iter_9_1 in ipairs(arg_9_0.attackEffects_) do
			if iter_9_1 ~= nil then
				iter_9_1:setFlipX(arg_9_1)
			end
		end

		arg_9_0.leftPoint, arg_9_0.rightPoint = arg_9_0:flipPoint_(arg_9_0.rightPoint), arg_9_0:flipPoint_(arg_9_0.leftPoint)
		arg_9_0.chestPoint = arg_9_0:flipPoint_(arg_9_0.chestPoint)
		arg_9_0.headPoint = arg_9_0:flipPoint_(arg_9_0.headPoint)
		arg_9_0.attackedPoint = arg_9_0:flipPoint_(arg_9_0.attackedPoint)

		for iter_9_2, iter_9_3 in ipairs(arg_9_0.attackPoints) do
			arg_9_0.attackPoints[iter_9_2] = arg_9_0:flipPoint_(iter_9_3)
		end
	end

	return arg_9_0.model
end

function var_0_0.getFlipX(arg_10_0)
	return arg_10_0.isFlip
end

function var_0_0.setFlipX(arg_11_0, arg_11_1)
	arg_11_0.isFlip = arg_11_1

	if arg_11_0.model:getName() ~= "common" then
		arg_11_0.model:setFlipX(arg_11_1)
	end
end

function var_0_0.showHeaderView(arg_12_0, arg_12_1, arg_12_2)
	if arg_12_0.headerView_ == nil then
		arg_12_0.headerView_ = var_0_1.new():addTo(arg_12_0.model, 1)

		arg_12_0.headerView_:setHPProgress(0)
		arg_12_0.headerView_:setActionProgress(0)
		arg_12_0.headerView_:setArrowVisible(false)
		xyd.setCascadeOpacityEnabled(arg_12_0.model, true)
	end

	arg_12_0.headerView_:setBorderByHeroClass(arg_12_1)
	arg_12_0.headerView_:setLevel(arg_12_2)
	arg_12_0.headerView_:align(display.CENTER_BOTTOM, arg_12_0.headPoint.x, arg_12_0.headPoint.y)
	arg_12_0.headerView_:setVisible(true)
end

function var_0_0.hideHeaderView(arg_13_0, arg_13_1)
	if arg_13_0.headerView_ ~= nil then
		arg_13_0.headerView_:setVisible(isTrue)
	end
end

function var_0_0.addBuffs(arg_14_0, arg_14_1, arg_14_2)
	arg_14_0.buffs_ = arg_14_0.buffs_ or {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_1) do
		local var_14_0 = false

		for iter_14_2, iter_14_3 in ipairs(arg_14_0.buffs_) do
			if iter_14_3:getTableID() == iter_14_1:getTableID() then
				var_14_0 = true

				break
			end
		end

		if not var_14_0 then
			table.insert(arg_14_0.buffs_, iter_14_1)

			if iter_14_1:getResource() then
				iter_14_1:getResource():setAnimation(0, "texiao", true)
				iter_14_1:getResource():addTo(arg_14_0.model, 30)

				if iter_14_1:position() == xyd.BuffPosition.Head then
					iter_14_1:getResource():align(display.CENTER_BOTTOM, arg_14_0.headPoint.x, arg_14_0.headPoint.y)
				elseif iter_14_1:position() == xyd.BuffPosition.Foot then
					iter_14_1:getResource():align(display.CENTER_BOTTOM, arg_14_0.footPoint.x, arg_14_0.footPoint.y)
				else
					iter_14_1:getResource():align(display.CENTER_BOTTOM, arg_14_0.chestPoint.x, arg_14_0.chestPoint.y)
				end
			end

			local var_14_1 = iter_14_1:getFilter()

			if var_14_1 and var_14_1.transparent then
				arg_14_0:setOpacity(arg_14_0:getMinOpacity())
			end

			if var_14_1 and var_14_1[1] and var_14_1[2] and var_14_1[3] then
				arg_14_0:modelFilter(var_14_1)
			end
		end
	end

	arg_14_0:updateBuffEffects_()
end

function var_0_0.setOpacity(arg_15_0, arg_15_1)
	return arg_15_0.model:setOpacity(arg_15_1)
end

function var_0_0.setMaskColor(arg_16_0, arg_16_1)
	return arg_16_0.model:setMaskColor(arg_16_1)
end

function var_0_0.unsetMaskColor(arg_17_0)
	return arg_17_0.model:unsetMaskColor()
end

function var_0_0.unsetGrayScale(arg_18_0)
	return arg_18_0.model:unsetGrayScale()
end

function var_0_0.getMinOpacity(arg_19_0)
	local var_19_0 = 255

	for iter_19_0, iter_19_1 in pairs(arg_19_0.buffs_ or {}) do
		if iter_19_1 and iter_19_1.transparent and var_19_0 > iter_19_1.transparent then
			var_19_0 = iter_19_1.transparent
		end
	end

	return var_19_0
end

function var_0_0.removeBuffs(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	arg_20_0.buffs_ = arg_20_0.buffs_ or {}

	for iter_20_0, iter_20_1 in ipairs(arg_20_1) do
		for iter_20_2 = #arg_20_0.buffs_, 1, -1 do
			local var_20_0 = arg_20_0.buffs_[iter_20_2]

			if var_20_0:getTableID() == iter_20_1:getTableID() then
				if arg_20_2 > var_20_0:getStartTime() + var_20_0:getTime() or arg_20_3 then
					if var_20_0:getResource() then
						var_20_0:getResource():removeSelf()
					end

					local var_20_1 = var_20_0:getFilterReverse()

					if var_20_1 and var_20_1.transparent and tonumber(arg_20_0:getOpacity()) == var_20_1.transparent then
						arg_20_0:setOpacity(arg_20_0:getMinOpacity())
					end

					if var_20_1 and var_20_1[1] and var_20_1[2] and var_20_1[3] then
						arg_20_0:modelFilter(var_20_1)
					end

					table.remove(arg_20_0.buffs_, iter_20_2)
				end

				break
			end
		end
	end

	arg_20_0:updateBuffEffects_()
end

function var_0_0.updateBuffEffects_(arg_21_0)
	for iter_21_0 = 1, #arg_21_0.buffs_ do
		if arg_21_0.buffs_[iter_21_0]:getResource() then
			arg_21_0.buffs_[iter_21_0]:getResource():setVisible(true)
		end
	end
end

function var_0_0.getOpacity(arg_22_0)
	return arg_22_0.model:getOpacity()
end

function var_0_0.playAttribute(arg_23_0, arg_23_1)
	local var_23_0 = {}
	local var_23_1 = {
		size = 24,
		align = cc.ui.TEXT_ALIGN_CENTER,
		x = arg_23_0.chestPoint.x,
		y = arg_23_0.chestPoint.y,
		font = xyd.AssetLoader.FONT_NAME,
		color = cc.c3b(247, 217, 54)
	}

	for iter_23_0, iter_23_1 in pairs(arg_23_1) do
		var_23_1.text = xyd.tables.attr:name(iter_23_0) .. "+" .. iter_23_1

		local var_23_2 = xyd.AssetLoader.get():loadLabel(var_23_1)

		var_23_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_23_2:enableOutline(cc.c4b(0, 0, 0, 155), 1)
		table.insert(var_23_0, var_23_2)
	end

	arg_23_0:playFloatAnimations_(var_23_0, callback)
end

function var_0_0.playAttackResultTypes(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = arg_24_0.headPoint.y + 20
	local var_24_1 = arg_24_0:getFlipX()
	local var_24_2 = {}

	for iter_24_0, iter_24_1 in ipairs(arg_24_1) do
		local var_24_3

		if iter_24_1 == xyd.AttackResultType.MISS then
			var_24_3 = "battle_buff_miss.png"
		elseif iter_24_1 == xyd.AttackResultType.CRIT then
			var_24_3 = "battle_crit.png"
		elseif iter_24_1 == xyd.AttackResultType.STRONG then
			var_24_3 = "battle_strong.png"
		elseif iter_24_1 == xyd.AttackResultType.BUFF_MISS then
			var_24_3 = "battle_miss.png"
		end

		if var_24_3 ~= nil and #var_24_3 > 0 then
			local var_24_4 = xyd.AssetLoader.get():loadSprite(var_24_3)

			table.insert(var_24_2, var_24_4)

			if var_24_1 then
				var_24_4:align(display.RIGHT_BOTTOM, arg_24_0.leftPoint.x, var_24_0)
			else
				var_24_4:align(display.LEFT_BOTTOM, arg_24_0.rightPoint.x, var_24_0)
			end
		end
	end

	if #var_24_2 <= 0 then
		if arg_24_2 ~= nil then
			arg_24_2()
		end
	else
		arg_24_0:playFloatAnimations_(var_24_2, arg_24_2)
	end
end

function var_0_0.setHPProgress(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	if arg_25_0.headerView_ ~= nil then
		arg_25_0.headerView_:setHPProgress(arg_25_1, arg_25_2, arg_25_3)
	end
end

function var_0_0.setActionProgress(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	if arg_26_0.headerView_ ~= nil then
		arg_26_0.headerView_:setActionProgress(arg_26_1, arg_26_2, arg_26_3)
	end
end

function var_0_0.setArrowVisible(arg_27_0, arg_27_1, arg_27_2)
	if arg_27_0.headerView_ ~= nil then
		arg_27_0.headerView_:setArrowVisible(arg_27_1, arg_27_2)
	end
end

function var_0_0.stop(arg_28_0)
	arg_28_0:clearTracks()
end

function var_0_0.pause(arg_29_0)
	getmetatable(cc.Node).pause(arg_29_0.model)

	if arg_29_0.blinkEffect_ ~= nil then
		arg_29_0.blinkEffect_:pause()
	end

	if arg_29_0.headerView_ ~= nil then
		arg_29_0.headerView_:pause()
	end
end

function var_0_0.resume(arg_30_0)
	getmetatable(cc.Node).resume(arg_30_0.model)

	if arg_30_0.blinkEffect_ ~= nil then
		arg_30_0.blinkEffect_:resume()
	end

	if arg_30_0.headerView_ ~= nil then
		arg_30_0.headerView_:resume()
	end
end

function var_0_0.setTimeScale(arg_31_0, arg_31_1)
	getmetatable(sp.SkeletonAnimation).setTimeScale(arg_31_0.model, arg_31_1)

	for iter_31_0 = 1, arg_31_0.numberOfAttackAnimations do
		local var_31_0 = arg_31_0.attackEffects_[iter_31_0]

		if var_31_0 ~= nil then
			var_31_0:setTimeScale(arg_31_1)
		end
	end
end

function var_0_0.idle(arg_32_0, arg_32_1)
	return arg_32_0:playAnimation_("idle", true, nil, nil, arg_32_1)
end

function var_0_0.walk(arg_33_0, arg_33_1, arg_33_2)
	return arg_33_0:playAnimation_("run", arg_33_1, nil, nil, arg_33_2)
end

function var_0_0.die(arg_34_0, arg_34_1)
	return arg_34_0:playAnimation_("dead", false, nil, nil, arg_34_1)
end

function var_0_0.rest(arg_35_0, arg_35_1, arg_35_2)
	return arg_35_0:playAnimation_("rest", arg_35_1, nil, nil, arg_35_2)
end

function var_0_0.attack(arg_36_0, arg_36_1, arg_36_2, arg_36_3, arg_36_4, arg_36_5, arg_36_6)
	arg_36_0.playingAttackAnimationIndex_ = arg_36_1

	local var_36_0 = arg_36_6 or false

	return arg_36_0:playAnimation_(arg_36_0:attackAnimationName_(arg_36_1), var_36_0, arg_36_2, arg_36_3, arg_36_4, arg_36_5)
end

function var_0_0.attacked(arg_37_0, arg_37_1)
	return arg_37_0:playAnimation_("hurt", false, nil, nil, arg_37_1)
end

function var_0_0.treasure(arg_38_0, arg_38_1, arg_38_2)
	return arg_38_0:playAnimation_("treasure", arg_38_1, nil, nil, arg_38_2)
end

function var_0_0.win(arg_39_0, arg_39_1, arg_39_2)
	return arg_39_0:playAnimation_("win", arg_39_1, nil, nil, arg_39_2)
end

function var_0_0.look(arg_40_0, arg_40_1, arg_40_2)
	return arg_40_0:playAnimation_("look", arg_40_1, nil, nil, arg_40_2)
end

function var_0_0.summon(arg_41_0, arg_41_1)
	return arg_41_0:playAnimation_("summon", false, nil, nil, arg_41_1)
end

function var_0_0.change(arg_42_0, arg_42_1)
	return arg_42_0:playAnimation_("change", false, nil, nil, arg_42_1)
end

function var_0_0.getNumberOfAttackAnimations_(arg_43_0)
	for iter_43_0 = 1, math.huge do
		if not arg_43_0:hasAnimation(arg_43_0:attackAnimationName_(iter_43_0)) then
			return iter_43_0 - 1
		end
	end
end

function var_0_0.hasAnimation(arg_44_0, arg_44_1)
	return arg_44_0.model:hasAnimation(arg_44_1)
end

function var_0_0.setupPoints_(arg_45_0)
	arg_45_0.leftPoint = arg_45_0:pointByName_("Pleft")
	arg_45_0.rightPoint = arg_45_0:pointByName_("Pright")
	arg_45_0.headPoint = arg_45_0:pointByName_("Phead")
	arg_45_0.chestPoint = arg_45_0:pointByName_("Pchest")
	arg_45_0.attackedPoint = arg_45_0:pointByName_("Pshouji")
	arg_45_0.footPoint = arg_45_0:pointByName_("Pfoot")
	arg_45_0.attackPoints = {}

	for iter_45_0 = 1, arg_45_0.numberOfAttackAnimations do
		table.insert(arg_45_0.attackPoints, arg_45_0:pointByName_(arg_45_0:attackPointName_(iter_45_0)))
	end

	arg_45_0:size(arg_45_0.rightPoint.x - arg_45_0.leftPoint.x, arg_45_0.headPoint.y)
	arg_45_0.model:size(arg_45_0.rightPoint.x - arg_45_0.leftPoint.x, arg_45_0.headPoint.y)
end

function var_0_0.addPoints(arg_46_0)
	arg_46_0.leftPointCircle = arg_46_0:newCircle()

	arg_46_0.leftPointCircle:addTo(arg_46_0.model)
	arg_46_0.leftPointCircle:setPosition(arg_46_0.leftPoint.x, arg_46_0.leftPoint.y)

	arg_46_0.rightPointCircle = arg_46_0:newCircle()

	arg_46_0.rightPointCircle:addTo(arg_46_0.model)
	arg_46_0.rightPointCircle:setPosition(arg_46_0.rightPoint.x, arg_46_0.rightPoint.y)

	arg_46_0.headPointCircle = arg_46_0:newCircle()

	arg_46_0.headPointCircle:addTo(arg_46_0.model)
	arg_46_0.headPointCircle:setPosition(arg_46_0.headPoint.x, arg_46_0.headPoint.y)

	arg_46_0.footPointCircle = arg_46_0:newCircle()

	arg_46_0.footPointCircle:addTo(arg_46_0.model)
	arg_46_0.footPointCircle:setPosition(0, 0)

	arg_46_0.chestPointCircle = arg_46_0:newCircle()

	arg_46_0.chestPointCircle:addTo(arg_46_0.model)
	arg_46_0.chestPointCircle:setPosition(arg_46_0.chestPoint.x, arg_46_0.chestPoint.y)

	arg_46_0.attackedPointCircle = arg_46_0:newCircle()

	arg_46_0.attackedPointCircle:addTo(arg_46_0.model)
	arg_46_0.attackedPointCircle:setPosition(arg_46_0.attackedPoint.x, arg_46_0.attackedPoint.y)
end

function var_0_0.newCircle(arg_47_0)
	return xyd.AssetLoader.get():loadSprite("images/circle.png")
end

function var_0_0.setupBlinkEffect_(arg_48_0)
	local var_48_0, var_48_1 = xyd.tables.model:blinkResource(arg_48_0.modelID_)

	if var_48_0 ~= nil and #var_48_0 > 0 and var_48_1 ~= nil and #var_48_1 > 0 then
		arg_48_0.blinkEffect_ = sp.SkeletonAnimation:create(var_48_0, var_48_1, arg_48_0.scale_):addTo(arg_48_0.model, -1)

		arg_48_0.blinkEffect_:setAnimation(0, "guangxiao", true)
	end
end

function var_0_0.setupEnergyEffect_(arg_49_0)
	local var_49_0 = "skeletons/ui_effect/common_effect_battle/common_effect_battle8"
	local var_49_1 = var_49_0 .. ".json"
	local var_49_2 = var_49_0 .. ".atlas"

	arg_49_0.energyEffect_ = var_0_3.new(var_49_1, var_49_2, 1)

	arg_49_0.energyEffect_:addTo(arg_49_0.model, 1)
	arg_49_0.energyEffect_:pos(arg_49_0.chestPoint.x, arg_49_0.chestPoint.y)
	arg_49_0.energyEffect_:hide()
end

function var_0_0.playEnergyEffect_(arg_50_0)
	if not arg_50_0.energyEffect_ then
		return
	end

	arg_50_0.energyEffect_:clearTracks()
	arg_50_0.energyEffect_:show()
	arg_50_0.energyEffect_:play(function()
		arg_50_0.energyEffect_:hide()
	end, false)
end

function var_0_0.setupAttackEffects_(arg_52_0)
	if not arg_52_0.tableID_ then
		return
	end

	arg_52_0.attackEffects_ = {}
	arg_52_0.skills_ = {}

	for iter_52_0, iter_52_1 in pairs(xyd.tables.hero:getSkill(arg_52_0.tableID_)) do
		local var_52_0 = var_0_2:attackIndex(iter_52_1)

		if var_52_0 > 0 then
			arg_52_0.skills_[var_52_0] = iter_52_1
		end
	end

	for iter_52_2 = 1, arg_52_0.numberOfAttackAnimations do
		if arg_52_0.skills_[iter_52_2] then
			local var_52_1, var_52_2 = var_0_2:selfResource(arg_52_0.skills_[iter_52_2])

			if var_52_1 and var_52_1 ~= "" and var_52_2 and var_52_2 ~= "" then
				local var_52_3 = sp.SkeletonAnimation:create(var_52_1, var_52_2, arg_52_0.scale_)

				if var_52_3 ~= nil then
					var_52_3:addTo(arg_52_0.model, back and -1 or 0):setVisible(false)

					arg_52_0.attackEffects_[iter_52_2] = var_52_3
				end
			end
		end
	end
end

function var_0_0.playFloatAnimations_(arg_53_0, arg_53_1, arg_53_2, arg_53_3)
	local function var_53_0()
		if arg_53_2 ~= nil then
			arg_53_2()
		end
	end

	arg_53_3 = arg_53_3 or 0

	local var_53_1 = xyd.tables.battleConfig.floatAnimationDuration
	local var_53_2 = xyd.tables.battleConfig.floatAnimationDeltaY
	local var_53_3 = xyd.tables.battleConfig.floatFadeOutDelay

	local function var_53_4(arg_55_0, arg_55_1)
		local var_55_0 = cc.p(arg_55_0:getPosition())

		arg_55_0:addTo(arg_53_0.model, 2)

		local var_55_1 = cc.Spawn:create({
			cc.MoveBy:create(var_53_1, cc.p(0, var_53_2)),
			cc.Sequence:create({
				cc.DelayTime:create(var_53_3),
				cc.FadeOut:create(var_53_1 - var_53_3)
			})
		})

		arg_55_0:runActionOnce(var_55_1, true, arg_55_1, arg_53_3)
	end

	local var_53_5 = {}
	local var_53_6 = xyd.tables.battleConfig.floatAnimationInternal

	for iter_53_0, iter_53_1 in ipairs(arg_53_1) do
		iter_53_1:retain()

		local var_53_7

		var_53_7 = iter_53_0 == #arg_53_1

		local function var_53_8()
			var_53_4(iter_53_1, function()
				iter_53_1:release()

				if iter_53_0 == #arg_53_1 then
					var_53_0()
				end
			end)
		end

		if #var_53_5 > 0 then
			table.insert(var_53_5, cc.DelayTime:create(var_53_6))
		end

		table.insert(var_53_5, cc.CallFunc:create(var_53_8))
	end

	if #var_53_5 <= 0 then
		var_53_0()
	else
		arg_53_0:runAction(transition.sequence(var_53_5))
	end
end

function var_0_0.playAnimation_(arg_58_0, arg_58_1, arg_58_2, arg_58_3, arg_58_4, arg_58_5, arg_58_6)
	if arg_58_6 ~= false then
		arg_58_0.model:setToSetupPose()
	end

	arg_58_0:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
	arg_58_0:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)

	local function var_58_0()
		arg_58_0.playingAttackAnimationIndex_ = nil

		if arg_58_5 ~= nil then
			arg_58_5()
		end
	end

	if not arg_58_0.model:hasAnimation(arg_58_1) then
		print("not self:hasAnimation(name)" .. arg_58_1)
		var_58_0()

		return
	end

	arg_58_0.currentAnimation_ = arg_58_1

	arg_58_0:clearTracks()

	if not arg_58_2 then
		arg_58_0:registerSpineEventHandler(function(arg_60_0)
			arg_58_0:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
			arg_58_0:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
			var_58_0()
		end, sp.EventType.ANIMATION_COMPLETE)
		arg_58_0:registerSpineEventHandler(function(arg_61_0)
			if arg_61_0.eventData ~= nil and arg_61_0.eventData.name == "kaishi" then
				arg_58_0:playAttackEffectIfNecessary_()
			elseif arg_61_0.eventData ~= nil and arg_61_0.eventData.name == "xuli" then
				if arg_58_3 ~= nil then
					arg_58_3()
				end
			elseif arg_61_0.eventData ~= nil and arg_61_0.eventData.name == "jiedian" and arg_58_4 ~= nil then
				arg_58_4()
			end
		end, sp.EventType.ANIMATION_EVENT)
	end

	arg_58_0:setAnimation(0, arg_58_1, arg_58_2)

	return arg_58_0.model
end

function var_0_0.setAnimation(arg_62_0, arg_62_1, arg_62_2, arg_62_3)
	return arg_62_0.model:setAnimation(arg_62_1, arg_62_2, arg_62_3)
end

function var_0_0.setToSetupPose(arg_63_0)
	return arg_63_0.model:setToSetupPose()
end

function var_0_0.unregisterSpineEventHandler(arg_64_0, arg_64_1)
	return arg_64_0.model:unregisterSpineEventHandler(arg_64_1)
end

function var_0_0.registerSpineEventHandler(arg_65_0, arg_65_1, arg_65_2)
	return arg_65_0.model:registerSpineEventHandler(arg_65_1, arg_65_2)
end

function var_0_0.playAttackEffectIfNecessary_(arg_66_0)
	local var_66_0 = arg_66_0.playingAttackAnimationIndex_
	local var_66_1 = arg_66_0.attackEffects_[var_66_0]

	if var_66_1 == nil then
		return
	end

	if var_66_1:getFlipX() ~= arg_66_0:getFlipX() then
		var_66_1:setFlipX(arg_66_0:getFlipX())
	end

	var_66_1:registerSpineEventHandler(function(arg_67_0)
		var_66_1:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
		var_66_1:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
		var_66_1:setVisible(false)
	end, sp.EventType.ANIMATION_COMPLETE)
	var_66_1:setVisible(true)
	var_66_1:clearTracks()
	var_66_1:setAnimation(0, "texiao", false)
	var_66_1:updateTo(0)
end

function var_0_0.stopAttackEffect_(arg_68_0, arg_68_1)
	if arg_68_1 then
		local var_68_0 = arg_68_0.attackEffects_[arg_68_1]

		if var_68_0 ~= nil then
			var_68_0:clearTrack(0)
			var_68_0:setVisible(false)
		end

		return
	end

	for iter_68_0, iter_68_1 in pairs(arg_68_0.attackEffects_) do
		if iter_68_1 ~= nil then
			iter_68_1:clearTrack(0)
			iter_68_1:setVisible(false)
		end
	end
end

function var_0_0.attackAnimationName_(arg_69_0, arg_69_1)
	return string.format("gongji%02d", arg_69_1)
end

function var_0_0.attackPointName_(arg_70_0, arg_70_1)
	return string.format("Pattack%02d", arg_70_1)
end

function var_0_0.pointByName_(arg_71_0, arg_71_1)
	local var_71_0, var_71_1 = arg_71_0:getBonePosition(arg_71_1)
	local var_71_2 = math.floor(var_71_0 or 0)
	local var_71_3 = math.floor(var_71_1 or 0)

	return cc.p(var_71_2, var_71_3)
end

function var_0_0.getBonePosition(arg_72_0, arg_72_1)
	return arg_72_0.model:getBonePosition(arg_72_1)
end

function var_0_0.flipPoint_(arg_73_0, arg_73_1)
	return cc.p(-arg_73_1.x, arg_73_1.y)
end

function var_0_1.ctor(arg_74_0)
	return
end

function var_0_1.setBorderByHeroClass(arg_75_0, arg_75_1)
	local var_75_0

	if arg_75_1 == xyd.HeroClass.WATER then
		var_75_0 = "battle_hp_border_water.png"
	elseif arg_75_1 == xyd.HeroClass.FIRE then
		var_75_0 = "battle_hp_border_fire.png"
	elseif arg_75_1 == xyd.HeroClass.WIND then
		var_75_0 = "battle_hp_border_wind.png"
	elseif arg_75_1 == xyd.HeroClass.GOD then
		var_75_0 = "battle_hp_border_god.png"
	elseif arg_75_1 == xyd.HeroClass.DEVIL then
		var_75_0 = "battle_hp_border_devil.png"
	end

	if arg_75_0.border_ ~= nil then
		arg_75_0.border_:removeSelf()

		arg_75_0.border_ = nil
	end

	if var_75_0 ~= nil then
		arg_75_0.border_ = xyd.AssetLoader.get():loadSprite(var_75_0):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_75_0.model, 0)

		arg_75_0:setContentSize(arg_75_0.border_:getContentSize())

		if arg_75_0.background_ == nil then
			arg_75_0.background_ = xyd.AssetLoader.get():loadSprite("battle_progress_bg.png"):align(display.LEFT_BOTTOM, 29, 12):addTo(arg_75_0.model, -2)
		end
	end
end

function var_0_1.setLevel(arg_76_0, arg_76_1)
	if arg_76_0.levelLabel_ == nil then
		arg_76_0.levelLabel_ = xyd.AssetLoader.get():loadLabel(nil, "battle_level"):align(display.CENTER, 19, 13):addTo(arg_76_0.model, 1)
	end

	arg_76_0.levelLabel_:setString(tostring(arg_76_1))
end

function var_0_1.setHPProgress(arg_77_0, arg_77_1, arg_77_2, arg_77_3)
	if arg_77_0.hpProgress_ == nil then
		local var_77_0 = xyd.AssetLoader.get():loadSprite("battle_hp_progress.png")

		arg_77_0.hpProgress_ = display.newProgressTimer(var_77_0, display.PROGRESS_TIMER_BAR):align(display.LEFT_TOP, 37, 29):addTo(arg_77_0.model, -1)

		arg_77_0.hpProgress_:setMidpoint(cc.p(0, 0))
		arg_77_0.hpProgress_:setBarChangeRate(cc.p(1, 0))
		arg_77_0.hpProgress_:setPercentage(0)
	end

	arg_77_0:setBarProgress_(arg_77_0.hpProgress_, arg_77_1, arg_77_2, arg_77_3)
end

function var_0_1.setActionProgress(arg_78_0, arg_78_1, arg_78_2, arg_78_3)
	if arg_78_0.actionProgress_ == nil then
		local var_78_0 = xyd.AssetLoader.get():loadSprite("battle_action_progress.png")

		arg_78_0.actionProgress_ = display.newProgressTimer(var_78_0, display.PROGRESS_TIMER_BAR):align(display.LEFT_BOTTOM, 38, 13):addTo(arg_78_0.model, -1)

		arg_78_0.actionProgress_:setMidpoint(cc.p(0, 0))
		arg_78_0.actionProgress_:setBarChangeRate(cc.p(1, 0))
		arg_78_0.actionProgress_:setPercentage(0)
	end

	arg_78_0:setBarProgress_(arg_78_0.actionProgress_, arg_78_1, arg_78_2, arg_78_3)
end

function var_0_1.setArrowVisible(arg_79_0, arg_79_1, arg_79_2)
	if arg_79_1 then
		if arg_79_0.arrow_ ~= nil then
			if arg_79_2 == arg_79_0.arrowRetrainType_ then
				return
			else
				arg_79_0.arrow_:removeSelf()

				arg_79_0.arrow_ = nil
			end
		end

		local var_79_0

		if arg_79_2 == xyd.RetrainType.NONE then
			var_79_0 = "battle_arrow.png"
		elseif arg_79_2 == xyd.RetrainType.RETRAIN then
			var_79_0 = "battle_arrow_retrain.png"
		elseif arg_79_2 == xyd.RetrainType.RETRAINED then
			var_79_0 = "battle_arrow_retrained.png"
		end

		arg_79_0.arrowRetrainType_ = arg_79_2

		if var_79_0 == nil then
			var_79_0 = "battle_arrow.png"
			arg_79_0.arrowRetrainType_ = xyd.RetrainType.NONE
		end

		local var_79_1 = arg_79_0:getContentSize()
		local var_79_2 = xyd.tables.battleConfig.arrowAnimationDuration

		arg_79_0.arrow_ = xyd.AssetLoader.get():loadSprite(var_79_0):align(display.CENTER_BOTTOM, 0.5 * var_79_1.width, var_79_1.height + 6):addTo(arg_79_0.model, 1)

		arg_79_0.arrow_:runAction(cc.RepeatForever:create(cc.Sequence:create({
			cc.MoveBy:create(var_79_2, cc.p(0, -16)),
			cc.MoveBy:create(var_79_2, cc.p(0, 16))
		})))
	elseif arg_79_0.arrow_ ~= nil then
		arg_79_0.arrow_:removeSelf()

		arg_79_0.arrow_ = nil
	end
end

function var_0_1.addBuffs(arg_80_0, arg_80_1)
	arg_80_0.buffInfos_ = arg_80_0.buffInfos_ or {}

	for iter_80_0, iter_80_1 in ipairs(arg_80_1) do
		local var_80_0
		local var_80_1 = iter_80_1:getTableID()

		for iter_80_2, iter_80_3 in ipairs(arg_80_0.buffInfos_) do
			if iter_80_3.buffID == var_80_1 then
				iter_80_3.count = iter_80_3.count + 1
				var_80_0 = iter_80_3

				break
			end
		end

		if var_80_0 == nil then
			local var_80_2 = {}

			table.insert(arg_80_0.buffInfos_, var_80_2)

			var_80_2.buffID = var_80_1
			var_80_2.count = 1

			local var_80_3, var_80_4 = xyd.tables.dbuff:effectResource(var_80_1)

			if var_80_3 ~= nil and var_80_4 ~= nil then
				local var_80_5 = sp.SkeletonAnimation:create(var_80_3, var_80_4, 1)

				var_80_5:setAnimation(0, "texiao", true)
				var_80_5:addTo(arg_80_0.model)
				var_80_5:setPosition(50, 0)
			end
		end
	end

	arg_80_0:updateBuffIcons_()
end

function var_0_1.removeBuffs(arg_81_0, arg_81_1)
	arg_81_0.buffInfos_ = arg_81_0.buffInfos_ or {}

	for iter_81_0, iter_81_1 in ipairs(arg_81_1) do
		local var_81_0 = iter_81_1:getBuffID()

		for iter_81_2 = #arg_81_0.buffInfos_, 1, -1 do
			local var_81_1 = arg_81_0.buffInfos_[iter_81_2]

			if var_81_1.buffID == var_81_0 then
				var_81_1.count = var_81_1.count - 1

				if var_81_1.count <= 0 then
					if var_81_1.icon ~= nil then
						var_81_1.icon:removeSelf()

						var_81_1.icon = nil
					end

					table.remove(arg_81_0.buffInfos_, iter_81_2)
				end

				break
			end
		end
	end

	arg_81_0:updateBuffIcons_()
end

function var_0_1.pause(arg_82_0)
	if arg_82_0.arrow_ ~= nil then
		arg_82_0.arrow_:pause()
	end
end

function var_0_1.resume(arg_83_0)
	if arg_83_0.arrow_ ~= nil then
		arg_83_0.arrow_:resume()
	end
end

function var_0_1.setBarProgress_(arg_84_0, arg_84_1, arg_84_2, arg_84_3, arg_84_4)
	arg_84_1:stopAllActions()

	arg_84_2 = arg_84_2 * 100

	if arg_84_3 then
		local var_84_0 = xyd.tables.battleConfig.progressAnimationDuration

		arg_84_1:runActionOnce(cc.ProgressTo:create(var_84_0, arg_84_2), false, arg_84_4)
	else
		arg_84_1:setPercentage(arg_84_2)

		if arg_84_4 ~= nil then
			arg_84_4()
		end
	end
end

function var_0_1.updateBuffIcons_(arg_85_0)
	local var_85_0 = 33
	local var_85_1 = 34

	if #arg_85_0.buffInfos_ ~= 0 then
		-- block empty
	end
end

function var_0_0.setSkillEffects_(arg_86_0)
	local var_86_0, var_86_1 = xyd.tables.model:effectResource(arg_86_0.modelID_)
end

function var_0_0.playSkillEffect(arg_87_0, arg_87_1)
	if arg_87_0.skillEffect == nil then
		return
	end

	arg_87_0.skillEffect:setAnimation(0, arg_87_1, false)

	return arg_87_0.skillEffect
end

function var_0_0.modelFilter(arg_88_0, arg_88_1)
	if not arg_88_1 then
		return
	end

	local var_88_0 = arg_88_1
	local var_88_1 = cc.TintBy:create(0, var_88_0[1], var_88_0[2], var_88_0[3])

	arg_88_0.model:runActionOnce(var_88_1)
end

return var_0_0
