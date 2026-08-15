local var_0_0 = class("ItemDetailItemBg", function()
	return cc.Node:create()
end)
local var_0_1 = 10
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.imgBg = arg_2_0.contentView_:nodeByName("bg")
	arg_2_0.list = arg_2_0.contentView_:nodeByName("list")
	arg_2_0.desc = arg_2_0.contentView_:nodeByName("desc")

	arg_2_0.desc:setVisible(false)

	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_2_0.getWayTable = xyd.tables.heroGetWayTable
	arg_2_0.maxNormalCampaign = arg_2_0.player_.normal_campaign_id
	arg_2_0.maxSuperChapter = arg_2_0.player_.super_chapter_id
	arg_2_0.campaignNum = 0
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.itemID = arg_3_1.itemID
	arg_3_0.detailType = arg_3_1.detailType
	arg_3_0.isChestPiece = arg_3_1.isChestPiece

	arg_3_0:layout()
	arg_3_0:setTouchSwallowEnabled(false)
	arg_3_0:setTouchEnabled(true)
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = xyd.tables.item:canCompose(arg_4_0.itemID)
	local var_4_1 = xyd.tables.item:hero(arg_4_0.itemID)
	local var_4_2 = xyd.tables.item:map(arg_4_0.itemID)
	local var_4_3 = xyd.tables.item:gainType(arg_4_0.itemID)
	local var_4_4 = {}
	local var_4_5 = {}
	local var_4_6 = {
		var_4_4,
		var_4_5
	}

	if arg_4_0.isChestPiece then
		var_4_4 = var_4_2
	else
		for iter_4_0 = 1, #var_4_2 do
			local var_4_7 = xyd.tables.campaign:campaignType(var_4_2[iter_4_0])

			if xyd.tables.item:type(arg_4_0.itemID) ~= xyd.ItemType.STONE and var_4_7 - 1 ~= xyd.CampaignType.SUPER then
				table.insert(var_4_4, var_4_2[iter_4_0])
			else
				table.insert(var_4_4, var_4_2[iter_4_0])
			end
		end

		for iter_4_1 = 1, #var_4_3 do
			id = var_4_3[iter_4_1]

			if id ~= 0 then
				table.insert(var_4_5, var_4_3[iter_4_1])
			end
		end
	end

	arg_4_0.imgBg:setVisible(false)

	local var_4_8 = {}

	if arg_4_0.detailType == xyd.ItemDetailType.EQUIPMENT then
		var_4_8 = var_4_0
	elseif arg_4_0.detailType == xyd.ItemDetailType.HERO then
		var_4_8 = var_4_1
	elseif arg_4_0.detailType == xyd.ItemDetailType.CAMPAIGN then
		var_4_8 = var_4_4

		arg_4_0.imgBg:setVisible(false)

		if #var_4_8 == 1 and var_4_8[1] == 0 then
			local var_4_9 = xyd.tables.item:gainType(arg_4_0.itemID)[1]

			if var_4_9 ~= 0 then
				arg_4_0.desc:setVisible(true)
				arg_4_0.desc:setString(xyd.tables.gainTypeDesc:desc(var_4_9))
			end
		end
	elseif arg_4_0.detailType == xyd.ItemDetailType.MAKE then
		var_4_8 = {
			true
		}

		arg_4_0.imgBg:setVisible(false)
	end

	local var_4_10 = {}
	local var_4_11 = var_4_5
	local var_4_12 = import("app.windows.ItemDetailItemNode").new()
	local var_4_13 = var_4_12.contentView_:getHeight() - 10
	local var_4_14 = var_4_12.contentView_:getWidth() + 5

	if arg_4_0.isChestPiece then
		var_4_14 = var_4_14 + 40
		var_0_1 = -35
	end

	for iter_4_2 = 1, #var_4_8 do
		if var_4_8[iter_4_2] ~= 0 and arg_4_0.detailType == xyd.ItemDetailType.CAMPAIGN then
			arg_4_0.campaignNum = arg_4_0.campaignNum + 1
		end
	end

	for iter_4_3 = 1, #var_4_8 do
		if var_4_8[iter_4_3] ~= 0 then
			local var_4_15 = import("app.windows.ItemDetailItemNode").new()
			local var_4_16 = {}

			if arg_4_0.detailType == xyd.ItemDetailType.EQUIPMENT then
				var_4_16.itemID = var_4_8[iter_4_3]
			elseif arg_4_0.detailType == xyd.ItemDetailType.HERO then
				var_4_16.heroID = var_4_8[iter_4_3]
				var_4_16.quality = 1
			elseif arg_4_0.detailType == xyd.ItemDetailType.CAMPAIGN then
				var_4_16.campaignName = xyd.tables.campaign:campaignName(var_4_8[iter_4_3])
				var_4_16.chapter = xyd.tables.campaign:chapter(var_4_8[iter_4_3])

				if xyd.tables.item:type(arg_4_0.itemID) == xyd.ItemType.PET_STONE or xyd.tables.item:type(arg_4_0.itemID) == xyd.ItemType.PET_EQUIP then
					var_4_16.chapter = 1
				end

				local var_4_17 = xyd.tables.campaign:relateCampaign(var_4_2[iter_4_3])
				local var_4_18 = xyd.tables.campaign:campaignType(var_4_2[iter_4_3])

				if var_4_18 - 1 == xyd.CampaignType.SUPER then
					var_4_16.campaignIcon = xyd.tables.campaign:icon(var_4_17)
				else
					var_4_16.campaignIcon = xyd.tables.campaign:icon(var_4_2[iter_4_3])
				end

				var_4_16.campaignType = var_4_18

				if var_4_18 == xyd.CampaignType.PET and xyd.tables.campaign:getFloorType(var_4_2[iter_4_3]) == 2 then
					var_4_16.petFloor = xyd.tables.campaign:getFloor(var_4_2[iter_4_3])
				end

				var_4_15:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
					if arg_5_0.name == "began" then
						var_4_15.contentView_:setScale(0.9)

						var_4_15.scrollViewMoved_ = false
						arg_4_0.preY = arg_5_0.y
					end

					if arg_5_0.name == "moved" then
						var_4_15.contentView_:setScale(1)

						if math.abs(arg_4_0.preY - arg_5_0.y) > 20 then
							var_4_15.scrollViewMoved_ = true
						end
					end

					if arg_5_0.name == "ended" and not var_4_15.scrollViewMoved_ then
						var_4_15.contentView_:setScale(1)

						var_4_15.scrollViewMoved_ = false

						if var_4_18 == xyd.CampaignType.PET then
							if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):isFuncOpen(xyd.FunctionID.ID_PET) == true then
								if xyd.WindowManager.get():getWindow("pet_campaign") then
									xyd.WindowManager.get():closeWindow("pet_campaign")
								end

								local var_5_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)

								var_5_0:getCampaignInfo(function(arg_6_0)
									if arg_6_0 == xyd.error.OK then
										var_5_0:setStateBaseOnCampaignID(var_4_2[iter_4_3])

										if var_5_0.openSuper then
											xyd.WindowManager.get():openWindow("pet_campaign", {
												now_floor = var_4_16.petFloor
											})
										else
											xyd.WindowManager.get():openWindow("pet_campaign")
										end
									end
								end)
							else
								local var_5_1 = xyd.tables.functionOpen
								local var_5_2 = string.format(var_0_2:translation("FUNCTION_OPEN_TIP_LEVEL"), var_5_1:level(xyd.FunctionID.ID_PET))

								xyd.WindowManager.get():openWindow("toast", {
									message = var_5_2
								})
							end
						elseif var_4_18 == xyd.CampaignType.CLOUD_LADDER or var_4_18 == xyd.CampaignType.CLOUD_ROAD or var_4_18 == xyd.CampaignType.CLOUD_TEMPLE then
							if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):isFuncOpen(xyd.FunctionID.ID_CLOUD_CITY) == true then
								xyd.WindowManager.get():openWindow("cloud_city")
							end
						elseif arg_4_0.maxSuperChapter >= xyd.tables.campaign:chapter(var_4_8[iter_4_3]) then
							arg_4_0.guild:loadGuildMap(function(arg_7_0)
								if arg_7_0 == xyd.error.OK then
									local var_7_0 = {}

									var_7_0.isStoneCampaign = true
									var_7_0.chapter = xyd.tables.campaign:chapter(var_4_8[iter_4_3])
									var_7_0.campaignID = var_4_2[iter_4_3]
									var_7_0.campaignType = xyd.tables.campaign:campaignType(var_4_2[iter_4_3]) - 1

									xyd.WindowManager.get():openWindow("map_window", var_7_0)
								else
									local var_7_1 = {
										isStoneCampaign = true,
										chapter = xyd.tables.campaign:chapter(var_4_8[iter_4_3]),
										campaignID = var_4_2[iter_4_3],
										campaignType = xyd.tables.campaign:campaignType(var_4_2[iter_4_3]) - 1
									}

									xyd.WindowManager.get():openWindow("map_window", var_7_1)
								end
							end)
						else
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("CHAPTER_NOT_AVAILABLE")
							})
						end
					end

					return true
				end)
			elseif arg_4_0.detailType == xyd.ItemDetailType.MAKE then
				var_4_16.isInscription = true
				var_4_16.campaignIcon = "windows/inscription/inscription_icon.png"

				var_4_15:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
					if arg_8_0.name == "began" then
						var_4_15.contentView_:setScale(0.9)

						var_4_15.scrollViewMoved_ = false
						arg_4_0.preY = arg_8_0.y
					end

					if arg_8_0.name == "moved" then
						var_4_15.contentView_:setScale(1)

						if math.abs(arg_4_0.preY - arg_8_0.y) > 20 then
							var_4_15.scrollViewMoved_ = true
						end
					end

					if arg_8_0.name == "ended" and not var_4_15.scrollViewMoved_ then
						var_4_15.contentView_:setScale(1)

						var_4_15.scrollViewMoved_ = false

						if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):isFuncOpen(xyd.FunctionID.ID_INSCRIPTION) then
							xyd.WindowManager.get():openWindow("inscription")
						else
							local var_8_0 = xyd.tables.functionOpen:tip(xyd.FunctionID.ID_INSCRIPTION)

							xyd.WindowManager.get():openWindow("toast", {
								message = var_8_0
							})
						end
					end

					return true
				end)
			end

			var_4_15:setParams(var_4_16)
			var_4_15:setAnchorPoint(cc.p(0.5, 0.5))
			var_4_15:ignoreAnchorPointForPosition(false)

			local var_4_19 = #var_4_8 - arg_4_0.campaignNum
			local var_4_20 = 0

			if var_4_19 < iter_4_3 then
				if (iter_4_3 - var_4_19) % 2 == 0 then
					var_4_20 = 1
				end

				var_4_15:setPosition(var_0_1 + (iter_4_3 + 1) % 2 * (var_4_14 + var_0_1) + var_4_14 / 2, (math.ceil(#var_4_8 / 2) + math.ceil(#var_4_11 / 2) - math.ceil(iter_4_3 / 2)) * var_4_13 + var_4_13 / 2 - (iter_4_3 - var_4_19 - var_4_20) / 2 * 25)
			else
				var_4_15:setPosition(var_0_1 + (iter_4_3 + 1) % 2 * (var_4_14 + var_0_1) + var_4_14 / 2, (math.ceil(#var_4_8 / 2) + math.ceil(#var_4_11 / 2) - math.ceil(iter_4_3 / 2)) * var_4_13 + var_4_13 / 2)
			end

			var_4_15:setTouchEnabled(true)
			var_4_15:setTouchSwallowEnabled(false)
			arg_4_0.list:addChild(var_4_15)
		end
	end

	for iter_4_4 = 1, #var_4_11 do
		if (arg_4_0.detailType == xyd.ItemDetailType.EQUIPMENT or arg_4_0.detailType == xyd.ItemDetailType.HERO or arg_4_0.detailType == xyd.ItemDetailType.CAMPAIGN or arg_4_0.detailType == xyd.ItemDetailType.MAKE) and var_4_11[iter_4_4] ~= 0 then
			local var_4_21 = var_4_11[iter_4_4]
			local var_4_22 = import("app.windows.ItemDetailItemNode").new()
			local var_4_23 = {
				getWayID = var_4_21
			}

			var_4_22:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
				if arg_9_0.name == "began" then
					var_4_22.contentView_:setScale(0.9)

					var_4_22.scrollViewMoved_ = false
					arg_4_0.preY = arg_9_0.y
				end

				if arg_9_0.name == "moved" then
					var_4_22.contentView_:setScale(1)

					if math.abs(arg_4_0.preY - arg_9_0.y) > 20 then
						var_4_22.scrollViewMoved_ = true
					end
				end

				if arg_9_0.name == "ended" and not var_4_22.scrollViewMoved_ then
					var_4_22.contentView_:setScale(1)

					var_4_22.scrollViewMoved_ = false

					xyd.navigateToHeroGetWay(var_4_21)
				end

				return true
			end)
			var_4_22:setParams(var_4_23)
			var_4_22:setAnchorPoint(cc.p(0.5, 0.5))
			var_4_22:ignoreAnchorPointForPosition(false)

			local var_4_24 = 0

			if iter_4_4 % 2 == 0 then
				var_4_24 = 1
			end

			local var_4_25 = #var_4_8 - arg_4_0.campaignNum

			if #var_4_8 == arg_4_0.campaignNum then
				var_4_22:setPosition(var_0_1 + (iter_4_4 + 1) % 2 * (var_4_14 + var_0_1) + var_4_14 / 2, (math.ceil(#var_4_11 / 2) - math.ceil(iter_4_4 / 2)) * var_4_13 + var_4_13 / 2 - arg_4_0.campaignNum / 2 * 25 - ((iter_4_4 - var_4_24) / 2 + 1) * 25 + 20)
			else
				var_4_22:setPosition(var_0_1 + (iter_4_4 + 1) % 2 * (var_4_14 + var_0_1) + var_4_14 / 2, (math.ceil(#var_4_8 / 2) + math.ceil(#var_4_11 / 2) - math.ceil(iter_4_4 / 2)) * var_4_13 + var_4_13 / 2 - (iter_4_4 - var_4_25 - var_4_24) / 2 * 25)
			end

			var_4_22:setTouchEnabled(true)
			var_4_22:setTouchSwallowEnabled(false)
			arg_4_0.list:addChild(var_4_22)
		end
	end

	local var_4_26 = math.ceil(#var_4_8 / 2) + math.ceil(#var_4_11 / 2)
	local var_4_27 = #var_4_8 / 2 - arg_4_0.campaignNum

	if var_4_26 > 0 and var_4_8[1] ~= 0 then
		arg_4_0.list:setContentSize(cc.size(var_4_14, var_4_26 * var_4_13))

		local var_4_28 = var_4_26 * var_4_13

		arg_4_0.imgBg:height(var_4_28 + 20)
	elseif var_4_26 > 0 and var_4_11[1] ~= 0 then
		arg_4_0.list:setContentSize(cc.size(var_4_14, var_4_26 * var_4_13))

		local var_4_29 = var_4_26 * var_4_13

		arg_4_0.imgBg:height(var_4_29 + 20)
	end
end

function var_0_0.contentView(arg_10_0)
	if arg_10_0.contentView_ == nil then
		arg_10_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_10_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/backpack_window/item_detail_item_bg.csb"))
		arg_10_0.contentView_:addTo(arg_10_0)
		arg_10_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_10_0.contentView_
end

return var_0_0
