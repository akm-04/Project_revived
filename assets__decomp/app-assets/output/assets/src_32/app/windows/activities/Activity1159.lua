local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.chargeList
local var_0_3 = xyd.tables.vip
local var_0_4 = xyd.tables.gift

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.baseInfo = arg_1_0.activity.details.base_info
	arg_1_0.vipInfo = arg_1_0.activity.details.max_vip_info
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	if arg_2_0.baseInfo.is_vip_award == 0 then
		arg_2_0.vipLev = xyd.getVipLev(arg_2_0.vipInfo.charge + arg_2_0.player.charge)
	else
		arg_2_0.vipLev = arg_2_0.baseInfo.bind_vip
	end

	arg_2_0.container = var_2_0:getChildByName("container")
	arg_2_0.ruleBtn = arg_2_0.container:getChildByName("rule_btn")
	arg_2_0.giftContainer = arg_2_0.container:getChildByName("gift_container")
	arg_2_0.buyBtn = arg_2_0.giftContainer:getChildByName("buy_btn")

	arg_2_0.container:getChildByName("server_and_name_txt"):setString("S" .. arg_2_0.vipInfo.player_info.region .. arg_2_0.vipInfo.player_info.player_name)
	arg_2_0.container:getChildByName("vip_exp"):setString(string.format(var_0_1:translation("RECALL_SERVER_TEXT_5"), arg_2_0.vipInfo.charge))
	arg_2_0.container:getChildByName("vip_lev"):setString(arg_2_0.vipLev)

	local var_2_1 = arg_2_0.giftContainer:getChildByName("container1")
	local var_2_2 = arg_2_0.giftContainer:getChildByName("container2")

	var_2_1:getChildByName("txt2"):setString(string.format(var_0_1:translation("RECALL_SERVER_TEXT_4"), arg_2_0.vipLev))
	var_2_2:getChildByName("txt"):setString(string.format(var_0_1:translation("RECALL_SERVER_VIP"), arg_2_0.vipLev))
	arg_2_0.buyBtn:getChildByName("buy_txt"):setString(var_0_2:charge(var_0_3:recallChargeGift(arg_2_0.vipLev)) .. "USD")
	arg_2_0.buyBtn:getChildByName("bind_txt"):setString(var_0_1:translation("RECALL_SERVER_TEXT_6"))
	arg_2_0.buyBtn:getChildByName("has_buy_txt"):setString(var_0_1:translation("RECALL_SERVER_TEXT_7"))
	arg_2_0.ruleBtn:addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.began then
			arg_2_0.ruleBtn:setScale(0.95)
			arg_2_0.ruleBtn:setBrightStyle(ccui.BrightStyle.highlight)
		elseif arg_3_1 == ccui.TouchEventType.ended then
			arg_2_0.ruleBtn:setScale(1)
			xyd.playButtonSound()
			arg_2_0.ruleBtn:setBrightStyle(ccui.BrightStyle.normal)
			xyd.WindowManager.get():openWindow("new_text_rule", {
				title_name = "RECALL_SERVER_RULE_TITLE",
				rule = "RECALL_SERVER_RULE_TEXT"
			})
		end
	end)
	arg_2_0.buyBtn:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_2_0.buyBtn:setScale(0.9)
			arg_2_0.buyBtn:setBrightStyle(ccui.BrightStyle.highlight)
		elseif arg_4_1 == ccui.TouchEventType.ended then
			arg_2_0.buyBtn:setScale(1)
			xyd.playButtonSound()
			arg_2_0.buyBtn:setBrightStyle(ccui.BrightStyle.normal)

			if arg_2_0.baseInfo.is_vip_award == 0 then
				arg_2_0.activitiesModel:getActivityReward(arg_2_0.activity.table_id, nil, function(arg_5_0, arg_5_1)
					if arg_5_0 == xyd.error.OK then
						arg_2_0.player:handleRewards(arg_5_1.awards)

						arg_2_0.baseInfo = arg_5_1.base_info

						arg_2_0:updateGiftContainer()
					end
				end)
			else
				local function var_4_0()
					local var_6_0 = true
					local var_6_1 = arg_2_0.player:getNewIDs()
					local var_6_2 = var_0_3:recallChargeGift(arg_2_0.vipLev)

					if device.platform == "android" then
						xyd.androidPurchase({
							var_6_2
						}, {}, var_6_2, false, var_0_2:charge(var_6_2), var_0_2:name(var_6_2))
					elseif device.platform == "ios" then
						local var_6_3 = var_0_2:iosProductId(var_6_2)

						xyd.sdkPurchase(var_6_3, var_6_0, var_6_2, {}, var_6_1, {
							var_6_2
						})
					end
				end

				if not arg_2_0.player.vipChargeData then
					arg_2_0.player:queryChargeData(function()
						var_4_0()
					end)
				else
					var_4_0()
				end
			end
		end
	end)
	arg_2_0:updateGiftContainer()
