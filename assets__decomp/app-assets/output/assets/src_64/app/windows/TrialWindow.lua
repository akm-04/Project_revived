local var_0_0 = class("TrialWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

var_0_0.NODE_WEI = "node_wei"
var_0_0.NODE_SHU = "node_shu"
var_0_0.NODE_WU = "node_wu"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.nodeWei_ = arg_2_0:nodeByName(var_0_0.NODE_WEI)
	arg_2_0.nodeShu_ = arg_2_0:nodeByName(var_0_0.NODE_SHU)
	arg_2_0.nodeWu_ = arg_2_0:nodeByName(var_0_0.NODE_WU)
	arg_2_0.nodes = {}

	table.insert(arg_2_0.nodes, arg_2_0.nodeWei_)
	table.insert(arg_2_0.nodes, arg_2_0.nodeShu_)
	table.insert(arg_2_0.nodes, arg_2_0.nodeWu_)

	arg_2_0.spriteWei_ = display.newFilteredSprite("images/trial/wei_img.png", "GRAY", {
		0.2,
		0.3,
		0.5,
		0.1
	})
	arg_2_0.spriteShu_ = display.newFilteredSprite("images/trial/shu_img.png", "GRAY", {
		0.2,
		0.3,
		0.5,
		0.1
	})
	arg_2_0.spriteWu_ = display.newFilteredSprite("images/trial/wu_img.png", "GRAY", {
		0.2,
		0.3,
		0.5,
		0.1
	})
	arg_2_0.sprites = {}

	table.insert(arg_2_0.sprites, arg_2_0.spriteWei_)
	table.insert(arg_2_0.sprites, arg_2_0.spriteShu_)
	table.insert(arg_2_0.sprites, arg_2_0.spriteWu_)
	arg_2_0.nodeWei_:addChild(arg_2_0.spriteWei_)
	arg_2_0.spriteWei_:setPositionY(arg_2_0.spriteWei_:getContentSize().height / 2)
	arg_2_0.nodeShu_:addChild(arg_2_0.spriteShu_)
	arg_2_0.spriteShu_:setPositionY(arg_2_0.spriteShu_:getContentSize().height / 2)
	arg_2_0.nodeWu_:addChild(arg_2_0.spriteWu_)
	arg_2_0.spriteWu_:setPositionY(arg_2_0.spriteWu_:getContentSize().height / 2)
	arg_2_0.nodeWei_:setTouchEnabled(true)
	arg_2_0.nodeShu_:setTouchEnabled(true)
	arg_2_0.nodeWu_:setTouchEnabled(true)

	arg_2_0.controllByWeekDay = true

	arg_2_0:setTouchSwallowEnabled(false)

	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0.selfPlayer:loadTrialInfos(function()
		arg_2_0:updateTrials()
	end)
end

function var_0_0.updateTrials(arg_4_0)
	arg_4_0.trials = arg_4_0.selfPlayer.trialInfos_

	for iter_4_0 = 1, #arg_4_0.nodes do
		local var_4_0 = xyd.tables.trialConfig:openDates(iter_4_0 + 10)
		local var_4_1 = ""

		for iter_4_1, iter_4_2 in pairs(var_4_0) do
			if string.len(var_4_1) > 0 then
				var_4_1 = var_4_1 .. "、" .. var_0_1:translation("NUM_" .. iter_4_2)
			else
				var_4_1 = var_0_1:translation("NUM_" .. iter_4_2)
			end
		end

		if arg_4_0.trials[iter_4_0 + 10] ~= nil and tonumber(arg_4_0.trials[iter_4_0 + 10].isOpen) == 1 then
			arg_4_0.sprites[iter_4_0]:clearFilter()
		end

		arg_4_0.nodes[iter_4_0]:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "began" then
				return true
			elseif arg_5_0.name == "ended" then
				arg_4_0.selfPlayer:loadTrialInfos(function()
					arg_4_0.trials = arg_4_0.selfPlayer.trialInfos_

					if arg_4_0.trials[iter_4_0 + 10] ~= nil and tonumber(arg_4_0.trials[iter_4_0 + 10].isOpen) == 1 then
						xyd.WindowManager.get():openWindow("select_trial", arg_4_0.trials[iter_4_0 + 10])
					elseif arg_4_0.controllByWeekDay == true then
						local var_6_0 = string.format(var_0_1:translation("OPEN_TIPS"), var_4_1)

						xyd.WindowManager.get():openWindow("trialtips", {
							trialType = iter_4_0 + 10,
							openStr = var_6_0
						})

						return
					end
				end)
			end
		end)
	end
end

function var_0_0.didOpen(arg_7_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RIGHT_PULL
	})
end

function var_0_0.didClose(arg_8_0)
	return
end

return var_0_0
