local currentPet = nil
local isFollowing = false
local animalPed = nil
local isPetInVehicle = false
local currentAnimationSet = nil 
local petName = nil
local groupHandle = nil
local petBlip = nil
local isPetDead = false

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
	end
	local blip = AddBlipForCoord(Config.ShopCoords)

	SetBlipSprite (blip, 463)
	SetBlipColour (blip, 47)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName("Negozio Animali")
	EndTextCommandSetBlipName(blip)
end)

Citizen.CreateThread(function()
	while true do
		Wait(0)
		DrawMarker(1, Config.ShopCoords, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.0, 2.0, 1.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)

		if Vdist(GetEntityCoords(GetPlayerPed(-1)), Config.ShopCoords) < 2.5 then
			if not ESX.UI.Menu.IsOpen("default", GetCurrentResourceName(), "pet_shop") then
				alert("Premi ~INPUT_PICKUP~ per aprire il menu")
				if IsControlJustReleased(1, 38) and not IsPedInAnyVehicle(GetPlayerPed(-1), true) then
					OpenShopMenu()
				end
			end
		elseif ESX.UI.Menu.IsOpen("default", GetCurrentResourceName(), "pet_shop") then
			ESX.UI.Menu.Close("default", GetCurrentResourceName(), "pet_shop")
		end
	end
end)

-- Controls
Citizen.CreateThread(function()
	while true do
		Wait(0)
		if IsControlJustPressed(0, 57) and not IsPedInAnyVehicle(GetPlayerPed(-1), false) then -- F9
			OpenPetInteraction()
		end
	end
end)

-- If pet stops, then follow again
Citizen.CreateThread(function()
	while true do
		if animalPed ~= nil then
			-- Follow if pet is still
			if (IsPedFleeing(animalPed) or IsEntityStatic(animalPed)) and isFollowing == true and not IsPedInAnyVehicle(animalPed, false) then
				Wait(2000)
				if IsEntityStatic(animalPed) and isFollowing == true and not IsPedInAnyVehicle(animalPed, false) then
					TaskFollowToOffsetOfEntity(animalPed, GetPlayerPed(-1), 1.0, 1.0, 0, 8.0, -1, 10.0, 1)
				end
			end
		end
		--[[
		--for player vehicle
		if GetVehiclePedIsTryingToEnter(GetPlayerPed(-1)) ~= 0 then
			local seatIndx = GetSeatPedIsTryingToEnter(GetPlayerPed(-1))
			local vehicle = GetVehiclePedIsTryingToEnter(GetPlayerPed(-1))
			local pet = GetPedInVehicleSeat(vehicle, seatIndx)
			
			if GetPedType(GetPedInVehicleSeat(vehicle, seatIndx)) == 28 then
				ClearPedTasks(GetPlayerPed(-1))
			end
		end]]
		Wait(0)
	end
end)

-- Combact
Citizen.CreateThread(function()
	while true do
		if animalPed ~= nil and Config.PetCanHelp then
			-- Make pet not attacking you
			if GetIsTaskActive(animalPed, 342) or GetIsTaskActive(animalPed, 3) then -- CTaskCombat, CTaskCombatRoll<-??
				local target = GetMeleeTargetForPed(animalPed)
				if target == GetPlayerPed(-1) then
					ClearPedTasksImmediately(animalPed)
					TaskFollowToOffsetOfEntity(animalPed, GetPlayerPed(-1), 1.0, 1.0, 0, 8.0, -1, 10.0, 1)
				end
			end
			-- Make pet attack your target while shooting
			if IsPlayerFreeAiming(PlayerId()) then
				local hasTarget, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
				if hasTarget then
					if GetPedConfigFlag(GetPlayerPed(-1), 58, 1) then -- Player shooting
						if target ~= animalPed and target ~= GetPlayerPed(-1) then
							TaskCombatPed(animalPed, target, 0, 16)
						end
					end
				end
			end
			-- Make pet attack your target while meele
			if IsPlayerTargettingAnything(PlayerId()) then
				local hasTarget, target = GetPlayerTargetEntity(PlayerId())
				if hasTarget then
					if GetPedConfigFlag(GetPlayerPed(-1), 58, 1) then -- Player shooting
						if target ~= animalPed and target ~= GetPlayerPed(-1) then
							TaskCombatPed(animalPed, target, 0, 16)
						end
					end
				end
			end
		end
		Wait(0)
	end
end)

