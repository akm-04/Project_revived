local var_0_0 = class("GuildWarScheduleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.guildBattleTable
local var_0_4 = 0
local var_0_5 = 6
local var_0_6 = 1
local var_0_7 = 2
local var_0_8 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.arena = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)

	arg_1_0:setTouchSwallowEnabled(true)
end

function var_0_0.updateListData(arg_2_0)
	arg_2_0.listData = {}

	local var_2_0
	local var_2_1 = var_0_3:season(arg_2_0.guild.warStep)
	local var_2_2 = var_0_3:round(arg_2_0.guild.warStep)
	local var_2_3 = var_0_3:step(arg_2_0.guild.warStep)

	if var_2_1 <= 10 then
		var_2_0 = var_0_2:translation("NUM_" .. var_2_1)
	else
		var_2_0 = tostring(var_2_1)
	end

	arg_2_0:nodeByName("title_text"):setString(string.format(var_0_2:translation("SCHEDULE_TITLE"), var_2_0))

	local function var_2_4(arg_3_0, arg_3_1)
		local var_3_0 = {
			type = arg_3_0,
			id = arg_2_0.guild.warStep - var_2_3 + (arg_3_1 - var_2_2) * var_0_5 + arg_3_0
		}

		if var_2_3 == arg_3_0 then
			var_3_0.selected = true
			var_3_0.state = var_0_7
		elseif arg_3_0 > var_2_3 then
			var_3_0.selected = false
			var_3_0.state = var_0_6
		else
			var_3_0.selected = false
			var_3_0.state = var_0_8
		end

		table.insert(arg_2_0.listData, var_3_0)
	end

	for iter_2_0 = 1, xyd.tables.misc.guildBattleTurn do
		if iter_2_0 == var_2_2 then
			if arg_2_0.guild.isEnrollWar == 1 then
				local var_2_5 = {
					type = var_0_4,
					num = iter_2_0,
					id = arg_2_0.guild.warStep - var_2_3 + (iter_2_0 - var_2_2) * var_0_5 + 1
				}

				var_2_5.selected = false
				var_2_5.nobg = true

				table.insert(arg_2_0.listData, var_2_5)

				local var_2_6 = {
					type = xyd.GuildWarStep.ENROLL
				}

				var_2_6.lines = 1
				var_2_6.id = arg_2_0.guild.warStep - var_2_3 + (iter_2_0 - var_2_2) * var_0_5 + 1

				if var_2_3 == 1 then
					var_2_6.selected = true
				else
					var_2_6.selected = false
				end

				table.insert(arg_2_0.listData, var_2_6)
				var_2_4(xyd.GuildWarStep.MATCH, iter_2_0)
				var_2_4(xyd.GuildWarStep.PREPARE, iter_2_0)
				var_2_4(xyd.GuildWarStep.WALK, iter_2_0)
				var_2_4(xyd.GuildWarStep.FIGHT, iter_2_0)

				local var_2_7 = {
					type = xyd.GuildWarStep.ACCOUNT,
					id = arg_2_0.guild.warStep - var_2_3 + (iter_2_0 - var_2_2) * var_0_5 + 6
				}

				if var_2_3 == 6 then
					var_2_7.selected = true
				else
					var_2_7.selected = false
				end

				table.insert(arg_2_0.listData, var_2_7)
			elseif var_2_3 > 1 then
				local var_2_8 = {
					type = var_0_4,
					num = iter_2_0,
					id = arg_2_0.guild.warStep - var_2_3 + (iter_2_0 - var_2_2) * var_0_5 + 1
				}

				var_2_8.selected = true

				table.insert(arg_2_0.listData, var_2_8)
			else
				local var_2_9 = {
					type = var_0_4,
					num = iter_2_0,
					id = arg_2_0.guild.warStep - var_2_3 + (iter_2_0 - var_2_2) * var_0_5 + 1
				}

				var_2_9.selected = false
				var_2_9.nobg = true

				table.insert(arg_2_0.listData, var_2_9)

				local var_2_10 = {
					type = xyd.GuildWarStep.ENROLL
				}

				var_2_10.lines = 2
				var_2_10.id = arg_2_0.guild.warStep
				var_2_10.selected = true

				table.insert(arg_2_0.listData, var_2_10)
			end
		elseif iter_2_0 == var_2_2 + 1 and var_2_2 + 1 <= xyd.tables.misc.guildBattleTurn and arg_2_0.guild.isEnrollWar == 0 and var_2_3 > 1 then
			local var_2_11 = {
				type = var_0_4,
				num = iter_2_0,
				id = arg_2_0.guild.warStep - var_2_3 + (iter_2_0 - var_2_2) * var_0_5 + 1
			}

			var_2_11.selected = false
			var_2_11.nobg = true

			table.insert(arg_2_0.listData, var_2_11)

			local var_2_12 = {
				type = xyd.GuildWarStep.ENROLL
			}

			var_2_12.lines = 3
			var_2_12.id = arg_2_0.guild.warStep - var_2_3 + (iter_2_0 - var_2_2) * var_0_5 + 1
			var_2_12.selected = false

			table.insert(arg_2_0.listData, var_2_12)
		else
			local var_2_13 = {
				type = var_0_4,
				num = iter_2_0,
				id = arg_2_0.guild.warStep - var_2_3 + (iter_2_0 - var_2_2) * var_0_5 + 1
			}

			var_2_13.selected = false

			table.insert(arg_2_0.listData, var_2_13)
		end
	end
