local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = import("app.windows.CountShopAlertWindow")
local var_0_5 = xyd.tables.discountShopNormal
local var_0_6 = xyd.tables.discountShopLocked
local var_0_7 = xyd.tables.discountShopMission
local var_0_8 = xyd.tables.misc:getValue("activity_sp_shop_refresh_time")
local var_0_9 = xyd.tables.misc:getValue("activity_sp_shop_item_id")
local var_0_10 = {
	txt_task = var_0_1:translation("ACTIVITY_SP_SHOP_MISSION"),
	txt_refresh = var_0_1:translation("SHOP_TIPS_REFRESH"),
	txt_next = var_0_1:translation("SHOP_AUTO_REFRESH_TEXT"),
	txt_free = var_0_1:translation("SUMMON_PRICE_FREE"),
	txt_count = var_0_1:translation("SHOP_TIPS_DISCOUNT"),
	txt_original = var_0_1:translation("ORIGINAL_PRICE"),
	txt_tips = var_0_1:translation("TIP")
}
local var_0_11 = "windows/activities/1180/sp_shop_texiao01"
local var_0_12 = "windows/activities/1180/sp_shop_texiao02"

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activityModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.taskProgress = arg_1_0.details.buy_count
	arg_1_0.taskInfo = arg_1_0.details.mission_infos
	arg_1_0.refreshTimes = arg_1_0.details.refresh_times
	arg_1_0.itemInfos = arg_1_0.details.item_info
	arg_1_0.flag = {}

	arg_1_0:initFlag()
end

function var_0_0.updateData(arg_2_0)
	return
end

function var_0_0.show(arg_3_0, arg_3_1)
	var_0_0.super.show(arg_3_0, arg_3_1)

	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_3_0.res)

	var_3_0:addTo(arg_3_0.parent)

	arg_3_0.container = var_3_0:getChildByName("container")

	arg_3_0:layout(arg_3_0.activity, arg_3_0.idx)
end

function var_0_0.layout(arg_4_0, arg_4_1, arg_4_2)
	if not arg_4_0.res or arg_4_0.res == 0 then
		print("No res available.")

		return
	end

	local var_4_0 = xyd.ServerTime.get():getServerTime()

	arg_4_0.item = {}
	arg_4_0.list = arg_4_0.container:getChildByName("list")

	local var_4_1 = arg_4_0.container:getChildByName("btn_rule")
	local var_4_2 = arg_4_0.container:getChildByName("btn_refresh")
	local var_4_3 = arg_4_0.container:getChildByName("btn_task")

	var_4_3:getChildByName("txt_task"):setString(var_0_10.txt_task)
	arg_4_0:createRefreshTime()
	var_4_3:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			var_4_3:setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			var_4_3:setScale(1)
			xyd.playButtonSound()
			var_4_3:getChildByName("red_mark"):setVisible(false)

			local var_5_0 = {
				progress = arg_4_0.taskProgress,
				task = arg_4_0.taskInfo,
				callback = function()
					arg_4_0.activityModel:loadSingleActivity({
						activity_id = xyd.Activities.SPShop
					}, function(arg_7_0, arg_7_1)
						if arg_7_0 == xyd.error.OK then
							arg_4_0.activity = arg_7_1
							arg_4_0.details = arg_4_0.activity.details
							arg_4_0.taskProgress = arg_4_0.details.buy_count
							arg_4_0.taskInfo = arg_4_0.details.mission_infos
							arg_4_0.refreshTimes = arg_4_0.details.refresh_times
							arg_4_0.itemInfos = arg_4_0.details.item_info
							arg_4_0.flag = {}

							arg_4_0:initFlag()
							arg_4_0.list:removeAllChildren()
							arg_4_0:initList()

							for iter_7_0 = 1, #arg_4_0.itemInfos do
								arg_4_0:updateList(iter_7_0)
							end
						end
					end)
				end
			}

			xyd.WindowManager.get():openWindow("count_shop_task", var_5_0)
		end
	end)
	var_4_1:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			var_4_1:setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			var_4_1:setScale(1)
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("new_text_rule", {
				title_name = "ACTIVITY_SP_SHOP_RULE_TITLE",
				rule = "ACTIVITY_SP_SHOP_RULE"
			})
		end
	end)
	arg_4_0:initList()

	for iter_4_0 = 1, #arg_4_0.itemInfos do
		arg_4_0:updateList(iter_4_0)
	end

	var_4_2:getChildByName("txt_refresh"):setString(var_0_10.txt_refresh)
	var_4_2:addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			var_4_2:setScale(0.9)
		elseif arg_9_1 == ccui.TouchEventType.ended then
			var_4_2:setScale(1)

			local var_9_0 = {
				title = var_0_10.txt_tips,
				align = xyd.ui_align.CENTER
			}

			if var_4_0 < arg_4_0.activity.start_time then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
					var_0_1:translation("ACTIVITY_NOT_OPEN")
				}, nil, var_9_0, nil, xyd.ColorMode.ACTIVITY)

				return
			end

			local var_9_1 = xyd.tables.refreshCost:spShopCost(arg_4_0.refreshTimes + 1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				string.format(var_0_1:translation("SHOP_REFRESH"), var_9_1),
				string.format(var_0_1:translation("SHOP_REFRESH_CONTINUE"), arg_4_0.refreshTimes)
			}, function()
				if arg_4_0.player.crystal < var_9_1 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						var_0_1:translation("ZUANSHI_ABSENCE")
					}, function()
						local var_11_0 = {}

						var_11_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
					end, var_9_0, nil, xyd.ColorMode.ACTIVITY)
				elseif arg_4_0 and not tolua.isnull(arg_4_0.container) then
					arg_4_0.list:removeAllChildren()

					arg_4_0.itemInfos = {}
					arg_4_0.flag = {}

					xyd.Backend.get():request(xyd.mid.DISCOUNT_SHOP_REFRESH, {}, function(arg_12_0, arg_12_1)
						if arg_12_0 == xyd.error.OK then
							arg_4_0.refreshTimes = arg_12_1.refresh_times
							arg_4_0.itemInfos = {}
							arg_4_0.itemInfos = arg_12_1.item_info
							arg_4_0.taskProgress = arg_12_1.buy_count
							arg_4_0.flag = {}

							arg_4_0:initFlag()
							arg_4_0.list:removeAllChildren()
							arg_4_0:initList()

							for iter_12_0 = 1, #arg_4_0.itemInfos do
								arg_4_0:updateList(iter_12_0)
							end
						end
					end)
				end
			end, var_9_0, nil, xyd.ColorMode.ACTIVITY)
		end
	end)
