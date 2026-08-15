local var_0_0 = class("TeamApplyMemberWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)
end

function var_0_0.delegate(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	data = arg_2_0.apply_list

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
		var_2_2:setPosition(10, 0)
		var_2_3:setContentSize(725, 140)
		var_2_0:setItemSize(725, 145)
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

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super:willOpen(arg_4_1)

	arg_4_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("list_container"):getWidth(), arg_4_0:nodeByName("list_container"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list_container")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.listView_:setBounceable(true)

	arg_4_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_4_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_4_0.apply_list = arg_4_0.guild.apply_players

	arg_4_0.listView_:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0:init()
	arg_4_0:nodeByName("title"):setString(var_0_2:translation("SHE_TUAN_TEXT_3"))
end

function var_0_0.init(arg_5_0)
	arg_5_0:updateApplyList()

	arg_5_0.memberNum = arg_5_0.guild.member_nums

	arg_5_0:nodeByName("member_num_text"):setString(string.format(var_0_2:translation("TEAM_APPLY_BG_NUM_TEXT"), arg_5_0.memberNum, xyd.tables.misc.teamPeopleLimit))
end

function var_0_0.updateApplyList(arg_6_0)
	if arg_6_0.apply_list == nil or #arg_6_0.apply_list == 0 then
		arg_6_0:nodeByName("no_apply_text"):setString(var_0_2:translation("TEAM_APPLY_IS_NONE"))
	end

	arg_6_0.listView_:reload()
end

function var_0_0.initCell(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/team_mannage_window/manage_apply_iteam.csb")
	local var_7_1 = var_7_0:getChildByName("container")
	local var_7_2 = var_7_1:getContentSize()

	var_7_0:setContentSize(var_7_2)
	arg_7_1:setContentSize(var_7_2)
	var_7_0:setName("layout")
	var_7_0:setPosition(cc.p(0, 0))
	arg_7_1:addChild(var_7_0)
	arg_7_1:setTouchSwallowEnabled(false)
	arg_7_1:setTouchEnabled(true)
	var_7_1:getChildByName("name_text"):setString(arg_7_2.name)
	var_7_1:getChildByName("level_text"):setString(arg_7_2.lev)
	xyd.setPlayerAvatar(var_7_1:getChildByName("icon_container"), {
		showLevel = false,
		avatar_id = arg_7_2.avatar_id,
		avatar_id = arg_7_2.avatar_frame_id
	})

	local var_7_3 = arg_7_2.player_id

	var_7_1:getChildByName("region"):setString("S" .. xyd.getPlayerRegion(arg_7_2.player_id))

	if arg_7_2.conquer_lev and arg_7_2.conquer_lev > 0 then
		local var_7_4 = {
			x = -1.5,
			y = 2.5
		}

		xyd.setConquerLev(arg_7_2.conquer_lev, var_7_1:getChildByName("level_text"), var_7_1:getChildByName("level_bg"), var_7_4, false, 0.75, nil, arg_7_2.conquer_loop_id)
	else
		var_7_1:getChildByName("level_text"):setString(arg_7_2.lev)
	end

	var_7_1:getChildByName("agree_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(var_7_1:getChildByName("agree_btn"), arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended and arg_7_0.startClick_ then
			xyd.playButtonSound()

			local var_8_0 = {
				apply_player_id = var_7_3
			}

			arg_7_0.guild:acceptApply(var_8_0, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					arg_7_0.memberNum = arg_7_0.memberNum + 1

					arg_7_0:nodeByName("member_num_text"):setString(string.format(var_0_2:translation("TEAM_APPLY_BG_NUM_TEXT"), arg_7_0.memberNum, xyd.tables.misc.teamPeopleLimit))

					arg_7_0.apply_list = arg_9_1

					arg_7_0:updateApplyList()

					return true
				end
			end)
		end

		return true
	end)
	var_7_1:getChildByName("refuse_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(var_7_1:getChildByName("refuse_btn"), arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended and arg_7_0.startClick_ then
			xyd.playButtonSound()

			local var_10_0 = {
				apply_player_id = var_7_3
			}

			arg_7_0.guild:refuseApply(var_10_0, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					arg_7_0.apply_list = arg_11_1

					arg_7_0:updateApplyList()

					return true
				end
			end)
		end

		return true
	end)
end

function var_0_0.didOpen(arg_12_0, arg_12_1)
	arg_12_0:addBlockLayer()
	var_0_0.super:didOpen(arg_12_1)
	arg_12_0:nodeByName("close_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			local var_13_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_13_0, false)
			xyd.WindowManager.get():closeWindow(arg_12_0)
		end
	end)
end

return var_0_0
