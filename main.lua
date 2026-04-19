--[[
    PIGEON GANG WAR
    Love2D Prototype
    Controls: WASD = move, P = peck, B = poop bomb
--]]

function love.load()
    -- Window
    love.window.setTitle("Pigeon Gang War")
    love.window.setMode(800, 600)
    
    -- Player
    player = {
        x = 400,
        y = 300,
        speed = 300,
        radius = 20,
        health = 100,
        maxHealth = 100,
        invincible = 0,
        flock = {}
    }
    
    -- Sparrows (enemies)
    sparrows = {}
    for i = 1, 5 do
        table.insert(sparrows, {
            x = math.random(100, 700),
            y = math.random(100, 500),
            radius = 15,
            health = 30,
            patrolDir = math.random(1,4),
            patrolTimer = 0,
            speed = 80
        })
    end
    
    -- Fries (collectables)
    fries = {}
    for i = 1, 8 do
        spawnFry()
    end
    
    -- Poop bombs
    bombs = {}
    bombCooldown = 0
    
    -- Attack
    attackCooldown = 0
    attackRange = 40
    
    -- Camera offset
    camX = 0
    camY = 0
    
    -- Score
    score = 0
    
    -- Font
    smallFont = love.graphics.newFont(16)
    largeFont = love.graphics.newFont(32)
end

function spawnFry()
    table.insert(fries, {
        x = math.random(50, 750),
        y = math.random(50, 550),
        radius = 8,
        floatOffset = 0,
        floatSpeed = math.random(50, 150) / 100
    })
end

