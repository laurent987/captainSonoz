functor
import
    Input
	OS
	System(show:Show)
	PositionManager(mapToList:MapToList generateMapPosition:GenerateMapPosition generateManhattanPositions:GenerateManhattanPositions
		getPositionsOnMap:GetPositionsOnMap	getPositionOnMap:GetPositionOnMap getPositionAround:GetPositionAround
		getPositionsAround:GetPositionsAround getPositionAround2:GetPositionAround2	getPositionsAround2:GetPositionsAround2
		getManhattanDst:GetManhattanDst	getDirection:GetDirection keepDirection:KeepDirection) 
	Util(getRandIndex:GetRandIndex getRandElem:GetRandElem randomExcept:RandomExcept getItemsLoaded:GetItemsLoaded isLoaded:IsLoaded
		sayItemExplode:SayItemExplode damageSustained:DamageSustained)
	Filters(isInsideMap:IsInsideMap isNotIsland:IsNotIsland isNotAlreadyGoThere:IsNotAlreadyGoThere isNotOnEdge:IsNotOnEdge)
export
    portPlayer:StartPlayer
define
	%%% Data %%%
	Strategy % Record belongs all the function strategy
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
			if {IsLoaded Player Item Load} then 
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
			ItemsLoaded = {GetItemsLoaded Player Load}
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
end