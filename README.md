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

## Damage Report module

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

