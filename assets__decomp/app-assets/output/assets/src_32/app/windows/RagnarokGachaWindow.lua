local var_0_0 = class("RagnarokGachaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.ragnarokGachaTable
local var_0_6 = 10001258
local var_0_7 = var_0_4:getValue("activity_ragnarok_gacha_coin")
local var_0_8 = {
	display = var_0_3:translation("RAGNAROK_GACHA_1"),
	one = var_0_3:translation("RAGNAROK_GACHA_2"),
	ten = var_0_3:translation("RAGNAROK_GACHA_3"),
	gacha = var_0_3:translation("RAGNAROK_GACHA_6")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2 or {})

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	local var_2_0 = {
		ecoCount = 1,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			var_0_7
		},
		ecoIcons = {
			"windows/activities/1203/icon_coin.png"
		}
	}

	arg_2_0:addTopSidebar(var_2_0)

	arg_2_0.ecoSidebar = arg_2_0:nodeByName("top_sidebar"):nodeByName("eco_sidebar")

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super.didClose(arg_4_0, arg_4_1)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_award"):setString(var_0_8.display)
	arg_5_0:nodeByName("txt_1"):setString(var_0_8.one)
	arg_5_0:nodeByName("txt_10"):setString(var_0_8.ten)

	arg_5_0.gachaFlag = false

	arg_5_0:initBalloonEffect()

	local var_5_0 = arg_5_0:nodeByName("hero"):getContentSize()
	local var_5_1 = var_0_1.new()

	var_5_1:initUnCollected(var_0_6)

	if var_5_1 then
		arg_5_0.model = var_5_1:getHeroModel()

		arg_5_0.model:addTo(arg_5_0:nodeByName("hero"))
		arg_5_0.model:setScale(1.1)
		arg_5_0.model:setPosition(cc.p(var_5_0.width, 0))
	end

	for iter_5_0 = 1, 4 do
		local var_5_2 = var_0_5:getItemIdById(iter_5_0)
		local var_5_3 = var_0_5:getItemNumById(iter_5_0)

		if var_5_2 == 0 then
			break
		end

		local var_5_4 = display.newNode()

		var_5_4:setContentSize(85, 85)
		var_5_4:setAnchorPoint(cc.p(0, 0))
		var_5_4:addTo(arg_5_0:nodeByName("award_list"))
		var_5_4:setPosition(cc.p((iter_5_0 - 1) * 110, 0))
		xyd.setItemAndAddTips(var_5_4, var_5_2, var_5_3)
	end

	arg_5_0:initBtn()
end

function var_0_0.initBalloonEffect(arg_6_0)
	arg_6_0.balloon = {
		arg_6_0:nodeByName("bg_loki"),
		arg_6_0:nodeByName("bg_rabbit"),
		arg_6_0:nodeByName("bg_bear"),
		arg_6_0:nodeByName("bg_dog"),
		arg_6_0:nodeByName("bg_cat")
	}

	for iter_6_0 = 1, #arg_6_0.balloon do
		local var_6_0 = cc.Sequence:create({
			cc.MoveBy:create(1.2, cc.p(0, 7)),
			cc.MoveBy:create(1.2, cc.p(0, -14)),
			cc.MoveBy:create(1.2, cc.p(0, 7)),
			cc.CallFunc:create(function()
				return
			end)
		})

		arg_6_0.balloon[iter_6_0]:runAction(cc.RepeatForever:create(var_6_0))
	end
end

