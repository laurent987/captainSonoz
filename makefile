all: sonoz

sonoz: GUI.ozf Input.ozf PlayerManager.ozf
	ozc -c Main.oz

GUI.ozf: Input.ozf
	ozc -c GUI.oz

Input.ozf:
	ozc -c Input.oz

PlayerManager.ozf:
	ozc -c PlayerManager.oz

clean:
	rm Main.ozf
	rm Input.ozf
	rm GUI.ozf