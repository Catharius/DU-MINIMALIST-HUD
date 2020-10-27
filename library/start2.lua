-------------------
-- FUEL MODULE
-------------------
-- LUA Parameters
fuel_module_active = true --export: Enable the fuel module
fuel_module_posx = 1 --export: Fuel module position from the left of the HUD
fuel_module_posy = 0 --export: Fuel module position from the top side of the HUD
fuel_module_refresh_rate = 0.25 --export: Fuel module refresh rate every x seconds
fuel_module_show_remaining_time = 10 --export: If fuel is lasting more than x hours, do not show remaining time, 0 to always show remaining time

-------------------
-- FUEL CLASS
-------------------
FuelModule = {}
FuelModule.__index = FuelModule

function FuelModule.new()
    local self = setmetatable({}, FuelModule)
    self.html = ""
    self.last_time_updated = 0
    return self
end

function FuelModule.computeData(self,fuel_tank)
    local fuel_percentage = ""
    local fuel_time_to_empty = ""

    local obj, pos, err = json.decode(fuel_tank.getData(), 1, nil)
    if err then
    else
        -- Computing fuel percentage
        if obj.percentage ~= nil then
            fuel_percentage = obj.percentage
        end
        -- Computing time left thanks to data in seconds
        if obj.timeLeft ~= nil and obj.timeLeft ~= "" then
            local time_left = tonumber(obj.timeLeft)
            if time_left ~= nil then
                -- DAYS (86 400 seconds are one day)
                local days = time_left // 86400
                -- Modulus to get hours lefts
                time_left = time_left % 86400
                -- HOURS (3600 seconds are one hour)
                local hours = time_left // 3600
                -- Modulus again to get minutes lefts
                time_left = time_left % 3600
                -- MINUTES (60 seconds are 1 minute) 
                local minutes = time_left // 60
                -- Modulus again to get minutes lefts
                time_left = time_left % 60
                local seconds = time_left
                -- To avoid useless infos we show only if we have 99 days of autonomy
                if days < 99 then                   
                    local truehours = tonumber(obj.timeLeft) // 3600
                    if (fuel_module_show_remaining_time==0 or fuel_module_show_remaining_time>=truehours) then
                        if days > 0 then
                            fuel_time_to_empty = " | "..tonumber(string.format("%."..(0).."f",days)).."d:"..tonumber(string.format("%."..(0).."f",hours)).."h:"..tonumber(string.format("%."..(0).."f",minutes)).."m:"..tonumber(string.format("%."..(0).."f", seconds)).."s"  
                        elseif hours>0 then
                            fuel_time_to_empty = " | "..tonumber(string.format("%."..(0).."f",hours)).."h:"..tonumber(string.format("%."..(0).."f",minutes)).."m:"..tonumber(string.format("%."..(0).."f", seconds)).."s"         
                        elseif minutes>0 then
                            fuel_time_to_empty = " | "..tonumber(string.format("%."..(0).."f",minutes)).."m:"..tonumber(string.format("%."..(0).."f", seconds)).."s"            
                        elseif seconds>0 then
                            fuel_time_to_empty = " | "..tonumber(string.format("%."..(0).."f",minutes)).."m:"..tonumber(string.format("%."..(0).."f", seconds)).."s"                
                        end        	 
                    end
                end    
            end      
        end          
    end
    return {fuel_percentage,fuel_time_to_empty}
end

function FuelModule.renderHTML(self)
    if fuel_module_active == true then
        -- Limiting refresh
        if system.getTime() > self.last_time_updated + fuel_module_refresh_rate then
            self.last_time_updated = system.getTime()
            -- CSS           
            self.html = [[
            <style>
            #progress {
            opacity:0.8;
            width: 8vw;   
            background-color:black;
            position: relative;
        }
            #percent {
            color:white;
            font-weight:bold;
            position: absolute; 
            font-size:1.2vh;
            left: 4%;
        }
            #bar {
            height: 1.4vh;
        }
            .fuelmodule {
            position:absolute;
            top:]]..fuel_module_posy..[[px;
            left:]]..fuel_module_posx..[[px;
        }
            </style>
            <div class="fuelmodule">
            <table>
            ]]
            -- ATMO    
            for _,f_tank in ipairs(atmofueltank) do
                local ft_data = self:computeData(f_tank)
                self.html=self.html..[[<tr><td><div id="progress"><span id="percent">]]..ft_data[1]..[[%]]..ft_data[2]..[[</span><div id="bar" style="background-color:#8FC3BD;width:]]..ft_data[1]..[[%;"></div></td></tr>]]
            end
            -- SPACE
            for _,f_tank in ipairs(spacefueltank) do
                local ft_data = self:computeData(f_tank)
                self.html=self.html..[[<tr><td><div id="progress"><span id="percent">]]..ft_data[1]..[[%]]..ft_data[2]..[[</span><div id="bar" style="background-color:#BCB83C;width:]]..ft_data[1]..[[%;"></div></td></tr>]]
            end
            -- ROCKET
            for _,f_tank in ipairs(rocketfueltank) do
                local ft_data = self:computeData(f_tank)
                self.html=self.html..[[<tr><td><div id="progress"><span id="percent">]]..ft_data[1]..[[%]]..ft_data[2]..[[</span><div id="bar" style="background-color:#937E97;width:]]..ft_data[1]..[[%;"></div></td></tr>]]
            end 

            --CLOSING TABLE 
            self.html=self.html..[[</table></div>]]
        end    
    end    
    return self.html    
end
