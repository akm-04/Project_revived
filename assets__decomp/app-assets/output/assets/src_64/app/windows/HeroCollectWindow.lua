local var_0_0 = class("HeroCollectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = require("framework.scheduler")
local var_0_3 = 30
local var_0_4 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.heroRecommend = xyd.ModelManager.get():loadModel(xyd.ModelType.HERO_RECOMMEND)
	arg_2_0.heroRecommend.recommendInfo = nil

	var_0_0.super:willOpen(arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.UPDATE_HERO_COLLECT_STONE, handler(arg_3_0, arg_3_0.onUpdateStoneNum_))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_3_0, arg_3_0.updateList))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.UPDATE_SEARCH_HEROS, handler(arg_3_0, arg_3_0.updateListBySearchTxt))

	arg_3_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_3_0:scheduleHandler()
end

function var_0_0.updateList(arg_4_0)
	arg_4_0:update()
	arg_4_0.heroList_:reload()
end

function var_0_0.updateListBySearchTxt(arg_5_0, arg_5_1)
	arg_5_0.searchTxt = arg_5_1.params

	arg_5_0:update()
	arg_5_0.heroList_:reload()
end

function var_0_0.didClose(arg_6_0)
	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	local var_6_0
	local var_6_1 = xyd.StoryData.get():getGuideID()

	if var_6_1 == xyd.GuideStoryType.GUIDE_EQUIP_END then
		arg_6_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_BACK3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_START)
		xyd.StoryData.get():persist()
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.GUIDE_FIGHT_2_START
			}
		})

		var_6_0 = true
	elseif var_6_1 == xyd.GuideStoryType.ACTIVITY_THREE then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.ACTIVITY_THREE
			}
		})

		var_6_0 = true
	elseif var_6_1 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_5_START)
		xyd.StoryData.get():persist()
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.GUIDE_FIGHT_5_START
			}
		})

		var_6_0 = true
	elseif var_6_1 == xyd.GuideStoryType.GUIDE_FIGHT_6_ONE then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.GUIDE_FIGHT_6_ONE
			}
		})

		var_6_0 = true
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {
			quickAction = var_6_0
		}
	})
end

function var_0_0.scheduleHandler(arg_7_0)
	arg_7_0.handler = var_0_2.scheduleUpdateGlobal(handler(arg_7_0, arg_7_0.loop))
end

function var_0_0.loop(arg_8_0)
	arg_8_0.count = arg_8_0.count or 0

	if tolua.isnull(arg_8_0) then
		if arg_8_0.handler ~= nil then
			var_0_2.unscheduleGlobal(arg_8_0.handler)

			arg_8_0.handler = nil
		end
	elseif arg_8_0.count < 1 then
		arg_8_0.count = arg_8_0.count + 1
	elseif arg_8_0.count < 2 then
		arg_8_0:update()

		arg_8_0.count = arg_8_0.count + 1
	else
		arg_8_0:layout()

		arg_8_0.selectedHeroClass_ = xyd.DistanceType.ALL

		arg_8_0:refreshSelectedHeroClass()
		arg_8_0:setTouchSwallowEnabled(false)
		arg_8_0:playGuide()

		if arg_8_0.handler ~= nil then
			var_0_2.unscheduleGlobal(arg_8_0.handler)

			arg_8_0.handler = nil
		end
	end
end

