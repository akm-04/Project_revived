local var_0_0 = class("DormWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.item
local var_0_5 = {
	guild = 2,
	friend = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.isSelfDorm = arg_1_0.dorm:isSelfDorm()
	arg_1_0.params = arg_1_2 or {}
	arg_1_0.isrank = arg_1_0.params.isrank or false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:setButtonClick()
	arg_2_0:layout()
end

function var_0_0.setButtonClick(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("btn_myhouse"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("my_house")
		end
	end)
	arg_3_0:nodeByName("btn_lounge"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_3_0.dorm:toLoungeHouse()
		end
	end)
	arg_3_0:nodeByName("btn_normal"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = {
				floorType = xyd.DormType.NORMAL
			}

			xyd.WindowManager.get():openWindow("floor_view", var_6_0)
		end
	end)
	arg_3_0:nodeByName("btn_foreign"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {
				floorType = xyd.DormType.FOREIGN
			}

			xyd.WindowManager.get():openWindow("floor_view", var_7_0)
		end
	end)
	arg_3_0:nodeByName("btn_villa"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = {
				floorType = xyd.DormType.VILLA
			}

			xyd.WindowManager.get():openWindow("floor_view", var_8_0)
		end
	end)
	arg_3_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			local var_9_0 = {
				title_name = "DORM_RULE_TITLE",
				rule = "DORM_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("text_rule", var_9_0)
		end
	end)
	arg_3_0:nodeByName("btn_visit"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			if not arg_3_0:nodeByName("visit_container"):isVisible() then
				arg_3_0:nodeByName("visit_container"):setVisible(true)
			else
				arg_3_0:nodeByName("visit_container"):setVisible(false)
			end
		end
	end)
	arg_3_0:nodeByName("btn_visit_friend"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			local var_11_0 = {
				visit_type = var_0_5.friend
			}

			xyd.WindowManager.get():openWindow("dorm_friend_list", var_11_0)
		end
	end)
	arg_3_0:nodeByName("btn_visit_guild"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			arg_3_0.guild:loadTeam(function(arg_13_0, arg_13_1)
				if arg_13_0 == xyd.error.OK then
					local var_13_0 = {
						visit_type = var_0_5.guild
					}

					if arg_3_0.guild.members then
						xyd.WindowManager.get():openWindow("dorm_friend_list", var_13_0)
					else
						local var_13_1 = var_0_3:translation("GUILD_CHAT_ALERT")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_13_1
						})
					end
				end
			end)
		end
	end)
	arg_3_0:nodeByName("btn_visit_random"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			arg_3_0.dorm:visitRandomHouse()
		end
	end)
	arg_3_0:nodeByName("btn_rank"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			local var_15_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RANK_LIST)

			var_15_0:loadRankList({
				xyd.SubRankType.DORM_COMFORT_RANK
			}, true, function(arg_16_0, arg_16_1)
				if arg_16_0 == xyd.error.OK then
					local var_16_0 = {
						rank_type = xyd.RankType.Dorm,
						sub_type = xyd.SubRankType.DORM_COMFORT_RANK,
						rankData = var_15_0:getRankList()
					}

					xyd.WindowManager.get():openWindow("new_rank_list", var_16_0)
				end
			end)
		end
	end)
	arg_3_0:nodeByName("close"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			local var_17_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_17_0, false)

			if arg_3_0.isrank then
				local var_17_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.RANK_LIST)

				var_17_1:loadRankList({
					xyd.SubRankType.DORM_COMFORT_RANK
				}, true, function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK then
						local var_18_0 = {
							rank_type = xyd.RankType.Dorm,
							sub_type = xyd.SubRankType.DORM_COMFORT_RANK,
							rankData = var_17_1:getRankList()
						}

						xyd.WindowManager.get():openWindow("new_rank_list", var_18_0)
					end
				end)
			end

			if not arg_3_0.isSelfDorm and arg_3_0.dorm.willOpenSelfRoom then
				arg_3_0.dorm:getHouseList(nil, function(arg_19_0, arg_19_1)
					if arg_19_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("dorm")
					else
						xyd.WindowManager.get():closeWindow(arg_3_0)
					end
				end)
			else
				arg_3_0.dorm:setOpenSelfRoom(false)
				xyd.WindowManager.get():closeWindow(arg_3_0)
			end
		end
	end)
	arg_3_0:nodeByName("normal_touch"):setTouchEnabled(true)
	arg_3_0:nodeByName("normal_touch"):setTouchSwallowEnabled(false)
	arg_3_0:nodeByName("normal_touch"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		if arg_20_0.name == "began" then
			preX_ = arg_20_0.x
			preY_ = arg_20_0.y
			isMove_ = false

			arg_3_0:nodeByName("normal_building"):setVisible(true)
		end

		if arg_20_0.name == "moved" and (math.abs(arg_20_0.x - preX_) > 30 or math.abs(arg_20_0.y - preY_) > 30) then
			arg_3_0:nodeByName("normal_building"):setVisible(false)

			isMove_ = true
		end

		if arg_20_0.name == "ended" then
			arg_3_0:nodeByName("normal_building"):setVisible(false)
		end

		return true
	end)
	arg_3_0:nodeByName("foreign_touch"):setTouchEnabled(true)
	arg_3_0:nodeByName("foreign_touch"):setTouchSwallowEnabled(false)
	arg_3_0:nodeByName("foreign_touch"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
		if arg_21_0.name == "began" then
			preX_ = arg_21_0.x
			preY_ = arg_21_0.y
			isMove_ = false

			arg_3_0:nodeByName("foreign_building"):setVisible(true)
		end

		if arg_21_0.name == "moved" and (math.abs(arg_21_0.x - preX_) > 30 or math.abs(arg_21_0.y - preY_) > 30) then
			arg_3_0:nodeByName("foreign_building"):setVisible(false)

			isMove_ = true
		end

		if arg_21_0.name == "ended" then
			arg_3_0:nodeByName("foreign_building"):setVisible(false)
		end

		return true
	end)
	arg_3_0:nodeByName("villa_touch"):setTouchEnabled(true)
	arg_3_0:nodeByName("villa_touch"):setTouchSwallowEnabled(false)
	arg_3_0:nodeByName("villa_touch"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
		if arg_22_0.name == "began" then
			preX_ = arg_22_0.x
			preY_ = arg_22_0.y
			isMove_ = false

			arg_3_0:nodeByName("villa_building"):setVisible(true)
		end

		if arg_22_0.name == "moved" and (math.abs(arg_22_0.x - preX_) > 30 or math.abs(arg_22_0.y - preY_) > 30) then
			arg_3_0:nodeByName("villa_building"):setVisible(false)

			isMove_ = true
		end

		if arg_22_0.name == "ended" then
			arg_3_0:nodeByName("villa_building"):setVisible(false)
		end

		return true
	end)
