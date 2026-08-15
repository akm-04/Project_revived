local var_0_0 = class("TwoYearsMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.twoYearsCampaign
local var_0_2 = xyd.tables.twoYearsCampaignAward
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.translation
local var_0_5 = import("framework.scheduler")
local var_0_6 = 1
local var_0_7 = 2
local var_0_8 = xyd.tables.misc.twoYearsRewardMaxLev
local var_0_9 = "skeletons/ui_effect/common_effect_spin/common_effect_spin"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.twoYearsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS)
	arg_1_0.starNum = arg_1_0.twoYearsModel.baseInfo.star_num or 0
	arg_1_0.starLev = arg_1_0.twoYearsModel.baseInfo.star_award_id + 1 or 1

	if arg_1_0.starLev > var_0_8 then
		arg_1_0.noBonus = true
		arg_1_0.starLev = var_0_8
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
	arg_3_0:createMap()
	arg_3_0:registerButtons()
end

function var_0_0.createBonusEffect(arg_4_0)
	if arg_4_0.effect and not tolua.isnull(arg_4_0.effect) then
		arg_4_0.effect:removeFromParent()

		arg_4_0.effect = nil
	end

	local var_4_0 = var_0_9 .. ".json"
	local var_4_1 = var_0_9 .. ".atlas"

	arg_4_0.effect = var_0_3.new(var_4_0, var_4_1, 1)

	arg_4_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_4_0.effect:addTo(arg_4_0:nodeByName("box"))
	arg_4_0.effect:setPosition(cc.p(arg_4_0:nodeByName("box"):getContentSize().width / 2, arg_4_0:nodeByName("box"):getContentSize().height / 2))
	arg_4_0.effect:setLocalZOrder(-10)
	arg_4_0.effect:setScale(0.5)
	arg_4_0.effect:setName("effect")
	arg_4_0.effect:play(nil, true)
end

function var_0_0.AliveNum(arg_5_0)
	local var_5_0 = arg_5_0.twoYearsModel.invitedList
	local var_5_1 = #var_5_0

	for iter_5_0, iter_5_1 in pairs(var_5_0) do
		if iter_5_1.hp == 0 then
			var_5_1 = var_5_1 - 1
		end
	end

	return var_5_1
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("total_players"):setString(string.format(var_0_4:translation("ANNI2_TIPS_TXT2"), arg_6_0:AliveNum()))
	arg_6_0:updateStarBonus(arg_6_0.starNum, arg_6_0.starLev)

	local function var_6_0()
		local var_7_0 = xyd.ServerTime.get():getServerTime()
		local var_7_1 = arg_6_0.twoYearsModel.activity.end_time - var_7_0

		if var_7_1 < 0 then
			var_7_1 = 0
		end

		arg_6_0:nodeByName("rest_time"):setString(string.format(var_0_4:translation("ANNI2_TIPS_TXT1"), xyd.secondsToString1(var_7_1)))

		local var_7_2 = xyd.tables.misc.twoYearsRefreshTime - (var_7_0 - arg_6_0.twoYearsModel.baseInfo.refresh_time)

		if var_7_2 <= 0 then
			arg_6_0.twoYearsModel:getAnniFightHeroList({}, function()
				arg_6_0.twoYearsModel.baseInfo.refresh_time = var_7_0

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.TWO_YEARS_HEROES_REFRESH,
					params = {}
				})
			end)
		end

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.TWO_YEARS_ITEM_TIME,
			params = {
				refresh_rest_time = var_7_2
			}
		})
	end

	var_6_0()

	arg_6_0.handle = var_0_5.scheduleGlobal(var_6_0, 0.3)
end

