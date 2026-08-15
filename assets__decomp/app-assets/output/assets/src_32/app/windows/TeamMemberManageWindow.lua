local var_0_0 = class("TeamMemberManageWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.parent = arg_1_2.parent
end

function var_0_0.delegate(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	data = arg_2_0.member_list

	if cc.ui.UIListView.COUNT_TAG == arg_2_2 then
		return #data
	elseif cc.ui.UIListView.CELL_TAG == arg_2_2 then
		if arg_2_3 > #data then
			return nil
		end

		local var_2_0 = arg_2_0.listView_:dequeueItem()

		if not var_2_0 then
			var_2_0 = arg_2_0.listView_:newItem()
		else
			var_2_0:removeAllChildren(true)
		end

		local var_2_1 = data[arg_2_3]
		local var_2_2 = display.newNode()

		arg_2_0:initCell(var_2_2, var_2_1)

		local var_2_3 = display.newNode()

		var_2_3:addChild(var_2_2)
		var_2_2:setPosition(0, 0)
		var_2_3:setContentSize(883, 153)
		var_2_0:setItemSize(883, 153)
		var_2_0:addContent(var_2_3)

		return var_2_0
	end
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.startClick_ = true
		arg_3_0.prevY_ = arg_3_1.y
	elseif arg_3_1.name == "moved" and 20 <= math.abs(arg_3_1.y - arg_3_0.prevY_) then
		arg_3_0.startClick_ = false
	end
end

function var_0_0.updateList(arg_4_0)
	arg_4_0:nodeByName("member_num_text"):setString(string.format(var_0_2:translation("TEAM_APPLY_BG_NUM_TEXT"), #arg_4_0.member_list, xyd.tables.misc.teamPeopleLimit))

	if arg_4_0.layerIndex == 1 then
		table.sort(arg_4_0.member_list, function(arg_5_0, arg_5_1)
			if arg_5_0.job == 1 then
				return true
			elseif arg_5_0.job == 2 and arg_5_1.job == 0 then
				return true
			elseif arg_5_0.job == arg_5_1.job then
				return arg_5_0.last_time > arg_5_1.last_time
			else
				return false
			end
		end)
	elseif arg_4_0.layerIndex == 2 then
		table.sort(arg_4_0.member_list, function(arg_6_0, arg_6_1)
			if arg_6_0.job == 1 then
				return true
			elseif arg_6_0.job == 2 and arg_6_1.job == 0 then
				return true
			elseif arg_6_0.job == arg_6_1.job then
				if arg_6_0.seven_huoyue > arg_6_1.seven_huoyue then
					return true
				elseif arg_6_0.seven_huoyue == arg_6_1.seven_huoyue then
					if arg_6_0.lev > arg_6_1.lev then
						return true
					else
						return false
					end
				else
					return false
				end
			else
				return false
			end
		end)
	else
		table.sort(arg_4_0.member_list, function(arg_7_0, arg_7_1)
			if arg_7_0.job == 1 then
				return true
			elseif arg_7_0.job == 2 and arg_7_1.job == 0 then
				return true
			elseif arg_7_0.job == arg_7_1.job then
				if arg_7_0.copy_challenge_times > arg_7_1.copy_challenge_times then
					return true
				elseif arg_7_0.copy_challenge_times == arg_7_1.copy_challenge_times then
					if arg_7_0.lev > arg_7_1.lev then
						return true
					else
						return false
					end
				else
					return false
				end
			else
				return false
			end
		end)
	end

	arg_4_0.listView_:reload()
end

function var_0_0.willOpen(arg_8_0, arg_8_1)
	var_0_0.super:willOpen(arg_8_1)

	arg_8_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_8_0:nodeByName("item_container"):getWidth(), arg_8_0:nodeByName("item_container"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_8_0:nodeByName("item_container")):onScroll(handler(arg_8_0, arg_8_0.scrollListener))

	arg_8_0.listView_:setBounceable(true)
	arg_8_0.listView_:setDelegate(handler(arg_8_0, arg_8_0.delegate))

	arg_8_0.layerIndex = 1

	arg_8_0:init()
end

function var_0_0.init(arg_9_0, arg_9_1)
	arg_9_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_9_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	if arg_9_1 == nil then
		arg_9_0.member_list = arg_9_0.guild.members

		arg_9_0:updateBtn()
		arg_9_0:nodeByName("time_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				arg_9_0.layerIndex = 1

				arg_9_0:updateBtn()
			end
		end)
		arg_9_0:nodeByName("active_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
			if arg_11_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				arg_9_0.layerIndex = 2

				arg_9_0:updateBtn()
			end
		end)
		arg_9_0:nodeByName("num_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
			if arg_12_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				arg_9_0.layerIndex = 3

				arg_9_0:updateBtn()
			end
		end)
		arg_9_0:updatejob()
	elseif arg_9_1 == 0 then
		arg_9_0:updateBtn()
		arg_9_0:updatejob()
	else
		arg_9_0.member_list = arg_9_1

		arg_9_0:updateBtn()
		arg_9_0:updatejob()
	end

	arg_9_0:nodeByName("title"):setString(var_0_2:translation("SHE_TUAN_TEXT_4"))
	arg_9_0:nodeByName("time_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_11"))
	arg_9_0:nodeByName("active_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_12"))
	arg_9_0:nodeByName("num_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_13"))
end

function var_0_0.updatejob(arg_13_0)
	for iter_13_0, iter_13_1 in pairs(arg_13_0.member_list) do
		if arg_13_0.player.playerID == iter_13_1.player_id then
			arg_13_0.job = iter_13_1.job

			break
		end
	end

	if arg_13_0.job == 0 then
		xyd.WindowManager.get():closeWindow(arg_13_0)
	end
end

function var_0_0.updateBtn(arg_14_0)
	if arg_14_0.layerIndex == 1 then
		arg_14_0:nodeByName("num_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_14_0:nodeByName("active_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_14_0:nodeByName("time_btn"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_14_0.layerIndex == 2 then
		arg_14_0:nodeByName("num_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_14_0:nodeByName("active_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_14_0:nodeByName("time_btn"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_14_0.layerIndex == 3 then
		arg_14_0:nodeByName("num_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_14_0:nodeByName("active_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_14_0:nodeByName("time_btn"):setBrightStyle(ccui.BrightStyle.normal)
	end

	arg_14_0:updateList()
end

function var_0_0.initCell(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/team_mannage_window/manage_member_item.csb")
	local var_15_1 = var_15_0:getChildByName("container")
	local var_15_2 = var_15_1:getContentSize()
	local var_15_3 = ""
	local var_15_4 = ""

	var_15_0:setContentSize(var_15_2)
	arg_15_1:setContentSize(var_15_2)
	var_15_0:setName("layout")
	var_15_0:setPosition(cc.p(0, 0))
	arg_15_1:addChild(var_15_0)
	arg_15_1:setTouchSwallowEnabled(false)
	arg_15_1:setTouchEnabled(true)
	var_15_1:getChildByName("name_text"):setString(arg_15_2.name)
	var_15_1:getChildByName("level_text"):setString(arg_15_2.lev)

	if arg_15_0.layerIndex == 1 then
		var_15_3 = var_0_2:translation("TEAM_MEMBER_LAST_ENTER_TIME")

		local var_15_5 = xyd.ServerTime.get():getServerTime()
		local var_15_6 = os.date("%M", var_15_5)
		local var_15_7 = os.date("%H", var_15_5)
		local var_15_8 = os.date("%S", var_15_5)
		local var_15_9 = var_15_5 - var_15_6 * 60 - var_15_7 * 3600 - var_15_8
		local var_15_10 = os.date("%M", arg_15_2.last_time)
		local var_15_11 = os.date("%H", arg_15_2.last_time)
		local var_15_12 = os.date("%S", arg_15_2.last_time)
		local var_15_13 = var_15_9 - arg_15_2.last_time

		if var_15_13 <= 0 then
			var_15_4 = var_0_2:translation("TODAY") .. var_15_11 .. ":" .. var_15_10
		elseif var_15_13 <= 86400 then
			var_15_4 = var_0_2:translation("YESTERDAY") .. var_15_11 .. ":" .. var_15_10
		elseif var_15_13 <= 172800 then
			var_15_4 = var_0_2:translation("THE_DAY_BEFORE_YESTERDAY") .. var_15_11 .. ":" .. var_15_10
		else
			var_15_4 = string.format(var_0_2:translation("TEAM_MEMBER_N_DAYS_NOT_ONLINE"), math.ceil(var_15_13 / 86400))
		end
	elseif arg_15_0.layerIndex == 2 then
		var_15_3 = var_0_2:translation("TEAM_MEMBER_SEVEN_DAYS_ACTIVE")
		var_15_4 = arg_15_2.seven_huoyue
	else
		var_15_3 = var_0_2:translation("TEAM_MEMBER_ACTIVE_TIMES")
		var_15_4 = arg_15_2.copy_challenge_times
	end

	var_15_1:getChildByName("time_text"):setString(var_15_4)
	var_15_1:getChildByName("time_words"):setString(var_15_3)

	if arg_15_2.job == 0 then
		var_15_1:getChildByName("possition_text"):setString(var_0_2:translation("TEAM_MEMBER"))
	elseif arg_15_2.job == 1 then
		var_15_1:getChildByName("possition_text"):setString(var_0_2:translation("TEAM_PRESIDENT"))
	else
		var_15_1:getChildByName("possition_text"):setString(var_0_2:translation("TEAM_VICE_PRESIDENT"))
	end

	var_15_1:getChildByName("region"):setString("S" .. xyd.getPlayerRegion(arg_15_2.player_id))
	xyd.setPlayerAvatar(var_15_1:getChildByName("icon_container"), {
		showLevel = false,
		avatar_id = arg_15_2.avatar_id,
		avatar_frame_id = arg_15_2.avatar_frame_id
	})

	if arg_15_2.conquer_lev and arg_15_2.conquer_lev > 0 then
		local var_15_14 = {
			x = -1.5,
			y = 2.5
		}

		xyd.setConquerLev(arg_15_2.conquer_lev, var_15_1:getChildByName("level_text"), var_15_1:getChildByName("level_bg"), var_15_14, false, 0.75, nil, arg_15_2.conquer_loop_id)
	else
		var_15_1:getChildByName("level_text"):setString(arg_15_2.lev)
	end

	local var_15_15 = display.newNode()

	var_15_15:setContentSize(var_15_1:getWidth(), var_15_1:getHeight())
	var_15_15:setTouchEnabled(true)
	var_15_15:setTouchSwallowEnabled(false)
	var_15_15:setAnchorPoint(cc.p(0, 0))
	var_15_15:setPosition(0, 0)
	var_15_1:addChild(var_15_15)
	var_15_15:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			var_15_1:setScale(0.9)

			return true
		elseif arg_16_0.name == "moved" then
			if arg_15_0.startClick_ == false then
				var_15_1:setScale(1)
			end

			return true
		elseif arg_16_0.name == "ended" then
			var_15_1:setScale(1)

			local var_16_0 = true

			if arg_15_0.job == 1 and arg_15_2.job == 1 then
				var_16_0 = false
			end

			if arg_15_0.job == 2 then
				var_16_0 = false

				if arg_15_2.job == 0 then
					var_16_0 = true
				end
			end

			if var_16_0 == true and arg_15_0.startClick_ == true then
				xyd.playButtonSound()
				xyd.WindowManager.get():openWindow("team_member_manage_menu", {
					job = arg_15_0.job,
					parent = arg_15_0,
					memberId = arg_15_2.player_id,
					memberJob = arg_15_2.job,
					selfName = arg_15_2.name,
					window_layer = arg_15_0.windowLayer
				})
			end

			return true
		end
	end)
end

function var_0_0.didOpen(arg_17_0, arg_17_1)
	var_0_0.super:didOpen(arg_17_1)
	arg_17_0:addBlockLayer()
	arg_17_0:nodeByName("close_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended then
			local var_18_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_18_0, false)
			xyd.WindowManager.get():closeWindow(arg_17_0)
		end
	end)
end

return var_0_0
