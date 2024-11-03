local ox_target = exports.ox_target

local activeJob = false
local missionBlip = nil
local missionVehicle = nil
local guards = {}
local playerData = {
    level = 1,
    exp = 0,
    completedJobs = 0,
    skills = {
        fastFingers = 0,
        informator = 0
    }
}
local currentQueueInfo = {position = 0, total = 0}
local currentDifficulty = nil

local function DrawText2D(text, x, y)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(x, y)
end

local function GetModifiedTimer(baseTimer, timerType)
    local skillLevel = playerData.skills.fastFingers or 0
    if skillLevel > 0 then
        if timerType == 'plantBomb' then
            return Config.Skills.fastFingers.levels[skillLevel].plantBombTime
        elseif timerType == 'collectMoney' then
            return Config.Skills.fastFingers.levels[skillLevel].collectMoneyTime
        end
    end
    return baseTimer
end

function ResyncPlayerData()
    playerData = lib.callback.await('snaily-tracker:getPlayerData', false)
end

local function CreateJobNPC()
    local model = GetHashKey(Config.NPCModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local npc = CreatePed(4, model, Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z - 1, 0.0, false, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    ox_target:addLocalEntity(npc, {
        {
            name = 'tracker_npc',
            label = 'Porozmawiaj',
            icon = 'fas fa-comments',
            onSelect = function()
                OpenJobMenu()
            end
        }
    })
end

function OpenJobMenu()
    lib.registerContext({
        id = 'tracker_menu',
        title = 'Zarządzaj',
        options = {
            {
                title = 'Zlecenia',
                description = 'Zobacz dostępne zlecenia',
                onSelect = function()
                    OpenMissionMenu()
                end
            },
            {
                title = 'Poziom specjalizacji',
                description = 'Sprawdź swój aktualny poziom',
                onSelect = function()
                    ShowLevelInfo()
                end
            },
            {
                title = 'Umiejętności',
                description = 'Zobacz aktualne umiejętności',
                onSelect = function()
                    OpenSkillsMenu()
                end
            }
        }
    })

    lib.showContext('tracker_menu')
end

function OpenMissionMenu()
    local queueInfo = lib.callback.await('snaily-tracker:getQueueInfo', false)
    currentQueueInfo = queueInfo

    lib.registerContext({
        id = 'mission_menu',
        title = 'Zlecenia',
        options = {
            {
                title = 'Zlecenie - Poziom Łatwy',
                metadata = {
                    {label = 'Osób w kolejce', value = currentQueueInfo.total},
                    {label = 'Wykonane zlecenia', value = playerData.completedJobs},
                },
                onSelect = function()
                    CheckJobAvailability('easy')
                end
            },
            {
                title = 'Zlecenie - Poziom Trudny',
                metadata = {
                    {label = 'Osób w kolejce', value = currentQueueInfo.total},
                    {label = 'Wykonane zlecenia', value = playerData.completedJobs},
                },
                onSelect = function()
                    CheckJobAvailability('hard')
                end
            }
        }
    })

    lib.showContext('mission_menu')
end

function ShowLevelInfo()
    local nextLevel = Config.Levels[playerData.level + 1]
    local currentLevelData = Config.Levels[playerData.level]

    local options = {
        {
            title = 'Aktualny Poziom: ' .. currentLevelData.name,
            metadata = {
                {label = 'Doświadczenie', value = playerData.exp .. ' / ' .. (nextLevel and nextLevel.exp or 'MAX')},
                {label = 'Wykonane zlecenia', value = playerData.completedJobs}
            }
        }
    }

    if nextLevel then
        local canLevelUp = playerData.exp >= nextLevel.exp
        table.insert(options, {
            title = 'Awansuj na następny poziom',
            description = canLevelUp and 'Kliknij aby awansować!' or 'Nie spełniasz wymagań',
            disabled = not canLevelUp,
            onSelect = function()
                if canLevelUp then
                    if lib.callback.await('snaily-tracker:tryLevelUp', false) then
                        ResyncPlayerData()
                    end
                end
            end
        })
    end

    lib.registerContext({
        id = 'level_menu',
        title = 'Poziom Specjalizacji',
        options = options
    })

    lib.showContext('level_menu')
end

function OpenSkillsMenu()
    local currentLevelFastFingers = playerData.skills.fastFingers or 0
    local currentLevelInformator = playerData.skills.informator or 0
    local nextLevelFastFingers = Config.Skills.fastFingers.levels[currentLevelFastFingers + 1]
    local nextLevelInformator = Config.Skills.informator.levels[currentLevelInformator + 1]

    local options = {
        {
            title = 'Szybkie palce',
            description = nextLevelFastFingers and nextLevelFastFingers.description or 'Maksymalny poziom osiągnięty',
            metadata = {
                {label = 'Aktualny poziom', value = currentLevelFastFingers},
                {label = 'Koszt ulepszenia', value = nextLevelFastFingers and '$' .. nextLevelFastFingers.price or 'MAX'},
            },
            disabled = not nextLevelFastFingers,
            onSelect = function()
                if nextLevelFastFingers then
                    local success = lib.callback.await('snaily-tracker:buySkill', false, 'fastFingers')
                    if success then
                        ResyncPlayerData()
                        OpenSkillsMenu()
                    end
                end
            end
        },
        {
            title = 'Informator',
            description = nextLevelInformator and nextLevelInformator.description or 'Maksymalny poziom osiągnięty',
            metadata = {
                {label = 'Aktualny poziom', value = currentLevelInformator},
                {label = 'Koszt ulepszenia', value = nextLevelInformator and '$' .. nextLevelInformator.price or 'MAX'},
            },
            disabled = not nextLevelInformator,
            onSelect = function()
                if nextLevelInformator then
                    local success = lib.callback.await('snaily-tracker:buySkill', false, 'informator')
                    if success then
                        ResyncPlayerData()
                        OpenSkillsMenu()
                    end
                end
            end
        }
    }

    lib.registerContext({
        id = 'skills_menu',
        title = 'Umiejętności',
        options = options
    })

    lib.showContext('skills_menu')
end

function CheckJobAvailability(difficulty)
    if activeJob then
        Config.ShowNotification({
            title = 'Błąd',
            description = 'Już masz aktywne zlecenie!',
            type = 'error'
        })
        return
    end

    local canStart = lib.callback.await('snaily-tracker:checkJobAvailability', false, difficulty)
    if canStart then
        currentDifficulty = difficulty
        StartTrackerMission()
    end
end

function StartTrackerMission()
    if activeJob then return end

    activeJob = true
    local endTime = GetGameTimer() + (Config.MissionTimeLimit * 1000)

    CreateThread(function()
        while activeJob do
            local remaining = math.max(0, endTime - GetGameTimer())
            if remaining <= 0 then
                break
            end
            DrawText2D('Pozostało: ' .. math.floor(remaining / 1000) .. 's', 0.5, 0.95)
            Wait(0)
        end
    end)

    local randomLoc = Config.VanLocations[math.random(#Config.VanLocations)]

    if missionBlip then RemoveBlip(missionBlip) end

    local informatorLevel = playerData.skills.informator or 0
    local searchRadius = 100.0

    if informatorLevel > 0 then
        searchRadius = Config.Skills.informator.levels[informatorLevel].searchRadius
    end

    missionBlip = AddBlipForRadius(randomLoc.x, randomLoc.y, randomLoc.z, searchRadius)
    SetBlipColour(missionBlip, 1)
    SetBlipAlpha(missionBlip, 128)

    Config.ShowNotification({
        title = 'Zlecenie rozpoczęte',
        description = 'Udaj się do oznaczonego obszaru i znajdź furgonetkę',
        type = 'info'
    })

    SpawnVanAndGuards(randomLoc)
end

function SpawnVanAndGuards(location)
    local settings = currentDifficulty == 'easy' and Config.Easy or Config.Hard
    local vehHash = GetHashKey(Config.VanModel)
    local guardHash = GetHashKey(Config.GuardModel)

    RequestModel(vehHash)
    RequestModel(guardHash)

    while not HasModelLoaded(vehHash) or not HasModelLoaded(guardHash) do
        Wait(0)
    end

    missionVehicle = CreateVehicle(vehHash, location.x, location.y, location.z, location.w, true, false)
    SetEntityAsMissionEntity(missionVehicle, true, true)

    CreateThread(function()
        local found = false
        while not found and DoesEntityExist(missionVehicle) and activeJob do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local vanCoords = GetEntityCoords(missionVehicle)
            local distance = #(playerCoords - vanCoords)

            if distance < 30.0 then
                found = true
                if missionBlip then
                    RemoveBlip(missionBlip)
                end
                missionBlip = AddBlipForEntity(missionVehicle)
                SetBlipSprite(missionBlip, 477)
                SetBlipColour(missionBlip, 1)
                SetBlipRoute(missionBlip, true)

                Config.ShowNotification({
                    title = 'Furgonetka znaleziona!',
                    description = 'Zlokalizowano cel.',
                    type = 'success'
                })
            end
            Wait(1000)
        end
    end)

    local driver = CreatePed(4, guardHash, location.x, location.y, location.z, location.w, true, true)
    SetPedIntoVehicle(driver, missionVehicle, -1)
    SetupGuard(driver, settings)
    table.insert(guards, driver)

    for i = 1, settings.Guards do
        local guard = CreatePed(4, guardHash, location.x, location.y, location.z, location.w, true, true)
        SetPedIntoVehicle(guard, missionVehicle, i)
        SetupGuard(guard, settings)
        table.insert(guards, guard)
    end

    exports.ox_target:addLocalEntity(missionVehicle, {
        {
            name = 'hack_van_doors',
            label = 'Wysadź drzwi',
            icon = 'fas fa-bomb',
            bones = {'door_pside_r', 'door_dside_r'},
            distance = 2.0,
            onSelect = function()
                StartVanHacking()
            end
        }
    })

    StartVanEscapeCheck()
end

function SetupGuard(guard, settings)
    SetPedCombatAttributes(guard, 46, true)
    SetPedFleeAttributes(guard, 0, false)
    SetPedCombatAbility(guard, settings.GuardDifficulty.combat)
    GiveWeaponToPed(guard, GetHashKey(Config.GuardWeapon), 999, false, true)
    SetPedArmour(guard, settings.GuardDifficulty.armor)
    SetPedAccuracy(guard, settings.GuardDifficulty.accuracy)
    SetPedRelationshipGroupHash(guard, GetHashKey('SECURITY_GUARD'))
end

function StartVanEscapeCheck()
    local settings = currentDifficulty == 'easy' and Config.Easy or Config.Hard

    CreateThread(function()
        local escapeStarted = false
        local wasShot = false

        while activeJob and DoesEntityExist(missionVehicle) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local vanCoords = GetEntityCoords(missionVehicle)
            local distance = #(playerCoords - vanCoords)

            if distance < settings.Escape.distance and not escapeStarted then
                StartVanEscape(settings)
                escapeStarted = true
            end

            if currentDifficulty == 'easy' and HasEntityBeenDamagedByWeapon(missionVehicle, 0, 2) and not wasShot then
                HandleVanShot()
                wasShot = true
            end

            Wait(1000)
        end
    end)
end

function StartVanEscape(settings)
    local driver = guards[1]
    if DoesEntityExist(driver) and not IsPedDeadOrDying(driver) then
        SetVehicleEngineOn(missionVehicle, true, true, false)
        SetVehicleForwardSpeed(missionVehicle, 10.0)

        local forwardVector = GetEntityForwardVector(missionVehicle)
        local escapePoint = GetOffsetFromEntityInWorldCoords(missionVehicle,
            forwardVector.x * 1000.0,
            forwardVector.y * 1000.0,
            forwardVector.z)

        TaskVehicleDriveToCoordLongrange(driver, missionVehicle,
            escapePoint.x, escapePoint.y, escapePoint.z,
            settings.Escape.speed, 787004, 0.0)

        SetPedKeepTask(driver, true)

        Config.ShowNotification({
            title = 'Uwaga!',
            description = 'Furgonetka próbuje uciec!',
            type = 'error'
        })
    end
end

function HandleVanShot()
    local driver = guards[1]
    if DoesEntityExist(driver) and not IsPedDeadOrDying(driver) then
        ClearPedTasks(driver)
        SetVehicleHandbrake(missionVehicle, true)
        for _, guard in ipairs(guards) do
            if DoesEntityExist(guard) and not IsPedDeadOrDying(guard) then
                TaskLeaveVehicle(guard, missionVehicle, 256)
                Wait(1000)
                TaskCombatPed(guard, PlayerPedId(), 0, 16)
            end
        end
    end
end

function StartVanHacking()
    local hasThermite = exports.ox_inventory:Search('count', 'thermite') > 0

    if not hasThermite then
        Config.ShowNotification({
            title = 'Błąd',
            description = 'Nie posiadasz termitu!',
            type = 'error'
        })
        return
    end

    local success = lib.callback.await('snaily-tracker:useThermite', false)

    if success then
        local result = Config.ShowProgressBar({
            duration = GetModifiedTimer(Config.Timers.plantBomb, 'plantBomb'),
            label = 'Podkładanie ładunków...',
            disable = {
                car = true,
                movement = true,
                combat = true
            },
            anim = Config.Animations.planting_bomb
        })

        if result then
            HandleSuccessfulHack()
        end
    end
end

function HandleSuccessfulHack()
    local vehCoords = GetEntityCoords(missionVehicle)
    AddExplosion(vehCoords.x - 2.0, vehCoords.y, vehCoords.z, 'EXPLOSION_TANKER', 0.5, true, false, 1.0)
    Wait(500)

    SetVehicleDoorBroken(missionVehicle, 2, true)
    SetVehicleDoorBroken(missionVehicle, 3, true)

    exports.ox_target:removeLocalEntity(missionVehicle)
    exports.ox_target:removeZone('money_collection')

    local vehHeading = GetEntityHeading(missionVehicle)
    local rearDoorCoords = GetOffsetFromEntityInWorldCoords(missionVehicle, 0.0, -3.5, 0.0)

    exports.ox_target:addBoxZone({
        name = 'money_collection',
        coords = vec3(rearDoorCoords.x, rearDoorCoords.y, rearDoorCoords.z + 0.5),
        size = vec3(2.5, 0.5, 1.5),
        rotation = vehHeading,
        options = {
            {
                name = 'collect_money_back',
                label = 'Zbierz pieniądze',
                icon = 'fas fa-money-bill',
                distance = 3.5,
                onSelect = function()
                    CollectMoney()
                end
            }
        }
    })

    Config.ShowNotification({
        title = 'Sukces!',
        description = 'Drzwi zostały wysadzone. Możesz zebrać pieniądze.',
        type = 'success'
    })
end

function CollectMoney()
    if Config.ShowProgressBar({
        duration = GetModifiedTimer(Config.Timers.collectMoney, 'collectMoney'),
        label = 'Zbieranie pieniędzy...',
        disable = {
            car = true,
            movement = true,
            combat = true
        },
        anim = Config.Animations.collecting_money
    }) then
        if lib.callback.await('snaily-tracker:finishJob', false, true, currentDifficulty) then
            ResyncPlayerData()
            CleanupMission()
        end
    end
end

function CleanupMission()
    if missionBlip then RemoveBlip(missionBlip) end
    if missionVehicle then
        exports.ox_target:removeLocalEntity(missionVehicle)
        exports.ox_target:removeZone('money_collection')
        DeleteEntity(missionVehicle)
    end
    for _, guard in pairs(guards) do
        if DoesEntityExist(guard) then
            DeleteEntity(guard)
        end
    end
    guards = {}
    activeJob = false
end

lib.callback.register('snaily-tracker:syncPlayerData', function(data)
    playerData = data
end)

lib.callback.register('snaily-tracker:startMission', function(difficulty)
    currentDifficulty = difficulty
    StartTrackerMission()
    return true
end)

lib.callback.register('snaily-tracker:updateQueue', function(queueData)
    currentQueueInfo = queueData
    Config.ShowNotification({
        title = 'Informacja o kolejce',
        description = 'Jesteś ' .. queueData.position .. ' w kolejce',
        type = 'info'
    })
end)

CreateThread(function()
    CreateJobNPC()
    ResyncPlayerData()
end)
