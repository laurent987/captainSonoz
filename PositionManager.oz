functor
import
	Filters(applyFilters:ApplyFilters filterGeneric:FilterGeneric isInsideMap:IsInsideMap
			isNotIsland:IsNotIsland isNotAlreadyGoThere:IsNotAlreadyGoThere)
	Util(getRandIndex:GetRandIndex getRandElem:GetRandElem)
	System(show:Show)
export
	mapToList: MapToList
	generateMapPosition: GenerateMapPosition
	generateManhattanPositions: GenerateManhattanPositions
	getPositionsOnMap: GetPositionsOnMap
	getPositionOnMap: GetPositionOnMap
	getPositionAround: GetPositionAround
	getPositionsAround: GetPositionsAround
	getPositionAround2: GetPositionAround2
	getPositionsAround2: GetPositionsAround2
	getManhattanDst: GetManhattanDst
	getDirection:GetDirection
	keepDirection:KeepDirection
	getNRow:GetNRow
	getNColumn:GetNColumn
define
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
	GetDirection
	KeepDirection
	GetNRow
	GetNColumn
in

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

	fun{GetPositionsOnMap Map Filters} S in
		S = thread {GenerateMapPosition {GetNRow Map} {GetNColumn Map}} end
		{ApplyFilters Filters S}
	end

	fun{GetPositionOnMap Map Filters}
		{GetRandElem {GetPositionsOnMap Map Filters}}
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
		S = {GenerateManhattanPositions Position Min Max}
		{ApplyFilters Filters S}
	end

	fun{GetPositionAround Position Min Max Filters}
		{GetRandElem {GetPositionsAround Position Min Max Filters}}
	end

	fun{GetPositionsAround2 Position Min Max Filters Map}
		NewFilters = {IsInsideMap Map}
					|{IsNotIsland {MapToList Map} {GetNColumn Map}}
					|Filters
	in
		{GetPositionsAround Position Min Max NewFilters}
	end

	fun{GetPositionAround2 Position Min Max Filters Map}
		{GetRandElem {GetPositionsAround2 Position Min Max Filters Map}}
	end

	fun{GetManhattanDst P1 P2}
		pt(x:X1 y:Y1) = P1
		pt(x:X2 y:Y2) = P2
	in
		{Abs X1-X2} + {Abs Y1-Y2}
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

	fun{GetNRow Map}
		{List.length Map}
	end

	fun{GetNColumn Map}
		{List.length Map.1}
	end

	fun{KeepDirection Player Map}
        Pos 
        pt(x:X y:Y) = Player.position
    in
        case Player.direction
        of west then Pos = pt(x:X y:Y-1)
        [] north then Pos = pt(x:X-1 y:Y)
        [] east then Pos = pt(x:X y:Y+1)
        [] south then Pos = pt(x:X+1 y:Y)
        else Pos = null
        end
        if (Pos \= null
            	andthen {{IsInsideMap Map} Pos}
            	andthen {{IsNotIsland {MapToList Map} {GetNColumn Map}} Pos}
            	andthen {{IsNotAlreadyGoThere Player.path} Pos}) then
            Pos
        else
			null
		end
    end
end
