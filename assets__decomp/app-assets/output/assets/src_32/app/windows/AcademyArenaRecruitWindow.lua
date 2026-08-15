local var_0_0 = class("AcademyArenaRecruitWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.hero
local var_0_3 = xyd.tables.misc
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.academyArenaHero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.ACADEMY_ARENA)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_0:nodeByName("recruit_tag")
	local var_2_1 = arg_2_0:nodeByName("team_tag")
	local var_2_2 = arg_2_0:nodeByName("bg1")
	local var_2_3 = arg_2_0:nodeByName("bg2")

	var_2_3:setVisible(false)
	var_2_0:addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			var_2_0:setTouchEnabled(false)
			var_2_0:setBright(false)
			var_2_1:setTouchEnabled(true)
			var_2_1:setBright(true)
			var_2_2:setVisible(true)
			var_2_3:setVisible(false)
		end
	end)
	var_2_0:setTouchEnabled(false)
	var_2_0:setBright(false)
	arg_2_0:initRecruit()
	arg_2_0.model:getAllTeam(function()
		var_2_1:addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				var_2_0:setTouchEnabled(true)
				var_2_0:setBright(true)
				var_2_1:setTouchEnabled(false)
				var_2_1:setBright(false)
				var_2_2:setVisible(false)
				var_2_3:setVisible(true)
			end
		end)
		arg_2_0:initTeam()
	end)
end

function var_0_0.initRecruit(arg_6_0)
	arg_6_0:updateResource()
	arg_6_0:initHeros(var_0_5:getIds())

	local var_6_0 = arg_6_0:nodeByName("hero_list")
	local var_6_1 = var_6_0:getContentSize()

	arg_6_0.width1 = var_6_1.width
	arg_6_0.ListView1 = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_1.width, var_6_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_6_0)

	arg_6_0.ListView1:setDelegate(handler(arg_6_0, arg_6_0.delegate1))
	arg_6_0:initRightMenu()
	arg_6_0:updateView()
end

function var_0_0.initTeam(arg_7_0)
	local var_7_0 = arg_7_0:nodeByName("team_list")
	local var_7_1 = var_7_0:getContentSize()

	arg_7_0.width2 = var_7_1.width
	arg_7_0.ListView2 = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_7_1.width, var_7_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_7_0)

	arg_7_0.ListView2:setDelegate(handler(arg_7_0, arg_7_0.delegate2))
	arg_7_0:nodeByName("add_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("academy_arena_select_team", {
				teamId = -1
			})
		end
	end)
	arg_7_0:updateTeam()
end

function var_0_0.initHeros(arg_9_0, arg_9_1)
	arg_9_0.herosList = {}
	arg_9_0.herosList[xyd.DistanceType.ALL] = {}
	arg_9_0.herosList[xyd.DistanceType.QIANPAI] = {}
	arg_9_0.herosList[xyd.DistanceType.ZHONGPAI] = {}
	arg_9_0.herosList[xyd.DistanceType.HOUPAI] = {}

	for iter_9_0, iter_9_1 in pairs(arg_9_1) do
		local var_9_0 = var_0_2:distanceType(iter_9_1)

		if var_9_0 == xyd.DistanceType.QIANPAI then
			table.insert(arg_9_0.herosList[xyd.DistanceType.QIANPAI], iter_9_1)
		elseif var_9_0 == xyd.DistanceType.ZHONGPAI then
			table.insert(arg_9_0.herosList[xyd.DistanceType.ZHONGPAI], iter_9_1)
		elseif var_9_0 == xyd.DistanceType.HOUPAI then
			table.insert(arg_9_0.herosList[xyd.DistanceType.HOUPAI], iter_9_1)
		end

		table.insert(arg_9_0.herosList[xyd.DistanceType.ALL], iter_9_1)
	end
end

