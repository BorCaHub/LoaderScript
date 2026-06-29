-- Loader/main.lua

-- Konfigurasi Supabase (Harap isi dengan detail Anda nanti)
local SUPABASE_URL = "https://YOUR_PROJECT_REF.supabase.co/rest/v1/keys"
local SUPABASE_ANON_KEY = "YOUR_ANON_KEY"

-- Load UI Library (Menggunakan Rayfield sebagai contoh)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Script Hub Loader",
    LoadingTitle = "Memuat Hub...",
    LoadingSubtitle = "by SPIDER X",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

-- Default Tier adalah Free
getgenv().Tier = "Free"

-- Fungsi untuk memuat script utama
local function LoadMainScript()
    Rayfield:Notify({
        Title = "Berhasil!",
        Content = "Memuat Script Tower Defense Simulator sebagai " .. getgenv().Tier,
        Duration = 3,
        Image = 4483362458
    })
    
    wait(1)
    Rayfield:Destroy()
    
    -- Memuat script TDS
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BorCaHub/BorcaScriptHub/main/Loader/Script/TowerDefensiSimulator/main.lua"))()
    
    -- Untuk simulasi lokal/testing, kita asumsikan file sudah diload setelah ini.
end

-- TAB FREE
local FreeTab = Window:CreateTab("Tiers Free", 4483362458)
FreeTab:CreateButton({
    Name = "Masuk sebagai FREE",
    Callback = function()
        getgenv().Tier = "Free"
        LoadMainScript()
    end,
})

-- TAB PREMIUM
local PremiumTab = Window:CreateTab("Tiers Premium", 4483362458)
local KeyInput = ""

PremiumTab:CreateInput({
    Name = "Masukkan Key Premium",
    PlaceholderText = "Key Anda...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        KeyInput = Text
    end,
})

PremiumTab:CreateButton({
    Name = "Login & Masuk",
    Callback = function()
        if KeyInput == "" then
            Rayfield:Notify({
                Title = "Error",
                Content = "Harap masukkan key terlebih dahulu!",
                Duration = 3
            })
            return
        end

        -- Validasi ke Supabase menggunakan REST API
        local requestFunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or request or function() return nil end
        
        local success, response = pcall(function()
            -- Memeriksa apakah key ada di tabel database 'keys' kolom 'key'
            return requestFunc({
                Url = SUPABASE_URL .. "?select=*&key=eq." .. KeyInput,
                Method = "GET",
                Headers = {
                    ["apikey"] = SUPABASE_ANON_KEY,
                    ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
                    ["Content-Type"] = "application/json"
                }
            })
        end)

        if success and response and response.StatusCode == 200 then
            local data = game:GetService("HttpService"):JSONDecode(response.Body)
            if #data > 0 then
                -- Key ditemukan
                getgenv().Tier = "Premium"
                Rayfield:Notify({
                    Title = "Login Sukses!",
                    Content = "Selamat datang, pengguna Premium!",
                    Duration = 3
                })
                LoadMainScript()
            else
                -- Key tidak ditemukan
                Rayfield:Notify({
                    Title = "Login Gagal",
                    Content = "Key salah atau tidak terdaftar!",
                    Duration = 3
                })
            end
        else
            Rayfield:Notify({
                Title = "Error Jaringan",
                Content = "Gagal menghubungi server Supabase.",
                Duration = 3
            })
        end
    end,
})
