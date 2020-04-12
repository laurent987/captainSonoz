functor
import
    Input
	OS
	System(show:Show)
export
    portPlayer:StartPlayer
define
	%%% Data %%%
	Strategy % Record belongs all the function strategy
	Map = Input.map
	NRow = Input.nRow
	NColumn = Input.nColumn
	ListMap
	DamageDstZero = 2 	% if the Manhattan distance, between the submarine and the explosion,  
	DamageDstOne = 1	% is 0 (resp. 1), the submarine gets 2 damages (resp. 1 damage).
	MinSecurityDstExplosion = 2 % if the dst between the submarine and explosion  is greater or egal to 2 then no damage 
	%%% Player %%%
    StartPlayer 
    TreatStream 
	MergeState
	%%% Util functions for Strategy functions %%%
	GetDirection
	GetItemsLoaded
	IsLoaded
	SayItemExplode
	DamageSustained
	%%% Position Management %%%
	MapToList
	GenerateMapPosition
	GenerateManhattanPositions
	GetPositionsOnMap
	GetPositionOnMap
	GetPositionAround
	GetPositionsAround
	GetPositionAround2
	GetPositionsAround2
	GetManhattanDst
	%%% Filters  %%%
	ApplyFilters
	FilterGeneric
	IsInsideMap
	IsNotIsland
	IsNotAlreadyGoThere
	%%% Util %%%
	GetRandIndex
	GetRandElem
	
