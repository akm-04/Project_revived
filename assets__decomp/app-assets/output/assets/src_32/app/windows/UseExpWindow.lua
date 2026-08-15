local var_0_0 = class("UseExpWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.itemID = arg_1_2.itemID
	arg_1_0.exp = xyd.tables.item:exp(arg_1_0.itemID)
	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.totalNum = arg_1_0.player_:getBackpack():getItemNumByID(arg_1_0.itemID)
	arg_1_0.maxLev = xyd.tables.player:heroMaxLev(arg_1_0.player_.lev)
	arg_1_0.curHeroID = 0
	arg_1_0.curNum = 0
	arg_1_0.curHeroIdex = 0
	arg_1_0.expHero = 0
	arg_1_0.isUsed = false
	arg_1_0.items = {}
	arg_1_0.handler = {}
	arg_1_0.heros_ = clone(arg_1_0.player_.heros_)

	table.sort(arg_1_0.heros_, function(arg_2_0, arg_2_1)
		if arg_2_0:canSummon() and not arg_2_1:canSummon() then
			return true
		elseif arg_2_1:canSummon() and not arg_2_0:canSummon() then
			return false
		end

		return xyd.heroNormalSort(arg_2_0, arg_2_1) or false
	end)
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("hero_list")

	arg_4_0.heroListWidth = var_4_0:getContentSize().width
	arg_4_0.heroListHeight = var_4_0:getContentSize().height
	arg_4_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 800, 390),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_4_0):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0:nodeByName("txt_desc"):setString(string.format(var_0_2:translation("USE_EXP_ITEM"), xyd.tables.item:name(arg_4_0.itemID)))
	arg_4_0.heroList_:setDelegate(handler(arg_4_0, arg_4_0.heroDelegate))
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevX_ = arg_5_1.x
	elseif arg_5_1.name == "moved" and 1 <= math.abs(arg_5_1.x - arg_5_0.prevX_) then
		arg_5_0.scrollViewMoved_ = true
	end
end

