local var_0_0 = cc
local var_0_1 = {}

function makeUIControl_(arg_1_0)
	cc(arg_1_0)
	arg_1_0:addComponent("components.ui.LayoutProtocol"):exportMethods()
	arg_1_0:addComponent("components.behavior.EventProtocol"):exportMethods()
	arg_1_0:setCascadeOpacityEnabled(true)
	arg_1_0:setCascadeColorEnabled(true)
	arg_1_0:addNodeEventListener(var_0_0.NODE_EVENT, function(arg_2_0)
		if arg_2_0.name == "cleanup" then
			arg_1_0:removeAllEventListeners()
		end
	end)
end

var_0_1.TEXT_ALIGN_LEFT = cc.TEXT_ALIGNMENT_LEFT
var_0_1.TEXT_ALIGN_CENTER = cc.TEXT_ALIGNMENT_CENTER
var_0_1.TEXT_ALIGN_RIGHT = cc.TEXT_ALIGNMENT_RIGHT
var_0_1.TEXT_VALIGN_TOP = cc.VERTICAL_TEXT_ALIGNMENT_TOP
var_0_1.TEXT_VALIGN_CENTER = cc.VERTICAL_TEXT_ALIGNMENT_CENTER
var_0_1.TEXT_VALIGN_BOTTOM = cc.VERTICAL_TEXT_ALIGNMENT_BOTTOM
var_0_1.UIGroup = import(".UIGroup")
var_0_1.UIImage = import(".UIImage")
var_0_1.UIPushButton = import(".UIPushButton")
var_0_1.UICheckBoxButton = import(".UICheckBoxButton")
var_0_1.UICheckBoxButtonGroup = import(".UICheckBoxButtonGroup")
var_0_1.UIInput = import(".UIInput")
var_0_1.UILabel = import(".UILabel")
var_0_1.UISlider = import(".UISlider")
var_0_1.UIBoxLayout = import(".UIBoxLayout")
var_0_1.UIScrollView = import(".UIScrollView")
var_0_1.UIListView = import(".UIListView")
var_0_1.UIPageView = import(".UIPageView")
var_0_1.UILoadingBar = import(".UILoadingBar")
var_0_1.UITableView = import(".UITableView")

return var_0_1
