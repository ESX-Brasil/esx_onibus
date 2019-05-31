Peds = {}
Peds.modelsHashUsedByPedCount = {}

function Peds.CreateRandomPedInArea(coords)
    local modelName = Peds.LoadModel(Peds.RandomlySelectModel())

    local x = coords.x + math.random() * 4 - 2
    local y = coords.y + math.random() * 4 - 2
    local heading = math.random() * 360

    local ped = CreatePed(4, modelName, x, y, coords.z, heading, true, false)
    Peds.WanderInArea(ped, coords)
    Peds.incrementModelsHashUsedByPedCount(modelName)
    return ped
end

function Peds.LeaveVehicle(ped, vehicle)
    if IsPedDeadOrDying(ped) then
        RemovePedElegantly(ped)
    else
        ClearPedTasksImmediately(ped, true)
        TaskLeaveVehicle(ped, vehicle, 64)
    end
end

function Peds.WanderInArea(ped, stopCoords)
    TaskWanderInArea(ped,
        stopCoords.x,
        stopCoords.y,
        stopCoords.z,
        Config.Markers.Size / 2.0, -- raios
        Config.Markers.Size / 2.0, -- Comprimento mínimo
        5000                       -- tempo entre caminhadas
    )
end

function Peds.EnterVehicle(ped, vehicle, seatNumber)
    Citizen.Wait(10)
    TaskEnterVehicle(ped,
        vehicle,
        Config.EnterVehicleTimeout, -- tempo esgotado
        seatNumber,                 -- assento
        1.0,                        -- velocidade (caminhada)
        1,                          -- bandeira, normal
        0                           -- p6? lol
    )
end

function Peds.IsPedInVehicleOrDead(ped, position)
    return GetVehiclePedIsIn(ped, false) or IsPedDeadOrDying(ped, 1)
end

function Peds.IsPedInVehicleDeadOrTooFarAway(ped, position)
    if IsPedInAnyVehicle(ped, false) or IsPedDeadOrDying(ped, 1) then
        return true
    end

    return GetDistanceBetweenCoords(GetEntityCoords(ped), position.x, position.y, position.z) > 15
end

function Peds.LoadModel(modelName)
    local loadAttempts = 0
    local hashKey = GetHashKey(modelName)

    RequestModel(hashKey)
    while not HasModelLoaded(hashKey) and loadAttempts < 10 do
        loadAttempts = loadAttempts + 1
        Citizen.Wait(50)
    end

    if loadAttempts == 10 then
        Log.debug('MODELO NÃO CARREGADO DEPOIS DE DEZ TENTATIVAS: ' .. modelName)
        return Peds.LoadModel(Peds.RandomlySelectModel())
    end

    Log.debug('Modelo carregado com sucesso: ' .. modelName)
    return modelName
end

function Peds.DeletePeds(pedList)
    while #pedList > 0 do
        Peds.DeletePed(table.remove(pedList))
        Citizen.Wait(10)
    end
end

function Peds.DeletePed(ped)
    Peds.HandleUnloadingModelIfNeeded(ped)
    SetEntityAsNoLongerNeeded(ped)
    DeletePed(ped)
end

function Peds.RandomlySelectModel()
    return Config.PedModels[math.random(#Config.PedModels)]
end

function Peds.WalkPedsToLocation(peds, coords)
    for i = 1, #peds do
        TaskGoToCoordAnyMeans(peds[i], coords.x, coords.y, coords.z, 1.0, 0, 0, 786603, 0.0);
    end
end

function Peds.incrementModelsHashUsedByPedCount(modelName)
    local hashKey = GetHashKey(modelName)

    local value = Peds.modelsHashUsedByPedCount[hashKey]
    if value == nil then value = 0 end

    Peds.modelsHashUsedByPedCount[hashKey] = value + 1
end

function Peds.decrementModelsHashUsedByPedCount(hashKey)
    local value = Peds.modelsHashUsedByPedCount[hashKey]
    if value == nil then value = 1 end

    Peds.modelsHashUsedByPedCount[hashKey] = value - 1
end

function Peds.HandleUnloadingModelIfNeeded(pedToDelete)
    local hashKey = GetEntityModel(pedToDelete)
    Peds.decrementModelsHashUsedByPedCount(hashKey)
    if Peds.modelsHashUsedByPedCount[hashKey] <= 0 then
        SetModelAsNoLongerNeeded(hashKey)
    end
end
