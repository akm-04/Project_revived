local var_0_0 = class("HeroListWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.hero
local var_0_5 = xyd.tables.item
local var_0_6 = 10
local var_0_7 = {
	FILTER = 3,
	ALL = 1,
	SEARCH = 2,
	PRESET = 4,
	STATE_SWITCH = 6,
	RECOMMEND = 5
}
local var_0_8 = {
	NORMAL = 1,
	INVERT = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.curState = var_0_7.ALL
	arg_1_0.displayType = xyd.HeroListDisplayType.HERO
	arg_1_0.orderType = var_0_8.NORMAL
	arg_1_0.heroRecommend = xyd.ModelManager.get():loadModel(xyd.ModelType.HERO_RECOMMEND)

	arg_1_0.heroRecommend:clearRecommend()

	arg_1_0.teams = arg_1_0.selfPlayer:getSaveTeams()
	arg_1_0.maxPresetNum = xyd.tables.vip:presetNum(arg_1_0.selfPlayer.vip)

	if arg_1_0.maxPresetNum <= 0 then
		arg_1_0.maxPresetNum = var_0_6
	end
end

function var_0_0.didOpen(arg_2_0)
	arg_2_0:layout()
	arg_2_0:setTouchSwallowEnabled(true)
	arg_2_0:playGuide()
	arg_2_0:onRegister()
end

function var_0_0.getHeroesData(arg_3_0)
	local var_3_0
	local var_3_1
	local var_3_2
	local var_3_3

	if not arg_3_0.heroName and arg_3_0.filterParams and next(arg_3_0.filterParams) then
		var_3_0 = arg_3_0.filterParams.posFilter
		var_3_1 = arg_3_0.filterParams.forceFilter
		var_3_2 = arg_3_0.filterParams.attrFilter
		var_3_3 = arg_3_0.filterParams.awakeFilter
	end

	local var_3_4 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfPlayer.heros_) do
		local var_3_5 = xyd.getOriginHeroId(iter_3_1:getTableID())

		if not var_3_4[var_3_5] then
			var_3_4[var_3_5] = iter_3_1
		end
	end

	arg_3_0.data = {}

	local var_3_6 = var_0_4:getWholeHeroes()

	for iter_3_2, iter_3_3 in ipairs(var_3_6) do
		local var_3_7 = xyd.getOriginHeroId(iter_3_3)
		local var_3_8

		if var_3_4[var_3_7] then
			var_3_8 = var_3_4[var_3_7]

			if arg_3_0.heroName and not xyd.searchHeroByName(arg_3_0.heroName, var_3_8) then
				var_3_8 = nil
			end
		elseif iter_3_3 < xyd.AWAKEN_HERO_START_ID and not xyd.isSuperHero(iter_3_3) then
			var_3_8 = var_0_1.new()

			var_3_8:initUnCollected(iter_3_3)

			if not var_3_8:isShow() and var_3_8:getSuiPian() <= 0 and not arg_3_0.heroName then
				var_3_8 = nil
			elseif arg_3_0.heroName and not xyd.searchHeroByName(arg_3_0.heroName, var_3_8) then
				var_3_8 = nil
			end
		end

		if var_3_8 then
			local var_3_9 = false

			if not var_3_9 and var_3_0 and not string.find(var_3_0, tostring(var_3_8:getDistanceType())) then
				var_3_9 = true
			end

			if not var_3_9 and var_3_1 and not string.find(var_3_1, tostring(var_3_8:getFromType())) then
				var_3_9 = true
			end

			if not var_3_9 and var_3_2 and not string.find(var_3_2, tostring(var_3_8:getHeroType())) then
				var_3_9 = true
			end

			if not var_3_9 and var_3_3 then
				local var_3_10

				if var_3_8:isCanBloodAwake() then
					var_3_10 = xyd.HeroAwakeType.AWAKE_TWICE
				elseif var_3_8:isCanAwaken() then
					var_3_10 = xyd.HeroAwakeType.AWAKE
				else
					var_3_10 = xyd.HeroAwakeType.NO_AWAKE
				end

				if not string.find(var_3_3, tostring(var_3_10)) then
					var_3_9 = true
				end
			end

			if not var_3_9 and arg_3_0.collocation then
				var_3_9 = not var_3_8:isCollocation()
			end

			if not var_3_9 then
				table.insert(arg_3_0.data, var_3_8)
			end
		end
	end

	arg_3_0:sortData()
end

function var_0_0.sortData(arg_4_0)
	if arg_4_0.orderType == var_0_8.NORMAL then
		table.sort(arg_4_0.data, function(arg_5_0, arg_5_1)
			if arg_5_0:canSummon() ~= arg_5_1:canSummon() then
				return arg_5_0:canSummon()
			elseif arg_5_0:canEnvolve() ~= arg_5_1:canEnvolve() then
				return arg_5_0:canEnvolve()
			elseif xyd.isSuperHero(arg_5_0) ~= xyd.isSuperHero(arg_5_1) then
				return xyd.isSuperHero(arg_5_0)
			elseif arg_5_0:isCollected() ~= arg_5_1:isCollected() then
				return arg_5_0:isCollected()
			elseif arg_5_0:getLevel() ~= arg_5_1:getLevel() then
				return arg_5_0:getLevel() > arg_5_1:getLevel()
			elseif arg_5_0:getStar() ~= arg_5_1:getStar() then
				return arg_5_0:getStar() > arg_5_1:getStar()
			elseif arg_5_0:getColor() ~= arg_5_1:getColor() then
				return arg_5_0:getColor() > arg_5_1:getColor()
			elseif arg_5_0:getInscriptionKuangLevel() ~= arg_5_1:getInscriptionKuangLevel() then
				return (arg_5_0:getInscriptionKuangLevel() or 0) > (arg_5_1:getInscriptionKuangLevel() or 0)
			elseif arg_5_0:isAwakeTwice() ~= arg_5_1:isAwakeTwice() then
				return arg_5_0:isAwakeTwice()
			elseif arg_5_0:isAwaken() ~= arg_5_1:isAwaken() then
				return arg_5_0:isAwaken()
			elseif arg_5_0:getTableID() ~= arg_5_1:getTableID() then
				return arg_5_0:getTableID() < arg_5_1:getTableID()
			end
		end)
	elseif arg_4_0.orderType == var_0_8.INVERT then
		table.sort(arg_4_0.data, function(arg_6_0, arg_6_1)
			if arg_6_0:canSummon() ~= arg_6_1:canSummon() then
				return arg_6_0:canSummon()
			elseif arg_6_0:canEnvolve() ~= arg_6_1:canEnvolve() then
				return arg_6_0:canEnvolve()
			elseif xyd.isSuperHero(arg_6_0) ~= xyd.isSuperHero(arg_6_1) then
				return xyd.isSuperHero(arg_6_0)
			elseif arg_6_0:isCollected() ~= arg_6_1:isCollected() then
				return arg_6_0:isCollected()
			elseif arg_6_0:getLevel() ~= arg_6_1:getLevel() then
				return arg_6_0:getLevel() < arg_6_1:getLevel()
			elseif arg_6_0:getStar() ~= arg_6_1:getStar() then
				return arg_6_0:getStar() < arg_6_1:getStar()
			elseif arg_6_0:getColor() ~= arg_6_1:getColor() then
				return arg_6_0:getColor() < arg_6_1:getColor()
			elseif arg_6_0:getInscriptionKuangLevel() ~= arg_6_1:getInscriptionKuangLevel() then
				return (arg_6_0:getInscriptionKuangLevel() or 0) < (arg_6_1:getInscriptionKuangLevel() or 0)
			elseif arg_6_0:isAwakeTwice() ~= arg_6_1:isAwakeTwice() then
				return arg_6_1:isAwakeTwice()
			elseif arg_6_0:isAwaken() ~= arg_6_1:isAwaken() then
				return arg_6_1:isAwaken()
			elseif arg_6_0:getTableID() ~= arg_6_1:getTableID() then
				return arg_6_0:getTableID() > arg_6_1:getTableID()
			end
		end)
	end
end

function var_0_0.layout(arg_7_0)
	arg_7_0.container = display.newNode()

	arg_7_0.container:size(1045, 604)
	arg_7_0.container:addTo(arg_7_0:background(), 1)
	arg_7_0.container:setAnchorPoint(0, 0)
	arg_7_0.container:setPosition(219, 48)

	arg_7_0.size = arg_7_0.container:getContentSize()
	arg_7_0.leftSidebar = arg_7_0:nodeByName("left_sidebar")

	arg_7_0.leftSidebar:createSidebarList({
		var_0_3:translation("HERO_LIST_BTN_ALL"),
		var_0_3:translation("HERO_LIST_BTN_SEARCH"),
		var_0_3:translation("HERO_LIST_BTN_FILTER"),
		var_0_3:translation("HERO_LIST_BTN_PRESET"),
		var_0_3:translation("HERO_LIST_BTN_RECOMMEND")
	})

	if not arg_7_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_RECOMMEND) then
		arg_7_0.leftSidebar:hideBtnByIdx(var_0_7.RECOMMEND)
	end

	arg_7_0.leftSidebar:getBtnByIdx(var_0_7.ALL):setBrightStyle(xyd.ButtonStyle.HIGHLIGHT)

	local var_7_0 = arg_7_0.leftSidebar:addTabBtn(var_0_3:translation("TXT_EQUIP_STATE"))

	var_7_0:setOnCall(function()
		arg_7_0.displayType = xyd.HeroListDisplayType.EQUIP

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.HERO_CELL_STATE_CHANGE,
			state = xyd.HeroListDisplayType.EQUIP
		})
	end)
	var_7_0:setOffCall(function()
		arg_7_0.displayType = xyd.HeroListDisplayType.HERO

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.HERO_CELL_STATE_CHANGE,
			state = xyd.HeroListDisplayType.HERO
		})
	end)

	local var_7_1 = arg_7_0.leftSidebar:addTabBtn(var_0_3:translation("TXT_COLLOCATION_STATE"))

	var_7_1:setOnCall(function()
		arg_7_0.collocation = true

		arg_7_0:updateHeroList()
	end)
	var_7_1:setOffCall(function()
		arg_7_0.collocation = false

		arg_7_0:updateHeroList()
	end)

	local var_7_2 = arg_7_0.leftSidebar:addTabBtn(var_0_3:translation("TXT_ORDER_TYPE_1"))

	var_7_2:setOnCall(function()
		var_7_2:setTitle(var_0_3:translation("TXT_ORDER_TYPE_2"))

		arg_7_0.orderType = var_0_8.INVERT

		arg_7_0:updateHeroList()
	end)
	var_7_2:setOffCall(function()
		var_7_2:setTitle(var_0_3:translation("TXT_ORDER_TYPE_1"))

		arg_7_0.orderType = var_0_8.NORMAL

		arg_7_0:updateHeroList()
	end)
	arg_7_0:updateRight()
