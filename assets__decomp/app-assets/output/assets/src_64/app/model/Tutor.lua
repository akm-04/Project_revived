local var_0_0 = class("Tutor", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.mode_ = 0
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	local var_3_0 = {
		activity_id = xyd.Activities.Tutor
	}

	xyd.Backend.get():request(xyd.mid.LOAD_SINGLE_ACTIVITY, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK and (arg_4_1 and false or arg_3_1) then
			arg_3_1(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.tutorInfo(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.TUTOR_INFO, var_5_0, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK and arg_6_1 and arg_6_1.campaign_infos then
			arg_5_0.campaignInfos = arg_6_1.campaign_infos
		end

		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.tutorEndCampaign(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	var_7_0.mode = arg_7_0.mode_

	xyd.Backend.get():request(xyd.mid.TUTOR_END_CAMPAIGN, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK and arg_8_1 and arg_8_1.campaign_info then
			arg_7_0.campaignInfos[tostring(var_7_0.campaign_id)] = arg_8_1.campaign_info
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.tutorResetHero(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	var_9_0.mode = arg_9_0.mode_

	xyd.Backend.get():request(xyd.mid.TUTOR_RESET_HERO, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK and arg_10_1 and arg_10_1.campaign_info then
			arg_9_0.campaignInfos[tostring(var_9_0.campaign_id)] = arg_10_1.campaign_info
			arg_9_0.campaignInfos[tostring(var_9_0.campaign_id)].campaign_id = var_9_0.campaign_id
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.getHeros(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = {}
	local var_11_1 = arg_11_0.campaignInfos[tostring(arg_11_1)]

	for iter_11_0, iter_11_1 in pairs(var_11_1.rent_heroes) do
		iter_11_0 = tonumber(iter_11_0)

		local var_11_2 = arg_11_0.selfPlayer:getHeroIgnoreAwaken(iter_11_0)
		local var_11_3, var_11_4 = arg_11_0:getAwakenTableID(iter_11_0, arg_11_2)

		if var_11_2 then
			local var_11_5 = var_11_2:toParams()

			var_11_5.table_id = var_11_3
			var_11_2 = var_0_2.new()

			var_11_2:populate(var_11_5)
		end

		if not var_11_2 then
			var_11_2 = var_0_2.new()

			var_11_2:populateWithTableID(var_11_3)
		end

		if var_11_4 == xyd.AwakeTwiceStage.COMPLETE then
			var_11_2:setAwakeTwiceStage(var_11_4)
		end

		if var_11_2 then
			table.insert(var_11_0, var_11_2)
		end

		var_11_2.useTime = iter_11_1
	end

	if not arg_11_2 then
		arg_11_0:formatNewHeros(var_11_0)
	else
		arg_11_0:formatRentHeros(var_11_0, arg_11_2)
	end

	return var_11_0
end

function var_0_0.formatNewHeros(arg_12_0, arg_12_1)
	for iter_12_0, iter_12_1 in pairs(arg_12_1) do
		local var_12_0 = xyd.tables.hero:isCanAwaken(iter_12_1:getFirstTableID())
		local var_12_1 = xyd.tables.hero:isCanAwakeTwice(xyd.tables.hero:afterAwaken(iter_12_1:getFirstTableID()))
		local var_12_2 = {
			100,
			100,
			80,
			60,
			0,
			0
		}
		local var_12_3 = {
			0,
			0,
			0,
			0,
			0,
			0
		}
		local var_12_4 = {
			0,
			0,
			0,
			0,
			0,
			0
		}

		if var_12_1 == 1 then
			var_12_2 = {
				100,
				100,
				80,
				60,
				40,
				40
			}
			var_12_3 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			var_12_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
		elseif var_12_0 == 1 then
			var_12_2 = {
				100,
				100,
				80,
				60,
				40,
				0
			}
			var_12_3 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			var_12_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
		else
			var_12_2 = {
				100,
				100,
				80,
				60,
				0,
				0
			}
			var_12_3 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
			var_12_4 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
		end

		arg_12_0:renewNewHeroInfo(iter_12_1, var_12_2, var_12_3, var_12_4)
		iter_12_1:updatePracticeAwardAttr()
		iter_12_1:setStar(3)

		if arg_12_0.backpack:getItemNumByID(xyd.tables.misc:getValue("activity_tutor_book_item")) > 0 and not xyd.tables.hero:isSX(iter_12_1:getFirstTableID()) then
			iter_12_1:setStar(5)
		end

		if arg_12_0.backpack:getItemNumByID(xyd.tables.misc:getValue("activity_tutor_senior_book_item")) > 0 and xyd.tables.hero:isSX(iter_12_1:getFirstTableID()) then
			iter_12_1:setStar(5)
		end
	end
end

function var_0_0.renewNewHeroInfo(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	local var_13_0 = 6

	arg_13_1.color_ = 16
	arg_13_1.level_ = 100
	arg_13_1.skillLev_ = {}
	arg_13_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_13_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_13_1.color_ >= xyd.EquipQuality.GREEN then
		arg_13_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_13_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_13_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_13_1.color_ >= xyd.EquipQuality.BLUE then
		arg_13_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_13_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_13_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_13_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_13_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_13_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_13_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_13_2[xyd.SKILL_INDEX.Awake] > 0 then
		arg_13_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_13_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_13_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	if arg_13_2[xyd.SKILL_INDEX.AwakeTwice] > 0 then
		arg_13_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = tonumber(arg_13_2[xyd.SKILL_INDEX.AwakeTwice]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.AwakeTwice]
	else
		arg_13_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = false
	end

	arg_13_1.equips_ = {}

	for iter_13_0 = 1, var_13_0 do
		table.insert(arg_13_1.equips_, tonumber(arg_13_4[iter_13_0]))
	end

	arg_13_1.fumo_ = {}

	for iter_13_1 = 1, var_13_0 do
		table.insert(arg_13_1.fumo_, tonumber(arg_13_3[iter_13_1]))
	end

	arg_13_1.fumoLev_ = {}

	for iter_13_2 = 1, var_13_0 do
		local var_13_1 = arg_13_1:getEquipByIndex(iter_13_2)

		table.insert(arg_13_1.fumoLev_, tonumber(var_13_1:getMaxFumoStar()))
	end
end

function var_0_0.getRentHeros(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = {}

	for iter_14_0, iter_14_1 in pairs(arg_14_1) do
		local var_14_1 = iter_14_1.hero_id
		local var_14_2 = arg_14_0.selfPlayer:getHeroIgnoreAwaken(var_14_1)
		local var_14_3, var_14_4 = arg_14_0:getAwakenTableID(var_14_1, arg_14_2)

		if var_14_2 then
			local var_14_5 = var_14_2:toParams()

			var_14_5.table_id = var_14_3
			var_14_2 = var_0_2.new()

			var_14_2:populate(var_14_5)
		end

		if not var_14_2 then
			var_14_2 = var_0_2.new()

			var_14_2:populateWithTableID(var_14_3)
		end

		if var_14_4 == xyd.AwakeTwiceStage.COMPLETE then
			var_14_2:setAwakeTwiceStage(var_14_4)
		end

		if var_14_2 then
			table.insert(var_14_0, var_14_2)
		end

		var_14_2.can_rent = true
		var_14_2.tutorInfo = iter_14_1
	end

	arg_14_0:formatRentHeros(var_14_0, arg_14_2)

	return var_14_0
end

function var_0_0.getAwakenTableID(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0

	if xyd.tables.hero:isCanAwaken(arg_15_1) > 0 and (not arg_15_2 or arg_15_2 >= 90) then
		arg_15_1 = xyd.tables.hero:afterAwaken(arg_15_1)
	end

	if xyd.tables.hero:isCanAwakeTwice(arg_15_1) > 0 and (not arg_15_2 or arg_15_2 >= 100) then
		var_15_0 = xyd.AwakeTwiceStage.COMPLETE
	end

	return arg_15_1, var_15_0
end

function var_0_0.formatRentHeros(arg_16_0, arg_16_1, arg_16_2)
	for iter_16_0, iter_16_1 in pairs(arg_16_1) do
		local var_16_0 = xyd.tables.hero:isCanAwaken(iter_16_1:getFirstTableID())
		local var_16_1 = xyd.tables.hero:isCanAwakeTwice(iter_16_1:getFirstTableID())
		local var_16_2 = {
			100,
			100,
			80,
			60,
			0,
			0
		}
		local var_16_3 = {
			0,
			0,
			0,
			0,
			0,
			0
		}
		local var_16_4 = {
			0,
			0,
			0,
			0,
			0,
			0
		}

		if var_16_1 == 1 and arg_16_2 >= 100 then
			var_16_2 = {
				100,
				100,
				80,
				60,
				40,
				40
			}
			var_16_3 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			var_16_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
		elseif var_16_0 == 1 and arg_16_2 >= 90 then
			var_16_2 = {
				100,
				100,
				80,
				60,
				40,
				0
			}
			var_16_3 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			var_16_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
		elseif iter_16_1:isHaveAwakenItem() then
			var_16_2 = {
				100,
				100,
				80,
				60,
				0,
				0
			}
			var_16_3 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
			var_16_4 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
		else
			var_16_2 = {
				100,
				100,
				80,
				60,
				0,
				0
			}
			var_16_3 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			var_16_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
		end

		if arg_16_2 and arg_16_2 < 100 then
			local var_16_5 = {
				0,
				0,
				20,
				40,
				60,
				60
			}

			for iter_16_2 = 1, #var_16_5 do
				var_16_2[iter_16_2] = math.max(math.min(var_16_2[iter_16_2], arg_16_2 - var_16_5[iter_16_2]), 0)
			end
		end

		arg_16_0:renewRentHeroInfo(iter_16_1, var_16_2, var_16_3, var_16_4, arg_16_2)
		iter_16_1:updatePracticeAwardAttr()
		iter_16_1:setStar(3)

		if arg_16_0.backpack:getItemNumByID(xyd.tables.misc:getValue("activity_tutor_book_item")) > 0 and not xyd.tables.hero:isSX(iter_16_1:getFirstTableID()) then
			iter_16_1:setStar(5)
		end

		if arg_16_0.backpack:getItemNumByID(xyd.tables.misc:getValue("activity_tutor_senior_book_item")) > 0 then
			iter_16_1:setStar(5)
		end
	end
end

function var_0_0.updateIcon(arg_17_0, arg_17_1)
	if arg_17_0.backpack:getItemNumByID(xyd.tables.misc:getValue("activity_tutor_senior_book_item")) > 0 then
		local var_17_0 = xyd.AssetLoader.get():loadSprite("windows/tutor/book1.png")

		arg_17_1:setSpriteFrame(var_17_0:getSpriteFrame())
	elseif arg_17_0.backpack:getItemNumByID(xyd.tables.misc:getValue("activity_tutor_book_item")) > 0 then
		local var_17_1 = xyd.AssetLoader.get():loadSprite("windows/tutor/book2.png")

		arg_17_1:setSpriteFrame(var_17_1:getSpriteFrame())
	else
		xyd.GrayNode(arg_17_1)
	end
end

function var_0_0.renewRentHeroInfo(arg_18_0, arg_18_1, arg_18_2, arg_18_3, arg_18_4, arg_18_5)
	local var_18_0 = xyd.tables.activityTutorPartnerCost:playerLevels()
	local var_18_1 = 6

	arg_18_1.color_ = xyd.findValue(var_18_0, arg_18_5) or 16
	arg_18_1.level_ = arg_18_5
	arg_18_1.skillLev_ = {}
	arg_18_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_18_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_18_1.color_ >= xyd.EquipQuality.GREEN then
		arg_18_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_18_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_18_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_18_1.color_ >= xyd.EquipQuality.BLUE then
		arg_18_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_18_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_18_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_18_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_18_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_18_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_18_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_18_1:isAwaken() then
		arg_18_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_18_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_18_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	if arg_18_1:isAwakeTwice() then
		arg_18_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = tonumber(arg_18_2[xyd.SKILL_INDEX.AwakeTwice]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.AwakeTwice]
	else
		arg_18_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = false
	end

	arg_18_1.equips_ = {}

	for iter_18_0 = 1, var_18_1 do
		table.insert(arg_18_1.equips_, tonumber(arg_18_4[iter_18_0]))
	end

	arg_18_1.fumo_ = {}

	for iter_18_1 = 1, var_18_1 do
		table.insert(arg_18_1.fumo_, tonumber(arg_18_3[iter_18_1]))
	end

	arg_18_1.fumoLev_ = {}

	for iter_18_2 = 1, var_18_1 do
		local var_18_2 = arg_18_1:getEquipByIndex(iter_18_2)

		table.insert(arg_18_1.fumoLev_, tonumber(var_18_2:getMaxFumoStar()))
	end
end

function var_0_0.setMode(arg_19_0, arg_19_1)
	arg_19_0.mode_ = arg_19_1 or 0
end

function var_0_0.getMode(arg_20_0)
	return arg_20_0.mode_
end

return var_0_0
