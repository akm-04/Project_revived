local var_0_0 = class("ZhugeMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_1_2 and arg_1_2.is_complete then
		arg_1_0.showCompleteTips = true
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0)
	local var_3_0 = xyd.WindowManager.get():getWindow("zhuge_small_house")

	if var_3_0 and not tolua.isnull(var_3_0) then
		var_3_0:updateCoin()
	end
end

function var_0_0.layout(arg_4_0)
	local function var_4_0()
		local var_5_0 = {
			teamType = xyd.ZhugeSelectTeamType.FIRST_SELECT
		}

		xyd.WindowManager.get():openWindow("zhuge_select_team", var_5_0)
	end

	arg_4_0:nodeByName("btn_start"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_6_0:setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.moved then
			arg_6_0:setScale(1)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			arg_6_0:setScale(1)

			local var_6_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_1")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
				arg_4_0.zhugeModel:resetAdventure(function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						xyd.db.formation:setFormationData(xyd.CampaignType.ZHUGE_ENEMY, "")

						if not arg_4_0 or tolua.isnull(arg_4_0) then
							return
						end

						if xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL):checkIsPass() then
							var_4_0()
						else
							arg_4_0:playStory()
						end
					end
				end)
			end, nil, nil, arg_4_0.colorMode)
		end
	end)
	arg_4_0:nodeByName("btn_continue"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			arg_9_0:setScale(0.9)
		elseif arg_9_1 == ccui.TouchEventType.moved then
			arg_9_0:setScale(1)
		elseif arg_9_1 == ccui.TouchEventType.ended then
			arg_9_0:setScale(1)

			local var_9_0 = arg_4_0.zhugeModel:getBaseInfo()

			if #arg_4_0.zhugeModel:getMemberInfos() == 0 then
				local var_9_1 = var_0_1:translation("ZHUGE_FOREST_TIPS_3")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_1
				})

				return
			end

			xyd.WindowManager.get():openWindow("zhuge_new_adventure")
		end
	end)

	if not arg_4_0.zhugeModel:checkIsPass() then
		arg_4_0:nodeByName("btn_sweep"):setTouchEnabled(false)
		arg_4_0:nodeByName("btn_sweep"):setBright(false)
	end

	arg_4_0:nodeByName("btn_sweep"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			arg_10_0:setScale(0.9)
		elseif arg_10_1 == ccui.TouchEventType.moved then
			arg_10_0:setScale(1)
		elseif arg_10_1 == ccui.TouchEventType.ended then
			arg_10_0:setScale(1)

			if arg_4_0.zhugeModel:checkIsPass() then
				xyd.WindowManager.get():openWindow("zhuge_forest_sweep", response)
			end
		end
	end)
	arg_4_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.began then
			arg_11_0:setScale(0.9)
		elseif arg_11_1 == ccui.TouchEventType.moved then
			arg_11_0:setScale(1)
		elseif arg_11_1 == ccui.TouchEventType.ended then
			arg_11_0:setScale(1)

			local var_11_0 = {
				title_name = "ZHUGE_RULE_TITLE",
				rule = "ZHUGE_RULE_CONTENT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_11_0)
		end
	end)
end

function var_0_0.didOpen(arg_12_0, arg_12_1)
	var_0_0.super:didOpen(arg_12_1)

	if arg_12_0.showCompleteTips then
		local var_12_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_31")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_12_0
		})
	end
end

function var_0_0.playStory(arg_13_0)
	local var_13_0 = {
		talk_id = "zhuge01",
		callback = function()
			local var_14_0 = {
				teamType = xyd.ZhugeSelectTeamType.FIRST_SELECT
			}

			xyd.WindowManager.get():openWindow("zhuge_select_team", var_14_0)
		end
	}

	xyd.WindowManager.get():openWindow("school_story_talk", var_13_0)
	xyd.WindowManager.get():closeWindow(arg_13_0.name)
end

return var_0_0
