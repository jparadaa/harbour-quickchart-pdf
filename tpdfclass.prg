// {% hb_SetEnv( "HB_INCLUDE", If( "Linux" $ OS(), "/home/anto/harbour/include", If( "Windows" $ OS(), "c:\harbour\include", "/Users/anto/harbour/include" ) ) ) %}

STATIC aTtfFontList:= NIL
STATIC cFontDir

//--- problemas con cos,sin 

/*function Main()
    
   local def_font, tw, i := 0
   local cPageTitle := "Title of the page"
   local font_list := { "Courier", "Courier-Bold", "Courier-Oblique", "Courier-BoldOblique",;
                        "Helvetica", "Helvetica-Bold", "Helvetica-Oblique", "Times-Roman",;
                        "Times-Bold", "Times-Italic", "Times-BoldItalic", "Symbol", "ZapfDingbats" }
   local oPrn

   oPrn := TPdf():New( "list" )
   oPrn:LoadedFonts := font_list
   if Empty( oPrn:hPdf )
      ? "PDFs not available!"
      return NIL
   endif

   oFont1 := oPrn:DefineFont( 'Helvetica',  24 )
   oFont3 := oPrn:DefineFont( 'Helvetica', 16 )
   oFont2 := oPrn:DefineFont( 'Helvetica-Bold', 16 )
     
   oPrn:StartPage()

   height :=  oprn:nVertSize()
   width  :=  oprn:nHorzSize()
   oPrn:Rect( 10, 10, height-20, width-20 ,  1 )
   oPrn:cmSay(  2, 7, cPageTitle, oFont1 )

   x = 90

   for n = 1 to Len( font_list )
      samp_text = "abcdefgABCDEFG12345!#$%&+-@?"
      oFont2    = oPrn:DefineFont( font_list[ n ], 16 )
      oPrn:Say( x + n * 40,  30, font_list[ n ], oFont2 )
      oPrn:Say( x + n * 40, 220, samp_text, oFont2 )
   next

   oPrn:EndPage()
   oPrn:Save( hb_GetEnv( "PRGPATH" ) + "/data/test2.pdf" )
   oPrn:end()

   ?? "<" + "iframe src='./data/test2.pdf' style='width:calc( 100% + 16px );height:100%;border:0px;margin:-8px;'><" + ;
      "/iframe>"

return nil
*/
//------------------------------------------------------------------------------

#include 'hbclass.ch'
#include 'harupdf.ch'
#include "common.ch"

CLASS TPdf

   DATA hPdf
   DATA hPage
   DATA LoadedFonts
   DATA aPages
   DATA nCurrentPage

   DATA nPageSize INIT HPDF_PAGE_SIZE_A4
   DATA nOrientation INIT HPDF_PAGE_PORTRAIT // HPDF_PAGE_LANDSCAPE
   DATA nHeight, nWidth

   DATA cFileName
   DATA nPermission
   DATA cPassword, cOwnerPassword

   DATA hImageList

   DATA lPreview INIT .F.
   DATA bPreview

   DATA nYOffSet init 0
   DATA nXOffSet init 0
   DATA oFont

   CONSTRUCTOR New( cFileName, cPassword, cOwnerPassword, nPermission, lPreview )
   METHOD SetPage( nPageSize )
   METHOD SetLandscape()
   METHOD SetPortrait()
   METHOD SetCompression( cMode ) INLINE HPDF_SetCompressionMode( ::hPdf, cMode )
   METHOD StartPage()
   METHOD EndPage()
   METHOD Say( nRow, nCol, cText, oFont, nWidth, nClrText, nBkMode, nPad )
   METHOD CmSay( nRow, nCol, cText, oFont, nWidth, nClrText, nBkMode, nPad, lO2A )
   METHOD MmSay( nRow, nCol, cText, oFont, nWidth, nClrText, nBkMode, nPad, lO2A )
   METHOD SayRotate( nTop, nLeft, cTxt, oFont, nClrText, nAngle )
   METHOD DefineFont( cFontName, nSize, lEmbed )
   METHOD Cmtr2Pix( nRow, nCol )
   METHOD Mmtr2Pix( nRow, nCol )
   METHOD CmRect2Pix( aRect )
   METHOD mmRect2Pix( aRect )
   METHOD nVertRes() INLINE 72
   METHOD nHorzRes() INLINE 72
   METHOD nLogPixelX() INLINE 72  // Number of pixels per logical inch
   METHOD nLogPixelY() INLINE 72
   METHOD nVertSize() INLINE HPDF_Page_GetHeight( ::hPage )
   METHOD nHorzSize() INLINE HPDF_Page_GetWidth( ::hPage )
   METHOD SizeInch2Pix( nHeight, nWidth )
   METHOD CmSayBitmap( nRow, nCol, xBitmap, nWidth, nHeight, nRaster, lStrech )
   METHOD SayBitmap( nRow, nCol, xBitmap, nWidth, nHeight, nRaster )
   METHOD GetImageFromFile( cImageFile )
   METHOD Line( nTop, nLeft, nBottom, nRight, oPen )
   METHOD CmLine( nTop, nLeft, nBottom, nRight, oPen )
   METHOD Rect( nTop, nLeft, nBottom, nRight, oPen, nColor )
   METHOD CmRect( nTop, nLeft, nBottom, nRight, oPen, nColor )
   MESSAGE Box METHOD Rect
   MESSAGE CmBox METHOD CmRect
   METHOD RoundBox( nTop, nLeft, nBottom, nRight, nWidth, nHeight, oPen, nColor, nBackColor, lFondo )
   METHOD CmRoundBox( nTop, nLeft, nBottom, nRight, nWidth, nHeight, oPen, nColor, nBackColor, lFondo )
   MESSAGE RoundRect METHOD RoundBox
   MESSAGE CmRoundRect METHOD CmRoundBox

   METHOD SetPen( oPen, nColor )
   METHOD SetRGBStroke( nColor )
   METHOD SetRGBFill( nColor )

   METHOD DashLine( nTop, nLeft, nBottom, nRight, oPen, nDashMode )
   METHOD CmDashLine( nTop, nLeft, nBottom, nRight, oPen, nDashMode )
   METHOD Save( cFilename )
   METHOD SyncPage()
   METHOD CheckPage()
   METHOD GetTextWidth( cText, oFont )
   METHOD GetTextHeight( cText, oFont )
   METHOD setfont(oFont)  INLINE IF(oFont:classname()=="TFONT",::oFont:=fwhtoharufont(oFont,self),::oFont := oFont)

   METHOD End()

ENDCLASS

//------------------------------------------------------------------------------

METHOD New( cFileName, cPassword, cOwnerPassword, nPermission, lPreview ) CLASS TPdf

   ::hPdf := HPDF_New()
   ::LoadedFonts := {}

   if ::hPdf == NIL
      ? "Pdf could not been created!"
      return NIL
   endif

   HPDF_SetCompressionMode( ::hPdf, HPDF_COMP_ALL )


   ::cFileName := cFileName
   ::cPassword := cPassword
   ::cOwnerPassword := cOwnerPassword
   ::nPermission := nPermission

   ::hImageList := { => }
   ::aPages := {}
   ::nCurrentPage := 0

   // Mastintin
   if HB_ISLOGICAL( lPreview )
      ::lPreview:= lPreview
    //  ::bPreview := { || HaruShellexecute( NIL, "open", ::cFileName ) }
   endif

return Self

//------------------------------------------------------------------------------

METHOD SetPage( nPageSize ) CLASS TPdf

   ::nPageSize:= nPageSize
   ::SyncPage()

return Self

//------------------------------------------------------------------------------

METHOD SyncPage() CLASS TPdf

   if ::hPage != NIL
      HPDF_Page_SetSize( ::hPage, ::nPageSize, ::nOrientation )
      ::nHeight := HPDF_Page_GetHeight( ::hPage )
      ::nWidth  := HPDF_Page_GetWidth( ::hPage )
   endif

return NIL

//------------------------------------------------------------------------------

METHOD CheckPage() CLASS TPdf

   if ::hPage == NIL
      ::StartPage()
   endif

return NIL

//------------------------------------------------------------------------------

METHOD SetLandscape() CLASS TPdf

   ::nOrientation:= HPDF_PAGE_LANDSCAPE
   ::SyncPage()

return Self

//------------------------------------------------------------------------------

METHOD SetPortrait() CLASS TPdf

   ::nOrientation:= HPDF_PAGE_PORTRAIT
   ::SyncPage()

return Self

//------------------------------------------------------------------------------

METHOD StartPage() CLASS TPdf

   ::hPage := HPDF_AddPage( ::hPdf )
   AAdd( ::aPages, ::hPage )
   ::nCurrentPage := Len( ::aPages )
   ::SyncPage()

return Self

//------------------------------------------------------------------------------

METHOD EndPage() CLASS TPdf

   ::hPage := NIL

return Self

//------------------------------------------------------------------------------

