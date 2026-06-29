-- Loader/Script/TowerDefensiSimulator/main.lua

-- Mengecek Tier (di-set oleh Loader sebelumnya)
local Tier = getgenv().Tier or "Free"

-- Load UI Library (Menggunakan Rayfield)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "TDS Script - " .. Tier .. " Edition",
    LoadingTitle = "Memuat Fitur...",
    LoadingSubtitle = "Tower Defense Simulator",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

-- Fungsi utilitas untuk mengecek apakah fitur diizinkan
local function CheckPremiumAccess()
    if Tier ~= "Premium" then
        Rayfield:Notify({
            Title = "Akses Ditolak",
            Content = "Fitur ini hanya untuk pengguna Premium! (Fitur Kuning)",
            Duration = 3
        })
        return false
    end
    return true
end

-- ==========================================
-- TAB UTAMA (MAIN)
-- ==========================================
local MainTab = Window:CreateTab("Utama", 4483362458)

MainTab:CreateSection("🔵 Fitur Umum (Free & Premium)")

MainTab:CreateButton({
    Name = "🔵 Auto Farm (Biasa)",
    Callback = function()
        -- Logika Auto Farm Biasa
        print("Auto Farm (Biasa) diaktifkan!")
        Rayfield:Notify({
            Title = "Auto Farm",
            Content = "Auto Farm biasa mulai berjalan...",
            Duration = 3
        })
    end,
})

MainTab:CreateToggle({
    Name = "🔵 Auto Upgrade Troop",
    CurrentValue = false,
    Flag = "AutoUpgrade",
    Callback = function(Value)
        print("Auto Upgrade: ", Value)
    end,
})


MainTab:CreateSection("🟡 Fitur Eksklusif (Premium Only)")

MainTab:CreateButton({
    Name = "🟡 Auto Farm (VIP/Fast Mode)",
    Callback = function()
        if not CheckPremiumAccess() then return end
        
        -- Logika Auto Farm VIP
        print("Auto Farm VIP diaktifkan!")
        Rayfield:Notify({
            Title = "Auto Farm VIP",
            Content = "Auto Farm kecepatan tinggi berjalan...",
            Duration = 3
        })
    end,
})

MainTab:CreateToggle({
    Name = "🟡 God Mode Base",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(Value)
        if Value and not CheckPremiumAccess() then
            -- Jika Free mencoba menghidupkan, kita bisa matikan lagi toogle-nya (meskipun di Rayfield sedikit tricky, minimal logic tidak jalan)
            return
        end
        
        if Value then
            print("God Mode diaktifkan!")
        else
            print("God Mode dimatikan!")
        end
    end,
})

MainTab:CreateButton({
    Name = "🟡 Unlock All Premium Emotes",
    Callback = function()
        if not CheckPremiumAccess() then return end
        print("Premium emotes unlocked!")
    end,
})
