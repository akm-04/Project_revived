local var_0_0 = class("SubDevWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.functionOpen
local var_0_2 = xyd.tables.translation
local var_0_3 = cc.Director:getInstance():getVisibleSize()
local var_0_4 = (var_0_3.width - xyd.STAGE_WIDTH) / 2
local var_0_5 = (var_0_3.height - xyd.STAGE_HEIGHT) / 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.treasureModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
	arg_1_0.skyModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()

	local var_2_0 = arg_2_0:nodeByName("treasure_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_TREASURE) then
		xyd.nodeEventSample(var_2_0, {}, function()
			arg_2_0.treasureModel:loadTreasureInfo(function(arg_4_0, arg_4_1)
				if arg_4_0 == xyd.error.OK then
					arg_2_0.selfPlayer:loadWorldMap(function()
						xyd.WindowManager.get():openWindow("treasure_window")
					end)
				end
			end)
		end)
	else
		arg_2_0:addLockAndTips(var_2_0, xyd.FunctionID.ID_TREASURE)
	end

	local var_2_1 = arg_2_0:nodeByName("march_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_MARCH) then
		xyd.nodeEventSample(var_2_1, {}, function()
			local var_6_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)

			if var_6_0.mapInfo == nil then
				var_6_0:loadMarchInfo({}, function(arg_7_0)
					if arg_7_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("march")
					end
				end)
			else
				xyd.WindowManager.get():openWindow("march")
			end
		end)
	else
		arg_2_0:addLockAndTips(var_2_1, xyd.FunctionID.ID_MARCH)
	end

	local var_2_2 = arg_2_0:nodeByName("sky_node")

	var_2_2:setTouchEnabled(true)
	var_2_2:setTouchSwallowEnabled(false)

	if not arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) then
		arg_2_0:addLock(var_2_2)
	end

	var_2_2.points = {
		{
			x = 401,
			y = 83
		},
		{
			x = 401,
			y = 386
		},
		{
			x = 685,
			y = 386
		},
		{
			x = 586,
			y = 83
		}
	}

	var_2_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			if not arg_2_0:isEventPossibleOnNode(var_2_2.points, arg_8_0.x - var_0_4, arg_8_0.y - var_0_5) then
				return
			end

			var_2_2:setScale(0.9)

			return true
		elseif arg_8_0.name == "moved" then
			if arg_2_0:isEventPossibleOnNode(var_2_2.points, arg_8_0.x - var_0_4, arg_8_0.y - var_0_5) then
				return
			end

			var_2_2:setScale(1)
		elseif arg_8_0.name == "ended" then
			var_2_2:setScale(1)

			if not arg_2_0:isEventPossibleOnNode(var_2_2.points, arg_8_0.x - var_0_4, arg_8_0.y - var_0_5) then
				return
			end

			if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) then
				arg_2_0.skyModel:getCampaignInfo(function(arg_9_0)
					if arg_9_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("pet_campaign")
					end
				end)
			else
				arg_2_0:lockTip(xyd.FunctionID.ID_PET)
			end
		end
	end)

	local var_2_3 = arg_2_0:nodeByName("cloud_node")

	var_2_3:setTouchEnabled(true)
	var_2_3:setTouchSwallowEnabled(false)

	if not arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_CLOUD_CITY) then
		arg_2_0:addLock(var_2_3)
	end

	var_2_3.points = {
		{
			x = 602,
			y = 83
		},
		{
			x = 704,
			y = 386
		},
		{
			x = 884,
			y = 386
		},
		{
			x = 884,
			y = 83
		}
	}

	var_2_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			if not arg_2_0:isEventPossibleOnNode(var_2_3.points, arg_10_0.x - var_0_4, arg_10_0.y - var_0_5) then
				return
			end

			var_2_3:setScale(0.9)

			return true
		elseif arg_10_0.name == "moved" then
			if arg_2_0:isEventPossibleOnNode(var_2_3.points, arg_10_0.x - var_0_4, arg_10_0.y - var_0_5) then
				return
			end

			var_2_3:setScale(1)
		elseif arg_10_0.name == "ended" then
			var_2_3:setScale(1)

			if not arg_2_0:isEventPossibleOnNode(var_2_3.points, arg_10_0.x - var_0_4, arg_10_0.y - var_0_5) then
				return
			end

			if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_CLOUD_CITY) then
				xyd.WindowManager.get():openWindow("cloud_city")
			else
				arg_2_0:lockTip(xyd.FunctionID.ID_CLOUD_CITY)
			end
		end
	end)

	local var_2_4 = arg_2_0:nodeByName("conquer_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_CONQUER_SCHOOL) then
		xyd.nodeEventSample(var_2_4, {}, function()
			xyd.ModelManager.get():loadModel(xyd.ModelType.CONQUER_SCHOOL):loadConquerSchoolInfo(function(arg_12_0)
				if arg_12_0 then
					xyd.WindowManager.get():openWindow("conquer_school", response)
				end
			end, true)
		end)
	else
		arg_2_0:addLockAndTips(var_2_4, xyd.FunctionID.ID_CONQUER_SCHOOL)
	end

	arg_2_0.treasureRedP = arg_2_0:nodeByName("treasure_red_p")

	arg_2_0:checkRedMark(xyd.CheckMiddleRed.TREASURE)

	arg_2_0.skyRedP = arg_2_0:nodeByName("sky_red_p")

	arg_2_0:checkRedMark(xyd.CheckMiddleRed.SKY)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.CHECK_MIDDLE_RED_MARK, function(arg_13_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:checkRedMark(arg_13_0.params)
		end
	end)

	for iter_2_0 = 1, 5 do
		arg_2_0:nodeByName("des" .. iter_2_0):setString(xyd.tables.translation:translation("YANGCHENGJIHUA_TIP" .. iter_2_0))
	end

	arg_2_0:playGuide()
end

function var_0_0.isEventPossibleOnNode(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = arg_14_1[1]
	local var_14_1 = arg_14_1[2]
	local var_14_2 = arg_14_1[3]
	local var_14_3 = arg_14_1[4]
	local var_14_4 = (var_14_1.x - var_14_0.x) * (arg_14_3 - var_14_0.y) - (var_14_1.y - var_14_0.y) * (arg_14_2 - var_14_0.x)
	local var_14_5 = (var_14_2.x - var_14_1.x) * (arg_14_3 - var_14_1.y) - (var_14_2.y - var_14_1.y) * (arg_14_2 - var_14_1.x)
	local var_14_6 = (var_14_3.x - var_14_2.x) * (arg_14_3 - var_14_2.y) - (var_14_3.y - var_14_2.y) * (arg_14_2 - var_14_2.x)
	local var_14_7 = (var_14_0.x - var_14_3.x) * (arg_14_3 - var_14_3.y) - (var_14_0.y - var_14_3.y) * (arg_14_2 - var_14_3.x)

	if var_14_4 >= 0 and var_14_5 >= 0 and var_14_6 >= 0 and var_14_7 >= 0 or var_14_4 <= 0 and var_14_5 <= 0 and var_14_6 <= 0 and var_14_7 <= 0 then
		return true
	else
		return false
	end
end

function var_0_0.addLockAndTips(arg_15_0, arg_15_1, arg_15_2)
	arg_15_0:addLock(arg_15_1, arg_15_2)
	xyd.nodeEventSample(arg_15_1, {}, function()
		arg_15_0:lockTip(arg_15_2)
	end)
end

function var_0_0.addLock(arg_17_0, arg_17_1, arg_17_2)
	arg_17_1:runActionOnce(cc.TintBy:create(0, -100, -100, -100))

	local var_17_0 = xyd.AssetLoader.get():loadSprite("windows/common/lock.png")

	var_17_0:addTo(arg_17_1)

	local var_17_1 = arg_17_1:getContentSize()

	var_17_0:setPosition(var_17_1.width / 2, var_17_1.height / 2)
end

function var_0_0.lockTip(arg_18_0, arg_18_1)
	local var_18_0 = var_0_1:tip(arg_18_1)

	if var_18_0 == "" then
		var_18_0 = var_0_2:translation("FUNCTION_OPEN_TIP_OTHER")
	end

	xyd.WindowManager.get():openWindow("toast", {
		message = var_18_0
	})
end

function var_0_0.checkRedMark(arg_19_0, arg_19_1)
	if arg_19_1 == xyd.CheckMiddleRed.TREASURE then
		arg_19_0.treasureRedP:setVisible(arg_19_0.treasureModel.has_red)
	elseif arg_19_1 == xyd.CheckMiddleRed.SKY then
		if not xyd.WindowManager.get():getWindow("pet_campaign") and arg_19_0.skyModel.has_red == true then
			arg_19_0.skyModel.begin_sweep_time = 0

			arg_19_0.skyRedP:setVisible(true)
		else
			arg_19_0.skyModel.has_red = nil

			arg_19_0.skyRedP:setVisible(false)
		end
	end
end

function var_0_0.playGuide(arg_20_0)
	local var_20_0 = xyd.WindowManager.get():getWindow("guide")
	local var_20_1 = xyd.StoryData.get():getGuideID()

	if var_20_1 >= xyd.GuideStoryType.GUIDE_PET_ONE and var_20_1 < xyd.GuideStoryType.GUIDE_PET_THREE then
		xyd.WindowManager.get():openWindow("guide")

		local var_20_2 = xyd.WindowManager.get():getWindow("guide")

		var_20_2:addNode()
		var_20_2:setStencil(250, 250, 514, 262, 0, {
			main_scene = true,
			position = {
				700,
				200
			}
		})
	end
end

function var_0_0.didClose(arg_21_0)
	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_PET_TWO then
		local var_21_0 = xyd.WindowManager.get():getWindow("main_scene_bottom")

		if var_21_0 then
			var_21_0:playGuide(true)
		end
	else
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_ACTION_START,
			params = {}
		})
	end
end

return var_0_0