function var_0_0.update(arg_9_0)
	arg_9_0.totalHero_ = {}
	arg_9_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_9_0.totalHero_[xyd.DistanceType.FILTER_FOR_COLLECT] = {}
	arg_9_0.totalHero_[xyd.DistanceType.SEARCH_FOR_COLLECT] = {}
	arg_9_0.unCollected_ = {}
	arg_9_0.unCollected_[xyd.DistanceType.ALL] = {}
	arg_9_0.unCollected_[xyd.DistanceType.FILTER_FOR_COLLECT] = {}
	arg_9_0.unCollected_[xyd.DistanceType.SEARCH_FOR_COLLECT] = {}
	arg_9_0.totalIDs_ = {}
	arg_9_0.allHeros_ = {}

	local var_9_0 = {
		0,
		0,
		0
	}
	local var_9_1 = {
		0,
		0,
		0
	}
	local var_9_2 = {
		0,
		0,
		0,
		0
	}
	local var_9_3 = {
		0,
		0,
		0
	}

	if arg_9_0.selfPlayer.sortType and arg_9_0.selfPlayer.sortType > 0 then
		local var_9_4 = {}
		local var_9_5 = arg_9_0.selfPlayer.sortType
		local var_9_6 = 1

		while var_9_5 > 0 do
			var_9_4[var_9_6] = var_9_5 % 2
			var_9_6 = var_9_6 + 1
			var_9_5 = math.floor(var_9_5 / 2)
		end

		local var_9_7 = 1

		for iter_9_0 = 13, 1, -1 do
			if iter_9_0 <= 4 then
				if iter_9_0 == 4 then
					var_9_7 = 1
				end

				var_9_2[var_9_7] = var_9_4[iter_9_0]
			elseif iter_9_0 <= 7 then
				if iter_9_0 == 7 then
					var_9_7 = 1
				end

				var_9_1[var_9_7] = var_9_4[iter_9_0]
			elseif iter_9_0 <= 10 then
				if iter_9_0 == 10 then
					var_9_7 = 1
				end

				var_9_0[var_9_7] = var_9_4[iter_9_0]
			elseif iter_9_0 <= 13 and var_9_4[iter_9_0] then
				var_9_3[var_9_7] = var_9_4[iter_9_0]
			end

			var_9_7 = var_9_7 + 1
		end
	else
		var_9_0 = {
			1,
			1,
			1
		}
		var_9_1 = {
			1,
			1,
			1
		}
		var_9_2 = {
			1,
			1,
			1,
			1
		}
		var_9_3 = {
			1,
			1,
			1
		}
	end

	for iter_9_1, iter_9_2 in pairs(arg_9_0.selfPlayer.heros_) do
		if var_9_0[iter_9_2:getDistanceType() - 1] == 1 and var_9_1[iter_9_2:getHeroType()] == 1 and var_9_2[iter_9_2:getFromType()] == 1 and var_9_3[iter_9_2:getAwakenType()] == 1 then
			table.insert(arg_9_0.totalHero_[xyd.DistanceType.FILTER_FOR_COLLECT], iter_9_2)
		end

		if arg_9_0.selectedHeroClass_ == xyd.DistanceType.SEARCH_FOR_COLLECT and xyd.searchHeroByName(arg_9_0.searchTxt, iter_9_2) then
			table.insert(arg_9_0.totalHero_[xyd.DistanceType.SEARCH_FOR_COLLECT], iter_9_2)
		elseif arg_9_0.selectedHeroClass_ ~= xyd.DistanceType.SEARCH_FOR_COLLECT then
			table.insert(arg_9_0.totalHero_[xyd.DistanceType.SEARCH_FOR_COLLECT], iter_9_2)
		end

		table.insert(arg_9_0.totalHero_[xyd.DistanceType.ALL], iter_9_2)
		table.insert(arg_9_0.allHeros_, iter_9_2)

		arg_9_0.totalIDs_[iter_9_2:getTableID()] = iter_9_2
	end

	for iter_9_3, iter_9_4 in pairs(xyd.tables.hero:getPartnerDistanceType()) do
		local var_9_8 = xyd.tables.hero:afterAwaken(iter_9_3)

		if var_9_8 > 0 and arg_9_0.totalIDs_[iter_9_3] == nil and arg_9_0.totalIDs_[var_9_8] == nil and not xyd.isSuperHero(iter_9_3) then
			local var_9_9 = var_0_1.new()

			var_9_9:initUnCollected(iter_9_3)
			table.insert(arg_9_0.allHeros_, var_9_9)

			if var_9_9:getSuiPian() > 0 or var_9_9:isShow() then
				if var_9_9:canSummon() then
					if var_9_0[var_9_9:getDistanceType() - 1] == 1 and var_9_1[var_9_9:getHeroType()] == 1 and var_9_2[var_9_9:getFromType()] == 1 and var_9_3[var_9_9:getAwakenType()] == 1 then
						table.insert(arg_9_0.totalHero_[xyd.DistanceType.FILTER_FOR_COLLECT], var_9_9)
					end

					if arg_9_0.selectedHeroClass_ == xyd.DistanceType.SEARCH_FOR_COLLECT and xyd.searchHeroByName(arg_9_0.searchTxt, var_9_9) then
						table.insert(arg_9_0.totalHero_[xyd.DistanceType.SEARCH_FOR_COLLECT], var_9_9)
					elseif arg_9_0.selectedHeroClass_ ~= xyd.DistanceType.SEARCH_FOR_COLLECT then
						table.insert(arg_9_0.totalHero_[xyd.DistanceType.SEARCH_FOR_COLLECT], var_9_9)
					end

					table.insert(arg_9_0.totalHero_[xyd.DistanceType.ALL], var_9_9)
				else
					if var_9_0[var_9_9:getDistanceType() - 1] == 1 and var_9_1[var_9_9:getHeroType()] == 1 and var_9_2[var_9_9:getFromType()] == 1 and var_9_3[var_9_9:getAwakenType()] == 1 then
						table.insert(arg_9_0.unCollected_[xyd.DistanceType.FILTER_FOR_COLLECT], var_9_9)
					end

					if arg_9_0.selectedHeroClass_ == xyd.DistanceType.SEARCH_FOR_COLLECT and xyd.searchHeroByName(arg_9_0.searchTxt, var_9_9) then
						table.insert(arg_9_0.unCollected_[xyd.DistanceType.SEARCH_FOR_COLLECT], var_9_9)
					elseif arg_9_0.selectedHeroClass_ ~= xyd.DistanceType.SEARCH_FOR_COLLECT then
						table.insert(arg_9_0.unCollected_[xyd.DistanceType.SEARCH_FOR_COLLECT], var_9_9)
					end

					table.insert(arg_9_0.unCollected_[xyd.DistanceType.ALL], var_9_9)
				end
			end
		end
	end

	if arg_9_0.selectedHeroClass_ == xyd.DistanceType.SEARCH_FOR_COLLECT and #arg_9_0.unCollected_[xyd.DistanceType.SEARCH_FOR_COLLECT] + #arg_9_0.totalHero_[xyd.DistanceType.SEARCH_FOR_COLLECT] <= 0 then
		arg_9_0.totalHero_[xyd.DistanceType.SEARCH_FOR_COLLECT] = arg_9_0.totalHero_[xyd.DistanceType.ALL]
		arg_9_0.unCollected_[xyd.DistanceType.SEARCH_FOR_COLLECT] = arg_9_0.unCollected_[xyd.DistanceType.ALL]

		xyd.WindowManager.get():openWindow("toast", {
			message = xyd.tables.translation:translation("SEARCH_NO_RESULT")
		})
	end

	arg_9_0:sortTables()

	arg_9_0.heroRecommend.heros = arg_9_0.allHeros_
end

