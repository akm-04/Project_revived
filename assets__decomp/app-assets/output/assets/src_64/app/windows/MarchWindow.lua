local var_0_0 = class("MarchScrollView", cc.ui.UIScrollView)
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = 1.5
local var_0_3 = 9
local var_0_4 = import("app.model.Hero")
local var_0_5 = xyd.tables.translation
local var_0_6 = require("framework.scheduler")
local var_0_7 = {}

var_0_7.open1 = "skeletons/ui_effect/common_effect_boxopen1/common_effect_boxopen1"
var_0_7.open2 = "skeletons/ui_effect/common_effect_boxopen2/common_effect_boxopen2"
var_0_7.open3 = "skeletons/ui_effect/common_effect_boxopen3/common_effect_boxopen3"
var_0_7.shake1 = "skeletons/ui_effect/common_effect_boxshake1/common_effect_boxshake1"
var_0_7.shake2 = "skeletons/ui_effect/common_effect_boxshake2/common_effect_boxshake2"
var_0_7.shake3 = "skeletons/ui_effect/common_effect_boxshake3/common_effect_boxshake3"

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.getScrollNodeRect(arg_2_0)
	local var_2_0 = cc.ui.UIScrollView.getScrollNodeRect(arg_2_0)

	var_2_0.x = var_2_0.x + arg_2_0.offsetX
	var_2_0.width = arg_2_0.scrollWidth

	return var_2_0
end

function var_0_0.twiningScroll(arg_3_0)
	if arg_3_0:isSideShow() then
		return false
	end

	if math.abs(arg_3_0.speed.x) < 5 and math.abs(arg_3_0.speed.y) < 5 then
		return false
	end

	local var_3_0, var_3_1 = arg_3_0:moveXY(0, 0, arg_3_0.speed.x * 15, arg_3_0.speed.y * 15)
	local var_3_2 = arg_3_0:getScrollNodeRect()
	local var_3_3 = arg_3_0:getViewRectInWorldSpace()

	if var_3_3.x <= var_3_2.x then
		return false
	end

	if var_3_2.x - var_3_3.x <= var_3_3.width - var_3_2.width then
		return false
	end

	if var_3_0 > 0 then
		var_3_0 = math.min(var_3_0, var_3_3.x - var_3_2.x)
	end

	if var_3_0 < 0 then
		local var_3_4 = math.max(var_3_0, var_3_3.width - var_3_2.width - (var_3_2.x - var_3_3.x))
	end
end

function var_0_0.setScrollWidth(arg_4_0, arg_4_1)
	arg_4_0.scrollWidth = arg_4_1
end

function var_0_0.setScrollHeight(arg_5_0, arg_5_1)
	arg_5_0.scrollHeight = arg_5_1
end

function var_0_0.setRectOffsetX(arg_6_0, arg_6_1)
	arg_6_0.offsetX = arg_6_1
end

local var_0_8 = class("MarchWindow", import("app.common.ui.BaseWindow"))

var_0_8.MAP_PANEL = "map_container"
var_0_8.ARROW_PANEL = "arrow_container"
var_0_8.RULE = "rule"
var_0_8.REWARD = "reward_button"
var_0_8.RESTART = "restart_button"
var_0_8.ADVANCED = "advanced_button"
var_0_8.TEXT_REMAIN = "text_remain_val"
var_0_8.TEXT_REMAIN_LABEL = "text_remain_label"

function var_0_8.ctor(arg_7_0, arg_7_1, arg_7_2)
	arg_7_0.super.ctor(arg_7_0, arg_7_1, arg_7_2)

	arg_7_0.campaignNum = 15
end

