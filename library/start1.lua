-------------------
-- DAMAGE REPORT MODULE
-------------------
-- LUA Parameters
damagereport_module_active = true --export: Enable the ship's damage report
damagereport_module_defaultFilter = 1 --export: 1 for all,2 for avionics and weapons,3 for avionics only, 4 for weapons only
damagereport_ratio_modifier = 0 --export: Change the size of the ship's map, use positive or negative numbers
damagereport_x_pos_modifier = 0 --export: Change the x position of the ship's map
damagereport_y_pos_modifier = 0 --export: Change the y position of the ship's map
damagereport_rotate_x = 43 --export: Change the x rotation of the ship's map in degrees (0 for 2D)
damagereport_rotate_y = -7 --export: Change the y rotation of the ship's map in degrees (0 for 2D)
damagereport_rotate_z = 8 --export: Change the z rotation of the ship's map in degrees (0 for 2D)
damagereport_txt_module_active = true --export: Enable the ship's damage text report
damagereport_txt_posx = 1 --export: Damage text position from the left side of the HUD   
damagereport_txt_posy = 120 --export: Damage text position from the top side of the HUD 
damagereport_txt_priority = 2 --export: Show damaged components (3) Below 100%, (2) Below 75%, (1) Below 50%

damagereport_refresh_rate = 0.25 --export: Damage report refresh rate every x seconds
-------------------
-- General Functions
-------------------
function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function getElemCategory(elemtype)
    elem_category="UNKNOWN"
    if elemtype ~= nil then
        local critical_part_list = {"DYNAMIC CORE","RESURRECTION NODE"}   
        local avionics_part_list = {"ENGINE","FUEL-TANK","ADJUSTOR","VERTICAL BOOSTER","RETRO-ROCKET BRAKE","WING","ATMOSPHERIC AIRBRAKE"}
        local weapon_part_list = {"GUNNER MODULE","LASER","COMMAND SEAT CONTROLLER","COCKPIT","CANNON","MISSILE","RAILGUN"}   
        -- CRITICALS
        for _,reftype in ipairs(critical_part_list) do
            if string.match(elemtype, reftype) then
                elem_category="CRITICALS"
                break
            end    
        end
        if elem_category == "UNKNOWN" then
            -- AVIONICS 
            for _,reftype in ipairs(avionics_part_list) do
                if string.match(elemtype, reftype) then
                    elem_category="AVIONICS"
                    break
                end    
            end
            if elem_category == "UNKNOWN" then
                -- WEAPONS
                for _,reftype in ipairs(avionics_part_list) do
                    -- Avoid mistaking laser emitter for a weapon...
                    if elemtype == "LASER" then
                        elem_category="WEAPON"
                        break 
                    elseif string.match(elemtype, reftype) then
                        elem_category="WEAPON"
                        break
                    end    
                end 
            end
        end 
    end    
    return elem_category
end


-------------------
-- Element Class
-------------------
Element = {}
Element.__index = Element

function Element.new(elem_id,elem_type,elem_category, elem_name, elem_pos_x, elem_pos_y, elem_pos_z)
    local self = setmetatable({}, Element)
    self.elem_id = elem_id
    self.elem_type = elem_type
    self.elem_category = elem_category
    self.elem_name = elem_name
    self.elem_pos_x = elem_pos_x
    self.elem_pos_y = elem_pos_y
    self.elem_pos_z = elem_pos_z

    return self
end

-------------------
-- DamageModule Class
-------------------
DamageModule = {}
DamageModule.__index = DamageModule

