local table = require(script.Parent.Table)

local String = {}

String.find = string.find
String.sub = string.sub
String.char = string.char
String.split = string.split
String.lower = string.lower
String.gsub = string.gsub
String.unpack = string.unpack
String.reverse = string.reverse
String.pack = string.pack
String.gmatch = string.gmatch
String.upper = string.upper
String.len = string.len
String.rep = string.rep
String.byte = string.byte
String.match = string.match
String.format = string.format
String.packsize = string.packsize

function String.finditer(str:string,sub:string,raw:boolean?):() -> (number?,number?)
	local last_idx = 1
	return function()
		local first_idx, rep_last_idx = String.find(str,sub,last_idx,raw)
		if rep_last_idx then
			last_idx = rep_last_idx+1
		end
		return first_idx, rep_last_idx
	end
end

function String.multifinditer(str:string,subs:{string},raw:boolean?):() -> (string?,number?,number?)
	local last_idx = 1
	return function()
		local lowest_num
		local lowest
		for _, sub in ipairs(subs) do
			local sub_first_idx, sub_last_idx = String.find(str,sub,last_idx,raw)
			if sub_first_idx and sub_last_idx then
				if lowest_num == nil or sub_last_idx < lowest_num then
					lowest_num = sub_last_idx
					lowest = {sub,sub_first_idx,sub_last_idx}
				end
			end
		end
		if lowest then
			last_idx = lowest[3]+1
			return lowest[1], lowest[2], lowest[3]
		else
			return nil, nil, nil
		end
	end
end

function String.findlast(str:string,sub:string,raw:boolean?):(number?,number?)
	local start, end_ = nil, nil
	for loop_start, loop_end in String.finditer(str,sub,raw) do
		start, end_ = loop_start, loop_end
	end
	return start, end_
end

function String.afterfirst(str:string,sub:string,raw:boolean?):string
	local _, after = String.find(str,sub,1,raw)
	if after then
		return String.sub(str,after+1)
	else
		return str
	end
end

function String.afterlast(str:string,sub:string,raw:boolean?):string
	local _, after = String.findlast(str,sub,raw)
	if after then
		return String.sub(str,after+1)
	else
		return str
	end
end

function String.beforefirst(str:string,sub:string,raw:boolean?):string
	local before, _ = String.find(str,sub,1,raw)
	if before then
		return String.sub(str,1,before-1)
	else
		return str
	end
end

function String.beforelast(str:string,sub:string,raw:boolean?):string
	local before, _ = String.findlast(str,sub,raw)
	if before then
		return String.sub(str,1,before-1)
	else
		return str
	end
end

function String.contains(str:string,sub:string):boolean
	return String.find(str,sub) ~= nil
end

function String.startswith(str:string,sub:string):boolean
	return String.sub(str,1,#sub) == sub
end

function String.endswith(str:string,sub:string):boolean
	return String.sub(str,-#sub,-1) == sub
end

function String.multisplit(str:string,subs:{string},raw:boolean?):{string}
	local start = 1
	local got = {}
	for _, _, i in String.multifinditer(str,subs,raw) do
		table.insert(got,String.sub(str,start,i-1))
		start = i+1
	end
	table.insert(got,String.sub(str,start,-1))
	return got
end

function String.fields(str:string):{string}
	return table.filterarr(String.multisplit(str,{'\t'," "}),function(_,val)
		return val ~= ""
	end)
end

function String.findbetween(str:string,start:string,end_:string):string
	local start_idx = select(2,String.find(str,start,nil,true))
	local end_idx = String.findlast(str,end_)
	if start_idx and end_idx then
		return String.sub(str,start_idx+1,end_idx-1)
	end
	return ""
end

function String.characters(str:string):{string}
	return String.split(str,"")
end

function String.indentwidth(str:string):number
	local amount = 0
	for _, char in ipairs(String.characters(str)) do
		if char == " " or char == "\t" then
			amount += 1
		else
			break
		end
	end
	return amount
end

function String.isascii(str:string):boolean
	for _, char in ipairs(String.characters(str)) do
		local byte = String.byte(char)
		if byte > 127 then
			return false
		end
	end
	return true
end

function String.islower(str:string):boolean
	return str == String.lower(str)
end

function String.isupper(str:string):boolean
	return str == String.upper(str)
end

function String.tabstospaces(str:string,space_amount:number):string
	local str = String.gsub(str,"\t",String.rep(" ",space_amount))
	return str
end

function String.splitnth(str:string,sub:string,nth:number,raw:boolean?):(string,string)
	local current_nth = 1
	local found = false
	local start, end_ = nil, nil
	for loop_start, loop_end in String.finditer(str,sub,raw) do
		start, end_ = loop_start, loop_end
		if current_nth == nth then
			found = true
			break
		end
		current_nth += 1
	end
	if found then
		return String.sub(str,1,start-1), String.sub(str,end_+1,-1)
	else
		return str, ""
	end
end

function String.splitonce(str:string,sub:string,raw:boolean?)
	return String.splitnth(str,sub,1,raw)
end

function String.trim(str:string):string
	local first_char, last_char
	local chars = String.characters(str)
	for i = 1,#chars do
		local char = chars[i]
		if char ~= " " and char ~= "\t" and char ~= "\n" then
			first_char = i
			break
		end
	end
	for i = #chars,1,-1 do
		local char = chars[i]
		if char ~= " " and char ~= "\t" and char ~= "\n" then
			last_char = i
			break
		end
	end
	return String.sub(str,first_char,last_char)
end

function String.trimleft(str:string):string
	local first_char
	local chars = String.characters(str)
	for i = 1,#chars do
		local char = chars[i]
		if char ~= " " and char ~= "\t" and char ~= "\n" then
			first_char = i
			break
		end
	end
	return String.sub(str,first_char,-1)
end

function String.trimright(str:string):string
	local last_char
	local chars = String.characters(str)
	for i = #chars,1,-1 do
		local char = chars[i]
		if char ~= " " and char ~= "\t" and char ~= "\n" then
			last_char = i
			break
		end
	end
	return String.sub(str,1,last_char)
end

return String
