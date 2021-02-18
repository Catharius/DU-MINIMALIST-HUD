-------------------
-- DAMAGE REPORT MODULE
-------------------
-- LUA Parameters
MINHUD_show_labels = true --export: show/hide view labels
MINHUD_defaultFilter = 1 --export: 1 for all,2 for avionics and weapons,3 for avionics only, 4 for weapons only
MINHUD_defaultView = 1 --export: 1 for top,2 for side and 3 for front
MINHUD_show_txt_module = true --export: enable the ship damage text report
MINHUD_dmg_priority = 2 --export: Show damaged components (3) Below 100%, (2) Below 75%, (1) Below 50%

MINHUD_size_ratio = 1 --export: change the size of the ship layout, use positive or negative numbers
MINHUD_top_position = 5 --export: change the left position of the ship layout (Increase to move right)
MINHUD_left_position = 180 --export: change the top position of the ship layout (Increase to move down)
MINHUD_label_position = 0 --export: move the view label left or right (useful for centering)

MINHUD_txt_module_left_pos = 1 --export:  change the left position of the ship layout (Increase to move right)   
MINHUD_txt_module_top_pos = 200 --export: change the top position of the ship layout (Increase to move down)


MINHUD_dmg_refresh_rate = 0.25 --export: Damage report refresh rate every x seconds
-------------------
-- General Functions
-------------------
function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function getElemCategory(elemtype)
    elem_category="UNKNOWN"
    if elemtype ~= nil then
        local critical_part_list = {"DYNAMIC CORE","RESURRECTION NODE","RADAR","GUNNER MODULE","COMMAND SEAT CONTROLLER","COCKPIT"}   
        local avionics_part_list = {"ENGINE","FUEL-TANK","ADJUSTOR","VERTICAL BOOSTER","RETRO-ROCKET BRAKE","WING","ATMOSPHERIC AIRBRAKE"}
        local weapon_part_list = {"LASER","CANNON","MISSILE","RAILGUN"}
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
                for _,reftype in ipairs(weapon_part_list) do
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
    self.elem_filter = MINHUD_defaultFilter -- 4 for all,3 for avionics and weapons,2 for avionics only, 1 for weapons
    self.active_view = MINHUD_defaultView -- 1 for top,2 for side and 3 for front
    self.last_time_updated = 0
    --Default placement
    self.dmg_module_size_ratio = 0

    -- Getting the core offset
    -- XS CORE
    local core_offset = -5
    self.dmg_module_size_ratio = 10

    local core_hp = core.getElementHitPointsById(core.getId())
    if core_hp > 10000 then
        -- L CORE
        core_offset = -128
        self.dmg_module_size_ratio = 1
    elseif core_hp > 1000 then
        -- M CORE
        core_offset = -64
        self.dmg_module_size_ratio = 2
    elseif core_hp > 150 then
        -- S CORE
        core_offset = -32
        self.dmg_module_size_ratio = 5
    end

    self.core_offset=core_offset   
    -- Adjustments
    self.dmg_module_size_ratio=self.dmg_module_size_ratio+MINHUD_size_ratio

    self.max_x= -999999999
    self.min_x= 999999999
    self.max_y= -999999999
    self.min_y = 999999999
    self.max_z= -999999999
    self.min_z = 999999999


    -- STORING SHIP ELEMENTS
    for i,idelem in ipairs(core.getElementIdList()) do
        local elem_type = core.getElementTypeById(idelem):upper()
        local elem_categ = getElemCategory(elem_type)
        local elem_name = core.getElementNameById(idelem)
        local x,y,z = table.unpack(core.getElementPositionById(idelem))
        x=(x+core_offset)*self.dmg_module_size_ratio
        y=(y+core_offset)*self.dmg_module_size_ratio
        z=(z+core_offset)*self.dmg_module_size_ratio
        if self.min_x > x then
            self.min_x = x
        end    
        if self.min_y > y then
            self.min_y = y
        end
        if self.min_z > z then
            self.min_z = z
        end 
        if self.max_x < x then
            self.max_x = x
        end    
        if self.max_y < y then
            self.max_y = y
        end
        if self.max_z < z then
            self.max_z = z
        end
        self:add(Element.new(idelem,elem_type, elem_categ, elem_name, x, y, z))
    end
    -- Computing ship size
    self.ship_width = 0
    if self.min_x < 0 then
        self.ship_width = self.ship_width + (self.min_x)*-1
    else
        self.ship_width = self.ship_width + self.min_x
    end      
    if self.max_x < 0 then
        self.ship_width = self.ship_width + (self.max_x)*-1
    else
        self.ship_width = self.ship_width + self.max_x
    end
    self.ship_height = 0
    if self.min_y < 0 then
        self.ship_height = self.ship_height + (self.min_y)*-1
    else
        self.ship_height = self.ship_height + self.min_y
    end      
    if self.max_y < 0 then
        self.ship_height = self.ship_height + (self.max_y)*-1
    else
        self.ship_height = self.ship_height + self.max_y
    end
    self.ship_z = 0
    if self.min_z < 0 then
        self.ship_z = self.ship_z + (self.min_z)*-1
    else
        self.ship_z = self.ship_z + self.min_z
    end      
    if self.max_z < 0 then
        self.ship_z = self.ship_z + (self.max_z)*-1
    else
        self.ship_z = self.ship_z + self.max_z
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

