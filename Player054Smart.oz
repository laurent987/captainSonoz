functor
import
    Input
	OS
	System(show:Show)
export
    portPlayer:StartPlayer
define
	%%% Data %%%
	Strategy % Record belongs all the functions strategy
	Map = Input.map
	NRow = Input.nRow
	NColumn = Input.nColumn
	Load=load(missile:Input.missile mine:Input.mine sonar:Input.sonar drone:Input.drone)
	ListMap
	DamageDstZero = 2 	% if the Manhattan distance, between the submarine and the explosion,  
	DamageDstOne = 1	% is 0 (resp. 1), the submarine gets 2 damages (resp. 1 damage).
	Damages = damages(0:DamageDstZero 1:DamageDstOne)
	MinSecurityDstExplosion = 2 % if the dst between the submarine and explosion  is greater or egal to 2 then no damage 
	
	%%% Player %%%
    StartPlayer 
    TreatStream 
	MergeState
	GetNewSubsetState
	IsAboutDrone
	AskID
	IsDead
	BoundId

	%%% PositionManager %%%
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
	GetDirection
	KeepDirection
	GetNRow
	GetNColumn

	%%% Filter %%%
	ApplyFilters
	FilterGeneric
	IsInsideMap
	IsNotIsland
	IsNotAlreadyGoThere
	IsNotOnEdge

	%%% Util %%%
	GetRandIndex
	GetRandElem
	RandomExcept
	GetItemsNoCreated
	GetItemsCreated
	IsCreated
	SayItemExplode
	DamageSustained