end

function var_0_0.updateRight(arg_14_0)
	if arg_14_0.curState == var_0_7.ALL then
		arg_14_0.heroName = nil
		arg_14_0.filterParams = nil

		arg_14_0:updateHeroList()
	elseif arg_14_0.curState == var_0_7.SEARCH then
		xyd.WindowManager.get():openWindow("hero_search_wnd")
	elseif arg_14_0.curState == var_0_7.FILTER then
		xyd.WindowManager.get():openWindow("hero_filter_wnd")
	elseif arg_14_0.curState == var_0_7.PRESET then
		arg_14_0:updatePreset()
	elseif arg_14_0.curState == var_0_7.RECOMMEND then
		if not arg_14_0.heroRecommend.recommendInfo then
			arg_14_0.heroRecommend:getRecommendInfo({}, function(arg_15_0)
				if arg_15_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("hero_recommend")
				end
			end)
		else
			xyd.WindowManager.get():openWindow("hero_recommend")
		end
	end
end

function var_0_0.updatePreset(arg_16_0)
	arg_16_0:hideHeroList()

	if not arg_16_0.presetContainer or tolua.isnull(arg_16_0.presetContainer) then
		arg_16_0.presetContainer = display.newNode()

		arg_16_0.presetContainer:setContentSize(1020, 620)
		arg_16_0.presetContainer:addTo(arg_16_0:background())
		arg_16_0.presetContainer:setPosition(240, 20)

		arg_16_0.presetList = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, arg_16_0.container:getWidth(), 500),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_16_0.presetContainer):onScroll(handler(arg_16_0, arg_16_0.scrollListener))

		arg_16_0.presetList:setAnchorPoint(0, 0)
		arg_16_0.presetList:setPosition(0, 120)
		arg_16_0.presetList:setDelegate(handler(arg_16_0, arg_16_0.presetDelegate))
		arg_16_0.presetList:reload()

		local var_16_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_collect/hero_preset_btn.csb")

		var_16_0:addTo(arg_16_0.presetContainer)
		var_16_0:setPosition(0, 0)

		local var_16_1 = string.format(var_0_3:translation("PRESET_MEMBER_NUM"), #arg_16_0.teams, arg_16_0.maxPresetNum)
		local var_16_2 = var_16_0:getChildByName("background")

		arg_16_0.presetBtn = var_0_2.new({
			sprite = "windows/button/btn173_1.png",
			titleSize = 24,
			titleOffSetX = 5,
			title = var_16_1,
			clickMode = xyd.ButtonClickMode.SCALE,
			capInsets = cc.rect(85, 1, 1, 1)
		})

		arg_16_0.presetBtn:setButtonSize(234, 60)
		arg_16_0.presetBtn:addTo(var_16_2)
		arg_16_0.presetBtn:setAnchorPoint(0.5, 0.5)
		arg_16_0.presetBtn:setPosition(var_16_2:getChildByName("pos_btn"):getPosition())
		arg_16_0.presetBtn:addTouchEvent(function(arg_17_0)
			if arg_17_0.name == "ended" then
				if #arg_16_0.teams >= arg_16_0.maxPresetNum then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("PRESET_MEMBER_IS_MAX_NUM")
					})

					return
				end

				local var_17_0 = {
					type = xyd.SelectTeamType.HERO_PRESET,
					presetHeroType = xyd.PresetHeroType.NEW_TEAM,
					presetHeroIndex = #arg_16_0.teams
				}

				xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_17_0)
			end
		end)
	else
		arg_16_0:showPreset()
	end
