local HealthIcon = Sprite:extend()

function HealthIcon:new(icon, flip)
    HealthIcon.super.new(self, 0, 0)

    self:loadTexture(paths.getImage("icons/icon-" .. (icon or "face")))

    self.static = true

    if self.width > 150 and self.width ~= self.height then
        self.width = self.width / 2
        self:loadTexture(paths.getImage("icons/icon-" .. (icon or "face")), true,
                    math.floor(self.width), math.floor(self.height))
        self:addAnim("i", {0, 1}, 0)
        self:play("i")

        self.static = false
    end

    self.flipX = flip or false
    if icon:endsWith("-pixel") then self.antialiasing = false end

    self:setScrollFactor()
    self:updateHitbox()
    self.origin = {x = 150, y = 0}

    self.imageData = love.image.newImageData("assets/images/icons/icon-" ..
                                       (icon or "face") .. ".png")
end

function HealthIcon:getDominant()
    local function is_close(r, g, b, th)
        return r <= th and g <= th and b <= th
    end

    self.dominant = {}

    local width, height = self.imageData:getDimensions()
    local th = 0.1

    for y = 1, height - 1 do
        for x = 1, width - 1 do
            local r, g, b, a = self.imageData:getPixel(x, y)
            if a == 1 and not is_close(r, g, b, th) then
                local color = {r, g, b}
                table.insert(self.dominant, color)
            end
        end
    end

    local freq = {}
    for _, color in ipairs(self.dominant) do
        local string = table.concat({color[1], color[2], color[3]}, ",")
        freq[string] = (freq[string] or 0) + 1
    end

    local result, max = nil, 0
    for string, frequency in pairs(freq) do
        if frequency > max then
            result = string
            max = frequency
        end
    end

    if result then
        local colortable = {}
        for value in string.gmatch(result, "([^,]+)") do
            table.insert(colortable, tonumber(value))
        end

        return colortable
    end
end

function HealthIcon:swap(frame)
    if not self.static then self.curFrame = frame end
end

return HealthIcon
