local var_0_0 = class("StoneWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.shop_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.getWayTable = xyd.tables.heroGetWayTable
	arg_1_0.campaigns = arg_1_0.selfPlayer.worldMaps_
	arg_1_0.maxChapter = arg_1_0.selfPlayer.super_chapter_id
	arg_1_0.itemComposeID = arg_1_2.itemComposeID
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 20 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)

	arg_3_0.listView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 410, 455),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("stage_container")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.updateStoneCampaign(arg_5_0)
	arg_5_0.listView_:removeAllItems()

	if arg_5_0.campaignID and #arg_5_0.campaignID > 0 then
		for iter_5_0 = 1, #arg_5_0.campaignID do
			local var_5_0 = display.newNode()
			local var_5_1 = arg_5_0.listView_:newItem()
			local var_5_2 = import("app.windows.StoneCampaignItem").new()
			local var_5_3 = xyd.tables.campaign:relateCampaign(arg_5_0.campaignID[iter_5_0])
			local var_5_4 = {
				campaignName = xyd.tables.campaign:campaignName(var_5_3),
				chapter = xyd.tables.campaign:chapter(var_5_3),
				campaignType = xyd.tables.campaign:campaignType(arg_5_0.campaignID[iter_5_0]),
				icon = xyd.tables.campaign:icon(var_5_3),
				campaignID = arg_5_0.campaignID[iter_5_0]
			}

			var_5_2:setParams(var_5_4)
			var_5_2:setPosition(0, 0)
			var_5_2:setAnchorPoint(cc.p(0.5, 0.5))
			var_5_2:ignoreAnchorPointForPosition(false)
			var_5_2:addTo(var_5_0)

			local var_5_5 = xyd.tables.campaign:campaignType(arg_5_0.campaignID[iter_5_0])

			var_5_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
				if arg_6_0.name == "began" then
					var_5_2.contentView_:nodeByName("background"):setScale(0.9)
				end

				if arg_6_0.name == "moved" and arg_5_0.scrollViewMoved_ then
					var_5_2.contentView_:nodeByName("background"):setScale(1)
				end

				if arg_6_0.name == "ended" and not arg_5_0.scrollViewMoved_ then
					var_5_2.contentView_:nodeByName("background"):setScale(1)

					if arg_5_0.maxChapter >= xyd.tables.campaign:chapter(var_5_3) then
						arg_5_0.guild:loadGuildMap(function(arg_7_0)
							if arg_7_0 == xyd.error.OK then
								if xyd.WindowManager.get():getWindow("map_window") then
									xyd.WindowManager.get():closeWindow("map_window")
								end

								local var_7_0 = {}

								var_7_0.isStoneCampaign = true
								var_7_0.chapter = xyd.tables.campaign:chapter(var_5_3)
								var_7_0.campaignID = arg_5_0.campaignID[iter_5_0]
								var_7_0.campaignType = xyd.tables.campaign:campaignType(arg_5_0.campaignID[iter_5_0]) - 1
								var_7_0.itemComposeID = arg_5_0.itemComposeID

								xyd.WindowManager.get():openWindow("map_window", var_7_0)
							else
								if xyd.WindowManager.get():getWindow("map_window") then
									xyd.WindowManager.get():closeWindow("map_window")
								end

								local var_7_1 = {
									isStoneCampaign = true,
									chapter = xyd.tables.campaign:chapter(var_5_3),
									campaignID = arg_5_0.campaignID[iter_5_0],
									campaignType = xyd.tables.campaign:campaignType(arg_5_0.campaignID[iter_5_0]) - 1,
									itemComposeID = arg_5_0.itemComposeID
								}

								xyd.WindowManager.get():openWindow("map_window", var_7_1)
							end
						end)
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("CHAPTER_NOT_AVAILABLE")
						})
					end
				end

				return true
			end)
			var_5_1:addContent(var_5_0)
			var_5_0:setContentSize(402, 118)
			var_5_1:setItemSize(402, 122)
			arg_5_0.listView_:addItem(var_5_1)
		end
	end

	local var_5_6 = arg_5_0.hero:getTableID()

	if arg_5_0.hero:isAwaken() then
		var_5_6 = xyd.tables.hero:beforeAwaken(var_5_6)
	end

	local var_5_7 = var_5_6 + 30000000

	if arg_5_0.hero:isSuper() then
		var_5_7 = arg_5_0.hero:getSuiPianID()
	end

	local var_5_8 = xyd.tables.item:gainType(var_5_7)

	for iter_5_1 = 1, #var_5_8 do
		id = var_5_8[iter_5_1]

		if id ~= 0 then
			local var_5_9 = arg_5_0.listView_:newItem()
			local var_5_10 = arg_5_0:creatWayContent(id)

			var_5_9:addContent(var_5_10)
			var_5_10:setContentSize(402, 118)
			var_5_9:setItemSize(402, 122)
			arg_5_0.listView_:addItem(var_5_9)
		end
	end

	if (not arg_5_0.campaignID or #arg_5_0.campaignID <= 0) and var_5_8[1] == 0 then
		local var_5_11 = {
			size = 24,
			color = cc.c3b(54, 54, 54)
		}
		local var_5_12 = xyd.AssetLoader.get():loadLabel(var_5_11)

		var_5_12:setString(var_0_1:translation("STONE_NOT_GET"))

		local var_5_13 = arg_5_0:nodeByName("stage_container"):getContentSize().width
		local var_5_14 = arg_5_0:nodeByName("stage_container"):getContentSize().height
		local var_5_15, var_5_16 = arg_5_0:nodeByName("stage_container"):getPosition()

		var_5_12:setAnchorPoint(cc.p(0.5, 0.5))
		var_5_12:addTo(arg_5_0:nodeByName("background"))
		var_5_12:setPosition(var_5_15 + var_5_13 / 2, var_5_16 + var_5_14 * 0.6)
	end

	arg_5_0.listView_:reload()
end

function var_0_0.creatWayContent(arg_8_0, arg_8_1)
	local var_8_0 = display.newNode()
	local var_8_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/stone_campaign.csb")
	local var_8_2 = var_8_1:getChildByName("background")

	var_8_2:getChildByName("campaign_type_txt"):setVisible(false)
	var_8_2:getChildByName("left_times"):setVisible(false)

	local var_8_3 = arg_8_0.getWayTable:getIcon(arg_8_1)
	local var_8_4 = xyd.AssetLoader:get():loadSprite(var_8_3)

	var_8_4:setAnchorPoint(cc.p(0.5, 0.5))

	local var_8_5 = var_8_2:getChildByName("icon_node"):getContentSize().width / 2

	var_8_4:addTo(var_8_2:getChildByName("icon_node"))
	var_8_4:setPosition(cc.p(var_8_5, var_8_5))
	var_8_2:getChildByName("chapter_txt"):setString(arg_8_0.getWayTable:getName(arg_8_1))
	var_8_2:getChildByName("campaign_name"):setString(arg_8_0.getWayTable:getDesc(arg_8_1))
	var_8_1:addTo(var_8_0)
	var_8_1:setAnchorPoint(cc.p(0, 0))
	var_8_1:setName("source")
	var_8_1:setTouchEnabled(true)
	var_8_1:setTouchSwallowEnabled(false)
	var_8_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			var_8_2:setScale(0.9)

			return true
		elseif arg_9_0.name == "moved" and arg_8_0.scrollViewMoved_ then
			var_8_2:setScale(1)
		elseif arg_9_0.name == "ended" and not arg_8_0.scrollViewMoved_ then
			var_8_2:setScale(1)
			xyd.navigateToHeroGetWay(arg_8_1)
		end
	end)

	return var_8_0
