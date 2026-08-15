local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.model
local var_0_5 = import("app.common.ui.SpineEffect")
local var_0_6 = "skeletons/ui_effect/flower_week_load/flower_week_load"
local var_0_7 = 10

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
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

	local var_2_1 = var_2_0:getChildByName("container")

	arg_2_0:init()
	arg_2_0:layout(var_2_1)
end

function var_0_0.init(arg_3_0)
	arg_3_0.herosList = {}
	arg_3_0.selectID = 0
end

function var_0_0.layout(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0.activity.details.hero_id

	if not var_4_0 or var_4_0 == 0 then
		arg_4_0:createSelect(arg_4_1)
	else
		arg_4_0.selectID = var_4_0

		arg_4_0:createDate(arg_4_1)
	end

	arg_4_0:updateShowHero(arg_4_1)

	local var_4_1 = arg_4_1:getChildByName("btn_check")

	var_4_1:getChildByName("txt_check"):setString(var_0_1:translation("ACTIVITY_1126_TEXT1"))
	var_4_1:getChildByName("txt_check"):enableOutline(cc.c4b(151, 90, 187, 255), 2)
	var_4_1:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			if arg_4_0.selectID == 0 then
				local var_5_0 = var_0_1:translation("NEW_DATE_TIPS_3")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_5_0
				})

				return
			end

			local var_5_1 = var_0_2.new()

			var_5_1:initUnCollected(arg_4_0.selectID)

			var_5_1.isHideBorrow = true

			xyd.WindowManager.get():openWindow(xyd.WindowName.heroattributeWnd, var_5_1)
		end
	end)
end

function var_0_0.createSelect(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1:getChildByName("first_panel")

	var_6_0:setVisible(true)
	arg_6_1:getChildByName("second_panel"):setVisible(false)
	var_6_0:getChildByName("txt_tip_1"):setString(var_0_1:translation("ACTIVITY_1126_TEXT2"))
	var_6_0:getChildByName("txt_tip_2"):setString(var_0_1:translation("ACTIVITY_1126_TEXT3"))
	var_6_0:getChildByName("txt_tip_3"):setString(var_0_1:translation("ACTIVITY_1126_TEXT4"))

	for iter_6_0 = 1, 4 do
		var_6_0:getChildByName("txt_tip_" .. iter_6_0):enableOutline(cc.c4b(171, 121, 179, 255), 2)
	end

	arg_6_0:initHerosPanel(var_6_0:getChildByName("heros_panel"))
	var_6_0:getChildByName("btn_date"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			if arg_6_0.selectID == 0 then
				local var_7_0 = var_0_1:translation("NEW_DATE_TIPS_3")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_0
				})

				return
			end

			local var_7_1 = var_0_3:name(arg_6_0.selectID)
			local var_7_2 = string.format(var_0_1:translation("NEW_DATE_TIPS"), var_7_1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_2, function()
				local var_8_0 = {
					hero_id = arg_6_0.selectID
				}

				xyd.Backend.get():request(xyd.mid.SELECT_DATE_HERO_2, var_8_0, function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						arg_6_0:getNewestData()

						arg_6_0.activity.details = arg_9_1
						arg_6_0.selectID = arg_9_1.hero_id

						arg_6_0:createDate(arg_6_1)
						arg_6_0:refreshRedPoint()
					end
				end)
			end, nil, nil, xyd.ColorMode.ACTIVITY)
		end
	end)
end

