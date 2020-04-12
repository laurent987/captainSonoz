functor
import
    GUI
    Input
    PlayerManager
	System(show:Show)
	OS
define
	PlayerList
	GUI_port
	X
	proc {SimultateThinking}
		{Delay Input.thinkMin + {OS.rand} mod (Input.thinkMax - Input.thinkMin)}
	end
	proc {NewGameTurnBased PlayerList}
		proc {LoopGame PlayerList} 
			if {Length PlayerList} > 1 then
				{LoopGame {RoundTable PlayerList PlayerList}}
			else
				{Show 'the end'#PlayerList}
			end
		end
		% PlayersLeft is a List with the Player who don't play yet in this round table.
		% PL is the List of All the players alive
		fun {RoundTable PlayersLeft PL}
			case PlayersLeft of nil then nil
			[] P|Pr andthen {Send P.port isDead($)} then {RoundTable Pr PL}
			[] P|Pr andthen X in (X=P.turnToWait)>0 then
				{Record.adjoin P player(turnToWait: X-1)}|{RoundTable Pr PL}
			[] P|Pr then {PlayTurn P PL}|{RoundTable Pr PL}
			end
		end
		fun {PlayTurn Player PlayerList} Dir in
			{Delay 50}
			if Player.surface then {Send Player.port dive} end
			Dir = {Move Player PlayerList}
			if Dir==surface then
				{Record.adjoin Player player(turnToWait: Input.turnSurface surface:true)}
			else
				{ChargeItem Player PlayerList}
				{FireItem Player PlayerList}
				{FireMine Player PlayerList}
				Player
			end
		end
	in
		{LoopGame PlayerList}
	end
	proc {NewGameRealTime PlayerList}
		for Player in PlayerList do
			proc{Loop Player} Dead in
				{Send Player.port isDead(?Dead)}
				if Dead then skip
				else Dir in 
					if Player.surface then {Send Player.port dive} end
					{SimultateThinking}
					Dir = {Move Player PlayerList}
					if Dir==surface then 
						{Delay Input.turnSurface*1000}
						{Loop {Record.adjoin Player player(surface:true)}}
					else
						{SimultateThinking}
						{ChargeItem Player PlayerList}
						{SimultateThinking}
						{FireItem Player PlayerList}
						{SimultateThinking}
						{FireMine Player PlayerList}
						{Loop Player}				
					end
				end					
			end
		in
			thread {Loop Player} end
		end
	end
    fun {GeneratePlayers}
        fun {Loop PlayerList ColorList IdNum}
            if IdNum > Input.nbPlayer then nil
            else		
                case PlayerList#ColorList of (H1|T1)#(H2|T2) then 
                    if (Input.isTurnByTurn) then 
                        player( port:{PlayerManager.playerGenerator H1 H2 IdNum}
								id: IdNum
								surface:true
                                turnToWait:0)|{Loop T1 T2 IdNum+1}
                    else
                        player(	port:{PlayerManager.playerGenerator H1 H2 IdNum}
								surface:true)|{Loop T1 T2 IdNum+1} 
                    end
                end
            end
        end
    in
        {Loop Input.players Input.colors 1}
    end
	proc {InitPlayer Player}
		PlayerID Position
	in
		{Send Player.port initPosition(PlayerID Position)}
		{Wait PlayerID}
		{Wait Position}
		{Send GUI_port initPlayer(PlayerID Position)}
	end
	proc {Broadcast Message PlayerList}
		case Message
		of explosion(Msg Id Position) then 
			{List.forAll PlayerList
				proc {$ P} Damage in
					{Send P.port Msg(Id Position ?Damage)}
					thread
					case Damage of null then skip
					[] sayDeath(ID) then 
						{Send GUI_port removePlayer(ID)}
						{Broadcast sayDeath(ID) PlayerList}
					[] sayDamageTaken(ID DamageTaken LifeLeft) then
						{Send GUI_port lifeUpdate(ID LifeLeft)}
						{Broadcast sayDamageTaken(ID DamageTaken LifeLeft) PlayerList}
					end
					end
				end			
			}
		[] query(Player QueryMsg AnswerMsg) then
			{List.forAll PlayerList
				proc {$ P}
					thread ID Answer Args ArgsTupled in
						Args = {List.append {Record.toList QueryMsg} [ID Answer]}
						ArgsTupled = {List.mapInd Args fun {$ I A} I#A end}
						{Send P.port {List.toRecord {Record.label QueryMsg} ArgsTupled}}
						{Wait Answer}
						{Send Player.port {List.toRecord {Record.label AnswerMsg} ArgsTupled}}
					end
				end
			}		
		else {List.forAll PlayerList proc {$ P} {Send P.port Message} end}
		end
	end
	fun {Move Player PlayerList} Position Id Direction in
		{Send Player.port move(?Id ?Position ?Direction)}
		case Direction of surface then
			{Send GUI_port surface(Id)}
			surface
		else
			{Send GUI_port movePlayer(Id Position)}
			{Broadcast sayMove(Id Direction) PlayerList}
			continue
		end
	end
	proc {ChargeItem Player PLayerList} Id KindItem in
		{Send Player.port chargeItem(?Id ?KindItem)}
		if KindItem \= null then
			{Broadcast sayCharge(Id KindItem) PLayerList}
		end
	end
	proc {FireItem Player PLayerList} ID KindItem in
		{Send Player.port fireItem(?ID ?KindItem)}
		if KindItem \= null then
			case KindItem
			of mine(Position) then 
				{Broadcast sayMinePlaced(ID) PLayerList}
				{Send GUI_port putMine(ID Position)}
			[] missile(Position) then {Broadcast explosion(sayMissileExplode ID Position) PlayerList}
			[] drone(...) then {Broadcast query(Player sayPassingDrone(KindItem) sayAnswerDrone) PlayerList}
			[] sonar then {Broadcast query(Player sayPassingSonar sayAnswerSonar) PlayerList}
			end
		end
	end
	proc {FireMine Player PlayerList} ID Position in
		{Send Player.port fireMine(?ID ?Position)}
		if Position \= null then 
			{Send GUI_port removeMine(ID Position)}
			{Broadcast explosion(sayMineExplode ID Position) PlayerList}
		end
	end
in
    GUI_port = {GUI.portWindow}
    {Send GUI_port buildWindow(X)}

    PlayerList = {GeneratePlayers} 
    {List.forAll PlayerList InitPlayer}
	{Wait X} % Wait Interface is build
    if (Input.isTurnByTurn) then 
        {NewGameTurnBased PlayerList}
    else
        {NewGameRealTime PlayerList}
    end
end