METHOD Say( nRow, nCol, cText, oFontx, nWidth, nClrText, nBkMode, nPad ) CLASS TPdf

   local c, nTextHeight, nTextWidth,oFont

   IF oFontx <> NIL
      IF oFontx:classname() == "TFONT"
         oFont:=fwhtoharufont(oFontx,self)
      ELSE
         oFont:=oFontx
      ENDIF
   ELSE
      oFont:=oFontx
   ENDIF

   IF oFont == NIL .AND. ::oFont <> NIL
      oFont := ::oFont
   ENDIF

   ::CheckPage()
   HPDF_Page_BeginText( ::hPage )

   if oFont == NIL
      nTextHeight := HPDF_Page_GetCurrentFontSize( ::hPage )
   ELSE
      HPDF_Page_SetFontAndSize( ::hPage, oFont[ 1 ], oFont[ 2 ] )
      nTextHeight := oFont[ 2 ]
   endif

   if ValType( nClrText ) == 'N'
      c := HPDF_Page_GetRGBFill( ::hPage )
      ::SetRGBFill( nClrText )
   endif

   DO CASE
   CASE nPad == NIL .OR. nPad == HPDF_TALIGN_LEFT
      HPDF_Page_TextOut( ::hPage, nCol, ::nHeight - nRow - nTextHeight, cText )
   CASE nPad == HPDF_TALIGN_RIGHT
      nTextWidth := HPDF_Page_TextWidth( ::hPage, cText )
      HPDF_Page_TextOut( ::hPage, nCol + nWidth - nTextWidth, ::nHeight - nRow - nTextHeight, cText )
   OTHERWISE
      nTextWidth := HPDF_Page_TextWidth( ::hPage, cText )
      HPDF_Page_TextOut( ::hPage, nCol + (nWidth / 2) - (nTextWidth/2) , ::nHeight - nRow - nTextHeight, cText )
   ENDCASE







   if ValType( c ) == 'A'
      HPDF_Page_SetRGBFill( ::hPage, c[ 1 ], c[ 2 ], c[ 3 ] )
   endif
   HPDF_Page_EndText( ::hPage )

return Self

//------------------------------------------------------------------------------

METHOD CmSay( nRow, nCol, cText, oFontx, nWidth, nClrText, nBkMode, nPad, lO2A ) CLASS TPdf

   LOCAL ofont

   IF oFontx <> NIL
      IF oFontx:classname() == "TFONT"
         oFont:=fwhtoharufont(oFontx,self)
      ELSE
         oFont:=oFontx
      ENDIF
   ELSE
      oFont:=oFontx
   ENDIF


   ::Cmtr2Pix( @nRow, @nCol )
   if nWidth != Nil
      ::Cmtr2Pix( 0, @nWidth )
   endif
   ::Say( nRow, nCol, cText, oFont, nWidth, nClrText, nBkMode, nPad, lO2A )

return Self
//------------------------------------------------------------------------------

METHOD MmSay( nRow, nCol, cText, oFontx, nWidth, nClrText, nBkMode, nPad, lO2A ) CLASS TPdf

   LOCAL ofont
   IF oFontx <> NIL
      IF oFontx:classname() == "TFONT"
         oFont:=fwhtoharufont(oFontx,self)
      ELSE
         oFont:=oFontx
      ENDIF
   ELSE
      oFont:=oFontx
   ENDIF

   ::Mmtr2Pix( @nRow, @nCol )
  /* if nWidth != Nil
      ::Mmtr2Pix( 0, @nWidth )
   endif*/
   ::Say( nRow, nCol, cText, oFont, nWidth, nClrText, nBkMode, nPad, lO2A )

return Self

//------------------------------------------------------------------------------

METHOD DefineFont( cFontName, nSize, lEmbed ) CLASS TPdf

   local font_list  := { ;
                        "Courier",                  ;
                        "Courier-Bold",             ;
                        "Courier-Oblique",          ;
                        "Courier-BoldOblique",      ;
                        "Helvetica",                ;
                        "Helvetica-Bold",           ;
                        "Helvetica-Oblique",        ;
                        "Helvetica-BoldOblique",    ;
                        "Times-Roman",              ;
                        "Times-Bold",               ;
                        "Times-Italic",             ;
                        "Times-BoldItalic",         ;
                        "Symbol",                   ;
                        "ZapfDingbats"              ;
                      }

   local i, ttf_list

   i := aScan( font_list, {|x| Upper( x ) == Upper( cFontName ) } )
   if i > 0 // Standard font
      cFontName:= font_list[ i ]
   ELSE
      i := aScan( ::LoadedFonts, {|x| Upper( x[ 1 ] ) == Upper( cFontName ) } )
      if i > 0
         cFontName := ::LoadedFonts[ i ][ 2 ]
         //DEBUGMSG 'Activada fuente ' + cFontName
      ELSE
         ttf_list := GetHaruFontList()
         i := aScan( ttf_list, {|x| Upper( x[ 1 ] ) == Upper( cFontName ) } )
         if i > 0
            cFontName := HPDF_LoadTTFontFromFile( ::hPdf, ttf_list[ i, 2 ], lEmbed )
            //DEBUGMSG 'Cargada fuente ' + cFontName
            //DEBUGMSG 'Fichero ' + ttf_list[ i, 2 ]
            AAdd( ::LoadedFonts, { ttf_list[ i, 1 ], cFontName } )
         ELSE
            Alert( 'Fuente desconocida '+cFontName )
            return NIL
         endif
      endif
   endif

return { HPDF_GetFont( ::hPdf, cFontName, "WinAnsiEncoding" ), nSize }

//------------------------------------------------------------------------------

METHOD Cmtr2Pix( nRow, nCol ) CLASS TPdf

   nRow *= 72 / 2.54
   nCol *= 72 / 2.54

return { nRow, nCol }

//------------------------------------------------------------------------------

METHOD Mmtr2Pix( nRow, nCol ) CLASS TPdf

   nRow *= 72 / 25.4
   nCol *= 72 / 25.4

 return { nRow, nCol }

//------------------------------------------------------------------------------

METHOD CmRect2Pix( aRect ) CLASS TPdf

   local aTmp[ 4 ]

   aTmp[ 1 ] = Max( 0, aRect[ 1 ] * 72 / 2.54 )
   aTmp[ 2 ] = Max( 0, aRect[ 2 ] * 72 / 2.54 )
   aTmp[ 3 ] = Max( 0, aRect[ 3 ] * 72 / 2.54 )
   aTmp[ 4 ] = Max( 0, aRect[ 4 ] * 72 / 2.54 )

return aTmp
//------------------------------------------------------------------------------

METHOD mmRect2Pix( aRect ) CLASS TPdf

   local aTmp[ 4 ]

   aTmp[ 1 ] = Max( 0, aRect[ 1 ] * 72 / 25.4 )
   aTmp[ 2 ] = Max( 0, aRect[ 2 ] * 72 / 25.4 )
   aTmp[ 3 ] = Max( 0, aRect[ 3 ] * 72 / 25.4 )
   aTmp[ 4 ] = Max( 0, aRect[ 4 ] * 72 / 25.4 )

return aTmp

//------------------------------------------------------------------------------

METHOD SizeInch2Pix( nHeight, nWidth ) CLASS TPdf

   nHeight *= 72
   nWidth *= 72

return { nHeight, nWidth }

//------------------------------------------------------------------------------

METHOD GetImageFromFile( cImageFile ) CLASS TPdf

   if hb_HHasKey( ::hImageList, cImageFile )
      return ::hImageList[ cImageFile ]
   endif
   if ! File( cImageFile )
      IF( Lower( Right( cImageFile, 4 ) ) == '.bmp' ) // En el c�digo esta como bmp, probar si ya fue transformado a png
         cImageFile := Left( cImageFile, Len( cImageFile ) - 3 ) + 'png'
         return ::GetImageFromFile( cImageFile )
      ELSE
         ? cImageFile + ' not found'
         return NIL
      endif
   endif
   IF( Lower( Right( cImageFile, 4 ) ) == '.png' )
      return ( ::hImageList[ cImageFile ] := HPDF_LoadPngImageFromFile(::hPdf, cImageFile ) )
   endif

return ::hImageList[ cImageFile ] := HPDF_LoadJpegImageFromFile(::hPdf, cImageFile )

//------------------------------------------------------------------------------

METHOD SayBitmap( nRow, nCol, xBitmap, nWidth, nHeight, nRaster ) CLASS TPdf

   local image

   if !Empty( image := ::GetImageFromFile( xBitmap ) )
      HPDF_Page_DrawImage( ::hPage, image, nCol, ::nHeight - nRow - nHeight, nWidth, nHeight /* iw, ih*/)
   endif

return Self

//------------------------------------------------------------------------------

METHOD Line( nTop, nLeft, nBottom, nRight, oPen ) CLASS TPdf

   if oPen != NIL
      ::SetPen( oPen )
   endif

   HPDF_Page_MoveTo ( ::hPage, nLeft, ::nHeight - nTop )
   HPDF_Page_LineTo ( ::hPage, nRight, ::nHeight - nBottom )
   HPDF_Page_Stroke ( ::hPage )