function DamageModule.new()
    local self = setmetatable({}, DamageModule)
    self.elem_list = {}
    self.elem_filter = damagereport_module_defaultFilter -- 4 for all,3 for avionics and weapons,2 for avionics only, 1 for weapons
    self.last_time_updated = 0
    --Default placement
    self.dmg_module_size_ratio = 0
    self.dmg_module_center_posx = 0
    self.dmg_module_center_posy = 0

    -- Getting the core offset
    -- XS CORE
    local core_offset = -5
    self.dmg_module_size_ratio = 14
    self.dmg_module_center_posx = 100
    self.dmg_module_center_posy = 380

    local core_hp = core.getElementHitPointsById(core.getId())
    if core_hp > 10000 then
        -- L CORE
        core_offset = -128
        self.dmg_module_size_ratio = 1
        self.dmg_module_center_posx = 20
        self.dmg_module_center_posy = 45
    elseif core_hp > 1000 then
        -- M CORE
        core_offset = -64
        self.dmg_module_size_ratio = 2
        self.dmg_module_center_posx = 210
        self.dmg_module_center_posy = 70
    elseif core_hp > 150 then
        -- S CORE
        core_offset = -32
        self.dmg_module_size_ratio = 5
        self.dmg_module_center_posx = 240
        self.dmg_module_center_posy = 70 
    end

    self.core_offset=core_offset   
    -- Adjustments
    self.dmg_module_size_ratio=self.dmg_module_size_ratio+damagereport_ratio_modifier
    self.dmg_module_center_posx=self.dmg_module_center_posx+damagereport_x_pos_modifier
    self.dmg_module_center_posy=self.dmg_module_center_posy+damagereport_y_pos_modifier

    self.min_y = 999999999
    -- STORING SHIP ELEMENTS
    for i,idelem in ipairs(core.getElementIdList()) do
        local elem_type = core.getElementTypeById(idelem):upper()
        local elem_categ = getElemCategory(elem_type)
        local elem_name = core.getElementNameById(idelem)
        local x,y,z = table.unpack(core.getElementPositionById(idelem))
        x=(x+core_offset)*self.dmg_module_size_ratio
        y=(y+core_offset)*self.dmg_module_size_ratio
        z=(z+core_offset)*self.dmg_module_size_ratio
        if self.min_y > y then
            self.min_y = y
        end    
        self:add(Element.new(idelem,elem_type, elem_categ, elem_name, x, y, z))
    end

    return self
end

function DamageModule.add(self,element)
    table.insert(self.elem_list, element)
end

function DamageModule.nextFilter(self)
    if self.elem_filter < 4 then
        self.elem_filter = self.elem_filter + 1
    else 
        self.elem_filter = 1 	    
    end 
end

