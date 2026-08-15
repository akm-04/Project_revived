local var_0_0 = class("ApplyQueueWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.chapterID = arg_1_2.chapter_id
	arg_1_0.rewardInfo = arg_1_2.rewardInfo
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevX_ = arg_2_1.x
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" then
		local var_2_0 = 20

		if var_2_0 <= math.abs(arg_2_1.x - arg_2_0.prevX_) or var_2_0 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
			arg_2_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 732, 386),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list"))

	arg_3_0:nodeByName("noone_apply_txt"):setString(var_0_1:translation("NO_ONE_APPLY"))
	arg_3_0:nodeByName("wait_apply_txt"):setString(var_0_1:translation("WAIT_FOR_APPLY"))
	arg_3_0:nodeByName("auto_apply_txt"):setString(var_0_1:translation("AUTO_APPLY_DESC"))
	arg_3_0:layout()
end

function var_0_0.willClose(arg_4_0, arg_4_1)
	var_0_0.super:willClose(arg_4_1)

	local var_4_0 = xyd.WindowManager.get():getWindow("apply_reward")

	if var_4_0 then
		var_4_0:layout()
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0.list:removeAllItems()
	arg_5_0:nodeByName("apply_queue_title"):setString(var_0_1:translation("SHE_TUAN_TEXT_58"))

	local var_5_0 = arg_5_0.rewardInfo.apply_member

	if #var_5_0 <= 0 then
		arg_5_0:nodeByName("noone_apply_txt"):setVisible(true)
	else
		arg_5_0:nodeByName("noone_apply_txt"):setVisible(false)
	end

	for iter_5_0 = 1, #var_5_0 do
		local var_5_1 = display.newNode()
		local var_5_2 = arg_5_0.list:newItem()
		local var_5_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/apply_reward/apply_queue_item.csb")
		local var_5_4 = var_5_3:getChildByName("container")
		local var_5_5 = var_5_0[iter_5_0].rank
		local var_5_6, var_5_7 = var_5_4:getChildByName("rank_pos"):getPosition()

		arg_5_0:setRankLabel(var_5_5, var_5_6, var_5_7, var_5_4)

		local var_5_8 = {
			avatar_id = var_5_0[iter_5_0].avatar_id,
			avatar_frame_id = var_5_0[iter_5_0].avatar_frame_id
		}

		xyd.setPlayerAvatar(var_5_4:getChildByName("avatar"), var_5_8)
		var_5_4:getChildByName("name_txt"):setString(var_5_0[iter_5_0].player_name)

		local var_5_9 = var_5_4:getChildByName("lev")

		if var_5_0[iter_5_0].conquer_lev and var_5_0[iter_5_0].conquer_lev > 0 then
			xyd.setConquerLev(var_5_0[iter_5_0].conquer_lev, var_5_9, var_5_4:getChildByName("dengjiquan"), nil, nil, nil, nil, var_5_0[iter_5_0].conquer_loop_id)
		else
			var_5_9:setString(var_5_0[iter_5_0].lev)
		end

		var_5_4:getChildByName("region"):setString("S" .. xyd.getPlayerRegion(var_5_0[iter_5_0].player_id))
		var_5_3:setContentSize(720, 132)
		var_5_1:addChild(var_5_3)
		var_5_1:setContentSize(720, 132)
		var_5_2:addContent(var_5_1)
		var_5_2:setItemSize(720, 132)
		arg_5_0.list:addItem(var_5_2)
	end

	arg_5_0.list:reload()
	arg_5_0:initSelfApplyInfo()
end