end

function var_0_0.hideHeroList(arg_18_0)
	if arg_18_0.container and not tolua.isnull(arg_18_0.container) then
		arg_18_0.container:setVisible(false)

		for iter_18_0, iter_18_1 in ipairs(arg_18_0.leftSidebar:getTabBtns()) do
			iter_18_1:setVisible(false)
		end
	end
end

function var_0_0.showHeroList(arg_19_0)
	if arg_19_0.container and not tolua.isnull(arg_19_0.container) then
		arg_19_0.container:setVisible(true)

		for iter_19_0, iter_19_1 in ipairs(arg_19_0.leftSidebar:getTabBtns()) do
			iter_19_1:setVisible(true)
		end
	end
end

function var_0_0.hidePreset(arg_20_0)
	if arg_20_0.presetContainer and not tolua.isnull(arg_20_0.presetContainer) then
		arg_20_0.presetContainer:setVisible(false)
	end
end

function var_0_0.showPreset(arg_21_0)
	if arg_21_0.presetContainer and not tolua.isnull(arg_21_0.presetContainer) then
		arg_21_0.presetContainer:setVisible(true)
	end
end

function var_0_0.updateHeroList(arg_22_0)
	arg_22_0:hidePreset()
	arg_22_0:getHeroesData()

	if not arg_22_0.list then
		arg_22_0.list = cc.ui.UIListView.new({
			framingDuration = 0.2,
			framing = true,
			viewRect = cc.rect(0, 0, arg_22_0.container:getWidth(), 600),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_22_0.container):onScroll(handler(arg_22_0, arg_22_0.scrollListener))

		arg_22_0.list:setAnchorPoint(0, 0)
		arg_22_0.list:setPosition(0, 0)
		arg_22_0.list:setDelegate(handler(arg_22_0, arg_22_0.delegate))
		arg_22_0.list:reload()
	else
		arg_22_0:showHeroList()
		arg_22_0.list:reload()
		collectgarbage("collect")
	end
end

function var_0_0.delegate(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	if cc.ui.UIListView.COUNT_TAG == arg_23_2 then
		return math.ceil(#arg_23_0.data / 5)
	elseif cc.ui.UIListView.CELL_TAG == arg_23_2 then
		local var_23_0
		local var_23_1 = arg_23_1:dequeueItem()

		if not var_23_1 then
			var_23_1 = arg_23_1:newItem()
		else
			var_23_1:removeAllChildren(false)
		end

		local var_23_2 = {}
		local var_23_3 = 1

		for iter_23_0 = 5 * arg_23_3 - 4, 5 * arg_23_3 do
			if not arg_23_0.data[iter_23_0] then
				break
			end

			var_23_2[var_23_3] = arg_23_0.data[iter_23_0]
			var_23_3 = var_23_3 + 1
		end

		local var_23_4 = {
			top = 0,
			left = 0,
			bottom = 6,
			right = 0
		}
		local var_23_5 = arg_23_0:createListCell(var_23_2, arg_23_3)
		local var_23_6 = var_23_5:getWidth()
		local var_23_7 = var_23_5:getHeight()

		var_23_1:setMargin(var_23_4)
		var_23_1:setItemSize(var_23_6, var_23_7)
		var_23_1:addContent(var_23_5)

		return var_23_1
	end
end

function var_0_0.presetDelegate(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	if cc.ui.UIListView.COUNT_TAG == arg_24_2 then
		return #arg_24_0.teams
	elseif cc.ui.UIListView.CELL_TAG == arg_24_2 then
		local var_24_0
		local var_24_1 = arg_24_1:dequeueItem()

		if not var_24_1 then
			var_24_1 = arg_24_1:newItem()
		else
			var_24_1:removeAllChildren(false)
		end

		local var_24_2 = {
			top = 0,
			left = 0,
			bottom = 5,
			right = 0
		}
		local var_24_3 = arg_24_0:createPresetCell(arg_24_3)

		if not var_24_3 then
			return
		end

		local var_24_4 = var_24_3:getWidth()
		local var_24_5 = var_24_3:getHeight()

		var_24_1:setMargin(var_24_2)
		var_24_1:setItemSize(var_24_4, var_24_5)
		var_24_1:addContent(var_24_3)

		return var_24_1
	end
end

function var_0_0.createPresetCell(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0.teams[arg_25_1]

	if not var_25_0 then
		return
	end

	local var_25_1 = var_25_0.team
	local var_25_2 = var_25_0.teamName
	local var_25_3 = var_25_0.pet
	local var_25_4 = display.newNode()
	local var_25_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_collect/hero_preset_cell.csb")

	var_25_5:addTo(var_25_4)

	local var_25_6 = var_25_5:getChildByName("background")

	var_25_4:setContentSize(var_25_6:getContentSize())
	var_25_6:getChildByName("txt_team_name"):setString(var_25_2)

	local var_25_7 = 0

	for iter_25_0 = 1, #var_25_1 do
		local var_25_8 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_new.csb")
		local var_25_9 = var_25_8:getChildByName("background"):getContentSize()

		var_25_8:setContentSize(var_25_9)
		xyd.setAvatarBorderNewUI(var_25_1[iter_25_0], var_25_8:getChildByName("avatar"))

		local var_25_10 = var_25_8:getChildByName("chosen")

		var_25_10:setLocalZOrder(100)
		var_25_10:setVisible(false)

		local var_25_11 = var_25_8:getChildByName("avatar_mask")

		var_25_11:setLocalZOrder(2)
		var_25_11:setVisible(false)

		for iter_25_1 = 1, 3 do
			var_25_8:getChildByName("team" .. iter_25_1):setVisible(false)
		end

		local var_25_12 = var_25_8:getChildByName("lv_txt")

		var_25_12:setString(var_25_1[iter_25_0]:getLevel())
		var_25_8:getChildByName("name_text"):setString(var_25_1[iter_25_0]:getName())
		var_25_12:enableOutline(cc.c4b(0, 0, 0, 255), 1)

		local var_25_13 = var_25_8:getChildByName("hp_bar")
		local var_25_14 = var_25_8:getChildByName("mp_bar")
		local var_25_15 = var_25_8:getChildByName("dead_text")

		if var_25_15 then
			var_25_15:setVisible(false)
		end

		var_25_8:getChildByName("yongbing_tubiao"):setVisible(false)
		var_25_13:hide()
		var_25_14:hide()
		var_25_8:getChildByName("hp_di"):hide()
		var_25_8:getChildByName("mp_di"):hide()
		var_25_8:addTo(var_25_6:getChildByName("avatar_" .. iter_25_0))

		var_25_7 = var_25_7 + var_25_1[iter_25_0]:getZhandouli()
	end

	if var_25_3 then
		xyd.setPetAvatarNewUI(var_25_6:getChildByName("pet"), var_25_3, 100)

		var_25_7 = var_25_7 + var_25_3:getZhandouli()
	end

	var_25_6:getChildByName("zhandouli"):setString(var_25_7)
	var_25_6:getChildByName("txt_zhandouli"):setString(var_0_3:translation("FORCE_TXT"))

	local var_25_16 = var_0_2.new({
		sprite = "windows/button/btn123_blue.png",
		titleSize = 20,
		title = var_0_3:translation("DELETE"),
		clickMode = xyd.ButtonClickMode.SCALE,
		capInsets = cc.rect(20, 0, 25, 48)
	})

	var_25_16:setButtonSize(115, 48)
	var_25_16:addTo(var_25_6)
	var_25_16:setPosition(var_25_6:getChildByName("pos_btn_delete"):getPosition())
	var_25_16:addTouchEvent(function(arg_26_0)
		if arg_26_0.name == "ended" then
			local var_26_0 = string.format(var_0_3:translation("PRESET_TEAM_DELETE"), var_25_2)

			local function var_26_1()
				local var_27_0, var_27_1, var_27_2 = arg_25_0.selfPlayer:getSaveTeamStr()
				local var_27_3 = xyd.split(var_27_0, ":")

				table.remove(var_27_3, arg_25_1)

				local var_27_4 = string.split(var_27_1, "|||")

				table.remove(var_27_4, arg_25_1)

				local var_27_5 = string.split(var_27_2, "|")

				table.remove(var_27_5, arg_25_1)

				local var_27_6 = xyd.catToString(var_27_3, ":")
				local var_27_7 = xyd.catToString(var_27_4, "|||")
				local var_27_8 = xyd.catToString(var_27_5, "|")
				local var_27_9 = {
					team_str = var_27_6,
					team_name_str = var_27_7,
					pet_str = var_27_8
				}

				arg_25_0.selfPlayer:heroPreset(var_27_9, function()
					local var_28_0 = xyd.WindowManager.get():getWindow("hero_list")

					if var_28_0 and not tolua.isnull(var_28_0) then
						var_28_0.teams = var_28_0.selfPlayer:getSaveTeams()

						if var_28_0.presetList and not tolua.isnull(var_28_0.presetList) then
							var_28_0.presetList:refreshList()
						end

						if var_28_0.presetBtn and not tolua.isnull(var_28_0.presetBtn) then
							local var_28_1 = string.format(var_0_3:translation("PRESET_MEMBER_NUM"), #var_28_0.teams, var_28_0.maxPresetNum)

							var_28_0.presetBtn:setTitle(var_28_1)
						end
					end
				end)
			end

			local var_26_2 = {
				rcallBefore = 0,
				txt = var_26_0,
				rcallback = var_26_1,
				align = xyd.ui_align.CENTER
			}

			xyd.WindowManager.get():openWindow("common_alert", var_26_2)
		end
	end)

	local var_25_17 = var_0_2.new({
		sprite = "windows/button/btn123_blue.png",
		titleSize = 22,
		title = var_0_3:translation("ADJUST"),
		clickMode = xyd.ButtonClickMode.SCALE,
		capInsets = cc.rect(20, 0, 25, 48)
	})

	var_25_17:setButtonSize(115, 48)
	var_25_17:addTo(var_25_6)
	var_25_17:setPosition(var_25_6:getChildByName("pos_btn_change"):getPosition())
	var_25_17:addTouchEvent(function(arg_29_0)
		if arg_29_0.name == "ended" then
			local var_29_0 = arg_25_0.selfPlayer:getSaveTeamStr()
			local var_29_1 = arg_25_0.selfPlayer:getSaveTeamIDs(var_29_0)
			local var_29_2 = {
				type = xyd.SelectTeamType.HERO_PRESET,
				presetHeroType = xyd.PresetHeroType.ADJUST_TEAM,
				presetHeroIndex = arg_25_1,
				selected = var_29_1[arg_25_1],
				preHeros = var_25_1,
				prePet = {
					var_25_3
				}
			}

			xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_29_2)
		end
	end)

	return var_25_4
end

function var_0_0.createListCell(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0 = import("app.windows.HeroListCell")
	local var_30_1 = display.newNode()
	local var_30_2 = 5
	local var_30_3 = 205 * #arg_30_1 + (#arg_30_1 - 1) * var_30_2
	local var_30_4 = 282

	var_30_1:setContentSize(var_30_3, var_30_4)

	for iter_30_0, iter_30_1 in ipairs(arg_30_1) do
		local var_30_5 = var_30_0.new({
			hero = iter_30_1,
			type = arg_30_0.displayType,
			idx = (arg_30_2 - 1) * 5 + iter_30_0
		})

		var_30_5:layout()
		var_30_5:setAnchorPoint(0.5, 0.5)
		var_30_5:addTo(var_30_1)
		var_30_5:setPosition(var_30_5:getWidth() * (iter_30_0 - 0.5) + (iter_30_0 - 1) * var_30_2, var_30_4 / 2)

		if iter_30_1:getTableID() == 10001001 then
			arg_30_0.lvmengCell = var_30_5
		elseif iter_30_1:getTableID() == 10001004 then
			arg_30_0.zhangjiaoCell = var_30_5
		end

		xyd.setItemAnimation(var_30_5, iter_30_0)
	end

	return var_30_1
end

function var_0_0.searchHeros(arg_31_0)
	if not arg_31_0.heroName then
		return
	end

	arg_31_0:hidePreset()
	arg_31_0:showHeroList()

	arg_31_0.filterParams = nil

	arg_31_0:getHeroesData()
	arg_31_0.list:scrollTo(0, 600)
	arg_31_0:reloadList()
end

function var_0_0.filterHeros(arg_32_0)
	arg_32_0:hidePreset()
	arg_32_0:showHeroList()

	arg_32_0.heroName = nil

	arg_32_0:getHeroesData()
	arg_32_0.list:scrollTo(0, 600)
	arg_32_0:reloadList()
end

function var_0_0.updateCellStone(arg_33_0, arg_33_1)
	if not arg_33_1 or arg_33_1 <= 0 then
		return
	end

	if var_0_5:type(arg_33_1) ~= 3 then
		return
	end

	local var_33_0 = xyd.tables.hero:getStoneTable()
	local var_33_1 = table.keyof(var_33_0, arg_33_1)

	if not var_33_1 or var_33_1 <= 0 then
		return
	end

	local var_33_2

	for iter_33_0, iter_33_1 in ipairs(arg_33_0.data) do
		if xyd.getOriginHeroId(iter_33_1:getTableID()) == var_33_1 then
			var_33_2 = iter_33_1

			break
		end
	end

	if not var_33_2 then
		return
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.HERO_CELL_REFRESH,
		tableID = var_33_2:getTableID()
	})
end

function var_0_0.reloadList(arg_34_0)
	if arg_34_0.list and not tolua.isnull(arg_34_0.list) then
		arg_34_0.list:reload()
	end
end

function var_0_0.onRegister(arg_35_0)
	arg_35_0:onRegisterCommon()
	arg_35_0:onRegisterButton()
end

function var_0_0.onRegisterCommon(arg_36_0)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_36_0):addEventListener(xyd.event.HERO_SEARCH, function(arg_37_0)
		if not xyd.WindowManager.get():getWindow(xyd.WindowName.SelectTeamWnd) and arg_37_0 and arg_37_0.heroName and arg_37_0.heroName ~= var_0_3:translation("HERO_SEARCH_TIPS") then
			arg_36_0.heroName = arg_37_0.heroName

			arg_36_0:searchHeros()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_36_0):addEventListener(xyd.event.HERO_LIST_REFRESH, function()
		arg_36_0:updateHeroList()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_36_0):addEventListener(xyd.event.HERO_FILTER, function(arg_39_0)
		if not xyd.WindowManager.get():getWindow(xyd.WindowName.SelectTeamWnd) then
			arg_36_0:updateHeroList()

			arg_36_0.filterParams = arg_39_0.filterParams

			arg_36_0:filterHeros()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_36_0):addEventListener(xyd.event.UPDATE_HERO_COLLECT_STONE, function(arg_40_0)
		if arg_40_0 and arg_40_0.itemComposeID then
			arg_36_0:updateCellStone(arg_40_0.itemComposeID)
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_36_0):addEventListener(xyd.event.HERO_PRESET_REFRESH, function()
		arg_36_0.teams = arg_36_0.selfPlayer:getSaveTeams()

		if arg_36_0.presetList and not tolua.isnull(arg_36_0.presetList) then
			arg_36_0.presetList:refreshList()
		end

		if arg_36_0.presetBtn and not tolua.isnull(arg_36_0.presetBtn) then
			local var_41_0 = string.format(var_0_3:translation("PRESET_MEMBER_NUM"), #arg_36_0.teams, arg_36_0.maxPresetNum)

			arg_36_0.presetBtn:setTitle(var_41_0)
		end
	end)
end

function var_0_0.onRegisterButton(arg_42_0)
	arg_42_0.leftSidebar:registerButton(function(arg_43_0, arg_43_1)
		if arg_43_1.name == "ended" then
			if arg_42_0.curState == arg_43_0 and arg_43_0 == 1 then
				return
			end

			arg_42_0.curState = arg_43_0

			arg_42_0:updateRight()
		end
	end)
end

function var_0_0.scrollListener(arg_44_0, arg_44_1)
	if arg_44_1.name == "began" then
		arg_44_0.scrollViewMoved_ = false
		arg_44_0.prevY_ = arg_44_1.y
	elseif arg_44_1.name == "moved" then
		if 20 <= math.abs(arg_44_1.y - arg_44_0.prevY_) then
			arg_44_0.scrollViewMoved_ = true
		end

		arg_44_0.scrollY = arg_44_0.list:getScrollNode():getPositionY()
	elseif arg_44_1.name == "scrollEnd" then
		arg_44_0.scrollY = arg_44_0.list:getScrollNode():getPositionY()
	end
end

function var_0_0.playGuide(arg_45_0)
	local var_45_0 = xyd.StoryData.get():getGuideID()

	if arg_45_0:checkGuideIntoHero() then
		arg_45_0:setIDBeforeGuideWnd()
		arg_45_0.list:setViewCanNotScroll(true)

		var_45_0 = xyd.StoryData.get():getGuideID()

		local var_45_1 = arg_45_0:getGuideHeroCell()
		local var_45_2 = {
			480,
			200
		}
		local var_45_3 = true

		if var_45_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_THREE or var_45_0 == xyd.GuideStoryType.GUIDE_LEVUP_ONE then
			var_45_3 = false
		end

		xyd.showGuideWnd(var_45_1, nil, nil, 3, var_45_2, var_45_3, true)
		arg_45_0:setIDAfterGuideWnd(var_45_0)
	elseif arg_45_0:checkGuideCloseWnd() then
		arg_45_0:setIDBeforeGuideWnd()

		local var_45_4 = arg_45_0:nodeByName("top_sidebar"):nodeByName("return_btn")
		local var_45_5 = {
			300,
			500
		}

		xyd.showGuideWnd(var_45_4, nil, nil, 1, var_45_5, true)
		arg_45_0:setIDAfterGuideWnd()
	elseif var_45_0 == xyd.GuideStoryType.GUIDE_LEVUP_END then
		arg_45_0:setIDBeforeGuideWnd()
		arg_45_0:showOnlyDialogGuide()
	end
end

function var_0_0.showOnlyDialogGuide(arg_46_0, arg_46_1)
	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	if xyd.WindowManager.get():isWindowOpen("guide_only_dialog") then
		xyd.WindowManager.get():closeWindow("guide_only_dialog")
	end

	local var_46_0 = true
	local var_46_1 = cc.p(300, 300)
	local var_46_2 = {
		tipPosition = var_46_1,
		right = var_46_0
	}

	if arg_46_1 then
		var_46_2.callback = arg_46_1
	else
		function var_46_2.callback()
			arg_46_0:playGuide()
		end
	end

	xyd.WindowManager.get():openWindow("guide_only_dialog", var_46_2)
end

function var_0_0.setIDBeforeGuideWnd(arg_48_0)
	local var_48_0 = xyd.StoryData.get():getGuideID()

	if var_48_0 >= xyd.GuideStoryType.GUIDE_SKILL_START and var_48_0 < xyd.GuideStoryType.GUIDE_SKILL_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SKILL_ONE, true)
	elseif var_48_0 == xyd.GuideStoryType.GUIDE_LEVUP_END then
		arg_48_0.selfPlayer:sendOperationLog(xyd.StatID.ID_LEVUP_5)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_START, true)
	elseif var_48_0 == xyd.GuideStoryType.ACTIVITY_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_ONE, true)
	end
end

function var_0_0.setIDAfterGuideWnd(arg_49_0)
	local var_49_0 = xyd.StoryData.get():getGuideID()

	if var_49_0 < xyd.GuideStoryType.GUIDE_EQUIP_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_TWO)
	elseif var_49_0 == xyd.GuideStoryType.GUIDE_LEVUP_ONE then
		arg_49_0.selfPlayer:sendOperationLog(xyd.StatID.ID_LEVUP_1)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_TWO)
	elseif var_49_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_THREE then
		arg_49_0.selfPlayer:sendOperationLog(xyd.StatID.ID_JINJIE_4)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_FOUR)
	elseif var_49_0 == xyd.GuideStoryType.GUIDE_SKILL_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SKILL_TWO)
	elseif var_49_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_NINE then
		arg_49_0.selfPlayer:sendOperationLog(xyd.StatID.ID_JINJIE_10)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_END)
		xyd.StoryData.get():persist()
	elseif var_49_0 == xyd.GuideStoryType.ACTIVITY_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_THREE)
		xyd.StoryData.get():persist()
	elseif var_49_0 == xyd.GuideStoryType.GUIDE_FIGHT_6_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_6_ONE)
		xyd.StoryData.get():persist()
	end
