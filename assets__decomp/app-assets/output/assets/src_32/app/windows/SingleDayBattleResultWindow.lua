local var_0_0 = class("SingleDayBattleResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.singleDay = xyd.ModelManager.get():loadModel(xyd.ModelType.SINGLE_DAY)
	arg_1_0.battleInfo = arg_1_2
	arg_1_0.result = true
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(nil, true)
end

function var_0_0.saveResult(arg_4_0)
	local var_4_0 = arg_4_0.battleInfo

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_FIGHT_RESULT, var_4_0, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			arg_4_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN
			})
		end
	end)
end

function var_0_0.layout(arg_6_0)
	arg_6_0:playEffect()
	arg_6_0:nodeByName("text_harm"):setString(var_0_1:translation("CHALLENAGE_BOSS_HARM"))
	arg_6_0:nodeByName("text_tacit"):setString(var_0_1:translation("CHALLENAGE_BOSS_TACIT"))

	local var_6_0 = arg_6_0.battleInfo.total_damage
	local var_6_1 = var_6_0 * xyd.tables.misc.singleChallengeRatio

	var_6_1 = var_6_1 <= xyd.tables.misc.singleChallengeLimit and var_6_1 or xyd.tables.misc.singleChallengeLimit

	arg_6_0:nodeByName("text_harm_num"):setString(var_6_0)
	arg_6_0:nodeByName("text_tacit_num"):setString(math.ceil(var_6_1))

	if var_6_0 <= 0 then
		arg_6_0.result = false

		arg_6_0:nodeByName("text_tips"):setString(var_0_1:translation("CHALLENAGE_BOSS_LOSE_TIPS"))
	else
		arg_6_0:nodeByName("text_tips"):setString(var_0_1:translation("CHALLENAGE_BOSS_TIPS"))
	end

	arg_6_0:nodeByName("btn_ok"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_6_0.result then
				arg_6_0:dispatchEvent({
					name = xyd.event.BATTLE_END_BACK_TO_MAIN
				})
			else
				arg_6_0:saveResult()
			end
		end
	end)
	arg_6_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_6_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN
			})
		end
	end)
end

function var_0_0.playEffect(arg_9_0)
	local var_9_0, var_9_1 = arg_9_0:nodeByName("effect"):getPosition()

	arg_9_0:nodeByName("effect"):removeSelf()

	if not arg_9_0.effect_ then
		local var_9_2 = "skeletons/ui_effect/common_effect_spin3/common_effect_spin3"
		local var_9_3 = var_9_2 .. ".json"
		local var_9_4 = var_9_2 .. ".atlas"

		arg_9_0.effect_ = var_0_2.new(var_9_3, var_9_4, 1)

		arg_9_0.effect_:setPosition(var_9_0, var_9_1)
		arg_9_0.effect_:addTo(arg_9_0:nodeByName("container"), -1)
	end

	arg_9_0.effect_:play(nil, true)
end

function var_0_0.willClose(arg_10_0)
	if arg_10_0.effect_ then
		arg_10_0.effect_:clearTracks()
		arg_10_0.effect_:removeSelf()
	end
end

return var_0_0
