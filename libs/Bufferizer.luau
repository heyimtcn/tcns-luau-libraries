--!nocheck

local table = require(script.Parent.Table)

local ValueType = {
	["nil"] = 0,
	u8 = 1,
	u16 = 2,
	u32 = 3,
	i8 = 4,
	i16 = 5,
	i32 = 6,
	f64 = 7,
	["true"] = 8,
	["false"] = 9,
	string = 10,
	Vector2 = 11,
	Vector3 = 12,
	UDim = 13,
	UDim2 = 14,
	CFrame = 15,
	Color3 = 16,
	BrickColor = 17,
	Ray = 18,
	EnumItem = 19,
	Instance = 20,
	EmptyTable = 21,
	Array = 22,
	Dictionary = 23,
	Buffer = 24,
	Player = 25,
	inf = 26,
	nan = 27,
	pi = 28
}

local Bufferizer = {
	ValueType = ValueType
}

local function array_size(arr:{any}):number
	local size = 4 --2 + 2 (lenght + size)
	for _, val in arr do
		local val_size = select(2,Bufferizer.get_value_type(val))
		size += 1 + val_size
	end
	return size
end

local BufferSize:{[number]:(val:any?) -> number|number} = {
	[ValueType["nil"]] = 0,
	[ValueType.u8] = 1,
	[ValueType.u16] = 2,
	[ValueType.u32] = 4,
	[ValueType.i8] = 1,
	[ValueType.i16] = 2,
	[ValueType.i32] = 4,
	[ValueType.f64] = 8,
	[ValueType["true"]] = 0,
	[ValueType["false"]] = 0,
	[ValueType.string] = function(str:string)
		return buffer.len(buffer.fromstring(str)) + 2
	end,
	[ValueType.Vector2] = 16,
	[ValueType.Vector3] = 24,
	[ValueType.UDim] = 6,
	[ValueType.UDim2] = 12,
	[ValueType.CFrame] = 48,
	[ValueType.Color3] = 6,
	[ValueType.BrickColor] = 2,
	[ValueType.Ray] = 36,
	[ValueType.EnumItem] = 4,
	[ValueType.Instance] = function(inst:Instance)
		return buffer.len(buffer.fromstring(inst:GetFullName())) + 2
	end,
	[ValueType.EmptyTable] = 0,
	[ValueType.Array] = function(arr:{any})
		return array_size(arr)
	end,
	[ValueType.Dictionary] = function(dict:{[any]:any})
		local arr = table.flatmap(table.keys(dict),function(val)
			return {val, dict[val]}
		end)
		return array_size(arr)
	end,
	[ValueType.Buffer] = function(buf:buffer)
		return buffer.len(buf) + 2
	end,
	[ValueType.Player] = 8,
	[ValueType.inf] = 0,
	[ValueType.nan] = 0,
	[ValueType.pi] = 0
}

Bufferizer.BufferSize = BufferSize

