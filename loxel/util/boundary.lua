local Boundary = {}

Boundary.showInfo = false
Boundary.infoFormat = "x: %.2f, y: %.2f\nw: %i, h: %i"

function Boundary.render(camera, o, i, total, color)
	if not Project.flags.loxelShowObjectBoundaries then return end
	-- code rewrite needed but i lost og one in the process :) -vk
end

return Boundary
