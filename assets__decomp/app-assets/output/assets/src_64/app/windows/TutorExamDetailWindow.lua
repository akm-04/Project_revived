local var_0_0 = class("TutorExamDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityTutorCampaign
local var_0_3 = import("app.model.Hero")
local var_0_4 = ngx.ctx.battle.getRequire("FighterModel")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.tutor = xyd.ModelManager.get():loadModel(xyd.ModelType.TUTOR)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.data = arg_1_2.data
	arg_1_0.mode_ = arg_1_2.mode
	arg_1_0.enermyHeros = {}
	arg_1_0.battleID = var_0_2:fightId(arg_1_0.data.campaign_id, arg_1_0.mode_)
	arg_1_0.rentHeroes = arg_1_0.tutor:getHeros(arg_1_0.data.campaign_id)

	table.sort(arg_1_0.rentHeroes, function(arg_2_0, arg_2_1)
		return arg_2_0.useTime < arg_2_1.useTime
	end)
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0.tutor:setMode(arg_3_0.mode_)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("select_hero_text"):setString(var_0_1:translation("CAN_SELECT_HERO_TEXT"))
	arg_5_0:nodeByName("title_txt"):setString(var_0_2:campaignName(arg_5_0.data.campaign_id))
	arg_5_0:nodeByName("enermy_text"):setString(var_0_1:translation("NEW_MAP_ENEMY_TXT"))
	arg_5_0:nodeByName("start_text"):setString(var_0_1:translation("TUTOR_START_TEXT"))
	arg_5_0:nodeByName("reset_hero_text"):setString(var_0_1:translation("RESET_HERO_TEXT"))

	arg_5_0.scroll = arg_5_0:nodeByName("scroll")

	local var_5_0 = arg_5_0.scroll:getContentSize()

	arg_5_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_0.width, var_5_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_5_0.scroll):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.scrollList:setDelegate(handler(arg_5_0, arg_5_0.scrollListDelegate))
	arg_5_0.scrollList:reload()
	arg_5_0:setButtonClick()
	arg_5_0:updateBtnState()
	arg_5_0:nodeByName("book"):setTouchEnabled(true)
	arg_5_0:nodeByName("book"):setTouchSwallowEnabled(false)
	arg_5_0:nodeByName("book"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			arg_5_0:nodeByName("book"):setScale(0.9)

			return true
		elseif arg_6_0.name == "moved" then
			return true
		elseif arg_6_0.name == "ended" then
			arg_5_0:nodeByName("book"):setScale(1)

			if arg_5_0.backpack:getItemNumByID(xyd.tables.misc:getValue("activity_tutor_senior_book_item")) > 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TUTOR_SENIOR_BOOK_ITEM_TIP")
				})

				return
			end

			local var_6_0 = {
				chargeState = xyd.ChargeState.giftbag
			}

			xyd.WindowManager.get():openWindow("vip_recharge", var_6_0)
		end
	end)
	arg_5_0.tutor:updateIcon(arg_5_0:nodeByName("book"))

	local var_5_1 = var_0_2:campaignText(arg_5_0.data.campaign_id)
	local var_5_2 = xyd.createMultiColorTxt(var_5_1, cc.c4b(91, 102, 111, 255), 22, false)

	var_5_2:setAnchorPoint(cc.p(0, 0.5))
	var_5_2:addTo(arg_5_0:nodeByName("desc_pos"))
	arg_5_0:playActivityGuide()
end

function var_0_0.playActivityGuide(arg_7_0)
	local var_7_0 = 1184001
	local var_7_1 = xyd.ServerTime.get():getServerTime()
	local var_7_2 = {
		playerID = arg_7_0.selfPlayer.playerID,
		name = "activity_guide" .. tostring(var_7_0),
		state = tostring(var_7_1)
	}

	if (tonumber(xyd.db.stateVariable:getState(var_7_2.playerID, var_7_2.name)) or 0) >= arg_7_0.activitiesModel:getActivityInfo(xyd.Activities.Tutor).start_time then
		return
	end

	xyd.db.stateVariable:setState(var_7_2)

	local var_7_3 = arg_7_0:nodeByName("book")

	xyd.WindowManager.get():openWindow("guide_activity")

	local var_7_4 = {
		600,
		520
	}
	local var_7_5 = false
	local var_7_6 = xyd.WindowManager.get():getWindow("guide_activity")

	var_7_6:addNode()

	local var_7_7 = cc.p(935, 478)
	local var_7_8 = xyd.tables.guideActivity:desc(1184001)

	var_7_6:setStencil(var_7_8, 100, 50, var_7_7.x, var_7_7.y, 0, {
		position = var_7_4,
		right = var_7_5
	})
