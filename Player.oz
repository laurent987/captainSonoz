functor
import
    Input
	OS
	System(show:Show)
	PositionManager(mapToList:MapToList generateMapPosition:GenerateMapPosition generateManhattanPositions:GenerateManhattanPositions
		getPositionsOnMap:GetPositionsOnMap	getPositionOnMap:GetPositionOnMap getPositionAround:GetPositionAround
		getPositionsAround:GetPositionsAround getPositionAround2:GetPositionAround2	getPositionsAround2:GetPositionsAround2
		getManhattanDst:GetManhattanDst	getDirection:GetDirection)
	Util(getRandIndex:GetRandIndex getRandElem:GetRandElem getItemsLoaded:GetItemsLoaded isLoaded:IsLoaded
		sayItemExplode:SayItemExplode damageSustained:DamageSustained)
	Filters(isInsideMap:IsInsideMap isNotIsland:IsNotIsland isNotAlreadyGoThere:IsNotAlreadyGoThere)
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
	MinSecurityDstExplosion = 2 % if the dst between the submarine and explosion  is greater or egal to 2 then no damage 
	%%% Player %%%
    StartPlayer 
    TreatStream 
	MergeState
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
		in
			if {Value.hasFeature Strategy Fun} then  
				{Procedure.apply Strategy.Fun Args}
				NewSubsetState = {FunAnonyme State}
				{TreatStream T {MergeState State NewSubsetState}}
			else % Msg don't match with a strategy function.
				{TreatStream T State}
			end
		end
	end

	fun{MergeState State NewSubsetState}
		Label = {Record.label NewSubsetState}
		Arities = {Record.arity NewSubsetState}
		fun{Loop State Arities}
			case Arities of nil then State
			[] H|T andthen (
					{Atom.is NewSubsetState.H} 
					orelse {List.is NewSubsetState.H}
					orelse {Not {Record.is NewSubsetState.H}}) then
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
	fun{$ ?ID ?Position}
		fun{$ Player}
			ID=Player.id
			Position = {GetPositionOnMap Map [{IsNotIsland ListMap NColumn}]}
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
		fun{$ Player} ValidPositions in
			ID = Player.id
			Position = {GetPositionAround2 Player.position 1 1 [{IsNotAlreadyGoThere Player.path}] Map}
			if Position == null then
				Direction=surface
				player(surface:true path: Player.position|nil)
			else 
				Direction = {GetDirection Player.position Position}
				player(position: Position path: Position|Player.path)
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
			ItemsLoaded = {GetItemsLoaded Player Load}
			if {List.length ItemsLoaded} > 0 then
				Item = {GetRandElem ItemsLoaded}
				{Show item#Item#loaded#preparationToFire}
				case Item
				of mine then
					MinePos = {GetPositionAround2 Player.position Input.minDistanceMine Input.maxDistanceMine nil Map}
					KindFire = mine(MinePos)
				[] missile then KindFire = missile({GetPositionAround2 Player.position Input.minDistanceMissile Input.maxDistanceMissile nil Map})
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
			NewLifeLeft = {SayItemExplode Player Position damages(0:DamageDstZero 1:DamageDstOne) ?Message}
			player(lifeLeft: NewLifeLeft) 	
		end		
	end
	
	sayMineExplode:
	fun{$ ID Position ?Message}
		fun{$ Player} NewLifeLeft in
			NewLifeLeft = {SayItemExplode Player Position damages(0:DamageDstZero 1:DamageDstOne) ?Message}
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
end