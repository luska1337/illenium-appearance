local Blips = {}
local client = client

RegisterNetEvent("illenium-appearance:Add", function(Infos)
    local exists = false
    for _, shop in ipairs(Config.Stores) do
        if (shop.shopId == Infos.shopsId )then
            exists = true
            break
        end
    end

    if not exists then
        local data = {
            shopId = Infos.shopsId,
            id = Infos.shopsId,
            type = Infos.type,
            coords = vector4(Infos.coords[1], Infos.coords[2], Infos.coords[3], Infos.coords[4]),
            size = vector3(4, 4, 4),
            rotation = 45,
            usePoly = false,
            showBlip = Infos.hasBlip,
            notShowBlip = Infos.hasBlip,
            points = { }
        }
        Config.Stores[#Config.Stores + 1] = data
    end
end)

RegisterNetEvent("illenium-appearance:Rem", function(id)
    local storeIndex = lib.array.findIndex(Config.Stores, function(e) return e.shopId == id end)
    if storeIndex then 
        table.remove(Config.Stores, storeIndex)
    end
end)

RegisterNetEvent("illenium-appearance:Blips", function()
    Wait(5000)
    ResetBlips()
end)

local function ShowBlip(blipConfig, blip)
    if blip.job and blip.job ~= client.job.name then
        return false
    elseif blip.gang and blip.gang ~= client.gang.name then
        return false
    end

    if Config.RCoreTattoosCompatibility and blip.type == "tattoo" then
        return false
    end

    return (blipConfig.Show and blip.showBlip == nil) or blip.showBlip
end

local function CreateBlip(blipConfig, coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, blipConfig.Sprite)
    SetBlipColour(blip, blipConfig.Color)
    SetBlipScale(blip, blipConfig.Scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipConfig.Name)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function SetupBlips()
    for k, _ in pairs(Config.Stores) do
        local blipConfig = Config.Blips[Config.Stores[k].type]
        if ShowBlip(blipConfig, Config.Stores[k]) and not _.notShowBlip then
            local blip = CreateBlip(blipConfig, Config.Stores[k].coords)
            Blips[#Blips + 1] = blip
        end
    end
end

function ResetBlips()
    if Config.ShowNearestShopOnly then
        return
    end

    for i = 1, #Blips do
        RemoveBlip(Blips[i])
    end
    Blips = {}
    SetupBlips()
end

local function ShowNearestShopBlip()
    for k in pairs(Config.Blips) do
        Blips[k] = 0
    end
    while true do
        local coords = GetEntityCoords(cache.ped)
        for shopType, blipConfig in pairs(Config.Blips) do
            local closest = 1000000
            local closestCoords

            for _, shop in pairs(Config.Stores) do
                if shop.type == shopType and ShowBlip(blipConfig, shop) then
                    local dist = #(coords - vector3(shop.coords.xyz))
                    if dist < closest then
                        closest = dist
                        closestCoords = shop.coords
                    end
                end
            end
            if DoesBlipExist(Blips[shopType]) then
                RemoveBlip(Blips[shopType])
            end

            if closestCoords then
                Blips[shopType] = CreateBlip(blipConfig, closestCoords)
            end
        end
        Wait(Config.NearestShopBlipUpdateDelay)
    end
end

if Config.ShowNearestShopOnly then
    CreateThread(ShowNearestShopBlip)
end