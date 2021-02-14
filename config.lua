Config = {}
Config.Locale = 'it'
Config.ShopCoords = vector3(562.38, 2740.58, 41.50)
Config.EnablePetBlip = true

Config.PetCanDie = true
Config.DeathTimeout = 60 -- Waiting time if the pet dies in seconds

-- If true pet will help you in fights
Config.PetCanHelp = true 

Config.AllowedVehicleClass = {
	0, -- Compacts  
	1, -- Sedans  
	2, -- SUVs  
	3, -- Coupes  
	4, -- Muscle  
	5, -- Sports Classics  
	6, -- Sports  
	7, -- Super  
	-- 8, -- Motorcycles  
	9, -- Off-road  
	10, -- Industrial  
	11, -- Utility  
	12, -- Vans  
	-- 13, -- Cycles  
	-- 14, -- Boats  
	-- 15, -- Helicopters  
	-- 16, -- Planes  
	17, -- Service  
	18, -- Emergency  
	19, -- Military  
	20, -- Commercial  
	-- 21, -- Trains  
}

Config.Animals = {
	{
		label = "Retriver",
		name = "a_c_retriever",
		price = 1800,
		animations = {
			sit = {dict = "creatures@retriever@amb@world_dog_sitting@enter", anim = "enter"},
			stand_up = {dict = "creatures@retriever@amb@world_dog_sitting@exit", anim = "exit"},
			car = {dict = "creatures@retriever@amb@world_dog_sitting@enter", anim = "enter"}
		}
	},
	{
		label = "Husky",
		name = "a_c_husky",
		price = 1500,
		animations = {
			sit = {dict = "creatures@husky@move", anim = "idle"},
			stand_up = {dict = "creatures@husky@move", anim = "idle"},
			car = {dict = "creatures@dog@move", anim = "sit_enter"}
		}
	},
	{
		label = "Rottweiler",
		name = "a_c_rottweiler",
		price = 1100,
		animations = {
			sit = {dict = "creatures@rottweiler@amb@world_dog_sitting@enter", anim = "enter"},
			stand_up = {dict = "creatures@rottweiler@amb@world_dog_sitting@exit", anim = "exit"},
			--car = {dict = "creatures@rottweiler@amb@world_dog_sitting@enter", anim = "enter"}
			car = {dict = "creatures@rottweiler@incar@", anim = "sit"}
		}
	},
	{
		label = "Shepherd",
		name = "a_c_shepherd",
		price = 900,
		animations = {
			sit = {dict = "creatures@retriever@amb@world_dog_sitting@enter", anim = "enter"},
			stand_up = {dict = "creatures@retriever@amb@world_dog_sitting@exit", anim = "exit"},
			car = {dict = "creatures@retriever@amb@world_dog_sitting@enter", anim = "enter"}
		}
	},
	{
		label = "Carlino",
		name = "a_c_pug",
		price = 800,
		animations = {
			sit = {dict = "creatures@pug@amb@world_dog_sitting@enter", anim = "enter"},
			stand_up = {dict = "creatures@pug@amb@world_dog_sitting@exit", anim = "exit"},
			car = {dict = "creatures@pug@amb@world_dog_sitting@enter", anim = "enter"}
		}
	},
	{
		label = "Coniglio",
		name = "a_c_rabbit_01",
		price = 80,
		animations = {
			sit = {dict = "creatures@rabbit@move", anim = "idle"},
			stand_up = {dict = "creatures@rabbit@move", anim = "idle"},
			car = {dict = "creatures@rabbit@move", anim = "idle"}
		}
	},
	{
		label = "Gatto",
		name  = "a_c_cat_01",
		price = 60,
		animations = {
			sit = {dict = "creatures@cat@move", anim = "idle_dwn"},
			stand_up = {dict = "creatures@cat@move", anim = "idle_dwn"},
			car = {dict = "creatures@cat@amb@world_cat_sleeping_ground@enter", anim = "enter"}
		}
	},
	{
		label = "Ratto",
		name  = "a_c_rat",
		price = 60,
		animations = {
			sit = {dict = "creatures@rat@move", anim = "idle"},
			stand_up = {dict = "creatures@rat@move", anim = "idle"},
			car = {dict = "creatures@rat@move", anim = "idle"}
		}
	},
	{
		label = "Gallina",
		name  = "a_c_hen",
		price = 60,
		animations = {
			sit = {dict = "creatures@hen@amb@world_hen_standing@enter", anim = "enter"},
			stand_up = {dict = "creatures@hen@amb@world_hen_standing@exit", anim = "exit"},
			car = {dict = "creatures@hen@amb@world_hen_standing@enter", anim = "enter"}
		}
	}
}

