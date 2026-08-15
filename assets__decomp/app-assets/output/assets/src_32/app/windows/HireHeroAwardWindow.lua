local var_0_0 = class("HireHeroAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SplitLine")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.jiewanAward = arg_1_2.jiewanAward
	arg_1_0.shouyingAward = arg_1_2.shouyingAward
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("jiewan_txt"):setString(var_0_1:translation("BORROW_FEI"))
	arg_3_0:nodeByName("shouying_txt"):setString(var_0_1:translation("LIXI_FEI"))
	arg_3_0:nodeByName("title"):setString(var_0_1:translation("GET_COIN"))
	arg_3_0:nodeByName("jiewan_award"):setString(arg_3_0.jiewanAward)
	arg_3_0:nodeByName("shouying_award"):setString(arg_3_0.shouyingAward)

	local var_3_0 = var_0_2.new({
		size = 591
	})

	var_3_0:addTo(arg_3_0:nodeByName("line"))
	var_3_0:setAnchorPoint(0, 0.5)
	arg_3_0:nodeByName("confirm_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.WindowManager.get():getWindow("hire_hero")

			if var_4_0 and var_4_0.girlType == 1 then
				var_4_0.sentHeros = arg_3_0.guild:getSentHeros()
				var_4_0.rentPets = arg_3_0.guild:getRentPets()

				var_4_0:updateSentList()
				xyd.WindowManager.get():closeWindow(arg_3_0.name)
			else
				xyd.WindowManager.get():closeWindow(arg_3_0.name)
			end
		end

		return true
	end)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
