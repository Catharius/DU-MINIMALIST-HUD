-------------------
-- RADAR UTILITY FUNCTIONS
-------------------
--function to split a string into an arrow using a delimeter
function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

--function to take a substring from another, identified between to known chars/set of chars, error if chars not found
function Str_Cut(str,s_begin,s_end)
    local StrLen = string.len(str)
    local s_begin_Len = string.len(s_begin)
    local s_end_Len = string.len(s_end)
    local s_begin_x = string.find(str, s_begin, 1)
    --print(s_begin_x)
    local s_end_x = string.find(str, s_end, s_begin_x+1)
    --print(s_end_x)
    local rs=(string.sub(str, s_begin_x+s_begin_Len, s_end_x-1))
    return rs
end


-------------------
-- WEAPON MODULE
-------------------
MINHUD_show_weapon = true --export: show/hide weapon module
MINHUD_weapon_refresh_rate = 0.25 --export: Weapon refresh rate every x seconds

WeaponModule = {}
WeaponModule.__index = WeaponModule

function WeaponModule.new()
    local self = setmetatable({}, WeaponModule)
    self.html = ""
    self.last_time_updated = 0
    return self
end

function WeaponModule.renderHTML(self)
    if MINHUD_show_weapon and weapon_size>0 and radar_size>0 then
        if system.getTime() > self.last_time_updated + MINHUD_weapon_refresh_rate then
            local idtarget=nil
            self.html=[[<style>
            .cat {
            color:black;
            background-color:white;
        }
            .wptxt {
            text-align:center;
            background-color: rgba(0, 0, 0, .4);
            width: 9vw;
            font-size:1vh;   
            position:absolute;
            left:]]..(MINHUD_txt_module_left_pos+180)..[[px;
            top:]]..(MINHUD_txt_module_top_pos+27)..[[px;
        }</style><div class="wptxt">]]
            -- Draw hud for each weapons
            for i,current_wp in ipairs(weapon) do
                local obj, pos, err = json.decode(current_wp.getData(), 1, nil)
                if err then
                    system.print("Error:", err)
                else
                    self.html = self.html..[[<div class="title"><hr>]]..obj.name..[[<br><hr><table style="width:100%;">]]
                    self.html = self.html..[[<tr><td class="cat" rowspan="2">A<br>M<br>M<br>O</td><td>type</td><td class="r">]]..obj.properties.ammoName..[[</td></tr>]]
                    if obj.properties.ammoCount == nil or obj.properties.ammoCount == 0 then
                        self.html = self.html..[[<tr><td style="background-color:red;" colspan="2">RELOAD !</td></tr>]]
                    else
                        self.html = self.html..[[<tr><td>Remaining</td><td class="r">]]..obj.properties.ammoCount..[[</td></tr>]]
                    end    
                    self.html = self.html..[[<tr><td colspan="3"><hr></td></tr>]]
                    self.html = self.html..[[<tr><td class="cat" rowspan="3">F<br>O<br>E</td>]]
                    if obj.targetConstruct ~= nil and obj.targetConstruct.constructId ~= nil and obj.targetConstruct.constructId ~= "0" and obj.properties.outOfZone == true then
                        self.html = self.html..[[<td colspan="2" style="background-color:red;">OUT OF RANGE</td></tr>]]
                    elseif obj.targetConstruct ~= nil and obj.targetConstruct.constructId ~= nil and obj.targetConstruct.constructId ~= "0" and obj.properties.outOfZone == false then
                        local hitchance = round(obj.properties.hitProbability*100,2)
                        local color="red"
                        if hitchance>75 then
                            color="green"
                        elseif hitchance>50 then
                            color="yellow"  
                        elseif hitchance>35 then
                            color="orange"
                        end    
                        self.html = self.html..[[<td colspan="2" style="background-color:]]..color..[[;font-size:2vh;">]]..hitchance..[[%</td></tr>]]    
                    else
                        self.html = self.html..[[<td colspan="2">NO TARGET</td></tr>]]
                    end    
                    self.html = self.html..[[</table></div>]]
                    -- Target info
                    if obj.targetConstruct ~= nil then
                        idtarget = obj.targetConstruct.constructId
                    end    
                end
            end  

            if idtarget ~= nil and tonumber(idtarget)>0 then
                -- To avoid CPU OVERLOAD, it is smarter to cut the radar contact list
                local data = split(radar[1].getData(),idtarget.."\",")
                if data ~= nil and data[2] ~= nil then
                    data = split(data[2],",\"targetThreatState") 
                    local target_data = data[1]
                    if  target_data ~= nil then
                        local obj, pos, err = json.decode("{"..target_data.."}", 1, nil)
                        if err then
                            system.print("Error:", err)
                        else 
                            self.html=self.html.."<br>Target<br><b>"..obj.name.."</b><hr>"
                            self.html=self.html.."Size<br><b>"..obj.size.."</b><hr>"
                            self.html=self.html.."Distance<br><b>"..getDistanceDisplayString(obj.distance).."</b>"
                        end
                    end
                end  
            end
        end
    end    
    return self.html.."</div>"
end