end

function var_0_0.checkGuideIntoHero(arg_50_0)
	local var_50_0 = xyd.StoryData.get():getGuideID()

	if var_50_0 >= xyd.GuideStoryType.GUIDE_EQUIP_START and var_50_0 < xyd.GuideStoryType.GUIDE_EQUIP_END or var_50_0 == xyd.GuideStoryType.GUIDE_LEVUP_ONE or var_50_0 == xyd.GuideStoryType.GUIDE_LEVUP_START or var_50_0 >= xyd.GuideStoryType.GUIDE_SKILL_START and var_50_0 < xyd.GuideStoryType.GUIDE_SKILL_END or var_50_0 == xyd.GuideStoryType.GUIDE_STONE_ONE or var_50_0 == xyd.GuideStoryType.GUIDE_STONE_END or var_50_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_THREE then
		return true
	end

	return false
end

function var_0_0.checkGuideCloseWnd(arg_51_0)
	local var_51_0 = xyd.StoryData.get():getGuideID()

	if var_51_0 == xyd.GuideStoryType.GUIDE_EQUIP_END or var_51_0 == xyd.GuideStoryType.GUIDE_LEVUP_FOUR or var_51_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_NINE or var_51_0 == xyd.GuideStoryType.ACTIVITY_START or var_51_0 == xyd.GuideStoryType.GUIDE_FIGHT_6_START then
		return true
	end

	return false
