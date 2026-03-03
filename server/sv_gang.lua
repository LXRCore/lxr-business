

--[[
    ██╗     ██╗  ██╗██████╗       ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗███╗   ███╗███████╗███╗   ██╗████████╗
    ██║     ╚██╗██╔╝██╔══██╗      ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
    ██║      ╚███╔╝ ██████╔╝█████╗██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██╔████╔██║█████╗  ██╔██╗ ██║   ██║   
    ██║      ██╔██╗ ██╔══██╗╚════╝██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   
    ███████╗██╔╝ ██╗██║  ██║      ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   

    🐺 LXR Management System — Server: Gang Menu

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:    The Land of Wolves 🐺
    Developer: iBoss21 / The Lux Empire
    Website:   https://www.wolves.land
    Discord:   https://discord.gg/CrKcWdfd3A
    Store:     https://theluxempire.tebex.io

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

local GangaccountGangs = {}

CreateThread(function()
	Wait(500)
	local gangmenu = MySQL.query.await('SELECT * FROM management_menu WHERE menu_type = "gang"', {})
	if not gangmenu then
		return
	end
	for k,v in pairs(gangmenu) do
		local k = tostring(v.job_name)
		local v = tonumber(v.amount)
		if k and v then
			GangaccountGangs[k] = v
		end
	end
end)

RegisterNetEvent("lxr-gangmenu:server:withdrawMoney", function(amount)
	local src = source
	local xPlayer = exports['lxr-core']:GetPlayer(src)
	local gang = xPlayer.PlayerData.gang.name

	if not GangaccountGangs[gang] then
		GangaccountGangs[gang] = 0
	end

	if GangaccountGangs[gang] >= amount and amount > 0 then
		GangaccountGangs[gang] = GangaccountGangs[gang] - amount
		xPlayer.Functions.AddMoney("cash", amount, 'Boss menu withdraw')
	else
		TriggerClientEvent('LXRCore:Notify', src, 9, "Invalid amount!", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
		TriggerClientEvent('lxr-gangmenu:client:OpenMenu', src)
		return
	end

	MySQL.query.await('UPDATE management_menu SET amount = ? WHERE job_name = ? AND menu_type = "gang"', { GangaccountGangs[gang], gang })
	TriggerEvent('lxr-log:server:CreateLog', 'gangmenu', 'Withdraw Money', 'yellow', xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname .. ' successfully withdrew $' .. amount .. ' (' .. gang .. ')', false)
	TriggerClientEvent('LXRCore:Notify', src, 9, "You have withdrawn: $" ..amount, 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
	TriggerClientEvent('lxr-gangmenu:client:OpenMenu', src)
end)

RegisterNetEvent("lxr-gangmenu:server:depositMoney", function(amount)
	local src = source
	local xPlayer = exports['lxr-core']:GetPlayer(src)
	local gang = xPlayer.PlayerData.gang.name

	if not GangaccountGangs[gang] then
		GangaccountGangs[gang] = 0
	end

	if xPlayer.Functions.RemoveMoney("cash", amount) then
		GangaccountGangs[gang] = GangaccountGangs[gang] + amount
	else
		TriggerClientEvent('LXRCore:Notify', src, 9, "Invalid amount!", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
		TriggerClientEvent('lxr-gangmenu:client:OpenMenu', src)
		return
	end

	MySQL.query.await('UPDATE management_menu SET amount = ? WHERE job_name = ? AND menu_type = "gang"', { GangaccountGangs[gang], gang })
	TriggerEvent('lxr-log:server:CreateLog', 'gangmenu', 'Deposit Money', 'yellow', xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname .. ' successfully deposited $' .. amount .. ' (' .. gang .. ')', false)
	TriggerClientEvent('LXRCore:Notify', src, 9, "You have deposited: $" ..amount, 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
	TriggerClientEvent('lxr-gangmenu:client:OpenMenu', src)
end)

RegisterNetEvent("lxr-gangmenu:server:addaccountGangMoney", function(accountGang, amount)
	if not GangaccountGangs[accountGang] then
		GangaccountGangs[accountGang] = 0
	end

	GangaccountGangs[accountGang] = GangaccountGangs[accountGang] + amount
	MySQL.query.await('UPDATE management_menu SET amount = ? WHERE job_name = ? AND menu_type = "gang"', { GangaccountGangs[accountGang], accountGang })
end)

RegisterNetEvent("lxr-gangmenu:server:removeaccountGangMoney", function(accountGang, amount)
	if not GangaccountGangs[accountGang] then
		GangaccountGangs[accountGang] = 0
	end

	if GangaccountGangs[accountGang] >= amount then
		GangaccountGangs[accountGang] = GangaccountGangs[accountGang] - amount
	end

	MySQL.query.await('UPDATE management_menu SET amount = ? WHERE job_name = ? AND menu_type = "gang"', { GangaccountGangs[accountGang], accountGang })
end)

exports['lxr-core']:CreateCallback('lxr-gangmenu:server:GetAccount', function(source, cb, GangName)
	local gangmoney = GetaccountGang(GangName)
	cb(gangmoney)
end)

-- Export
function GetaccountGang(accountGang)
	return GangaccountGangs[accountGang] or 0
end

-- Get Employees
exports['lxr-core']:CreateCallback('lxr-gangmenu:server:GetEmployees', function(source, cb, gangname)
	local src = source
	local employees = {}
	if not GangaccountGangs[gangname] then
		GangaccountGangs[gangname] = 0
	end
	local players = MySQL.query.await("SELECT * FROM `players` WHERE `gang` LIKE '%".. gangname .."%'", {})
	if players[1] ~= nil then
		for key, value in pairs(players) do
			local isOnline = exports['lxr-core']:GetPlayerByCitizenId(value.citizenid)

			if isOnline then
				employees[#employees+1] = {
				empSource = isOnline.PlayerData.citizenid,
				grade = isOnline.PlayerData.gang.grade,
				isboss = isOnline.PlayerData.gang.isboss,
				name = '🟢' .. isOnline.PlayerData.charinfo.firstname .. ' ' .. isOnline.PlayerData.charinfo.lastname
				}
			else
				employees[#employees+1] = {
				empSource = value.citizenid,
				grade =  json.decode(value.gang).grade,
				isboss = json.decode(value.gang).isboss,
				name = '❌' ..  json.decode(value.charinfo).firstname .. ' ' .. json.decode(value.charinfo).lastname
				}
			end
		end
	end
	cb(employees)
end)

-- Grade Change
RegisterNetEvent('lxr-gangmenu:server:GradeUpdate', function(data)
	local src = source
	local Player = exports['lxr-core']:GetPlayer(src)
	local Employee = exports['lxr-core']:GetPlayerByCitizenId(data.cid)
	if Employee then
		if Employee.Functions.SetGang(Player.PlayerData.gang.name, data.grado) then
			TriggerClientEvent('LXRCore:Notify', src, 9, "Successfully promoted!", 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
			TriggerClientEvent('LXRCore:Notify', Employee.PlayerData.source, 9, "You have been promoted to " ..data.nomegrado..".", 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
		else
			TriggerClientEvent('LXRCore:Notify', src, 9, "Grade does not exist.", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
		end
	else
		TriggerClientEvent('LXRCore:Notify', src, 9, "Civilian is not in city.", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
	end
	TriggerClientEvent('lxr-gangmenu:client:OpenMenu', src)
end)

-- Fire Member
RegisterNetEvent('lxr-gangmenu:server:FireMember', function(target)
	local src = source
	local Player = exports['lxr-core']:GetPlayer(src)
	local Employee = exports['lxr-core']:GetPlayerByCitizenId(target)
	if Employee then
		if target ~= Player.PlayerData.citizenid then
			if Employee.Functions.SetGang("none", '0') then
				TriggerEvent("lxr-log:server:CreateLog", "gangmenu", "Gang Fire", "orange", Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. ' successfully fired ' .. Employee.PlayerData.charinfo.firstname .. " " .. Employee.PlayerData.charinfo.lastname .. " (" .. Player.PlayerData.gang.name .. ")", false)
				TriggerClientEvent('LXRCore:Notify', src, 9, "Gang Member fired!", 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
				TriggerClientEvent('LXRCore:Notify', Employee.PlayerData.source , 9, "You have been expelled from the gang!", 2000, 0, 'mp_lobby_textures', 'cross')
			else
				TriggerClientEvent('LXRCore:Notify', src, 9, "Error.", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
			end
		else
			TriggerClientEvent('LXRCore:Notify', src, 9, "You can\'t kick yourself out of the gang!", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
		end
	else
		local player = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', {target})
		if player[1] ~= nil then
			Employee = player[1]
			local gang = {}
			gang.name = "none"
			gang.label = "No Affiliation"
			gang.payment = 0
			gang.onduty = true
			gang.isboss = false
			gang.grade = {}
			gang.grade.name = nil
			gang.grade.level = 0
			MySQL.query.await('UPDATE players SET gang = ? WHERE citizenid = ?', {json.encode(gang), target})
			TriggerClientEvent('LXRCore:Notify', src, 9, "Gang member fired!", 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
			TriggerEvent("lxr-log:server:CreateLog", "gangmenu", "Gang Fire", "orange", Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. ' successfully fired ' .. Employee.PlayerData.charinfo.firstname .. " " .. Employee.PlayerData.charinfo.lastname .. " (" .. Player.PlayerData.gang.name .. ")", false)
		else
			TriggerClientEvent('LXRCore:Notify', src, 9, "Civilian is not in city.", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
		end
	end
	TriggerClientEvent('lxr-gangmenu:client:OpenMenu', src)
end)

-- Recruit Player
RegisterNetEvent('lxr-gangmenu:server:HireMember', function(recruit)
	local src = source
	local Player = exports['lxr-core']:GetPlayer(src)
	local Target = exports['lxr-core']:GetPlayer(recruit)
	if Player.PlayerData.gang.isboss == true then
		if Target and Target.Functions.SetGang(Player.PlayerData.gang.name, 0) then
			TriggerClientEvent('LXRCore:Notify', src, 9, "You hired " .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. " come " .. Player.PlayerData.gang.label .. "", 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
			TriggerClientEvent('LXRCore:Notify', Target.PlayerData.source , 9, "You have been hired as " .. Player.PlayerData.gang.label .. "", 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
			TriggerEvent('lxr-log:server:CreateLog', 'gangmenu', 'Recruit', 'yellow', (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname).. ' successfully recruited ' .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname .. ' (' .. Player.PlayerData.gang.name .. ')', false)
		end
	end
	TriggerClientEvent('lxr-gangmenu:client:OpenMenu', src)
end)

-- Get closest player sv
exports['lxr-core']:CreateCallback('lxr-gangmenu:getplayers', function(source, cb)
	local src = source
	local players = {}
	local PlayerPed = GetPlayerPed(src)
	local pCoords = GetEntityCoords(PlayerPed)
	for k, v in pairs(exports['lxr-core']:GetPlayers()) do
		local targetped = GetPlayerPed(v)
		local tCoords = GetEntityCoords(targetped)
		local dist = #(pCoords - tCoords)
		if PlayerPed ~= targetped and dist < 10 then
			local ped = exports['lxr-core']:GetPlayer(v)
			players[#players+1] = {
			id = v,
			coords = GetEntityCoords(targetped),
			name = ped.PlayerData.charinfo.firstname .. " " .. ped.PlayerData.charinfo.lastname,
			citizenid = ped.PlayerData.citizenid,
			sources = GetPlayerPed(ped.PlayerData.source),
			sourceplayer = ped.PlayerData.source
			}
		end
	end
		table.sort(players, function(a, b)
			return a.name < b.name
		end)
	cb(players)
end)

