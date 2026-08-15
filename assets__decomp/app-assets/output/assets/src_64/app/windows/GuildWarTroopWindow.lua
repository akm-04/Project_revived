local var_0_0 = class("GuildWarTroop", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.teams = {}
	arg_1_0.deleteIds = {}

	local var_1_0 = 0

	for iter_1_0, iter_1_1 in pairs(arg_1_0.guild.troopInfo) do
		var_1_0 = var_1_0 + 1
		arg_1_0.teams[var_1_0] = {}
		arg_1_0.teams[var_1_0].formation = iter_1_1.formation
		arg_1_0.teams[var_1_0].id = iter_1_0
		arg_1_0.teams[var_1_0].adjusted = false
		arg_1_0.teams[var_1_0].petId = iter_1_1.petId
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.teamList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("list"):getWidth(), arg_2_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.teamList:setBounceable(true)
	arg_2_0.teamList:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0:updateMain()

	arg_2_0.adjusted = false

	arg_2_0:layout()
end

function var_0_0.updateMain(arg_3_0)
	arg_3_0:sortTeamsByPower()
	arg_3_0.teamList:reload()

	if arg_3_0.originY then
		arg_3_0.teamList:scrollTo(0, arg_3_0.originY)
	end

	arg_3_0:nodeByName("team_num_text"):setString(string.format(var_0_1:translation("OWN_TROOP_NUM"), #arg_3_0.teams))

	local var_3_0 = {}

	for iter_3_0, iter_3_1 in pairs(arg_3_0.teams) do
		local var_3_1 = xyd.splitToNumber(iter_3_1.formation, "|")

		for iter_3_2, iter_3_3 in pairs(var_3_1) do
			var_3_0[iter_3_3] = 0
		end
	end

	for iter_3_4, iter_3_5 in pairs(arg_3_0.selfPlayer.heros_) do
		if iter_3_5:getLevel() >= arg_3_0.selfPlayer.lev - 15 and var_3_0[iter_3_5:getHeroID()] == nil then
			var_3_0[iter_3_5:getHeroID()] = 1
		end
	end

	arg_3_0.needHeroNum = 0

	for iter_3_6, iter_3_7 in pairs(var_3_0) do
		if iter_3_7 == 1 then
			arg_3_0.needHeroNum = arg_3_0.needHeroNum + 1
		end
	end

	arg_3_0:nodeByName("hero_num_text"):setString(string.format(var_0_1:translation("LEFT_HEROS_NUM"), arg_3_0.needHeroNum))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("addteam_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.needHeroNum == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("NO_HERO_TO_ADD")
				})
			else
				arg_4_0.adjusted = true

				local var_5_0 = {}
				local var_5_1 = {}
				local var_5_2 = {}
				local var_5_3 = {}

				for iter_5_0, iter_5_1 in pairs(arg_4_0.teams) do
					local var_5_4 = xyd.splitToNumber(iter_5_1.formation, "|")

					for iter_5_2, iter_5_3 in pairs(var_5_4) do
						table.insert(var_5_2, iter_5_3)
					end

					local var_5_5 = iter_5_1.petId or 0

					if var_5_5 ~= 0 then
						table.insert(var_5_3, var_5_5)
					end
				end

				params = {
					type = xyd.SelectTeamType.ADJUST_TROOP,
					selected = var_5_0,
					preHeros = var_5_1,
					busyHeros = var_5_2,
					busyPets = var_5_3
				}

				xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, params)
			end
		end
	end)
	arg_4_0:nodeByName("close_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_6_0 = arg_4_0:makeParams()

			if arg_4_0.adjusted == true and #var_6_0.team_ids > 0 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("SAVE_TROOP_ALERT"), function()
					arg_4_0.guild:guildWarAddTeam(var_6_0, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("SAVE_OK")
							})
						end

						xyd.WindowManager.get():closeWindow(arg_4_0)
					end)
				end, {
					lcallback = function()
						xyd.WindowManager.get():closeWindow(arg_4_0)
					end
				}, nil, arg_4_0.colorMode)
			else
				xyd.WindowManager.get():closeWindow(arg_4_0)
			end
		end
	end)
	arg_4_0:nodeByName("save_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_10_0 = arg_4_0:makeParams()

			if arg_4_0.adjusted == true and #var_10_0.team_ids > 0 then
				arg_4_0.guild:guildWarAddTeam(var_10_0, function(arg_11_0, arg_11_1)
					if arg_11_0 == xyd.error.OK then
						arg_4_0.teams = {}
						arg_4_0.deleteIds = {}

						local var_11_0 = 0

						for iter_11_0, iter_11_1 in pairs(arg_11_1.troop) do
							var_11_0 = var_11_0 + 1
							arg_4_0.teams[var_11_0] = {}
							arg_4_0.teams[var_11_0].formation = iter_11_1.formation
							arg_4_0.teams[var_11_0].id = iter_11_1.team_id
							arg_4_0.teams[var_11_0].adjusted = false
							arg_4_0.teams[var_11_0].petId = iter_11_1.pet_id
						end

						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("SAVE_OK")
						})

						arg_4_0.adjusted = false

						arg_4_0:updateMain()
					end
				end)
			end
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.UPDATE_GUILD_TROOP, function(arg_12_0)
		if arg_12_0.params.defenseHeroes then
			local var_12_0 = {}

			for iter_12_0 = 1, #arg_12_0.params.defenseHeroes do
				if #var_12_0 >= 5 then
					break
				elseif arg_12_0.params.defenseHeroes[iter_12_0] then
					table.insert(var_12_0, arg_12_0.params.defenseHeroes[iter_12_0]:getHeroID())
				end
			end

			local var_12_1 = ""

			for iter_12_1 = 1, #var_12_0 do
				if iter_12_1 ~= 1 then
					var_12_1 = var_12_1 .. "|"
				end

				var_12_1 = var_12_1 .. var_12_0[iter_12_1]
			end

			if arg_12_0.params.selectTeamId == nil then
				local var_12_2 = #arg_4_0.teams + 1

				arg_4_0.teams[var_12_2] = {}
				arg_4_0.teams[var_12_2].formation = var_12_1
				arg_4_0.teams[var_12_2].id = 0
				arg_4_0.teams[var_12_2].adjusted = true
				arg_4_0.teams[var_12_2].petId = arg_12_0.params.pet_id or 0
			else
				if arg_4_0.teams[arg_12_0.params.selectTeamId].formation ~= var_12_1 then
					arg_4_0.teams[arg_12_0.params.selectTeamId].adjusted = true
				elseif tonumber(arg_4_0.teams[arg_12_0.params.selectTeamId].petId) ~= arg_12_0.params.pet_id then
					arg_4_0.teams[arg_12_0.params.selectTeamId].adjusted = true
				end

				arg_4_0.teams[arg_12_0.params.selectTeamId].formation = var_12_1
				arg_4_0.teams[arg_12_0.params.selectTeamId].petId = arg_12_0.params.pet_id
			end

			arg_4_0:updateMain()
		end
	end)
	arg_4_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.delegate(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	data = arg_13_0.teams

	if cc.ui.UIListView.COUNT_TAG == arg_13_2 then
		return #data
	elseif cc.ui.UIListView.CELL_TAG == arg_13_2 then
		if arg_13_3 > #data then
			return nil
		end

		local var_13_0 = arg_13_0.teamList:dequeueItem()

		if not var_13_0 then
			var_13_0 = arg_13_0.teamList:newItem()
		else
			var_13_0:removeAllChildren(true)
		end

		local var_13_1 = display.newNode()

		arg_13_0:initCell(var_13_1, arg_13_3)

		local var_13_2 = display.newNode()

		var_13_2:addChild(var_13_1)
		var_13_1:setPosition(0, 0)
		var_13_2:setContentSize(arg_13_0:nodeByName("list"):getWidth(), 125)
		var_13_0:setItemSize(arg_13_0:nodeByName("list"):getWidth(), 125)
		var_13_0:addContent(var_13_2)

		return var_13_0
	end
end

function var_0_0.sortTeamsByPower(arg_14_0)
	if not arg_14_0.teamHeros then
		arg_14_0.teamHeros = {}
	end

	if not arg_14_0.teamPets then
		arg_14_0.teamPets = {}
		arg_14_0.teamPets[0] = 0
	end

	local var_14_0 = arg_14_0.teamHeros
	local var_14_1 = arg_14_0.teamPets

	local function var_14_2()
		table.sort(arg_14_0.teams, function(arg_16_0, arg_16_1)
			local var_16_0 = 0
			local var_16_1 = 0
			local var_16_2 = xyd.splitToNumber(arg_16_0.formation, "|")
			local var_16_3 = xyd.splitToNumber(arg_16_1.formation, "|")
			local var_16_4 = tonumber(arg_16_0.petId) or 0
			local var_16_5 = tonumber(arg_16_1.petId) or 0

			for iter_16_0, iter_16_1 in pairs(var_16_2) do
				var_16_0 = var_16_0 + var_14_0[iter_16_1] or 0
			end

			local var_16_6 = var_16_0 + var_14_1[var_16_4]

			for iter_16_2, iter_16_3 in pairs(var_16_3) do
				var_16_1 = var_16_1 + var_14_0[iter_16_3] or 0
			end

			local var_16_7

			var_16_7 = var_16_1 + var_14_1[var_16_5] or 0
			arg_16_0.power = var_16_6
			arg_16_1.power = var_16_7

			if #var_16_2 ~= #var_16_3 then
				return #var_16_2 < #var_16_3
			elseif arg_16_0.power ~= arg_16_1.power then
				return arg_16_0.power > arg_16_1.power
			end
		end)
	end

	local var_14_3 = false

	for iter_14_0, iter_14_1 in pairs(arg_14_0.teams) do
		local var_14_4 = ""

		for iter_14_2, iter_14_3 in pairs(xyd.splitToNumber(iter_14_1.formation, "|")) do
			local var_14_5 = 0

			if not arg_14_0.teamHeros[iter_14_3] then
				local var_14_6 = arg_14_0.selfPlayer:getHeroByID(iter_14_3)

				if var_14_6.level_ < arg_14_0.selfPlayer.lev - xyd.tables.misc.guildBattleLimit then
					var_14_3 = true
					var_14_5 = iter_14_2
					iter_14_1.adjusted = true
				else
					arg_14_0.teamHeros[iter_14_3] = var_14_6:getZhandouli()
				end
			end

			if iter_14_2 ~= var_14_5 then
				if var_14_4 == "" then
					var_14_4 = var_14_4 .. iter_14_3
				else
					var_14_4 = var_14_4 .. "|" .. iter_14_3
				end

				if not iter_14_1.power then
					iter_14_1.power = 0
				end

				if arg_14_0.teamHeros[iter_14_3] then
					iter_14_1.power = iter_14_1.power + arg_14_0.teamHeros[iter_14_3]
				end
			end
		end

		local var_14_7 = iter_14_1.petId or 0

		if iter_14_1.petId and iter_14_1.petId ~= 0 and not arg_14_0.teamPets[iter_14_1.petId] then
			local var_14_8 = arg_14_0.selfPlayer:getPetByID(iter_14_1.petId)

			if var_14_8.level_ < arg_14_0.selfPlayer.lev - xyd.tables.misc.guildBattleLimit then
				var_14_3 = true
				iter_14_1.adjusted = true
				var_14_7 = 0
			else
				var_14_7 = iter_14_1.petId
				arg_14_0.teamPets[var_14_7] = var_14_8:getZhandouli()
			end

			if not iter_14_1.power then
				iter_14_1.power = 0
			end

			if var_14_7 ~= 0 and arg_14_0.teamPets[iter_14_1.petId] then
				iter_14_1.power = iter_14_1.power + arg_14_0.teamPets[iter_14_1.petId]
			end
		end

		if var_14_4 == "" then
			if iter_14_1.id ~= 0 then
				table.insert(arg_14_0.deleteIds, iter_14_1.id)
			end

			table.remove(arg_14_0.teams, iter_14_0)
		else
			iter_14_1.formation = var_14_4
			iter_14_1.petId = var_14_7
		end
	end

	if var_14_3 then
		arg_14_0.guild:guildWarAddTeam(arg_14_0:makeParams(), function(arg_17_0, arg_17_1)
			if arg_17_0 == xyd.error.OK then
				var_14_2()

				arg_14_0.deleteIds = {}

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_1:translation("GUILD_WAR_LEVEL_UP_TAKE_HERO"), nil, nil, nil, arg_14_0.colorMode)
			end
		end)
	else
		var_14_2()
	end
