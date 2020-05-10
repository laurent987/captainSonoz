functor
import
	OS(rand:Rand)
export
   isTurnByTurn:IsTurnByTurn
   nRow:NRow
   nColumn:NColumn
   map:Map
   nbPlayer:NbPlayer
   players:Players
   colors:Colors
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   turnSurface:TurnSurface
   maxDamage:MaxDamage
   missile:Missile
   mine:Mine
   sonar:Sonar
   drone:Drone
   minDistanceMine:MinDistanceMine
   maxDistanceMine:MaxDistanceMine
   minDistanceMissile:MinDistanceMissile
   maxDistanceMissile:MaxDistanceMissile
   guiDelay:GUIDelay
   getRandMap:GetRandMap
define
   IsTurnByTurn
   NRow
   NColumn
   Alpha
   Map
   NbPlayer
   Players
   Colors
   ThinkMin
   ThinkMax
   TurnSurface
   MaxDamage
   Missile
   Mine
   Sonar
   Drone
   MinDistanceMine
   MaxDistanceMine
   MinDistanceMissile
   MaxDistanceMissile
   GUIDelay
   GenRandBinList
   GetBinNum
   GetRandMap
in

%%%% Style of game %%%%

   IsTurnByTurn = true

%%%% Description of the map %%%%

   NRow = 10
   NColumn = 10
   Alpha = 1

   Map = [[0 0 0 0 0 0 0 0 0 0]
	  [0 0 0 0 0 0 0 0 0 0]
	  [0 0 0 1 1 0 0 0 0 0]
	  [0 0 1 1 0 0 1 0 0 0]
	  [0 0 0 0 0 0 0 0 0 0]
	  [0 0 0 0 0 0 0 0 0 0]
	  [0 0 0 1 0 0 1 1 0 0]
	  [0 0 1 1 0 0 1 0 0 0]
	  [0 0 0 0 0 0 0 0 0 0]
	  [0 0 0 0 0 0 0 0 0 0]]


	fun{GetRandMap NRow NCol Alpha}
		fun{Loop N}
			if N==NRow then nil
			else {GenRandBinList NCol Alpha}|{Loop N+1}
			end
		end
	in
		{Loop 0}
	end

	fun{GenRandBinList Length Alpha}
		fun {Loop Length N}
			if Length==N then nil
			else {GetBinNum Alpha}|{Loop Length N+1}
			end
		end
	in
		{Loop Length 0}
	end

	fun{GetBinNum Alpha}
		Ran = 1 + {Rand} mod 100
	in
		case Alpha
		of 1 then if Ran < 20 then 1 else 0 end
		[] 2 then if Ran < 40 then 1 else 0 end
		[] 3 then if Ran < 60 then 1 else 0 end
		else  if Ran < 80 then 1 else 0 end
		end
	end



%%%% Players description %%%%

   NbPlayer = 3
   Players = [player054human player054smart player054smart]
   Colors = [yellow green blue]

%%%% Thinking parameters (only in simultaneous) %%%%

   ThinkMin = 500
   ThinkMax = 3000

%%%% Surface time/turns %%%%

   TurnSurface = 3

%%%% Life %%%%

   MaxDamage = 4

%%%% Number of load for each item %%%%

   Missile = 3
   Mine = 3
   Sonar = 3
   Drone = 3

%%%% Distances of placement %%%%

   MinDistanceMine = 1
   MaxDistanceMine = 2
   MinDistanceMissile = 1
   MaxDistanceMissile = 4

%%%% Waiting time for the GUI between each effect %%%%

   GUIDelay = 500 % ms

end
