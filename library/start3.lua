-------------------
-- WARP MODULE
-------------------
-- LUA Parameters
MINHUD_show_warp = false --export: Enable the warp module
MINHUD_warp_left_position = 1--export: Warp module position from the left of the HUD
MINHUD_warp_top_position = 120 --export: Warp module position from the top side of the HUD
MINHUD_warp_refresh_rate = 0.25 --export: Warp module refresh rate every x seconds

-------------------
-- WARP UTILITIES
-------------------
-- Function extracted from DU-Orbital-Hud by Dimencia
function getDistanceDisplayString(distance)
    local su = distance > 100000
    local result = ""
    if su then
        -- Convert to SU
        result = round(distance / 1000 / 200, 1) .. " SU"
    elseif distance < 1000 then
        result = round(distance, 1) .. " M"
    else
        -- Convert to KM
        result = round(distance / 1000, 1) .. " KM"
    end

    return result
end
-------------------
-- WARP CLASS
-------------------
WarpModule = {}
WarpModule.__index = WarpModule

function WarpModule.new()
    local self = setmetatable({}, WarpModule)
    self.html = ""
    self.last_time_updated = 0
    if MINHUD_show_warp == true then
        if warpdrive ~= nil then warpdrive.hide() end
    end
    return self
end


function WarpModule.renderHTML(self)
    if (MINHUD_show_warp == true and warpdrive ~= nil) then
        -- Limiting refresh
        if system.getTime() > self.last_time_updated + MINHUD_warp_refresh_rate then
            local obj, pos, err = json.decode(warpdrive.getData(), 1, nil)
            if err then

            else
                self.html = [[
                <style>
                .warp_mod {
                padding:5px;
                width: 9vw;  
                font-weight:bold;
                background-color: rgba(0, 0, 0, .4);
                position:absolute;
                top:]]..MINHUD_warp_top_position..[[px;
                left:]]..MINHUD_warp_left_position..[[px;
                font-size:1vh;
                color:white;
            }
                </style>
                ]]
                self.html = self.html..[[<div class="warp_mod"><div>]]..obj.buttonMsg..[[</div><div style="background-color:red;color:white">]]..obj.errorMsg..[[</div><div>Dest : ]]..obj.destination..[[</div><div>Dist : ]]..getDistanceDisplayString(obj.distance)..[[</div><div>Cells : ]]..obj.cellCount..[[</div></div>]]
            end
        end    
    end
    return self.html
end
