local var_0_0 = class("WarCampRebornWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("framework.scheduler")
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = xyd.tables.item
local var_0_6 = xyd.tables.hero
local var_0_7 = 30
local var_0_8 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dieHeros_ = {}
	arg_1_0.herosToReborn_ = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_0, arg_2_1)
	arg_2_0:getDieHeros()
	arg_2_0:initItemListViews()
	arg_2_0:setupButtons()

	if not arg_2_0.ticketNum_ then
		arg_2_0.ticketNum_ = arg_2_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.campWarReviveItem)
	end

	arg_2_0:nodeByName("ticket_num"):setString(arg_2_0.ticketNum_)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.getDieHeros(arg_4_0)
	local var_4_0 = arg_4_0.warCamp_:getDieHeros()

	for iter_4_0 = 1, #var_4_0 do
		local var_4_1 = arg_4_0.selfPlayer:getHeroByID(var_4_0[iter_4_0])

		if var_4_1 then
			local var_4_2 = var_0_2.new()

			var_4_2:populate(var_4_1:toParams())
			table.insert(arg_4_0.dieHeros_, var_4_2)
		end
	end

	arg_4_0.warCamp_:updateHeros(arg_4_0.dieHeros_)
end

function var_0_0.updateDieHero(arg_5_0, arg_5_1)
	for iter_5_0 = #arg_5_0.dieHeros_, 1, -1 do
		if arg_5_0.dieHeros_[iter_5_0] == arg_5_1 then
			table.remove(arg_5_0.dieHeros_, iter_5_0)

			break
		end
	end
end

function var_0_0.updateDieHeros(arg_6_0, arg_6_1)
	for iter_6_0 = 1, #arg_6_1 do
		for iter_6_1 = #arg_6_0.dieHeros_, 1, -1 do
			if arg_6_0.dieHeros_[iter_6_1]:getHeroID() == arg_6_1[iter_6_0] then
				table.remove(arg_6_0.dieHeros_, iter_6_1)

				break
			end
		end
	end
end

function var_0_0.initItemListViews(arg_7_0)
	local var_7_0 = {
		touchOnContent = true,
		async = true,
		viewRect = cc.rect(0, 0, arg_7_0:nodeByName("heros_container"):getContentSize().width, arg_7_0:nodeByName("heros_container"):getContentSize().height + 10),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}

	arg_7_0.heroList = cc.ui.UIListView.new(var_7_0):addTo(arg_7_0:nodeByName("heros_container"))

	arg_7_0.heroList:setDelegate(handler(arg_7_0, arg_7_0.delegate))
	arg_7_0.heroList:reload()
end

