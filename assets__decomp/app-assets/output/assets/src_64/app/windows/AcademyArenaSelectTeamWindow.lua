local var_0_0 = class("AcademyArenaSelectTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.hero
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.ACADEMY_ARENA)
	arg_1_0.teamId = arg_1_2.teamId or -1
	arg_1_0.preIds = arg_1_2.preIds or {}
	arg_1_0.heros = arg_1_0.model.recruitHeros
	arg_1_0.team_ = {}
	arg_1_0.select_ = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initPreHero(arg_2_0.preIds)
	arg_2_0:initHeros(arg_2_0.heros)

	local var_2_0 = arg_2_0:nodeByName("list_container")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.width = var_2_1.width
	arg_2_0.ListView = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_2_0)

	arg_2_0.ListView:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0:initRightMenu()
	arg_2_0:updateView()
	arg_2_0:updateScore()
	arg_2_0:nodeByName("confirm_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			arg_2_0.model:adjustTeam(arg_2_0.teamId, arg_2_0.select_, arg_2_0.combatEffectiveness, function()
				local var_4_0 = xyd.WindowManager.get():getWindow("academy_arena")

				if var_4_0 then
					local var_4_1 = 0

					for iter_4_0, iter_4_1 in ipairs(arg_2_0.model.teamInfo) do
						if iter_4_1.map_id == arg_2_0.model.baseMapId then
							var_4_1 = var_4_1 + 1
						end
					end

					var_4_0.baseTeamNum:getChildByName("num"):setString(var_4_1)
				end

				local var_4_2 = xyd.WindowManager.get():getWindow("academy_arena_recruit")

				if var_4_2 then
					var_4_2:updateTeam()
				end

				xyd.WindowManager.get():closeWindow(arg_2_0)
			end)
		end
	end)
end

function var_0_0.initPreHero(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in ipairs(arg_5_1) do
		local var_5_0 = arg_5_0:newAcademyHero(iter_5_1)
		local var_5_1 = arg_5_0:initBottomCell(var_5_0, iter_5_1)

		var_5_1.iniCellVisible_ = true
		var_5_1.iniCell_ = display.newNode()

		var_5_1:addTo(arg_5_0)
		var_5_1:setTouchEnabled(true)
		var_5_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
			if arg_6_0.name == "ended" then
				arg_5_0:clickBottomAvatar(var_5_1)
			end

			return true
		end)

		for iter_5_2 = arg_5_0:getTeamNo(var_5_1), #arg_5_0.team_ do
			local var_5_2, var_5_3 = arg_5_0:nodeByName("avatar" .. iter_5_2):getPosition()

			arg_5_0.team_[iter_5_2]:pos(var_5_2, var_5_3)

			if arg_5_0.team_[iter_5_2].iniCell_ then
				arg_5_0.team_[iter_5_2].iniCell_.teamNo_ = iter_5_2
			end
		end
	end
end

function var_0_0.initHeros(arg_7_0, arg_7_1)
	arg_7_0.herosList = {}
	arg_7_0.herosList[xyd.DistanceType.ALL] = {}
	arg_7_0.herosList[xyd.DistanceType.QIANPAI] = {}
	arg_7_0.herosList[xyd.DistanceType.ZHONGPAI] = {}
	arg_7_0.herosList[xyd.DistanceType.HOUPAI] = {}

	for iter_7_0, iter_7_1 in pairs(arg_7_1) do
		iter_7_0 = tonumber(iter_7_0)

		local var_7_0 = var_0_1:distanceType(iter_7_0)

		if var_7_0 == xyd.DistanceType.QIANPAI then
			table.insert(arg_7_0.herosList[xyd.DistanceType.QIANPAI], {
				id = iter_7_0,
				info = iter_7_1
			})
		elseif var_7_0 == xyd.DistanceType.ZHONGPAI then
			table.insert(arg_7_0.herosList[xyd.DistanceType.ZHONGPAI], {
				id = iter_7_0,
				info = iter_7_1
			})
		elseif var_7_0 == xyd.DistanceType.HOUPAI then
			table.insert(arg_7_0.herosList[xyd.DistanceType.HOUPAI], {
				id = iter_7_0,
				info = iter_7_1
			})
		end

		table.insert(arg_7_0.herosList[xyd.DistanceType.ALL], {
			id = iter_7_0,
			info = iter_7_1
		})
	end

	for iter_7_2, iter_7_3 in ipairs(arg_7_0.herosList) do
		table.sort(iter_7_3, function(arg_8_0, arg_8_1)
			return
		end)
	end
