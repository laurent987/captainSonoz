functor
import
	OS
	PositionManager(getManhattanDst:GetManhattanDst)
export
	getRandIndex:GetRandIndex
	getRandElem:GetRandElem
	randomExcept:RandomExcept
	getItemsNoCreated:GetItemsNoCreated
	getItemsCreated:GetItemsCreated
	isCreated:IsCreated
	sayItemExplode:SayItemExplode
	damageSustained:DamageSustained	
define
	GetRandIndex
	GetRandElem
	RandomExcept
	GetItemsNoCreated
	GetItemsCreated
	IsCreated
	SayItemExplode
	DamageSustained
in
	fun{GetRandIndex L}
		{OS.rand} mod {List.length L} + 1
	end

	fun{GetRandElem L}
		if {List.length L} == 0 then null
		else {List.nth L {GetRandIndex L}} end
	end

	fun{RandomExcept Min Max NumNotAccepted}
		L = {List.subtract {List.number Min Max 1} NumNotAccepted}
	in
		{GetRandElem L}
	end

	fun{GetItemsNoCreated Player Load}
		fun{Loop Player Items}
			case Items of nil then nil
			[] Item|T andthen {Not {IsCreated Player Item Load}} then Item|{Loop Player T}
			[] _|T then {Loop Player T} end		
		end
	in
		{Loop Player {Record.arity Player.load}}
	end


	fun{GetItemsCreated Player Load}
		fun{Loop Player Items}
			case Items of nil then nil
			[] Item|T andthen {IsCreated Player Item Load} then Item|{Loop Player T}
			[] _|T then {Loop Player T} end		
		end
	in
		{Loop Player {Record.arity Player.load}}
	end

	fun{IsCreated Player Item Load}
		Player.load.Item >= Load.Item
	end

	fun{SayItemExplode Player Position Damages ?Message} 
		if Player.dead then 
			Message=null
			player()
		else Damage NewLifeLeft in
			Damage={DamageSustained Damages Player Position} 
			NewLifeLeft = Player.lifeLeft - Damage
			if NewLifeLeft =< 0 then
				Message = sayDeath(Player.id)
				player(dead:true lifeLeft:NewLifeLeft)
			elseif Damage == 0 then
				Message = null
				player()
			else 
				Message = sayDamageTaken(Player.id Damage NewLifeLeft)
				player(lifeLeft:NewLifeLeft)
			end
		end
					
	end

	fun{DamageSustained Damages Player PositionExplosion}
		Dst = {GetManhattanDst Player.position PositionExplosion}
	in
		if{Value.hasFeature Damages Dst} then Damages.Dst
		else 0 end
	end
end