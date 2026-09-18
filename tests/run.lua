--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-BUSINESS — Offline tests: permissions, grades, desks, locale parity
     Requires a sibling checkout of lxr-core (../lxr-core).
     Usage (from the lxr-business folder):  lua tests/run.lua [--mock out.js en|ka]
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local CORE = os.getenv('LXR_CORE_PATH') or '../lxr-core'
package.path = CORE .. '/?.lua;' .. package.path
local ok = pcall(function() require('tests.lib.fxshim') end)
if not ok then print('lxr-core shim not found at ' .. CORE .. ' (set LXR_CORE_PATH)') os.exit(2) end
local Shim = require('tests.lib.fxshim')

for _, f in ipairs({ 'shared/main.lua', 'shared/locale.lua', 'locales/en.lua', 'config.lua', 'shared/jobs.lua' }) do Shim.load(CORE .. '/' .. f) end
Config = nil
Locale = nil
Shim.load('shared/locale.lua')
Shim.load('locales/en.lua')
Shim.load('locales/ka.lua')
Shim.load('config.lua')
Shim.load('shared/rules.lua')
local B = LXRBusiness

local passed, failed = 0, 0
local function test(name, fn)
    local okT, err = xpcall(fn, debug.traceback)
    if okT then passed = passed + 1 print('  ^ ok   ' .. name) else failed = failed + 1 print('  x FAIL ' .. name .. '\n' .. err) end
end
local function eq(a, b, msg) if a ~= b then error((msg or 'eq') .. ': expected ' .. tostring(b) .. ' got ' .. tostring(a), 2) end end

print('lxr-business offline tests')

test('every desk belongs to a registry job with grades', function()
    for job, c in pairs(Config.Desks) do assert(LXRShared.Jobs[job], 'desk for unknown job ' .. job) assert(c.x, job) assert(#B.Grades(job) > 0, job .. ' has no grades') end
end)

test('grades are ordered and the top is the boss', function()
    local g = B.Grades('vallaw')
    for i = 2, #g do assert(g[i].level > g[i - 1].level) end
    assert(g[#g].boss, 'top grade is boss')
    eq(B.TopLevel('vallaw'), g[#g].level)
end)

test('who manages, and what they may do to whom', function()
    local top = B.TopLevel('general')
    local boss = { name = 'general', grade = { level = top }, isboss = true }
    local hand = { name = 'general', grade = { level = 0 } }
    local foreman = { name = 'general', grade = { level = 2 } }
    assert(B.Manages(boss)) assert(not B.Manages(hand)) assert(B.Manages(foreman), 'foreman hires and promotes')
    assert(B.MaySet(boss, 1, nil)) assert(B.MaySet(boss, top, 0), 'the boss may promote to any grade')
    local okF, why = B.MaySet(foreman, 2, nil) assert(not okF and why == 'above_you', 'foreman cannot hire at own grade')
    assert(B.MaySet(foreman, 1, nil))
    assert(B.MaySet(foreman, 1, 0), 'foreman promotes below')
    local okFire, whyFire = B.MayFire(foreman, 0) assert(not okFire and whyFire == 'no_fire', 'foreman does not fire')
    assert(B.MayFire(boss, 2))
    local okSelf = B.MayFire(boss, top) assert(okSelf, 'a boss may let another boss go')
end)

test('wage bill', function()
    local bill = B.WageBill('general', { [0] = 2, [1] = 1 })
    local g = B.Grades('general')
    eq(bill, g[1].payment * 2 + g[2].payment)
end)

test('locale parity', function()
    local en, ka = Locale.Bundles.en, Locale.Bundles.ka
    local missing = {}
    for k in pairs(en) do if ka[k] == nil then missing[#missing + 1] = k end end
    eq(#missing, 0, 'ka missing: ' .. table.concat(missing, ', '))
end)

print(('%d passed, %d failed'):format(passed, failed))

if arg and arg[1] == '--mock' and arg[2] then
    Config.Lang = arg[3] or 'en'
    local grades = B.Grades('general')
    local data = {
        job = { name = 'general', label = LXRShared.Jobs.general.label, grade = grades[#grades].name, level = grades[#grades].level, type = 'trade' },
        grades = grades, headcount = { [0] = 2, [1] = 1, [2] = 1 }, wageBill = B.WageBill('general', { [0] = 2, [1] = 1, [2] = 1 }),
        staff = { { citizenid = 'LXR2001', name = 'Mary Beth Gaskill', level = 2, grade = grades[3].name, online = true, onduty = true, wage = grades[3].payment }, { citizenid = 'LXR2002', name = 'Lenny Summers', level = 1, grade = grades[2].name, online = true, onduty = false, wage = grades[2].payment }, { citizenid = 'LXR2003', name = 'Tilly Jackson', level = 0, grade = grades[1].name, online = false, wage = grades[1].payment, lastSeen = '2026-09-15 20:11:00' }, { citizenid = 'LXR2004', name = 'Uncle', level = 0, grade = grades[1].name, online = false, wage = grades[1].payment, lastSeen = '2026-09-02 09:40:00' } },
        book = { balance = 412.60, bankOn = true }, perms = { hire = true, fire = true, promote = true, society = true, boss = true }, cash = 31.20, maxMove = 5000,
    }
    local f = assert(io.open(arg[2], 'w'))
    f:write('window.__LXR_MOCK__ = ' .. json.encode({ action = 'open', data = data, near = { { id = 12 } }, locale = Lang.bundle(), lang = Config.Lang, brand = { name = 'The Land of Wolves', theme = 'night' } }) .. ';\n')
    f:close()
    print('mock written to ' .. arg[2])
end
os.exit(failed == 0 and 0 or 1)