function var_0_0.initHerosPanel(arg_10_0, arg_10_1)
	arg_10_1:removeAllChildren()

	local var_10_0 = arg_10_1:getContentSize()
	local var_10_1 = 0
	local var_10_2 = var_10_0.height
	local var_10_3 = 0
	local var_10_4 = xyd.tables.misc.activityWeek2PresentPartner

	for iter_10_0 = 1, #var_10_4 do
		local var_10_5 = var_10_4[iter_10_0]
		local var_10_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1126/show_hero_item.csb")

		var_10_6:addTo(arg_10_1)

		local var_10_7 = var_10_6:getChildByName("container")
		local var_10_8 = var_10_7:getContentSize()

		var_10_6:setPosition(cc.p(var_10_1, var_10_2 - var_10_8.height))
		arg_10_0:setHeroCard(var_10_5, var_10_7:getChildByName("hero_card"))

		local var_10_9 = arg_10_0.selectID == var_10_5 and true or false

		var_10_7:getChildByName("hero_bg_select"):setVisible(var_10_9)
		var_10_7:getChildByName("text_name"):setString(var_0_3:name(var_10_5))
		var_10_7:getChildByName("text_name"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
		var_10_6:setTouchEnabled(true)
		var_10_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
			if arg_11_0.name == "began" then
				return true
			elseif arg_11_0.name == "ended" and arg_10_0.selectID ~= var_10_5 then
				arg_10_0:updateSelect(var_10_5)
				arg_10_0:updateShowHero(arg_10_1:getParent():getParent())
			end
		end)

		var_10_3 = var_10_3 + 1

		if var_10_3 >= 3 then
			var_10_2 = var_10_2 - var_10_8.height + 5
			var_10_1 = 0
			var_10_3 = 0
		else
			var_10_1 = var_10_1 + var_10_8.width + 2
		end

		arg_10_0.herosList[var_10_5] = var_10_7
	end

	if arg_10_0.selectID == 0 then
		arg_10_0.selectID = var_10_4[1]
	end

	arg_10_0:updateSelect(arg_10_0.selectID)
end

function var_0_0.updateSelect(arg_12_0, arg_12_1)
	if arg_12_0.herosList and next(arg_12_0.herosList) then
		for iter_12_0, iter_12_1 in pairs(arg_12_0.herosList) do
			local var_12_0 = false

			if iter_12_0 == arg_12_1 then
				arg_12_0.selectID = arg_12_1
				var_12_0 = true
			end

			iter_12_1:getChildByName("hero_bg_select"):setVisible(var_12_0)
		end
	end
end

