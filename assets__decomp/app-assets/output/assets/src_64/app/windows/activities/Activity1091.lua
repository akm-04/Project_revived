local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = 5

function var_0_0.layout(arg_1_0)
	arg_1_0.container:getChildByName("num"):setString(arg_1_0.selfPlayer.signTimes)

	local var_1_0 = "windows/activities/1091/month/" .. arg_1_0.selfPlayer.signMonth .. ".png"

	arg_1_0.container:getChildByName("month"):setTexture(var_1_0)
end

function var_0_0.ctor(arg_2_0, arg_2_1)
	var_0_0.super.ctor(arg_2_0, arg_2_1)

	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_3_0, arg_3_1)
	var_0_0.super.show(arg_3_0, arg_3_1)

	if not arg_3_0.res or arg_3_0.res == 0 then
		print("No res available.")

		return
	end

	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_3_0.res)

	if var_3_0 then
		arg_3_0.container = var_3_0:getChildByName("container")

		var_3_0:addTo(arg_3_0.parent)
	end

	local var_3_1 = arg_3_0.container:getChildByName("award_list")
	local var_3_2 = var_3_1:getContentSize().width
	local var_3_3 = var_3_1:getContentSize().height

	arg_3_0.awardList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_2, var_3_3),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_1):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.awardList_:setDelegate(handler(arg_3_0, arg_3_0.awardDelegate))
	arg_3_0.selfPlayer:loadSignInfo(function()
		arg_3_0:layout()
		arg_3_0.awardList_:reload()
	end)
end

function var_0_0.awardDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return (math.ceil(#arg_5_0.selfPlayer.signAwards / var_0_3))
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0 = arg_5_0.awardList_:dequeueItem()

		if not var_5_0 then
			var_5_0 = arg_5_0.awardList_:newItem()
		else
			var_5_0:removeAllChildren(true)
		end

		local var_5_1 = 700
		local var_5_2 = 160

		var_5_0:setItemSize(var_5_1, 160)

		local var_5_3 = display.newNode()

		var_5_3:setContentSize(var_5_1, 160)

		for iter_5_0 = 1, var_0_3 do
			local var_5_4 = (arg_5_3 - 1) * var_0_3 + iter_5_0

			if var_5_4 > #arg_5_0.selfPlayer.signAwards then
				break
			end

			local var_5_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1091/item.csb")
			local var_5_6 = var_5_5:getChildByName("container")

			var_5_5:setPosition(140 * (iter_5_0 - 1), 0)
			var_5_3:addChild(var_5_5)
			var_5_5:setTouchEnabled(true)
			var_5_5:setTouchSwallowEnabled(false)

			local var_5_7 = arg_5_0.selfPlayer.signAwards[var_5_4]

			var_5_7.dayIdx = var_5_4

			local var_5_8 = string.format(var_0_1:translation("NDAYS"), var_5_4)

			var_5_6:getChildByName("week_day"):setString(var_5_8)

			if var_5_7.double_vip_lv < 0 then
				var_5_6:getChildByName("vip_double"):setVisible(false)
			else
				var_5_6:getChildByName("vip_double"):setVisible(true)
				var_5_6:getChildByName("vip_double"):getChildByName("txt_vip"):setString("V" .. var_5_7.double_vip_lv)
			end

			local var_5_9 = var_5_6:getChildByName("item"):getContentSize()

			if var_5_7.award_item_id > 0 then
				local var_5_10 = xyd.tables.item:icon(var_5_7.award_item_id)

				xyd.SpriteLoader.new(var_5_10, nil, nil, xyd.DefaultImageType.ITEM_ICON):addTo(var_5_6:getChildByName("item")):pos(var_5_9.width / 2, var_5_9.height / 2)
				var_5_6:getChildByName("num"):setString("x" .. var_5_7.award_item_num)
			elseif var_5_7.award_crystal and var_5_7.award_crystal > 0 then
				local var_5_11 = "windows/activities/1091/crystal.png"

				xyd.AssetLoader.get():loadSprite(var_5_11):addTo(var_5_6:getChildByName("item")):pos(var_5_9.width / 2, var_5_9.height / 2)
				var_5_6:getChildByName("num"):setString("x" .. var_5_7.award_crystal)
			end

			var_5_5.item = var_5_7

			if var_5_4 < arg_5_0.selfPlayer.signTimes then
				var_5_6:getChildByName("block"):setVisible(true)
			elseif arg_5_0.selfPlayer.signTimes == var_5_4 then
				if arg_5_0.selfPlayer.isSigned == 1 then
					var_5_6:getChildByName("block"):setVisible(false)
				else
					var_5_6:getChildByName("block"):setVisible(true)
				end
			elseif var_5_4 == arg_5_0.selfPlayer.signTimes + 1 and arg_5_0.selfPlayer.isSigned == 0 then
				var_5_6:getChildByName("block"):setVisible(false)
			else
				var_5_6:getChildByName("block"):setVisible(false)

				local var_5_12 = xyd.tables.item:type(var_5_7.award_item_id)
				local var_5_13 = var_5_6:getChildByName("item"):getContentSize()

				if var_5_12 == -1 then
					local var_5_14 = xyd.getItemEffect(5, 0.5)

					if var_5_14 then
						var_5_6:getChildByName("item"):addChild(var_5_14)
						var_5_14:setLocalZOrder(-100)
						var_5_14:setPosition(var_5_13.width / 2, var_5_13.height / 2)
						var_5_14:play(nil, true)
					end
				end
			end

			var_5_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
				if arg_6_0.name == "began" then
					var_5_6:setScale(0.9)

					return true
				elseif arg_6_0.name == "ended" then
					var_5_6:setScale(1)

					local var_6_0 = {}

					if var_5_4 == arg_5_0.selfPlayer.signTimes + 1 and arg_5_0.selfPlayer.isSigned == 0 then
						xyd.Backend.get():request(xyd.mid.SIGN, var_6_0, function(arg_7_0, arg_7_1)
							if arg_7_0 == xyd.error.OK then
								arg_5_0:showSignInRes(arg_7_1)
							end
						end)
					elseif var_5_4 == arg_5_0.selfPlayer.signTimes and arg_5_0.selfPlayer.isSigned == 1 then
						if arg_5_0.selfPlayer.vip >= var_5_5.item.double_vip_lv then
							xyd.Backend.get():request(xyd.mid.SIGN, var_6_0, function(arg_8_0, arg_8_1)
								if arg_8_0 == xyd.error.OK then
									arg_5_0:showSignInRes(arg_8_1)
								end
							end)
						else
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
								var_0_1:translation("SIGN_IN_GOT"),
								string.format(var_0_1:translation("SIGN_IN_VIP"), var_5_5.item.double_vip_lv)
							}, function()
								xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
									windowState = true
								})
							end, nil, nil, xyd.ColorMode.ACTIVITY)
						end
					elseif not arg_5_0.scrollViewMoved_ then
						local var_6_1 = {
							id = var_5_7.award_item_id
						}

						if not xyd.WindowManager.get():getWindow("new_item_tips") then
							local var_6_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_6_1)

							xyd.adaptToWorldPosition(var_5_6, var_6_2)
							var_6_2:addBlockLayerClickClose(cc.c4b(0, 0, 0, 0), nil, nil, 2)
						end
					end
				end
			end)
		end

		var_5_0:addContent(var_5_3)

		return var_5_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_5_2 then
		-- block empty
	end
