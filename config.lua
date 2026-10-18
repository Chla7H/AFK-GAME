Config = {}

Config.Command      = 'afk'        -- /afk : enter / leave AFK
Config.EmoteCommand = 'afkemote'   -- /afkemote 1-10

-- AFK spots (a random free one is picked)
Config.AfkSlots = {
    vector3(1204.73, -3246.47, -49.00),
    vector3(1199.12, -3255.97, -49.00),
    vector3(1193.95, -3248.76, -49.00),
    vector3(1194.59, -3252.15, -49.00),
    vector3(1192.40, -3256.58, -49.00),
    vector3(1180.51, -3252.92, -49.00),
    vector3(1180.91, -3249.15, -49.00),
    vector3(1181.06, -3257.34, -49.00),
}

-- Where the player returns when leaving /afk
Config.ReturnCoords = vector3(2772.41, 7533.55, 305.48)

Config.Ghost = {
    alpha = 110,          -- 0-255 (transparent)
    invincible = true,    -- cannot be damaged
    noCollision = true,   -- no collision with other players
    freeze = true,
    snapToGround = true,  -- put the player exactly on the floor when entering AFK
    groundOffset = 1.0,   -- ped origin height above the floor. Floating? lower it (0.9, 0.8...). Sinking? raise it (1.1...)
}

-- Sitting emote (default on entering) + 10 dances
Config.SitAnim = { dict = 'amb@world_human_picnic@male@base', anim = 'base' }

Config.Dances = {
    { label = 'Dance 1',  dict = 'anim@amb@nightclub@dancers@podium_dancers@',                  anim = 'hi_dance_facedj_17_v2_male^5' },
    { label = 'Dance 2',  dict = 'anim@amb@casino@mini@dance@dance_solo@female@var_a@',         anim = 'high_center' },
    { label = 'Dance 3',  dict = 'anim@amb@nightclub@mini@dance@dance_solo@male@var_a@',        anim = 'high_center' },
    { label = 'Dance 4',  dict = 'anim@amb@nightclub@mini@dance@dance_solo@male@var_b@',        anim = 'high_center' },
    { label = 'Dance 5',  dict = 'anim@amb@nightclub@lazlow@hi_podium@',                        anim = 'danceidle_hi_11_buttwiggle_b_laz' },
    { label = 'Dance 6',  dict = 'anim@mp_player_intcelebrationmale@uncle_disco',               anim = 'uncle_disco' },
    { label = 'Dance 7',  dict = 'anim@mp_player_intcelebrationfemale@uncle_disco',             anim = 'uncle_disco' },
    { label = 'Dance 8',  dict = 'anim@amb@nightclub@mini@dance@dance_solo@female@var_b@',      anim = 'high_center' },
    { label = 'Dance 9',  dict = 'anim@mp_player_intcelebrationmale@air_synth',                 anim = 'air_synth' },
    { label = 'Dance 10', dict = 'anim@mp_player_intcelebrationmale@jazz_hands',                anim = 'jazz_hands' },
}

-- Moving cinematic camera while in AFK mode (orbits around the player)
Config.Camera = {
    enabled   = true,
    distance  = 3.2,     -- distance from the player (meters)
    height    = 0.5,     -- camera height above the player's feet
    speed     = 10.0,    -- orbit speed in degrees/second (negative = other direction)
    fov       = 50.0,
    bobHeight = 0.35,    -- slow up/down movement (0 = none)
    bobSpeed  = 0.6,
    lookAtZ   = 0.35,    -- point of the body the camera looks at
    blendIn   = 1500,    -- ms smooth transition when entering
}

Config.ShowMessage = false   -- true = show the AFK MODE message, false = hide it

Config.Music = {
    enabled = true,
    file = 'sound/mp.mp3',
    volume = 0.6,   -- 0.0 to 1.0 (in game: /afkvolume 0-100)
    loop = true,
    spaceToggle = true,   -- true = press SPACE while AFK to stop / resume the music
}

Config.Text = {
    title      = 'AFK MODE',
    subtitle   = 'Type /afk to leave',
    emoteHint  = '← → to change dance  |  /afkemote 1-10  |  SPACE = music on/off',
    sitting    = 'Sitting',
    cantUse    = 'You cannot use /afk right now',
    noSlot     = 'No free AFK spot available',
}

-- txAdmin integration: warn AFK players when a scheduled restart is coming
Config.TxAdmin = {
    restartWarning = true,
    -- %s = time remaining (e.g. "5 minutes")
    restartMessage = 'Server Restart In %s. Please leave AFK .',
}

-- Warning shown immediately when a player enters AFK mode
Config.EnterWarning = {
    enabled  = true,
    message  = 'WARNING: Player Caught AFK Inside The RedZone = Banned.',
    type     = 'error',
    duration = 8000,   -- ms
    -- true = show it in the txAdmin "DM from admin" style (blue box)
    -- false = show it as a normal QBCore notification
    useTxAdminStyle = true,
    author   = 'Mega Team',   -- name shown after "DM from admin"
}