end

function var_0_0.initRightMenu(arg_9_0)
	arg_9_0.nowType = xyd.DistanceType.ALL
	arg_9_0.rightMenuButtons_ = {}

	table.insert(arg_9_0.rightMenuButtons_, arg_9_0:nodeByName("all_btn"))
	table.insert(arg_9_0.rightMenuButtons_, arg_9_0:nodeByName("qian_btn"))
	table.insert(arg_9_0.rightMenuButtons_, arg_9_0:nodeByName("zhong_btn"))
	table.insert(arg_9_0.rightMenuButtons_, arg_9_0:nodeByName("hou_btn"))

	for iter_9_0 = 1, #arg_9_0.rightMenuButtons_ do
		arg_9_0.rightMenuButtons_[iter_9_0]:addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				arg_9_0.nowType = iter_9_0

				arg_9_0:updateView()
			end
		end)
	end
end

function var_0_0.updateView(arg_11_0)
	for iter_11_0 = 1, #arg_11_0.rightMenuButtons_ do
		if iter_11_0 == arg_11_0.nowType then
			arg_11_0.rightMenuButtons_[iter_11_0]:setTouchEnabled(false)
			arg_11_0.rightMenuButtons_[iter_11_0]:setBright(false)
		else
			arg_11_0.rightMenuButtons_[iter_11_0]:setTouchEnabled(true)
			arg_11_0.rightMenuButtons_[iter_11_0]:setBright(true)
		end
	end

	arg_11_0.ListView:reload()
end

function var_0_0.delegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = 5
	local var_12_1 = 180

	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return math.ceil(#arg_12_0.herosList[arg_12_0.nowType] / var_12_0)
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		local var_12_2
		local var_12_3 = arg_12_0.ListView:dequeueItem()

		if not var_12_3 then
			var_12_3 = arg_12_0.ListView:newItem()
		else
			var_12_3:removeAllChildren()
		end

		local var_12_4 = display.newNode()

		var_12_4:setTouchSwallowEnabled(false)

		for iter_12_0 = 1, var_12_0 do
			local var_12_5 = (arg_12_3 - 1) * var_12_0 + iter_12_0

			if var_12_5 > #arg_12_0.herosList[arg_12_0.nowType] then
				break
			end

			local var_12_6 = arg_12_0:initHeroCell(var_12_5)

			var_12_6:pos((iter_12_0 - (var_12_0 + 1) / 2) * 130 + arg_12_0.width / 2, var_12_1 / 2)
			var_12_6:addTo(var_12_4)
		end

		var_12_4:setContentSize(arg_12_0.width, var_12_1)
		var_12_3:setItemSize(arg_12_0.width, var_12_1)
		var_12_3:addContent(var_12_4)

		return var_12_3
	end
end

function var_0_0.initHeroCell(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_0.herosList[arg_13_0.nowType][arg_13_1]
	local var_13_1 = var_13_0.id
	local var_13_2 = var_13_0.info
	local var_13_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/academy_arena/recruit/hero_item.csb")
	local var_13_4 = var_13_3:getChildByName("mask")
	local var_13_5 = arg_13_0:newAcademyHero(var_13_1)

	xyd.setAvatarBorder(var_13_5, var_13_3:getChildByName("avatar"))

	local var_13_6 = var_13_3:getChildByName("bg_hp")

	var_13_6:setVisible(true)

	if var_13_2.health > 0 then
		var_13_6:getChildByName("hp_bar"):setPercent(math.max(var_13_2.hp, 1) / var_13_2.total_hp * 100)
	end

	var_13_3:getChildByName("lv_txt"):setString(var_13_5:getLevel())

	local var_13_7 = var_13_3:getChildByName("name_text")

	var_13_7:setString(var_13_5:getName())
	var_13_7:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[var_13_5:getColor()] ~= "" then
		local var_13_8 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_13_7:getX() + var_13_7:getWidth() / 2 - 10,
			y = var_13_7:getY(),
			color = xyd.color.HERO_QUALITY[var_13_5:getColor()],
			text = xyd.Color2Level[var_13_5:getColor()]
		}
		local var_13_9 = xyd.AssetLoader.get():loadLabel(var_13_8)

		var_13_9:addTo(var_13_3)
		var_13_9:align(display.CENTER_LEFT)
		var_13_9:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_13_7:x(var_13_7:getX() - 15)
	end

	var_13_3.data = var_13_5
	var_13_3.id = var_13_1

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.select_) do
		if iter_13_1 == var_13_1 then
			var_13_3.teamNo_ = iter_13_0
			arg_13_0.team_[iter_13_0].iniCell_ = var_13_3
			arg_13_0.team_[iter_13_0].iniCellVisible_ = false

			var_13_4:setVisible(true)
			var_13_3:getChildByName("chosen"):setVisible(true)

			var_13_3.isChosen = 1

			break
		end
	end

	if var_13_2.act then
		var_13_4:setVisible(true)
		var_13_3:getChildByName("tip0"):setVisible(true)
		var_13_3:getChildByName("tip0"):setString(var_0_2:translation("ACADEMY_ARENA_IS_ACT"))
	else
		if var_13_3.isChosen ~= 1 and var_13_2.teamId and var_13_2.teamId ~= arg_13_0.teamId then
			var_13_4:setVisible(true)
			var_13_3:getChildByName("tip1"):setVisible(true)
			var_13_3:getChildByName("tip1"):setString(var_0_2:translation("ACADEMY_ARENA_IN_OTHER_TEAM"))
		end

		var_13_3:setTouchEnabled(true)
		var_13_3:setTouchSwallowEnabled(false)
		var_13_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
			arg_13_0:buttonHandler(nil, var_13_3, arg_14_0)

			if arg_14_0.name == "began" then
				arg_13_0.startClick_ = true
				arg_13_0.prevX_ = arg_14_0.x
				arg_13_0.prevY_ = arg_14_0.y
			elseif arg_14_0.name == "moved" then
				if math.abs(arg_14_0.y - arg_13_0.prevY_) > 5 or math.abs(arg_14_0.x - arg_13_0.prevX_) > 5 then
					arg_13_0.startClick_ = false
				end
			elseif arg_14_0.name == "ended" and arg_13_0.startClick_ then
				if var_13_2.teamId and var_13_2.teamId ~= arg_13_0.teamId then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ACADEMY_ARENA_TWO_CONFIRMATIONS"), function()
						var_13_3:getChildByName("tip1"):setVisible(false)
						arg_13_0:clickAvatar(var_13_3)
					end, nil, nil, arg_13_0.colorMode)
				else
					arg_13_0:clickAvatar(var_13_3)
				end
			end

			return true
		end)
	end

	return var_13_3
