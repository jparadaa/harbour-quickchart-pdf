/*
 * ejemplo_pdf_graficas.prg
 *
 * Ejemplo: Generar PDF con gráficas usando QuickChart + tpdfclass
 *
 * Requisitos:
 *   - Harbour con hbhpdf, hbcurl
 *   - QuickChart corriendo en Docker: docker run -d -p 3000:3000 ianw/quickchart
 *
  */

// URL base de QuickChart local
#define URL_QUICKCHART  "http://localhost:3400/chart?"

FUNCTION Main()

   LOCAL oPdf
   LOCAL hFonts  := {=>}
   LOCAL cImgBarras := hb_DirBase() + "tmp_barras.png"
   LOCAL cImgDona   := hb_DirBase() + "tmp_dona.png"
   LOCAL cPdfFile   := hb_DirBase() + "reporte_ejemplo.pdf"
   LOCAL aResult

   ? "Generando grafica de barras..."
   aResult := Ejemplo_GraficarBarras( cImgBarras )
   IF !aResult[1]
      ? "ERROR barras:", aResult[2]
      RETURN NIL
   ENDIF

   ? "Generando grafica de dona..."
   aResult := Ejemplo_GraficarDona( cImgDona )
   IF !aResult[1]
      ? "ERROR dona:", aResult[2]
      RETURN NIL
   ENDIF

   ? "Generando PDF..."
   oPdf := TPdf():New()

   hFonts["titulo"] := oPdf:DefineFont( "Helvetica-Bold", 16 )
   hFonts["normal"] := oPdf:DefineFont( "Helvetica", 10 )

   oPdf:StartPage()
   oPdf:SetPage( HPDF_PAGE_SIZE_LETTER )
   oPdf:SetLandscape()

   // Título
   oPdf:CmSay( 1.0, 2.0, "Reporte de Ventas Ejemplo", hFonts["titulo"] )
   oPdf:CmSay( 1.8, 2.0, "Datos ficticios para demostracion", hFonts["normal"] )

   // Línea separadora
   oPdf:CmLine( 2.4, 0.8, 2.4, 27.1, 0.3 )

   // Gráfica barras: PNG 900x450 (ratio 2:1) → en PDF ancho 16cm alto 8cm
   IF File( cImgBarras )
      oPdf:CmSayBitmap( 2.8, 0.8, cImgBarras, 16.0, 8.0 )
   ENDIF

   // Gráfica dona: PNG 450x450 (ratio 1:1) → en PDF ancho 8cm alto 8cm
   IF File( cImgDona )
      oPdf:CmSayBitmap( 2.8, 17.5, cImgDona, 8.0, 8.0 )
   ENDIF

   // Pie de página
   oPdf:CmLine( 20.4, 0.8, 20.4, 27.1, 0.2 )
   oPdf:CmSay( 20.7, 0.8, "Ejemplo generado con Harbour + QuickChart + libharu", hFonts["normal"] )

   oPdf:EndPage()
   oPdf:Save( cPdfFile )
   oPdf:End()

   // Limpiar temporales
   FErase( cImgBarras )
   FErase( cImgDona )

   ? "PDF generado:", cPdfFile

RETURN NIL


