local var_0_0 = class("HeroTuJianWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.hero

var_0_0.LEFT = "left_btn"
var_0_0.RIGHT = "right_btn"

local var_0_4 = 14
local var_0_5 = math.ceil(var_0_4 / 2)
local var_0_6 = 158
local var_0_7 = 223
local var_0_8 = 16
local var_0_9 = 26

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.heroRecommend = xyd.ModelManager.get():loadModel(xyd.ModelType.HERO_RECOMMEND)
	arg_1_0.heroRecommend.recommendInfo = nil
	arg_1_0.playerLev = arg_1_0.selfPlayer.lev
	arg_1_0.heroShowList = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()
	arg_2_0:nodeByName("top_sidebar"):setLocalZOrder(-1)
	arg_2_0:nodeByName("eco_sidebar"):setVisible(false)
	arg_2_0:addThemeBG()

	arg_2_0.left = arg_2_0:nodeByName(var_0_0.LEFT)
	arg_2_0.right = arg_2_0:nodeByName(var_0_0.RIGHT)
	arg_2_0.heroShowType = 9

	if arg_2_1 and arg_2_1.hero_show_type then
		arg_2_0.heroShowType = arg_2_1.hero_show_type
	end

	arg_2_0:getHeroesData()
	arg_2_0:nodeByName("collect_txt"):setString(var_0_2:translation("TUJIAN_COLLECT_NUM") .. arg_2_0.ownHeroNum .. "/" .. #arg_2_0.hero_list)
	arg_2_0:nodeByName("collect_txt"):enableOutline(cc.c4b(136, 64, 47, 255), 1)
	arg_2_0:setTouchSwallowEnabled(true)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.listNode = arg_3_0:nodeByName("pos_line_1")
	arg_3_0.pageText_ = arg_3_0:nodeByName("page_txt")

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.HERO_TUJIAN_SEARCH, function(arg_4_0)
		if arg_4_0 and arg_4_0.heroName and arg_4_0.heroName ~= var_0_2:translation("HERO_SEARCH_TIPS") then
			arg_3_0.heroName = arg_4_0.heroName
			arg_3_0.filterParams = nil

			arg_3_0:getHeroesData()
			arg_3_0:switchHeroGroup()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.HERO_TUJIAN_FILTER, function(arg_5_0)
		if arg_5_0 and arg_5_0.filterParams then
			arg_3_0.filterParams = arg_5_0.filterParams
			arg_3_0.heroName = nil

			arg_3_0:getHeroesData()
			arg_3_0:switchHeroGroup()
		end
	end)

	local var_3_0 = xyd.AssetLoader.get()
	local var_3_1 = 24
	local var_3_2 = arg_3_0:nodeByName("num_panel")
	local var_3_3 = "windows/login/transparent.png"
	local var_3_4 = var_3_0:loadSprite(var_3_3)

	arg_3_0.chatBox_ = ccui.EditBox:create(var_3_2:getContentSize(), var_3_3)

	arg_3_0.chatBox_:setAnchorPoint(0, 0)
	arg_3_0.chatBox_:pos(0, 0):addTo(var_3_2)
	arg_3_0.chatBox_:setFont(var_3_0.FONT_NAME, var_3_1)
	arg_3_0.chatBox_:setPlaceholderFont(var_3_0.FONT_NAME, var_3_1)
	arg_3_0.chatBox_:setPlaceHolder(var_0_2:translation("CHAT_INPUT_MESSAGE"))
	arg_3_0.chatBox_:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_3_0.chatBox_:setFontColor(cc.c3b(90, 40, 23))
	arg_3_0.chatBox_:registerScriptEditBoxHandler(handler(arg_3_0, arg_3_0.inputboxEventHandler))
	arg_3_0.chatBox_:setInputFlag(3)
	arg_3_0:setButtonListener()
	arg_3_0:switchHeroGroup()
	arg_3_0:setFlipButtonListener()
end

function var_0_0.inputboxEventHandler(arg_6_0, arg_6_1)
	if arg_6_1 == "return" then
		local var_6_0 = arg_6_0.chatBox_:getText()

		arg_6_0.chatBox_:setText("")

		local var_6_1 = xyd.getTextLen(var_6_0)
		local var_6_2 = math.floor(tonumber(var_6_0) or 0)

		arg_6_0:nodeByName("page_txt"):setVisible(true)

		if var_6_0 ~= "" then
			if var_6_2 then
				if var_6_2 <= arg_6_0.totalPage and var_6_2 > 0 then
					arg_6_0.pageIndex_ = var_6_2
					arg_6_0.currentIdx = (arg_6_0.pageIndex_ - 1) * var_0_4 + 1

					arg_6_0:updateItems()
				else
					local var_6_3 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_6_3
					})

					return
				end

				return
			else
				local var_6_4 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_4
				})

				return
			end
		else
			return
		end
	elseif arg_6_1 == "began" then
		arg_6_0:nodeByName("page_txt"):setVisible(false)
		arg_6_0.chatBox_:setText("")
	end
