RegisterNetEvent('syncYouTubePlayback')
AddEventHandler('syncYouTubePlayback', function(youtubeUrl, volume, passengers)
    for _, playerId in ipairs(passengers) do
        TriggerClientEvent('playYouTubeForAll', playerId, youtubeUrl, volume)
    end
end)

RegisterNetEvent('syncYouTubePlaybackState')
AddEventHandler('syncYouTubePlaybackState', function(isPlaying, isPaused, passengers)
    for _, playerId in ipairs(passengers) do
        TriggerClientEvent('updateYouTubePlaybackStateForAll', playerId, isPlaying, isPaused)
    end
end)