end

function var_0_0.buttonHandler(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	if not arg_16_2 or not arg_16_2:getParent() then
		return
	end

	if arg_16_3.name == "ended" then
		transition.stopTarget(arg_16_2)
		arg_16_2:setScale(1)

		if arg_16_1 then
			arg_16_1(arg_16_2, eventType)
		end
	elseif arg_16_3.name == "began" then
		local var_16_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_16_2:runAction(var_16_0)

		return true
	elseif arg_16_3.name == "cancled" then
		transition.stopTarget(arg_16_2)
		arg_16_2:setScale(1)
	end
end

function var_0_0.clickAvatar(arg_17_0, arg_17_1, arg_17_2)
	if arg_17_1.isAnimated_ or not arg_17_1.teamNo_ and #arg_17_0.team_ >= xyd.MAX_TEAM_MEMBER_NUM then
		return
	end

	if not arg_17_2 then
		arg_17_0.unPreSelect_ = true
	end

	local var_17_0 = arg_17_1:getChildByName("mask")
	local var_17_1 = arg_17_1:getChildByName("chosen")
	local var_17_2 = arg_17_1:convertToWorldSpace(cc.p(0, 0))
	local var_17_3 = var_17_2.x + arg_17_1:getContentSize().width / 2
	local var_17_4 = var_17_2.y + arg_17_1:getContentSize().height / 2

	arg_17_1.isAnimated_ = true

	if arg_17_1.teamNo_ then
		local var_17_5 = arg_17_0.team_[arg_17_1.teamNo_]

		arg_17_0:moveFadeOutAction(var_17_3, var_17_4, var_17_5, function()
			arg_17_1.isAnimated_ = false
		end)
		var_17_0:setVisible(false)
		var_17_1:setVisible(false)

		for iter_17_0 = #arg_17_0.team_, arg_17_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_17_0.team_[iter_17_0])

			local var_17_6, var_17_7 = arg_17_0:nodeByName("avatar" .. iter_17_0 - 1):getPosition()

			transition.moveTo(arg_17_0.team_[iter_17_0], {
				time = 0.3,
				x = var_17_6,
				y = var_17_7
			})

			arg_17_0.team_[iter_17_0].iniCell_.teamNo_ = iter_17_0 - 1
		end

		table.remove(arg_17_0.team_, arg_17_1.teamNo_)
		table.remove(arg_17_0.select_, arg_17_1.teamNo_)

		arg_17_1.teamNo_ = nil
	elseif not arg_17_1.teamNo_ and #arg_17_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
		if not arg_17_2 then
			local var_17_8 = arg_17_1.data:getTableID()

			if var_0_1:chosenSound(var_17_8) ~= "" then
				xyd.AssetDownload.get():preloadCharacterSound({
					var_17_8
				}, function()
					return
				end, true)
				audio.playSound(var_0_1:chosenSound(var_17_8), false)
			end
		end

		local var_17_9 = arg_17_0:initBottomCell(arg_17_1.data, arg_17_1.id)

		var_17_9.iniCell_ = arg_17_1

		var_17_9:pos(var_17_3, var_17_4)
		var_17_9:addTo(arg_17_0)
		var_17_9:setTouchEnabled(true)

		local var_17_10 = arg_17_1.data

		var_17_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
			if arg_20_0.name == "ended" then
				arg_17_0:clickBottomAvatar(var_17_9)
			end

			return true
		end)

		arg_17_1.teamNo_ = arg_17_0:getTeamNo(var_17_9)

		for iter_17_1 = arg_17_1.teamNo_, #arg_17_0.team_ do
			local var_17_11, var_17_12 = arg_17_0:nodeByName("avatar" .. iter_17_1):getPosition()

			if arg_17_2 then
				arg_17_0.team_[iter_17_1]:pos(var_17_11, var_17_12)

				arg_17_1.isAnimated_ = false
			elseif iter_17_1 ~= arg_17_1.teamNo_ then
				local var_17_13 = arg_17_0.team_[iter_17_1]

				transition.stopTarget(var_17_13)
				transition.moveTo(var_17_13, {
					time = 0.3,
					x = var_17_11,
					y = var_17_12,
					onComplete = function()
						var_17_13.iniCell_.isAnimated_ = false
						var_17_13.isAnimated_ = false
					end
				})
			else
				local var_17_14 = arg_17_0.team_[iter_17_1]

				transition.stopTarget(var_17_14)

				var_17_9.isAnimated_ = true

				transition.moveTo(var_17_14, {
					time = 0.3,
					x = var_17_11,
					y = var_17_12,
					onComplete = function()
						arg_17_1.isAnimated_ = false
						var_17_9.isAnimated_ = false
					end
				})
			end

			arg_17_0.team_[iter_17_1].iniCell_.teamNo_ = iter_17_1
		end

		var_17_0:setVisible(true)
		var_17_1:setVisible(true)
	end

	arg_17_0:updateScore()