function var_0_0.heroDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return (math.ceil(#arg_6_0.heros_ / var_0_3))
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0 = arg_6_0.heroList_:dequeueItem()

		if not var_6_0 then
			var_6_0 = arg_6_0.heroList_:newItem()
		else
			var_6_0:removeAllChildren(true)
		end

		local var_6_1 = 800
		local var_6_2 = 160

		var_6_0:setItemSize(var_6_1, 130)

		local var_6_3 = display.newNode()

		var_6_3:setContentSize(var_6_1, 130)

		for iter_6_0 = 1, var_0_3 do
			local var_6_4 = import("app.windows.UseExpItem").new()
			local var_6_5 = (arg_6_3 - 1) * var_0_3 + iter_6_0

			if var_6_5 > #arg_6_0.heros_ then
				break
			end

			var_6_4:setParams(arg_6_0.heros_[var_6_5])
			var_6_3:addChild(var_6_4)
			var_6_4:setPosition(400 * iter_6_0 - 400 + 10, 0)
			var_6_4:setAnchorPoint(cc.p(0.5, 0.5))
			var_6_4:ignoreAnchorPointForPosition(false)
			var_6_4:setTouchEnabled(true)
			var_6_4:setTouchSwallowEnabled(false)
			var_6_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
				local var_7_0 = 0
				local var_7_1 = false

				local function var_7_2()
					var_7_0 = var_7_0 + 0.03

					if var_6_4.hero == nil then
						return
					end

					if var_6_4.hero:getExp() >= xyd.tables.partnerExp:totalExp(arg_6_0.maxLev) then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("EXP_FULL")
						})

						return
					end

					if arg_6_0.curNum < arg_6_0.totalNum then
						if arg_6_0.curHeroID == 0 then
							arg_6_0.curHeroID = var_6_4.hero.heroID_
						end

						if arg_6_0.curHeroIdex == 0 then
							arg_6_0.curHeroIdex = var_6_5
						end

						if arg_6_0.expHero == 0 then
							arg_6_0.expHero = var_6_4.hero
						end

						if arg_6_0.curHeroID ~= var_6_4.hero.heroID_ then
							if arg_6_0.curNum > 0 then
								var_6_4:setTouchEnabled(false)
								arg_6_0.player_:addPartnerExp({
									item_id = arg_6_0.itemID,
									partner_id = arg_6_0.curHeroID,
									item_num = arg_6_0.curNum,
									total_num = arg_6_0.player_:getBackpack():getItemNumByID(arg_6_0.itemID)
								}, function(arg_9_0, arg_9_1, arg_9_2)
									if not tolua.isnull(var_6_4) then
										var_6_4:setTouchEnabled(true)
									end

									local var_9_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

									if arg_9_0 == xyd.error.OK then
										if arg_6_0.expHero ~= 0 then
											if arg_9_2.item_id then
												local var_9_1 = arg_9_2.item_id
												local var_9_2 = arg_9_2.partner_exp
												local var_9_3 = arg_9_2.total_num

												var_9_0:getBackpack():setItemNumByID(var_9_1, var_9_3)

												local var_9_4 = xyd.tables.player:heroMaxLev(arg_6_0.player_.lev)

												var_9_0:getHeroByID(arg_6_0.expHero:getHeroID()):setExp(var_9_2, var_9_4)
											else
												var_9_0:getHeroByID(arg_6_0.expHero:getHeroID()).exp_ = arg_6_0.expHero.exp_
												var_9_0:getHeroByID(arg_6_0.expHero:getHeroID()).level_ = arg_6_0.expHero.level_
												arg_6_0.totalNum = var_9_0:getBackpack():getItemNumByID(arg_6_0.itemID)

												local var_9_5 = xyd.WindowManager.get():getWindow("backpack")

												if var_9_5 then
													var_9_5:updateItemDetail(arg_6_0.itemID)
													var_9_5:refreshDisplayOption()
												end

												arg_6_0.curHeroIdex = var_6_5
												arg_6_0.expHero = var_6_4.hero
											end
										end
									else
										arg_6_0.expHero = var_9_0:getHeroByID(arg_6_0.expHero:getHeroID())
									end
								end)
							end

							arg_6_0.curHeroID = var_6_4.hero.heroID_
							arg_6_0.curNum = 1
						else
							arg_6_0.curNum = arg_6_0.curNum + 1
						end

						var_6_4.hero:addExp(arg_6_0.exp, arg_6_0.maxLev)
						var_6_4:updateExp(arg_6_0.curNum)
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("EXP_ITEM_ABSENCE")
						})
					end
				end

				local function var_7_3()
					var_7_0 = var_7_0 + 0.1

					if var_6_4.hero == nil then
						return
					end

					if var_7_0 > 0.5 and var_7_0 <= 4 and (not arg_6_0.scrollViewMoved_ or var_7_1 == true) then
						var_7_1 = true

						if var_6_4.hero:getExp() >= xyd.tables.partnerExp:totalExp(arg_6_0.maxLev) then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("EXP_FULL")
							})

							return
						end

						if arg_6_0.curNum < arg_6_0.totalNum then
							if arg_6_0.curHeroID == 0 then
								arg_6_0.curHeroID = var_6_4.hero.heroID_
							end

							if arg_6_0.curHeroIdex == 0 then
								arg_6_0.curHeroIdex = var_6_5
							end

							if arg_6_0.expHero == 0 then
								arg_6_0.expHero = var_6_4.hero
							end

							if arg_6_0.curHeroID ~= var_6_4.hero.heroID_ then
								if arg_6_0.curNum > 0 then
									var_6_4:setTouchEnabled(false)
									arg_6_0.player_:addPartnerExp({
										item_id = arg_6_0.itemID,
										partner_id = arg_6_0.curHeroID,
										item_num = arg_6_0.curNum,
										total_num = arg_6_0.player_:getBackpack():getItemNumByID(arg_6_0.itemID)
									}, function(arg_11_0, arg_11_1, arg_11_2)
										if not tolua.isnull(var_6_4) then
											var_6_4:setTouchEnabled(true)
										end

										if arg_11_0 == xyd.error.OK then
											if arg_11_2.item_id then
												local var_11_0 = arg_11_2.item_id
												local var_11_1 = arg_11_2.partner_exp
												local var_11_2 = arg_11_2.total_num

												arg_6_0.player_:getBackpack():setItemNumByID(var_11_0, var_11_2)

												local var_11_3 = xyd.tables.player:heroMaxLev(arg_6_0.player_.lev)

												arg_6_0.player_:getHeroByID(arg_6_0.expHero:getHeroID()):setExp(var_11_1, var_11_3)
											else
												arg_6_0.player_:getHeroByID(arg_6_0.expHero:getHeroID()).exp_ = arg_6_0.expHero.exp_
												arg_6_0.player_:getHeroByID(arg_6_0.expHero:getHeroID()).level_ = arg_6_0.expHero.level_
												arg_6_0.totalNum = arg_6_0.player_:getBackpack():getItemNumByID(arg_6_0.itemID)

												local var_11_4 = xyd.WindowManager.get():getWindow("backpack")

												if var_11_4 then
													var_11_4:updateItemDetail(arg_6_0.itemID)
													var_11_4:refreshDisplayOption()
												end

												arg_6_0.curHeroIdex = var_6_5
												arg_6_0.expHero = var_6_4.hero
											end
										else
											arg_6_0.expHero = arg_6_0.player_:getHeroByID(arg_6_0.expHero:getHeroID())
										end
									end)
								end

								arg_6_0.curHeroID = var_6_4.hero.heroID_
								arg_6_0.curNum = 1
							else
								arg_6_0.curNum = arg_6_0.curNum + 1
							end

							var_6_4.hero:addExp(arg_6_0.exp, arg_6_0.maxLev)
							var_6_4:updateExp(arg_6_0.curNum)
						else
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("EXP_ITEM_ABSENCE")
							})
						end
					elseif var_7_0 > 4 and var_7_1 == true then
						arg_6_0.handler[2] = var_0_1.scheduleGlobal(var_7_2, 0.03)

						var_0_1.unscheduleGlobal(arg_6_0.handler[1])
					end
				end

				if arg_7_0.name == "began" then
					arg_6_0.handler[1] = var_0_1.scheduleGlobal(var_7_3, 0.1)

					return true
				elseif arg_7_0.name == "ended" then
					if arg_6_0.handler[1] ~= nil then
						var_0_1.unscheduleGlobal(arg_6_0.handler[1])
					end

					if arg_6_0.handler[2] ~= nil then
						var_0_1.unscheduleGlobal(arg_6_0.handler[2])
					end

					if not arg_6_0.scrollViewMoved_ then
						local var_7_4 = xyd.tables.sound:getSound("train_exp_up")

						audio.playSound(var_7_4, false)
						var_7_2()
					end

					var_7_0 = 0
				end
			end)
		end

		var_6_0:addContent(var_6_3)

		return var_6_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_6_2 then
		-- block empty
	end
