local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = {
	TEN = 10,
	ONE = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	arg_2_0.buyTimes = arg_2_0.activity.details.buy_times

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.container = var_2_0:getChildByName("background")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:refreshLayout()

	arg_3_0.tableID = xyd.tables.misc:getValue("activity_tie_up_partner")

	arg_3_0.container:getChildByName("text_up_safe_count"):getVirtualRenderer():setAdditionalKerning(-4)
	arg_3_0.container:getChildByName("text_up_safe_tips"):setString(var_0_1:translation("ACTIVITY_CONTRACT_TEXT_19"))

	local var_3_0 = xyd.tables.hero:getSkill(arg_3_0.tableID)
	local var_3_1 = arg_3_0.container:getChildByName("skill_container")

	for iter_3_0 = 1, 4 do
		local var_3_2 = var_3_0[iter_3_0]
		local var_3_3 = display.newNode()
		local var_3_4 = 96

		var_3_3:setContentSize(var_3_4, var_3_4)
		xyd.setSkillBorder(var_3_3, var_3_2, true)
		var_3_3:addTo(var_3_1)
		var_3_3:setPosition((iter_3_0 - 1) * 127, 0)
		var_3_3:setTouchEnabled(true)
		var_3_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
			if arg_4_0.name == "began" then
				local var_4_0 = {
					has_jiantou = false,
					id = var_3_2
				}

				if not xyd.WindowManager.get():getWindow("skill_tips") then
					local var_4_1 = xyd.WindowManager.get():openWindow("skill_tips", var_4_0)

					xyd.adaptToWorldPosition(var_3_3, var_4_1)
				end

				return true
			elseif arg_4_0.name == "ended" then
				xyd.WindowManager.get():closeWindow("skill_tips")
			end
		end)
	end

	arg_3_0.container:getChildByName("text_desc"):setString(string.format(var_0_1:translation("ACTIVITY_CONTRACT_TEXT_1"), xyd.tables.hero:name(arg_3_0.tableID)))
	arg_3_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {}

			var_5_0.title_name = "ACTIVITY_CONTRACT_TEXT_6"
			var_5_0.rule = "ACTIVITY_CONTRACT_TEXT_7"
			var_5_0.style = xyd.RuleStyle.PURPLE

			xyd.WindowManager.get():openWindow("new_text_rule", var_5_0)
		end
	end)
	arg_3_0.container:getChildByName("btn_buy_ticket"):getChildByName("text_buy_ticket"):setString(var_0_1:translation("ACTIVITY_CONTRACT_TEXT_2"))
	arg_3_0.container:getChildByName("btn_buy_ticket"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			if arg_3_0.buyTimes >= xyd.tables.misc:getValue("activity_tie_ticket_buy_limit") then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ACTIVITY_CONTRACT_TEXT_16"), function()
					return
				end, nil, nil, xyd.ColorMode.PURPLE)

				return
			end

			xyd.WindowManager.get():openWindow("activity_contract_buy_ticket", {
				buyTimes = arg_3_0.buyTimes
			})
		end
	end)
	arg_3_0.container:getChildByName("btn_browse"):getChildByName("text_browse"):setString(var_0_1:translation("ACTIVITY_CONTRACT_TEXT_3"))
	arg_3_0.container:getChildByName("btn_browse"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_8_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("activity_contract_browse")
		end
	end)
	arg_3_0.container:getChildByName("btn_one"):getChildByName("text_one"):setString(var_0_1:translation("ACTIVITY_CONTRACT_TEXT_4"))
	arg_3_0.container:getChildByName("btn_one"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			if arg_3_0.selfPlayer:getBackpack():getItemNumByID(var_0_2:getValue("activity_tie_summon_item")) < var_0_3.ONE then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_CONTRACT_TEXT_15")
				})

				return
			end

			local function var_9_0()
				local var_10_0 = {
					id = 1
				}

				xyd.Backend.get():request(xyd.mid.ACTIVITY_CONTRACT_SUMMON, var_10_0, function(arg_11_0, arg_11_1)
					if arg_11_0 == xyd.error.OK and arg_11_1 and arg_11_1.awards then
						if arg_11_1.base_info then
							arg_3_0.activity.details = arg_11_1.base_info
						end

						local var_11_0 = var_0_2:getValue("activity_tie_summon_item")

						arg_3_0.selfPlayer:getBackpack():removeItem({
							itemID = var_11_0,
							itemNum = var_0_3.ONE
						})

						local var_11_1 = {}

						arg_3_0.selfPlayer:handleRewardsWithoutShow(arg_11_1.awards)

						for iter_11_0, iter_11_1 in pairs(arg_11_1.awards) do
							if tonumber(iter_11_0) then
								table.insert(var_11_1, iter_11_1)
							end
						end

						local var_11_2 = {
							items = var_11_1,
							times = var_0_3.ONE,
							extraAward = arg_11_1.items
						}

						for iter_11_2, iter_11_3 in pairs(var_11_1) do
							arg_3_0.selfPlayer:heroUpdateEvent_({
								name = xyd.event.HERO_UPDATE,
								params = iter_11_3
							}, true)
						end

						arg_3_0:refreshLayout()
						xyd.WindowManager.get():openWindow("activity_girls_treasure_award_show", var_11_2)
					end
				end)
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ACTIVITY_CONTRACT_TEXT_18"), var_9_0)
		end
	end)
	arg_3_0.container:getChildByName("btn_ten"):getChildByName("text_ten"):setString(var_0_1:translation("ACTIVITY_CONTRACT_TEXT_5"))
	arg_3_0.container:getChildByName("btn_ten"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_12_0, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			if arg_3_0.selfPlayer:getBackpack():getItemNumByID(var_0_2:getValue("activity_tie_summon_item")) < var_0_3.TEN then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_CONTRACT_TEXT_15")
				})

				return
			end

			local var_12_0 = {
				id = 2
			}

			xyd.Backend.get():request(xyd.mid.ACTIVITY_CONTRACT_SUMMON, var_12_0, function(arg_13_0, arg_13_1)
				if arg_13_0 == xyd.error.OK and arg_13_1 and arg_13_1.awards then
					if arg_13_1.base_info then
						arg_3_0.activity.details = arg_13_1.base_info
					end

					local var_13_0 = var_0_2:getValue("activity_tie_summon_item")

					arg_3_0.selfPlayer:getBackpack():removeItem({
						itemID = var_13_0,
						itemNum = var_0_3.TEN
					})

					local var_13_1 = {}

					arg_3_0.selfPlayer:handleRewardsWithoutShow(arg_13_1.awards)

					for iter_13_0, iter_13_1 in pairs(arg_13_1.awards) do
						if tonumber(iter_13_0) then
							table.insert(var_13_1, iter_13_1)
						end
					end

					local var_13_2 = {
						items = var_13_1,
						times = var_0_3.TEN,
						extraAward = arg_13_1.items
					}

					for iter_13_2, iter_13_3 in pairs(var_13_1) do
						arg_3_0.selfPlayer:heroUpdateEvent_({
							name = xyd.event.HERO_UPDATE,
							params = iter_13_3
						}, true)
					end

					arg_3_0:refreshLayout()
					xyd.WindowManager.get():openWindow("activity_girls_treasure_award_show", var_13_2)
				end
			end)
		end
	end)
end

function var_0_0.refreshLayout(arg_14_0)
	local var_14_0 = arg_14_0.container:getChildByName("text_up_safe_count")
	local var_14_1 = var_0_2:getValue("activity_tie_up_safe") - arg_14_0.activity.details.up_count
	local var_14_2 = math.ceil(var_14_1 / 10)

	var_14_0:setString(var_14_2)
end

return var_0_0