end

function var_0_0.initFlag(arg_13_0)
	for iter_13_0 = 1, #arg_13_0.itemInfos do
		if iter_13_0 <= 5 then
			arg_13_0.flag[iter_13_0] = arg_13_0.itemInfos[iter_13_0].is_buy
			arg_13_0.flag[iter_13_0 + 5] = arg_13_0.itemInfos[iter_13_0].is_buy + 2
		elseif iter_13_0 > 5 then
			arg_13_0.flag[iter_13_0] = arg_13_0.flag[iter_13_0] + arg_13_0.itemInfos[iter_13_0].is_buy
		end
	end
end

function var_0_0.initList(arg_14_0)
	local var_14_0 = arg_14_0.container:getChildByName("btn_task")

	var_14_0:getChildByName("red_mark"):setVisible(false)

	for iter_14_0 = 1, #arg_14_0.details.mission_infos do
		if var_0_7:taskNum(var_0_7:ids()[iter_14_0]) <= arg_14_0.taskProgress and arg_14_0.details.mission_infos[iter_14_0].is_award == 0 then
			var_14_0:getChildByName("red_mark"):setVisible(true)

			break
		end
	end

	for iter_14_1 = 1, #arg_14_0.itemInfos do
		arg_14_0.item[iter_14_1] = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1180/count_shop_item.csb")

		arg_14_0.item[iter_14_1]:addTo(arg_14_0.list)

		local var_14_1 = iter_14_1 - 1

		arg_14_0.item[iter_14_1]:setPosition(190 * (var_14_1 % 5) + 5, (1 - math.floor(var_14_1 / 5)) * 230)
	end
end

