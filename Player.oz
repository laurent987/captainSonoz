functor
import
    Input
export
    portPlayer:StartPlayer
define
    StartPlayer
    TreatStream
	InitPosition
	StateMod
	GetInitialPosition
in

	fun{InitPosition ?ID ?Position}
		fun{$ Player}
			ID=Player.ID
			Position={GetInitialPosition}
			player(position: Position)
		end
	end

	fun{StateMod State Fun}
		{Record.adjoin State {Fun State}}
	end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fun{StartPlayer Color Id}
        Stream
        Port
		StateInitial=player(id(id:Id color:Color name:'Player')
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
