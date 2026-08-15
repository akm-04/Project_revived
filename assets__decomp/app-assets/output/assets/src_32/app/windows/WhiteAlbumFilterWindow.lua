local var_0_0 = class("WhiteAlbumFilterWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.attr
local var_0_3 = {
	4,
	5,
	6,
	7,
	8,
	9,
	10,
	11,
	12,
	14,
	15
}
local var_0_4 = import("app.common.ui.SplitLine")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.selected = arg_1_2.attrs
	arg_1_0.showCollected = arg_1_2.showCollected
	arg_1_0.showUncollected = arg_1_2.showUncollected
	arg_1_0.map = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("title"):setString(var_0_1:translation("WHITE_ALBUM_TXT14"))
	arg_2_0:nodeByName("lbl1"):setString(var_0_1:translation("WHITE_ALBUM_TXT15"))
	arg_2_0:nodeByName("lbl2"):setString(var_0_1:translation("WHITE_ALBUM_TXT16"))
	arg_2_0:nodeByName("txt_have"):setString(var_0_1:translation("WHITE_ALBUM_TXT17"))
	arg_2_0:nodeByName("txt_not"):setString(var_0_1:translation("WHITE_ALBUM_TXT18"))
	arg_2_0:nodeByName("txt_sure"):setString(var_0_1:translation("OK"))

	local var_2_0 = {
		size = 760,
		offset = 0,
		align = xyd.SplitLineAlign.CENTER
	}
	local var_2_1 = var_0_4.new(var_2_0)

	var_2_1:addTo(arg_2_0:nodeByName("container"))
	var_2_1:setPosition(407, 115)

	for iter_2_0 = 1, #arg_2_0.selected do
		arg_2_0.map[arg_2_0.selected[iter_2_0]] = true
	end

	for iter_2_1 = 1, #var_0_3 do
		local var_2_2 = var_0_3[iter_2_1]

		arg_2_0:nodeByName("attr" .. iter_2_1):setString(var_0_2:name(var_2_2))
		arg_2_0:nodeByName("box" .. iter_2_1):setSelected(arg_2_0.map[var_2_2])
	end

	arg_2_0:nodeByName("box_have"):setSelected(arg_2_0.showCollected)
	arg_2_0:nodeByName("box_not"):setSelected(arg_2_0.showUncollected)
	xyd.nodeEventSample(arg_2_0:nodeByName("btn_close"), nil, function()
		xyd.WindowManager.get():closeWindow(arg_2_0)
	end)
	xyd.addTouchEvent(arg_2_0:nodeByName("btn_sure"), function()
		local var_4_0 = {
			attrs = {},
			showCollected = arg_2_0:nodeByName("box_have"):isSelected(),
			showUncollected = arg_2_0:nodeByName("box_not"):isSelected()
		}

		for iter_4_0 = 1, #var_0_3 do
			if arg_2_0:nodeByName("box" .. iter_4_0):isSelected() then
				table.insert(var_4_0.attrs, var_0_3[iter_4_0])
			end
		end

		local var_4_1 = xyd.WindowManager.get():getWindow("white_album")

		if var_4_1 then
			var_4_1:onFilterReturn(var_4_0)
		end

		xyd.WindowManager.get():closeWindow(arg_2_0)
	end)
end

function var_0_0.didOpen(arg_5_0)
	arg_5_0:addBlockLayer()
end

return var_0_0
