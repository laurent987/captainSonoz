functor
import
    GUI
    Input
    PlayerManager
	System(show:Show)
	List(length: Length)
define
	PlayerList
	GUI_port
	proc {NewGameTurnBased PlayerList}
		proc {LoopGame PlayerList} 
			if {Length PlayerList} > 1 then
				{LoopGame {RoundTable PlayerList}}
			else {Show 'the end'}
		end
		proc {RoundTable PlayerList} 
			case PlayerList of nil then nil
			[] player(alive: Alive ...)|Pr andthen {Not Alive} then {RoundTable Pr}
			[] player(turnToWait:X)|Pr andthen X>0 then {Adjoin P player(turnToWait: X-1)}|{RoundTable Pr}
			[] P|Pr then {PlayTurn P}|{RoundTable Pr}
		end
		proc {PlayTurn Player}
			{Move Player}
		end
	in
		{LoopGame PlayerList}
	end
	proc {NewGameRealTime GuiPort PlayerList} skip end
    fun {GeneratePlayers}
        fun {Loop PlayerList ColorList IdNum}
            if IdNum > Input.nbPlayer then nil
            else		
                case PlayerList#ColorList of (H1|T1)#(H2|T2) then 
                    if (Input.isTurnByTurn) then 
                        player( port:{PlayerManager.playerGenerator H1 H2 IdNum}
                                turnToWait:0
                                alive:true)|{Loop T1 T2 IdNum+1}
                    else
                        player(port:{PlayerManager.playerGenerator H1 H2 IdNum})|{Loop T1 T2 IdNum+1} 
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
	proc {Move Player}
		
	end
in
    GUI_port = {GUI.portWindow}
    {Send GUI_port buildWindow}

    PlayerList = {GeneratePlayers} 
    {List.forAll PlayerList InitPlayer}

    if (Input.isTurnByTurn) then 
        {NewGameTurnBased GUI_port PlayerList}
    else
        {NewGameRealTime GUI_port PlayerList}
    end
end