end

function var_0_0.startBattle(arg_8_0)
	local var_8_0 = arg_8_0.battleID
	local var_8_1 = xyd.tables.battle:campaignType(var_8_0)
	local var_8_2 = {
		type = xyd.SelectTeamType.TUTOR,
		battleID = var_8_0,
		campaignType = xyd.CampaignType.TUTOR,
		campaignID = arg_8_0.data.campaign_id
	}

	xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_8_2)
end

function var_0_0.updateBtnState(arg_9_0)
	if arg_9_0.data.reset_hero_times >= xyd.tables.misc:getValue("activity_tutor_campaign_reset_limit") then
		arg_9_0:nodeByName("reset_hero_btn"):setBright(false)
		arg_9_0:nodeByName("reset_hero_btn"):setTouchEnabled(false)
	end
end

function var_0_0.setButtonClick(arg_10_0)
	arg_10_0:nodeByName("start_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_10_0:startBattle()
		end
	end)
	arg_10_0:nodeByName("close"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("close"), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_10_0)
		end
	end)
	arg_10_0:nodeByName("reset_hero_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_13_0 = xyd.tables.misc:getValue("activity_tutor_campaign_reset_crystal")

			if var_13_0 > arg_10_0.selfPlayer.crystal then
				local var_13_1 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_13_1, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end, nil, nil, arg_10_0.colorMode)
			else
				local var_13_2 = string.format(var_0_1:translation("TUTOR_COST_TO_UPDATE_GROUP"), var_13_0)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_13_2, function()
					local var_15_0 = {
						campaign_id = arg_10_0.data.campaign_id
					}

					arg_10_0.tutor:tutorResetHero(var_15_0, function(arg_16_0, arg_16_1)
						if arg_16_0 == xyd.error.OK then
							if arg_16_1 and arg_16_1.campaign_info then
								arg_10_0.data = arg_16_1.campaign_info
								arg_10_0.rentHeroes = arg_10_0.tutor:getHeros(arg_10_0.data.campaign_id)
							end

							arg_10_0:updateBtnState()
							arg_10_0.scrollList:reload()
						end
					end)
				end, nil, nil, arg_10_0.colorMode)
			end
		end
	end)

	local var_10_0 = arg_10_0.data.campaign_id
	local var_10_1 = var_0_2:monsterDisplay(var_10_0)
	local var_10_2 = var_0_2:monsterStar(var_10_0)
	local var_10_3 = var_0_2:monsterQuality(var_10_0)
	local var_10_4 = var_0_2:monsterLevel(var_10_0)

	for iter_10_0 = 1, #var_10_1 do
		local var_10_5 = {}
		local var_10_6 = cc.Node:create()

		var_10_5.isBoss = false

		var_10_6:setContentSize(76, 76)
		xyd.setAvatarBorderNewUI(var_10_1[iter_10_0], var_10_6, var_10_3[iter_10_0], var_10_2[iter_10_0])
		arg_10_0:nodeByName("enermy_scroll"):addChild(var_10_6)
		var_10_6:setPosition(iter_10_0 * 80 - 80, 0)

		var_10_5.id = var_10_1[iter_10_0]
		var_10_5.lev = var_10_4[iter_10_0]
		var_10_5.quality = var_10_3[iter_10_0]
		var_10_5.name = xyd.tables.hero:name(var_10_1[iter_10_0])
		var_10_5.desc = xyd.tables.hero:getDes(var_10_1[iter_10_0])
		var_10_5.isHero = true

		local var_10_7, var_10_8 = var_10_6:getPosition()

		var_10_6:setTouchEnabled(true)
		var_10_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
			if arg_17_0.name == "began" then
				local var_17_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_17_1 = cc.p(0, 0)

				if not var_17_0 then
					local var_17_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_10_5)

					xyd.adaptToWorldPosition(var_10_6, var_17_2)
				end

				return true
			elseif arg_17_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_17_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end

	local var_10_9 = var_0_2:challengeTimes(var_10_0) - arg_10_0.data.challenge_times

	arg_10_0:nodeByName("remain_time_txt"):setString(var_10_9)
	arg_10_0:nodeByName("remain_time_text"):setString(var_0_1:translation("LEFT_TIMES"))

	for iter_10_1 = 1, 3 do
		if iter_10_1 <= arg_10_0.data.star then
			arg_10_0:nodeByName("star" .. iter_10_1):setVisible(true)
			arg_10_0:nodeByName("star_gray" .. iter_10_1):setVisible(false)
		else
			arg_10_0:nodeByName("star" .. iter_10_1):setVisible(false)
			arg_10_0:nodeByName("star_gray" .. iter_10_1):setVisible(true)
		end
	end

	local var_10_10 = var_0_2:campaignDisplay(arg_10_0.data.campaign_id)
	local var_10_11 = var_0_3.new()

	var_10_11:populateWithTableID(var_10_10)

	local var_10_12 = xyd.tables.hero:modelID(var_10_10)
	local var_10_13 = xyd.tables.model:creatsUiScale(var_10_12) * 1.5
	local var_10_14 = var_0_4.new(var_10_11, var_10_13)

	var_10_14:addTo(arg_10_0:nodeByName("card_container"))
	var_10_14:setPosition(cc.p(arg_10_0:nodeByName("card_container"):getContentSize().width / 2, 0))
	var_10_14:getHeroAnimation():idle(true)