end

function var_0_0.updateList(arg_4_0)
	arg_4_0.timeStr = nil

	arg_4_0.listView:removeAllItems()

	local var_4_0 = 0
	local var_4_1 = 0

	for iter_4_0, iter_4_1 in pairs(arg_4_0.listData) do
		local var_4_2 = arg_4_0.listView:newItem()
		local var_4_3 = display.newNode()

		arg_4_0:initCell(var_4_3, iter_4_1)

		local var_4_4 = display.newNode()

		var_4_4:addChild(var_4_3)
		var_4_3:setPosition(0, 0)
		var_4_4:setContentSize(var_4_3:getContentSize())
		var_4_2:setItemSize(var_4_3:getContentSize().width, var_4_3:getContentSize().height)
		var_4_2:addContent(var_4_4)
		arg_4_0.listView:addItem(var_4_2)

		if iter_4_1.selected == true then
			var_4_1 = var_4_0
		end

		var_4_0 = var_4_0 + var_4_3:getContentSize().height
	end

	arg_4_0.listView:reload()
	arg_4_0.listView:scrollTo(0, -var_4_0 + var_4_1 + arg_4_0:nodeByName("list"):getHeight())
	arg_4_0.listView:scrollAuto()
end

function var_0_0.initCell(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0
	local var_5_1

	if arg_5_2.type == var_0_4 then
		if arg_5_0.guild.roundWinInfo[var_0_3:round(arg_5_2.id)] then
			var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/schedule/item_3.csb")
			var_5_1 = var_5_0:getChildByName("container")

			var_5_1:getChildByName("des_right"):setVisible(false)
			var_5_1:getChildByName("sign_in_container"):setVisible(false)

			local var_5_2 = ""

			if arg_5_0.guild.roundWinInfo[var_0_3:round(arg_5_2.id)].isWin == 0 then
				var_5_2 = var_0_2:translation("REGION_ARENA_TIP30")
			else
				var_5_2 = var_0_2:translation("REGION_ARENA_TIP29")
			end

			var_5_1:getChildByName("item_des1"):setString(string.format(var_0_2:translation("GUILD_SCHEDULE_TITLE"), var_0_2:translation("NUM_" .. var_0_3:round(arg_5_2.id)), var_5_2))
			var_5_1:getChildByName("item_des2"):setString(var_0_2:translation("GUILD_SCHEDULE_ENEMY"))

			local var_5_3 = arg_5_0.guild.roundWinInfo[var_0_3:round(arg_5_2.id)].name

			if not var_5_3 or var_5_3 == "" then
				var_5_3 = var_0_2:translation("GUILD_BATTLE_NAME")
			end

			var_5_1:getChildByName("item_des3"):setString(var_5_3)
		else
			var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/schedule/item_1.csb")
			var_5_1 = var_5_0:getChildByName("container")

			var_5_1:getChildByName("item_des1"):setString(string.format(var_0_2:translation("NUM_LUN"), var_0_2:translation("NUM_" .. var_0_3:round(arg_5_2.id))))
		end
	elseif arg_5_2.type == xyd.GuildWarStep.ENROLL then
		if arg_5_2.lines == 1 then
			var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/schedule/item_1.csb")
			var_5_1 = var_5_0:getChildByName("container")

			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("ENROLLED"))
		elseif arg_5_2.lines == 2 then
			var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/schedule/item_3.csb")
			var_5_1 = var_5_0:getChildByName("container")

			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("ENROLL"))

			arg_5_0.timeStr = var_5_1:getChildByName("item_des2")
			arg_5_0.tillTime = arg_5_0.guild.warEndTime

			var_5_1:getChildByName("item_des3"):setString("")
			arg_5_0:updateTimeStr()

			if arg_5_0.guild.job == 0 then
				var_5_1:getChildByName("des_right"):setVisible(true)
				var_5_1:getChildByName("sign_in_container"):setVisible(false)
				var_5_1:getChildByName("des_right"):setString(var_0_2:translation("GUILD_WAR_SIGN_DES"))
			else
				var_5_1:getChildByName("des_right"):setVisible(false)

				local var_5_4 = var_5_1:getChildByName("sign_in_container")

				var_5_4:setVisible(true)
				var_5_4:getChildByName("huoyue_words"):setString(xyd.tables.misc.guildBattleCost)
				var_5_4:getChildByName("cost_words"):setString(var_0_2:translation("ENROLL_NEED_COST"))

				if arg_5_0.guild.huoyue < xyd.tables.misc.guildBattleCost then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("CANT_ENROLL")
					})
				else
					var_5_4:getChildByName("sign_in_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
						if arg_6_1 == ccui.TouchEventType.ended then
							xyd.playButtonSound()
							arg_5_0.guild:guildWarEnroll(function(arg_7_0)
								if arg_7_0 == xyd.error.OK then
									arg_5_0:updateListData()
									arg_5_0:updateList()
								end
							end)
						end
					end)
				end
			end
		else
			var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/schedule/item_3.csb")
			var_5_1 = var_5_0:getChildByName("container")

			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("ENROLL"))
			var_5_1:getChildByName("item_des2"):setString(var_0_2:translation("TILL_ENROLL_TIME"))

			arg_5_0.timeStr = var_5_1:getChildByName("item_des3")
			arg_5_0.tillTime = arg_5_0.guild.warNextStartTime

			arg_5_0:updateTimeStr()
			var_5_1:getChildByName("sign_in_container"):setVisible(false)
			var_5_1:getChildByName("des_right"):setVisible(false)
		end
	elseif arg_5_2.type == xyd.GuildWarStep.MATCH then
		var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/schedule/item_2.csb")
		var_5_1 = var_5_0:getChildByName("container")

		var_5_1:getChildByName("des_right"):setVisible(false)

		if arg_5_2.state == var_0_6 then
			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_MATCH"))
			var_5_1:getChildByName("item_des2"):setVisible(false)
		elseif arg_5_2.state == var_0_7 then
			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_MATCHING"))

			arg_5_0.timeStr = var_5_1:getChildByName("item_des2")
			arg_5_0.tillTime = arg_5_0.guild.warEndTime

			arg_5_0:updateTimeStr()
		else
			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_MATCHED"))

			if arg_5_0.guild.warEnemy then
				var_5_1:getChildByName("item_des2"):setString(arg_5_0.guild.warEnemy.name)
			else
				var_5_1:getChildByName("item_des2"):setString("")
			end
		end
	elseif arg_5_2.type == xyd.GuildWarStep.PREPARE then
		var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/schedule/item_2.csb")
		var_5_1 = var_5_0:getChildByName("container")

		var_5_1:getChildByName("des_right"):setVisible(false)
		var_5_1:getChildByName("des_right"):setString(var_0_2:translation("SET_TEAM_PATH"))

		if arg_5_2.state == var_0_6 then
			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_PREPARE"))
			var_5_1:getChildByName("item_des2"):setVisible(false)
		elseif arg_5_2.state == var_0_7 then
			var_5_1:getChildByName("des_right"):setVisible(true)
			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_PREPARING"))

			arg_5_0.timeStr = var_5_1:getChildByName("item_des2")
			arg_5_0.tillTime = arg_5_0.guild.warEndTime

			arg_5_0:updateTimeStr()
		else
			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_PREPARED"))
			var_5_1:getChildByName("item_des2"):setVisible(false)
		end
	elseif arg_5_2.type == xyd.GuildWarStep.WALK then
		var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/schedule/item_2.csb")
		var_5_1 = var_5_0:getChildByName("container")

		var_5_1:getChildByName("des_right"):setVisible(false)
		var_5_1:getChildByName("des_right"):setString(var_0_2:translation("SET_TEAM_PATH"))

		if arg_5_2.state == var_0_6 then
			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_WALK"))
			var_5_1:getChildByName("item_des2"):setVisible(false)
		elseif arg_5_2.state == var_0_7 then
			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_WALKING"))

			arg_5_0.timeStr = var_5_1:getChildByName("item_des2")
			arg_5_0.tillTime = arg_5_0.guild.warEndTime

			arg_5_0:updateTimeStr()
		else
			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_WALKED"))
			var_5_1:getChildByName("item_des2"):setVisible(false)
		end
	elseif arg_5_2.type == xyd.GuildWarStep.FIGHT then
		var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/schedule/item_2.csb")
		var_5_1 = var_5_0:getChildByName("container")

		var_5_1:getChildByName("des_right"):setVisible(false)

		if arg_5_2.state == var_0_6 then
			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_FIGHT"))
			var_5_1:getChildByName("item_des2"):setVisible(false)
		elseif arg_5_2.state == var_0_7 then
			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_FIGHTING"))

			arg_5_0.timeStr = var_5_1:getChildByName("item_des2")
			arg_5_0.tillTime = arg_5_0.guild.warEndTime

			arg_5_0:updateTimeStr()
		else
			var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_FIGHTED"))
			var_5_1:getChildByName("item_des2"):setVisible(false)
		end
	elseif arg_5_2.type == xyd.GuildWarStep.ACCOUNT then
		var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/schedule/item_2.csb")
		var_5_1 = var_5_0:getChildByName("container")

		var_5_1:getChildByName("des_right"):setVisible(false)
		var_5_1:getChildByName("item_des2"):setVisible(false)
		var_5_1:getChildByName("item_des1"):setString(var_0_2:translation("STATE_ACCOUNT"))
	end

	local var_5_5 = var_5_1:getChildByName("time_container")

	var_5_5:getChildByName("date_text"):setString(string.format(var_0_2:translation("TEAM_DATA_DATE"), var_0_3:getStartMonth(arg_5_2.id), var_0_3:getStartDate(arg_5_2.id)))

	local var_5_6 = math.floor(var_0_3:getStartTime(arg_5_2.id) / 3600)
	local var_5_7 = math.floor(var_0_3:getStartTime(arg_5_2.id) % 3600 / 60)

	var_5_5:getChildByName("time_text"):setString(string.format("%02d:%02d", var_5_6, var_5_7))

	if arg_5_2.selected == false then
		var_5_1:getChildByName("select_bg"):setVisible(false)
		var_5_1:getChildByName("arrow_bg"):setVisible(false)
	else
		var_5_1:getChildByName("item_bg"):setVisible(false)
	end

	if arg_5_2.nobg then
		var_5_1:getChildByName("time_container"):setVisible(false)
		var_5_1:getChildByName("item_bg"):setVisible(false)
		var_5_1:getChildByName("select_bg"):setVisible(false)
		var_5_1:getChildByName("arrow_bg"):setVisible(false)
	end

	local var_5_8 = var_5_1:getContentSize()

	var_5_0:setContentSize(var_5_8)
	arg_5_1:setContentSize(var_5_8)
	var_5_0:setName("layout")
	var_5_0:setPosition(cc.p(0, 0))
	arg_5_1:addChild(var_5_0)
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.startClick_ = true
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" and 20 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
		arg_8_0.startClick_ = false
	end