function var_0_0.updateList(arg_15_0, arg_15_1)
	if arg_15_0.flag[arg_15_1] == 0 then
		arg_15_0:initYellowCard(arg_15_1)
	elseif arg_15_0.flag[arg_15_1] == 1 then
		arg_15_0:initYellowCard(arg_15_1)
		arg_15_0:addCover(arg_15_1)
	elseif arg_15_0.flag[arg_15_1] == 2 then
		arg_15_0:hideBlueCard(arg_15_1)
	elseif arg_15_0.flag[arg_15_1] == 3 then
		arg_15_0:initBlueCard(arg_15_1)
	elseif arg_15_0.flag[arg_15_1] == 4 then
		arg_15_0:initBlueCard(arg_15_1)
		arg_15_0:addCover(arg_15_1)
	end
end

function var_0_0.initYellowCard(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0.item[arg_16_1]:getChildByName("container")

	var_16_0:getChildByName("container_blue"):setVisible(false)
	var_16_0:getChildByName("contanier_blue_back"):setVisible(false)
	var_16_0:getChildByName("container_cover"):setVisible(false)
	var_16_0:getChildByName("container_yellow"):setVisible(true)

	local var_16_1 = var_16_0:getContentSize()
	local var_16_2 = arg_16_0.itemInfos[arg_16_1].item_id
	local var_16_3 = var_0_5:num(var_16_2)
	local var_16_4 = var_0_5:type(var_16_2)
	local var_16_5 = var_0_5:name(var_16_2)
	local var_16_6 = var_0_5:price(var_16_2)
	local var_16_7 = arg_16_0.itemInfos[arg_16_1].discount
	local var_16_8 = math.ceil(var_16_6 * var_16_7 / 10)
	local var_16_9 = var_16_0:getChildByName("container_yellow")

	var_16_9:getChildByName("bg_yellow"):setTouchEnabled(true)
	var_16_9:getChildByName("bg_yellow"):setTouchSwallowEnabled(false)
	var_16_9:getChildByName("bg_yellow"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
		if arg_17_0.name == "began" then
			var_16_0:getChildByName("container_yellow"):setScale(0.9)

			return true
		elseif arg_17_0.name == "ended" then
			var_16_0:getChildByName("container_yellow"):setScale(1)

			local var_17_0 = {
				title = var_0_10.txt_tips,
				align = xyd.ui_align.CENTER
			}

			if xyd.ServerTime.get():getServerTime() < arg_16_0.activity.start_time then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
					var_0_1:translation("ACTIVITY_NOT_OPEN")
				}, nil, var_17_0, nil, xyd.ColorMode.ACTIVITY)

				return
			end

			local var_17_1 = {
				id = arg_16_1,
				cost = var_16_8,
				item_id = var_16_2
			}

			var_0_4.open(string.format(var_0_1:translation("ACTIVITY_SUPER_RICH_BUY_ALERT"), var_16_8, var_16_3, var_16_5), function(arg_18_0)
				if arg_16_0.player.crystal < var_16_8 and not arg_18_0 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						var_0_1:translation("ZUANSHI_ABSENCE")
					}, function()
						local var_19_0 = {}

						var_19_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_19_0)
					end, var_17_0, nil, xyd.ColorMode.ACTIVITY)
				elseif arg_18_0 and arg_16_0.player:getBackpack():getItemNumByID(var_0_9) < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("ACTIVITY_SP_SHOP_ITEM_NOT_ENOUGH")
					})
				else
					if arg_18_0 then
						var_17_1.use_item = 1
					else
						var_17_1.use_item = 0
					end

					xyd.Backend.get():request(xyd.mid.DISCOUNT_SHOP_BUY, var_17_1, function(arg_20_0, arg_20_1)
						if arg_20_0 == xyd.error.OK then
							arg_16_0.player:handleRewards(arg_20_1.awards)
							arg_16_0.player:getBackpack():addItemsByID(var_0_9, -var_17_1.use_item)

							if arg_16_0 and not tolua.isnull(arg_16_0.container) then
								arg_16_0.itemInfos = {}
								arg_16_0.itemInfos = arg_20_1.item_info
								arg_16_0.taskProgress = arg_20_1.buy_count
								arg_16_0.flag = {}

								arg_16_0:initFlag()
								arg_16_0.list:removeAllChildren()
								arg_16_0:initList()

								for iter_20_0 = 1, #arg_16_0.itemInfos do
									if iter_20_0 == arg_16_1 then
										arg_16_0.item[arg_16_1 + 5]:setVisible(false)

										local var_20_0 = arg_16_0:createEffect(var_0_11)

										var_20_0:addTo(arg_16_0.list)
										var_20_0:setPosition(arg_16_0.item[arg_16_1 + 5]:getPositionX() + var_16_1.width / 2, arg_16_0.item[arg_16_1 + 5]:getPositionY() + var_16_1.height / 2 + 22)
										var_20_0:play(function()
											var_20_0:setVisible(false)
											arg_16_0.item[arg_16_1 + 5]:setVisible(true)

											local var_21_0 = arg_16_0:createEffect(var_0_12)

											var_21_0:addTo(arg_16_0.list)
											var_21_0:setPosition(arg_16_0.item[arg_16_1 + 5]:getPositionX() + var_16_1.width / 2, arg_16_0.item[arg_16_1 + 5]:getPositionY() + var_16_1.height / 2)
											var_21_0:play(function()
												var_21_0:setVisible(false)
											end, false)
										end, false)
									end

									arg_16_0:updateList(iter_20_0)
								end
							end
						end
					end)
				end
			end)
		end
	end)

	local var_16_10 = var_16_9:getChildByName("icon")

	xyd.setItemAndAddTips(var_16_10, var_16_2, var_16_3)
	var_16_9:getChildByName("txt_goods"):setString(var_0_10.txt_original)
	var_16_9:getChildByName("txt_goods")
	var_16_9:getChildByName("txt_yuanjia"):setString(var_16_6)
	var_16_9:getChildByName("txt_xianjia"):setString(var_16_8)

	local var_16_11, var_16_12 = var_16_9:getChildByName("icon_zuanshi"):getPosition()

	var_16_9:getChildByName("icon_zuanshi"):setVisible(false)

	local var_16_13

	if var_16_4 == 1 then
		var_16_13 = xyd.AssetLoader.get():loadSprite("windows/common/middle_crystal.png")
	elseif var_16_4 == 2 then
		var_16_13 = xyd.AssetLoader.get():loadSprite("windows/common/jinbi.png")
	else
		var_16_13 = xyd.AssetLoader.get():loadSprite("windows/common/middle_crystal.png")
	end

	var_16_13:addTo(var_16_9)
	var_16_13:setPosition(var_16_11, var_16_12)
	var_16_13:setAnchorPoint(cc.p(0.5, 0.5))
	var_16_13:setScale(0.5)

	if var_16_7 == 0 then
		var_16_9:getChildByName("bg_count"):getChildByName("pos_count"):setVisible(false)
		var_16_9:getChildByName("bg_count"):getChildByName("word_zhe"):setVisible(false)
		var_16_9:getChildByName("bg_count"):getChildByName("word_free"):setVisible(true)
	else
		local var_16_14 = xyd.AssetLoader.get():loadSprite("windows/activities/1180/word_" .. var_16_7 .. ".png")

		var_16_14:setAnchorPoint(cc.p(0.5, 0.5))
		var_16_14:addTo(var_16_9:getChildByName("bg_count"):getChildByName("pos_count"))
		var_16_9:getChildByName("bg_count"):getChildByName("word_zhe"):setVisible(true)
		var_16_9:getChildByName("bg_count"):getChildByName("word_free"):setVisible(false)
	end
