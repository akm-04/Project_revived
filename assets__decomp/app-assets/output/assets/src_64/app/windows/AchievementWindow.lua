local var_0_0 = class("AchievementWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("app.common.ui.EcoSidebar")
local var_0_3 = xyd.tables.translation
local var_0_4 = 3
local var_0_5 = "skeletons/ui_effect/achievement/chest_new"
local var_0_6 = "skeletons/ui_effect/achievement/achievement_baoxiang_spin"
local var_0_7 = "skeletons/ui_effect/achievement/achievement_cup_silver"
local var_0_8 = "skeletons/ui_effect/achievement/achievement_cup_gold"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.isOnlyShowUnfinish = false
	arg_1_0.arena = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.achievement = xyd.ModelManager.get():loadModel(xyd.ModelType.ACHIEVEMENT)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.award = {
		is_partner = false,
		item_num = false,
		to_stone = false,
		table_id = 50001039
	}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addTopSidebar()
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	if arg_3_0.callback then
		arg_3_0.callback()
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0.award_lev = 2
	arg_4_0.main_container = arg_4_0:nodeByName("main_container")

	local var_4_0 = arg_4_0.main_container:getContentSize()

	arg_4_0.mainList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.main_container):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0)

	arg_4_0.mainList_:setDelegate(handler(arg_4_0, arg_4_0.achievementDelegate))
	arg_4_0.mainList_:reload()
	arg_4_0:setButtonClick()
	arg_4_0:updateLeftContainer()
	arg_4_0:updateChangeAchievementsBtnShow()

	local var_4_1 = cc.c4b(147, 235, 187, 0)
	local var_4_2 = 1000

	arg_4_0.blockLayer_ = display.newColorLayer(var_4_1)

	local var_4_3 = arg_4_0:nodeByName("background"):convertToWorldSpace(cc.p(0, 0))

	arg_4_0.blockLayer_:pos(-var_4_3.x, -var_4_3.y):addTo(arg_4_0:nodeByName("background"), var_4_2)
	arg_4_0.blockLayer_:setLocalZOrder(1000)
	arg_4_0.blockLayer_:setTouchEnabled(true)
	arg_4_0.blockLayer_:setTouchSwallowEnabled(true)
	arg_4_0.blockLayer_:setVisible(false)
	arg_4_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" and not arg_4_0.isPlayingEffect then
			return true
		elseif arg_5_0.name == "ended" then
			arg_4_0:nodeByName("effect_pos"):removeAllChildren(true)
			arg_4_0:nodeByName("all_btn"):setTouchEnabled(true)
			arg_4_0:nodeByName("not_get_btn"):setTouchEnabled(true)
			arg_4_0:nodeByName("view_all_awards_btn"):setTouchEnabled(true)
			arg_4_0:updateLeftContainer()
			arg_4_0.blockLayer_:setVisible(false)
		end
	end)
	arg_4_0:nodeByName("partner"):setVisible(false)

	local var_4_4 = "skeletons/dynamic_card/caozhi/caozhipifudongtai"

	xyd.EffectLoader.new(var_4_4, 3, 1, {
		x = 455,
		y = -5
	}, true):addTo(arg_4_0:nodeByName("node_partner"))
end

