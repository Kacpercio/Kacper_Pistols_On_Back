local curWeapon = nil
local ox_inventory = exports.ox_inventory
local ped = cache.ped
local playerLoaded = false
local Weapons = {
    [`weapon_ceramicpistol`] = { object = `w_pi_ceramic_pistol`, item = 'WEAPON_CERAMICPISTOL', rot = vector3(0,-180,0)},
    [`weapon_pistol`] = { object = `w_pi_pistol`, item = 'WEAPON_PISTOL', rot = vector3(0,-180,0)},
    [`weapon_vintagepistol`] = { object = `w_pi_vintage_pistol`, item = 'WEAPON_VINTAGEPISTOL', rot = vector3(0,-180,0)},
}


local slots = {
    [1] = {
        pos = vec3(-0.17, -0.13, -0.06), -- Center Of Back
        entity = nil,
        hash = nil,
        wep = nil
    },
    [2] = {
        pos = vec3(-0.17, -0.13, 0.10), -- Center-Right
        entity = nil,
        hash = nil,
        wep = nil
    },
    [3] = {
        pos = vec3(0.13, -0.15, 0.07), -- Center-Left
        entity = nil,
        hash = nil,
        wep = nil
    },
}

local function clearSlot(i)
    DetachEntity(slots[i].entity)
    DeleteEntity(slots[i].entity)
    slots[i].entity = nil
    slots[i].hash = nil
    slots[i].wep = nil
end

local function removeFromSlot(hash)
    if Weapons[hash] == nil then return end
    local whatItem = Weapons[hash].item
    local count = ox_inventory:Search(2, whatItem)
    for i = 1, #slots do
        if slots[i].hash == hash then
            if not count or count <= 0 or hash == curWeapon then
                clearSlot(i)
            end
        end
    end
end

local function removeWeapon(hash)
    if Weapons[hash] then
        removeFromSlot(hash)
    end
end

local function removeFromInv(hash)
    removeFromSlot(hash)
end

local function checkForSlot(hash)
    for i = 1, #slots do
        if slots[i].hash == hash then return false end
    end
    for i = 1, #slots do
        local slot = slots[i]
        if not slot.entity then
            return i
        end
    end
    return false
end


local function putOnBack(hash)
    local whatSlot = checkForSlot(hash)
    if whatSlot then
        curWeapon = nil
        local object = Weapons[hash].object
        local item = Weapons[hash].item
        lib.requestModel(object, 500)
        local coords = GetEntityCoords(ped)
        local prop = CreateObject(object, coords.x, coords.y, coords.z,  true,  true, true)
        slots[whatSlot].entity = prop
        slots[whatSlot].hash = hash
        slots[whatSlot].wep = item
        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 24816), slots[whatSlot].pos.x, slots[whatSlot].pos.y, slots[whatSlot].pos.z, Weapons[hash].rot.x, Weapons[hash].rot.y, Weapons[hash].rot.z, true, true, false, true, 2, true)
    end
end

local function respawningCheckWeapon()
    for i = 1, #slots do
        local slot = slots[i]
        if slot.entity ~= nil then
            if DoesEntityExist(slot.entity) then
                DeleteEntity(slot.entity)
            end
            local whatItem = Weapons[slot.hash].item
            local count = ox_inventory:Search(2, whatItem)
            local oldHash = slot.hash
            slots[i].entity = nil
            slots[i].hash = nil
            if count > 0 then
                putOnBack(oldHash)
            end
        end
    end
end

AddEventHandler('ox_inventory:currentWeapon', function(data)
    if data then
        if Weapons[data.hash] then
            putOnBack(curWeapon)
            curWeapon = data.hash
            removeWeapon(data.hash)
        end
    else
        if curWeapon then
            putOnBack(curWeapon)
        end
    end
end)



AddEventHandler('ox_inventory:updateInventory', function(changes)
    playerLoaded = true
    for k, v in pairs(changes) do
        if type(v) == 'table' then
            local hash = joaat(v.name)
            if Weapons[hash] then
                if curWeapon ~= hash then
                    putOnBack(hash)
                else
                    removeFromInv(hash)
                end
            end
        end
        if type(v) == 'boolean' then
            for i = 1, #slots do
                local count = ox_inventory:Search(2, slots[i].wep)
                if not count or count <= 0 then
                    removeFromInv(slots[i].hash)
                end
            end
        end
    end
end)

lib.onCache('vehicle', function(value)
    if value then
        for i = 1, #slots do
            clearSlot(i)
        end
    else
        if GetResourceState('ox_inventory') ~= 'started' or not playerLoaded then return end
        for k, v in pairs(Weapons) do
            local count = ox_inventory:Search(2, v.item)
            if count and count >= 1 then
                putOnBack(k)
            end
        end
    end
end)

lib.onCache('ped', function(value)
    ped = value
end)



