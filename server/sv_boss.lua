

--[[
    ██╗     ██╗  ██╗██████╗       ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗███╗   ███╗███████╗███╗   ██╗████████╗
    ██║     ╚██╗██╔╝██╔══██╗      ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
    ██║      ╚███╔╝ ██████╔╝█████╗██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██╔████╔██║█████╗  ██╔██╗ ██║   ██║   
    ██║      ██╔██╗ ██╔══██╗╚════╝██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   
    ███████╗██╔╝ ██╗██║  ██║      ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   

    🐺 LXR Management System — Server: Boss Menu

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

local Accounts = {}

CreateThread(function()
	Wait(500)
	local bossmenu = MySQL.query.await('SELECT * FROM management_menu WHERE menu_type = "boss"', {})
	if not bossmenu then
		return
	end
	for k,v in pairs(bossmenu) do
		local k = tostring(v.job_name)
		local v = tonumber(v.amount)
		if k and v then
			Accounts[k] = v
		end
	end
end)

RegisterNetEvent("lxr-bossmenu:server:withdrawMoney", function(amount)
	local src = source
	local xPlayer = exports['lxr-core']:GetPlayer(src)
	local job = xPlayer.PlayerData.job.name

	if not Accounts[job] then
		Accounts[job] = 0
	end

	if Accounts[job] >= amount and amount > 0 then
		Accounts[job] = Accounts[job] - amount
		xPlayer.Functions.AddMoney("cash", amount)
	else
		TriggerClientEvent('LXRCore:Notify', src, 9, "Invalid Amount!", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
		TriggerClientEvent('lxr-bossmenu:client:OpenMenu', src)
		return
	end

	MySQL.query.await('UPDATE management_menu SET amount = ? WHERE job_name = ? AND menu_type = "boss"', { Accounts[job], job})
	TriggerEvent('lxr-log:server:CreateLog', 'bossmenu', 'Withdraw Money', "blue", xPlayer.PlayerData.name.. "Withdrawal $" .. amount .. ' (' .. job .. ')', true)
	TriggerClientEvent('LXRCore:Notify', src, 9, "You have withdrawn: $" ..amount, 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
	TriggerClientEvent('lxr-bossmenu:client:OpenMenu', src)
end)

RegisterNetEvent("lxr-bossmenu:server:depositMoney", function(amount)
	local src = source
	local xPlayer = exports['lxr-core']:GetPlayer(src)
	local job = xPlayer.PlayerData.job.name

	if not Accounts[job] then
		Accounts[job] = 0
	end

	if xPlayer.Functions.RemoveMoney("cash", amount) then
		Accounts[job] = Accounts[job] + amount
	else
		TriggerClientEvent('LXRCore:Notify', src, 9, "Invalid Amount!", 2000, 0, 'mp_lobby_textures', 'cross')
		TriggerClientEvent('lxr-bossmenu:client:OpenMenu', src)
		return
	end

	MySQL.query.await('UPDATE management_menu SET amount = ? WHERE job_name = ? AND menu_type = "boss"', { Accounts[job], job })
	TriggerEvent('lxr-log:server:CreateLog', 'bossmenu', 'Deposit Money', "blue", xPlayer.PlayerData.name.. "Deposit $" .. amount .. ' (' .. job .. ')', true)
	TriggerClientEvent('LXRCore:Notify', src, 9, "You have deposited: $" ..amount, 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
	TriggerClientEvent('lxr-bossmenu:client:OpenMenu', src)
end)

RegisterNetEvent("lxr-bossmenu:server:addAccountMoney", function(account, amount)
	if not Accounts[account] then
		Accounts[account] = 0
	end

	Accounts[account] = Accounts[account] + amount
	MySQL.query.await('UPDATE management_menu SET amount = ? WHERE job_name = ? AND menu_type = "boss"', { Accounts[account], account })
end)

RegisterNetEvent("lxr-bossmenu:server:removeAccountMoney", function(account, amount)
	if not Accounts[account] then
		Accounts[account] = 0
	end

	if Accounts[account] >= amount then
		Accounts[account] = Accounts[account] - amount
	end

	MySQL.query.await('UPDATE management_menu SET amount = ? WHERE job_name = ? AND menu_type = "boss"', { Accounts[account], account })
end)

exports['lxr-core']:CreateCallback('lxr-bossmenu:server:GetAccount', function(source, cb, jobname)
	local result = GetAccount(jobname)
	cb(result)
end)

-- Export
function GetAccount(account)
	return Accounts[account] or 0
end

-- Get Employees
exports['lxr-core']:CreateCallback('lxr-bossmenu:server:GetEmployees', function(source, cb, jobname)
	local src = source
	local employees = {}
	if not Accounts[jobname] then
		Accounts[jobname] = 0
	end
	local players = MySQL.query.await("SELECT * FROM `players` WHERE `job` LIKE '%".. jobname .."%'", {})
	if players[1] ~= nil then
		for key, value in pairs(players) do
			local isOnline = exports['lxr-core']:GetPlayerByCitizenId(value.citizenid)

			if isOnline then
				employees[#employees+1] = {
				empSource = isOnline.PlayerData.citizenid,
				grade = isOnline.PlayerData.job.grade,
				isboss = isOnline.PlayerData.job.isboss,
				name = '🟢 ' .. isOnline.PlayerData.charinfo.firstname .. ' ' .. isOnline.PlayerData.charinfo.lastname
				}
			else
				employees[#employees+1] = {
				empSource = value.citizenid,
				grade =  json.decode(value.job).grade,
				isboss = json.decode(value.job).isboss,
				name = '❌ ' ..  json.decode(value.charinfo).firstname .. ' ' .. json.decode(value.charinfo).lastname
				}
			end
		end
		table.sort(employees, function(a, b)
            return a.grade.level > b.grade.level
        end)
	end
	cb(employees)
end)

-- Grade Change
RegisterNetEvent('lxr-bossmenu:server:GradeUpdate', function(data)
	local src = source
	local Player = exports['lxr-core']:GetPlayer(src)
	local Employee = exports['lxr-core']:GetPlayerByCitizenId(data.cid)
	if Employee then
		if Employee.Functions.SetJob(Player.PlayerData.job.name, data.grado) then
			TriggerClientEvent('LXRCore:Notify', src, 9, "Sucessfulluy promoted!", 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
			TriggerClientEvent('LXRCore:Notify', Employee.PlayerData.source, 9, "You have been promoted to" ..data.nomegrado..".", 2000, 0, 'hud_textures', 'check')
		else
			TriggerClientEvent('LXRCore:Notify', src, 9, "Promotion grade does not exist.", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
		end
	else
		TriggerClientEvent('LXRCore:Notify', src, 9, "Civilian not in city.", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
	end
	TriggerClientEvent('lxr-bossmenu:client:OpenMenu', src)
end)

-- Fire Employee
RegisterNetEvent('lxr-bossmenu:server:FireEmployee', function(target)
	local src = source
	local Player = exports['lxr-core']:GetPlayer(src)
	local Employee = exports['lxr-core']:GetPlayerByCitizenId(target)
	if Employee then
		if target ~= Player.PlayerData.citizenid then
			if Employee.Functions.SetJob("unemployed", '0') then
				TriggerEvent("lxr-log:server:CreateLog", "bossmenu", "Job Fire", "red", Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. ' successfully fired ' .. Employee.PlayerData.charinfo.firstname .. " " .. Employee.PlayerData.charinfo.lastname .. " (" .. Player.PlayerData.job.name .. ")", false)
				TriggerClientEvent('LXRCore:Notify', src, 9, "Employee fired!", 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
				TriggerClientEvent('LXRCore:Notify', Employee.PlayerData.source , 9, "You have been fired! Good luck.", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
			else
				TriggerClientEvent('LXRCore:Notify', src, 9, "Error..", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
			end
		else
			TriggerClientEvent('LXRCore:Notify', src, 9, "You can\'t fire yourself", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
		end
	else
		local player = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', { target })
		if player[1] ~= nil then
			Employee = player[1]
			local job = {}
			job.name = "unemployed"
			job.label = "Unemployed"
			job.payment = 500
			job.onduty = true
			job.isboss = false
			job.grade = {}
			job.grade.name = nil
			job.grade.level = 0
			MySQL.query.await('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(job), target })
			TriggerClientEvent('LXRCore:Notify', src, 9, "Employee fired!", 2000, 0, 'hud_textures', 'check')
			TriggerEvent("lxr-log:server:CreateLog", "bossmenu", "Job Fire", "red", Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. ' successfully fired ' .. Employee.PlayerData.charinfo.firstname .. " " .. Employee.PlayerData.charinfo.lastname .. " (" .. Player.PlayerData.job.name .. ")", false)
		else
			TriggerClientEvent('LXRCore:Notify', src, 9, "Civilian not in city.", 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
		end
	end
	TriggerClientEvent('lxr-bossmenu:client:OpenMenu', src)
end)

-- Recruit Player
RegisterNetEvent('lxr-bossmenu:server:HireEmployee', function(recruit)
	local src = source
	local Player = exports['lxr-core']:GetPlayer(src)
	local Target = exports['lxr-core']:GetPlayer(recruit)
	if Player.PlayerData.job.isboss == true then
		if Target and Target.Functions.SetJob(Player.PlayerData.job.name, 0) then
			TriggerClientEvent('LXRCore:Notify', src, 9, "You hired " .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. " come " .. Player.PlayerData.job.label .. "", 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
			TriggerClientEvent('LXRCore:Notify', Target.PlayerData.source , 9, "You were hired as " .. Player.PlayerData.job.label .. "", 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
			TriggerEvent('lxr-log:server:CreateLog', 'bossmenu', 'Recruit', "lightgreen", (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname).. " successfully recruited " .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. ' (' .. Player.PlayerData.job.name .. ')', true)
		end
	end
	TriggerClientEvent('lxr-bossmenu:client:OpenMenu', src)
end)

-- Get closest player sv
exports['lxr-core']:CreateCallback('lxr-bossmenu:getplayers', function(source, cb)
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