function var_0_0.playOpenEffect(arg_6_0, arg_6_1)
	if arg_6_0.openEffect and not tolua.isnull(arg_6_0.openEffect) then
		arg_6_0.openEffect:removeFromParent(true)
	end

	local var_6_0 = var_0_5 .. ".json"
	local var_6_1 = var_0_5 .. ".atlas"

	arg_6_0.openEffect = var_0_1.new(var_6_0, var_6_1, 1)

	arg_6_0.openEffect:addTo(arg_6_0:nodeByName("effect_pos"))
	arg_6_0.openEffect:setAnchorPoint(cc.p(0.5, 0.5))

	local var_6_2 = var_0_6 .. ".json"
	local var_6_3 = var_0_6 .. ".atlas"

	arg_6_0.spinEffect = var_0_1.new(var_6_2, var_6_3, 1)

	arg_6_0.spinEffect:addTo(arg_6_0:nodeByName("effect_pos"))
	arg_6_0.spinEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_6_0.spinEffect:setPositionY(10)

	arg_6_0.isPlayingEffect = true

	arg_6_0:nodeByName("get_award_btn"):setBright(false)
	arg_6_0:nodeByName("get_award_btn"):setTouchEnabled(false)
	arg_6_0:nodeByName("all_btn"):setTouchEnabled(false)
	arg_6_0:nodeByName("not_get_btn"):setTouchEnabled(false)
	arg_6_0:nodeByName("view_all_awards_btn"):setTouchEnabled(false)
	arg_6_0:nodeByName("box_get_award"):setTouchEnabled(false)
	arg_6_0.blockLayer_:setVisible(true)
	arg_6_0.openEffect:play(function()
		local var_7_0 = display.newNode()

		var_7_0:setContentSize(85, 85)
		var_7_0:setAnchorPoint(cc.p(0.5, 0.5))

		if arg_6_1 then
			xyd.setItemBorder(var_7_0, arg_6_1.table_id, nil, nil, arg_6_1.item_num)
		end

		var_7_0:addTo(arg_6_0:nodeByName("effect_pos"))
		var_7_0:setPositionY(10)
		var_7_0:setScale(0)

		local var_7_1 = cc.Sequence:create(cc.ScaleTo:create(1, 1), cc.DelayTime:create(1), cc.CallFunc:create(function()
			arg_6_0.isPlayingEffect = false

			arg_6_0:nodeByName("effect_pos"):removeAllChildren(true)
			arg_6_0:nodeByName("all_btn"):setTouchEnabled(true)
			arg_6_0:nodeByName("not_get_btn"):setTouchEnabled(true)
			arg_6_0:nodeByName("view_all_awards_btn"):setTouchEnabled(true)
			arg_6_0:updateLeftContainer()
			arg_6_0.blockLayer_:setVisible(false)
		end))

		var_7_0:runAction(var_7_1)
	end, false, nil, "texiao02")
end

function var_0_0.playBoxEffect(arg_9_0)
	if arg_9_0.openEffect and not tolua.isnull(arg_9_0.openEffect) then
		arg_9_0.openEffect:removeFromParent(true)
	end

	local var_9_0 = var_0_5 .. ".json"
	local var_9_1 = var_0_5 .. ".atlas"

	arg_9_0.openEffect = var_0_1.new(var_9_0, var_9_1, 1)

	arg_9_0.openEffect:addTo(arg_9_0:nodeByName("effect_pos"))
	arg_9_0.openEffect:setAnchorPoint(cc.p(0.5, 0))
	arg_9_0.openEffect:setPositionY(-72)

	arg_9_0.isPlayingEffect = true

	arg_9_0:nodeByName("box_open"):setVisible(false)
	arg_9_0:nodeByName("box_close"):setVisible(false)
	arg_9_0:nodeByName("box_get_award"):setTouchEnabled(true)
	arg_9_0.openEffect:play(nil, true, nil, "texiao01")
end