function var_0_0.delegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return math.ceil(#arg_8_0.dieHeros_ / 6)
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0
		local var_8_1
		local var_8_2 = arg_8_0.heroList:dequeueItem()

		if not var_8_2 then
			var_8_2 = arg_8_0.heroList:newItem()
		else
			var_8_2:removeAllChildren()
		end

		local var_8_3 = display.newNode()

		for iter_8_0 = 1, 6 do
			if not arg_8_0.dieHeros_[6 * (arg_8_3 - 1) + iter_8_0] then
				break
			end

			cell = display.newNode()

			arg_8_0:initHeroCell(cell, arg_8_0.dieHeros_[6 * (arg_8_3 - 1) + iter_8_0])
			cell:addTo(var_8_3)

			local var_8_4 = cell:getContentSize().width
			local var_8_5 = cell:getContentSize().height
			local var_8_6 = (arg_8_0.heroList.viewRect_.width - var_8_4 * var_0_8) / (var_0_8 + 1)

			cell:setPosition(var_8_6 * iter_8_0 + (iter_8_0 - 1) * var_8_4 + var_8_4 / 2, var_0_7 + var_8_5 / 2 - 2)
			var_8_3:size(840, var_8_5 + var_0_7)
			var_8_2:setItemSize(840, var_8_5 + var_0_7)
		end

		var_8_2:addContent(var_8_3)

		return var_8_2
	end
end

function var_0_0.initHeroCell(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")

	var_9_0:getChildByName("yongbing_tubiao"):setVisible(false)

	local var_9_1 = var_9_0:getChildByName("background"):getContentSize()

	var_9_0:setContentSize(var_9_1)
	arg_9_1:setContentSize(var_9_1)
	xyd.setAvatarBorder(arg_9_2, var_9_0:getChildByName("avatar"))

	local var_9_2 = var_9_0:getChildByName("chosen")

	var_9_2:setLocalZOrder(100)
	var_9_2:setVisible(false)

	local var_9_3 = var_9_0:getChildByName("avatar_mask")

	var_9_3:setLocalZOrder(2)
	var_9_3:setVisible(false)
	var_9_0:getChildByName("is_can_rent"):setVisible(false)

	for iter_9_0 = 1, 3 do
		var_9_0:getChildByName("team" .. iter_9_0):setVisible(false)
	end

	var_9_0:getChildByName("lv_txt"):setString(arg_9_2:getLevel())

	local var_9_4 = var_9_0:getChildByName("name_text")

	var_9_4:setString(arg_9_2:getName())
	var_9_4:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	local var_9_5 = var_9_0:getChildByName("hp_bar")
	local var_9_6 = var_9_0:getChildByName("mp_bar")
	local var_9_7 = var_9_0:getChildByName("dead_text")

	if not tolua.isnull(var_9_7) then
		var_9_7:setVisible(false)
	end

	var_9_5:hide()
	var_9_6:hide()
	var_9_0:getChildByName("hp_di"):hide()
	var_9_0:getChildByName("mp_di"):hide()
	var_9_0:setName("layout")
	var_9_0:setPosition(cc.p(0, 0))

	arg_9_1.data = arg_9_2

	arg_9_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_9_1:addChild(var_9_0)
	arg_9_1:setTouchSwallowEnabled(false)
	arg_9_1:setTouchEnabled(true)

	arg_9_1.hero = arg_9_2

	arg_9_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			arg_9_0.startClick_ = true
			arg_9_0.prevX_ = arg_10_0.x
			arg_9_0.prevY_ = arg_10_0.y

			arg_9_1:setScale(0.9)
		elseif arg_10_0.name == "moved" then
			if math.abs(arg_10_0.y - arg_9_0.prevY_) > 5 or math.abs(arg_10_0.x - arg_9_0.prevX_) > 5 then
				arg_9_0.startClick_ = false

				arg_9_1:setScale(1)
			end
		elseif arg_10_0.name == "ended" and arg_9_0.startClick_ then
			arg_9_0:clickAvatar(arg_9_1)
			arg_9_1:setScale(1)
		end

		return true
	end)
end

function var_0_0.checkTicket(arg_11_0, arg_11_1)
	arg_11_1 = arg_11_1 or 1

	if not arg_11_0.ticketNum_ then
		arg_11_0.ticketNum_ = arg_11_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.campWarReviveItem)
	end

	if arg_11_0.ticketNum_ and arg_11_1 <= arg_11_0.ticketNum_ then
		return true
	end

	return false
end

function var_0_0.changeTicket(arg_12_0)
	local var_12_0 = arg_12_0.selfPlayer:getBackpack()
	local var_12_1 = {
		itemNum = 1,
		itemID = xyd.tables.misc.campWarReviveItem
	}

	var_12_0:removeItem(var_12_1)

	arg_12_0.ticketNum_ = arg_12_0.ticketNum_ - 1

	local var_12_2 = xyd.WindowManager.get():getWindow("war_camp_map")

	if var_12_2 then
		var_12_2:updateTop()
	end
end

