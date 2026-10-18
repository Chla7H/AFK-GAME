local QBCore = exports['qb-core']:GetCoreObject()
local isAfk = false
local danceIndex = 0 -- 0 = sitting
local session = 0
local musicOn = false

local function loadDict(d)
    RequestAnimDict(d)
    local t = 0
    while not HasAnimDictLoaded(d) and t < 100 do Wait(50) t = t + 1 end
end

local function playEmote(i)
    local ped = PlayerPedId()
    local data
    if i == 0 then data = Config.SitAnim else data = Config.Dances[i] end
    if not data then return end
    danceIndex = i
    loadDict(data.dict)
    ClearPedTasks(ped)
    TaskPlayAnim(ped, data.dict, data.anim, 4.0, 4.0, -1, 1, 0.0, false, false, false)
    if Config.ShowMessage then
        SendNUIMessage({
            action = 'emote',
            label = (i == 0) and Config.Text.sitting or data.label,
        })
    end
end

local function setGhost(state)
    local ped = PlayerPedId()
    if state then
        SetEntityAlpha(ped, Config.Ghost.alpha, false)
        SetEntityInvincible(ped, Config.Ghost.invincible)
        SetEntityCanBeDamaged(ped, not Config.Ghost.invincible)
        SetPedCanRagdoll(ped, false)
        if Config.Ghost.noCollision then SetEntityCollision(ped, false, false) end
        if Config.Ghost.freeze then FreezeEntityPosition(ped, true) end
    else
        SetEntityAlpha(ped, 255, false)
        ResetEntityAlpha(ped)
        SetEntityVisible(ped, true, false)
        SetEntityInvincible(ped, false)
        SetEntityCanBeDamaged(ped, true)
        SetPedCanRagdoll(ped, true)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
    end
end

local function snapToGround(c)
    local ped = PlayerPedId()
    local found, gz = false, 0.0
    for _ = 1, 20 do
        found, gz = GetGroundZFor_3dCoord(c.x, c.y, c.z + 1.5, false)
        if found then break end
        RequestCollisionAtCoord(c.x, c.y, c.z)
        Wait(50)
    end
    local z = found and (gz + (Config.Ghost.groundOffset or 1.0)) or c.z
    SetEntityCoordsNoOffset(ped, c.x, c.y, z, false, false, false)
end

local function teleport(c, snap)
    local ped = PlayerPedId()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    RequestCollisionAtCoord(c.x, c.y, c.z)
    SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, false)
    local t = 0
    while not HasCollisionLoadedAroundEntity(ped) and t < 100 do Wait(20) t = t + 1 end
    if snap and Config.Ghost.snapToGround then snapToGround(c) end
    DoScreenFadeIn(500)
end

local afkCam = nil

local function stopCam()
    if not afkCam then return end
    local c = afkCam
    afkCam = nil
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(c, false)
end

local function startCam(mySession)
    local cfg = Config.Camera
    if not cfg or not cfg.enabled then return end
    stopCam()
    local ped = PlayerPedId()
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    afkCam = cam
    local angle = GetEntityHeading(ped) + 90.0
    local p = GetEntityCoords(ped)
    local r0 = math.rad(angle)
    SetCamCoord(cam, p.x + math.cos(r0) * cfg.distance, p.y + math.sin(r0) * cfg.distance, p.z + cfg.height)
    PointCamAtCoord(cam, p.x, p.y, p.z + cfg.lookAtZ)
    SetCamFov(cam, cfg.fov)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, cfg.blendIn or 1500, true, true)

    CreateThread(function()
        local started = GetGameTimer()
        local last = started
        while isAfk and session == mySession and afkCam == cam do
            Wait(0)
            local now = GetGameTimer()
            local dt = (now - last) / 1000.0
            last = now
            angle = angle + cfg.speed * dt
            local pc = GetEntityCoords(PlayerPedId())
            local rad = math.rad(angle)
            local bob = math.sin((now - started) / 1000.0 * cfg.bobSpeed) * cfg.bobHeight
            SetCamCoord(cam,
                pc.x + math.cos(rad) * cfg.distance,
                pc.y + math.sin(rad) * cfg.distance,
                pc.z + cfg.height + bob)
            PointCamAtCoord(cam, pc.x, pc.y, pc.z + cfg.lookAtZ)
        end
    end)
