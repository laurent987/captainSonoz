functor
import
	PlayerBasicAI
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player2 then {PlayerBasicAI.portPlayer Color ID}
		[] player1 then {PlayerBasicAI.portPlayer Color ID}
		end
	end
end
