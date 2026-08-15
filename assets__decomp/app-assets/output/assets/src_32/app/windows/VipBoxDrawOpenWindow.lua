local var_0_0 = class("VipBoxDrawOpenWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.hero
local var_0_4 = 5
local var_0_5 = 33
local var_0_6 = 15
local var_0_7 = 25
local var_0_8 = 0.04
local var_0_9 = 0.05
local var_0_10 = 0.1

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.heroId = arg_1_2.heroId
	arg_1_0.heroIds = arg_1_2.heroIds
	arg_1_0.awards = arg_1_2.awards
	arg_1_0.multiple = arg_1_2.multiple
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("title_txt"):setString(var_0_2:translation("ACTIVITY_VIP_BOX_DRAW_OPEN_TITLE"))
	arg_2_0:init()
	arg_2_0:roll(0)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.roll(arg_4_0, arg_4_1)
	moveTime = arg_4_0:rollFunc(arg_4_1)

	if moveTime == -1 then
		local var_4_0 = "skeletons/ui_effect/vip_box_draw/box_draw_open3"
		local var_4_1 = var_0_1.new(var_4_0 .. ".json", var_4_0 .. ".atlas", 1)

		var_4_1:addTo(arg_4_0)
		var_4_1:setPosition(0, -45)
		var_4_1:play(function()
			arg_4_0:drawFinish()
		end)

		return
	end

	local var_4_2 = arg_4_0.rollContainer:getChildByName("node1")

	var_4_2:setPosition(arg_4_0.nodePosition[var_0_4 + 2])

	local var_4_3 = var_4_2:getChildByName("avatar_container")
	local var_4_4 = arg_4_0:randomId()

	if arg_4_1 == var_0_5 - 2 then
		var_4_4 = arg_4_0.heroId
	end

	var_4_3:removeAllChildren()
	xyd.setAvatarBorder(var_4_4, var_4_3, 1, var_0_3:initialStar(var_4_4))

	for iter_4_0 = 2, var_0_4 + 1 do
		local var_4_5 = arg_4_0.rollContainer:getChildByName("node" .. iter_4_0)

		var_4_5:setName("node" .. iter_4_0 - 1)
		var_4_5:runAction(transition.sequence({
			cc.MoveTo:create(moveTime, cc.p(arg_4_0.nodePosition[iter_4_0 - 1]))
		}))
	end

	var_4_2:setName("node" .. var_0_4 + 1)

	local var_4_6 = cc.CallFunc:create(function()
		arg_4_0:roll(arg_4_1 + 1)
	end)

	var_4_2:runAction(transition.sequence({
		cc.MoveTo:create(moveTime, cc.p(arg_4_0.nodePosition[var_0_4 + 1])),
		var_4_6
	}))
end

function var_0_0.init(arg_7_0)
	local var_7_0 = arg_7_0:nodeByName("scroll_outer_container"):getContentSize()
	local var_7_1 = cc.rect(0, 0, var_7_0.width, var_7_0.height)

	arg_7_0.rollContainer = display.newClippingRegionNode(var_7_1):size(var_7_0.width, var_7_0.height)

	arg_7_0.rollContainer:addTo(arg_7_0:nodeByName("scroll_outer_container"))

	local var_7_2 = var_7_0.width / var_0_4

	arg_7_0.nodePosition = {}

	for iter_7_0 = 1, var_0_4 + 2 do
		arg_7_0.nodePosition[iter_7_0] = cc.p(var_7_2 * (iter_7_0 - 1.5), var_7_0.height / 2)
	end

	for iter_7_1 = 1, var_0_4 + 2 do
		heroId = arg_7_0:randomId()

		local var_7_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/vip_box_draw/vip_box_draw_open/vip_box_draw_open_node.csb")

		var_7_3:addTo(arg_7_0.rollContainer)
		var_7_3:setName("node" .. iter_7_1)
		var_7_3:setPosition(arg_7_0.nodePosition[iter_7_1])
		xyd.setAvatarBorder(heroId, var_7_3:getChildByName("avatar_container"), 1, var_0_3:initialStar(heroId))
	end
end

function var_0_0.randomId(arg_8_0)
	local var_8_0 = arg_8_0.heroIds[math.random(#arg_8_0.heroIds)]

	while var_8_0 == arg_8_0.preId or var_8_0 == arg_8_0.heroId do
		var_8_0 = arg_8_0.heroIds[math.random(#arg_8_0.heroIds)]
	end

	arg_8_0.preId = var_8_0

	return var_8_0
end

function var_0_0.rollFunc(arg_9_0, arg_9_1)
	if arg_9_1 > var_0_5 then
		return -1
	end

	if arg_9_1 < var_0_6 then
		return var_0_8
	end

	if arg_9_1 < var_0_7 then
		return var_0_9
	end

	return var_0_9 + (arg_9_1 - var_0_7) * var_0_10
end

function var_0_0.drawFinish(arg_10_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards({
		arg_10_0.awards[1]
	}, function()
		if arg_10_0.multiple then
			xyd.WindowManager.get():openWindow("vip_box_draw_extra", {
				award = {
					arg_10_0.awards[2]
				},
				multiple = arg_10_0.multiple
			})
		end

		xyd.WindowManager.get():closeWindow(arg_10_0.name)
	end)
end

return var_0_0
