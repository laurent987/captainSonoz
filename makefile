
all: sonoz

sonoz: out/GUI.ozf out/Input.ozf out/PlayerManager.ozf
	ozc -c Main.oz -o out/Main.ozf

out/GUI.ozf: out/Input.ozf
	ozc -c GUI.oz -o out/GUI.ozf

out/Input.ozf:
	ozc -c Input.oz -o out/Input.ozf

out/PlayerManager.ozf: out/Player.ozf out/Player2.ozf out/PlayerHuman.ozf out/Player089Dummy.ozf out/Player089Smart.ozf
	ozc -c PlayerManager.oz -o out/PlayerManager.ozf

out/Player.ozf: out/PositionManager.ozf out/Util.ozf out/Filters.ozf
	ozc -c Player.oz -o out/Player.ozf

out/Player2.ozf: out/PositionManager.ozf out/Util.ozf out/Filters.ozf
	ozc -c Player2.oz -o out/Player2.ozf

out/PlayerHuman.ozf:
	ozc -c PlayerHuman.oz -o out/PlayerHuman.ozf

out/Player089Dummy.ozf:
	ozc -c Player089Dummy.oz -o out/Player089Dummy.ozf

out/Player089Smart.ozf:
	ozc -c Player089Smart.oz -o out/Player089Smart.ozf

out/PositionManager.ozf: out/Filters.ozf
	ozc -c PositionManager.oz -o out/PositionManager.ozf

out/Filters.ozf: out/PositionManager.ozf
	ozc -c Filters.oz -o out/Filters.ozf

out/Util.ozf:
	ozc -c Util.oz -o out/Util.ozf



clean:
	rm -f out/*.ozf

clean_player:
	rm out/Player.ozf

clean_player2:
	rm out/Player2.ozf

clean_human:
	rm out/PlayerHuman.ozf
