local var_0_0 = class("GuildWarPathWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1
local var_0_3 = 2
local var_0_4 = 3
local var_0_5 = 4
local var_0_6 = 5
local var_0_7 = 11
local var_0_8 = 12

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.path = arg_1_2.path
	arg_1_0.isWalking = arg_1_2.isWalking
	arg_1_0.rightPath = 0
	arg_1_0.selectedSendTeam = {}
	arg_1_0.startClick_ = true
	arg_1_0.closeRight = true
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.updateRightList(arg_2_0)
	arg_2_0.rightlist = {}

	for iter_2_0 = 0, 3 do
		if iter_2_0 ~= arg_2_0.path then
			local var_2_0 = {
				type = var_0_7,
				path = iter_2_0
			}

			table.insert(arg_2_0.rightlist, var_2_0)
		end

		if iter_2_0 == arg_2_0.rightPath then
			for iter_2_1, iter_2_2 in pairs(arg_2_0.guild.troopInfo) do
				if iter_2_2.path == iter_2_0 then
					local var_2_1 = {
						type = var_0_8,
						formation = iter_2_2.formation,
						petId = iter_2_2.petId,
						teamId = iter_2_1
					}

					table.insert(arg_2_0.rightlist, var_2_1)
				end
			end
		end
	end
end

function var_0_0.updateLeftList(arg_3_0)
	arg_3_0.Leftlist = {}

	local var_3_0 = {
		type = var_0_2
	}

	table.insert(arg_3_0.Leftlist, var_3_0)

	arg_3_0.leftTeam = 0
	arg_3_0.pathTeamNum = {}
	arg_3_0.pathTeamNum[0] = 0
	arg_3_0.pathTeamNum[1] = 0
	arg_3_0.pathTeamNum[2] = 0
	arg_3_0.pathTeamNum[3] = 0

	for iter_3_0, iter_3_1 in pairs(arg_3_0.guild.troopInfo) do
		arg_3_0.pathTeamNum[iter_3_1.path] = arg_3_0.pathTeamNum[iter_3_1.path] + 1

		if iter_3_1.path == arg_3_0.path then
			local var_3_1 = {
				type = var_0_3,
				formation = iter_3_1.formation,
				petId = iter_3_1.petId,
				teamId = iter_3_0
			}

			table.insert(arg_3_0.Leftlist, var_3_1)
		elseif iter_3_1.path == 0 then
			arg_3_0.leftTeam = arg_3_0.leftTeam + 1
		end
	end

	if arg_3_0.isWalking == nil then
		local var_3_2 = {
			type = var_0_4
		}

		table.insert(arg_3_0.Leftlist, var_3_2)
	end

	local var_3_3 = {
		type = var_0_5
	}

	table.insert(arg_3_0.Leftlist, var_3_3)

	arg_3_0.allTeamNum = 0

	for iter_3_2, iter_3_3 in pairs(arg_3_0.guild.guildWarOtherPlayer) do
		arg_3_0.allTeamNum = arg_3_0.allTeamNum + iter_3_3.team_num

		local var_3_4 = {
			type = var_0_6,
			heroNum = iter_3_3.hero_num,
			avatar = iter_3_3.player_avatar,
			avatarFrame = iter_3_3.player_avatar_frame,
			lev = iter_3_3.player_lev,
			name = iter_3_3.player_name,
			teamNum = iter_3_3.team_num,
			conquer_lev = iter_3_3.player_conquer_lev,
			conquer_loop_id = iter_3_3.player_conquer_loop_id
		}

		table.insert(arg_3_0.Leftlist, var_3_4)
	end
end

function var_0_0.rightDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = arg_4_0.rightlist

	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #var_4_0
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		if arg_4_3 > #var_4_0 then
			return nil
		end

		local var_4_1 = arg_4_0.rightListView:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.rightListView:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = var_4_0[arg_4_3]
		local var_4_3 = display.newNode()

		arg_4_0:initCell(var_4_3, var_4_2)

		local var_4_4 = display.newNode()

		var_4_4:addChild(var_4_3)
		var_4_4:setContentSize(var_4_3:getContentSize())
		var_4_1:setItemSize(var_4_3:getContentSize().width, var_4_3:getContentSize().height)
		var_4_1:addContent(var_4_4)

		return var_4_1
	end
end

function var_0_0.leftDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = arg_5_0.Leftlist

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #var_5_0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		if arg_5_3 > #var_5_0 then
			return nil
		end

		local var_5_1 = arg_5_0.leftListView:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_0.leftListView:newItem()
		else
			var_5_1:removeAllChildren(true)
		end

		local var_5_2 = var_5_0[arg_5_3]
		local var_5_3 = display.newNode()

		arg_5_0:initCell(var_5_3, var_5_2)

		local var_5_4 = display.newNode()

		var_5_4:addChild(var_5_3)
		var_5_4:setContentSize(var_5_3:getContentSize())
		var_5_1:setItemSize(var_5_3:getContentSize().width, var_5_3:getContentSize().height)
		var_5_1:addContent(var_5_4)

		return var_5_1
	end
end

function var_0_0.initCell(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0
	local var_6_1

	if arg_6_2.type == var_0_2 then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/guild_path/fu_title.csb")
		var_6_1 = var_6_0:getChildByName("container")

		var_6_1:getChildByName("des_text"):setVisible(false)
		var_6_1:getChildByName("num_text"):setVisible(false)
		var_6_1:getChildByName("title_text"):setString(var_0_1:translation("MY_TEAM"))

		if arg_6_0.pathTeamNum[arg_6_0.path] == 0 then
			var_6_1:getChildByName("title_text"):setString(var_0_1:translation("NOT_SEND_TEAM_TO_PATH"))
		end
	elseif arg_6_2.type == var_0_3 then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/guild_path/team_item.csb")
		var_6_1 = var_6_0:getChildByName("container")

		local var_6_2 = {}
		local var_6_3 = xyd.splitToNumber(arg_6_2.formation, "|")

		for iter_6_0, iter_6_1 in pairs(var_6_3) do
			local var_6_4 = arg_6_0.selfPlayer:getHeroByID(iter_6_1)

			xyd.setAvatarBorder(var_6_4, var_6_1:getChildByName("icon_" .. iter_6_0), var_6_4:getColor(), var_6_4:getStar())
		end

		if arg_6_2.petId and arg_6_2.petId ~= 0 then
			local var_6_5 = arg_6_0.selfPlayer:getPetByID(arg_6_2.petId)
			local var_6_6 = var_6_1:getChildByName("icon_pet")

			xyd.setPetAvatar(var_6_6, var_6_5, nil, true)
			var_6_6:setScale(0.6, 0.6)

			local var_6_7 = #var_6_3 + 1

			if var_6_7 <= 5 and var_6_7 >= 1 then
				var_6_1:getChildByName("icon_pet"):setPositionX(var_6_1:getChildByName("icon_" .. var_6_7):getPositionX() + var_6_1:getChildByName("icon_" .. var_6_7):getWidth() / 2)
			end
		end

		if arg_6_0.isWalking then
			var_6_1:getChildByName("change_btn"):setVisible(false)
		end

		var_6_1:getChildByName("change_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended and arg_6_0.startClick_ == true then
				xyd.playButtonSound()
				arg_6_0:nodeByName("right_container"):setVisible(false)
				xyd.WindowManager.get():openWindow("guild_war_change_path", {
					path = arg_6_0.path,
					teamId = arg_6_2.teamId
				}):setPosition(var_6_1:getChildByName("change_btn"):getPositionX() + 170, arg_6_0.prevY_ - 140)
			end
		end)
	elseif arg_6_2.type == var_0_4 then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/guild_path/add_team_item.csb")
		var_6_1 = var_6_0:getChildByName("container")

		var_6_1:getChildByName("des_text"):setString(string.format(var_0_1:translation("LEFT_FREE_TEAM"), arg_6_0.leftTeam))
		var_6_1:getChildByName("add_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended and arg_6_0.startClick_ == true then
				xyd.playButtonSound()

				if arg_6_0.closeRight then
					arg_6_0:nodeByName("right_container"):setVisible(true)

					arg_6_0.closeRight = false
				else
					arg_6_0:nodeByName("right_container"):setVisible(false)

					arg_6_0.closeRight = true
				end
			end
		end)
	elseif arg_6_2.type == var_0_5 then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/guild_path/fu_title.csb")
		var_6_1 = var_6_0:getChildByName("container")

		var_6_1:getChildByName("title_text"):setVisible(false)
		var_6_1:getChildByName("des_text"):setString(var_0_1:translation("GUILD_MEMBER_TEAM"))
		var_6_1:getChildByName("num_text"):setString(string.format(var_0_1:translation("GUILD_MEMBER_TEAM_NUM"), arg_6_0.allTeamNum))
	elseif arg_6_2.type == var_0_6 then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/guild_path/player_item.csb")
		var_6_1 = var_6_0:getChildByName("container")

		if arg_6_2.conquer_lev and arg_6_2.conquer_lev > 0 then
			xyd.setConquerLev(arg_6_2.conquer_lev, var_6_1:getChildByName("lev_text"), var_6_1:getChildByName("lev_bg"), nil, false, 0.75, nil, arg_6_2.conquer_loop_id)
		else
			var_6_1:getChildByName("lev_text"):setString(arg_6_2.lev)
		end

		var_6_1:getChildByName("name_text"):setString(arg_6_2.name)
		var_6_1:getChildByName("des_text"):setString(string.format(var_0_1:translation("PLAYER_SEND_TEAM"), arg_6_2.teamNum, arg_6_2.heroNum))
		xyd.setAvatarClip(var_6_1:getChildByName("icon"), arg_6_2.avatar, 1)

		local var_6_8 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

		if arg_6_2.avatarFrame and arg_6_2.avatarFrame ~= 0 then
			var_6_8 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_6_2.avatarFrame] .. ".png"
		end

		local var_6_9 = xyd.AssetLoader.get():loadSprite(var_6_8)

		var_6_9:setPosition(40, 40)
		var_6_1:getChildByName("icon_border"):addChild(var_6_9)
	elseif arg_6_2.type == var_0_7 then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/guild_path/right_title_item.csb")
		var_6_1 = var_6_0:getChildByName("container")

		if arg_6_2.path == 0 then
			var_6_1:getChildByName("title_text"):setString(var_0_1:translation("FREE_TEAM"))
		else
			local var_6_10 = ""

			if arg_6_2.path == xyd.GuildWarPath.TOP then
				var_6_10 = var_0_1:translation("TOP_PATH")
			elseif arg_6_2.path == xyd.GuildWarPath.MID then
				var_6_10 = var_0_1:translation("MID_PATH")
			else
				var_6_10 = var_0_1:translation("BOTTOM_PATH")
			end

			var_6_1:getChildByName("title_text"):setString(string.format(var_0_1:translation("PREPARE_SEND_TEAM"), var_6_10))
			var_6_1:getChildByName("title_num"):setPositionX(var_6_1:getChildByName("title_num"):getPositionX() + 100)
		end

		var_6_1:getChildByName("title_num"):setString(string.format(var_0_1:translation("GUILD_MEMBER_TEAM_NUM"), arg_6_0.pathTeamNum[arg_6_2.path]))

		local var_6_11 = display.newNode()

		var_6_11:setContentSize(var_6_1:getChildByName("bg"):getWidth(), var_6_1:getChildByName("bg"):getHeight())
		var_6_11:setTouchEnabled(true)
		var_6_11:setTouchSwallowEnabled(false)
		var_6_11:setAnchorPoint(cc.p(0, 0))
		var_6_11:setPosition(var_6_1:getChildByName("bg"):getPositionX(), var_6_1:getChildByName("bg"):getPositionY())
		var_6_1:addChild(var_6_11)
		var_6_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			if arg_9_0.name == "began" then
				var_6_1:setScale(0.9)

				return true
			elseif arg_9_0.name == "moved" then
				if arg_6_0.startClick_ == false then
					var_6_1:setScale(1)
				end

				return true
			elseif arg_9_0.name == "ended" then
				var_6_1:setScale(1)

				if arg_6_0.startClick_ == true then
					xyd.playButtonSound()

					arg_6_0.rightPath = arg_6_2.path

					arg_6_0:updateRightList()
					arg_6_0.rightListView:reload()
				end

				return true
			end
		end)
	elseif arg_6_2.type == var_0_8 then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/guild_path/right_team_item.csb")
		var_6_1 = var_6_0:getChildByName("container")

		var_6_1:getChildByName("power_words"):setString(var_0_1:translation("HERO_INFO_ZHANDOULI"))

		local var_6_12 = {}
		local var_6_13 = 0
		local var_6_14 = xyd.splitToNumber(arg_6_2.formation, "|")

		for iter_6_2, iter_6_3 in pairs(var_6_14) do
			local var_6_15 = arg_6_0.selfPlayer:getHeroByID(iter_6_3)

			xyd.setAvatarBorder(var_6_15, var_6_1:getChildByName("icon_" .. iter_6_2), var_6_15:getColor(), var_6_15:getStar())

			var_6_13 = var_6_13 + var_6_15:getZhandouli()
		end

		if arg_6_2.petId and arg_6_2.petId ~= 0 then
			local var_6_16 = arg_6_0.selfPlayer:getPetByID(arg_6_2.petId)

			xyd.setAvatarBorder(var_6_16, var_6_1:getChildByName("icon_pet"))

			local var_6_17 = var_6_1:getChildByName("icon_pet")

			xyd.setPetAvatar(var_6_17, var_6_16, nil, true)
			var_6_17:setScale(0.6, 0.6)

			var_6_13 = var_6_13 + var_6_16:getZhandouli()

			local var_6_18 = #var_6_14 + 1

			if var_6_18 <= 5 and var_6_18 >= 1 then
				var_6_1:getChildByName("icon_pet"):setPositionX(var_6_1:getChildByName("icon_" .. var_6_18):getPositionX() + var_6_1:getChildByName("icon_" .. var_6_18):getWidth() / 2)
			end
		end

		var_6_1:getChildByName("power_text"):setString(var_6_13)

		if arg_6_0.selectedSendTeam[arg_6_2.teamId] then
			arg_6_0.selectedSendTeam[arg_6_2.teamId] = true

			var_6_1:getChildByName("select"):setVisible(true)
		else
			arg_6_0.selectedSendTeam[arg_6_2.teamId] = false

			var_6_1:getChildByName("select"):setVisible(false)
		end

		local var_6_19 = display.newNode()

		var_6_19:setContentSize(var_6_1:getChildByName("select_bg"):getWidth(), var_6_1:getChildByName("select_bg"):getHeight())
		var_6_19:setTouchEnabled(true)
		var_6_19:setTouchSwallowEnabled(false)
		var_6_19:setAnchorPoint(cc.p(0.5, 0.5))
		var_6_19:setPosition(var_6_1:getChildByName("select_bg"):getPositionX(), var_6_1:getChildByName("select_bg"):getPositionY())
		var_6_1:addChild(var_6_19)
		var_6_19:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
			if arg_10_0.name == "began" then
				return true
			elseif arg_10_0.name == "moved" then
				return true
			elseif arg_10_0.name == "ended" then
				if arg_6_0.startClick_ == true then
					xyd.playButtonSound()

					if arg_6_0.selectedSendTeam[arg_6_2.teamId] then
						arg_6_0.selectedSendTeam[arg_6_2.teamId] = false

						var_6_1:getChildByName("select"):setVisible(false)
					else
						arg_6_0.selectedSendTeam[arg_6_2.teamId] = true

						var_6_1:getChildByName("select"):setVisible(true)
					end
				end

				return true
			end
		end)
	end

	local var_6_20 = var_6_1:getContentSize()

	var_6_0:setContentSize(var_6_20)
	arg_6_1:setContentSize(var_6_20)
	var_6_0:setName("layout")
	var_6_0:setPosition(cc.p(0, 0))
	arg_6_1:addChild(var_6_0)
	arg_6_1:setTouchSwallowEnabled(false)
	arg_6_1:setTouchEnabled(true)
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.startClick_ = true
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" and 20 <= math.abs(arg_11_1.y - arg_11_0.prevY_) then
		arg_11_0.startClick_ = false
	end
