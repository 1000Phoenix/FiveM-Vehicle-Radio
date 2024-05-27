local radioStations = {
    { name = "Los Santos Rock Radio", station = "RADIO_01_CLASS_ROCK" },
    { name = "Non-Stop-Pop FM", station = "RADIO_02_POP" },
    { name = "Radio Los Santos", station = "RADIO_03_HIPHOP_NEW" },
    { name = "Channel X", station = "RADIO_04_PUNK" },
    { name = "West Coast Talk Radio", station = "RADIO_05_TALK_01" },
    { name = "Rebel Radio", station = "RADIO_06_COUNTRY" },
    { name = "Soulwax FM", station = "RADIO_07_DANCE_01" },
    { name = "East Los FM", station = "RADIO_08_MEXICAN" },
    { name = "West Coast Classics", station = "RADIO_09_HIPHOP_OLD" },
    { name = "Blue Ark", station = "RADIO_12_REGGAE" },
    { name = "WorldWide FM", station = "RADIO_13_JAZZ" },
    { name = "FlyLo FM", station = "RADIO_14_DANCE_02" },
    { name = "The Lowdown 91.1", station = "RADIO_15_MOTOWN" },
    { name = "The Lab", station = "RADIO_20_THELAB" },
    { name = "Radio Mirror Park", station = "RADIO_16_SILVERLAKE" },
    { name = "Space 103.2", station = "RADIO_17_FUNK" },
    { name = "Vinewood Boulevard Radio", station = "RADIO_18_90S_ROCK" },
    { name = "Blonded Los Santos 97.8 FM", station = "RADIO_21_DLC_XM17" },
    { name = "Blaine County Radio", station = "RADIO_11_TALK_02" },
    { name = "Los Santos Underground Radio", station = "RADIO_22_DLC_BATTLE_MIX1_RADIO" },
    { name = "iFruit Radio", station = "RADIO_23_DLC_XM19_RADIO" },
    { name = "Radio Off", station = "OFF" }
}

local isRadioUIOpen = false
local isYouTubePlaying = false
local isYouTubePaused = false

function toggleRadioUI()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if not isRadioUIOpen and (not vehicle or not GetIsVehicleEngineRunning(vehicle)) then
        return
    end

    if isRadioUIOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "closeRadioUI" })
    else
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        SendNUIMessage({
            action = "openRadioUI",
            stations = radioStations,
            isYouTubePlaying = isYouTubePlaying,
            isYouTubePaused = isYouTubePaused
        })
    end
    isRadioUIOpen = not isRadioUIOpen
end

function stopYouTubePlayback()
    if isYouTubePlaying or isYouTubePaused then
        exports.xsound:Destroy('radio')
        isYouTubePlaying = false
        isYouTubePaused = false
        SendNUIMessage({ action = "updatePlaybackState", isYouTubePlaying = false, isYouTubePaused = false })
    end
end

RegisterNUICallback('selectRadioStation', function(data, cb)
    local station = data.station
    if isYouTubePlaying or isYouTubePaused then
        stopYouTubePlayback()
    end
    if station == "OFF" then
        SetVehRadioStation(GetVehiclePedIsIn(PlayerPedId(), false), "OFF")
    else
        SetVehRadioStation(GetVehiclePedIsIn(PlayerPedId(), false), station)
    end
    toggleRadioUI()
    cb('ok')
end)

-- Retrieve all vehicle passengers
local function getVehiclePassengers(vehicle)
    local passengers = {}
    for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        local ped = GetPedInVehicleSeat(vehicle, i)
        if ped and ped ~= 0 then
            table.insert(passengers, GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped)))
        end
    end
    return passengers
end

-- Handles URL input (YouTube)
RegisterNUICallback('playYouTube', function(data, cb)
    local youtubeUrl = data.url
    local volume = 0.5
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local passengers = getVehiclePassengers(vehicle)
    
    SetVehRadioStation(vehicle, "OFF")
    exports.xsound:PlayUrl('radio', youtubeUrl, volume, false)
    exports.xsound:Distance('radio', 10)
    isYouTubePlaying = true
    isYouTubePaused = false
    SendNUIMessage({ action = "updatePlaybackState", isYouTubePlaying = true, isYouTubePaused = false })
    toggleRadioUI()
    cb('ok')
    TriggerServerEvent('syncYouTubePlayback', youtubeUrl, volume, passengers)
end)

-- YouTube playback handler
RegisterNUICallback('pauseYouTube', function(data, cb)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local passengers = getVehiclePassengers(vehicle)
    
    if isYouTubePlaying then
        exports.xsound:Pause('radio')
        isYouTubePlaying = false
        isYouTubePaused = true
    elseif isYouTubePaused then
        exports.xsound:Resume('radio')
        isYouTubePlaying = true
        isYouTubePaused = false
    end
    SendNUIMessage({ action = "updatePlaybackState", isYouTubePlaying = isYouTubePlaying, isYouTubePaused = isYouTubePaused })
    cb('ok')
    TriggerServerEvent('syncYouTubePlaybackState', isYouTubePlaying, isYouTubePaused, passengers)
end)

-- Play YouTube for all passengers
RegisterNetEvent('playYouTubeForAll')
AddEventHandler('playYouTubeForAll', function(youtubeUrl, volume)
    exports.xsound:PlayUrl('radio', youtubeUrl, volume, false)
    exports.xsound:Distance('radio', 10)
    isYouTubePlaying = true
    isYouTubePaused = false
    SendNUIMessage({ action = "updatePlaybackState", isYouTubePlaying = true, isYouTubePaused = false })
end)

-- Update YouTube for all passengers
RegisterNetEvent('updateYouTubePlaybackStateForAll')
AddEventHandler('updateYouTubePlaybackStateForAll', function(isPlaying, isPaused)
    if isPlaying then
        exports.xsound:Resume('radio')
    else
        exports.xsound:Pause('radio')
    end
    isYouTubePlaying = isPlaying
    isYouTubePaused = isPaused
    SendNUIMessage({ action = "updatePlaybackState", isYouTubePlaying = isYouTubePlaying, isYouTubePaused = isYouTubePaused })
end)

-- Volume control
RegisterNUICallback('setVolume', function(data, cb)
    local volume = data.volume
    exports.xsound:setVolume('radio', volume)
    cb('ok')
end)

-- Close UI
RegisterNUICallback('closeRadioUI', function(data, cb)
    toggleRadioUI()
    cb('ok')
end)

-- Close UI with keyboard keypress (commented out due to inability to rebind per client)
--[[ RegisterNUICallback('keyPress', function(data, cb)
    if data.control == "Q" then
        toggleRadioUI()
    end
    cb('ok')
end) ]]

-- Override radial wheel
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            DisableControlAction(0, 85, true) -- Disable radio wheel (Q)
            if IsDisabledControlJustReleased(0, 85) then
                toggleRadioUI()
            end
        end
    end
end)

-- Stop YouTube playing when engine off or exit vehicle
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if GetIsVehicleEngineRunning(vehicle) == false then
                stopYouTubePlayback()
            end
        else
            stopYouTubePlayback()
        end
    end
end)

-- Disable mouse when in Radio UI
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isRadioUIOpen then
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
        end
    end
end)