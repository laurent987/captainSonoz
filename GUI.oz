functor
import
	QTk at 'x-oz://system/wp/QTk.ozf'
	Input
	System(show:Show)
export
	portWindow:StartWindow
define

	StartWindow
	TreatStream

	RemoveItem
	RemovePath
	RemovePlayer

	Map = Input.map

	NRow = Input.nRow
	NColumn = Input.nColumn

	DrawSubmarine
	MoveSubmarine
	DrawMine
	RemoveMine
	DrawOneSegmentOfPath
	UpdatePath
	RemovePathTmp
	DrawPath


	BuildWindow
	Handles
	Port
	AddPlayerToPathDisplay
	BuildPathWidget

	Label
	Squares
	DrawMap

	StateModification
	NewState

	UpdateLife
in

	proc{AddPlayerToPathDisplay Grid ID}
		{Grid.path insert('end' [ID.color])}
	end

	proc{BuildPathWidget Handle}
		{Handle bind(event:"<1>"
					action:
						proc{$} X Color in
							X = {Handle get(firstselection:$)}
							Color = {List.nth {Handle get(1:$)} X}
							{Send Port displayPath(Color)}
						end
		)}
	end

%%%%% Build the initial window and set it up (call only once)
	fun{BuildWindow}
		Grid GridScore Path Toolbar Desc DescScore DescPath Window
	in
		Toolbar=lr(glue:we tbbutton(text:"Quit" glue:w action:toplevel#close))
		Desc=grid(handle:Grid height:500 width:500)
		DescScore=grid(handle:GridScore height:100 width:500)
		DescPath=dropdownlistbox(handle:Path init:[all])
		Window={QTk.build td(Toolbar Desc lr(DescScore DescPath))}
		{Window show}

		% configure rows and set headers
		{Grid rowconfigure(1 minsize:50 weight:0 pad:5)}
		for N in 1..NRow do
			{Grid rowconfigure(N+1 minsize:50 weight:0 pad:5)}
			{Grid configure({Label N} row:N+1 column:1 sticky:wesn)}
		end
		% configure columns and set headers
		{Grid columnconfigure(1 minsize:50 weight:0 pad:5)}
		for N in 1..NColumn do
			{Grid columnconfigure(N+1 minsize:50 weight:0 pad:5)}
			{Grid configure({Label N} row:1 column:N+1 sticky:wesn)}
		end
		% configure scoreboard
		{GridScore rowconfigure(1 minsize:50 weight:0 pad:5)}
		for N in 1..(Input.nbPlayer) do
			{GridScore columnconfigure(N minsize:50 weight:0 pad:5)}
		end

		{DrawMap Grid}
		{BuildPathWidget Path}

		handle(grid:Grid score:GridScore path:Path)
	end

%%%%% Squares of water and island
	Squares = square(0:label(text:"" width:1 height:1 bg:c(102 102 255))
			 1:label(text:"" borderwidth:5 relief:raised width:1 height:1 bg:c(153 76 0))
			)

%%%%% Labels for rows and columns
	fun{Label V}
		label(text:V borderwidth:5 relief:raised bg:c(255 51 51) ipadx:5 ipady:5)
	end

%%%%% Function to draw the map
	proc{DrawMap Grid}
		proc{DrawColumn Column M N}
			case Column
			of nil then skip
			[] T|End then
				{Grid configure(Squares.T row:M+1 column:N+1 sticky:wesn)}
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

%%%%% Init the submarine
	fun{DrawSubmarine Grid ID Position}
		Handle HandlePath HandleScore X Y Id Color LabelSub LabelScore
	in
		pt(x:X y:Y) = Position
		id(id:Id color:Color name:_) = ID

		LabelSub = label(text:"S" handle:Handle borderwidth:5 relief:raised bg:Color ipadx:5 ipady:5)
		LabelScore = label(text:Input.maxDamage borderwidth:5 handle:HandleScore relief:solid bg:Color ipadx:5 ipady:5)
		HandlePath = path(handle:{DrawOneSegmentOfPath Grid Color X Y} x:X y:Y)
		{Grid.grid configure(LabelSub row:X+1 column:Y+1 sticky:wesn)}
		{Grid.score configure(LabelScore row:1 column:Id sticky:wesn)}
		{HandlePath.handle 'raise'()}
		{Handle 'raise'()}
		guiPlayer(id:ID score:HandleScore submarine:Handle mines:nil path:HandlePath|nil drawPath:true)
	end

	fun{MoveSubmarine Position}
		fun{$ Grid State}
			ID HandleScore Handle Mine Path NewPath DrawPath X Y
		in
			guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path drawPath:DrawPath) = State
			pt(x:X y:Y) = Position
			NewPath = path(handle:{DrawOneSegmentOfPath Grid ID.color X Y} x:X y:Y)
			if {Not DrawPath} then 
				{Grid.grid remove(NewPath.handle)}
				{Grid.grid remove(Handle)}
			else
				{Grid.grid remove(Handle)}
				{Grid.grid configure(Handle row:X+1 column:Y+1 sticky:wesn)}
			end
			{NewPath.handle 'raise'()}
			{Handle 'raise'()}
			guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:NewPath|Path drawPath:DrawPath)
		end
	end
  
	fun{DrawMine Position}
		fun{$ Grid State}
			ID HandleScore Handle Mine Path LabelMine HandleMine Bool X Y
			in
			guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path drawPath:Bool) = State
			pt(x:X y:Y) = Position
			LabelMine = label(text:"M" handle:HandleMine borderwidth:5 relief:raised bg:ID.color ipadx:5 ipady:5)
			if Bool then {Grid.grid configure(LabelMine row:X+1 column:Y+1)} end
			{HandleMine 'raise'()}
			{Handle 'raise'()}
			guiPlayer(id:ID score:HandleScore submarine:Handle mines:mine(HandleMine Position)|Mine path:Path drawPath:Bool) 
		end
	end

	local
		fun{RmMine Grid Position List}
			case List
			of nil then nil
			[] H|T then
				if (H.2 == Position) then
					{RemoveItem Grid H.1}
					T
				else
					H|{RmMine Grid Position T}
				end
			end
		end
	in
		fun{RemoveMine Position}
			fun{$ Grid State}
				ID HandleScore Handle Mine Path NewMine Bool
			in
				guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path drawPath:Bool) = State
				NewMine = {RmMine Grid Position Mine}
				guiPlayer(id:ID score:HandleScore submarine:Handle mines:NewMine path:Path drawPath:Bool)
			end
		end
	end

	proc{UpdatePath Selected Grid State}
		for Player in State do
			if Selected=={Atom.toString all} then {DrawPath Grid Player}
			elseif Selected=={Atom.toString Player.id.color} then {DrawPath Grid Player}
			else {RemovePathTmp Grid Player} end
		end
	end

	proc{DrawPath Grid Player}
		for Path in Player.path do
			{Grid.grid configure(Path.handle row:Path.x+1 column:Path.y+1)}
		end
	end
	
	fun{DrawOneSegmentOfPath Grid Color X Y}
		Handle LabelPath
	in
		LabelPath = label(text:"**" handle:Handle bg:Color)
		{Grid.grid configure(LabelPath row:X+1 column:Y+1)}
		Handle
	end
	
	proc{RemoveItem Grid Handle}
		{Grid.grid forget(Handle)}
	end

	proc{RemovePathTmp Grid Player}
		for P in Player.path do
			{Grid.grid remove(P.handle)}
		end
	end
		
	fun{RemovePath Grid State}
		ID HandleScore Handle Mine Path Bool
	in
		guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path drawPath:Bool) = State
		for P in Path.2 do
	 {RemoveItem Grid P.handle}
		end
		guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path.1|nil drawPath:Bool)
	end

	fun{UpdateLife Life}
		fun{$ Grid State}
			HandleScore
			in
			guiPlayer(id:_ score:HandleScore submarine:_ mines:_ path:_ drawPath:_) = State
			{HandleScore set(Life)}
	 		State
		end
	end


	fun{StateModification Grid WantedID State Fun}
		case State
		of nil then nil
		[] guiPlayer(id:ID score:_ submarine:_ mines:_ path:_ drawPath:_)|Next then
			if (ID == WantedID) then
				{Fun Grid State.1}|Next
			else
				State.1|{StateModification Grid WantedID Next Fun}
			end
		end
	end

	fun{RemovePlayer Grid WantedID State}
		case State
		of nil then nil
		[] guiPlayer(id:ID score:HandleScore submarine:Handle mines:M path:P drawPath:_)|Next then
			if (ID == WantedID) then
				{HandleScore set(0)}
				for H in P do
			 		{RemoveItem Grid H.handle}
				end
				for H in M do
			 		{RemoveItem Grid H.1}
				end
				{RemoveItem Grid Handle}
				Next
			else
				State.1|{RemovePlayer Grid WantedID Next}
			end
		end
	end

	fun{NewState IDColor State}
		case State
		of nil then nil
		[] guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path drawPath:Bool)|Next then
			if ({Atom.toString ID.color} == IDColor) orelse {Atom.toString all} == IDColor then
				guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path drawPath:true)|{NewState IDColor State.2}
			else guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path drawPath:false)|{NewState IDColor State.2}
			end
		end
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	fun{StartWindow}
		Stream
	in
		{NewPort Stream Port}
		thread
			{TreatStream Stream nil nil}
		end
		Port
	end

	proc{TreatStream Stream Grid State}
		case Stream
		of nil then skip
		[] buildWindow|T then NewGrid in
			NewGrid = {BuildWindow}
			{TreatStream T NewGrid State}
		[] displayPath(IDColor)|T then 
			{UpdatePath IDColor Grid State}
			{TreatStream T Grid {NewState IDColor State}}
		[] initPlayer(ID Position)|T then NewState in
			NewState = {DrawSubmarine Grid ID Position}
			{AddPlayerToPathDisplay Grid ID}
			{TreatStream T Grid NewState|State}
		[] movePlayer(ID Position)|T then
			{TreatStream T Grid {StateModification Grid ID State {MoveSubmarine Position}}}
		[] lifeUpdate(ID Life)|T then
			{TreatStream T Grid {StateModification Grid ID State {UpdateLife Life}}}
		[] putMine(ID Position)|T then 
			{TreatStream T Grid {StateModification Grid ID State {DrawMine Position}}}
		[] removeMine(ID Position)|T then
			{TreatStream T Grid {StateModification Grid ID State {RemoveMine Position}}}
		[] surface(ID)|T then
			{TreatStream T Grid {StateModification Grid ID State RemovePath}}
		[] removePlayer(ID)|T then
			{TreatStream T Grid {RemovePlayer Grid ID State}}
		[] explosion(ID Position)|T then
			{TreatStream T Grid State}
		[] drone(ID Drone)|T then
			{TreatStream T Grid State}
		[] sonar(ID)|T then
			{TreatStream T Grid State}
		[] _|T then
			{TreatStream T Grid State}
		end
	end
end
