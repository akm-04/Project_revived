local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = "skeletons/ui_effect/activity_multiskin/activity_multiskin_sale"

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backPack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.container = var_2_0:getChildByName("container")

		var_2_0:addTo(arg_2_0.parent)
		var_2_0:setPosition(0, 0)

		arg_2_0.scroll = arg_2_0.container:getChildByName("scroll")

		local var_2_1 = arg_2_0.scroll:getContentSize()

		arg_2_0.awardedList = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
		}):addTo(arg_2_0.scroll):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

		arg_2_0.awardedList:setBounceable(false)
		arg_2_0.awardedList:setTouchType(false)
		arg_2_0.container:getChildByName("rule_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
			xyd.buttonScaleAnim(arg_2_0.container:getChildByName("rule_btn"), arg_3_1)

			if arg_3_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_3_0 = {}

				var_3_0.title_name = "MULTISKIN_RULE_TITLE"
				var_3_0.rule = "MULTISKIN_RULE_TEXT"

				xyd.WindowManager.get():openWindow("new_text_rule", var_3_0)
			end
		end)
		arg_2_0.container:getChildByName("normal_discount"):setTouchEnabled(true)
		arg_2_0.container:getChildByName("normal_discount"):setTouchSwallowEnabled(false)
		arg_2_0.container:getChildByName("normal_discount"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
			if arg_4_0.name == "began" then
				return true
			elseif arg_4_0.name == "ended" then
				xyd.playButtonSound()

				if arg_2_0.backPack:getItemNumByID(arg_2_0.discountIds[1]) <= 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = xyd.tables.translation:translation("MULTISKIN_NO_DISCOUNT_TIP")
					})

					return
				else
					if arg_2_0.discountId == arg_2_0.discountIds[1] then
						arg_2_0.discountId = nil
					else
						arg_2_0.discountId = arg_2_0.discountIds[1]
					end

					arg_2_0:update()
				end
			end
		end)
		arg_2_0.container:getChildByName("super_discount"):setTouchEnabled(true)
		arg_2_0.container:getChildByName("super_discount"):setTouchSwallowEnabled(false)
		arg_2_0.container:getChildByName("super_discount"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "began" then
				return true
			elseif arg_5_0.name == "ended" then
				xyd.playButtonSound()

				if arg_2_0.backPack:getItemNumByID(arg_2_0.discountIds[2]) <= 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = xyd.tables.translation:translation("MULTISKIN_NO_DISCOUNT_TIP")
					})

					return
				else
					if arg_2_0.discountId == arg_2_0.discountIds[2] then
						arg_2_0.discountId = nil
					else
						arg_2_0.discountId = arg_2_0.discountIds[2]
					end

					arg_2_0:update()
				end
			end
		end)
		arg_2_0.container:getChildByName("question_mark"):setTouchEnabled(true)
		arg_2_0.container:getChildByName("question_mark"):setTouchSwallowEnabled(false)
		arg_2_0.container:getChildByName("question_mark"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
			if arg_6_0.name == "began" then
				return true
			elseif arg_6_0.name == "ended" then
				xyd.playButtonSound()
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("MULTISKIN_GET_POINT_TIP"), function()
					local var_7_0 = {}

					var_7_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			end
		end)

		arg_2_0.awardedIdx = {}

		arg_2_0:update()
	end
end

function var_0_0.updateDiscount(arg_8_0)
	local var_8_0 = xyd.tables.activityMultiskinDiscount:ids()

	table.sort(var_8_0, function(arg_9_0, arg_9_1)
		return arg_9_0 < arg_9_1
	end)

	arg_8_0.discountIds = var_8_0

	if arg_8_0.backPack:getItemNumByID(var_8_0[1]) <= 0 then
		if arg_8_0.discountId == var_8_0[1] then
			arg_8_0.discountId = nil
		end

		xyd.GrayNode(arg_8_0.container:getChildByName("normal_discount"))
	else
		local var_8_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1139/normal_discount.png")

		arg_8_0.container:getChildByName("normal_discount"):setSpriteFrame(var_8_1:getSpriteFrame())
	end

	if arg_8_0.backPack:getItemNumByID(var_8_0[2]) <= 0 then
		if arg_8_0.discountId == var_8_0[2] then
			arg_8_0.discountId = nil
		end

		xyd.GrayNode(arg_8_0.container:getChildByName("super_discount"))
	else
		local var_8_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1139/super_discount.png")

		arg_8_0.container:getChildByName("super_discount"):setSpriteFrame(var_8_2:getSpriteFrame())
	end

	arg_8_0:updateDiscountEffect()
