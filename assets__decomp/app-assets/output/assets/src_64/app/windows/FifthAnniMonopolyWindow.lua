local var_0_0 = class("FifthAnniMonopolyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.fifthAnniMonopolyMap
local var_0_3 = xyd.tables.fifthAnniMonopolyAward
local var_0_4 = xyd.tables.misc
local var_0_5 = import("app.model.Hero")
local var_0_6 = import("framework.scheduler")
local var_0_7 = var_0_4:getValue("fifth_anni_monopoly_block_num")
local var_0_8 = 1
local var_0_9 = 10
local var_0_10 = {}
local var_0_11 = var_0_4:getValue("fifth_anni_monopoly_model_id")

for iter_0_0 = 1, 6 do
	table.insert(var_0_10, "skeletons/ui_effect/super_rich/activity_rich_dice0" .. iter_0_0)
end

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.fifthAnniModel = xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY)
	arg_1_0.isFirst = true
	arg_1_0.isAnimation = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		show_rule = true
	})
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)

	arg_3_0.initPos = arg_3_0.fifthAnniModel.monopolyPos
	arg_3_0.diceTimes = arg_3_0.fifthAnniModel.monopolyTimes or 0
	arg_3_0.circles = arg_3_0.fifthAnniModel.monopolyCircles or 1

	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	xyd.nodeEventSample(arg_4_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function()
		local var_5_0 = {
			title_name = "FIFTH_ANNI_MONOPOLY_RULE_TITLE",
			rule = "FIFTH_ANNI_MONOPOLY_RULE_TEXT"
		}

		xyd.WindowManager.get():openWindow("new_text_rule", var_5_0)
	end)

	if arg_4_0.isFirst then
		-- block empty
	end

	arg_4_0:initPlayerModel()
	arg_4_0:initDiceBtn()

	local var_4_0 = var_0_4:getValue("fifth_anni_monopoly_extra_award_gift")
	local var_4_1 = xyd.tables.gift:items(var_4_0)[1]
	local var_4_2 = arg_4_0:nodeByName("gift")

	xyd.setItemAndAddTips(var_4_2, var_4_1)
	arg_4_0:updateDiceTimes()
end

function var_0_0.updateDiceTimes(arg_6_0)
	if arg_6_0.diceTimes > 0 then
		local var_6_0 = string.format(var_0_1:translation("ACTIVITY_1232_MONOPOLY_2"), arg_6_0.diceTimes)

		arg_6_0:nodeByName("txt_chat"):setString(var_6_0)
	else
		local var_6_1 = var_0_1:translation("ACTIVITY_1232_MONOPOLY_3")

		arg_6_0:nodeByName("txt_chat"):setString(var_6_1)
	end

	local var_6_2 = var_0_4:getValue("fifth_anni_monopoly_extra_award_circle") - arg_6_0.circles + 1

	if var_6_2 > 0 then
		local var_6_3 = string.format(var_0_1:translation("ACTIVITY_1232_MONOPOLY_1"), var_6_2)

		arg_6_0:nodeByName("txt_message"):setString(var_6_3)
	else
		arg_6_0:nodeByName("bg_message"):setVisible(false)
	end
end

function var_0_0.initPlayerModel(arg_7_0)
	arg_7_0.player = xyd.HeroAnimation.new(nil, var_0_11, 0.5, {})

	arg_7_0.player:addTo(arg_7_0:nodeByName("map"))
	arg_7_0.player:setPosition(arg_7_0:nodeByName("pos_" .. arg_7_0.initPos):getPosition())

	if arg_7_0.player then
		arg_7_0.player:idle()

		if arg_7_0.initPos >= var_0_9 then
			arg_7_0.player:flipX(not arg_7_0.player:getFlipX())
		end
	end
end

function var_0_0.playerMove(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}

	if not arg_8_1 or not next(arg_8_1) then
		return
	end

	local var_8_1 = arg_8_1[1].move

	for iter_8_0 = 1, var_8_1 do
		arg_8_0.initPos = arg_8_0.initPos + 1

		if arg_8_0.initPos > var_0_7 then
			arg_8_0.initPos = arg_8_0.initPos - var_0_7
			arg_8_0.circles = arg_8_0.circles + 1
			arg_8_0.fifthAnniModel.monopolyCircles = arg_8_0.circles

			arg_8_0:updateDiceTimes()
		end

		local var_8_2, var_8_3 = arg_8_0:nodeByName("pos_" .. arg_8_0.initPos):getPosition()
		local var_8_4 = cc.MoveTo:create(0.5, cc.p(var_8_2, var_8_3))

		table.insert(var_8_0, var_8_4)

		if arg_8_0.initPos == var_0_8 or arg_8_0.initPos == var_0_9 then
			local var_8_5 = cc.CallFunc:create(function()
				if arg_8_0.player then
					arg_8_0.player:flipX(not arg_8_0.player:getFlipX())
				end
			end)

			table.insert(var_8_0, var_8_5)
		end
	end

	local var_8_6 = cc.CallFunc:create(function()
		if arg_8_0.player then
			arg_8_0.player:idle()
		end
	end)

	table.insert(var_8_0, var_8_6)

	local function var_8_7()
		table.remove(arg_8_1, 1)

		if next(arg_8_1) then
			arg_8_2 = false

			if arg_8_0.initPos + arg_8_1[1].move == var_0_7 + 1 and arg_8_1[2] then
				arg_8_2 = true
			end

			arg_8_0:playerMove(arg_8_1, arg_8_2)
		else
			arg_8_0.isAnimation = false
		end
	end

	local var_8_8 = var_0_2:typeId(arg_8_0.initPos)
	local var_8_9 = var_0_3:message(var_8_8)[arg_8_1[1].award_id]

	table.insert(var_8_0, cc.DelayTime:create(0.5))
	table.insert(var_8_0, cc.CallFunc:create(function()
		xyd.WindowManager.get():openWindow("fifth_anni_story", {
			message = var_8_9,
			callback = function()
				if arg_8_1[1].awards then
					arg_8_0.selfPlayer:handleRewards(arg_8_1[1].awards, var_8_7)
				else
					var_8_7()
				end
			end
		})
	end))

	if arg_8_0.player then
		arg_8_0.player:walk(true)
	end

	arg_8_0.player:runAction(cc.Sequence:create(var_8_0))