function var_0_0.scrollToHero(arg_10_0, arg_10_1)
	local var_10_0
	local var_10_1 = arg_10_0.totalHero_[arg_10_0.selectedHeroClass_]

	for iter_10_0, iter_10_1 in pairs(var_10_1) do
		if iter_10_1.heroID_ == arg_10_1 then
			var_10_0 = iter_10_0

			break
		end
	end

	if not var_10_0 then
		return
	end

	if var_10_0 > 3 and var_10_0 < #var_10_1 - 3 and #var_10_1 >= 6 then
		arg_10_0.heroList_:scrollTo(-(var_10_0 - 4) * 185 - 126, 0)
	elseif var_10_0 >= #var_10_1 - 3 and #var_10_1 >= 6 then
		arg_10_0.heroList_:scrollTo(-(#var_10_1 - 6) * 185 - 60, 0)
	elseif var_10_0 < 3 then
		arg_10_0.heroList_:scrollTo(0, 0)
	end
end

function var_0_0.scrollToHero1(arg_11_0, arg_11_1)
	local var_11_0
	local var_11_1 = arg_11_0.totalHero_[xyd.DistanceType.ALL]

	for iter_11_0, iter_11_1 in pairs(var_11_1) do
		if iter_11_1.heroID_ == arg_11_1 then
			var_11_0 = iter_11_0

			break
		end
	end

	if not var_11_0 then
		return
	end

	arg_11_0.heroList_:scrollTo(-(var_11_0 - 1) * 185, 0)
end

function var_0_0.sortTables(arg_12_0)
	local function var_12_0(arg_13_0)
		local var_13_0 = true

		if arg_13_0:getStar() >= xyd.MAX_STAR_LEVEL or arg_13_0:getSuiPian() < xyd.StarLevelSuipian[arg_13_0:getStar() + 1] then
			var_13_0 = false
		end

		return var_13_0
	end

	for iter_12_0 = 1, #arg_12_0.totalHero_ do
		table.sort(arg_12_0.totalHero_[iter_12_0], function(arg_14_0, arg_14_1)
			if arg_14_0:canSummon() and not arg_14_1:canSummon() then
				return true
			elseif arg_14_1:canSummon() and not arg_14_0:canSummon() then
				return false
			end

			if var_12_0(arg_14_0) and var_12_0(arg_14_1) then
				return true
			elseif var_12_0(arg_14_1) and not var_12_0(arg_14_0) then
				return false
			end

			return xyd.heroNormalSort(arg_14_0, arg_14_1) or false
		end)
	end

	for iter_12_1 = 1, #arg_12_0.unCollected_ do
		table.sort(arg_12_0.unCollected_[iter_12_1], function(arg_15_0, arg_15_1)
			if arg_15_0:getSuiPian() / xyd.TotalStarSuipian[arg_15_0:getStar()] ~= arg_15_1:getSuiPian() / xyd.TotalStarSuipian[arg_15_1:getStar()] then
				return arg_15_0:getSuiPian() / xyd.TotalStarSuipian[arg_15_0:getStar()] > arg_15_1:getSuiPian() / xyd.TotalStarSuipian[arg_15_1:getStar()]
			else
				return arg_15_0:getSuiPian() > arg_15_1:getSuiPian()
			end
		end)
	end
end

function var_0_0.layout(arg_16_0)
	arg_16_0.splitLine_ = arg_16_0:nodeByName("split_line")

	arg_16_0:nodeByName("split_label"):setString(xyd.tables.translation:translation("LIST_HERO_NOT_CALL"))
	arg_16_0.splitLine_:setVisible(false)
	arg_16_0:initMenu()

	for iter_16_0 = 1, 2 do
		local var_16_0 = arg_16_0:nodeByName("img_label" .. iter_16_0)

		var_16_0:setTouchSwallowEnabled(false)
		var_16_0:setTouchEnabled(false)
		var_16_0:zorder(4)
	end

	arg_16_0:nodeByName("img_search"):setTouchSwallowEnabled(false)
	arg_16_0:nodeByName("img_search"):setTouchEnabled(false)
	arg_16_0:nodeByName("img_search"):zorder(4)

	local var_16_1 = arg_16_0:nodeByName("hero_list_layer")
	local var_16_2 = var_16_1:getContentSize().width
	local var_16_3 = var_16_1:getContentSize().height

	arg_16_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_16_2, var_16_3),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_16_1):onScroll(handler(arg_16_0, arg_16_0.scrollListener))

	arg_16_0.heroList_:setTouchSwallowEnabled(false)
	var_16_1:setTouchSwallowEnabled(false)

	arg_16_0.heroCells_ = {}

	arg_16_0.heroList_:setDelegate(handler(arg_16_0, arg_16_0.heroDelegate))

	arg_16_0.scrollx = 0
end

function var_0_0.scrollListener(arg_17_0, arg_17_1)
	if arg_17_1.name == "began" then
		arg_17_0.startClick_ = true
		arg_17_0.prevX_ = arg_17_1.x
	elseif arg_17_1.name == "moved" then
		arg_17_0.scrollx = arg_17_0.heroList_:getScrollNode():getPositionX()

		if 20 <= math.abs(arg_17_1.x - arg_17_0.prevX_) then
			arg_17_0.startClick_ = false
		end
	elseif arg_17_1.name == "scrollEnd" then
		arg_17_0.scrollx = arg_17_0.heroList_:getScrollNode():getPositionX()
	end
end

function var_0_0.initMenu(arg_18_0)
	arg_18_0.heroClassButtons_ = {}

	table.insert(arg_18_0.heroClassButtons_, arg_18_0:nodeByName("button_all"))
	table.insert(arg_18_0.heroClassButtons_, arg_18_0:nodeByName("button_filter"))
	table.insert(arg_18_0.heroClassButtons_, arg_18_0:nodeByName("button_search"))

	for iter_18_0 = 1, #arg_18_0.heroClassButtons_ do
		arg_18_0.heroClassButtons_[iter_18_0]:setZoomScale(0.3)
		arg_18_0.heroClassButtons_[iter_18_0]:addTouchEventListener(function(arg_19_0, arg_19_1)
			if arg_19_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				arg_18_0.selectedHeroClass_ = iter_18_0
				arg_18_0.scrollx = 0

				arg_18_0:refreshSelectedHeroClass()

				if iter_18_0 == 2 then
					local var_19_0 = {
						checkAwaken = 1
					}

					xyd.WindowManager.get():openWindow("hero_filter", var_19_0)
				end

				if iter_18_0 == 3 then
					xyd.WindowManager.get():openWindow("hero_search")
				end
			end
		end)
	end

	arg_18_0:nodeByName("button_preset"):setZoomScale(0.3)
	arg_18_0:nodeByName("button_preset"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended then
			local var_20_0 = {
				callback = function(arg_21_0)
					if arg_21_0 == 4 then
						arg_18_0:toHeroRecommend()
					else
						arg_18_0.selectedHeroClass_ = arg_21_0
						arg_18_0.scrollx = 0

						arg_18_0:refreshSelectedHeroClass()
					end
				end
			}

			xyd.WindowManager.get():openWindow("hero_preset", var_20_0)
		end
	end)
	arg_18_0:nodeByName("button_recommend"):setZoomScale(0.3)
	arg_18_0:nodeByName("button_recommend"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended then
			arg_18_0:toHeroRecommend()
		end
	end)
end

function var_0_0.toHeroRecommend(arg_23_0)
	if not arg_23_0.heroRecommend.recommendInfo then
		local var_23_0 = {}

		arg_23_0.heroRecommend:getRecommendInfo(var_23_0, function(arg_24_0, arg_24_1)
			if arg_24_0 == xyd.error.OK and arg_23_0 and not tolua.isnull(arg_23_0) then
				xyd.WindowManager.get():openWindow("hero_recommend")
			end
		end)
	else
		xyd.WindowManager.get():openWindow("hero_recommend")
	end
end

