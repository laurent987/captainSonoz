functor
import
	Player054Dummy 
	Player054Smart
	Player054Human 
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player054dummy then {Player054Dummy.portPlayer Color ID}
		[] player054smart then {Player054Smart.portPlayer Color ID}
		[] player054human then {Player054Human.portPlayer Color ID}
		end
	end
end
