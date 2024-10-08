
all: sonoz

sonoz: out/GUI.ozf out/Input.ozf out/PlayerManager.ozf
	ozc -c Main.oz -o out/Main.ozf

out/GUI.ozf: out/Input.ozf
	ozc -c GUI.oz -o out/GUI.ozf

out/Input.ozf:
	ozc -c Input.oz -o out/Input.ozf

out/PlayerManager.ozf: out/Player.ozf out/Player2.ozf out/Player054Human.ozf out/Player054Dummy.ozf out/Player054Smart.ozf
	ozc -c PlayerManager.oz -o out/PlayerManager.ozf

out/Player.ozf: out/PositionManager.ozf out/Util.ozf out/Filters.ozf
	ozc -c Player.oz -o out/Player.ozf

out/Player2.ozf: out/PositionManager.ozf out/Util.ozf out/Filters.ozf
	ozc -c Player2.oz -o out/Player2.ozf

out/Player054Human.ozf:
	ozc -c Player054Human.oz -o out/Player054Human.ozf

out/Player054Dummy.ozf:
	ozc -c Player054Dummy.oz -o out/Player054Dummy.ozf

out/Player054Smart.ozf:
	ozc -c Player054Smart.oz -o out/Player054Smart.ozf

out/PositionManager.ozf: out/Filters.ozf
	ozc -c PositionManager.oz -o out/PositionManager.ozf

out/Filters.ozf: out/PositionManager.ozf
	ozc -c Filters.oz -o out/Filters.ozf

out/Util.ozf:
	ozc -c Util.oz -o out/Util.ozf



clean:
	rm -f out/*.ozf

clean_in:
	rm -f out/Input.ozf

clean_gui:
	rm -f out/GUI.ozf

clean_player:
	rm out/Player.ozf

clean_player2:
	rm out/Player2.ozf

clean_human:
	rm out/PlayerHuman.ozf
