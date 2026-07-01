--[[
    Ocean Hub // Mac Device Configuration
    Device: Mac (Similar to PC but with retina scaling)
]]
return {
    -- Frame Settings
    frameSize = UDim2.new(0, 440, 0, 330),
    cornerRadius = 14,
    borderThickness = 1,
    
    -- Text Settings
    titleTextSize = 27,
    subtitleTextSize = 13,
    versionTextSize = 11,
    tierBtnTextSize = 23,
    tierDescTextSize = 12,
    keyBoxTextSize = 19,
    keySubmitTextSize = 17,
    scriptTitleSize = 21,
    scriptDescSize = 14,
    comingSoonSize = 19,
    
    -- Button Settings
    closeBtnSize = UDim2.new(0, 29, 0, 29),
    minBtnSize = UDim2.new(0, 29, 0, 29),
    keyBoxHeight = 47,
    keyButtonHeight = 41,
    scriptButtonHeight = 54,
    
    -- Position Settings
    titleTextPosition = UDim2.new(0, 19, 0, 2),
    subtitlePosition = UDim2.new(0, 19, 0, 46),
    closeBtnPosition = UDim2.new(1, -37, 0, 5),
    minBtnPosition = UDim2.new(1, -37, 0, 37),
    versionPosition = UDim2.new(1, -69, 0, 9),
    pagesPosition = UDim2.new(0, 18, 0, 60),
    
    -- UI Scale Multiplier
    uiScale = 0.95,
    
    -- Device Type
    deviceType = "Mac"
}