end

function var_0_0.willOpen(arg_9_0, arg_9_1)
	var_0_0.super:willOpen(arg_9_1)

	arg_9_0.listView = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, arg_9_0:nodeByName("list"):getWidth(), arg_9_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_9_0:nodeByName("list")):onScroll(handler(arg_9_0, arg_9_0.scrollListener))

	arg_9_0.listView:setBounceable(true)
	arg_9_0:updateListData()
	arg_9_0:updateList()
	arg_9_0:addBlockLayer()
	arg_9_0:layout()
end

function var_0_0.didOpen(arg_10_0, arg_10_1)
	var_0_0.super:didOpen(arg_10_1)
end

function var_0_0.layout(arg_11_0)
	arg_11_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_12_0 = {}

			var_12_0.title_name = "GUILD_BATTLE_RULE_TITLE"
			var_12_0.rule = "GUILD_BATTLE_RULE"

			xyd.WindowManager.get():openWindow("text_rule", var_12_0)
		end
	end)
	arg_11_0:nodeByName("win_times_text"):setString(string.format(var_0_2:translation("GUILD_WAR_ROUND_WIN"), arg_11_0.guild.roundWinNum))

	if not arg_11_0.handle then
		arg_11_0.handle = var_0_1.scheduleGlobal(function()
			arg_11_0:updateTimeStr()
		end, 1)
	end