function var_0_0.initBtn(arg_8_0)
	arg_8_0:nodeByName("btn_shop"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			arg_8_0.ragnarok:enterGachaShop()
		end
	end)

	local var_8_0 = arg_8_0:nodeByName("btn_details")

	var_8_0:addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			var_8_0:setScale(0.9)
		elseif arg_10_1 == ccui.TouchEventType.ended then
			var_8_0:setScale(1)
			xyd.WindowManager.get():openWindow("activity_ragnarok_gacha_display")
		end
	end)

	local var_8_1 = arg_8_0:nodeByName("btn_1")

	var_8_1:addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.began then
			var_8_1:setScale(0.9)
		elseif arg_11_1 == ccui.TouchEventType.ended then
			var_8_1:setScale(1)

			if arg_8_0.gachaFlag then
				return
			end

			if arg_8_0.selfPlayer:getBackpack():getItemNumByID(var_0_7) < 1 then
				local var_11_0 = var_0_4:getValue("activity_ragnarok_gacha_cost")
				local var_11_1 = string.format(var_0_8.gacha, var_11_0)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_1, function()
					local var_12_0 = {}

					var_12_0.times = 1

					xyd.Backend.get():request(xyd.mid.RAGNAROK_GACHA, var_12_0, function(arg_13_0, arg_13_1)
						if arg_13_0 == xyd.error.OK then
							arg_8_0:gachaEffect(arg_13_1.awards)
						end
					end)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			else
				local var_11_2 = {}

				var_11_2.times = 1

				xyd.Backend.get():request(xyd.mid.RAGNAROK_GACHA, var_11_2, function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						arg_8_0.selfPlayer:getBackpack():addItemsByID(var_0_7, -1)
						arg_8_0:gachaEffect(arg_14_1.awards)
					end
				end)
			end
		end
	end)

	local var_8_2 = arg_8_0:nodeByName("btn_10")

	var_8_2:addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.began then
			var_8_2:setScale(0.9)
		elseif arg_15_1 == ccui.TouchEventType.ended then
			var_8_2:setScale(1)

			if arg_8_0.gachaFlag then
				return
			end

			local var_15_0 = arg_8_0.selfPlayer:getBackpack():getItemNumByID(var_0_7)

			if var_15_0 < 10 then
				local var_15_1 = var_0_4:getValue("activity_ragnarok_gacha_cost")
				local var_15_2 = string.format(var_0_8.gacha, (10 - var_15_0) * var_15_1)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_15_2, function()
					local var_16_0 = {}

					var_16_0.times = 10

					xyd.Backend.get():request(xyd.mid.RAGNAROK_GACHA, var_16_0, function(arg_17_0, arg_17_1)
						if arg_17_0 == xyd.error.OK then
							arg_8_0.selfPlayer:getBackpack():addItemsByID(var_0_7, -var_15_0)
							arg_8_0:gachaEffect(arg_17_1.awards)
						end
					end)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			else
				local var_15_3 = {}

				var_15_3.times = 10

				xyd.Backend.get():request(xyd.mid.RAGNAROK_GACHA, var_15_3, function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK then
						arg_8_0.selfPlayer:getBackpack():addItemsByID(var_0_7, -10)
						arg_8_0:gachaEffect(arg_18_1.awards)
					end
				end)
			end
		end
	end)
end

function var_0_0.gachaEffect(arg_19_0, arg_19_1)
	arg_19_0:updateEco()

	arg_19_0.gachaFlag = true

	local var_19_0 = 5

	for iter_19_0 = 1, #arg_19_1 do
		local var_19_1 = var_0_5:getIdByInfo(arg_19_1[iter_19_0].table_id, arg_19_1[iter_19_0].item_num)
		local var_19_2 = var_0_5:balloonType(var_19_1)

		if var_19_2 < var_19_0 then
			var_19_0 = var_19_2
		end
	end

	local var_19_3, var_19_4 = arg_19_0.balloon[var_19_0]:getPosition()

	if arg_19_0.model then
		arg_19_0.model:attack(5, nil, nil, function()
			local var_20_0 = "skeletons/aoding/aodingdandao05"
			local var_20_1 = var_20_0 .. ".json"
			local var_20_2 = var_20_0 .. ".atlas"
			local var_20_3 = var_0_2.new(var_20_1, var_20_2, 1)

			var_20_3:addTo(arg_19_0:nodeByName("container"))
			var_20_3:setPosition(cc.p(var_19_3 - 100, var_19_4 + 200))
			var_20_3:setRotation(60)
			var_20_3:play(nil, true)

			local var_20_4 = cc.Sequence:create({
				cc.Spawn:create({
					cc.MoveBy:create(0.4, cc.p(100, -180)),
					cc.ScaleTo:create(0.4, 0.2)
				}),
				cc.CallFunc:create(function()
					var_20_3:hide()
					arg_19_0.model:idle()
					arg_19_0.balloon[var_19_0]:setVisible(false)
					arg_19_0.selfPlayer:handleRewards(arg_19_1, function()
						arg_19_0.balloon[var_19_0]:setVisible(true)

						arg_19_0.gachaFlag = false
					end)
				end)
			})

			var_20_3:runAction(var_20_4)
		end)
	end
end

function var_0_0.updateEco(arg_23_0)
	local var_23_0 = {
		true
	}

	arg_23_0.ecoSidebar:update(var_23_0)
end

return var_0_0
