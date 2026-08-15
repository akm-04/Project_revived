local var_0_0 = class("MemoriesOfSchoolFinalRewardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("framework.scheduler")
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = xyd.tables.item
local var_0_6 = xyd.tables.hero
local var_0_7 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
local var_0_8 = xyd.ModelManager.get():loadModel(xyd.ModelType.MEMORIES_OF_SCHOOL)
local var_0_9 = 30
local var_0_10 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.gridPos = arg_1_2.grid_pos
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("tips_txt"):setString(var_0_1:translation("MEMORIES_OF_SCHOOL_TIPS4"))
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("MEMORIES_OF_SCHOOL_TIPS11"))

	for iter_4_0 = 1, 3 do
		arg_4_0:nodeByName("final_icon_" .. iter_4_0):setTouchEnabled(true)
		arg_4_0:nodeByName("final_icon_open_" .. iter_4_0):setVisible(false)
		arg_4_0:nodeByName("final_icon_" .. iter_4_0):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "began" then
				-- block empty
			elseif arg_5_0.name == "ended" then
				math.randomseed(os.time())
				math.random(3)

				local var_5_0 = xyd.tables.misc.memoriesOfSchoolPassBox[math.random(3)]

				var_0_8:getFinalAward({
					grid_pos = arg_4_0.gridPos,
					award_id = var_5_0
				}, function(arg_6_0, arg_6_1)
					var_0_7:handleRewards(arg_6_1.awards, function()
						if xyd.WindowManager.get():getWindow("memories_of_school_final_reward") then
							xyd.WindowManager.get():closeWindow("memories_of_school_final_reward")
						end

						if xyd.WindowManager.get():getWindow("memories_of_school") then
							xyd.WindowManager.get():closeWindow("memories_of_school")
						end

						if xyd.WindowManager.get():getWindow("memories_of_school_main") then
							xyd.WindowManager.get():getWindow("memories_of_school_main"):updateWindow(var_0_8:getLocalParams())
						end
					end)
				end)
			end

			return true
		end)
	end

	arg_4_0:nodeByName("tips_txt"):setString(var_0_1:translation("MAZE_PASS_CHOOSE"))
end

return var_0_0
