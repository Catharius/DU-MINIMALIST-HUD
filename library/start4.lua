-------------------
-- WEAPON MODULE
-------------------
MINHUD_show_weapon=true

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

        if idtarget ~= nil then
            local obj, pos, err = json.decode(radar[1].getData(), 1, nil)
            if err then
                system.print("Error:", err)
            else 
                for i = 1,#obj.constructsList do
                    if obj.constructsList[i].constructId==idtarget then
                        self.html=self.html.."Target<br><b>"..obj.constructsList[i].name.."</b><hr>"
                        self.html=self.html.."Distance<br><b>"..getDistanceDisplayString(obj.constructsList[i].distance).."</b>"
                    end    
                end
            end
        end
    end
    return self.html.."</div>"
end
