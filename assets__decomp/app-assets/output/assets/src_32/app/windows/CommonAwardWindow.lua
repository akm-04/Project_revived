local var_0_0 = class("CommonAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 60
local var_0_3 = 70
local var_0_4 = 40
local var_0_5 = 20
local var_0_6 = 35
local var_0_7 = 30

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.title = arg_1_2.name or var_0_1:translation("ALERT_AWARD_NAME")
	arg_1_0.awards = arg_1_2.awards or {}
	arg_1_0.callback = arg_1_2.callback or nil
	arg_1_0.isList = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = xyd.tables.sound:getSound("ui_tips")

	audio.playSound(var_2_0, false)
	var_0_0.super.willOpen()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen()
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
	arg_3_0:setTouchSwallowEnabled(true)
end

function var_0_0.willClose(arg_4_0)
	var_0_0.super.willClose()
end

function var_0_0.didClose(arg_5_0)
	var_0_0.super.didClose()

	if arg_5_0.callback then
		arg_5_0.callback()
	end
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 20 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_0.layout(arg_7_0)
	arg_7_0:nodeByName("tips_txt"):setString(var_0_1:translation("MISSION_REWARD_TIPS"))

	local var_7_0 = #arg_7_0.awards
	local var_7_1 = (var_7_0 - 2) * var_0_3 + 10
	local var_7_2 = arg_7_0:nodeByName("item_container"):getContentSize()
	local var_7_3 = arg_7_0:nodeByName("container"):getContentSize()

	arg_7_0:nodeByName("item_container"):setContentSize(var_7_2.width, var_7_2.height + var_7_1)
	arg_7_0:nodeByName("container"):setContentSize(var_7_3.width, var_7_3.height + var_7_1)
	arg_7_0:nodeByName("item_container"):setPositionY(arg_7_0:nodeByName("item_container"):getPositionY() + var_7_1)
	arg_7_0:nodeByName("tips_txt"):setPositionY(arg_7_0:nodeByName("tips_txt"):getPositionY() + var_7_1)
	arg_7_0:nodeByName("bg_line"):setPositionY(arg_7_0:nodeByName("bg_line"):getPositionY() + var_7_1)

	arg_7_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 350, 130 + var_7_1),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_7_0:nodeByName("item_container")):onScroll(handler(arg_7_0, arg_7_0.scrollListener))

	arg_7_0.list:setAnchorPoint(cc.p(0, 0))

	for iter_7_0 = 1, var_7_0 do
		local var_7_4 = arg_7_0.awards[iter_7_0]
		local var_7_5 = cc.Node:create()

		var_7_5:setContentSize(var_0_2, var_0_2)

		if var_7_4.item_id > 0 then
			xyd.setItemBorder(var_7_5, var_7_4.item_id)
		else
			local var_7_6 = xyd.tables.asset:transparentIcon(item.item_id)
			local var_7_7 = xyd.AssetLoader:get():loadSprite(var_7_6)

			xyd.displaySpriteOnContainer(var_7_7, var_7_5, false)
		end

		local var_7_8 = display.newNode()
		local var_7_9 = arg_7_0.list:newItem()

		var_7_8:addChild(var_7_5)
		var_7_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_7_5:setPosition(20, 35)

		local var_7_10 = {
			size = 18,
			color = cc.c4b(255, 239, 148, 255)
		}
		local var_7_11 = xyd.AssetLoader:get():loadLabel(var_7_10)

		if var_7_4.item_id < 0 then
			var_7_11:setString("X " .. var_7_4.item_num)
		else
			local var_7_12 = xyd.tables.item:name(var_7_4.item_id)

			var_7_11:setString(var_7_12 .. " X " .. var_7_4.item_num)
		end

		var_7_8:addChild(var_7_11)
		var_7_11:setAnchorPoint(cc.p(0, 0.5))
		var_7_11:setPosition(75, 35)
		var_7_8:setContentSize(300, 70)
		var_7_9:addContent(var_7_8)
		var_7_9:setItemSize(300, 70)
		arg_7_0.list:addItem(var_7_9)
	end

	arg_7_0.list:reload()
end

return var_0_0