end

function var_0_0.getGuideHeroCell(arg_52_0)
	local var_52_0 = xyd.StoryData.get():getGuideID()

	if var_52_0 == xyd.GuideStoryType.GUIDE_LEVUP_ONE or var_52_0 == xyd.GuideStoryType.GUIDE_STONE_ONE then
		return arg_52_0.zhangjiaoCell
	else
		return arg_52_0.lvmengCell
	end
end

function var_0_0.didClose(arg_53_0)
	if arg_53_0.list and not tolua.isnull(arg_53_0.list) then
		arg_53_0.list:onCleanup()
		collectgarbage("collect")
	end

	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	local var_53_0
	local var_53_1 = xyd.StoryData.get():getGuideID()

	if var_53_1 == xyd.GuideStoryType.GUIDE_EQUIP_END then
		arg_53_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_BACK3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_START)
		xyd.StoryData.get():persist()
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.GUIDE_FIGHT_2_START
			}
		})

		var_53_0 = true
	elseif var_53_1 == xyd.GuideStoryType.ACTIVITY_THREE then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.ACTIVITY_THREE
			}
		})

		var_53_0 = true
	elseif var_53_1 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_5_START)
		xyd.StoryData.get():persist()
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.GUIDE_FIGHT_5_START
			}
		})

		var_53_0 = true
	elseif var_53_1 == xyd.GuideStoryType.GUIDE_FIGHT_6_ONE then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.GUIDE_FIGHT_6_ONE
			}
		})

		var_53_0 = true
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {
			quickAction = var_53_0
		}
	})
end

return var_0_0
