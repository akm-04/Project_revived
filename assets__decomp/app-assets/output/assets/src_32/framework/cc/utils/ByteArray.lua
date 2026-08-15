local var_0_0 = class("ByteArray")

var_0_0.ENDIAN_LITTLE = "ENDIAN_LITTLE"
var_0_0.ENDIAN_BIG = "ENDIAN_BIG"
var_0_0.radix = {
	[16] = "%02X",
	[10] = "%03u",
	[8] = "%03o"
}

require("pack")

function var_0_0.toString(arg_1_0, arg_1_1, arg_1_2)
	arg_1_1 = arg_1_1 or 16
	arg_1_1 = var_0_0.radix[arg_1_1] or "%02X"
	arg_1_2 = arg_1_2 or " "

	local var_1_0 = arg_1_1 .. arg_1_2

	local function var_1_1(arg_2_0)
		return string.format(var_1_0, string.byte(arg_2_0))
	end

	if type(arg_1_0) == "string" then
		return string.gsub(arg_1_0, "(.)", var_1_1)
	end

	local var_1_2 = {}

	for iter_1_0 = 1, #arg_1_0._buf do
		var_1_2[iter_1_0] = var_1_1(arg_1_0._buf[iter_1_0])
	end

	return table.concat(var_1_2), #var_1_2
end

function var_0_0.ctor(arg_3_0, arg_3_1)
	arg_3_0._endian = arg_3_1
	arg_3_0._buf = {}
	arg_3_0._pos = 1
end

function var_0_0.getLen(arg_4_0)
	return #arg_4_0._buf
end

function var_0_0.getAvailable(arg_5_0)
	return #arg_5_0._buf - arg_5_0._pos + 1
end

function var_0_0.getPos(arg_6_0)
	return arg_6_0._pos
end

function var_0_0.setPos(arg_7_0, arg_7_1)
	arg_7_0._pos = arg_7_1

	return arg_7_0
end

function var_0_0.getEndian(arg_8_0)
	return arg_8_0._endian
end

function var_0_0.setEndian(arg_9_0, arg_9_1)
	arg_9_0._endian = arg_9_1
end

function var_0_0.getBytes(arg_10_0, arg_10_1, arg_10_2)
	arg_10_1 = arg_10_1 or 1
	arg_10_2 = arg_10_2 or #arg_10_0._buf

	return table.concat(arg_10_0._buf, "", arg_10_1, arg_10_2)
end