return Self

//------------------------------------------------------------------------------

METHOD Save( cFilename ) CLASS TPdf

   FErase( cFilename )

   if ValType( ::nPermission ) != 'N'
      ::nPermission := ( HPDF_ENABLE_READ + HPDF_ENABLE_PRINT + HPDF_ENABLE_COPY )
   endif

   if ValType( ::cPassword ) == 'C' .AND. !Empty( ::cPassword )
      if Empty( ::cOwnerPassword )
         ::cOwnerPassword := ::cPassword + '+1'
      endif
      HPDF_SetPassword( ::hPdf, ::cOwnerPassword, ::cPassword )
      HPDF_SetPermission( ::hPdf, ::nPermission )
   endif

return HPDF_SaveToFile ( ::hPdf, cFilename )

//------------------------------------------------------------------------------

METHOD GetTextWidth( cText, oFontx ) CLASS TPdf
   LOCAL ofont
   IF oFontx <> NIL
      IF oFontx:classname() == "TFONT"
         oFont:=fwhtoharufont(oFontx,self)
      ELSE
         oFont:=oFontx
      ENDIF
   ELSE
      oFont:=oFontx
   ENDIF

   HPDF_Page_SetFontAndSize( ::hPage, oFont[ 1 ], oFont[ 2 ] )

return HPDF_Page_TextWidth( ::hPage, cText )

//------------------------------------------------------------------------------

METHOD GetTextHeight( cText, oFontx ) CLASS TPdf
   LOCAL ofont
   IF oFontx <> NIL
      IF oFontx:classname() == "TFONT"
         oFont:=fwhtoharufont(oFontx,self)
      ELSE
         oFont:=oFontx
      ENDIF
   ELSE
      oFont:=oFontx
   ENDIF


   HPDF_Page_SetFontAndSize( ::hPage, oFont[ 1 ], oFont[ 2 ] )

return oFont[ 2 ] // height of the font when we create it

//------------------------------------------------------------------------------

METHOD End() CLASS TPdf

   local nResult

   if ValType( ::cFileName ) == 'C'
      nResult := ::Save( ::cFileName )
   endif

   HPDF_Free( ::hPdf )

   ::aPages := {}

   if ::lPreview
      Eval( ::bPreview, Self )
   endif

return nResult

//------------------------------------------------------------------------------

METHOD Rect( nTop, nLeft, nBottom, nRight, oPen, nColor ) CLASS TPdf

   HPDF_Page_GSave( ::hPage )
   ::SetPen( oPen, nColor )

   HPDF_Page_Rectangle( ::hPage, nLeft, ::nHeight - nBottom, nRight - nLeft,  nBottom - nTop )

   HPDF_Page_Stroke ( ::hPage )
   HPDF_Page_GRestore( ::hPage )

return Self


METHOD CmRect( nTop, nLeft, nBottom, nRight, oPen, nColor ) CLASS TPdf

   ::Rect( nTop * 72 / 2.54, nLeft * 72 / 2.54, nBottom * 72 / 2.54, nRight * 72 / 2.54, oPen, nColor )

return Self

METHOD CmLine( nTop, nLeft, nBottom, nRight, oPen ) CLASS TPdf

   ::Line( nTop * 72 / 2.54, nLeft * 72 / 2.54, nBottom * 72 / 2.54, nRight * 72 / 2.54, oPen )

return Self

METHOD CmDashLine( nTop, nLeft, nBottom, nRight, oPen, nDashMode ) CLASS TPdf

   ::DashLine( nTop * 72 / 2.54, nLeft * 72 / 2.54, nBottom * 72 / 2.54, nRight * 72 / 2.54, oPen, nDashMode )

return Self

METHOD DashLine( nTop, nLeft, nBottom, nRight, oPen, nDashMode ) CLASS TPdf

   HPDF_Page_SetDash( ::hPage, { 3, 7 }, 2, 2 )
   ::Line( nTop, nLeft, nBottom, nRight, oPen )
   HPDF_Page_SetDash( ::hPage, NIL, 0, 0 )

return Self

//------------------------------------------------------------------------------

METHOD CmSayBitmap( nRow, nCol, xBitmap, nWidth, nHeight, nRaster, lStrech  ) CLASS TPdf

   if !Empty(  nWidth  )
     nWidth := nWidth * 72 / 2.54
   endif

   if !Empty(  nHeight  )
      nHeight := nHeight * 72 / 2.54
   endif

   ::SayBitmap( nRow * 72 / 2.54, nCol * 72 / 2.54, xBitmap, nWidth, nHeight, nRaster, lStrech )

return nil

//------------------------------------------------------------------------------

METHOD RoundBox( nTop, nLeft, nBottom, nRight, nWidth, nHeight, oPen, nColor, nBackColor ) CLASS TPdf

   local nRay
   local xposTop, xposBotton
   local nRound

   HB_DEFAULT( @nWidth, 0 )
   HB_DEFAULT( @nHeight, 0 )

      nRound:= Min( nWidth, nHeight )

      nRound := nRound / 250

   HPDF_Page_GSave(::hPage)
   ::SetPen( oPen, nColor )

   if HB_ISNUMERIC( nBackColor )
      ::SetRGBFill( nBackColor )
   endif

   if Empty( nRound )
      HPDF_Page_Rectangle( ::hPage, nLeft, ::nHeight - nBottom, nRight - nLeft,  nBottom - nTop )
   ELSE
      nRay = Round( iif( ::nWidth > ::nHeight, Min( nRound,Int( (nBottom - nTop ) / 2 ) ), Min( nRound,Int( (nRight - nLeft) / 2 ) ) ), 0 )

      xposTop := ::nHeight - nTop
      xposBotton := ::nHeight - nBottom

      HPDF_Page_MoveTo ( ::hPage, nLeft + nRay,  xposTop )
      HPDF_Page_LineTo ( ::hPage, nRight - nRay, xposTop )

      HPDF_Page_CurveTo( ::hPage, nRight, xposTop, nRight,  xposTop, nRight,  xposTop - nRay )

      HPDF_Page_LineTo ( ::hPage, nRight, xposBotton + nRay )
      HPDF_Page_CurveTo( ::hPage, nRight, xposBotton, nRight, xposBotton, nRight - nRay,  xposBotton  )
      HPDF_Page_LineTo ( ::hPage, nLeft + nRay, xposBotton )
      HPDF_Page_CurveTo( ::hPage, nLeft, xposBotton,  nLeft, xposBotton, nLeft, xposBotton + nRay )

      HPDF_Page_LineTo ( ::hPage, nLeft, xposTop - nRay )
      HPDF_Page_CurveTo( ::hPage, nLeft, xposTop,  nLeft, xposTop, nLeft + nRay, xposTop )
   endif

   if HB_ISNUMERIC( nBackColor )
      HPDF_Page_FillStroke ( ::hPage )
   ELSE
      HPDF_Page_Stroke ( ::hPage )
   endif
   HPDF_Page_GRestore( ::hPage )

return Self

//------------------------------------------------------------------------------

METHOD SetPen( oPen, nColor ) CLASS TPdf

   if oPen != NIL
      if ValType( oPen ) == 'N'
         HPDF_Page_SetLineWidth( ::hPage, oPen )
      ELSE
         HPDF_Page_SetLineWidth( ::hPage, oPen:nWidth )
         nColor:= oPen:nColor
      endif
   endif

   if ValType( nColor ) == 'N'
      ::SetRGBStroke( nColor )
   endif

return SELF

//------------------------------------------------------------------------------

METHOD SetRGBStroke( nColor ) CLASS TPdf

  HPDF_Page_SetRGBStroke( ::hPage, ( nColor  % 256 ) / 256.00,;
                                   ( Int( nColor / 0x100 )  % 256 ) / 256.00,;
                                   ( Int( nColor / 0x10000 ) % 256 ) / 256.00 )
return NIL

//------------------------------------------------------------------------------

METHOD SetRGBFill( nColor ) CLASS TPdf

    HPDF_Page_SetRGBFill( ::hPage, HB_BitAnd( Int( nColor ), 0xFF ) / 255.00,;
                                   HB_BitAnd( HB_BitShift( Int( nColor ), -8 ), 0xFF ) / 255.00,;
                                   HB_BitAnd( HB_BitShift( Int( nColor ), -16 ), 0xFF ) / 255.00 )


//  HPDF_Page_SetRGBFill( ::hPage,  nRGBRed( nColor ) / 255.00,;
//                                  nRGBGeen( nColor ) / 255.00,;
//                                  nRGBBlue( nColor ) / 255.00 )

//  HPDF_Page_SetRGBFill( ::hPage, ( nColor  % 256 ) / 256.00,;
//                                  ( Int( nColor / 0x100 )  % 256 ) / 256.00,;
//                                  ( Int( nColor / 0x10000 ) % 256 ) / 256.00 )

