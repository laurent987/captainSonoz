functor
import
	QTk at 'x-oz://system/wp/QTk.ozf'
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
	Handles
	%%% Player %%%
    StartPlayer 
    TreatStream
	TreatStreamEvent 
	MergeState
	PortEvent
	Init
	Move
	Load
	Fire
	FireMine
	%%% Window %%%
	SquareHandles
	SetSquare
	SetSquareAround
	BuildMap
	UpdateGUI
	InitLoadGUI
	InitInfoGUI
	BuildWindow
	BuildLoad
	BuildFire
	BuildExplode
	DrawMap
	Squares
	Label
	MapGUI
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
	AddToEnd
	
in
	%%%%%%%%%%%%%%%%%%%%%%%%%% CREATION OF PLAYER'S PORT AND LECTURE OF STREAM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fun{StartPlayer Color Id}
        Stream
		StreamEvent
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
		Handles = {BuildWindow}
		PortEvent = {NewPort StreamEvent}
		{BuildMap}
		{BuildLoad}
		{BuildFire}
		{BuildExplode}
		{InitInfoGUI}
		thread {TreatStreamEvent StreamEvent} end
        thread {TreatStream Stream StateInitial null} end
        {NewPort Stream}
    end

	proc{TreatStream Stream State PrevState}
		{UpdateGUI State PrevState}
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
				{TreatStream T {MergeState State NewSubsetState} State}
			else % Msg don't match with a strategy function.
				{TreatStream T State State}
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
	proc{InitInfoGUI}
		{Handles.info configure({Label 'lifeLeft'} row:0 column:0 sticky:wesn)}
		{Handles.info configure({Label Input.maxDamage} row:0 column:1 sticky:wesn)}
		{InitLoadGUI [mine missile drone sonar] 1}
	end

	proc{InitLoadGUI Items N}
		case Items of nil then skip
		[] H|T then 
			{Handles.info configure({Label H} row:N column:0 sticky:wesn)}
			{Handles.info configure({Label 0} row:N column:1 sticky:wesn)}
			{Handles.info configure({Label sur} row:N column:2 sticky:wesn)}
			{Handles.info configure({Label Input.H} row:N column:3 sticky:wesn)}
			{InitLoadGUI T N+1}
		end
	end

	proc{UpdateGUI State PrevState}
		if PrevState==null then skip
		else 
			if State.lifeLeft \= PrevState.lifeLeft then
				{Handles.info configure({Label State.lifeLeft} row:0 column:1)}
			end
			if State.load.mine \= PrevState.load.mine then
				{Handles.info configure({Label State.load.mine} row:1 column:1)}
			end
			if State.load.missile \= PrevState.load.missile then
				{Handles.info configure({Label State.load.missile} row:2 column:1)}
			end
			if State.load.drone \= PrevState.load.drone then
				{Handles.info configure({Label State.load.drone} row:3 column:1)}
			end
			if State.load.sonar \= PrevState.load.sonar then
				{Handles.info configure({Label State.load.sonar} row:4 column:1)}
			end
		end
	end
	
	fun{BuildWindow}
		HAction HStep HInfo HLayout
		Toolbar Layout DescStep DescAction DescInfo Window
	in
		Toolbar=lr(glue:we tbbutton(text:"Quit" glue:w action:toplevel#close))
		Layout=grid(handle:HLayout height:50 width:80 glue:wesn)
		DescStep=label(handle:HStep font:{QTk.newFont font(size:18)} height:2 width:50 bg:white glue:wesn)
		DescAction=grid(handle:HAction height:40 width:50 bg:red glue:wesn)
		DescInfo=grid(handle:HInfo bg:green glue:wesn)
		Window={QTk.build td(Toolbar Layout)}
  
		{Window show}
		{HLayout rowconfigure(0 minsize:50 weight:0 pad:5)}

		{HLayout columnconfigure(0 minsize:50 weight:2 pad:5)}
		{HLayout columnconfigure(1 minsize:30 weight:2 pad:5)}

		{HLayout configure(td(DescStep DescAction glue:wesn) row:0 column:0 sticky:wesn)}
		{HLayout configure(DescInfo row:0 column:1 sticky:wesn)}
		{HAction rowconfigure(0 weight:2)}
		{HAction columnconfigure(0 weight:2)}

		handle(action:HAction step:HStep info:HInfo map:_ load:_ fire:_ explode:_)
	end

	proc{BuildMap} HMap in
		MapGUI = grid(handle:HMap highlightthickness:0)
		Handles.map = HMap
		{Handles.action configure(MapGUI row:0 column:0)}
		% configure rows and set headers
		{HMap rowconfigure(1 minsize:50 weight:0 pad:5)}
		for N in 1..NRow do
			{HMap rowconfigure(N+1 minsize:50 weight:0 pad:5)}
			{HMap configure({Label N} row:N+1 column:1 sticky:wesn)}
		end
		% % configure columns and set headers
		{HMap columnconfigure(1 minsize:50 weight:0 pad:5)}
		for N in 1..NColumn do
			{HMap columnconfigure(N+1 minsize:50 weight:0 pad:5)}
			{HMap configure({Label N} row:1 column:N+1 sticky:wesn)}
		end
		{DrawMap HMap}
		{AddToEnd SquareHandles nil}
	end

	proc{BuildLoad} HLoad LoadGUI in
		LoadGUI = listbox(glue:wesn height:40 font:{QTk.newFont font(size:16)}
					init:["Mine" "Missile" "Drone" "Sonar"]
					handle:HLoad
					action:
						proc{$} X Item in
							X = {HLoad get(firstselection:$)}
							case X 
							of 1 then Item=mine
							[] 2 then Item=missile
							[] 3 then Item=drone
							[] 4 then Item=sonar
							end
 							{Show Item}
							{Send PortEvent set(load(Item))}
						end
						)
		{Handles.action configure(LoadGUI row:0 column:0 sticky:wesn)}
		{Handles.action remove(HLoad)}
		Handles.load=HLoad
	end

	proc{BuildFire} HFire FireGUI in
		FireGUI = listbox(glue:wesn height:40 font:{QTk.newFont font(size:16)}
					init:["Mine" "Missile" "Drone" "Sonar"]
					handle:HFire
					action:
						proc{$} X Item in
							X = {HFire get(firstselection:$)}
							case X 
							of 1 then Item=mine
							[] 2 then Item=missile
							[] 3 then Item=drone
							[] 4 then Item=sonar
							end
							{Send PortEvent set(fire(Item))}
						end
						)
		{Handles.action configure(FireGUI row:0 column:0 sticky:wesn)}
		{Handles.action remove(HFire)}
		Handles.fire=HFire
	end

	proc{BuildExplode} HExplode ExplodeGUI in
		ExplodeGUI = listbox(glue:wesn height:40 font:{QTk.newFont font(size:16)}
						init:["Yes" "No"]
						handle:HExplode
						action:
							proc{$} X in 
								case {HExplode get(firstselection:$)}
								of 1 then X=true
								else X=false end
								{Send PortEvent set(mine(X))}
							end
						)
		{Handles.action configure(ExplodeGUI row:0 column:0 sticky:wesn)}
		{Handles.action remove(HExplode)}
		Handles.explode=HExplode
	end

	%%%%% Squares of water and island
	fun {Squares T Handle}
		case T 
		of 0 then label(handle:Handle text:"" width:1 height:1 bg:c(102 102 255))
		[] 1 then label(handle:Handle text:"" borderwidth:5 relief:raised width:1 height:1 bg:c(153 76 0))
		end
	end

	%%%%% Labels for rows and columns
	fun{Label V}
		label(text:V borderwidth:5 relief:raised bg:c(255 51 51) ipadx:5 ipady:5)
	end

	%%%%% Function to draw the map
	proc{DrawMap Grid}
		proc{DrawColumn Column M N}
			case Column
			of nil then skip
			[] T|End then Handle in
				{Grid configure({Squares T Handle} row:M+1 column:N+1 sticky:wesn)}
				if T==0 then {Handle bind(event:"<1>" args:[int(M) int(N)] action:Init)} end
				{AddToEnd SquareHandles rec(h:Handle row:M col:N)}
				{DrawColumn End M N+1}
			end
		end
		proc{DrawRow Row M}
			case Row
			of nil then skip
			[] T|End then
				{DrawColumn T M 1}
				{DrawRow End M+1}
			end
		end
	in
		{DrawRow Map 1}
	end

	proc{AddToEnd L E}
		if {Not {IsDet L}} andthen E\=nil then L = E|_ end
		case L of nil then skip
		[] _|T andthen {Not {IsDet T}} andthen E==nil then T = E
		[] _|T andthen {Not {IsDet T}} then T = E|_
		[] _|T then {AddToEnd T E}
		else skip end
	end

	proc{SetSquare ValidPos Proc}
		proc{Loop Handles}
			case Handles of nil then skip
			[] H|T andthen {List.member pt(x:H.row y:H.col) ValidPos} then
				{H.h set(bg:c(102 102 255))}
				{H.h bind(event:"<1>" args:[int(H.row) int(H.col)] action:Proc)}
				{Loop T}
			[] H|T andthen {IsNotIsland pt(x:H.row y:H.col)} then
				{H.h set(bg:c(59 77 117))}
				{Loop T}
			[] _|T then {Loop T}
			end	 
		end
	in
		{Loop SquareHandles}
	end
	
	proc{SetSquareAround Pos Min Max Filters Proc}
		ValidPos = {GetPositionsAround2 Pos Min Max Filters}
	in
		{SetSquare ValidPos Proc}
	end


%%%%%%%%%%%%%%%%%%%%%%%%%%%% Strategy functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%

	proc{Init X Y}
		{Send PortEvent set(init(pt(x:X y:Y)))}
	end

	proc{Move X Y}
		{Show x#X#and#y#Y}
		{Send PortEvent set(move(pt(x:X y:Y)))}
	end

	proc{Fire X Y}
		{Send PortEvent set(fire(pt(x:X y:Y)))}
	end

	proc{FireMine X Y}
		{Send PortEvent set(mine(pt(x:X y:Y)))}
	end

	proc{Load X}
		{Send PortEvent set(load(X))}
	end
		
	proc {TreatStreamEvent Stream}
		proc{Loop S State}
			case S of Msg|T then
				case Msg
				of get(M) then Label in
					Label = {Record.label M}
					M.1 = State.Label
					{Loop T State}	
				[] set(M) then Label in
					Label = {Record.label M}
					State.Label = M.1
					{Loop T {Record.adjoin State state(Label:_)}}
				end
			end 
		end
	in
		{Loop Stream state(init:_ move:_ load:_ fire:_ mine:_)}
	end

	Strategy = strategy(

	initPosition:
	fun{$ ?ID ?Position}
		fun{$ Player}
			{Handles.step set("Choose your initial position")}
			{Send PortEvent get(init(Position))}
			ID=Player.id
			{Wait Position}
			thread {SetSquareAround Position 1 1 [{IsNotAlreadyGoThere Player}] Move} end
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
		fun{$ Player}
			{Show player#Player}
			{Handles.action configure(Handles.map row:0 column:0)}
			{Handles.step set("Choose your next position")}
			{SetSquareAround Player.position 1 1 [{IsNotAlreadyGoThere Player}] Move}
			{Send PortEvent get(move(Position))}
			ID = Player.id
			if Position == null then
				Direction=surface
				thread {Handles.action remove(Handles.map)} end
				player(surface:true path:Player.position|nil)
			else 
				Direction = {GetDirection Player.position Position}
				thread {Handles.action remove(Handles.map)} end
				thread {SetSquareAround Position 1 1 [{IsNotAlreadyGoThere Player}] Move} end
				player(position: Position path:Position|Player.path)
			end
		end
	end
	
	chargeItem:
	fun{$ ?ID ?KindItem}
		fun{$ Player} Items Item NewLoad in
			{Handles.step set("Load one item")}
			{Handles.action configure(Handles.load row:0 column:0)}
			{Send PortEvent get(load(Item))}
			NewLoad = Player.load.Item + 1
			ID = Player.id
			if NewLoad mod Input.Item == 0 then KindItem = Item
			else KindItem = null end
			{Show Player.id.color#chargeItem#Item#NewLoad}
			{Handles.action remove(Handles.load)}
			thread {SetSquareAround Player.position 1 1 [{IsNotAlreadyGoThere Player}] Move} end
			player(load:items(Item:NewLoad))
		end
	end

	fireItem:
	fun{$ ?ID ?KindFire}
		fun{$ Player} ItemsLoaded Item MinePos Mines in
			ItemsLoaded = {GetItemsLoaded Player}	
			ID = Player.id
			if {List.length ItemsLoaded} > 0 then
				{Handles.step set("Select an item to fire")}
				{Handles.action configure(Handles.fire row:0 column:0)}
				{Send PortEvent get(fire(Item))}
				case Item
				of mine then
					{Handles.action remove(Handles.fire)}
					{Handles.step set("Select a position to place the mine")}
					{Handles.action configure(Handles.map)}
					{SetSquareAround Player.position Input.minDistanceMine Input.maxDistanceMine nil Fire}
					{Send PortEvent get(fire(MinePos))}
					{Wait MinePos}
					{Handles.action remove(Handles.map)}
					KindFire = mine(MinePos)
				[] missile then  MissilePos in
					{Handles.action remove(Handles.fire)}
					{Handles.step set("Select a position to fire the missile")}
					{Handles.action configure(Handles.map)}
					{SetSquareAround Player.position Input.minDistanceMissile Input.maxDistanceMissile nil Fire}
					{Send PortEvent get(fire(MissilePos))}
					{Wait MissilePos}
					{Handles.action remove(Handles.map)}					
					KindFire = missile(MissilePos)
				[] drone then KindFire = drone(row 3)
				[] sonar then KindFire = sonar
				end
				if {IsDet MinePos} then Mines = MinePos|Player.mines
				else Mines = Player.mines end
				{Handles.action remove(Handles.fire)}
				thread {SetSquareAround Player.position 1 1 [{IsNotAlreadyGoThere Player}] Move} end
				player(load:items(Item:Player.load.Item - Input.Item) mines:Mines)
			else 
				{Handles.step set("Waiting others players")}
				KindFire = null
				player()
			end
		end
	end

	fireMine:
	fun{$ ?ID ?Mine}
		fun{$ Player}
			ID=Player.id
			if Player.mines \= nil then MinePos WannaExplode in
				{Handles.step set("Do you want to explode a mine ?")}
				{Handles.action configure(Handles.explode row:0 column:0)}
				{Send PortEvent get(mine(WannaExplode))}
				if WannaExplode then 
					{Handles.step set("Select a mine to fire")}
					{Handles.action remove(Handles.explode)}
					{Handles.action configure(Handles.map row:0 column:0)}
					{SetSquare Player.mines FireMine}
					{Send PortEvent get(mine(MinePos))}
					if {List.member MinePos Player.mines} then Mines in
						Mine = MinePos
						Mines = {List.subtract Player.mines MinePos}
						thread {SetSquareAround Player.position 1 1 [{IsNotAlreadyGoThere Player}] Move} end
						player(mines:Mines)
					else Mine=null player() end
				else
					{Handles.action remove(Handles.explode)} 
					Mine=null player()
				end
			else
				{Handles.action remove(Handles.explode)}
				Mine=null player()
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
		0 < X andthen X =< NRow andthen 0 < Y andthen Y =< NColumn
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
		{Show streamAround#S}
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