// ============================================================
// Gráfica de barras con línea comparativa
// Datos ficticios: ventas mensuales 2024 vs 2023
// ============================================================
STATIC FUNCTION Ejemplo_GraficarBarras( cFile )
   LOCAL hChart    := {=>}
   LOCAL hData     := {=>}
   LOCAL hOptions  := {=>}
   LOCAL hScales   := {=>}
   LOCAL hYAxis    := {=>}
   LOCAL hXAxis    := {=>}
   LOCAL aDatasets := {}
   LOCAL hBarras   := {=>}
   LOCAL hLinea    := {=>}
   LOCAL cChartJs, cParams, cUrlFinal
   LOCAL hCurl, nResult, nHttpCode := 0

   // Datos ficticios — ventas mensuales en miles
   hBarras["type"]            := "bar"
   hBarras["label"]           := "2024"
   hBarras["data"]            := { 320, 415, 380, 490, 520, 610 }
   hBarras["backgroundColor"] := "rgba(31,73,125,0.85)"
   hBarras["borderColor"]     := "rgb(31,73,125)"
   hBarras["borderWidth"]     := 1
   hBarras["order"]           := 2
   hBarras["datalabels"]      := { ;
      "align"  => "end", ;
      "anchor" => "end", ;
      "color"  => "#1F497D", ;
      "font"   => { "size" => 10, "weight" => "bold" } ;
   }

   hLinea["type"]                 := "line"
   hLinea["label"]                := "2023"
   hLinea["data"]                 := { 290, 370, 340, 420, 460, 550 }
   hLinea["borderColor"]          := "rgb(230,90,40)"
   hLinea["borderWidth"]          := 3
   hLinea["fill"]                 := .F.
   hLinea["order"]                := 1
   hLinea["pointRadius"]          := 5
   hLinea["pointBackgroundColor"] := "rgb(230,90,40)"
   hLinea["datalabels"]           := { ;
      "align"           => "bottom", ;
      "anchor"          => "center", ;
      "color"           => "white", ;
      "backgroundColor" => "rgba(230,90,40,0.75)", ;
      "borderRadius"    => 3, ;
      "font"            => { "size" => 9, "weight" => "bold" } ;
   }

   AAdd( aDatasets, hBarras )
   AAdd( aDatasets, hLinea )

   // Eje Y con callback para formato $mil
   hYAxis["ticks"]  := { "beginAtZero" => .T., "fontSize" => 11, "callback" => "##JS_Y##" }
   hXAxis["ticks"]  := { "fontSize" => 11 }
   hScales["yAxes"] := { hYAxis }
   hScales["xAxes"] := { hXAxis }

   hOptions["title"]   := { "display" => .T., "text" => "Ventas Mensuales (miles de pesos)", "fontSize" => 14, "fontStyle" => "bold" }
   hOptions["legend"]  := { "position" => "top", "labels" => { "fontSize" => 11 } }
   hOptions["scales"]  := hScales
   hOptions["plugins"] := { "datalabels" => { "display" => .T., "formatter" => "##JS_LBL##" } }
   hOptions["layout"]  := { "padding" => { "top" => 25, "bottom" => 10, "left" => 10, "right" => 10 } }

   hData["labels"]   := { "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio" }
   hData["datasets"] := aDatasets
   hChart["type"]    := "bar"
   hChart["data"]    := hData
   hChart["options"] := hOptions

   // Serializar y sustituir callbacks JS
   // Importante: QuickChart Docker usa Chart.js v2
   // El placeholder entre comillas dobles es reemplazado por la función JS real
   cChartJs := hb_jsonEncode( hChart )
   cChartJs := StrTran( cChartJs, '"##JS_Y##"', ;
      "function(v){if(v>=1000)return '$'+(v/1000).toFixed(1)+' M';return '$'+v+' mil';}" )
   cChartJs := StrTran( cChartJs, '"##JS_LBL##"', ;
      "function(v){return '$'+v+' mil';}" )

   cParams   := "c=" + Ejemplo_UrlEncode( cChartJs ) + "&w=900&h=450&bkg=white"
   cUrlFinal := URL_QUICKCHART + cParams

   curl_global_init()
   hCurl := curl_easy_init()
   IF Empty( hCurl )
      RETURN { .F., "No se pudo inicializar CURL" }
   ENDIF

   curl_easy_setopt( hCurl, HB_CURLOPT_URL,            cUrlFinal )
   curl_easy_setopt( hCurl, HB_CURLOPT_HTTPGET,        .T. )
   curl_easy_setopt( hCurl, HB_CURLOPT_DOWNLOAD )
   curl_easy_setopt( hCurl, HB_CURLOPT_DL_FILE_SETUP,  cFile )
   curl_easy_setopt( hCurl, HB_CURLOPT_CONNECTTIMEOUT, 10 )
   curl_easy_setopt( hCurl, HB_CURLOPT_TIMEOUT,        30 )

   nResult := curl_easy_perform( hCurl )
   IF nResult == HB_CURLE_OK
      nHttpCode := curl_easy_getinfo( hCurl, HB_CURLINFO_RESPONSE_CODE )
   ENDIF

   curl_easy_setopt( hCurl, HB_CURLOPT_DL_FILE_CLOSE )
   curl_easy_cleanup( hCurl )
   curl_global_cleanup()

   IF nResult == HB_CURLE_OK .AND. nHttpCode == 200
      RETURN { .T., cFile }
   ENDIF
RETURN { .F., "CURL error: " + curl_easy_strerror(nResult) + " HTTP:" + hb_NToS(nHttpCode) }


