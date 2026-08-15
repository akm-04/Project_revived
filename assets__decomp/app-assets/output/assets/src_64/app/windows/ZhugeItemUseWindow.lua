local var_0_0 = class("ZhugeItemUseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.zhugeShop
local var_0_4 = import("app.model.Hero")
local var_0_5 = 5
local var_0_6 = 30

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.itemID = arg_1_2.itemID
	arg_1_0.specialItem = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initHeros()
	arg_2_0:initListview()
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0)
	local var_3_0 = xyd.WindowManager.get():getWindow("zhuge_backpack")

	if var_3_0 then
		var_3_0:updateListview()
	end

	local var_3_1 = xyd.WindowManager.get():getWindow("zhuge_adventure")

	if var_3_1 then
		var_3_1:updateBottomList()
		var_3_1:initHerosModel(true)
		var_3_1:showRightBtn(true)
	end
end

function var_0_0.initHeros(arg_4_0)
	local var_4_0 = arg_4_0.zhugeModel:getMemberHeros()
	local var_4_1 = arg_4_0:checkItemCanSaveLife()
	local var_4_2 = arg_4_0:checkItemCanAwaken()
	local var_4_3 = {}

	for iter_4_0 = 1, #var_4_0 do
		local var_4_4 = var_4_0[iter_4_0]
		local var_4_5 = arg_4_0.zhugeModel:getHeroStatus(var_4_4:getTableID())

		if var_4_2 then
			if arg_4_0:checkHeroCanAwaken(var_4_4) then
				table.insert(var_4_3, var_4_4)
			end
		elseif var_4_1 then
			if var_4_5.health == 2 then
				table.insert(var_4_3, var_4_4)
			end
		elseif var_4_5.health ~= 2 then
			table.insert(var_4_3, var_4_4)
		end
	end

	arg_4_0.heros = var_4_3
end

function var_0_0.checkItemCanSaveLife(arg_5_0)
	local var_5_0 = var_0_3:types(arg_5_0.itemID)

	for iter_5_0 = 1, #var_5_0 do
		if var_5_0[iter_5_0] == xyd.ZhugeShopItemType.SAVE_LIFE then
			arg_5_0.specialItem = true

			return true
		end
	end

	return false
end

function var_0_0.checkItemCanAwaken(arg_6_0)
	local var_6_0 = var_0_3:types(arg_6_0.itemID)

	for iter_6_0 = 1, #var_6_0 do
		if var_6_0[iter_6_0] == xyd.ZhugeShopItemType.AWAKEN then
			arg_6_0.specialItem = true

			return true
		end
	end

	return false
end

function var_0_0.checkHeroCanAwaken(arg_7_0, arg_7_1)
	return arg_7_1:afterAwakenID() > 0 and arg_7_1:isCanAwaken()
end

function var_0_0.updateHero(arg_8_0, arg_8_1)
	if arg_8_0:checkItemCanAwaken() then
		local var_8_0 = arg_8_1:afterAwakenID()

		arg_8_1:setTableID(var_8_0)
	end
end

function var_0_0.layout(arg_9_0)
	local var_9_0 = var_0_2:name(arg_9_0.itemID)
	local var_9_1 = string.format(var_0_1:translation("ZHUGE_FOREST_TIPS_16"), var_9_0)

	arg_9_0:nodeByName("text_tips"):setString(var_9_1)
end

function var_0_0.initListview(arg_10_0)
	local var_10_0 = arg_10_0:nodeByName("list")
	local var_10_1 = var_10_0:getContentSize().width
	local var_10_2 = var_10_0:getContentSize().height

	arg_10_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_10_1, var_10_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_10_0)

	arg_10_0.list:setDelegate(handler(arg_10_0, arg_10_0.delegate))
end

