local ParallaxImage = Basic:extend("ParallaxImage")

function ParallaxImage:new(x, y, width, height, texture)
	ParallaxImage.super.new(self)

	if x == nil then x = 0 end
	if y == nil then y = 0 end
	self.x = x
	self.y = y

	self.width = width
	self.height = height

	self.vertices = {
		{0, 0,           0, 0}, {self.width, 0, 1, 0}, {self.width, self.height, 1, 1},
		{0, self.height, 0, 1}
	}

	self.offsetBack = {x = 0, y = 0}
	self.offsetFront = {x = 0, y = 0}

	self.scrollFactorBack = {x = 1, y = 1}
	self.scrollFactorFront = {x = 1, y = 1}

	self.scaleBack = 1
	self.scaleFront = 1

	self.color = Color.WHITE
	self.alpha = 1

	self.mesh = love.graphics.newMesh(self.vertices, "fan")
	self.mesh:setTexture(texture)
end

function ParallaxImage:__render(camera)
	local xBack, yBack = self.x, self.y
	xBack, yBack = xBack - (camera.scroll.x * self.scrollFactorBack.x),
		yBack - (camera.scroll.y * self.scrollFactorBack.y)

	local xFront, yFront = self.x, self.y
	xFront, yFront = xFront - (camera.scroll.x * self.scrollFactorFront.x),
		yFront - (camera.scroll.y * self.scrollFactorFront.y)

	xBack = xBack + self.width / 2
	xFront = xFront + self.width / 2

	local size, pos = -self.width * self.scaleBack / 2,
		yBack - self.offsetBack.y

	self.vertices[1][1] = size + xBack - self.offsetBack.x
	self.vertices[1][2] = pos

	self.vertices[2][1] = size + xBack + (self.width * self.scaleBack) -
		self.offsetBack.x
	self.vertices[2][2] = pos

	size, pos = -self.width * self.scaleFront / 2,
		yFront + self.height - self.offsetFront.y

	self.vertices[3][1] = size + xFront + (self.width * self.scaleFront) -
		self.offsetFront.x
	self.vertices[3][2] = pos

	self.vertices[4][1] = size + xFront - self.offsetFront.x
	self.vertices[4][2] = pos

	self.mesh:setVertices(self.vertices)

	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(self.color[1], self.color[2], self.color[3],
		self.alpha)

	love.graphics.draw(self.mesh, 0, 0)

	love.graphics.setColor(r, g, b, a)
end

return ParallaxImage