function var_0_0.initHeroCell(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	local function var_25_0(arg_26_0, arg_26_1)
		local var_26_0
		local var_26_1 = xyd.isSuperHero(arg_26_0) and arg_26_1 > xyd.MAX_STAR_LEVEL and "windows/common/small_pink_star.png" or "windows/common/small_yellow_star.png"

		return xyd.AssetLoader.get():loadSprite(var_26_1)
	end

	local var_25_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_list/hero_list_item.csb")
	local var_25_2 = var_25_1:getChildByName("background"):getContentSize()

	var_25_1:setContentSize(var_25_2.width, var_25_2.height)
	arg_25_1:setContentSize(var_25_2.width, var_25_2.height)

	if arg_25_3 and arg_25_2 > #arg_25_0.totalHero_[arg_25_0.selectedHeroClass_] or not arg_25_3 and arg_25_2 > #arg_25_0.unCollected_[arg_25_0.selectedHeroClass_] then
		return
	end

	var_25_1:setPosition(cc.p(0, 0))
	arg_25_1:addChild(var_25_1)
	var_25_1:setName("layout")

	local var_25_3 = var_25_1:getChildByName("background")
	local var_25_4

	if arg_25_3 then
		var_25_4 = arg_25_0.totalHero_[arg_25_0.selectedHeroClass_][arg_25_2]
	else
		var_25_4 = arg_25_0.unCollected_[arg_25_0.selectedHeroClass_][arg_25_2]
	end

	arg_25_1.heroID = var_25_4:getTableID()

	local var_25_5 = var_25_1:getChildByName("name_container")

	arg_25_1.nameLabel_ = var_25_5:getChildByName("name_text")

	arg_25_1.nameLabel_:enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_25_1.nameLabel_:setString(var_25_4:getName())
	arg_25_1.nameLabel_:getVirtualRenderer():setAdditionalKerning(3)

	if xyd.Color2Level[var_25_4:getColor()] ~= "" then
		local var_25_6 = {
			size = 22,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = arg_25_1.nameLabel_:getX() + arg_25_1.nameLabel_:getWidth(),
			y = arg_25_1.nameLabel_:getY(),
			color = xyd.color.HERO_QUALITY[var_25_4:getColor()],
			text = xyd.Color2Level[var_25_4:getColor()]
		}
		local var_25_7 = xyd.AssetLoader.get():loadLabel(var_25_6)

		var_25_7:addTo(var_25_5)
		var_25_7:align(display.LEFT_BOTTOM)
		var_25_7:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_25_5:size(arg_25_1.nameLabel_:getX() + arg_25_1.nameLabel_:getWidth() + 30)
	else
		var_25_5:size(arg_25_1.nameLabel_:getWidth())
	end

	var_25_5:pos(var_25_1:getWidth() / 2, var_25_5:getY())

	local var_25_8 = var_25_1:getChildByName("label_level")

	var_25_8:setString("LV." .. var_25_4:getLevel())
	var_25_8:setVisible(var_25_4:isCollected())

	local function var_25_9()
		local var_27_0 = xyd.AssetLoader.get():loadSprite("windows/common/long_border" .. var_25_4:getColor() .. ".png")

		if var_25_4:isAwaken() then
			if var_25_4:isAwakeTwice() then
				var_27_0 = xyd.AssetLoader.get():loadSprite("windows/common/long_border_awake_twice" .. var_25_4:getColor() .. ".png")
			else
				var_27_0 = xyd.AssetLoader.get():loadSprite("windows/common/long_border_awake" .. var_25_4:getColor() .. ".png")
			end
		end

		if var_25_4:getInscriptionKuangLevel() then
			var_27_0 = xyd.AssetLoader.get():loadSprite("windows/common/long_border_suit" .. var_25_4:getInscriptionKuangLevel() .. ".png")
		end

		if xyd.isSuperHero(var_25_4) then
			var_27_0 = xyd.AssetLoader.get():loadSprite("windows/common/long_border_super.png")
		end

		var_27_0:align(display.LEFT_BOTTOM, 0, -2)
		var_27_0:setName("border")
		var_27_0:addTo(var_25_1)
	end

	var_25_9()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_25_0):addEventListener(xyd.event.FRESH_EQUIPED_INSCRIPTION, function(arg_28_0)
		if arg_25_0 and not tolua.isnull(arg_25_0) and not tolua.isnull(var_25_1) then
			var_25_1:removeChildByName("border")
			var_25_9()
		end
	end)

	local var_25_10 = var_25_4:getStar()
	local var_25_11 = var_25_10

	if var_25_11 > xyd.MAX_STAR_LEVEL then
		var_25_11 = var_25_11 - xyd.MAX_STAR_LEVEL
	end

	local var_25_12 = var_25_0(var_25_4, var_25_10):getContentSize().width
	local var_25_13 = (var_25_1:getWidth() - var_25_11 * var_25_12) / 2
	local var_25_14 = var_25_1:getChildByName("node_pos"):getY()

	for iter_25_0 = 1, var_25_11 do
		local var_25_15 = var_25_0(var_25_4, var_25_10)

		var_25_1:addChild(var_25_15)
		var_25_15:x(var_25_13 + (iter_25_0 - 1) * var_25_12):y(var_25_14)
		var_25_15:setAnchorPoint(cc.p(0, 0.5))
	end

	local var_25_16 = xyd.AssetLoader.get():loadSprite("images/card_mask2.png")

	var_25_16:align(display.LEFT_BOTTOM, 0, 0)

	local var_25_17 = cc.ClippingNode:create()

	var_25_17:setStencil(var_25_16)
	var_25_17:setInverted(true)
	var_25_17:setAlphaThreshold(0)
	var_25_17:setName("clipper")

	local var_25_18

	if var_25_4:isCollected() then
		var_25_18 = xyd.getSmallCard(var_25_4, xyd.SkinDynamicPosType.PERSON_DISPLAY)
	else
		local var_25_19 = {
			filter = {}
		}

		var_25_19.filter.name = "GRAY"
		var_25_19.filter.value = {
			0.2,
			0.3,
			0.5,
			0.1
		}
		var_25_18 = xyd.SpriteLoader.new(var_25_4:getSmallCard(), nil, var_25_19, xyd.DefaultImageType.SMALL_CARD)
	end

	local var_25_20 = var_25_1:getChildByName("card")

	xyd.displaySpriteOnContainer(var_25_18, var_25_20, true)
	var_25_1:removeChild(var_25_20)
	var_25_17:addChild(var_25_20)
	var_25_20:setName("card")
	var_25_1:addChild(var_25_17, -1)

	local var_25_21 = var_25_4:getHeroType()

	var_25_1:getChildByName("strength"):setVisible(var_25_21 == xyd.HeroType.STRENGTH and var_25_4:isCollected())
	var_25_1:getChildByName("wise"):setVisible(var_25_21 == xyd.HeroType.WISE and var_25_4:isCollected())
	var_25_1:getChildByName("agile"):setVisible(var_25_21 == xyd.HeroType.AGILE and var_25_4:isCollected())
	var_25_1:getChildByName("wise"):setLocalZOrder(2)
	var_25_1:getChildByName("strength"):setLocalZOrder(2)
	var_25_1:getChildByName("agile"):setLocalZOrder(2)

	if var_25_4:isCollected() then
		var_25_1:getChildByName("item_bg1"):hide()

		local var_25_22 = display.newNode()
		local var_25_23 = display.newNode()

		var_25_22:size(var_25_1:getWidth(), 120)
		var_25_23:size(var_25_1:getWidth(), 120)
		var_25_22:align(display.LEFT_BOTTOM, 0, 0):addTo(var_25_1)
		var_25_23:align(display.LEFT_BOTTOM, 0, 0):addTo(var_25_1)

		for iter_25_1 = 1, xyd.MAX_ITEM_NUM do
			local var_25_24 = var_25_4:getEquipByIndexShow(iter_25_1)
			local var_25_25 = var_25_1:getChildByName("icon" .. iter_25_1)
			local var_25_26 = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
			local var_25_27 = var_25_25:getChildByName("hero_collect_hide")

			if var_25_27 then
				var_25_27:setVisible(false)
			end

			if var_25_24:isCollected() then
				local var_25_28 = var_25_24:getIcon()

				xyd.displaySpriteOnContainer(var_25_28, var_25_25, true)

				if iter_25_1 == 1 and xyd.tables.item:isAwakenItem(var_25_24:getTableID()) == 1 and var_25_4:canOpenAwakeTwiceMission() and not var_25_26:isHasAwakeOpen(xyd.AwakeType.HERO_TWICE) then
					local var_25_29 = "skeletons/ui_effect/awake_twice/awake_twice_effect1"
					local var_25_30 = var_0_4.new(var_25_29 .. ".json", var_25_29 .. ".atlas", 1)

					var_25_30:addTo(var_25_25)
					var_25_30:setAnchorPoint(cc.p(0.5, 0.5))
					var_25_30:setPosition(var_25_25:getWidth() / 2, var_25_25:getHeight() / 2)
					var_25_30:play(nil, true)
				end
			elseif var_25_24:getTableID() == 0 then
				var_25_27:setVisible(true)
			elseif iter_25_1 == 1 and var_25_4:isCanAwaken() and not var_25_26:isAwaking(var_25_4:getTableID(), xyd.AwakeType.HERO) and xyd.tables.item:isAwakenItem(var_25_24:getTableID()) == 1 and arg_25_0.selfPlayer.maxTeamLev >= 90 then
				var_25_27:setVisible(true)

				if not var_25_26:isHasAwakeOpen(xyd.AwakeType.HERO) and var_25_4:getLevel() >= xyd.tables.misc.awakenOpenLev then
					local var_25_31 = "skeletons/ui_effect/effect_awaken_item/effect_awaken_item1"
					local var_25_32 = var_0_4.new(var_25_31 .. ".json", var_25_31 .. ".atlas", 1)

					var_25_32:addTo(var_25_25)
					var_25_32:setAnchorPoint(cc.p(0.5, 0.5))
					var_25_32:setPosition(var_25_25:getWidth() / 2, var_25_25:getHeight() / 2)
					var_25_32:play(nil, true)
				end
			elseif (var_25_4:isHasItem(iter_25_1) or var_25_4:canComposeItem(iter_25_1)) and var_25_4:getLevel() >= var_25_24:getLevel() then
				local var_25_33 = xyd.AssetLoader.get():loadSprite("windows/common/green_plus.png")

				var_25_33:align(display.LEFT_BOTTOM, var_25_25:getX(), var_25_25:getY()):addTo(var_25_23)
				var_25_33:scale(var_25_25:getWidth() / var_25_33:getWidth())
			elseif (var_25_4:isHasItem(iter_25_1) or var_25_4:canComposeItem(iter_25_1)) and var_25_4:getLevel() < var_25_24:getLevel() then
				local var_25_34 = xyd.AssetLoader.get():loadSprite("windows/common/white_plus.png")

				var_25_34:align(display.LEFT_BOTTOM, var_25_25:getX(), var_25_25:getY()):addTo(var_25_22)
				var_25_34:scale(var_25_25:getWidth() / var_25_34:getWidth())
			else
				var_25_25:hide()
			end
		end

		if xyd.isSuperHero(var_25_4) then
			local var_25_35 = var_25_1:getChildByName("bar_text")
			local var_25_36 = var_25_1:getChildByName("stone_bar")
			local var_25_37 = 100

			if var_25_4:getStar() <= xyd.MAX_STAR_LEVEL or var_25_4:getStar() >= xyd.SUPER_HERO_TOTAL_STARS then
				var_25_35:setString(xyd.tables.translation:translation("TAITAN_TEXT_9"))

				var_25_37 = 100
			else
				var_25_35:setString(var_25_4:getSuiPian() .. "/" .. xyd.StarLevelSuipian[var_25_4:getStar() + 1])

				var_25_37 = math.min(var_25_4:getSuiPian() / xyd.StarLevelSuipian[var_25_4:getStar() + 1] * 100, 100)
			end

			var_25_36:setPercent(var_25_37)
		else
			local var_25_38 = var_25_1:getChildByName("bar_text")
			local var_25_39 = var_25_1:getChildByName("stone_bar")
			local var_25_40 = 100

			if var_25_4:getStar() >= xyd.MAX_STAR_LEVEL then
				var_25_38:setString(xyd.tables.translation:translation("HERO_MAIN_MAX_STAR"))

				var_25_40 = 100
			else
				var_25_38:setString(var_25_4:getSuiPian() .. "/" .. xyd.StarLevelSuipian[var_25_4:getStar() + 1])

				var_25_40 = math.min(var_25_4:getSuiPian() / xyd.StarLevelSuipian[var_25_4:getStar() + 1] * 100, 100)
			end

			var_25_39:setPercent(var_25_40)
		end

		if (function(arg_29_0)
			local var_29_0 = true

			if xyd.isSuperHero(arg_29_0) then
				if arg_29_0:getStar() <= xyd.MAX_STAR_LEVEL or arg_29_0:getStar() >= 8 or arg_29_0:getStar() > xyd.MAX_STAR_LEVEL and arg_29_0:getStar() < 8 and arg_29_0:getSuiPian() < xyd.StarLevelSuipian[arg_29_0:getStar() + 1] then
					var_29_0 = false
				end
			elseif arg_29_0:getStar() >= xyd.MAX_STAR_LEVEL or arg_29_0:getSuiPian() < xyd.StarLevelSuipian[arg_29_0:getStar() + 1] then
				var_29_0 = false
			end

			return var_29_0
		end)(var_25_4) then
			local var_25_41 = "skeletons/ui_effect/star_up_effect/star_up_effect"
			local var_25_42 = var_0_4.new(var_25_41 .. ".json", var_25_41 .. ".atlas", 1)

			var_25_42:addTo(var_25_1:getChildByName("star_effect_node"))
			var_25_42:setAnchorPoint(cc.p(0.5, 0.5))
			var_25_42:setPosition(var_25_1:getChildByName("star_effect_node"):getWidth() / 2, var_25_1:getChildByName("star_effect_node"):getHeight() / 2)
			var_25_42:play(nil, true)
			var_25_1:getChildByName("bar_text"):setVisible(false)
		end
	else
		var_25_1:getChildByName("item_bg2"):hide()

		local var_25_43 = var_25_1:getChildByName("stone_bar")
		local var_25_44 = math.min(var_25_4:getSuiPian() / xyd.TotalStarSuipian[var_25_4:getStar()] * 100, 100)

		var_25_43:setPercent(var_25_44)

		local var_25_45 = var_25_1:getChildByName("bar_text")
		local var_25_46 = ""

		if var_25_4:getSuiPian() >= xyd.TotalStarSuipian[var_25_4:getStar()] then
			var_25_46 = xyd.tables.translation:translation("HERO_KEZHAOHUAN")
		else
			var_25_46 = var_25_4:getSuiPian() .. "/" .. xyd.TotalStarSuipian[var_25_4:getStar()]
		end

		var_25_45:setString(var_25_46)
		var_25_45:enableOutline(cc.c4b(0, 0, 0, 175), 1)

		for iter_25_2 = 1, xyd.MAX_ITEM_NUM do
			var_25_1:getChildByName("icon" .. iter_25_2):setVisible(false)
		end
	end

	if not var_25_4:isCollected() and var_25_4:getSuiPian() >= xyd.TotalStarSuipian[var_25_4:getStar()] then
		local var_25_47 = "skeletons/ui_effect/common_effect_hero8/common_effect_hero8"
		local var_25_48 = var_25_47 .. ".json"
		local var_25_49 = var_25_47 .. ".atlas"
		local var_25_50 = var_0_4.new(var_25_48, var_25_49, 1)

		var_25_50:align(display.CENTER, arg_25_1:getWidth() / 2 - 3, arg_25_1:getHeight() / 2 - 8)
		arg_25_1:addChild(var_25_50, 1)
		var_25_50:play(nil, true)
	end

	if var_25_4:isHeroMarried() == true then
		var_25_1:getChildByName("married_icon"):setVisible(true)
	else
		var_25_1:getChildByName("married_icon"):setVisible(false)
	end

	arg_25_1:setTouchEnabled(true)
	arg_25_1:setTouchSwallowEnabled(false)
	arg_25_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
		if arg_30_0.name == "began" then
			arg_25_0.prevX_ = arg_30_0.x
			arg_25_0.prevY_ = arg_30_0.y
			arg_25_0.startClick_ = true
		elseif arg_30_0.name == "moved" then
			if math.abs(arg_30_0.y - arg_25_0.prevY_) > 5 or math.abs(arg_30_0.x - arg_25_0.prevX_) > 5 then
				arg_25_0.startClick_ = false
			end
		elseif arg_30_0.name == "ended" and arg_25_0.startClick_ then
			if xyd.WindowManager.get():isWindowOpen("guide") then
				xyd.WindowManager.get():closeWindow("guide")
			end

			if var_25_4:isCollected() then
				var_25_4 = arg_25_0.totalHero_[arg_25_0.selectedHeroClass_][arg_25_2]

				xyd.playButtonSound()

				local var_30_0 = xyd.StoryData.get():getGuideID()

				if var_30_0 < xyd.GuideStoryType.GUIDE_EQUIP_END then
					arg_25_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_HERO)
				elseif var_30_0 == xyd.GuideStoryType.GUIDE_STONE_ONE then
					arg_25_0.selfPlayer:sendOperationLog(xyd.StatID.ID_STONE_2)
				end

				xyd.Backend.get():request(xyd.mid.LOAD_SINGLE_ACTIVITY, {
					activity_id = xyd.Activities.HalfPriceSkill
				}, function(arg_31_0, arg_31_1)
					return
				end, nil, false, false)
				xyd.WindowManager.get():openWindow(xyd.WindowName.heroMainWnd, {
					heros = arg_25_0.totalHero_[arg_25_0.selectedHeroClass_],
					current = arg_25_2,
					scrollx = arg_25_0.scrollx
				})
			elseif var_25_4:getSuiPian() >= xyd.TotalStarSuipian[var_25_4:getStar()] then
				local var_30_1 = xyd.tables.star:summonPrice(var_25_4:getStar())
				local var_30_2 = {
					string.format(xyd.tables.translation:translation("SUMMON_HERO"), var_30_1)
				}

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_30_2, function()
					if var_30_1 > arg_25_0.selfPlayer.mana then
						xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):judgePush(4)
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("JINBI_ABSENCE"), function()
							local var_33_0 = xyd.FunctionID.ID_GOLD_HAND

							if arg_25_0.selfPlayer:isFuncOpen(var_33_0) == true then
								xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
							else
								local var_33_1 = xyd.tables.functionOpen:level(var_33_0)
								local var_33_2 = string.format(xyd.tables.translation:translation("FUNCTION_OPEN_TIP_LEVEL"), var_33_1)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_33_2
								})
							end
						end, nil, nil, arg_25_0.colorMode)
					else
						arg_25_0:summonHero(var_25_4)
					end
				end, {
					guideID = xyd.StoryData.get():getGuideID()
				}, 0, arg_25_0.colorMode)
			else
				local var_30_3 = xyd.tables.hero:stoneID(var_25_4:getTableID())

				xyd.WindowManager.get():openWindow("stone", {
					hero = var_25_4,
					itemComposeID = var_30_3
				})
			end
		end

		return true
	end)
