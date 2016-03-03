# astas   
MineTest Mods : Advanced Storage and Autocrafting System   
   
/!\--- ON CODING --- /!\   
not functionnal at all... 

--- Project ---   
ligth port minecraft mods like AE2, IC2/GregTech5u, etc to MT.
(rewrite from scratch)


AbsPipes :    
----------   
 - logical connection [finished]
 - propagation [finished]   
 - activation [finished]        
 - emerge node on propagation [finished]
 - helper [partiel]    
 - wrapper (pipeworks interface) [if asked]

     
from AE2 : (huge job)    
----------   
  - ME Cable [WIP-50%]
  - ME Controler  (crafting terminal inclued) [WIP-10%]     
  - ME Driver [on fire]    
  - ME Drive (items, liquids, nrj) [on fire]   
  - ME Interface [if asked]  
  - ME Molecular assembler (aka autocrafter)   
  - ME LuaControler (like ligth OC)   
  - ...   

         
from GT5u : (medium job)     
-----------     
   - steam generator (coal, lava, hot coolant, oil)    
   - turbine (steam, super steam)    
   - electic cable    
   - liquid pipe     
   - elecric furnace    
   - macerator    
   - washing machine    
   - extractor    
   - compressor      
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
   - ITER tokamac (fusion reactor)    
   - ...
   - PowerSuite (jetpack, ultra armor etc)    
   - quarry (node+liquid)    
   - tools (drill, laserminer, portable pump)    
   
from OC : (intermediat job)     
---------    
	- robot    
   
Like I think my mods, no one machine need mesecon or pipeworks (or other)  

Changelog :
2016/03/01-21:47	abspipes	add default handler to .on_check, .on_propagate & .set_faces     
2016/03/02-21:37	abspipes	rename .on_check_pipe to on_check
					abspipes	add pipes:register (without register_node)
					aeme		wip mecable, mecontroller
					abspipes	add on_propagate_finished