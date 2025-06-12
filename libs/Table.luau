local Table = {}

Table.find = table.find
Table.clone = table.clone
Table.remove = table.remove
Table.insert = table.insert
Table.unpack = table.unpack
Table.concat = table.concat
Table.sort = table.sort
Table.clear = table.clear
Table.create = table.create
Table.move = table.move
Table.maxn = table.maxn
Table.pack = table.pack
Table.freeze = table.freeze
Table.isfrozen = table.isfrozen

function clone_value(val:any):any
	if type(val) == "table" then
		return Table.clone(val)
	end
	return val
end

--slightly modified function by XAXA (https://devforum.roblox.com/t/detecting-type-of-table-empty-array-dictionary-mixedtable/292323/15)
function Table.gettype(tbl:{[any]:any?}):"empty"|"array"|"dict"|"mixed"
	if next(tbl) == nil then return "empty" end
	local is_arr = true
	local is_dict = true
	for k, _ in next, tbl do
		if typeof(k) == "number" and k%1 == 0 and k > 0 then
			is_dict = false
		else
			is_arr = false
		end
	end
	if is_arr then
		return "array"
	elseif is_dict then
		return "dict"
	else
		return "mixed"
	end
end

function Table.setnget<T,U>(tbl:{T:U},key:T,val:U):U
	tbl[key] = val
	return val
end

function Table.insertnget<T>(arr:{T},val:T):T
	Table.insert(arr,val)
	return val
end

function Table.repeattimes<T>(arr:{T},count:number,same_arr:boolean?):{T}
	local new_arr = if same_arr then arr else Table.clone(arr)
	local current_values = Table.clone(new_arr)
	for count_idx = 0,count-1 do
		for current_values_idx, current_values_val in ipairs(current_values) do
			new_arr[count_idx * #current_values + current_values_idx] = if count_idx == 0 then current_values_val else clone_value(current_values_val)	
		end
	end
	return new_arr
end

function Table.first<T>(arr:{T}):T
	return arr[1]
end

function Table.last<T>(arr:{T}):T
	return arr[#arr]
end

function Table.prepend<T>(arr:{T},val:T)
	Table.insert(arr,1,val)
end

function Table.removemany<T>(arr:{T},idx:number,size:number)
	for i = math.min(idx+size,#arr),idx,-1 do
		Table.remove(arr,i)
	end
end

function Table.slice<T>(arr:{T},from:number,to:number,same_arr:boolean?):{T}
	if from < 0 then
		from = #arr - (math.abs(from) % #arr)
	end
	if to < 0 then
		to = #arr - (math.abs(to) % #arr)
	end
	from = math.max(from,1)
	to = math.min(to,#arr)
	local new_arr = if same_arr then arr else {}
	local current_values = Table.clone(arr)
	Table.clear(new_arr)
	for i = from,to do
		Table.insert(new_arr,current_values[i])
	end
	return new_arr
end

function Table.pop<T>(arr:{T}):T
	local val = arr[#arr]
	Table.remove(arr,#arr)
	return val
end

function Table.deepclone<T>(tbl:T):T
	local function clone(c_tbl)
		c_tbl = Table.clone(c_tbl)
		for key, val in pairs(c_tbl) do
			if type(val) == "table" then
				c_tbl[key] = clone(val)
			end
		end
		return c_tbl
	end
	return clone(tbl)
end

function Table.reverse<T>(arr:{T},same_arr:boolean?):{T}
	local new_arr = if same_arr then arr else {}
	local current_values = Table.clone(arr)
	Table.clear(new_arr)
	for i = 1,#current_values do
		new_arr[#current_values-i+1] = current_values[i]
	end
	return new_arr
end

function Table.filter<T,U>(tbl:{[T]:U},fn:(key:T,val:U) -> boolean,same_tbl:boolean?):{[T]:U}
	local new_tbl = if same_tbl then tbl else Table.clone(tbl)
	for key, value in pairs(new_tbl) do
		new_tbl[key] = if fn(key,value) then new_tbl[key] else nil
	end
	return new_tbl
end

function Table.filterarr<T>(arr:{T},fn:(index:number,val:T) -> boolean,same_arr:boolean?):{T}
	local new_arr = if same_arr then arr else {}
	local current_values = Table.clone(arr)
	Table.clear(new_arr)
	for key, value in ipairs(current_values) do
		if fn(key,value) then
			Table.insert(new_arr,current_values[key])
		end
	end
	return new_arr
end

function Table.any<T,U>(tbl:{[T]:U},fn:(key:T,val:U) -> boolean):boolean
	for key, value in pairs(tbl) do
		if fn(key,value) then
			return true
		end
	end
	return false
end

function Table.count<T,U>(tbl:{[T]:U},fn:(key:T,val:U) -> boolean):number
	local amount = 0
	for key, value in pairs(tbl) do
		if fn(key,value) then
			amount += 1
		end
	end
	return amount
end

function Table.all<T,U>(tbl:{[T]:U},fn:(key:T,val:U) -> boolean):boolean
	for key, value in pairs(tbl) do
		if not fn(key,value) then
			return false
		end
	end
	return true
end

function Table.map<A,B,C,D>(tbl:{[A]:B},fn:(key:A,val:B) -> (C,D),same_tbl:boolean?):{[C]:D}
	local new_tbl = if same_tbl then tbl else {}
	local current_values = Table.clone(tbl)
	Table.clear(new_tbl)
	for key, value in pairs(current_values) do
		local new_key, new_value = fn(key,value)
		if new_key ~= nil then
			new_tbl[new_key] = new_value
		end
	end
	return new_tbl
end

function Table.arrmap<A,B>(arr:{A},fn:(val:A) -> B,same_arr:boolean?):{B}
	local new_arr = if same_arr then arr else {}
	local current_values = Table.clone(arr)
	Table.clear(new_arr)
	for _, value in pairs(current_values) do
		local new_value = fn(value)
		if new_value ~= nil then
			Table.insert(new_arr,new_value)
		end
	end
	return new_arr
end

function Table.flatmap<A,B>(arr:{A},fn:(val:A) -> {B},same_arr:boolean?):{B}
	local new_arr = if same_arr then arr else {}
	local current_values = Table.clone(arr)
	Table.clear(new_arr)
	for _, value in pairs(current_values) do
		local new_value = fn(value)
		if new_value ~= nil then
			if type(new_value) == "table" then
				for _, unwrapped in ipairs(new_value) do
					Table.insert(new_arr,unwrapped)
				end
			else
				Table.insert(new_arr,new_value)
			end
		end
	end
	return new_arr
end

function Table.pair<T,U>(keys:{T},values:{U}):{[T]:U}
	local tbl = {}
	for i = 1,math.min(#keys,#values) do
		tbl[keys[i]] = values[i]
	end
	return tbl
end

function Table.keyof(tbl:{[any]:any},val:any):any?
	for key, tbl_val in pairs(tbl) do
		if tbl_val == val then
			return key
		end
	end
	return nil
end

function Table.merge(...:{[any]:any}):{[any]:any}
	local new_tbl = {}
	for _, tbl in pairs({...}) do
		for key, val in pairs(tbl) do
			new_tbl[key] = val
		end
	end
	return new_tbl
end

function Table.contains<T>(tbl:{[any]:T},val:T):boolean
	for _, tbl_val in pairs(tbl) do
		if tbl_val == val then
			return true
		end
	end
	return false
end

function Table.shuffle<T>(arr:{T},rng:Random?,same_arr:boolean?):{T}
	local shuffled = if same_arr then arr else Table.clone(arr)
	local random = if rng then rng else Random.new()
	for i = #arr, 2, -1 do
		local j = random:NextInteger(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

function Table.sample<T>(arr:{T},size:number,rng:Random?,same_arr:boolean?):{T}
	local new_arr = if same_arr then arr else Table.clone(arr)
	local random = if rng then rng else Random.new()
	Table.shuffle(new_arr,rng,true)
	return Table.slice(new_arr,1,size,same_arr)
end

function Table.random<T>(arr:{T},rng:Random?):T
	local random = if rng then rng else Random.new()
	return arr[random:NextInteger(1,#arr)]
end

function Table.haskey(tbl:{[any]:any},key:any):boolean
	return tbl[key] ~= nil
end

function Table.rawhaskey(tbl:{[any]:any},key:any):boolean
	return rawget(tbl,key) ~= nil
end

function Table.issorted<T>(arr:{T},fn:((a:T,b:T) -> boolean)?):boolean
	local fn = fn or function(a,b)
		return a > b
	end
	for i = 2,#arr do
		if not fn(arr[i],arr[i-1]) then
			return false
		end
	end
	return true
end

function Table.sortedinsert<T>(arr:{T},val:T,fn:((a:T,b:T) -> boolean)?,start_from_end:boolean?)
	local fn = fn or function(a,b)
		return a > b
	end
	if not start_from_end then
		for index, arr_val in ipairs(arr) do
			if fn(arr_val,val) then
				Table.insert(arr,index,val)
				break
			end
		end
	else
		for index = #arr,1,-1 do
			local arr_val = arr[index]
			if fn(val,arr_val) then
				Table.insert(arr,index+1,val)
				break
			end
		end
	end
end

function Table.binarysearch<T>(arr:{T},target:T):number?
	local left = 1
	local right = #arr
	while left <= right do
		local idx = (left + right)//2
		local elem = arr[idx]
		if elem == target then
			return idx
		elseif elem < target then
			left = idx + 1
		else
			right = idx - 1
		end
	end
	return nil
end

function Table.append<T>(arr:{T},...:{T}|boolean):{T}
	local same_arr = select(-1,...) == true
	local app_arrs = {...}
	if same_arr then
		Table.remove(app_arrs,#app_arrs)
	end
	local new_arr = if same_arr then arr else Table.clone(arr)
	for _, app_arr in ipairs(app_arrs) do
		for _, val in ipairs(app_arr) do
			Table.insert(new_arr,val)
		end
	end
	return new_arr
end

function Table.chunk<T>(arr:{T},size:number,same_arr:boolean?):{{T}}
	local new_arr = if same_arr then arr else {}
	local current_values = Table.clone(arr)
	Table.clear(new_arr)
	local chunk_amount = math.ceil(#current_values/size)
	for i = 0,chunk_amount-1 do
		Table.insert(new_arr,Table.slice(current_values,i*size+1,i*size+size))
	end
	return new_arr
end

function Table.distinct<T>(arr:{T},same_arr:boolean?):{T}
	local new_arr = if same_arr then arr else {}
	local current_values = Table.clone(arr)
	Table.clear(new_arr)
	for _, val in ipairs(current_values) do
		if not Table.contains(new_arr,val) then
			Table.insert(new_arr,val)
		end
	end
	return new_arr
end

function Table.removenils<T>(arr:{T},same_arr:boolean?):{T}
	local new_arr = if same_arr then arr else {}
	local current_values = Table.clone(arr)
	Table.clear(new_arr)
	for _,val in pairs(current_values) do
		if val ~= nil then
			Table.insert(new_arr,val)
		end
	end
	return new_arr
end

function Table.flat<T>(arr:{{T}},same_arr:boolean?):{T}
	local new_arr = if same_arr then arr else {}
	local current_values = Table.clone(arr)
	Table.clear(new_arr)
	local function flat(flat_arr)
		for _, val in ipairs(flat_arr) do
			if type(val) == "table" then
				flat(val)
			else
				table.insert(new_arr,val)
			end
		end
	end
	flat(current_values)
	return new_arr
end

function Table.flatdepth<T>(arr:{{T}},depth:number,same_arr:boolean?):{T}
	depth = depth+1
	local new_arr = if same_arr then arr else {}
	local current_values = Table.clone(arr)
	Table.clear(new_arr)
	local function flat(flat_arr,flat_depth)
		for _, val in ipairs(flat_arr) do
			if type(val) == "table" and not (flat_depth == depth) then
				flat(val,flat_depth+1)
			else
				table.insert(new_arr,val)
			end
		end
	end
	flat(current_values,1)
	return new_arr
end

function Table.findfn<T,U>(tbl:{[T]:U},fn:(key:T,el:U) -> boolean):(T?,U?)
	for key, value in pairs(tbl) do
		if fn(key,value) then
			return key, value
		end
	end
	return nil, nil
end

function Table.findfirstfn<T>(arr:{T},fn:(el:T) -> boolean):(number?,T?)
	for index, value in ipairs(arr) do
		if fn(value) then
			return index, value
		end
	end
	return nil, nil
end

function Table.findlastfn<T>(arr:{T},fn:(el:T) -> boolean):(number?|T?)
	for i = #arr,1,-1 do
		local value = arr[i]
		if fn(value) then
			return i, value
		end
	end
	return nil, nil
end

function Table.reduce<T>(arr:{T},fn:(idx:number,acc:T,el:T) -> T):T
	local acc = arr[1]
	for i = 2,#arr do
		acc = fn(i,acc,arr[i])
	end
	return acc
end

function Table.keys<T>(tbl:{[T]:any}):{T}
	local keys = {}
	for key, _ in pairs(tbl) do
		Table.insert(keys,key)
	end
	return keys
end

function Table.values<T>(tbl:{[any]:T}):{T}
	local values = {}
	for _, value in pairs(tbl) do
		Table.insert(values,value)
	end
	return values
end

function Table.invert<T,U>(tbl:{[T]:U},same_tbl:boolean?):{[U]:T}
	local new_tbl = if same_tbl then tbl else {}
	local current_values = Table.clone(tbl)
	Table.clear(new_tbl)
	for key, value in pairs(current_values) do
		new_tbl[value] = key
	end
	return new_tbl
end

function Table.sync(src:{[any]:any},tmpl:{[any]:any},same_tbl:boolean?):{[any]:any}
	local new_tbl = if same_tbl then src else {}
	local current_values = Table.clone(src)
	Table.clear(new_tbl)
	local function sync(tmpl_tbl:{[any]:any},src_tbl:{[any]:any},set_tbl:{[any]:any})
		for key, val in pairs(tmpl_tbl) do
			local src_val = src_tbl[key]
			if src_val then
				if type(src_val) == "table" then
					set_tbl[key] = {}
					sync(tmpl_tbl[key],src_val,set_tbl[key])
				else
					set_tbl[key] = src_val
				end
			else
				set_tbl[key] = val
			end
		end
	end
	sync(tmpl,current_values,new_tbl)
	return new_tbl
end

function Table.reconcile(src:{[any]:any},tmpl:{[any]:any},same_tbl:boolean?):{[any]:any}
	local new_tbl = if same_tbl then src else {}
	local current_values = Table.clone(src)
	Table.clear(new_tbl)
	local function reconcile(tmpl_tbl:{[any]:any},src_tbl:{[any]:any},set_tbl:{[any]:any})
		for key, val in pairs(tmpl_tbl) do
			local src_val = src_tbl[key]
			if src_val then
				if type(src_val) == "table" then
					set_tbl[key] = {}
					reconcile(tmpl_tbl[key],src_val,set_tbl[key])
				else
					set_tbl[key] = src_val
				end
			else
				set_tbl[key] = val
			end
		end
		local tmpl_keys = Table.keys(tmpl_tbl)
		for key, val in pairs(src_tbl) do
			if not Table.contains(tmpl_keys,key) then
				set_tbl[key] = val
			end
		end
	end
	reconcile(tmpl,current_values,new_tbl)
	return new_tbl
end

function Table.swapremove(arr:{any},idx:number)
	local len = #arr
	arr[idx] = arr[len]
	arr[len] = nil
end

function Table.swapremovefirst<T>(arr:{T},val:T)
	local idx = Table.find(arr,val)
	if idx then
		Table.swapremove(arr,idx)
	end
end

function Table.max(tbl:{number}):number
	return math.max(Table.unpack(tbl))
end

function Table.min(tbl:{number}):number
	return math.min(Table.unpack(tbl))
end

export type Destroyable = {Destroy:(self:Destroyable) -> ()}
export type Disconnectable = {Disconnect:(self:Disconnectable) -> ()}
export type CleanupContainer = {Cleanup:(self:CleanupContainer) -> (),Destroy:(self:CleanupContainer) -> (),Add:<T>(self:CleanupContainer,val:T) -> T,[number]:CleanupType}
export type CleanupType = Instance|RBXScriptConnection|thread|() -> ()|Destroyable|Disconnectable|CleanupContainer

function Table.cleanup(arr:{CleanupType})
	for _, val in ipairs(arr) do
		local typ = typeof(val)
		if typ == "Instance" then
			val:Destroy()
		elseif typ == "RBXScriptConnection" then
			val:Disconnect()
		elseif typ == "thread" then
			local status = coroutine.status(val)
			if status == "suspended" then
				task.cancel(val)
			elseif status ~= "dead" then
				task.defer(function()
					task.cancel(val)
				end)
			end
		elseif typ == "function" then
			val()
		elseif typ == "table" then
			if type(val["Destroy"]) == "function" then
				val:Destroy()
			elseif type(val["Disconnect"]) == "function" then
				val:Disconnect()
			end
		end
	end
	Table.clear(arr)
end

function Table.cleanupcontainer(parent:CleanupContainer?):CleanupContainer
	local mmidx = {}
	local tbl = setmetatable({},{__index = mmidx})
	function mmidx:Cleanup()
		Table.cleanup(tbl)
	end
	function mmidx:Destroy()
		mmidx:Cleanup()
	end
	function mmidx:Add(val)
		return Table.insertnget(tbl,val)
	end
	if parent then
		Table.insert(parent,tbl)
	end
	return tbl
end

function Table.callall<T,U...>(arr:{T},fn:(T,U...) -> any?,...:U...)
	for _, val in ipairs(arr) do
		fn(val,...)
	end
end

function Table.callallmethod(arr:{any},method_name:any,...)
	for _, val in ipairs(arr) do
		val[method_name](val,...)
	end
end

return Table
