local var_0_0 = ngx
local var_0_1 = class("SkillEffectByPath", function(arg_1_0)
	if xyd.BattleType.CreateReport == var_0_0.ctx.battle.battleType then
		return display.newNode()
	end

	local var_1_0 = arg_1_0 .. ".json"
	local var_1_1 = arg_1_0 .. ".atlas"

	if var_1_0 and var_1_1 and var_1_0 ~= "" and var_1_1 ~= "" then
		return sp.SkeletonAnimation:create(var_1_0, var_1_1, 1)
	end
end)

function var_0_1.ctor(arg_2_0, arg_2_1, arg_2_2)
	if xyd.BattleType.CreateReport == var_0_0.ctx.battle.battleType then
		return
	end

	arg_2_2 = arg_2_2 or {}

	if arg_2_2.flip then
		arg_2_0:setFlipX(true)
	end

	arg_2_0.leftPoint = arg_2_0:pointByName_("Pleft")
	arg_2_0.rightPoint = arg_2_0:pointByName_("Pright")

	arg_2_0:retain()

	arg_2_0.key = arg_2_1 .. ".json"

	arg_2_0:setTimeScale(var_0_0.ctx.battle.timeScale)
end

function var_0_1.getSizeX(arg_3_0)
	if xyd.BattleType.CreateReport == var_0_0.ctx.battle.battleType then
		return 10
	end

	return arg_3_0.rightPoint.x - arg_3_0.leftPoint.x
end

function var_0_1.pointByName_(arg_4_0, arg_4_1)
	local var_4_0, var_4_1 = arg_4_0:getBonePosition(arg_4_1)

	var_4_0 = var_4_0 or 0
	var_4_1 = var_4_1 or 0

	return cc.p(var_4_0, var_4_1)
end

function var_0_1.playRepeat(arg_5_0)
	if xyd.BattleType.CreateReport == var_0_0.ctx.battle.battleType then
		return
	end

	arg_5_0:setVisible(true)
	arg_5_0:clearTracks()
	arg_5_0:setAnimation(0, "texiao", true)
end

function var_0_1.play(arg_6_0, arg_6_1)
	if xyd.BattleType.CreateReport == var_0_0.ctx.battle.battleType then
		return
	end

	local function var_6_0()
		local var_7_0 = arg_6_1

		arg_6_1 = nil

		if var_7_0 ~= nil then
			var_7_0()
		end
	end

	arg_6_0:setVisible(true)
	arg_6_0:registerSpineEventHandler(function(arg_8_0)
		arg_6_0:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
		arg_6_0:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
		var_6_0()
	end, sp.EventType.ANIMATION_COMPLETE)
	arg_6_0:registerSpineEventHandler(function(arg_9_0)
		if arg_9_0.eventData ~= nil and arg_9_0.eventData.name == "hit" then
			var_6_0()
		end
	end, sp.EventType.ANIMATION_EVENT)
	arg_6_0:clearTracks()
	arg_6_0:setAnimation(0, "texiao", false)
end

function var_0_1.playOnce(arg_10_0, arg_10_1)
	if xyd.BattleType.CreateReport == var_0_0.ctx.battle.battleType then
		return
	end

	local function var_10_0()
		local var_11_0 = arg_10_1

		arg_10_1 = nil

		if var_11_0 ~= nil then
			var_11_0()
		end
	end

	arg_10_0:setVisible(true)
	arg_10_0:registerSpineEventHandler(function(arg_12_0)
		arg_10_0:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
		arg_10_0:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
		var_10_0()
		arg_10_0:stop()
	end, sp.EventType.ANIMATION_COMPLETE)
	arg_10_0:registerSpineEventHandler(function(arg_13_0)
		if arg_13_0.eventData ~= nil and arg_13_0.eventData.name == "hit" then
			var_10_0()
		end
	end, sp.EventType.ANIMATION_EVENT)
	arg_10_0:clearTracks()
	arg_10_0:setAnimation(0, "texiao", false)
end

function var_0_1.stop(arg_14_0)
	if xyd.BattleType.CreateReport == var_0_0.ctx.battle.battleType then
		return
	end

	arg_14_0:clearTracks()
	arg_14_0:setVisible(false)
	var_0_0.ctx.battle.cacheSpine(arg_14_0)
end

function var_0_1.flipX(arg_15_0, arg_15_1)
	if xyd.BattleType.CreateReport == var_0_0.ctx.battle.battleType then
		return
	end

	arg_15_0:setFlipX(arg_15_1)
end

function var_0_1.setTimeScale(arg_16_0, arg_16_1)
	getmetatable(sp.SkeletonAnimation).setTimeScale(arg_16_0, arg_16_1)
end

return var_0_1