function DamageModule.nextView(self)
    if self.active_view < 3 then
        self.active_view = self.active_view + 1
    else 
        self.active_view = 1 	    
    end 
end

function DamageModule.getActiveView(self)
    return self.active_view
end

function DamageModule.renderCSS(self)
    local css = [[
    <style>
    svg {
    padding:10px;
} 
    .view {
    position:absolute;
    top:]]..MINHUD_top_position..[[px;
    left:]]..MINHUD_left_position..[[px;
}
    .dmgdotlabel {
    width:100%;
    text-align:center;
    font-size:1vh;
    font-weight:bold;

}
    ]]
    if MINHUD_show_txt_module == true then
        css=css..[[
        .title {
        font-size:1vh;
        text-align:center;
        font-weight:bold;
    }
        .r {
        text-align:right;
    }
        .dmgtxt {
        text-align:center;
        background-color: rgba(0, 0, 0, .4);
        width: 9vw;
        font-size:1vh;   
        position:absolute;
        left:]]..MINHUD_txt_module_left_pos..[[px;
        top:]]..MINHUD_txt_module_top_pos..[[px;
    }

        .pristine {
        color: #9BFFAC;
    }
        .ldmg {
        color: #FFDD8E;
    }
        .mdmg {
        color: #FF9E66;
    }
        .hdmg {
        color: #FF2819;
    }
        .dead {
        color: #7F120C;
    }]]
    end
    css=css..[[</style>]]
    return css
end

