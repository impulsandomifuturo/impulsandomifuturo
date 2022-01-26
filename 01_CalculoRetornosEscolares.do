********************************************
* Calculo Retornos Escolares - ENAHO 2020
********************************************
*Ingresar la dirección donde se encuentran las bases:

	global dir " "

*I. Preparacion de Base de datos
	*Fuente de datos: ENAHO 2020 - INEI  

	use "${dir}enaho01a-2020-300.dta", clear
	isid conglome vivienda hogar codperso 
	keep conglome vivienda hogar codperso p301* p306 p207
	merge 1:1 conglome vivienda hogar codperso using "${dir}enaho01-2020-200.dta", keepusing(p212 p214 p208a p201 ubigeo dominio estrato)
	keep if _merge==3
	drop _merge 
	merge 1:1 conglome vivienda hogar codperso using "${dir}enaho01a-2020-500.dta", keepusing(i5* d5* p5* ocu500 /* tipoent* tipocuest*/ fac*)
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

	*3.1 Macroregiones: 
	
	/*	
	Definicion:
	Fuente: 
	https://www.mincetur.gob.pe/wp-content/uploads/documentos/comercio_exterior/estadisticas_y_publicaciones/estadisticas/reporte_regional/Mensual/RMCR_Abril_2019.pdf

	01 Norte - Ancash, la libertad, piura, cajamarca, lambayeque, tumbes 
	02 Sur - Aqp, apurimac, cusco, moquegua, puno, tacna 
	03 centro -  ica junin ayacucho pasco huancavelica  huanuco 
	04 selva-  madre de dios loreto  san martin amazonas ucayali 
	05 Lima: lima y callao 

	*Codigo de Departamento. 
	 Fuente: 
	 
		01	AMAZONAS
		02	ANCASH
		03	APURIMAC
		04	AREQUIPA
		05	AYACUCHO
		06	CAJAMARCA
		07	CALLAO
		08	CUSCO
		09	HUANCAVELICA
		10	HUANUCO
		11	ICA
		12	JUNIN
		13	LA LIBERTAD
		14	LAMBAYEQUE
		15	LIMA
		16	LORETO
		17	MADRE DE DIOS
		18	MOQUEGUA
		19	PASCO
		20	PIURA
		21	PUNO
		22	SAN MARTIN
		23	TACNA
		24	TUMBES
		25	UCAYALI
		*/
	
	gen depa=substr(ubigeo,1,2)
	destring depa, replace
	
	gen macroregion=1 if depa==2 | depa==13 | depa==20 | depa==6 | depa==14 | depa==24 
	replace macroregion=2 if depa==4 | depa==3 | depa==8 | depa==18 | depa==21 | depa==23 
	replace macroregion=3 if depa==11 | depa==12 | depa==5 | depa==19 | depa==9 | depa==10 
	replace macroregion=4 if depa==17 | depa==16 | depa==22 | depa==1 | depa==25
	replace macroregion=5 if depa==7 | depa==15 
	
	assert macroregion!=. 
	tab macroregion,m
	
	count
	
	label define macroregion 1 "Norte" 2 "Sur" 3 "Centro" 4 "Selva" 5 "Lima"
	label values macroregion macroregion

	*3.2 Ingreso de actividad principal y secundaria(ingresos netos dependiente e independiente e ingresos extraordinarios) 
	
	recode i524e1 i530a d544t i538e1 i541a (999999=.)

	egen ylabi=rowtotal(i524e1 i530a d544t i538e1 i541a)
	replace ylabi=. if i524e1==. & i530a==. & d544t==. & i538e1==. &  i541a==.
	
	egen b=rsum(i524e1 i530a d544t i538e1 i541a), missing
	assert b==ylabi
	
	replace ylabi=ylabi/12 // mensual 

	count if ylabi!=.

	*Ajuste por inflacion (6.43% a Diciembre 2021)
		*Fuente: https://www.bcrp.gob.pe/docs/Transparencia/Notas-Informativas/2022/nota-informativa-2022-01-06-1.pdf
	
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

	collapse (mean) ylabi* [iw=fac500a] , by(macroregion educ_group)
	drop if educ_group==.
	
*V. Exportación de resultados 

	sort macroregion educ_group
	egen newid=group(macroregion )
	reshape wide ylabi*, i(newid) j(educ_group)
	drop newid
	order macr*  ylabi1 ylabi2  ylabi3 
	sort  macroregion
	rename ylabi1 prim_incompleta
	rename ylabi2 prim_completa
	rename ylabi3 sec_incompleta
	rename ylabi4 sec_completa
	rename ylabi5 sup_completa

	export excel "${dir}Retornos.xlsx", replace firstrow(var)
	
	************************************
