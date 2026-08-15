local var_0_0 = class("JigsawDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SplitLine")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.shop = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.jigInfo = arg_1_2.jigInfo
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("title_txt"):setString(var_0_1:translation("JIGSAW_DETAIL_TEXT"))
	arg_3_0:nodeByName("conditon_text"):setString(var_0_1:translation("GET_CONDITION"))
	arg_3_0:nodeByName("progress_text"):setString(var_0_1:translation("GET_PROGRESS"))

	local var_3_0 = xyd.tables.ActivityJigsaw:desc(arg_3_0.jigInfo.jigsaw_id)

	arg_3_0:nodeByName("conditon_desc"):setString(var_3_0)

	if arg_3_0:isGotten() == true then
		arg_3_0:nodeByName("progress_txt"):setString(var_0_1:translation("HAD_GOTTEN"))
	else
		arg_3_0:nodeByName("progress_txt"):setString(arg_3_0.jigInfo.count .. "/" .. xyd.tables.ActivityJigsaw:amount(arg_3_0.jigInfo.jigsaw_id))
	end

	local var_3_1 = "windows/jigsaw/" .. "big_" .. arg_3_0.jigInfo.jigsaw_id .. ".png"
	local var_3_2 = xyd.AssetLoader.get():loadSprite(var_3_1)

	if not arg_3_0:isGotten() then
		var_3_2:runActionOnce(cc.TintBy:create(0, -100, -100, -100))
	end

	var_3_2:addTo(arg_3_0:nodeByName("graph_pos"))
	var_3_2:setPosition(cc.p(0, 10))
	var_3_2:setScale(0.7)

	local var_3_3 = var_0_2.new({
		size = 500
	})

	var_3_3:addTo(arg_3_0:nodeByName("contianer"))
	var_3_3:setAnchorPoint(0.5, 0.5)
	var_3_3:setPosition(cc.p(355, 90))

	local var_3_4 = arg_3_0:nodeByName("go_btn")

	var_3_4:getChildByName("txt"):setString(var_0_1:translation("BUTTON_NAME_GO"))
	var_3_4:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(var_3_4, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.tables.ActivityJigsaw:type(arg_3_0.jigInfo.jigsaw_id)

			if (var_4_0 == xyd.JigsawGetType.ARENA_SHOP or var_4_0 == xyd.JigsawGetType.ARENA) and arg_3_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ARENA) ~= true then
				if xyd.WindowManager.get():isWindowOpen("toast") then
					xyd.WindowManager.get():closeWindow("toast")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("FUNCTION_OPEN_TIP_OTHER")
				})

				return
			end

			if var_4_0 == xyd.JigsawGetType.GASHAPON then
				arg_3_0.activities:loadActivities(function(arg_5_0)
					if arg_5_0 == xyd.error.OK then
						activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

						if activities:isActivityOpen(xyd.Activities.GaCha) then
							local var_5_0 = {
								default_table_id = xyd.Activities.GaCha
							}

							xyd.WindowManager.get():openWindow("activities", var_5_0)
							arg_3_0:closeJigSawWindows()
						else
							if xyd.WindowManager.get():isWindowOpen("toast") then
								xyd.WindowManager.get():closeWindow("toast")
							end

							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ACTIVITY_UNRECHABLE")
							})
						end

						return
					end
				end)
			elseif var_4_0 == xyd.JigsawGetType.ARENA_SHOP then
				arg_3_0.shop:loadShopList({}, function()
					xyd.WindowManager.get():openWindow("shop", {
						shop_type = xyd.ShopType.ARENA
					})
					arg_3_0:closeJigSawWindows()
				end)
			elseif var_4_0 == xyd.JigsawGetType.ARENA then
				arg_3_0:goToArena()
			elseif var_4_0 == xyd.JigsawGetType.DAILY_MISSION then
				arg_3_0.task:loadTaskByType(xyd.TaskType.DAILY, function(arg_7_0)
					if arg_7_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("task")
					end
				end)
				arg_3_0:closeJigSawWindows()
			elseif var_4_0 == xyd.JigsawGetType.SUMMON then
				arg_3_0.selfPlayer:loadSummonInfo(nil, function()
					xyd.WindowManager.get():openWindow("summon")

					if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_SUMMON_FREE_TWO then
						arg_3_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_SUMMON)
					end

					arg_3_0:closeJigSawWindows()
				end, true)
			end
		end
	end)
end

function var_0_0.isGotten(arg_9_0)
	if arg_9_0.jigInfo.is_put == 1 or arg_9_0.jigInfo.count >= xyd.tables.ActivityJigsaw:amount(arg_9_0.jigInfo.jigsaw_id) then
		return true
	else
		return false
	end
end

function var_0_0.closeJigSawWindows(arg_10_0)
	if xyd.WindowManager.get():isWindowOpen("jigsaw") then
		xyd.WindowManager.get():closeWindow("jigsaw")
	end

	xyd.WindowManager.get():closeWindow(arg_10_0)
end

function var_0_0.goToArena(arg_11_0)
	local var_11_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	xyd.Backend.get():request(xyd.mid.LOAD_ARENA_FIGHT_RECORDS, {}, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			local var_12_0 = arg_12_1.records
			local var_12_1 = {}

			for iter_12_0, iter_12_1 in ipairs(var_12_0) do
				if iter_12_1.report_key then
					table.insert(var_12_1, iter_12_1.report_key)
				end
			end

			if var_12_1 and next(var_12_1) then
				xyd.db.arenaReportKeys:deleteAllReportKeys(var_11_0.playerID)

				for iter_12_2, iter_12_3 in ipairs(var_12_1) do
					xyd.db.arenaReportKeys:setArenaReportKeys(var_11_0.playerID, iter_12_3)
				end
			end
		end
	end)
	xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):loadArenaInfo(function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			xyd.WindowManager.get():openWindow("sub_arena")
			arg_11_0:closeJigSawWindows()
		end
	end)
end

function var_0_0.didOpen(arg_14_0, arg_14_1)
	arg_14_0:addBlockLayer()
end

return var_0_0