function var_0_0.updateStarBonus(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = var_0_2:stars()

	arg_9_0:nodeByName("bonus_label"):setString(string.format(var_0_4:translation("ANNI2_TIPS_TXT9"), arg_9_2))
	arg_9_0:nodeByName("star_nums"):setString(tostring(arg_9_0.starNum) .. "/" .. var_9_0[arg_9_0.starLev])
	arg_9_0:nodeByName("invite_concnent_process_bar"):setPercent(arg_9_0.starNum / var_9_0[arg_9_0.starLev] * 100)

	if arg_9_0.starNum >= var_0_2:stars()[arg_9_0.starLev] and not arg_9_0.noBonus then
		arg_9_0:createBonusEffect()
	elseif arg_9_0.effect and not tolua.isnull(arg_9_0.effect) then
		arg_9_0.effect:setVisible(false)
	end
end

function var_0_0.createMap(arg_10_0)
	local var_10_0 = display.newScale9Sprite("windows/two_years/map_scene.png")

	var_10_0:setAnchorPoint(0, 0)

	arg_10_0.mapNode = cc.Node:create()

	arg_10_0.mapNode:addChild(var_10_0)

	local var_10_1 = cc.rect(0, 0, arg_10_0:nodeByName("map_container"):getWidth(), arg_10_0:nodeByName("map_container"):getHeight())

	cc.ui.UIScrollView.new({
		viewRect = var_10_1
	}):addScrollNode(arg_10_0.mapNode):setDirection(cc.ui.UIScrollView.DIRECTION_HORIZONTAL):onScroll(handler(arg_10_0, arg_10_0.scrollListener)):addTo(arg_10_0:nodeByName("map_container")):setBounceable(false)

	arg_10_0.arrow = xyd.AssetLoader.get():loadSprite("images/down_arrow.png")

	arg_10_0.arrow:setTouchEnabled(false)
	arg_10_0.mapNode:addChild(arg_10_0.arrow)
	arg_10_0:displayMapNodesOnContainer()
end

function var_0_0.displayMapNodesOnContainer(arg_11_0)
	local var_11_0 = arg_11_0.twoYearsModel.campaignList
	local var_11_1 = arg_11_0.twoYearsModel.openCampaignID
	local var_11_2 = false

	for iter_11_0 = 1, #var_11_0 do
		local var_11_3 = var_11_0[iter_11_0]
		local var_11_4 = var_11_3.campaign_id
		local var_11_5 = var_0_1:posx(var_11_4)
		local var_11_6 = var_0_1:posy(var_11_4)
		local var_11_7 = var_0_1:icon(var_11_4)
		local var_11_8 = var_0_1:campaignType(var_11_4)
		local var_11_9 = cc.Node:create()
		local var_11_10
		local var_11_11 = cc.Node:create()

		var_11_9:setTouchEnabled(true)
		var_11_9:setTouchSwallowEnabled(false)

		local function var_11_12(arg_12_0)
			if arg_12_0.name == "began" then
				arg_11_0.beganX = arg_12_0.x
				arg_11_0.beganY = arg_12_0.y
				arg_11_0.movingMap = false

				return true
			elseif arg_12_0.name == "moved" then
				if math.abs(arg_12_0.y - arg_11_0.beganY) + math.abs(arg_12_0.x - arg_11_0.beganX) > 20 then
					arg_11_0.movingMap = true
				end

				return true
			end

			return false
		end

		local function var_11_13(arg_13_0)
			if arg_13_0.name == "began" or arg_13_0.name == "moved" then
				return var_11_12(arg_13_0)
			elseif arg_13_0.name == "ended" and not arg_11_0.movingMap then
				local var_13_0 = {
					campaign_id = var_11_4
				}

				arg_11_0.twoYearsModel:getPreFightDetails(var_13_0, function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						local var_14_0 = arg_14_1.monster_infos or {}
						local var_14_1 = {}

						var_14_1.showEnemy = true
						var_14_1.campaignID = var_11_4
						var_14_1.campaignType = xyd.CampaignType.TWO_YEARS
						var_14_1.type = xyd.SelectTeamType.TWO_YEARS
						var_14_1.noPreset = true
						var_14_1.enemyHeroes, var_14_1.enemyPets = arg_11_0.twoYearsModel:initEnemies(var_14_0)

						xyd.WindowManager.get():openWindow("battle_select_team", var_14_1)
					end
				end)

				return false
			end
		end

		local function var_11_14(arg_15_0)
			if arg_15_0.name == "began" or arg_15_0.name == "moved" then
				return var_11_12(arg_15_0)
			elseif arg_15_0.name == "ended" and not arg_11_0.movingMap then
				local var_15_0 = var_0_4:translation("ANNI2_TIPS_TXT25")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_15_0
				})

				return false
			end
		end

		local function var_11_15(arg_16_0)
			if arg_16_0.name == "began" or arg_16_0.name == "moved" then
				return var_11_12(arg_16_0)
			elseif arg_16_0.name == "ended" and not arg_11_0.movingMap then
				local var_16_0 = var_0_4:translation("ANNI2_TIPS_TXT24")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_16_0
				})

				return false
			end
		end

		if var_11_8 == var_0_6 then
			if var_11_3.is_finish == 0 and not var_11_2 then
				var_11_10 = xyd.AssetLoader:get():loadSprite("images/xiaoguan_fight.png")

				var_11_10:setAnchorPoint(0.5, 0.25)
				var_11_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, var_11_13)
			elseif var_11_3.is_finish == 1 then
				var_11_10 = xyd.AssetLoader:get():loadSprite("images/xiaoguan_unlock.png")

				var_11_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, var_11_15)
			else
				var_11_10 = xyd.AssetLoader:get():loadSprite("images/xiaoguan_lock.png")

				var_11_10:setAnchorPoint(0.5, 0.25)
				var_11_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, var_11_14)
			end
		end

		if var_11_8 == var_0_7 then
			if var_11_3.is_finish == 0 and not var_11_2 then
				var_11_10 = xyd.AssetLoader:get():loadSprite(var_11_7)

				var_11_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, var_11_13)
			else
				var_11_10 = display.newFilteredSprite(var_11_7, "GRAY", {
					0.2,
					0.3,
					0.5,
					0.1
				})

				if var_11_2 then
					var_11_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, var_11_14)
				else
					var_11_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, var_11_15)
				end
			end

			if var_11_3.star > 0 then
				xyd.addCampaignStar(var_11_11, var_11_3.star)
			end

			var_11_9:setScale(0.8)
		end

		if var_11_10 ~= nil then
			var_11_9:addChild(var_11_10)
			var_11_9:addChild(var_11_11)
			var_11_11:setPosition(0, -var_11_10:getContentSize().height / 2)
			var_11_11:setAnchorPoint(cc.p(0.5, 0))
			arg_11_0.mapNode:addChild(var_11_9)
			var_11_9:setPosition(var_11_5, var_11_6)
		end

		if var_11_4 == var_11_1 then
			var_11_2 = true

			local var_11_16, var_11_17 = var_11_9:getPosition()

			arg_11_0.arrow:setPosition(var_11_16, var_11_17 + 70)
			arg_11_0.arrow:setVisible(true)
			arg_11_0.arrow:setLocalZOrder(100)

			local var_11_18 = transition.sequence({
				cc.MoveTo:create(1, cc.p(var_11_16, var_11_17 + 50)),
				cc.MoveTo:create(1, cc.p(var_11_16, var_11_17 + 70))
			})
			local var_11_19 = cc.RepeatForever:create(var_11_18)

			arg_11_0.arrow:runAction(var_11_19)
		end
	end