function var_0_0.delegate1(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = 5
	local var_10_1 = 180

	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return math.ceil(#arg_10_0.herosList[arg_10_0.nowType] / var_10_0)
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_2 = arg_10_0.ListView1:dequeueItem()

		if not var_10_2 then
			var_10_2 = arg_10_0.ListView1:newItem()
		else
			var_10_2:removeAllChildren()
		end

		local var_10_3 = display.newNode()

		for iter_10_0 = 1, var_10_0 do
			local var_10_4 = (arg_10_3 - 1) * var_10_0 + iter_10_0

			if var_10_4 > #arg_10_0.herosList[arg_10_0.nowType] then
				break
			end

			local var_10_5 = arg_10_0:initHeroCell(var_10_4)

			var_10_5:pos((iter_10_0 - (var_10_0 + 1) / 2) * 130 + arg_10_0.width1 / 2, var_10_1 / 2)
			var_10_5:addTo(var_10_3)
		end

		var_10_3:setContentSize(arg_10_0.width1, var_10_1)
		var_10_2:setItemSize(arg_10_0.width1, var_10_1)
		var_10_2:addContent(var_10_3)

		return var_10_2
	end
end

function var_0_0.delegate2(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = 130

	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return math.ceil(#arg_11_0.teams)
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_1 = arg_11_0.ListView2:dequeueItem()

		if not var_11_1 then
			var_11_1 = arg_11_0.ListView2:newItem()
		else
			var_11_1:removeAllChildren()
		end

		local var_11_2 = arg_11_0:initTeamContent(arg_11_3)

		var_11_2:setContentSize(arg_11_0.width2, var_11_0)
		var_11_1:setItemSize(arg_11_0.width2, var_11_0)
		var_11_1:addContent(var_11_2)

		return var_11_1
	end
end

function var_0_0.initTeamContent(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_0.teams[arg_12_1]
	local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/academy_arena/recruit/team_item.csb")

	var_12_1:getChildByName("combat_effectiveness"):setString(var_12_0.total_force)

	for iter_12_0, iter_12_1 in ipairs(var_12_0.table_ids) do
		local var_12_2 = arg_12_0.model.recruitHeros[tostring(iter_12_1)]
		local var_12_3 = var_12_1:getChildByName("hp" .. iter_12_0)

		var_12_3:setVisible(true)

		if var_12_2.health > 0 then
			var_12_3:getChildByName("hp_bar"):setPercent(math.max(var_12_2.hp, 1) / var_12_2.total_hp * 100)
		end

		xyd.setAvatarBorder(arg_12_0:newAcademyHero(iter_12_1), var_12_1:getChildByName("hero" .. iter_12_0))
	end

	var_12_1:getChildByName("operate_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			if var_12_0.map_id ~= arg_12_0.model.baseMapId then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_4:translation("ACADEMY_ARENA_ADJUST_TEAM_TIP")
				})

				return
			end

			xyd.WindowManager.get():openWindow("academy_arena_select_team", {
				teamId = var_12_0.team_id,
				preIds = var_12_0.table_ids
			})
		end
	end)

	return var_12_1
end

function var_0_0.updateTeam(arg_14_0)
	arg_14_0.teams = arg_14_0.model.teamInfo

	arg_14_0:nodeByName("team_num"):setString(string.format(var_0_4:translation("ACADEMY_ARENA_TEAM_NUM"), #arg_14_0.teams))
	arg_14_0.ListView2:reload()
end

function var_0_0.initHeroCell(arg_15_0, arg_15_1)
	local var_15_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/academy_arena/recruit/recruit_item.csb")

	var_15_0.data = arg_15_0.herosList[arg_15_0.nowType][arg_15_1]

	xyd.setAvatarBorder(arg_15_0:newAcademyHero(var_15_0.data), var_15_0:getChildByName("avatar"))

	local var_15_1 = var_15_0:getChildByName("bg_bottom")
	local var_15_2 = var_15_1:getChildByName("icon_summon_point")
	local var_15_3 = var_15_1:getChildByName("icon_agility_point")

	if arg_15_0.model.recruitHeros[tostring(var_15_0.data)] then
		var_15_2:setVisible(false)
		var_15_3:setVisible(false)
		var_15_0:getChildByName("mask"):setVisible(true)
	else
		local var_15_4 = var_0_5:commonCost(var_15_0.data)
		local var_15_5 = var_0_5:sxCost(var_15_0.data)
		local var_15_6 = var_15_2:getChildByName("summon_point")

		var_15_6:setString(var_15_4)

		if var_15_4 > arg_15_0.summonPoint then
			var_15_6:setColor(cc.c3b(255, 0, 0))
		end

		if var_15_5 > 0 then
			local var_15_7 = var_15_3:getChildByName("agility_point")

			var_15_7:setString(var_15_5)

			if var_15_5 > arg_15_0.sxPoint then
				var_15_7:setColor(cc.c3b(255, 0, 0))
			end
		else
			var_15_3:setVisible(false)
		end

		var_15_0:setTouchEnabled(true)
		var_15_0:setTouchSwallowEnabled(false)
		var_15_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
			if arg_16_0.name == "began" then
				arg_15_0.startClick_ = true
				arg_15_0.prevX_, arg_15_0.prevY_ = arg_16_0.x, arg_16_0.y

				var_15_0:setScale(0.9)

				return true
			elseif arg_16_0.name == "moved" then
				if math.abs(arg_16_0.y - arg_15_0.prevY_) > 20 or math.abs(arg_16_0.x - arg_15_0.prevX_) > 20 then
					arg_15_0.startClick_ = false

					var_15_0:setScale(1)
				end
			elseif arg_16_0.name == "ended" and arg_15_0.startClick_ then
				var_15_0:setScale(1)

				if var_15_4 > arg_15_0.summonPoint or var_15_5 > math.max(0, arg_15_0.sxPoint) then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_4:translation("ACADEMY_ARENA_RECRUIT_ABSENCE")
					})

					return
				end

				local var_16_0 = string.format(var_0_4:translation("ACADEMY_ARENA_RECRUIT_TIP"), var_0_2:name(var_15_0.data))

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_16_0, function()
					arg_15_0.model:recruit(var_15_0.data, function()
						arg_15_0:updateResource()
						var_15_2:setVisible(false)
						var_15_3:setVisible(false)
						var_15_0:getChildByName("mask"):setVisible(true)
						var_15_0:setTouchEnabled(false)

						local var_18_0 = xyd.WindowManager.get():getWindow("academy_arena")

						if var_18_0 then
							var_18_0:updateBottom()
						end
					end)
				end, nil, nil, arg_15_0.colorMode)
			end
		end)
	end

	return var_15_0
end

function var_0_0.newAcademyHero(arg_19_0, arg_19_1)
	local var_19_0 = var_0_1.new()

	var_19_0:initUnCollected(arg_19_1)

	local var_19_1 = arg_19_0.selfPlayer:getHeroIgnoreAwaken(arg_19_1)

	if var_19_1 then
		var_19_0.star_ = var_19_1.star_
		var_19_0.awakeTwiceStage_ = var_19_1.awakeTwiceStage_
	end

	xyd.formatAcademyArenaHero(var_19_0)

	return var_19_0
end

function var_0_0.initRightMenu(arg_20_0)
	arg_20_0.nowType = xyd.DistanceType.ALL
	arg_20_0.rightMenuButtons_ = {}

	table.insert(arg_20_0.rightMenuButtons_, arg_20_0:nodeByName("all_btn"))
	table.insert(arg_20_0.rightMenuButtons_, arg_20_0:nodeByName("qian_btn"))
	table.insert(arg_20_0.rightMenuButtons_, arg_20_0:nodeByName("zhong_btn"))
	table.insert(arg_20_0.rightMenuButtons_, arg_20_0:nodeByName("hou_btn"))

	for iter_20_0 = 1, #arg_20_0.rightMenuButtons_ do
		arg_20_0.rightMenuButtons_[iter_20_0]:addTouchEventListener(function(arg_21_0, arg_21_1)
			if arg_21_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				arg_20_0.nowType = iter_20_0

				arg_20_0:updateView()
			end
		end)
	end
end

function var_0_0.updateView(arg_22_0)
	for iter_22_0 = 1, #arg_22_0.rightMenuButtons_ do
		if iter_22_0 == arg_22_0.nowType then
			arg_22_0.rightMenuButtons_[iter_22_0]:setTouchEnabled(false)
			arg_22_0.rightMenuButtons_[iter_22_0]:setBright(false)
		else
			arg_22_0.rightMenuButtons_[iter_22_0]:setTouchEnabled(true)
			arg_22_0.rightMenuButtons_[iter_22_0]:setBright(true)
		end
	end

	arg_22_0.ListView1:reload()
end

function var_0_0.updateResource(arg_23_0)
	arg_23_0.summonPoint = arg_23_0.model.playerInfo.summon_point

	arg_23_0:nodeByName("summon_point"):setString(arg_23_0.summonPoint .. "/" .. var_0_3.academySpUpper)
	arg_23_0:nodeByName("agility_point"):setString(arg_23_0.model.playerInfo.agility_point)

	local var_23_0, var_23_1 = arg_23_0.model:getResourceInc()

	arg_23_0:nodeByName("agility_point_inc"):setString("(-" .. arg_23_0.model.playerInfo.sx_num .. ")")

	arg_23_0.sxPoint = arg_23_0.model.playerInfo.agility_point - arg_23_0.model.playerInfo.sx_num
end

function var_0_0.didOpen(arg_24_0, arg_24_1)
	arg_24_0:addBlockLayer()
end

return var_0_0