function var_0_0.initSelfApplyInfo(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("item")

	xyd.setItemBorder(var_6_0, arg_6_0.rewardInfo.award_id)

	local var_6_1 = arg_6_0:nodeByName("apply_btn")

	arg_6_0:setApplyBtnState(arg_6_0.rewardInfo, var_6_1)
	arg_6_0:nodeByName("item_num"):setString(tostring(arg_6_0.rewardInfo.award_num) .. var_0_1:translation("GE"))

	local var_6_2 = string.format(var_0_1:translation("NOW_GUILD_APPLY_RANK"), arg_6_0.rewardInfo.self_rank)

	arg_6_0:nodeByName("apply_rank_txt"):setString(var_6_2)
	arg_6_0:createTimeLabel(arg_6_0.guild:getNextApplyTime())
	var_6_1:getChildByName("have_apply_txt"):setString(var_0_1:translation("SHE_TUAN_TEXT_56"))
	var_6_1:getChildByName("has_not_apply_txt"):setString(var_0_1:translation("SHE_TUAN_TEXT_57"))
	var_6_1:addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(var_6_1, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = arg_6_0.guild:getSelfAppliedInfo()

			if var_7_0 and var_7_0.item_id then
				local function var_7_1()
					local var_8_0 = {
						chapter_id = arg_6_0.chapterID,
						award_id = arg_6_0.rewardInfo.award_id
					}

					arg_6_0.guild:applyReward(var_8_0, function(arg_9_0, arg_9_1)
						if arg_9_0 == xyd.error.OK then
							local var_9_0 = arg_6_0.guild:getChapterRewardList()

							arg_6_0.rewardInfo = var_9_0[arg_6_0.rewardInfo.award_id]

							arg_6_0:layout()
						end
					end)
				end

				local function var_7_2()
					arg_6_0:setApplyBtnState(arg_6_0.rewardInfo, var_6_1)
				end

				local var_7_3 = {
					oldItemID = var_7_0.item_id,
					newItemID = arg_6_0.rewardInfo.award_id,
					rank = var_7_0.rank,
					type = arg_6_0.rewardInfo.self_apply,
					callback1 = var_7_1,
					callback2 = var_7_2
				}

				xyd.WindowManager.get():openWindow("apply_confirm", var_7_3)
			else
				local var_7_4 = {
					chapter_id = arg_6_0.chapterID,
					award_id = arg_6_0.rewardInfo.award_id
				}

				arg_6_0.guild:applyReward(var_7_4, function(arg_11_0, arg_11_1)
					if arg_11_0 == xyd.error.OK then
						local var_11_0 = arg_6_0.guild:getChapterRewardList()

						arg_6_0.rewardInfo = var_11_0[arg_6_0.rewardInfo.award_id]

						arg_6_0:layout()
					end
				end)
			end
		end
	end)

	if arg_6_0.rewardInfo.award_num == 0 then
		arg_6_0:nodeByName("time_label"):setVisible(false)
		arg_6_0:nodeByName("auto_apply_txt"):setVisible(false)

		if arg_6_0.rewardInfo.self_rank > 0 then
			arg_6_0:nodeByName("apply_rank_txt"):setVisible(true)
		else
			arg_6_0:nodeByName("apply_rank_txt"):setVisible(false)
		end
	elseif arg_6_0.rewardInfo.self_rank > 0 then
		arg_6_0:nodeByName("apply_rank_txt"):setVisible(true)
	else
		arg_6_0:nodeByName("apply_rank_txt"):setVisible(false)
	end
end

function var_0_0.createTimeLabel(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_0:nodeByName("time_label")

	if arg_12_1 <= 0 then
		return
	else
		if arg_12_1 < 3600 then
			var_12_0:setString(math.floor(arg_12_1 / 60) .. var_0_1:translation("UNIT_MINUTE"))
		elseif arg_12_1 >= 3600 and arg_12_1 < 86400 then
			local var_12_1 = math.floor(arg_12_1 / 3600)
			local var_12_2 = math.floor(arg_12_1 % 3600 / 60)
			local var_12_3 = var_12_1 .. var_0_1:translation("UNIT_HOUR")

			if var_12_2 ~= 0 then
				var_12_3 = var_12_3 .. var_12_2 .. var_0_1:translation("UNIT_MINUTE")
			end

			var_12_0:setString(var_12_3)
		else
			local var_12_4 = math.floor(arg_12_1 / 86400)
			local var_12_5 = math.floor(arg_12_1 % 86400 / 3600)
			local var_12_6 = math.floor(arg_12_1 % 86400 % 3600 / 60)
			local var_12_7 = var_12_4 .. var_0_1:translation("UNIT_DAY")

			if var_12_5 ~= 0 then
				var_12_7 = var_12_7 .. var_12_5 .. var_0_1:translation("UNIT_HOUR")
			end

			if var_12_6 ~= 0 then
				var_12_7 = var_12_7 .. var_12_6 .. var_0_1:translation("UNIT_MINUTE")
			end

			var_12_0:setString(var_12_7)
		end

		arg_12_0:nodeByName("auto_apply_txt"):setPositionX(var_12_0:getPositionX() + var_12_0:getContentSize().width + 2)
	end
end

function var_0_0.setRankLabel(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	local var_13_0 = xyd.AssetLoader.get():loadLabel(nil, "bonus")

	var_13_0:setString(arg_13_1)
	var_13_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_13_0:setPosition(arg_13_2, arg_13_3)
	var_13_0:addTo(arg_13_4)
end

function var_0_0.didOpen(arg_14_0, arg_14_1)
	var_0_0.super:didOpen(arg_14_1)
	arg_14_0:addBlockLayer()
end

function var_0_0.setApplyBtnState(arg_15_0, arg_15_1, arg_15_2)
	if not arg_15_1 then
		arg_15_2:setBrightStyle(ccui.BrightStyle.normal)
		arg_15_2:getChildByName("have_apply_txt"):setVisible(false)
		arg_15_2:getChildByName("has_not_apply_txt"):setVisible(true)
	elseif arg_15_1.self_apply > 0 then
		arg_15_2:setBrightStyle(ccui.BrightStyle.highlight)
		arg_15_2:getChildByName("have_apply_txt"):setVisible(true)
		arg_15_2:getChildByName("has_not_apply_txt"):setVisible(false)
	else
		arg_15_2:setBrightStyle(ccui.BrightStyle.normal)
		arg_15_2:getChildByName("have_apply_txt"):setVisible(false)
		arg_15_2:getChildByName("has_not_apply_txt"):setVisible(true)
	end
end

return var_0_0
