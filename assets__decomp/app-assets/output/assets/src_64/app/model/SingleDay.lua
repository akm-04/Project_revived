local var_0_0 = class("SingleDay", import(".BaseModel"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = {
	Sending = 1,
	Rejected = 3,
	Recieving = 2,
	NotApply = 0
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.getRecommendFellows(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_RECOMMEND_FELLOWS, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK and (arg_4_1 and false or arg_3_2) then
			arg_3_2(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.loadInfo(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	local var_5_1 = {
		activity_id = xyd.Activities.SingleDay
	}

	var_5_0:loadSingleActivity(var_5_1, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0.activity = arg_6_1
			arg_5_0.details = arg_5_0.activity.details

			if arg_5_0.details.self_base_info.has_new_apply == 1 then
				arg_5_0.isApplyRedMarkShow = true
			end

			arg_5_0:updateRedMark()

			if arg_5_2 then
				arg_5_2(arg_6_0, arg_6_1)
			end
		end
	end)
end

function var_0_0.updateRedMark(arg_7_0)
	local var_7_0 = false
	local var_7_1 = arg_7_0.details.self_daily_infos

	for iter_7_0 = 1, #var_7_1 do
		if var_7_1[iter_7_0].award_status == 1 then
			var_7_0 = true
		end
	end

	if arg_7_0.isApplyRedMarkShow == true then
		var_7_0 = true
	end

	local var_7_2 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_7_2 then
		var_7_2:showSingleDayRedMark(var_7_0)
	end
end

function var_0_0.updateSingleDayWindow(arg_8_0)
	local var_8_0 = xyd.WindowManager.get():getWindow("single_day")

	if var_8_0 and not tolua.isnull(var_8_0) then
		var_8_0:update()
	end
end

function var_0_0.getApplyList(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_GET_APPLY_LIST, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0.applyList = arg_10_1 or {}
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.getRankInfo(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_RANK_INFO, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			-- block empty
		end

		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.refreshRedMark(arg_13_0)
	return
end

function var_0_0.searchPlayers(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_SEARCH_PLAYERS, var_14_0, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			-- block empty
		end

		if arg_14_2 then
			arg_14_2(arg_15_0, arg_15_1)
		end
	end)
end

function var_0_0.applyFellow(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_APPLY_FELLOW, var_16_0, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK then
			-- block empty
		end

		if arg_16_2 then
			arg_16_2(arg_17_0, arg_17_1)
		end
	end)
end

function var_0_0.acceptFellow(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = arg_18_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_ACCEPT_FELLOW, var_18_0, function(arg_19_0, arg_19_1)
		if arg_19_0 == xyd.error.OK then
			arg_18_0.details.fellow_base_info = arg_19_1.fellow_base_info
			arg_18_0.details.self_base_info = arg_19_1.self_base_info
			arg_18_0.details.fellow_daily_infos = arg_19_1.fellow_daily_infos
			arg_18_0.details.self_daily_infos = arg_19_1.self_daily_infos
		end

		if arg_18_2 then
			arg_18_2(arg_19_0, arg_19_1)
		end
	end)
end

function var_0_0.cancelApply(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_CANCEL_APPLY, var_20_0, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK then
			-- block empty
		end

		if arg_20_2 then
			arg_20_2(arg_21_0, arg_21_1)
		end
	end)
end

function var_0_0.removeFellow(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = arg_22_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_REMOVE_FELLOW, var_22_0, function(arg_23_0, arg_23_1)
		if arg_23_0 == xyd.error.OK then
			arg_22_0.details.self_base_info = arg_23_1.self_base_info
		end

		if arg_22_2 then
			arg_22_2(arg_23_0, arg_23_1)
		end
	end)
end

function var_0_0.acceptRemove(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = arg_24_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_ACCEPT_REMOVE, var_24_0, function(arg_25_0, arg_25_1)
		if arg_25_0 == xyd.error.OK then
			arg_24_0.details.self_base_info = arg_25_1.self_base_info
			arg_24_0.details.self_daily_infos = arg_25_1.self_daily_infos
		end

		if arg_24_2 then
			arg_24_2(arg_25_0, arg_25_1)
		end
	end)
end

function var_0_0.denyRemove(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = arg_26_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_DENY_REMOVE, var_26_0, function(arg_27_0, arg_27_1)
		if arg_27_0 == xyd.error.OK then
			arg_26_0.details.self_base_info = arg_27_1.self_base_info
		end

		if arg_26_2 then
			arg_26_2(arg_27_0, arg_27_1)
		end
	end)
end

function var_0_0.openMission(arg_28_0, arg_28_1, arg_28_2)
	local var_28_0 = arg_28_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_OPEN_MISSION, var_28_0, function(arg_29_0, arg_29_1)
		if arg_29_0 == xyd.error.OK then
			-- block empty
		end

		if arg_28_2 then
			arg_28_2(arg_29_0, arg_29_1)
		end
	end)
end

function var_0_0.startFight(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0 = arg_30_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_START_FIGHT, var_30_0, function(arg_31_0, arg_31_1)
		if arg_31_0 == xyd.error.OK then
			-- block empty
		end

		if arg_30_2 then
			arg_30_2(arg_31_0, arg_31_1)
		end
	end)
end

function var_0_0.fightResult(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = arg_32_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_FIGHT_RESULT, var_32_0, function(arg_33_0, arg_33_1)
		if arg_33_0 == xyd.error.OK then
			-- block empty
		end

		if arg_32_2 then
			arg_32_2(arg_33_0, arg_33_1)
		end
	end)
end

function var_0_0.forceDeletePartener(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = arg_34_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_FORCE_DELETE_PARTENER, var_34_0, function(arg_35_0, arg_35_1)
		if arg_35_0 == xyd.error.OK then
			-- block empty
		end

		if arg_34_2 then
			arg_34_2(arg_35_0, arg_35_1)
		end
	end)
end

function var_0_0.addPartener(arg_36_0, arg_36_1, arg_36_2)
	local var_36_0 = arg_36_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_ADD_PARTENER, var_36_0, function(arg_37_0, arg_37_1)
		if arg_37_0 == xyd.error.OK then
			-- block empty
		end

		if arg_36_2 then
			arg_36_2(arg_37_0, arg_37_1)
		end
	end)
end

function var_0_0.selectTask(arg_38_0, arg_38_1, arg_38_2)
	local var_38_0 = arg_38_1 or {}

	xyd.Backend.get():request(xyd.mid.SINGLE_DAY_SELECT_TASK, var_38_0, function(arg_39_0, arg_39_1)
		if arg_39_0 == xyd.error.OK then
			-- block empty
		end

		if arg_38_2 then
			arg_38_2(arg_39_0, arg_39_1)
		end
	end)
end

function var_0_0.refreshStateInfo(arg_40_0)
	local var_40_0 = {
		playerID = arg_40_0.selfPlayer.playerID,
		name = xyd.state.LAST_FELLOW_ID,
		state = tostring(arg_40_0.details.self_base_info.fellow_id)
	}

	xyd.db.stateVariable:setState(var_40_0)

	if arg_40_0.details.fellow_base_info then
		var_40_0.name = xyd.state.LAST_FELLOW_NAME
		var_40_0.state = tostring(arg_40_0.details.fellow_base_info.player_name)

		xyd.db.stateVariable:setState(var_40_0)
	end

	var_40_0.name = xyd.state.REMOVE_APPLY_STATE
	var_40_0.state = tostring(arg_40_0.details.self_base_info.remove_apply)

	xyd.db.stateVariable:setState(var_40_0)
end

return var_0_0
