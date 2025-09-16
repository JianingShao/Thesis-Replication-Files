
*************************************************
**** Auxiliary file 1                        ****
**** Replace all accents with normal letters ****
*************************************************
**** Ehrl (2017) Estudos Economicos 47/1     **** 
*************************************************

*** call: variable name

replace `1' = subinstr(`1',"ã","a",.) // a tilde
replace `1' = subinstr(`1',"ç","c",.) // cedille

replace `1' = subinstr(`1'," Â"," A",.) // some strange a (capital letter)
replace `1' = subinstr(`1',"Â","a",.) // some strange a (minor letter)

replace `1' = subinstr(`1'," Á"," A",.) // �  (capital letter)
replace `1' = subinstr(`1',"Á","a",.) // �
replace `1' = subinstr(`1'," á"," A",.) // �  (capital letter)
replace `1' = subinstr(`1',"á","a",.) // �
replace `1' = subinstr(`1'," é"," E",.) // �  (capital letter)
replace `1' = subinstr(`1',"é","e",.) // �
replace `1' = subinstr(`1'," í"," I",.) // �  (capital letter)
replace `1' = subinstr(`1',"í","i",.) // �

replace `1' = subinstr(`1'," ú"," U",.) // � (capital letter)
replace `1' = subinstr(`1',"ú","u",.) // � 

replace `1' = subinstr(`1'," Ó"," O",.) // some strange O (capital letter)
replace `1' = subinstr(`1',"Ó","o",.) // some strange O
replace `1' = subinstr(`1'," ó"," O",.) // some strange O (capital letter)
replace `1' = subinstr(`1',"ó","o",.) // some strange O
replace `1' = subinstr(`1'," õ"," O",.) // some strange O (capital letter)
replace `1' = subinstr(`1',"õ","o",.) // some strange O
replace `1' = subinstr(`1'," ê"," E",.) // some strange E (capital letter)
replace `1' = subinstr(`1',"ê","e",.) // some strange E

replace `1' = subinstr(`1'," Í"," I",.) // some strange I (capital letter)
replace `1' = subinstr(`1',"Í","i",.) // some strange I

replace `1' = subinstr(`1'," â"," A",.) // � (capital letter)
replace `1' = subinstr(`1',"â","a",.) // � 
replace `1' = subinstr(`1'," ô"," O",.) // � (capital letter)
replace `1' = subinstr(`1',"ô","o",.) // � 









