functor
import
    Input
	OS
	System(show:Show)
export
    portPlayer:StartPlayer
define
	%%% Data %%%
	Map = Input.map
	NRow = Input.nRow
	NColumn = Input.nColumn
	ListMap
	%%% Player %%%
    StartPlayer % Port
    TreatStream % Manage Stream
	StateMod	% Merge State 
	%%% Strategy functions %%%
	InitPosition
	Move
		GetDirection
	ChargeItem
	FireItem
		GetItemsLoaded
		IsLoaded
	FireMine
	%%% Position Management %%%
	MapToList
	GenerateMapPosition
	GenerateManathanPosition
	GetValidPositionsOnMap
	GetValidPositionOnMap
	GetValidPosition
	GetValidPositions
	GetValidPosition2
	GetValidPositions2
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
	fun{StateMod State Fun}
		Rec = {Fun State}
		Label = {Record.label Rec}
		Arities = {Record.arity Rec}
		fun{Loop State Arities}
			case Arities of nil then State
			[] H|T andthen ({Not {Record.is Rec.H}} orelse {List.is Rec.H}) then 
				{Loop {Record.adjoin State Label(H:Rec.H)} T}
			[] H|T then
				{Loop {Record.adjoin State Label(H:{StateMod State.H fun{$ _} Rec.H end})} T}
			end
		end
	in
		{Loop State Arities}
	end

	fun{InitPosition ?ID ?Position}
		fun{$ Player}
			ID=Player.id
			Position = {GetValidPositionOnMap}
			player(position:Position path:Position|Player.path)
		end
	end

	fun{Move ID Position Direction}
		fun{$ Player} ValidPositions in
			ID = Player.id
			Position = {GetValidPosition2 Player.position 1 1 [{IsNotAlreadyGoThere Player}]}
			if Position == null then
				Direction=surface
				player(path: Player.position|nil)
			else 
				Direction = {GetDirection Player.position Position}
				player(position: Position path: Position|Player.path)
			end
		end
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

	fun{ChargeItem ?ID ?KindItem}
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

	fun{FireItem ?ID ?KindFire}
		fun{$ Player} ItemsLoaded Item MinePos Mines in
			ID = Player.id
			ItemsLoaded = {GetItemsLoaded Player}
			if {List.length ItemsLoaded} > 0 then
				Item = {GetRandElem ItemsLoaded}
				{Show item#Item#loaded#preparationToFire}
				case Item
				of mine then
					MinePos = {GetValidPosition2 Player.position Input.minDistanceMine Input.maxDistanceMine nil}
					KindFire = mine(MinePos)
				[] missile then KindFire = missile({GetValidPosition2 Player.position Input.minDistanceMissile Input.maxDistanceMissile nil})
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

	fun{FireMine ?ID ?Mine}
		fun{$ Player}
			ID = Player.id
			case Player.mines 
			of H|Mines then Ran = {OS.rand} mod 4 in
				if Ran == 0 then
					Mine=H
					{Show Player.id.color#fireMine#H}
					player(mines:Mines)
				end
			else Mine=null player()
			end
		end
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
		[] H|T andthen {F H} then H|{Filter T F}
		[] _|T then {Filter T F} end
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

	fun{GetValidPositionsOnMap} S in
		S = thread {GenerateMapPosition NRow NColumn} end
		{ApplyFilters [IsNotIsland] S}
	end

	fun{GetValidPositionOnMap}
		{GetRandElem {GetValidPositionsOnMap}}
	end

	fun{GenerateManathanPosition Position Min Max}
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

	fun{GetValidPositions Position Min Max Filters} S in
		S = thread {GenerateManathanPosition Position Min Max} end
		{ApplyFilters Filters S}
	end

	fun{GetValidPosition Position Min Max Filters}
		{GetRandElem {GetValidPositions Position Min Max Filters}}
	end

	fun{GetValidPositions2 Position Min Max Filters}
		NewFilters = IsInsideMap|IsNotIsland|Filters
	in
		{GetValidPositions Position Min Max NewFilters}
	end

	fun{GetValidPosition2 Position Min Max Filters}
		{GetRandElem {GetValidPositions2 Position Min Max Filters}}
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% UTIL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%

	fun{GetRandIndex L}
		{OS.rand} mod {List.length L} + 1
	end

	fun{GetRandElem L}
		if {List.length L} == 0 then null
		else {List.nth L {GetRandIndex L}} end
	end

%%%%%%%%%%%%%%%%%%%%%%%%%% CREATION OF PLAYER'S PORT AND LECTURE OF STREAM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fun{StartPlayer Color Id}
        Stream
        Port
		StateInitial=player(id:id(id:Id color:Color name:'Player')
							position: pt(x:0 y:0)
							path: nil
							domage:0 			% numbre of domage received
							surface:true		% true if the sub is on the surface
							mines:nil			% mines=[mine_1(<position),..., mine_n(<position)]
							load: items(mine:0 missile:0 drone:0  sonar:0)) % number of charge for each item
    in
		ListMap = {MapToList Map}
        {NewPort Stream Port}
        thread
            {TreatStream Stream StateInitial}
        end
        Port
    end

	proc{TreatStream Stream State}
		case Stream of nil then skip
		[] initPosition(?ID ?Position)|T then
			{TreatStream T {StateMod State {InitPosition ID Position}}}
		[] move(?ID ?Position ?Direction)|T then
			{TreatStream T {StateMod State {Move ID Position Direction}}}
		[] dive|T then
			{TreatStream T State}
		[] chargeItem(?ID ?KindItem)|T then
			{TreatStream T {StateMod State {ChargeItem ID KindItem}}}
		[] fireItem(?ID ?KindFire)|T then
			{TreatStream T {StateMod State {FireItem ID KindFire}}}
		[] fireMine(?ID ?Mine)|T then
			{TreatStream T {StateMod State {FireMine ID Mine}}}
		[] isDead(?Answer)|T then
			Answer = false
			{TreatStream T State}
		[] sayMove(ID Direction)|T then
			{TreatStream T State}
		[] saySurface(ID)|T then
			{TreatStream T State}
		[] sayCharge(ID KindItem)|T then
			{TreatStream T State}
		[] sayMinePlaced(ID)|T then
			{TreatStream T State}
		[] sayMissileExplode(ID Position ?Message)|T then
			Message=null
			{TreatStream T State}
		[] sayMineExplode(ID Position ?Message)|T then
			Message=null
			{TreatStream T State}
		[] sayPassingDrone(Drone ?ID ?Answer)|T then
			ID=null Answer=null
			{TreatStream T State}
		[] sayAnswerDrone(Drone ID Answer)|T then
			{TreatStream T State}
		[] sayPassingSonar(?ID ?Answer)|T then
			ID=null Answer=null
			{TreatStream T State}
		[] sayAnswerSonar(ID  Answer)|T then
			{TreatStream T State}
		[] sayDeath(ID)|T then
			{TreatStream T State}
		[] sayDamageTaken(ID Damage LifeLeft)|T then 
			{TreatStream T State}
		end
	end

end
