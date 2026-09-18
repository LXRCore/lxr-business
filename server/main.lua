--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-BUSINESS — Server: the ledger
     ═══════════════════════════════════════════════════════════════════════════
     Staff changes go through the core's job engine (online or offline
     player objects); money goes through lxr-bank's society books. Every
     action checks the holder's grade permissions against the target's
     grade — nobody manages above themselves.
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local B = LXRBusiness
local RES = GetCurrentResourceName()
local buckets = {}

local function limited(src)
    local b = buckets[src]
    local now = GetGameTimer()
    if not b or now - b.at > Config.Security.rateLimit.windowMs then b = { at = now, n = 0 } buckets[src] = b end
    b.n = b.n + 1
    return b.n > Config.Security.rateLimit.burst
end
local function player(src) return LXRCore.Functions.GetPlayer(src) end
local function nameOf(P) local ci = P.PlayerData.charinfo return ci.firstname .. ' ' .. ci.lastname end
local function log(msg, data) if Config.Debug.log then LXRCore.Log.info('business', msg, data) end end
local function bankOn() return GetResourceState('lxr-bank') == 'started' end
local function book(name) return bankOn() and exports['lxr-bank']:GetBook('society_' .. name) or 0 end

local function atDesk(src, jobName)
    local desk = B.Desk(jobName)
    if not desk then return Config.Ledger.anywhere end
    local ped = GetPlayerPed(src)
    return ped ~= 0 and #(GetEntityCoords(ped) - desk) <= Config.Security.maxDistance
end