function love.update(dt)
    if player.health <= 0 then return end
    
    -- Camera follow
    camX = player.x - 400
    camY = player.y - 300
    camX = math.max(0, math.min(camX, 2000))
    camY = math.max(0, math.min(camY, 2000))
    
    -- Player movement (WASD)
    local moveX, moveY = 0, 0
    if love.keyboard.isDown('w') then moveY = moveY - 1 end
    if love.keyboard.isDown('s') then moveY = moveY + 1 end
    if love.keyboard.isDown('a') then moveX = moveX - 1 end
    if love.keyboard.isDown('d') then moveX = moveX + 1 end
    
    if moveX ~= 0 or moveY ~= 0 then
        local len = math.sqrt(moveX^2 + moveY^2)
        moveX = moveX / len
        moveY = moveY / len
    end
    
    player.x = player.x + moveX * player.speed * dt
    player.y = player.y + moveY * player.speed * dt
    
    -- Boundaries
    player.x = math.max(30, math.min(player.x, 770))
    player.y = math.max(30, math.min(player.y, 570))
    
    -- Invincibility frames
    if player.invincible > 0 then
        player.invincible = player.invincible - dt
    end
    
    -- Attack cooldown
    if attackCooldown > 0 then
        attackCooldown = attackCooldown - dt
    end
    
    -- Bomb cooldown
    if bombCooldown > 0 then
        bombCooldown = bombCooldown - dt
    end
    
    -- Attack (P key)
    if love.keyboard.isDown('p') and attackCooldown <= 0 then
        attackCooldown = 0.3
        -- Check for enemies in range
        for i = #sparrows, 1, -1 do
            local s = sparrows[i]
            local dx = player.x - s.x
            local dy = player.y - s.y
            local dist = math.sqrt(dx^2 + dy^2)
            if dist < attackRange then
                s.health = s.health - 25
                if s.health <= 0 then
                    table.remove(sparrows, i)
                    score = score + 10
                    -- Chance to recruit flock member
                    if math.random() < 0.3 then
                        table.insert(player.flock, {
                            x = player.x,
                            y = player.y,
                            radius = 12
                        })
                    end
                end
            end
        end
    end
    
    -- Poop bomb (B key)
    if love.keyboard.isDown('b') and bombCooldown <= 0 then
        bombCooldown = 1.5
        table.insert(bombs, {
            x = player.x,
            y = player.y,
            radius = 8,
            timer = 0.5
        })
    end
    
    -- Update bombs
    for i = #bombs, 1, -1 do
        local b = bombs[i]
        b.timer = b.timer - dt
        if b.timer <= 0 then
            -- Explode
            for j = #sparrows, 1, -1 do
                local s = sparrows[j]
                local dx = b.x - s.x
                local dy = b.y - s.y
                local dist = math.sqrt(dx^2 + dy^2)
                if dist < 50 then
                    s.health = s.health - 40
                    if s.health <= 0 then
                        table.remove(sparrows, j)
                        score = score + 10
                        if math.random() < 0.3 then
                            table.insert(player.flock, {
                                x = player.x,
                                y = player.y,
                                radius = 12
                            })
                        end
                    end
                end
            end
            table.remove(bombs, i)
        end
    end
    
    -- Update sparrows (patrol)
    for _, s in ipairs(sparrows) do
        s.patrolTimer = s.patrolTimer + dt
        
        -- Simple patrol: move in direction, turn after 2 seconds
        if s.patrolTimer > 2 then
            s.patrolTimer = 0
            s.patrolDir = math.random(1, 4)
        end
        
        if s.patrolDir == 1 then s.x = s.x + s.speed * dt
        elseif s.patrolDir == 2 then s.x = s.x - s.speed * dt
        elseif s.patrolDir == 3 then s.y = s.y + s.speed * dt
        else s.y = s.y - s.speed * dt end
        
        -- Boundaries for sparrows
        s.x = math.max(20, math.min(s.x, 780))
        s.y = math.max(20, math.min(s.y, 580))
        
        -- Collision with player
        local dx = player.x - s.x
        local dy = player.y - s.y
        local dist = math.sqrt(dx^2 + dy^2)
        if dist < player.radius + s.radius and player.invincible <= 0 then
            player.health = player.health - 10
            player.invincible = 0.8
        end
    end
    
    -- Update flock (follow player)
    for i, f in ipairs(player.flock) do
        local dx = player.x - f.x
        local dy = player.y - f.y
        local dist = math.sqrt(dx^2 + dy^2)
        if dist > 30 then
            f.x = f.x + dx * 3 * dt
            f.y = f.y + dy * 3 * dt
        end
        
        -- Flock pecks enemies
        for j, s in ipairs(sparrows) do
            local dx2 = f.x - s.x
            local dy2 = f.y - s.y
            local dist2 = math.sqrt(dx2^2 + dy2^2)
            if dist2 < f.radius + s.radius then
                s.health = s.health - 5
                if s.health <= 0 then
                    table.remove(sparrows, j)
                    score = score + 10
                end
            end
        end
    end
    
    -- Update fries (floating)
    for _, f in ipairs(fries) do
        f.floatOffset = f.floatOffset + dt * f.floatSpeed
    end
    
    -- Collision with fries
    for i = #fries, 1, -1 do
        local f = fries[i]
        local dx = player.x - f.x
        local dy = player.y - f.y
        local dist = math.sqrt(dx^2 + dy^2)
        if dist < player.radius + f.radius then
            player.health = math.min(player.maxHealth, player.health + 15)
            table.remove(fries, i)
            spawnFry() -- respawn fry elsewhere
        end
    end
    
    -- Spawn new sparrows if too few
    if #sparrows < 3 then
        table.insert(sparrows, {
            x = math.random(100, 700),
            y = math.random(100, 500),
            radius = 15,
            health = 30,
            patrolDir = math.random(1,4),
            patrolTimer = 0,
            speed = 80
        })
    end
end