end

function var_0_0.willOpen(arg_12_0, arg_12_1)
	var_0_0.super:willOpen(arg_12_1)
	arg_12_0:updateLeftList()
	arg_12_0:updateRightList()

	arg_12_0.leftListView = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_12_0:nodeByName("left_list"):getWidth(), arg_12_0:nodeByName("left_list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_12_0:nodeByName("left_list")):onScroll(handler(arg_12_0, arg_12_0.scrollListener))

	arg_12_0.leftListView:setBounceable(true)
	arg_12_0.leftListView:setDelegate(handler(arg_12_0, arg_12_0.leftDelegate))
	arg_12_0.leftListView:reload()

	arg_12_0.rightListView = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_12_0:nodeByName("right_list"):getWidth(), arg_12_0:nodeByName("right_list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_12_0:nodeByName("right_list")):onScroll(handler(arg_12_0, arg_12_0.scrollListener))

	arg_12_0.rightListView:setBounceable(true)
	arg_12_0.rightListView:setDelegate(handler(arg_12_0, arg_12_0.rightDelegate))
	arg_12_0.rightListView:reload()
	arg_12_0:addBlockLayer()
	arg_12_0:layout()
end

function var_0_0.didOpen(arg_13_0, arg_13_1)
	var_0_0.super:didOpen(arg_13_1)
end

function var_0_0.layout(arg_14_0)
	arg_14_0:nodeByName("right_container"):setVisible(false)
	arg_14_0:nodeByName("team_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("guild_war_troop")
		end
	end)
	arg_14_0:nodeByName("send_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_16_0 = {
				team_ids = {},
				path = arg_14_0.path
			}

			for iter_16_0, iter_16_1 in pairs(arg_14_0.selectedSendTeam) do
				if iter_16_1 == true then
					table.insert(var_16_0.team_ids, iter_16_0)
				end
			end

			arg_14_0.guild:guildWarChangePath(var_16_0, function(arg_17_0, arg_17_1)
				if arg_17_0 == xyd.error.OK then
					arg_14_0.selectedSendTeam = {}

					arg_14_0:updateLeftList()
					arg_14_0.leftListView:reload()
					arg_14_0:updateRightList()
					arg_14_0.rightListView:reload()
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("SEND_TEAM_NOT_EXIST")
					})
				end
			end)
		end
	end)

	if arg_14_0.path == xyd.GuildWarPath.TOP then
		arg_14_0:nodeByName("title_text"):setString(var_0_1:translation("TOP_PATH"))
	elseif arg_14_0.path == xyd.GuildWarPath.MID then
		arg_14_0:nodeByName("title_text"):setString(var_0_1:translation("MID_PATH"))
	else
		arg_14_0:nodeByName("title_text"):setString(var_0_1:translation("BOTTOM_PATH"))
	end
end

function var_0_0.willClose(arg_18_0, arg_18_1)
	var_0_0.super:willClose(arg_18_1)
end

return var_0_0
