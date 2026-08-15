local var_0_0 = class("DreamWorldSelectModeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = cc.Director:getInstance():getVisibleSize()
local var_0_3 = (var_0_2.width - xyd.STAGE_WIDTH) / 2
local var_0_4 = (var_0_2.height - xyd.STAGE_HEIGHT) / 2
local var_0_5 = {
	Challenge = 2,
	Story = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dreamWorld = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("text_story"):setString(var_0_1:translation("DREAM_WORLD_TEXT_3"))
	arg_3_0:nodeByName("text_challenge"):setString(var_0_1:translation("DREAM_WORLD_TEXT_4"))
	arg_3_0:nodeByName("text_close"):setString(var_0_1:translation("DREAM_WORLD_TEXT_5"))
	arg_3_0:nodeByName("text_story"):enableOutline(cc.c4b(25, 25, 25, 255), 2)
	arg_3_0:nodeByName("text_challenge"):enableOutline(cc.c4b(25, 25, 25, 255), 2)
	arg_3_0:nodeByName("text_close"):enableOutline(cc.c4b(25, 25, 25, 255), 2)

	local var_3_0 = 11002
	local var_3_1 = 11002
	local var_3_2 = xyd.HeroAnimation.new(var_3_0, var_3_1)

	var_3_2:idle()
	var_3_2:addTo(arg_3_0:nodeByName("node_hero_1"))

	local var_3_3 = 11001
	local var_3_4 = 11001
	local var_3_5 = xyd.HeroAnimation.new(var_3_3, var_3_4)

	var_3_5:flipX(true)
	var_3_5:idle()
	var_3_5:addTo(arg_3_0:nodeByName("node_hero_2"))

	local var_3_6 = arg_3_0:nodeByName("img_story")

	var_3_6:setTouchEnabled(true)
	var_3_6:setTouchSwallowEnabled(false)

	var_3_6.points = {
		{
			x = 154,
			y = 100
		},
		{
			x = 154,
			y = 678
		},
		{
			x = 650,
			y = 678
		},
		{
			x = 590,
			y = 100
		}
	}

	var_3_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			if not arg_3_0:isEventPossibleOnNode(var_3_6.points, arg_4_0.x - var_0_3, arg_4_0.y - var_0_4) then
				return
			end

			var_3_6:setScale(0.9)

			return true
		elseif arg_4_0.name == "moved" then
			if arg_3_0:isEventPossibleOnNode(var_3_6.points, arg_4_0.x - var_0_3, arg_4_0.y - var_0_4) then
				return
			end

			var_3_6:setScale(1)
		elseif arg_4_0.name == "ended" then
			var_3_6:setScale(1)

			if not arg_3_0:isEventPossibleOnNode(var_3_6.points, arg_4_0.x - var_0_3, arg_4_0.y - var_0_4) then
				return
			end

			local var_4_0 = 100000

			xyd.WindowManager.get():openWindow("dream_world_story", {
				notSendMid = true,
				showBG = true,
				dialogueID = var_4_0,
				callback = function()
					arg_3_0.dreamWorld:startExplore(var_0_5.Story, function()
						xyd.WindowManager.get():openWindow("dream_world_explore", {
							showOpenStory = true
						})
					end)
					arg_3_0:close()
				end
			})
		end
	end)

	local var_3_7 = arg_3_0:nodeByName("img_challenge")

	var_3_7:setTouchEnabled(true)
	var_3_7:setTouchSwallowEnabled(false)

	var_3_7.points = {
		{
			x = 625,
			y = 100
		},
		{
			x = 690,
			y = 678
		},
		{
			x = 1118,
			y = 678
		},
		{
			x = 1118,
			y = 100
		}
	}

	var_3_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			if not arg_3_0:isEventPossibleOnNode(var_3_7.points, arg_7_0.x - var_0_3, arg_7_0.y - var_0_4) then
				return
			end

			var_3_7:setScale(0.9)

			return true
		elseif arg_7_0.name == "moved" then
			if arg_3_0:isEventPossibleOnNode(var_3_7.points, arg_7_0.x - var_0_3, arg_7_0.y - var_0_4) then
				return
			end

			var_3_7:setScale(1)
		elseif arg_7_0.name == "ended" then
			var_3_7:setScale(1)

			if not arg_3_0:isEventPossibleOnNode(var_3_7.points, arg_7_0.x - var_0_3, arg_7_0.y - var_0_4) then
				return
			end

			local var_7_0 = 100000

			xyd.WindowManager.get():openWindow("dream_world_story", {
				notSendMid = true,
				showBG = true,
				dialogueID = var_7_0,
				callback = function()
					arg_3_0.dreamWorld:startExplore(var_0_5.Challenge, function()
						xyd.WindowManager.get():openWindow("dream_world_explore", {
							showOpenStory = true
						})
					end)
					arg_3_0:close()
				end
			})
		end
	end)
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

function var_0_0.didOpen(arg_11_0)
	arg_11_0:addBlockLayer()
end

function var_0_0.didClose(arg_12_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {}
	})
end

return var_0_0