end

function var_0_0.didOpen(arg_12_0)
	arg_12_0:addBlockLayer(nil, true)
	arg_12_0.heroList_:reload()
end

function var_0_0.willClose(arg_13_0)
	if arg_13_0.handler[1] ~= nil then
		var_0_1.unscheduleGlobal(arg_13_0.handler[1])
	end

	if arg_13_0.handler[2] ~= nil then
		var_0_1.unscheduleGlobal(arg_13_0.handler[2])
	end

	if arg_13_0.curNum > 0 then
		local var_13_0 = arg_13_0.player_
		local var_13_1 = arg_13_0.expHero
		local var_13_2 = arg_13_0.itemID
		local var_13_3 = arg_13_0.curHeroIdex

		arg_13_0.player_:addPartnerExp({
			item_id = arg_13_0.itemID,
			partner_id = arg_13_0.curHeroID,
			item_num = arg_13_0.curNum,
			total_num = arg_13_0.player_:getBackpack():getItemNumByID(arg_13_0.itemID)
		}, function(arg_14_0, arg_14_1, arg_14_2)
			if arg_14_0 == xyd.error.OK then
				if arg_14_2.item_id then
					local var_14_0 = arg_14_2.item_id
					local var_14_1 = arg_14_2.partner_exp
					local var_14_2 = arg_14_2.total_num

					var_13_0:getBackpack():setItemNumByID(var_14_0, var_14_2)

					local var_14_3 = xyd.tables.player:heroMaxLev(var_13_0.lev)

					var_13_0:getHeroByID(var_13_1:getHeroID()):setExp(var_14_1, var_14_3)
				else
					var_13_0:getHeroByID(var_13_1:getHeroID()).exp_ = var_13_1.exp_
					var_13_0:getHeroByID(var_13_1:getHeroID()).level_ = var_13_1.level_

					var_13_0:getBackpack():getItemNumByID(var_13_2)

					local var_14_4 = xyd.WindowManager.get():getWindow("backpack")

					if var_14_4 then
						var_14_4:updateItemDetail(var_13_2)
						var_14_4:refreshDisplayOption()
					end
				end
			end
		end)
	end
end

return var_0_0