end

function var_0_0.createEffect(arg_23_0, arg_23_1)
	local var_23_0 = arg_23_1 .. ".json"
	local var_23_1 = arg_23_1 .. ".atlas"
	local var_23_2 = var_0_3.new(var_23_0, var_23_1, 1.1)

	var_23_2:setAnchorPoint(cc.p(0.5, 0.5))

	return var_23_2
end

function var_0_0.hideBlueCard(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_0.item[arg_24_1]:getChildByName("container")

	var_24_0:getChildByName("container_yellow"):setVisible(false)
	var_24_0:getChildByName("container_blue"):setVisible(false)
	var_24_0:getChildByName("container_cover"):setVisible(false)
	var_24_0:getChildByName("contanier_blue_back"):setVisible(true)
	var_24_0:getChildByName("container_blue"):getChildByName("bg_blue"):setTouchEnabled(false)
end

function var_0_0.initBlueCard(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0.item[arg_25_1]:getChildByName("container")

	var_25_0:getChildByName("container_yellow"):setVisible(false)
	var_25_0:getChildByName("contanier_blue_back"):setVisible(false)
	var_25_0:getChildByName("container_cover"):setVisible(false)
	var_25_0:getChildByName("container_blue"):setVisible(true)

	local var_25_1 = arg_25_0.itemInfos[arg_25_1].item_id
	local var_25_2 = var_0_6:num(var_25_1)
	local var_25_3 = var_0_6:type(var_25_1)
	local var_25_4 = var_0_6:name(var_25_1)
	local var_25_5 = var_0_6:price(var_25_1)
	local var_25_6 = arg_25_0.itemInfos[arg_25_1].discount
	local var_25_7 = math.ceil(var_25_5 * var_25_6 / 10)
	local var_25_8 = var_25_0:getChildByName("container_blue")

	var_25_8:getChildByName("bg_blue"):setTouchEnabled(true)
	var_25_8:getChildByName("bg_blue"):setTouchSwallowEnabled(false)
	var_25_8:getChildByName("bg_blue"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
		if arg_26_0.name == "began" then
			var_25_0:getChildByName("container_blue"):setScale(0.9)

			return true
		elseif arg_26_0.name == "ended" then
			var_25_0:getChildByName("container_blue"):setScale(1)

			local var_26_0 = {
				title = var_0_10.txt_tips,
				align = xyd.ui_align.CENTER
			}
			local var_26_1 = {
				id = arg_25_1,
				cost = var_25_7,
				item_id = var_25_1
			}

			var_0_4.open(string.format(var_0_1:translation("ACTIVITY_SUPER_RICH_BUY_ALERT"), var_25_7, var_25_2, var_25_4), function(arg_27_0)
				if arg_25_0.player.crystal < var_25_7 and not arg_27_0 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						var_0_1:translation("ZUANSHI_ABSENCE")
					}, function()
						local var_28_0 = {}

						var_28_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_28_0)
					end, var_26_0, nil, xyd.ColorMode.ACTIVITY)
				elseif arg_27_0 and arg_25_0.player:getBackpack():getItemNumByID(var_0_9) < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("ACTIVITY_SP_SHOP_ITEM_NOT_ENOUGH")
					})
				else
					if arg_27_0 then
						var_26_1.use_item = 1
					else
						var_26_1.use_item = 0
					end

					xyd.Backend.get():request(xyd.mid.DISCOUNT_SHOP_BUY, var_26_1, function(arg_29_0, arg_29_1)
						if arg_29_0 == xyd.error.OK then
							arg_25_0.player:handleRewards(arg_29_1.awards)
							arg_25_0.player:getBackpack():addItemsByID(var_0_9, -var_26_1.use_item)

							if arg_25_0 and not tolua.isnull(arg_25_0.container) then
								arg_25_0.itemInfos = {}
								arg_25_0.itemInfos = arg_29_1.item_info
								arg_25_0.taskProgress = arg_29_1.buy_count
								arg_25_0.flag = {}

								arg_25_0:initFlag()
								arg_25_0.list:removeAllChildren()
								arg_25_0:initList()

								for iter_29_0 = 1, #arg_25_0.itemInfos do
									arg_25_0:updateList(iter_29_0)
								end
							end
						end
					end)
				end
			end)
		end
	end)

	local var_25_9 = var_25_8:getChildByName("icon")

	xyd.setItemAndAddTips(var_25_9, var_25_1, var_25_2)
	var_25_8:getChildByName("txt_goods"):setString(var_0_10.txt_original)
	var_25_8:getChildByName("txt_goods")
	var_25_8:getChildByName("txt_yuanjia"):setString(var_25_5)
	var_25_8:getChildByName("txt_xianjia"):setString(var_25_7)

	local var_25_10, var_25_11 = var_25_8:getChildByName("icon_zuanshi"):getPosition()

	var_25_8:getChildByName("icon_zuanshi"):setVisible(false)

	local var_25_12

	if var_25_3 == 1 then
		var_25_12 = xyd.AssetLoader.get():loadSprite("windows/common/middle_crystal.png")
	elseif var_25_3 == 2 then
		var_25_12 = xyd.AssetLoader.get():loadSprite("windows/common/jinbi.png")
	else
		var_25_12 = xyd.AssetLoader.get():loadSprite("windows/common/middle_crystal.png")
	end

	var_25_12:addTo(var_25_8)
	var_25_12:setPosition(var_25_10, var_25_11)
	var_25_12:setAnchorPoint(cc.p(0.5, 0.5))
	var_25_12:setScale(0.5)

	if var_25_6 == 0 then
		var_25_8:getChildByName("bg_count"):getChildByName("pos_count"):setVisible(false)
		var_25_8:getChildByName("bg_count"):getChildByName("word_zhe"):setVisible(false)
		var_25_8:getChildByName("bg_count"):getChildByName("word_free"):setVisible(true)
	else
		local var_25_13 = xyd.AssetLoader.get():loadSprite("windows/activities/1180/word_" .. var_25_6 .. ".png")

		var_25_13:setAnchorPoint(cc.p(0.5, 0.5))
		var_25_13:addTo(var_25_8:getChildByName("bg_count"):getChildByName("pos_count"))
		var_25_8:getChildByName("bg_count"):getChildByName("word_zhe"):setVisible(true)
		var_25_8:getChildByName("bg_count"):getChildByName("word_free"):setVisible(false)
	end
