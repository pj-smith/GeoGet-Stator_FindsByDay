

//hlavni funkce modulu
function FindsByDay_Run(aPar:TStringList):string;
var
  sOld,s,sStyle,sButtonId, sButtonBlock, sIdElement, tdJsTemplate:string;
  tab: TSqliteTable;
  a:array [0..12*31-1] of integer;
  aSumaMon:array[0..12] of integer; //soucet nalezu v kazdem z mesicu kalendarniho dne
                                    //aSumaMon[mesic]=suma(data[1-31,mesic]) a nalezu celkem
  aSumaDay:array[0..31] of integer; //soucet nalezu v kazdem z kalednarnich dni vsech mesicu
                                    //aSumaDay[den]=suma(data[den,1-12]) a nalezu celkem
  i,n,dd,mm,nMax,nMaxMes,nMaxDen,nKombinaci,nMinimalFoundInDay,nFoundDaysInYear,nPosition:integer;
  bCond,bDnySvisle,bGenerateAuto,bGenerateLabels,bExpanded,bBreakGenerate,bGenerateDetail:boolean;
  aMonthName:array [0..11] of string;
  aDdmmDetail:array [0..12*31-1] of string; // Detail GC dne
begin
    
  
  if(aPar.Values['Title']<>'') then begin
    Output(ProcessCommand('CmdTitle',aPar))
  end;
  
  
  nMinimalFoundInDay := 0;
  nFoundDaysInYear := 0;
  nPosition := 0;
  bGenerateAuto := false;
  bGenerateLabels := false;
  sButtonBlock  := '';
  bExpanded := true;
  bBreakGenerate := false;
  sIdElement := GlobalVarGet('IdElement',false);

  try
    if(aPar.Values['MinimalFoundInDay'] = '') then begin
       nMinimalFoundInDay := 0;
    end
    else if(aPar.Values['MinimalFoundInDay'] = '-1') then begin
      nMinimalFoundInDay := 0;
      bGenerateAuto := true;
      bGenerateLabels := true;
    end 
    else begin
      nMinimalFoundInDay := StrToInt(aPar.Values['MinimalFoundInDay']);
    end;
  except
    nMinimalFoundInDay := 0;
  end;

  bGenerateDetail := true;
  tdJsTemplate:= '';
  try
    if(aPar.Values['GenerateDetail'] = 'Yes') then begin
      Log('GenerateDetail='+aPar.Values['GenerateDetail']);
       bGenerateDetail := true;
       
    end;
  except
    bGenerateDetail := true;
  end;

  if bGenerateDetail then
    tdJsTemplate:='onmouseover="var desc=this.getElementsByClassName(''dayDesc'')[0]; desc.style.display=''block''; desc.style.position=''absolute'';" onmouseout="this.getElementsByClassName(''dayDesc'')[0].style.display=''none'';"';

  bDnySvisle:=(aPar.Values['DaysVertically']='Yes');
  Log('Zmena orientace tabulky - Dny svisle='+IntToStr(bDnySvisle as integer));

  while true do
    begin

    GlobalVarSet('IdElement',sIdElement+'part'+IntToStr(nPosition));
   
    Log('FindsByDay_Run nMinimalFoundInDay: '+ IntToStr(Integer(nMinimalFoundInDay)));
    s:= 'SELECT COUNT(*) as dnu_v_roce'
    +'  FROM '
    +'  (SELECT count(dtfound), substr(dtfound,5,8) mmdd FROM geocache gc WHERE gc.dtfound>0 AND substr(gc.id,1,2)="GC" GROUP BY substr(dtfound,5,8)'
    +'   HAVING (count(dtfound)) > ' + IntToStr(nMinimalFoundInDay) +' ) y ;';
    Log('SQL='+s);
    nFoundDaysInYear:= Geoget_DB.GetTableValue(s);
    Log('FindsByDay_Run bGenerateLabels: '+ IntToStr(Integer(bGenerateLabels)));
    Log('FindsByDay_Run nFoundDaysInYear: '+ IntToStr(Integer(nFoundDaysInYear)));
    bExpanded := (nFoundDaysInYear < 366);
    
    if bGenerateLabels then begin
        //do sButtonBlock nasbirej HTMLko pro tlacitka
        sButtonId := 'b'+GlobalVarGet('IdElement',false);
        sButtonBlock := sButtonBlock + '<button id="' + sButtonId + '" style="cursor:pointer; margin:2px 2px 5px 2px; ';
        if bExpanded then sButtonBlock := sButtonBlock + 'font-weight:bold; " ' else sButtonBlock := sButtonBlock+'font-weight:normal;" ';
        sButtonBlock := sButtonBlock+'onclick="'
              +'document.getElementById('''+ GlobalVarGet('IdElement',false)+ ''').style.display=(getElementById('''+GlobalVarGet('IdElement',false)+''').style.display!=''none''?''none'':'''');'
              +'document.getElementById('''+ sButtonId + ''').style.fontWeight=(getElementById(''' + GlobalVarGet('IdElement',false) + ''').style.display!=''none''?''bold'':''normal'');'
              +'return false;">' + IntToStr(nFoundDaysInYear) + ' / 366</button>' + CRLF;
    end;

  // pøepínaè zúženého výpisu tabulky
  i:=Geoget_DB.GetTableValue('SELECT count(*) Num FROM geocache gc WHERE gc.dtfound>0 AND '+sCachePrefixForSql+SetSqlFilter(aPar));
  bCond:=((iWidth<700) or (i>2500));
  //inicializace poli
  for n:=0 to 12*31-1 do 
    begin
    a[n]:=0;
    aDdmmDetail[2*31-2]:= '';
  end;
  //nastavime neplatne dny
  a[2*31-2]:=-1; a[2*31-1]:=-1; aDdmmDetail[2*31-2]:= ''; aDdmmDetail[2*31-1]:= ''; //unor 
  a[4*31-1]:=-1; aDdmmDetail[4*31-1]:= ''; //duben
  a[6*31-1]:=-1; aDdmmDetail[6*31-1]:= ''; //cerven
  a[9*31-1]:=-1; aDdmmDetail[9*31-1]:= ''; //zari
  a[11*31-1]:=-1; aDdmmDetail[11*31-1]:= '';  //listopad
  for n:=0 to 31 do begin
    aSumaDay[n]:=0;
    aDdmmDetail[n]:= '';
  end;
  //pokud jsou mesice vodorovne, je osklive, kdyz kazdy mesic ma jinou sirku
  //sloupce podle delky jmena, rozdily jsou znacne (Unor/Prosinec)
  //proto dame vzdy zkratku
  if (bCond) or (bDnySvisle) then begin
    aMonthName[0]:='Jan';   aMonthName[1]:='Feb';     aMonthName[2]:='Mar';
    aMonthName[3]:='Apr';   aMonthName[4]:='Ma';      aMonthName[5]:='Jun';
    aMonthName[6]:='Jul';   aMonthName[7]:='Aug';     aMonthName[8]:='Sep';
    aMonthName[9]:='Oct';   aMonthName[10]:='Nov';    aMonthName[11]:='Dec';
  end else begin
    aMonthName[0]:='January'; aMonthName[1]:='February';  aMonthName[2]:='March';
    aMonthName[3]:='April';   aMonthName[4]:='May';       aMonthName[5]:='June';
    aMonthName[6]:='July';    aMonthName[7]:='August';    aMonthName[8]:='September';
    aMonthName[9]:='October'; aMonthName[10]:='November'; aMonthName[11]:='December';
  end;


  s:= 'SELECT count(mesic_den) pocet,mesic_den FROM'
    //datum nalezu prevedeme na string YYYY-MM-DD, vypiseme jeho den v tydnu a prevedeme tak, aby 0 bylo pondeli
    +'  (SELECT substr(dtfound,5,2)||"."||substr(dtfound,7,2) AS mesic_den'
    +'    FROM geocache gc WHERE gc.dtfound>0 AND '+sCachePrefixForSql+SetSqlFilter(aPar);
  s:=s+' GROUP BY gc.mesic_den ) x'
    +' GROUP BY mesic_den'
    +' HAVING count(mesic_den) > ' + IntToStr(nMinimalFoundInDay)
    +' ORDER BY mesic_den';

  s:= ' SELECT count(*),substr(dtfound,5,2)||"."||substr(dtfound,7,2) AS mesic_den,gc.cachetype'
    +'    FROM geocache gc WHERE gc.dtfound>0 AND '+sCachePrefixForSql+SetSqlFilter(aPar);
  s:=s+' GROUP BY gc.cachetype,mesic_den'
    +' HAVING count(*) > ' + IntToStr(nMinimalFoundInDay)
    +' ORDER BY mesic_den';

  s:= 'SELECT day_types.cnt,found_days.mesic_den,day_types.cachetype  FROM ( SELECT substr(dtfound,5,2)||"."||substr(dtfound,7,2) AS mesic_den FROM geocache gc WHERE gc.dtfound>0 AND  substr(gc.id,1,2)="GC" AND '+sCachePrefixForSql+SetSqlFilter(aPar) +' GROUP BY mesic_den HAVING count(*) > ' + IntToStr(nMinimalFoundInDay) +' ORDER BY mesic_den) as found_days JOIN (SELECT count(*) as cnt,substr(dtfound,5,2)||"."||substr(dtfound,7,2) AS mesic_den,gc.cachetype FROM geocache gc WHERE gc.dtfound>0  AND '+sCachePrefixForSql+SetSqlFilter(aPar) +' GROUP BY gc.cachetype,mesic_den) as day_types ON (found_days.mesic_den = day_types.mesic_den) ORDER BY day_types.cachetype';

  Log('FindsByDay_Run SQL='+s);
  tab:=Geoget_DB.GetTable(s, false);
  try
    while not tab.eof do
    begin
      n:=tab.FieldAsInteger(0);
      if(n>nMax) then nMax:=n;
      s:=tab.FieldAsString(1);
      mm:=StrToInt(Fetch(s,'.'))-1;
      dd:=StrToInt(s)-1;
      a[mm*31+dd] := a[mm*31+dd] + n;
      if bGenerateDetail then 
        aDdmmDetail[mm*31+dd] := (aDdmmDetail[mm*31+dd]) + '<tr><td><img style="vertical-align:bottom;" src="%IconCacheTypeSmall'+tab.FieldAsString(2)+'%" /></td><td>'+IntToStr(n) +' x</td><td>'+tab.FieldAsString(2)+'</td></tr>';
      tab.Next();
    end;
  finally
    tab.free;
  end;

  try
    s:=aPar.Values['TextMinimalFoundInDay'];
    if((s<>'') and (nMinimalFoundInDay > 0)) then begin
      s:=ReplaceString(s,'%MinimalFoundInDay%',IntToStr(nMinimalFoundInDay));
      Result:=Result+'%StyleTableBottomTextStartHtml%'+s+'%StyleTableBottomTextEndHtml%'+CRLF;
    end;
  except
  end;

  if bGenerateLabels then begin
    Result := Result + '<div id="'+GlobalVarGet('IdElement',false)+'" style="';
    if bExpanded then Result := Result + 'display:;' else Result := Result + 'display:none;';
    Result := Result + '">'+CRLF;
  end;

  //vytvorime vystupni tabulku
  //protoze sirka muze byt dana i primo v px, musime nahradit styl a v nem sirku,
  //jinak pri globalni nahrade je pouzita sirka cele statistiky
  sOld:=GlobalVarGet('StyleTableMatrix',false)
  sOld:=ReplaceString(sOld,'%Width%',IntToStr(iWidth));
  //zmenime velikost fontu, pokud je to potreba
  s:=aPar.Values['FontSize'];
  if(s<>'') then begin
    //sOld:=RegexReplace('font-size[:]\s*\d+',sOld,'font-size:'+s,false);
    sOld:=RegexReplace('font-size[:]\s*\d+(px|%|em|pt)',sOld,'font-size:'+s+'px',false);
  end;
  Result:=Result+'<div class="FindsByDay" style="margin:0px; padding:0px; overflow:auto;">'+CRLF; //pro rolovani prilis siroke tabulky
  Result:=Result+'<table style="'+sOld+'">'+CRLF;
  //vypocty souctu za dny a mesice
  nMaxMes:=0;
  nMaxDen:=0;
  nKombinaci:=0;
  for mm:=0 to 11 do begin
    aSumaMon[mm]:=0;
    for dd:=0 to 30 do begin
      if(a[mm*31+dd]>0) then begin
        aSumaMon[mm]:=aSumaMon[mm]+a[mm*31+dd];
        aSumaDay[dd]:=aSumaDay[dd]+a[mm*31+dd];
        if(nMaxDen<aSumaDay[dd]) then nMaxDen:=aSumaDay[dd];
        Inc(nKombinaci);
      end;
    end;
    aSumaDay[31]:=aSumaDay[31]+aSumaMon[mm];       //celkovy soucet vsechn dni a mesicu
    if(nMaxMes<aSumaMon[mm]) then nMaxMes:=aSumaMon[mm];
  end;
  aSumaMon[12]:=aSumaDay[31];                     //celkovy soucet vsech dni a mesicu
  //ShowMessage('nMaxDen='+IntToStr(nMaxDen)+', nMaxMes='+IntToStr(nMaxMes));

  if(not bDnySvisle) then begin  ////////////////////
    sOld:=GlobalVarget('MonthMonth',false);
    s:=sOld;
    if(bCond) then begin //udelame svisly text
      s:='';
      for dd:=1 to Length(sOld) do begin
        s:=s+'&nbsp;'+sOld[dd]+'&nbsp;<br />';
      end;
    end;
    Result:=Result
      +'  <tr style="%StyleTableMatrixTr%"><th colspan=33 style="%StyleTableMatrixTh1%">%DayDay%</th></tr>'+CRLF
      +'  <tr style="%StyleTableMatrixTr%">'
      //+'    <th rowspan=14 style="%StyleTableMatrixTh1Down%">'+s+'</th>'
      +'    <th style="%StyleTableMatrixTh2%">&nbsp;</th>';
    for dd:=0 to 30 do Result:=Result+'<th style="%StyleTableMatrixTh2%">'+FormatFloat('00',dd+1)+'</th>';
    Result:=Result+'<th style="%StyleTableMatrixTh2%">&sum;</th>'
      +'  </tr>'+CRLF;
    for mm:=0 to 11 do begin
      Result:=Result+'  <tr style="%StyleTableMatrixTr%"><th style="%StyleTableMatrixTh2%">%Month'+aMonthName[mm]+'%</th>'+CRLF;
      for dd:=0 to 30 do begin
        if(a[mm*31+dd]=0) then Result:=Result+'    <td style="%StyleTableMatrixTdEmpty%">&nbsp;</td>'+CRLF
        else if(a[mm*31+dd]=-1) then Result:=Result+'    <td style="%StyleTableMatrixTh2%">&nbsp;</td>'+CRLF
        else begin
          if(a[mm*31+dd]=nMax) and (GlobalVarGet('StyleTableMatrixTdMaxValueText',true)<>'') then begin
            Result:=Result+'    <td '+tdJsTemplate+' style="%StyleTableMatrixTdMaxValue% background:#'
              +ScaleColor(a[mm*31+dd],0,nMax,GlobalVarGet('ColorTableScaleMinBkg',false),GlobalVarGet('ColorTableScaleAvgBkg',false),GlobalVarGet('ColorTableScaleMaxBkg',false))
              +'">'+IntToStr(a[mm*31+dd]);
              if bGenerateDetail then
                Result:=Result+' <div class="dayDesc" style="display:none; border:1px solid #000; padding:4px; text-align: left !important; %StyleTableMatrixTh2%"><table>'+ aDdmmDetail[mm*31+dd] +'</table></div>';
              Result:=Result+' </td>'+CRLF;
              aDdmmDetail[mm*31+dd] := ''; // destroy aflter usage
          end
          else begin Result:=Result+'    <td '+tdJsTemplate+' style="%StyleTableMatrixTd% background:#'
            +ScaleColor(a[mm*31+dd],0,nMax,GlobalVarGet('ColorTableScaleMinBkg',false),GlobalVarGet('ColorTableScaleAvgBkg',false),GlobalVarGet('ColorTableScaleMaxBkg',false))
            +'">'+IntToStr(a[mm*31+dd]);
            if bGenerateDetail then
                Result:=Result+' <div class="dayDesc" style="display:none; border:1px solid #000; padding:4px; text-align: left !important; %StyleTableMatrixTh2%"><table>'+ aDdmmDetail[mm*31+dd] +'</table></div>';
            Result:=Result+' </td>'+CRLF;
            aDdmmDetail[mm*31+dd] := ''; // destroy aflter usage
          end;
        end;
      end;
      sStyle:=GlobalVarGet('StyleTableMatrixTh2',false);
      if(aSumaMon[mm]=nMaxMes) and (GlobalVarGet('StyleTableMatrixTh2Max',true)<>'')
        then sStyle:=GlobalVarGet('StyleTableMatrixTh2Max',false);
      Result:=Result+'    <th style="'+sStyle+'">'+IntToStr(aSumaMon[mm])+'</th>'+CRLF+'  </tr>'+CRLF;
    end;
    //doplnime soucty za jednotlive hodiny
    Result:=Result+'  <tr style="%StyleTableMatrixTr%"><th style="%StyleTableMatrixTh2%">&sum;</th>'+CRLF;
    for dd:=0 to 31 do begin
      //ve stylu nahradime barvu textu za barvu maximalniho textu
      sStyle:=GlobalVarGet('StyleTableMatrixTh2',false);
      if(aSumaDay[dd]=nMaxDen) and (GlobalVarGet('StyleTableMatrixTh2Max',true)<>'')
        then sStyle:=GlobalVarGet('StyleTableMatrixTh2Max',false);
      Result:=Result+'    <th style="'+sStyle+'">'+IntToStr(aSumaDay[dd])+'</th>'+CRLF
    end;
    Result:=Result+'  </tr>'+CRLF;
  end   ////konec dnu vodorovne
  else begin       ////////////////////////// tabulka se dny razenymi svisle
    sOld:=GlobalVarget('MonthMonth',false);
    s:=sOld;
    Result:=Result
      //+'  <tr style="%StyleTableMatrixTr%"><th colspan=14 style="%StyleTableMatrixTh1%">%MonthMonth%</th></tr>'+CRLF
      +'  <tr style="%StyleTableMatrixTr%">'
      +    '<th style="%StyleTableMatrixTh2%">&nbsp;</th>';
    for mm:=0 to 11 do Result:=Result+'<th style="%StyleTableMatrixTh2%">%Month'+aMonthName[mm]+'%</th>';
    Result:=Result+'<th style="%StyleTableMatrixTh2%">&sum;</th>'
      +'</tr>'+CRLF;
    //vlastni konstrukce tabulky po datovych radkach
    //ShowMessage('nMaxDen='+IntToStr(nMaxDen)+', nMaxMes='+IntToStr(nMaxMes));
    for dd:=0 to 30 do begin
      Result:=Result+'  <tr style="%StyleTableMatrixTr%"><th style="%StyleTableMatrixTh2%">'+FormatFloat('00',dd+1)+'</th>'+CRLF;
      for mm:=0 to 11 do begin
        if(a[mm*31+dd]=0) then Result:=Result+'    <td style="%StyleTableMatrixTdEmpty%">&nbsp;</td>'+CRLF
        else if(a[mm*31+dd]=-1) then Result:=Result+'    <td style="%StyleTableMatrixTh2%">&nbsp;</td>'+CRLF
        else begin
          if(a[mm*31+dd]=nMax) and (GlobalVarGet('StyleTableMatrixTdMaxValueText',true)<>'') then begin
            Result:=Result+'    <td '+tdJsTemplate+' style="%StyleTableMatrixTdMaxValue% background:#'+ScaleColor(a[mm*31+dd],0,nMax,GlobalVarGet('ColorTableScaleMinBkg',false),GlobalVarGet('ColorTableScaleAvgBkg',false),GlobalVarGet('ColorTableScaleMaxBkg',false))
              +'">'+IntToStr(a[mm*31+dd]);
            if bGenerateDetail then
                Result:=Result+' <div class="dayDesc" style="display:none; border:1px solid #000; padding:4px; text-align: left !important; %StyleTableMatrixTh2%"><table>'+ aDdmmDetail[mm*31+dd] +'</table></div>';
            Result:=Result+' </td>'+CRLF;
            aDdmmDetail[mm*31+dd] := ''; // destroy aflter usage
          end
          else begin Result:=Result+'    <td '+tdJsTemplate+' style="%StyleTableMatrixTd% background:#'
            +ScaleColor(a[mm*31+dd],0,nMax,GlobalVarGet('ColorTableScaleMinBkg',false),GlobalVarGet('ColorTableScaleAvgBkg',false),GlobalVarGet('ColorTableScaleMaxBkg',false))
            +'">'+IntToStr(a[mm*31+dd]);
            if bGenerateDetail then
                Result:=Result+' <div class="dayDesc" style="display:none; border:1px solid #000; padding:4px; text-align: left !important; %StyleTableMatrixTh2%"><table>'+ aDdmmDetail[mm*31+dd] +'</table></div>';
            Result:=Result+' </td>'+CRLF;
            aDdmmDetail[mm*31+dd] := ''; // destroy aflter usage
          end;
        end;
      end;
      sStyle:=GlobalVarGet('StyleTableMatrixTh2',false);
      if(aSumaDay[dd]=nMaxDen) and (GlobalVarGet('StyleTableMatrixTh2Max',true)<>'')
        then sStyle:=GlobalVarGet('StyleTableMatrixTh2Max',false);
      Result:=Result+'    <th style="'+sStyle+'">'+IntToStr(aSumaDay[dd])+'</th>'+CRLF+'  </tr>'+CRLF;
    end;
    //doplnime soucty za jednotlive dny
    Result:=Result+'  <tr style="%StyleTableMatrixTr%"><th style="%StyleTableMatrixTh2%">&sum;</th>'+CRLF;
    for mm:=0 to 12 do begin
      //ve stylu nahradime barvu textu za barvu maximalniho textu
      sStyle:=GlobalVarGet('StyleTableMatrixTh2',false);
      if(aSumaMon[mm]=nMaxMes) and (GlobalVarGet('StyleTableMatrixTh2Max',true)<>'')
        then sStyle:=GlobalVarGet('StyleTableMatrixTh2Max',false);
      Result:=Result+'    <th style="'+sStyle+'">'+IntToStr(aSumaMon[mm])+'</th>'+CRLF
    end;
    Result:=Result+'  </tr>'+CRLF;
  end;

  Result:=Result+'</table>'+CRLF;
  Result:=Result+'</div>'+CRLF; //konec automaticky rolovaneho divu
  
  
  s:=aPar.Values['TextBottom'];
  if(s<>'') then begin
    s:=ReplaceString(s,'%FoundCount%',IntToStr(nKombinaci));
    s:=ReplaceString(s,'%RestCount%',IntToStr(366 - nKombinaci));
    s:=ReplaceString(s,'%AllCount%',IntToStr(366));
    Result:=Result+'%StyleTableBottomTextStartHtml%'+s+'%StyleTableBottomTextEndHtml%'+CRLF;
  end;
  
  if bGenerateLabels then begin
     Result := Result + '</div>'; // end label div
  end;

  GlobalVarSet('IdElement',sIdElement); 
  nPosition:= nPosition + 1;
  if bGenerateAuto and (nFoundDaysInYear = 366) then begin
    Log('366 : '+ IntToStr(nFoundDaysInYear));
    nMinimalFoundInDay := nMinimalFoundInDay + 1;
  end else begin
    Log('366 != '+ IntToStr(nFoundDaysInYear));
    bBreakGenerate := true;
    break;
  end;

end; // end of while

if sButtonBlock <> '' then Result := '<div style="text-align:center; ">' + sButtonBlock + '</div>' + Result;


//Output(Result);

end; // end of function 