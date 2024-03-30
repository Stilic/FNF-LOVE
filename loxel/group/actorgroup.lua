---@class ActorGroup:Sprite
local ActorGroup = ActorSprite:extend("ActorGroup")
ActorGroup:implement(SpriteGroup)

function ActorGroup:new(x, y, z, affect)
	ActorGroup.super.new(self, x, y, z)

	self.group = Group()
	self.members = self.group.members

	self.__unusedCameraRenderQueue = {}
	self.__cameraRenderQueue = {}

	self:_initializeDrawFunctions()

	if affect == nil then affect = true end
	self.affectAngle = affect
	self.affectScale = affect
end

function ActorGroup:__drawNestGroup(members, camera, list, x2, y2, sf, zoomx, zoomy)
	for _, member in ipairs(members) do
		local sf2, px, py, sfx, sfy = member.scrollFactor, member.x, member.y
		if px then
			member.x, member.y = px + x2, py + y2
			if sf2 then
				sfx, sfy = sf2.x, sf2.y
				sf2.x, sf2.y = sf2.x * sf.x, sf2.y * sf.y
			end
		end

		if member.__cameraRenderQueue then
			if Sprite.super._canDraw(member) and next(member:_prepareCameraDraw(camera)) then
				table.insert(list, member)
			end
		elseif member:_canDraw() then
			if member.__render then
				local sf = self.scrollFactor
				local x, y, w, h, sx, sy, ox, oy = self:_getBoundary()

				if member:_isOnScreen(x, y, w, h, sx, sy, ox, oy,
					sf and sf.x or 1, sf and sf.y or 1, camera)
				then
					table.insert(list, member)
				end
			elseif member.members then
				self:__drawNestGroup(member.members, camera, list,
					(member.x or x2), (member.y or y2), sf, zoomx, zoomy)
			end
		end

		member.x, member.y = px, py
		if sf2 then
			sf2.x, sf2.y = sfx, sfy
		end
	end
end

function ActorGroup:__render(camera)
	local list = self.__cameraRenderQueue[camera]
	if not list then return end

	local cr, cg, cb, ca = love.graphics.getColor()
	self.__ogSetColor, love.graphics.setColor = love.graphics.setColor, self.__setColor

	local x, y, z, ox, oy, oz, rx, ry, rz, angle, sx, sy, sz, affectAngle, affectScale =
		self.x + self.offset.x,
		self.y + self.offset.y,
		self.z + self.offset.z,
		self.origin.x, self.origin.y, self.origin.z,
		self.rotation.x, self.rotation.y, self.rotation.z, self.angle,
		self.scale.x * self.zoom.x, self.scale.y * self.zoom.y, self.scale.z * self.zoom.z,
		self.affectAngle, self.affectScale

	local a, b = camera.scroll, self.scrollFactor
	for i, member in ipairs(list) do
		if member.x then
			local mrot, msc = member.rotation, member.scale
			local px, py, pz, prx, pry, prz, pa, psx, psy, psz = member.x, member.y, member.z

			local vx, vy, vz = Actor.worldSpin(px, py, pz, rx, ry, rz, ox, oy, oz)
			member.x, member.y, member.z =
				vx + x + (a.x * member.scrollFactor.x * (1 - b.x)),
				vy + y + (a.y * member.scrollFactor.y * (1 - b.y)),
				vz + z

			if affectAngle then
				if mrot then
					prx, pry, prz = mrot.x, mrot.y, mrot.z
					mrot.x, mrot.y, mrot.z = prx + rx, pry + ry, prz + rz
				end
				pa = member.angle
				member.angle = pa + angle
			end
			if affectScale then
				psx, psy, psz = msc.x, msc.y, msc.z
				msc.x, msc.y, msc.z = psx * sx, psy * sy, psz * sz
			end

			member:__render(camera)

			member.x, member.y, member.z = px, py, pz
			if affectAngle then
				if mrot then
					mrot.x, mrot.y, mrot.z = prx, pry, prz
				end
				member.angle = pa
			end
			if affectScale then
				msc.x, msc.y, msc.z = psx, psy, psz
			end
		else
			member:__render(camera)
		end

		list[i] = nil
	end
	self.__cameraRenderQueue[camera] = nil
	table.insert(self.__unusedCameraRenderQueue, list)

	love.graphics.setColor = self.__ogSetColor
	self.__ogSetColor(cr, cg, cb, ca)
end

function ActorGroup:screenCenter(axes)
	self:getWidth()
	return ActorGroup.super.screenCenter(self, axes)
end

function ActorGroup:loadTexture() return self end

ActorGroup.updateHitbox = SpriteGroup.updateHitbox
ActorGroup.centerOffsets = SpriteGroup.centerOffsets
ActorGroup.fixOffsets = SpriteGroup.fixOffsets
ActorGroup.centerOrigin = SpriteGroup.centerOrigin
ActorGroup.loadTexture = SpriteGroup.loadTexture
ActorGroup.isOnScreen = SpriteGroup.isOnScreen
ActorGroup.update = SpriteGroup.update
ActorGroup._isOnScreen = SpriteGroup._isOnScreen
ActorGroup._canDraw = SpriteGroup._canDraw
ActorGroup.kill = SpriteGroup.kill
ActorGroup.revive = SpriteGroup.revive
ActorGroup.destroy = SpriteGroup.destroy

return ActorGroup
