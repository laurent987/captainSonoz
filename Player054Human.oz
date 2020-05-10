functor
import
	QTk at 'x-oz://system/wp/QTk.ozf'
    Input
	OS
	System(show:Show)
	PositionManager(mapToList:MapToList generateMapPosition:GenerateMapPosition generateManhattanPositions:GenerateManhattanPositions
		getPositionsOnMap:GetPositionsOnMap	getPositionOnMap:GetPositionOnMap getPositionAround:GetPositionAround
		getPositionsAround:GetPositionsAround getPositionAround2:GetPositionAround2	getPositionsAround2:GetPositionsAround2
		getManhattanDst:GetManhattanDst	getDirection:GetDirection) 
	Util(getRandIndex:GetRandIndex getRandElem:GetRandElem randomExcept:RandomExcept getItemsNoCreated:GetItemsNoCreated getItemsCreated:GetItemsCreated isCreated:IsCreated
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
	Damages = damages(0:DamageDstZero 1:DamageDstOne)
	MinSecurityDstExplosion = 2 % if the dst between the submarine and explosion  is greater or egal to 2 then no damage
	Handles

	%%% Player %%%
    StartPlayer 
    TreatStream
	TreatStreamEvent 
	MergeState
	GetNewSubsetState
	IsAboutDrone
	AskID
	IsDead
	BoundId

	%%% Event %%%
	PortEvent
	Init
	Move
	LoadItem
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
			dead:false  			
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
		case Stream
		of nil then skip
		[] Msg|T then NewSubsetState in
			NewSubsetState = {GetNewSubsetState Msg State}
			{TreatStream T {MergeState State NewSubsetState} State}
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
			[] H|T andthen {{IsNotIsland ListMap NColumn} pt(x:H.row y:H.col)} then
				{H.h set(bg:c(59 77 117))}
				{Loop T}
			[] _|T then {Loop T}
			end	 
		end
	in
		{Show validPos#ValidPos}
		{Wait ValidPos}
		{Show validPos#ValidPos}
		{Loop SquareHandles}
	end
	
	proc{SetSquareAround Pos Min Max Filters Proc}
		{Show pos#Pos}
		{Show min#Min}
		{Show max#Max}
		{Show filters#Filters}
		{Show map#Map}
		ValidPos = {GetPositionsAround2 Pos Min Max Filters Map}
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

	proc{LoadItem X}
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
			{Wait Position}
			thread {SetSquareAround Position 1 1 [{IsNotAlreadyGoThere Player.path}] Move} end
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
			{SetSquareAround Player.position 1 1 [{IsNotAlreadyGoThere Player.path}] Move}
			{Send PortEvent get(move(Position))}
			if Position == null then
				Direction=surface
				thread {Handles.action remove(Handles.map)} end
				player(surface:true path:Player.position|nil)
			else 
				Direction = {GetDirection Player.position Position}
				thread {Handles.action remove(Handles.map)} end
				thread {SetSquareAround Position 1 1 [{IsNotAlreadyGoThere Player.path}] Move} end
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
			if NewLoad mod Input.Item == 0 then KindItem = Item
			else KindItem = null end
			{Show Player.id.color#chargeItem#Item#NewLoad}
			{Handles.action remove(Handles.load)}
			thread {SetSquareAround Player.position 1 1 [{IsNotAlreadyGoThere Player.path}] Move} end
			player(load:items(Item:NewLoad))
		end
	end

	fireItem:
	fun{$ ?ID ?KindFire}
		fun{$ Player} ItemsCreated Item MinePos Mines in
			ItemsCreated = {GetItemsCreated Player Load}	
			if {List.length ItemsCreated} > 0 then
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
				thread {SetSquareAround Player.position 1 1 [{IsNotAlreadyGoThere Player.path}] Move} end
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
						thread {SetSquareAround Player.position 1 1 [{IsNotAlreadyGoThere Player.path}] Move} end
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
		fun{$ Player} player() end
	end

	saySurface:
	fun {$ ID}
		fun{$ Player} player() end
	end

	sayCharge:
	fun {$ ID KindItem}
		fun{$ Player} player() end
	end

	sayMinePlaced:
	fun {$ ID}
		fun{$ Player} player() end
	end

	sayMissileExplode:
	fun{$ ID Position ?Message}
		fun{$ Player}
			{SayItemExplode Player Position Damages ?Message}
		end		
	end
	
	sayMineExplode:
	fun{$ ID Position ?Message}
		fun{$ Player} S in 
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
		fun{$ Player} player() end
	end

	sayPassingSonar:
	fun{$ ?ID ?Answer}
		fun{$ Player}
			Answer = pt(x:Player.position.x y:{RandomExcept 1 NRow Player.position.y})
			player()
		end
	end

	sayAnswerSonar:
	fun{$ ID Answer}
		fun{$ Player} player() end
	end

	sayDeath:
	fun{$ ID}
		fun{$ Player} player() end
	end

	sayDamageTaken:
	fun{$ ID Damage LifeLeft}
		fun{$ Player} player() end
	end)

end