# astas   
MineTest Mods : Advanced Storage, Technic and Autocrafting System   
   
/!\--- ON CODING --- /!\   
not functionnal at all... 

--- Project ---   
ligth clone minecraft mods like AE2, IC2/GregTech5u, etc port to MT.
(rewrite from scratch)

aeme is a mass storage and a automatic crafting system   
ME Cable link node between us & make a distinct system (aka "MESystem")   
(only linked node with same cable "path" are in the same "MESystem")   
ME Storage can store large amound (million !) of items in 64 slots    
(a slot = items of same type (wear and meta inclued))    
/!\but lost all of items stored in if breaked/!\   
ME Controler can do several operation :   
- insert items thru the "MESystem" (the closer or free ME Storage)]   
- extract items   
- make a "autocrafting pattern"   
- autocrafting items (need ME crafting computer)   
ME Crafting computer can cascade crafting items by following "autocrafting pattern" rules :   
- extract items from ME storage,    
- send items to "crafting machine" etc...    
(all of this automatically !!!)    
    
ME "Crafting Machine" (ME Furnace, ME Grinder etc) are enumerated into "autocrafting formspec"   
    
"autocrafting formspec" is the formspec for build a "autocrafting pattern".   
"autocrafting pattern" determine how craft a specific items :   
something like this : send "1 iron ingot" into "grinder" to obtain "1 iron powder"  
ME Crafting computer following this rules and can cascade pattern   
("cascade pattern"= when 1 craft need a other craft)   

<troll mode="bashing">   
Why I haven't use greatest Pipeworks, digiline or technic MT mods ?   
pipeworks : My pipe/cable dont following same logic...       
digiline seen bit obscurated (no doc, no exemple etc)...   
and technic seen coded with <here>left foot</here>...   
in fact, I don't understand these code...   
</troll>   

#How u can help ?
#----------------
- I need texture for
	- me cable (soon nodeboxeditor.nbe)
	- me controler	
	
AbsPipes : [WIP]   
----------   
 - logical connection
 - propagation 
 - activation 
 - emerge node on propagation 
 - helper [partiel]    
 - wrapper (pipeworks interface) [if asked]
     
from AE2 (aka aeme): [WIP -- in rewrite ---]
----------   
  - ME Cable 
	- visual connection
	- propagation [abspipes vanilla]
  - ME Controler 
	- propagation
		- enumeration 
	- formspec 
		- "items storage list" (need ME Storage)
		- "crafting pattern" (need ME Crafting Computer)
		- "mass deposite" [on fire]
  - ME Storage [0%] <-- need reach 99% for ALPHA
	- propagation
		- enumeration 
		- items push (store) 
		- items pop (get) [on fire]
		- items purge [can wait]
		- items filter [later]
  - ME Crafting computer 		
  - ME Molecular assembler (aka autocrafter) [0%]   <-- need reach 99% for BETA   
  - ME Acces Control
  - ME Wifi base/terminal [0%] <-- need reach 99% for RC1   
  - ME LuaControler (like a light OC)   
  - ME Interface [if asked]  
  - ...   

         
from GT5u : (medium job)     
-----------     
   - electic cable    
   - steam generator (coal, lava, hot coolant, oil)    
   - turbine (steam, super steam)       
   - liquid pump     
   - elecric furnace    
   - macerator [0%] <-- need reach 99% for RC2   
   - extractor    
   - compressor [0%] <-- need reach 99% for Release V1       
   - washing machine    
   - centrifuge    
   - circuit printer (inscriber)    
   - thermal centrifuge    
   - chemical bath    
   - blast furnace (coal, coke, electric)      
   - explosion chamber   
   - chemical reactor  
   - oil liquid (mapgened liquid)    
   - oil processing    
   - liquid pump    
   - Nuclear reactor (cooled with fluid)    
   - ITER tokamac (fusion reactor) [multiblock ?)   
   - ...
   - PowerSuite (jetpack, ultra armor etc)    
   - quarry (node+liquid)    
   - tools (drill, laserminer, portable pump)    
   
from OC : (intermediat job)     
---------    
	- robot    
	
#Refer :
#-------------
AE2 : http://ae-mod.info/ by AlgorithmX2   
GT5u : (soon)


#--- LICENCES ---   
(A) RULEZ (no gov usage)        
CC BY SA NC   

(C)SJFN@ by foxz at free.fr

you can only use this mod in a "gratuit" server   
with donation but without pay-to-win (all form inclued voting gift)      
you can only speak about this mod on a "spam"-free webpage    
(or a discret 1/8 screen "spam", < 1Ko, no sound, non scam, non X, non gov)    

I don't make money with...   
dont make money with too...   
or share it with your "user" or why not ? with me...    
(but I cost a lot)    

if u follow this rules, dont ask me...
but I'm always happy to receive a email (or PM)...

except millions dollars : no exception.. don't ask !   
----------------   
   
Changelog :
2016/03/01	abspipes	add default handler to .on_check_pipe, .on_propagate & .set_faces     
2016/03/02	abspipes	rename .on_check_pipe to on_check
			abspipes	add pipes:register (without register_node)
			aeme		wip mecable, mecontroller
			abspipes	add on_propagate_finished
2016/03/03	abspipes	add pipes.propagate.kill (safethread ?)
			aeme		wip mestorage
2016/03/04	aeme		testing mecable + mecontroler interaction (visual+enum prop msg)= OK
2016/03/05	aeme		thinking on mestorage messaging exchange
2016/03/06	cloop		adding light oop like to lua
			*			rewrite all for inclued oop where is usefull/fun