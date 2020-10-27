# DU-MINIMALIST-HUD
Hud project for Dual Universe with a fuel tank monitor and a damage report system

![hudimage](https://cdn.discordapp.com/attachments/761286504886173766/770416098264219658/unknown.png)

Features :
* Hide default fuel widgets if script is installed via autoconf
* Add a fuel tank monitor in the top left corner of the hud
* Add a ship layout based on the real position of your elements on your dynamic core
* Add a damage report list on the left of the hud
* Elements can be filtered (ALL,WEAPONS AND AVIONICS,AVIONICS ONLY,WEAPONS ONLY) by using option 1 key (ALT+1 by default)

How to use this script :
* You can use the autoconf to make a clean installation of the hud on a piloting seat (Cockpit not supported yet)
* You can also copy paste the code into a programming board to make an onboard HUD for your crew (Useful for reparations and refueling in PVP)
* For advanced lua coders : A function "renderHTML" will allow you to get an html string of the hud (position:absolute should allow for easy positionning)


Disclaimer : This is an early build, you may encounter some hud positionning problems (Large core not tested yet). if so, you can adjust all parameters from the lua parameter menu on your piloting seat

## Fuel module
### List of lua parameters
* fuel_module_active : Enable/Disable the fuel module
* fuel_module_posx : Fuel module position from the left side of the HUD
* fuel_module_posy : Fuel module position from the top side of the HUD
* fuel_module_refresh_rate : Fuel module refresh rate every x seconds (useful if you have performance issues) 
* fuel_module_show_remaining_time : If fuel is lasting more than x hours, do not show remaining time, 0 to always show remaining time. It shows 10 hours by default.

## Damage Report module
### List of lua parameters
* damagereport_module_active : Enable/Disable the damage report module
* damagereport_module_defaultFilter : Set the default filter when you start the script (1 for all,2 for avionics and weapons,3 for avionics only, 4 for weapons only)
* damagereport_ratio_modifier : Change the size of the ship layout, use positive or negative numbers to scale up or down (Please note that you will need to adjust the x,y position
* damagereport_x_pos_modifier : Change the x position of the ship layout
* damagereport_y_pos_modifier : Change the y position of the ship layout
* damagereport_rotate_x : Change the x rotation of the ship layout in degrees (0 for 2D)
* damagereport_rotate_y : Change the y rotation of the ship layout in degrees (0 for 2D)
* damagereport_rotate_z : Change the z rotation of the ship layout in degrees (0 for 2D)
* damagereport_txt_module_active : Enable the ship's damage text report
* damagereport_txt_posx : Damage text position from the left side of the HUD
* damagereport_txt_posy : Damage text position from the top side of the HUD 
* damagereport_txt_priority : Show damaged components (3) Below 100%, (2) Below 75%, (1) Below 50%
* damagereport_refresh_rate : Damage report refresh rate every x seconds (useful if you have performance issues) 
### Filters
You can use alt+1 (option1) to switch between filter modes
* ALL : Show all elements below 75% by default (You can adjust using the damagereport_txt_priority parameter)
* WP & AV : Show only weapons & avionics elements
* AVIONICS  : Show only avionics components (Wings, adjustors, vertical boosters, engines, fuel tanks, etc..)
* WEAPONS : Show only weapons

The dynamic core unit and resurection nodes will always be visible no matter what filter you have selected since they are really important.

## Lua scripting

### Fuel module script
Create a new fuel module :
```lua
fuel_module = FuelModule.new()
```
Get the html code of the module
```lua
fuel_html=fuel_module:renderHTML()
```

### Damage report module script
Create a new damage report module :
```lua
damage_html = DamageModule.new()
```
Get the html code of the module
```lua
damage_html=damage_rep:renderHTML()
```
Change the filter
```lua
damage_rep:nextFilter()
```

