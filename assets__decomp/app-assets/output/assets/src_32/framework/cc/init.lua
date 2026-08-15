local var_0_0 = ...

cc.Registry = import(".Registry")
cc.GameObject = import(".GameObject")
cc.EventProxy = import(".EventProxy")
cc.Component = import(".components.Component")

local var_0_1 = {
	"components.behavior.StateMachine",
	"components.behavior.EventProtocol",
	"components.ui.BasicLayoutProtocol",
	"components.ui.LayoutProtocol",
	"components.ui.DraggableProtocol"
}

for iter_0_0, iter_0_1 in ipairs(var_0_1) do
	cc.Registry.add(import("." .. iter_0_1, var_0_0), iter_0_1)
end

local var_0_2 = cc.GameObject
local var_0_3 = {
	__call = function(arg_1_0, arg_1_1)
		if arg_1_1 then
			return var_0_2.extend(arg_1_1)
		end

		printError("cc() - invalid target")
	end
}

setmetatable(cc, var_0_3)

cc.mvc = import(".mvc.init")
cc.ui = import(".ui.init")
cc.uiloader = import(".uiloader.init")
