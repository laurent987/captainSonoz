functor
import
	PositionManager(getNRow:GetNRow getNColumn:GetNColumn)
export
	applyFilters: ApplyFilters
	filterGeneric: FilterGeneric
	isInsideMap: IsInsideMap
	isNotIsland: IsNotIsland
	isNotAlreadyGoThere: IsNotAlreadyGoThere
	isNotOnEdge:IsNotOnEdge
define
	ApplyFilters
	FilterGeneric
	IsInsideMap
	IsNotIsland
	IsNotAlreadyGoThere
	IsNotOnEdge
in
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

	fun{IsInsideMap Map}
		fun{$ Position}
			NRow = {List.length Map}
			NColumn = {List.length Map.1}
			pt(x:X y:Y) = Position
		in
			0 < X andthen X =< NRow andthen 0 < Y andthen Y =< NColumn
		end
	end

	fun{IsNotIsland ListMap NColumn}
		fun{$ Position}
			pt(x:X y:Y) = Position
		in
			{List.nth ListMap (X-1)*NColumn + Y} == 0
		end
	end

	fun{IsNotAlreadyGoThere Path}
		fun{$ Position}
			fun{Loop Path Position}
				case Path of nil then true
				[] H|T andthen H\=Position then {Loop T Position}
				else false end
			end
		in
			{Loop Path Position}
		end			
	end

	fun{IsNotOnEdge Map}
		fun{$ Position}
			pt(x:X y:Y) = Position
		in
			X > 1 andthen X < {GetNRow Map} andthen Y > 1 andthen Y < {GetNColumn Map}
		end
	end
end