-- Copy and paste the code below at the end of update
-- Please note that if you already have a UI, you can add the desired ui part by finding system.setScreen and adding the html variable fuel_html or damage_html
-- (i do not guaranty it will work fine with an other ui)
fuel_html=fm:renderHTML()
damage_html=dmgrep:renderHTML()
system.setScreen(fuel_html..damage_html)
system.showScreen(1)