function DamageModule.renderHTML(self)
    local html=""
    if damagereport_module_active == true then
        -- Limiting refresh
        if system.getTime() > self.last_time_updated + damagereport_refresh_rate then
            local css = [[ 
            <style>
            .rotate_div {
            -webkit-transform:rotateX(]]..damagereport_rotate_x..[[deg) rotateY(]]..damagereport_rotate_y..[[deg) rotateZ(]]..damagereport_rotate_z..[[deg);
            -moz-transform:rotateX(]]..damagereport_rotate_x..[[deg) rotateY(]]..damagereport_rotate_y..[[deg) rotateZ(]]..damagereport_rotate_z..[[deg);
            -ms-transform:rotateX(]]..damagereport_rotate_x..[[deg) rotateY(]]..damagereport_rotate_y..[[deg) rotateZ(]]..damagereport_rotate_z..[[deg);
            -o-transform:rotateX(]]..damagereport_rotate_x..[[deg) rotateY(]]..damagereport_rotate_y..[[deg) rotateZ(]]..damagereport_rotate_z..[[deg);
            transform:rotateX(]]..damagereport_rotate_x..[[deg) rotateY(]]..damagereport_rotate_y..[[deg) rotateZ(]]..damagereport_rotate_z..[[deg);
        }
            .title {
            font-size:1vh;
            text-align:center;
            font-weight:bold;
        }
            .dmgtxt {
            background-color: rgba(0, 0, 0, .4);
            width: 8vw;
            font-size:1vh;   
            position:absolute;
            left:]]..damagereport_txt_posx..[[px;
            top:]]..damagereport_txt_posy..[[px;
        }
            .dmgdotlabel {
            width: 8vw;
            text-align:center;
            font-size:2vh;
            font-weight:bold;
            position:absolute;
        }
            .dmgdot {
            height: 10px;
            width: 10px;
            border-radius: 50%;
            display: inline-block;
            position:absolute;
            opacity:0.35;
        }
            .pristine {
            background-color: #9BFFAC;
        }
            .ldmg {
            background-color: #FFDD8E;
        }
            .mdmg {
            background-color: #FF9E66;
        }
            .hdmg {
            background-color: #FF2819;
        }
            .dead {
            background-color: #7F120C;
        }
            </style>
            <div class="rotate_div">
            ]]  
            html = css
            havedamage = false
            local dead_elem_list=""
            local high_damage_list=""
            local medium_damage_list=""
            local light_damage_list=""

            for _,elem in ipairs(self.elem_list) do
                local element_excluded = false
                if self.elem_filter == 2 and elem.elem_category ~= "AVIONICS" and elem.elem_category ~= "WEAPON" and elem.elem_category ~= "CRITICAL" then
                    element_excluded = true
                elseif self.elem_filter == 3 and elem.elem_category ~= "AVIONICS" and elem.elem_category ~= "CRITICAL" then
                    element_excluded = true
                elseif self.elem_filter == 4 and elem.elem_category ~= "WEAPON" and elem.elem_category ~= "CRITICAL" then
                    element_excluded = true   
                end    
                if element_excluded == false then
                    local elem_hp = core.getElementHitPointsById(elem.elem_id)
                    local elemmax_hp = core.getElementMaxHitPointsById(elem.elem_id)
                    local elem_hp_percentage = (elem_hp*100)/elemmax_hp
                    local color_class=""
                    if elem_hp_percentage >= 100 then
                        color_class=" pristine"
                    elseif elem_hp_percentage >= 75 then
                        color_class=" ldmg"
                        havedamage = true
                        if damagereport_txt_priority > 2 then
                            light_damage_list=light_damage_list..[[<div style="color:#FFDD8E;"> ]]..elem.elem_name..[[ -> ]]..elem_hp_percentage..[[</div>]]
                        end                
                    elseif elem_hp_percentage >= 50 then
                        color_class=" mdmg"
                        havedamage = true
                        if damagereport_txt_priority > 1 then
                            medium_damage_list=medium_damage_list..[[<div style="color:#FF9E66;"> ]]..elem.elem_name..[[ -> ]]..round(elem_hp_percentage,0)..[[%</div>]]
                        end
                    elseif elem_hp_percentage > 0 then
                        color_class=" hdmg"
                        havedamage = true
                        high_damage_list=high_damage_list..[[<div style="color:#FF2819;"> ]]..elem.elem_name..[[ -> ]]..round(elem_hp_percentage,0)..[[%</div>]]
                    elseif elem_hp_percentage == 0 then
                        color_class=" dead"
                        havedamage = true
                        dead_elem_list=dead_elem_list..[[<div style="color:#7F120C;"> ]]..elem.elem_name..[[ -> DEAD</div>]]
                    end
                    html = html..[[<div class="dmgdot]]..color_class..[[" style="transform:translateY(]]..(-elem.elem_pos_z)..[[px);left:]]..self.dmg_module_center_posx+elem.elem_pos_x..[[px;top:]]..self.dmg_module_center_posy-elem.elem_pos_y..[[px;"></div>]]      
                end 
            end    
            html = html..[[</div>]]
            -- Text damage report
            --Adding filter label below
            local filter_label = "ALL"
            if self.elem_filter == 2 then
                filter_label = "WP & AV"
            elseif self.elem_filter == 3 then
                filter_label = "AVIONICS"
            elseif  self.elem_filter == 4 then
                filter_label = "WEAPONS"
            end
            if damagereport_txt_module_active==true then
                html = html..[[<div class="dmgtxt"><div class="title">Damage Report :<br>]]..filter_label..[[</div><hr>]]..dead_elem_list..high_damage_list..medium_damage_list..light_damage_list..[[</div>]]
            end
        end   
    end
    return html
end