end

function var_0_0.summonHero(arg_34_0, arg_34_1)
	arg_34_1:stoneSummonHero(function(arg_35_0, arg_35_1)
		if arg_35_0 == xyd.error.OK then
			local var_35_0 = {
				toStone = false,
				partnerID = arg_34_1:getTableID()
			}

			arg_34_0:hide()

			local var_35_1 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_35_0)

			cc.EventProxy.new(var_35_1, var_35_1):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
				arg_34_0:show()
			end)
			arg_34_0:update()
			arg_34_0.heroList_:reload()
		end
	end)
end

function var_0_0.updateAfterOpenMission(arg_37_0)
	arg_37_0.scrollNodePosX = arg_37_0.heroList_.scrollNode:getPositionX()
	arg_37_0.scrollNodePosY = arg_37_0.heroList_.scrollNode:getPositionY()

	arg_37_0.heroList_:reload()
	arg_37_0.heroList_.scrollNode:setPosition(arg_37_0.scrollNodePosX, arg_37_0.scrollNodePosY)
end

function var_0_0.isItemInViewRect(arg_38_0, arg_38_1)
	local var_38_0 = -200 - arg_38_0.heroList_:getScrollNode():getPositionX()
	local var_38_1 = var_38_0 + 1440

	if var_38_0 >= arg_38_1 * 185 or var_38_1 <= (arg_38_1 - 1) * 185 then
		return false
	else
		return true
	end
