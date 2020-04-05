functor
import
    Input
	OS
	System(show:Show)
export
    portPlayer:StartPlayer
define
    StartPlayer
    TreatStream
	Map = Input.map
	NRow = Input.nRow
	NColumn = Input.nColumn
	StateMod
	InitPosition
	GetInitialPosition
	GetAcceptablePositions
in

	fun{InitPosition ?ID ?Position}
		fun{$ Player}
			{Show player#Player}
			ID=Player.id
			{Show ID}
			Position = {GetInitialPosition}
			{Show Position}
			player(position: Position)
		end
	end

	fun {GetInitialPosition}
			L Ran Position X Y
	in
		{Show getinit}
		L = {GetAcceptablePositions Map 0}
		{Show L}
		Ran = 1 + {OS.rand} mod {List.length L}
		Position = {List.nth L Ran}
		X = Position div NColumn + 1
		Y = Position mod NColumn + 1
		pt(x:X y:Y)		
	end

	%% @Pre : 
	%%	--> Matrice: a List of List : 
	%% 		[[a_11 ... a_1n] ... [a_m1 ... a_mn]]
	%% 		where 'n' is the number of column and 'm' the number of row.
	%% -->	Value: a number 
	%% @Post: 
	%%	--> Return a List 'L' with the positions of elements a_ij which are egal to Value.
	%%	 	Where position of a_ij is P(a_ij) = (i - 1) * n + (j-1)
	%% 	 	L = [ ... P(a_lk) ... P(a_uv) ...] with a_lk = a_uv = Value and l =< u and (l=u => k<v)
	%% Exemple: 
	%% Matrice = [[0 1 0][0 1 0]], Value = 0
	%% Return L = [0 2 3 5]
	fun{GetAcceptablePositions Matrice Value}
		fun{SearchRow Row N X}
			case Row of nil then X
			[] H|T andthen H==0 then N|{SearchRow T N+1 X}
			else {SearchRow Row.2 N+1 X} end
		end
		proc{Loop Rows N NColumn R}
			case Rows of nil then R=nil
			[] T|End then X in
				R = {SearchRow T N X}
				{Show R}
				{Loop End N+NColumn NColumn X}
			end
		end
	in
		{Show accept}
		{Loop Matrice 0 {List.length Matrice.1} $}
	end


	fun{StateMod State Fun}
		{Record.adjoin State {Fun State}}
	end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fun{StartPlayer Color Id}
        Stream
        Port
		StateInitial=player(id:id(id:Id color:Color name:'Player')
							domage:0 			% numbre of domage received
							surface:true		% true if the sub is on the surface
							mines:nil			% mines=[mine_1(<position),..., mine_n(<position)]
							load: item(mine:0 missile:0 drone:0  sonar:0)) % number of charge for each item
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream StateInitial}
        end
        Port
    end

	proc{TreatStream Stream State}
		case Stream of nil then skip
		[] initPosition(?ID ?Position)|T then
			thread {Wait Position} {Show pos#Position} end
			{TreatStream T {StateMod State {InitPosition ID Position}}}
		[] move(?ID ?Position ?Direction)|T then
			{TreatStream T State}
		[] dive|T then
			{TreatStream T State}
		[] chargeItem(?ID ?KindItem)|T then
			{TreatStream T State}
		[] fireItem(?ID ?KinfFire)|T then
			{TreatStream T State}
		[] fireMine(?ID ?Mine)|T then
			{TreatStream T State}
		[] isDead(?Answer)|T then
			{TreatStream T State}
		[] sayMove(ID Direction)|T then
			{TreatStream T State}
		[] saySurface(ID)|T then
			{TreatStream T State}
		[] sayCharge(ID KindItem)|T then
			{TreatStream T State}
		[] sayMinePlaced(ID)|T then
			{TreatStream T State}
		[] sayMissileExplode(ID Position ?Message)|T then
			{TreatStream T State}
		[] sayMineExplode(ID Position ?Message)|T then
			{TreatStream T State}
		[] sayPassingDrone(Drone ?ID ?Answer)|T then
			{TreatStream T State}
		[] sayAnswerDrone(Drone ID Answer)|T then
			{TreatStream T State}
		[] sayPassingSonar(?ID ?Answer)|T then
			{TreatStream T State}
		[] sayAnswerSonar(ID  Answer)|T then
			{TreatStream T State}
		[] sayDeath(ID)|T then
			{TreatStream T State}
		[] sayDamageTaken(ID Damage LifeLeft)|T then 
			{TreatStream T State}
		end
	end

end