end

function var_0_0.scrollListDelegate(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	if cc.ui.UIListView.COUNT_TAG == arg_18_2 then
		return #arg_18_0.rentHeroes
	elseif cc.ui.UIListView.CELL_TAG == arg_18_2 then
		local var_18_0
		local var_18_1 = arg_18_0.scrollList:dequeueItem()

		if not var_18_1 then
			var_18_1 = arg_18_0.scrollList:newItem()
		else
			var_18_1:removeAllChildren(true)
		end

		local var_18_2 = arg_18_0:createListContent(arg_18_0.rentHeroes[arg_18_3])
		local var_18_3 = var_18_2:getWidth()
		local var_18_4 = var_18_2:getHeight()

		var_18_1:setItemSize(var_18_3 + 4, 90)
		var_18_2:setPosition(cc.p(2, 0))
		var_18_1:addContent(var_18_2)

		return var_18_1
	end
end

function var_0_0.createListContent(arg_19_0, arg_19_1)
	heroId = arg_19_1:getFirstTableID()

	local var_19_0 = arg_19_0.data.rent_heroes[tostring(heroId)]
	local var_19_1 = display.newNode()

	var_19_1:setContentSize(76, 76)
	xyd.setAvatarBorderNewUI(arg_19_1, var_19_1)

	if var_19_0 >= xyd.tables.misc:getValue("activity_tutor_partner_used_nums") then
		xyd.GrayNode(var_19_1)
	end

	var_19_1:setTouchEnabled(true)
	var_19_1:setTouchSwallowEnabled(false)
	var_19_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		if arg_20_0.name == "began" then
			return true
		elseif arg_20_0.name == "moved" then
			return true
		elseif arg_20_0.name == "ended" and not arg_19_0.scrollViewMoved_ then
			local var_20_0 = {
				heros = {
					arg_19_1
				}
			}

			var_20_0.current = 1
			var_20_0.showType = 2

			xyd.WindowManager.get():openWindow("tujian_herodetail", var_20_0)
		end
	end)

	return var_19_1
end

function var_0_0.scrollListener(arg_21_0, arg_21_1)
	if arg_21_1.name == "began" then
		arg_21_0.scrollViewMoved_ = false
		arg_21_0.prevY_ = arg_21_1.y
	elseif arg_21_1.name == "moved" and 5 <= math.abs(arg_21_1.y - arg_21_0.prevY_) then
		arg_21_0.scrollViewMoved_ = true
	end
end

return var_0_0
