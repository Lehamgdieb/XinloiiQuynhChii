repeat wait() until game:IsLoaded() and game.Players.LocalPlayer 
task.spawn(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Lehamgdieb/Configvippro/refs/heads/main/track.lua"))()
end)
getgenv().team = "Pirates" -- Pirates or Marines
loadstring(game:HttpGet("https://raw.githubusercontent.com/vinh129150/hack/refs/heads/main/Bloxfruits.lua"))()
