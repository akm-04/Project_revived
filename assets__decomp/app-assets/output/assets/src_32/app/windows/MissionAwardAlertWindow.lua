local var_0_0 = class("MissionAwardAlertWindow", import("app.common.ui.BaseWindow"))

var_0_0.TITLE = "title"
var_0_0.DESC1 = "desc1"
var_0_0.DESC2 = "desc2"
var_0_0.AWARD1 = "award1"
var_0_0.AWARD2 = "award2"
var_0_0.OK = "ok"
var_0_0.XP1_IMAGE = "xp1"
var_0_0.CRYSTAL1_IMAGE = "crystal1"
var_0_0.MANA1_IMAGE = "mana1"
var_0_0.SCROLL1_IMAGE = "scroll1"
var_0_0.ENERGY1_IMAGE = "energy1"
var_0_0.XP2_IMAGE = "xp2"
var_0_0.CRYSTAL2_IMAGE = "crystal2"
var_0_0.MANA2_IMAGE = "mana2"
var_0_0.SCROLL2_IMAGE = "scroll2"
var_0_0.ENERGY2_IMAGE = "energy2"
var_0_0.OK_BUTTON = "ok_button"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.tableID = arg_1_2.table_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName(var_0_0.TITLE):setString(xyd.tables.mission:name(arg_4_0.tableID))
	arg_4_0:nodeByName(var_0_0.DESC1):setString(xyd.tables.translation:translation("MISSION_AWARD"))
	arg_4_0:nodeByName(var_0_0.DESC2):setString(xyd.tables.translation:translation("MISSION_AWARD"))
	arg_4_0:nodeByName(var_0_0.OK):setString(xyd.tables.translation:translation("OK"))
	arg_4_0:setMissionAward()
	arg_4_0:nodeByName(var_0_0.OK_BUTTON):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0:okEvent(arg_5_0, arg_5_1)
		end
	end)
end

function var_0_0.okEvent(arg_6_0, arg_6_1, arg_6_2)
	xyd.Backend.get():request(xyd.mid.TAKE_MISSION_AWARD, params, function(arg_7_0)
		if arg_7_0 == xyd.error.OK then
			xyd.WindowManager.get():closeWindow("mission_award_alert")
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.TAKE_MISSION_AWARD,
				params = {
					table_id = arg_6_0.tableID
				}
			})
		end
	end, params)
end

function var_0_0.setMissionAward(arg_8_0)
	local var_8_0 = 1

	arg_8_0:nodeByName(var_0_0.MANA1_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.ENERGY1_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.CRYSTAL1_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.XP1_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.SCROLL1_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.MANA2_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.ENERGY2_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.CRYSTAL2_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.XP2_IMAGE):setVisible(false)
	arg_8_0:nodeByName(var_0_0.SCROLL2_IMAGE):setVisible(false)

	local var_8_1 = xyd.tables.mission:crystal(arg_8_0.tableID)

	if var_8_1 > 0 then
		if var_8_0 == 1 then
			arg_8_0:nodeByName(var_0_0.CRYSTAL1_IMAGE):setVisible(true)
			arg_8_0:nodeByName(var_0_0.AWARD1):setString(var_8_1)
		else
			arg_8_0:nodeByName(var_0_0.CRYSTAL2_IMAGE):setVisible(true)
			arg_8_0:nodeByName(var_0_0.AWARD2):setString(var_8_1)
		end

		var_8_0 = var_8_0 + 1
	end

	local var_8_2 = xyd.tables.mission:mana(arg_8_0.tableID)

	if var_8_2 > 0 then
		if var_8_0 == 1 then
			arg_8_0:nodeByName(var_0_0.MANA1_IMAGE):setVisible(true)
			arg_8_0:nodeByName(var_0_0.AWARD1):setString(var_8_2)
		else
			arg_8_0:nodeByName(var_0_0.MANA2_IMAGE):setVisible(true)
			arg_8_0:nodeByName(var_0_0.AWARD2):setString(var_8_2)
		end

		var_8_0 = var_8_0 + 1
	end

	local var_8_3 = xyd.tables.mission:energy(arg_8_0.tableID)

	if var_8_3 > 0 then
		if var_8_0 == 1 then
			arg_8_0:nodeByName(var_0_0.ENERGY1_IMAGE):setVisible(true)
			arg_8_0:nodeByName(var_0_0.AWARD1):setString(var_8_3)
		else
			arg_8_0:nodeByName(var_0_0.ENERGY2_IMAGE):setVisible(true)
			arg_8_0:nodeByName(var_0_0.AWARD2):setString(var_8_3)
		end

		var_8_0 = var_8_0 + 1
	end

	local var_8_4 = xyd.tables.mission:scroll(arg_8_0.tableID)

	if var_8_4 > 0 then
		if var_8_0 == 1 then
			arg_8_0:nodeByName(var_0_0.SCROLL1_IMAGE):setVisible(true)
			arg_8_0:nodeByName(var_0_0.AWARD1):setString(var_8_4)
		else
			arg_8_0:nodeByName(var_0_0.SCROLL2_IMAGE):setVisible(true)
			arg_8_0:nodeByName(var_0_0.AWARD2):setString(var_8_4)
		end

		var_8_0 = var_8_0 + 1
	end

	local var_8_5 = xyd.tables.mission:exp(arg_8_0.tableID)

	if var_8_5 > 0 then
		if var_8_0 == 1 then
			arg_8_0:nodeByName(var_0_0.XP1_IMAGE):setVisible(true)
			arg_8_0:nodeByName(var_0_0.AWARD1):setString(var_8_5)
		else
			arg_8_0:nodeByName(var_0_0.XP2_IMAGE):setVisible(true)
			arg_8_0:nodeByName(var_0_0.AWARD2):setString(var_8_5)
		end

		local var_8_6 = var_8_0 + 1
	end
end

return var_0_0
