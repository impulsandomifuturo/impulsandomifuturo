********************************************
* Calculo Retornos Escolares - ENAHO 2020
********************************************
*Ingresar la dirección donde se encuentran las bases:

	global dir "C:\Users\guada\Dropbox\Work\SMS Desercion\Data\2019\"

*I. Preparacion de Base de datos
	*Fuente de datos: ENAHO 2019 - INEI  

	use "${dir}enaho01a-2019-300.dta", clear
	isid conglome vivienda hogar codperso 
	keep conglome vivienda hogar codperso p301* p306 p207
	merge 1:1 conglome vivienda hogar codperso using "${dir}enaho01-2019-200.dta", keepusing(p212 p214 p208a p201 ubigeo dominio estrato)
	keep if _merge==3
	drop _merge 
	merge 1:1 conglome vivienda hogar codperso using "${dir}enaho01a-2019-500.dta", keepusing(i5* d5* p5* ocu500 /* tipoent* tipocuest*/ fac*)
	keep if _merge==3
	drop i559*
	drop i560*
	drop p559*

*II. Definicion de la muestra 

	*Ocupados 
	keep if ocu500==1
	
	*Jovenes entre 25-50 años
	keep if p208a>=25 & p208a<=50 
	
*III. Creacion de Variables de interes 

	*3.1 Ingreso de actividad principal y secundaria(ingresos netos dependiente e independiente e ingresos extraordinarios) 
	
	recode i524e1 i530a d544t i538e1 i541a (999999=.)

	egen ylabi=rowtotal(i524e1 i530a d544t i538e1 i541a)
	replace ylabi=. if i524e1==. & i530a==. & d544t==. & i538e1==. &  i541a==.
	
	egen b=rsum(i524e1 i530a d544t i538e1 i541a), missing
	assert b==ylabi
	
	replace ylabi=ylabi/12 // mensual 

	count if ylabi!=.

	*Ajuste por inflacion (1.97% a Diciembre 2020 y 6.43% a Diciembre 2021) Usamos dos decimales.
		*Fuente: https://estadisticas.bcrp.gob.pe/estadisticas/series/anuales/resultados/PM05197PA/html [Agregaron 2021]
		*Fuente: https://www.bcrp.gob.pe/docs/Transparencia/Notas-Informativas/2022/nota-informativa-2022-01-06-1.pdf
	
	replace ylabi=ylabi*(1+ 0.0197)
	replace ylabi=ylabi*(1+ 0.0643)
		
	*3.3 Variable de Max. Nivel Educativo 

	gen educ_group=1 if p301a==3
	replace educ_group=2 if p301a==4
	replace educ_group=3  if p301a==5
	replace educ_group=4  if p301a==6	
	replace educ_group=5 if (p301a==8 | p301a==10)

	*3.4 Variable de sexo
	gen sexo=p207
			
*IV Calculo del promedio de ingresos laborales por macroregion y sexo: 
	*Nota: Los resultados son los mismos utilizando svyset [pweight = fac500a], psu(conglome)strata(estrato) y el comando mean. 

	collapse (mean) ylabi* [iw=fac500a] , by(educ_group)
	drop if educ_group==.
	
*V. Exportación de resultados 

	label define educ_group 1 "prim_incompleta" 2 "prim_completa" 3 "sec_incompleta" 4 "sec_completa" 5 "sup_completa"
	label values educ_grou educ_group 

	export excel "${dir}Retornos.xlsx", replace firstrow(var)
	
	************************************
