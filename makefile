all: sonoz

sonoz: GUI.ozf Input.ozf PlayerManager.ozf
	ozc -c Main.oz

GUI.ozf: Input.ozf
	ozc -c GUI.oz

Input.ozf:
	ozc -c Input.oz

PlayerManager.ozf: Player.ozf PlayerHuman.ozf
	ozc -c PlayerManager.oz

Player.ozf:
	ozc -c Player.oz

PlayerHuman.ozf:
	ozc -c PlayerHuman.oz


clean:
	rm Main.ozf
	rm Input.ozf
	rm GUI.ozf
	rm Player.ozf

clean_player:
	rm Player.ozf

clean_human:
	rm PlayerHuman.ozf
