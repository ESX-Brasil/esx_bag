local ESX = nil

-- ESX
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterUsableItem('bag', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)

    xPlayer.removeInventoryItem('bag', 1)

    TriggerClientEvent('esx_bag:CheckBag', source, HasBag)
    if not HasBag then
        TriggerEvent('esx_bag:InsertBag', source)
    else
        TriggerClientEvent('esx:showNotification', source, _U('already_bag'))
    end
end)

ESX.RegisterServerCallback('esx_bag:getPlayerInventory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local items   = xPlayer.inventory

    cb({items = items})
 end)

ESX.RegisterServerCallback('esx_bag:getBag', function(source, cb)
    local src = source
    local identifier = ESX.GetPlayerFromId(src).identifier

        MySQL.Async.fetchAll('SELECT * FROM owned_bags WHERE identifier = @identifier ',{["@identifier"] = identifier}, function(bag)

            if bag[1] ~= nil then
                MySQL.Async.fetchAll('SELECT * FROM owned_bag_inventory WHERE id = @id ',{["@id"] = bag[1].id}, function(inventory)
                cb({bag = bag, inventory = inventory})
                end)
            else
                cb(nil)
            end
    end)
end)

ESX.RegisterServerCallback('esx_bag:getAllBags', function(source, cb)
    local src = source

    MySQL.Async.fetchAll('SELECT * FROM owned_bags', {}, function(bags)

        if bags[1] ~= nil then
            cb(bags)
        else
            cb(nil)
        end
    end)
end)


ESX.RegisterServerCallback('esx_bag:getBagInventory', function(source, cb, BagId)
    local src = source
    local identifier = ESX.GetPlayerFromId(src).identifier

        MySQL.Async.fetchAll('SELECT * FROM owned_bag_inventory WHERE id = @id ',{["@id"] = BagId}, function(bag)
        cb(bag)
    end)
end)

RegisterServerEvent('esx_bag:InsertBag')
AddEventHandler('esx_bag:InsertBag', function(source)
    local src = source
    local identifier = ESX.GetPlayerFromId(src).identifier
    local xPlayer = ESX.GetPlayerFromId(src)
    local xPlayers = ESX.GetPlayers()

    TriggerClientEvent('esx_bag:GiveBag', src)
    for i=1, #xPlayers, 1 do
        TriggerClientEvent('esx_bag:ReSync', xPlayers[i], id)
     end
    MySQL.Async.execute('INSERT INTO owned_bags (identifier, id, x, y, z) VALUES (@identifier, @id, @x, @y, @z)', {['@identifier'] = identifier,['@id']  = math.random(1, 100000), ['@x']  = nil, ['@y'] = nil, ['@y'] = nil})
end)

RegisterServerEvent('esx_bag:TakeItem')
AddEventHandler('esx_bag:TakeItem', function(id, item, count, type)
    local src = source
    local identifier = ESX.GetPlayerFromId(src).identifier
    local xPlayer = ESX.GetPlayerFromId(src)

    MySQL.Async.fetchAll('SELECT * FROM owned_bags WHERE id = @id ',{["@id"] = id}, function(bag)
    MySQL.Async.fetchAll('SELECT * FROM owned_bag_inventory WHERE id = @id AND item = @item ',{["@id"] = id, ["@item"] = item}, function(result)

    if result[1] ~= nil then

        if type == 'weapon' then
            xPlayer.addWeapon(item, count)
        elseif type == 'item' then
            xPlayer.addInventoryItem(item, count)
        end
                MySQL.Async.execute('UPDATE owned_bags SET itemcount = @itemcount WHERE id = @id', {['@id'] = id, ['@itemcount'] = bag[1].itemcount - 1})
                MySQL.Async.execute('DELETE FROM owned_bag_inventory WHERE id = @id AND item = @item AND count = @count',{['@id'] = id,['@item'] = item, ['@count'] = count})
            end
        end)
    end)
end)

