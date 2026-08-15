local var_0_0 = class("HunqiCombWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.spiritSuit
local var_0_3 = xyd.tables.spirit
local var_0_4 = xyd.tables.spiritEquip
local var_0_5 = xyd.tables.attr
local var_0_6 = xyd.tables.misc:getValue("spirit_program_limit")
local var_0_7 = {
	xyd.AttributeType.HP,
	xyd.AttributeType.BAOJI_RATE,
	xyd.AttributeType.AD,
	xyd.AttributeType.BAOJIHARM,
	xyd.AttributeType.AP,
	xyd.AttributeType.ZHUANGTAI_MINGZHONG,
	xyd.AttributeType.HUJIA,
	xyd.AttributeType.ZHUANGTAI_KANGXING,
	xyd.AttributeType.MOKANG,
	xyd.AttributeType.HUNQI_HP_BONUS,
	xyd.AttributeType.HUNQI_AD_AP_BONUS,
	xyd.AttributeType.HUNQI_JIAKANG_BONUS
}
local var_0_8 = {
	[xyd.AttributeType.HP] = var_0_1:translation("HUNQI_TEXT_55"),
	[xyd.AttributeType.BAOJI_RATE] = var_0_1:translation("HUNQI_TEXT_56"),
	[xyd.AttributeType.AD] = var_0_1:translation("HUNQI_TEXT_57"),
	[xyd.AttributeType.BAOJIHARM] = var_0_1:translation("HUNQI_TEXT_58"),
	[xyd.AttributeType.AP] = var_0_1:translation("HUNQI_TEXT_59"),
	[xyd.AttributeType.ZHUANGTAI_MINGZHONG] = var_0_1:translation("HUNQI_TEXT_60"),
	[xyd.AttributeType.HUJIA] = var_0_1:translation("HUNQI_TEXT_61"),
	[xyd.AttributeType.ZHUANGTAI_KANGXING] = var_0_1:translation("HUNQI_TEXT_62"),
	[xyd.AttributeType.MOKANG] = var_0_1:translation("HUNQI_TEXT_63")
}
local var_0_9 = {
	AD = 5,
	HUJIA = 7,
	HP = 4,
	LEV = 1,
	ZHUANGTAI_KANGXING = 11,
	AP = 6,
	BAOJIHARM = 10,
	BAOJI_RATE = 9,
	HUNQI_HP_BONUS = 13,
	QUALITY = 2,
	MOKANG = 8,
	ZHUANGTAI_MINGZHONG = 12,
	GET_TIME = 3,
	HUNQI_JIAKANG_BONUS = 15,
	DEFAULT = 16,
	HUNQI_AD_AP_BONUS = 14
}
local var_0_10 = {
	var_0_1:translation("HUNQI_TEXT_21"),
	var_0_1:translation("HUNQI_TEXT_22"),
	var_0_1:translation("HUNQI_TEXT_23"),
	var_0_5:name(xyd.AttributeType.HP),
	var_0_5:name(xyd.AttributeType.AD),
	var_0_5:name(xyd.AttributeType.AP),
	var_0_5:name(xyd.AttributeType.HUJIA),
	var_0_5:name(xyd.AttributeType.MOKANG),
	var_0_5:name(xyd.AttributeType.BAOJI_RATE),
	var_0_5:name(xyd.AttributeType.BAOJIHARM),
	var_0_5:name(xyd.AttributeType.ZHUANGTAI_KANGXING),
	var_0_5:name(xyd.AttributeType.ZHUANGTAI_MINGZHONG),
	var_0_5:name(xyd.AttributeType.HUNQI_HP_BONUS),
	var_0_5:name(xyd.AttributeType.HUNQI_AD_AP_BONUS),
	var_0_5:name(xyd.AttributeType.HUNQI_JIAKANG_BONUS),
	var_0_1:translation("HUNQI_TEXT_50")
}
local var_0_11 = {
	NOW_EQUIP = 2,
	COMB_LIST = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.infos = arg_1_2.infos or {}
	arg_1_0.idx = 1
	arg_1_0.equipIdx = 1
	arg_1_0.posState = 1
	arg_1_0.sortTypePos = var_0_9.DEFAULT

	arg_1_0:initDatas()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.initDatas(arg_4_0)
	local var_4_0 = true

	arg_4_0.data = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.infos) do
		local var_4_1 = iter_4_1.collocation

		if var_4_0 and arg_4_0:isNowEquips(var_4_1) then
			var_4_0 = false

			arg_4_0:addData(var_4_1, var_0_11.COMB_LIST, true, iter_4_1.id, iter_4_1.name)
		else
			arg_4_0:addData(var_4_1, var_0_11.COMB_LIST, false, iter_4_1.id, iter_4_1.name)
		end
	end

	if var_4_0 then
		arg_4_0:addData(arg_4_0.hero:getSpiritEquips(), var_0_11.NOW_EQUIP, true, 0)
	end
end

function var_0_0.addData(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	local var_5_0, var_5_1 = arg_5_0:getCombAttr(arg_5_1)
	local var_5_2, var_5_3 = arg_5_0:getAttrShowNum(var_5_0, var_5_1)
	local var_5_4 = {
		equips = arg_5_1,
		attrs = var_5_0,
		bonusAttr = var_5_1,
		showNum = var_5_2,
		num = var_5_3,
		type_ = arg_5_2,
		id = arg_5_4,
		name = arg_5_5
	}

	if arg_5_3 then
		table.insert(arg_5_0.data, 1, var_5_4)
	else
		table.insert(arg_5_0.data, var_5_4)
	end
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("list"):getContentSize()

	arg_6_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_0.width, var_6_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_6_0:nodeByName("list")):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.list:setDelegate(handler(arg_6_0, arg_6_0.delegate))
	arg_6_0.list:reload()
	arg_6_0:nodeByName("txt_sort"):setString(var_0_10[arg_6_0.sortTypePos])
	arg_6_0:setText()
	arg_6_0:setBtns()
	arg_6_0:setSelectEquipNode(arg_6_0.posState)
	arg_6_0:updateHero()
	arg_6_0:updateBtnShow()
end

function var_0_0.setText(arg_7_0)
	arg_7_0:nodeByName("txt_hero_name"):enableOutline(cc.c4b(59, 59, 94, 255), 2)
	arg_7_0:nodeByName("txt_save"):enableOutline(cc.c4b(141, 153, 204, 255), 2)
	arg_7_0:nodeByName("txt_delete"):enableOutline(cc.c4b(141, 153, 204, 255), 2)
	arg_7_0:nodeByName("txt_editor"):enableOutline(cc.c4b(141, 153, 204, 255), 2)
	arg_7_0:nodeByName("txt_equip"):enableOutline(cc.c4b(141, 153, 204, 255), 2)
	arg_7_0:nodeByName("txt_new"):setString(var_0_1:translation("HUNQI_TEXT_49"))
	arg_7_0:nodeByName("txt_save"):setString(var_0_1:translation("HUNQI_TEXT_51"))
	arg_7_0:nodeByName("txt_delete"):setString(var_0_1:translation("HUNQI_TEXT_52"))
	arg_7_0:nodeByName("txt_editor"):setString(var_0_1:translation("HUNQI_TEXT_53"))
	arg_7_0:nodeByName("txt_equip"):setString(var_0_1:translation("HUNQI_TEXT_54"))
	arg_7_0:nodeByName("txt_skill"):getVirtualRenderer():setLineHeight(22)
end

function var_0_0.setBtns(arg_8_0)
	for iter_8_0 = 1, 6 do
		local var_8_0 = display.newNode()

		var_8_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_0:setContentSize(110, 110)
		var_8_0:setTouchEnabled(true)
		var_8_0:setTouchSwallowEnabled(true)
		var_8_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			if arg_9_0.name == "ended" then
				xyd.playButtonSound()

				if arg_8_0.posState ~= iter_8_0 then
					arg_8_0.posState = iter_8_0

					arg_8_0:setSelectEquipNode(iter_8_0)
				end

				local var_9_0 = arg_8_0.data[arg_8_0.idx].equips

				if var_9_0[iter_8_0] ~= 0 then
					arg_8_0:performWithDelay(function()
						local var_10_0 = arg_8_0.backpack:getSpiritItemBySpiritID(var_9_0[iter_8_0])
						local var_10_1 = {}

						var_10_1.showActive = true

						local var_10_2 = {
							hero = arg_8_0.hero,
							item1 = var_10_0,
							itemParams1 = var_10_1
						}
						local var_10_3 = xyd.WindowManager.get():openWindow("hunqi_detail", var_10_2)

						if iter_8_0 < 4 then
							var_10_3:setPosition(940, xyd.STAGE_HEIGHT - var_10_3:getTipHeight() - 80)
						else
							var_10_3:setPosition(620, xyd.STAGE_HEIGHT - var_10_3:getTipHeight() - 80)
						end
					end, 0.03333333333333333)
				end
			end

			return true
		end)
		var_8_0:addTo(arg_8_0:nodeByName("node_item_" .. iter_8_0))
	end

	xyd.nodeEventSample(arg_8_0:nodeByName("btn_sort"), {
		scale = 1
	}, function()
		xyd.playButtonSound()

		local var_11_0 = {}

		table.insert(var_11_0, var_0_9.HP)
		table.insert(var_11_0, var_0_9.AD)
		table.insert(var_11_0, var_0_9.AP)
		table.insert(var_11_0, var_0_9.HUJIA)
		table.insert(var_11_0, var_0_9.MOKANG)
		table.insert(var_11_0, var_0_9.BAOJI_RATE)
		table.insert(var_11_0, var_0_9.BAOJIHARM)
		table.insert(var_11_0, var_0_9.ZHUANGTAI_KANGXING)
		table.insert(var_11_0, var_0_9.ZHUANGTAI_MINGZHONG)

		local var_11_1 = {
			colNum = 2,
			types = var_11_0,
			callback = handler(arg_8_0, arg_8_0.sortList)
		}
		local var_11_2 = xyd.WindowManager.get():openWindow("hunqi_sort_type", var_11_1)

		var_11_2:setPosition(400, 570 - var_11_2:getTipHeight())
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("btn_new"), nil, function()
		xyd.playButtonSound()

		local var_12_0 = {
			callback = handler(arg_8_0, arg_8_0.onEditorComb),
			data = arg_8_0.data
		}

		xyd.WindowManager.get():openWindow("hunqi_comb_editor", var_12_0)
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("btn_save"), nil, function()
		local var_13_0 = 0

		for iter_13_0, iter_13_1 in ipairs(arg_8_0.data) do
			if iter_13_1.type_ == var_0_11.COMB_LIST then
				var_13_0 = var_13_0 + 1
			end
		end

		if var_13_0 >= var_0_6 then
			local var_13_1 = var_0_1:translation("HUNQI_TEXT_64")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_13_1
			})

			return
		end

		local var_13_2 = arg_8_0.data[arg_8_0.equipIdx].equips
		local var_13_3 = table.concat(var_13_2, "|")

		if var_13_3 == "0|0|0|0|0|0" then
			local var_13_4 = var_0_1:translation("HUNQI_TEXT_65")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_13_4
			})

			return
		end

		local var_13_5 = {
			data = arg_8_0.data,
			callback = function(arg_14_0)
				local var_14_0 = {
					name = arg_14_0,
					collocation = var_13_3
				}

				xyd.Backend.get():request(xyd.mid.HUNQI_SAVE_COLLOCATION, var_14_0, function(arg_15_0, arg_15_1)
					if arg_15_0 == xyd.error.OK then
						for iter_15_0, iter_15_1 in ipairs(var_13_2) do
							if iter_15_1 > 0 then
								arg_8_0.backpack:addSpiritColloCount(iter_15_1, 1)
							end
						end

						arg_8_0:onEditorComb(var_13_2, arg_14_0, arg_15_1.id)
					end
				end)
			end
		}

		xyd.WindowManager.get():openWindow("hunqi_comb_input_name", var_13_5)
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("btn_editor"), nil, function()
		xyd.playButtonSound()

		local var_16_0 = {
			callback = handler(arg_8_0, arg_8_0.onEditorComb),
			idx = arg_8_0.idx,
			equips = arg_8_0.data[arg_8_0.idx].equips,
			name = arg_8_0.data[arg_8_0.idx].name,
			data = arg_8_0.data
		}

		xyd.WindowManager.get():openWindow("hunqi_comb_editor", var_16_0)
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("btn_equip"), nil, function()
		if arg_8_0.idx == arg_8_0.equipIdx then
			local var_17_0 = var_0_1:translation("HUNQI_TEXT_66")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_17_0
			})

			return
		end

		local var_17_1 = arg_8_0.data[arg_8_0.idx].equips
		local var_17_2 = {}

		for iter_17_0, iter_17_1 in ipairs(var_17_1) do
			if iter_17_1 > 0 then
				local var_17_3 = arg_8_0.backpack:getSpiritItemBySpiritID(iter_17_1)

				if var_17_3.is_equip > 0 and var_17_3.is_equip ~= arg_8_0.hero:getHeroID() then
					table.insert(var_17_2, var_17_3)
				end
			end
		end

		local function var_17_4()
			local var_18_0 = {
				id = arg_8_0.data[arg_8_0.idx].id,
				partner_id = arg_8_0.hero:getHeroID()
			}

			xyd.Backend.get():request(xyd.mid.APPLY_COLLOCATION, var_18_0, function(arg_19_0, arg_19_1)
				if arg_19_0 == xyd.error.OK then
					local var_19_0 = arg_8_0.hero:getSpiritEquips()

					for iter_19_0, iter_19_1 in ipairs(var_19_0) do
						if iter_19_1 > 0 then
							arg_8_0.backpack:setSpiritItem(iter_19_1, {
								is_equip = 0
							})
						end
					end

					local var_19_1 = {}

					for iter_19_2, iter_19_3 in ipairs(arg_8_0.data[arg_8_0.idx].equips) do
						if iter_19_3 > 0 then
							local var_19_2 = arg_8_0.backpack:getSpiritItemBySpiritID(iter_19_3)

							if var_19_2.is_equip > 0 then
								var_19_1[var_19_2.is_equip] = var_19_1[var_19_2.is_equip] or {}

								table.insert(var_19_1[var_19_2.is_equip], iter_19_2)
							end

							arg_8_0.backpack:setSpiritItem(iter_19_3, {
								is_equip = arg_8_0.hero:getHeroID()
							})
						end
					end

					if next(var_19_1) then
						for iter_19_4, iter_19_5 in pairs(var_19_1) do
							local var_19_3 = arg_8_0.selfPlayer:getHeroByID(iter_19_4)
							local var_19_4 = clone(var_19_3:getSpiritEquips())

							for iter_19_6, iter_19_7 in ipairs(iter_19_5) do
								var_19_4[iter_19_7] = 0
							end

							var_19_3:setSpiritEquips(var_19_4)
						end
					end

					arg_8_0.hero:setSpiritEquips(arg_8_0.data[arg_8_0.idx].equips)
					arg_8_0:initDatas()

					arg_8_0.equipIdx = 1
					arg_8_0.idx = 1

					if arg_8_0.sortTypePos == var_0_9.DEFAULT then
						arg_8_0.list:refreshList(0)
					else
						arg_8_0:sortList(arg_8_0.sortTypePos)
					end

					arg_8_0:updateItemNode()
					arg_8_0:updateBtnShow()

					local var_19_5 = xyd.WindowManager.get():getWindow("hero_main")

					if var_19_5 and not tolua.isnull(var_19_5) then
						var_19_5:updateAttrScore()
						var_19_5:updateAttrLabels()
					end

					local var_19_6 = xyd.WindowManager.get():getWindow("hunqi")

					if var_19_6 then
						var_19_6:updateAllItems()
					end
				end
			end)
		end

		if next(var_17_2) then
			local var_17_5 = {
				items = var_17_2,
				callback = var_17_4
			}

			xyd.WindowManager.get():openWindow("hunqi_comb_confirm", var_17_5)
		else
			var_17_4()
		end
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("btn_delete"), nil, function()
		local var_20_0 = var_0_1:translation("HUNQI_TEXT_67")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_20_0, function()
			local var_21_0 = {
				id = arg_8_0.data[arg_8_0.idx].id
			}

			xyd.Backend.get():request(xyd.mid.DEL_COLLOCATION, var_21_0, function(arg_22_0, arg_22_1)
				if arg_22_0 == xyd.error.OK then
					for iter_22_0, iter_22_1 in ipairs(arg_8_0.infos) do
						if iter_22_1.id == var_21_0.id then
							for iter_22_2, iter_22_3 in ipairs(iter_22_1.collocation) do
								arg_8_0.backpack:addSpiritColloCount(iter_22_3, -1)
							end

							table.remove(arg_8_0.infos, iter_22_0)

							break
						end
					end

					arg_8_0:initDatas()

					arg_8_0.equipIdx = 1
					arg_8_0.idx = 1

					if arg_8_0.sortTypePos == var_0_9.DEFAULT then
						arg_8_0.list:refreshList(0)
					else
						arg_8_0:sortList(arg_8_0.sortTypePos)
					end

					arg_8_0:updateItemNode()
					arg_8_0:updateBtnShow()
				end
			end)
		end)
	end)
