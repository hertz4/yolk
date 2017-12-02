local game = {}
local lg = love.graphics
local actors

local base_actor = {
    x=0, y=0, dx=0, dy=0,
    hitboxes = {},
}
function base_actor:setpos (x, y)
    self.x, self.y = x ,y
end
function base_actor:init(x, y) self:setpos(x, y) end
function base_actor:physics ()
    self.x = self.x + self.dx
    self.y = self.y + self.dy
end
function base_actor:update () self:physics () end
function base_actor:die () end
function base_actor:draw () end
function base_actor:collide () end

game.add_actor = function (name, ...)
    local actor = dofile("actors/" .. name .. ".lua")
    setmetatable(actor, {__index = base_actor})
    actor:init(...)
    actors[#actors+1] = actor
end

game.load_level = function (name)
    actors = {}
    local level = dofile("levels/" .. name .. ".lua")
    for _,actor in ipairs(level.actors) do
        game.add_actor(unpack(actor))
    end
end

local check_collision
game.update = function (buttons)
    for i = 1,#actors do
        for j = i+1,#actors do
            check_collision(actors[i], actors[j])
        end
    end
    for i,actor in ipairs(actors) do
        actor:update(buttons)
    end
    for i,actor in ipairs(actors) do
        if actor.killme then
            actor:die()
            actors[#actors-1] = actors[i]
        end
    end
end

game.draw = function ()
    lg.clear()
    for i,actor in ipairs(actors) do
        actor:draw()
    end
end

check_collision = function (a, b)
    if a.player == b.player or
       #a.hitboxes == 0 or #b.hitboxes == 0
    then
        return
    end
    for _,ha in ipairs(a.hitboxes) do
        for _,hb in ipairs(b.hitboxes) do
            local dist_x = (a.x + ha[1]) - (b.x + hb[1])
            local dist_y = (a.y + ha[2]) - (b.y + hb[2])
            local thresh = ha[3] + hb[3]
            if dist_x*dist_x + dist_y*dist_y < thresh*thresh then
                a:collide(b)
                b:collide(a)
                return
            end
        end
    end
end

game.draw_hitboxes = function (sx, sy)
    lg.push()
    lg.scale(sx, sy)
    lg.setLineWidth(0.2)
    for _,actor in ipairs(actors) do
        if actor.player then
            lg.setColor(0, 255, 255)
        else
            lg.setColor(255, 255, 0)
        end
        for _,hitbox in ipairs(actor.hitboxes) do
            lg.circle("line", actor.x + hitbox[1], actor.y + hitbox[2], hitbox[3], 40)
        end
    end
    lg.pop()
end

return game
