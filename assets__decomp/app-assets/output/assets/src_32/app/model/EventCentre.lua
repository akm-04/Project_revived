local var_0_0 = class("EventCentre", import(".BaseModel"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.onLoadBuildingInfo(arg_3_0, arg_3_1)
	arg_3_0.buidingInfo = arg_3_1.params.building_list
end

function var_0_0.getBuildingList(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_BUILDING_LIST, var_4_0, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			arg_4_0.buidingInfo = arg_5_1.building_list
			arg_4_0.deskInfo = arg_5_1.desk_info
			arg_4_0.petRoomInfo = arg_5_1.pet_cabin_info
			arg_4_0.cabinetInfo = arg_5_1.cabinet_info
			arg_4_0.skillNeedTime = arg_5_1.cabinet_info.need_time
			arg_4_0.skillStartTime = arg_5_1.cabinet_info.start_time
			arg_4_0.recentCompleteSkill = arg_5_1.cabinet_info.recent_complete_skill
			arg_4_0.cabinetLev = arg_4_0.buidingInfo["1"].lev
			arg_4_0.cabinetNeedTime = arg_4_0.buidingInfo["1"].need_time
			arg_4_0.cabinetStartTime = arg_4_0.buidingInfo["1"].start_time
			arg_4_0.cabinetNewEvolve = arg_4_0.buidingInfo["1"].new_evolve

			local var_5_0 = "" .. xyd.EventCentreBuildingType.ADMIN

			arg_4_0.adminLev = arg_4_0.buidingInfo[var_5_0].lev
			arg_4_0.adminNeedTime = arg_4_0.buidingInfo[var_5_0].need_time
			arg_4_0.adminStartTime = arg_4_0.buidingInfo[var_5_0].start_time
			arg_4_0.adminNewEvolve = arg_4_0.buidingInfo[var_5_0].new_evolve

			local var_5_1 = "" .. xyd.EventCentreBuildingType.BOARD

			arg_4_0.boardLev = arg_4_0.buidingInfo[var_5_1].lev
			arg_4_0.boardNeedTime = arg_4_0.buidingInfo[var_5_1].need_time
			arg_4_0.boardStartTime = arg_4_0.buidingInfo[var_5_1].start_time
			arg_4_0.boardNewEvolve = arg_4_0.buidingInfo[var_5_1].new_evolve

			if not arg_4_0.petRoomInfo.pet_id then
				arg_4_0.petRoomInfo.pet_id = 0
			end

			arg_4_0:updateHeroBookshelfLevel()
		end

		if arg_4_2 then
			arg_4_2(arg_5_0, arg_5_1)
		end
	end)
end

function var_0_0.updateHeroBookshelfLevel(arg_6_0)
	local var_6_0 = arg_6_0.buidingInfo["" .. xyd.EventCentreBuildingType.BOOKSHELF]

	if var_6_0.new_evolve and var_6_0.new_evolve == 1 then
		local var_6_1 = arg_6_0.selfPlayer:getHeros()

		if var_6_1 and next(var_6_1) then
			for iter_6_0, iter_6_1 in pairs(var_6_1) do
				iter_6_1:setBookshelfLevel(var_6_0.lev)
			end
		end
	end
end

function var_0_0.getRedPointInfo(arg_7_0)
	local var_7_0 = -1
	local var_7_1 = false
	local var_7_2 = xyd.ServerTime.get():getServerTime()

	if arg_7_0.buidingInfo then
		for iter_7_0, iter_7_1 in pairs(arg_7_0.buidingInfo) do
			local var_7_3 = iter_7_1.need_time - (var_7_2 - iter_7_1.start_time)

			if var_7_3 >= 0 and (var_7_3 < var_7_0 or var_7_0 == -1) then
				var_7_0 = var_7_3
			end

			local var_7_4 = xyd.EventCentreBuildingType.BOARD

			if iter_7_1.new_evolve and iter_7_1.new_evolve == 1 and tonumber(iter_7_0) ~= var_7_4 then
				var_7_1 = true
			end
		end
	end

	if arg_7_0.deskInfo and arg_7_0.deskInfo.is_making == 1 then
		local var_7_5 = arg_7_0.deskInfo.make_need_time - (var_7_2 - arg_7_0.deskInfo.make_start_time)

		if var_7_5 >= 0 and (var_7_5 < var_7_0 or var_7_0 == -1) then
			var_7_0 = var_7_5
		end
	end

	if arg_7_0.deskInfo and arg_7_0.deskInfo.make_item and arg_7_0.deskInfo.make_item > 0 then
		var_7_1 = true
	end

	if arg_7_0.petRoomInfo and arg_7_0.petRoomInfo.is_making == 1 then
		local var_7_6 = arg_7_0.petRoomInfo.make_need_time - (var_7_2 - arg_7_0.petRoomInfo.make_start_time)

		if var_7_6 >= 0 and (var_7_6 < var_7_0 or var_7_0 == -1) then
			var_7_0 = var_7_6
		end
	end

	if arg_7_0.petRoomInfo and arg_7_0.petRoomInfo.make_item and arg_7_0.petRoomInfo.make_item > 0 then
		var_7_1 = true
	end

	if arg_7_0.cabinetInfo then
		local var_7_7 = arg_7_0.skillNeedTime - (var_7_2 - arg_7_0.skillStartTime)

		if var_7_7 >= 0 and (var_7_7 < var_7_0 or var_7_0 == -1) then
			var_7_0 = var_7_7
		end

		if arg_7_0.recentCompleteSkill and arg_7_0.recentCompleteSkill > 0 then
			var_7_1 = true
		end
	end

	return var_7_1, var_7_0
end

function var_0_0.upgradeBuilding(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_1 or {}

	xyd.Backend.get():request(xyd.mid.UPGRADE_BUILDING, var_8_0, function(arg_9_0, arg_9_1)
		if arg_8_2 then
			if arg_9_0 == xyd.error.OK then
				arg_8_0.buidingInfo[tostring(var_8_0.type)].lev = arg_9_1.lev
				arg_8_0.buidingInfo[tostring(var_8_0.type)].need_time = arg_9_1.need_time
				arg_8_0.buidingInfo[tostring(var_8_0.type)].start_time = arg_9_1.start_time
			end

			arg_8_2(arg_9_0, arg_9_1)
		end
	end)
end

function var_0_0.cancelEvolveBuilding(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_1 or {}

	xyd.Backend.get():request(xyd.mid.CANCEL_EVOLVE_BUILDING, var_10_0, function(arg_11_0, arg_11_1)
		if arg_10_2 then
			if arg_11_0 == xyd.error.OK then
				arg_10_0.buidingInfo[tostring(var_10_0.type)] = arg_11_1.building_info
			end

			arg_10_2(arg_11_0, arg_11_1)
		end
	end)
end

function var_0_0.getCabinetInfo(arg_12_0, arg_12_1)
	local var_12_0 = {}

	xyd.Backend.get():request(xyd.mid.GET_CABINET_INFO, var_12_0, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			arg_12_0.bookInfo = arg_13_1.book_info
			arg_12_0.curLearnSkill = arg_13_1.cabinet_info.cur_learn_skill
			arg_12_0.skillNeedTime = arg_13_1.cabinet_info.need_time
			arg_12_0.skillStartTime = arg_13_1.cabinet_info.start_time
			arg_12_0.recentCompleteSkill = arg_13_1.cabinet_info.recent_complete_skill
			arg_12_0.creatsBook = {}
			arg_12_0.workingBook = {}
			arg_12_0.pieceBook = {}
			arg_12_0.overBook = {}
			arg_12_0.uncollectedBook = {}
			arg_12_0.allBooks = {}
			arg_12_0.allSkillsLev = {}

			for iter_13_0, iter_13_1 in pairs(xyd.tables.cabinetBookTable:getIds()) do
				local var_13_0 = arg_12_0.bookInfo[tostring(iter_13_1)]

				if var_13_0 and xyd.tables.cabinetBookTable:isHide(iter_13_1) == 0 then
					local var_13_1 = {
						title = xyd.tables.cabinetBookTable:name(iter_13_1),
						star = xyd.tables.cabinetBookTable:star(iter_13_1),
						skills = {}
					}

					for iter_13_2, iter_13_3 in pairs(xyd.tables.cabinetBookTable:skillId(iter_13_1)) do
						var_13_1.skills[iter_13_3] = {}
						var_13_1.skills[iter_13_3].lev = 0
						var_13_1.skills[iter_13_3].id = iter_13_3
						arg_12_0.allSkillsLev[iter_13_3] = 0
					end

					var_13_1.author = xyd.tables.cabinetBookTable:author(iter_13_1)
					var_13_1.desc = xyd.tables.cabinetBookTable:desc(iter_13_1)
					var_13_1.id = iter_13_1

					if xyd.tables.cabinetBookTable:type(iter_13_1) == 2 then
						if arg_12_0.selfPlayer:getBackpack():getItemNumByID(iter_13_1) > 0 then
							for iter_13_4, iter_13_5 in pairs(xyd.tables.cabinetBookTable:skillId(iter_13_1)) do
								if var_13_0[tostring(iter_13_5)] then
									var_13_1.skills[iter_13_5] = {}
									var_13_1.skills[iter_13_5].lev = var_13_0[tostring(iter_13_5)].lev
									var_13_1.skills[iter_13_5].id = iter_13_5
									arg_12_0.allSkillsLev[iter_13_5] = var_13_0[tostring(iter_13_5)].lev
								end
							end
						end

						table.insert(arg_12_0.creatsBook, var_13_1)

						var_13_1.type = xyd.BookType.CREATS
						arg_12_0.allBooks[var_13_1.id] = var_13_1
					elseif arg_12_0.selfPlayer:getBackpack():getItemNumByID(iter_13_1) > 0 and xyd.tables.cabinetBookTable:type(iter_13_1) == 1 then
						local var_13_2 = true

						for iter_13_6, iter_13_7 in pairs(xyd.tables.cabinetBookTable:skillId(iter_13_1)) do
							if var_13_0[tostring(iter_13_7)] then
								if var_13_0[tostring(iter_13_7)].lev ~= xyd.tables.cabinetBookTable:star(iter_13_1) then
									var_13_2 = false
								end

								var_13_1.skills[iter_13_7] = {}
								var_13_1.skills[iter_13_7].lev = var_13_0[tostring(iter_13_7)].lev
								var_13_1.skills[iter_13_7].id = iter_13_7
								arg_12_0.allSkillsLev[iter_13_7] = var_13_0[tostring(iter_13_7)].lev
							end
						end

						if var_13_2 == true then
							table.insert(arg_12_0.overBook, var_13_1)

							var_13_1.type = xyd.BookType.OVER
							arg_12_0.allBooks[var_13_1.id] = var_13_1
						else
							table.insert(arg_12_0.workingBook, var_13_1)

							var_13_1.type = xyd.BookType.WORKING
							arg_12_0.allBooks[var_13_1.id] = var_13_1
						end
					elseif arg_12_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.cabinetBookTable:piece(iter_13_1)) > 0 then
						if arg_12_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.cabinetBookTable:piece(iter_13_1)) >= xyd.tables.item:itemNum(xyd.tables.cabinetBookTable:piece(iter_13_1)) then
							table.insert(arg_12_0.workingBook, var_13_1)

							var_13_1.type = xyd.BookType.WORKING
							arg_12_0.allBooks[var_13_1.id] = var_13_1
						else
							table.insert(arg_12_0.pieceBook, var_13_1)

							var_13_1.type = xyd.BookType.PIECE
							arg_12_0.allBooks[var_13_1.id] = var_13_1
						end
					elseif arg_12_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.cabinetBookTable:piece(iter_13_1)) == 0 then
						table.insert(arg_12_0.uncollectedBook, var_13_1)

						var_13_1.type = xyd.BookType.UNCOLLECTED
						arg_12_0.allBooks[var_13_1.id] = var_13_1
					end
				end
			end
		end

		arg_12_0:sortBook()

		if arg_12_1 then
			arg_12_1(arg_13_0, arg_13_1)
		end
	end)
end

function var_0_0.levUp(arg_14_0, arg_14_1)
	local var_14_0 = xyd.tables.cabinetSkillTable:skillbook(arg_14_1)

	for iter_14_0, iter_14_1 in pairs(arg_14_0.workingBook) do
		if iter_14_1.id == var_14_0 then
			local var_14_1 = false

			iter_14_1.skills[arg_14_1].lev = iter_14_1.skills[arg_14_1].lev + 1
			arg_14_0.allSkillsLev[arg_14_1] = iter_14_1.skills[arg_14_1].lev

			local var_14_2 = xyd.tables.cabinetSkillTable:partner(arg_14_1)

			if arg_14_0.selfPlayer:getHeroIgnoreAwaken(var_14_2) then
				arg_14_0.selfPlayer:getHeroIgnoreAwaken(var_14_2):updateBookSkill(arg_14_1, iter_14_1.skills[arg_14_1].lev)
			end

			for iter_14_2, iter_14_3 in pairs(iter_14_1.skills) do
				if iter_14_3.lev ~= xyd.tables.cabinetBookTable:star(var_14_0) then
					break
				end

				if iter_14_2 == #iter_14_1.skills then
					var_14_1 = true
				end
			end

			if var_14_1 then
				table.insert(arg_14_0.overBook, iter_14_1)
				table.remove(arg_14_0.workingBook, iter_14_0)

				arg_14_0.allBooks[var_14_0] = iter_14_1
				arg_14_0.allBooks[var_14_0].type = xyd.BookType.OVER

				arg_14_0:sortBook()
			end
		end
	end

	for iter_14_4, iter_14_5 in pairs(arg_14_0.creatsBook) do
		if iter_14_5.id == var_14_0 then
			local var_14_3 = false

			iter_14_5.skills[arg_14_1].lev = iter_14_5.skills[arg_14_1].lev + 1
			arg_14_0.allSkillsLev[arg_14_1] = iter_14_5.skills[arg_14_1].lev

			local var_14_4 = xyd.tables.cabinetSkillTable:partner(arg_14_1)

			if arg_14_0.selfPlayer:getHeroIgnoreAwaken(var_14_4) then
				arg_14_0.selfPlayer:getHeroIgnoreAwaken(var_14_4):updateBookSkill(arg_14_1, iter_14_5.skills[arg_14_1].lev)
			end
		end
	end
end

function var_0_0.learnSkill(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_1 or {}

	xyd.Backend.get():request(xyd.mid.LEARN_SKILL, var_15_0, function(arg_16_0, arg_16_1)
		if arg_15_2 then
			if arg_16_0 == xyd.error.OK then
				arg_15_0.curLearnSkill = arg_16_1.cabinet_info.cur_learn_skill
				arg_15_0.skillNeedTime = arg_16_1.cabinet_info.need_time
				arg_15_0.skillStartTime = arg_16_1.cabinet_info.start_time
			end

			arg_15_2(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.giveUpLearnSkill(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1 or {}

	xyd.Backend.get():request(xyd.mid.GIVE_UP_LEARN_SKILL, var_17_0, function(arg_18_0, arg_18_1)
		if arg_17_2 then
			if arg_18_0 == xyd.error.OK then
				arg_17_0.curLearnSkill = arg_18_1.cabinet_info.cur_learn_skill
				arg_17_0.skillNeedTime = arg_18_1.cabinet_info.need_time
				arg_17_0.skillStartTime = arg_18_1.cabinet_info.start_time
			end

			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.getRecycleInfo(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_RECYCLE_INFO, var_19_0, function(arg_20_0, arg_20_1)
		if arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.recycleItems(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = arg_21_1 or {}

	xyd.Backend.get():request(xyd.mid.RECYCLE_ITEMS, var_21_0, function(arg_22_0, arg_22_1)
		if arg_21_2 then
			arg_21_2(arg_22_0, arg_22_1)
		end
	end)
end

function var_0_0.getDeskpInfo(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = arg_23_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_DESKP_INFO, var_23_0, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK then
			arg_23_0.deskInfo = arg_24_1
		end

		if arg_23_2 then
			arg_23_2(arg_24_0, arg_24_1)
		end
	end)
end

function var_0_0.getPetRoomInfo(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_PET_ROOM_INFO, var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			arg_25_0.petRoomInfo = arg_26_1

			if not arg_25_0.petRoomInfo.pet_id then
				arg_25_0.petRoomInfo.pet_id = 0
			end
		end

		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.makeItem(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_1 or {}

	xyd.Backend.get():request(xyd.mid.MAKE_ITEM, var_27_0, function(arg_28_0, arg_28_1)
		if arg_27_2 then
			arg_27_2(arg_28_0, arg_28_1)
		end
	end)
end

function var_0_0.makePetItem(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_1 or {}

	xyd.Backend.get():request(xyd.mid.MAKE_PET_ITEM, var_29_0, function(arg_30_0, arg_30_1)
		if arg_29_2 then
			arg_29_2(arg_30_0, arg_30_1)
		end
	end)
end

function var_0_0.getAdminInfo(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = arg_31_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_ADMIN_INFO, var_31_0, function(arg_32_0, arg_32_1)
		if arg_31_2 then
			arg_31_2(arg_32_0, arg_32_1)
		end
	end)
end

function var_0_0.adminConversion(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = arg_33_1 or {}

	xyd.Backend.get():request(xyd.mid.ADMIN_CONVERSION, var_33_0, function(arg_34_0, arg_34_1)
		if arg_33_2 then
			arg_33_2(arg_34_0, arg_34_1)
		end
	end)
end

function var_0_0.speedUpBuilding(arg_35_0, arg_35_1, arg_35_2)
	local var_35_0 = arg_35_1 or {}

	xyd.Backend.get():request(xyd.mid.SPEED_UP_BUILDING, var_35_0, function(arg_36_0, arg_36_1)
		if var_35_0.type ~= nil and arg_36_0 == xyd.error.OK then
			arg_35_0.buidingInfo[tostring(var_35_0.type)].lev = arg_36_1.lev
		end

		if arg_35_2 then
			arg_35_2(arg_36_0, arg_36_1)
		end
	end)
end

function var_0_0.sortBook(arg_37_0)
	table.sort(arg_37_0.workingBook, function(arg_38_0, arg_38_1)
		local var_38_0 = arg_38_0.star
		local var_38_1 = arg_38_1.star

		if arg_37_0.selfPlayer:getBackpack():getItemNumByID(arg_38_0.id) <= 0 then
			var_38_0 = var_38_0 + 10
		end

		if arg_37_0.selfPlayer:getBackpack():getItemNumByID(arg_38_1.id) <= 0 then
			var_38_1 = var_38_1 + 10
		end

		return var_38_0 < var_38_1
	end)
	table.sort(arg_37_0.pieceBook, function(arg_39_0, arg_39_1)
		return arg_39_0.star < arg_39_1.star
	end)
	table.sort(arg_37_0.overBook, function(arg_40_0, arg_40_1)
		return arg_40_0.star < arg_40_1.star
	end)
	table.sort(arg_37_0.uncollectedBook, function(arg_41_0, arg_41_1)
		return arg_41_0.star < arg_41_1.star
	end)
	table.sort(arg_37_0.creatsBook, function(arg_42_0, arg_42_1)
		local var_42_0 = arg_42_0.star
		local var_42_1 = arg_42_1.star

		if arg_37_0.selfPlayer:getBackpack():getItemNumByID(arg_42_0.id) <= 0 then
			var_42_0 = var_42_0 + 10
		end

		if arg_37_0.selfPlayer:getBackpack():getItemNumByID(arg_42_1.id) <= 0 then
			var_42_1 = var_42_1 + 10
		end

		return var_42_0 < var_42_1
	end)
end

function var_0_0.speedUpSkill(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0 = arg_43_1 or {}

	xyd.Backend.get():request(xyd.mid.SPEED_UP_SKILL, var_43_0, function(arg_44_0, arg_44_1)
		if arg_43_2 then
			arg_43_0.curLearnSkill = arg_44_1.cabinet_info.cur_learn_skill
			arg_43_0.skillNeedTime = arg_44_1.cabinet_info.need_time
			arg_43_0.skillStartTime = arg_44_1.cabinet_info.start_time
			arg_43_0.recentCompleteSkill = arg_44_1.cabinet_info.recent_complete_skill

			local var_44_0 = tonumber(arg_44_1.book_id)

			for iter_44_0, iter_44_1 in pairs(arg_43_0.workingBook) do
				if iter_44_1.id == var_44_0 then
					local var_44_1 = false

					for iter_44_2, iter_44_3 in pairs(arg_44_1.book_info) do
						if iter_44_3.lev ~= xyd.tables.cabinetBookTable:star(var_44_0) then
							break
						end

						if iter_44_2 == #arg_44_1.book_info then
							var_44_1 = true
						end
					end

					if var_44_1 then
						table.remove(arg_43_0.workingBook, iter_44_0)

						local var_44_2 = {
							title = xyd.tables.cabinetBookTable:name(var_44_0),
							star = xyd.tables.cabinetBookTable:star(var_44_0),
							skills = {}
						}

						for iter_44_4, iter_44_5 in pairs(xyd.tables.cabinetBookTable:skillId(var_44_0)) do
							var_44_2.skills[iter_44_5] = {}
							var_44_2.skills[iter_44_5].lev = arg_44_1.book_info[tostring(iter_44_5)].lev
							var_44_2.skills[iter_44_5].id = iter_44_5
							arg_43_0.allSkillsLev[iter_44_5] = arg_44_1.book_info[tostring(iter_44_5)].lev

							local var_44_3 = xyd.tables.cabinetSkillTable:partner(iter_44_5)

							if arg_43_0.selfPlayer:getHeroIgnoreAwaken(var_44_3) then
								arg_43_0.selfPlayer:getHeroIgnoreAwaken(var_44_3):updateBookSkill(iter_44_5, var_44_2.skills[iter_44_5].lev)
							end
						end

						var_44_2.author = xyd.tables.cabinetBookTable:author(var_44_0)
						var_44_2.desc = xyd.tables.cabinetBookTable:desc(var_44_0)
						var_44_2.id = var_44_0
						arg_43_0.allBooks[var_44_2.id] = var_44_2

						table.insert(arg_43_0.overBook, var_44_2)

						arg_43_0.allBooks[var_44_2.id].type = xyd.BookType.OVER
					else
						for iter_44_6, iter_44_7 in pairs(xyd.tables.cabinetBookTable:skillId(var_44_0)) do
							iter_44_1.skills[iter_44_7] = {}
							iter_44_1.skills[iter_44_7].lev = arg_44_1.book_info[tostring(iter_44_7)].lev
							iter_44_1.skills[iter_44_7].id = iter_44_7
							arg_43_0.allSkillsLev[iter_44_7] = arg_44_1.book_info[tostring(iter_44_7)].lev

							local var_44_4 = xyd.tables.cabinetSkillTable:partner(iter_44_7)

							if arg_43_0.selfPlayer:getHeroIgnoreAwaken(var_44_4) then
								arg_43_0.selfPlayer:getHeroIgnoreAwaken(var_44_4):updateBookSkill(iter_44_7, iter_44_1.skills[iter_44_7].lev)
							end
						end
					end
				end
			end

			for iter_44_8, iter_44_9 in pairs(arg_43_0.creatsBook) do
				if iter_44_9.id == var_44_0 then
					for iter_44_10, iter_44_11 in pairs(xyd.tables.cabinetBookTable:skillId(var_44_0)) do
						iter_44_9.skills[iter_44_11] = {}
						iter_44_9.skills[iter_44_11].lev = arg_44_1.book_info[tostring(iter_44_11)].lev
						iter_44_9.skills[iter_44_11].id = iter_44_11
						arg_43_0.allSkillsLev[iter_44_11] = arg_44_1.book_info[tostring(iter_44_11)].lev

						local var_44_5 = xyd.tables.cabinetSkillTable:partner(iter_44_11)

						if arg_43_0.selfPlayer:getHeroIgnoreAwaken(var_44_5) then
							arg_43_0.selfPlayer:getHeroIgnoreAwaken(var_44_5):updateBookSkill(iter_44_11, iter_44_9.skills[iter_44_11].lev)
						end
					end
				end
			end

			arg_43_0:sortBook()
			arg_43_2(arg_44_0, arg_44_1)
		end
	end)
end

function var_0_0.cancelMaking(arg_45_0, arg_45_1, arg_45_2)
	local var_45_0 = arg_45_1 or {}

	xyd.Backend.get():request(xyd.mid.CANCEL_MAKE_ITEM, var_45_0, function(arg_46_0, arg_46_1)
		if arg_45_2 then
			arg_45_2(arg_46_0, arg_46_1)
		end
	end)
end

function var_0_0.confirmMakeItem(arg_47_0, arg_47_1, arg_47_2)
	local var_47_0 = arg_47_1 or {}

	xyd.Backend.get():request(xyd.mid.CONFIRM_MAKE_ITEM, var_47_0, function(arg_48_0, arg_48_1)
		if arg_48_0 == xyd.error.OK then
			if var_47_0.building_type == xyd.EventCentreBuildingType.DESK then
				arg_47_0.deskInfo.make_item = 0
			elseif var_47_0.building_type == xyd.EventCentreBuildingType.PETROOM then
				arg_47_0.petRoomInfo.make_item = 0
			end
		end

		if arg_47_2 then
			arg_47_2(arg_48_0, arg_48_1)
		end
	end)
end

function var_0_0.accelerateMakeItem(arg_49_0, arg_49_1, arg_49_2)
	local var_49_0 = arg_49_1 or {}

	xyd.Backend.get():request(xyd.mid.ACCELERATE_MAKE_ITEM, var_49_0, function(arg_50_0, arg_50_1)
		if arg_49_2 then
			arg_49_2(arg_50_0, arg_50_1)
		end
	end)
end

function var_0_0.confirmBuildingUpgrade(arg_51_0, arg_51_1, arg_51_2)
	local var_51_0 = arg_51_1 or {}

	xyd.Backend.get():request(xyd.mid.CONFIRM_BUILDING_UPGRADE, var_51_0, function(arg_52_0, arg_52_1)
		if arg_52_0 == xyd.error.OK then
			arg_51_0.buidingInfo[tostring(var_51_0.type)].new_evolve = 0

			local var_52_0 = xyd.WindowManager.get():getWindow("event_centre")

			if var_52_0 then
				var_52_0:updateRedPointShow()
			end
		end

		if arg_51_2 then
			arg_51_2(arg_52_0, arg_52_1)
		end
	end)
end

function var_0_0.confirmSkillUpgrade(arg_53_0, arg_53_1, arg_53_2)
	local var_53_0 = arg_53_1 or {}

	xyd.Backend.get():request(xyd.mid.CABINET_SKILL_CONFIRM, var_53_0, function(arg_54_0, arg_54_1)
		if arg_53_2 then
			arg_53_2(arg_54_0, arg_54_1)

			if arg_53_0.recentCompleteSkill and arg_53_0.recentCompleteSkill ~= 0 then
				xyd.WindowManager.get():openWindow("junk_chest_skill_up_ok")

				local var_54_0 = xyd.tables.cabinetSkillTable:skillbook(arg_53_0.recentCompleteSkill)
				local var_54_1 = true

				for iter_54_0, iter_54_1 in pairs(arg_53_0.allBooks[var_54_0].skills) do
					if iter_54_1.lev ~= xyd.tables.cabinetBookTable:star(var_54_0) then
						var_54_1 = false

						break
					end
				end

				if var_54_1 then
					xyd.WindowManager.get():openWindow("junk_chest_finish_book")
				end

				arg_53_0.recentCompleteSkill = 0

				local var_54_2 = xyd.WindowManager.get():getWindow("event_centre")

				if var_54_2 then
					var_54_2:updateRedPointShow()
				end
			end
		end
	end)
end

function var_0_0.getNoticeBoardInfo(arg_55_0, arg_55_1, arg_55_2)
	local var_55_0 = arg_55_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_NOTICE_BOARD_INFO, var_55_0, function(arg_56_0, arg_56_1)
		if arg_55_2 then
			if arg_56_0 == xyd.error.OK then
				arg_55_0:loadBusyPartners_(arg_56_1.doing_mission_list)
			end

			arg_55_2(arg_56_0, arg_56_1)
		end
	end)
end

function var_0_0.receiveMission(arg_57_0, arg_57_1, arg_57_2)
	local var_57_0 = arg_57_1 or {}

	xyd.Backend.get():request(xyd.mid.RECEIVE_MISSION, var_57_0, function(arg_58_0, arg_58_1)
		if arg_57_2 then
			arg_57_2(arg_58_0, arg_58_1)
		end
	end)
end

function var_0_0.loadBusyPartners_(arg_59_0, arg_59_1)
	arg_59_0.busyPartners_ = {}

	for iter_59_0 = 1, #arg_59_1 do
		table.insert(arg_59_0.busyPartners_, arg_59_1[iter_59_0].leader)

		for iter_59_1 = 1, #arg_59_1[iter_59_0].partners do
			table.insert(arg_59_0.busyPartners_, arg_59_1[iter_59_0].partners[iter_59_1])
		end
	end
end

function var_0_0.getBusyPartners(arg_60_0)
	return arg_60_0.busyPartners_
end

function var_0_0.giveUpMission(arg_61_0, arg_61_1, arg_61_2)
	local var_61_0 = arg_61_1 or {}

	xyd.Backend.get():request(xyd.mid.GIVE_UP_MISSION, var_61_0, function(arg_62_0, arg_62_1)
		if arg_61_2 then
			arg_61_2(arg_62_0, arg_62_1)
		end
	end)
end

function var_0_0.confirmNewAwardLog(arg_63_0, arg_63_1, arg_63_2)
	local var_63_0 = arg_63_1 or {}

	xyd.Backend.get():request(xyd.mid.CONFIRM_NEW_AWARD_LOG, var_63_0, function(arg_64_0, arg_64_1)
		if arg_63_2 then
			arg_63_2(arg_64_0, arg_64_1)
		end
	end)
end

function var_0_0.getUpgradeCost(arg_65_0, arg_65_1)
	local var_65_0

	if arg_65_1 < 14400 then
		var_65_0 = arg_65_1 / 72
	elseif arg_65_1 < 43200 then
		var_65_0 = (arg_65_1 - 14400) / 144 + 200
	else
		var_65_0 = (arg_65_1 - 43200) / 432 + 400
	end

	return (math.max(math.ceil(var_65_0), 1))
end

function var_0_0.getNoticeBoardReport(arg_66_0, arg_66_1, arg_66_2)
	local var_66_0 = arg_66_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_NOTICE_BOARD_REPORT, var_66_0, function(arg_67_0, arg_67_1)
		if arg_66_2 then
			arg_66_2(arg_67_0, arg_67_1)
		end
	end)
end

return var_0_0