end

function var_0_0.heroDelegate(arg_39_0, arg_39_1, arg_39_2, arg_39_3)
	local var_39_0 = #arg_39_0.totalHero_[arg_39_0.selectedHeroClass_] + #arg_39_0.unCollected_[arg_39_0.selectedHeroClass_]

	if cc.ui.UIListView.COUNT_TAG == arg_39_2 then
		return var_39_0
	elseif cc.ui.UIListView.CELL_TAG == arg_39_2 then
		local var_39_1
		local var_39_2
		local var_39_3
		local var_39_4 = arg_39_0.heroList_:dequeueItem()

		if not var_39_4 then
			var_39_4 = arg_39_0.heroList_:newItem()
		else
			var_39_4:removeAllChildren()
		end

		local var_39_5 = display.newNode()
		local var_39_6 = arg_39_3

		arg_39_0:isItemInViewRect(arg_39_3)

		local var_39_7 = display.newNode()

		if arg_39_0:isItemInViewRect(arg_39_3) then
			if arg_39_3 > #arg_39_0.totalHero_[arg_39_0.selectedHeroClass_] then
				var_39_6 = arg_39_3 - #arg_39_0.totalHero_[arg_39_0.selectedHeroClass_]

				arg_39_0:initHeroCell(var_39_7, var_39_6, false)
			else
				arg_39_0:initHeroCell(var_39_7, var_39_6, true)
			end
		else
			var_39_7:setContentSize(155, 450)
		end

		var_39_7:setAnchorPoint(cc.p(0, 0))
		var_39_7:pos(0, 0)
		var_39_5:addChild(var_39_7)
		var_39_7:setName("cell")

		var_39_5.heroID = var_39_7.heroID
		arg_39_0.heroCells_[arg_39_3] = var_39_5

		if arg_39_3 == #arg_39_0.totalHero_[arg_39_0.selectedHeroClass_] + 1 then
			local var_39_8 = arg_39_0.splitLine_:clone()

			var_39_8:setVisible(true)
			var_39_8:addTo(var_39_5)
			var_39_8:x(var_0_3 / 2):y(arg_39_0.heroList_.viewRect_.height / 2)
			var_39_5:size(var_39_7:getWidth() + var_0_3 * 2, var_39_7:getHeight())
			var_39_7:pos(var_0_3 * 2, 0)
			var_39_4:setItemSize(var_39_5:getWidth() + var_0_3, var_39_7:getHeight())
		else
			var_39_5:size(var_39_7:getWidth(), var_39_7:getHeight())
			var_39_4:setItemSize(var_39_5:getWidth() + var_0_3, var_39_7:getHeight())
		end

		var_39_5:align(display.CENTER, var_39_4:getWidth() / 2, var_39_4:getHeight() / 2)
		var_39_4:addContent(var_39_5)

		return var_39_4
	end