function var_0_0.updateItems(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_0.selfPlayer:getBackpack()
	local var_13_1 = {
		itemID = xyd.tables.misc.campWarReviveItem,
		itemNum = arg_13_1
	}

	var_13_0:removeItem(var_13_1)

	arg_13_0.ticketNum_ = arg_13_0.ticketNum_ - arg_13_1

	arg_13_0:nodeByName("ticket_num"):setString(arg_13_0.ticketNum_)

	local var_13_2 = xyd.WindowManager.get():getWindow("war_camp_map")

	if var_13_2 then
		var_13_2:updateTop()
	end
end

function var_0_0.setupButtons(arg_14_0)
	arg_14_0:nodeByName("reborn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			if not arg_14_0:checkTicket(#arg_14_0.herosToReborn_) then
				local var_15_0 = var_0_1:translation("WAR_CAMP_REBORN_TEXT3")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_15_0
				})

				return
			end

			if #arg_14_0.herosToReborn_ > 0 then
				local var_15_1 = string.format(var_0_1:translation("WAR_CAMP_REBORN_TEXT1"), #arg_14_0.herosToReborn_)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_15_1, function()
					local var_16_0 = {
						partner_ids = arg_14_0.herosToReborn_
					}

					arg_14_0.warCamp_:rebornHero(var_16_0, function(arg_17_0, arg_17_1)
						if arg_17_0 == xyd.error.OK then
							arg_14_0:updateDieHeros(arg_14_0.herosToReborn_)
							arg_14_0:updateItems(arg_17_1.reborn_num or 0)

							arg_14_0.herosToReborn_ = {}

							arg_14_0.heroList:reload()
						end
					end)
				end, nil, nil, arg_14_0.colorMode)
			else
				local var_15_2 = var_0_1:translation("WAR_CAMP_REBORN_TEXT2")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_15_2
				})
			end
		end
	end)
	arg_14_0:nodeByName("reborn_all"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended then
			if not arg_14_0:checkTicket(#arg_14_0.dieHeros_) then
				local var_18_0 = var_0_1:translation("WAR_CAMP_REBORN_TEXT3")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_18_0
				})

				return
			end

			local var_18_1 = {}

			if #arg_14_0.dieHeros_ > 0 then
				for iter_18_0 = 1, #arg_14_0.dieHeros_ do
					table.insert(var_18_1, arg_14_0.dieHeros_[iter_18_0]:getHeroID())
				end

				local var_18_2 = string.format(var_0_1:translation("WAR_CAMP_REBORN_TEXT1"), #var_18_1)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_18_2, function()
					local var_19_0 = {
						partner_ids = var_18_1
					}

					arg_14_0.warCamp_:rebornHero(var_19_0, function(arg_20_0, arg_20_1)
						if arg_20_0 == xyd.error.OK then
							arg_14_0:updateDieHeros(var_18_1)
							arg_14_0:updateItems(arg_20_1.reborn_num or 0)

							arg_14_0.herosToReborn_ = {}

							arg_14_0.heroList:reload()
						end
					end)
				end, nil, nil, arg_14_0.colorMode)
			else
				local var_18_3 = var_0_1:translation("WAR_CAMP_REBORN_TEXT2")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_18_3
				})
			end
		end
	end)
end

function var_0_0.clickAvatar(arg_21_0, arg_21_1)
	local var_21_0 = arg_21_1.data

	if xyd.tableHaveElement(arg_21_0.herosToReborn_, var_21_0:getHeroID()) then
		table.remove(arg_21_0.herosToReborn_, table.indexof(arg_21_0.herosToReborn_, var_21_0:getHeroID()))
		arg_21_1:removeChildByName("tick")
		arg_21_1:removeChildByName("kuang")
	else
		table.insert(arg_21_0.herosToReborn_, var_21_0:getHeroID())

		local var_21_1 = xyd.AssetLoader.get():loadSprite("windows/war_camp/reborn/kuang.png")

		var_21_1:setName("kuang")
		var_21_1:setPosition(90, 110)
		var_21_1:addTo(arg_21_1)

		local var_21_2 = xyd.AssetLoader.get():loadSprite("windows/war_camp/reborn/tick.png")

		var_21_2:setName("tick")
		var_21_2:setPosition(100, 120)
		var_21_2:addTo(arg_21_1)
	end
end

return var_0_0