end

function var_0_0.clickBottomAvatar(arg_23_0, arg_23_1)
	if arg_23_1.isAnimated_ then
		return
	end

	local var_23_0, var_23_1 = arg_23_0:nodeByName("list_container"):getPosition()
	local var_23_2 = arg_23_1.iniCell_
	local var_23_3

	for iter_23_0, iter_23_1 in ipairs(arg_23_0.select_) do
		if iter_23_1 == arg_23_1.id then
			var_23_3 = iter_23_0

			break
		end
	end

	if not var_23_3 then
		return
	end

	if not arg_23_1.iniCellVisible_ and not tolua.isnull(var_23_2) then
		local var_23_4 = var_23_2:convertToWorldSpace(cc.p(0, 0))

		var_23_0, var_23_1 = var_23_4.x + var_23_2:getContentSize().width / 2, var_23_4.y + var_23_2:getContentSize().height / 2

		var_23_2:getChildByName("mask"):setVisible(false)
		var_23_2:getChildByName("chosen"):setVisible(false)
	end

	arg_23_0:moveFadeOutAction(var_23_0, var_23_1, arg_23_1)

	for iter_23_2 = #arg_23_0.team_, var_23_3 + 1, -1 do
		local var_23_5 = arg_23_0.team_[iter_23_2]
		local var_23_6, var_23_7 = arg_23_0:nodeByName("avatar" .. iter_23_2 - 1):getPosition()

		transition.stopTarget(var_23_5)
		transition.moveTo(arg_23_0.team_[iter_23_2], {
			time = 0.3,
			x = var_23_6,
			y = var_23_7
		})

		arg_23_0.team_[iter_23_2].iniCell_.teamNo_ = iter_23_2 - 1
	end

	table.remove(arg_23_0.team_, var_23_3)
	table.remove(arg_23_0.select_, var_23_3)

	var_23_2.teamNo_ = nil

	arg_23_0:updateScore()