end

function var_0_0.registerButtons(arg_17_0)
	arg_17_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended then
			local var_18_0 = {}

			var_18_0.title_name = "ANNI2_RULE_TITLE"
			var_18_0.rule = "ANNI2_RULE_TEXT"

			xyd.WindowManager.get():openWindow("text_rule", var_18_0)
		end
	end)
	arg_17_0:nodeByName("invite_btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.ended then
			arg_17_0.twoYearsModel:getAnniFightHeroList({}, function(arg_20_0, arg_20_1)
				xyd.WindowManager.get():openWindow("two_years_invite")
			end)
		end
	end)
	arg_17_0:nodeByName("world_rank_btn"):addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.ended then
			arg_17_0.twoYearsModel:getAnniFightRankList({}, function(arg_22_0, arg_22_1)
				local var_22_0 = {
					rank_list = arg_22_1.rank_list,
					self_rank = arg_22_1.self_rank
				}

				xyd.WindowManager.get():openWindow("two_years_rank", var_22_0)
			end)
		end
	end)
	arg_17_0:nodeByName("box"):setTouchEnabled(true)
	arg_17_0:nodeByName("box"):setTouchSwallowEnabled(false)
	arg_17_0:nodeByName("box"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
		if arg_23_0.name == "ended" then
			if arg_17_0.noBonus then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_4:translation("ANNI2_TIPS_TXT33")
				})
			elseif arg_17_0.starNum >= var_0_2:stars()[arg_17_0.starLev] then
				arg_17_0.twoYearsModel:getAnniFightStarAward({}, function()
					arg_17_0.starNum = arg_17_0.twoYearsModel.baseInfo.star_num or 0
					arg_17_0.starLev = arg_17_0.twoYearsModel.baseInfo.star_award_id + 1 or 1

					if arg_17_0.starLev > var_0_8 then
						arg_17_0.starLev = var_0_8
						arg_17_0.noBonus = true
					end

					arg_17_0:updateStarBonus(arg_17_0.starNum, arg_17_0.starLev)
				end)
			else
				xyd.WindowManager.get():openWindow("two_years_bonus")
			end
		end

		return true
	end)
end

function var_0_0.scrollListener(arg_25_0, arg_25_1)
	return
end

function var_0_0.willClose(arg_26_0)
	if arg_26_0.handle then
		var_0_5.unscheduleGlobal(arg_26_0.handle)

		arg_26_0.handle = nil
	end
end

return var_0_0