function var_0_8.willOpen(arg_8_0, arg_8_1)
	local var_8_0 = {
		show_rule = true
	}

	arg_8_0:addTopSidebar(var_8_0)

	arg_8_0.mapPanel = arg_8_0:nodeByName(var_0_8.MAP_PANEL)
	arg_8_0.arrowPanel = arg_8_0:nodeByName(var_0_8.ARROW_PANEL)
	arg_8_0.rule_button = arg_8_0:nodeByName("top_sidebar"):nodeByName(var_0_8.RULE)
	arg_8_0.reward_button = arg_8_0:nodeByName(var_0_8.REWARD)
	arg_8_0.restart_button = arg_8_0:nodeByName(var_0_8.RESTART)
	arg_8_0.advanced_button = arg_8_0:nodeByName(var_0_8.ADVANCED)
	arg_8_0.text_remain = arg_8_0:nodeByName(var_0_8.TEXT_REMAIN)
	arg_8_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_8_0.marchModel = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)
	arg_8_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_8_0.clippingNode = display.newClippingRegionNode()

	arg_8_0.clippingNode:setClippingRegion(cc.rect(0, 0, arg_8_0.mapPanel:getContentSize().width, arg_8_0.mapPanel:getContentSize().height))
	arg_8_0.mapPanel:addChild(arg_8_0.clippingNode)

	arg_8_0.clippingNode2 = display.newClippingRegionNode()

	arg_8_0.clippingNode2:setClippingRegion(cc.rect(0, 0, arg_8_0.mapPanel:getContentSize().width, arg_8_0.mapPanel:getContentSize().height + 50))
	arg_8_0.arrowPanel:addChild(arg_8_0.clippingNode2)

	arg_8_0.arrowSprite = xyd.AssetLoader:get():loadSprite("images/down_arrow.png")

	arg_8_0.clippingNode2:addChild(arg_8_0.arrowSprite)

	arg_8_0.mapPanelWidth = arg_8_0.mapPanel:getContentSize().width

	arg_8_0:setTouchSwallowEnabled(false)

	arg_8_0.BoxEffects = {}

	arg_8_0:layout()
end

function var_0_8.layout(arg_9_0)
	arg_9_0:nodeByName("text_remain_label"):setString(xyd.tables.translation:translation("MAP_LEFT_TIMES"))
	arg_9_0:nodeByName("text_remain_label"):enableOutline(cc.c4b(71, 64, 97, 255), 2)
	arg_9_0:nodeByName("text_reward"):setString(xyd.tables.translation:translation("EXCHANGE_AWARD"))
	arg_9_0:nodeByName("text_advanced"):setString(xyd.tables.translation:translation("MARCH_ADVANCED"))
	arg_9_0:nodeByName("text_restart"):setString(xyd.tables.translation:translation("ACTIVITY_SAKURA_TIP1"))
	arg_9_0.rule_button:setTouchEnabled(true)
	arg_9_0.rule_button:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "ended" then
			xyd.playButtonSound()

			local var_10_0 = {}

			var_10_0.title_name = "MARCH_RULE_TITLE"
			var_10_0.rule = "MARCH_RULE_TEXT"

			xyd.WindowManager.get():openWindow("march_rule", var_10_0)
		end

		return true
	end)
	arg_9_0.reward_button:addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_11_0, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.MARCH
				})
			end)
		end
	end)
	arg_9_0.restart_button:addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_13_0, arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			local var_13_0 = arg_9_0.marchModel.mapInfo.resets_left

			if var_13_0 == nil or var_13_0 < 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_5:translation("MARCH_RESET_ALL_USED")
				})

				return
			end

			local var_13_1

			if arg_9_0.marchModel.isGetExtraAward == 0 then
				var_13_1 = var_0_5:translation("MARCH_RESTART_ABSENCE2")
			elseif arg_9_0.marchModel.isGetExtraAward == 1 then
				var_13_1 = var_0_5:translation("MARCH_RESTART_ABSENCE1")
			end

			local function var_13_2()
				local var_14_0 = {}

				xyd.Backend.get():request(xyd.mid.RESTART_MARCH, var_14_0, function(arg_15_0, arg_15_1)
					arg_9_0:addMap()
					xyd.db.formation:clearFormationData(xyd.CampaignType.MARCH, arg_9_0.selfPlayer.playerID)
				end)
			end

			local var_13_3 = {
				rcallBefore = 0,
				txt = var_13_1,
				rcallback = var_13_2,
				align = xyd.ui_align.CENTER
			}

			xyd.WindowManager.get():openWindow("common_alert", var_13_3)
		end
	end)

	if arg_9_0.selfPlayer.lev < 65 then
		arg_9_0.advanced_button:setVisible(false)
	else
		arg_9_0.advanced_button:addTouchEventListener(function(arg_16_0, arg_16_1)
			xyd.buttonScaleAnim(arg_16_0, arg_16_1)

			if arg_16_1 == ccui.TouchEventType.ended then
				if arg_9_0.marchModel.mapInfo.has_fight > 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("MARCH_ADVANCED_CANNOT_USE")
					})

					return
				end

				xyd.playButtonSound()

				local var_16_0 = {
					campaign_type = xyd.CampaignType.MARCH
				}

				arg_9_0.guild:loadAllTeamHeros(var_16_0, function(arg_17_0)
					local var_17_0 = false
					local var_17_1 = {}

					if arg_17_0 == xyd.error.OK then
						var_17_0 = true

						for iter_17_0, iter_17_1 in ipairs(arg_9_0.guild:getAllMarchTeamHeros()) do
							local var_17_2 = var_0_4.new()

							var_17_2:populate(iter_17_1)

							var_17_2.player_name = iter_17_1.player_name
							var_17_2.rent_need_mana = iter_17_1.rent_need_mana
							var_17_2.can_rent = iter_17_1.can_rent
							var_17_2.player_id = iter_17_1.player_id
							var_17_2.have_rent = iter_17_1.have_rent

							table.insert(var_17_1, var_17_2)
						end
					end

					local var_17_3 = {
						type = xyd.SelectTeamType.ADVANCED,
						recommendHeros = xyd.splitToNumber(arg_9_0.marchModel.mapInfo.recommend_partners, "|"),
						isMercenary = var_17_0,
						allTeamHeros = var_17_1
					}

					xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_17_3)
				end)
			end
		end)
	end

	arg_9_0:addMap()