in
	%%%%%%%%%%%%%%%%%%%%%%%%%% CREATION OF PLAYER'S PORT AND LECTURE OF STREAM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fun{StartPlayer Color Id}
        Stream
		StateInitial=player(
			id:id(id:Id color:Color name:'Player')
			position: pt(x:0 y:0)
			path: nil
			lifeLeft: Input.maxDamage  			
			surface:true		% true if the sub is on the surface
			mines:nil			% mines=[mine_1(<position),..., mine_n(<position)]
			load: items(mine:0 missile:0 drone:0  sonar:0)) % number of charge for each item
    in
		ListMap = {MapToList Map}
        thread {TreatStream Stream StateInitial} end
        {NewPort Stream}
    end

	proc{TreatStream Stream State}
		case Stream of nil then skip
		[] Msg|T then 
			NewSubsetState
			FunAnonyme
			Args = {List.append {Record.toList Msg} [FunAnonyme]}
			Fun = {Record.label Msg}
			{Show Args}
		in
			if {Value.hasFeature Strategy Fun} then  
				{Show ok}
				{Procedure.apply Strategy.Fun Args}
				{Show FunAnonyme}
				NewSubsetState = {FunAnonyme State}
				{Show NewSubsetState}
				{TreatStream T {MergeState State NewSubsetState}}
			else % Msg don't match with a strategy function.
				{Show what}
				{TreatStream T State}
			end
		end
	end

	fun{MergeState State NewSubsetState}
		Label = {Record.label NewSubsetState}
		Arities = {Record.arity NewSubsetState}
		fun{Loop State Arities}
			case Arities of nil then State
			[] H|T andthen ({Not {Record.is NewSubsetState.H}} orelse {List.is NewSubsetState.H}) then 
				{Loop {Record.adjoin
						State
						Label(H:NewSubsetState.H)} T}
			[] H|T then
				{Loop {Record.adjoin
						State
						Label(H:{MergeState State.H NewSubsetState.H})} T}
			end
		end
	in
		{Loop State Arities}
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Strategy functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Strategy = strategy(

    initPosition:
    fun{$ ?ID ?Position Player}
        ID=Player.id
        Position = {GetPositionOnMap [IsNotIsland NotOnEdge]}
        player(position:Position path:Position|Player.path)
    end

	dive:
	fun{$}
		fun{$ Player}
			player(surface:false)
		end
	end

move:
    fun{$ ID Position Direction}
		fun{$ Player} ValidPositions PosTmp in
			ID = Player.id
			PosTmp = {KeepDirection Player}
			if PosTmp \= null then
				Position = PosTmp
			else
				Position = {GetPositionAround2 Player.position 1 1 [{IsNotAlreadyGoThere Player}]}
			end
			if Position == null then
				Direction=surface
				player(surface:true path: Player.position|nil)
			else 
				Direction = {GetDirection Player.position Position}
				{Show dir#Direction}
				player(position:Position direction:Direction path:Position|Player.path)
			end
		end
    end
	
	chargeItem:
	fun{$ ?ID ?KindItem}
		fun{$ Player} Items Item NewLoad in
			ID = Player.id
			Items = {Record.arity Player.load}
			Item = {GetRandElem Items}
			NewLoad = Player.load.Item + 1
			if NewLoad mod Input.Item == 0 then KindItem = Item
			else KindItem = null end
			{Show Player.id.color#chargeItem#Item#NewLoad}
			player(load: items(Item:NewLoad))
		end
	end

	fireItem:
	fun{$ ?ID ?KindFire}
		fun{$ Player} ItemsLoaded Item MinePos Mines in
			ID = Player.id
			ItemsLoaded = {GetItemsLoaded Player}
			if {List.length ItemsLoaded} > 0 then
				Item = {GetRandElem ItemsLoaded}
				{Show item#Item#loaded#preparationToFire}
				case Item
				of mine then
					MinePos = {GetPositionAround2 Player.position Input.minDistanceMine Input.maxDistanceMine nil}
					KindFire = mine(MinePos)
				[] missile then KindFire = missile({GetPositionAround2 Player.position Input.minDistanceMissile Input.maxDistanceMissile nil})
				[] drone then KindFire = drone(row 3)
				[] sonar then KindFire = sonar
				end
				{Show Player.id.color#fireItem#Item}
				if {IsDet MinePos} then Mines = MinePos|Player.mines
				else Mines = Player.mines end

				player(load:items(Item:Player.load.Item - Input.Item) mines:Mines)
			else 
				KindFire = null
				player()
			end
		end
	end

	fireMine:
	fun{$ ?ID ?Mine}
		fun{$ Player}
			ID = Player.id
			case Player.mines 
			of H|Mines andthen {OS.rand} mod 4 == 0 then
				Mine=H
				{Show Player.id.color#fireMine#H}
				player(mines:Mines)
			else Mine=null player()
			end
		end
	end

	isDead:
	fun {$ ?Answer}
		fun{$ Player}
			Answer = Player.lifeLeft =< 0
			player()
		end
	end

	sayMove:
	fun {$ ID Direction}
		fun{$ Player}
			player()
		end
	end

	saySurface:
	fun {$ ID}
		fun{$ Player}
			player()
		end
	end

	sayCharge:
	fun {$ ID KindItem}
		fun{$ Player}
			player()
		end
	end

	sayMinePlaced:
	fun {$ ID}
		fun{$ Player}
			player()
		end
	end

	sayMissileExplode:
	fun{$ ID Position ?Message}
		fun{$ Player} NewLifeLeft in
			NewLifeLeft = {SayItemExplode Player Position ?Message}
			player(lifeLeft: NewLifeLeft) 	
		end		
	end
	
	sayMineExplode:
	fun{$ ID Position ?Message}
		fun{$ Player} NewLifeLeft in
			NewLifeLeft = {SayItemExplode Player Position ?Message}
			player(lifeLeft: NewLifeLeft)
		end
	end

	sayPassingDrone:
	fun{$ Drone ?ID ?Answer}
		fun{$ Player}
			ID = Player.id
			Answer = false
			player()
		end
	end

	sayAnswerDrone:
	fun{$ Drone ID Answer}
		fun{$ Player}
			player()
		end
	end

	sayPassingSonar:
	fun{$ ?ID ?Answer}
		fun{$ Player}
			ID = Player.id
			Answer = pt(x: Player.position.x y: 3)
			player()
		end
	end

	sayAnswerSonar:
	fun{$ ID Answer}
		fun{$ Player}
			player()
		end
	end

	sayDeath:
	fun{$ ID}
		fun{$ Player}
			player()
		end
	end

	sayDamageTaken:
	fun{$ ID Damage LifeLeft}
		fun{$ Player}
			player()
		end
	end)


%%%%%%%%%%%%%%%%%%%%%%%%%%%% Util function for Strategy functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%

	fun{GetItemsLoaded Player}
		fun{Loop Player Items}
			case Items of nil then nil
			[] Item|T andthen {IsLoaded Player Item} then Item|{Loop Player T}
			[] _|T then {Loop Player T} end		
		end
	in
		{Loop Player {Record.arity Player.load}}
	end

	fun{IsLoaded Player Item}
		Player.load.Item >= Input.Item
	end

	fun{KeepDirection Player}
        Pos 
        pt(x:X y:Y) = Player.position
    in
        {Show Player.direction}
        case Player.direction
        of west then Pos = pt(x:X y:Y-1)
        [] north then Pos = pt(x:X-1 y:Y)
        [] east then Pos = pt(x:X y:Y+1)
        [] sud then Pos = pt(x:X+1 y:Y)
        else Pos = null
        end
        {Show oldPos#Player.position#newPos#Pos}
        if (Pos \= null
            andthen {IsInsideMap Pos}
            andthen {IsNotIsland Pos}
            andthen {{IsNotAlreadyGoThere Player} Pos}) then
                {Show pos#Pos}
                Pos
        else null end
    end

	fun{GetDirection CurrentPosition NextPosition}
		pt(x:Cx y:Cy) = CurrentPosition
		pt(x:Nx y:Ny) = NextPosition
	in
		case (Nx-Cx)#(Ny-Cy)
		of 0#~1 then west
		[] ~1#0 then north
		[] 0#1 then east
		else south end
	end

	fun{SayItemExplode Player Position ?Message} Damage NewLifeLeft in
		Damage = {DamageSustained Player Position}
		NewLifeLeft = Player.lifeLeft - Damage
		if NewLifeLeft =< 0 then Message = sayDeath(Player.id)
		elseif Damage == 0 then	Message = null
		else Message = sayDamageTaken(Player.id Damage NewLifeLeft) end
		NewLifeLeft 			
	end

	fun{DamageSustained Player PositionExplosion}
		case {GetManhattanDst Player.position PositionExplosion}
		of 0 then DamageDstZero
		[] 1 then DamageDstOne
		else 0 end
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% FILTERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	fun{ApplyFilters Filters Ys}
		thread
			case Filters of nil then Ys
			[] Filter|Fs then Zs in
				Zs = {FilterGeneric Ys Filter}
				{ApplyFilters Fs Zs}
			end 
		end
	end

	fun{FilterGeneric Ys F}
		case Ys of nil then nil
		[] H|T andthen {F H} then H|{FilterGeneric T F}
		[] _|T then {FilterGeneric T F} end
	end 

	fun{IsInsideMap Position}
		pt(x:X y:Y) = Position
	in
		0 < X andthen X =< NRow andthen 0 < Y andthen Y =< NRow
	end

	fun{IsNotIsland Position}
		pt(x:X y:Y) = Position
	in
		{List.nth ListMap (X-1)*NColumn + Y} == 0
	end

	fun{NotOnEdge Position}
        pt(x:X y:Y) = Position
    in
        X \= NRow andthen Y \= NColumn
    end


	fun{IsNotAlreadyGoThere Player}
		fun{$ Position}
			fun{Loop Path Position}
				case Path of nil then true
				[] H|T andthen H\=Position then {Loop T Position}
				else false end
			end
		in
			{Loop Player.path Position}
		end			
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Position Management %%%%%%%%%%%%%%%%%%%%%%%%%%%%

	fun{MapToList Map}
		fun{GetRow Row X}
			case Row of nil then X
			[] H|T then H|{GetRow T X}
			end
		end
		proc{Loop Rows R}
			case Rows of nil then R=nil
			[] List|End then X in 
				R = {GetRow List X}
				{Loop End X}
			end
		end
	in
		{Loop Map $}
	end

	fun{GenerateMapPosition Row Col}
		fun{Loop I J}
			if I == Row+1 then nil
			elseif J == Col+1 then {Loop I+1 1}
			else pt(x:I y:J)|{Loop I J+1} end  
		end
	in
		{Loop 1 1}
	end

	fun{GetPositionsOnMap Filters} S in
		S = thread {GenerateMapPosition NRow NColumn} end
		{ApplyFilters Filters S}
	end

	fun{GetPositionOnMap Filters}
		{GetRandElem {GetPositionsOnMap Filters}}
	end

	fun{GenerateManhattanPositions Position Min Max}
		pt(x:X y:Y) = Position
		fun{Loop Min Max I J} NextPos=pt(x:X+I y:Y+J) in
			if I == Max+1 then nil
			elseif J == Max+1 then {Loop Min Max I+1 ~Max}
			elseif {Abs I}+{Abs J} =< Max andthen {Abs I}+{Abs J} >= Min then
				NextPos|{Loop Min Max I J+1}
			else {Loop Min Max I J+1} end
		end
	in
		{Loop Min Max ~Max ~Max}
	end

	fun{GetPositionsAround Position Min Max Filters} S in
		S = thread {GenerateManhattanPositions Position Min Max} end
		{ApplyFilters Filters S}
	end

	fun{GetPositionAround Position Min Max Filters}
		{GetRandElem {GetPositionsAround Position Min Max Filters}}
	end

	fun{GetPositionsAround2 Position Min Max Filters}
		NewFilters = IsInsideMap|IsNotIsland|Filters
	in
		{GetPositionsAround Position Min Max NewFilters}
	end

	fun{GetPositionAround2 Position Min Max Filters}
		{GetRandElem {GetPositionsAround2 Position Min Max Filters}}
	end

	fun{GetManhattanDst P1 P2}
		pt(x:X1 y:Y1) = P1
		pt(x:X2 y:Y2) = P2
	in
		{Abs X1-X2} + {Abs Y1-Y2}
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% UTIL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%

	fun{GetRandIndex L}
		{OS.rand} mod {List.length L} + 1
	end

	fun{GetRandElem L}
		if {List.length L} == 0 then null
		else {List.nth L {GetRandIndex L}} end
	end
end