end

function var_0_0.showSignInRes(arg_10_0, arg_10_1)
	arg_10_0.selfPlayer:setSignIn(arg_10_1.is_signed)

	arg_10_0.selfPlayer.signTimes = arg_10_1.sign_times

	arg_10_0:layout()
	arg_10_0.awardList_:reload()

	local var_10_0 = arg_10_1.award

	if var_10_0.is_partner == true then
		local var_10_1 = var_0_2.new()

		var_10_1:populate(var_10_0)
		arg_10_0.selfPlayer:addHero(var_10_1)

		local var_10_2 = {
			toStone = false,
			partnerID = var_10_0.table_id
		}
		local var_10_3 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_10_2)
	else
		if var_10_0.table_id > 0 then
			arg_10_0.selfPlayer:getBackpack():addItemsByID(tonumber(var_10_0.table_id), tonumber(var_10_0.item_num))

			if var_10_0.to_stone == true then
				local var_10_4 = {
					partnerID = xyd.tables.item:heroID(var_10_0.table_id),
					toStone = tonumber(var_10_0.item_num)
				}
				local var_10_5 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_10_4)

				cc.EventProxy.new(var_10_5, var_10_5):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
					xyd.WindowManager.get():openWindow("alert_award", {
						awards = {
							var_10_0
						}
					})
				end)
			end
		end

		if var_10_0.to_stone == false or var_10_0.table_id < 0 then
			xyd.WindowManager.get():openWindow("alert_award", {
				awards = {
					var_10_0
				}
			})
		end
	end
end

return var_0_0
