local var_0_0 = class("AdventureOccurWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.adventureEvent
local var_0_3 = xyd.tables.adventureSummon

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.event = arg_1_2
	arg_1_0.index = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)
end

function var_0_0.showTopEffect(arg_5_0)
	local var_5_0 = "skeletons/adventure/adventure_title_bg_light"
	local var_5_1 = var_0_1.new(var_5_0 .. ".json", var_5_0 .. ".atlas", 1)
	local var_5_2 = cc.p(arg_5_0:nodeByName("effect"):getPosition())

	var_5_1:align(display.CENTER, 0, 0):addTo(arg_5_0:nodeByName("effect"))
	var_5_1:play(nil, true, 1, nil)
end

function var_0_0.showHideEffect(arg_6_0)
	local var_6_0 = "skeletons/adventure/zhuzhan02"
	local var_6_1 = var_0_1.new(var_6_0 .. ".json", var_6_0 .. ".atlas", 1)
	local var_6_2 = display.newNode()

	var_6_2:size(394, 454)
	var_6_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_6_2:addTo(arg_6_0:nodeByName("container"))

	local var_6_3 = var_6_2:getContentSize()

	var_6_1:align(display.CENTER, var_6_3.width / 2, var_6_3.height / 2):addTo(var_6_2)
	var_6_1:play(nil, false)

	local var_6_4 = cc.p(arg_6_0:nodeByName("border"):getPosition())

	var_6_2:pos(var_6_4.x, var_6_4.y)

	local var_6_5 = cc.Spawn:create(cc.CallFunc:create(function()
		arg_6_0:nodeByName("event_container"):setVisible(false)
	end), cc.MoveTo:create(1.2, cc.p(50, 200)), cc.Sequence:create({
		cc.DelayTime:create(0.7),
		cc.CallFunc:create(function()
			return
		end)
	}))

	var_6_2:runActionOnce(var_6_5, false, function()
		arg_6_0:layout()
	end, 0.2)
end

function var_0_0.layout(arg_10_0)
	arg_10_0.index = arg_10_0.index + 1

	if arg_10_0.index > #arg_10_0.event then
		if arg_10_0.selfPlayer.AdventureEventOccurIds and next(arg_10_0.selfPlayer.AdventureEventOccurIds) then
			arg_10_0.event = clone(arg_10_0.selfPlayer.AdventureEventOccurIds)
			arg_10_0.selfPlayer.AdventureEventOccurIds = {}
			arg_10_0.index = 1
		else
			xyd.WindowManager.get():closeWindow(arg_10_0)

			return
		end
	end

	arg_10_0.eventId = arg_10_0.event[arg_10_0.index].eventId
	arg_10_0.eventInfo = arg_10_0.event[arg_10_0.index].eventInfo

	local var_10_0
	local var_10_1
	local var_10_2
	local var_10_3 = arg_10_0:nodeByName("img")
	local var_10_4 = arg_10_0:nodeByName("title")
	local var_10_5 = arg_10_0:nodeByName("card_container")

	arg_10_0:nodeByName("event_container"):setVisible(true)
	var_10_5:removeAllChildren()
	var_10_3:removeAllChildren()
	var_10_4:removeAllChildren()

	local var_10_6 = xyd.AssetLoader.get():loadSprite(var_0_2:titleBg(arg_10_0.eventId))
	local var_10_7 = xyd.AssetLoader.get():loadSprite(var_0_2:titlePic(arg_10_0.eventId))

	if tonumber(arg_10_0.eventId) == xyd.AdventureEventType.FAVOR then
		local var_10_8 = arg_10_0.selfPlayer:getHeroByID(arg_10_0.eventInfo.special_data)

		arg_10_0.adventureEvent:updateCardContainer(var_10_8, var_10_5)
	elseif tonumber(arg_10_0.eventId) == xyd.AdventureEventType.SUMMON then
		local var_10_9 = var_0_3:itemId(tostring(arg_10_0.eventInfo.special_data))

		arg_10_0.adventureEvent:updateCardContainer(nil, var_10_5, nil, var_10_9)
	end

	var_10_6:addTo(var_10_3)
	var_10_7:addTo(var_10_4)
	arg_10_0:nodeByName("event_container"):setScale(0)

	local var_10_10 = cc.Sequence:create({
		cc.ScaleTo:create(0.5, 1),
		cc.DelayTime:create(2)
	})

	arg_10_0:showTopEffect()
	arg_10_0:nodeByName("event_container"):runActionOnce(var_10_10, false, function()
		arg_10_0:setTouchEnabled(true)
		arg_10_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
			if arg_12_0.name == "began" then
				return true
			elseif arg_12_0.name == "ended" then
				arg_10_0:showHideEffect()
				arg_10_0:setTouchEnabled(false)
			end
		end)
	end)
end

return var_0_0
