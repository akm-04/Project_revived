local var_0_0 = class("BossMapDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.battle
local var_0_3 = 100
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.model.Pet")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.chapter = arg_1_2.chapter
	arg_1_0.chapterType = arg_1_2.chapter_type

	arg_1_0:setTouchSwallowEnabled(true)
end

function var_0_0.layout(arg_2_0)
	arg_2_0:nodeByName("txt_desc"):setString(xyd.tables.chapter:hideBossMesc(arg_2_0.chapter))
	arg_2_0:nodeByName("title_pos"):setString(xyd.tables.chapter:name(arg_2_0.chapter))
	arg_2_0:nodeByName("txt_equip"):setString(var_0_1:translation("NEW_MAP_GET_TXT"))

	local var_2_0 = {
		viewRect = cc.rect(65, 10, arg_2_0:nodeByName("panel_equip"):getContentSize().width - 70, var_0_3),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}

	arg_2_0.listview = cc.ui.UIListView.new(var_2_0):addTo(arg_2_0:nodeByName("panel_equip")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	local var_2_1 = xyd.tables.chapter:rewardDisplay(arg_2_0.chapter)
	local var_2_2 = xyd.tables.chapter:rewardDisplayNums(arg_2_0.chapter)

	for iter_2_0 = 1, #var_2_1 do
		local var_2_3 = cc.Node:create()
		local var_2_4 = display.newNode()
		local var_2_5 = arg_2_0.listview:newItem()

		var_2_3:setContentSize(100, 100)
		xyd.setItemBorder(var_2_3, var_2_1[iter_2_0])

		local var_2_6 = {
			id = var_2_1[iter_2_0]
		}

		xyd.addTips(var_2_3, var_2_6)
		var_2_4:addChild(var_2_3)
		var_2_4:setContentSize(var_0_3 + 7, var_0_3)
		var_2_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_2_3:setPosition(var_0_3 / 2, var_0_3 / 2)
		var_2_5:addContent(var_2_4)
		var_2_5:setItemSize(var_0_3 + 7, var_0_3)
		arg_2_0.listview:addItem(var_2_5)

		if iter_2_0 == 1 then
			arg_2_0.dormItem = var_2_3
		end
	end

	arg_2_0.listview:reload()
	arg_2_0:updateLayout()
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevX_ = arg_3_1.x
	elseif arg_3_1.name == "moved" and 20 <= math.abs(arg_3_1.x - arg_3_0.prevX_) then
		arg_3_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateLayout(arg_4_0)
	local var_4_0 = arg_4_0.selfPlayer.chapterEvents[arg_4_0.chapter] or {}

	arg_4_0:nodeByName("left_label"):setString(var_0_1:translation("MAP_LEFT_TIMES"))
	arg_4_0:nodeByName("tips_txt1"):setString(var_0_1:translation("BOSS_MAP_DETAIL_TEXT1"))
	arg_4_0:nodeByName("tips_txt3"):setString(var_0_1:translation("BOSS_MAP_DETAIL_TEXT2"))
	arg_4_0:nodeByName("tips_txt2"):setString(string.format("%d/%d", var_4_0.cost, xyd.tables.chapter:eventEnergyNeed(arg_4_0.chapter)))
	arg_4_0:nodeByName("left_times_txt"):setString(var_4_0.left_times or 0)

	local var_4_1 = 10

	for iter_4_0 = 2, 3 do
		arg_4_0:nodeByName("tips_txt" .. iter_4_0):setPositionX(arg_4_0:nodeByName("tips_txt" .. iter_4_0 - 1):getPositionX() + arg_4_0:nodeByName("tips_txt" .. iter_4_0 - 1):getContentSize().width + var_4_1)
	end

	local var_4_2 = var_4_0.val * 100 / var_4_0.record

	if var_4_2 < 0.1 then
		var_4_2 = 0.1
	end

	arg_4_0:nodeByName("progress_bar"):setPercent(var_4_2)
	arg_4_0:nodeByName("progress_txt"):setString(string.format("%.1f", var_4_2) .. "%")
	arg_4_0:nodeByName("progress_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 1)

	if var_4_0.left_times <= 0 then
		arg_4_0:nodeByName("start"):setBright(false)
		arg_4_0:nodeByName("start"):setTouchEnabled(false)
	end
end

function var_0_0.willOpen(arg_5_0, arg_5_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.GUIDE_WINODW_CLOSE, function(arg_6_0)
		if arg_5_0 and not tolua.isnull(arg_5_0) then
			arg_5_0:playGuide()
		end
	end)
	arg_5_0:layout()
	arg_5_0:updateModelContainer()
end

function var_0_0.updateModelContainer(arg_7_0)
	arg_7_0:nodeByName("model_container"):removeAllChildren()

	local var_7_0 = arg_7_0:nodeByName("model_container"):getContentSize()
	local var_7_1 = xyd.tables.chapter:eventBossId(arg_7_0.chapter)
	local var_7_2 = xyd.tables.chapter:hideSmallBg(arg_7_0.chapter)

	if var_7_2 and var_7_2 ~= "" then
		local var_7_3 = xyd.SpriteLoader.new(var_7_2, nil, nil, xyd.DefaultImageType.SMALL_MAP_BG)

		var_7_3:addTo(arg_7_0:nodeByName("model_container"))
		var_7_3:setPosition(cc.p(var_7_0.width / 2, var_7_0.height / 2))
	end

	if var_7_1 and var_7_1 > 0 then
		local var_7_4 = xyd.tables.hero:modelID(var_7_1)
		local var_7_5 = xyd.HeroAnimation.new(nil, var_7_4, xyd.tables.model:uiScale(var_7_4) * 0.8, {})

		var_7_5:addTo(arg_7_0:nodeByName("model_container"))
		var_7_5:setPosition(cc.p(var_7_0.width / 2, 30))
		var_7_5:idle()
	end
end

function var_0_0.didOpen(arg_8_0)
	arg_8_0:nodeByName("start"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if xyd.WindowManager.get():getWindow("guide") then
				xyd.WindowManager.get():closeWindow("guide")
			end

			if not arg_8_0.selfPlayer.chapterEvents[arg_8_0.chapter] then
				local var_9_0 = {}
			end

			arg_8_0:startChapterBossBattle(arg_8_0.chapter)
		end
	end)
	arg_8_0:addBlockLayer(nil, false, true)
	arg_8_0:playGuide()
end

function var_0_0.startChapterBossBattle(arg_10_0, arg_10_1)
	local var_10_0 = {
		campaign_type = xyd.CampaignType.CHAPTER_BOSS
	}

	arg_10_0.guild:loadAllTeamHeros(var_10_0, function(arg_11_0)
		local var_11_0 = false
		local var_11_1 = {}

		if arg_11_0 == xyd.error.OK then
			var_11_0 = true

			local var_11_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

			for iter_11_0, iter_11_1 in ipairs(var_11_2:getAllTeamHeros()) do
				local var_11_3 = var_0_4.new()

				var_11_3:populate(iter_11_1)

				var_11_3.player_name = iter_11_1.player_name
				var_11_3.rent_need_mana = iter_11_1.rent_need_mana
				var_11_3.can_rent = iter_11_1.can_rent
				var_11_3.player_id = iter_11_1.player_id

				table.insert(var_11_1, var_11_3)
			end
		end

		local var_11_4 = xyd.tables.chapter:eventBossId(arg_10_1)
		local var_11_5 = xyd.tables.chapter:eventBattleId(arg_10_1)
		local var_11_6 = {
			type = xyd.SelectTeamType.CHAPTER_BOSS,
			battleID = var_11_5,
			campaignType = xyd.CampaignType.CHAPTER_BOSS,
			chapter = arg_10_0.chapter,
			chapterType = arg_10_0.chapterType,
			isMercenary = var_11_0,
			allTeamHeros = var_11_1
		}

		xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_11_6)
	end)
end

function var_0_0.playGuide(arg_12_0)
	local var_12_0 = xyd.StoryData.get():getGuideID()
	local var_12_1
	local var_12_2 = {
		920,
		350
	}

	if var_12_0 >= xyd.GuideStoryType.GUIDE_CHAPTER_BOSS_START and var_12_0 < xyd.GuideStoryType.GUIDE_CHAPTER_BOSS_END then
		if var_12_0 == xyd.GuideStoryType.GUIDE_CHAPTER_BOSS_START then
			var_12_1 = arg_12_0.dormItem
		elseif var_12_0 == xyd.GuideStoryType.GUIDE_CHAPTER_BOSS_ONE then
			var_12_1 = arg_12_0:nodeByName("tips_txt2")
			var_12_2 = {
				500,
				150
			}
		elseif var_12_0 == xyd.GuideStoryType.GUIDE_CHAPTER_BOSS_TWO then
			var_12_1 = arg_12_0:nodeByName("start")
			var_12_2 = {
				920,
				250
			}
		end

		local var_12_3 = var_12_0 + 1

		xyd.StoryData.get():setGuideID(var_12_3, true)
	end

	if var_12_1 then
		xyd.showGuideWnd(var_12_1, nil, nil, 2, var_12_2, true)
	end
end

return var_0_0
