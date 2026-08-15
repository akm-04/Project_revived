local var_0_0 = class("WarCampDamageWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.data = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = 0
	local var_3_1 = 0
	local var_3_2 = 0
	local var_3_3 = arg_3_0.warCamp_:getOldBossMapInfo()
	local var_3_4 = arg_3_0.warCamp_:getMapInfoByMapID(var_3_3.map_id)

	if var_3_3 and next(var_3_3) and var_3_4 and next(var_3_4) then
		var_3_0 = var_3_4.self_hurt - var_3_3.self_hurt
		var_3_1 = var_3_4.self_hurt
		var_3_2 = math.floor(var_3_0 * xyd.tables.misc.campWarBossHonorParam / xyd.DECIMAL_BASE)

		local var_3_5 = 1

		for iter_3_0, iter_3_1 in pairs(xyd.tables.misc.warCampSkinItems) do
			if arg_3_0.selfPlayer:hasSkin(iter_3_1) then
				var_3_5 = var_3_5 + xyd.tables.misc.warCampSkinItemRate
			end
		end

		var_3_2 = math.floor(var_3_2 * var_3_5)
	end

	arg_3_0:nodeByName("text_damage"):setString(var_0_1:translation("CAMP_BOSS_DAMAGE_TIMES") .. var_3_0)
	arg_3_0:nodeByName("text_total_damage"):setString(var_0_1:translation("CAMP_BOSS_DAMAGE_TOTAL") .. var_3_1)
	arg_3_0:nodeByName("text_score"):setString(var_0_1:translation("CAMP_BOSS_TIMES_HONOR") .. var_3_2)
	arg_3_0:nodeByName("close"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_4_0, false)
			arg_3_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN
			})
		end
	end)
	arg_3_0:nodeByName("btn_data"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, {
				herosA = arg_3_0.data.fighterA,
				herosB = arg_3_0.data.fighterB,
				petA = arg_3_0.data.petA
			})
		end
	end)
end

return var_0_0