end

function var_0_0.getHeroesData(arg_7_0)
	local var_7_0
	local var_7_1
	local var_7_2
	local var_7_3
	local var_7_4

	if not arg_7_0.heroName and arg_7_0.filterParams and next(arg_7_0.filterParams) then
		var_7_0 = arg_7_0.filterParams.favorFilter
		var_7_1 = arg_7_0.filterParams.posFilter
		var_7_2 = arg_7_0.filterParams.forceFilter
		var_7_3 = arg_7_0.filterParams.attrFilter
		var_7_4 = arg_7_0.filterParams.awakeFilter
	end

	arg_7_0.ownHeroNum = 0

	local var_7_5 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfPlayer.heros_) do
		local var_7_6 = xyd.getOriginHeroId(iter_7_1:getTableID())

		if not var_7_5[var_7_6] then
			arg_7_0.ownHeroNum = arg_7_0.ownHeroNum + 1
			var_7_5[var_7_6] = iter_7_1
		end
	end

	arg_7_0.hero_list = {}

	local var_7_7 = var_0_3:getWholeHeroes()

	for iter_7_2, iter_7_3 in ipairs(var_7_7) do
		local var_7_8 = xyd.getOriginHeroId(iter_7_3)
		local var_7_9

		if var_7_5[var_7_8] and xyd.tables.hero:isLibraryShow(var_7_8) then
			var_7_9 = var_7_5[var_7_8]

			if arg_7_0.heroName and not xyd.searchHeroByName(arg_7_0.heroName, var_7_9) then
				var_7_9 = nil
			end
		elseif iter_7_3 < xyd.AWAKEN_HERO_START_ID and xyd.tables.hero:isLibraryShow(var_7_8) then
			var_7_9 = var_0_1.new()

			var_7_9:initUnCollected(iter_7_3)

			if arg_7_0.heroName and not xyd.searchHeroByName(arg_7_0.heroName, var_7_9) then
				var_7_9 = nil
			end
		end

		if var_7_9 then
			local var_7_10 = false

			if not var_7_10 and var_7_0 then
				local var_7_11

				if xyd.tables.hero:isOpenDialog(var_7_9:getFirstTableID()) then
					var_7_11 = xyd.HerosFavorType.FAVOR
				else
					var_7_11 = xyd.HerosFavorType.NO_FAVOR
				end

				if not string.find(var_7_0, tostring(var_7_11)) then
					var_7_10 = true
				end
			end

			if not var_7_10 and var_7_1 and not string.find(var_7_1, tostring(var_7_9:getDistanceType())) then
				var_7_10 = true
			end

			if not var_7_10 and var_7_2 and not string.find(var_7_2, tostring(var_7_9:getFromType())) then
				var_7_10 = true
			end

			if not var_7_10 and var_7_3 and not string.find(var_7_3, tostring(var_7_9:getHeroType())) then
				var_7_10 = true
			end

			if not var_7_10 and var_7_4 then
				local var_7_12

				if var_7_9:isCanBloodAwake() then
					var_7_12 = xyd.HeroAwakeType.AWAKE_TWICE
				elseif var_7_9:isCanAwaken() then
					var_7_12 = xyd.HeroAwakeType.AWAKE
				else
					var_7_12 = xyd.HeroAwakeType.NO_AWAKE
				end

				if not string.find(var_7_4, tostring(var_7_12)) then
					var_7_10 = true
				end
			end

			if not var_7_10 then
				table.insert(arg_7_0.hero_list, var_7_9)
			end
		end
	end

	arg_7_0:sortData()