end

function var_0_0.initBottomCell(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/academy_arena/recruit/hero_item.csb")

	xyd.setAvatarBorder(arg_24_1, var_24_0:getChildByName("avatar"))

	local var_24_1 = arg_24_0.model.recruitHeros[tostring(arg_24_2)]
	local var_24_2 = var_24_0:getChildByName("bg_hp")

	var_24_2:setVisible(true)

	if var_24_1.health > 0 then
		var_24_2:getChildByName("hp_bar"):setPercent(math.max(var_24_1.hp, 1) / var_24_1.total_hp * 100)
	end

	var_24_0:getChildByName("lv_txt"):setString(arg_24_1:getLevel())

	local var_24_3 = var_24_0:getChildByName("name_text")

	var_24_3:setString(arg_24_1:getName())
	var_24_3:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[arg_24_1:getColor()] ~= "" then
		local var_24_4 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_24_3:getX() + var_24_3:getWidth() / 2 - 10,
			y = var_24_3:getY(),
			color = xyd.color.HERO_QUALITY[arg_24_1:getColor()],
			text = xyd.Color2Level[arg_24_1:getColor()]
		}
		local var_24_5 = xyd.AssetLoader.get():loadLabel(var_24_4)

		var_24_5:addTo(var_24_0)
		var_24_5:align(display.CENTER_LEFT)
		var_24_5:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_24_3:x(var_24_3:getX() - 15)
	end

	var_24_0.data = arg_24_1
	var_24_0.id = arg_24_2

	var_24_0:setAnchorPoint(cc.p(0, 0))

	return var_24_0
end

function var_0_0.widgetSet(arg_25_0, arg_25_1)
	for iter_25_0, iter_25_1 in ipairs(arg_25_1:getChildren()) do
		if iter_25_1 ~= nil then
			iter_25_1:setCascadeOpacityEnabled(true)
			arg_25_0:widgetSet(iter_25_1)
		end
	end
end

function var_0_0.moveFadeOutAction(arg_26_0, arg_26_1, arg_26_2, arg_26_3, arg_26_4)
	arg_26_0:widgetSet(arg_26_3)
	arg_26_3:setCascadeOpacityEnabled(true)

	local var_26_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_26_1, arg_26_2)))

	arg_26_3:runActionOnce(var_26_0, true, arg_26_4)
end

function var_0_0.getTeamNo(arg_27_0, arg_27_1)
	for iter_27_0, iter_27_1 in ipairs(arg_27_0.select_) do
		if var_0_1:distance(arg_27_1.id) < var_0_1:distance(iter_27_1) then
			table.insert(arg_27_0.team_, iter_27_0, arg_27_1)
			table.insert(arg_27_0.select_, iter_27_0, arg_27_1.id)

			return iter_27_0
		end
	end

	table.insert(arg_27_0.team_, arg_27_1)
	table.insert(arg_27_0.select_, arg_27_1.id)

	return #arg_27_0.team_
end

function var_0_0.updateScore(arg_28_0)
	local var_28_0 = 0

	for iter_28_0, iter_28_1 in ipairs(arg_28_0.team_) do
		var_28_0 = var_28_0 + iter_28_1.data:getZhandouli()
	end

	arg_28_0:nodeByName("combat_effectiveness"):setString(var_28_0)

	arg_28_0.combatEffectiveness = var_28_0
end

function var_0_0.newAcademyHero(arg_29_0, arg_29_1)
	local var_29_0 = import("app.model.Hero").new()

	var_29_0:initUnCollected(arg_29_1)

	local var_29_1 = arg_29_0.selfPlayer:getHeroIgnoreAwaken(arg_29_1)

	if var_29_1 then
		var_29_0.star_ = var_29_1.star_
		var_29_0.awakeTwiceStage_ = var_29_1.awakeTwiceStage_
	end

	xyd.formatAcademyArenaHero(var_29_0)

	return var_29_0
end

function var_0_0.didOpen(arg_30_0, arg_30_1)
	arg_30_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
