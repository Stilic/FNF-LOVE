---@class Group:Basic
local Group = Basic:extend("Group")

function Group:new()
	Group.super.new(self)
	self.members = {}
end

function Group:add(obj)
	table.insert(self.members, obj)
	return obj
end

function Group:remove(obj)
	table.delete(self.members, obj)
	return obj
end

function Group:clear() table.clear(self.members) end

function Group:reverse() table.clear(self.members) end

function Group:sort(func) table.sort(self.members, func) end

function Group:recycle(class, factory, revive)
	if class == nil then class = Sprite end
	if factory == nil then factory = class end
	if revive == nil then revive = true end

	local newObject
	for _, member in next, self.members do
		if member and not member.exists and member.is and member:is(class) then
			newObject = member
			break
		end
	end
	if newObject then
		self:remove(newObject)
		if revive then newObject:revive() end
	else
		newObject = factory()
	end
	self:add(newObject)

	return newObject
end

function Group:update(dt)
	local f
	for _, member in next, self.members do
		if member.exists and member.active then
			f = member.update
			if f then f(member, dt) end
		end
	end
end

function Group:draw()
	local oldDefaultCameras = Camera.__defaultCameras
	if self.cameras then Camera.__defaultCameras = self.cameras end

	local f
	for _, member in next, self.members do
		if member.exists and member.visible then
			f = member.draw
			if f then f(member) end
		end
	end

	Camera.__defaultCameras = oldDefaultCameras
end

function Group:kill()
	local f
	for _, member in next, self.members do
		f = member.kill
		if f then f(member) end
	end

	Group.super.kill(self)
end

function Group:revive()
	local f
	for _, member in next, self.members do
		f = member.revive
		if f then f(member) end
	end

	Group.super.revive(self)
end

function Group:destroy()
	Group.super.destroy(self)

	local f
	for _, member in next, self.members do
		f = member.destroy
		if f then f(member) end
	end
end

return Group
