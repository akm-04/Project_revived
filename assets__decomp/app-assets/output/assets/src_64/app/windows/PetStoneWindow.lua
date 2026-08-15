local var_0_0 = class("PetStoneWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.campaigns = arg_1_0.selfPlayer.worldMaps_
	arg_1_0.maxChapter = arg_1_0.selfPlayer.super_chapter_id
	arg_1_0.itemComposeID = arg_1_2.itemComposeID
	arg_1_0.getWayTable = xyd.tables.heroGetWayTable
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 20 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.scrollListener2(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevX_ = arg_3_1.x
	elseif arg_3_1.name == "moved" and 20 <= math.abs(arg_3_1.x - arg_3_0.prevX_) then
		arg_3_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)

	arg_4_0.listView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(10, 0, 401, 454),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("stage_container")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))
	arg_4_0.skillListView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("skill_container"):getWidth(), arg_4_0:nodeByName("skill_container"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_4_0:nodeByName("skill_container")):onScroll(handler(arg_4_0, arg_4_0.scrollListener2))

	arg_4_0:layout()
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
end

function var_0_0.updateStoneCampaign(arg_6_0)
	arg_6_0.listView_:removeAllItems()

	if arg_6_0.campaignID and #arg_6_0.campaignID > 0 then
		for iter_6_0 = 1, #arg_6_0.campaignID do
			local var_6_0 = display.newNode()
			local var_6_1 = arg_6_0.listView_:newItem()
			local var_6_2 = import("app.windows.PetStoneCampaignItem").new()
			local var_6_3 = xyd.tables.campaign:relateCampaign(arg_6_0.campaignID[iter_6_0])
			local var_6_4 = {
				campaignName = xyd.tables.campaign:campaignName(var_6_3),
				chapter = xyd.tables.campaign:chapter(var_6_3),
				campaignType = xyd.tables.campaign:campaignType(arg_6_0.campaignID[iter_6_0]),
				icon = xyd.tables.campaign:icon(var_6_3),
				campaignID = arg_6_0.campaignID[iter_6_0]
			}

			var_6_2:setParams(var_6_4)
			var_6_2:setPosition(0, 0)
			var_6_2:setAnchorPoint(cc.p(0.5, 0.5))
			var_6_2:ignoreAnchorPointForPosition(false)
			var_6_2:addTo(var_6_0)

			local var_6_5 = xyd.tables.campaign:campaignType(arg_6_0.campaignID[iter_6_0])

			var_6_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
				if arg_7_0.name == "began" then
					var_6_2.contentView_:nodeByName("background"):setScale(0.9)
				end

				if arg_7_0.name == "moved" and arg_6_0.scrollViewMoved_ then
					var_6_2.contentView_:nodeByName("background"):setScale(1)
				end

				if arg_7_0.name == "ended" and not arg_6_0.scrollViewMoved_ then
					var_6_2.contentView_:nodeByName("background"):setScale(1)

					if arg_6_0.maxChapter >= xyd.tables.campaign:chapter(var_6_3) then
						arg_6_0.guild:loadGuildMap(function(arg_8_0)
							if arg_8_0 == xyd.error.OK then
								if xyd.WindowManager.get():getWindow("map_window") then
									xyd.WindowManager.get():closeWindow("map_window")
								end

								local var_8_0 = {}

								var_8_0.isStoneCampaign = true
								var_8_0.chapter = xyd.tables.campaign:chapter(var_6_3)
								var_8_0.campaignID = arg_6_0.campaignID[iter_6_0]
								var_8_0.campaignType = xyd.tables.campaign:campaignType(arg_6_0.campaignID[iter_6_0]) - 1
								var_8_0.itemComposeID = arg_6_0.itemComposeID

								xyd.WindowManager.get():openWindow("map_window", var_8_0)
							else
								if xyd.WindowManager.get():getWindow("map_window") then
									xyd.WindowManager.get():closeWindow("map_window")
								end

								local var_8_1 = {
									isStoneCampaign = true,
									chapter = xyd.tables.campaign:chapter(var_6_3),
									campaignID = arg_6_0.campaignID[iter_6_0],
									campaignType = xyd.tables.campaign:campaignType(arg_6_0.campaignID[iter_6_0]) - 1,
									itemComposeID = arg_6_0.itemComposeID
								}

								xyd.WindowManager.get():openWindow("map_window", var_8_1)
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
			var_6_1:addContent(var_6_0)
			var_6_0:setContentSize(401, 123)
			var_6_1:setItemSize(401, 123)
			arg_6_0.listView_:addItem(var_6_1)
		end

		arg_6_0.listView_:reload()
	end
end

function var_0_0.layout(arg_9_0)
	arg_9_0:nodeByName("text_name"):setString(arg_9_0.hero:getName())
	arg_9_0:nodeByName("text_name"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_9_0:nodeByName("des_word"):setString(var_0_1:translation("PET_DES"))
	arg_9_0:nodeByName("des_word"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_9_0:nodeByName("skill_word"):setString(var_0_1:translation("PET_SKILL"))
	arg_9_0:nodeByName("skill_word"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_9_0:nodeByName("text_stone"):setString(var_0_1:translation("PET_STONE_NUM"))
	arg_9_0:nodeByName("des_text"):setString(arg_9_0.hero:getDes())

	arg_9_0.iconImg = arg_9_0:nodeByName("avatar")

	arg_9_0.iconImg:removeAllChildren()

	local var_9_0 = arg_9_0.hero:getSuiPianID()

	xyd.setItemBorder(arg_9_0.iconImg, var_9_0)
	arg_9_0:showProgressBar()
	arg_9_0:initSkillContainer()

	arg_9_0.campaignID = xyd.tables.hero:stoneCampain(arg_9_0.hero:getTableID())

	if arg_9_0.campaignID and #arg_9_0.campaignID > 0 then
		for iter_9_0 = 1, #arg_9_0.campaignID do
			local var_9_1 = display.newNode()
			local var_9_2 = arg_9_0.listView_:newItem()
			local var_9_3 = import("app.windows.PetStoneCampaignItem").new()
			local var_9_4 = arg_9_0.campaignID[iter_9_0]
			local var_9_5 = {
				campaignName = xyd.tables.campaign:campaignName(var_9_4),
				chapter = xyd.tables.campaign:chapter(var_9_4),
				campaignType = xyd.tables.campaign:campaignType(arg_9_0.campaignID[iter_9_0]),
				icon = xyd.tables.campaign:icon(var_9_4),
				campaignID = arg_9_0.campaignID[iter_9_0]
			}

			var_9_5.onlyName = true

			var_9_3:setParams(var_9_5)
			var_9_3:setPosition(0, 0)
			var_9_3:setAnchorPoint(cc.p(0.5, 0.5))
			var_9_3:ignoreAnchorPointForPosition(false)
			var_9_3:addTo(var_9_1)

			local var_9_6 = xyd.tables.campaign:campaignType(arg_9_0.campaignID[iter_9_0])

			var_9_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
				if arg_10_0.name == "began" then
					var_9_3.contentView_:nodeByName("background"):setScale(0.9)
				end

				if arg_10_0.name == "moved" and arg_9_0.scrollViewMoved_ then
					var_9_3.contentView_:nodeByName("background"):setScale(1)
				end

				if arg_10_0.name == "ended" and not arg_9_0.scrollViewMoved_ then
					var_9_3.contentView_:nodeByName("background"):setScale(1)

					if xyd.WindowManager.get():getWindow("pet_campaign") then
						xyd.WindowManager.get():closeWindow("pet_campaign")
					end

					xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN):getCampaignInfo(function(arg_11_0)
						if arg_11_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("pet_campaign")
						end
					end)
				end

				return true
			end)
			var_9_2:addContent(var_9_1)
			var_9_1:setContentSize(401, 123)
			var_9_2:setItemSize(401, 123)
			arg_9_0.listView_:addItem(var_9_2)
		end
	end

	local var_9_7 = arg_9_0.hero:getSuiPianID()
	local var_9_8 = xyd.tables.item:gainType(var_9_7)

	for iter_9_1 = 1, #var_9_8 do
		id = var_9_8[iter_9_1]

		if id ~= 0 then
			local var_9_9 = arg_9_0.listView_:newItem()
			local var_9_10 = arg_9_0:creatWayContent(id)

			var_9_9:addContent(var_9_10)
			var_9_10:setContentSize(401, 123)
			var_9_9:setItemSize(401, 123)
			arg_9_0.listView_:addItem(var_9_9)
		end
	end

	if (not arg_9_0.campaignID or #arg_9_0.campaignID <= 0) and var_9_8[1] == 0 then
		local var_9_11 = {
			size = 24,
			color = cc.c3b(235, 75, 94)
		}
		local var_9_12 = xyd.AssetLoader.get():loadLabel(var_9_11)

		var_9_12:setString(var_0_1:translation("PET_STONE_NOT_GET"))

		local var_9_13 = arg_9_0:nodeByName("stage_container"):getContentSize().width
		local var_9_14 = arg_9_0:nodeByName("stage_container"):getContentSize().height
		local var_9_15, var_9_16 = arg_9_0:nodeByName("stage_container"):getPosition()

		var_9_12:setAnchorPoint(cc.p(0.5, 0.5))
		var_9_12:addTo(arg_9_0:nodeByName("background"))
		var_9_12:setPosition(var_9_15 + var_9_13 / 2, var_9_16 + var_9_14 * 0.6)
		var_9_12:enableShadow(cc.c4b(8, 8, 8, 200), cc.size(1, -1), 2)
	else
		arg_9_0.listView_:reload()
	end
end

function var_0_0.creatWayContent(arg_12_0, arg_12_1)
	local var_12_0 = display.newNode()
	local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/stone_campaign.csb")
	local var_12_2 = var_12_1:getChildByName("background")

	var_12_2:getChildByName("campaign_type_txt"):setVisible(false)
	var_12_2:getChildByName("left_times"):setVisible(false)

	local var_12_3 = arg_12_0.getWayTable:getIcon(arg_12_1)
	local var_12_4 = xyd.AssetLoader:get():loadSprite(var_12_3)

	var_12_4:setAnchorPoint(cc.p(0.5, 0.5))

	local var_12_5 = var_12_2:getChildByName("icon_node"):getContentSize().width / 2

	var_12_4:addTo(var_12_2:getChildByName("icon_node"))
	var_12_4:setPosition(cc.p(var_12_5, var_12_5))
	var_12_2:getChildByName("chapter_txt"):setString(arg_12_0.getWayTable:getName(arg_12_1))
	var_12_2:getChildByName("campaign_name"):setString(arg_12_0.getWayTable:getDesc(arg_12_1))
	var_12_1:addTo(var_12_0)
	var_12_1:setAnchorPoint(cc.p(0, 0))
	var_12_1:setName("source")
	var_12_1:setTouchEnabled(true)
	var_12_1:setTouchSwallowEnabled(false)
	var_12_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			var_12_2:setScale(0.9)

			return true
		elseif arg_13_0.name == "moved" and arg_12_0.scrollViewMoved_ then
			var_12_2:setScale(1)
		elseif arg_13_0.name == "ended" and not arg_12_0.scrollViewMoved_ then
			var_12_2:setScale(1)
			xyd.navigateToHeroGetWay(arg_12_1)
		end
	end)

	return var_12_0
end

function var_0_0.initSkillContainer(arg_14_0)
	local var_14_0 = arg_14_0.hero
	local var_14_1 = var_14_0:getSkillId()
	local var_14_2 = {}

	arg_14_0.skillItems = {}

	for iter_14_0, iter_14_1 in ipairs(var_14_1) do
		local var_14_3 = iter_14_1 == 0 or xyd.tables.skill:isAwakenSkill(iter_14_1) > 0
		local var_14_4 = xyd.tables.hero:isCanAwaken(var_14_0:getTableID()) > 0 and arg_14_0.selfPlayer.maxTeamLev >= 90

		if not iter_14_1 or iter_14_1 == 0 then
			break
		end

		if var_14_3 and not var_14_4 then
			break
		end

		local var_14_5 = display.newNode()
		local var_14_6 = arg_14_0.skillListView_:newItem()
		local var_14_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/stone_item.csb")
		local var_14_8 = var_14_7:getChildByName("container")

		var_14_7:addTo(var_14_5)
		var_14_6:addContent(var_14_5)
		var_14_5:setContentSize(var_14_8:getContentSize().width, var_14_8:getContentSize().height)
		var_14_6:setItemSize(var_14_8:getContentSize().width + 15, var_14_8:getContentSize().height)
		arg_14_0.skillListView_:addItem(var_14_6)

		local var_14_9 = xyd.tables.skill:icon(iter_14_1)
		local var_14_10 = xyd.SpriteLoader.new(var_14_9, nil, nil, xyd.DefaultImageType.SKILL_ICON)
		local var_14_11 = var_14_8:getChildByName("skill_con")

		if not var_14_3 or var_14_0:isAwaken() then
			local var_14_12 = xyd.AssetLoader:get():loadSprite("windows/pet/petMainWindow/skill_icon_mask.png")

			var_14_12:setPosition(var_14_11:getWidth() / 2, var_14_11:getHeight() / 2)
			var_14_12:setAnchorPoint(cc.p(0.5, 0.5))
			var_14_12:scale((var_14_11:getWidth() + 4) / var_14_12:getWidth())

			local var_14_13 = cc.ClippingNode:create()

			var_14_13:setStencil(var_14_12)
			var_14_13:setInverted(true)
			var_14_13:setAlphaThreshold(0)
			var_14_11:addChild(var_14_13)
			var_14_13:addChild(var_14_10)
			var_14_10:align(display.LEFT_BOTTOM, 0, 0)
			var_14_10:scale(var_14_11:getWidth() / var_14_10:getWidth())
			table.insert(arg_14_0.skillItems, var_14_11)
			arg_14_0:createSkillTip(iter_14_0, iter_14_1)
		end
	end

	arg_14_0.skillListView_:reload()
end

function var_0_0.createSkillTip(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_0.skillItems[arg_15_1]

	if not var_15_0 then
		return
	end

	local var_15_1, var_15_2 = var_15_0:getPosition()
	local var_15_3 = display.newNode()

	var_15_3:addTo(var_15_0)
	var_15_3:setAnchorPoint(cc.p(0, 0))
	var_15_3:setContentSize(var_15_0:getContentSize())
	var_15_3:setTouchEnabled(true)
	var_15_3:setTouchSwallowEnabled(false)

	local var_15_4 = arg_15_0:convertToWorldSpace(cc.p(0, 0))

	var_15_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			local var_16_0 = {
				has_jiantou = false,
				id = arg_15_2
			}

			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_16_1 = xyd.WindowManager.get():openWindow("skill_tips", var_16_0)

				xyd.adaptToWorldPosition(var_15_3, var_16_1)
			end

			return true
		elseif arg_16_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("skill_tips")
		end
	end)
end

function var_0_0.showProgressBar(arg_17_0)
	local var_17_0 = arg_17_0.hero
	local var_17_1 = arg_17_0:nodeByName("progress_bar")
	local var_17_2
	local var_17_3

	if var_17_0:isCollected() then
		if var_17_0:getStar() >= xyd.MAX_STAR_LEVEL then
			var_17_2 = 100
			var_17_3 = var_0_1:translation("HERO_MAIN_MAX_STAR")
		else
			var_17_2 = math.min(var_17_0:getSuiPian() / xyd.StarLevelSuipian[var_17_0:getStar() + 1] * 100, 100)
			var_17_3 = var_17_0:getSuiPian() .. " / " .. xyd.StarLevelSuipian[var_17_0:getStar() + 1]
		end
	else
		var_17_2 = math.min(var_17_0:getSuiPian() / xyd.TotalStarSuipian[var_17_0:getStar()] * 100, 100)
		var_17_3 = var_17_0:getSuiPian() .. " / " .. xyd.TotalStarSuipian[var_17_0:getStar()]
	end

	var_17_1:setPercent(var_17_2)
	arg_17_0:nodeByName("progress_text"):setString(var_17_3)
end

function var_0_0.willClose(arg_18_0)
	return
end

function var_0_0.didClose(arg_19_0)
	return
end

return var_0_0