end

function var_0_0.updateGiftContainer(arg_8_0)
	local var_8_0 = {}
	local var_8_1 = {}

	if arg_8_0.baseInfo.is_vip_award == 0 then
		arg_8_0.giftContainer:getChildByName("container1"):setVisible(true)
		arg_8_0.giftContainer:getChildByName("container2"):setVisible(false)
		arg_8_0.buyBtn:getChildByName("bind_txt"):setVisible(true)
		arg_8_0.buyBtn:getChildByName("buy_txt"):setVisible(false)
		arg_8_0.buyBtn:getChildByName("has_buy_txt"):setVisible(false)
		arg_8_0.buyBtn:setTouchEnabled(true)
		arg_8_0.buyBtn:setBright(true)

		local var_8_2 = clone(var_0_4:items(var_0_3:recallGift(arg_8_0.vipLev)))
		local var_8_3 = clone(var_0_4:itemNum(var_0_3:recallGift(arg_8_0.vipLev)))
		local var_8_4 = var_0_4:crystal(var_0_3:recallGift(arg_8_0.vipLev))

		if var_8_4 and var_8_4 > 0 then
			table.insert(var_8_2, -1)
			table.insert(var_8_3, var_8_4)
		end

		arg_8_0.giftContainer:getChildByName("item_node"):removeAllChildren()

		for iter_8_0 = 1, #var_8_2 do
			local var_8_5 = display.newNode()

			var_8_5:setContentSize(86, 86)
			xyd.setItemAndAddTips(var_8_5, var_8_2[iter_8_0], var_8_3[iter_8_0])
			arg_8_0.giftContainer:getChildByName("item_node"):addChild(var_8_5)
			var_8_5:setAnchorPoint(cc.p(0, 0))
			var_8_5:setPosition((iter_8_0 - 1) * 102, 0)
		end
	else
		arg_8_0.giftContainer:getChildByName("container1"):setVisible(false)
		arg_8_0.giftContainer:getChildByName("container2"):setVisible(true)

		local var_8_6 = arg_8_0.giftContainer:getChildByName("container2")

		if arg_8_0.baseInfo.is_charge_award == 0 then
			arg_8_0.buyBtn:getChildByName("bind_txt"):setVisible(false)
			arg_8_0.buyBtn:getChildByName("buy_txt"):setVisible(true)
			arg_8_0.buyBtn:getChildByName("has_buy_txt"):setVisible(false)
			arg_8_0.buyBtn:setTouchEnabled(true)
			arg_8_0.buyBtn:setBright(true)
		else
			arg_8_0.buyBtn:getChildByName("bind_txt"):setVisible(false)
			arg_8_0.buyBtn:getChildByName("buy_txt"):setVisible(false)
			arg_8_0.buyBtn:getChildByName("has_buy_txt"):setVisible(true)
			arg_8_0.buyBtn:setTouchEnabled(false)
			arg_8_0.buyBtn:setBright(false)
		end

		local var_8_7 = clone(var_0_4:items(var_0_2:gift(var_0_3:recallChargeGift(arg_8_0.vipLev))))

		table.insert(var_8_7, -1)

		local var_8_8 = clone(var_0_4:itemNum(var_0_2:gift(var_0_3:recallChargeGift(arg_8_0.vipLev))))

		table.insert(var_8_8, var_0_2:diamond(var_0_3:recallChargeGift(arg_8_0.vipLev)))
		arg_8_0.giftContainer:getChildByName("item_node"):removeAllChildren()

		for iter_8_1 = 1, #var_8_7 do
			local var_8_9 = display.newNode()

			var_8_9:setContentSize(86, 86)
			xyd.setItemAndAddTips(var_8_9, var_8_7[iter_8_1], var_8_8[iter_8_1])
			arg_8_0.giftContainer:getChildByName("item_node"):addChild(var_8_9)
			var_8_9:setAnchorPoint(cc.p(0, 0))
			var_8_9:setPosition((iter_8_1 - 1) * 102, 0)
		end
	end
end

return var_0_0