end

function var_0_0.updateTimeStr(arg_14_0)
	if not arg_14_0 or tolua.isnull(arg_14_0) then
		return
	end

	if arg_14_0.tillTime and arg_14_0.timeStr then
		local var_14_0 = arg_14_0.tillTime - xyd.ServerTime.get():getServerTime()
		local var_14_1 = math.floor((var_14_0 + 60) / xyd.OneDaySec)
		local var_14_2 = math.floor((var_14_0 + 60) % xyd.OneDaySec / 3600)
		local var_14_3 = math.floor((var_14_0 + 60) % 3600 / 60)

		if var_14_0 >= xyd.OneDaySec then
			arg_14_0.timeStr:setString(string.format(var_0_2:translation("ACTIVITY_LEFT_TIME"), var_14_1, var_14_2, var_14_3))
		else
			arg_14_0.timeStr:setString(string.format(var_0_2:translation("GUILD_WAR_LEFT_TIME"), var_14_2, var_14_3))
		end
	end
end

function var_0_0.willClose(arg_15_0, arg_15_1)
	var_0_0.super:willClose(arg_15_1)

	arg_15_0.timeStr = nil

	if arg_15_0.handle then
		var_0_1.unscheduleGlobal(arg_15_0.handle)
	end
end

return var_0_0
