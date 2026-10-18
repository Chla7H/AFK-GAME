local QBCore = exports['qb-core']:GetCoreObject()
local afkPlayers = {}   -- [src] = slotIndex
local slotOwner  = {}   -- [slotIndex] = src

local function freeSlot()
    local free = {}
    for i = 1, #Config.AfkSlots do
        if not slotOwner[i] then free[#free + 1] = i end
    end
    if #free == 0 then return nil end
    return free[math.random(#free)]
end

local function leave(src)
    local slot = afkPlayers[src]
    if not slot then return end
    slotOwner[slot] = nil
    afkPlayers[src] = nil
    Player(src).state:set('afk', false, true)
end

RegisterCommand(Config.Command, function(src)
    if src == 0 then return end
    if afkPlayers[src] then
        leave(src)
        TriggerClientEvent('tm_afk:exit', src, Config.ReturnCoords)
        return
    end
    local slot = freeSlot()
    if not slot then
        TriggerClientEvent('QBCore:Notify', src, Config.Text.noSlot, 'error')
        return
    end
    afkPlayers[src] = slot
    slotOwner[slot] = src
    Player(src).state:set('afk', true, true)
    TriggerClientEvent('tm_afk:enter', src, Config.AfkSlots[slot])
    if Config.EnterWarning.enabled and Config.EnterWarning.useTxAdminStyle then
        TriggerClientEvent('txcl:showDirectMessage', src, Config.EnterWarning.message, Config.EnterWarning.author)
    end
end, false)

-- Heartbeat from client: a player in AFK mode counts as active (not kicked)
RegisterNetEvent('tm_afk:heartbeat', function() end)

AddEventHandler('playerDropped', function() leave(source) end)

-- Export so any other AFK-kick script can check:
-- if exports['tm_afk']:IsPlayerAFK(src) then return end
exports('IsPlayerAFK', function(src) return afkPlayers[src] ~= nil end)

-- txAdmin: scheduled restart warning for players in AFK mode
AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if not Config.TxAdmin.restartWarning then return end
    local secs = tonumber(eventData and eventData.secondsRemaining) or 0
    local when = secs >= 60 and (math.ceil(secs / 60) .. ' minute(s)') or (secs .. ' second(s)')
    local msg = Config.TxAdmin.restartMessage:format(when)
    for src in pairs(afkPlayers) do
        TriggerClientEvent('txcl:showDirectMessage', src, msg, Config.EnterWarning.author)
    end
end)