function var_0_0.setHeroCard(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = "windows/activities/1126/bg_" .. arg_13_1 .. ".png"
	local var_13_1 = xyd.AssetLoader.get():loadSprite(var_13_0)
	local var_13_2 = size
	local var_13_3 = arg_13_2:getContentSize().height
	local var_13_4 = arg_13_2:getContentSize().width

	if not var_13_1 then
		return
	end

	arg_13_2:addChild(var_13_1)
	var_13_1:setPosition(var_13_4 / 2, var_13_3 / 2)
	var_13_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_13_1:setScale(var_13_4 / var_13_1:getWidth(), var_13_3 / var_13_1:getHeight())
	var_13_1:setLocalZOrder(-1)
end

function var_0_0.updateShowHero(arg_14_0, arg_14_1)
	if arg_14_0.selectID == 0 then
		return
	end

	local var_14_0 = arg_14_0.selectID
	local var_14_1 = arg_14_1:getChildByName("hero_show")
	local var_14_2 = var_14_1:getChildByName("hero")

	var_14_2:removeAllChildren()

	local var_14_3 = var_0_4:transparentCard(var_0_3:modelID(var_14_0))
	local var_14_4 = xyd.SpriteLoader.new(var_14_3, nil, extra_params, xyd.DefaultImageType.HOME_CARD)

	var_14_4:setAnchorPoint(cc.p(0.5, 0))
	var_14_4:addTo(var_14_2)

	local var_14_5 = var_14_2:getContentSize()

	var_14_4:setPosition(cc.p(var_14_5.width / 2, 0))

	if var_14_0 == 10001012 then
		var_14_4:setScale(-1, 1)
	else
		var_14_4:setScale(1)
	end

	var_14_1:getChildByName("hero_name_txt"):setString(var_0_3:name(var_14_0))

	local var_14_6 = var_0_3:initialStar(var_14_0)
	local var_14_7 = cc.p(var_14_1:getChildByName("star_pos"):getPosition())
	local var_14_8

	if var_14_1:getChildByName("hero_star_node") then
		var_14_1:getChildByName("hero_star_node"):removeAllChildren()

		var_14_8 = var_14_1:getChildByName("hero_star_node")
	else
		var_14_8 = display.newNode()

		var_14_8:addTo(var_14_1)
		var_14_8:setName("hero_star_node")
		var_14_8:setAnchorPoint(cc.p(0.5, 0.5))
		var_14_8:setPosition(cc.p(var_14_7))
	end

	local var_14_9 = 0
	local var_14_10 = 0

	for iter_14_0 = 1, var_14_6 do
		local var_14_11 = xyd.AssetLoader.get():loadSprite("windows/activities/1126/star.png")

		var_14_11:addTo(var_14_8)
		var_14_11:setAnchorPoint(cc.p(0.5, 0.5))
		var_14_11:setPosition(cc.p(var_14_9, var_14_10))

		var_14_10 = var_14_10 - var_14_11:getContentSize().height
	end
end

function var_0_0.createDate(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_1:getChildByName("second_panel")

	var_15_0:setVisible(true)
	arg_15_1:getChildByName("first_panel"):setVisible(false)
	arg_15_0:updateDialog(var_15_0)
	arg_15_0:updateDayCount(var_15_0)
	arg_15_0:updateGiftList(var_15_0)
	var_15_0:getChildByName("txt_tip_5"):setString(var_0_1:translation("ACTIVITY_1126_TEXT5"))
	var_15_0:getChildByName("txt_tip_6"):setString(var_0_1:translation("ACTIVITY_1126_TEXT6"))
	var_15_0:getChildByName("txt_tip_7"):setString(var_0_1:translation("ACTIVITY_1126_TEXT7"))
	var_15_0:getChildByName("txt_tip_8"):setString(var_0_1:translation("ACTIVITY_1126_TEXT8"))
	var_15_0:getChildByName("txt_tip_9"):setString(var_0_1:translation("ACTIVITY_1126_TEXT9"))
	var_15_0:getChildByName("btn_send_gift"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.began then
			var_15_0:getChildByName("btn_send_gift"):setScale(0.9)
		elseif arg_16_1 == ccui.TouchEventType.moved then
			var_15_0:getChildByName("btn_send_gift"):setScale(1)
		elseif arg_16_1 == ccui.TouchEventType.ended then
			var_15_0:getChildByName("btn_send_gift"):setScale(1)

			local var_16_0 = arg_15_0.activity.details.dating_day + 1

			arg_15_0.activitiesModel:getActivityReward(arg_15_0.activity.table_id, var_16_0, function(arg_17_0, arg_17_1)
				if arg_17_0 == xyd.error.OK then
					arg_15_0:getNewestData()

					arg_15_0.activity.details = arg_17_1.base_info

					arg_15_0:playMove(var_15_0, arg_17_1.awards)
					arg_15_0:refreshRedPoint()
				end
			end)
		end
	end)
	var_15_0:getChildByName("btn_show_gifts"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended then
			local var_18_0 = {
				details = arg_15_0.activity.details
			}

			xyd.WindowManager.get():openWindow("new_date_gifts_2", var_18_0)
		end
	end)
end

function var_0_0.updateDialog(arg_19_0, arg_19_1)
	if not (arg_19_0.activity.details.is_login == 1 and true or false) then
		arg_19_1:getChildByName("dialog_bg"):setVisible(false)
		arg_19_1:getChildByName("text_dialog"):setVisible(false)

		return
	end

	arg_19_1:getChildByName("dialog_bg"):setVisible(true)
	arg_19_1:getChildByName("text_dialog"):setVisible(true)

	local var_19_0 = var_0_3:name(arg_19_0.selectID)
	local var_19_1 = string.format(var_0_1:translation("NEW_DATE_DIALOG"), var_19_0)

	arg_19_1:getChildByName("text_dialog"):setString(var_19_1)
end

function var_0_0.updateDayCount(arg_20_0, arg_20_1)
	local var_20_0 = arg_20_0.activity.details.dating_day
	local var_20_1 = arg_20_1:getChildByName("day_count")

	var_20_1:removeAllChildren()

	local var_20_2 = xyd.tables.misc.activityWeekDay
	local var_20_3 = 0

	for iter_20_0 = 1, var_20_2 do
		local var_20_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1126/day_count.csb")

		var_20_4:addTo(var_20_1)
		var_20_4:setPosition(cc.p(var_20_3, 0))

		local var_20_5 = var_20_4:getChildByName("container")
		local var_20_6 = false

		if iter_20_0 <= var_20_0 then
			local var_20_7 = iter_20_0 .. var_0_1:translation("UNIT_DAY")

			var_20_5:getChildByName("text_day"):setString(var_20_7)
			var_20_5:getChildByName("text_day"):enableOutline(cc.c4b(229, 111, 234, 255), 2)

			var_20_6 = true
		end

		var_20_5:getChildByName("small_love_1"):setVisible(var_20_6)
		var_20_5:getChildByName("small_love_2"):setVisible(not var_20_6)
		var_20_5:getChildByName("text_day"):setVisible(var_20_6)

		var_20_3 = var_20_3 + var_20_5:getContentSize().width + 10
	end
end

function var_0_0.updateGiftList(arg_21_0, arg_21_1)
	local var_21_0 = arg_21_0.activity.details.is_login == 1 and true or false

	arg_21_1:getChildByName("btn_send_gift"):setVisible(not var_21_0)
	arg_21_1:getChildByName("text_is_send"):setVisible(var_21_0)
	arg_21_1:getChildByName("have_get_gift"):setVisible(false)

	local var_21_1 = arg_21_1:getChildByName("gift_list")

	var_21_1:removeAllChildren()

	local var_21_2 = arg_21_1:getContentSize()
	local var_21_3 = 0

	if var_21_0 then
		var_21_3 = arg_21_0.activity.details.dating_day
	else
		var_21_3 = arg_21_0.activity.details.dating_day + 1
	end

	local var_21_4 = xyd.tables.activityWeekNew2:gift(var_21_3)
	local var_21_5 = xyd.tables.activityWeekNew2:scrollNum(var_21_3)

	arg_21_0:rewardFormat(var_21_1, var_21_4, var_21_5)
end

function var_0_0.rewardFormat(arg_22_0, arg_22_1, arg_22_2, arg_22_3)
	local var_22_0 = arg_22_1:getContentSize().height
	local var_22_1 = 14
	local var_22_2 = clone(xyd.tables.gift:items(arg_22_2))
	local var_22_3 = clone(xyd.tables.gift:itemNum(arg_22_2))

	if arg_22_3 == -1 then
		table.insert(var_22_2, 1, arg_22_0.selectID)
		table.insert(var_22_3, 1, 1)
	elseif arg_22_3 > 0 then
		table.insert(var_22_2, 1, xyd.tables.hero:stoneID(arg_22_0.selectID))
		table.insert(var_22_3, 1, arg_22_3)
	end

	local var_22_4 = #var_22_2

	for iter_22_0 = 1, #var_22_2 do
		local var_22_5 = display.newNode()

		var_22_5:setContentSize(var_22_0, var_22_0)

		if xyd.tables.item:type(var_22_2[iter_22_0]) == -1 then
			xyd.setAvatarBorder(var_22_2[iter_22_0], var_22_5, 1, xyd.tables.hero:initialStar(var_22_2[iter_22_0]))
		else
			xyd.setItemBorder(var_22_5, var_22_2[iter_22_0], false, false, var_22_3[iter_22_0])
		end

		var_22_5:addTo(arg_22_1)
		var_22_5:setAnchorPoint(cc.p(0, 0))
		var_22_5:setPosition((iter_22_0 - 1) * (var_22_0 + var_22_1), 0)

		local var_22_6 = {
			id = var_22_2[iter_22_0],
			lev = xyd.tables.item:level(var_22_2[iter_22_0])
		}

		if xyd.tables.item:type(var_22_2[iter_22_0]) == -1 then
			var_22_6.tipsType = 0
			var_22_6.desc1 = xyd.tables.hero:getDes(var_22_2[iter_22_0])
		elseif specialItem then
			var_22_6.tipsType = 1
			var_22_6.id = -3
		else
			var_22_6.tipsType = 1
			var_22_6.desc1 = xyd.tables.item:desc1(var_22_2[iter_22_0])
			var_22_6.desc2 = xyd.tables.item:desc2(var_22_2[iter_22_0])
		end

		var_22_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_22_2[iter_22_0])
		var_22_6.name = xyd.tables.item:name(var_22_2[iter_22_0])

		arg_22_0:addTips(var_22_5, var_22_6)
	end

	local var_22_7 = xyd.tables.gift:crystal(arg_22_2)

	if var_22_7 and var_22_7 > 0 then
		local var_22_8 = display.newNode()

		var_22_8:setContentSize(var_22_0, var_22_0)
		xyd.setItemBorder(var_22_8, -1, false, false, var_22_7)
		var_22_8:addTo(arg_22_1)
		var_22_8:setAnchorPoint(cc.p(0, 0))
		var_22_8:setPosition(var_22_4 * (var_22_0 + var_22_1), 0)

		local var_22_9 = {}

		var_22_9.id = -1
		var_22_9.tipsType = 1

		arg_22_0:addTips(var_22_8, var_22_9)

		var_22_4 = var_22_4 + 1
	end

	local var_22_10 = xyd.tables.gift:mana(arg_22_2)

	if var_22_10 and var_22_10 > 0 then
		local var_22_11 = display.newNode()

		var_22_11:setContentSize(var_22_0, var_22_0)
		xyd.setItemBorder(var_22_11, -2, false, false, var_22_10)
		var_22_11:addTo(arg_22_1)
		var_22_11:setAnchorPoint(cc.p(0, 0))
		var_22_11:setPosition(var_22_4 * (var_22_0 + var_22_1), 0)

		local var_22_12 = {}

		var_22_12.id = -2
		var_22_12.tipsType = 1

		arg_22_0:addTips(var_22_11, var_22_12)

		local var_22_13 = var_22_4 + 1
	end

	return arg_22_1
end

function var_0_0.playMove(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = cc.p(arg_23_1:getChildByName("flower_2"):getPosition())
	local var_23_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1126/flower_2.png")

	var_23_1:addTo(arg_23_1, var_0_7)
	var_23_1:setPosition(var_23_0)
	var_23_1:setName("effect_flower")

	local var_23_2 = cc.p(0, 0)
	local var_23_3 = 0.5
	local var_23_4 = cc.MoveBy:create(var_23_3, cc.p(-300, 100))

	var_23_1:runActionOnce(var_23_4, false, function()
		if arg_23_1 and not tolua.isnull(arg_23_1) then
			local var_24_0 = cc.p(var_23_1:getPosition())

			arg_23_0:showEffect(arg_23_1, var_24_0, nil, arg_23_2)
		end
	end)
end

function var_0_0.showEffect(arg_25_0, arg_25_1, arg_25_2, arg_25_3, arg_25_4)
	if not arg_25_1 or tolua.isnull(arg_25_1) then
		return
	end

	local var_25_0 = var_0_6 .. ".json"
	local var_25_1 = var_0_6 .. ".atlas"
	local var_25_2 = var_0_5.new(var_25_0, var_25_1, 1)

	var_25_2:addTo(arg_25_1)
	var_25_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_25_2:setPosition(arg_25_2)

	local var_25_3 = arg_25_3

	if not var_25_3 then
		var_25_3 = 1

		var_25_2:setLocalZOrder(var_0_7 - 1)
	else
		var_25_3 = var_25_3 + 1

		var_25_2:setLocalZOrder(var_0_7 + 1)

		local var_25_4 = cc.FadeOut:create(0.5)

		arg_25_1:getChildByName("effect_flower"):runActionOnce(var_25_4, true)
	end

	var_25_2:play(function()
		if var_25_3 < 2 then
			arg_25_0:showEffect(arg_25_1, arg_25_2, var_25_3, arg_25_4)
		else
			xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_25_4)
			arg_25_0:createDate(arg_25_1:getParent())
		end
	end, false)
end

return var_0_0
