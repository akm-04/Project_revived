local var_0_0 = class("MarchAwardWindow", import("app.common.ui.BaseWindow"))

var_0_0.AWARD_CONTAINER = "award_container"
var_0_0.TITLE = "task_award_title"
var_0_0.OK_BUTTON = "btn_award_ok"
var_0_0.OK = "ok_text"

local var_0_1 = 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.reward = arg_1_2.reward
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen()

	local var_2_0 = xyd.tables.sound:getSound("gain_window_sound")

	audio.playSound(var_2_0, false)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen()
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 0), nil, true)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName(var_0_0.AWARD_CONTAINER):setPosition(cc.p(0, 0))
	arg_4_0:nodeByName(var_0_0.TITLE):setString(xyd.tables.mission:name(arg_4_0.tableID))
	arg_4_0:setAward()
	arg_4_0:nodeByName(var_0_0.OK_BUTTON):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0:okEvent(arg_5_0, arg_5_1)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.okEvent(arg_6_0, arg_6_1, arg_6_2)
	arg_6_0:dispatchEvent({
		name = xyd.event.GOT_MARCH_AWARD
	})
end

function var_0_0.setAward(arg_7_0)
	local var_7_0 = arg_7_0.reward

	if var_7_0 == nil or next(var_7_0) == nil then
		return
	end

	local var_7_1 = var_7_0.item_cat_num + 1
	local var_7_2 = 1

	if var_7_0.march_coin and var_7_0.march_coin > 0 then
		var_7_1 = var_7_1 + 1
		var_7_2 = var_7_2 + 1
	end

	local var_7_3 = 60
	local var_7_4
	local var_7_5

	if var_7_1 > 1 then
		local var_7_6 = arg_7_0:nodeByName(var_0_0.AWARD_CONTAINER)
		local var_7_7 = var_7_6:getContentSize()
		local var_7_8 = cc.size(var_7_7.width, var_7_7.height + (var_7_1 - 1) * var_7_3)

		var_7_6:setContentSize(var_7_8)

		var_7_5 = arg_7_0:nodeByName("inner_container")

		local var_7_9 = var_7_5:getContentSize()
		local var_7_10 = cc.size(var_7_9.width, var_7_9.height + (var_7_1 - 1) * var_7_3)

		var_7_5:setContentSize(var_7_10)

		local var_7_11 = cc.p(arg_7_0:nodeByName(var_0_0.TITLE):getPosition())

		arg_7_0:nodeByName(var_0_0.TITLE):setPosition(cc.p(var_7_11.x, var_7_11.y + (var_7_8.height - var_7_7.height)))
	end

	local var_7_12

	for iter_7_0 = 1, var_7_1 do
		local var_7_13
		local var_7_14
		local var_7_15 = display.newNode()

		var_7_15:setAnchorPoint(1, 0)
		var_7_15:setContentSize(50, 50)
		var_7_15:setPosition(188, 20 + (var_7_1 - iter_7_0) * var_7_3)
		var_7_15:addTo(var_7_5)

		if iter_7_0 <= var_7_2 then
			if iter_7_0 == 1 then
				var_7_13 = "images/icon/eco/jinbi.png"
				var_7_14 = var_7_0.mana
			elseif iter_7_0 == 2 then
				var_7_13 = "images/icon/eco/march_coin.png"
				var_7_14 = var_7_0.march_coin
			end

			local var_7_16 = xyd.AssetLoader.get():loadSprite(var_7_13)

			xyd.displaySpriteOnContainer(var_7_16, var_7_15)
		else
			local var_7_17 = var_7_0["item_" .. iter_7_0 - var_7_2]
			local var_7_18 = xyd.tables.item:name(var_7_17)
			local var_7_19 = var_7_0["count_" .. iter_7_0 - var_7_2]
			local var_7_20 = var_7_0["type_" .. iter_7_0 - var_7_2]

			if var_7_17 > 0 and var_7_19 > 0 then
				local var_7_21 = "images/icon/" .. var_7_17 .. "_icon.png"

				var_7_14 = var_7_18 .. " x " .. var_7_19

				if var_7_20 == var_0_1 then
					var_7_17 = xyd.tables.hero:stoneID(var_7_17)
				end

				xyd.setItemBorder(var_7_15, var_7_17)
			else
				print("error in get march reward " .. iter_7_0)
			end
		end

		local var_7_22 = {
			size = 22,
			x = 210,
			text = var_7_14,
			color = cc.c3b(255, 255, 255),
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			y = 25 + (var_7_1 - iter_7_0) * var_7_3
		}
		local var_7_23 = xyd.AssetLoader.get():loadLabel(var_7_22)

		var_7_23:addTo(var_7_5)
		var_7_23:setAnchorPoint(0, 0)

		iter_7_0 = iter_7_0 + 1
	end
end

return var_0_0
