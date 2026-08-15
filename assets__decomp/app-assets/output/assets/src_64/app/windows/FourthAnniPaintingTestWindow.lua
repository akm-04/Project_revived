local var_0_0 = class("FourthAnniPaintingTestWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.fourthAnniPaintingTable
local var_0_2 = 1

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
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()

	arg_2_0.map = {}
	arg_2_0.colorMode = 1

	local var_2_0 = var_0_1:getIdsByMapId(var_0_2)

	for iter_2_0 = 1, #var_2_0 do
		arg_2_0.map[iter_2_0] = {}

		local var_2_1 = var_0_1:getData(var_0_2, var_2_0[iter_2_0])

		for iter_2_1 = 1, 48 do
			arg_2_0.map[iter_2_0][iter_2_1] = var_2_1[iter_2_1]

			local var_2_2 = xyd.AssetLoader.get():loadSprite("windows/anniversary4th/painting/block.png")

			var_2_2:pos(arg_2_0.basePos.x + 15 * iter_2_1, arg_2_0.basePos.y - 15 * iter_2_0)
			var_2_2:addTo(arg_2_0:nodeByName("container"))
			var_2_2:setAnchorPoint(0.5, 0.5)
			var_2_2:setName("block_" .. iter_2_0 .. "_" .. iter_2_1)

			if var_2_1[iter_2_1] == 0 then
				var_2_2:setVisible(false)
			else
				var_2_2:setColor(arg_2_0.color[var_2_1[iter_2_1]])
			end
		end
	end

	local var_2_3 = display.newNode()

	var_2_3:size(720, 450)
	var_2_3:setAnchorPoint(0, 1)
	var_2_3:pos(arg_2_0.basePos.x + 7, arg_2_0.basePos.y - 7)
	var_2_3:addTo(arg_2_0:nodeByName("container"))
	var_2_3:setTouchEnabled(true)
	var_2_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
		local var_3_0 = var_2_3:convertToNodeSpace(cc.p(arg_3_0.x, arg_3_0.y))

		if arg_3_0.name == "began" then
			arg_2_0.blockI = 30 - math.floor(var_3_0.y / 15)
			arg_2_0.blockJ = math.floor(var_3_0.x / 15) + 1

			return true
		elseif arg_3_0.name == "ended" then
			local var_3_1 = 30 - math.floor(var_3_0.y / 15)
			local var_3_2 = math.floor(var_3_0.x / 15) + 1

			if var_3_1 ~= arg_2_0.blockI or var_3_2 ~= arg_2_0.blockJ then
				return
			end

			local var_3_3 = arg_2_0:nodeByName("container"):getChildByName("block_" .. var_3_1 .. "_" .. var_3_2)

			arg_2_0.map[var_3_1][var_3_2] = arg_2_0.colorMode

			if arg_2_0.colorMode == 0 then
				var_3_3:setVisible(false)
			else
				var_3_3:setVisible(true)
				var_3_3:setColor(arg_2_0.color[arg_2_0.colorMode])
			end
		end
	end)

	for iter_2_2 = 1, 6 do
		xyd.nodeEventSample(arg_2_0:nodeByName("color" .. iter_2_2), {
			scale = 1
		}, function()
			arg_2_0.colorMode = iter_2_2

			arg_2_0:updateColorBtns()
		end)
	end

	xyd.nodeEventSample(arg_2_0:nodeByName("erase"), {
		scale = 1
	}, function()
		arg_2_0.colorMode = 0

		arg_2_0:updateColorBtns()
	end)
	xyd.nodeEventSample(arg_2_0:nodeByName("btn"), nil, function()
		arg_2_0:print()
	end)
	arg_2_0:updateColorBtns()
end

function var_0_0.updateColorBtns(arg_7_0)
	for iter_7_0 = 1, 6 do
		local var_7_0 = arg_7_0:nodeByName("color" .. iter_7_0)

		if iter_7_0 == arg_7_0.colorMode then
			var_7_0:setScale(1)
			var_7_0:setPositionX(1200)
		else
			var_7_0:setScale(0.75)
			var_7_0:setPositionX(1222)
		end
	end

	if arg_7_0.colorMode == 0 then
		arg_7_0:nodeByName("erase"):setScale(1.25)
	else
		arg_7_0:nodeByName("erase"):setScale(1)
	end
end

function var_0_0.print(arg_8_0)
	local var_8_0 = ""
	local var_8_1 = {}

	var_8_1[0] = 0
	var_8_1[1] = 0
	var_8_1[2] = 0
	var_8_1[3] = 0
	var_8_1[4] = 0
	var_8_1[5] = 0
	var_8_1[6] = 0

	for iter_8_0 = 1, 48 do
		for iter_8_1 = 1, 29 do
			local var_8_2 = arg_8_0.map[iter_8_1][iter_8_0]

			var_8_0 = var_8_0 .. var_8_2 .. "|"
			var_8_1[var_8_2] = var_8_1[var_8_2] + 1
		end

		var_8_0 = var_8_0 .. arg_8_0.map[30][iter_8_0] .. "\n"
		var_8_1[arg_8_0.map[30][iter_8_0]] = var_8_1[arg_8_0.map[30][iter_8_0]] + 1
	end

	local var_8_3 = var_8_0 .. "\n"

	for iter_8_2 = 0, 6 do
		var_8_3 = var_8_3 .. "color" .. iter_8_2 .. "    " .. tostring(var_8_1[iter_8_2]) .. "\n"
	end

	local var_8_4 = "resources/en_en/web/windows/anniversary4th/painting/output.lua"
	local var_8_5 = io.open(var_8_4, "w")

	var_8_5:write(var_8_3)
	var_8_5:close()
end

return var_0_0
