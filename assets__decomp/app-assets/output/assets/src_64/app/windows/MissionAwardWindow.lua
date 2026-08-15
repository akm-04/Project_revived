local var_0_0 = class("MissionAwardWindow", import("app.common.ui.BaseWindow"))

var_0_0.AWARD_CONTAINER = "award_container"
var_0_0.TITLE = "task_award_title"
var_0_0.OK_BUTTON = "btn_award_ok"
var_0_0.OK = "ok_text"
var_0_0.EXP_IMAGE = "exp"
var_0_0.EXP_NUM = "exp_num"
var_0_0.CRYSTAL_IMAGE = "crystal"
var_0_0.CRYSTAL_NUM = "crystal_num"
var_0_0.GOLD_IMAGE = "gold"
var_0_0.GOLD_NUM = "gold_num"
var_0_0.AWARD_IMAGE = "award_icon"
var_0_0.POWER_IMAGE = "power"
var_0_0.AWARD_NUM = "award_num"

local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.mission

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.tableID = arg_1_2.table_id
	arg_1_0.missionType = arg_1_2.type
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen()

	local var_2_0 = xyd.tables.sound:getSound("gain_window_sound")

	audio.playSound(var_2_0, false)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen()
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName(var_0_0.AWARD_CONTAINER):setPosition(cc.p(0, 0))
	arg_4_0:nodeByName(var_0_0.TITLE):setString(string.format("%s %s", var_0_1:translation("FINISH"), var_0_2:name(arg_4_0.tableID)))
	arg_4_0:setMissionAward()
	arg_4_0:nodeByName(var_0_0.OK_BUTTON):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow("mission_award")
		end
	end)
end

function var_0_0.okEvent(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = {
		table_id = arg_6_0.tableID
	}

	xyd.Backend.get():request(xyd.mid.TAKE_MISSION_AWARD, var_6_0, function(arg_7_0, arg_7_1, arg_7_2)
		if arg_7_0 == xyd.error.OK then
			-- block empty
		end
	end, var_6_0)
end

function var_0_0.setMissionAward(arg_8_0)
	arg_8_0:nodeByName(var_0_0.GOLD_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.GOLD_NUM):setVisible(false)
	arg_8_0:nodeByName(var_0_0.CRYSTAL_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.CRYSTAL_NUM):setVisible(false)
	arg_8_0:nodeByName(var_0_0.EXP_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.EXP_NUM):setVisible(false)
	arg_8_0:nodeByName(var_0_0.POWER_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.AWARD_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.AWARD_NUM):setVisible(false)

	local var_8_0 = 0

	if xyd.tables.mission:crystal(arg_8_0.tableID) > 0 then
		var_8_0 = var_8_0 + 1
	end

	if xyd.tables.mission:gold(arg_8_0.tableID) > 0 then
		var_8_0 = var_8_0 + 1
	end

	if xyd.tables.mission:exp(arg_8_0.tableID) > 0 then
		var_8_0 = var_8_0 + 1
	end

	if xyd.tables.mission:award(arg_8_0.tableID) ~= "0" then
		var_8_0 = var_8_0 + 1
	end

	local var_8_1 = 60
	local var_8_2 = arg_8_0:nodeByName(var_0_0.AWARD_CONTAINER)
	local var_8_3 = arg_8_0:nodeByName("inner_container")

	if var_8_0 > 1 then
		local var_8_4 = var_8_2:getContentSize()
		local var_8_5 = cc.size(var_8_4.width, var_8_4.height + (var_8_0 - 1) * var_8_1)

		var_8_2:setContentSize(var_8_5)

		local var_8_6 = var_8_3:getContentSize()
		local var_8_7 = cc.size(var_8_6.width, var_8_6.height + (var_8_0 - 1) * var_8_1)

		var_8_3:setContentSize(var_8_7)

		local var_8_8 = cc.p(arg_8_0:nodeByName(var_0_0.TITLE):getPosition())

		arg_8_0:nodeByName(var_0_0.TITLE):setPosition(cc.p(var_8_8.x, var_8_8.y + (var_8_5.height - var_8_4.height)))
	end

	local var_8_9 = 1

	local function var_8_10(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
		local var_9_0 = arg_8_0:nodeByName(arg_9_0)

		var_9_0:setVisible(true)

		local var_9_1 = arg_8_0:nodeByName(arg_9_1)

		var_9_1:setVisible(true)
		var_9_1:setString("×" .. arg_9_2)

		local var_9_2, var_9_3 = var_9_0:getPosition()
		local var_9_4, var_9_5 = var_9_1:getPosition()
		local var_9_6 = var_8_1 * (var_8_0 - arg_9_3)

		var_9_0:setPosition(cc.p(var_9_2, var_9_3 + var_9_6))
		var_9_1:setPosition(cc.p(var_9_4, var_9_5 + var_9_6))
	end

	local var_8_11 = xyd.tables.mission:exp(arg_8_0.tableID)

	if var_8_11 > 0 then
		var_8_10(var_0_0.EXP_IMAGE, var_0_0.EXP_NUM, var_8_11, var_8_9)

		var_8_9 = var_8_9 + 1
	end

	local var_8_12 = xyd.tables.mission:crystal(arg_8_0.tableID)

	if var_8_12 > 0 then
		var_8_10(var_0_0.CRYSTAL_IMAGE, var_0_0.CRYSTAL_NUM, var_8_12, var_8_9)

		var_8_9 = var_8_9 + 1
	end

	local var_8_13 = xyd.tables.mission:gold(arg_8_0.tableID)

	if var_8_13 > 0 then
		var_8_10(var_0_0.GOLD_IMAGE, var_0_0.GOLD_NUM, var_8_13, var_8_9)

		var_8_9 = var_8_9 + 1
	end

	local var_8_14 = xyd.tables.mission:award(arg_8_0.tableID)

	if var_8_14 ~= "" and var_8_14 ~= "0" then
		local var_8_15 = xyd.splitToNumber(var_8_14, "|")
		local var_8_16 = var_8_15[1]

		if #var_8_15 > 1 then
			if var_8_16 == 1 then
				local var_8_17 = var_8_15[2]

				var_8_10(var_0_0.POWER_IMAGE, var_0_0.AWARD_NUM, var_8_17, var_8_9)
			end
		else
			local var_8_18 = xyd.tables.mission:award_num(arg_8_0.tableID)

			if arg_8_0.tableID == xyd.MissionIDs.DAILY.GET_SWEEP_CARD then
				local var_8_19 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

				var_8_18 = xyd.tables.vip:sweepCard(var_8_19.vip)
			end

			if var_8_18 > 0 and var_8_16 > 0 then
				var_8_10("award_icon", "award_num", var_8_18, var_8_9)

				local var_8_20 = var_8_3:getChildByName("award_icon")

				xyd.setItemBorder(var_8_20, var_8_16)
			end
		end

		local var_8_21 = var_8_9 + 1
	end
end

return var_0_0
