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
	var_2_0:setPosition(40, 25)

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
	arg_4_1:getChildByName("btn_check"):addTouchEventListener(function(arg_5_0, arg_5_1)
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

				xyd.Backend.get():request(xyd.mid.SELECT_DATE_HERO, var_8_0, function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						arg_6_0:getNewestData()

						arg_6_0.activity.details = arg_9_1
						arg_6_0.selectID = arg_9_1.hero_id

						arg_6_0:createDate(arg_6_1)
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
	local var_10_4 = xyd.tables.misc.activityWeekPresentPartner

	for iter_10_0 = 1, #var_10_4 do
		local var_10_5 = var_10_4[iter_10_0]
		local var_10_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1107/show_hero_item.csb")

		var_10_6:addTo(arg_10_1)

		local var_10_7 = var_10_6:getChildByName("container")
		local var_10_8 = var_10_7:getContentSize()

		var_10_6:setPosition(cc.p(var_10_1, var_10_2 - var_10_8.height + 5))

		local var_10_9 = "windows/activities/1107/hero_bg.png"

		arg_10_0:setHeroCard(var_10_5, var_10_7:getChildByName("hero_card"), var_10_9)

		local var_10_10 = arg_10_0.selectID == var_10_5 and true or false

		var_10_7:getChildByName("hero_bg_select"):setVisible(var_10_10)
		var_10_7:getChildByName("hero_bg"):setVisible(not var_10_10)
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
			var_10_1 = var_10_1 + var_10_8.width
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
			iter_12_1:getChildByName("hero_bg"):setVisible(not var_12_0)
		end
	end
end

function var_0_0.setHeroCard(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = var_0_4:smallCard(var_0_3:modelID(arg_13_1))
	local var_13_1 = xyd.SpriteLoader.new(var_13_0, nil, nil, xyd.DefaultImageType.SMALL_CARD)
	local var_13_2 = size
	local var_13_3 = arg_13_2:getContentSize().height
	local var_13_4 = arg_13_2:getContentSize().width

	if not var_13_1 then
		return
	end

	local var_13_5 = xyd.AssetLoader.get():loadSprite(arg_13_3)

	var_13_5:setPosition(var_13_4 / 2, var_13_3 / 2)
	var_13_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_13_5:setScale(var_13_4 / var_13_5:getWidth() * 1.11, var_13_3 / var_13_5:getHeight() * 1.11)

	local var_13_6 = cc.ClippingNode:create()

	var_13_6:setStencil(var_13_5)
	var_13_6:setInverted(true)
	var_13_6:setAlphaThreshold(0)
	arg_13_2:addChild(var_13_6)
	var_13_6:addChild(var_13_1)
	var_13_1:setPosition(var_13_4 / 2, var_13_3 / 2)
	var_13_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_13_1:setScale(var_13_4 / var_13_1:getWidth(), var_13_3 / var_13_1:getHeight())
	var_13_6:setLocalZOrder(-1)
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
	local var_14_4 = xyd.SpriteLoader.new(var_14_3, nil, nil, xyd.DefaultImageType.HOME_CARD)

	var_14_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_14_4:addTo(var_14_2)

	local var_14_5 = var_14_2:getContentSize()

	var_14_4:setPosition(cc.p(var_14_5.width / 2, var_14_5.height / 2 + 25))
	var_14_4:setScale(0.55)

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

	for iter_14_0 = 1, var_14_6 do
		local var_14_10 = xyd.AssetLoader.get():loadSprite("windows/activities/1107/star.png")

		var_14_10:addTo(var_14_8)
		var_14_10:setAnchorPoint(cc.p(0, 0))
		var_14_10:setPosition(cc.p(var_14_9, 0))

		var_14_9 = var_14_9 + var_14_10:getContentSize().width
	end

	var_14_8:setContentSize(var_14_9, 33)
end

function var_0_0.createDate(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_1:getChildByName("second_panel")

	var_15_0:setVisible(true)
	arg_15_1:getChildByName("first_panel"):setVisible(false)
	arg_15_0:updateDialog(var_15_0)
	arg_15_0:updateDayCount(var_15_0)
	arg_15_0:updateGiftList(var_15_0)
	var_15_0:getChildByName("btn_change_hero"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			local var_16_0 = xyd.tables.misc.activityWeekRechooseCost
			local var_16_1 = string.format(var_0_1:translation("NEW_DATE_TIPS_2"), var_16_0)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_16_1, function()
				if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).crystal < var_16_0 then
					local var_17_0 = var_0_1:translation("ZUANSHI_ABSENCE")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_17_0, function()
						local var_18_0 = {}

						var_18_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_18_0)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					xyd.Backend.get():request(xyd.mid.CHANGE_DATE_HERO, {}, function(arg_19_0, arg_19_1)
						if arg_19_0 == xyd.error.OK then
							arg_15_0:getNewestData()

							arg_15_0.activity.details.hero_id = 0

							arg_15_0:createSelect(arg_15_1)
						end
					end)
				end
			end, nil, 0, xyd.ColorMode.ACTIVITY)
		end
	end)
	var_15_0:getChildByName("btn_send_gift"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended then
			local var_20_0 = arg_15_0.activity.details.dating_day + 1

			arg_15_0.activitiesModel:getActivityReward(arg_15_0.activity.table_id, var_20_0, function(arg_21_0, arg_21_1)
				if arg_21_0 == xyd.error.OK then
					arg_15_0:getNewestData()

					arg_15_0.activity.details = arg_21_1.base_info

					arg_15_0:playMove(var_15_0, arg_21_1.awards)
				end
			end)
		end
	end)
	var_15_0:getChildByName("btn_show_gifts"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended then
			local var_22_0 = {
				details = arg_15_0.activity.details
			}

			xyd.WindowManager.get():openWindow("new_date_gifts", var_22_0)
		end
	end)

	if arg_15_0.activity.details.is_login == 1 and arg_15_0.activity.details.dating_day == 7 then
		var_15_0:getChildByName("btn_change_hero"):setVisible(false)
	end
end

function var_0_0.updateDialog(arg_23_0, arg_23_1)
	if not (arg_23_0.activity.details.is_login == 1 and true or false) then
		arg_23_1:getChildByName("dialog_bg"):setVisible(false)
		arg_23_1:getChildByName("text_dialog"):setVisible(false)

		return
	end

	arg_23_1:getChildByName("dialog_bg"):setVisible(true)
	arg_23_1:getChildByName("text_dialog"):setVisible(true)

	local var_23_0 = var_0_3:name(arg_23_0.selectID)
	local var_23_1 = string.format(var_0_1:translation("NEW_DATE_DIALOG"), var_23_0)

	arg_23_1:getChildByName("text_dialog"):setString(var_23_1)
end

function var_0_0.updateDayCount(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_0.activity.details.dating_day
	local var_24_1 = arg_24_1:getChildByName("day_count")

	var_24_1:removeAllChildren()

	local var_24_2 = xyd.tables.misc.activityWeekDay
	local var_24_3 = 0

	for iter_24_0 = 1, var_24_2 do
		local var_24_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1107/day_count.csb")

		var_24_4:addTo(var_24_1)
		var_24_4:setPosition(cc.p(var_24_3, 0))

		local var_24_5 = var_24_4:getChildByName("container")
		local var_24_6 = false

		if iter_24_0 <= var_24_0 then
			local var_24_7 = iter_24_0 .. var_0_1:translation("UNIT_DAY")

			var_24_5:getChildByName("text_day"):setString(var_24_7)

			var_24_6 = true
		end

		var_24_5:getChildByName("small_love_1"):setVisible(var_24_6)
		var_24_5:getChildByName("small_love_2"):setVisible(not var_24_6)
		var_24_5:getChildByName("text_day"):setVisible(var_24_6)

		var_24_3 = var_24_3 + var_24_5:getContentSize().width - 2
	end
end

function var_0_0.updateGiftList(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0.activity.details.is_login == 1 and true or false

	arg_25_1:getChildByName("btn_send_gift"):setVisible(not var_25_0)
	arg_25_1:getChildByName("text_is_send"):setVisible(var_25_0)
	arg_25_1:getChildByName("have_get_gift"):setVisible(var_25_0)

	local var_25_1 = arg_25_1:getChildByName("gift_list")

	var_25_1:removeAllChildren()

	local var_25_2 = arg_25_1:getContentSize()
	local var_25_3 = 0

	if var_25_0 then
		var_25_3 = arg_25_0.activity.details.dating_day
	else
		var_25_3 = arg_25_0.activity.details.dating_day + 1
	end

	if var_25_3 == 7 then
		local var_25_4 = display.newNode()
		local var_25_5 = var_25_1:getContentSize().height

		var_25_4:setContentSize(var_25_5, var_25_5)
		xyd.setAvatarBorder(arg_25_0.selectID, var_25_4, 1, xyd.tables.hero:initialStar(arg_25_0.selectID))
		var_25_4:addTo(var_25_1)

		local var_25_6 = {
			id = arg_25_0.selectID,
			lev = xyd.tables.item:level(arg_25_0.selectID),
			name = xyd.tables.item:name(arg_25_0.selectID)
		}
		local var_25_7 = xyd.tables.item:type(arg_25_0.selectID)

		var_25_6.tipsType = 0
		var_25_6.desc1 = xyd.tables.hero:getDes(arg_25_0.selectID)

		arg_25_0:addTips(var_25_4, var_25_6)
	else
		local var_25_8 = xyd.tables.activityWeekNew:gift(var_25_3)

		arg_25_0:rewardFormat(var_25_1, var_25_8, nil, 1)
	end
end

function var_0_0.playMove(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = cc.p(arg_26_1:getChildByName("flower_2"):getPosition())
	local var_26_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1107/flower_2.png")

	var_26_1:addTo(arg_26_1, var_0_7)
	var_26_1:setPosition(var_26_0)
	var_26_1:setName("effect_flower")

	local var_26_2 = cc.p(255.37, 138)
	local var_26_3 = cc.p(177.37, 242)
	local var_26_4 = 0.5
	local var_26_5 = cc.CircleBy:create(var_26_4, var_26_2, var_26_0, 0.4166666666666667 * math.pi, false)

	var_26_1:runActionOnce(var_26_5, false, function()
		if arg_26_1 and not tolua.isnull(arg_26_1) then
			local var_27_0 = cc.p(var_26_1:getPosition())

			arg_26_0:showEffect(arg_26_1, var_27_0, nil, arg_26_2)
		end
	end)
end

function var_0_0.showEffect(arg_28_0, arg_28_1, arg_28_2, arg_28_3, arg_28_4)
	if not arg_28_1 or tolua.isnull(arg_28_1) then
		return
	end

	local var_28_0 = var_0_6 .. ".json"
	local var_28_1 = var_0_6 .. ".atlas"
	local var_28_2 = var_0_5.new(var_28_0, var_28_1, 1)

	var_28_2:addTo(arg_28_1)
	var_28_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_28_2:setPosition(arg_28_2)

	local var_28_3 = arg_28_3

	if not var_28_3 then
		var_28_3 = 1

		var_28_2:setLocalZOrder(var_0_7 - 1)
	else
		var_28_3 = var_28_3 + 1

		var_28_2:setLocalZOrder(var_0_7 + 1)

		local var_28_4 = cc.FadeOut:create(0.5)

		arg_28_1:getChildByName("effect_flower"):runActionOnce(var_28_4, true)
	end

	var_28_2:play(function()
		if var_28_3 < 2 then
			arg_28_0:showEffect(arg_28_1, arg_28_2, var_28_3, arg_28_4)
		else
			xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_28_4)
			arg_28_0:createDate(arg_28_1:getParent())
		end
	end, false)
end

return var_0_0