end

RegisterNetEvent('tm_afk:enter', function(coords)
    local ped = PlayerPedId()
    if IsPedDeadOrDying(ped, true) or IsPedCuffed(ped) or IsPedInAnyVehicle(ped, false) then
        ExecuteCommand(Config.Command) -- reset state on the server
        QBCore.Functions.Notify(Config.Text.cantUse, 'error')
        return
    end
    isAfk = true
    musicOn = (Config.Music and Config.Music.enabled) and true or false
    session = session + 1
    local mySession = session
    teleport(coords, true)
    setGhost(true)
    playEmote(0)
    startCam(mySession)
    if Config.EnterWarning.enabled and not Config.EnterWarning.useTxAdminStyle then
        QBCore.Functions.Notify(Config.EnterWarning.message, Config.EnterWarning.type, Config.EnterWarning.duration)
    end
    SendNUIMessage({
        action = 'show',
        showMessage = Config.ShowMessage,
        title = Config.Text.title,
        subtitle = Config.Text.subtitle,
        hint = Config.Text.emoteHint,
        music = Config.Music,
    })

    CreateThread(function()
        while isAfk and session == mySession do
            Wait(0)
            DisableControlAction(0, 24, true)  -- attack
            DisableControlAction(0, 25, true)  -- aim
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 23, true)  -- enter vehicle
            -- SPACE (control 22) = stop / resume the AFK music
            if Config.Music.enabled and Config.Music.spaceToggle and IsControlJustPressed(0, 22) then
                musicOn = not musicOn
                SendNUIMessage({ action = 'musicToggle', play = musicOn })
            end
            -- ← → to change dance
            if IsControlJustPressed(0, 175) then
                danceIndex = (danceIndex % #Config.Dances) + 1
                playEmote(danceIndex)
            elseif IsControlJustPressed(0, 174) then
                danceIndex = danceIndex - 1
                if danceIndex < 1 then danceIndex = #Config.Dances end
                playEmote(danceIndex)
            end
            local ped = PlayerPedId()
            SetEntityAlpha(ped, Config.Ghost.alpha, false)
            if not IsEntityPlayingAnim(ped, (danceIndex == 0 and Config.SitAnim or Config.Dances[danceIndex]).dict,
                (danceIndex == 0 and Config.SitAnim or Config.Dances[danceIndex]).anim, 3) then
                playEmote(danceIndex)
            end
        end
    end)

    CreateThread(function()
        while isAfk and session == mySession do
            TriggerServerEvent('tm_afk:heartbeat')
            Wait(30000)
        end
    end)
end)

RegisterNetEvent('tm_afk:exit', function(coords)
    isAfk = false
    session = session + 1
    stopCam()
    Wait(100) -- let the loops stop
    SendNUIMessage({ action = 'hide' })
    ClearPedTasks(PlayerPedId())
    setGhost(false)
    teleport(coords)
    Wait(200)
    setGhost(false) -- run again to be sure
end)

RegisterCommand(Config.EmoteCommand, function(_, args)
    if not isAfk then return end
    local n = tonumber(args[1])
    if n and n >= 1 and n <= #Config.Dances then playEmote(n) end
end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isAfk then
        stopCam()
        SendNUIMessage({ action = 'hide' })
        setGhost(false)
    end
end)


AddEventHandler('onClientResourceStart', function(res)
    if res == GetCurrentResourceName() then setGhost(false) end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    isAfk = false
    stopCam()
    setGhost(false)
end)


-- music debug (shown in F8 console)
RegisterNUICallback('audioStatus', function(data, cb)
    print(('[tm_afk] audio: %s %s'):format(data.status or '?', data.extra or ''))
    cb('ok')
end)

-- /afkvolume 0-100
RegisterCommand('afkvolume', function(_, args)
    local v = tonumber(args[1])
    if isAfk and v then
        SendNUIMessage({ action = 'volume', volume = v / 100.0 })
    end
end, false)
