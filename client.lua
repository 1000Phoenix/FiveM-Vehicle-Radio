local radioStationNames = {
    RADIO_01_CLASS_ROCK = "Los Santos Rock Radio",
    RADIO_02_POP = "Non-Stop-Pop FM",
    RADIO_03_HIPHOP_NEW = "Radio Los Santos",
    RADIO_04_PUNK = "Channel X",
    RADIO_05_TALK_01 = "West Coast Talk Radio",
    RADIO_06_COUNTRY = "Rebel Radio",
    RADIO_07_DANCE_01 = "Soulwax FM",
    RADIO_08_MEXICAN = "East Los FM",
    RADIO_09_HIPHOP_OLD = "West Coast Classics",
    RADIO_12_REGGAE = "Blue Ark",
    RADIO_13_JAZZ = "WorldWide FM",
    RADIO_14_DANCE_02 = "FlyLo FM",
    RADIO_15_MOTOWN = "The Lowdown 91.1",
    RADIO_20_THELAB = "The Lab",
    RADIO_16_SILVERLAKE = "Radio Mirror Park",
    RADIO_17_FUNK = "Space 103.2",
    RADIO_18_90S_ROCK = "Vinewood Boulevard Radio",
    RADIO_21_DLC_XM17 = "Blonded Los Santos 97.8 FM",
    RADIO_11_TALK_02 = "Blaine County Radio",
    RADIO_22_DLC_BATTLE_MIX1_RADIO = "Los Santos Underground Radio",
    RADIO_23_DLC_XM19_RADIO = "iFruit Radio",
    RADIO_CUSTOM = "Radio Custom"
}

local isYouTubePlaying = false
local isYouTubePaused = false
local currentSong = "No song playing"
local source = "No source"

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
            isYouTubePaused = isYouTubePaused,
            currentSong = currentSong,
            source = source
        })
    end
    isRadioUIOpen = not isRadioUIOpen
end

function stopYouTubePlayback()
    if isYouTubePlaying or isYouTubePaused then
        exports.xsound:Destroy('radio')
        isYouTubePlaying = false
        isYouTubePaused = false
        currentSong = "No song playing"
        source = "No source"
        SendNUIMessage({ action = "updatePlaybackState", isYouTubePlaying = false, isYouTubePaused = false, currentSong = currentSong, source = source })
    end
end

function updateCurrentSong(song, source)
    SendNUIMessage({
        action = "updateCurrentSong",
        song = song,
        source = source
    })
end

RegisterNUICallback('selectRadioStation', function(data, cb)
    local station = data.station
    if isYouTubePlaying or isYouTubePaused then
        stopYouTubePlayback()
    end
    if station == "OFF" then
        SetVehRadioStation(GetVehiclePedIsIn(PlayerPedId(), false), "OFF")
        currentSong = "No song playing"
        source = "No source"
    else
        SetVehRadioStation(GetVehiclePedIsIn(PlayerPedId(), false), station)
        currentSong = radioStationNames[station] or station
        source = "Radio"
    end
    updateCurrentSong(currentSong, source)
    SendNUIMessage({ action = "updatePlaybackState", isYouTubePlaying = isYouTubePlaying, isYouTubePaused = isYouTubePaused, currentSong = currentSong, source = source })
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
    currentSong = "Loading..."
    source = "YouTube"
    updateCurrentSong(currentSong, source)
    SendNUIMessage({ action = "updatePlaybackState", isYouTubePlaying = true, isYouTubePaused = false, currentSong = currentSong, source = source })
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
        SetVehRadioStation(vehicle, "OFF")
    elseif isYouTubePaused then
        exports.xsound:Resume('radio')
        isYouTubePlaying = true
        isYouTubePaused = false
        SetVehRadioStation(vehicle, "OFF")
    else
        SetVehRadioStation(vehicle, "OFF")
        currentSong = "No song playing"
        source = "No source"
        SendNUIMessage({ action = "updatePlaybackState", isYouTubePlaying = false, isYouTubePaused = false, currentSong = currentSong, source = source })
    end
    updateCurrentSong(currentSong, source)
    SendNUIMessage({ action = "updatePlaybackState", isYouTubePlaying = isYouTubePlaying, isYouTubePaused = isYouTubePaused, currentSong = currentSong, source = source })
    cb('ok')
    TriggerServerEvent('syncYouTubePlaybackState', isYouTubePlaying, isYouTubePaused, passengers)
end)

-- Play YouTube for all passengers
RegisterNetEvent('playYouTubeForAll')
AddEventHandler('playYouTubeForAll', function(youtubeUrl, volume, title)
    exports.xsound:PlayUrl('radio', youtubeUrl, volume, false)
    exports.xsound:Distance('radio', 10)
    isYouTubePlaying = true
    isYouTubePaused = false
    currentSong = title
    source = "YouTube"
    updateCurrentSong(currentSong, source)
    SendNUIMessage({ action = "updatePlaybackState", isYouTubePlaying = true, isYouTubePaused = false, currentSong = currentSong, source = source })
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
    updateCurrentSong(currentSong, source)
    SendNUIMessage({ action = "updatePlaybackState", isYouTubePlaying = isYouTubePlaying, isYouTubePaused = isYouTubePaused, currentSong = currentSong, source = source })
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

-- Radio UI keybind
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 85) then -- Q key by default
            toggleRadioUI()
        end
    end
end)