end

local function var_0_9(arg_18_0)
	local var_18_0 = arg_18_0 .. ".json"
	local var_18_1 = arg_18_0 .. ".atlas"

	return (var_0_1.new(var_18_0, var_18_1, 1))
end

function var_0_8.getBoxEffect(arg_19_0, arg_19_1)
	if not arg_19_0.BoxEffects[arg_19_1] then
		local var_19_0 = "shake" .. arg_19_1
		local var_19_1 = "open" .. arg_19_1
		local var_19_2 = var_0_7["shake" .. arg_19_1]
		local var_19_3 = var_0_7["open" .. arg_19_1]

		arg_19_0.BoxEffects[arg_19_1] = {
			open = var_0_9(var_19_3),
			shake = var_0_9(var_19_2)
		}
	end

	return arg_19_0.BoxEffects[arg_19_1]
end

function var_0_8.addMap(arg_20_0)
	arg_20_0.text_remain:setString(arg_20_0.marchModel.mapInfo.resets_left or 0)
	arg_20_0.text_remain:enableOutline(cc.c4b(71, 64, 97, 255), 2)
	arg_20_0.clippingNode:removeAllChildren()

	local var_20_0 = xyd.AssetLoader:get():loadSprite("windows/march/march_map.png")
	local var_20_1 = var_20_0:getContentSize()
	local var_20_2 = arg_20_0.mapPanel:getContentSize()
	local var_20_3 = var_20_2.height / var_20_1.height

	arg_20_0.scrollMap = var_0_0.new({
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL,
		viewRect = cc.rect(0, 0, var_20_2.width, var_20_2.height)
	}):onScroll(handler(arg_20_0, arg_20_0.scrollListener)):setTouchType(true):setBounceable(false):pos(0, 0)

	local var_20_4 = cc.Node:create()

	arg_20_0.scrollMap:addScrollNode(var_20_4)

	local var_20_5 = var_20_1.width * var_20_3
	local var_20_6 = var_20_2.height

	arg_20_0.mapViewWidth = var_20_2.width
	arg_20_0.mapWidth = var_20_5

	arg_20_0.scrollMap:setScrollWidth(var_20_5)
	arg_20_0.scrollMap:setScrollHeight(var_20_6)
	arg_20_0.scrollMap:setRectOffsetX(0)
	var_20_4:setContentSize(var_20_5, var_20_6)
	xyd.displaySpriteOnContainer(var_20_0, var_20_4, true)

	local var_20_7 = xyd.AssetLoader:get():loadSprite("windows/march/march_rd.png")

	xyd.displaySpriteOnContainer(var_20_7, var_20_4, true)

	local var_20_8 = 0.7

	arg_20_0.innnerMapPianyi = var_20_4:getHeight() / 2 * (1 - var_20_8)

	var_20_7:setScaleY(var_20_3 * var_20_8)
	var_20_7:setAnchorPoint(cc.p(0.5, 0))
	var_20_7:setPositionY(arg_20_0.innnerMapPianyi)
	arg_20_0:loadCampaigns()

	arg_20_0.compaignNode = display.newNode()

	arg_20_0.compaignNode:setPositionY(arg_20_0.innnerMapPianyi)
	print("scale", var_20_3)
	print("scrollNode:getHeight()", var_20_4:getHeight())
	arg_20_0.compaignNode:setContentSize(var_20_5, var_20_5 * var_20_8)
	var_20_4:addChild(arg_20_0.compaignNode)
	arg_20_0:showCampaigns(arg_20_0.compaignNode, var_20_3, var_20_8)
	arg_20_0:initExtraAward()
	arg_20_0.clippingNode:addChild(arg_20_0.scrollMap)