return NIL

//------------------------------------------------------------------------------

METHOD CmRoundBox( nTop, nLeft, nBottom, nRight, nWidth, nHeight, oPen, nColor, nBackColor, lFondo ) ;
   CLASS TPdf

   DEFAULT nWidth To 0, nHeight TO 0

return ::RoundBox( nTop * 72 / 2.54, nLeft * 72 / 2.54, nBottom * 72 / 2.54, nRight * 72 / 2.54,;
       nWidth * 72 / 2.54 , nHeight * 72 / 2.54 , oPen, nColor, nBackColor, lFondo )

//------------------------------------------------------------------------------

METHOD SayRotate( nTop, nLeft, cTxt, oFontx, nClrText, nAngle ) CLASS TPdf

   local aBackColor
   local nRadian := ( nAngle / 180 ) * 3.141592 /* Calcurate the radian value. */
   LOCAL ofont

   IF oFontx <> NIL
      IF oFontx:classname() == "TFONT"
         oFont:=fwhtoharufont(oFontx,self)
      ELSE
         oFont:=oFontx
      ENDIF
   ELSE
      oFont:=oFontx
   ENDIF


   IF oFont == NIL .AND. ::oFont <> NIL
      oFont := ::oFont
   ENDIF


    if ValType( nClrText ) == 'N'
       aBackColor:= HPDF_Page_GetRGBFill( ::hPage )
      ::SetRGBFill( nClrText )
   endif

   /* FONT and SIZE*/
   if !Empty( oFont )
       HPDF_Page_SetFontAndSize( ::hPage, oFont[1], oFont[2] )
   EndI

   /* Rotating text */
   HPDF_Page_BeginText( ::hPage )
   HPDF_Page_SetTextMatrix( ::hPage, cos( nRadian ),;
                                     sin( nRadian ),;
                                     -( sin( nRadian ) ),;
                                     cos( nRadian ), nLeft, HPDF_Page_GetHeight( ::hPage )-( nTop ) )
   HPDF_Page_ShowText( ::hPage, cTxt )

   if ValType( aBackColor ) == 'A'
      HPDF_Page_SetRGBFill( ::hPage, aBackColor[1], aBackColor[2], aBackColor[3] )
   endif

   HPDF_Page_EndText( ::hPage )

return NIL

//------------------------------------------------------------------------------

FUNCTION SetHaruFontDir(cDir)

   local cPrevValue:= cFontDir
   if ValType( cDir ) == 'C' .AND. HB_DirExists( cDir )
      cFontDir:= cDir
   endif

return cPrevValue

//------------------------------------------------------------------------------

FUNCTION GetHaruFontDir()

#define CSIDL_FONTS 0x0014

   if cFontDir == NIL
      cFontDir:= /*Haru*/ GetSpecialFolder( CSIDL_FONTS )
   endif

return cFontDir

//------------------------------------------------------------------------------

FUNCTION GetHaruFontList()

   if aTtfFontList == NIL
      InitTtfFontList()
   endif

return aTtfFontList

//------------------------------------------------------------------------------