end

function var_0_0.updateHero(arg_23_0)
	local var_23_0 = arg_23_0:nodeByName("avatar")

	var_23_0:removeAllChildren()
	xyd.setAvatarBorderNewUI(arg_23_0.hero, var_23_0)
	arg_23_0:nodeByName("txt_hero_name"):setString(arg_23_0.hero:getName())
	arg_23_0:updateItemNode()
end

function var_0_0.updateItemNode(arg_24_0)
	local var_24_0 = arg_24_0.data[arg_24_0.idx].equips

	for iter_24_0 = 1, 6 do
		local var_24_1 = arg_24_0:nodeByName("node_item_" .. iter_24_0)

		if var_24_1:getChildByName("item") then
			var_24_1:removeChildByName("item")
		end

		if var_24_0[iter_24_0] ~= 0 then
			local var_24_2 = display.newNode()

			var_24_2:setAnchorPoint(cc.p(0.5, 0.5))
			var_24_2:setContentSize(xyd.HunqiDefualtSize, xyd.HunqiDefualtSize)

			local var_24_3 = {
				noBorder = true,
				levShowTop = true,
				container = var_24_2,
				item = arg_24_0.backpack:getSpiritItemBySpiritID(var_24_0[iter_24_0])
			}

			xyd.setHunqiBorder(var_24_3)
			var_24_2:addTo(var_24_1)
			var_24_2:setName("item")
		end
	end

	local var_24_4 = arg_24_0:nodeByName("container_attr")

	var_24_4:removeAllChildren()

	local var_24_5 = arg_24_0.data[arg_24_0.equipIdx].equips
	local var_24_6 = arg_24_0.data[arg_24_0.equipIdx].attrs
	local var_24_7

	if arg_24_0.idx ~= arg_24_0.equipIdx then
		var_24_7 = arg_24_0.data[arg_24_0.idx].attrs
	end

	local var_24_8 = var_24_4:getHeight()

	for iter_24_1 = 1, math.ceil(#var_24_6 / 2) do
		local var_24_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/comb_attr.csb")

		for iter_24_2 = 1, 2 do
			local var_24_10 = var_24_6[(iter_24_1 - 1) * 2 + iter_24_2]

			if not var_24_10 then
				var_24_9:getChildByName("txt_attr_name_" .. iter_24_2):setVisible(false)
				var_24_9:getChildByName("txt_attr_num_now_" .. iter_24_2):setVisible(false)
				var_24_9:getChildByName("arrow_small_" .. iter_24_2):setVisible(false)
				var_24_9:getChildByName("txt_attr_num_next_" .. iter_24_2):setVisible(false)

				break
			end

			local var_24_11 = arg_24_0.data[arg_24_0.equipIdx].showNum[var_24_10.attrType]

			var_24_9:getChildByName("txt_attr_name_" .. iter_24_2):setString(var_0_8[var_24_10.attrType])
			var_24_9:getChildByName("txt_attr_num_now_" .. iter_24_2):setString(var_24_11)

			if var_24_7 then
				local var_24_12 = arg_24_0.data[arg_24_0.idx].showNum[var_24_10.attrType]

				var_24_9:getChildByName("txt_attr_num_next_" .. iter_24_2):setString(var_24_12)

				if arg_24_0.data[arg_24_0.equipIdx].num[var_24_10.attrType] > arg_24_0.data[arg_24_0.idx].num[var_24_10.attrType] then
					var_24_9:getChildByName("txt_attr_num_next_" .. iter_24_2):setColor(cc.c3b(222, 105, 104))
				end
			else
				var_24_9:getChildByName("arrow_small_" .. iter_24_2):setVisible(false)
				var_24_9:getChildByName("txt_attr_num_next_" .. iter_24_2):setVisible(false)
			end
		end

		var_24_9:addTo(var_24_4)
		var_24_9:setPosition(0, var_24_8 - iter_24_1 * 30)
	end

	local var_24_13, var_24_14 = arg_24_0:getSpiritSuitID(var_24_0)

	if var_24_14 ~= 0 then
		arg_24_0:nodeByName("skill_container"):setVisible(true)
		arg_24_0:nodeByName("txt_skill"):setString(var_0_2:attr4Desc(var_24_14))
	else
		arg_24_0:nodeByName("skill_container"):setVisible(false)
	end
end

function var_0_0.getSpiritSuitID(arg_25_0, arg_25_1)
	local var_25_0 = {}
	local var_25_1 = 0
	local var_25_2 = {}

	for iter_25_0, iter_25_1 in ipairs(arg_25_1) do
		if iter_25_1 ~= 0 then
			local var_25_3 = arg_25_0.backpack:getSpiritItemBySpiritID(iter_25_1)
			local var_25_4 = xyd.tables.spiritEquip:from(var_25_3.table_id)

			if not var_25_2[var_25_4] then
				var_25_2[var_25_4] = 1
			else
				var_25_2[var_25_4] = var_25_2[var_25_4] + 1
			end
		end
	end

	for iter_25_2, iter_25_3 in pairs(var_25_2) do
		if iter_25_3 >= 2 then
			table.insert(var_25_0, iter_25_2)
		end

		if iter_25_3 >= 4 then
			var_25_1 = iter_25_2
		end
	end

	return var_25_0, var_25_1
end

function var_0_0.getCombAttr(arg_26_0, arg_26_1)
	local var_26_0 = {}
	local var_26_1 = {}

	for iter_26_0, iter_26_1 in ipairs(var_0_7) do
		var_26_0[iter_26_0] = {
			attrNum = 0,
			attrType = iter_26_1
		}

		if xyd.tables.attr:isPercent(iter_26_1) then
			var_26_0[iter_26_0].isP = true
		end

		for iter_26_2, iter_26_3 in ipairs(arg_26_1) do
			if iter_26_3 ~= 0 then
				local var_26_2 = arg_26_0.backpack:getSpiritItemBySpiritID(iter_26_3)
				local var_26_3 = var_26_2.table_id
				local var_26_4 = var_0_4:from(var_26_3)
				local var_26_5 = var_0_4:modelId(var_26_3)

				if var_0_3:main(var_26_5, var_26_2.main) == iter_26_1 then
					var_26_0[iter_26_0].attrNum = var_26_0[iter_26_0].attrNum + var_26_2.main_attr_value
				end

				if var_26_2.sub then
					for iter_26_4 = 1, #var_26_2.sub do
						local var_26_6 = var_26_2.sub[iter_26_4]

						if var_0_3:sub(var_26_5, var_26_6) == iter_26_1 then
							var_26_0[iter_26_0].attrNum = var_26_0[iter_26_0].attrNum + var_26_2.sub_attr_value[iter_26_4]
						end
					end
				end
			end
		end
	end

	local var_26_7 = arg_26_0:getSpiritSuitID(arg_26_1)

	for iter_26_5, iter_26_6 in ipairs(var_26_7) do
		local var_26_8 = var_0_2:attr2(iter_26_6)
		local var_26_9 = var_0_2:attr2Value(iter_26_6)

		for iter_26_7, iter_26_8 in ipairs(var_26_0) do
			if iter_26_8.attrType == var_26_8 then
				iter_26_8.attrNum = iter_26_8.attrNum + var_26_9
			end
		end
	end

	for iter_26_9 = #var_26_0, 1, -1 do
		local var_26_10 = var_26_0[iter_26_9]

		if var_26_10.attrType == xyd.AttributeType.HUNQI_HP_BONUS then
			var_26_1[xyd.AttributeType.HP] = var_26_10.attrNum

			table.remove(var_26_0, iter_26_9)
		elseif var_26_10.attrType == xyd.AttributeType.HUNQI_AD_AP_BONUS then
			var_26_1[xyd.AttributeType.AD] = var_26_10.attrNum
			var_26_1[xyd.AttributeType.AP] = var_26_10.attrNum

			table.remove(var_26_0, iter_26_9)
		elseif var_26_10.attrType == xyd.AttributeType.HUNQI_JIAKANG_BONUS then
			var_26_1[xyd.AttributeType.HUJIA] = var_26_10.attrNum
			var_26_1[xyd.AttributeType.MOKANG] = var_26_10.attrNum

			table.remove(var_26_0, iter_26_9)
		end
	end

	return var_26_0, var_26_1
end

function var_0_0.getAttrShowNum(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = {}
	local var_27_1 = {}

	for iter_27_0, iter_27_1 in ipairs(arg_27_1) do
		local var_27_2
		local var_27_3

		if iter_27_1.isP then
			var_27_3 = iter_27_1.attrNum / xyd.DECIMAL_BASE * 100

			if var_27_3 < 10 and var_27_3 > 0 then
				var_27_2 = string.format("%.2f", var_27_3)
			else
				var_27_2 = string.format("%.f", var_27_3)
			end

			var_27_2 = var_27_2 .. "%"
		elseif arg_27_2[iter_27_1.attrType] then
			local var_27_4 = 1 + arg_27_2[iter_27_1.attrType] / xyd.DECIMAL_BASE

			var_27_3 = iter_27_1.attrNum * var_27_4

			if var_27_3 < 10 and var_27_3 > 0 then
				var_27_2 = string.format("%.2f", var_27_3)
			else
				var_27_2 = string.format("%.f", var_27_3)
			end
		else
			var_27_3 = iter_27_1.attrNum

			if var_27_3 < 10 and var_27_3 > 0 then
				var_27_2 = string.format("%.2f", var_27_3)
			else
				var_27_2 = string.format("%.f", var_27_3)
			end
		end

		var_27_0[iter_27_1.attrType] = var_27_2
		var_27_1[iter_27_1.attrType] = var_27_3
	end

	return var_27_0, var_27_1
end

function var_0_0.setSelectEquipNode(arg_28_0, arg_28_1)
	for iter_28_0 = 1, 6 do
		arg_28_0:nodeByName("node_item_" .. iter_28_0):getChildByName("choose"):setVisible(false)
	end

	if arg_28_1 then
		arg_28_0:nodeByName("node_item_" .. arg_28_1):getChildByName("choose"):setVisible(true)
	end
end

function var_0_0.delegate(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	if arg_29_2 == cc.ui.UIListView.COUNT_TAG then
		return math.ceil(#arg_29_0.data / 2)
	elseif arg_29_2 == cc.ui.UIListView.CELL_TAG then
		local var_29_0 = arg_29_0.list:dequeueItem()

		if var_29_0 then
			var_29_0:removeAllChildren()
		else
			var_29_0 = arg_29_0.list:newItem()
		end

		local var_29_1 = arg_29_0:createContent(arg_29_3)
		local var_29_2 = var_29_1:getContentSize()

		var_29_0:addContent(var_29_1)
		var_29_0:setItemSize(var_29_2.width, var_29_2.height + 3)

		return var_29_0
	end
end

function var_0_0.createContent(arg_30_0, arg_30_1)
	local var_30_0 = display.newNode()

	for iter_30_0 = 1, 2 do
		local var_30_1 = (arg_30_1 - 1) * 2 + iter_30_0
		local var_30_2 = arg_30_0.data[var_30_1]

		if not var_30_2 then
			break
		end

		local var_30_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/comb_item.csb")
		local var_30_4 = var_30_3:getChildByName("container")

		if var_30_1 == arg_30_0.equipIdx then
			var_30_4:getChildByName("icon_2"):setVisible(true)
		else
			var_30_4:getChildByName("icon_1"):setVisible(true)
		end

		if var_30_1 == arg_30_0.idx then
			var_30_4:getChildByName("comb_item_2"):setVisible(true)
		else
			var_30_4:getChildByName("comb_item_1"):setVisible(true)
		end

		if var_30_2.type_ == var_0_11.NOW_EQUIP then
			var_30_4:getChildByName("txt_name"):setString("Equipped")
		elseif var_30_2.type_ == var_0_11.COMB_LIST then
			var_30_4:getChildByName("txt_name"):setString(var_30_2.name)
		end

		var_30_4:addTouchEventListener(function(arg_31_0, arg_31_1)
			if arg_31_1 == ccui.TouchEventType.ended then
				if arg_30_0.scrollViewMoved_ then
					return
				end

				if var_30_1 == arg_30_0.idx then
					return
				end

				arg_30_0.idx = var_30_1

				arg_30_0:updateItemNode()
				arg_30_0:updateBtnShow()
				arg_30_0.list:refreshList(0)
			end
		end)
		var_30_3:setPosition(258 * (iter_30_0 - 1), 0)
		var_30_0:addChild(var_30_3)
	end

	var_30_0:setContentSize(502, 95)

	return var_30_0
end

function var_0_0.onEditorComb(arg_32_0, arg_32_1, arg_32_2, arg_32_3)
	if arg_32_3 then
		table.insert(arg_32_0.infos, {
			collocation = arg_32_1,
			id = arg_32_3,
			name = arg_32_2
		})
		table.sort(arg_32_0.infos, function(arg_33_0, arg_33_1)
			return tonumber(arg_33_0.id) < tonumber(arg_33_1.id)
		end)
	else
		arg_32_3 = arg_32_0.data[arg_32_0.idx].id

		for iter_32_0, iter_32_1 in ipairs(arg_32_0.infos) do
			if iter_32_1.id == arg_32_3 then
				iter_32_1.collocation = arg_32_1
				iter_32_1.name = arg_32_2

				break
			end
		end
	end

	arg_32_0:initDatas()

	arg_32_0.equipIdx = 1

	for iter_32_2, iter_32_3 in ipairs(arg_32_0.data) do
		if iter_32_3.id == arg_32_3 then
			arg_32_0.idx = iter_32_2

			break
		end
	end

	if arg_32_0.sortTypePos == var_0_9.DEFAULT then
		arg_32_0.list:refreshList(0)
	else
		arg_32_0:sortList(arg_32_0.sortTypePos)
	end

	arg_32_0:updateItemNode()
	arg_32_0:updateBtnShow()
end

function var_0_0.isNowEquips(arg_34_0, arg_34_1)
	local var_34_0 = arg_34_0.hero:getSpiritEquips()
	local var_34_1 = true

	for iter_34_0, iter_34_1 in ipairs(var_34_0) do
		if iter_34_1 ~= arg_34_1[iter_34_0] then
			var_34_1 = false

			break
		end
	end

	return var_34_1
end

function var_0_0.updateBtnShow(arg_35_0)
	local var_35_0 = arg_35_0.data[arg_35_0.idx]

	if var_35_0.type_ == var_0_11.COMB_LIST then
		arg_35_0:nodeByName("btn_container_1"):setVisible(false)
		arg_35_0:nodeByName("btn_container_2"):setVisible(true)
	elseif var_35_0.type_ == var_0_11.NOW_EQUIP then
		arg_35_0:nodeByName("btn_container_1"):setVisible(true)
		arg_35_0:nodeByName("btn_container_2"):setVisible(false)
	end
end

function var_0_0.scrollListener(arg_36_0, arg_36_1)
	if arg_36_1.name == "began" then
		arg_36_0.scrollViewMoved_ = false
		arg_36_0.prevY_ = arg_36_1.y
	elseif arg_36_1.name == "moved" and 10 <= math.abs(arg_36_1.y - arg_36_0.prevY_) then
		arg_36_0.scrollViewMoved_ = true
	end
end

function var_0_0.sortList(arg_37_0, arg_37_1)
	local var_37_0

	if arg_37_1 == var_0_9.HP then
		var_37_0 = xyd.AttributeType.HP
	elseif arg_37_1 == var_0_9.AD then
		var_37_0 = xyd.AttributeType.AD
	elseif arg_37_1 == var_0_9.AP then
		var_37_0 = xyd.AttributeType.AP
	elseif arg_37_1 == var_0_9.HUJIA then
		var_37_0 = xyd.AttributeType.HUJIA
	elseif arg_37_1 == var_0_9.MOKANG then
		var_37_0 = xyd.AttributeType.MOKANG
	elseif arg_37_1 == var_0_9.BAOJI_RATE then
		var_37_0 = xyd.AttributeType.BAOJI_RATE
	elseif arg_37_1 == var_0_9.BAOJIHARM then
		var_37_0 = xyd.AttributeType.BAOJIHARM
	elseif arg_37_1 == var_0_9.ZHUANGTAI_KANGXING then
		var_37_0 = xyd.AttributeType.ZHUANGTAI_KANGXING
	elseif arg_37_1 == var_0_9.ZHUANGTAI_MINGZHONG then
		var_37_0 = xyd.AttributeType.ZHUANGTAI_MINGZHONG
	elseif arg_37_1 == var_0_9.HUNQI_HP_BONUS then
		var_37_0 = xyd.AttributeType.HUNQI_HP_BONUS
	elseif arg_37_1 == var_0_9.HUNQI_AD_AP_BONUS then
		var_37_0 = xyd.AttributeType.HUNQI_AD_AP_BONUS
	elseif arg_37_1 == var_0_9.HUNQI_JIAKANG_BONUS then
		var_37_0 = xyd.AttributeType.HUNQI_JIAKANG_BONUS
	end

	local var_37_1 = arg_37_0.data[arg_37_0.idx].id
	local var_37_2 = arg_37_0.data[arg_37_0.equipIdx].id

	table.sort(arg_37_0.data, function(arg_38_0, arg_38_1)
		if arg_38_0.num[var_37_0] == arg_38_1.num[var_37_0] then
			return tonumber(arg_38_0.id) < tonumber(arg_38_1.id)
		else
			return arg_38_0.num[var_37_0] > arg_38_1.num[var_37_0]
		end
	end)

	for iter_37_0, iter_37_1 in ipairs(arg_37_0.data) do
		if iter_37_1.id == var_37_1 then
			arg_37_0.idx = iter_37_0
		end

		if iter_37_1.id == var_37_2 then
			arg_37_0.equipIdx = iter_37_0
		end
	end

	arg_37_0.sortTypePos = arg_37_1

	arg_37_0.list:refreshList(0)
	arg_37_0:nodeByName("txt_sort"):setString(var_0_10[arg_37_0.sortTypePos])
end

return var_0_0
