functor
import
	OS
	PositionManager(getManhattanDst:GetManhattanDst)
export
	getRandIndex:GetRandIndex
	getRandElem:GetRandElem
	randomExcept:RandomExcept
	getItemsLoaded:GetItemsLoaded
	isLoaded:IsLoaded
	sayItemExplode:SayItemExplode
	damageSustained:DamageSustained	
define
	GetRandIndex
	GetRandElem
	RandomExcept
	GetItemsLoaded
	IsLoaded
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

	fun{GetItemsLoaded Player Load}
		fun{Loop Player Items}
			case Items of nil then nil
			[] Item|T andthen {IsLoaded Player Item Load} then Item|{Loop Player T}
			[] _|T then {Loop Player T} end		
		end
	in
		{Loop Player {Record.arity Player.load}}
	end

	fun{IsLoaded Player Item Load}
		Player.load.Item >= Load.Item
	end

	fun{SayItemExplode Player Position Damages ?Message} Damage NewLifeLeft Dead in
		if Player.dead then 
			Message=null
			Dead=true
		else 
			Damage={DamageSustained Damages Player Position} 
			NewLifeLeft = Player.lifeLeft - Damage
			if NewLifeLeft =< 0 then
				Message = sayDeath(Player.id)
				Dead=true
			elseif Damage == 0 then	Message = null
			else Message = sayDamageTaken(Player.id Damage NewLifeLeft) end
			if {Not {IsDet Dead}} then Dead=false end
		end
		player(lifeLeft:NewLifeLeft dead:Dead)			
	end

	fun{DamageSustained Damages Player PositionExplosion}
		Dst = {GetManhattanDst Player.position PositionExplosion}
	in
		if{Value.hasFeature Damages Dst} then Damages.Dst
		else 0 end
	end
end