end

function var_0_8.initExtraAward(arg_21_0)
	arg_21_0:nodeByName("extra_award_container"):removeAllChildren()

	local var_21_0 = arg_21_0.marchModel:getMapInfo().passed_stage
	local var_21_1 = var_21_0 + 1
	local var_21_2 = arg_21_0.marchModel:getMapInfo().stage_done
	local var_21_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/march/extra_chest.csb")

	var_21_3:addTo(arg_21_0:nodeByName("extra_award_container"))
	arg_21_0:nodeByName("extra_award_container"):setLocalZOrder(100)

	local var_21_4 = var_21_3:getChildByName("container")

	if var_21_2 == 1 then
		arg_21_0.pass = var_21_1
	else
		arg_21_0.pass = var_21_0
	end

	local var_21_5 = 0

	if arg_21_0.pass >= var_0_3 then
		var_21_4:getChildByName("not_get"):setVisible(false)

		if arg_21_0.marchModel.isGetExtraAward == 1 then
			var_21_5 = 2

			local var_21_6 = xyd.AssetLoader:get():loadSprite("windows/march/box.png")

			var_21_6:setScale(0.7, 0.7)
			var_21_6:setAnchorPoint(cc.p(0.5, 0.5))
			var_21_6:setPosition(var_21_4:getChildByName("chest_effect_pos"):getPosition())
			var_21_6:addTo(var_21_4)
		else
			var_21_5 = 1

			local var_21_7 = "skeletons/ui_effect/effect_baoxiang/baoxiang01" .. ".json"
			local var_21_8 = "skeletons/ui_effect/effect_baoxiang/baoxiang01" .. ".atlas"

			arg_21_0.effect = var_0_1.new(var_21_7, var_21_8, 1)

			arg_21_0.effect:setScale(0.7)
			arg_21_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
			arg_21_0.effect:setPosition(var_21_4:getChildByName("chest_effect_pos"):getPosition())
			arg_21_0.effect:addTo(var_21_4)
			arg_21_0.effect:play(nil, true)
		end

		local var_21_9 = arg_21_0:createExtraLabel(var_21_5, arg_21_0.pass)

		var_21_9:addTo(var_21_4)
		var_21_9:setAnchorPoint(cc.p(0.5, 0.5))
		var_21_9:setPosition(var_21_4:getChildByName("desc_pos"):getPosition())
	else
		local var_21_10 = 0

		var_21_4:getChildByName("not_get"):setVisible(true)

		local var_21_11 = arg_21_0:createExtraLabel(var_21_10, arg_21_0.pass)

		var_21_11:addTo(var_21_4)
		var_21_11:setAnchorPoint(cc.p(0.5, 0.5))
		var_21_11:setPosition(var_21_4:getChildByName("desc_pos"):getPosition())
	end

	var_21_4:getChildByName("chest_bg"):setTouchSwallowEnabled(true)
	var_21_4:getChildByName("chest_bg"):setTouchEnabled(true)
	var_21_4:getChildByName("chest_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
		if arg_22_0.name == "began" then
			return true
		elseif arg_22_0.name == "ended" and arg_21_0.marchModel.isGetExtraAward == 0 then
			local var_22_0 = {
				passedStage = arg_21_0.pass
			}

			xyd.WindowManager.get():openWindow("open_chest_wnd", var_22_0)
		end
	end)
