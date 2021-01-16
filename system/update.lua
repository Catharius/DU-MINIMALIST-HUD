-- Copy and paste the code below at the end of update
-- Please note that if you already have a UI, you can add the desired ui part by finding system.setScreen and adding the html variable fuel_html or damage_html along with damage_css
-- For advanced lua coders, you can define your own css
-- (Disclaimer : i do not guaranty it will work fine with an other ui)
-- dmgrep:renderHTML() will return  all ui part {top_view_html,front_view_html,side_view_html,table_view_html}, example : dmgrep:renderHTML()[3] will return the side view part 

-- minimalistic hud
fuel_html=fm:renderHTML()
warp_html=wm:renderHTML()
wp_html=wp:renderHTML()
damage_html=dmgrep:renderHTML()
damage_css=dmgrep:renderCSS()
-- Show the selected view
i = dmgrep:getActiveView() 
txt_view = ""
if MINHUD_show_txt_module == true then
txt_view=damage_html[4]
end
system.setScreen(fuel_html..warp_html..damage_css..damage_html[i]..txt_view..wp_html)