function var_0_0.delegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = math.ceil(#arg_11_0.heros / var_0_5)

	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return var_11_0
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_1
		local var_11_2
		local var_11_3
		local var_11_4 = arg_11_0.list:dequeueItem()

		if not var_11_4 then
			var_11_4 = arg_11_0.list:newItem()
		else
			var_11_4:removeAllChildren()
		end

		local var_11_5 = display.newNode()

		var_11_5:setTouchSwallowEnabled(false)

		for iter_11_0 = 1, var_0_5 do
			local var_11_6 = (arg_11_3 - 1) * var_0_5 + iter_11_0

			if var_11_6 > #arg_11_0.heros then
				break
			end

			var_11_3 = display.newNode()

			arg_11_0:initHeroItem(var_11_3, var_11_6)

			local var_11_7 = var_11_3:getContentSize().width
			local var_11_8 = var_11_3:getContentSize().height
			local var_11_9 = (arg_11_0.list.viewRect_.width - var_11_7 * var_0_5) / (var_0_5 + 1)

			var_11_3:pos(var_11_9 * iter_11_0 + (iter_11_0 - 1) * var_11_7 + var_11_7 / 2, var_0_6 + var_11_8 / 2 - 2)
			var_11_5:addChild(var_11_3)
		end

		var_11_5:setContentSize(cc.size(arg_11_0.list.viewRect_.width, var_11_3:getContentSize().height + var_0_6))
		var_11_4:setItemSize(arg_11_0.list.viewRect_.width, var_11_3:getContentSize().height + var_0_6)
		var_11_4:addContent(var_11_5)

		return var_11_4
	end
end

function var_0_0.initHeroItem(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_0.heros[arg_12_2]
	local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")

	var_12_1:getChildByName("yongbing_tubiao"):setVisible(false)

	local var_12_2 = var_12_1:getChildByName("background"):getContentSize()

	var_12_1:setContentSize(var_12_2)
	arg_12_1:setContentSize(var_12_2)
	xyd.setAvatarBorder(var_12_0, var_12_1:getChildByName("avatar"))

	local var_12_3 = var_12_1:getChildByName("chosen")

	var_12_3:setLocalZOrder(100)
	var_12_3:setVisible(false)

	local var_12_4 = var_12_1:getChildByName("avatar_mask")

	var_12_4:setLocalZOrder(2)
	var_12_4:setVisible(false)
	var_12_1:getChildByName("is_can_rent"):setVisible(false)

	for iter_12_0 = 1, 3 do
		var_12_1:getChildByName("team" .. iter_12_0):setVisible(false)
	end

	var_12_1:getChildByName("lv_txt"):setString(var_12_0:getLevel())

	local var_12_5 = var_12_1:getChildByName("name_text")

	var_12_5:setString(var_12_0:getName())
	var_12_5:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[var_12_0:getColor()] ~= "" then
		local var_12_6 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_12_5:getX() + var_12_5:getWidth() / 2 - 10,
			y = var_12_5:getY(),
			color = xyd.color.HERO_QUALITY[var_12_0:getColor()],
			text = xyd.Color2Level[var_12_0:getColor()]
		}
		local var_12_7 = xyd.AssetLoader.get():loadLabel(var_12_6)

		var_12_7:addTo(var_12_1)
		var_12_7:align(display.CENTER_LEFT)
		var_12_7:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_12_5:x(var_12_5:getX() - 15)
	end

	local var_12_8 = var_12_1:getChildByName("hp_bar")
	local var_12_9 = var_12_1:getChildByName("mp_bar")
	local var_12_10 = var_12_1:getChildByName("dead_text")

	var_12_10:setString(var_0_1:translation("ALREADY_DEAD"))

	if var_12_10 then
		var_12_10:setVisible(false)
	end

	local var_12_11 = false
	local var_12_12 = arg_12_0.zhugeModel:getHeroStatus(var_12_0:getTableID())

	if var_12_12 and next(var_12_12) ~= nil then
		arg_12_0:updateHeroAvatar(var_12_1, arg_12_1, var_12_0, var_12_12)
	else
		var_12_8:hide()
		var_12_9:hide()
		var_12_1:getChildByName("hp_di"):hide()
		var_12_1:getChildByName("mp_di"):hide()
	end

	var_12_1:setName("layout")
	var_12_1:setPosition(cc.p(0, 0))

	arg_12_1.data = var_12_0
	var_12_0.isDead = var_12_11

	arg_12_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_12_1:addChild(var_12_1)
	arg_12_1:setTouchSwallowEnabled(false)
	arg_12_1:setTouchEnabled(true)
	arg_12_1:setTouchEnabled(true)
	arg_12_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			return true
		elseif arg_13_0.name == "moved" then
			-- block empty
		elseif arg_13_0.name == "ended" then
			if arg_12_0.backpack:getItemNumByID(arg_12_0.itemID) <= 0 then
				local var_13_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_15")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_13_0
				})

				return
			end

			local var_13_1 = var_0_2:name(arg_12_0.itemID)
			local var_13_2 = string.format(var_0_1:translation("ZHUGE_FOREST_TIPS_22"), var_12_0:getName(), var_13_1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_13_2, function()
				local var_14_0 = {
					item_id = arg_12_0.itemID,
					partner_id = var_12_12.init_id
				}

				arg_12_0.zhugeModel:useItem(var_14_0, function(arg_15_0, arg_15_1)
					if arg_15_0 == xyd.error.OK then
						local var_15_0 = {
							itemNum = 1,
							itemID = arg_12_0.itemID
						}

						arg_12_0.backpack:removeItem(var_15_0)

						local var_15_1 = string.format(var_0_1:translation("ZHUGE_FOREST_TIPS_17"), var_12_0:getName(), var_0_2:name(arg_12_0.itemID))

						xyd.WindowManager.get():openWindow("toast", {
							message = var_15_1
						})

						if arg_12_0.specialItem then
							arg_12_0:updateHero(var_12_0)
							arg_12_0:initHeros()
							arg_12_0.list:reload()
						else
							local var_15_2 = arg_12_0.zhugeModel:getHeroStatus(var_12_0:getTableID())

							arg_12_0:updateHeroAvatar(var_12_1, arg_12_1, var_12_0, var_15_2)
						end
					end
				end)
			end, nil, nil, arg_12_0.colorMode)
		end
	end)
