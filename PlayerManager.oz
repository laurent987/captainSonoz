functor
import
	Player 
	Player2 
	PlayerHuman 
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player1 then {Player.portPlayer Color ID}
		[] player2 then {Player2.portPlayer Color ID}
		end
	end
end
