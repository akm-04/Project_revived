local var_0_0 = class("FourthAnniPaintRandomVisitWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rankInfo = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("title"):setString(var_0_1:translation("FOURTH_ANNI_PAINT_TXT12"))
	xyd.nodeEventSample(arg_3_0:nodeByName("btn_close"), nil, function()
		xyd.playButtonSound()
		xyd.WindowManager.get():closeWindow(arg_3_0)
	end)

	for iter_3_0 = 1, #arg_3_0.rankInfo do
		local var_3_0 = arg_3_0.rankInfo[iter_3_0]
		local var_3_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th/painting/random_visit_item.csb")
		local var_3_2 = var_3_1:getChildByName("container")
		local var_3_3 = var_3_0.player_info

		xyd.setPlayerAvatar(var_3_2:getChildByName("icon_container"), var_3_3)

		if var_3_3.conquer_lev and var_3_3.conquer_lev > 0 then
			var_3_2:getChildByName("lev_txt"):setString(var_3_3.conquer_lev)
			var_3_2:getChildByName("lv_bg"):setVisible(false)

			local var_3_4 = xyd.getLoopBy(var_3_3.conquer_lev, var_3_3.conquer_loop_id)

			if var_3_4 < 2 then
				var_3_4 = ""
			end

			var_3_2:getChildByName("conquer_lev_bg"):setTexture("images/conquer_lev" .. var_3_4 .. ".png")
		else
			var_3_2:getChildByName("lev_txt"):setString(var_3_3.lev)
			var_3_2:getChildByName("conquer_lev_bg"):setVisible(false)
		end

		var_3_2:getChildByName("name_txt"):setString(var_3_3.player_name)
		var_3_2:getChildByName("vote_num"):setString(var_3_0.vote_num)
		var_3_2:getChildByName("vote_text"):setString(var_0_1:translation("FOURTH_ANNI_PAINT_TXT2"))
		var_3_2:getChildByName("region_txt"):setString("S" .. tostring(xyd.getPlayerRegion(var_3_0.player_id)))
		var_3_2:getChildByName("btn_visit"):getChildByName("visit_txt"):setString(var_0_1:translation("FOURTH_ANNI_PAINT_TXT3"))
		xyd.nodeEventSample(var_3_2:getChildByName("btn_visit"), nil, function()
			if var_3_0.not_show == 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("FOURTH_ANNI_PAINT_TXT14")
				})
			else
				xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_PAINT_VISIT, {
					visited_player = var_3_0.player_id
				}, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						local var_6_0 = {
							map = arg_6_1.map,
							info = var_3_0
						}

						xyd.WindowManager.get():openWindow("fourth_anni_paint_visit", var_6_0)
						xyd.WindowManager.get():closeWindow(arg_3_0)
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("FOURTH_ANNI_PAINT_TXT14")
						})
					end
				end)
			end
		end)
		var_3_1:addTo(arg_3_0:nodeByName("pos" .. iter_3_0))
		var_3_1:setAnchorPoint(cc.p(0, 0))
	end
end

return var_0_0
