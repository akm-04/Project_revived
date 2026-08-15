local var_0_0 = class("WndTopSidebar", import("app.common.ui.BaseWidget"))
local var_0_1 = import("app.common.ui.EcoSidebar")
local var_0_2 = import("app.common.ui.EcoDisplaySidebar")
local var_0_3 = import("app.common.ui.SpriteNodeButton")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.colorMode = arg_1_2.colorMode or xyd.ColorMode.BLUE
	arg_1_0.title = arg_1_2.title
	arg_1_0.parent = arg_1_2.parent
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.showRule = arg_1_2.show_rule
	arg_1_0.isEcoBar = arg_1_2.isEcoBar or 1
	arg_1_0.ecoBarType = arg_1_2.ecoBarType or xyd.EcoSidebarType.MAIN
	arg_1_0.ecoIcons = arg_1_2.ecoIcons
	arg_1_0.ecoCount = arg_1_2.ecoCount or 3
	arg_1_0.ecoTypes = arg_1_2.ecoTypes or {}
	arg_1_0.ecoIcons = arg_1_2.ecoIcons or {}
	arg_1_0.ecoIsAdd = arg_1_2.ecoIsAdd or {}
	arg_1_0.ecoScale = arg_1_2.ecoScale or {}
	arg_1_0.ecoAddCallback = arg_1_2.ecoAddCallback or {}

	arg_1_0:init()
	arg_1_0:onRegister()
end

function var_0_0.init(arg_2_0)
	if arg_2_0.isEcoBar == 1 then
		if arg_2_0.ecoBarType == xyd.EcoSidebarType.MAIN then
			local var_2_0 = {
				colorMode = arg_2_0.colorMode
			}
			local var_2_1 = var_0_1.new(xyd.WidgetName.ecoSidebar, var_2_0)

			var_2_1:addTo(arg_2_0:nodeByName("eco_sidebar"))
			var_2_1:setAnchorPoint(0, 0)
			var_2_1:setPosition(0, 0)
			var_2_1:setName("eco_sidebar")

			arg_2_0.children_.eco_sidebar = var_2_1
		elseif arg_2_0.ecoBarType == xyd.EcoSidebarType.DISPLAY then
			local var_2_2 = {
				colorMode = arg_2_0.colorMode,
				ecoCount = arg_2_0.ecoCount,
				ecoTypes = arg_2_0.ecoTypes,
				ecoIcons = arg_2_0.ecoIcons,
				ecoIsAdd = arg_2_0.ecoIsAdd,
				ecoScale = arg_2_0.ecoScale,
				ecoAddCallback = arg_2_0.ecoAddCallback
			}
			local var_2_3 = var_0_2.new(xyd.WidgetName.ecoDisplaySidebar, var_2_2)

			var_2_3:addTo(arg_2_0:nodeByName("eco_sidebar"))
			var_2_3:setAnchorPoint(0, 0)
			var_2_3:setPosition(-120, 0)
			var_2_3:setName("eco_sidebar")

			arg_2_0.children_.eco_sidebar = var_2_3
		end
	end

	local var_2_4 = var_0_3.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(arg_2_0.colorMode)
	})

	var_2_4:addTo(arg_2_0:nodeByName("background"))
	var_2_4:setAnchorPoint(0.5, 0.5)
	var_2_4:setPosition(arg_2_0:nodeByName("pos_btn_return"):getPosition())
	var_2_4:setName("return_btn")

	arg_2_0.children_.return_btn = var_2_4

	local var_2_5 = arg_2_0:nodeByName("txt_title")

	if arg_2_0.showRule then
		arg_2_0:nodeByName("rule"):setVisible(true)
		arg_2_0:nodeByName("rule"):setTouchEnabled(true)
		var_2_5:setPositionX(var_2_5:getPositionX() - 13)

		if #arg_2_0.title > 12 then
			var_2_5:setFontSize(28)
		end
	end

	var_2_5:setString(arg_2_0.title)
end

function var_0_0.onRegister(arg_3_0)
	arg_3_0:registerCommon()
	arg_3_0:registerButton()
end

function var_0_0.registerCommon(arg_4_0)
	return
end

function var_0_0.registerButton(arg_5_0)
	arg_5_0:nodeByName("return_btn"):addTouchEvent(function(arg_6_0)
		if arg_6_0.name == "ended" then
			xyd.playCloseSound()

			if arg_5_0.callback then
				arg_5_0.callback()
			elseif arg_5_0.parent and arg_5_0.parent.close then
				arg_5_0.parent:close()
			end
		end
	end)
end

function var_0_0.update(arg_7_0)
	return
end

return var_0_0
