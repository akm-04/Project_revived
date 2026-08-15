local var_0_0 = class("FourthAnniPaintVisitWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = xyd.tables.fourthAnniPaintingTable
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.basePos = {
		x = 352,
		y = 598
	}
	arg_1_0.color = {
		cc.c3b(255, 123, 119),
		cc.c3b(135, 217, 244),
		cc.c3b(80, 223, 157),
		cc.c3b(255, 224, 204),
		cc.c3b(255, 255, 255),
		cc.c3b(54, 47, 44)
	}
	arg_1_0.info = arg_1_2.info
	arg_1_0.painted = arg_1_2.map
	arg_1_0.voteNum = arg_1_0.info.vote_num
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("vote_num"):setString(arg_2_0.voteNum)
	arg_2_0:nodeByName("title_txt"):setString(var_0_3:translation("FOURTH_ANNI_PAINT_TXT8"))
	arg_2_0:nodeByName("talk_content"):setString(var_0_3:translation("FOURTH_ANNI_PAINT_TXT16"))
	arg_2_0:initDatas()
	arg_2_0:initBlocks()
	arg_2_0:setBtns()
end

function var_0_0.initDatas(arg_3_0)
	arg_3_0.map = {}

	for iter_3_0 = 1, 48 do
		arg_3_0.map[iter_3_0] = {}

		local var_3_0

		if arg_3_0.painted[iter_3_0] and arg_3_0.painted[iter_3_0] ~= "" then
			var_3_0 = xyd.splitToNumber(arg_3_0.painted[iter_3_0], "|")
		else
			var_3_0 = {}
		end

		for iter_3_1 = 1, 30 do
			arg_3_0.map[iter_3_0][iter_3_1] = var_3_0[iter_3_1] or 0
		end
	end
end

function var_0_0.initBlocks(arg_4_0)
	for iter_4_0 = 1, 48 do
		for iter_4_1 = 1, 30 do
			local var_4_0 = xyd.AssetLoader.get():loadSprite("windows/anniversary4th/painting/block.png")

			var_4_0:pos(arg_4_0.basePos.x + 15 * iter_4_0, arg_4_0.basePos.y - 15 * iter_4_1)
			var_4_0:addTo(arg_4_0:nodeByName("container"):getChildByName("blocks"))
			var_4_0:setAnchorPoint(0.5, 0.5)
			var_4_0:setName("block_" .. iter_4_0 .. "_" .. iter_4_1)

			local var_4_1 = arg_4_0.map[iter_4_0][iter_4_1]

			if var_4_1 > 0 then
				var_4_0:setColor(arg_4_0.color[var_4_1])
			else
				var_4_0:setVisible(false)
			end
		end
	end
end

function var_0_0.setBtns(arg_5_0)
	local var_5_0 = var_0_1.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_5_0:addTo(arg_5_0:nodeByName("title"))
	var_5_0:setAnchorPoint(0.5, 0.5)
	var_5_0:setPosition(43, -23)
	var_5_0:setName("return_btn")

	arg_5_0.returnBtn = var_5_0

	arg_5_0.returnBtn:addTouchEvent(function(arg_6_0)
		if arg_6_0.name == "ended" then
			xyd.playCloseSound()
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_vote"), nil, function()
		xyd.WindowManager.get():openWindow("fourth_anni_paint_vote", arg_5_0.info)
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("rule_btn"), nil, function()
		local var_8_0 = {
			title_name = "FOURTH_ANNI_PAINT_RULE_TITLE",
			rule = "FOURTH_ANNI_PAINT_RULE_TEXT"
		}

		xyd.WindowManager.get():openWindow("new_text_rule", var_8_0)
	end)
end

return var_0_0
