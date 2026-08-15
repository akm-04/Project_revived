local var_0_0 = class("JunkChestPieceDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = import("app.windows.GainWayItem")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.bookId = arg_1_2.bookId
	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.maxSuperCampaign = arg_1_0.selfPlayer.super_campaign_id
	arg_1_0.maxNormalCampaign = arg_1_0.selfPlayer.normal_campaign_id
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 20 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.listView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("list"):getWidth(), arg_3_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.listView_:setBounceable(true)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("BACKPACK_TEXT_1"))
	arg_4_0:addTitle(var_0_1:translation("RELATED_HEROS"))

	local var_4_0 = math.ceil(#xyd.tables.cabinetBookTable:relevantHero(arg_4_0.bookId) / 4)

	for iter_4_0 = 1, var_4_0 do
		local var_4_1 = display.newNode()
		local var_4_2 = arg_4_0.listView_:newItem()

		for iter_4_1 = 1, 4 do
			local var_4_3 = (iter_4_0 - 1) * 4 + iter_4_1

			if var_4_3 > #xyd.tables.cabinetBookTable:relevantHero(arg_4_0.bookId) then
				break
			end

			local var_4_4 = arg_4_0:creatAvatar(xyd.tables.cabinetBookTable:relevantHero(arg_4_0.bookId)[var_4_3])

			var_4_1:addChild(var_4_4)
			var_4_4:setPosition(iter_4_1 * 150 - 70, 0)
		end

		var_4_1:setContentSize(760, 140)
		var_4_2:setItemSize(760, 150)
		var_4_2:addContent(var_4_1)
		arg_4_0.listView_:addItem(var_4_2)
	end

	arg_4_0:addTitle(var_0_1:translation("ITEM_DETAIL_GAIN_WAY"))

	local var_4_5 = arg_4_0.listView_:newItem()

	display.newNode():setAnchorPoint(cc.p(0, 1))
	arg_4_0:creatWayContent(xyd.tables.cabinetBookTable:piece(arg_4_0.bookId))
	arg_4_0.listView_:reload()
end

function var_0_0.creatAvatar(arg_5_0, arg_5_1)
	local var_5_0 = display.newNode()
	local var_5_1 = arg_5_0.listView_:newItem()
	local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/pet_room/select_pet_item.csb")

	var_5_2:getChildByName("container"):getChildByName("txt_name"):setString(xyd.tables.item:name(arg_5_1))

	local var_5_3 = arg_5_0.selfPlayer:getHeroIgnoreAwaken(arg_5_1)

	if var_5_3 then
		xyd.setAvatarBorderNewUI(var_5_3:getTableID(), var_5_2:getChildByName("container"):getChildByName("pet"), var_5_3:getColor(), var_5_3:getStar())
	else
		xyd.setAvatarBorderNewUI(arg_5_1, var_5_2:getChildByName("container"):getChildByName("pet"), 1, xyd.tables.hero:initialStar(arg_5_1))
	end

	var_5_2:setPosition(55, 70)
	var_5_2:addTo(var_5_0)
	var_5_0:setContentSize(110, 140)

	return var_5_0
end

function var_0_0.creatWayContent(arg_6_0, arg_6_1)
	local var_6_0 = var_0_2:map(arg_6_1)

	if var_0_2:isAwakenPiece(arg_6_1) == 1 and type(var_6_0) == "table" then
		local var_6_1 = var_6_0[1]

		for iter_6_0 = 1, #var_6_0 do
			local var_6_2 = 0

			if arg_6_0.selfPlayer.worldMaps_[var_6_0[iter_6_0]] then
				var_6_2 = arg_6_0.selfPlayer.worldMaps_[var_6_0[iter_6_0]].star or 0
			end

			if var_6_1 <= var_6_0[iter_6_0] and var_6_2 == 3 then
				var_6_1 = var_6_0[iter_6_0]
			end
		end

		var_6_0 = {
			var_6_1
		}
	end

	for iter_6_1 = #var_6_0, 1, -1 do
		if var_6_0[iter_6_1] == 0 then
			table.remove(var_6_0, iter_6_1)
		end
	end

	for iter_6_2 = 1, #var_6_0 do
		local var_6_3 = display.newNode()
		local var_6_4 = arg_6_0.listView_:newItem()
		local var_6_5 = var_0_3.new()
		local var_6_6 = xyd.tables.campaign:relateCampaign(var_6_0[iter_6_2])
		local var_6_7 = xyd.tables.campaign:campaignType(var_6_0[iter_6_2])
		local var_6_8

		if var_6_7 - 1 == xyd.CampaignType.SUPER then
			var_6_8 = xyd.tables.campaign:icon(var_6_6)
		else
			var_6_8 = xyd.tables.campaign:icon(var_6_0[iter_6_2])
		end

		if not var_6_8 then
			return
		end

		local var_6_9 = {
			campaignName = xyd.tables.campaign:campaignName(var_6_0[iter_6_2]),
			chapter = xyd.tables.campaign:chapter(var_6_0[iter_6_2]),
			icon = var_6_8,
			campaignType = var_6_7,
			campaignID = var_6_0[iter_6_2]
		}

		var_6_9.nodeSize = 694

		if var_6_7 == xyd.CampaignType.PET and xyd.tables.campaign:getFloorType(var_6_0[iter_6_2]) == 2 then
			var_6_9.petFloor = xyd.tables.campaign:getFloor(var_6_0[iter_6_2])
		end

		var_6_5:setParams(var_6_9)
		var_6_5:setPosition(170, 0)
		var_6_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_6_5:ignoreAnchorPointForPosition(false)
		var_6_5:addTo(var_6_3)
		var_6_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "began" then
				var_6_5.contentView_:nodeByName("gain_way_node"):setScale(0.9)
			end

			if arg_7_0.name == "moved" and arg_6_0.scrollViewMoved_ then
				var_6_5.contentView_:nodeByName("gain_way_node"):setScale(1)
			end

			if arg_7_0.name == "ended" and not arg_6_0.scrollViewMoved_ then
				var_6_5.contentView_:nodeByName("gain_way_node"):setScale(1)

				if var_6_7 == 3 and arg_6_0.maxSuperCampaign >= var_6_0[iter_6_2] or var_6_7 == 2 and arg_6_0.maxNormalCampaign >= var_6_0[iter_6_2] or arg_6_0.selfPlayer.worldMaps_[var_6_0[iter_6_2]] then
					arg_6_0.guild:loadGuildMap(function(arg_8_0)
						local var_8_0 = {
							isStoneCampaign = true,
							chapter = xyd.tables.campaign:chapter(var_6_0[iter_6_2]),
							campaignID = var_6_0[iter_6_2],
							campaignType = xyd.tables.campaign:campaignType(var_6_0[iter_6_2]),
							itemComposeID = itemID
						}

						if var_8_0.campaignType == 2 then
							var_8_0.campaignType = 1
						elseif var_8_0.campaignType == 3 then
							var_8_0.campaignType = 2
						elseif var_8_0.campaignType == 24 then
							var_8_0.campaignType = 24
						end

						xyd.WindowManager.get():openWindow("map_window", var_8_0)
					end)
				elseif var_6_7 == xyd.CampaignType.PET then
					if xyd.WindowManager.get():getWindow("pet_campaign") then
						xyd.WindowManager.get():closeWindow("pet_campaign")
					end

					local var_7_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)

					var_7_0:getCampaignInfo(function(arg_9_0)
						if arg_9_0 == xyd.error.OK then
							var_7_0:setStateBaseOnCampaignID(var_6_0[iter_6_2])

							if var_7_0.openSuper then
								xyd.WindowManager.get():openWindow("pet_campaign", {
									now_floor = var_6_9.petFloor
								})
							else
								xyd.WindowManager.get():openWindow("pet_campaign")
							end
						end
					end)
				elseif var_6_7 == xyd.CampaignType.CLOUD_LADDER or var_6_7 == xyd.CampaignType.CLOUD_ROAD or var_6_7 == xyd.CampaignType.CLOUD_TEMPLE then
					if arg_6_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_CLOUD_CITY) == true then
						xyd.WindowManager.get():openWindow("cloud_city")
					end
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("CHAPTER_NOT_AVAILABLE")
					})
				end
			end

			return true
		end)
		var_6_4:addContent(var_6_3)
		var_6_3:setContentSize(760, 117)
		var_6_4:setItemSize(760, 122)
		arg_6_0.listView_:addItem(var_6_4)
	end
end

function var_0_0.addTitle(arg_10_0, arg_10_1)
	local var_10_0 = display.newNode()
	local var_10_1 = arg_10_0.listView_:newItem()
	local var_10_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/junk_chest/piece_title.csb")

	var_10_2:getChildByName("container"):getChildByName("text_1"):setString(arg_10_1)
	var_10_2:getChildByName("container"):getChildByName("text_1"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_10_2:setPosition(0, 0)
	var_10_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_10_2:addTo(var_10_0)
	var_10_1:addContent(var_10_0)
	var_10_0:setContentSize(760, 50)
	var_10_1:setItemSize(760, 70)
	arg_10_0.listView_:addItem(var_10_1)
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)
	arg_11_0:addBlockLayer()
end

return var_0_0
