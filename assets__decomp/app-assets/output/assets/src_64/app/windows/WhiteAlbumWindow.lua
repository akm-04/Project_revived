local var_0_0 = class("WhiteAlbumWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.attr
local var_0_5 = xyd.tables.albumNormalCollectTable
local var_0_6 = xyd.tables.albumSpecialCollectTable
local var_0_7 = 1
local var_0_8 = 2
local var_0_9 = {
	4,
	5,
	6,
	7,
	8,
	9,
	10,
	11,
	12,
	14,
	15
}
local var_0_10 = "skeletons/ui_effect/white_album/tujianshouji"
local var_0_11 = "skeletons/ui_effect/white_album/tujiandakai"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.currentState = var_0_7
	arg_1_0.selectedAttrs = var_0_9
	arg_1_0.showCollected = true
	arg_1_0.showUncollected = true
	arg_1_0.typeChanged = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:prepareData()
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	arg_3_0.selfPlayer:checkAlbumRedPoint()
end

function var_0_0.prepareData(arg_4_0)
	arg_4_0.specialIdList = {}

	for iter_4_0 = 1, #arg_4_0.selfPlayer.albumSpecialCollect do
		arg_4_0.specialIdList[iter_4_0] = iter_4_0
	end

	arg_4_0:getHeroesData()
	arg_4_0:initTables()
end

function var_0_0.sortSpecialIdList(arg_5_0)
	table.sort(arg_5_0.specialIdList, function(arg_6_0, arg_6_1)
		if arg_5_0.selfPlayer.albumSpecialCollect[arg_6_0] > arg_5_0.selfPlayer.albumSpecialCollect[arg_6_1] then
			return false
		end

		if arg_5_0.selfPlayer.albumSpecialCollect[arg_6_0] < arg_5_0.selfPlayer.albumSpecialCollect[arg_6_1] then
			return true
		end

		if arg_5_0.selfPlayer.albumSpecialCanCollect[arg_6_0] and not arg_5_0.selfPlayer.albumSpecialCanCollect[arg_6_1] then
			return true
		end

		if arg_5_0.selfPlayer.albumSpecialCanCollect[arg_6_1] and not arg_5_0.selfPlayer.albumSpecialCanCollect[arg_6_0] then
			return false
		end

		return arg_6_0 < arg_6_1
	end)
end

function var_0_0.getHeroesData(arg_7_0)
	arg_7_0.heroMap = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfPlayer.heros_) do
		local var_7_0 = xyd.getOriginHeroId(iter_7_1:getTableID())

		if not arg_7_0.heroMap[var_7_0] then
			arg_7_0.heroMap[var_7_0] = iter_7_1
		end
	end
end

function var_0_0.initTables(arg_8_0)
	arg_8_0.heroCanUpgrade = {}
	arg_8_0.heroCollected = {}
	arg_8_0.heroUnCollected = {}

	for iter_8_0 = 1, 15 do
		arg_8_0.heroCanUpgrade[iter_8_0] = {}
		arg_8_0.heroCollected[iter_8_0] = {}
		arg_8_0.heroUnCollected[iter_8_0] = {}
	end

	local var_8_0 = var_0_5:ids()

	for iter_8_1 = 1, #var_8_0 do
		local var_8_1 = var_8_0[iter_8_1]
		local var_8_2 = var_0_5:attrType(var_8_1)

		if not arg_8_0.heroMap[var_8_1] then
			table.insert(arg_8_0.heroUnCollected[var_8_2], var_8_1)
		elseif arg_8_0:checkCanUpgrade(var_8_1) then
			table.insert(arg_8_0.heroCanUpgrade[var_8_2], var_8_1)
		else
			table.insert(arg_8_0.heroCollected[var_8_2], var_8_1)
		end
	end
end