STATIC FUNCTION InitTtfFontList()

 /*  local aDfltList:= { { 'Arial', 'arial.ttf' } ;
                     , { 'Verdana', 'verdana.ttf' } ;
                     , { 'Courier New', 'cour.ttf' } ;
                     , { 'Calibri', 'calibri.ttf' } ;
                     , { 'Tahoma', 'tahoma.ttf' } ;
                     , { 'Tahoma-Bold', 'tahomabd.ttf' };
                  } */

  LOCAL aDfltList := {;
                    {"Arial","arial.ttf" },;
                    {"Arial Black","ariblk.ttf" },;
                    {"Arial Bold","arialbd.ttf" },;
                    {"Arial Bold Italic","arialbi.ttf" },;
                    {"Arial Italic","ariali.ttf" },;
                    {"Bahnschrift","bahnschrift.ttf" },;
                    {"Calibri","calibri.ttf" },;
                    {"Calibri Bold","calibrib.ttf" },;
                    {"Calibri Bold Italic","calibriz.ttf" },;
                    {"Calibri Italic","calibrii.ttf" },;
                    {"Calibri Light","calibril.ttf" },;
                    {"Calibri Light Italic","calibrili.ttf" },;
                    {"Cambria Bold","cambriab.ttf" },;
                    {"Cambria Bold Italic","cambriaz.ttf" },;
                    {"Cambria Italic","cambriai.ttf" },;
                    {"Candara","candara.ttf" },;
                    {"Candara Bold","candarab.ttf" },;
                    {"Candara Bold Italic","candaraz.ttf" },;
                    {"Candara Italic","candarai.ttf" },;
                    {"Candara Light","candaral.ttf" },;
                    {"Candara Light Italic","candarali.ttf" },;
                    {"Comic Sans MS","comic.ttf" },;
                    {"Comic Sans MS Bold","comicbd.ttf" },;
                    {"Comic Sans MS Bold Italic","comicz.ttf" },;
                    {"Comic Sans MS Italic","comici.ttf" },;
                    {"Consolas","consola.ttf" },;
                    {"Consolas Bold","consolab.ttf" },;
                    {"Consolas Bold Italic","consolaz.ttf" },;
                    {"Consolas Italic","consolai.ttf" },;
                    {"Constantia","constan.ttf" },;
                    {"Constantia Bold","constanb.ttf" },;
                    {"Constantia Bold Italic","constanz.ttf" },;
                    {"Constantia Italic","constani.ttf" },;
                    {"Corbel","corbel.ttf" },;
                    {"Corbel Bold","corbelb.ttf" },;
                    {"Corbel Bold Italic","corbelz.ttf" },;
                    {"Corbel Italic","corbeli.ttf" },;
                    {"Corbel Light","corbell.ttf" },;
                    {"Corbel Light Italic","corbelli.ttf" },;
                    {"Courier New","cour.ttf" },;
                    {"Courier New Bold","courbd.ttf" },;
                    {"Courier New Bold Italic","courbi.ttf" },;
                    {"Courier New Italic","couri.ttf" },;
                    {"Ebrima","ebrima.ttf" },;
                    {"Ebrima Bold","ebrimabd.ttf" },;
                    {"Franklin Gothic Medium","framd.ttf" },;
                    {"Franklin Gothic Medium Italic","framdit.ttf" },;
                    {"Gabriola","Gabriola.ttf" },;
                    {"Gadugi","gadugi.ttf" },;
                    {"Gadugi Bold","gadugib.ttf" },;
                    {"Georgia","georgia.ttf" },;
                    {"Georgia Bold","georgiab.ttf" },;
                    {"Georgia Bold Italic","georgiaz.ttf" },;
                    {"Georgia Italic","georgiai.ttf" },;
                    {"Impact","impact.ttf" },;
                    {"Ink Free","Inkfree.ttf" },;
                    {"Javanese Text","javatext.ttf" },;
                    {"Leelawadee UI","leelawui.ttf" },;
                    {"Leelawadee UI Bold","leelauib.ttf" },;
                    {"Leelawadee UI Semilight","leeluisl.ttf" },;
                    {"Lucida Console","lucon.ttf" },;
                    {"Lucida Sans Unicode","l_10646.ttf" },;
                    {"Malgun Gothic","malgun.ttf" },;
                    {"Malgun Gothic Bold","malgunbd.ttf" },;
                    {"Malgun Gothic SemiLight","malgunsl.ttf" },;
                    {"Microsoft Himalaya","himalaya.ttf" },;
                    {"Microsoft New Tai Lue","ntailu.ttf" },;
                    {"Microsoft New Tai Lue Bold","ntailub.ttf" },;
                    {"Microsoft PhagsPa","phagspa.ttf" },;
                    {"Microsoft PhagsPa Bold","phagspab.ttf" },;
                    {"Microsoft Sans Serif","micross.ttf" },;
                    {"Microsoft Tai Le","taile.ttf" },;
                    {"Microsoft Tai Le Bold","taileb.ttf" },;
                    {"Microsoft Yi Baiti","msyi.ttf" },;
                    {"Mongolian Baiti","monbaiti.ttf" },;
                    {"MV Boli","mvboli.ttf" },;
                    {"Myanmar Text","mmrtext.ttf" },;
                    {"Myanmar Text Bold","mmrtextb.ttf" },;
                    {"Nirmala UI","Nirmala.ttf" },;
                    {"Nirmala UI Bold","NirmalaB.ttf" },;
                    {"Nirmala UI Semilight","NirmalaS.ttf" },;
                    {"Palatino Linotype","pala.ttf" },;
                    {"Palatino Linotype Bold","palab.ttf" },;
                    {"Palatino Linotype Bold Italic","palabi.ttf" },;
                    {"Palatino Linotype Italic","palai.ttf" },;
                    {"Segoe MDL2 Assets","segmdl2.ttf" },;
                    {"Segoe Print","segoepr.ttf" },;
                    {"Segoe Print Bold","segoeprb.ttf" },;
                    {"Segoe Script","segoesc.ttf" },;
                    {"Segoe Script Bold","segoescb.ttf" },;
                    {"Segoe UI","segoeui.ttf" },;
                    {"Segoe UI Black","seguibl.ttf" },;
                    {"Segoe UI Black Italic","seguibli.ttf" },;
                    {"Segoe UI Bold","segoeuib.ttf" },;
                    {"Segoe UI Bold Italic","segoeuiz.ttf" },;
                    {"Segoe UI Emoji","seguiemj.ttf" },;
                    {"Segoe UI Historic","seguihis.ttf" },;
                    {"Segoe UI Italic","segoeuii.ttf" },;
                    {"Segoe UI Light","segoeuil.ttf" },;
                    {"Segoe UI Light Italic","seguili.ttf" },;
                    {"Segoe UI Semibold","seguisb.ttf" },;
                    {"Segoe UI Semibold Italic","seguisbi.ttf" },;
                    {"Segoe UI Semilight","segoeuisl.ttf" },;
                    {"Segoe UI Semilight Italic","seguisli.ttf" },;
                    {"Segoe UI Symbol","seguisym.ttf" },;
                    {"SimSun-ExtB","simsunb.ttf" },;
                    {"Sylfaen","sylfaen.ttf" },;
                    {"Symbol","symbol.ttf" },;
                    {"Tahoma","tahoma.ttf" },;
                    {"Tahoma Bold","tahomabd.ttf" },;
                    {"Times New Roman","times.ttf" },;
                    {"Times New Roman Bold","timesbd.ttf" },;
                    {"Times New Roman Bold Italic","timesbi.ttf" },;
                    {"Times New Roman Italic","timesi.ttf" },;
                    {"Trebuchet MS","trebuc.ttf" },;
                    {"Trebuchet MS Bold","trebucbd.ttf" },;
                    {"Trebuchet MS Bold Italic","trebucbi.ttf" },;
                    {"Trebuchet MS Italic","trebucit.ttf" },;
                    {"Verdana","verdana.ttf" },;
                    {"Verdana Bold","verdanab.ttf" },;
                    {"Verdana Bold Italic","verdanaz.ttf" },;
                    {"Verdana Italic","verdanai.ttf" },;
                    {"Webdings","webdings.ttf" },;
                    {"Wingdings","wingding.ttf" },;
                    {"Holo MDL2 Assets","holomdl2.ttf" },;
                    {"ZWAdobeF","ZWAdobeF.ttf" },;
                    {"Book Antiqua Bold","ANTQUAB.ttf" },;
                    {"Book Antiqua Bold Italic","ANTQUABI.ttf" },;
                    {"Book Antiqua Italic","ANTQUAI.ttf" },;
                    {"Book Antiqua","BKANT.ttf" },;
                    {"Century Gothic","GOTHIC.ttf" },;
                    {"Century Gothic Bold","GOTHICB.ttf" },;
                    {"Century Gothic Bold Italic","GOTHICBI.ttf" },;
                    {"Century Gothic Italic","GOTHICI.ttf" },;
                    {"Bookshelf Symbol 7","BSSYM7.ttf" },;
                    {"MS Reference Sans Serif","REFSAN.ttf" },;
                    {"MS Reference Specialty","REFSPCL.ttf" },;
                    {"Bradley Hand ITC","BRADHITC.ttf" },;
                    {"Freestyle Script","FREESCPT.ttf" },;
                    {"French Script MT","FRSCRIPT.ttf" },;
                    {"Juice ITC","JUICE___.ttf" },;
                    {"Kristen ITC","ITCKRIST.ttf" },;
                    {"Lucida Handwriting Italic","LHANDW.ttf" },;
                    {"Mistral","MISTRAL.ttf" },;
                    {"Papyrus","PAPYRUS.ttf" },;
                    {"Pristina","PRISTINA.ttf" },;
                    {"Tempus Sans ITC","TEMPSITC.ttf" },;
                    {"Garamond","GARA.ttf" },;
                    {"Garamond Bold","GARABD.ttf" },;
                    {"Garamond Italic","GARAIT.ttf" },;
                    {"Monotype Corsiva","MTCORSVA.ttf" },;
                    {"Agency FB Bold","AGENCYB.ttf" },;
                    {"Agency FB","AGENCYR.ttf" },;
                    {"Arial Rounded MT Bold","ARLRDBD.ttf" },;
                    {"Blackadder ITC","ITCBLKAD.ttf" },;
                    {"Bodoni MT Bold","BOD_B.ttf" },;
                    {"Bodoni MT Bold Italic","BOD_BI.ttf" },;
                    {"Bodoni MT Italic","BOD_I.ttf" },;
                    {"Bodoni MT","BOD_R.ttf" },;
                    {"Bodoni MT Black Italic","BOD_BLAI.ttf" },;
                    {"Bodoni MT Black","BOD_BLAR.ttf" },;
                    {"Bodoni MT Condensed Bold","BOD_CB.ttf" },;
                    {"Bodoni MT Condensed Bold Italic","BOD_CBI.ttf" },;
                    {"Bodoni MT Condensed Italic","BOD_CI.ttf" },;
                    {"Bodoni MT Condensed","BOD_CR.ttf" },;
                    {"Bookman Old Style","BOOKOS.ttf" },;
                    {"Bookman Old Style Bold","BOOKOSB.ttf" },;
                    {"Bookman Old Style Bold Italic","BOOKOSBI.ttf" },;
                    {"Bookman Old Style Italic","BOOKOSI.ttf" },;
                    {"Calisto MT","CALIST.ttf" },;
                    {"Calisto MT Bold","CALISTB.ttf" },;
                    {"Calisto MT Bold Italic","CALISTBI.ttf" },;
                    {"Calisto MT Italic","CALISTI.ttf" },;
                    {"Castellar","CASTELAR.ttf" },;
                    {"Century Schoolbook","CENSCBK.ttf" },;
                    {"Century Schoolbook Bold","SCHLBKB.ttf" },;
                    {"Century Schoolbook Bold Italic","SCHLBKBI.ttf" },;
                    {"Century Schoolbook Italic","SCHLBKI.ttf" },;
                    {"Copperplate Gothic Bold","COPRGTB.ttf" },;
                    {"Copperplate Gothic Light","COPRGTL.ttf" },;
                    {"Curlz MT","CURLZ___.ttf" },;
                    {"Edwardian Script ITC","ITCEDSCR.ttf" },;
                    {"Elephant","ELEPHNT.ttf" },;
                    {"Elephant Italic","ELEPHNTI.ttf" },;
                    {"Engravers MT","ENGR.ttf" },;
                    {"Eras Bold ITC","ERASBD.ttf" },;
                    {"Eras Demi ITC","ERASDEMI.ttf" },;
                    {"Eras Light ITC","ERASLGHT.ttf" },;
                    {"Eras Medium ITC","ERASMD.ttf" },;
                    {"Felix Titling","FELIXTI.ttf" },;
                    {"Forte","FORTE.ttf" },;
                    {"Franklin Gothic Book","FRABK.ttf" },;
                    {"Franklin Gothic Book Italic","FRABKIT.ttf" },;
                    {"Franklin Gothic Demi","FRADM.ttf" },;
                    {"Franklin Gothic Demi Italic","FRADMIT.ttf" },;
                    {"Franklin Gothic Demi Cond","FRADMCN.ttf" },;
                    {"Franklin Gothic Heavy","FRAHV.ttf" },;
                    {"Franklin Gothic Heavy Italic","FRAHVIT.ttf" },;
                    {"Franklin Gothic Medium Cond","FRAMDCN.ttf" },;
                    {"Gigi","GIGI.ttf" },;
                    {"Gill Sans MT Bold Italic","GILBI___.ttf" },;
                    {"Gill Sans MT Bold","GILB____.ttf" },;
                    {"Gill Sans MT Italic","GILI____.ttf" },;
                    {"Gill Sans MT","GIL_____.ttf" },;
                    {"Gill Sans MT Condensed","GILC____.ttf" },;
                    {"Gill Sans Ultra Bold","GILSANUB.ttf" },;
                    {"Gill Sans Ultra Bold Condensed","GILLUBCD.ttf" },;
                    {"Gill Sans MT Ext Condensed Bold","GLSNECB.ttf" },;
                    {"Gloucester MT Extra Condensed","GLECB.ttf" },;
                    {"Goudy Old Style","GOUDOS.ttf" },;
                    {"Goudy Old Style Bold","GOUDOSB.ttf" },;
                    {"Goudy Old Style Italic","GOUDOSI.ttf" },;
                    {"Goudy Stout","GOUDYSTO.ttf" },;
                    {"Imprint MT Shadow","IMPRISHA.ttf" },;
                    {"Lucida Sans Regular","LSANS.ttf" },;
                    {"Lucida Sans Demibold Roman","LSANSD.ttf" },;
                    {"Lucida Sans Demibold Italic","LSANSDI.ttf" },;
                    {"Lucida Sans Italic","LSANSI.ttf" },;
                    {"Lucida Sans Typewriter Regular","LTYPE.ttf" },;
                    {"Lucida Sans Typewriter Bold","LTYPEB.ttf" },;
                    {"Lucida Sans Typewriter Bold Oblique","LTYPEBO.ttf" },;
                    {"Lucida Sans Typewriter Oblique","LTYPEO.ttf" },;
                    {"Maiandra GD","MAIAN.ttf" },;
                    {"OCR A Extended","OCRAEXT.ttf" },;
                    {"Palace Script MT","PALSCRI.ttf" },;
                    {"Perpetua Bold Italic","PERBI___.ttf" },;
                    {"Perpetua Bold","PERB____.ttf" },;
                    {"Perpetua Italic","PERI____.ttf" },;
                    {"Perpetua","PER_____.ttf" },;
                    {"Perpetua Titling MT Bold","PERTIBD.ttf" },;
                    {"Perpetua Titling MT Light","PERTILI.ttf" },;
                    {"Rage Italic","RAGE.ttf" },;
                    {"Rockwell","ROCK.ttf" },;
                    {"Rockwell Bold","ROCKB.ttf" },;
                    {"Rockwell Bold Italic","ROCKBI.ttf" },;
                    {"Rockwell Italic","ROCKI.ttf" },;
                    {"Rockwell Condensed Bold","ROCCB___.ttf" },;
                    {"Rockwell Condensed","ROCC____.ttf" },;
                    {"Rockwell Extra Bold","ROCKEB.ttf" },;
                    {"Script MT Bold","SCRIPTBL.ttf" },;
                    {"Tw Cen MT Bold Italic","TCBI____.ttf" },;
                    {"Tw Cen MT Bold","TCB_____.ttf" },;
                    {"Tw Cen MT Condensed","TCCM____.ttf" },;
                    {"Tw Cen MT Condensed Bold","TCCB____.ttf" },;
                    {"Tw Cen MT Condensed Extra Bold","TCCEB.ttf" },;
                    {"Tw Cen MT Italic","TCMI____.ttf" },;
                    {"Tw Cen MT","TCM_____.ttf" },;
                    {"Algerian","ALGER.ttf" },;
                    {"Baskerville Old Face","BASKVILL.ttf" },;
                    {"Bauhaus 93","BAUHS93.ttf" },;
                    {"Bell MT","BELL.ttf" },;
                    {"Bell MT Bold","BELLB.ttf" },;
                    {"Bell MT Italic","BELLI.ttf" },;
                    {"Berlin Sans FB Bold","BRLNSB.ttf" },;
                    {"Berlin Sans FB Demi Bold","BRLNSDB.ttf" },;
                    {"Berlin Sans FB","BRLNSR.ttf" },;
                    {"Bernard MT Condensed","BERNHC.ttf" },;
                    {"Bodoni MT Poster Compressed","BOD_PSTC.ttf" },;
                    {"Britannic Bold","BRITANIC.ttf" },;
                    {"Broadway","BROADW.ttf" },;
                    {"Brush Script MT Italic","BRUSHSCI.ttf" },;
                    {"Californian FB Bold","CALIFB.ttf" },;
                    {"Californian FB Italic","CALIFI.ttf" },;
                    {"Californian FB","CALIFR.ttf" },;
                    {"Centaur","CENTAUR.ttf" },;
                    {"Chiller","CHILLER.ttf" },;
                    {"Colonna MT","COLONNA.ttf" },;
                    {"Cooper Black","COOPBL.ttf" },;
                    {"Footlight MT Light","FTLTLT.ttf" },;
                    {"Harlow Solid Italic","HARLOWSI.ttf" },;
                    {"Harrington","HARNGTON.ttf" },;
                    {"High Tower Text","HTOWERT.ttf" },;
                    {"High Tower Text Italic","HTOWERTI.ttf" },;
                    {"Jokerman","JOKERMAN.ttf" },;
                    {"Kunstler Script","KUNSTLER.ttf" },;
                    {"Lucida Bright","LBRITE.ttf" },;
                    {"Lucida Bright Demibold","LBRITED.ttf" },;
                    {"Lucida Bright Demibold Italic","LBRITEDI.ttf" },;
                    {"Lucida Bright Italic","LBRITEI.ttf" },;
                    {"Lucida Calligraphy Italic","LCALLIG.ttf" },;
                    {"Lucida Fax Regular","LFAX.ttf" },;
                    {"Lucida Fax Demibold","LFAXD.ttf" },;
                    {"Lucida Fax Demibold Italic","LFAXDI.ttf" },;
                    {"Lucida Fax Italic","LFAXI.ttf" },;
                    {"Magneto Bold","MAGNETOB.ttf" },;
                    {"Matura MT Script Capitals","MATURASC.ttf" },;
                    {"Modern No. 20","MOD20.ttf" },;
                    {"Niagara Engraved","NIAGENG.ttf" },;
                    {"Niagara Solid","NIAGSOL.ttf" },;
                    {"Old English Text MT","OLDENGL.ttf" },;
                    {"Onyx","ONYX.ttf" },;
                    {"Parchment","PARCHM.ttf" },;
                    {"Playbill","PLAYBILL.ttf" },;
                    {"Poor Richard","POORICH.ttf" },;
                    {"Ravie","RAVIE.ttf" },;
                    {"Informal Roman","INFROMAN.ttf" },;
                    {"Showcard Gothic","SHOWG.ttf" },;
                    {"Snap ITC","SNAP____.ttf" },;
                    {"Stencil","STENCIL.ttf" },;
                    {"Viner Hand ITC","VINERITC.ttf" },;
                    {"Vivaldi Italic","VIVALDII.ttf" },;
                    {"Vladimir Script","VLADIMIR.ttf" },;
                    {"Wide Latin","LATINWD.ttf" },;
                    {"MS Mincho","MSMINCHO.ttf" },;
                    {"Arial Narrow","ARIALN.ttf" },;
                    {"Arial Narrow Bold","ARIALNB.ttf" },;
                    {"Arial Narrow Bold Italic","ARIALNBI.ttf" },;
                    {"Arial Narrow Italic","ARIALNI.ttf" },;
                    {"SWGamekeys MT","Swkeys1.ttf" },;
                    {"Arial Unicode MS","ARIALUNI.ttf" },;
                    {"Century","CENTURY.ttf" },;
                    {"Wingdings 2","WINGDNG2.ttf" },;
                    {"Wingdings 3","WINGDNG3.ttf" },;
                    {"X360 by Redge Normal","X360.ttf" },;
                    {"Kievit Offc Pro","KievitOffcPro.ttf" },;
                    {"Univers Bold","UNVR65W.ttf" },;
                    {"Univers Bold Italic","UNVR66W.ttf" },;
                    {"Univers Condensed Bold","UNVR67W.ttf" },;
                    {"Univers Condensed Bold Italic","UNVR68W.ttf" },;
                    {"Univers Condensed Medium","UNVR57W.ttf" },;
                    {"Univers Condensed Medium Italic","UNVR58W.ttf" },;
                    {"Univers Medium","UNVR55W.ttf" },;
                    {"Univers Medium Italic","UNVR56W.ttf" },;
                    {"DIN-Regular","font.ttf" },;
                    {"Open Sans Light","OpenSans-Light.ttf" },;
                    {"Open Sans Regular","OpenSans-Regular.ttf" },;
                    {"Noto Sans","NotoSans-Regular.ttf" },;
                    {"Noto Sans Semibold","NotoSans-Bold.ttf" },;
                    {"Reem Kufi Regular","ReemKufi-Regular.ttf" },;
                    {"Caladea Bold","Caladea-Bold.ttf" },;
                    {"David CLM Bold","DavidCLM-Bold.ttf" },;
                    {"Scheherazade Bold","Scheherazade-Bold.ttf" },;
                    {"Alef Bold","Alef-Bold.ttf" },;
                    {"OpenSymbol","opens___.ttf" },;
                    {"Carlito Bold","Carlito-Bold.ttf" },;
                    {"Noto Kufi Arabic Bold","NotoKufiArabic-Bold.ttf" },;
                    {"David Libre Bold","DavidLibre-Bold.ttf" },;
                    {"DejaVuMathTeXGyre-Regular","DejaVuMathTeXGyre.ttf" },;
                    {"Source Sans Pro Black","SourceSansPro-Black.ttf" },;
                    {"KacstBook","KacstBook.ttf" },;
                    {"Liberation Mono Bold","LiberationMono-Bold.ttf" },;
                    {"Linux Biolinum G Bold","LinBiolinum_RB_G.ttf" },;
                    {"Amiri Bold","amiri-bold.ttf" },;
                    {"Source Code Pro Black","SourceCodePro-Black.ttf" },;
                    {"Gentium Basic Bold","GenBasB.ttf" },;
                    {"EmojiOne Color SVGinOT","EmojiOneColor-SVGinOT.ttf" },;
                    {"Liberation Sans Narrow Bold","LiberationSansNarrow-Bold.ttf" },;
                    {"Alef Regular","Alef-Regular.ttf" },;
                    {"Amiri Bold Slanted","amiri-boldslanted.ttf" },;
                    {"Amiri Quran","amiri-quran.ttf" },;
                    {"Amiri","amiri-regular.ttf" },;
                    {"Amiri Slanted","amiri-slanted.ttf" },;
                    {"Caladea Bold Italic","Caladea-BoldItalic.ttf" },;
                    {"Caladea Italic","Caladea-Italic.ttf" },;
                    {"Caladea","Caladea-Regular.ttf" },;
                    {"Carlito Bold Italic","Carlito-BoldItalic.ttf" },;
                    {"Carlito Italic","Carlito-Italic.ttf" },;
                    {"Carlito","Carlito-Regular.ttf" },;
                    {"David CLM Bold Italic","DavidCLM-BoldItalic.ttf" },;
                    {"David CLM Medium","DavidCLM-Medium.ttf" },;
                    {"David CLM Medium Italic","DavidCLM-MediumItalic.ttf" },;
                    {"Frank Ruehl CLM Bold","FrankRuehlCLM-Bold.ttf" },;
                    {"Frank Ruehl CLM Bold Oblique","FrankRuehlCLM-BoldOblique.ttf" },;
                    {"Frank Ruehl CLM Medium","FrankRuehlCLM-Medium.ttf" },;
                    {"Frank Ruehl CLM Medium Oblique","FrankRuehlCLM-MediumOblique.ttf" },;
                    {"Miriam CLM Bold","MiriamCLM-Bold.ttf" },;
                    {"Miriam CLM Book","MiriamCLM-Book.ttf" },;
                    {"Miriam Mono CLM Bold","MiriamMonoCLM-Bold.ttf" },;
                    {"Miriam Mono CLM Bold Oblique","MiriamMonoCLM-BoldOblique.ttf" },;
                    {"Miriam Mono CLM Book","MiriamMonoCLM-Book.ttf" },;
                    {"Miriam Mono CLM Book Oblique","MiriamMonoCLM-BookOblique.ttf" },;
                    {"DejaVu Sans Bold","DejaVuSans-Bold.ttf" },;
                    {"DejaVu Sans Bold Oblique","DejaVuSans-BoldOblique.ttf" },;
                    {"DejaVu Sans ExtraLight","DejaVuSans-ExtraLight.ttf" },;
                    {"DejaVu Sans Oblique","DejaVuSans-Oblique.ttf" },;
                    {"DejaVu Sans","DejaVuSans.ttf" },;
                    {"DejaVu Sans Condensed Bold","DejaVuSansCondensed-Bold.ttf" },;
                    {"DejaVu Sans Condensed Bold Oblique","DejaVuSansCondensed-BoldOblique.ttf" },;
                    {"DejaVu Sans Condensed Oblique","DejaVuSansCondensed-Oblique.ttf" },;
                    {"DejaVu Sans Condensed","DejaVuSansCondensed.ttf" },;
                    {"DejaVu Sans Mono Bold","DejaVuSansMono-Bold.ttf" },;
                    {"DejaVu Sans Mono Bold Oblique","DejaVuSansMono-BoldOblique.ttf" },;
                    {"DejaVu Sans Mono Oblique","DejaVuSansMono-Oblique.ttf" },;
                    {"DejaVu Sans Mono","DejaVuSansMono.ttf" },;
                    {"DejaVu Serif Bold","DejaVuSerif-Bold.ttf" },;
                    {"DejaVu Serif Bold Italic","DejaVuSerif-BoldItalic.ttf" },;
                    {"DejaVu Serif Italic","DejaVuSerif-Italic.ttf" },;
                    {"DejaVu Serif","DejaVuSerif.ttf" },;
                    {"DejaVu Serif Condensed Bold","DejaVuSerifCondensed-Bold.ttf" },;
                    {"DejaVu Serif Condensed Bold Italic","DejaVuSerifCondensed-BoldItalic.ttf" },;
                    {"DejaVu Serif Condensed Italic","DejaVuSerifCondensed-Italic.ttf" },;
                    {"DejaVu Serif Condensed","DejaVuSerifCondensed.ttf" },;
                    {"Gentium Basic Bold Italic","GenBasBI.ttf" },;
                    {"Gentium Basic Italic","GenBasI.ttf" },;
                    {"Gentium Basic","GenBasR.ttf" },;
                    {"Gentium Book Basic Bold","GenBkBasB.ttf" },;
                    {"Gentium Book Basic Bold Italic","GenBkBasBI.ttf" },;
                    {"Gentium Book Basic Italic","GenBkBasI.ttf" },;
                    {"Gentium Book Basic","GenBkBasR.ttf" },;
                    {"KacstOffice","KacstOffice.ttf" },;
                    {"Liberation Mono Bold Italic","LiberationMono-BoldItalic.ttf" },;
                    {"Liberation Mono Italic","LiberationMono-Italic.ttf" },;
                    {"Liberation Mono","LiberationMono-Regular.ttf" },;
                    {"Liberation Sans Bold","LiberationSans-Bold.ttf" },;
                    {"Liberation Sans Bold Italic","LiberationSans-BoldItalic.ttf" },;
                    {"Liberation Sans Italic","LiberationSans-Italic.ttf" },;
                    {"Liberation Sans","LiberationSans-Regular.ttf" },;
                    {"Liberation Serif Bold","LiberationSerif-Bold.ttf" },;
                    {"Liberation Serif Bold Italic","LiberationSerif-BoldItalic.ttf" },;
                    {"Liberation Serif Italic","LiberationSerif-Italic.ttf" },;
                    {"Liberation Serif","LiberationSerif-Regular.ttf" },;
                    {"Liberation Sans Narrow Bold Italic","LiberationSansNarrow-BoldItalic.ttf" },;
                    {"Liberation Sans Narrow Italic","LiberationSansNarrow-Italic.ttf" },;
                    {"Liberation Sans Narrow","LiberationSansNarrow-Regular.ttf" },;
                    {"Linux Biolinum G Italic","LinBiolinum_RI_G.ttf" },;
                    {"Linux Biolinum G Regular","LinBiolinum_R_G.ttf" },;
                    {"Linux Libertine G Display Regular","LinLibertine_DR_G.ttf" },;
                    {"Linux Libertine G Bold Italic","LinLibertine_RBI_G.ttf" },;
                    {"Linux Libertine G Bold","LinLibertine_RB_G.ttf" },;
                    {"Linux Libertine G Italic","LinLibertine_RI_G.ttf" },;
                    {"Linux Libertine G Semibold Italic","LinLibertine_RZI_G.ttf" },;
                    {"Linux Libertine G Semibold","LinLibertine_RZ_G.ttf" },;
                    {"Linux Libertine G Regular","LinLibertine_R_G.ttf" },;
                    {"David Libre Regular","DavidLibre-Regular.ttf" },;
                    {"Rubik-Bold","Rubik-Bold.ttf" },;
                    {"Rubik Bold Italic","Rubik-BoldItalic.ttf" },;
                    {"Rubik Italic","Rubik-Italic.ttf" },;
                    {"Rubik-Regular","Rubik-Regular.ttf" },;
                    {"Noto Kufi Arabic","NotoKufiArabic-Regular.ttf" },;
                    {"Noto Mono","NotoMono-Regular.ttf" },;
                    {"Noto Naskh Arabic Bold","NotoNaskhArabic-Bold.ttf" },;
                    {"Noto Naskh Arabic","NotoNaskhArabic-Regular.ttf" },;
                    {"Noto Naskh Arabic UI Bold","NotoNaskhArabicUI-Bold.ttf" },;
                    {"Noto Naskh Arabic UI","NotoNaskhArabicUI-Regular.ttf" },;
                    {"Noto Sans Bold","NotoSans-Bold.ttf" },;
                    {"Noto Sans Bold Italic","NotoSans-BoldItalic.ttf" },;
                    {"Noto Sans Condensed","NotoSans-Condensed.ttf" },;
                    {"Noto Sans Condensed Bold","NotoSans-CondensedBold.ttf" },;
                    {"Noto Sans Condensed Bold Italic","NotoSans-CondensedBoldItalic.ttf" },;
                    {"Noto Sans Condensed Italic","NotoSans-CondensedItalic.ttf" },;
                    {"Noto Sans Italic","NotoSans-Italic.ttf" },;
                    {"Noto Sans Light","NotoSans-Light.ttf" },;
                    {"Noto Sans Light Italic","NotoSans-LightItalic.ttf" },;
                    {"Noto Sans Regular","NotoSans-Regular.ttf" },;
                    {"Noto Sans Arabic Bold","NotoSansArabic-Bold.ttf" },;
                    {"Noto Sans Arabic Regular","NotoSansArabic-Regular.ttf" },;
                    {"Noto Sans Arabic UI Bold","NotoSansArabicUI-Bold.ttf" },;
                    {"Noto Sans Arabic UI Regular","NotoSansArabicUI-Regular.ttf" },;
                    {"Noto Sans Armenian Bold","NotoSansArmenian-Bold.ttf" },;
                    {"Noto Sans Armenian Regular","NotoSansArmenian-Regular.ttf" },;
                    {"Noto Sans Georgian Bold","NotoSansGeorgian-Bold.ttf" },;
                    {"Noto Sans Georgian Regular","NotoSansGeorgian-Regular.ttf" },;
                    {"Noto Sans Hebrew Bold","NotoSansHebrew-Bold.ttf" },;
                    {"Noto Sans Hebrew Regular","NotoSansHebrew-Regular.ttf" },;
                    {"Noto Sans Lao Bold","NotoSansLao-Bold.ttf" },;
                    {"Noto Sans Lao Regular","NotoSansLao-Regular.ttf" },;
                    {"Noto Sans Lisu Regular","NotoSansLisu-Regular.ttf" },;
                    {"Noto Serif Bold","NotoSerif-Bold.ttf" },;
                    {"Noto Serif Bold Italic","NotoSerif-BoldItalic.ttf" },;
                    {"Noto Serif Condensed","NotoSerif-Condensed.ttf" },;
                    {"Noto Serif Condensed Bold","NotoSerif-CondensedBold.ttf" },;
                    {"Noto Serif Condensed Bold Italic","NotoSerif-CondensedBoldItalic.ttf" },;
                    {"Noto Serif Condensed Italic","NotoSerif-CondensedItalic.ttf" },;
                    {"Noto Serif Italic","NotoSerif-Italic.ttf" },;
                    {"Noto Serif Light","NotoSerif-Light.ttf" },;
                    {"Noto Serif Light Italic","NotoSerif-LightItalic.ttf" },;
                    {"Noto Serif Regular","NotoSerif-Regular.ttf" },;
                    {"Noto Serif Armenian Bold","NotoSerifArmenian-Bold.ttf" },;
                    {"Noto Serif Armenian Regular","NotoSerifArmenian-Regular.ttf" },;
                    {"Noto Serif Georgian Bold","NotoSerifGeorgian-Bold.ttf" },;
                    {"Noto Serif Georgian Regular","NotoSerifGeorgian-Regular.ttf" },;
                    {"Noto Serif Hebrew Bold","NotoSerifHebrew-Bold.ttf" },;
                    {"Noto Serif Hebrew Regular","NotoSerifHebrew-Regular.ttf" },;
                    {"Noto Serif Lao Bold","NotoSerifLao-Bold.ttf" },;
                    {"Noto Serif Lao Regular","NotoSerifLao-Regular.ttf" },;
                    {"Scheherazade","Scheherazade-Regular.ttf" },;
                    {"Source Code Pro Black Italic","SourceCodePro-BlackIt.ttf" },;
                    {"Source Code Pro Bold","SourceCodePro-Bold.ttf" },;
                    {"Source Code Pro Bold Italic","SourceCodePro-BoldIt.ttf" },;
                    {"Source Code Pro ExtraLight","SourceCodePro-ExtraLight.ttf" },;
                    {"Source Code Pro ExtraLight Italic","SourceCodePro-ExtraLightIt.ttf" },;
                    {"Source Code Pro Italic","SourceCodePro-It.ttf" },;
                    {"Source Code Pro Light","SourceCodePro-Light.ttf" },;
                    {"Source Code Pro Light Italic","SourceCodePro-LightIt.ttf" },;
                    {"Source Code Pro Medium","SourceCodePro-Medium.ttf" },;
                    {"Source Code Pro Medium Italic","SourceCodePro-MediumIt.ttf" },;
                    {"Source Code Pro","SourceCodePro-Regular.ttf" },;
                    {"Source Code Pro Semibold","SourceCodePro-Semibold.ttf" },;
                    {"Source Code Pro Semibold Italic","SourceCodePro-SemiboldIt.ttf" },;
                    {"Source Sans Pro Black Italic","SourceSansPro-BlackIt.ttf" },;
                    {"Source Sans Pro Bold","SourceSansPro-Bold.ttf" },;
                    {"Source Sans Pro Bold Italic","SourceSansPro-BoldIt.ttf" },;
                    {"Source Sans Pro ExtraLight","SourceSansPro-ExtraLight.ttf" },;
                    {"Source Sans Pro ExtraLight Italic","SourceSansPro-ExtraLightIt.ttf" },;
                    {"Source Sans Pro Italic","SourceSansPro-It.ttf" },;
                    {"Source Sans Pro Light","SourceSansPro-Light.ttf" },;
                    {"Source Sans Pro Light Italic","SourceSansPro-LightIt.ttf" },;
                    {"Source Sans Pro","SourceSansPro-Regular.ttf" },;
                    {"Source Sans Pro Semibold","SourceSansPro-Semibold.ttf" },;
                    {"Source Sans Pro Semibold Italic","SourceSansPro-SemiboldIt.ttf" },;
                    {"OpenSans-Regular","OpenSans-Regular.ttf" },;
                    {"OpenSans-Semibold","OpenSans-Semibold.ttf" },;
                    {"Haettenschweiler","HATTEN.ttf" },;
                    {"MS Outlook","OUTLOOK.ttf" },;
                    {"Dubai Bold","DUBAI-BOLD.ttf" },;
                    {"Dubai Light","DUBAI-LIGHT.ttf" },;
                    {"Dubai Medium","DUBAI-MEDIUM.ttf" },;
                    {"Dubai Regular","DUBAI-REGULAR.ttf" },;
                    {"Leelawadee","LEELAWAD.ttf" },;
                    {"Leelawadee Negrita","LEELAWDB.ttf" },;
                    {"Microsoft Uighur Negrita","MSUIGHUB.ttf" },;
                    {"Microsoft Uighur","MSUIGHUR.ttf" },;
                    {"MT Extra","MTEXTRA.ttf" };
                    }


   aTtfFontList:= {}
   aEval( aDfltList, {|_x| HaruAddFont( _x[1], _x[2] ) } )

