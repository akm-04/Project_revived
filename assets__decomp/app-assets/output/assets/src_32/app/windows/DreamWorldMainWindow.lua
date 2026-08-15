local var_0_0 = class("DreamWorldMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = cc.Director:getInstance():getVisibleSize()
local var_0_3 = (var_0_2.width - xyd.STAGE_WIDTH) / 2
local var_0_4 = (var_0_2.height - xyd.STAGE_HEIGHT) / 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dreamWorld = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:addTopSidebar()
	arg_3_0:nodeByName("text_left_time"):setString(var_0_1:translation("DREAM_WORLD_TEXT_1"))
	arg_3_0:updateState()
	arg_3_0:nodeByName("text_left_time"):enableOutline(cc.c4b(39, 39, 39, 255), 2)
	arg_3_0:nodeByName("left_time"):enableOutline(cc.c4b(39, 39, 39, 255), 2)

	local var_3_0 = arg_3_0:nodeByName("img_start")

	var_3_0:setTouchEnabled(true)
	var_3_0:setTouchSwallowEnabled(false)

	var_3_0.points = {
		{
			x = 63,
			y = 52
		},
		{
			x = 63,
			y = 632
		},
		{
			x = 697,
			y = 632
		},
		{
			x = 788,
			y = 52
		}
	}

	var_3_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			if not arg_3_0:isEventPossibleOnNode(var_3_0.points, arg_4_0.x - var_0_3, arg_4_0.y - var_0_4) then
				return
			end

			var_3_0:setScale(0.9)

			return true
		elseif arg_4_0.name == "moved" then
			if arg_3_0:isEventPossibleOnNode(var_3_0.points, arg_4_0.x - var_0_3, arg_4_0.y - var_0_4) then
				return
			end

			var_3_0:setScale(1)
		elseif arg_4_0.name == "ended" then
			var_3_0:setScale(1)

			if not arg_3_0:isEventPossibleOnNode(var_3_0.points, arg_4_0.x - var_0_3, arg_4_0.y - var_0_4) then
				return
			end

			if arg_3_0.dreamWorld.mapType > 0 then
				arg_3_0.dreamWorld:getMap(function()
					xyd.WindowManager.get():openWindow("dream_world_explore")
				end)
			elseif arg_3_0.dreamWorld.ticketNum > 0 then
				xyd.WindowManager.get():openWindow("dream_world_select_mode")
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("DREAM_WORLD_TEXT_2")
				})
			end
		end
	end)

	local var_3_1 = arg_3_0:nodeByName("img_achievement")

	var_3_1:setTouchEnabled(true)
	var_3_1:setTouchSwallowEnabled(false)

	var_3_1.points = {
		{
			x = 785,
			y = 303
		},
		{
			x = 730,
			y = 628
		},
		{
			x = 1222,
			y = 628
		},
		{
			x = 1222,
			y = 303
		}
	}

	var_3_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			if not arg_3_0:isEventPossibleOnNode(var_3_1.points, arg_6_0.x - var_0_3, arg_6_0.y - var_0_4) then
				return
			end

			var_3_1:setScale(0.9)

			return true
		elseif arg_6_0.name == "moved" then
			if arg_3_0:isEventPossibleOnNode(var_3_1.points, arg_6_0.x - var_0_3, arg_6_0.y - var_0_4) then
				return
			end

			var_3_1:setScale(1)
		elseif arg_6_0.name == "ended" then
			var_3_1:setScale(1)

			if not arg_3_0:isEventPossibleOnNode(var_3_1.points, arg_6_0.x - var_0_3, arg_6_0.y - var_0_4) then
				return
			end

			arg_3_0.dreamWorld:getTaskList(function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("dream_world_task")
				end
			end)
		end
	end)

	local var_3_2 = arg_3_0:nodeByName("img_rule")

	var_3_2:setTouchEnabled(true)
	var_3_2:setTouchSwallowEnabled(false)

	var_3_2.points = {
		{
			x = 820,
			y = 63
		},
		{
			x = 792,
			y = 268
		},
		{
			x = 1222,
			y = 268
		},
		{
			x = 1222,
			y = 63
		}
	}

	var_3_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			if not arg_3_0:isEventPossibleOnNode(var_3_2.points, arg_8_0.x - var_0_3, arg_8_0.y - var_0_4) then
				return
			end

			var_3_2:setScale(0.9)

			return true
		elseif arg_8_0.name == "moved" then
			if arg_3_0:isEventPossibleOnNode(var_3_2.points, arg_8_0.x - var_0_3, arg_8_0.y - var_0_4) then
				return
			end

			var_3_2:setScale(1)
		elseif arg_8_0.name == "ended" then
			var_3_2:setScale(1)

			if not arg_3_0:isEventPossibleOnNode(var_3_2.points, arg_8_0.x - var_0_3, arg_8_0.y - var_0_4) then
				return
			end

			local var_8_0 = {
				title_name = "ACTIVITY_DREAMWORLD_RULE_TITLE",
				rule = "ACTIVITY_DREAMWORLD_RULE_TEXT",
				style = xyd.RuleStyle.BLUE
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_8_0)
		end
	end)
end

function var_0_0.updateState(arg_9_0)
	if arg_9_0.dreamWorld.baseInfo.current_floor > 1 then
		arg_9_0:nodeByName("img_start_" .. arg_9_0.dreamWorld.baseInfo.current_floor):setVisible(true)
	end

	if arg_9_0.dreamWorld.mapType > 0 then
		arg_9_0:nodeByName("text_start"):setVisible(false)
		arg_9_0:nodeByName("text_continue"):setVisible(true)
	else
		arg_9_0:nodeByName("text_start"):setVisible(true)
		arg_9_0:nodeByName("text_continue"):setVisible(false)
	end

	local var_9_0 = xyd.tables.misc:getValue("dreamworld_energy2ticket_num")
	local var_9_1 = arg_9_0.dreamWorld.baseInfo.energy_cost
	local var_9_2 = string.format(var_0_1:translation("DREAM_WORLD_TEXT_18"), var_9_1, var_9_0)

	arg_9_0:nodeByName("left_time"):setString(arg_9_0.dreamWorld.ticketNum .. var_9_2)
end

function var_0_0.isEventPossibleOnNode(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = arg_10_1[1]
	local var_10_1 = arg_10_1[2]
	local var_10_2 = arg_10_1[3]
	local var_10_3 = arg_10_1[4]
	local var_10_4 = (var_10_1.x - var_10_0.x) * (arg_10_3 - var_10_0.y) - (var_10_1.y - var_10_0.y) * (arg_10_2 - var_10_0.x)
	local var_10_5 = (var_10_2.x - var_10_1.x) * (arg_10_3 - var_10_1.y) - (var_10_2.y - var_10_1.y) * (arg_10_2 - var_10_1.x)
	local var_10_6 = (var_10_3.x - var_10_2.x) * (arg_10_3 - var_10_2.y) - (var_10_3.y - var_10_2.y) * (arg_10_2 - var_10_2.x)
	local var_10_7 = (var_10_0.x - var_10_3.x) * (arg_10_3 - var_10_3.y) - (var_10_0.y - var_10_3.y) * (arg_10_2 - var_10_3.x)

	if var_10_4 >= 0 and var_10_5 >= 0 and var_10_6 >= 0 and var_10_7 >= 0 or var_10_4 <= 0 and var_10_5 <= 0 and var_10_6 <= 0 and var_10_7 <= 0 then
		return true
	else
		return false
	end
end

function var_0_0.didClose(arg_11_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {}
	})
end

return var_0_0
