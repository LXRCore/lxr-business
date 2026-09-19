--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-BUSINESS — Client: the desk point and the ledger page
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
-- LXRCore crosses the export as a copy: its PlayerData would stay what it was at load. The core broadcasts every
-- change (money, job, metadata) — keep ours current.
RegisterNetEvent('lxr:client:data', function(d) if type(d) == 'table' then LXRCore.PlayerData = d end end)
RegisterNetEvent('lxr:client:unloaded', function() LXRCore.PlayerData = {} end)
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

-- ── jobs held: /myjobs — switch, or leave one
RegisterNetEvent('lxr-business:client:jobs', function()
    local ok, list, cap = LXR.RPC.Server('lxr-business:jobs')
    if not ok then return toast('error.' .. tostring(list), 'error') end
    local rows = {}
    for _, j in ipairs(list) do rows[#rows + 1] = { id = j.job, name = j.label, sub = j.gradeLabel, badge = j.active and Lang:t('ui.active') or nil } end
    if #rows == 0 then return toast('info.no_jobs', 'inform') end
    exports['lxr-nui']:Menu({ title = Lang:t('ui.my_jobs'), subtitle = Lang:t('ui.jobs_cap', { n = #list, cap = cap }), rows = rows }, function(id)
        if not id then return end
        local actions = { { id = 'switch', name = Lang:t('ui.switch_to') } }
        if Config.Jobs.dropAllowed then actions[#actions + 1] = { id = 'drop', name = Lang:t('ui.leave_job') } end
        exports['lxr-nui']:Menu({ title = Lang:t('ui.my_jobs'), rows = actions }, function(a)
            if not a then return end
            local ok2, err = LXR.RPC.Server('lxr-business:' .. a, id)
            if ok2 then toast(a == 'switch' and 'info.switched' or 'info.left', 'success') else toast('error.' .. tostring(err), 'error') end
        end)
    end)
end)

-- ── billing: an option on people for the jobs that may bill
CreateThread(function()
    while GetResourceState('lxr-interact') ~= 'started' do Wait(1000) end
    if not Config.Billing.enabled then return end
    local function sid(e) return GetPlayerServerId(NetworkGetPlayerIndexFromPed(e)) end
    local function may()
        local job = me().job or {}
        if job.name == 'unemployed' or not job.name then return false end
        if #(Config.Billing.jobs or {}) == 0 then return true end
        for _, t in ipairs(Config.Billing.jobs) do if job.type == t then return true end end
        return false
    end
    exports['lxr-interact']:AddGlobal('lxr-business:bill', 'player', { label = Lang:t('ui.person'), distance = Config.Billing.distance, options = {
        { label = Lang:t('ui.bill'), key = 'B', canInteract = function(e) return e ~= nil and may() end, onSelect = function(d)
            local id = sid(d.entity)
            exports['lxr-nui']:Input({ title = Lang:t('ui.bill'), fields = { { id = 'amount', label = Lang:t('ui.bill_amount'), type = 'number', value = 1 }, { id = 'reason', label = Lang:t('ui.bill_reason'), type = 'text' } } }, function(v)
                if not v then return end
                local ok, paid = LXR.RPC.Server('lxr-business:bill', id, tonumber(v.amount) or 0, v.reason)
                if ok then toast(paid and 'info.bill_paid' or 'info.bill_receipt', 'success') else toast('error.' .. tostring(paid), 'error') end
            end)
        end },
    }})
end)
RegisterNetEvent('lxr:client:unloaded', close)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then close() end end)
exports('Open', open)