end

function var_0_0.layout(arg_23_0)
	arg_23_0:nodeByName("normal_building"):setVisible(false)
	arg_23_0:nodeByName("villa_building"):setVisible(false)
	arg_23_0:nodeByName("foreign_building"):setVisible(false)
	arg_23_0:nodeByName("btn_normal"):setVisible(false)
	arg_23_0:nodeByName("btn_foreign"):setVisible(false)
	arg_23_0:nodeByName("btn_villa"):setVisible(false)
	arg_23_0:nodeByName("normal_touch"):setVisible(true)
	arg_23_0:nodeByName("foreign_touch"):setVisible(true)
	arg_23_0:nodeByName("villa_touch"):setVisible(true)

	if arg_23_0.dorm:checkDormOpen(xyd.FunctionID.ID_DORM_NORMAL) then
		arg_23_0:nodeByName("btn_normal"):setVisible(true)
		arg_23_0:nodeByName("normal_touch"):setVisible(false)
	end

	if arg_23_0.dorm:checkDormOpen(xyd.FunctionID.ID_DORM_FOREIGN) then
		arg_23_0:nodeByName("btn_foreign"):setVisible(true)
		arg_23_0:nodeByName("foreign_touch"):setVisible(false)
	end

	if arg_23_0.dorm:checkDormOpen(xyd.FunctionID.ID_DORM_VILLA) then
		arg_23_0:nodeByName("btn_villa"):setVisible(true)
		arg_23_0:nodeByName("villa_touch"):setVisible(false)
	end

	arg_23_0:nodeByName("visit_container"):setVisible(false)

	if arg_23_0.dorm:isSelfDorm() then
		arg_23_0:nodeByName("house_name_bg"):setVisible(false)
	else
		arg_23_0:nodeByName("house_name_bg"):setVisible(true)
		arg_23_0:nodeByName("owner"):setString((arg_23_0.dorm.dormPlayerInfo.player_name or arg_23_0.dorm.dormPlayerInfo.name) .. var_0_3:translation("DORM_OWNER_NAME"))
	end

	if not arg_23_0.dorm:checkDormOpen(xyd.FunctionID.ID_DORM_VILLA) then
		arg_23_0:nodeByName("btn_myhouse"):setVisible(false)
		arg_23_0:nodeByName("visit_container"):setPositionY(arg_23_0:nodeByName("visit_container"):getPositionY() - 143)
		arg_23_0:nodeByName("btn_visit"):setPositionY(arg_23_0:nodeByName("btn_visit"):getPositionY() - 143)
	end
end

function var_0_0.didClose(arg_24_0)
	var_0_0.super.didClose()

	if arg_24_0.schedulerHandler ~= nil then
		var_0_1.unscheduleGlobal(arg_24_0.schedulerHandler)
	end
end

return var_0_0