return NIL

//------------------------------------------------------------------------------

FUNCTION HaruAddFont( cFontName, cTtfFile )

   local aList := GetHaruFontList()

   if !File( cTtfFile ) .AND. File( GetHaruFontDir() + '\' + cTtfFile )
      cTtfFile:= GetHaruFontDir() + '\' + cTtfFile
   endif
   if File( cTtfFile )
      aAdd( aList, { cFontName, cTtfFile } )
   ELSE
      ? 'file not found ' + cTtfFile
   endif

return NIL

//------------------------------------------------------------------------------

FUNCTION fwhtoharufont(ofont,opdf)

   LOCAL cnombre
   LOCAL nwidth
   LOCAL nheight
   LOCAL litalic
   LOCAL lbold
   LOCAL ofonth

   cnombre := ofont:cFaceName
   nwidth  := ofont:ninpwidth
   nheight := ofont:ninpheight
   litalic := ofont:litalic
   lbold   := ofont:lbold

   cnombre += IF(lbold," Bold","")+IF(litalic," Italic","")
   IF nheight < 0
      nheight := nheight*-1
   ENDIF
   

   ofonth := opdf:definefont(cnombre,nheight,.T.)
  // msginfo("cnombre "+hb_valtoexp(cnombre)+" "+Chr(10)+Chr(13)+"ofonth "+hb_valtoexp(ofonth)+" "+ValType(ofonth),"muestra")

RETURN ofonth


/*
#define CSIDL_PROGRAMS                  0x0002        // Start  Menu\Programs
#define CSIDL_DESKTOPDIRECTORY          0x0010        // <user  name>\Desktop

Function Main()
Local cEscritorio

cEscritorio:= GETSPECIALFOLDER(CSIDL_DESKTOPDIRECTORY)

Alert(cEscritorio,{"Ok"})


Return cEscritorio
  */
*---------------------------------------------------------------*
Function GETSPECIALFOLDER(nCSIDL) // Contributed By Ryszard Rylko
*---------------------------------------------------------------*
RETURN C_getspecialfolder(nCSIDL)

#pragma BEGINDUMP

#include <windows.h>
#include <shlobj.h>

#include "hbapi.h"
#include "hbapiitm.h"


HB_FUNC( C_GETSPECIALFOLDER ) // Contributed By Ryszard RyRko
{
    char *lpBuffer = (char*) hb_xgrab( MAX_PATH+1);
    LPITEMIDLIST pidlBrowse;    // PIDL selected by user
    SHGetSpecialFolderLocation(GetActiveWindow(), hb_parni(1), &pidlBrowse)
;
    SHGetPathFromIDList(pidlBrowse, lpBuffer);
    hb_retc(lpBuffer);
    hb_xfree( lpBuffer);
}


#pragma ENDDUMP