function DamageModule.renderHTML(self)
    local front_view_html = ""
    local side_view_html = ""
    local top_view_html = ""
    local table_view_html = ""
    if system.getTime() > self.last_time_updated + MINHUD_dmg_refresh_rate then
        --Data gathering
        local dead_elem_list=""
        local high_damage_list=""
        local medium_damage_list=""
        local light_damage_list=""
        local label_x = self.max_x-self.min_x
        local maxtoptv = -99999999999
        local maxtopfv = -99999999999
        local maxtopsv = -99999999999

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
                local color=""
                local opacity=0.2
                elem_hp_percentage = round(elem_hp_percentage)
                if elem_hp_percentage >= 100 then
                    color="#9BFFAC"
                elseif elem_hp_percentage >= 75 then
                    opacity=0.3
                    color="#FFDD8E"
                    if MINHUD_dmg_priority > 2 then
                        light_damage_list=light_damage_list..[[<tr class="ldmg"><td>]]..elem.elem_name..[[</td><td class="r">]]..elem_hp_percentage..[[%</td></tr>]]
                    end
                elseif elem_hp_percentage >= 50 then
                    color="#FF9E66"
                    opacity=0.4
                    if MINHUD_dmg_priority > 1 then
                        medium_damage_list=medium_damage_list..[[<tr class="mdmg"><td>]]..elem.elem_name..[[</td><td class="r">]]..elem_hp_percentage..[[%</td></tr>]]
                    end
                elseif elem_hp_percentage > 0 then
                    color="#FF2819"
                    opacity=0.5
                    high_damage_list=high_damage_list..[[<tr class="hdmg"><td>]]..elem.elem_name..[[</td><td class="r">]]..elem_hp_percentage..[[%</td></tr>]]
                elseif elem_hp_percentage == 0 then
                    color="#7F120C"
                    opacity=1
                    dead_elem_list=dead_elem_list..[[<tr class="dead"><td>]]..elem.elem_name..[[</td><td class="r">0%</td></tr>]]
                end
                local left = 0
                local top = 0
                -- We are using quadrants to place points correctly
                -- 1 2
                -- 3 4
                if (elem.elem_pos_x>=self.min_x and elem.elem_pos_x<=0) and (elem.elem_pos_y>=0 and elem.elem_pos_y<=self.max_y) then    
                    -- 1
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_y - elem.elem_pos_y
                elseif (elem.elem_pos_x>0 and elem.elem_pos_x<=self.max_x) and (elem.elem_pos_y>=0 and elem.elem_pos_y<=self.max_y) then    
                    -- 2
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_y - elem.elem_pos_y
                elseif (elem.elem_pos_x>=self.min_x and elem.elem_pos_x<=0) and (elem.elem_pos_y>=self.min_y and elem.elem_pos_y<0) then    
                    -- 3
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_y + (elem.elem_pos_y*-1)
                elseif (elem.elem_pos_x>0 and elem.elem_pos_x<=self.max_x) and (elem.elem_pos_y>=self.min_y and elem.elem_pos_y<0) then    
                    -- 4
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_y + (elem.elem_pos_y*-1)
                end    
                -- Top view x,y
                if maxtoptv < top then
                    maxtoptv = top
                end 
                top_view_html = top_view_html..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="5" fill="]]..color..[[" />]]
                -- Front view x,z
                if (elem.elem_pos_x>=self.min_x and elem.elem_pos_x<=0) and (elem.elem_pos_z>=0 and elem.elem_pos_z<=self.max_z) then    
                    -- 1
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_z - elem.elem_pos_z
                elseif (elem.elem_pos_x>0 and elem.elem_pos_x<=self.max_x) and (elem.elem_pos_z>=0 and elem.elem_pos_z<=self.max_z) then    
                    -- 2
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_z - elem.elem_pos_z
                elseif (elem.elem_pos_x>=self.min_x and elem.elem_pos_x<=0) and (elem.elem_pos_z>=self.min_z and elem.elem_pos_z<0) then    
                    -- 3
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_z + (elem.elem_pos_z*-1)
                elseif (elem.elem_pos_x>0 and elem.elem_pos_x<=self.max_x) and (elem.elem_pos_z>=self.min_z and elem.elem_pos_z<0) then    
                    -- 4
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_z + (elem.elem_pos_z*-1)
                end 
                if maxtopfv < top then
                    maxtopfv = top
                end 
                front_view_html = front_view_html..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="5" fill="]]..color..[[" />]]
                -- Side view y,z
                if (elem.elem_pos_y>=self.min_y and elem.elem_pos_y<=0) and (elem.elem_pos_z>=0 and elem.elem_pos_z<=self.max_z) then    
                    -- 1
                    left = (self.min_y*-1) + elem.elem_pos_y
                    top = self.max_z - elem.elem_pos_z
                elseif (elem.elem_pos_y>0 and elem.elem_pos_y<=self.max_y) and (elem.elem_pos_z>=0 and elem.elem_pos_z<=self.max_z) then    
                    -- 2
                    left = (self.min_y*-1) + elem.elem_pos_y
                    top = self.max_z - elem.elem_pos_z
                elseif (elem.elem_pos_y>=self.min_y and elem.elem_pos_y<=0) and (elem.elem_pos_z>=self.min_z and elem.elem_pos_z<0) then    
                    -- 3
                    left = (self.min_y*-1) + elem.elem_pos_y
                    top = self.max_z + (elem.elem_pos_z*-1)
                elseif (elem.elem_pos_y>0 and elem.elem_pos_y<=self.max_y) and (elem.elem_pos_z>=self.min_z and elem.elem_pos_z<0) then    
                    -- 4
                    left = (self.min_y*-1) + elem.elem_pos_y
                    top = self.max_z + (elem.elem_pos_z*-1)
                end 
                if maxtopsv < top then
                    maxtopsv = top
                end 
                side_view_html = side_view_html..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="5" fill="]]..color..[[" />]]
            end 
        end
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
        -- Top view code x,y
        top_view_html=[[<div class="view top_view"><svg width="1000" height="1000">]]..top_view_html
        if MINHUD_show_labels == true then
            top_view_html=top_view_html..[[<text x="]]..(label_x/2)+MINHUD_label_position..[[" y="]]..(maxtoptv+30)..[[" text-anchor="middle" font-family="sans-serif" font-size="14px" fill="white">TOP</text><text x="]]..(label_x/2)+MINHUD_label_position..[[" y="]]..(maxtoptv+45)..[[" text-anchor="middle" font-family="sans-serif" font-size="14px" fill="white">]]..filter_label..[[</text>]]
        end
        top_view_html=top_view_html..[[</svg></div>]]

        -- front view code x,z
        front_view_html=[[<div class="view front_view"><svg width="1000" height="1000">]]..front_view_html
        if MINHUD_show_labels == true then
            front_view_html=front_view_html..[[<text x="]]..(label_x/2)+MINHUD_label_position..[[" y="]]..(maxtopfv+30)..[[" text-anchor="middle" font-family="sans-serif" font-size="14px" fill="white">FRONT</text><text x="]]..(label_x/2)+MINHUD_label_position..[[" y="]]..(maxtopfv+45)..[[" text-anchor="middle" font-family="sans-serif" font-size="14px" fill="white">]]..filter_label..[[</text>]]
        end
        front_view_html=front_view_html..[[</svg></div>]]
        -- side view y,z
        side_view_html=[[<div class="view side_view"><svg width="1000" height="1000">]]..side_view_html
        if MINHUD_show_labels == true then
            side_view_html=side_view_html..[[<text x="]]..(label_x/2)+MINHUD_label_position..[[" y="]]..(maxtopsv+30)..[[" text-anchor="middle" font-family="sans-serif" font-size="14px" fill="white">SIDE</text><text x="]]..(label_x/2)+MINHUD_label_position..[[" y="]]..(maxtopsv+45)..[[" text-anchor="middle" font-family="sans-serif" font-size="14px" fill="white">]]..filter_label..[[</text>]]
        end    
        side_view_html=side_view_html..[[</svg></div>]]
        table_view_html = table_view_html..[[<div class="dmgtxt"><div class="title">Damage Report :<br>]]..filter_label..[[</div><hr><table style="width:100%;">]]..dead_elem_list..high_damage_list..medium_damage_list..light_damage_list..[[</table></div>]]
    end
    return {top_view_html,front_view_html,side_view_html,table_view_html}
end