end

function var_0_0.refreshSelectedHeroClass(arg_40_0)
	for iter_40_0 = 1, #arg_40_0.heroClassButtons_ do
		if iter_40_0 == arg_40_0.selectedHeroClass_ then
			arg_40_0.heroClassButtons_[iter_40_0]:setBrightStyle(ccui.BrightStyle.highlight)
			arg_40_0.heroClassButtons_[iter_40_0]:zorder(3)
		else
			arg_40_0.heroClassButtons_[iter_40_0]:setBrightStyle(ccui.BrightStyle.normal)
			arg_40_0.heroClassButtons_[iter_40_0]:zorder(1)
		end
	end

	arg_40_0.heroList_:reload()
end

function var_0_0.setIDBeforeGuideWnd(arg_41_0)
	local var_41_0 = xyd.StoryData.get():getGuideID()

	if var_41_0 >= xyd.GuideStoryType.GUIDE_SKILL_START and var_41_0 < xyd.GuideStoryType.GUIDE_SKILL_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SKILL_ONE, true)
	elseif var_41_0 == xyd.GuideStoryType.GUIDE_LEVUP_END then
		arg_41_0.selfPlayer:sendOperationLog(xyd.StatID.ID_LEVUP_5)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_START, true)
	elseif var_41_0 == xyd.GuideStoryType.ACTIVITY_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_ONE, true)
	end
end

function var_0_0.setIDAfterGuideWnd(arg_42_0)
	local var_42_0 = xyd.StoryData.get():getGuideID()

	if var_42_0 < xyd.GuideStoryType.GUIDE_EQUIP_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_TWO)
	elseif var_42_0 == xyd.GuideStoryType.GUIDE_LEVUP_ONE then
		arg_42_0.selfPlayer:sendOperationLog(xyd.StatID.ID_LEVUP_1)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_TWO)
	elseif var_42_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_THREE then
		arg_42_0.selfPlayer:sendOperationLog(xyd.StatID.ID_JINJIE_4)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_FOUR)
	elseif var_42_0 == xyd.GuideStoryType.GUIDE_SKILL_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SKILL_TWO)
	elseif var_42_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_NINE then
		arg_42_0.selfPlayer:sendOperationLog(xyd.StatID.ID_JINJIE_10)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_END)
		xyd.StoryData.get():persist()
	elseif var_42_0 == xyd.GuideStoryType.ACTIVITY_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_THREE)
		xyd.StoryData.get():persist()
	elseif var_42_0 == xyd.GuideStoryType.GUIDE_FIGHT_6_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_6_ONE)
		xyd.StoryData.get():persist()
	end
end

function var_0_0.checkGuideIntoHero(arg_43_0)
	local var_43_0 = xyd.StoryData.get():getGuideID()

	if var_43_0 >= xyd.GuideStoryType.GUIDE_EQUIP_START and var_43_0 < xyd.GuideStoryType.GUIDE_EQUIP_END or var_43_0 == xyd.GuideStoryType.GUIDE_LEVUP_ONE or var_43_0 == xyd.GuideStoryType.GUIDE_LEVUP_START or var_43_0 >= xyd.GuideStoryType.GUIDE_SKILL_START and var_43_0 < xyd.GuideStoryType.GUIDE_SKILL_END or var_43_0 == xyd.GuideStoryType.GUIDE_STONE_ONE or var_43_0 == xyd.GuideStoryType.GUIDE_STONE_END or var_43_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_THREE then
		return true
	end

	return false
end

function var_0_0.checkGuideCloseWnd(arg_44_0)
	local var_44_0 = xyd.StoryData.get():getGuideID()

	if var_44_0 == xyd.GuideStoryType.GUIDE_EQUIP_END or var_44_0 == xyd.GuideStoryType.GUIDE_LEVUP_FOUR or var_44_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_NINE or var_44_0 == xyd.GuideStoryType.ACTIVITY_START or var_44_0 == xyd.GuideStoryType.GUIDE_FIGHT_6_START then
		return true
	end

	return false