// ============================================================
// Gráfica de dona con participación por región
// Datos ficticios: distribución de ventas por zona
// ============================================================
STATIC FUNCTION Ejemplo_GraficarDona( cFile )
   LOCAL hChart    := {=>}
   LOCAL hData     := {=>}
   LOCAL hOptions  := {=>}
   LOCAL hPlugins  := {=>}
   LOCAL hDataset  := {=>}
   LOCAL aDatasets := {}
   LOCAL cChartJs, cParams, cUrlFinal
   LOCAL hCurl, nResult, nHttpCode := 0

   hDataset["data"]            := { 38, 29, 21, 12 }
   hDataset["backgroundColor"] := { ;
      "rgb(31,73,125)",   ;
      "rgb(70,130,180)",  ;
      "rgb(144,194,231)", ;
      "rgb(200,220,240)"  ;
   }
   hDataset["borderWidth"] := 2
   hDataset["borderColor"] := "white"
   AAdd( aDatasets, hDataset )

   hPlugins["datalabels"] := { ;
      "display"   => .T., ;
      "color"     => "white", ;
      "font"      => { "size" => 12, "weight" => "bold" }, ;
      "formatter" => "##JS_DONA##" ;
   }

   hOptions["title"]            := { "display" => .T., "text" => "Participacion por Zona", "fontSize" => 14, "fontStyle" => "bold" }
   hOptions["legend"]           := { "position" => "bottom", "labels" => { "fontSize" => 11 } }
   hOptions["plugins"]          := hPlugins
   hOptions["cutoutPercentage"] := 50

   // Importante: cutoutPercentage es sintaxis Chart.js v2
   // En v3 se usa cutout: "50%"

   hData["labels"]   := { "Norte 38%", "Centro 29%", "Sur 21%", "Otros 12%" }
   hData["datasets"] := aDatasets
   hChart["type"]    := "doughnut"
   hChart["data"]    := hData
   hChart["options"] := hOptions

   cChartJs := hb_jsonEncode( hChart )
   cChartJs := StrTran( cChartJs, '"##JS_DONA##"', ;
      "function(v,ctx){" + ;
      "var s=ctx.dataset.data.reduce(function(a,b){return a+b;},0);" + ;
      "return ((v/s)*100).toFixed(1)+'%';}" )

   cParams   := "c=" + Ejemplo_UrlEncode( cChartJs ) + "&w=450&h=450&bkg=white"
   cUrlFinal := URL_QUICKCHART + cParams

   curl_global_init()
   hCurl := curl_easy_init()
   IF Empty( hCurl )
      RETURN { .F., "No se pudo inicializar CURL" }
   ENDIF

   curl_easy_setopt( hCurl, HB_CURLOPT_URL,            cUrlFinal )
   curl_easy_setopt( hCurl, HB_CURLOPT_HTTPGET,        .T. )
   curl_easy_setopt( hCurl, HB_CURLOPT_DOWNLOAD )
   curl_easy_setopt( hCurl, HB_CURLOPT_DL_FILE_SETUP,  cFile )
   curl_easy_setopt( hCurl, HB_CURLOPT_CONNECTTIMEOUT, 10 )
   curl_easy_setopt( hCurl, HB_CURLOPT_TIMEOUT,        30 )

   nResult := curl_easy_perform( hCurl )
   IF nResult == HB_CURLE_OK
      nHttpCode := curl_easy_getinfo( hCurl, HB_CURLINFO_RESPONSE_CODE )
   ENDIF

   curl_easy_setopt( hCurl, HB_CURLOPT_DL_FILE_CLOSE )
   curl_easy_cleanup( hCurl )
   curl_global_cleanup()

   IF nResult == HB_CURLE_OK .AND. nHttpCode == 200
      RETURN { .T., cFile }
   ENDIF
RETURN { .F., "CURL error: " + curl_easy_strerror(nResult) + " HTTP:" + hb_NToS(nHttpCode) }


// ============================================================
// URL Encode — RFC 3986
// Necesario para enviar el JSON como parámetro GET
// ============================================================
FUNCTION Ejemplo_UrlEncode( c )
   LOCAL cRes := "", i, ch
   LOCAL safe := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"
   FOR i := 1 TO Len(c)
      ch := SubStr(c, i, 1)
      IF At(ch, safe) > 0
         cRes += ch
      ELSE
         cRes += "%" + Upper( hb_NumToHex( Asc(ch), 2 ) )
      ENDIF
   NEXT
RETURN cRes