--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-BUSINESS — Shared rules: who may manage, what a grade may do to another
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

LXRBusiness = LXRBusiness or {}
local B = LXRBusiness

local function level(job) local g = job and job.grade return type(g) == 'table' and (tonumber(g.level) or 0) or (tonumber(g) or 0) end
function B.Level(job) return level(job) end

---The registry record for a job.
function B.Def(name) return LXRShared.Jobs and LXRShared.Jobs[name] end

---Does this job record hold a management permission (hire / fire / promote / society / manage).
function B.Can(job, perm)
    if not job or not job.name then return false end
    if job.isboss then return true end
    if LXRShared.JobHasPerm then return LXRShared.JobHasPerm(job, perm) end
    return false
end

---May the holder open the ledger at all.
function B.Manages(job)
    return B.Can(job, 'hire') or B.Can(job, 'fire') or B.Can(job, 'promote') or B.Can(job, 'society') or B.Can(job, 'manage')
end

---Grades of a job, sorted, as { level, name, payment, boss }.
function B.Grades(name)
    local def = B.Def(name)
    local out = {}
    for lvl, g in pairs(def and def.grades or {}) do out[#out + 1] = { level = tonumber(lvl), name = g.name, payment = g.payment, boss = g.isboss == true } end
    table.sort(out, function(a, b) return a.level < b.level end)
    return out
end

function B.TopLevel(name)
    local top = 0
    for _, g in ipairs(B.Grades(name)) do if g.level > top then top = g.level end end
    return top
end

---May `job` set someone to `target` level: only below the holder's own grade, and only what the permission allows.
function B.MaySet(job, targetLevel, currentLevel)
    targetLevel = tonumber(targetLevel) or 0
    local mine = level(job)
    if not job.isboss and targetLevel >= mine then return false, 'above_you' end
    if currentLevel ~= nil and not job.isboss and (tonumber(currentLevel) or 0) >= mine then return false, 'above_you' end
    if currentLevel == nil then return B.Can(job, 'hire'), 'no_hire' end
    if targetLevel ~= currentLevel then return B.Can(job, 'promote'), 'no_promote' end
    return true
end

function B.MayFire(job, targetLevel)
    if not B.Can(job, 'fire') then return false, 'no_fire' end
    if not job.isboss and (tonumber(targetLevel) or 0) >= level(job) then return false, 'above_you' end
    return true
end

---A job's monthly-ish wage bill from its grades and a headcount table { [level] = n }.
function B.WageBill(name, headcount)
    local total = 0
    for _, g in ipairs(B.Grades(name)) do total = total + (tonumber(g.payment) or 0) * (headcount[g.level] or 0) end
    return math.floor(total * 100 + 0.5) / 100
end

function B.Desk(name) return Config.Desks[name] end
