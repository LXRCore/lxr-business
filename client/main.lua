--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-BUSINESS — Client: the desk point and the ledger page
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local B = LXRBusiness
local session = nil

local function me() return LXRCore.PlayerData or {} end
local function toast(key, kind, vars) LXRCore.Notify(Lang:t(key, vars), kind or 'info') end

local function close()
    if not session then return end
    session = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function open()
    if session then return end
    local job = me().job or {}
    local ok, data, bundle, brand = LXR.RPC.Server('lxr-business:open', job.name)
    if not ok then return toast('error.' .. tostring(data), 'error') end
    session = { job = job.name }
    -- people at the desk who may be hired
    local near = {}
    local pos = GetEntityCoords(PlayerPedId())
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped ~= PlayerPedId() and #(GetEntityCoords(ped) - pos) <= Config.Ledger.hireDistance then near[#near + 1] = { id = GetPlayerServerId(pid) } end
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data, near = near, locale = bundle, brand = brand or LXRCore.Brand, lang = Config.Lang })
end

local function rpc(name, ...)
    if not session then return { ok = false } end
    local ok, res, extra = LXR.RPC.Server('lxr-business:' .. name, session.job, ...)
    if not ok then toast('error.' .. tostring(res), 'error', { amount = extra }) return { ok = false, why = res } end
    return { ok = true, data = res }
end
RegisterNUICallback('close', function(_, cb) close() cb({ ok = true }) end)
RegisterNUICallback('hire', function(d, cb) cb(rpc('hire', d.id, d.level)) end)
RegisterNUICallback('grade', function(d, cb) cb(rpc('grade', d.citizenid, d.level)) end)
RegisterNUICallback('fire', function(d, cb) cb(rpc('fire', d.citizenid)) end)
RegisterNUICallback('book', function(d, cb) cb(rpc('book', d.amount)) end)
RegisterNUICallback('sound', function(d, cb) PlaySoundFrontend(d.name or 'NAV_UP', d.set or 'HUD_SHOP_SOUNDSET', true, 0) cb({}) end)

CreateThread(function()
    while GetResourceState('lxr-interact') ~= 'started' do Wait(1000) end
    for jobName, coords in pairs(Config.Desks) do
        local def = B.Def(jobName)
        exports['lxr-interact']:AddPoint('lxr-business:' .. jobName, coords, { label = Lang:t('ui.ledger_of', { job = def and def.label or jobName }), distance = Config.Security.promptDistance, options = {
            { label = Lang:t('ui.open_ledger'), key = 'J', canInteract = function() local j = me().job return j and j.name == jobName and B.Manages(j) end, onSelect = open },
        }})
    end
end)

if Config.Ledger.anywhere then RegisterCommand(Config.Ledger.command, function() if B.Manages(me().job) then open() end end, false) end
RegisterNetEvent('lxr:client:unloaded', close)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then close() end end)
exports('Open', open)
