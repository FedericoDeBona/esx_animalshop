ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('esx_animalshop:buyPet', function(playerId, cb, pet, price)
	local petProperties = json.encode({pet = pet, name = ""})
	local xPlayer = ESX.GetPlayerFromId(playerId)
	if xPlayer.getMoney() >= price then
		xPlayer.removeMoney(price)
		MySQL.Async.execute('UPDATE users SET pet = @pet WHERE identifier = @identifier', {['@pet'] = petProperties, ['@identifier'] = xPlayer.identifier})
		cb(true)
	else
		cb(false)
	end
end)

AddEventHandler("playerDropped", function(source, reason)
	local _source = source
	TriggerClientEvent("esx_animalshop:deleteAnimal", _source)
end)

RegisterServerEvent("esx_animalshop:changeName")
AddEventHandler("esx_animalshop:changeName", function(pet, petName)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local petProperties = json.encode({pet = pet, name = petName})
	MySQL.Async.execute('UPDATE users SET pet = @pet WHERE identifier = @identifier', {['@pet'] = petProperties, ['@identifier'] = xPlayer.identifier})
end)

ESX.RegisterServerCallback('esx_animalshop:getPet', function(playerId, cb)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	MySQL.Async.fetchAll('SELECT pet, identifier FROM users WHERE identifier = @identifier', 
		{['@identifier'] = xPlayer.identifier},
		function(result)
			if result[1].pet ~= nil then
				local val = json.decode(result[1].pet)
				cb({pet = val.pet, name = val.name})
			else
				cb(nil)
			end
		end)
end)