local var_0_0 = class("TeamMemberListWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.job = arg_1_0.guild.job
	arg_1_0.member_list = arg_1_0.guild.members

	table.sort(arg_1_0.member_list, function(arg_2_0, arg_2_1)
		if arg_2_0.job == 1 then
			return true
		elseif arg_2_0.job == 2 and arg_2_1.job == 0 then
			return true
		elseif arg_2_0.job == 2 and arg_2_1.job == 1 then
			return false
		elseif arg_2_0.job == 0 and arg_2_1.job > 0 then
			return false
		elseif arg_2_0.lev > arg_2_1.lev then
			return true
		else
			return false
		end
	end)
end

function var_0_0.delegate(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	data = arg_3_0.member_list

	if cc.ui.UIListView.COUNT_TAG == arg_3_2 then
		return #data
	elseif cc.ui.UIListView.CELL_TAG == arg_3_2 then
		if arg_3_3 > #data then
			return nil
		end

		local var_3_0 = arg_3_0.listView_:dequeueItem()

		if not var_3_0 then
			var_3_0 = arg_3_0.listView_:newItem()
		else
			var_3_0:removeAllChildren(true)
		end

		local var_3_1 = data[arg_3_3]
		local var_3_2 = display.newNode()

		arg_3_0:initCell(var_3_2, var_3_1)

		local var_3_3 = display.newNode()

		var_3_3:addChild(var_3_2)
		var_3_2:setPosition(0, 0)
		var_3_3:setContentSize(725, 139)
		var_3_0:setItemSize(725, 145)
		var_3_0:addContent(var_3_3)

		return var_3_0
	end
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.startClick_ = true
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 20 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.startClick_ = false
	end
end

function var_0_0.willOpen(arg_5_0, arg_5_1)
	var_0_0.super:willOpen(arg_5_1)

	arg_5_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_5_0:nodeByName("list_container"):getWidth(), arg_5_0:nodeByName("list_container"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0:nodeByName("list_container")):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.listView_:setBounceable(true)
	arg_5_0.listView_:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0.listView_:reload()
	arg_5_0:init()
end

function var_0_0.init(arg_6_0)
	arg_6_0:nodeByName("title"):setString(var_0_2:translation("SHE_TUAN_TEXT_1"))
	arg_6_0:nodeByName("manage_team_words"):setString(var_0_2:translation("SHE_TUAN_TEXT_2"))
	arg_6_0:nodeByName("manage_btn"):setTouchEnabled(true)
	arg_6_0:nodeByName("manage_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("manage_btn"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_6_0.job == 0 then
				xyd.WindowManager.get():openWindow("manage_my_guild", {
					parent = arg_6_0
				})
			else
				xyd.WindowManager.get():openWindow("team_manage_menu", {
					parent = arg_6_0
				})
			end
		end
	end)

	if arg_6_0.job == 0 then
		arg_6_0:nodeByName("job_text"):setString(string.format(var_0_2:translation("PLAYER_INFO_JOB"), var_0_2:translation("TEAM_MEMBER")))
	elseif arg_6_0.job == 1 then
		arg_6_0:nodeByName("job_text"):setString(string.format(var_0_2:translation("PLAYER_INFO_JOB"), var_0_2:translation("TEAM_PRESIDENT")))
	else
		arg_6_0:nodeByName("job_text"):setString(string.format(var_0_2:translation("PLAYER_INFO_JOB"), var_0_2:translation("TEAM_VICE_PRESIDENT")))
	end

	arg_6_0:nodeByName("member_text"):setString(string.format(var_0_2:translation("TEAM_APPLY_BG_NUM_TEXT"), #arg_6_0.member_list, xyd.tables.misc.teamPeopleLimit))
end

function var_0_0.updateManageBtn(arg_8_0, arg_8_1)
	if arg_8_1 ~= nil then
		arg_8_0.job = arg_8_1
	end

	if arg_8_0.job == 0 then
		arg_8_0:nodeByName("manage_btn"):setVisible(false)
	else
		arg_8_0:nodeByName("manage_btn"):setVisible(true)
	end
end

function var_0_0.initCell(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/team_mannage_window/member_list_window/member_list_item.csb")
	local var_9_1 = var_9_0:getChildByName("container")
	local var_9_2 = var_9_1:getContentSize()
	local var_9_3 = ""
	local var_9_4 = ""

	var_9_0:setContentSize(var_9_2)
	arg_9_1:setContentSize(var_9_2)
	var_9_0:setName("layout")
	var_9_0:setPosition(cc.p(0, 0))
	arg_9_1:addChild(var_9_0)
	arg_9_1:setTouchSwallowEnabled(false)
	arg_9_1:setTouchEnabled(true)
	var_9_1:getChildByName("name_text"):setString(arg_9_2.name)

	if arg_9_2.conquer_lev and arg_9_2.conquer_lev > 0 then
		local var_9_5 = {
			x = -1.5,
			y = 2.5
		}

		xyd.setConquerLev(arg_9_2.conquer_lev, var_9_1:getChildByName("level_text"), var_9_1:getChildByName("level_bg"), var_9_5, false, 0.75, nil, arg_9_2.conquer_loop_id)
	else
		var_9_1:getChildByName("level_text"):setString(arg_9_2.lev)
	end

	if arg_9_2.job == 0 then
		var_9_1:getChildByName("possition_text"):setString(var_0_2:translation("TEAM_MEMBER"))
	elseif arg_9_2.job == 1 then
		var_9_1:getChildByName("possition_text"):setString(var_0_2:translation("TEAM_PRESIDENT"))
	else
		var_9_1:getChildByName("possition_text"):setString(var_0_2:translation("TEAM_VICE_PRESIDENT"))
	end

	var_9_1:getChildByName("region"):setString("S" .. xyd.getPlayerRegion(arg_9_2.player_id))
	xyd.setPlayerAvatar(var_9_1:getChildByName("icon_container"), {
		showLevel = false,
		avatar_id = arg_9_2.avatar_id,
		avatar_frame_id = arg_9_2.avatar_frame_id
	})

	local var_9_6 = display.newNode()

	var_9_6:setContentSize(var_9_1:getWidth(), var_9_1:getHeight())
	var_9_6:setTouchEnabled(true)
	var_9_6:setTouchSwallowEnabled(false)
	var_9_6:setAnchorPoint(cc.p(0, 0))
	var_9_6:setPosition(0, 0)
	var_9_1:addChild(var_9_6)
	var_9_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			var_9_1:setScale(0.9)

			return true
		elseif arg_10_0.name == "moved" then
			if arg_9_0.startClick_ == false then
				var_9_1:setScale(1)
			end

			return true
		elseif arg_10_0.name == "ended" then
			var_9_1:setScale(1)

			if arg_9_0.startClick_ == true then
				xyd.playButtonSound()
				xyd.WindowManager.get():openWindow("team_member_list_alert", {
					job = arg_9_2.job,
					pname = arg_9_2.name,
					lev = arg_9_2.lev,
					avatar_id = arg_9_2.avatar_id,
					avatar_frame_id = arg_9_2.avatar_frame_id,
					seven_huoyue = arg_9_2.seven_huoyue,
					last_time = arg_9_2.last_time,
					player_id = arg_9_2.player_id,
					conquer_lev = arg_9_2.conquer_lev,
					conquer_loop_id = arg_9_2.conquer_loop_id
				})
			end

			return true
		end
	end)
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)
	arg_11_0:addBlockLayer()
	arg_11_0:nodeByName("red_point"):setVisible(false)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_11_0):addEventListener(xyd.event.GUILD_APPLY_NOTICE, handler(arg_11_0, arg_11_0.updateGuildNotice))
	arg_11_0:updateGuildNotice()
	arg_11_0:nodeByName("close_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			local var_12_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_12_0, false)
			xyd.WindowManager.get():closeWindow(arg_11_0.name)
		end
	end)
end

function var_0_0.updateGuildNotice(arg_13_0, arg_13_1)
	arg_13_0.guild:loadAllApply(function(arg_14_0, arg_14_1)
		if arg_13_0 and not tolua.isnull(arg_13_0) then
			if arg_14_1 ~= nil and #arg_14_1 ~= 0 then
				if arg_13_0.job == 1 or arg_13_0.job == 2 then
					arg_13_0:nodeByName("red_point"):setVisible(true)
				end
			else
				arg_13_0:nodeByName("red_point"):setVisible(false)
			end
		end
	end)
end

function var_0_0.willClose(arg_15_0, arg_15_1)
	var_0_0.super:willClose(arg_15_1)
end

return var_0_0
