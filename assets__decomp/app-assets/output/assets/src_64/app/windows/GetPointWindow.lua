local var_0_0 = class("GetPointWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = {
	"",
	"map_window",
	"arena",
	"march",
	"mission"
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.count = arg_1_2.count or nil
	arg_1_0.activity = arg_1_2.activity or nil
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 20 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 740, 450),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	if arg_3_0.activity then
		arg_3_0:layout()
	else
		arg_3_0:updateWindow()
	end
end

function var_0_0.updateWindow(arg_4_0)
	arg_4_0.activities:loadActivities(function(arg_5_0)
		if arg_5_0 == xyd.error.OK then
			arg_4_0.activity = arg_4_0.activities:getActivitiesList()[arg_4_0.count]

			arg_4_0:layout()
		end
	end)
end

function var_0_0.layout(arg_6_0)
	if arg_6_0.list then
		arg_6_0.list:removeAllItems()
	end

	local var_6_0 = arg_6_0.activity.details.mission_ids
	local var_6_1 = arg_6_0.activity.details.mission_nums

	for iter_6_0 = 1, #var_6_0 do
		local var_6_2 = xyd.tables.translation
		local var_6_3 = display.newNode()
		local var_6_4 = arg_6_0.list:newItem()
		local var_6_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/gain_point_item.csb")
		local var_6_6 = var_6_5:getChildByName("container")

		var_6_6:getChildByName("point_name_txt"):setString(var_6_2:translation("ACTIVITY_POINT_REWARD"))

		local var_6_7 = var_6_6:getChildByName("btn")

		if var_0_1[iter_6_0] == "" then
			var_6_7:setVisible(false)
		end

		local var_6_8 = xyd.tables.activityMission:taskNum(tonumber(var_6_0[iter_6_0]))

		if var_6_8 <= tonumber(var_6_1[iter_6_0]) then
			var_6_7:setVisible(false)
			var_6_6:getChildByName("point_get"):setVisible(true)
		else
			var_6_7:setVisible(true)
			var_6_6:getChildByName("point_get"):setVisible(false)
			var_6_7:addTouchEventListener(function(arg_7_0, arg_7_1)
				if arg_7_1 == ccui.TouchEventType.ended then
					arg_6_0.activities:setActivityCount(arg_6_0.count)

					if var_0_1[xyd.tables.activityMission:goId(tonumber(var_6_0[iter_6_0]))] == "map_window" then
						arg_6_0.guild:loadGuildMap(function(arg_8_0)
							if arg_8_0 == xyd.error.OK then
								local var_8_0 = {}

								var_8_0.chapter_type = 1

								xyd.WindowManager.get():openWindow("map_window", var_8_0)
							else
								xyd.WindowManager.get():openWindow("map_window", {
									chapter_type = 1
								})
							end
						end)
					elseif var_0_1[xyd.tables.activityMission:goId(tonumber(var_6_0[iter_6_0]))] == "march" then
						if arg_6_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_MARCH) ~= true then
							local var_7_0
							local var_7_1 = xyd.tables.functionOpen
							local var_7_2 = xyd.tables.translation

							if var_7_1:level(xyd.FunctionID.ID_MARCH) > 1 then
								var_7_0 = string.format(var_7_2:translation("FUNCTION_OPEN_TIP_LEVEL"), var_7_1:level(xyd.FunctionID.ID_MARCH))
							elseif var_7_1:stage(xyd.FunctionID.ID_MARCH) > 0 then
								local var_7_3 = xyd.tables.campaign
								local var_7_4 = "NUM_" .. var_7_3:chapter(var_7_1:stage(xyd.FunctionID.ID_MARCH))

								var_7_0 = string.format(var_7_2:translation("FUNCTION_OPEN_TIP_STAGE"), var_7_2:translation(var_7_4))
							else
								var_7_0 = string.format(var_7_2:translation("FUNCTION_OPEN_TIP_OTHER"))
							end

							if xyd.WindowManager.get():getWindow("toast") ~= nil then
								xyd.WindowManager.get():closeWindow("toast")
							end

							xyd.WindowManager.get():openWindow("toast", {
								message = var_7_0
							})

							return true
						end

						local var_7_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)

						if var_7_5.mapInfo == nil then
							var_7_5:loadMarchInfo({}, function(arg_9_0)
								if arg_9_0 == xyd.error.OK then
									xyd.WindowManager.get():openWindow("march")
								end
							end)
						else
							xyd.WindowManager.get():openWindow("march")
						end
					elseif var_0_1[xyd.tables.activityMission:goId(tonumber(var_6_0[iter_6_0]))] == "arena" then
						if arg_6_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ARENA) ~= true then
							local var_7_6
							local var_7_7 = xyd.tables.functionOpen

							if var_7_7:level(xyd.FunctionID.ID_ARENA) > 1 then
								var_7_6 = string.format(var_6_2:translation("FUNCTION_OPEN_TIP_LEVEL"), var_7_7:level(xyd.FunctionID.ID_ARENA))
							elseif var_7_7:stage(xyd.FunctionID.ID_ARENA) > 0 then
								local var_7_8 = xyd.tables.campaign
								local var_7_9 = "NUM_" .. var_7_8:chapter(var_7_7:stage(xyd.FunctionID.ID_ARENA))

								var_7_6 = string.format(var_6_2:translation("FUNCTION_OPEN_TIP_STAGE"), var_6_2:translation(var_7_9))
							else
								var_7_6 = string.format(var_6_2:translation("FUNCTION_OPEN_TIP_OTHER"))
							end

							if xyd.WindowManager.get():getWindow("toast") ~= nil then
								xyd.WindowManager.get():closeWindow("toast")
							end

							xyd.WindowManager.get():openWindow("toast", {
								message = var_7_6
							})

							return true
						end

						xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):loadArenaInfo(function(arg_10_0, arg_10_1)
							if arg_10_0 == xyd.error.OK then
								xyd.WindowManager.get():openWindow("arena")
							end
						end)
					else
						xyd.WindowManager.get():openWindow(var_0_1[xyd.tables.activityMission:goId(tonumber(var_6_0[iter_6_0]))])
					end
				end
			end)
		end

		local var_6_9 = var_6_6:getChildByName("item_name_txt")
		local var_6_10 = "（" .. var_6_1[iter_6_0] .. "/" .. var_6_8 .. "）"

		var_6_9:setString(xyd.tables.activityMission:name(tonumber(var_6_0[iter_6_0])) .. var_6_10)

		local var_6_11 = var_6_6:getChildByName("point_num_txt"):setString(xyd.tables.activityMission:point(tonumber(var_6_0[iter_6_0])))

		var_6_5:addTo(var_6_3)
		var_6_3:setContentSize(748, 144)
		var_6_3:setAnchorPoint(cc.p(0, 0))
		var_6_3:setPosition(0, 0)
		var_6_4:addContent(var_6_3)
		var_6_4:setItemSize(748, 144)
		arg_6_0.list:addItem(var_6_4)
	end

	arg_6_0.list:reload()
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)
	arg_11_0:addBlockLayer()
end

return var_0_0
