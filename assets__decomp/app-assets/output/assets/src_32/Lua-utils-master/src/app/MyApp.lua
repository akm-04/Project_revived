require("config")
require("cocos.init")
require("framework.init")

local var_0_0 = require("framework.AppBase")
local var_0_1 = class("MyApp", var_0_0)

function var_0_1.ctor(arg_1_0)
	var_0_1.super.ctor(arg_1_0)
end

function var_0_1.run(arg_2_0)
	cc.FileUtils:getInstance():addSearchPath("res/")
	arg_2_0:enterScene("MainScene")
end

return var_0_1