end

function var_0_0.sortData(arg_8_0)
	local var_8_0 = xyd.tables.hero

	table.sort(arg_8_0.hero_list, function(arg_9_0, arg_9_1)
		return (arg_9_0:isAwaken() and var_8_0:beforeAwaken(arg_9_0:getTableID()) or arg_9_0:getTableID()) < (arg_9_1:isAwaken() and var_8_0:beforeAwaken(arg_9_1:getTableID()) or arg_9_1:getTableID())
	end)
end

function var_0_0.loadHero(arg_10_0)
	if arg_10_0.currentIdx <= 1 then
		arg_10_0:nodeByName(var_0_0.LEFT):setTouchEnabled(false)
		arg_10_0:nodeByName(var_0_0.LEFT):setVisible(false)
	else
		arg_10_0:nodeByName(var_0_0.LEFT):setTouchEnabled(true)
		arg_10_0:nodeByName(var_0_0.LEFT):setVisible(true)
	end

	if #arg_10_0.hero_list - arg_10_0.currentIdx < var_0_4 then
		arg_10_0:nodeByName(var_0_0.RIGHT):setTouchEnabled(false)
		arg_10_0:nodeByName(var_0_0.RIGHT):setVisible(false)
	else
		arg_10_0:nodeByName(var_0_0.RIGHT):setTouchEnabled(true)
		arg_10_0:nodeByName(var_0_0.RIGHT):setVisible(true)
	end

	if #arg_10_0.hero_list - arg_10_0.currentIdx >= var_0_4 then
		arg_10_0:showNhero(var_0_4)
	else
		local var_10_0 = #arg_10_0.hero_list - arg_10_0.currentIdx + 1

		arg_10_0:showNhero(var_10_0)
	end
end

function var_0_0.showNhero(arg_11_0, arg_11_1)
	for iter_11_0 = 1, arg_11_1 do
		local var_11_0, var_11_1 = arg_11_0.listNode:getPosition()
		local var_11_2

		if arg_11_0.heroShowList[iter_11_0] then
			local var_11_3 = arg_11_0.heroShowList[iter_11_0]
		end

		local var_11_4 = arg_11_0:createListCell(arg_11_0.hero_list[arg_11_0.currentIdx])

		var_11_4:addTo(arg_11_0:nodeByName("background"))
		var_11_4:setAnchorPoint(0, 0)
		var_11_4:setPosition(var_11_0 + (iter_11_0 - 1) % var_0_5 * (var_0_6 + var_0_8), var_11_1 - math.floor((iter_11_0 - 1) / var_0_5) * (var_0_7 + var_0_9))

		local var_11_5 = arg_11_0.currentIdx

		var_11_4:setTouchEnabled(true)
		var_11_4:setTouchSwallowEnabled(true)
		var_11_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
			if arg_12_0.name == "began" then
				return true
			elseif arg_12_0.name == "ended" then
				xyd.playButtonSound()

				local var_12_0 = {
					heros = arg_11_0.hero_list,
					current = var_11_5,
					partner_logs = arg_11_0.partner_logs,
					partner_dialogs = arg_11_0.partnerDialogs
				}

				xyd.WindowManager.get():openWindow("tujian_herodetail", var_12_0)
			end
		end)

		arg_11_0.currentIdx = arg_11_0.currentIdx + 1
		arg_11_0.heroShowList[iter_11_0] = var_11_4
	end

	if arg_11_0.currentIdx > #arg_11_0.hero_list then
		if #arg_11_0.hero_list % var_0_4 == 0 then
			arg_11_0.currentIdx = #arg_11_0.hero_list + 1
		else
			arg_11_0.currentIdx = #arg_11_0.hero_list - #arg_11_0.hero_list % var_0_4 + var_0_4 + 1
		end
	end
