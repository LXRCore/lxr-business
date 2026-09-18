--[[
    ██╗     ██╗  ██╗██████╗       ██████╗ ██╗   ██╗███████╗██╗███╗   ██╗███████╗███████╗███████╗
    ██║     ╚██╗██╔╝██╔══██╗      ██╔══██╗██║   ██║██╔════╝██║████╗  ██║██╔════╝██╔════╝██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗██████╔╝██║   ██║███████╗██║██╔██╗ ██║█████╗  ███████╗███████╗
    ██║      ██╔██╗ ██╔══██╗╚════╝██╔══██╗██║   ██║╚════██║██║██║╚██╗██║██╔══╝  ╚════██║╚════██║
    ███████╗██╔╝ ██╗██║  ██║      ██████╔╝╚██████╔╝███████║██║██║ ╚████║███████╗███████║███████║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═════╝  ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝

    LXR Core - Business

    The proprietor's ledger. Every job in the core registry with grades is a
    business here: the boss (or any grade with hire / fire / promote) opens
    the ledger at the desk, sees the staff — online and not — hires from
    the street, promotes, lets go, reads the society book and the wages it
    owes, and moves money between the book and the till. Gangs get the
    same ledger for their book.

    Brand:       LXRCore — Lux Empire eXperience RedM Core
    Product:     wolves.land / The Land of Wolves
    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    Discord:     https://discord.gg/ZHMKVYyhBa (development)
    GitHub:      https://github.com/LXRCore

    Version: 3.0.0
    Performance Target: 0.00 ms idle (desks are lxr-interact points)

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

Config = Config or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE ██████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
Config.Lang = 'en'

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DESKS ═════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- job → where its ledger lies. Jobs without a desk use `/ledger` when Config.Ledger.anywhere is on.
Config.Desks = {
    vallaw   = vector3(-275.89, 809.44, 119.38),
    rholaw   = vector3(1360.88, -1301.53, 77.77),
    sdlaw    = vector3(2501.83, -1309.04, 48.95),
    blklaw   = vector3(-760.47, -1269.14, 44.04),
    strlaw   = vector3(-1810.57, -350.91, 164.66),
    valdoc   = vector3(-286.28, 804.77, 119.30),
    sddoc    = vector3(2385.24, -1374.19, 46.55),
    armdoc   = vector3(-3650.37, -2645.63, -13.45),
    bank     = vector3(-303.02, 771.60, 118.47),
    general  = vector3(-322.43, 803.80, 117.90),
    gunsmith = vector3(-281.97, 781.09, 119.52),
    saloon   = vector3(-313.26, 805.22, 118.98),
    butcher  = vector3(-355.75, 789.03, 116.18),
    barber   = vector3(-283.65, 811.25, 119.38),
    tailor   = vector3(-322.43, 803.80, 117.90),
    stable   = vector3(-364.60, 788.30, 116.20),
}

Config.Ledger = {
    anywhere = false,            -- /ledger opens the ledger without a desk
    command = 'ledger',
    hireDistance = 3.0,          -- the person being hired must be this close to the desk
    staffRows = 100,             -- employees listed (online first)
    gangs = true,                -- gang bosses get a ledger for the gang book
    tillAccount = 'cash',        -- what moves in and out of the society book
    maxMove = 5000,
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SECURITY ══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Security = { rateLimit = { windowMs = 2000, burst = 8 }, maxDistance = 4.0, promptDistance = 2.0 }

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DEBUG ═════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Debug = { printBanner = true, log = true }