function var_0_0.getPack(arg_11_0, arg_11_1, arg_11_2)
	arg_11_1 = arg_11_1 or 1
	arg_11_2 = arg_11_2 or #arg_11_0._buf

	local var_11_0 = {}

	for iter_11_0 = arg_11_1, arg_11_2 do
		var_11_0[#var_11_0 + 1] = string.byte(arg_11_0._buf[iter_11_0])
	end

	local var_11_1 = arg_11_0:_getLC("b" .. #var_11_0)

	return (string.pack(var_11_1, unpack(var_11_0)))
end

function var_0_0.rawPack(arg_12_0, arg_12_1, ...)
	local var_12_0 = string.pack(arg_12_1, ...)

	arg_12_0:writeBuf(var_12_0)

	return arg_12_0
end

function var_0_0.rawUnPack(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_0:getBytes(arg_13_0._pos)
	local var_13_1, var_13_2 = string.unpack(var_13_0, arg_13_1)

	arg_13_0._pos = arg_13_0._pos + var_13_1

	return var_13_2, var_13_1
end

function var_0_0.readBool(arg_14_0)
	return arg_14_0:readChar() ~= 0
end

function var_0_0.writeBool(arg_15_0, arg_15_1)
	if arg_15_1 then
		arg_15_0:writeByte(1)
	else
		arg_15_0:writeByte(0)
	end

	return arg_15_0
end

function var_0_0.readDouble(arg_16_0)
	local var_16_0, var_16_1 = string.unpack(arg_16_0:readBuf(8), arg_16_0:_getLC("d"))

	return var_16_1
end

function var_0_0.writeDouble(arg_17_0, arg_17_1)
	local var_17_0 = string.pack(arg_17_0:_getLC("d"), arg_17_1)

	arg_17_0:writeBuf(var_17_0)

	return arg_17_0
end

function var_0_0.readFloat(arg_18_0)
	local var_18_0, var_18_1 = string.unpack(arg_18_0:readBuf(4), arg_18_0:_getLC("f"))

	return var_18_1
end

function var_0_0.writeFloat(arg_19_0, arg_19_1)
	local var_19_0 = string.pack(arg_19_0:_getLC("f"), arg_19_1)

	arg_19_0:writeBuf(var_19_0)

	return arg_19_0
end

function var_0_0.readInt(arg_20_0)
	local var_20_0, var_20_1 = string.unpack(arg_20_0:readBuf(4), arg_20_0:_getLC("i"))

	return var_20_1
end

function var_0_0.writeInt(arg_21_0, arg_21_1)
	local var_21_0 = string.pack(arg_21_0:_getLC("i"), arg_21_1)

	arg_21_0:writeBuf(var_21_0)

	return arg_21_0
end

function var_0_0.readUInt(arg_22_0)
	local var_22_0, var_22_1 = string.unpack(arg_22_0:readBuf(4), arg_22_0:_getLC("I"))

	return var_22_1
end

function var_0_0.writeUInt(arg_23_0, arg_23_1)
	local var_23_0 = string.pack(arg_23_0:_getLC("I"), arg_23_1)

	arg_23_0:writeBuf(var_23_0)

	return arg_23_0
end

function var_0_0.readShort(arg_24_0)
	local var_24_0, var_24_1 = string.unpack(arg_24_0:readBuf(2), arg_24_0:_getLC("h"))

	return var_24_1
end

function var_0_0.writeShort(arg_25_0, arg_25_1)
	local var_25_0 = string.pack(arg_25_0:_getLC("h"), arg_25_1)

	arg_25_0:writeBuf(var_25_0)

	return arg_25_0
end

function var_0_0.readUShort(arg_26_0)
	local var_26_0, var_26_1 = string.unpack(arg_26_0:readBuf(2), arg_26_0:_getLC("H"))

	return var_26_1
end

function var_0_0.writeUShort(arg_27_0, arg_27_1)
	local var_27_0 = string.pack(arg_27_0:_getLC("H"), arg_27_1)

	arg_27_0:writeBuf(var_27_0)

	return arg_27_0
end

function var_0_0.readUByte(arg_28_0)
	local var_28_0, var_28_1 = string.unpack(arg_28_0:readRawByte(), "b")

	return var_28_1
end

function var_0_0.writeUByte(arg_29_0, arg_29_1)
	local var_29_0 = string.pack("b", arg_29_1)

	arg_29_0:writeBuf(var_29_0)

	return arg_29_0
end

function var_0_0.readLuaNumber(arg_30_0, arg_30_1)
	local var_30_0, var_30_1 = string.unpack(arg_30_0:readBuf(8), arg_30_0:_getLC("n"))

	return var_30_1
end

function var_0_0.writeLuaNumber(arg_31_0, arg_31_1)
	local var_31_0 = string.pack(arg_31_0:_getLC("n"), arg_31_1)

	arg_31_0:writeBuf(var_31_0)

	return arg_31_0
end

function var_0_0.readStringBytes(arg_32_0, arg_32_1)
	assert(arg_32_1, "Need a length of the string!")

	if arg_32_1 == 0 then
		return ""
	end

	arg_32_0:_checkAvailable()

	local var_32_0, var_32_1 = string.unpack(arg_32_0:readBuf(arg_32_1), arg_32_0:_getLC("A" .. arg_32_1))

	return var_32_1
end

function var_0_0.writeStringBytes(arg_33_0, arg_33_1)
	local var_33_0 = string.pack(arg_33_0:_getLC("A"), arg_33_1)

	arg_33_0:writeBuf(var_33_0)

	return arg_33_0
end

function var_0_0.readString(arg_34_0, arg_34_1)
	assert(arg_34_1, "Need a length of the string!")

	if arg_34_1 == 0 then
		return ""
	end

	arg_34_0:_checkAvailable()

	return arg_34_0:readBuf(arg_34_1)
end

function var_0_0.writeString(arg_35_0, arg_35_1)
	arg_35_0:writeBuf(arg_35_1)

	return arg_35_0
end

function var_0_0.readStringUInt(arg_36_0)
	arg_36_0:_checkAvailable()

	local var_36_0 = arg_36_0:readUInt()

	return arg_36_0:readStringBytes(var_36_0)
end

function var_0_0.writeStringUInt(arg_37_0, arg_37_1)
	arg_37_0:writeUInt(#arg_37_1)
	arg_37_0:writeStringBytes(arg_37_1)

	return arg_37_0
end

function var_0_0.readStringSizeT(arg_38_0)
	arg_38_0:_checkAvailable()

	return (arg_38_0:rawUnPack(arg_38_0:_getLC("a")))
end

function var_0_0.writeStringSizeT(arg_39_0, arg_39_1)
	arg_39_0:rawPack(arg_39_0:_getLC("a"), arg_39_1)

	return arg_39_0
end

function var_0_0.readStringUShort(arg_40_0)
	arg_40_0:_checkAvailable()

	local var_40_0 = arg_40_0:readUShort()

	return arg_40_0:readStringBytes(var_40_0)
end

function var_0_0.writeStringUShort(arg_41_0, arg_41_1)
	local var_41_0 = string.pack(arg_41_0:_getLC("P"), arg_41_1)

	arg_41_0:writeBuf(var_41_0)

	return arg_41_0
end

function var_0_0.readBytes(arg_42_0, arg_42_1, arg_42_2, arg_42_3)
	assert(iskindof(arg_42_1, "ByteArray"), "Need a ByteArray instance!")

	local var_42_0 = #arg_42_0._buf
	local var_42_1 = var_42_0 - arg_42_0._pos

	arg_42_2 = arg_42_2 or 1

	if var_42_0 < arg_42_2 then
		arg_42_2 = 1
	end

	arg_42_3 = arg_42_3 or 0

	if arg_42_3 == 0 or var_42_1 < arg_42_3 then
		arg_42_3 = var_42_1
	end

	arg_42_1:setPos(arg_42_2)

	for iter_42_0 = arg_42_2, arg_42_2 + arg_42_3 do
		arg_42_1:writeRawByte(arg_42_0:readRawByte())
	end
end

function var_0_0.writeBytes(arg_43_0, arg_43_1, arg_43_2, arg_43_3)
	assert(iskindof(arg_43_1, "ByteArray"), "Need a ByteArray instance!")

	local var_43_0 = arg_43_1:getLen()

	if var_43_0 == 0 then
		return
	end

	arg_43_2 = arg_43_2 or 1

	if var_43_0 < arg_43_2 then
		arg_43_2 = 1
	end

	local var_43_1 = var_43_0 - arg_43_2

	arg_43_3 = arg_43_3 or var_43_1

	if arg_43_3 == 0 or var_43_1 < arg_43_3 then
		arg_43_3 = var_43_1
	end

	local var_43_2 = arg_43_1:getPos()

	arg_43_1:setPos(arg_43_2)

	for iter_43_0 = arg_43_2, arg_43_2 + arg_43_3 do
		arg_43_0:writeRawByte(arg_43_1:readRawByte())
	end

	arg_43_1:setPos(var_43_2)

	return arg_43_0
end

function var_0_0.readChar(arg_44_0)
	local var_44_0, var_44_1 = string.unpack(arg_44_0:readRawByte(), "c")

	return var_44_1
end

function var_0_0.writeChar(arg_45_0, arg_45_1)
	arg_45_0:writeRawByte(string.pack("c", arg_45_1))

	return arg_45_0
end

function var_0_0.readByte(arg_46_0)
	return string.byte(arg_46_0:readRawByte())
end

function var_0_0.writeByte(arg_47_0, arg_47_1)
	arg_47_0:writeRawByte(string.char(arg_47_1))

	return arg_47_0
end

function var_0_0.readRawByte(arg_48_0)
	arg_48_0:_checkAvailable()

	local var_48_0 = arg_48_0._buf[arg_48_0._pos]

	arg_48_0._pos = arg_48_0._pos + 1

	return var_48_0
end

function var_0_0.writeRawByte(arg_49_0, arg_49_1)
	if arg_49_0._pos > #arg_49_0._buf + 1 then
		for iter_49_0 = #arg_49_0._buf + 1, arg_49_0._pos - 1 do
			arg_49_0._buf[iter_49_0] = string.char(0)
		end
	end

	arg_49_0._buf[arg_49_0._pos] = string.sub(arg_49_1, 1, 1)
	arg_49_0._pos = arg_49_0._pos + 1

	return arg_49_0
end

function var_0_0.readBuf(arg_50_0, arg_50_1)
	local var_50_0 = arg_50_0:getBytes(arg_50_0._pos, arg_50_0._pos + arg_50_1 - 1)

	arg_50_0._pos = arg_50_0._pos + arg_50_1

	return var_50_0
end

function var_0_0.writeBuf(arg_51_0, arg_51_1)
	for iter_51_0 = 1, #arg_51_1 do
		arg_51_0:writeRawByte(string.sub(arg_51_1, iter_51_0, iter_51_0))
	end

	return arg_51_0
end

function var_0_0._checkAvailable(arg_52_0)
	assert(#arg_52_0._buf >= arg_52_0._pos, string.format("End of file was encountered. pos: %d, len: %d.", arg_52_0._pos, #arg_52_0._buf))
end

function var_0_0._getLC(arg_53_0, arg_53_1)
	arg_53_1 = arg_53_1 or ""

	if arg_53_0._endian == var_0_0.ENDIAN_LITTLE then
		return "<" .. arg_53_1
	elseif arg_53_0._endian == var_0_0.ENDIAN_BIG then
		return ">" .. arg_53_1
	end

	return "=" .. arg_53_1
end

return var_0_0