end

function var_0_0.diceEffect(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = {}

	if not arg_14_1 or not next(arg_14_1) then
		return
	end

	local var_14_1

	if arg_14_2 then
		var_14_1 = arg_14_1[1].move + arg_14_1[2].move
	else
		var_14_1 = arg_14_1[1].move
	end

	for iter_14_0 = 1, 10 do
		local var_14_2 = math.random(6)
		local var_14_3 = cc.CallFunc:create(function()
			arg_14_0:nodeByName("dice_" .. var_14_2):setVisible(true)
		end)

		table.insert(var_14_0, var_14_3)

		local var_14_4 = cc.DelayTime:create(0.1)

		table.insert(var_14_0, var_14_4)

		local var_14_5 = cc.CallFunc:create(function()
			arg_14_0:nodeByName("dice_" .. var_14_2):setVisible(false)
		end)

		table.insert(var_14_0, var_14_5)
	end

	local var_14_6 = cc.CallFunc:create(function()
		arg_14_0:nodeByName("dice_" .. var_14_1):setVisible(true)
	end)

	table.insert(var_14_0, var_14_6)

	if arg_14_3 then
		table.insert(var_14_0, cc.DelayTime:create(0.5))
		table.insert(var_14_0, cc.CallFunc:create(arg_14_3))
	end

	arg_14_0:nodeByName("dice_1"):setVisible(false)
	arg_14_0:nodeByName("dice_2"):setVisible(false)
	arg_14_0:nodeByName("dice_3"):setVisible(false)
	arg_14_0:nodeByName("dice_4"):setVisible(false)
	arg_14_0:nodeByName("dice_5"):setVisible(false)
	arg_14_0:nodeByName("dice_6"):setVisible(false)
	arg_14_0:nodeByName("map"):runAction(cc.Sequence:create(var_14_0))
end

function var_0_0.initDiceBtn(arg_18_0)
	arg_18_0:nodeByName("dice_2"):setVisible(false)
	arg_18_0:nodeByName("dice_3"):setVisible(false)
	arg_18_0:nodeByName("dice_4"):setVisible(false)
	arg_18_0:nodeByName("dice_5"):setVisible(false)
	arg_18_0:nodeByName("dice_6"):setVisible(false)

	local var_18_0 = arg_18_0:nodeByName("dice_1")
	local var_18_1 = display.newNode()

	var_18_1:setContentSize(var_18_0:getContentSize().width, var_18_0:getContentSize().height)
	var_18_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_18_1:addTo(arg_18_0:nodeByName("container"))
	var_18_1:setPosition(arg_18_0:nodeByName("pos_dice"):getPosition())
	var_18_1:setTouchEnabled(true)
	var_18_1:setTouchSwallowEnabled(false)
	var_18_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "began" then
			var_18_0:setScale(0.9)

			return true
		end

		if arg_19_0.name == "moved" then
			var_18_0:setScale(1)

			return true
		end

		if arg_19_0.name == "ended" then
			var_18_0:setScale(1)

			if arg_18_0.diceTimes <= 0 then
				arg_18_0.isAnimation = false

				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_1232_MONOPOLY_3")
				})
			elseif not arg_18_0.isAnimation then
				arg_18_0.fifthAnniModel:monopolyMove(function(arg_20_0, arg_20_1)
					if arg_20_0 == xyd.error.OK then
						arg_18_0.isAnimation = true

						local var_20_0 = arg_20_1.move_info

						arg_18_0.diceTimes = arg_18_0.diceTimes - 1
						arg_18_0.fifthAnniModel.monopolyTimes = arg_18_0.diceTimes

						local var_20_1 = false

						if arg_18_0.initPos + var_20_0[1].move == var_0_7 + 1 and var_20_0[2] then
							var_20_1 = true
						end

						arg_18_0:updateDiceTimes()
						arg_18_0:diceEffect(var_20_0, var_20_1, function()
							arg_18_0:playerMove(var_20_0, var_20_1)
						end)
					end
				end)
			end

			return true
		end
	end)
end

function var_0_0.didClose(arg_22_0)
	var_0_0.super.didClose(arg_22_0, params)

	arg_22_0.fifthAnniModel.monopolyPos = arg_22_0.initPos
end

return var_0_0