end

function var_0_0.createListCell(arg_13_0, arg_13_1)
	local var_13_0 = import("app.windows.HeroListCell")
	local var_13_1 = display.newNode()
	local var_13_2 = var_0_6
	local var_13_3 = var_0_7

	var_13_1:setContentSize(var_13_2, var_13_3)

	local var_13_4 = var_13_0.new({
		hasEvent = 0,
		hero = arg_13_1,
		type = xyd.HeroListDisplayType.HERO
	})

	var_13_4:layout()
	var_13_4:setAnchorPoint(0, 0)
	var_13_4:addTo(var_13_1)
	var_13_4:setScale(var_13_3 / var_13_4:getContentSize().height)

	if xyd.isSuperHero(arg_13_1) then
		var_13_4:hideStoneProgress(true)
	end

	return var_13_1
end

function var_0_0.setButtonListener(arg_14_0)
	arg_14_0:nodeByName("search_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended and not arg_14_0.isSummon then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("tujian_hero_search")
		end
	end)
	arg_14_0:nodeByName("filter_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended and not arg_14_0.isSummon then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("tujian_hero_filter")
		end
	end)
	arg_14_0:nodeByName("recommend_btn"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended and not arg_14_0.isSummon then
			xyd.playButtonSound()

			if not arg_14_0.heroRecommend.recommendInfo then
				local var_17_0 = {}

				arg_14_0.heroRecommend:getRecommendInfo(var_17_0, function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK and arg_14_0 and not tolua.isnull(arg_14_0) then
						xyd.WindowManager.get():openWindow("hero_recommend")
					end
				end)
			else
				xyd.WindowManager.get():openWindow("hero_recommend")
			end
		end
	end)
end

function var_0_0.switchHeroGroup(arg_19_0)
	arg_19_0.totalPage = math.ceil(#arg_19_0.hero_list / var_0_4)

	if #arg_19_0.hero_list == 0 then
		arg_19_0.pageIndex_ = 0
	else
		arg_19_0.pageIndex_ = 1
	end

	arg_19_0.currentIdx = 1

	arg_19_0:refresh()
	arg_19_0:loadHero()
end

function var_0_0.refresh(arg_20_0)
	arg_20_0.pageText_:setString(arg_20_0.pageIndex_ .. "/" .. arg_20_0.totalPage)

	for iter_20_0 = 1, var_0_4 do
		if arg_20_0.heroShowList[iter_20_0] then
			arg_20_0.heroShowList[iter_20_0]:removeAllChildren()
			arg_20_0.heroShowList[iter_20_0]:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
		end
	end
end

function var_0_0.setFlipButtonListener(arg_21_0)
	arg_21_0.left:addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.began then
			arg_21_0:nodeByName(var_0_0.LEFT):setScale(0.9)
		elseif arg_22_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_21_0:nodeByName(var_0_0.LEFT):setScale(1)

			arg_21_0.pageIndex_ = arg_21_0.pageIndex_ - 1

			if arg_21_0.pageIndex_ <= 0 then
				arg_21_0.pageIndex_ = 1

				return
			end

			arg_21_0.currentIdx = arg_21_0.currentIdx - var_0_4 * 2

			arg_21_0:updateItems()
		end
	end)
	arg_21_0.right:addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.began then
			arg_21_0:nodeByName(var_0_0.RIGHT):setScale(0.9)
		elseif arg_23_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_21_0:nodeByName(var_0_0.RIGHT):setScale(1)

			arg_21_0.pageIndex_ = arg_21_0.pageIndex_ + 1

			if arg_21_0.pageIndex_ > arg_21_0.totalPage then
				arg_21_0.pageIndex_ = arg_21_0.totalPage

				return
			end

			arg_21_0:updateItems()
		end
	end)
end

function var_0_0.updataHeroShow(arg_24_0)
	arg_24_0.currentIdx = arg_24_0.currentIdx - var_0_4

	arg_24_0:updateItems()
end

function var_0_0.updateItems(arg_25_0)
	arg_25_0:refresh()
	arg_25_0:loadHero()
end

return var_0_0
