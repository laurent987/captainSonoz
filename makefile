sonoz: GUI.ozf Input.ozf 
        ozc -c Main.oz

GUI.ozf: Input.ozf
        ozc -c GUI.oz

Input.ozf:
        ozc -c Input.ozf