function var_0_0.setButtonClick(arg_10_0)
	arg_10_0:nodeByName("all_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_10_0.isOnlyShowUnfinish = false

			arg_10_0:updateChangeAchievementsBtnShow()
			arg_10_0.mainList_:reload()
		end
	end)
	arg_10_0:nodeByName("not_get_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_10_0.isOnlyShowUnfinish = true

			arg_10_0:updateChangeAchievementsBtnShow()
			arg_10_0.mainList_:reload()
		end
	end)
	arg_10_0:nodeByName("view_all_awards_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("achievement_award")
		end
	end)
	arg_10_0:nodeByName("get_award_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_10_0.achievement:getAchievementAward({}, function(arg_15_0, arg_15_1)
				if arg_15_0 == xyd.error.OK then
					arg_10_0.achievement.baseInfo.award_status = arg_15_1.award_status

					local var_15_0 = xyd.WindowManager.get():getWindow("main_scene_top")

					if var_15_0 and not tolua.isnull(var_15_0) then
						var_15_0:updateAchievementRedMark()
					end

					if arg_10_0.callback then
						arg_10_0.callback()
					end

					arg_10_0:nodeByName("box_close"):setVisible(false)

					local var_15_1 = arg_15_1.awards[1]

					if not var_15_1 or not var_15_1.table_id then
						return
					end

					arg_10_0.selfPlayer:handleRewards(arg_15_1.awards)
					arg_10_0:playOpenEffect(var_15_1)

					if not arg_10_0.selfPlayer:getBackpack():getItemByID(var_15_1.table_id) then
						local var_15_2 = {}

						var_15_2.itemNum = 0
						var_15_2.itemID = var_15_1.table_id

						arg_10_0.selfPlayer:getBackpack():addItem(var_15_2)
					end

					arg_10_0.selfPlayer:getBackpack():setItemNumByID(var_15_1.table_id, var_15_1.item_num)
				end
			end)
		end
	end)
	arg_10_0:nodeByName("box_get_award"):setAnchorPoint(0.5, 0.5)
	arg_10_0:nodeByName("box_get_award"):setContentSize(162, 144)
	arg_10_0:nodeByName("box_get_award"):setTouchSwallowEnabled(false)
	arg_10_0:nodeByName("box_get_award"):setTouchEnabled(false)
	arg_10_0:nodeByName("box_get_award"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			return true
		elseif arg_16_0.name == "ended" then
			xyd.playButtonSound()
			arg_10_0.achievement:getAchievementAward({}, function(arg_17_0, arg_17_1)
				if arg_17_0 == xyd.error.OK then
					arg_10_0.achievement.baseInfo.award_status = arg_17_1.award_status

					local var_17_0 = xyd.WindowManager.get():getWindow("main_scene_top")

					if var_17_0 and not tolua.isnull(var_17_0) then
						var_17_0:updateAchievementRedMark()
					end

					if arg_10_0.callback then
						arg_10_0.callback()
					end

					arg_10_0:nodeByName("box_close"):setVisible(false)

					local var_17_1 = arg_17_1.awards[1]

					if not var_17_1 or not var_17_1.table_id then
						return
					end

					arg_10_0.selfPlayer:handleRewards(arg_17_1.awards)
					arg_10_0:playOpenEffect(var_17_1)

					if not arg_10_0.selfPlayer:getBackpack():getItemByID(var_17_1.table_id) then
						local var_17_2 = {}

						var_17_2.itemNum = 0
						var_17_2.itemID = var_17_1.table_id

						arg_10_0.selfPlayer:getBackpack():addItem(var_17_2)
					end

					arg_10_0.selfPlayer:getBackpack():setItemNumByID(var_17_1.table_id, var_17_1.item_num)
				end
			end)
		end
	end)
	arg_10_0:nodeByName("flag"):setTouchEnabled(true)
	arg_10_0:nodeByName("flag"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
		if arg_18_0.name == "began" then
			return true
		elseif arg_18_0.name == "ended" then
			local var_18_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RANK_LIST)

			var_18_0:loadRankList({
				xyd.SubRankType.ACHIEVEMENT_POINT
			}, true, function(arg_19_0, arg_19_1)
				if arg_19_0 == xyd.error.OK then
					local var_19_0 = {
						rank_type = xyd.RankType.Achievement,
						sub_type = xyd.SubRankType.ACHIEVEMENT_POINT,
						rankData = var_18_0:getRankList()
					}

					xyd.WindowManager.get():openWindow("new_rank_list", var_19_0)
				end
			end)
		end
	end)
end

