local var_0_0 = class("ArenaModeSelectLeadWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2.params
	arg_1_0.heros = arg_1_2.heros
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.isBegin = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("label_title"):setString(var_0_1:translation("ARENA_MODE_SELECT_LEAD_TITLE"))
	arg_2_0:nodeByName("label_tip"):setString(var_0_1:translation("ARENA_MODE_SELECT_LEAD_TIP"))

	local var_2_0 = arg_2_0:nodeByName("container_hero")

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.heros) do
		local var_2_1 = display.newNode()

		var_2_1:addTo(var_2_0)
		var_2_1:setContentSize(108, 108)
		var_2_1:setAnchorPoint(cc.p(0.5, 0.5))
		xyd.setAvatarBorderNewUI(iter_2_1, var_2_1)
		var_2_1:setPosition((iter_2_0 - 1) * 130 + 54, 54)
		var_2_1:setTouchEnabled(true)
		var_2_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
			if arg_3_0.name == "began" then
				var_2_1:setScale(0.9)

				return true
			elseif arg_3_0.name == "ended" then
				var_2_1:setScale(1)

				arg_2_0.isBegin = true
				arg_2_0.params.leader_id = iter_2_1:getHeroID()

				arg_2_0.callback(arg_2_0.params)
				xyd.WindowManager.get():closeWindow(arg_2_0)
			end
		end)
	end
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.willClose(arg_5_0)
	if not arg_5_0.isBegin then
		local var_5_0 = xyd.WindowManager.get():getWindow("arena_select_team")

		if var_5_0 and not tolua.isnull(var_5_0) then
			var_5_0.battleBegan = false
		end
	end
end

return var_0_0
