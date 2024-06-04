local function fetchYouTubeTitle(url, callback)
    PerformHttpRequest("https://noembed.com/embed?url=" .. url, function(statusCode, response, headers)
        if statusCode == 200 then
            local data = json.decode(response)
            if data and data.title then
                callback(data.title)
            else
                callback("YouTube Video")
            end
        else
            callback("YouTube Video")
        end
    end, "GET", "", { ["Content-Type"] = "application/json" })
end

RegisterNetEvent('syncYouTubePlayback')
AddEventHandler('syncYouTubePlayback', function(youtubeUrl, volume, passengers)
    fetchYouTubeTitle(youtubeUrl, function(title)
        for _, playerId in ipairs(passengers) do
            TriggerClientEvent('playYouTubeForAll', playerId, youtubeUrl, volume, title)
        end
    end)
end)

RegisterNetEvent('syncYouTubePlaybackState')
AddEventHandler('syncYouTubePlaybackState', function(isPlaying, isPaused, passengers)
    for _, playerId in ipairs(passengers) do
        TriggerClientEvent('updateYouTubePlaybackStateForAll', playerId, isPlaying, isPaused)
    end
end)