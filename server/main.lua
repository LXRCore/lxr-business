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
local dropJob   -- the jobs-held book, defined below; fire uses it
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
    dropJob(T.PlayerData.citizenid, jobName)
    T.Functions.SetJob('unemployed', 0)
    if offline then T.Functions.Save() else LXRCore.Notify(T.PlayerData.source, Lang:t('info.you_fired', { job = B.Def(jobName).label }), 'inform') end
    LXRCore.Emit('lxr:business:fired', nil, jobName, T.PlayerData.citizenid, src)
    log('fired', { job = jobName, source = src, target = T.PlayerData.citizenid })
    return true, ledger(src)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 💼 JOBS HELD — hired into several, one active at a time
-- ═══════════════════════════════════════════════════════════════════════════════
LXRCore.DB.RegisterMigration(RES, '0001_jobs_held', [[
CREATE TABLE IF NOT EXISTS `lxr_jobs_held` (
  `citizenid` VARCHAR(50) NOT NULL,
  `job` VARCHAR(64) NOT NULL,
  `grade` INT NOT NULL DEFAULT 0,
  `since` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizenid`, `job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])
local function heldOf(cid) return LXRCore.DB.Query('SELECT job, grade, since FROM lxr_jobs_held WHERE citizenid = ? ORDER BY since', { cid }) or {} end
local function holdJob(cid, job, grade)
    if not Config.Jobs.held or job == 'unemployed' then return end
    LXRCore.DB.UpdateAsync('INSERT INTO lxr_jobs_held (citizenid, job, grade) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE grade = VALUES(grade)', { cid, job, grade or 0 })
end
dropJob = function(cid, job) LXRCore.DB.UpdateAsync('DELETE FROM lxr_jobs_held WHERE citizenid = ? AND job = ?', { cid, job }) end
local function jobCap(cid) return tonumber(Config.Jobs.maxByCitizen[cid]) or Config.Jobs.max or 2 end
-- every job change the core makes is remembered (hires from anywhere: desks, admin, other resources)
AddEventHandler('lxr:job:changed', function(src, job)
    if not Config.Jobs.held or type(job) ~= 'table' then return end
    local P = player(src)
    if not P or job.name == 'unemployed' then return end
    holdJob(P.PlayerData.citizenid, job.name, job.grade and job.grade.level or 0)
end)
LXR.RPC.Register('lxr-business:jobs', function(src)
    if limited(src) then return false, 'rate' end
    local P = player(src)
    if not P then return false, 'invalid' end
    local out = {}
    for _, r in ipairs(heldOf(P.PlayerData.citizenid)) do
        local def = B.Def(r.job)
        if def then
            local g = def.grades and def.grades[tostring(r.grade)] or nil
            out[#out + 1] = { job = r.job, label = def.label, grade = r.grade, gradeLabel = g and g.name or tostring(r.grade), active = P.PlayerData.job.name == r.job }
        end
    end
    return true, out, jobCap(P.PlayerData.citizenid)
end)
LXR.RPC.Register('lxr-business:switch', function(src, job)
    if limited(src) then return false, 'rate' end
    local P = player(src)
    if not P or not Config.Jobs.held then return false, 'invalid' end
    if P.PlayerData.job.onduty then return false, 'on_duty' end
    local found
    for _, r in ipairs(heldOf(P.PlayerData.citizenid)) do if r.job == job then found = r end end
    if not found then return false, 'not_held' end
    if not P.Functions.SetJob(found.job, tonumber(found.grade) or 0) then return false, 'invalid' end
    log('switched job', { source = src, job = job })
    return true
end)
LXR.RPC.Register('lxr-business:drop', function(src, job)
    if limited(src) then return false, 'rate' end
    local P = player(src)
    if not P or not Config.Jobs.dropAllowed then return false, 'invalid' end
    dropJob(P.PlayerData.citizenid, job)
    if P.PlayerData.job.name == job then P.Functions.SetJob('unemployed', 0) end
    log('dropped job', { source = src, job = job })
    return true
end)
LXRCore.Commands.Add(Config.Jobs.command or 'myjobs', Lang:t('command.myjobs'), {}, false, function(src) TriggerClientEvent('lxr-business:client:jobs', src) end, 'user')

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🧾 BILLING — a bill from a job to a person standing by
-- ═══════════════════════════════════════════════════════════════════════════════
local function mayBill(P)
    if not Config.Billing.enabled then return false end
    local job = P.PlayerData.job or {}
    if job.name == 'unemployed' then return false end
    if #(Config.Billing.jobs or {}) == 0 then return true end
    for _, t in ipairs(Config.Billing.jobs) do if job.type == t then return true end end
    return false
end
LXR.RPC.Register('lxr-business:bill', function(src, targetId, amount, reason)
    if limited(src) then return false, 'rate' end
    local P, T = player(src), player(tonumber(targetId) or -1)
    if not P or not T or T == P then return false, 'invalid' end
    if not mayBill(P) then return false, 'not_allowed' end
    amount = math.floor((tonumber(amount) or 0) * 100) / 100
    if amount <= 0 or amount > (Config.Billing.max or 500) then return false, 'bad_amount' end
    local pa, pb = GetPlayerPed(src), GetPlayerPed(T.PlayerData.source)
    if pa == 0 or pb == 0 or #(GetEntityCoords(pa) - GetEntityCoords(pb)) > (Config.Billing.distance or 3.0) then return false, 'too_far' end
    reason = tostring(reason or ''):gsub('[%c<>]', ''):sub(1, 80)
    local jobName = P.PlayerData.job.name
    local label = B.Def(jobName) and B.Def(jobName).label or jobName
    if T.Functions.RemoveMoney('cash', amount, 'bill:' .. jobName) or T.Functions.RemoveMoney('bank', amount, 'bill:' .. jobName) then
        if Config.Billing.toSociety and bankOn() then exports['lxr-bank']:MoveBook('society_' .. jobName, amount, P.PlayerData.citizenid, 'bill: ' .. nameOf(T))
        else P.Functions.AddMoney('cash', amount, 'bill paid') end
        LXRCore.Notify(T.PlayerData.source, Lang:t('info.you_paid', { amount = ('%.2f'):format(amount), job = label, reason = reason }), 'inform')
        LXRCore.Emit('lxr:business:billed', nil, jobName, T.PlayerData.citizenid, amount, reason, true)
        log('bill paid', { job = jobName, source = src, target = T.PlayerData.source, amount = amount })
        return true, true
    end
    if Config.Billing.receiptItem and LXRShared.Items[Config.Billing.receiptItem] then
        T.Functions.AddItem(Config.Billing.receiptItem, 1, nil, { amount = amount, job = jobName, label = label, reason = reason, from = nameOf(P), issued = os.time() }, 'bill')
        LXRCore.Notify(T.PlayerData.source, Lang:t('info.you_owe', { amount = ('%.2f'):format(amount), job = label }), 'warning')
        LXRCore.Emit('lxr:business:billed', nil, jobName, T.PlayerData.citizenid, amount, reason, false)
        return true, false
    end
    return false, 'cannot_pay'
end)
-- a receipt item is paid by using it
CreateThread(function()
    local item = Config.Billing.receiptItem
    if not item or not LXRShared.Items[item] then return end
    LXRCore.Items.RegisterUsable(item, function(src, it)
        local P = player(src)
        local info = it and it.info or {}
        local amount = tonumber(info.amount) or 0
        if not P or amount <= 0 then return end
        if not (P.Functions.RemoveMoney('cash', amount, 'receipt') or P.Functions.RemoveMoney('bank', amount, 'receipt')) then return LXRCore.Notify(src, Lang:t('error.cannot_pay'), 'error') end
        if not P.Functions.RemoveItem(item, 1, it.slot, 'receipt paid') then P.Functions.AddMoney('cash', amount, 'receipt refund') return end
        if Config.Billing.toSociety and bankOn() and info.job then exports['lxr-bank']:MoveBook('society_' .. info.job, amount, P.PlayerData.citizenid, 'receipt: ' .. nameOf(P)) end
        LXRCore.Notify(src, Lang:t('info.receipt_paid', { amount = ('%.2f'):format(amount), job = info.label or info.job or '' }), 'success')
    end)
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
