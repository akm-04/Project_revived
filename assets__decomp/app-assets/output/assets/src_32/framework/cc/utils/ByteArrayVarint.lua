local var_0_0 = class("BitVaiant", import(".ByteArray"))

import(".bit")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0._endian = arg_1_1
	arg_1_0._buf = {}
	arg_1_0._pos = 1
end

function var_0_0.readVInt(arg_2_0)
	local var_2_0 = arg_2_0:_decodeVarint()

	return arg_2_0:_zigZagDecode(var_2_0)
end

function var_0_0.writeVInt(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_0:_zigZagEncode(arg_3_1)

	arg_3_0:_encodeVarint(var_3_0)

	return arg_3_0
end

function var_0_0.readUVInt(arg_4_0)
	return arg_4_0:_decodeVarint()
end

function var_0_0.writeUVInt(arg_5_0, arg_5_1)
	arg_5_0:_encodeVarint(arg_5_1)

	return arg_5_0
end

function var_0_0.readStringUVInt(arg_6_0)
	local var_6_0 = arg_6_0:readUVInt()

	return arg_6_0:readStringBytes(var_6_0)
end

function var_0_0.writeStringUVInt(arg_7_0, arg_7_1)
	arg_7_0:writeUVInt(#arg_7_1)
	arg_7_0:writeStringBytes(arg_7_1)

	return arg_7_0
end

function var_0_0._zigZagEncode(arg_8_0, arg_8_1)
	if arg_8_1 >= 0 then
		return bit.lshift(arg_8_1, 1)
	end

	return bit.bxor(bit.lshift(arg_8_1, 1), bit.bnot(0))
end

function var_0_0._zigZagDecode(arg_9_0, arg_9_1)
	if bit.band(arg_9_1, 1) == 0 then
		return bit.rshift(arg_9_1, 1)
	end

	return bit.bxor(bit.rshift(arg_9_1, 1), bit.bnot(0))
end

function var_0_0._encodeVarint(arg_10_0, arg_10_1)
	assert(type(arg_10_1) == "number", "Value to encode must be a number!")

	local var_10_0 = bit.band(arg_10_1, 127)

	arg_10_1 = bit.rshift(arg_10_1, 7)

	while arg_10_1 ~= 0 do
		arg_10_0:writeByte(bit.bor(128, var_10_0))

		var_10_0 = bit.band(arg_10_1, 127)
		arg_10_1 = bit.rshift(arg_10_1, 7)
	end

	arg_10_0:writeByte(var_10_0)
end

function var_0_0._decodeVarint(arg_11_0)
	local var_11_0 = 0
	local var_11_1 = 0
	local var_11_2

	while arg_11_0._pos <= #arg_11_0._buf do
		local var_11_3 = arg_11_0:readByte()

		var_11_0 = bit.bor(var_11_0, bit.lshift(bit.band(var_11_3, 127), var_11_1))

		if bit.band(var_11_3, 128) == 0 then
			return var_11_0
		end

		var_11_1 = var_11_1 + 7

		assert(var_11_1 < 32, "Varint decode error! 32bit bitwise is unavailable in BitOp!")
	end

	error("Read variant at EOF!")
end

return var_0_0
