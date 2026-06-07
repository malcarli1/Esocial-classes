#include "hbclass.ch"

PROCEDURE Main()
   LOCAL cArquivo := "Retorno_eSocial.xml"
   LOCAL cXml, oRet, nI, nX, oEvento, oOcorr

   IF ! Empty( hb_ArgV( 1 ) )
      cArquivo := hb_ArgV( 1 )
   ENDIF

   IF ! File( cArquivo )
      ? "Arquivo nao encontrado: " + cArquivo
      RETURN
   ENDIF

   cXml := hb_MemoRead( cArquivo )
   oRet := EsocialRetornoLoteFromXml( cXml )

   ? "Lote:", oRet:nCdResposta, oRet:cDescResposta
   ? "Protocolo:", oRet:cProtocolo
   ? "Eventos:", oRet:GetEventoCount()
   ? "Lote OK:", IIf( oRet:LoteOk(), "SIM", "NAO" )
   ? "Todos eventos OK:", IIf( oRet:TodosEventosOk(), "SIM", "NAO" )

   FOR nI := 1 TO oRet:GetEventoCount()
      oEvento := oRet:GetEvento( nI - 1 )
      ? "Evento", nI, oEvento:cId, oEvento:nCdResposta, oEvento:cDescResposta

      FOR nX := 1 TO oEvento:GetOcorrenciaCount()
         oOcorr := oEvento:GetOcorrencia( nX - 1 )
         ? "  Ocorrencia", nX, "tipo", oOcorr:nTipo, "codigo", oOcorr:cCodigo
         ? "  " + oOcorr:cDescricao
         IF ! Empty( oOcorr:cLocalizacao )
            ? "  Local:", oOcorr:cLocalizacao
         ENDIF
      NEXT
   NEXT

   hb_MemoWrit( "demo_retorno_lote.log", oRet:ToTexto() )
RETURN
