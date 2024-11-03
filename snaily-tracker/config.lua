Config = {}

Config.NPCLocation = vector3(9.9926, -667.2503, 33.4493) -- Lokalizacja NPC od zleceń / NPC Mission Location
Config.NPCModel = "cs_andreas" -- Model NPC / NPC Model

Config.VanModel = 'stockade' -- Model furgonetki / Van Model
Config.GuardModel = 's_m_m_security_01' -- Model strażników / Guard Model
Config.GuardWeapon = 'WEAPON_COMBATPISTOL' -- Broń strażników / Guard Weapon

Config.MissionTimeLimit = 900    -- Limit czasu na wykonanie zlecenia (15 minut) / Time limit for mission completion (15 minutes)
Config.FailureExpPenalty = 200   -- Kara exp za niewykonanie zlecenia w czasie / EXP penalty for mission failure

Config.Timers = {
    plantBomb = 9000,    -- Podstawowy czas podkładania bomby / Base time for planting bomb
    collectMoney = 6000, -- Podstawowy czas zbierania / Base time for collecting money
}

Config.Skills = {
    fastFingers = {
        name = "Szybkie palce", -- Fast Fingers
        levels = {
            [1] = {
                price = 10000, -- Cena umiejętności / Skill price
                plantBombTime = 7000, -- Czas podkładania bomby / Bomb planting time
                collectMoneyTime = 5000, -- Czas zbierania / Collection time
                description = "Poziom 1: -2s podkładanie, -1s zbieranie" -- Level 1: -2s planting, -1s collecting
            },
            [2] = {
                price = 25000, -- Cena umiejętności / Skill price
                plantBombTime = 5000, -- Czas podkładania bomby / Bomb planting time
                collectMoneyTime = 3000, -- Czas zbierania / Collection time
                description = "Poziom 2: -4s podkładanie, -3s zbieranie" -- Level 2: -4s planting, -3s collecting
            }
        }
    },
    informator = {
        name = "Informator", -- Informant
        levels = {
            [1] = {
                price = 40000, -- Cena umiejętności / Skill price
                searchRadius = 50.0, -- Obszar czerwonego kółka / Red circle search area
                description = "Dokładniejsze informacje o lokalizacji celu" -- More precise target location information
            }
        }
    }
}

Config.Easy = {
    Guards = 2, -- Liczba strażników (bez kierowcy) / Number of guards (excluding driver)
    GuardDifficulty = {
        accuracy = 40, -- Celność strażników (0-100) / Guard accuracy (0-100)
        armor = 50,   -- Pancerz strażników / Guard armor
        combat = 50   -- Umiejętności walki (0-100) / Combat ability (0-100)
    },
    Escape = {
        distance = 50.0, -- Odległość od której furgonetka zaczyna uciekać / Distance at which van starts escaping
        speed = 20.0    -- Prędkość ucieczki / Escape speed
    },
    Rewards = {
        money = {min = 5000, max = 10000}, -- Zakres nagrody pieniężnej / Money reward range
        exp = 50 -- Doświadczenie za wykonanie / Experience for completion
    },
    Cooldown = 1 -- Czas odnowienia w sekundach (5 minut) / Cooldown in seconds (5 minutes) 300
}

Config.Hard = {
    Guards = 3, -- Liczba strażników (bez kierowcy) / Number of guards (excluding driver)
    GuardDifficulty = {
        accuracy = 100, -- Celność strażników (0-100) / Guard accuracy (0-100)
        armor = 100,   -- Pancerz strażników / Guard armor
        combat = 100   -- Umiejętności walki (0-100) / Combat ability (0-100)
    },
    Escape = {
        distance = 40.0, -- Odległość od której furgonetka zaczyna uciekać / Distance at which van starts escaping
        speed = 30.0    -- Prędkość ucieczki / Escape speed
    },
    Rewards = {
        money = {min = 10000, max = 20000}, -- Zakres nagrody pieniężnej / Money reward range
        exp = 100 -- Doświadczenie za wykonanie / Experience for completion
    },
    Cooldown = 1 -- Czas odnowienia w sekundach (10 minut) / Cooldown in seconds (10 minutes) 600
}

Config.Levels = {
    [1] = {exp = 0, name = "Początkujący"}, -- Beginner
    [2] = {exp = 1000, name = "Zaawansowany"}, -- Advanced (10 easy missions or 5 hard ones)
    [3] = {exp = 2500, name = "Ekspert"},      -- Expert (25 easy missions or 13 hard ones)
    [4] = {exp = 5000, name = "Mistrz"}        -- Master (50 easy missions or 25 hard ones)
}

Config.LevelBonuses = {
    [1] = { money = 0 },    -- Początkujący (brak bonusu) / Beginner (no bonus)
    [2] = { money = 2000 }, -- Zaawansowany / Advanced
    [3] = { money = 4000 }, -- Ekspert / Expert
    [4] = { money = 6000 }  -- Mistrz / Master
}

Config.VanLocations = {
    vector4(1204.5187, -3116.3350, 5.5403, 0.0), -- Doki / Docks
}

Config.Animations = {
    planting_bomb = {
        dict = 'anim@heists@ornate_bank@thermal_charge',
        clip = 'thermal_charge'
    },
    collecting_money = {
        dict = 'anim@heists@ornate_bank@grab_cash',
        clip = 'grab'
    }
}

Config.ShowNotification = function(data)
    lib.notify({
        title = data.title,
        description = data.description,
        type = data.type
    })
end

Config.ShowProgressBar = function(data)
    return lib.progressBar({
        duration = data.duration,
        label = data.label,
        useWhileDead = false,
        canCancel = true,
        disable = data.disable,
        anim = data.anim
    })
end