end

function var_0_0.updateDiscountEffect(arg_10_0)
	if arg_10_0.effect1 and not tolua.isnull(arg_10_0.effect1) then
		arg_10_0.effect1:removeFromParent()

		arg_10_0.effect1 = nil
	end

	if arg_10_0.discountId == arg_10_0.discountIds[1] then
		local var_10_0 = var_0_4 .. "01.json"
		local var_10_1 = var_0_4 .. "01.atlas"

		arg_10_0.effect1 = var_0_3.new(var_10_0, var_10_1, 1)

		arg_10_0.effect1:setAnchorPoint(cc.p(0.5, 0.5))
		arg_10_0.effect1:addTo(arg_10_0.container:getChildByName("normal_discount"))
		arg_10_0.effect1:setPosition(cc.p(arg_10_0.container:getChildByName("normal_discount"):getContentSize().width / 2, arg_10_0.container:getChildByName("normal_discount"):getContentSize().height / 2 - 7))
	elseif arg_10_0.discountId == arg_10_0.discountIds[2] then
		local var_10_2 = var_0_4 .. "02.json"
		local var_10_3 = var_0_4 .. "02.atlas"

		arg_10_0.effect1 = var_0_3.new(var_10_2, var_10_3, 1)

		arg_10_0.effect1:setAnchorPoint(cc.p(0.5, 0.5))
		arg_10_0.effect1:addTo(arg_10_0.container:getChildByName("super_discount"))
		arg_10_0.effect1:setPosition(cc.p(arg_10_0.container:getChildByName("super_discount"):getContentSize().width / 2 - 3, arg_10_0.container:getChildByName("super_discount"):getContentSize().height / 2 - 6))
	else
		arg_10_0.effect1 = nil
	end

	if arg_10_0.effect1 then
		arg_10_0.effect1:setName("effect1")
		arg_10_0.effect1:play(nil, true)
	end
end

function var_0_0.update(arg_11_0)
	arg_11_0.container:getChildByName("current_point_txt"):setString(arg_11_0.activity.details.base_info.point)
	arg_11_0:updateDiscount()
	arg_11_0:updateAwardScroll()
end

function var_0_0.updateAwardScroll(arg_12_0)
	arg_12_0.awardedList:removeAllItems()

	arg_12_0.sellIds = xyd.tables.activityMultiskinSell:ids()

	table.sort(arg_12_0.sellIds, function(arg_13_0, arg_13_1)
		if not arg_12_0:isCanBuy(arg_13_1) and arg_12_0:isCanBuy(arg_13_0) then
			return true
		elseif arg_12_0:isCanBuy(arg_13_1) and not arg_12_0:isCanBuy(arg_13_0) then
			return false
		else
			return arg_13_0 < arg_13_1
		end
	end)

	for iter_12_0 = 1, #arg_12_0.sellIds do
		local var_12_0
		local var_12_1 = arg_12_0.awardedList:dequeueItem()

		if not var_12_1 then
			var_12_1 = arg_12_0.awardedList:newItem()
		else
			var_12_1:removeAllChildren(true)
		end

		local var_12_2 = arg_12_0:createListContent(iter_12_0)
		local var_12_3 = var_12_2:getWidth()
		local var_12_4 = var_12_2:getHeight()

		var_12_1:setItemSize(var_12_3, var_12_4)
		var_12_1:addContent(var_12_2)
		arg_12_0.awardedList:addItem(var_12_1)
		arg_12_0.awardedList:reload()
	end
end