function var_0_0.updateChangeAchievementsBtnShow(arg_20_0)
	if arg_20_0.isOnlyShowUnfinish == false then
		arg_20_0:nodeByName("all_btn"):getChildByName("all_chosen"):setVisible(true)
		arg_20_0:nodeByName("all_btn"):getChildByName("all_not_chosen"):setVisible(false)
		arg_20_0:nodeByName("not_get_btn"):getChildByName("not_get"):setVisible(true)
		arg_20_0:nodeByName("not_get_btn"):getChildByName("not_get_click"):setVisible(false)
		arg_20_0:nodeByName("all_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_20_0:nodeByName("not_get_btn"):setBrightStyle(ccui.BrightStyle.normal)
	else
		arg_20_0:nodeByName("all_btn"):getChildByName("all_chosen"):setVisible(false)
		arg_20_0:nodeByName("all_btn"):getChildByName("all_not_chosen"):setVisible(true)
		arg_20_0:nodeByName("not_get_btn"):getChildByName("not_get"):setVisible(false)
		arg_20_0:nodeByName("not_get_btn"):getChildByName("not_get_click"):setVisible(true)
		arg_20_0:nodeByName("all_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_20_0:nodeByName("not_get_btn"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.updateLeftContainer(arg_21_0)
	local var_21_0 = arg_21_0.achievement.baseInfo

	arg_21_0:nodeByName("lev_pos"):removeAllChildren(true)

	local var_21_1 = xyd.AssetLoader.get():loadLabel(nil, "achieve_level")

	var_21_1:setString(var_21_0.point_level)
	var_21_1:setAnchorPoint(cc.p(0, 0.5))
	var_21_1:addTo(arg_21_0:nodeByName("lev_pos"))
	arg_21_0:nodeByName("main_rank_pos"):removeAllChildren(true)

	local var_21_2 = xyd.AssetLoader.get():loadLabel(nil, "all_rank")

	var_21_2:setString(var_21_0.rank)
	var_21_2:setAnchorPoint(cc.p(0, 0.5))
	var_21_2:addTo(arg_21_0:nodeByName("main_rank_pos"))
	arg_21_0:nodeByName("box_close"):setVisible(false)
	arg_21_0:nodeByName("box_open"):setVisible(false)
	arg_21_0:nodeByName("award_icon"):setVisible(false)

	arg_21_0.awardLev = arg_21_0.achievement:getShowAwardLev()

	if var_21_0.award_status[arg_21_0.awardLev] == 0 or var_21_0.award_status[arg_21_0.awardLev] == 1 then
		arg_21_0:nodeByName("box_close"):setVisible(true)
	elseif var_21_0.award_status[arg_21_0.awardLev] == -1 then
		arg_21_0:nodeByName("box_open"):setVisible(true)
	end

	arg_21_0:nodeByName("main_rank_text"):setString(var_0_3:translation("ZHUGE_HOUSE_TIPS_15"))

	local var_21_3 = xyd.tables.achievementLevel:pointCondition(var_21_0.point_level)
	local var_21_4 = xyd.tables.achievementLevel:pointCondition(var_21_0.point_level + 1)

	if var_21_4 == 0 then
		var_21_4 = var_21_3
	end

	arg_21_0:nodeByName("progress_txt"):setString(var_21_0.total_points .. " / " .. var_21_4)
	arg_21_0:nodeByName("progress_bar"):setPercent(100 * var_21_0.total_points / var_21_4)
	arg_21_0:nodeByName("get_award_btn"):setBright(true)
	arg_21_0:nodeByName("get_award_btn"):setTouchEnabled(true)
	arg_21_0:nodeByName("box_get_award"):setTouchEnabled(true)

	if arg_21_0.achievement:getCanAwardLev() == 0 then
		arg_21_0:nodeByName("get_award_btn"):setBright(false)
		arg_21_0:nodeByName("get_award_btn"):setTouchEnabled(false)
		arg_21_0:nodeByName("box_get_award"):setTouchEnabled(false)
	else
		arg_21_0:playBoxEffect()
	end
end

function var_0_0.achievementDelegate(arg_22_0, arg_22_1, arg_22_2, arg_22_3)
	if arg_22_0.isOnlyShowUnfinish == false then
		arg_22_0.data = arg_22_0.achievement.achieveList or {}
	else
		arg_22_0.data = arg_22_0.achievement.unfinishList or {}
	end

	if cc.ui.UIListView.COUNT_TAG == arg_22_2 then
		return math.ceil(#arg_22_0.data / var_0_4)
	elseif cc.ui.UIListView.CELL_TAG == arg_22_2 then
		local var_22_0 = arg_22_0.mainList_:dequeueItem()

		if not var_22_0 then
			var_22_0 = arg_22_0.mainList_:newItem()
		else
			var_22_0:removeAllChildren(true)
		end

		local var_22_1 = arg_22_0:createAchieveLine(arg_22_3)
		local var_22_2 = var_22_1:getWidth()
		local var_22_3 = var_22_1:getHeight()

		var_22_0:setItemSize(var_22_2, var_22_3)
		var_22_0:addContent(var_22_1)

		return var_22_0
	end
end

function var_0_0.createAchieveLine(arg_23_0, arg_23_1)
	local var_23_0 = display.newNode()
	local var_23_1 = 212
	local var_23_2 = 256
	local var_23_3 = 53
	local var_23_4 = 20

	if arg_23_1 == 1 then
		var_23_2 = 288
	end

	var_23_0:setContentSize(729, var_23_2 + var_23_4)

	local var_23_5 = xyd.AssetLoader:get():loadSprite("windows/achievement/line.png")

	var_23_5:setAnchorPoint(cc.p(0, 0))
	var_23_5:addTo(var_23_0)
	var_23_5:setPosition(cc.p(0, 0))

	for iter_23_0 = 1, var_0_4 do
		local var_23_6
		local var_23_7 = {}

		if (arg_23_1 - 1) * var_0_4 + iter_23_0 <= #arg_23_0.data then
			var_23_7 = arg_23_0.data[(arg_23_1 - 1) * var_0_4 + iter_23_0]
			var_23_6 = arg_23_0:createAchievementItem(var_23_7)
		else
			return var_23_0
		end

		var_23_6:addTo(var_23_0)
		var_23_6:setPosition(cc.p(var_23_3, var_23_4))

		var_23_3 = var_23_3 + var_23_1

		var_23_6:setTouchEnabled(true)
		var_23_6:setTouchSwallowEnabled(false)
		var_23_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_24_0)
			if arg_24_0.name == "began" then
				return true
			elseif arg_24_0.name == "ended" then
				if arg_23_0.scrollViewMoved_ then
					return
				end

				local var_24_0 = {
					data = var_23_7
				}

				xyd.WindowManager.get():openWindow("achievement_detail", var_24_0)
			end
		end)
	end

	return var_23_0
end

function var_0_0.createAchievementItem(arg_25_0, arg_25_1)
	local var_25_0 = display.newNode()
	local var_25_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/achievement/achieve_item.csb")
	local var_25_2 = var_25_1:getChildByName("container")

	var_25_2:getChildByName("name_txt"):setString(xyd.tables.achievement:name(arg_25_1.achieve_id))

	local var_25_3 = arg_25_0.achievement:getLatestIndex(arg_25_1.complete_time)

	if var_25_3 == 0 then
		var_25_2:getChildByName("light"):setVisible(false)
		var_25_2:getChildByName("progress_txt"):setVisible(false)
		var_25_2:getChildByName("progress_txt_not"):setVisible(true)
		var_25_2:getChildByName("achieve_name_bg"):setVisible(false)
		var_25_2:getChildByName("achieve_name_bg2"):setVisible(true)
		var_25_2:getChildByName("progress_txt_not"):setString(var_0_3:translation("NOT_GET_TEXT"))
	else
		var_25_2:getChildByName("light"):setVisible(true)
		var_25_2:getChildByName("progress_txt"):setVisible(true)
		var_25_2:getChildByName("progress_txt_not"):setVisible(false)
		var_25_2:getChildByName("achieve_name_bg"):setVisible(true)
		var_25_2:getChildByName("achieve_name_bg2"):setVisible(false)
		var_25_2:getChildByName("progress_txt"):setString(arg_25_0.achievement:createFinishedTimeString(arg_25_1.complete_time[var_25_3]))
	end

	local var_25_4 = var_25_3

	if var_25_4 == 0 then
		var_25_4 = 1
	end

	local var_25_5 = xyd.tables.achievement:icon(arg_25_1.achieve_id) .. var_25_4 .. ".png"

	if var_25_3 == 0 then
		local var_25_6 = {
			filter = {}
		}

		var_25_6.filter.name = "GRAY"
		var_25_6.filter.value = {
			0.2,
			0.3,
			0.5,
			0.1
		}
		achieveIcon = xyd.SpriteLoader.new(var_25_5, nil, var_25_6, xyd.DefaultImageType.ACHIEVEMENT_ICON)
	else
		achieveIcon = xyd.SpriteLoader.new(var_25_5, nil, nil, xyd.DefaultImageType.ACHIEVEMENT_ICON)
	end

	achieveIcon:setScale(0.5)
	achieveIcon:setAnchorPoint(cc.p(0.5, 0))
	achieveIcon:addTo(var_25_2:getChildByName("icon_pos"))

	if var_25_3 == 3 then
		arg_25_0.achievement:addEffect(var_0_8, var_25_2:getChildByName("icon_pos"), cc.p(0, 85))
	elseif var_25_3 == 2 then
		arg_25_0.achievement:addEffect(var_0_7, var_25_2:getChildByName("icon_pos"), cc.p(0, 85))
	end

	var_25_1:addTo(var_25_0)
	var_25_1:setAnchorPoint(cc.p(0, 0))
	var_25_0:setContentSize(var_25_2:getContentSize())
	var_25_1:setName("source")

	return var_25_0
end

function var_0_0.refreshWindow(arg_26_0)
	arg_26_0:updateLeftContainer()
	arg_26_0.mainList_:reload()
end

function var_0_0.getLatestTime(arg_27_0, arg_27_1)
	for iter_27_0 = #arg_27_1, 1, -1 do
		if arg_27_1[iter_27_0] ~= 0 then
			return arg_27_1[iter_27_0]
		end
	end

	return 0
end

function var_0_0.createItemNumLabel(arg_28_0, arg_28_1)
	local var_28_0 = {
		font = "fonts/main_font.ttf",
		size = 30,
		color = cc.c3b(255, 255, 255)
	}
	local var_28_1 = xyd.AssetLoader.get():loadLabel(var_28_0)

	var_28_1:setMaxLineWidth(250)
	var_28_1:setString("X" .. arg_28_1)

	return var_28_1
end

function var_0_0.scrollListener(arg_29_0, arg_29_1)
	if arg_29_1.name == "began" then
		arg_29_0.scrollViewMoved_ = false
		arg_29_0.prevY_ = arg_29_1.y
	elseif arg_29_1.name == "moved" and 10 <= math.abs(arg_29_1.y - arg_29_0.prevY_) then
		arg_29_0.scrollViewMoved_ = true
	end
end

return var_0_0
