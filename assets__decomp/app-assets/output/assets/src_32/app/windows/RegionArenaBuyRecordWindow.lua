local var_0_0 = class("RegionArenaBuyRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = 16
local var_0_4 = 6
local var_0_5 = 96
local var_0_6 = xyd.RegionArenaHeroShop.HERO_ADD_STAR
local var_0_7 = xyd.RegionArenaHeroShop.HERO_AWAKE
local var_0_8 = xyd.RegionArenaHeroShop.SUMMON_HERO

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.awards = arg_1_0.regionArena.awards
	arg_1_0.isAddStarHeros = {}
	arg_1_0.isAwakeHeros = {}
	arg_1_0.isSummonHeros = {}
	arg_1_0.exchangeTimes = arg_1_0.regionArena.exchangeTimes
	arg_1_0.heros = {}
	arg_1_0.totalHero = {}
	arg_1_0.totalHero[var_0_6] = {}
	arg_1_0.totalHero[var_0_7] = {}
	arg_1_0.totalHero[var_0_8] = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initHeros(arg_2_0.awards)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.initHeros(arg_4_0, arg_4_1)
	for iter_4_0, iter_4_1 in pairs(arg_4_1) do
		local var_4_0 = var_0_2.new()

		var_4_0:initUnCollected(iter_4_1.table_id)

		var_4_0.color_ = var_0_3

		if iter_4_1.add_star > 0 then
			table.insert(arg_4_0.totalHero[var_0_6], iter_4_1)
			var_4_0:setStar(iter_4_1.add_star)
		end

		if iter_4_1.is_awake == 1 then
			table.insert(arg_4_0.totalHero[var_0_7], iter_4_1)

			local var_4_1 = xyd.tables.hero:afterAwaken(iter_4_1.table_id)

			var_4_0:setTableID(var_4_1)
		end

		if iter_4_1.is_summon == 1 then
			table.insert(arg_4_0.totalHero[var_0_8], iter_4_1)
		end

		arg_4_0.heros[iter_4_1.table_id] = var_4_0
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("title_title"):setString(var_0_1:translation("REGION_ARENA_MISSION_TIPS_1"))
	arg_5_0:nodeByName("title_word_1"):setString(var_0_1:translation("REGION_ARENA_MISSION_TIPS_2"))
	arg_5_0:nodeByName("title_word_2"):setString(var_0_1:translation("REGION_ARENA_MISSION_TIPS_3"))
	arg_5_0:nodeByName("title_word_3"):setString(var_0_1:translation("REGION_ARENA_MISSION_TIPS_4"))

	arg_5_0.detailContainer = arg_5_0:nodeByName("detail_container")

	local var_5_0 = arg_5_0.detailContainer:getContentSize()

	arg_5_0.scrollView = cc.ui.UIScrollView.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_5_0.width, var_5_0.height)
	}):onScroll(handler(arg_5_0, arg_5_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0):addTo(arg_5_0.detailContainer)

	arg_5_0:addScrollView()
	arg_5_0:update()
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevX_ = arg_6_1.x
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 5 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end

	local var_6_0 = arg_6_0.scrollView:getScrollNode()
	local var_6_1 = 0
	local var_6_2 = -(var_6_0:getCascadeBoundingBox().height - var_6_0:getContentSize().height)

	if var_6_1 < var_6_0:getPositionX() then
		arg_6_0.scrollView:scrollTo(0, var_6_1)
	elseif var_6_2 > var_6_0:getPositionX() then
		arg_6_0.scrollView:scrollTo(0, var_6_2)
	end
end

function var_0_0.addScrollView(arg_7_0)
	local var_7_0 = cc.Node:create()

	arg_7_0.scrollView:addScrollNode(var_7_0)

	arg_7_0.recordContainer = arg_7_0:nodeByName("record_container")

	arg_7_0.detailContainer:removeChild(arg_7_0.recordContainer)
	arg_7_0.recordContainer:addTo(var_7_0)
end

function var_0_0.update(arg_8_0)
	arg_8_0:addDetail()

	local var_8_0 = arg_8_0.recordContainer:getContentSize().height
	local var_8_1 = arg_8_0.scrollView:getViewRect()

	arg_8_0.scrollView.scrollWidth = var_8_1.width
	arg_8_0.scrollView.scrollHeight = var_8_0

	arg_8_0.scrollView:scrollTo(0, 0)
end

function var_0_0.addDetail(arg_9_0)
	local var_9_0 = arg_9_0:nodeByName("record_container")
	local var_9_1 = 0
	local var_9_2 = arg_9_0:nodeByName("title1"):getPositionY()

	for iter_9_0 = 1, 3 do
		local var_9_3 = arg_9_0.totalHero[iter_9_0]

		if #var_9_3 ~= 0 then
			local var_9_4 = arg_9_0:nodeByName("title" .. iter_9_0)

			var_9_4:setPosition(cc.p(5, var_9_2))
			var_9_4:setAnchorPoint(cc.p(0, 0))

			var_9_2 = var_9_2 - var_0_5 - 30

			local var_9_5 = 0
			local var_9_6 = 40

			for iter_9_1, iter_9_2 in pairs(var_9_3) do
				var_9_5 = var_9_5 + 1

				if var_9_5 > var_0_4 then
					var_9_5 = 1
					var_9_2 = var_9_2 - var_0_5 - 20
				end

				local var_9_7 = arg_9_0.heros[iter_9_2.table_id]

				arg_9_0:addRecord(var_9_0, var_9_7, 0, var_9_6, var_9_2, iter_9_0)

				var_9_6 = iter_9_1 % var_0_4 * (var_0_5 + 20) + 40
			end

			var_9_2 = var_9_2 - 80
		else
			arg_9_0:nodeByName("title" .. iter_9_0):setVisible(false)
		end
	end
end

function var_0_0.addRecord(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6)
	local var_10_0 = display.newNode()

	var_10_0:setContentSize(var_0_5, var_0_5)
	var_10_0:setPosition(arg_10_4, arg_10_5)
	var_10_0:setAnchorPoint(cc.p(0, 0))
	arg_10_1:addChild(var_10_0)

	if arg_10_6 == var_0_6 then
		xyd.setAvatarBorder(arg_10_2, var_10_0, arg_10_2:getColor(), arg_10_3)
	elseif arg_10_6 == var_0_7 then
		xyd.setAvatarBorder(arg_10_2, var_10_0, arg_10_2:getColor(), arg_10_3)
	elseif arg_10_6 == var_0_8 then
		if arg_10_2:isAwaken() then
			tableID = arg_10_2:beforeAwakenID()

			arg_10_2:setTableID(tableID)
		end

		xyd.setAvatarBorder(arg_10_2, var_10_0, arg_10_2:getColor(), arg_10_3)
	end
end

function var_0_0.addBlueStar(arg_11_0, arg_11_1, arg_11_2)
	local function var_11_0()
		local var_12_0 = "windows/across_arena/icon_blue_star.png"

		return xyd.AssetLoader.get():loadSprite(var_12_0)
	end

	local var_11_1 = arg_11_1:getChildByName("border")
	local var_11_2 = clone(var_11_1:getContentSize())
	local var_11_3 = arg_11_1:getContentSize()
	local var_11_4 = 0.6666666666666666
	local var_11_5 = var_11_0()

	var_11_5:setScale(var_11_4)

	local var_11_6 = var_11_5:getContentSize().width * var_11_4 - 3

	containerChildren = arg_11_1:getChildByName("view"):getChildren()

	local var_11_7 = (var_11_2.width - arg_11_2 * var_11_6) / 2

	for iter_11_0 = 1, arg_11_2 do
		local var_11_8 = var_11_0()

		var_11_8:setScale(var_11_4)
		arg_11_1:getChildByName("view"):addChild(var_11_8)
		var_11_8:x(var_11_7 + (iter_11_0 - 1) * var_11_6):y(5)
		var_11_8:setAnchorPoint(cc.p(0, 0))
	end
end

function var_0_0.setAvatarBorder(arg_13_0, arg_13_1, arg_13_2)
	local function var_13_0()
		local var_14_0 = "windows/common/small_blue_star.png"

		return xyd.AssetLoader.get():loadSprite(var_14_0)
	end

	local var_13_1 = arg_13_1:getStar()
	local var_13_2 = 0
end

return var_0_0