function var_0_0.createListContent(arg_14_0, arg_14_1)
	local var_14_0 = display.newNode()
	local var_14_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1139/activity_item.csb")
	local var_14_2 = var_14_1:getChildByName("container")
	local var_14_3 = arg_14_0.sellIds[arg_14_1]
	local var_14_4 = xyd.tables.activityMultiskinSell:skinItem(var_14_3)
	local var_14_5 = xyd.tables.item:skinPartner(var_14_4)
	local var_14_6 = arg_14_0:getHero(var_14_5)
	local var_14_7 = xyd.tables.skinSkill:getModelID(var_14_4)
	local var_14_8 = xyd.tables.model:smallCard(var_14_7)
	local var_14_9 = xyd.SpriteLoader.new(var_14_8, nil, nil, xyd.DefaultImageType.SMALL_CARD)

	xyd.displaySpriteOnContainer(var_14_9, var_14_2:getChildByName("card_container"))

	if not arg_14_0:isCanBuy(var_14_3) then
		xyd.GrayNode(var_14_2:getChildByName("card_container"))
	end

	var_14_1:addTo(var_14_0)
	var_14_1:setAnchorPoint(cc.p(0, 0))

	local var_14_10 = xyd.tables.activityMultiskinSell:price(var_14_3)

	if arg_14_0.discountId then
		var_14_10 = math.ceil(var_14_10 * xyd.tables.activityMultiskinDiscount:discount(arg_14_0.discountId) / 10)
	end

	var_14_2:getChildByName("point_txt"):setString(var_14_10)

	if not arg_14_0:isCanBuy(var_14_3) then
		var_14_2:getChildByName("point_txt"):setString(var_0_1:translation("MULTISKIN_OWN_TEXT"))
	end

	var_14_0:setContentSize(var_14_2:getContentSize().width + 2, var_14_2:getContentSize().height + 4)
	var_14_1:setPosition(cc.p(1, 2))
	var_14_1:setName("source")
	var_14_1:setTouchEnabled(true)
	var_14_1:setTouchSwallowEnabled(false)
	var_14_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			return true
		elseif arg_15_0.name == "ended" then
			if arg_14_0.scrollViewMoved_ then
				return
			end

			xyd.playButtonSound()

			if not arg_14_0:isCanBuy(var_14_3) then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("MULTISKIN_OWN_TIP_TEXT")
				})

				return
			end

			local function var_15_0(arg_16_0)
				if arg_16_0.base_info then
					arg_14_0.activity.details.base_info = arg_16_0.base_info
				end

				arg_14_0:update()
			end

			arg_14_0:isCanBuy(var_14_3)

			local var_15_1 = {
				discount_id = arg_14_0.discountId,
				sell_id = var_14_3,
				callback = var_15_0,
				point = arg_14_0.activity.details.base_info.point
			}

			xyd.WindowManager.get():openWindow("multiskin_buy", var_15_1)
		end
	end)

	return var_14_0
end

function var_0_0.getHero(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_0.selfPlayer:getHeroIgnoreAwaken(arg_17_1)

	if not var_17_0 then
		var_17_0 = var_0_2.new()

		var_17_0:initUnCollected(arg_17_1)
	end

	return var_17_0
end

function var_0_0.isCanBuy(arg_18_0, arg_18_1)
	local var_18_0 = xyd.tables.activityMultiskinSell:skinItem(arg_18_1)
	local var_18_1 = xyd.tables.skinSkill:getModelID(var_18_0)
	local var_18_2 = xyd.tables.item:skinPartner(var_18_0)
	local var_18_3 = arg_18_0:getHero(var_18_2).skinIds_ or {}

	if arg_18_0.backPack:getItemNumByID(var_18_0) > 0 or xyd.isInTable(var_18_3, var_18_1) then
		return false
	end

	return true
end

function var_0_0.scrollListener(arg_19_0, arg_19_1)
	if arg_19_1.name == "began" then
		arg_19_0.scrollViewMoved_ = false
		arg_19_0.prevX_ = arg_19_1.x
	elseif arg_19_1.name == "moved" and 20 <= math.abs(arg_19_1.x - arg_19_0.prevX_) then
		arg_19_0.scrollViewMoved_ = true
	end
end

return var_0_0