end

function var_0_0.makeParams(arg_18_0)
	local var_18_0 = {
		formations = {},
		team_ids = {},
		forces = {},
		pet_ids = {}
	}

	for iter_18_0, iter_18_1 in pairs(arg_18_0.teams) do
		if iter_18_1.adjusted then
			table.insert(var_18_0.formations, iter_18_1.formation)
			table.insert(var_18_0.team_ids, iter_18_1.id)
			table.insert(var_18_0.forces, iter_18_1.power)
			table.insert(var_18_0.pet_ids, iter_18_1.petId)
		end
	end

	if #arg_18_0.deleteIds > 0 then
		for iter_18_2, iter_18_3 in pairs(arg_18_0.deleteIds) do
			table.insert(var_18_0.formations, "-1")
			table.insert(var_18_0.team_ids, iter_18_3)
			table.insert(var_18_0.forces, 0)
			table.insert(var_18_0.pet_ids, 0)
		end
	end

	return var_18_0
end

function var_0_0.initCell(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = xyd.splitToNumber(arg_19_0.teams[arg_19_2].formation, "|")
	local var_19_1 = arg_19_0.teams[arg_19_2].petId
	local var_19_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/guild_troop/troop_item.csb")
	local var_19_3 = var_19_2:getChildByName("container")
	local var_19_4 = var_19_3:getContentSize()
	local var_19_5 = 0

	for iter_19_0, iter_19_1 in pairs(var_19_0) do
		local var_19_6 = arg_19_0.selfPlayer:getHeroByID(iter_19_1)

		xyd.setAvatarBorder(var_19_6, var_19_3:getChildByName("icon_" .. iter_19_0), var_19_6:getColor(), var_19_6:getStar())

		var_19_5 = var_19_5 + var_19_6:getZhandouli()
	end

	if var_19_1 and var_19_1 ~= 0 then
		local var_19_7 = arg_19_0.selfPlayer:getPetByID(var_19_1)
		local var_19_8 = var_19_3:getChildByName("icon_pet")

		xyd.setPetAvatar(var_19_8, var_19_7, nil, true)
		var_19_8:setScale(0.8, 0.8)
		var_19_8:setPosition(var_19_8:getPositionX() + 10, var_19_8:getPositionY() + 10)

		var_19_5 = var_19_5 + var_19_7:getZhandouli()

		local var_19_9 = #var_19_0 + 1

		if var_19_9 <= 5 and var_19_9 >= 1 then
			var_19_3:getChildByName("icon_pet"):setPositionX(var_19_3:getChildByName("icon_" .. var_19_9):getPositionX() + 10)
		end
	end

	arg_19_0.teams[arg_19_2].power = var_19_5

	var_19_3:getChildByName("power_words"):setString(var_0_1:translation("HERO_INFO_ZHANDOULI"))
	var_19_3:getChildByName("power_text"):setString(var_19_5)
	var_19_2:setContentSize(var_19_4)
	arg_19_1:setContentSize(var_19_4)
	var_19_2:setName("layout")
	var_19_2:setPosition(cc.p(0, 0))
	arg_19_1:addChild(var_19_2)
	var_19_3:getChildByName("adjust_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended and arg_19_0.scrollViewMoved_ == false then
			xyd.playButtonSound()

			arg_19_0.adjusted = true

			local var_20_0 = {}
			local var_20_1 = {}
			local var_20_2 = var_19_0
			local var_20_3 = {}
			local var_20_4 = {}

			for iter_20_0, iter_20_1 in pairs(var_20_2) do
				table.insert(var_20_3, arg_19_0.selfPlayer:getHeroByID(iter_20_1))
			end

			if var_19_1 and var_19_1 ~= 0 then
				table.insert(var_20_4, arg_19_0.selfPlayer:getPetByID(var_19_1))
			end

			for iter_20_2, iter_20_3 in pairs(arg_19_0.teams) do
				if iter_20_2 ~= arg_19_2 then
					local var_20_5 = xyd.splitToNumber(iter_20_3.formation, "|")

					for iter_20_4, iter_20_5 in pairs(var_20_5) do
						table.insert(var_20_0, iter_20_5)
					end

					local var_20_6 = iter_20_3.petId or 0

					if var_20_6 ~= 0 then
						table.insert(var_20_1, var_20_6)
					end
				end
			end

			params = {
				type = xyd.SelectTeamType.ADJUST_TROOP,
				selected = var_20_2,
				preHeros = var_20_3,
				prePet = var_20_4,
				selectTeamId = arg_19_2,
				busyHeros = var_20_0,
				busyPets = var_20_1
			}

			xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, params)
		end
	end)
	var_19_3:getChildByName("dissolve_btn"):addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.ended and arg_19_0.scrollViewMoved_ == false then
			xyd.playButtonSound()

			arg_19_0.adjusted = true

			if arg_19_0.teams[arg_19_2].id ~= 0 then
				table.insert(arg_19_0.deleteIds, arg_19_0.teams[arg_19_2].id)
			end

			table.remove(arg_19_0.teams, arg_19_2)
			arg_19_0:updateMain()
		end
	end)
end

function var_0_0.scrollListener(arg_22_0, arg_22_1)
	if arg_22_1.name == "began" then
		arg_22_0.scrollViewMoved_ = false
		arg_22_0.prevY_ = arg_22_1.y
	elseif arg_22_1.name == "moved" and 10 <= math.abs(arg_22_1.y - arg_22_0.prevY_) then
		arg_22_0.scrollViewMoved_ = true
	end

	arg_22_0.originY = arg_22_0.teamList.scrollNode:getPositionY()
end

function var_0_0.willClose(arg_23_0, arg_23_1)
	var_0_0.super:willClose(arg_23_1)

	local var_23_0 = xyd.WindowManager.get():getWindow("guild_war_path")

	if var_23_0 then
		var_23_0:updateLeftList()
		var_23_0.leftListView:reload()
		var_23_0:updateRightList()
		var_23_0.rightListView:reload()
	end
end

return var_0_0