end

function var_0_0.addCover(arg_30_0, arg_30_1)
	local var_30_0 = arg_30_0.item[arg_30_1]:getChildByName("container")

	var_30_0:getChildByName("container_cover"):setVisible(true)

	local var_30_1 = var_30_0:getChildByName("container_blue"):getChildByName("bg_blue")

	var_30_0:getChildByName("container_yellow"):getChildByName("bg_yellow"):setTouchEnabled(false)
	var_30_1:setTouchEnabled(false)
end

function var_0_0.createRefreshTime(arg_31_0)
	if arg_31_0.handle then
		var_0_2.unscheduleGlobal(arg_31_0.handle)

		arg_31_0.handle = nil
	end

	arg_31_0:checkActivityOnTime()

	local var_31_0 = xyd.ServerTime.get():getServerTime()
	local var_31_1 = math.ceil(var_31_0 / 86400) * 86400 - 28800 + var_0_8
	local var_31_2 = var_31_1 - var_31_0

	if var_31_2 <= 0 then
		var_31_2 = var_31_2 + 86400
	end

	arg_31_0:updateDownTime(var_31_2)

	arg_31_0.handle = var_0_2.scheduleGlobal(function()
		var_31_2 = var_31_2 - 1

		if var_31_2 <= 0 then
			var_31_0 = xyd.ServerTime.get():getServerTime()
			var_31_1 = math.ceil(var_31_0 / 86400) * 86400 - 28800 + var_0_8
			var_31_2 = var_31_1 - var_31_0

			if var_31_2 <= 0 then
				var_31_2 = var_31_2 + 86400
			end

			arg_31_0.activityModel:loadSingleActivity({
				activity_id = xyd.Activities.SPShop
			}, function(arg_33_0, arg_33_1)
				if arg_33_0 == xyd.error.OK then
					arg_31_0.activity = arg_33_1
					arg_31_0.details = arg_31_0.activity.details
					arg_31_0.refreshTimes = arg_31_0.details.refresh_times
					arg_31_0.itemInfos = arg_31_0.details.item_info
					arg_31_0.flag = {}

					arg_31_0:initFlag()
					arg_31_0.list:removeAllChildren()
					arg_31_0:initList()

					for iter_33_0 = 1, #arg_31_0.itemInfos do
						arg_31_0:updateList(iter_33_0)
					end

					arg_31_0:checkActivityOnTime()
				end
			end)
			arg_31_0:updateDownTime(var_31_2)
		else
			arg_31_0:updateDownTime(var_31_2)
		end
	end, 1)
end

function var_0_0.updateDownTime(arg_34_0, arg_34_1)
	local var_34_0 = arg_34_0.container:getChildByName("bg_time")

	if var_34_0 then
		var_34_0:getChildByName("txt_time"):setString(var_0_10.txt_next .. xyd.secondsToString(arg_34_1))
	end
end

function var_0_0.checkActivityOnTime(arg_35_0)
	local var_35_0 = xyd.ServerTime.get():getServerTime()

	if arg_35_0.activity.end_time - var_35_0 <= 0 or var_35_0 < arg_35_0.activity.start_time then
		if arg_35_0.handle then
			var_0_2.unscheduleGlobal(arg_35_0.handle)

			arg_35_0.handle = nil
		end

		return
	end
end

function var_0_0.release(arg_36_0)
	if arg_36_0.handle then
		var_0_2.unscheduleGlobal(arg_36_0.handle)
	end

	var_0_0.super:release()
end

return var_0_0
