local var_0_0 = class("XiaoZhuShou")

function var_0_0.ctor(arg_1_0)
	arg_1_0:load_()
end

function var_0_0.persist(arg_2_0)
	if not arg_2_0.loaded_ then
		return
	end

	local var_2_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO xiaoZhuShou (id, xiaoZhuShouID, noShowEvent, banners, latestEventTime, noEventTime) VALUES (0, ?, ?, ?, ?, ?)\n    ")

	if arg_2_0.xiaoZhuShouID == nil then
		arg_2_0.xiaoZhuShouID = 0
	end

	if arg_2_0.banners == nil then
		arg_2_0.banners = ""
	end

	if arg_2_0.lastTime == nil then
		arg_2_0.lastTime = 0
	end

	var_2_0:bind_values(arg_2_0.xiaoZhuShouID, arg_2_0.noShowEvent, arg_2_0.banners, arg_2_0.latestEventTime, arg_2_0.noEventTime)
	var_2_0:step()
	var_2_0:reset()
end

function var_0_0.load_(arg_3_0)
	arg_3_0.xiaoZhuShouID = 0
	arg_3_0.noShowEvent = 0
	arg_3_0.banners = ""
	arg_3_0.latestEventTime = 0
	arg_3_0.noEventTime = 0

	for iter_3_0 in xyd.db.openGameData():prepare("SELECT * FROM xiaoZhuShou"):nrows() do
		arg_3_0.xiaoZhuShouID = tonumber(iter_3_0.xiaoZhuShouID)
		arg_3_0.noShowEvent = tonumber(iter_3_0.noShowEvent)
		arg_3_0.banners = iter_3_0.banners
		arg_3_0.latestEventTime = tonumber(iter_3_0.latestEventTime)
		arg_3_0.noEventTime = tonumber(iter_3_0.noEventTime)

		break
	end

	arg_3_0.loaded_ = true

	if arg_3_0.xiaoZhuShouID == 0 then
		arg_3_0.xiaoZhuShouID = 60001001
	end
end

function var_0_0.reset(arg_4_0)
	arg_4_0.xiaoZhuShouID = 60001001
end

return var_0_0
