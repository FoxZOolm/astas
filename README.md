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
- insert items 
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
"pattern" don't need to remake each time is used at all

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
	
AbsPipes : [80%]   
----------   
 - logical connection [finished]
 - propagation [80%]
 - activation [wip oop]
 - emerge node on propagation [finished]
 - helper [partiel]    
 - wrapper (pipeworks interface) [if asked]
     
from AE2 (aka aeme): [WIP -- in rewrite ---]
----------   
  - ME Cable [80%]
	- visual connection [finished]
	- propagation [abspipes vanilla]
  - ME Controler [wip oop]
	- propagation [wip 10%]
		- enumeration [wip 1%]
	- formspec
		- "main menu" [wip 1%]
		- "items storage list" (need ME Storage)
		- "crafting pattern" (need ME Crafting Computer)
		- "mass deposite" [on fire]
  - ME Storage [0%] <-- need reach 99% for ALPHA
	- propagation
		- enumeration [1%]
		- items push (store) [oop]
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
(A) RULEZ (no GOV usage, include EDU)        
CC BY SA NC   

(C)SJFN@ by foxz at free. fr

you can only use this mod in a "gratuit" server   
(or free-donation server)
no pay-to-win (all form inclued voting gift)      
you can only speak about this mod on a "spam"-free webpage    
(or a discret 1/8 screen "spam", < 1Ko, no sound, non scam, non X, non gov)    

I'm always happy to receive a email (or PM)...
but if u follow this rules, dont ask me...
except millions dollars : no exception.. don't ask !   
----------------   
   
	