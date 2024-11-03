local activeJobs = {}
local jobQueue = {}
local playerData = {}

local function LoadPlayerData()
    local file = LoadResourceFile(GetCurrentResourceName(), "trackerData.json")
    if file then
        playerData = json.decode(file) or {}
    end
end

local function SavePlayerData()
    SaveResourceFile(GetCurrentResourceName(), "trackerData.json", json.encode(playerData), -1)
end

local function InitializePlayerData(source)
    local identifier = GetPlayerIdentifier(source, 0)
    if not playerData[identifier] then
        playerData[identifier] = {
            level = 1,
            exp = 0,
            completedJobs = 0,
            lastJobTime = 0,
            skills = {
                fastFingers = 0,
                informator = 0
            }
        }
    end
    return playerData[identifier]
end

local function StartMissionTimer(source, identifier)
    SetTimeout(Config.MissionTimeLimit * 1000, function()
        for i, job in ipairs(activeJobs) do
            if job.source == source then
                if GetPlayerPing(source) > 0 then
                    if playerData[identifier] then
                        playerData[identifier].exp = math.max(0, playerData[identifier].exp - Config.FailureExpPenalty)
                        SavePlayerData()

                        TriggerClientEvent('ox_lib:notify', source, {
                            title = 'Misja nie udana',
                            description = 'Przekroczono limit czasu! Tracisz ' .. Config.FailureExpPenalty .. ' EXP',
                            type = 'error'
                        })

                        TriggerClientEvent('snaily-tracker:forceMissionEnd', source)
                    end
                end
                table.remove(activeJobs, i)
                AdvanceQueue()
                break
            end
        end
    end)
end

local function AdvanceQueue()
    if #jobQueue > 0 then
        local nextPlayer = table.remove(jobQueue, 1)
        activeJobs = {}

        if type(nextPlayer.source) == 'number' then
            table.insert(activeJobs, nextPlayer)

            StartMissionTimer(nextPlayer.source, GetPlayerIdentifier(nextPlayer.source, 0))

            local success = lib.callback.await('snaily-tracker:startMission', nextPlayer.source, false, nextPlayer.difficulty)
            if success then
                TriggerClientEvent('ox_lib:notify', nextPlayer.source, {
                    title = 'Misja rozpoczęta!',
                    description = 'Zlecenie zostało aktywowane',
                    type = 'success'
                })
            end

            for i, queuedJob in ipairs(jobQueue) do
                if type(queuedJob.source) == 'number' then
                    TriggerClientEvent('snaily-tracker:updateQueue', queuedJob.source, {
                        position = i,
                        total = #jobQueue
                    })
                end
            end
        end
    end
end

lib.callback.register('snaily-tracker:getPlayerData', function(source)
    return InitializePlayerData(source)
end)

lib.callback.register('snaily-tracker:checkJobAvailability', function(source, difficulty)
    local identifier = GetPlayerIdentifier(source, 0)
    local data = playerData[identifier]
    local settings = difficulty == 'easy' and Config.Easy or Config.Hard

    if data.lastJobTime and (os.time() - data.lastJobTime) < settings.Cooldown then
        local remainingTime = settings.Cooldown - (os.time() - data.lastJobTime)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Cooldown',
            description = 'Musisz poczekać jeszcze ' .. remainingTime .. ' sekund',
            type = 'error'
        })
        return false
    end

    for _, job in ipairs(activeJobs) do
        if job.source == source then return false end
    end

    for _, job in ipairs(jobQueue) do
        if job.source == source then return false end
    end

    if #activeJobs > 0 then
        table.insert(jobQueue, {source = source, difficulty = difficulty})
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Kolejka',
            description = 'Jesteś ' .. #jobQueue .. ' w kolejce',
            type = 'info'
        })
        return false
    end

    table.insert(activeJobs, {source = source, difficulty = difficulty})
    StartMissionTimer(source, identifier)
    return true
end)

