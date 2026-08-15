local var_0_0 = class("JunkChestSkillUpWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.cabinetSkillTable
local var_0_4 = import("app.common.ui.SplitLine")
local var_0_5 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.lev = arg_1_2.lev + 1
	arg_1_0.resType = arg_1_2.resType
	arg_1_0.resNum = arg_1_2.resNum
	arg_1_0.theId = arg_1_2.theId
	arg_1_0.skillPageId = arg_1_2.skillPageId
	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_title"):setString(var_0_2:translation("EVENT_CENTRE_TIP6"))

	for iter_3_0 = 1, 5 do
		arg_3_0:nodeByName("quest_container" .. iter_3_0):setVisible(false)
		arg_3_0:nodeByName("icon_node" .. iter_3_0):scale(0.8, 0.8)
	end

	for iter_3_1, iter_3_2 in pairs(arg_3_0.resType) do
		if iter_3_2 == xyd.currencyType.MAGIC_DUST then
			local var_3_0 = xyd.AssetLoader.get():loadSprite("images/icon/eco/magic_dust.png")

			arg_3_0:nodeByName("icon_node" .. iter_3_1):addChild(var_3_0)
		elseif iter_3_2 == xyd.currencyType.MAGIC_LIQUID then
			local var_3_1 = xyd.AssetLoader.get():loadSprite("images/icon/eco/magic_liquid.png")

			arg_3_0:nodeByName("icon_node" .. iter_3_1):addChild(var_3_1)
		elseif iter_3_2 == xyd.currencyType.MAGIC_ENERGY then
			local var_3_2 = xyd.AssetLoader.get():loadSprite("images/icon/eco/magic_energy.png")

			arg_3_0:nodeByName("icon_node" .. iter_3_1):addChild(var_3_2)
		elseif iter_3_2 == xyd.currencyType.MANA then
			local var_3_3 = xyd.AssetLoader.get():loadSprite("images/icon/eco/jinbi.png")

			arg_3_0:nodeByName("icon_node" .. iter_3_1):addChild(var_3_3)
		elseif iter_3_2 == -1 then
			local var_3_4 = xyd.SpriteLoader.new(var_0_5:icon(arg_3_0.skillPageId), nil, nil, xyd.DefaultImageType.ITEM_ICON)

			var_3_4:setScale(0.6, 0.6)

			arg_3_0.skillPageNum = arg_3_0.resNum[iter_3_1]

			arg_3_0:nodeByName("icon_node" .. iter_3_1):addChild(var_3_4)
		end

		arg_3_0:nodeByName("quest_container" .. iter_3_1):setVisible(true)
		arg_3_0:nodeByName("num_text" .. iter_3_1):setString(arg_3_0.resNum[iter_3_1])
	end

	arg_3_0:nodeByName("time_words"):setString(var_0_2:translation("COST_TIME"))
	arg_3_0:nodeByName("name_text"):setString(xyd.tables.cabinetSkillTable:name(arg_3_0.theId))
	arg_3_0:nodeByName("lev_text"):setString("Lv." .. arg_3_0.lev)

	local var_3_5 = 0
	local var_3_6 = 0
	local var_3_7 = xyd.tables.cabinetSkillTable:time(arg_3_0.theId)[arg_3_0.lev] - xyd.tables.cabinetTable:cutTime(arg_3_0.eventCentre.cabinetLev)

	if var_3_7 > 0 then
		var_3_5 = math.floor(var_3_7 / 3600)
		var_3_6 = math.floor(var_3_7 % 3600 / 60)
	end

	if var_3_6 == 0 then
		arg_3_0:nodeByName("time_text"):setString(var_3_5 .. var_0_2:translation("UNIT_HOUR"))
	elseif var_3_5 == 0 then
		arg_3_0:nodeByName("time_text"):setString(var_3_6 .. var_0_2:translation("UNIT_MINUTE"))
	else
		arg_3_0:nodeByName("time_text"):setString(var_3_5 .. var_0_2:translation("UNIT_HOUR") .. var_3_6 .. var_0_2:translation("UNIT_MINUTE"))
	end

	local var_3_8 = xyd.AssetLoader.get():loadSprite(var_0_3:icon(arg_3_0.theId))
	local var_3_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/junk_chest/skill_item.csb")
	local var_3_10 = cc.p(80, 80)

	var_3_9:setContentSize(var_3_10)

	local var_3_11 = var_3_9:getChildByName("icon")
	local var_3_12 = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

	var_3_12:setPosition(var_3_11:getWidth() / 2, var_3_11:getHeight() / 2)
	var_3_12:setAnchorPoint(cc.p(0.5, 0.5))
	var_3_12:scale(var_3_11:getWidth() / var_3_12:getWidth())

	local var_3_13 = cc.ClippingNode:create()

	var_3_13:setStencil(var_3_12)
	var_3_13:setInverted(true)
	var_3_13:setAlphaThreshold(0)
	var_3_11:addChild(var_3_13)
	var_3_13:addChild(var_3_8)
	var_3_8:align(display.LEFT_BOTTOM, 0, 0)
	var_3_8:scale((var_3_11:getWidth() - 3) / var_3_8:getWidth())
	var_3_9:scale(0.65, 0.65)
	var_3_9:addTo(arg_3_0:nodeByName("skill_icon"))
	var_3_9:setPosition(arg_3_0:nodeByName("skill_icon"):getWidth() / 2, arg_3_0:nodeByName("skill_icon"):getHeight() / 2)
	xyd.nodeEventSample(arg_3_0:nodeByName("btn_ok"), nil, function(arg_4_0)
		local var_4_0 = {
			skill_id = arg_3_0.theId
		}

		arg_3_0.eventCentre:learnSkill(var_4_0, function(arg_5_0, arg_5_1)
			if arg_5_0 == xyd.error.OK then
				if arg_3_0.eventCentre.curLearnSkill == 0 then
					arg_3_0.eventCentre:levUp(var_4_0.skill_id)

					local var_5_0 = xyd.WindowManager.get():getWindow("junk_chest")

					if var_5_0 then
						if var_5_0.isSelectHero then
							var_5_0:avatarUpdateLeft(var_5_0.selectHeroId)
						else
							var_5_0:updateBookList()
						end

						var_5_0:updateLeftContainer(3)
					end

					arg_3_0.eventCentre.recentCompleteSkill = arg_3_0.theId

					arg_3_0.eventCentre:confirmSkillUpgrade({}, function(arg_6_0, arg_6_1)
						if arg_6_0 == xyd.error.OK then
							return true
						end
					end)
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.REFRESH_MAGIC_RES
				})
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.LEARN_CABINET_SKILL,
					params = arg_3_0.theId
				})

				if arg_3_0.skillPageId and arg_3_0.skillPageNum then
					arg_3_0.backpack:removeItem({
						itemID = arg_3_0.skillPageId,
						itemNum = arg_3_0.skillPageNum
					})
				end

				xyd.WindowManager.get():closeWindow(arg_3_0)

				return true
			end
		end)
	end)
	var_0_4.new({
		size = 500
	}):addTo(arg_3_0:nodeByName("pos_line"))
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayer()
end

return var_0_0
