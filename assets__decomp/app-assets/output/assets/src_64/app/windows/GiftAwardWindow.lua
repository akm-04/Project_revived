local var_0_0 = class("GiftAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 45
local var_0_3 = 50
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

	arg_7_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 290, 115 + var_7_1),
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

		if var_7_4.table_id > 0 then
			xyd.setItemBorder(var_7_5, var_7_4.table_id)
		else
			local var_7_6

			if var_7_4.energy and var_7_4.energy > 0 then
				var_7_6 = xyd.AssetLoader:get():loadSprite("images/tili.png")
			elseif var_7_4.crystal and var_7_4.crystal > 0 then
				var_7_6 = xyd.AssetLoader:get():loadSprite("images/zuanshi.png")
			elseif var_7_4.mana and var_7_4.mana > 0 then
				var_7_6 = xyd.AssetLoader:get():loadSprite("images/jinbi.png")
			elseif var_7_4.march_coin and var_7_4.march_coin > 0 then
				var_7_6 = xyd.AssetLoader:get():loadSprite("images/icon/eco/march_coin.png")
			elseif var_7_4.exp and var_7_4.exp > 0 then
				var_7_6 = xyd.AssetLoader:get():loadSprite("images/icon/eco/exp.png")
			elseif var_7_4.guild_coin and var_7_4.guild_coin > 0 then
				var_7_6 = xyd.AssetLoader:get():loadSprite("images/icon/eco/guild_coin.png")
			elseif var_7_4.arena_coin and var_7_4.arena_coin > 0 then
				var_7_6 = xyd.AssetLoader:get():loadSprite("images/icon/eco/shell.png")
			elseif var_7_4.friendship_coin and var_7_4.friendship_coin > 0 then
				var_7_6 = xyd.AssetLoader:get():loadSprite("images/icon/eco/friendship_coin.png")
			elseif var_7_4.dust and var_7_4.dust > 0 then
				var_7_6 = xyd.AssetLoader:get():loadSprite("images/icon/eco/magic_dust.png")
			elseif var_7_4.liquid and var_7_4.liquid > 0 then
				var_7_6 = xyd.AssetLoader:get():loadSprite("images/icon/eco/magic_liquid.png")
			elseif var_7_4.king_coin and var_7_4.king_coin > 0 then
				var_7_6 = xyd.AssetLoader:get():loadSprite("images/icon/eco/king_coin.png")
			elseif var_7_4.lucky_star and var_7_4.lucky_star > 0 then
				xyd.setItemBorder(var_7_5, -100)
			elseif var_7_4.lucky_coin and var_7_4.lucky_coin > 0 then
				xyd.setItemBorder(var_7_5, -5)
			elseif var_7_4.spirit_stone and var_7_4.spirit_stone > 0 then
				var_7_6 = xyd.AssetLoader:get():loadSprite("images/icon/eco/spirit_stone.png")
			end

			xyd.displaySpriteOnContainer(var_7_6, var_7_5, false)
		end

		local var_7_7 = display.newNode()
		local var_7_8 = arg_7_0.list:newItem()

		var_7_7:addChild(var_7_5)
		var_7_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_7_5:setPosition(40, 20)

		local var_7_9 = {
			size = 18,
			color = cc.c4b(255, 241, 0, 255)
		}
		local var_7_10 = xyd.AssetLoader:get():loadLabel(var_7_9)

		if var_7_4.table_id < 0 then
			var_7_10:setString("X " .. var_7_4.item_num)
		else
			local var_7_11 = xyd.tables.item:name(var_7_4.table_id)

			var_7_10:setString(var_7_11 .. " X " .. var_7_4.item_num)
		end

		var_7_7:addChild(var_7_10)
		var_7_10:setAnchorPoint(cc.p(0, 0.5))
		var_7_10:setPosition(95, 18)
		var_7_7:setContentSize(290, 50)
		var_7_8:addContent(var_7_7)
		var_7_8:setItemSize(290, 50)
		arg_7_0.list:addItem(var_7_8)
	end

	arg_7_0.list:reload()
end

return var_0_0