lib.callback.register('snaily-tracker:finishJob', function(source, success, difficulty)
    local identifier = GetPlayerIdentifier(source, 0)

    for i, job in ipairs(activeJobs) do
        if job.source == source then
            table.remove(activeJobs, i)
            break
        end
    end

    if success then
        local settings = difficulty == 'easy' and Config.Easy or Config.Hard
        local data = playerData[identifier]

        local baseReward = math.random(settings.Rewards.money.min, settings.Rewards.money.max)
        local levelBonus = Config.LevelBonuses[data.level].money
        local totalReward = baseReward + levelBonus

        exports.ox_inventory:AddItem(source, 'money', totalReward)

        data.completedJobs = data.completedJobs + 1
        data.exp = data.exp + settings.Rewards.exp
        data.lastJobTime = os.time()

        SavePlayerData()

        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Nagroda',
            description = string.format('Otrzymałeś $%d (+$%d bonus)', baseReward, levelBonus),
            type = 'success'
        })
    end

    AdvanceQueue()
    return success
end)

lib.callback.register('snaily-tracker:getQueueInfo', function(source)
    return {
        total = #jobQueue,
        activeJobs = #activeJobs
    }
end)

lib.callback.register('snaily-tracker:tryLevelUp', function(source)
    local identifier = GetPlayerIdentifier(source, 0)
    local data = playerData[identifier]
    if not data then return false end

    local nextLevel = Config.Levels[data.level + 1]
    if not nextLevel then return false end

    if data.exp >= nextLevel.exp then
        data.level = data.level + 1
        SavePlayerData()
        return true
    end
    return false
end)

lib.callback.register('snaily-tracker:buySkill', function(source, skillName)
    local identifier = GetPlayerIdentifier(source, 0)
    local data = playerData[identifier]
    if not data then return false end

    local currentLevel = data.skills[skillName] or 0
    local nextLevel = Config.Skills[skillName].levels[currentLevel + 1]
    if not nextLevel then return false end

    local money = exports.ox_inventory:GetItem(source, 'money', nil, true)
    if money < nextLevel.price then return false end

    exports.ox_inventory:RemoveItem(source, 'money', nextLevel.price)
    data.skills[skillName] = currentLevel + 1
    SavePlayerData()
    return true
end)

lib.callback.register('snaily-tracker:useThermite', function(source)
    return exports.ox_inventory:RemoveItem(source, 'thermite', 1)
end)

-- RegisterCommand('addtestqueue', function(source, args)
--     local testPlayer = {
--         source = 'SNAILY_DEVELOPMENT_' .. (#jobQueue + 1),
--         difficulty = 'easy'
--     }

--     if #activeJobs == 0 then
--         table.insert(activeJobs, testPlayer)

--         SetTimeout(30000, function()
--             for i, job in ipairs(activeJobs) do
--                 if type(job.source) == 'string' and job.source == testPlayer.source then
--                     print('Test player finished mission')
--                     table.remove(activeJobs, i)

--                     SetTimeout(1000, function()
--                         AdvanceQueue()
--                     end)
--                     break
--                 end
--             end
--         end)
--     else
--         table.insert(jobQueue, testPlayer)
--     end
-- end, true)

-- RegisterCommand('removetestplayer', function(source, args)
--     for i = #jobQueue, 1, -1 do
--         if type(jobQueue[i].source) == 'string' and jobQueue[i].source:match('^SNAILY_DEVELOPMENT_') then
--             table.remove(jobQueue, i)
--             break
--         end
--     end

--     for i, queuedJob in ipairs(jobQueue) do
--         if type(queuedJob.source) == 'number' then
--             TriggerClientEvent('snaily-tracker:updateQueue', queuedJob.source, {
--                 position = i,
--                 total = #jobQueue
--             })
--         end
--     end
-- end, true)

AddEventHandler('playerDropped', function()
    SavePlayerData()
end)

CreateThread(function()
    LoadPlayerData()
    while true do
        Wait(300000)
        SavePlayerData()
    end
end)