function Bufferizer.from_bytes(arr:{number}):buffer
	assert(table.all(arr,function(_, val)
		if type(val) ~= "number" then
			return false
		end
		return val < 256
	end),"invalid array")
	local buf = buffer.create(#arr)
	local offset = 0
	for _, val in arr do
		buffer.writeu8(buf,offset,val)
		offset += 1
	end
	return buf
end

function Bufferizer.to_bytes(buf:buffer):{number}
	local buf_len = buffer.len(buf)
	local arr = {}
	local offset = 0
	while offset < buf_len do
		table.insert(arr,buffer.readu8(buf,offset))
		offset += 1
	end
	return arr
end

function Bufferizer.get_value_type(val:any):(number,number)
	local buf_size = 0
	local val_type = -1
	local typ = typeof(val)
	if typ == "nil" then
		val_type = ValueType["nil"]
	elseif typ == "boolean" then
		if val then
			val_type = ValueType["true"]
		else
			val_type = ValueType["false"]
		end
	elseif typ == "number" then
		if val == math.huge then
			val_type = ValueType.inf
			buf_size = BufferSize[val_type]
		elseif tostring(val) == "nan" then
			val_type = ValueType.nan
			buf_size = BufferSize[val_type]
		elseif val == math.pi then
			val_type = ValueType.pi
			buf_size = BufferSize[val_type]
		elseif math.floor(val) == val then
			if val < 0 then
				if val > -(2^7) then
					val_type = ValueType.i8
					buf_size = BufferSize[val_type]
				elseif val > -(2^15) then
					val_type = ValueType.i16
					buf_size = BufferSize[val_type]
				else
					val_type = ValueType.i32
					buf_size = BufferSize[val_type]
				end
			else
				if val < 2^8 then
					val_type = ValueType.u8
					buf_size = BufferSize[val_type]
				elseif val < 2^16 then
					val_type = ValueType.u16
					buf_size = BufferSize[val_type]
				else
					val_type = ValueType.u32
					buf_size = BufferSize[val_type]
				end
			end
		else
			val_type = ValueType.f64
			buf_size = BufferSize[val_type]
		end
	elseif typ == "string" then
		val_type = ValueType.string
		buf_size = BufferSize[val_type](val)
	elseif typ == "Vector2" then
		val_type = ValueType.Vector2
		buf_size = BufferSize[val_type]
	elseif typ == "Vector3" then
		val_type = ValueType.Vector3
		buf_size = BufferSize[val_type]
	elseif typ == "UDim" then
		val_type = ValueType.UDim
		buf_size = BufferSize[val_type]
	elseif typ == "UDim2" then
		val_type = ValueType.UDim2
		buf_size = BufferSize[val_type]
	elseif typ == "CFrame" then
		val_type = ValueType.CFrame
		buf_size = BufferSize[val_type]
	elseif typ == "Color3" then
		val_type = ValueType.Color3
		buf_size = BufferSize[val_type]
	elseif typ == "BrickColor" then
		val_type = ValueType.BrickColor
		buf_size = BufferSize[val_type]
	elseif typ == "Ray" then
		val_type = ValueType.Ray
		buf_size = BufferSize[val_type]
	elseif typ == "EnumItem" then
		val_type = ValueType.EnumItem
		buf_size = BufferSize[val_type]
	elseif typ == "Instance" then
		if val:IsA("Player") then
			val_type = ValueType.Player
			buf_size = BufferSize[val_type]
		else
			val_type = ValueType.Instance
			buf_size = BufferSize[val_type](val)
		end
	elseif typ == "table" then
		local tbl_type:"array"|"dict"|"empty"|"mixed" = table.gettype(val)
		if tbl_type == "empty" then
			val_type = ValueType.EmptyTable
			buf_size = BufferSize[val_type]
		elseif tbl_type == "array" then
			val_type = ValueType.Array
			buf_size = BufferSize[val_type](val)
		elseif tbl_type == "dict" or tbl_type == "mixed" then
			val_type = ValueType.Dictionary
			buf_size = BufferSize[val_type](val)
		end
	elseif typ == "buffer" then
		val_type = ValueType.Buffer
		buf_size = BufferSize[val_type](val)
	end
	return val_type, buf_size
end

function Bufferizer.bufferize(val):buffer?
	local val_type, buf_size = Bufferizer.get_value_type(val)
	if val_type == -1 then
		return nil
	end
	local buf = buffer.create(buf_size + 1)
	buffer.writeu8(buf,0,val_type)
	local function write_arr(arr:{any})
		local offset = 1
		buffer.writeu16(buf,offset,buf_size - 2) --exclude size
		offset += 2
		buffer.writeu16(buf,offset,#arr)
		offset += 2
		for _, arr_val in arr do
			local iter_buf = Bufferizer.bufferize(arr_val)
			local iter_buf_len = buffer.len(iter_buf)
			buffer.copy(buf,offset,iter_buf,0,iter_buf_len)
			offset += iter_buf_len
		end
	end
	if val_type == ValueType["nil"] then
	elseif val_type == ValueType.u8 then
		buffer.writeu8(buf,1,val)
	elseif val_type == ValueType.u16 then
		buffer.writeu16(buf,1,val)
	elseif val_type == ValueType.u32 then
		buffer.writeu32(buf,1,val)
	elseif val_type == ValueType.i8 then
		buffer.writei8(buf,1,val)
	elseif val_type == ValueType.i16 then
		buffer.writei16(buf,1,val)
	elseif val_type == ValueType.i32 then
		buffer.writei32(buf,1,val)
	elseif val_type == ValueType.f64 then
		buffer.writef64(buf,1,val)
	elseif val_type == ValueType["true"] or val_type == ValueType["false"] then
	elseif val_type == ValueType.string then
		local str_buf = buffer.fromstring(val)
		local str_len = buffer.len(str_buf)
		buffer.writeu16(buf,1,str_len) --string lenght
		buffer.copy(buf,3,str_buf,0,str_len)
	elseif val_type == ValueType.Vector2 then
		buffer.writef64(buf,1,val.X)
		buffer.writef64(buf,9,val.Y)
	elseif val_type == ValueType.Vector3 then
		buffer.writef64(buf,1,val.X)
		buffer.writef64(buf,9,val.Y)
		buffer.writef64(buf,17,val.Z)
	elseif val_type == ValueType.UDim then
		buffer.writef32(buf,1,val.Scale)
		buffer.writeu16(buf,5,val.Offset)
	elseif val_type == ValueType.UDim2 then
		buffer.writef32(buf,1,val.X.Scale)
		buffer.writeu16(buf,5,val.X.Offset)
		buffer.writef32(buf,7,val.Y.Scale)
		buffer.writeu16(buf,11,val.Y.Offset)
	elseif val_type == ValueType.CFrame then
		buffer.writef64(buf,1,val.X)
		buffer.writef64(buf,9,val.Y)
		buffer.writef64(buf,17,val.Z)
		buffer.writef32(buf,25,val.LookVector.X)
		buffer.writef32(buf,29,val.LookVector.Y)
		buffer.writef32(buf,33,val.LookVector.Z)
		buffer.writef32(buf,37,val.UpVector.X)
		buffer.writef32(buf,41,val.UpVector.Y)
		buffer.writef32(buf,45,val.UpVector.Z)
	elseif val_type == ValueType.Color3 then
		buffer.writestring(buf,1,val:ToHex())
	elseif val_type == ValueType.BrickColor then
		buffer.writeu16(buf,1,val.Number)
	elseif val_type == ValueType.Ray then
		buffer.writef64(buf,1,val.Origin.X)
		buffer.writef64(buf,9,val.Origin.Y)
		buffer.writef64(buf,17,val.Origin.Z)
		buffer.writef32(buf,25,val.Direction.X)
		buffer.writef32(buf,29,val.Direction.Y)
		buffer.writef32(buf,33,val.Direction.Z)
	elseif val_type == ValueType.EnumItem then
		local enum_name = tostring(val.EnumType)
		local enum_index = table.findfirstfn(Enum:GetEnums(),function(el)
			return tostring(el) == enum_name
		end)
		buffer.writeu16(buf,1,enum_index)
		buffer.writeu16(buf,3,val.Value)
	elseif val_type == ValueType.Instance then
		local str_buf = buffer.fromstring(val:GetFullName())
		local str_len = buffer.len(str_buf)
		buffer.writeu16(buf,1,str_len) --full name lenght
		buffer.copy(buf,3,str_buf,0,str_len)
	elseif val_type == ValueType.EmptyTable then
	elseif val_type == ValueType.Array then
		write_arr(val)
	elseif val_type == ValueType.Dictionary then
		local arr = table.flatmap(table.keys(val),function(key)
			return {key, val[key]}
		end)
		write_arr(arr)
	elseif val_type == ValueType.Buffer then
		local encoded_buf_len = buffer.len(val)
		buffer.writeu16(buf,1,encoded_buf_len)
		buffer.copy(buf,3,val,0,encoded_buf_len)
	elseif val_type == ValueType.Player then
		buffer.writef64(buf,1,val.UserId)
	elseif val_type == ValueType.inf then
	elseif val_type == ValueType.nan then
	elseif val_type == ValueType.pi then
	end
	return buf
end

function Bufferizer.extract(buf:buffer):any?
	local buf_len = buffer.len(buf)
	local val_type = buffer.readu8(buf,0)
	local function get_array()
		local arr = {}
		local elem_amount = buffer.readu16(buf,3)
		local offset = 5
		local elems_done = 0
		while elems_done < elem_amount do
			local val_type = buffer.readu8(buf,offset)
			local buf_size
			--print("val_type",val_type)
			if type(BufferSize[val_type]) == "function" then
				buf_size = buffer.readu16(buf,offset + 1) + 3 --1 + 2 (type + size)
			else
				buf_size = BufferSize[val_type] + 1
			end
			--print("buf_size",buf_size)
			local val_buff = buffer.create(buf_size)
			buffer.copy(val_buff,0,buf,offset,buf_size)
			--print(elems_done,Bufferizer.to_bytes(val_buff),arr)
			local iter_val = Bufferizer.extract(val_buff)
			--print("iter_val",iter_val)
			table.insert(arr,iter_val)
			elems_done += 1
			offset += buf_size
		end
		return arr
	end
	if val_type == ValueType["nil"] then
		return nil
	elseif val_type == ValueType.u8 then
		return buffer.readu8(buf,1)
	elseif val_type == ValueType.u16 then
		return buffer.readu16(buf,1)
	elseif val_type == ValueType.u32 then
		return buffer.readu32(buf,1)
	elseif val_type == ValueType.i8 then
		return buffer.readi8(buf,1)
	elseif val_type == ValueType.i16 then
		return buffer.readi16(buf,1)
	elseif val_type == ValueType.i32 then
		return buffer.readi32(buf,1)
	elseif val_type == ValueType.f64 then
		return buffer.readf64(buf,1)
	elseif val_type == ValueType["true"] then
		return true
	elseif val_type == ValueType["false"] then
		return false
	elseif val_type == ValueType.string then
		return buffer.readstring(buf,3,buffer.readu16(buf,1))
	elseif val_type == ValueType.Vector2 then
		return Vector2.new(buffer.readf64(buf,1),buffer.readf64(buf,9))
	elseif val_type == ValueType.Vector3 then
		return Vector3.new(buffer.readf64(buf,1),buffer.readf64(buf,9),buffer.readf64(buf,17))
	elseif val_type == ValueType.UDim then
		return UDim.new(buffer.readf32(buf,1),buffer.readu16(buf,5))
	elseif val_type == ValueType.UDim2 then
		return UDim2.new(buffer.readf32(buf,1),buffer.readu16(buf,5),buffer.readf32(buf,7),buffer.readu16(buf,11))
	elseif val_type == ValueType.CFrame then
		local pos = Vector3.new(buffer.readf64(buf,1),buffer.readf64(buf,9),buffer.readf64(buf,17))
		local look_at = Vector3.new(buffer.readf32(buf,25),buffer.readf32(buf,29),buffer.readf32(buf,33))
		local up_vec = Vector3.new(buffer.readf32(buf,37),buffer.readf32(buf,41),buffer.readf32(buf,45))
		return CFrame.lookAt(pos,pos + look_at,up_vec)
	elseif val_type == ValueType.Color3 then
		return Color3.fromHex(buffer.readstring(buf,1,6))
	elseif val_type == ValueType.BrickColor then
		return BrickColor.new(buffer.readu16(buf,1))
	elseif val_type == ValueType.Ray then
		local origin = Vector3.new(buffer.readf64(buf,1),buffer.readf64(buf,9),buffer.readf64(buf,17))
		local direction = Vector3.new(buffer.readf32(buf,25),buffer.readf32(buf,29),buffer.readf32(buf,33))
		return Ray.new(origin,direction)
	elseif val_type == ValueType.EnumItem then
		local enum_index = buffer.readu16(buf,1)
		local val = buffer.readu16(buf,3)
		return select(2,table.findfirstfn(Enum:GetEnums()[enum_index]:GetEnumItems(),function(enum_item)
			return enum_item.Value == val
		end))
	elseif val_type == ValueType.Instance then
		local path = buffer.readstring(buf,3,buffer.readu16(buf,1))
		local inst = game
		for _, name in path:split(".") do
			local loop_inst = inst:FindFirstChild(name)
			if loop_inst then
				inst = loop_inst
			else
				return nil
			end
		end
		return inst
	elseif val_type == ValueType.EmptyTable then
		return {}
	elseif val_type == ValueType.Array then
		return get_array()
	elseif val_type == ValueType.Dictionary then
		local arr = get_array()
		local dict = {}
		local i = 1
		while i < #arr do
			dict[arr[i]] = arr[i+1]
			i += 2
		end
		return dict
	elseif val_type == ValueType.Buffer then
		local new_buf_size = buffer.readu16(buf,1)
		local new_buf = buffer.create(new_buf_size)
		buffer.copy(new_buf,0,buf,3,new_buf_size)
		return new_buf
	elseif val_type == ValueType.Player then
		return game.Players:GetPlayerByUserId(buffer.readf64(buf,1))
	elseif val_type == ValueType.inf then
		return math.huge
	elseif val_type == ValueType.nan then
		return tonumber("nan")
	elseif val_type == ValueType.pi then
		return math.pi
	end
	return nil
end

return Bufferizer