end

function var_0_0.layout(arg_10_0)
	arg_10_0:nodeByName("text_name"):setString(arg_10_0.hero:getName())
	arg_10_0:nodeByName("text_ability"):setString(var_0_1:translation("ABILITY_EVALUATE"))
	arg_10_0:nodeByName("text_get_way"):setString(var_0_1:translation("ITEM_DETAIL_GAIN_WAY"))
	arg_10_0:nodeByName("text_stone"):setString(var_0_1:translation("STONE_NUM"))
	arg_10_0:nodeByName("text_stone"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_10_0:nodeByName("txt_ad"):setString(var_0_1:translation("HERO_MAIN_TEXT_48"))
	arg_10_0:nodeByName("txt_as"):setString(var_0_1:translation("HERO_MAIN_TEXT_52"))
	arg_10_0:nodeByName("txt_march"):setString(var_0_1:translation("HERO_MAIN_TEXT_51"))
	arg_10_0:nodeByName("txt_boss"):setString(var_0_1:translation("HERO_MAIN_TEXT_50"))
	arg_10_0:nodeByName("txt_df"):setString(var_0_1:translation("HERO_MAIN_TEXT_49"))
	arg_10_0:nodeByName("txt_pk"):setString(var_0_1:translation("HERO_MAIN_TEXT_53"))
	arg_10_0:nodeByName("txt_ad"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_10_0:nodeByName("txt_as"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_10_0:nodeByName("txt_march"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_10_0:nodeByName("txt_boss"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_10_0:nodeByName("txt_df"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_10_0:nodeByName("txt_pk"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	arg_10_0.iconImg = arg_10_0:nodeByName("avatar")

	arg_10_0.iconImg:removeAllChildren()

	local var_10_0 = arg_10_0.hero:getSuiPianID()

	xyd.setItemBorder(arg_10_0.iconImg, var_10_0)

	local var_10_1 = arg_10_0.hero:getAttrRates()
	local var_10_2 = arg_10_0:nodeByName("canvas")

	xyd.drawColorPentagon(var_10_2, {
		radius = 112,
		values = var_10_1,
		center = cc.p(119, 119.5)
	})
	arg_10_0:showProgressBar()

	arg_10_0.campaignID = xyd.tables.hero:stoneCampain(arg_10_0.hero:getTableID())

	arg_10_0:updateStoneCampaign()
end

function var_0_0.showProgressBar(arg_11_0)
	local var_11_0 = arg_11_0.hero
	local var_11_1 = arg_11_0:nodeByName("progress_bar")
	local var_11_2
	local var_11_3

	if var_11_0:isCollected() then
		if xyd.isSuperHero(var_11_0) then
			if var_11_0:getStar() >= xyd.SUPER_HERO_TOTAL_STARS then
				var_11_2 = 100
				var_11_3 = var_0_1:translation("HERO_MAIN_MAX_STAR")
			else
				var_11_2 = math.min(var_11_0:getSuiPian() / xyd.StarLevelSuipian[var_11_0:getStar() + 1] * 100, 100)
				var_11_3 = var_11_0:getSuiPian() .. " / " .. xyd.StarLevelSuipian[var_11_0:getStar() + 1]
			end
		elseif var_11_0:getStar() >= xyd.MAX_STAR_LEVEL then
			var_11_2 = 100
			var_11_3 = var_0_1:translation("HERO_MAIN_MAX_STAR")
		else
			var_11_2 = math.min(var_11_0:getSuiPian() / xyd.StarLevelSuipian[var_11_0:getStar() + 1] * 100, 100)
			var_11_3 = var_11_0:getSuiPian() .. " / " .. xyd.StarLevelSuipian[var_11_0:getStar() + 1]
		end
	else
		var_11_2 = math.min(var_11_0:getSuiPian() / xyd.TotalStarSuipian[var_11_0:getStar()] * 100, 100)
		var_11_3 = var_11_0:getSuiPian() .. " / " .. xyd.TotalStarSuipian[var_11_0:getStar()]
	end

	var_11_1:setPercent(var_11_2)
	arg_11_0:nodeByName("progress_text"):setString(var_11_3)
	arg_11_0:nodeByName("progress_text"):enableOutline(cc.c4b(0, 0, 0, 255), 2)
end

function var_0_0.willClose(arg_12_0)
	return
end

function var_0_0.didClose(arg_13_0)
	return
end

return var_0_0
