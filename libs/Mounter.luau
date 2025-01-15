--!nocheck

local ValueContainer = require(script.ValueContainer)

local Mounter = {}

type MounterConfig = {[string|(inst:Instance,any) -> ()]:any}

local function _mount(inst:Instance,config:MounterConfig)
	local parent
	for prop_key, prop_val in pairs(config) do
		if type(prop_key) == "string" then
			if prop_key == "Parent" then
				parent = prop_val
				continue
			end
			if ValueContainer.is(prop_val) then
				prop_val.Changed:Connect(function(val)
					inst[prop_key] = val
				end)
			else
				inst[prop_key] = prop_val
			end
		else
			prop_key(inst,prop_val)
		end
	end
	if parent then
		if ValueContainer.is(parent) then
			parent.Changed:Connect(function(val)
				inst.Parent = val
			end)
		else
			inst.Parent = parent
		end
	end
end

function Mounter.mount(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig)
	if type(config) == "function" then
		_mount(inst,config(inst))
	else
		_mount(inst,config)
	end
end

function Mounter.new(class:string,config:MounterConfig|(inst:Instance) -> MounterConfig):Instance
	local new_inst = Instance.new(class)
	Mounter.mount(new_inst,config)
	return new_inst
end

function Mounter.tags(inst:Instance,tags:{string})
	for _, tag in ipairs(tags) do
		inst:AddTag(tag)
	end
end

function Mounter.children(inst:Instance,children:{Instance})
	for _, child in ipairs(children) do
		child.Parent = inst
	end
end

function Mounter.instance(inst:Instance,fn:(inst:Instance) -> ())
	fn(inst)
end

function Mounter.attributes(inst:Instance,attrs:{[string]:any})
	for attr_name, attr_val in pairs(attrs) do
		if ValueContainer.is(attr_val) then
			attr_val.Changed:Connect(function(val)
				inst:SetAttribute(attr_name,val)
			end)
		else
			inst:SetAttribute(attr_name,attr_val)
		end
	end
end

function Mounter.changed(prop_name:string):(inst:Instance,fn:(val:any) -> ()) -> ()
	return function(inst:Instance,fn:(val:any) -> ())
		inst:GetPropertyChangedSignal(prop_name):Connect(fn)
	end
end

function Mounter.attrchanged(prop_name:string):(inst:Instance,fn:(val:any) -> ()) -> ()
	return function(inst:Instance,fn:(val:any) -> ())
		inst:GetAttributeChangedSignal(prop_name):Connect(fn)
	end
end

function Mounter.on(prop_name:string):(inst:Instance,fn:(...any) -> ()) -> ()
	return function(inst:Instance,fn:(...any) -> ())
		inst[prop_name]:Connect(fn)
	end
end

function Mounter.findfirstchild(name:string):(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig) -> ()
	return function(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig)
		Mounter.mount(inst:FindFirstChild(name),config)
	end
end

function Mounter.findfirstchildwhichisa(class:string):(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig) -> ()
	return function(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig)
		Mounter.mount(inst:FindFirstChildWhichIsA(class),config)
	end
end

function Mounter.findfirstchildofclass(class:string):(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig) -> ()
	return function(inst:Instance,config:MounterConfig|(inst:Instance) -> MounterConfig)
		Mounter.mount(inst:FindFirstChildOfClass(class),config)
	end
end

return Mounter