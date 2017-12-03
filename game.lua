local game = {}
local lg = love.graphics
local sprites = require "sprites"
local actors

local base_actor = {
    x=0, y=0, dx=0, dy=0,
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
function base_actor:spawn (...) game.add_actor (...) end
function base_actor:die () end
function base_actor:draw_sprite (...) sprites.draw(...) end
function base_actor:draw () end
function base_actor:collide () end

local player
local scroll, scroll_rate
game.add_actor = function (name, ...)
    local actor = dofile("actors/" .. name .. ".lua")
    setmetatable(actor, {__index = base_actor})
    actor:init(...)
    actors[#actors+1] = actor
    return actor
end

game.load_level = function (name)
    scroll = 0
    scroll_rate = 0.25
    actors = {}
    local level = dofile("levels/" .. name .. ".lua")
    for _,actor in ipairs(level.actors) do
        game.add_actor(unpack(actor))
    end
    player = game.add_actor("player", 20, _G.GAMEH/2)
end

local check_collision
game.update = function (buttons)
    scroll = scroll + scroll_rate
    player.x = player.x + scroll_rate
    for i = 1,#actors do
        for j = i+1,#actors do
            check_collision(actors[i], actors[j])
        end
    end
    for i,actor in ipairs(actors) do
        actor:update(buttons)
    end
    if player.x < scroll then
        player.x = scroll
    end
    if player.y < -8 or player.y > _G.GAMEH-8 then
        player.killme = true
    end
    for i,actor in ipairs(actors) do
        if actor.killme then
            actor:die()
            actors[i] = actors[#actors-1]
        end
    end
end

local border = {}
border.image = lg.newImage("res/border.png")
border.image:setWrap("repeat", "clamp")
border.w,border.h = border.image:getDimensions()
border.quad = lg.newQuad(0, 0, _G.GAMEW+border.w, border.h, border.w, border.h)
game.draw = function ()
    lg.clear(85, 45, 65)
    local border_x = math.floor(-scroll*2 % border.w - border.w)
    lg.draw(border.image, border.quad, border_x, -border.h/2)
    lg.draw(border.image, border.quad, border_x, _G.GAMEH-border.h/2)
    lg.translate(-scroll, 0)
    for i,actor in ipairs(actors) do
        lg.setColor(255,255,255,255)
        actor:draw()
    end
end

check_collision = function (a, b)
    if a.player == b.player or
       not a.hitboxes or not b.hitboxes
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
    lg.translate(-scroll*sx, 0)
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
