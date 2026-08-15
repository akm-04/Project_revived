local var_0_0 = class("ApplyRewardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.chapterID = arg_1_2.chapter_id
	arg_1_0.rewards = arg_1_2.rewardList
	arg_1_0.scrollNodePosX = nil
	arg_1_0.scrollNodePosY = nil
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
		viewRect = cc.rect(1, 1, 732, 477),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list"))

	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:checkEquipCanGet()
	arg_4_0.list:removeAllItems()

	arg_4_0.rewards = arg_4_0.guild:getChapterRewardList()

	local var_4_0 = xyd.tables.teamDungeonSelect:itemDisplay(arg_4_0.chapterID)

	for iter_4_0 = 1, #var_4_0 do
		local var_4_1 = display.newNode()
		local var_4_2 = arg_4_0.list:newItem()
		local var_4_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/apply_reward/apply_item.csb")
		local var_4_4 = var_4_3:getChildByName("container")
		local var_4_5 = var_4_4:getChildByName("item_container")
		local var_4_6 = var_4_4:getChildByName("item_name")
		local var_4_7 = var_4_4:getChildByName("detail_btn")
		local var_4_8 = var_4_4:getChildByName("apply_btn")
		local var_4_9, var_4_10 = var_4_4:getChildByName("desc_pos"):getPosition()

		xyd.setItemBorder(var_4_5, var_4_0[iter_4_0])

		local var_4_11 = {
			id = var_4_0[iter_4_0]
		}

		xyd.addTips(node, var_4_11)
		var_4_7:getChildByName("detail_txt"):setString(var_0_1:translation("SHE_TUAN_TEXT_55"))
		arg_4_0:setApplyBtnState(arg_4_0.rewards[var_4_0[iter_4_0]], var_4_8)

		if arg_4_0.rewards[var_4_0[iter_4_0]] and arg_4_0.rewards[var_4_0[iter_4_0]].apply_member and next(arg_4_0.rewards[var_4_0[iter_4_0]].apply_member) then
			var_4_7:setVisible(true)
			var_4_7:addTouchEventListener(function(arg_5_0, arg_5_1)
				xyd.buttonScaleAnim(var_4_7, arg_5_1)

				if arg_5_1 == ccui.TouchEventType.ended and not arg_4_0.scrollViewMoved_ then
					arg_4_0.scrollNodePosX = arg_4_0.list.scrollNode:getPositionX()
					arg_4_0.scrollNodePosY = arg_4_0.list.scrollNode:getPositionY()

					local var_5_0 = {
						chapter_id = arg_4_0.chapterID,
						rewardInfo = arg_4_0.rewards[var_4_0[iter_4_0]]
					}

					xyd.WindowManager.get():openWindow("apply_queue", var_5_0)
				end
			end)
		else
			var_4_7:setVisible(false)
		end

		var_4_6:setString(xyd.tables.item:name(var_4_0[iter_4_0]))

		if arg_4_0.rewards[var_4_0[iter_4_0]] then
			arg_4_0:createRewardDesc(arg_4_0.rewards[var_4_0[iter_4_0]].award_num, arg_4_0.rewards[var_4_0[iter_4_0]].self_rank, #arg_4_0.rewards[var_4_0[iter_4_0]].apply_member, var_4_9, var_4_10, var_4_4)
		end

		var_4_8:getChildByName("have_apply_txt"):setString(var_0_1:translation("SHE_TUAN_TEXT_56"))
		var_4_8:getChildByName("has_not_apply_txt"):setString(var_0_1:translation("SHE_TUAN_TEXT_57"))
		var_4_8:addTouchEventListener(function(arg_6_0, arg_6_1)
			xyd.buttonScaleAnim(var_4_8, arg_6_1)

			if arg_6_1 == ccui.TouchEventType.ended and not arg_4_0.scrollViewMoved_ then
				arg_4_0.scrollNodePosX = arg_4_0.list.scrollNode:getPositionX()
				arg_4_0.scrollNodePosY = arg_4_0.list.scrollNode:getPositionY()

				if arg_4_0.equipApplyTimes >= 4 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("GUILD_EQUIP_LIMIT_TIPS")
					})

					return
				end

				local var_6_0 = arg_4_0.guild:getSelfAppliedInfo()

				if var_6_0 and var_6_0.item_id then
					local function var_6_1()
						local var_7_0 = {
							chapter_id = arg_4_0.chapterID,
							award_id = var_4_0[iter_4_0]
						}

						arg_4_0.guild:applyReward(var_7_0, function(arg_8_0, arg_8_1)
							if arg_8_0 == xyd.error.OK then
								arg_4_0.rewardList = arg_8_1

								arg_4_0:layout()
							end
						end)
					end

					local function var_6_2()
						arg_4_0:setApplyBtnState(arg_4_0.rewards[var_4_0[iter_4_0]], var_4_8)
					end

					local var_6_3 = {
						oldItemID = var_6_0.item_id,
						newItemID = var_4_0[iter_4_0],
						rank = var_6_0.rank,
						type = arg_4_0.rewards[var_4_0[iter_4_0]].self_apply,
						callback1 = var_6_1,
						callback2 = var_6_2
					}

					xyd.WindowManager.get():openWindow("apply_confirm", var_6_3)
				else
					local var_6_4 = {
						chapter_id = arg_4_0.chapterID,
						award_id = var_4_0[iter_4_0]
					}

					arg_4_0.guild:applyReward(var_6_4, function(arg_10_0, arg_10_1)
						if arg_10_0 == xyd.error.OK then
							arg_4_0.rewardList = arg_10_1

							arg_4_0:layout()
						end
					end)
				end
			end
		end)
		var_4_3:setContentSize(720, 132)
		var_4_1:addChild(var_4_3)
		var_4_1:setContentSize(720, 132)
		var_4_2:addContent(var_4_1)
		var_4_2:setItemSize(720, 140)
		arg_4_0.list:addItem(var_4_2)
	end

	arg_4_0.list:reload()

	if arg_4_0.scrollNodePosX and arg_4_0.scrollNodePosY then
		arg_4_0.list.scrollNode:setPosition(arg_4_0.scrollNodePosX, arg_4_0.scrollNodePosY)
	end