end

function var_0_0.getGuideHeroCell(arg_45_0)
	local var_45_0 = xyd.StoryData.get():getGuideID()
	local var_45_1 = 10001001

	if var_45_0 == xyd.GuideStoryType.GUIDE_LEVUP_ONE or var_45_0 == xyd.GuideStoryType.GUIDE_STONE_ONE then
		var_45_1 = 10001004
	end

	for iter_45_0 = 1, #arg_45_0.heroCells_ do
		if arg_45_0.heroCells_[iter_45_0].heroID == var_45_1 then
			return arg_45_0.heroCells_[iter_45_0]
		end
	end

	return arg_45_0.heroCells_[1]
end

function var_0_0.playGuide(arg_46_0)
	local var_46_0 = xyd.StoryData.get():getGuideID()

	if arg_46_0:checkGuideIntoHero() then
		arg_46_0:setIDBeforeGuideWnd()
		arg_46_0.heroList_:setViewCanNotScroll(true)

		var_46_0 = xyd.StoryData.get():getGuideID()

		local var_46_1 = arg_46_0:getGuideHeroCell()
		local var_46_2 = {
			480,
			200
		}
		local var_46_3 = true

		if var_46_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_THREE or var_46_0 == xyd.GuideStoryType.GUIDE_LEVUP_ONE then
			var_46_3 = false
		end

		xyd.showGuideWnd(var_46_1, nil, nil, 3, var_46_2, var_46_3, true)
		arg_46_0:setIDAfterGuideWnd()
	elseif arg_46_0:checkGuideCloseWnd() then
		arg_46_0:setIDBeforeGuideWnd()

		local var_46_4 = arg_46_0:nodeByName("close")
		local var_46_5 = {
			300,
			500
		}

		xyd.showGuideWnd(var_46_4, nil, nil, 1, var_46_5, true)
		arg_46_0:setIDAfterGuideWnd()
	elseif var_46_0 == xyd.GuideStoryType.GUIDE_LEVUP_END then
		arg_46_0:setIDBeforeGuideWnd()
		arg_46_0:showOnlyDialogGuide()
	end
end

function var_0_0.showOnlyDialogGuide(arg_47_0, arg_47_1)
	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	if xyd.WindowManager.get():isWindowOpen("guide_only_dialog") then
		xyd.WindowManager.get():closeWindow("guide_only_dialog")
	end

	local var_47_0 = true
	local var_47_1 = cc.p(300, 300)
	local var_47_2 = {
		tipPosition = var_47_1,
		right = var_47_0
	}

	if arg_47_1 then
		var_47_2.callback = arg_47_1
	else
		function var_47_2.callback()
			arg_47_0:playGuide()
		end
	end

	local var_47_3 = xyd.WindowManager.get():openWindow("guide_only_dialog", var_47_2)
end

function var_0_0.onUpdateSmallCard(arg_49_0, arg_49_1)
	local var_49_0 = arg_49_1.heroID
	local var_49_1 = arg_49_0.selfPlayer:getHeroByTableID(var_49_0)

	for iter_49_0, iter_49_1 in pairs(arg_49_0.heroCells_) do
		if iter_49_1.heroID == var_49_0 then
			local var_49_2 = iter_49_1:getChildByName("cell"):getChildByName("layout")
			local var_49_3

			if var_49_1:isCollected() then
				var_49_3 = xyd.SpriteLoader.new(var_49_1:getSmallCard(), nil, nil, xyd.DefaultImageType.SMALL_CARD)
			else
				local var_49_4 = {
					filter = {}
				}

				var_49_4.filter.name = "GRAY"
				var_49_4.filter.value = {
					0.2,
					0.3,
					0.5,
					0.1
				}
				var_49_3 = xyd.SpriteLoader.new(var_49_1:getSmallCard(), nil, var_49_4, xyd.DefaultImageType.SMALL_CARD)
			end

			local var_49_5 = var_49_2:getChildByName("clipper"):getChildByName("card")

			var_49_5:removeAllChildren()
			xyd.displaySpriteOnContainer(var_49_3, var_49_5, true)
		end
	end
end

function var_0_0.onUpdateStoneNum_(arg_50_0, arg_50_1)
	local var_50_0 = arg_50_1.params.itemComposeID

	if xyd.tables.item:type(var_50_0) ~= 3 then
		return
	end

	local var_50_1 = xyd.tables.hero:getStoneTable()
	local var_50_2 = table.keyof(var_50_1, var_50_0)
	local var_50_3 = arg_50_0.selfPlayer:getHeroByTableID(var_50_2)

	if not var_50_3 then
		for iter_50_0, iter_50_1 in pairs(arg_50_0.unCollected_[arg_50_0.selectedHeroClass_]) do
			if iter_50_1:getTableID() == var_50_2 then
				var_50_3 = iter_50_1

				break
			end
		end
	end

	if not var_50_3 then
		return
	end

	for iter_50_2, iter_50_3 in pairs(arg_50_0.heroCells_) do
		if iter_50_3.heroID == var_50_2 then
			local var_50_4 = iter_50_3:getChildByName("cell"):getChildByName("layout")
			local var_50_5 = var_50_4:getChildByName("bar_text")
			local var_50_6 = var_50_4:getChildByName("stone_bar")

			if var_50_3:isCollected() then
				local var_50_7

				if var_50_3:getStar() >= xyd.MAX_STAR_LEVEL then
					var_50_5:setString(xyd.tables.translation:translation("HERO_MAIN_MAX_STAR"))

					var_50_7 = 100
				else
					var_50_5:setString(var_50_3:getSuiPian() .. "/" .. xyd.StarLevelSuipian[var_50_3:getStar() + 1])

					var_50_7 = math.min(var_50_3:getSuiPian() / xyd.StarLevelSuipian[var_50_3:getStar() + 1] * 100, 100)
				end

				var_50_6:setPercent(var_50_7)
			else
				local var_50_8 = math.min(var_50_3:getSuiPian() / xyd.TotalStarSuipian[var_50_3:getStar()] * 100, 100)

				var_50_6:setPercent(var_50_8)

				local var_50_9

				if var_50_3:getSuiPian() >= xyd.TotalStarSuipian[var_50_3:getStar()] then
					var_50_9 = xyd.tables.translation:translation("HERO_KEZHAOHUAN")
				else
					var_50_9 = var_50_3:getSuiPian() .. "/" .. xyd.TotalStarSuipian[var_50_3:getStar()]
				end

				var_50_5:setString(var_50_9)
				var_50_5:enableOutline(cc.c4b(0, 0, 0, 175), 1)
			end
		end
	end
end

return var_0_0
