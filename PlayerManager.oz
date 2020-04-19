functor
import
	Player089Dummy 
	Player089Smart
	PlayerHuman 
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player089dummy then {Player089Dummy.portPlayer Color ID}
		[] player089smart then {Player089Smart.portPlayer Color ID}
		end
	end
end