function love.draw()
    -- Apply camera
    love.graphics.push()
    love.graphics.translate(-camX, -camY)
    
    -- Ground (plaza tiles)
    love.graphics.setColor(0.3, 0.3, 0.35)
    for x = 0, 2000, 50 do
        for y = 0, 2000, 50 do
            love.graphics.rectangle("fill", x, y, 48, 48)
        end
    end
    
    -- Draw fries (floating)
    for _, f in ipairs(fries) do
        local floatY = math.sin(f.floatOffset) * 5
        love.graphics.setColor(0.9, 0.8, 0.2)
        love.graphics.rectangle("fill", f.x - 6, f.y + floatY - 4, 12, 8)
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.line(f.x - 3, f.y + floatY - 2, f.x - 1, f.y + floatY + 2)
        love.graphics.line(f.x + 1, f.y + floatY - 2, f.x + 3, f.y + floatY + 2)
    end
    
    -- Draw sparrows
    for _, s in ipairs(sparrows) do
        love.graphics.setColor(0.4, 0.4, 0.45)
        love.graphics.circle("fill", s.x, s.y, s.radius)
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.circle("fill", s.x - 5, s.y - 4, 3)
        love.graphics.circle("fill", s.x + 5, s.y - 4, 3)
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", s.x - 5, s.y - 5, 1.5)
        love.graphics.circle("fill", s.x + 5, s.y - 5, 1.5)
        -- Angry eyebrows
        love.graphics.line(s.x - 8, s.y - 7, s.x - 3, s.y - 6)
        love.graphics.line(s.x + 8, s.y - 7, s.x + 3, s.y - 6)
    end
    
    -- Draw poop bombs
    for _, b in ipairs(bombs) do
        love.graphics.setColor(0.9, 0.85, 0.7)
        love.graphics.circle("fill", b.x, b.y, b.radius)
        love.graphics.circle("fill", b.x - 3, b.y + 2, 3)
    end
    
    -- Draw flock pigeons
    for _, f in ipairs(player.flock) do
        love.graphics.setColor(0.55, 0.45, 0.4)
        love.graphics.circle("fill", f.x, f.y, f.radius)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", f.x - 3, f.y - 3, 2)
        love.graphics.circle("fill", f.x + 3, f.y - 3, 2)
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", f.x - 3, f.y - 4, 1)
        love.graphics.circle("fill", f.x + 3, f.y - 4, 1)
    end
    
    -- Draw player pigeon
    love.graphics.setColor(0.55, 0.45, 0.4)
    if player.invincible > 0 and math.floor(love.timer.getTime() * 10) % 2 == 0 then
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.circle("fill", player.x, player.y, player.radius)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", player.x - 6, player.y - 6, 4)
    love.graphics.circle("fill", player.x + 6, player.y - 6, 4)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", player.x - 6, player.y - 7, 2)
    love.graphics.circle("fill", player.x + 6, player.y - 7, 2)
    love.graphics.setColor(0.9, 0.6, 0.2)
    love.graphics.polygon("fill", player.x, player.y - 4, player.x - 4, player.y + 2, player.x + 4, player.y + 2)
    
    -- Attack range indicator (when on cooldown but key held)
    if attackCooldown > 0 then
        love.graphics.setColor(0.8, 0.2, 0.2, 0.3)
        love.graphics.circle("fill", player.x, player.y, attackRange)
    end
    
    love.graphics.pop() -- End camera
    
    -- UI (drawn in screen space)
    love.graphics.setFont(smallFont)
    
    -- Health bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 20, 20, 204, 24)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", 22, 22, 200 * (player.health / player.maxHealth), 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HEALTH", 25, 25)
    
    -- Flock counter
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("FLOCK: " .. #player.flock, 20, 55)
    
    -- Score
    love.graphics.print("SCORE: " .. score, 20, 85)
    
    -- Controls hint
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("WASD = move | P = peck | B = poop bomb", 20, 570)
    
    -- Game over
    if player.health <= 0 then
        love.graphics.setFont(largeFont)
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.print("GAME OVER", 280, 250)
        love.graphics.setFont(smallFont)
        love.graphics.print("Press R to restart", 340, 300)
    end
end

function love.keypressed(key)
    if key == 'r' and player.health <= 0 then
        love.load() -- restart
    end
end