function var_0_0.checkCanUpgrade(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_0.heroMap[arg_9_1]

	if not var_9_0 then
		return false
	end

	local var_9_1 = var_9_0.collectQualityStage
	local var_9_2 = var_9_0.collectStarStage
	local var_9_3 = var_0_5:qualityStages(arg_9_1)

	if var_9_1 ~= #var_9_3 and var_9_0:getColor() >= var_9_3[var_9_1 + 1] then
		return true
	end

	local var_9_4 = var_0_5:starStages(arg_9_1)

	if var_9_2 ~= #var_9_4 and var_9_0:getStar() >= var_9_4[var_9_2 + 1] then
		return true
	end

	return false
end

function var_0_0.heroUpgrade(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_0.heroMap[arg_10_1]

	if not var_10_0 then
		return
	end

	local var_10_1 = var_10_0.collectQualityStage or 0
	local var_10_2 = var_10_0.collectStarStage or 0
	local var_10_3 = var_10_1
	local var_10_4 = var_0_5:qualityStages(arg_10_1)
	local var_10_5 = var_0_5:qualityAttr(arg_10_1)

	while var_10_3 < #var_10_4 and var_10_0:getColor() >= var_10_4[var_10_3 + 1] do
		var_10_3 = var_10_3 + 1
	end

	local var_10_6 = (var_10_5[var_10_3] or 0) - (var_10_5[var_10_1] or 0)

	var_10_0.collectQualityStage = var_10_3

	local var_10_7 = var_10_2
	local var_10_8 = var_0_5:starStages(arg_10_1)
	local var_10_9 = var_0_5:starAttr(arg_10_1)

	while var_10_7 < #var_10_8 and var_10_0:getStar() >= var_10_8[var_10_7 + 1] do
		var_10_7 = var_10_7 + 1
	end

	local var_10_10 = var_10_6 + (var_10_9[var_10_7] or 0) - (var_10_9[var_10_2] or 0)

	var_10_0.collectStarStage = var_10_7

	local var_10_11 = var_0_5:attrType(arg_10_1)

	arg_10_0.selfPlayer.albumAttr[var_10_11] = arg_10_0.selfPlayer.albumAttr[var_10_11] + var_10_10

	local var_10_12

	for iter_10_0 = 1, #arg_10_0.heroCanUpgrade[var_10_11] do
		if arg_10_0.heroCanUpgrade[var_10_11][iter_10_0] == arg_10_1 then
			var_10_12 = iter_10_0

			break
		end
	end

	table.remove(arg_10_0.heroCanUpgrade[var_10_11], var_10_12)
	table.insert(arg_10_0.heroCollected[var_10_11], arg_10_1)
	table.sort(arg_10_0.heroCollected[var_10_11], function(arg_11_0, arg_11_1)
		return arg_11_0 < arg_11_1
	end)
end

function var_0_0.getSelectResultList(arg_12_0, arg_12_1, arg_12_2)
	if arg_12_2 < arg_12_1 then
		return {}, {}, {}
	end

	if arg_12_1 == arg_12_2 then
		local var_12_0 = arg_12_0.selectedAttrs[arg_12_1]

		return clone(arg_12_0.heroCanUpgrade[var_12_0]), clone(arg_12_0.heroCollected[var_12_0]), clone(arg_12_0.heroUnCollected[var_12_0])
	end

	local var_12_1
	local var_12_2
	local var_12_3
	local var_12_4
	local var_12_5
	local var_12_6
	local var_12_7
	local var_12_8
	local var_12_9

	if arg_12_1 == arg_12_2 - 1 then
		local var_12_10 = arg_12_0.selectedAttrs[arg_12_1]

		var_12_2 = clone(arg_12_0.heroCanUpgrade[var_12_10])
		var_12_5 = clone(arg_12_0.heroCollected[var_12_10])
		var_12_8 = clone(arg_12_0.heroUnCollected[var_12_10])

		local var_12_11 = arg_12_0.selectedAttrs[arg_12_2]

		var_12_3 = clone(arg_12_0.heroCanUpgrade[var_12_11])
		var_12_6 = clone(arg_12_0.heroCollected[var_12_11])
		var_12_9 = clone(arg_12_0.heroUnCollected[var_12_11])
	else
		local var_12_12 = math.floor((arg_12_1 + arg_12_2) / 2)

		var_12_2, var_12_5, var_12_8 = arg_12_0:getSelectResultList(arg_12_1, var_12_12)
		var_12_3, var_12_6, var_12_9 = arg_12_0:getSelectResultList(var_12_12 + 1, arg_12_2)
	end

	local var_12_13 = arg_12_0:mixTable(var_12_2, var_12_3)
	local var_12_14 = arg_12_0:mixTable(var_12_5, var_12_6)
	local var_12_15 = arg_12_0:mixTable(var_12_8, var_12_9)

	return var_12_13, var_12_14, var_12_15
end

function var_0_0.mixTable(arg_13_0, arg_13_1, arg_13_2)
	if #arg_13_1 == 0 then
		return arg_13_2
	end

	if #arg_13_2 == 0 then
		return arg_13_1
	end

	local var_13_0 = {}
	local var_13_1 = 1
	local var_13_2 = 1

	while var_13_1 <= #arg_13_1 and var_13_2 <= #arg_13_2 do
		if arg_13_1[var_13_1] < arg_13_2[var_13_2] then
			table.insert(var_13_0, arg_13_1[var_13_1])

			var_13_1 = var_13_1 + 1
		else
			table.insert(var_13_0, arg_13_2[var_13_2])

			var_13_2 = var_13_2 + 1
		end
	end

	if var_13_1 <= #arg_13_1 then
		for iter_13_0 = var_13_1, #arg_13_1 do
			table.insert(var_13_0, arg_13_1[iter_13_0])
		end
	end

	if var_13_2 <= #arg_13_2 then
		for iter_13_1 = var_13_2, #arg_13_2 do
			table.insert(var_13_0, arg_13_2[iter_13_1])
		end
	end

	return var_13_0
end

function var_0_0.layout(arg_14_0)
	arg_14_0:nodeByName("txt_filter"):setString(var_0_3:translation("HERO_LIST_BTN_FILTER"))
	arg_14_0:nodeByName("txt_all"):setString(var_0_3:translation("WHITE_ALBUM_TXT1"))
	arg_14_0:nodeByName("bg_white"):getChildByName("txt"):setString(var_0_3:translation("WHITE_ALBUM_TXT2"))
	arg_14_0:nodeByName("btn_change"):getChildByName("txt"):setString(var_0_3:translation("WHITE_ALBUM_TXT3"))

	local var_14_0 = arg_14_0.selfPlayer.albumSpecialCollectedNum / #arg_14_0.selfPlayer.albumSpecialCollect * 100
	local var_14_1 = math.ceil(var_14_0 * 100) / 100

	arg_14_0:nodeByName("bar_txt"):setString(var_0_3:translation("WHITE_ALBUM_TXT19") .. var_14_1 .. "%")
	arg_14_0:nodeByName("bar"):setPercent(var_14_1)

	local var_14_2 = var_0_2.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.YELLOW)
	})

	var_14_2:addTo(arg_14_0:nodeByName("background"))
	var_14_2:setAnchorPoint(0.5, 0.5)
	var_14_2:setPosition(46, 694)
	var_14_2:setName("return_btn")

	arg_14_0.returnBtn = var_14_2

	arg_14_0.returnBtn:addTouchEvent(function(arg_15_0)
		if arg_15_0.name == "ended" then
			xyd.playCloseSound()
			xyd.WindowManager.get():closeWindow(arg_14_0)
		end
	end)
	xyd.addTouchEvent(arg_14_0:nodeByName("btn_all"), function()
		local var_16_0 = 0

		for iter_16_0 = 1, #var_0_9 do
			var_16_0 = var_16_0 + #arg_14_0.heroCollected[var_0_9[iter_16_0]] + #arg_14_0.heroCanUpgrade[var_0_9[iter_16_0]]
		end

		xyd.WindowManager.get():openWindow("album_total", {
			collectNum = var_16_0
		})
	end)
	xyd.addTouchEvent(arg_14_0:nodeByName("btn_filter"), function()
		xyd.WindowManager.get():openWindow("album_filter", {
			attrs = clone(arg_14_0.selectedAttrs),
			showCollected = arg_14_0.showCollected,
			showUncollected = arg_14_0.showUncollected
		})
	end)
	xyd.nodeEventSample(arg_14_0:nodeByName("btn_change"), {
		scale = 1
	}, function()
		arg_14_0.currentState = var_0_7 + var_0_8 - arg_14_0.currentState

		arg_14_0:nodeByName("btn_change"):setTouchEnabled(false)
		arg_14_0:nodeByName("btn_rule"):setTouchEnabled(false)
		arg_14_0:nodeByName("btn_change"):runAction(cc.Sequence:create({
			cc.Spawn:create({
				cc.FadeOut:create(0.3),
				cc.MoveBy:create(0.3, cc.p(-164, -5)),
				cc.ScaleTo:create(0.3, 1.25)
			}),
			cc.MoveBy:create(0, cc.p(164, 5)),
			cc.CallFunc:create(function()
				arg_14_0:nodeByName("btn_change"):setOpacity(255)
				arg_14_0:nodeByName("btn_change"):setScale(1)
				arg_14_0:nodeByName("btn_change"):setTouchEnabled(true)

				if arg_14_0.currentState == var_0_7 then
					arg_14_0:nodeByName("bg_white"):getChildByName("txt"):setString(var_0_3:translation("WHITE_ALBUM_TXT2"))
					arg_14_0:nodeByName("btn_change"):getChildByName("txt"):setString(var_0_3:translation("WHITE_ALBUM_TXT3"))
				else
					arg_14_0:nodeByName("bg_white"):getChildByName("txt"):setString(var_0_3:translation("WHITE_ALBUM_TXT3"))
					arg_14_0:nodeByName("btn_change"):getChildByName("txt"):setString(var_0_3:translation("WHITE_ALBUM_TXT2"))
				end
			end)
		}))
		arg_14_0:nodeByName("bg_white"):runAction(cc.Sequence:create({
			cc.Spawn:create({
				cc.FadeOut:create(0.3),
				cc.MoveBy:create(0.3, cc.p(164, 5)),
				cc.ScaleTo:create(0.3, 0.8)
			}),
			cc.MoveBy:create(0, cc.p(-164, -5)),
			cc.CallFunc:create(function()
				arg_14_0:nodeByName("bg_white"):setOpacity(255)
				arg_14_0:nodeByName("bg_white"):setScale(1)
				arg_14_0:nodeByName("btn_rule"):setTouchEnabled(true)
			end)
		}))
		arg_14_0:updateWindow()
	end)
	xyd.nodeEventSample(arg_14_0:nodeByName("btn_rule"), nil, function()
		xyd.WindowManager.get():openWindow("new_text_rule", {
			title_name = "COLLECT_TITLE",
			rule = "COLLECT_RULE"
		})
	end)

	arg_14_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_14_0:nodeByName("list"):getWidth(), arg_14_0:nodeByName("list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_14_0:nodeByName("list")):onScroll(handler(arg_14_0, arg_14_0.scrollListener))

	arg_14_0.list:setDelegate(handler(arg_14_0, arg_14_0.listDelegate))

	arg_14_0.specialList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_14_0:nodeByName("special_list"):getWidth(), arg_14_0:nodeByName("special_list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_14_0:nodeByName("special_list")):onScroll(handler(arg_14_0, arg_14_0.scrollListener))

	arg_14_0.specialList:setDelegate(handler(arg_14_0, arg_14_0.specialListDelegate))

	arg_14_0.reloadList = true

	arg_14_0:updateWindow()
end

function var_0_0.updateWindow(arg_22_0)
	arg_22_0:nodeByName("btn_all"):setVisible(arg_22_0.currentState == var_0_7)
	arg_22_0:nodeByName("btn_filter"):setVisible(arg_22_0.currentState == var_0_7)
	arg_22_0:nodeByName("list"):setVisible(arg_22_0.currentState == var_0_7)
	arg_22_0:nodeByName("bar_container"):setVisible(arg_22_0.currentState == var_0_8)
	arg_22_0:nodeByName("special_list"):setVisible(arg_22_0.currentState == var_0_8)

	if arg_22_0.currentState == var_0_7 then
		if not arg_22_0.reloadList then
			return
		end

		arg_22_0.typeChanged = {}
		arg_22_0.reloadList = false
		arg_22_0.canUpgradeList, arg_22_0.collectedList, arg_22_0.unCollectedList = arg_22_0:getSelectResultList(1, #arg_22_0.selectedAttrs)
		arg_22_0.canUpgradeList = arg_22_0.showCollected and arg_22_0.canUpgradeList or {}
		arg_22_0.collectedList = arg_22_0.showCollected and arg_22_0.collectedList or {}
		arg_22_0.unCollectedList = arg_22_0.showUncollected and arg_22_0.unCollectedList or {}

		arg_22_0.list:reload()
	else
		arg_22_0:sortSpecialIdList()
		arg_22_0.specialList:reload()
	end
end

function var_0_0.scrollListener(arg_23_0, arg_23_1)
	if arg_23_1.name == "began" then
		arg_23_0.scrollViewMoved_ = false
		arg_23_0.prevY_ = arg_23_1.y
	elseif arg_23_1.name == "moved" then
		if 10 <= math.abs(arg_23_1.y - arg_23_0.prevY_) then
			arg_23_0.scrollViewMoved_ = true
		end
	elseif arg_23_1.name == "ended" then
		arg_23_0.scrollViewMoved_ = false
	end
end

function var_0_0.listDelegate(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	local var_24_0 = #arg_24_0.canUpgradeList + #arg_24_0.collectedList + #arg_24_0.unCollectedList

	if cc.ui.UIListView.COUNT_TAG == arg_24_2 then
		return math.ceil(var_24_0 / 5)
	elseif cc.ui.UIListView.CELL_TAG == arg_24_2 then
		local var_24_1
		local var_24_2 = arg_24_1:dequeueItem()

		if not var_24_2 then
			var_24_2 = arg_24_1:newItem()
		else
			var_24_2:removeAllChildren(false)
		end

		local var_24_3 = display.newNode()

		var_24_3:size(1150, 288)

		for iter_24_0 = 1, 5 do
			local var_24_4 = arg_24_3 * 5 - 5 + iter_24_0

			if var_24_0 < var_24_4 then
				break
			end

			local var_24_5 = 1
			local var_24_6 = arg_24_0.canUpgradeList[var_24_4]

			if var_24_4 > #arg_24_0.canUpgradeList then
				local var_24_7 = var_24_4 - #arg_24_0.canUpgradeList

				if var_24_7 > #arg_24_0.collectedList then
					var_24_7 = var_24_7 - #arg_24_0.collectedList
					var_24_6 = arg_24_0.unCollectedList[var_24_7]
					var_24_5 = 3
				else
					var_24_6 = arg_24_0.collectedList[var_24_7]
					var_24_5 = 2
				end
			end

			if arg_24_0.typeChanged[arg_24_3] then
				var_24_5 = arg_24_0.typeChanged[arg_24_3]
			end

			local var_24_8 = xyd.AssetLoader.get():loadNodeFromJson("windows/white_album/normal_cell.csb")

			var_24_8:addTo(var_24_3)
			var_24_8:pos(16 + 230 * (iter_24_0 - 1), 5)

			local var_24_9 = var_24_8:getChildByName("container")
			local var_24_10
			local var_24_11
			local var_24_12

			if not arg_24_0.heroMap[var_24_6] then
				local var_24_13 = {
					filter = {
						name = "GRAY",
						value = {
							0.2,
							0.3,
							0.5,
							0.1
						}
					}
				}

				var_24_10 = xyd.SpriteLoader.new(xyd.tables.model:newSmallCard(var_24_6), nil, var_24_13, xyd.DefaultImageType.S_CARD)
				var_24_11 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/border_gray.png")
				var_24_12 = arg_24_0:getHeroQualityIcon(1)
			else
				var_24_10 = xyd.getNewSmallCard(arg_24_0.heroMap[var_24_6])
				var_24_11 = xyd.getSmallCardBorder(arg_24_0.heroMap[var_24_6])
				var_24_12 = arg_24_0:getHeroQualityIcon(arg_24_0.heroMap[var_24_6]:getColor(), arg_24_0.heroMap[var_24_6]:getInscriptionKuangLevel())
			end

			var_24_10:setAnchorPoint(0.5, 0.5)
			var_24_10:addTo(var_24_9:getChildByName("card"))
			var_24_10:pos(101, 137)
			var_24_11:addTo(var_24_9:getChildByName("card"))
			var_24_11:pos(101, 137)

			if var_24_12 then
				var_24_12:addTo(var_24_9:getChildByName("card"))
				var_24_12:setAnchorPoint(0.5, 0.5)
				var_24_12:pos(30, 255)
			end

			var_24_9:getChildByName("name"):setString(var_0_5:name(var_24_6))
			var_24_9:getChildByName("name"):enableOutline(cc.c4b(51, 31, 31, 255), 3)
			var_24_9:getChildByName("txt_upgrade"):setString(var_0_3:translation("WHITE_ALBUM_TXT4"))
			var_24_9:getChildByName("txt_upgrade"):enableOutline(cc.c4b(40, 21, 16, 255), 2)
			var_24_9:getChildByName("txt_uncollect"):setString(var_0_3:translation("WHITE_ALBUM_TXT5"))
			var_24_9:getChildByName("star_attr_txt"):setString(var_0_3:translation("WHITE_ALBUM_TXT10"))
			arg_24_0:updateNormalCell(var_24_9, var_24_6, var_24_5, arg_24_3)
		end

		var_24_2:addContent(var_24_3)
		var_24_2:setItemSize(1150, 288)

		return var_24_2
	end
end

function var_0_0.updateNormalCell(arg_25_0, arg_25_1, arg_25_2, arg_25_3, arg_25_4)
	arg_25_1:getChildByName("lock"):setVisible(arg_25_3 == 3)
	arg_25_1:getChildByName("txt_uncollect"):setVisible(arg_25_3 == 3)
	arg_25_1:getChildByName("txt_upgrade"):setVisible(arg_25_3 == 1)
	arg_25_1:getChildByName("clip"):setVisible(arg_25_3 ~= 2)
	arg_25_1:getChildByName("tip"):setVisible(arg_25_3 ~= 2)
	arg_25_1:getChildByName("quality_attr_txt"):setVisible(arg_25_3 == 2)
	arg_25_1:getChildByName("quality_attr_num"):setVisible(arg_25_3 == 2)

	if arg_25_3 == 1 then
		arg_25_1:getChildByName("tip"):setString(var_0_3:translation("WHITE_ALBUM_TXT7"))
	elseif arg_25_3 == 3 then
		arg_25_1:getChildByName("tip"):setString(var_0_3:translation("WHITE_ALBUM_TXT8"))
	end

	local var_25_0 = arg_25_3 ~= 3 and arg_25_0.heroMap[arg_25_2].collectStarStage or 0
	local var_25_1 = var_0_5:starAttr(arg_25_2)

	arg_25_1:getChildByName("star_attr_num"):setString("+" .. (var_25_1[var_25_0] or 0))

	local var_25_2 = arg_25_3 ~= 3 and arg_25_0.heroMap[arg_25_2].collectQualityStage or 0
	local var_25_3 = var_0_5:qualityStages(arg_25_2)
	local var_25_4 = var_0_5:qualityAttr(arg_25_2)
	local var_25_5 = var_0_5:attrType(arg_25_2)

	arg_25_1:getChildByName("quality_attr_txt"):setString(var_0_4:name(var_25_5))
	arg_25_1:getChildByName("quality_attr_num"):setString("+" .. (var_25_4[var_25_2] or 0))

	if arg_25_3 ~= 2 then
		arg_25_1:getChildByName("upgrade_attr_txt"):setString(var_0_4:name(var_25_5))

		local var_25_6 = var_25_2
		local var_25_7 = 1

		if arg_25_0.heroMap[arg_25_2] then
			var_25_7 = arg_25_0.heroMap[arg_25_2]:getColor()
		end

		while var_25_6 < #var_25_3 and var_25_7 >= var_25_3[var_25_6 + 1] do
			var_25_6 = var_25_6 + 1
		end

		arg_25_1:getChildByName("upgrade_attr_num"):setString("+" .. (var_25_4[var_25_6] or 0))
	elseif var_25_2 == #var_25_3 then
		arg_25_1:getChildByName("upgrade_attr_txt"):setString(var_0_3:translation("WHITE_ALBUM_TXT9"))
		arg_25_1:getChildByName("upgrade_attr_num"):setString("")
	else
		local var_25_8 = var_25_3[var_25_2 + 1]

		arg_25_1:getChildByName("upgrade_attr_txt"):setString(var_0_3:translation("WHITE_ALBUM_TXT6") .. string.upper(xyd.Color2NewQuality[var_25_8]) .. xyd.Color2Level[var_25_8])
		arg_25_1:getChildByName("upgrade_attr_num"):setString("+" .. var_25_4[var_25_2 + 1])
	end

	if arg_25_3 == 1 then
		local var_25_9 = xyd.createEffect(var_0_10)

		var_25_9:addTo(arg_25_1)
		var_25_9:pos(arg_25_1:getWidth() / 2, arg_25_1:getHeight() / 2)
		var_25_9:setName("effect1")
		var_25_9:play(nil, true)
		arg_25_1:getChildByName("clip"):setTouchSwallowEnabled(false)
		xyd.nodeEventSample(arg_25_1:getChildByName("clip"), {
			scale = 1
		}, function()
			if arg_25_0.scrollViewMoved_ then
				return
			end

			local var_26_0 = arg_25_0.heroMap[arg_25_2]

			xyd.Backend.get():request(xyd.mid.ALBUM_PARTNER_UNLOCK, {
				partner_id = var_26_0:getHeroID()
			}, function(arg_27_0)
				if arg_27_0 == xyd.error.OK then
					arg_25_0.typeChanged[arg_25_4] = 2

					arg_25_0:heroUpgrade(arg_25_2)
					arg_25_0:updateNormalCell(arg_25_1, arg_25_2, 2, arg_25_4)
					var_25_9:setVisible(false)

					local var_27_0 = xyd.createEffect(var_0_11)

					var_27_0:addTo(arg_25_1)
					var_27_0:pos(arg_25_1:getWidth() / 2, arg_25_1:getHeight() / 2)
					var_27_0:play(function()
						var_27_0:setVisible(false)
					end)
				end
			end)
		end)
	end
end

function var_0_0.getHeroQualityIcon(arg_29_0, arg_29_1, arg_29_2)
	if xyd.Color2Level[arg_29_1] == "" then
		return
	end

	local var_29_0 = "windows/common/hero_common/hero_quality_"
	local var_29_1

	if arg_29_2 then
		if arg_29_2 == 1 then
			return
		end

		var_29_1 = "suit_" .. arg_29_2
	else
		var_29_1 = tostring(arg_29_1)
	end

	return xyd.AssetLoader.get():loadSprite(var_29_0 .. var_29_1 .. ".png")
end

function var_0_0.specialListDelegate(arg_30_0, arg_30_1, arg_30_2, arg_30_3)
	if cc.ui.UIListView.COUNT_TAG == arg_30_2 then
		return #arg_30_0.specialIdList
	elseif cc.ui.UIListView.CELL_TAG == arg_30_2 then
		local var_30_0
		local var_30_1 = arg_30_1:dequeueItem()

		if not var_30_1 then
			var_30_1 = arg_30_1:newItem()
		else
			var_30_1:removeAllChildren(false)
		end

		local var_30_2 = display.newNode()

		var_30_2:size(1185, 173)
		var_30_1:addContent(var_30_2)
		var_30_1:setItemSize(1185, 173)

		local var_30_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/white_album/special_cell.csb")

		var_30_3:addTo(var_30_2)
		var_30_3:pos(0, 1)

		local var_30_4 = var_30_3:getChildByName("container")
		local var_30_5 = arg_30_0.specialIdList[arg_30_3]

		var_30_4:getChildByName("title"):setString(var_0_6:title(var_30_5))
		var_30_4:getChildByName("title"):enableOutline(cc.c4b(85, 49, 27, 255), 2)
		var_30_4:getChildByName("desc"):setString(var_0_6:desc(var_30_5))

		local var_30_6 = var_0_6:partnerId(var_30_5)
		local var_30_7 = true
		local var_30_8 = arg_30_0.selfPlayer.albumSpecialCollect[var_30_5]

		for iter_30_0 = 1, #var_30_6 do
			local var_30_9 = display.newNode()

			var_30_9:size(90, 90)
			var_30_9:pos(100 * (iter_30_0 - 1), 0)
			var_30_9:setAnchorPoint(0.5, 0.5)
			var_30_9:addTo(var_30_4:getChildByName("hero_pos"))
			xyd.setAvatarBorderNewUI(var_30_6[iter_30_0], var_30_9, 1, 0, nil, not arg_30_0.heroMap[var_30_6[iter_30_0]])

			local var_30_10 = {}
			local var_30_11 = cc.Node:create()

			var_30_11:setAnchorPoint(cc.p(0, 0))
			var_30_11:setContentSize(100, 100)
			var_30_9:addChild(var_30_11)

			var_30_10.id = var_30_6[iter_30_0]
			var_30_10.desc = xyd.tables.hero:getDes(var_30_6[iter_30_0])
			var_30_10.name = xyd.tables.hero:name(var_30_6[iter_30_0])
			var_30_10.isHero = true

			var_30_11:setTouchEnabled(true)
			var_30_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_31_0)
				if arg_31_0.name == "began" then
					local var_31_0 = xyd.WindowManager.get():getWindow("new_item_tips")
					local var_31_1 = arg_30_0:convertToWorldSpace(cc.p(0, 0))

					if not var_31_0 then
						local var_31_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_30_10)

						xyd.adaptToWorldPosition(var_30_11, var_31_2)
					end

					return true
				elseif arg_31_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
					local var_31_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
				end
			end)

			var_30_7 = var_30_7 and arg_30_0.heroMap[var_30_6[iter_30_0]]
		end

		var_30_4:getChildByName("btn_unlock"):setVisible(var_30_7 and var_30_8 == 0)
		var_30_4:getChildByName("arrow"):setVisible(not var_30_7)
		var_30_4:getChildByName("item"):setVisible(true)
		var_30_4:getChildByName("unlocked"):setVisible(var_30_8 == 1)

		local var_30_12 = var_0_6:type(var_30_5)

		if var_30_12 == 1 then
			local var_30_13 = var_0_6:icon(var_30_5)
			local var_30_14 = xyd.AssetLoader.get():loadSprite(var_30_13)

			var_30_14:addTo(var_30_4:getChildByName("item"))
			var_30_14:pos(45, 45)
			var_30_14:setTouchEnabled(true)
			var_30_14:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_32_0)
				if arg_32_0.name == "began" then
					local var_32_0 = {
						attr = var_0_6:reward(var_30_5),
						num = var_0_6:num(var_30_5)
					}
					local var_32_1 = xyd.WindowManager.get():openWindow("album_attr_tip", var_32_0)
					local var_32_2 = var_30_14:convertToWorldSpace(cc.p(0, 0))
					local var_32_3 = cc.Director:getInstance():getVisibleSize()

					var_32_1:setPosition(var_32_2.x - 20 - 0.5 * (var_32_3.width - 1280), var_32_2.y - 0.5 * (var_32_3.height - 720) + 90)
				elseif arg_32_0.name == "ended" or arg_30_0.scrollViewMoved_ then
					xyd.WindowManager.get():closeWindow("album_attr_tip")
				end

				return true
			end)
		elseif var_30_12 == 2 then
			xyd.setItemAndAddTips(var_30_4:getChildByName("item"), var_0_6:reward(var_30_5))
		end

		xyd.nodeEventSample(var_30_4:getChildByName("btn_unlock"), nil, function()
			xyd.Backend.get():request(xyd.mid.ALBUM_SPECIAL_COLLECT_REWARD, {
				id = var_30_5
			}, function(arg_34_0, arg_34_1)
				if arg_34_0 == xyd.error.OK then
					var_30_4:getChildByName("btn_unlock"):setVisible(false)
					var_30_4:getChildByName("unlocked"):setVisible(true)

					arg_30_0.selfPlayer.albumSpecialCollect[var_30_5] = 1
					arg_30_0.selfPlayer.albumSpecialCanCollect[var_30_5] = false

					if var_30_12 == 1 then
						local var_34_0 = var_0_6:reward(var_30_5)
						local var_34_1 = var_0_6:num(var_30_5)

						arg_30_0.selfPlayer.albumAttr[var_34_0] = arg_30_0.selfPlayer.albumAttr[var_34_0] + var_34_1
					elseif var_30_12 == 2 then
						arg_30_0.selfPlayer:handleRewards(arg_34_1.awards)
					end

					arg_30_0.selfPlayer.albumSpecialCollectedNum = arg_30_0.selfPlayer.albumSpecialCollectedNum + 1

					local var_34_2 = arg_30_0.selfPlayer.albumSpecialCollectedNum / #arg_30_0.selfPlayer.albumSpecialCollect * 100
					local var_34_3 = math.ceil(var_34_2 * 100) / 100

					arg_30_0:nodeByName("bar_txt"):setString(var_0_3:translation("WHITE_ALBUM_TXT19") .. var_34_3 .. "%")
					arg_30_0:nodeByName("bar"):setPercent(var_34_3)
				end
			end)
		end)

		return var_30_1
	end
end

function var_0_0.onFilterReturn(arg_35_0, arg_35_1)
	arg_35_0.showCollected = arg_35_1.showCollected
	arg_35_0.showUncollected = arg_35_1.showUncollected
	arg_35_0.selectedAttrs = arg_35_1.attrs
	arg_35_0.reloadList = true

	arg_35_0:updateWindow()
end

return var_0_0