-- Pet death, too far
Citizen.CreateThread(function()
	while true do
		if IsPedInAnyVehicle(GetPlayerPed(-1), true) then
			if ESX.UI.Menu.IsOpen("default", GetCurrentResourceName(), "pet_interactions") then
				ESX.UI.Menu.Close("default", GetCurrentResourceName(), "pet_interactions")
			end
		end

		if animalPed ~= nil and isFollowing == true then
			local playerPos = GetEntityCoords(GetPlayerPed(-1))
			local petPos = GetEntityCoords(animalPed)
			if Vdist2(playerPos, petPos) > 10000 then
				DismissAnimal()
				ESX.ShowNotification("~g~" .. petName .. "~s~ è stato congedato")
			end
		end

		if animalPed ~= nil then
			if IsPedFatallyInjured(animalPed) or IsPedDeadOrDying(animalPed) then
				if Config.PetCanDie and isPetDead == false then
					isPetDead = true
					ESX.ShowNotification("~g~" .. petName .. "~s~ è ferito gravemente")
					Citizen.CreateThread(function()
						local timer = Config.DeathTimeout
						while timer > 0 do
							Wait(1000)
							timer = timer - 1
						end
						DismissAnimal()
						isPetDead = false
					end)
				else
					SetEntityHealth(animalPed, 200)
					ResurrectPed(animations)
					if isFollowing then
						TaskFollowToOffsetOfEntity(animalPed, GetPlayerPed(-1), 1.0, 1.0, 0, 8.0, -1, 10.0, 1)
					end
				end
			end
		end
		Wait(0)
	end
end)

-- Vehicle
Citizen.CreateThread(function()
	while true do
		local playerPed = GetPlayerPed(-1)
		-- for animal
		if animalPed ~= nil and isFollowing and IsPedInAnyVehicle(playerPed, false) and not isPetInVehicle then
			local vehicle = GetVehiclePedIsIn(playerPed, false)

			if IsEntityAVehicle(vehicle) then
				if contains(Config.AllowedVehicleClass, GetVehicleClass(vehicle)) then
					if AreAnyVehicleSeatsFree(vehicle) then
						local pos = nil
						TaskWarpPedIntoVehicle(animalPed, vehicle, -2)
						isPetInVehicle = true
						while not IsPedInAnyVehicle(animalPed) do
							Wait(1)
						end
						pos = GetEntityCoords(animalPed)
						if currentAnimationSet.car.dict ~= nil then
							DoRequestAnimSet(currentAnimationSet.car.dict)
							TaskPlayAnimAdvanced(animalPed, currentAnimationSet.car.dict, currentAnimationSet.car.anim, pos.x, pos.y, pos.z + 0.5, 0.0, 0.0, 0.0, 1.0, 1.0, -1, 2)
						end				
					else
						ESX.ShowNotification("Non c'è posto in macchina per ~g~" .. petName)
					end
				else
					--ESX.ShowNotification("~g~" .. petName .. "~s~ non può salire qui")
				end
			end
		elseif isPetInVehicle and not IsPedInAnyVehicle(playerPed) then
			local coords = GetEntityCoords(GetPlayerPed(-1))
			FreezeEntityPosition(animalPed, false)
			SetEntityCoords(animalPed, coords.x + 0.2, coords.y + 0.2, coords.z - 0.5)
			TaskFollowToOffsetOfEntity(animalPed, GetPlayerPed(-1), 1.0, 1.0, 0, 8.0, -1, 50.0, 1)
			isPetInVehicle = false
		end
		Wait(500)
	end
end)

RegisterNetEvent("esx_animalshop:deleteAnimal")
AddEventHandler("esx_animalshop:deleteAnimal", function()
	if animalPed ~= nil then
		DeleteAnimal()
	end
end)