RegisterServerEvent('esx_bag:PutItem')
AddEventHandler('esx_bag:PutItem', function(id, item, label, count, type)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = ESX.GetPlayerFromId(src).identifier
	local update
    local insert

    MySQL.Async.fetchAll('SELECT * FROM owned_bags WHERE identifier = @identifier ',{["@identifier"] = identifier}, function(bag)

    if bag[1].itemcount < Config.MaxDifferentItems then

    if type == 'weapon' then
        xPlayer.removeWeapon(item, count)
        MySQL.Async.execute('UPDATE owned_bags SET itemcount = @itemcount WHERE identifier = @identifier', {['@identifier'] = identifier, ['@itemcount'] = bag[1].itemcount + 1})
		MySQL.Async.execute('INSERT INTO owned_bag_inventory (id, label, item, count) VALUES (@id, @label, @item, @count)', {['@id'] = id,['@item']  = item, ['@label']  = label, ['@count'] = count})
    elseif type == 'item' and count < Config.MaxItemCount then
        xPlayer.removeInventoryItem(item, count)
		MySQL.Async.fetchAll('SELECT * FROM owned_bag_inventory WHERE id = @id ',{["@id"] = id}, function(result)
			if result[1] ~= nil then
				for i=1, #result, 1 do
					if result[i].item == item then
						count = count + result[i].count
						update = 1
					elseif result[i].item ~= item then
						insert = 1
					end
				end
                    if update == 1 then
                        MySQL.Async.execute('UPDATE owned_bag_inventory SET count = @count WHERE item = @item', {['@item'] = item, ['@count'] = count})
                    elseif insert == 1 then
                        MySQL.Async.execute('UPDATE owned_bags SET itemcount = @itemcount WHERE identifier = @identifier', {['@identifier'] = identifier, ['@itemcount'] = bag[1].itemcount + 1})
                        MySQL.Async.execute('INSERT INTO owned_bag_inventory (id, label, item, count) VALUES (@id, @label, @item, @count)', {['@id'] = id,['@item']  = item, ['@label']  = label, ['@count'] = count})
                    end
                    else
                        MySQL.Async.execute('UPDATE owned_bags SET itemcount = @itemcount WHERE identifier = @identifier', {['@identifier'] = identifier, ['@itemcount'] = bag[1].itemcount + 1})
                        MySQL.Async.execute('INSERT INTO owned_bag_inventory (id, label, item, count) VALUES (@id, @label, @item, @count)', {['@id'] = id,['@item']  = item, ['@label']  = label, ['@count'] = count})
			        end
		        end)
            end
        else
            TriggerClientEvent('esx:showNotification', src, _U('you_can_only_have') .. Config.MaxItemCount .. _U('different_items_in_your_bag'))
        end
    end)
end)
RegisterServerEvent('esx_bag:PickUpBag')
AddEventHandler('esx_bag:PickUpBag', function(id)
    local src = source
    local identifier = ESX.GetPlayerFromId(src).identifier

    MySQL.Async.fetchAll('UPDATE owned_bags SET identifier = @identifier, x = @x, y = @y, z = @z WHERE id = @id', {['@identifier'] = identifier, ['@id'] = id, ['@x'] = nil, ['@y'] = nil, ['@z'] = nil})

        local xPlayers = ESX.GetPlayers()

     for i=1, #xPlayers, 1 do
        TriggerClientEvent('esx_bag:SetOntoPlayer', src, id)
	TriggerClientEvent('esx:showNotification', src, _U('bag_access'))
        TriggerClientEvent('esx_bag:ReSync', xPlayers[i], id)
     end
end)

RegisterServerEvent('esx_bag:DropBag')
AddEventHandler('esx_bag:DropBag', function(id, x, y, z)
    local src = source
    local identifier = ESX.GetPlayerFromId(src).identifier

    MySQL.Async.fetchAll('UPDATE owned_bags SET identifier = @identifier, x = @x, y = @y, z = @z WHERE id = @id', {['@identifier'] = nil, ['@id'] = id, ['@x'] = x, ['@y'] = y, ['@z'] = z})

        local xPlayers = ESX.GetPlayers()

    for i=1, #xPlayers, 1 do
        TriggerClientEvent('esx_bag:ReSync', xPlayers[i], id)
    end
end)
