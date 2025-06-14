--!nocheck

local ValueContainer = require(script.Parent.ValueContainer)
local table = require(script.Parent.Table)
local ReactiveTable = require(script.Parent.ReactiveTable)

local Mounter = {}

type MounterConfig = {[string|(inst:Instance,any) -> table.CleanupType?]:any}

local function _mount(inst:Instance,config:MounterConfig):table.CleanupContainer
	local cleanup_container = table.cleanupcontainer()
	local parent
	for prop_key, prop_val in config do
		if type(prop_key) == "string" then
			if prop_key == "Parent" then
				parent = prop_val
				continue
			end
			if ValueContainer.is(prop_val) then
				cleanup_container:Add(prop_val:SyncToProp(inst,prop_key))
			else
				inst[prop_key] = prop_val
			end
		else
			local key_cleanup = prop_key(inst,prop_val)
			if key_cleanup then
				cleanup_container:Add(key_cleanup)
			end
		end
	end
	if parent then
		if ValueContainer.is(parent) then
			cleanup_container:Add(parent:SyncToProp(inst,"Parent"))
		else
			inst.Parent = parent
		end
	end
	inst.Destroying:Once(function()
		cleanup_container:Cleanup()
	end)
	return cleanup_container
end

function Mounter.mount(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig):table.CleanupContainer
	if type(config) == "function" then
		return _mount(inst,config(inst))
	else
		return _mount(inst,config)
	end
end

function Mounter.new(class:string,config:MounterConfig|(inst:Instance) -> MounterConfig):(Instance,table.CleanupContainer)
	local new_inst = Instance.new(class)
	local cleanup_container = Mounter.mount(new_inst,config)
	return new_inst, cleanup_container
end

function Mounter.tags(inst:Instance,tags:{string}):table.CleanupContainer
	local cleanup_container = table.cleanupcontainer()
	if ReactiveTable.is(tags) then
		for key, tag_or_enabled in tags do
			local key_type = type(key)
			if key_type == "number" then
				inst:AddTag(tag_or_enabled)
			elseif key_type == "string" then
				if tag_or_enabled then
					inst:AddTag(key)
				end
			end
		end
		cleanup_container:Add(tags.Changed:Connect(function(tag)
			if type(tag) == "string" then
				if tags[tag] and not inst:HasTag(tag) then
					inst:AddTag(tag)
				elseif inst:HasTag(tag) then
					inst:RemoveTag(tag)
				end
			end
		end))
	else
		for _, tag in tags do
			inst:AddTag(tag)
		end
	end
	return cleanup_container
end

function Mounter.children(inst:Instance,children:{Instance}):table.CleanupContainer
	local cleanup_container = table.cleanupcontainer() 
	for _, child in children do
		child.Parent = inst
		cleanup_container:Add(child)
	end
	return cleanup_container
end

function Mounter.instance(inst:Instance,fn:(inst:Instance) -> table.CleanupType?):table.CleanupType?
	return fn(inst)
end

function Mounter.attributes(inst:Instance,attrs:{[string]:any}):table.CleanupContainer
	local cleanup_container = table.cleanupcontainer()
	for attr_name, attr_val in attrs do
		if ValueContainer.is(attr_val) then
			cleanup_container:Add(attr_val:SyncToAttr(inst,attr_name))
		else
			inst:SetAttribute(attr_name,attr_val)
		end
	end
	return cleanup_container
end

function Mounter.changed(prop_name:string):(inst:Instance,fn:(val:any) -> ()) -> RBXScriptConnection
	return function(inst:Instance,fn:(val:any) -> ())
		return inst:GetPropertyChangedSignal(prop_name):Connect(fn)
	end
end

function Mounter.attrchanged(prop_name:string):(inst:Instance,fn:(val:any) -> ()) -> RBXScriptConnection
	return function(inst:Instance,fn:(val:any) -> ())
		return inst:GetAttributeChangedSignal(prop_name):Connect(fn)
	end
end

function Mounter.on(prop_name:string):(inst:Instance,fn:(...any) -> ()) -> RBXScriptSignal
	return function(inst:Instance,fn:(...any) -> ())
		return inst[prop_name]:Connect(fn)
	end
end

function Mounter.once(prop_name:string):(inst:Instance,fn:(...any) -> ()) -> RBXScriptSignal
	return function(inst:Instance,fn:(...any) -> ())
		return inst[prop_name]:Once(fn)
	end
end

function Mounter.findfirstchild(name:string,recursive:boolean?):(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig) -> table.CleanupContainer
	return function(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig)
		return Mounter.mount(inst:FindFirstChild(name,recursive),config)
	end
end

function Mounter.findfirstchildwhichisa(class:string):(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig) -> table.CleanupContainer
	return function(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig)
		return Mounter.mount(inst:FindFirstChildWhichIsA(class),config)
	end
end

function Mounter.findfirstchildofclass(class:string):(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig) -> table.CleanupContainer
	return function(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig)
		return Mounter.mount(inst:FindFirstChildOfClass(class),config)
	end
end

return Mounter
