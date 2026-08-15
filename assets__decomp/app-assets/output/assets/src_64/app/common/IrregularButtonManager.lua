local var_0_0 = class("IrregularButtonManager")
local var_0_1 = xyd.IrregularButton
local var_0_2 = {
	"images/map_1",
	"images/map_2",
	"images/map_3",
	"images/map_4",
	"images/map_5",
	"images/map_6",
	"images/map_7",
	"images/map_8",
	"images/map_9",
	"images/dungeon"
}

function var_0_0.get()
	if var_0_0.INSTANCE == nil then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

function var_0_0.ctor(arg_2_0)
	arg_2_0.buttons_ = {}

	for iter_2_0, iter_2_1 in ipairs(var_0_2) do
		arg_2_0:addButton(iter_2_1)
	end
end

function var_0_0.addButton(arg_3_0, arg_3_1)
	local var_3_0 = xyd.AssetLoader.get():loadButton(arg_3_1, var_0_1, nil)

	var_3_0:retain()
	print("IrregularButtonManage retain " .. tostring(var_3_0))

	arg_3_0.buttons_[arg_3_1] = var_3_0
end

function var_0_0.release(arg_4_0)
	for iter_4_0, iter_4_1 in pairs(arg_4_0.buttons_) do
		iter_4_1:release()
		print("IrregularButtonManage release " .. tostring(iter_4_1))
	end
end

return var_0_0