AddEventHandler('playerSpawned', function(spawn)
    if animalPed ~= nil then
    	Wait(1000)
    	ClearPedTasksImmediately(animalPed)
		TaskFollowToOffsetOfEntity(animalPed, GetPlayerPed(-1), 1.0, 1.0, 0, 8.0, -1, 50.0, 1)
	end
end)

-- FUNCTIONS
function contains(tab, element)
	for i=1, #tab do
		if tab[i] == element then
			return true
		end
	end
	return false
end

function CreateAnimal(pet)
	local playerPed = GetPlayerPed(-1)
	local pos = GetEntityCoords(playerPed)
	currentAnimationSet = FindAnimations(currentPet)
	
	PlaySoundFromEntity(-1, "Franklin_Whistle_For_Chop", GetPlayerPed(-1), "SPEECH_RELATED_SOUNDS", 1)

	ESX.Streaming.RequestModel(GetHashKey(currentPet), function()
		isFollowing = true
		local coords = vector3(pos.x + math.random(-5.0, 5.0), pos.y + math.random(-5.0, 5.0), pos.z - 0.4)
		local i = 0
		while not ESX.Game.IsSpawnPointClear(coords, 3.0) do
			if i >= 20 then
				break
			end
			coords = vector3(pos.x + math.random(-5.0, 5.0), pos.y + math.random(-5.0, 5.0), pos.z - 0.4)
			i = i + 1
			Wait(1)
		end
		animalPed = CreatePed(28, currentPet, coords, 1, 1)
		-- Group mng
		

		if Config.PetCanHelp then
			--SetPedSeeingRange(animalPed, 30.0)
			--SetPedHearingRange(animalPed, 30.0)
			SetPedFleeAttributes(animalPed, 0, true)
			SetPedCombatAttributes(animalPed, 5, true)
			SetPedCombatAttributes(animalPed, 46, true)
			SetBlockingOfNonTemporaryEvents(animalPed, true)
			--SetPedCombatRange(animalPed,2)
			--SetPedAlertness(animalPed,3)
			--SetPedCombatAbility(animalPed, 100)
			--SetBlockingOfNonTemporaryEvents(animalPed, true)
			--SetPedCombatMovement(animalPed, 3)
		else
			SetPedHearingRange(animalPed, 0.0)
			SetPedSeeingRange(animalPed, 0.0)
			SetPedAlertness(animalPed, 0.0)
			SetPedFleeAttributes(animalPed, 0, 0)
			SetBlockingOfNonTemporaryEvents(animalPed, true)
		end

		if Config.PetCanDie then
			SetPedCanBeTargettedByPlayer(animalPed, PlayerId(), false)
		else
			SetEntityCanBeDamaged(animalPed, false)
			SetPedCanBeTargetted(animalPed, false)
		end
		if Config.PetCanHelp then
			SetPedRelationshipGroupHash(animalPed, GetHashKey("GUARD_DOG"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("PLAYER"))

			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("CIVMALE"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("CIVFEMALE"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("SECURITY_GUARD"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("AMBIENT_GANG_LOST"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("AMBIENT_GANG_MEXICAN"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("AMBIENT_GANG_FAMILY"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("AMBIENT_GANG_MARABUNTE"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("AMBIENT_GANG_BALLAS"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("AMBIENT_GANG_CULT"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("AMBIENT_GANG_SALVA"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("PRIVATE_SECURITY"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("AMBIENT_GANG_WEICHENG"))
			SetRelationshipBetweenGroups(3, GetHashKey("GUARD_DOG"), GetHashKey("AMBIENT_GANG_HILLBILLY"))
		else
			SetPedRelationshipGroupHash(animalPed, GetHashKey("GUARD_DOG"))
			SetRelationshipBetweenGroups(0, GetHashKey("GUARD_DOG"), GetHashKey("PLAYER"))
			SetRelationshipBetweenGroups(0, GetHashKey("PLAYER"), GetHashKey("GUARD_DOG"))
		end

		SetPedPathCanUseClimbovers(animalPed, true)
		SetEntityAsMissionEntity(animalPed, true,true)
		TaskFollowToOffsetOfEntity(animalPed, GetPlayerPed(-1), 1.0, 1.0, 0, 8.0, -1, 10.0, 1)
		if Config.EnablePetBlip then
			petBlip = AddBlipForEntity(animalPed)
			SetBlipSprite (1, 463)
			SetBlipColour (petBlip, 38)
			SetBlipScale(petBlip, 0.5)
			SetBlipAsShortRange(petBlip, true)

			BeginTextCommandSetBlipName('STRING')
			AddTextComponentSubstringPlayerName(petName)
			EndTextCommandSetBlipName(petBlip)
		end
	end)
end

function DeleteAnimal()
	DeleteEntity(animalPed)
	RemoveGroup(groupHandle)
	if Config.EnablePetBlip then
		RemoveBlip(petBlip)
	end
	animalPed = nil
	currentPet = nil
	isFollowing = false
	isPetInVehicle = false
	currentAnimationSet = nil
end

function DismissAnimal()
	DeleteEntity(animalPed)
	animalPed = nil
	if Config.EnablePetBlip then
		RemoveBlip(petBlip)
	end
end

function FindAnimations(pet)
	for i=1, #Config.Animals do
		if Config.Animals[i].name == pet then
			return Config.Animals[i].animations
		end
	end
end

function OpenShopMenu()
	local elements = {}

	for i=1, #Config.Animals do
		local current = Config.Animals[i]

		table.insert(elements, {
			label = ('%s - <span style="color:green;">%s</span>'):format(current.label, ESX.Math.GroupDigits(current.price) .. "$"),
			label_2 = current.label,
			pet = current.name,
			price = current.price
		})
	end
	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'pet_shop', {
		title    = "Negozio Animali",
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		local newPetName = nil
		local label = data.current.label_2
		currentPet = data.current.pet
		
		menu.close()
		
		ESX.TriggerServerCallback('esx_animalshop:buyPet', function(boughtPed)
			if boughtPed then
				DeleteAnimal(currentPet)

				currentPet = data.current.pet

				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'choose_name',{
					title    = "Dai un nome al tuo animale"
				},function(data, menu)
					TriggerServerEvent("esx_animalshop:changeName", currentPet, data.value)
					petName = data.value
					ESX.ShowNotification("Hai un nuovo animale (~g~" .. petName .. "~s~)")
					menu.close()
				end,
				function(data, menu)
					TriggerServerEvent("esx_animalshop:changeName", currentPet, label)
					petName = label
					ESX.ShowNotification("Hai un nuovo animale (~g~" .. petName .. "~s~)")
					menu.close()
				end)

				
			else
				ESX.ShowNotification("Non hai abbastanza soldi")
			end
			menu.close()
		end, data.current.pet, data.current.price)
		
	end, 
	function(data, menu)
		menu.close()
	end)
end

function OpenPetInteraction()
	local elements = {}

	local followLabel = ""
	if animalPed == nil and isPetDead == false then
		table.insert(elements,  {label = _U("call"), value = "call"})
	elseif animalPed ~= nil and isPetDead == false then
		table.insert(elements,  {label = "Congeda", value = "dismiss"})
		if isFollowing then
			followLabel = "Ferma"
		else
			followLabel = "Segui"
		end
		table.insert(elements,  {label = followLabel, value = "follow"})
		table.insert(elements,  {label = "Cambia nome", value = "change_name"})
	elseif isPetDead == true then
		ESX.ShowNotification("~g~" .. petName .. "~s~ si sta riprendendo")
		return
	end

	local title = ""
	if animalPed == nil then
		title = "Interazioni con il tuo animale"
	else
		title = "Interazioni con " .. petName
	end
	
	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), "pet_interactions", {
		title = title,
		align = "top-left",
		elements = elements
	},function(data, menu)
		if data.current.value == "call" then
			if currentPet == nil then 
				ESX.TriggerServerCallback("esx_animalshop:getPet", function(pet)
					if pet ~= nil then
						currentPet = pet.pet
						petName = pet.name
						CreateAnimal(currentPet)
						ESX.ShowNotification("Hai chiamato ~g~" .. petName)
					else
						ESX.ShowNotification("Devi prima comprare un animale")
					end
					menu.close()
				end)
			else
				CreateAnimal(currentPet)
				ESX.ShowNotification("Hai chiamato ~g~" .. petName)
				menu.close()
			end
		elseif data.current.value == "dismiss" then
			DismissAnimal()
			ESX.ShowNotification("Hai congedato ~g~" .. petName)
			menu.close()
		elseif data.current.value == "follow" then
			local playerPed = GetPlayerPed(-1)
			if isFollowing == true then
				isFollowing = false
				local pos = GetEntityCoords(animalPed)
				if currentAnimationSet.sit.dict ~= nil then
					DoRequestAnimSet(currentAnimationSet.sit.dict)
					TaskPlayAnim(animalPed, currentAnimationSet.sit.dict, currentAnimationSet.sit.anim, 8.0, -8, -1, 2, 0, false, false, false)
				end
				menu.close()
			elseif isFollowing == false then
				isFollowing = true
				if currentAnimationSet.stand_up.dict ~= nil then
					DoRequestAnimSet(currentAnimationSet.stand_up.dict)
					TaskPlayAnim(animalPed, currentAnimationSet.stand_up.dict, currentAnimationSet.stand_up.anim, 8.0, -8, -1, 2, 0, false, false, false)
					menu.close()
					
					Wait(1000)
				else
					menu.close()
				end
				TaskFollowToOffsetOfEntity(animalPed, GetPlayerPed(-1), 1.0, 1.0, 0, 8.0, -1, 10.0, 1)
			end
		elseif data.current.value == "change_name" then
			ESX.UI.Menu.CloseAll()
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'change_name',{
			title    = "Dai un nome al tuo animale"
			},function(data, menu)
				petName = data.value
				TriggerServerEvent("esx_animalshop:changeName", currentPet ,petName)
				ESX.ShowNotification("Ora il tuo animale si chiama ~g~" .. petName)
				menu.close()
			end,
			function(data, menu)
				menu.close()
			end)
		end
	end,
	function(data, menu)
		menu.close()
	end)
end

-- 
RegisterCommand("coords", function()
	print(GetEntityCoords(GetPlayerPed(-1)))
	--SetEntityCoords(GetPlayerPed(-1), vector3(562.38, 2740.58, 41.73))
	GiveWeaponToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PISTOL"), 2000, false--[[ weapon is hidden or not (bool)]], false)
end)

RegisterCommand("petstore", function()
	SetEntityCoords(GetPlayerPed(-1), vector3(562.38, 2740.58, 41.73))
end)

RegisterCommand("tp", function()
	SetEntityCoords(GetPlayerPed(-1), -1398.69, -90.00, 55.50, false, false, false, false)
end)

function alert(msg)
	SetTextComponentFormat("STRING")
	AddTextComponentString(msg)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function DoRequestAnimSet(anim)
	RequestAnimDict(anim)
	while not HasAnimDictLoaded(anim) do
		Citizen.Wait(1)
	end
end

RegisterCommand("spawn", function()
	ESX.Streaming.RequestModel(GetHashKey("s_m_y_swat_01"), function()
		local newPed = CreatePed(7 , GetHashKey("s_m_y_swat_01"), GetEntityCoords(GetPlayerPed(-1)), 0.0, false, true)
		SetPedRelationshipGroupHash(newPed, GetHashKey("PLAYER"))
		local vehicle = ESX.Game.GetVehiclesInArea(GetEntityCoords(GetPlayerPed(-1)), 2.0)[1]
		SetPedIntoVehicle(newPed, vehicle, -1)
		--SetPedCombatAttributes(newPed, 0, true) --[[ BF_CanUseCover ]]
        --SetPedCombatAttributes(newPed, 5, true) --[[ BF_CanFightArmedPedsWhenNotArmed ]]
        --SetPedCombatAttributes(newPed, 46, true) --[[ BF_AlwaysFight ]]
        --SetPedFleeAttributes(newPed, 0, true) --[[ allows/disallows the ped to flee from a threat i think]]
        --GiveWeaponToPed(newPed, GetHashKey("WEAPON_PISTOL"), 2000, false--[[ weapon is hidden or not (bool)]], false)
	end)
end)

RegisterCommand("putPet", function()
	if animalPed ~= nil then
		local vehicle = ESX.Game.GetVehiclesInArea(GetEntityCoords(GetPlayerPed(-1)), 2.0)[1]
		--TaskWarpPedIntoVehicle(animalPed, vehicles[1], -1)
		SetPedIntoVehicle(animalPed, vehicle, -2)
	end
end)

RegisterCommand("petpet" ,function()
	if Vdist(GetEntityCoords(GetPlayerPed(-1)), GetEntityCoords(animalPed)) <= 1.5 then
		if animalPed ~= nil then
			TaskTurnPedToFaceEntity(animalPed, GetPlayerPed(-1), -1)
			TaskTurnPedToFaceEntity(GetPlayerPed(-1), animalPed, -1)
			Wait(3000)
			local pos = GetEntityCoords(GetPlayerPed(-1))
			local rot = GetEntityRotation(GetPlayerPed(-1))
			local scene1 = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z - 1.0, rot, 2, false, false, 1065353216, 0, 1.3)
			DoRequestAnimSet("creatures@rottweiler@tricks@")
			NetworkAddPedToSynchronisedScene(animalPed, scene1, "creatures@rottweiler@tricks@", "petting_chop", 1.5, -2.5, 4, 0, 1148846080, 0)
			NetworkAddPedToSynchronisedScene(GetPlayerPed(-1), scene1, "creatures@rottweiler@tricks@", "petting_franklin", 1.5, -2.5, 4, 0, 1148846080, 0)
			NetworkStartSynchronisedScene(scene1)
			--ClearPedTasks(animalPed)
			--ClearPedTasks(GetPlayerPed(-1))
			--TaskFollowToOffsetOfEntity(animalPed, GetPlayerPed(-1), 1.0, 1.0, 0, 8.0, -1, 10.0, 1)
		end
	else
		ESX.ShowNotification(petName .. " è troppo lontano")
	end
end)

-- TEST

local doors = {
	{"seat_dside_f", -1},
	{"seat_pside_f", 0},
	{"seat_dside_r", 1},
	{"seat_pside_r", 2}
}

function VehicleInFront(ped)
    local pos = GetEntityCoords(ped)
    local entityWorld = GetOffsetFromEntityInWorldCoords(ped, 0.0, 5.0, 0.0)
    local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, ped, 0)
    local _, _, _, _, result = GetRaycastResult(rayHandle)
	
    return result
end

Citizen.CreateThread(function()
	while true do
    	Citizen.Wait(0)
			
		local ped = PlayerPedId()
			
   		if IsControlJustReleased(0, 23) and running ~= true and GetVehiclePedIsIn(ped, false) == 0 then
      		local vehicle = VehicleInFront(ped)

      		running = true
				
      		if vehicle ~= nil then
				local plyCoords = GetEntityCoords(ped, false)
        		local doorDistances = {}
					
        		for k, door in pairs(doors) do
          			local doorBone = GetEntityBoneIndexByName(vehicle, door[1])
          			local doorPos = GetWorldPositionOfEntityBone(vehicle, doorBone)
          			local distance = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, doorPos.x, doorPos.y, doorPos.z)
					
        			if GetPedType(GetPedInVehicleSeat(vehicle, door[2])) == 28 then
						distance = distance + 50.0
					end
					table.insert(doorDistances, distance)
        		end
					
        		local key, min = 1, doorDistances[1]
					
        		for k, v in ipairs(doorDistances) do
          			if doorDistances[k] < min then
           				key, min = k, v
          			end
        		end
					
        		TaskEnterVehicle(ped, vehicle, -1, doors[key][2], 1.5, 1, 0)
     		end
				
      		running = false
    	end
  	end
end)

-- Disable seat shuffle
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
			SetPedConfigFlag(GetPlayerPed(-1), 184, true)
		end
	end
end)