in
	%%%%%%%%%%%%%%%%%%%%%%%%%% CREATION OF PLAYER'S PORT AND LECTURE OF STREAM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fun{StartPlayer Color Id}
        Stream
		StateInitial=player(
			id:id(id:Id color:Color name:'Player2')
			position:pt(x:0 y:0)
			direction:null
			path:nil
			dead:false
			lifeLeft: Input.maxDamage  			
			surface:true		% true if the sub is on the surface
			mines:nil			% mines=[mine_1(<position),..., mine_n(<position)]
			load:items(mine:0 missile:0 drone:0  sonar:0)) % number of charge for each item
    in
		ListMap = {MapToList Map}
        thread {TreatStream Stream StateInitial} end
        {NewPort Stream}
    end

	proc{TreatStream Stream State}
		case Stream
		of nil then skip
		[] Msg|T then NewSubsetState in
			NewSubsetState = {GetNewSubsetState Msg State}
			{TreatStream T {MergeState State NewSubsetState}}
		end
	end

	fun{GetNewSubsetState Msg State}
		NewSubsetState
		FunAnonyme
		Args = {List.append {Record.toList Msg} [FunAnonyme]}
		Fun = {Record.label Msg}
	in
		{BoundId Args Msg State}
		if {Value.hasFeature Strategy Fun} 
			andthen ({Not {IsDead State}} orelse {Record.label Msg} == isDead) then 
			{Procedure.apply Strategy.Fun Args}
			{FunAnonyme State}
		else player() end
	end

	fun{MergeState State NewSubsetState}
		Label = {Record.label NewSubsetState}
		Arities = {Record.arity NewSubsetState}
		fun{Loop State Arities}
			case Arities of nil then State
			[] H|T andthen {Not {List.is NewSubsetState.H}}
					andthen {Record.is NewSubsetState.H} then
				{Loop {Record.adjoin
						State
						Label(H:{MergeState State.H NewSubsetState.H})} T}
			[] H|T then
				{Loop {Record.adjoin
						State
						Label(H:NewSubsetState.H)} T}
			end
		end
	in
		{Loop State Arities}
	end

	fun{IsAboutDrone Msg} Lb = {Record.label Msg} in
		Lb==sayPassingDrone orelse Lb==sayAnswerDrone
	end

	fun{AskID Msg} Lb = {Record.label Msg} in
		Lb==initPosition orelse Lb==move orelse Lb==chargeItem orelse Lb==fireItem orelse Lb==fireMine
		orelse Lb==sayPassingDrone orelse Lb==sayPassingSonar
	end

	fun{IsDead Player}
		Player.dead
	end

	proc{BoundId Args Msg State}
		if {IsDead State} andthen {AskID Msg} then
			if {IsAboutDrone Msg} then Args.2.1 = null
			else Args.1 = null end
		elseif {Not {IsDead State}} andthen {AskID Msg} then
			if {IsAboutDrone Msg} then Args.2.1 = State.id
			else Args.1 = State.id end
		end
	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Strategy functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Strategy = strategy(

    initPosition:
    fun{$ ?ID ?Position}
		fun{$ Player}
			Position = {GetPositionOnMap Map [{IsNotIsland ListMap NColumn} {IsNotOnEdge Map}]}
			player(position:Position path:Position|Player.path)
		end
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
			PosTmp = {KeepDirection Player Map}
			if PosTmp \= null then
				Position = PosTmp
			else
			Position = {GetPositionAround2 Player.position 1 1 [{IsNotAlreadyGoThere Player.path}] Map}
			end
			if Position == null then
				{Show '|_______'#Player.id.color#makeSurface}
				Direction=surface
				player(surface:true path: Player.position|nil)
			else 
				Direction = {GetDirection Player.position Position}
				{Show '|_______'#Player.id.color#goTo#Direction#'in'#Position}
				player(position:Position direction:Direction path:Position|Player.path)
			end
		end
	end
	
	chargeItem:
	fun{$ ?ID ?KindItem}
		fun{$ Player} Items Item NewLoad in
			Item = mine
			if {IsCreated Player Item Load} then 
				KindItem = null
				player()
			else 
				NewLoad = Player.load.Item + 1
				{Show '|_______'#Player.id.color#chargeItem#Item#NewLoad}
				if NewLoad == Input.Item then 
					{Show '|_______'#Player.id.color#createdItem#Item#NewLoad}
					KindItem = Item
				else KindItem = null end
				player(load:items(Item:NewLoad))
			end
		end
	end

	fireItem:
	fun{$ ?ID ?KindFire}
		fun{$ Player} ItemsLoaded Item MinePos Mines in
			ItemsLoaded = {GetItemsCreated Player Load}
			if {List.length ItemsLoaded} > 0 then
				Item = {GetRandElem ItemsLoaded}
				case Item
				of mine then
					MinePos = {GetPositionAround2 Player.position Input.minDistanceMine Input.maxDistanceMine nil Map}
					KindFire = mine(MinePos)
				[] missile then KindFire = missile({GetPositionAround2 Player.position Input.minDistanceMissile Input.maxDistanceMissile nil Map})
				[] drone then KindFire = drone(row 3)
				[] sonar then KindFire = sonar
				end
				{Show '|_______'#Player.id.color#fireItem#Item}
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
			case Player.mines 
			of H|Mines 
					andthen {OS.rand} mod 3 == 0 
					andthen {GetManhattanDst H Player.position} >= MinSecurityDstExplosion
					then
				Mine=H
				{Show '|_______'#Player.id.color#fireMine#H}
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
			{SayItemExplode Player Position Damages ?Message} 	
		end		
	end
	
	sayMineExplode:
	fun{$ ID Position ?Message}
		fun{$ Player} NewLifeLeft in
			{SayItemExplode Player Position Damages ?Message} 	
		end		
	end

	sayPassingDrone:
	fun{$ Drone ?ID ?Answer}
		fun{$ Player}
			case Drone.1
			of row then Answer = Drone.2 == Player.position.x
			[] column then Answer = Drone.2 == Player.position.y
			end
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
			Answer = pt(x:{RandomExcept 1 NColumn Player.position.x} y:Player.position.y)
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Position Manager %%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

	fun{GetPositionsOnMap Map Filters} S in
		S = thread {GenerateMapPosition {GetNRow Map} {GetNColumn Map}} end
		{ApplyFilters Filters S}
	end

	fun{GetPositionOnMap Map Filters}
		{GetRandElem {GetPositionsOnMap Map Filters}}
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
		S = {GenerateManhattanPositions Position Min Max}
		{ApplyFilters Filters S}
	end

	fun{GetPositionAround Position Min Max Filters}
		{GetRandElem {GetPositionsAround Position Min Max Filters}}
	end

	fun{GetPositionsAround2 Position Min Max Filters Map}
		NewFilters = {IsInsideMap Map}
					|{IsNotIsland {MapToList Map} {GetNColumn Map}}
					|Filters
	in
		{GetPositionsAround Position Min Max NewFilters}
	end

	fun{GetPositionAround2 Position Min Max Filters Map}
		{GetRandElem {GetPositionsAround2 Position Min Max Filters Map}}
	end

	fun{GetManhattanDst P1 P2}
		pt(x:X1 y:Y1) = P1
		pt(x:X2 y:Y2) = P2
	in
		{Abs X1-X2} + {Abs Y1-Y2}
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

	fun{GetNRow Map}
		{List.length Map}
	end

	fun{GetNColumn Map}
		{List.length Map.1}
	end

	fun{KeepDirection Player Map}
        Pos 
        pt(x:X y:Y) = Player.position
    in
        case Player.direction
        of west then Pos = pt(x:X y:Y-1)
        [] north then Pos = pt(x:X-1 y:Y)
        [] east then Pos = pt(x:X y:Y+1)
        [] south then Pos = pt(x:X+1 y:Y)
        else Pos = null
        end
        if (Pos \= null
            	andthen {{IsInsideMap Map} Pos}
            	andthen {{IsNotIsland {MapToList Map} {GetNColumn Map}} Pos}
            	andthen {{IsNotAlreadyGoThere Player.path} Pos}) then
            Pos
        else
			null
		end
    end	


%%%%%%%%%%%%%%%%%%%%%%%%%%%% Filters %%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
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

	fun{IsInsideMap Map}
		fun{$ Position}
			NRow = {List.length Map}
			NColumn = {List.length Map.1}
			pt(x:X y:Y) = Position
		in
			0 < X andthen X =< NRow andthen 0 < Y andthen Y =< NColumn
		end
	end

	fun{IsNotIsland ListMap NColumn}
		fun{$ Position}
			pt(x:X y:Y) = Position
		in
			{List.nth ListMap (X-1)*NColumn + Y} == 0
		end
	end

	fun{IsNotAlreadyGoThere Path}
		fun{$ Position}
			fun{Loop Path Position}
				case Path of nil then true
				[] H|T andthen H\=Position then {Loop T Position}
				else false end
			end
		in
			{Loop Path Position}
		end			
	end

	fun{IsNotOnEdge Map}
		fun{$ Position}
			pt(x:X y:Y) = Position
		in
			X > 1 andthen X < {GetNRow Map} andthen Y > 1 andthen Y < {GetNColumn Map}
		end
	end


%%%%%%%%%%%%%%%%%%%%%%%%%%%% Util %%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	fun{GetRandIndex L}
		{OS.rand} mod {List.length L} + 1
	end

	fun{GetRandElem L}
		if {List.length L} == 0 then null
		else {List.nth L {GetRandIndex L}} end
	end

	fun{RandomExcept Min Max NumNotAccepted}
		L = {List.subtract {List.number Min Max 1} NumNotAccepted}
	in
		{GetRandElem L}
	end

	fun{GetItemsNoCreated Player Load}
		fun{Loop Player Items}
			case Items of nil then nil
			[] Item|T andthen {Not {IsCreated Player Item Load}} then Item|{Loop Player T}
			[] _|T then {Loop Player T} end		
		end
	in
		{Loop Player {Record.arity Player.load}}
	end

	fun{GetItemsCreated Player Load}
		fun{Loop Player Items}
			case Items of nil then nil
			[] Item|T andthen {IsCreated Player Item Load} then Item|{Loop Player T}
			[] _|T then {Loop Player T} end		
		end
	in
		{Loop Player {Record.arity Player.load}}
	end

	fun{IsCreated Player Item Load}
		Player.load.Item >= Load.Item
	end

	fun{SayItemExplode Player Position Damages ?Message} 
		if Player.dead then 
			Message=null
			player()
		else Damage NewLifeLeft in
			Damage={DamageSustained Damages Player Position} 
			NewLifeLeft = Player.lifeLeft - Damage
			if NewLifeLeft =< 0 then
				Message = sayDeath(Player.id)
				player(dead:true lifeLeft:NewLifeLeft)
			elseif Damage == 0 then
				Message = null
				player()
			else 
				Message = sayDamageTaken(Player.id Damage NewLifeLeft)
				player(lifeLeft:NewLifeLeft)
			end
		end
					
	end

	fun{DamageSustained Damages Player PositionExplosion}
		Dst = {GetManhattanDst Player.position PositionExplosion}
	in
		if{Value.hasFeature Damages Dst} then Damages.Dst
		else 0 end
	end
end