end

function var_0_0.checkEquipCanGet(arg_11_0)
	arg_11_0.equipApplyTimes = arg_11_0.guild.guildEquipApplyTimes

	arg_11_0:nodeByName("desc"):setString(string.format(var_0_1:translation("GUILD_EQUIP_LIMIT"), arg_11_0.equipApplyTimes, 4))
end

function var_0_0.didOpen(arg_12_0, arg_12_1)
	var_0_0.super:didOpen(arg_12_1)
	arg_12_0:addBlockLayer()
end

function var_0_0.createRewardDesc(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6)
	if arg_13_1 then
		local var_13_0 = {
			size = 24,
			color = cc.c3b(255, 111, 40)
		}
		local var_13_1 = {
			size = 24,
			color = cc.c3b(54, 54, 54)
		}
		local var_13_2

		if arg_13_1 > 0 then
			local var_13_3 = xyd.AssetLoader.get():loadLabel(var_13_0)

			var_13_3:setString(var_0_1:translation("SHENGYU"))
			var_13_3:setPosition(arg_13_4, arg_13_5)
			var_13_3:addTo(arg_13_6)
			var_13_3:setAnchorPoint(cc.p(0, 0))

			local var_13_4 = xyd.AssetLoader.get():loadLabel(var_13_1)

			var_13_4:setString(arg_13_1)

			arg_13_4 = arg_13_4 + var_13_3:getContentSize().width + 1

			var_13_4:setPosition(arg_13_4, arg_13_5)
			var_13_4:addTo(arg_13_6)
			var_13_4:setAnchorPoint(cc.p(0, 0))

			var_13_2 = xyd.AssetLoader.get():loadLabel(var_13_0)

			var_13_2:setString(var_0_1:translation("JIAN"))

			arg_13_4 = arg_13_4 + var_13_4:getContentSize().width + 1

			var_13_2:setPosition(arg_13_4, arg_13_5)
			var_13_2:addTo(arg_13_6)
			var_13_2:setAnchorPoint(cc.p(0, 0))
		end

		if arg_13_2 > 0 then
			local var_13_5 = xyd.AssetLoader.get():loadLabel(var_13_0)

			if arg_13_1 > 0 then
				var_13_5:setString(var_0_1:translation("APPLY_RANK_DESC1"))

				arg_13_4 = arg_13_4 + var_13_2:getContentSize().width + 1
			else
				var_13_5:setString(var_0_1:translation("APPLY_RANK_DESC2"))
			end

			var_13_5:setPosition(arg_13_4, arg_13_5)
			var_13_5:addTo(arg_13_6)
			var_13_5:setAnchorPoint(cc.p(0, 0))

			local var_13_6 = xyd.AssetLoader.get():loadLabel(var_13_1)

			var_13_6:setString(arg_13_2)

			arg_13_4 = arg_13_4 + var_13_5:getContentSize().width + 1

			var_13_6:setPosition(arg_13_4, arg_13_5)
			var_13_6:addTo(arg_13_6)
			var_13_6:setAnchorPoint(cc.p(0, 0))
		elseif arg_13_3 > 0 then
			local var_13_7 = xyd.AssetLoader.get():loadLabel(var_13_0)

			if arg_13_1 > 0 then
				var_13_7:setString(var_0_1:translation("APPLY_RANK_DESC3"))

				arg_13_4 = arg_13_4 + var_13_2:getContentSize().width + 1
			else
				var_13_7:setString(var_0_1:translation("APPLY_RANK_DESC4"))
			end

			var_13_7:setPosition(arg_13_4, arg_13_5)
			var_13_7:addTo(arg_13_6)
			var_13_7:setAnchorPoint(cc.p(0, 0))

			local var_13_8 = xyd.AssetLoader.get():loadLabel(var_13_1)

			var_13_8:setString(arg_13_3)

			arg_13_4 = arg_13_4 + var_13_7:getContentSize().width + 1

			var_13_8:setPosition(arg_13_4, arg_13_5)
			var_13_8:addTo(arg_13_6)
			var_13_8:setAnchorPoint(cc.p(0, 0))
		end
	end
end

function var_0_0.setApplyBtnState(arg_14_0, arg_14_1, arg_14_2)
	if not arg_14_1 then
		arg_14_2:setBrightStyle(ccui.BrightStyle.normal)
		arg_14_2:getChildByName("have_apply_txt"):setVisible(false)
		arg_14_2:getChildByName("has_not_apply_txt"):setVisible(true)
	elseif arg_14_1.self_apply > 0 then
		arg_14_2:setBrightStyle(ccui.BrightStyle.highlight)
		arg_14_2:getChildByName("have_apply_txt"):setVisible(true)
		arg_14_2:getChildByName("has_not_apply_txt"):setVisible(false)
	else
		arg_14_2:setBrightStyle(ccui.BrightStyle.normal)
		arg_14_2:getChildByName("have_apply_txt"):setVisible(false)
		arg_14_2:getChildByName("has_not_apply_txt"):setVisible(true)
	end
end

return var_0_0