end

function var_0_8.createExtraLabel(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0

	if arg_23_1 == 0 then
		local var_23_1 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}

		var_23_0 = xyd.AssetLoader.get():loadLabel(var_23_1)

		var_23_0:setString(string.format(var_0_5:translation("EXTRA_CHEST_TIP1"), 9 - arg_23_2))
	elseif arg_23_1 == 1 then
		local var_23_2 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}

		var_23_0 = xyd.AssetLoader.get():loadLabel(var_23_2)

		var_23_0:setString(var_0_5:translation("EXTRA_CHEST_TIP2"))
	elseif arg_23_1 == 2 then
		local var_23_3 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}

		var_23_0 = xyd.AssetLoader.get():loadLabel(var_23_3)

		var_23_0:setString(var_0_5:translation("EXTRA_CHEST_TIP3"))
	end

	return var_23_0
end

function var_0_8.showCampaigns(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	arg_24_1:removeAllChildren()

	local var_24_0 = arg_24_0.mapPanel:getContentSize().height
	local var_24_1 = (arg_24_0.marchModel:getMapInfo().passed_stage or 0) + 1

	arg_24_0.currentStage = var_24_1

	if var_24_1 > 15 and arg_24_0.arrowSprite then
		arg_24_0.arrowSprite:setPosition(-100, 0)
	end

	for iter_24_0 = 1, 15 do
		local var_24_2 = xyd.tables.marchRoad:x(iter_24_0) * arg_24_2
		local var_24_3 = xyd.tables.marchRoad:y(iter_24_0) * arg_24_2 * arg_24_3
		local var_24_4 = xyd.tables.marchRoad:bx(iter_24_0) * arg_24_2
		local var_24_5 = xyd.tables.marchRoad:by(iter_24_0) * arg_24_2 * arg_24_3
		local var_24_6 = xyd.tables.marchRoad:icon(iter_24_0)
		local var_24_7 = cc.Node:create()

		var_24_7:setTouchEnabled(true)

		local var_24_8

		if var_24_1 == iter_24_0 then
			var_24_8 = xyd.AssetLoader:get():loadSprite(var_24_6)
		else
			var_24_8 = xyd.AssetLoader:get():loadSprite(var_24_6, nil, {
				filter = {
					name = "GRAY",
					value = {
						0.2,
						0.3,
						0.5,
						0.1
					}
				}
			})
		end

		var_24_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
			if iter_24_0 > arg_24_0.marchModel:getCurrentStage() then
				return true
			end

			if arg_25_0.name == "began" then
				local var_25_0 = xyd.tables.sound:getSound("ui_button_click")

				audio.playSound(var_25_0, false)
				var_24_7:setScale(0.9)

				return true
			elseif arg_25_0.name == "moved" and arg_24_0.scrollViewMoved_ then
				var_24_7:setScale(1)
			elseif arg_25_0.name == "ended" and not arg_24_0.scrollViewMoved_ then
				var_24_7:setScale(1)

				local var_25_1 = arg_24_0.marchModel:getEnemy(iter_24_0)
				local var_25_2 = {
					team = var_25_1,
					teamIdx = iter_24_0,
					isActive = arg_24_0.marchModel:getCurrentStage() == iter_24_0 and arg_24_0.marchModel.stageDone == false
				}

				xyd.WindowManager.get():openWindow("march_team_info", var_25_2)

				return true
			end
		end)

		if var_24_8 ~= nil then
			var_24_7:addChild(var_24_8)
			arg_24_1:addChild(var_24_7)

			local var_24_9 = var_24_8:getContentSize()

			var_24_8:setPosition(var_24_9.width * 0.5, var_24_9.height * 0.5)
			var_24_7:setAnchorPoint(0.5, 0.4)
			var_24_7:setPosition(var_24_2, var_24_3)
			var_24_7:setContentSize(var_24_8:getContentSize())
			var_24_7:setTouchSwallowEnabled(false)
		end

		local var_24_10 = cc.Node:create()

		var_24_10:setTouchEnabled(true)

		if iter_24_0 == var_24_1 and arg_24_0.marchModel.stageDone == true then
			local var_24_11
			local var_24_12
			local var_24_13
			local var_24_14 = {}

			if iter_24_0 == arg_24_0.campaignNum then
				var_24_14 = arg_24_0:getBoxEffect(3)
			elseif iter_24_0 % 3 == 0 then
				var_24_14 = arg_24_0:getBoxEffect(2)
			else
				var_24_14 = arg_24_0:getBoxEffect(1)
			end

			local var_24_15 = var_24_14.open
			local var_24_16 = var_24_14.shake
			local var_24_17 = false

			if var_24_16 and var_24_15 then
				var_24_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
					if iter_24_0 ~= var_24_1 or var_24_17 == true then
						return true
					end

					if arg_26_0.name == "began" then
						arg_24_0.startClickX_ = arg_26_0.x

						return true
					elseif arg_26_0.name == "ended" then
						if math.abs(arg_26_0.x - arg_24_0.startClickX_) < 10 then
							var_24_17 = true

							var_24_16:clearTracks()
							var_24_16:setVisible(false)
							var_24_15:play(function()
								var_24_15:setVisible(false)
							end, false)
							var_0_6.performWithDelayGlobal(function(arg_28_0)
								if arg_24_0 and not tolua.isnull(arg_24_0) then
									arg_24_0:openBox(var_24_1, function()
										var_24_15:setVisible(false)
									end, false)
								end
							end, 0.8)
						end

						return true
					end
				end)
				var_24_10:addChild(var_24_16)
				var_24_10:addChild(var_24_15)
				var_24_16:setPosition(cc.p(46, 46))
				var_24_15:setPosition(cc.p(46, 46))
				arg_24_1:addChild(var_24_10)
				var_24_10:setPosition(var_24_4, var_24_5)
				var_24_10:setAnchorPoint(0.5, 0.5)
				var_24_10:setContentSize(92, 92)
			end
		else
			local var_24_18 = arg_24_0:showBox(iter_24_0, var_24_1, var_24_10, arg_24_1)

			var_24_10:addChild(var_24_18)

			local var_24_19 = var_24_18:getContentSize()

			var_24_18:setPosition(var_24_19.width * 0.5, var_24_19.height * 0.5)
			arg_24_1:addChild(var_24_10)
			var_24_10:setPosition(var_24_4, var_24_5)
			var_24_10:setAnchorPoint(0.5, 0.5)
			var_24_10:setContentSize(var_24_19)
			var_24_10:setTouchSwallowEnabled(false)

			if var_24_1 <= iter_24_0 then
				var_24_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
					if arg_30_0.name == "began" then
						var_24_10:setScale(0.9)

						arg_24_0.startClickX_ = arg_30_0.x

						return true
					elseif arg_30_0.name == "moved" and arg_24_0.scrollViewMoved_ then
						var_24_10:setScale(1)
					elseif arg_30_0.name == "ended" and not arg_24_0.scrollViewMoved_ then
						var_24_10:setScale(1)

						if math.abs(arg_30_0.x - arg_24_0.startClickX_) < 10 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_5:translation("MYSTERIOUS_GIFT")
							})
						end

						return true
					end
				end)
			end
		end

		if var_24_1 == iter_24_0 then
			local var_24_20

			if arg_24_0.marchModel.stageDone == true then
				var_24_20 = cc.p(var_24_4, var_24_5 + 30)
			else
				var_24_20 = cc.p(var_24_2, var_24_3 + 50)
			end

			arg_24_0.arrowPos = var_24_20

			local var_24_21 = math.max(math.min(arg_24_0.mapViewWidth / 2 - var_24_2, 0), arg_24_0.mapViewWidth - arg_24_0.mapWidth)

			arg_24_0.scrollMap:scrollTo(var_24_21, 0)
			arg_24_0.arrowSprite:setPosition(arg_24_0.arrowPos.x + var_24_21, arg_24_0.arrowPos.y + arg_24_0.innnerMapPianyi)

			local var_24_22 = cc.MoveBy:create(1, cc.p(0, 20))
			local var_24_23 = cc.MoveBy:create(1, cc.p(0, -20))
			local var_24_24 = transition.sequence({
				var_24_22,
				var_24_23
			})

			arg_24_0.arrowSprite:runAction(cc.RepeatForever:create(var_24_24))
		end
	end

	local var_24_25

	arg_24_0:showCloud(arg_24_1, arg_24_2, var_24_1, var_24_25)