---Gate: the caller manages `jobName` and stands at its desk.
local function gate(src, jobName)
    if limited(src) then return nil, 'rate' end
    local P = player(src)
    if not P then return nil, 'invalid' end
    local job = P.PlayerData.job
    if job.name ~= jobName or not B.Manages(job) then return nil, 'not_yours' end
    if not atDesk(src, jobName) then return nil, 'too_far' end
    return P
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📒 THE LEDGER
-- ═══════════════════════════════════════════════════════════════════════════════
local function staff(jobName)
    local out, seen, head = {}, {}, {}
    for src, P in pairs(LXRCore.Players) do
        local j = P.PlayerData.job
        if j.name == jobName then
            seen[P.PlayerData.citizenid] = true
            out[#out + 1] = { citizenid = P.PlayerData.citizenid, name = nameOf(P), level = j.grade.level, grade = j.grade.name, online = true, onduty = j.onduty, wage = j.grade.payment }
            head[j.grade.level] = (head[j.grade.level] or 0) + 1
        end
    end
    local rows = LXRCore.DB.Query("SELECT citizenid, charinfo, job, last_updated FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(job, '$.name')) = ? ORDER BY last_updated DESC LIMIT ?", { jobName, Config.Ledger.staffRows }) or {}
    for _, r in ipairs(rows) do
        if not seen[r.citizenid] then
            local ci = json.decode(r.charinfo or '{}') or {}
            local j = json.decode(r.job or '{}') or {}
            local lvl = tonumber(j.grade and j.grade.level) or 0
            local g = B.Def(jobName) and B.Def(jobName).grades[tostring(lvl)]
            out[#out + 1] = { citizenid = r.citizenid, name = (ci.firstname or '?') .. ' ' .. (ci.lastname or ''), level = lvl, grade = g and g.name or ('Grade ' .. lvl), online = false, onduty = false, wage = g and g.payment or 0, lastSeen = r.last_updated }
            head[lvl] = (head[lvl] or 0) + 1
        end
    end
    table.sort(out, function(a, b) if a.online ~= b.online then return a.online end if a.level ~= b.level then return a.level > b.level end return a.name < b.name end)
    return out, head
end

local function ledger(src)
    local P = player(src)
    local job = P.PlayerData.job
    local def = B.Def(job.name)
    local list, head = staff(job.name)
    local perms = { hire = B.Can(job, 'hire'), fire = B.Can(job, 'fire'), promote = B.Can(job, 'promote'), society = B.Can(job, 'society'), boss = job.isboss == true }
    return {
        job = { name = job.name, label = def and def.label or job.name, grade = job.grade.name, level = job.grade.level, type = def and def.type },
        grades = B.Grades(job.name), staff = list, headcount = head, wageBill = B.WageBill(job.name, head),
        book = { balance = book(job.name), bankOn = bankOn() }, perms = perms, cash = P.PlayerData.money[Config.Ledger.tillAccount] or 0, maxMove = Config.Ledger.maxMove,
    }
end

LXR.RPC.Register('lxr-business:open', function(src, jobName)
    local P, why = gate(src, jobName)
    if not P then return false, why end
    return true, ledger(src), Lang.bundle(), LXRCore.Brand
end)

-- hire: the person must stand at the desk
LXR.RPC.Register('lxr-business:hire', function(src, jobName, targetId, level)
    local P, why = gate(src, jobName)
    if not P then return false, why end
    local ok, err = B.MaySet(P.PlayerData.job, level, nil)
    if not ok then return false, err end
    local T = player(tonumber(targetId) or -1)
    if not T or T.PlayerData.source == src then return false, 'invalid' end
    local desk = B.Desk(jobName)
    if desk and #(GetEntityCoords(GetPlayerPed(T.PlayerData.source)) - desk) > Config.Ledger.hireDistance then return false, 'too_far_hire' end
    local def = B.Def(jobName)
    if def and def.hireable == false then return false, 'not_hireable' end
    if not T.Functions.SetJob(jobName, tonumber(level) or 0) then return false, 'invalid' end
    LXRCore.Emit('lxr:business:hired', nil, jobName, T.PlayerData.citizenid, tonumber(level) or 0, src)
    log('hired', { job = jobName, source = src, target = T.PlayerData.citizenid, level = level })
    return true, ledger(src)
end)

local function targetOf(citizenid)
    local T = LXRCore.Functions.GetPlayerByCitizenId(citizenid)
    if T then return T, false end
    T = LXRCore.Functions.GetOfflinePlayerByCitizenId(citizenid)
    return T, true
end

LXR.RPC.Register('lxr-business:grade', function(src, jobName, citizenid, level)
    local P, why = gate(src, jobName)
    if not P then return false, why end
    local T, offline = targetOf(tostring(citizenid or ''))
    if not T or T.PlayerData.job.name ~= jobName then return false, 'not_staff' end
    if T.PlayerData.citizenid == P.PlayerData.citizenid then return false, 'yourself' end
    local ok, err = B.MaySet(P.PlayerData.job, level, T.PlayerData.job.grade.level)
    if not ok then return false, err end
    if not T.Functions.SetJob(jobName, tonumber(level) or 0) then return false, 'invalid' end
    if offline then T.Functions.Save() end
    LXRCore.Emit('lxr:business:graded', nil, jobName, T.PlayerData.citizenid, tonumber(level) or 0, src)
    log('grade', { job = jobName, source = src, target = T.PlayerData.citizenid, level = level })
    return true, ledger(src)
end)

LXR.RPC.Register('lxr-business:fire', function(src, jobName, citizenid)
    local P, why = gate(src, jobName)
    if not P then return false, why end
    local T, offline = targetOf(tostring(citizenid or ''))
    if not T or T.PlayerData.job.name ~= jobName then return false, 'not_staff' end
    if T.PlayerData.citizenid == P.PlayerData.citizenid then return false, 'yourself' end
    local ok, err = B.MayFire(P.PlayerData.job, T.PlayerData.job.grade.level)
    if not ok then return false, err end
    T.Functions.SetJob('unemployed', 0)
    if offline then T.Functions.Save() else LXRCore.Notify(T.PlayerData.source, Lang:t('info.you_fired', { job = B.Def(jobName).label }), 'inform') end
    LXRCore.Emit('lxr:business:fired', nil, jobName, T.PlayerData.citizenid, src)
    log('fired', { job = jobName, source = src, target = T.PlayerData.citizenid })
    return true, ledger(src)
end)

-- the book ↔ the till (society permission)
LXR.RPC.Register('lxr-business:book', function(src, jobName, amount)
    local P, why = gate(src, jobName)
    if not P then return false, why end
    if not B.Can(P.PlayerData.job, 'society') then return false, 'no_society' end
    if not bankOn() then return false, 'no_bank' end
    amount = tonumber(amount)
    if not amount or amount == 0 or amount ~= amount then return false, 'amount' end
    local abs = math.floor(math.abs(amount) * 100 + 0.5) / 100
    if abs > Config.Ledger.maxMove then return false, 'amount' end
    local bookName = 'society_' .. jobName
    if amount > 0 then
        if not P.Functions.RemoveMoney(Config.Ledger.tillAccount, abs, 'business:deposit:' .. jobName) then return false, 'no_cash', abs end
        exports['lxr-bank']:MoveBook(bookName, abs, P.PlayerData.citizenid, 'deposit by ' .. nameOf(P))
    else
        local ok = exports['lxr-bank']:MoveBook(bookName, -abs, P.PlayerData.citizenid, 'withdrawal by ' .. nameOf(P))
        if not ok then return false, 'book_poor' end
        P.Functions.AddMoney(Config.Ledger.tillAccount, abs, 'business:withdraw:' .. jobName)
    end
    return true, ledger(src)
end)

CreateThread(function()
    local n = 0 for _ in pairs(Config.Desks) do n = n + 1 end
    if Config.Debug.printBanner then print(('^1[lxr-business]^7 v%s — %d desks, ledger anywhere %s'):format(GetResourceMetadata(RES, 'version', 0), n, tostring(Config.Ledger.anywhere))) end
end)
AddEventHandler('playerDropped', function() buckets[source] = nil end)

exports('Staff', function(jobName) return (staff(jobName)) end)
exports('Hire', function(citizenid, jobName, level) local T, off = targetOf(citizenid) if not T then return false end local ok = T.Functions.SetJob(jobName, level or 0) if ok and off then T.Functions.Save() end return ok end)