end

function var_0_0.updateHeroAvatar(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4)
	if not arg_16_4 then
		return
	end

	local var_16_0 = arg_16_1:getChildByName("hp_bar")
	local var_16_1 = arg_16_1:getChildByName("mp_bar")
	local var_16_2 = arg_16_1:getChildByName("dead_text")

	var_16_2:setVisible(false)

	local var_16_3 = arg_16_1:getChildByName("avatar_mask")

	var_16_3:setVisible(false)

	local var_16_4 = false

	arg_16_3.healthStatus = arg_16_4

	if arg_16_4 and arg_16_4.health then
		local var_16_5 = 0
		local var_16_6 = 0

		if arg_16_4.health == 0 then
			var_16_5 = 100
			var_16_6 = arg_16_4.mp / 10
		elseif arg_16_4.health == 1 and arg_16_4.hp >= 1 then
			var_16_5 = arg_16_4.hp / arg_16_4.max_hp * 100
			var_16_6 = arg_16_4.mp / 10
		else
			var_16_5 = 0
			var_16_6 = 0

			var_16_3:setVisible(true)
			var_16_2:setLocalZOrder(3)
			var_16_2:setVisible(true)
			var_16_2:enableOutline(cc.c4b(0, 0, 0), 2)
			var_16_2:getVirtualRenderer():setAdditionalKerning(-2)

			var_16_4 = true
		end

		var_16_0:setPercent(var_16_5)
		var_16_0:setVisible(true)
		var_16_1:setPercent(var_16_6)
		var_16_1:setVisible(true)
	end

	arg_16_3.isDead = var_16_4
end

function var_0_0.didOpen(arg_17_0, arg_17_1)
	var_0_0.super:didOpen(arg_17_1)
	arg_17_0.list:reload()
end

return var_0_0