end

function var_0_8.showBox(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0
	local var_31_1 = arg_31_2 <= arg_31_1 and (arg_31_1 == 15 and "images/icon/box/box2a.png" or arg_31_1 % 3 == 0 and "images/icon/box/box3a.png" or "images/icon/box/box1a.png") or arg_31_1 == arg_31_0.campaignNum and "images/icon/box/box2b.png" or arg_31_1 % 3 == 0 and "images/icon/box/box3b.png" or "images/icon/box/box1b.png"

	return (xyd.AssetLoader:get():loadSprite(var_31_1))
end

function var_0_8.showCloud(arg_32_0, arg_32_1, arg_32_2, arg_32_3)
	local var_32_0 = 0.9
	local var_32_1 = xyd.AssetLoader:get():loadSprite("windows/march/cloud1.png")

	var_32_1:setPosition(630 * arg_32_2, 200 * arg_32_2 - arg_32_0.innnerMapPianyi)
	var_32_1:setScale(arg_32_2 * var_32_0)
	arg_32_1:addChild(var_32_1)

	if arg_32_3 > 3 then
		var_32_1:setVisible(false)
	end

	local var_32_2 = xyd.AssetLoader:get():loadSprite("windows/march/cloud2.png")

	var_32_2:setPosition(850 * arg_32_2, 200 * arg_32_2 - arg_32_0.innnerMapPianyi)
	var_32_2:setScale(arg_32_2 * var_32_0)
	arg_32_1:addChild(var_32_2)

	if arg_32_3 > 6 then
		var_32_2:setVisible(false)
	end

	local var_32_3 = xyd.AssetLoader:get():loadSprite("windows/march/cloud3.png")

	var_32_3:setPosition(1100 * arg_32_2, 200 * arg_32_2 - arg_32_0.innnerMapPianyi)
	var_32_3:setScale(arg_32_2 * var_32_0)
	arg_32_1:addChild(var_32_3)

	if arg_32_3 > 8 then
		var_32_3:setVisible(false)
	end

	local var_32_4 = xyd.AssetLoader:get():loadSprite("windows/march/cloud4.png")

	var_32_4:setPosition(1500 * arg_32_2, 160 * arg_32_2 - arg_32_0.innnerMapPianyi)
	var_32_4:setScale(arg_32_2 * var_32_0)
	arg_32_1:addChild(var_32_4)

	if arg_32_3 > 12 then
		var_32_4:setVisible(false)
	end
end

function var_0_8.openBox(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = arg_33_0.marchModel
	local var_33_1 = {
		stage = arg_33_1
	}

	xyd.Backend.get():request(xyd.mid.MARCH_OPEN_BOX, var_33_1, function(arg_34_0, arg_34_1, arg_34_2)
		if arg_34_0 == xyd.error.OK then
			local var_34_0 = arg_34_1.rewards

			local function var_34_1(arg_35_0)
				local var_35_0 = {}
				local var_35_1 = {}

				for iter_35_0, iter_35_1 in ipairs(arg_35_0) do
					if iter_35_1.is_partner == true then
						iter_35_1.item_num = 1

						table.insert(var_35_0, iter_35_1)
					elseif iter_35_1.to_stone == true then
						table.insert(var_35_0, iter_35_1)
						table.insert(var_35_1, iter_35_1)
					else
						table.insert(var_35_0, iter_35_1)
						table.insert(var_35_1, iter_35_1)
					end
				end

				return var_35_0
			end

			local var_34_2 = xyd.WindowManager.get():openWindow("alert_award", {
				type = "march",
				awards = var_34_1(var_34_0)
			})

			cc.EventProxy.new(var_34_2, var_34_2):addEventListener(xyd.event.GOT_MARCH_AWARD, function(arg_36_0)
				if arg_33_0 and arg_33_0.marchModel then
					arg_33_0.marchModel.stageDone = false

					arg_33_0:addMap()
				end
			end)
		end
	end, var_33_1)
end

function var_0_8.loadCampaigns(arg_37_0)
	arg_37_0.campaigns = {
		{
			bx = 88,
			by = 169,
			y = 64,
			id = 100001,
			x = 35
		},
		{
			bx = 254,
			by = 252,
			y = 268,
			id = 200002,
			x = 124
		},
		{
			bx = 461,
			by = 129,
			y = 79,
			id = 100001,
			x = 313
		},
		{
			bx = 521,
			by = 258,
			y = 253,
			id = 200002,
			x = 401
		},
		{
			bx = 731,
			by = 64,
			y = 111,
			id = 100001,
			x = 646
		},
		{
			bx = 859,
			by = 163,
			y = 40,
			id = 200002,
			x = 929
		},
		{
			bx = 862,
			by = 268,
			y = 246,
			id = 100001,
			x = 719
		},
		{
			bx = 1022,
			by = 185,
			y = 264,
			id = 200002,
			x = 978
		},
		{
			bx = 1104,
			by = 160,
			y = 57,
			id = 100001,
			x = 1035
		},
		{
			bx = 1266,
			by = 264,
			y = 267,
			id = 200002,
			x = 1133
		},
		{
			bx = 1301,
			by = 66,
			y = 132,
			id = 100001,
			x = 1250
		},
		{
			bx = 1478,
			by = 138,
			y = 45,
			id = 200002,
			x = 1449
		},
		{
			bx = 1487,
			by = 283,
			y = 214,
			id = 100001,
			x = 1386
		},
		{
			bx = 1631,
			by = 109,
			y = 190,
			id = 200002,
			x = 1578
		},
		{
			bx = 1725,
			by = 265,
			y = 187,
			id = 100001,
			x = 1680
		}
	}
end

function var_0_8.loadEnemies(arg_38_0)
	return
end

function var_0_8.didOpen(arg_39_0)
	xyd.WindowManager.get():closeWindow("march_team_info")
end

function var_0_8.scrollListener(arg_40_0, arg_40_1)
	arg_40_0:adjustScrollMap()

	if arg_40_1.name == "began" then
		arg_40_0.scrollViewMoved_ = false
		arg_40_0.prevX_ = arg_40_1.x
	elseif arg_40_1.name == "moved" and 20 <= math.abs(arg_40_1.x - arg_40_0.prevX_) then
		arg_40_0.scrollViewMoved_ = true
	end
end

function var_0_8.adjustScrollMap(arg_41_0)
	local var_41_0 = arg_41_0.scrollMap:getScrollNode()
	local var_41_1 = arg_41_0.marchModel:getMapInfo()

	if var_41_1 ~= nil and var_41_1.passed_stage ~= nil and var_41_1.passed_stage < 15 then
		local var_41_2

		if var_41_0:getPositionX() >= 0 then
			arg_41_0.scrollMap:scrollTo(0, 0)

			var_41_2 = arg_41_0.arrowPos.x
		elseif var_41_0:getPositionX() <= arg_41_0.mapViewWidth - arg_41_0.mapWidth then
			arg_41_0.scrollMap:scrollTo(arg_41_0.mapViewWidth - arg_41_0.mapWidth, 0)

			var_41_2 = arg_41_0.arrowPos.x + arg_41_0.mapViewWidth - arg_41_0.mapWidth
		else
			var_41_2 = arg_41_0.arrowPos.x + var_41_0:getPositionX()
		end

		arg_41_0.arrowSprite:setPosition(var_41_2, arg_41_0.arrowPos.y + arg_41_0.innnerMapPianyi)
	end
end

function var_0_8.summonHeroEvent(arg_42_0, arg_42_1)
	if not arg_42_1.item_index then
		return
	end

	arg_42_0:checkReward(arg_42_1.item_index + 1, true)
end

return var_0_8
