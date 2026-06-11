cind/*****************************************************************************
 * SISTEMA  : SISTEMA DE GESTÃO OCUPACIONAL                                  *
 * PROGRAMA : ESOCIAL_CLASSES.PRG                                            *
 * OBJETIVO : Gerar, Assinar e Enviar Arquivos do eSocial                    *
 * AUTOR    : Franklin Brasil                                                *
 * ALTERADO : Marcelo Antonio Lazzaro Carli                                  *
 * DATA     : 29.05.2026                                                     *
 * ULT. ALT.: 11.06.2026                                                     *
 *****************************************************************************/
#include "hbclass.ch"

#define ESOCIAL_URL_ENVIO_RESTRITA "https://webservices.producaorestrita.esocial.gov.br/servicos/empregador/enviarloteeventos/WsEnviarLoteEventos.svc"
#define ESOCIAL_URL_CONSULTA_RESTRITA "https://webservices.producaorestrita.esocial.gov.br/servicos/empregador/consultarloteeventos/WsConsultarLoteEventos.svc"
#define ESOCIAL_URL_ENVIO_PRODUCAO "https://webservices.envio.esocial.gov.br/servicos/empregador/enviarloteeventos/WsEnviarLoteEventos.svc"
#define ESOCIAL_URL_CONSULTA_PRODUCAO "https://webservices.consulta.esocial.gov.br/servicos/empregador/consultarloteeventos/WsConsultarLoteEventos.svc"
#define ESOCIAL_SOAP_ENVIO "http://www.esocial.gov.br/servicos/empregador/lote/eventos/envio/v1_1_0/ServicoEnviarLoteEventos/EnviarLoteEventos"
#define ESOCIAL_SOAP_CONSULTA "http://www.esocial.gov.br/servicos/empregador/lote/eventos/envio/consulta/retornoProcessamento/v1_1_0/ServicoConsultarLoteEventos/ConsultarLoteEventos"

STATIC s_cEsocialValidacaoLastError := ""

CLASS TEsocialConfig
   VAR cEnvioUrl      AS Character INIT ""
   VAR cConsultaUrl   AS Character INIT ""
   VAR cCertName      AS Character INIT ""
   VAR lIgnoraErroSsl AS Logical   INIT .T.
   VAR cXsdPath       AS Character INIT "xsd\schemas"
   VAR lValidarXsd    AS Logical   INIT .F.

   METHOD New()
   METHOD UseProducao()
   METHOD UseProducaoRestrita()
   METHOD UseMockLocal()
   METHOD SetCertName()         // cCertName 
   METHOD SetXsdPath()          // cXsdPath
   METHOD EnableXsdValidation() // lAtivar
ENDCLASS

METHOD New() CLASS TEsocialConfig
   ::UseProducaoRestrita()
   ::cCertName := ""
RETURN Self

METHOD UseProducao() CLASS TEsocialConfig
   ::cEnvioUrl := ESOCIAL_URL_ENVIO_PRODUCAO
   ::cConsultaUrl := ESOCIAL_URL_CONSULTA_PRODUCAO
RETURN Self

METHOD UseProducaoRestrita() CLASS TEsocialConfig
   ::cEnvioUrl := ESOCIAL_URL_ENVIO_RESTRITA
   ::cConsultaUrl := ESOCIAL_URL_CONSULTA_RESTRITA
RETURN Self

METHOD UseMockLocal() CLASS TEsocialConfig
   ::cEnvioUrl := "http://127.0.0.1:8088/servicos/empregador/enviarloteeventos/WsEnviarLoteEventos.svc"
   ::cConsultaUrl := "http://127.0.0.1:8088/servicos/empregador/consultarloteeventos/WsConsultarLoteEventos.svc"
RETURN Self

METHOD SetCertName( cCertName ) CLASS TEsocialConfig
   ::cCertName := AllTrim( cCertName )
RETURN Self

METHOD SetXsdPath( cXsdPath ) CLASS TEsocialConfig
   ::cXsdPath := AllTrim( cXsdPath )
RETURN Self

METHOD EnableXsdValidation( lAtivar ) CLASS TEsocialConfig
   IF lAtivar == Nil
      lAtivar := .T.
   ENDIF
   ::lValidarXsd := lAtivar
RETURN Self

CLASS TEsocialEventoS2220
   VAR cVersaoSchema   AS Character INIT [v_S_01_03_00]
   VAR cId             AS Character INIT ""
   VAR cTpAmb          AS Character INIT "2"
   VAR cProcEmi        AS Character INIT "1"
   VAR cVerProc        AS Character INIT "HARBOUR-SST"
   VAR cIndRetif       AS Character INIT "1"
   VAR cNrRecibo       AS Character INIT ""
   VAR cTpInsc         AS Character INIT "1"
   VAR cNrInsc         AS Character INIT "00000000"
   VAR cNrInscId       AS Character INIT "00000000000000"
   VAR cCpfTrab        AS Character INIT "00000000191"
   VAR cMatricula      AS Character INIT "MAT001"
   VAR cCodCateg       AS Character INIT ""
   VAR cTpExameOcup    AS Character INIT "1"
   VAR cDtAso          AS Character INIT ""
   VAR cResAso         AS Character INIT "1"
   VAR cDtExm          AS Character INIT ""
   VAR cProcRealizado  AS Character INIT "0295"
   VAR cObsProc        AS Character INIT ""
   VAR cOrdExame       AS Character INIT ""
   VAR cIndResult      AS Character INIT "1"
   VAR aExames                      INIT {}
   VAR cNmMed          AS Character INIT "MEDICO TESTE"
   VAR cNrCRM          AS Character INIT "12345"
   VAR cUfCRM          AS Character INIT "PR"
   VAR cNmRespMonit    AS Character INIT ""
   VAR cNrCRMRespMonit AS Character INIT ""
   VAR cUfCRMRespMonit AS Character INIT ""
   VAR cCpfRespMonit   AS Character INIT ""

   METHOD New()
   METHOD SetId()          // cId 
   METHOD SetAmbiente()    // cTpAmb
   METHOD SetEmpregador()  // cTpInsc, cNrInsc 
   METHOD SetTrabalhador() // cCpfTrab, cMatricula, cCodCateg 
   METHOD SetAso()         // cDtAso, cTpExameOcup, cResAso 
   METHOD SetExame()       // cDtExm, cProcRealizado, cIndResult, cObsProc, cOrdExame
   METHOD AddExame()       // cDtExm, cProcRealizado, cIndResult, cObsProc, cOrdExame
   METHOD SetMedico()      // cNmMed, cNrCRM, cUfCRM 
   METHOD SetRespMonit()   // cNmResp, cNrCRM, cUfCRM, cCpfResp 
   METHOD ToXml()
ENDCLASS

METHOD New() CLASS TEsocialEventoS2220
   LOCAL cHoje := DateXml( Date() )

   ::cId := EsocialNovoId()
   ::cDtAso := cHoje
   ::cDtExm := cHoje
   ::aExames := {}
RETURN Self

METHOD SetId( cId ) CLASS TEsocialEventoS2220
   ::cId := AllTrim( cId )
RETURN Self

METHOD SetAmbiente( cTpAmb ) CLASS TEsocialEventoS2220
   ::cTpAmb := AllTrim( cTpAmb )
RETURN Self

METHOD SetEmpregador( cTpInsc, cNrInsc ) CLASS TEsocialEventoS2220
   ::cTpInsc := AllTrim( cTpInsc )
   ::cNrInscId := SoNumeroCnpj( cNrInsc )
   ::cNrInsc := ::cNrInscId
   IF ::cTpInsc == "1" .AND. Len( ::cNrInsc ) > 8
      ::cNrInsc := Left( ::cNrInsc, 8 )
   ENDIF
   ::cId := EsocialNovoIdEvento( ::cTpInsc, ::cNrInscId )
RETURN Self

METHOD SetTrabalhador( cCpfTrab, cMatricula, cCodCateg ) CLASS TEsocialEventoS2220
   ::cCpfTrab := OnlyDigits( cCpfTrab )
   IF cMatricula != Nil
      ::cMatricula := AllTrim( cMatricula )
   ENDIF
   IF cCodCateg != Nil
      ::cCodCateg := OnlyDigits( cCodCateg )
   ENDIF
RETURN Self

METHOD SetAso( cDtAso, cTpExameOcup, cResAso ) CLASS TEsocialEventoS2220
   ::cDtAso := DateXml( cDtAso )

   IF cTpExameOcup != Nil
      ::cTpExameOcup := AllTrim( cTpExameOcup )
   ENDIF
   IF cResAso != Nil
      ::cResAso := AllTrim( cResAso )
   ENDIF
RETURN Self

METHOD SetExame( cDtExm, cProcRealizado, cIndResult, cObsProc, cOrdExame ) CLASS TEsocialEventoS2220
   ::aExames := {}
RETURN ::AddExame( cDtExm, cProcRealizado, cIndResult, cObsProc, cOrdExame )

METHOD AddExame( cDtExm, cProcRealizado, cIndResult, cObsProc, cOrdExame ) CLASS TEsocialEventoS2220
   ::cDtExm := DateXml( cDtExm )
   ::cProcRealizado := OnlyDigits( cProcRealizado )
   IF cIndResult != Nil
      ::cIndResult := AllTrim( cIndResult )
   ENDIF
   IF cObsProc != Nil
      ::cObsProc := AllTrim( cObsProc )
   ENDIF
   IF cOrdExame != Nil
      ::cOrdExame := AllTrim( cOrdExame )
   ENDIF
   AAdd( ::aExames, { ::cDtExm, ::cProcRealizado, ::cIndResult, ::cObsProc, ::cOrdExame } )
RETURN Self

METHOD SetMedico( cNmMed, cNrCRM, cUfCRM ) CLASS TEsocialEventoS2220
   ::cNmMed := AllTrim( cNmMed )
   ::cNrCRM := AllTrim( OnlyDigits( cNrCRM ))
   ::cUfCRM := Upper( AllTrim( cUfCRM ) )
RETURN Self

METHOD SetRespMonit( cNmResp, cNrCRM, cUfCRM, cCpfResp ) CLASS TEsocialEventoS2220
   ::cNmRespMonit := AllTrim( cNmResp )
   ::cNrCRMRespMonit := AllTrim( OnlyDigits( cNrCRM ))
   ::cUfCRMRespMonit := Upper( AllTrim( cUfCRM ) )
   IF cCpfResp != Nil
      ::cCpfRespMonit := OnlyDigits( cCpfResp )
   ENDIF
RETURN Self

METHOD ToXml() CLASS TEsocialEventoS2220
   LOCAL cXml, nI, aExame

   cXml := '<eSocial xmlns="http://www.esocial.gov.br/schema/evt/evtMonit/' + ::cVersaoSchema + '">'
   cXml += '<evtMonit Id="' + EsocialXmlEscape( ::cId ) + '">'
   cXml += '<ideEvento><indRetif>' + ::cIndRetif + '</indRetif>'
   IF ! Empty( ::cNrRecibo ) .and. ::cIndRetif == "2"
      cXml += '<nrRecibo>' + EsocialXmlEscape( ::cNrRecibo ) + '</nrRecibo>'
   ENDIF
   cXml += '<tpAmb>' + ::cTpAmb + '</tpAmb><procEmi>' + ::cProcEmi + '</procEmi><verProc>' + EsocialXmlEscape( ::cVerProc ) + '</verProc></ideEvento>'
   cXml += '<ideEmpregador><tpInsc>' + ::cTpInsc + '</tpInsc><nrInsc>' + ::cNrInsc + '</nrInsc></ideEmpregador>'
   cXml += '<ideVinculo><cpfTrab>' + ::cCpfTrab + '</cpfTrab>'
   IF ! Empty( ::cMatricula )
      cXml += '<matricula>' + EsocialXmlEscape( ::cMatricula ) + '</matricula>'
   ENDIF
   IF ! Empty( ::cCodCateg )
      cXml += '<codCateg>' + ::cCodCateg + '</codCateg>'
   ENDIF
   cXml += '</ideVinculo>'
   cXml += '<exMedOcup><tpExameOcup>' + ::cTpExameOcup + '</tpExameOcup><aso>'
   cXml += '<dtAso>' + ::cDtAso + '</dtAso>'
   IF ! Empty( ::cResAso )
      cXml += '<resAso>' + ::cResAso + '</resAso>'
   ENDIF
   IF Len( ::aExames ) == 0
      ::AddExame( ::cDtExm, ::cProcRealizado, ::cIndResult, ::cObsProc, ::cOrdExame )
   ENDIF
   FOR nI := 1 TO Len( ::aExames )
      aExame := ::aExames[ nI ]
      cXml += '<exame><dtExm>' + aExame[ 1 ] + '</dtExm><procRealizado>' + aExame[ 2 ] + '</procRealizado>'
      IF ! Empty( aExame[ 4 ] )
         cXml += '<obsProc>' + EsocialXmlEscape( aExame[ 4 ] ) + '</obsProc>'
      ENDIF
      IF ! Empty( aExame[ 5 ] )
         cXml += '<ordExame>' + aExame[ 5 ] + '</ordExame>'
      ENDIF
      IF ! Empty( aExame[ 3 ] )
         cXml += '<indResult>' + aExame[ 3 ] + '</indResult>'
      ENDIF
      cXml += '</exame>'
   NEXT
   cXml += '<medico><nmMed>' + EsocialXmlEscape( ::cNmMed ) + '</nmMed>'
   IF ! Empty( ::cNrCRM )
      cXml += '<nrCRM>' + EsocialXmlEscape( ::cNrCRM ) + '</nrCRM>'
   ENDIF
   IF ! Empty( ::cUfCRM )
      cXml += '<ufCRM>' + ::cUfCRM + '</ufCRM>'
   ENDIF
   cXml += '</medico></aso>'
   IF ! Empty( ::cNmRespMonit )
      cXml += '<respMonit>'
      IF ! Empty( ::cCpfRespMonit )
         cXml += '<cpfResp>' + ::cCpfRespMonit + '</cpfResp>'
      ENDIF
      cXml += '<nmResp>' + EsocialXmlEscape( ::cNmRespMonit ) + '</nmResp>'
      cXml += '<nrCRM>' + EsocialXmlEscape( ::cNrCRMRespMonit ) + '</nrCRM>'
      cXml += '<ufCRM>' + ::cUfCRMRespMonit + '</ufCRM>'
      cXml += '</respMonit>'
   ENDIF
   cXml += '</exMedOcup></evtMonit></eSocial>'
RETURN cXml

CLASS TEsocialEventoS3000 FROM TEsocialEventoS2220
   VAR cTpEvento   AS Character INIT "S-2220"
   VAR cNrRecEvt   AS Character INIT "1.1.0000000099999999999"

   METHOD New()
   METHOD SetEventoExcluido()  //  cTpEvento, cNrRecEvt 
   METHOD ToXml()
ENDCLASS

METHOD New() CLASS TEsocialEventoS3000
   ::Super:New()
RETURN Self

METHOD SetEventoExcluido( cTpEvento, cNrRecEvt ) CLASS TEsocialEventoS3000
   ::cTpEvento := AllTrim( cTpEvento )
   ::cNrRecEvt := AllTrim( cNrRecEvt )
RETURN Self

METHOD ToXml() CLASS TEsocialEventoS3000
   LOCAL cXml

   cXml := '<eSocial xmlns="http://www.esocial.gov.br/schema/evt/evtExclusao/' + ::cVersaoSchema + '">'
   cXml += '<evtExclusao Id="' + EsocialXmlEscape( ::cId ) + '">'
   cXml += '<ideEvento><tpAmb>' + ::cTpAmb + '</tpAmb><procEmi>' + ::cProcEmi + '</procEmi><verProc>' + EsocialXmlEscape( ::cVerProc ) + '</verProc></ideEvento>'
   cXml += '<ideEmpregador><tpInsc>' + ::cTpInsc + '</tpInsc><nrInsc>' + ::cNrInsc + '</nrInsc></ideEmpregador>'
   cXml += '<infoExclusao><tpEvento>' + ::cTpEvento + '</tpEvento>'
   cXml += '<nrRecEvt>' + ::cNrRecEvt  + '</nrRecEvt>'
   IF ! Empty( ::cCpfTrab )
      cXml += '<ideTrabalhador><cpfTrab>' + ::cCpfTrab + '</cpfTrab></ideTrabalhador>'
   ENDIF
   cXml += '</infoExclusao></evtExclusao></eSocial>'
RETURN cXml

CLASS TEsocialEventoS2221 FROM TEsocialEventoS2220
   VAR cDtExm       AS Character INIT ""                                       // Data da Realização do Exame Toxicológico
   VAR cCnpjLab     AS Character INIT ""                                       // Cnpj do Laboratório Responsável
   VAR cCodSeqExame AS Character INIT ""                                       // Código Sequencial do Exame - AA999999999

   METHOD New()
   METHOD SetEventoToxico()                                                    // cDtExm, cCnpjLab, cCodSeqExame
   METHOD ToXml()
ENDCLASS

METHOD New() CLASS TEsocialEventoS2221
   ::Super:New()
RETURN Self

METHOD SetEventoToxico( cDtExm, cCnpjLab, cCodSeqExame) CLASS TEsocialEventoS2221
   ::cDtExm      := DateXml(cDtExm)
   ::cCnpjLab    := SoNumeroCnpj( cCnpjLab ) 
   ::cCodSeqExame:= AllTrim( cCodSeqExame )
RETURN Self

METHOD ToXml() CLASS TEsocialEventoS2221
   LOCAL cXml

   cXml := '<eSocial xmlns="http://www.esocial.gov.br/schema/evt/evtToxic/' + ::cVersaoSchema + '">'
   cXml += '<evtToxic Id="' + EsocialXmlEscape( ::cId ) + '">'
   cXml += '<ideEvento><indRetif>' + ::cIndRetif + '</indRetif>'
   IF ! Empty( ::cNrRecibo ) .and. ::cIndRetif == "2"
      cXml += '<nrRecibo>' + EsocialXmlEscape( ::cNrRecibo ) + '</nrRecibo>'
   ENDIF
   cXml += '<tpAmb>' + ::cTpAmb + '</tpAmb><procEmi>' + ::cProcEmi + '</procEmi><verProc>' + EsocialXmlEscape( ::cVerProc ) + '</verProc></ideEvento>'
   cXml += '<ideEmpregador><tpInsc>' + ::cTpInsc + '</tpInsc><nrInsc>' + ::cNrInsc + '</nrInsc></ideEmpregador>'
   cXml += '<ideVinculo><cpfTrab>' + ::cCpfTrab + '</cpfTrab>'
   IF ! Empty( ::cMatricula )
      cXml += '<matricula>' + EsocialXmlEscape( ::cMatricula ) + '</matricula>'
   ENDIF
   IF ! Empty( ::cCodCateg )
      cXml += '<codCateg>' + ::cCodCateg + '</codCateg>'
   ENDIF
   cXml += '</ideVinculo><toxicologico>'
   cXml += '<dtExame>' + ::cDtExm + '</dtExame>'
   cXml += '<cnpjLab>' + ::cCnpjLab + '</cnpjLab>'
   cXml += '<codSeqExame>' + ::cCodSeqExame + '</codSeqExame>'
   cXml += '<nmMed>' + EsocialXmlEscape( ::cNmMed ) + '</nmMed>'
   IF ! Empty( ::cNrCRM )
      cXml += '<nrCRM>' + EsocialXmlEscape( ::cNrCRM ) + '</nrCRM>'
   ENDIF
   IF ! Empty( ::cUfCRM )
      cXml += '<ufCRM>' + ::cUfCRM + '</ufCRM>'
   ENDIF
   cXml += '</toxicologico></evtToxic></eSocial>'
RETURN cXml

CLASS TEsocialEventoS2210 FROM TEsocialEventoS2220
   VAR cDtAcid           AS Character INIT ""
   VAR cTpAcid           AS Character INIT "1"
   VAR cHrAcid           AS Character INIT ""
   VAR cHrsTrabAntesAcid AS Character INIT ""
   VAR cTpCat            AS Character INIT "1"
   VAR cIndCatObito      AS Character INIT "N"
   VAR cDtObito          AS Character INIT ""
   VAR cIndComunPolicia  AS Character INIT "N"
   VAR cCodSitGeradora   AS Character INIT "200004300"
   VAR cIniciatCAT       AS Character INIT "1"
   VAR cObsCAT           AS Character INIT ""
   VAR cUltDiaTrab       AS Character INIT ""
   VAR cHouveAfast       AS Character INIT "N"
   VAR cTpLocal          AS Character INIT "1"
   VAR cDscLocal         AS Character INIT ""
   VAR cTpLograd         AS Character INIT ""
   VAR cDscLograd        AS Character INIT "NAO INFORMADO"
   VAR cNrLograd         AS Character INIT "S/N"
   VAR cComplemento      AS Character INIT ""
   VAR cBairro           AS Character INIT ""
   VAR cCep              AS Character INIT ""
   VAR cCodMunic         AS Character INIT ""
   VAR cUf               AS Character INIT ""
   VAR cPais             AS Character INIT ""
   VAR cCodPostal        AS Character INIT ""
   VAR cTpInscLocal      AS Character INIT ""
   VAR cNrInscLocal      AS Character INIT ""
   VAR cCodParteAting    AS Character INIT "753030000"
   VAR cLateralidade     AS Character INIT "0"
   VAR cCodAgntCausador  AS Character INIT "200004300"
   VAR cDtAtendimento    AS Character INIT ""
   VAR cHrAtendimento    AS Character INIT "0800"
   VAR cIndInternacao    AS Character INIT "N"
   VAR cDurTrat          AS Character INIT "1"
   VAR cIndAfast         AS Character INIT "N"
   VAR cDscLesao         AS Character INIT "702070000"
   VAR cDscCompLesao     AS Character INIT ""
   VAR cDiagProvavel     AS Character INIT ""
   VAR cCodCID           AS Character INIT "Z00"
   VAR cObservacao       AS Character INIT ""
   VAR cNmEmit           AS Character INIT "MEDICO TESTE"
   VAR cIdeOC            AS Character INIT "1"
   VAR cNrOC             AS Character INIT "12345"
   VAR cUfOC             AS Character INIT "SP"
   VAR cNrRecCatOrig     AS Character INIT ""

   METHOD New()
   METHOD SetAcidente()
   METHOD SetLocalAcidente()
   METHOD SetParteAtingida()
   METHOD SetAgenteCausador()
   METHOD SetAtestado()
   METHOD SetCatOrigem()
   METHOD ToXml()
ENDCLASS

METHOD New() CLASS TEsocialEventoS2210
   ::Super:New()
   ::cDtAcid := DateXml( Date() )
   ::cUltDiaTrab := ::cDtAcid
   ::cDtAtendimento := ::cDtAcid
RETURN Self

METHOD SetAcidente( cDtAcid, cTpAcid, cHrAcid, cHrsTrabAntesAcid, cTpCat, cIndCatObito, cIndComunPolicia, cCodSitGeradora, cIniciatCAT, cObsCAT, cUltDiaTrab, cHouveAfast, cDtObito ) CLASS TEsocialEventoS2210
   ::cDtAcid := DateXml( cDtAcid )
   IF cTpAcid != Nil
      ::cTpAcid := AllTrim( cTpAcid )
   ENDIF
   IF cHrAcid != Nil
      ::cHrAcid := OnlyDigits( cHrAcid )
   ENDIF
   IF cHrsTrabAntesAcid != Nil
      ::cHrsTrabAntesAcid := OnlyDigits( cHrsTrabAntesAcid )
   ENDIF
   IF cTpCat != Nil
      ::cTpCat := AllTrim( cTpCat )
   ENDIF
   IF cIndCatObito != Nil
      ::cIndCatObito := Upper( AllTrim( cIndCatObito ) )
   ENDIF
   IF cIndComunPolicia != Nil
      ::cIndComunPolicia := Upper( AllTrim( cIndComunPolicia ) )
   ENDIF
   IF cCodSitGeradora != Nil
      ::cCodSitGeradora := OnlyDigits( cCodSitGeradora )
   ENDIF
   IF cIniciatCAT != Nil
      ::cIniciatCAT := AllTrim( cIniciatCAT )
   ENDIF
   IF cObsCAT != Nil
      ::cObsCAT := AllTrim( cObsCAT )
   ENDIF
   IF cUltDiaTrab != Nil
      ::cUltDiaTrab := DateXml( cUltDiaTrab )
   ENDIF
   IF cHouveAfast != Nil
      ::cHouveAfast := Upper( AllTrim( cHouveAfast ) )
   ENDIF
   IF cDtObito != Nil
      ::cDtObito := DateXml( cDtObito )
   ENDIF
RETURN Self

METHOD SetLocalAcidente( cTpLocal, cDscLocal, cTpLograd, cDscLograd, cNrLograd, cComplemento, cBairro, cCep, cCodMunic, cUf, cPais, cCodPostal, cTpInscLocal, cNrInscLocal ) CLASS TEsocialEventoS2210
   IF cTpLocal != Nil
      ::cTpLocal := AllTrim( cTpLocal )
   ENDIF
   IF cDscLocal != Nil
      ::cDscLocal := AllTrim( cDscLocal )
   ENDIF
   IF cTpLograd != Nil
      ::cTpLograd := AllTrim( cTpLograd )
   ENDIF
   IF cDscLograd != Nil
      ::cDscLograd := AllTrim( cDscLograd )
   ENDIF
   IF cNrLograd != Nil
      ::cNrLograd := AllTrim( cNrLograd )
   ENDIF
   IF cComplemento != Nil
      ::cComplemento := AllTrim( cComplemento )
   ENDIF
   IF cBairro != Nil
      ::cBairro := AllTrim( cBairro )
   ENDIF
   IF cCep != Nil
      ::cCep := OnlyDigits( cCep )
   ENDIF
   IF cCodMunic != Nil
      ::cCodMunic := OnlyDigits( cCodMunic )
   ENDIF
   IF cUf != Nil
      ::cUf := Upper( AllTrim( cUf ) )
   ENDIF
   IF cPais != Nil
      ::cPais := OnlyDigits( cPais )
   ENDIF
   IF cCodPostal != Nil
      ::cCodPostal := AllTrim( cCodPostal )
   ENDIF
   IF cTpInscLocal != Nil
      ::cTpInscLocal := AllTrim( cTpInscLocal )
   ENDIF
   IF cNrInscLocal != Nil
      ::cNrInscLocal := SoNumeroCnpj( cNrInscLocal )
   ENDIF
RETURN Self

METHOD SetParteAtingida( cCodParteAting, cLateralidade ) CLASS TEsocialEventoS2210
   ::cCodParteAting := OnlyDigits( cCodParteAting )
   ::cLateralidade := AllTrim( cLateralidade )
RETURN Self

METHOD SetAgenteCausador( cCodAgntCausador ) CLASS TEsocialEventoS2210
   ::cCodAgntCausador := OnlyDigits( cCodAgntCausador )
RETURN Self

METHOD SetAtestado( cDtAtendimento, cHrAtendimento, cIndInternacao, cDurTrat, cIndAfast, cDscLesao, cCodCID, cNmEmit, cIdeOC, cNrOC, cUfOC, cDscCompLesao, cDiagProvavel, cObservacao ) CLASS TEsocialEventoS2210
   ::cDtAtendimento := DateXml( cDtAtendimento )
   ::cHrAtendimento := OnlyDigits( cHrAtendimento )
   ::cIndInternacao := Upper( AllTrim( cIndInternacao ) )
   ::cDurTrat := OnlyDigits( cDurTrat )
   ::cIndAfast := Upper( AllTrim( cIndAfast ) )
   ::cDscLesao := OnlyDigits( cDscLesao )
   ::cCodCID := Upper( AllTrim( cCodCID ) )
   ::cNmEmit := AllTrim( cNmEmit )
   ::cIdeOC := AllTrim( cIdeOC )
   ::cNrOC := AllTrim( cNrOC )
   ::cUfOC := Upper( AllTrim( cUfOC ) )
   IF cDscCompLesao != Nil
      ::cDscCompLesao := AllTrim( cDscCompLesao )
   ENDIF
   IF cDiagProvavel != Nil
      ::cDiagProvavel := AllTrim( cDiagProvavel )
   ENDIF
   IF cObservacao != Nil
      ::cObservacao := AllTrim( cObservacao )
   ENDIF
RETURN Self

METHOD SetCatOrigem( cNrRecCatOrig ) CLASS TEsocialEventoS2210
   ::cNrRecCatOrig := AllTrim( cNrRecCatOrig )
RETURN Self

METHOD ToXml() CLASS TEsocialEventoS2210
   LOCAL cXml

   cXml := '<eSocial xmlns="http://www.esocial.gov.br/schema/evt/evtCAT/' + ::cVersaoSchema + '">'
   cXml += '<evtCAT Id="' + EsocialXmlEscape( ::cId ) + '">'
   cXml += '<ideEvento><indRetif>' + ::cIndRetif + '</indRetif>'
   IF ! Empty( ::cNrRecibo ) .and. ::cIndRetif == "2"
      cXml += '<nrRecibo>' + EsocialXmlEscape( ::cNrRecibo ) + '</nrRecibo>'
   ENDIF
   cXml += '<tpAmb>' + ::cTpAmb + '</tpAmb><procEmi>' + ::cProcEmi + '</procEmi><verProc>' + EsocialXmlEscape( ::cVerProc ) + '</verProc></ideEvento>'
   cXml += '<ideEmpregador><tpInsc>' + ::cTpInsc + '</tpInsc><nrInsc>' + ::cNrInsc + '</nrInsc></ideEmpregador>'
   cXml += '<ideVinculo><cpfTrab>' + ::cCpfTrab + '</cpfTrab>'
   IF ! Empty( ::cMatricula )
      cXml += '<matricula>' + EsocialXmlEscape( ::cMatricula ) + '</matricula>'
   ENDIF
   IF ! Empty( ::cCodCateg )
      cXml += '<codCateg>' + ::cCodCateg + '</codCateg>'
   ENDIF
   cXml += '</ideVinculo><cat>'
   cXml += '<dtAcid>' + ::cDtAcid + '</dtAcid><tpAcid>' + ::cTpAcid + '</tpAcid>'
   IF ! Empty( ::cHrAcid )
      cXml += '<hrAcid>' + ::cHrAcid + '</hrAcid>'
   ENDIF
   IF ! Empty( ::cHrsTrabAntesAcid )
      cXml += '<hrsTrabAntesAcid>' + ::cHrsTrabAntesAcid + '</hrsTrabAntesAcid>'
   ENDIF
   cXml += '<tpCat>' + ::cTpCat + '</tpCat><indCatObito>' + ::cIndCatObito + '</indCatObito>'
   IF ! Empty( ::cDtObito )
      cXml += '<dtObito>' + ::cDtObito + '</dtObito>'
   ENDIF
   cXml += '<indComunPolicia>' + ::cIndComunPolicia + '</indComunPolicia>'
   cXml += '<codSitGeradora>' + ::cCodSitGeradora + '</codSitGeradora><iniciatCAT>' + ::cIniciatCAT + '</iniciatCAT>'
   IF ! Empty( ::cObsCAT )
      cXml += '<obsCAT>' + EsocialXmlEscape( ::cObsCAT ) + '</obsCAT>'
   ENDIF
   IF ! Empty( ::cUltDiaTrab )
      cXml += '<ultDiaTrab>' + ::cUltDiaTrab + '</ultDiaTrab>'
   ENDIF
   IF ! Empty( ::cHouveAfast )
      cXml += '<houveAfast>' + ::cHouveAfast + '</houveAfast>'
   ENDIF
   cXml += '<localAcidente><tpLocal>' + ::cTpLocal + '</tpLocal>'
   IF ! Empty( ::cDscLocal )
      cXml += '<dscLocal>' + EsocialXmlEscape( ::cDscLocal ) + '</dscLocal>'
   ENDIF
   IF ! Empty( ::cTpLograd )
      cXml += '<tpLograd>' + EsocialXmlEscape( ::cTpLograd ) + '</tpLograd>'
   ENDIF
   cXml += '<dscLograd>' + EsocialXmlEscape( ::cDscLograd ) + '</dscLograd><nrLograd>' + EsocialXmlEscape( ::cNrLograd ) + '</nrLograd>'
   IF ! Empty( ::cComplemento )
      cXml += '<complemento>' + EsocialXmlEscape( ::cComplemento ) + '</complemento>'
   ENDIF
   IF ! Empty( ::cBairro )
      cXml += '<bairro>' + EsocialXmlEscape( ::cBairro ) + '</bairro>'
   ENDIF
   IF ! Empty( ::cCep )
      cXml += '<cep>' + ::cCep + '</cep>'
   ENDIF
   IF ! Empty( ::cCodMunic )
      cXml += '<codMunic>' + ::cCodMunic + '</codMunic>'
   ENDIF
   IF ! Empty( ::cUf )
      cXml += '<uf>' + ::cUf + '</uf>'
   ENDIF
   IF ! Empty( ::cPais )
      cXml += '<pais>' + ::cPais + '</pais>'
   ENDIF
   IF ! Empty( ::cCodPostal )
      cXml += '<codPostal>' + EsocialXmlEscape( ::cCodPostal ) + '</codPostal>'
   ENDIF
   IF ! Empty( ::cTpInscLocal ) .AND. ! Empty( ::cNrInscLocal )
      cXml += '<ideLocalAcid><tpInsc>' + ::cTpInscLocal + '</tpInsc><nrInsc>' + ::cNrInscLocal + '</nrInsc></ideLocalAcid>'
   ENDIF
   cXml += '</localAcidente>'
   cXml += '<parteAtingida><codParteAting>' + ::cCodParteAting + '</codParteAting><lateralidade>' + ::cLateralidade + '</lateralidade></parteAtingida>'
   cXml += '<agenteCausador><codAgntCausador>' + ::cCodAgntCausador + '</codAgntCausador></agenteCausador>'
   cXml += '<atestado><dtAtendimento>' + ::cDtAtendimento + '</dtAtendimento><hrAtendimento>' + ::cHrAtendimento + '</hrAtendimento>'
   cXml += '<indInternacao>' + ::cIndInternacao + '</indInternacao><durTrat>' + ::cDurTrat + '</durTrat><indAfast>' + ::cIndAfast + '</indAfast>'
   cXml += '<dscLesao>' + ::cDscLesao + '</dscLesao>'
   IF ! Empty( ::cDscCompLesao )
      cXml += '<dscCompLesao>' + EsocialXmlEscape( ::cDscCompLesao ) + '</dscCompLesao>'
   ENDIF
   IF ! Empty( ::cDiagProvavel )
      cXml += '<diagProvavel>' + EsocialXmlEscape( ::cDiagProvavel ) + '</diagProvavel>'
   ENDIF
   cXml += '<codCID>' + EsocialXmlEscape( ::cCodCID ) + '</codCID>'
   IF ! Empty( ::cObservacao )
      cXml += '<observacao>' + EsocialXmlEscape( ::cObservacao ) + '</observacao>'
   ENDIF
   cXml += '<emitente><nmEmit>' + EsocialXmlEscape( ::cNmEmit ) + '</nmEmit><ideOC>' + ::cIdeOC + '</ideOC>'
   cXml += '<nrOC>' + EsocialXmlEscape( ::cNrOC ) + '</nrOC>'
   IF ! Empty( ::cUfOC )
      cXml += '<ufOC>' + ::cUfOC + '</ufOC>'
   ENDIF
   cXml += '</emitente></atestado>'
   IF ! Empty( ::cNrRecCatOrig )
      cXml += '<catOrigem><nrRecCatOrig>' + EsocialXmlEscape( ::cNrRecCatOrig ) + '</nrRecCatOrig></catOrigem>'
   ENDIF
   cXml += '</cat></evtCAT></eSocial>'
RETURN cXml

CLASS TEsocialEventoS2240 FROM TEsocialEventoS2220
   VAR cDtIniCondicao AS Character INIT ""
   VAR cDtFimCondicao AS Character INIT ""
   VAR aAmbientes                  INIT {}
   VAR cDscAtivDes    AS Character INIT "ATIVIDADES ADMINISTRATIVAS"
   VAR aAgentes                    INIT {}
   VAR aRespReg                    INIT {}
   VAR cObsCompl      AS Character INIT ""

   METHOD New()
   METHOD SetCondicao()
   METHOD SetAmbienteTrabalho()
   METHOD AddAmbienteTrabalho()
   METHOD SetAtividade()
   METHOD SetAgente()
   METHOD AddAgente()
   METHOD SetRespReg()
   METHOD AddRespReg()
   METHOD SetObs()
   METHOD ToXml()
ENDCLASS

METHOD New() CLASS TEsocialEventoS2240
   ::Super:New()
   ::cDtIniCondicao := DateXml( Date() )
   ::aAmbientes := {}
   ::aAgentes := {}
   ::aRespReg := {}
RETURN Self

METHOD SetCondicao( cDtIniCondicao, cDtFimCondicao ) CLASS TEsocialEventoS2240
   ::cDtIniCondicao := DateXml( cDtIniCondicao )
   IF cDtFimCondicao != Nil
      ::cDtFimCondicao := DateXml( cDtFimCondicao )
   ENDIF
RETURN Self

METHOD SetAmbienteTrabalho( cLocalAmb, cDscSetor, cTpInsc, cNrInsc ) CLASS TEsocialEventoS2240
   ::aAmbientes := {}
RETURN ::AddAmbienteTrabalho( cLocalAmb, cDscSetor, cTpInsc, cNrInsc )

METHOD AddAmbienteTrabalho( cLocalAmb, cDscSetor, cTpInsc, cNrInsc ) CLASS TEsocialEventoS2240
   AAdd( ::aAmbientes, { AllTrim( cLocalAmb ), AllTrim( cDscSetor ), AllTrim( cTpInsc ), SoNumeroCnpj( cNrInsc ) } )
RETURN Self

METHOD SetAtividade( cDscAtivDes ) CLASS TEsocialEventoS2240
   ::cDscAtivDes := AllTrim( cDscAtivDes )
RETURN Self

METHOD SetAgente( cCodAgNoc, cDscAgNoc, cTpAval, cIntConc, cLimTol, cUnMed, cTecMedicao, cNrProcJud, cUtilizEPC, cEficEpc, cUtilizEPI, cEficEpi ) CLASS TEsocialEventoS2240
   ::aAgentes := {}
RETURN ::AddAgente( cCodAgNoc, cDscAgNoc, cTpAval, cIntConc, cLimTol, cUnMed, cTecMedicao, cNrProcJud, cUtilizEPC, cEficEpc, cUtilizEPI, cEficEpi )

METHOD AddAgente( cCodAgNoc, cDscAgNoc, cTpAval, cIntConc, cLimTol, cUnMed, cTecMedicao, cNrProcJud, cUtilizEPC, cEficEpc, cUtilizEPI, cEficEpi ) CLASS TEsocialEventoS2240
   AAdd( ::aAgentes, { AllTrim( cCodAgNoc ), AllTrim( hb_DefaultValue( cDscAgNoc, "" ) ), AllTrim( hb_DefaultValue( cTpAval, "" ) ), ;
      AllTrim( hb_DefaultValue( cIntConc, "" ) ), AllTrim( hb_DefaultValue( cLimTol, "" ) ), AllTrim( hb_DefaultValue( cUnMed, "" ) ), ;
      AllTrim( hb_DefaultValue( cTecMedicao, "" ) ), AllTrim( hb_DefaultValue( cNrProcJud, "" ) ), AllTrim( hb_DefaultValue( cUtilizEPC, "" ) ), ;
      Upper( AllTrim( hb_DefaultValue( cEficEpc, "" ) ) ), AllTrim( hb_DefaultValue( cUtilizEPI, "" ) ), Upper( AllTrim( hb_DefaultValue( cEficEpi, "" ) ) ) } )
RETURN Self

METHOD SetRespReg( cCpfResp, cIdeOC, cDscOC, cNrOC, cUfOC ) CLASS TEsocialEventoS2240
   ::aRespReg := {}
RETURN ::AddRespReg( cCpfResp, cIdeOC, cDscOC, cNrOC, cUfOC )

METHOD AddRespReg( cCpfResp, cIdeOC, cDscOC, cNrOC, cUfOC ) CLASS TEsocialEventoS2240
   AAdd( ::aRespReg, { OnlyDigits( cCpfResp ), AllTrim( hb_DefaultValue( cIdeOC, "" ) ), AllTrim( hb_DefaultValue( cDscOC, "" ) ), ;
      AllTrim( hb_DefaultValue( cNrOC, "" ) ), Upper( AllTrim( hb_DefaultValue( cUfOC, "" ) ) ) } )
RETURN Self

METHOD SetObs( cObsCompl ) CLASS TEsocialEventoS2240
   ::cObsCompl := AllTrim( cObsCompl )
RETURN Self

METHOD ToXml() CLASS TEsocialEventoS2240
   LOCAL cXml, nI, aItem

   IF Len( ::aAmbientes ) == 0
      ::AddAmbienteTrabalho( "1", "SETOR ADMINISTRATIVO", ::cTpInsc, ::cNrInscId )
   ENDIF
   IF Len( ::aAgentes ) == 0
      ::AddAgente( "09.01.001", "", "", "", "", "", "", "", "", "", "", "" )
   ENDIF
   IF Len( ::aRespReg ) == 0
      ::AddRespReg( ::cCpfTrab, "", "", "", "" )
   ENDIF

   cXml := '<eSocial xmlns="http://www.esocial.gov.br/schema/evt/evtExpRisco/' + ::cVersaoSchema + '">'
   cXml += '<evtExpRisco Id="' + EsocialXmlEscape( ::cId ) + '">'
   cXml += '<ideEvento><indRetif>' + ::cIndRetif + '</indRetif>'
   IF ! Empty( ::cNrRecibo ) .and. ::cIndRetif == "2"
      cXml += '<nrRecibo>' + EsocialXmlEscape( ::cNrRecibo ) + '</nrRecibo>'
   ENDIF
   cXml += '<tpAmb>' + ::cTpAmb + '</tpAmb><procEmi>' + ::cProcEmi + '</procEmi><verProc>' + EsocialXmlEscape( ::cVerProc ) + '</verProc></ideEvento>'
   cXml += '<ideEmpregador><tpInsc>' + ::cTpInsc + '</tpInsc><nrInsc>' + ::cNrInsc + '</nrInsc></ideEmpregador>'
   cXml += '<ideVinculo><cpfTrab>' + ::cCpfTrab + '</cpfTrab>'
   IF ! Empty( ::cMatricula )
      cXml += '<matricula>' + EsocialXmlEscape( ::cMatricula ) + '</matricula>'
   ENDIF
   IF ! Empty( ::cCodCateg )
      cXml += '<codCateg>' + ::cCodCateg + '</codCateg>'
   ENDIF
   cXml += '</ideVinculo><infoExpRisco><dtIniCondicao>' + ::cDtIniCondicao + '</dtIniCondicao>'
   IF ! Empty( ::cDtFimCondicao )
      cXml += '<dtFimCondicao>' + ::cDtFimCondicao + '</dtFimCondicao>'
   ENDIF
   FOR nI := 1 TO Len( ::aAmbientes )
      aItem := ::aAmbientes[ nI ]
      cXml += '<infoAmb><localAmb>' + aItem[ 1 ] + '</localAmb><dscSetor>' + EsocialXmlEscape( aItem[ 2 ] ) + '</dscSetor>'
      cXml += '<tpInsc>' + aItem[ 3 ] + '</tpInsc><nrInsc>' + aItem[ 4 ] + '</nrInsc></infoAmb>'
   NEXT
   cXml += '<infoAtiv><dscAtivDes>' + EsocialXmlEscape( ::cDscAtivDes ) + '</dscAtivDes></infoAtiv>'
   FOR nI := 1 TO Len( ::aAgentes )
      aItem := ::aAgentes[ nI ]
      cXml += '<agNoc><codAgNoc>' + aItem[ 1 ] + '</codAgNoc>'
      IF ! Empty( aItem[ 2 ] )
         cXml += '<dscAgNoc>' + EsocialXmlEscape( aItem[ 2 ] ) + '</dscAgNoc>'
      ENDIF
      IF ! Empty( aItem[ 3 ] )
         cXml += '<tpAval>' + aItem[ 3 ] + '</tpAval>'
      ENDIF
      IF ! Empty( aItem[ 4 ] )
         cXml += '<intConc>' + aItem[ 4 ] + '</intConc>'
      ENDIF
      IF ! Empty( aItem[ 5 ] )
         cXml += '<limTol>' + aItem[ 5 ] + '</limTol>'
      ENDIF
      IF ! Empty( aItem[ 6 ] )
         cXml += '<unMed>' + aItem[ 6 ] + '</unMed>'
      ENDIF
      IF ! Empty( aItem[ 7 ] )
         cXml += '<tecMedicao>' + EsocialXmlEscape( aItem[ 7 ] ) + '</tecMedicao>'
      ENDIF
      IF ! Empty( aItem[ 8 ] )
         cXml += '<nrProcJud>' + aItem[ 8 ] + '</nrProcJud>'
      ENDIF
      IF ! Empty( aItem[ 9 ] ) .OR. ! Empty( aItem[ 11 ] )
         cXml += '<epcEpi>'
         IF ! Empty( aItem[ 9 ] )
            cXml += '<utilizEPC>' + aItem[ 9 ] + '</utilizEPC>'
            IF ! Empty( aItem[ 10 ] )
               cXml += '<eficEpc>' + aItem[ 10 ] + '</eficEpc>'
            ENDIF
         ENDIF
         IF ! Empty( aItem[ 11 ] )
            cXml += '<utilizEPI>' + aItem[ 11 ] + '</utilizEPI>'
            IF ! Empty( aItem[ 12 ] )
               cXml += '<eficEpi>' + aItem[ 12 ] + '</eficEpi>'
            ENDIF
         ENDIF
         cXml += '</epcEpi>'
      ENDIF
      cXml += '</agNoc>'
   NEXT
   FOR nI := 1 TO Len( ::aRespReg )
      aItem := ::aRespReg[ nI ]
      cXml += '<respReg><cpfResp>' + aItem[ 1 ] + '</cpfResp>'
      IF ! Empty( aItem[ 2 ] )
         cXml += '<ideOC>' + aItem[ 2 ] + '</ideOC>'
      ENDIF
      IF ! Empty( aItem[ 3 ] )
         cXml += '<dscOC>' + EsocialXmlEscape( aItem[ 3 ] ) + '</dscOC>'
      ENDIF
      IF ! Empty( aItem[ 4 ] )
         cXml += '<nrOC>' + EsocialXmlEscape( aItem[ 4 ] ) + '</nrOC>'
      ENDIF
      IF ! Empty( aItem[ 5 ] )
         cXml += '<ufOC>' + aItem[ 5 ] + '</ufOC>'
      ENDIF
      cXml += '</respReg>'
   NEXT
   IF ! Empty( ::cObsCompl )
      cXml += '<obs><obsCompl>' + EsocialXmlEscape( ::cObsCompl ) + '</obsCompl></obs>'
   ENDIF
   cXml += '</infoExpRisco></evtExpRisco></eSocial>'
RETURN cXml

CLASS TEsocialEventoXml
   VAR cVersaoSchema AS Character  INIT [v_S_01_03_00]
   VAR cId           AS Character  INIT ""
   VAR cSchemaEvento AS Character  INIT ""
   VAR cNomeEvento   AS Character  INIT ""
   VAR cConteudo     AS Character  INIT ""
   VAR cTipoIdeEvento AS Character INIT ""
   VAR aCampos                     INIT {}
   VAR cCodigoEvento AS Character  INIT ""
   VAR cTemplatePath  AS Character INIT "templates_eventos"

   METHOD New()
   METHOD SetId()
   METHOD SetEvento()
   METHOD SetTipoIdeEvento()
   METHOD SetConteudo()
   METHOD ClearConteudo()
   METHOD AddXml()
   METHOD SetCodigo()
   METHOD SetTemplatePath()
   METHOD SetCampo()
   METHOD SetCampos()
   METHOD SetAmbiente()
   METHOD SetProcesso()
   METHOD SetRetificacao()
   METHOD SetEmpregador()
   METHOD SetTrabalhador()
   METHOD SetPeriodo()
   METHOD SetOperacao()
   METHOD SetEscolha()
   METHOD SetGrupoOpcional()
   METHOD SetEventoExcluido()
   METHOD SetRecibo()
   METHOD AddCampo()
   METHOD BeginGrupo()
   METHOD EndGrupo()
   METHOD AddGrupo()
   METHOD AddIdeEvento()
   METHOD AddIdeEventoTrabalhador()
   METHOD AddIdeEventoFolha()
   METHOD AddIdeEventoFolhaMensal()
   METHOD AddIdeEventoFolhaSemRetificacao()
   METHOD AddIdeEventoTabela()
   METHOD AddIdeEventoExclusao()
   METHOD AddIdeEventoRetorno()
   METHOD AddIdeEmpregador()
   METHOD AddIdeVinculo()
   METHOD AddCabecalho()
   METHOD ToXml()
ENDCLASS

METHOD New( cNomeEvento, cSchemaEvento ) CLASS TEsocialEventoXml
   ::cId := EsocialNovoId()
   ::aCampos := {}
   IF cNomeEvento != Nil
      ::cNomeEvento := AllTrim( cNomeEvento )
   ENDIF
   IF cSchemaEvento != Nil
      ::cSchemaEvento := AllTrim( cSchemaEvento )
   ENDIF
   ::cTipoIdeEvento := EsocialTipoIdeEventoPorTag( ::cNomeEvento )
   ::cCodigoEvento := EsocialCodigoPorTag( ::cNomeEvento )
   ::SetCampo( "Id", ::cId )
   ::SetCampo( "tpAmb", "2" )
   ::SetCampo( "procEmi", "1" )
   ::SetCampo( "verProc", "HARBOUR-SST" )
   ::SetCampo( "indRetif", "1" )
RETURN Self

METHOD SetId( cId ) CLASS TEsocialEventoXml
   ::cId := AllTrim( cId )
   ::SetCampo( "Id", ::cId )
RETURN Self

METHOD SetEvento( cNomeEvento, cSchemaEvento ) CLASS TEsocialEventoXml
   ::cNomeEvento := AllTrim( cNomeEvento )
   ::cSchemaEvento := AllTrim( cSchemaEvento )
   ::cTipoIdeEvento := EsocialTipoIdeEventoPorTag( ::cNomeEvento )
   ::cCodigoEvento := EsocialCodigoPorTag( ::cNomeEvento )
RETURN Self

METHOD SetTipoIdeEvento( cTipoIdeEvento ) CLASS TEsocialEventoXml
   ::cTipoIdeEvento := AllTrim( hb_DefaultValue( cTipoIdeEvento, "" ) )
RETURN Self

METHOD SetConteudo( cConteudo ) CLASS TEsocialEventoXml
   ::cConteudo := AllTrim( cConteudo )
RETURN Self

METHOD ClearConteudo() CLASS TEsocialEventoXml
   ::cConteudo := ""
RETURN Self

METHOD AddXml( cXml ) CLASS TEsocialEventoXml
   ::cConteudo += AllTrim( hb_DefaultValue( cXml, "" ) )
RETURN Self

METHOD SetCodigo( cCodigo ) CLASS TEsocialEventoXml
   ::cCodigoEvento := Upper( StrTran( AllTrim( hb_DefaultValue( cCodigo, "" ) ), "-", "" ) )
RETURN Self

METHOD SetTemplatePath( cTemplatePath ) CLASS TEsocialEventoXml
   ::cTemplatePath := AllTrim( hb_DefaultValue( cTemplatePath, "templates_eventos" ) )
RETURN Self

METHOD SetCampo( cTag, cValor ) CLASS TEsocialEventoXml
   LOCAL cNome := AllTrim( hb_DefaultValue( cTag, "" ) )
   LOCAL nI

   IF ! Empty( cNome )
      FOR nI := 1 TO Len( ::aCampos )
         IF ValType( ::aCampos[ nI ] ) == "A" .AND. Len( ::aCampos[ nI ] ) >= 2
            IF AllTrim( ::aCampos[ nI, 1 ] ) == cNome
               ::aCampos[ nI, 2 ] := EsocialValorTexto( cValor )
               RETURN Self
            ENDIF
         ENDIF
      NEXT
      AAdd( ::aCampos, { cNome, EsocialValorTexto( cValor ) } )
   ENDIF
RETURN Self

METHOD SetCampos( aCampos ) CLASS TEsocialEventoXml
   LOCAL nI

   IF ValType( aCampos ) == "A"
      FOR nI := 1 TO Len( aCampos )
         IF ValType( aCampos[ nI ] ) == "A" .AND. Len( aCampos[ nI ] ) >= 2
            ::SetCampo( aCampos[ nI, 1 ], aCampos[ nI, 2 ] )
         ENDIF
      NEXT
   ENDIF
RETURN Self

METHOD SetAmbiente( cTpAmb ) CLASS TEsocialEventoXml
RETURN ::SetCampo( "tpAmb", cTpAmb )

METHOD SetProcesso( cProcEmi, cVerProc ) CLASS TEsocialEventoXml
   ::SetCampo( "procEmi", hb_DefaultValue( cProcEmi, "1" ) )
   ::SetCampo( "verProc", hb_DefaultValue( cVerProc, "HARBOUR-SST" ) )
RETURN Self

METHOD SetRetificacao( cIndRetif, cNrRecibo ) CLASS TEsocialEventoXml
   ::SetCampo( "indRetif", hb_DefaultValue( cIndRetif, "1" ) )
   IF ! Empty( hb_DefaultValue( cNrRecibo, "" ) )
      ::SetCampo( "nrRecibo", cNrRecibo )
   ENDIF
RETURN Self

METHOD SetEmpregador( cTpInsc, cNrInsc ) CLASS TEsocialEventoXml
   LOCAL cTp := AllTrim( hb_DefaultValue( cTpInsc, "1" ) )
   LOCAL cNrOriginal := hb_DefaultValue( cNrInsc, "" )

   ::cId := EsocialNovoIdEvento( cTp, cNrOriginal )
   ::SetCampo( "Id", ::cId )
   ::SetCampo( "tpInsc", cTp )
   ::SetCampo( "nrInsc", EsocialNrInscEmpregador( cTp, cNrOriginal ) )
RETURN Self

METHOD SetTrabalhador( cCpfTrab, cMatricula, cCodCateg ) CLASS TEsocialEventoXml
   ::SetCampo( "cpfTrab", OnlyDigits( hb_DefaultValue( cCpfTrab, "" ) ) )
   IF ! Empty( hb_DefaultValue( cMatricula, "" ) )
      ::SetCampo( "matricula", cMatricula )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCodCateg, "" ) )
      ::SetCampo( "codCateg", OnlyDigits( cCodCateg ) )
   ENDIF
RETURN Self

METHOD SetPeriodo( cPerApur, cIndApuracao ) CLASS TEsocialEventoXml
   IF ! Empty( hb_DefaultValue( cIndApuracao, "" ) )
      ::SetCampo( "indApuracao", cIndApuracao )
   ENDIF
   IF ! Empty( hb_DefaultValue( cPerApur, "" ) )
      ::SetCampo( "perApur", cPerApur )
   ENDIF
RETURN Self

METHOD SetOperacao( cOperacao, cIniValid, cFimValid ) CLASS TEsocialEventoXml
   ::SetCampo( "operacao", Lower( hb_DefaultValue( cOperacao, "inclusao" ) ) )
   IF ! Empty( hb_DefaultValue( cIniValid, "" ) )
      ::SetCampo( "iniValid", cIniValid )
   ENDIF
   IF ! Empty( hb_DefaultValue( cFimValid, "" ) )
      ::SetCampo( "fimValid", cFimValid )
   ENDIF
RETURN Self

METHOD SetEscolha( cOpcao ) CLASS TEsocialEventoXml
   LOCAL cTag := AllTrim( hb_DefaultValue( cOpcao, "" ) )

   IF ! Empty( cTag )
      ::SetCampo( "escolha_" + cTag, "S" )
   ENDIF
RETURN Self

METHOD SetGrupoOpcional( cTag ) CLASS TEsocialEventoXml
   LOCAL cNome := AllTrim( hb_DefaultValue( cTag, "" ) )

   IF ! Empty( cNome )
      ::SetCampo( "grupo_" + cNome, "S" )
   ENDIF
RETURN Self

METHOD SetEventoExcluido( cTpEvento, cNrRecEvt ) CLASS TEsocialEventoXml
   IF ! Empty( hb_DefaultValue( cTpEvento, "" ) )
      ::SetCampo( "tpEvento", cTpEvento )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNrRecEvt, "" ) )
      ::SetCampo( "nrRecEvt", cNrRecEvt )
   ENDIF
RETURN Self

METHOD SetRecibo( cNrRecibo ) CLASS TEsocialEventoXml
RETURN ::SetCampo( "nrRecibo", cNrRecibo )

METHOD AddCampo( cTag, cValor ) CLASS TEsocialEventoXml
   LOCAL cNome := AllTrim( hb_DefaultValue( cTag, "" ) )
   LOCAL cVal := hb_DefaultValue( cValor, "" )

   IF ! Empty( cNome )
      ::cConteudo += '<' + cNome + '>' + EsocialXmlEscape( cVal ) + '</' + cNome + '>'
   ENDIF
RETURN Self

METHOD BeginGrupo( cTag ) CLASS TEsocialEventoXml
   LOCAL cNome := AllTrim( hb_DefaultValue( cTag, "" ) )

   IF ! Empty( cNome )
      ::cConteudo += '<' + cNome + '>'
   ENDIF
RETURN Self

METHOD EndGrupo( cTag ) CLASS TEsocialEventoXml
   LOCAL cNome := AllTrim( hb_DefaultValue( cTag, "" ) )

   IF ! Empty( cNome )
      ::cConteudo += '</' + cNome + '>'
   ENDIF
RETURN Self

METHOD AddGrupo( cTag, cXmlInterno ) CLASS TEsocialEventoXml
   LOCAL cNome := AllTrim( hb_DefaultValue( cTag, "" ) )

   IF ! Empty( cNome )
      ::cConteudo += '<' + cNome + '>' + AllTrim( hb_DefaultValue( cXmlInterno, "" ) ) + '</' + cNome + '>'
   ENDIF
RETURN Self

METHOD AddIdeEvento( cXmlInterno ) CLASS TEsocialEventoXml
RETURN ::AddGrupo( "ideEvento", cXmlInterno )

METHOD AddIdeEventoTrabalhador( cTpAmb, cProcEmi, cVerProc, cIndRetif, cNrRecibo, cIndGuia ) CLASS TEsocialEventoXml
   LOCAL cXml := ""

   cXml += '<indRetif>' + AllTrim( hb_DefaultValue( cIndRetif, "1" ) ) + '</indRetif>'
   IF ! Empty( hb_DefaultValue( cNrRecibo, "" ) )
      cXml += '<nrRecibo>' + EsocialXmlEscape( cNrRecibo ) + '</nrRecibo>'
   ENDIF
   IF ! Empty( hb_DefaultValue( cIndGuia, "" ) )
      cXml += '<indGuia>' + AllTrim( cIndGuia ) + '</indGuia>'
   ENDIF
   cXml += '<tpAmb>' + AllTrim( hb_DefaultValue( cTpAmb, "2" ) ) + '</tpAmb>'
   cXml += '<procEmi>' + AllTrim( hb_DefaultValue( cProcEmi, "1" ) ) + '</procEmi>'
   cXml += '<verProc>' + EsocialXmlEscape( hb_DefaultValue( cVerProc, "HARBOUR-SST" ) ) + '</verProc>'
RETURN ::AddGrupo( "ideEvento", cXml )

METHOD AddIdeEventoFolha( cIndApuracao, cPerApur, cTpAmb, cProcEmi, cVerProc, cIndRetif, cNrRecibo, cIndGuia ) CLASS TEsocialEventoXml
   LOCAL cXml := ""

   cXml += '<indRetif>' + AllTrim( hb_DefaultValue( cIndRetif, "1" ) ) + '</indRetif>'
   IF ! Empty( hb_DefaultValue( cNrRecibo, "" ) )
      cXml += '<nrRecibo>' + EsocialXmlEscape( cNrRecibo ) + '</nrRecibo>'
   ENDIF
   cXml += '<indApuracao>' + AllTrim( hb_DefaultValue( cIndApuracao, "1" ) ) + '</indApuracao>'
   cXml += '<perApur>' + AllTrim( hb_DefaultValue( cPerApur, Left( DToS( Date() ), 4 ) + "-" + SubStr( DToS( Date() ), 5, 2 ) ) ) + '</perApur>'
   IF ! Empty( hb_DefaultValue( cIndGuia, "" ) )
      cXml += '<indGuia>' + AllTrim( cIndGuia ) + '</indGuia>'
   ENDIF
   cXml += '<tpAmb>' + AllTrim( hb_DefaultValue( cTpAmb, "2" ) ) + '</tpAmb>'
   cXml += '<procEmi>' + AllTrim( hb_DefaultValue( cProcEmi, "1" ) ) + '</procEmi>'
   cXml += '<verProc>' + EsocialXmlEscape( hb_DefaultValue( cVerProc, "HARBOUR-SST" ) ) + '</verProc>'
RETURN ::AddGrupo( "ideEvento", cXml )

METHOD AddIdeEventoFolhaMensal( cPerApur, cTpAmb, cProcEmi, cVerProc, cIndRetif, cNrRecibo, cIndGuia ) CLASS TEsocialEventoXml
   LOCAL cXml := ""

   cXml += '<indRetif>' + AllTrim( hb_DefaultValue( cIndRetif, "1" ) ) + '</indRetif>'
   IF ! Empty( hb_DefaultValue( cNrRecibo, "" ) )
      cXml += '<nrRecibo>' + EsocialXmlEscape( cNrRecibo ) + '</nrRecibo>'
   ENDIF
   cXml += '<perApur>' + AllTrim( hb_DefaultValue( cPerApur, Left( DToS( Date() ), 4 ) + "-" + SubStr( DToS( Date() ), 5, 2 ) ) ) + '</perApur>'
   IF ! Empty( hb_DefaultValue( cIndGuia, "" ) )
      cXml += '<indGuia>' + AllTrim( cIndGuia ) + '</indGuia>'
   ENDIF
   cXml += '<tpAmb>' + AllTrim( hb_DefaultValue( cTpAmb, "2" ) ) + '</tpAmb>'
   cXml += '<procEmi>' + AllTrim( hb_DefaultValue( cProcEmi, "1" ) ) + '</procEmi>'
   cXml += '<verProc>' + EsocialXmlEscape( hb_DefaultValue( cVerProc, "HARBOUR-SST" ) ) + '</verProc>'
RETURN ::AddGrupo( "ideEvento", cXml )

METHOD AddIdeEventoFolhaSemRetificacao( cIndApuracao, cPerApur, cTpAmb, cProcEmi, cVerProc, cIndGuia ) CLASS TEsocialEventoXml
   LOCAL cXml := ""

   cXml += '<indApuracao>' + AllTrim( hb_DefaultValue( cIndApuracao, "1" ) ) + '</indApuracao>'
   cXml += '<perApur>' + AllTrim( hb_DefaultValue( cPerApur, Left( DToS( Date() ), 4 ) + "-" + SubStr( DToS( Date() ), 5, 2 ) ) ) + '</perApur>'
   IF ! Empty( hb_DefaultValue( cIndGuia, "" ) )
      cXml += '<indGuia>' + AllTrim( cIndGuia ) + '</indGuia>'
   ENDIF
   cXml += '<tpAmb>' + AllTrim( hb_DefaultValue( cTpAmb, "2" ) ) + '</tpAmb>'
   cXml += '<procEmi>' + AllTrim( hb_DefaultValue( cProcEmi, "1" ) ) + '</procEmi>'
   cXml += '<verProc>' + EsocialXmlEscape( hb_DefaultValue( cVerProc, "HARBOUR-SST" ) ) + '</verProc>'
RETURN ::AddGrupo( "ideEvento", cXml )

METHOD AddIdeEventoTabela( cTpAmb, cProcEmi, cVerProc ) CLASS TEsocialEventoXml
   LOCAL cXml := ""

   cXml += '<tpAmb>' + AllTrim( hb_DefaultValue( cTpAmb, "2" ) ) + '</tpAmb>'
   cXml += '<procEmi>' + AllTrim( hb_DefaultValue( cProcEmi, "1" ) ) + '</procEmi>'
   cXml += '<verProc>' + EsocialXmlEscape( hb_DefaultValue( cVerProc, "HARBOUR-SST" ) ) + '</verProc>'
RETURN ::AddGrupo( "ideEvento", cXml )

METHOD AddIdeEventoExclusao( cTpAmb, cProcEmi, cVerProc ) CLASS TEsocialEventoXml
RETURN ::AddIdeEventoTabela( cTpAmb, cProcEmi, cVerProc )

METHOD AddIdeEventoRetorno( cPerApur, cIndApuracao ) CLASS TEsocialEventoXml
   LOCAL cXml := ""

   IF ! Empty( hb_DefaultValue( cIndApuracao, "" ) )
      cXml += '<indApuracao>' + AllTrim( cIndApuracao ) + '</indApuracao>'
   ENDIF
   cXml += '<perApur>' + AllTrim( hb_DefaultValue( cPerApur, Left( DToS( Date() ), 4 ) + "-" + SubStr( DToS( Date() ), 5, 2 ) ) ) + '</perApur>'
RETURN ::AddGrupo( "ideEvento", cXml )

METHOD AddIdeEmpregador( cTpInsc, cNrInsc ) CLASS TEsocialEventoXml
   LOCAL cTp := AllTrim( hb_DefaultValue( cTpInsc, "1" ) )
   LOCAL cNr := EsocialNrInscEmpregador( cTp, hb_DefaultValue( cNrInsc, "" ) )

   ::cConteudo += '<ideEmpregador><tpInsc>' + cTp + '</tpInsc><nrInsc>' + cNr + '</nrInsc></ideEmpregador>'
   ::cId := EsocialNovoIdEvento( cTp, cNrInsc )
RETURN Self

METHOD AddIdeVinculo( cCpfTrab, cMatricula, cCodCateg ) CLASS TEsocialEventoXml
   ::cConteudo += '<ideVinculo><cpfTrab>' + OnlyDigits( hb_DefaultValue( cCpfTrab, "" ) ) + '</cpfTrab>'
   IF ! Empty( hb_DefaultValue( cMatricula, "" ) )
      ::cConteudo += '<matricula>' + EsocialXmlEscape( cMatricula ) + '</matricula>'
   ENDIF
   IF ! Empty( hb_DefaultValue( cCodCateg, "" ) )
      ::cConteudo += '<codCateg>' + OnlyDigits( cCodCateg ) + '</codCateg>'
   ENDIF
   ::cConteudo += '</ideVinculo>'
RETURN Self

METHOD AddCabecalho( cTpInsc, cNrInsc, cTpAmb, cProcEmi, cVerProc, cIndRetif, cNrRecibo, cIndApuracao, cPerApur, cIndGuia ) CLASS TEsocialEventoXml
   LOCAL cTipo := AllTrim( ::cTipoIdeEvento )

   DO CASE
   CASE cTipo == "folha"
      ::AddIdeEventoFolha( cIndApuracao, cPerApur, cTpAmb, cProcEmi, cVerProc, cIndRetif, cNrRecibo, cIndGuia )
   CASE cTipo == "folha-opp"
      ::AddIdeEventoFolha( cIndApuracao, cPerApur, cTpAmb, cProcEmi, cVerProc, cIndRetif, cNrRecibo, "" )
   CASE cTipo == "folha-mensal" .OR. cTipo == "folha-mensal-pf"
      ::AddIdeEventoFolhaMensal( cPerApur, cTpAmb, cProcEmi, cVerProc, cIndRetif, cNrRecibo, cIndGuia )
   CASE cTipo == "folha-sem-retificacao"
      ::AddIdeEventoFolhaSemRetificacao( cIndApuracao, cPerApur, cTpAmb, cProcEmi, cVerProc, cIndGuia )
   CASE cTipo == "tabela" .OR. cTipo == "tabela-inicial"
      ::AddIdeEventoTabela( cTpAmb, cProcEmi, cVerProc )
   CASE cTipo == "exclusao" .OR. cTipo == "exclusao-proc-trab"
      ::AddIdeEventoExclusao( cTpAmb, cProcEmi, cVerProc )
   CASE cTipo == "retorno-contrib"
      ::AddIdeEventoRetorno( cPerApur, cIndApuracao )
   CASE cTipo == "retorno-mensal" .OR. cTipo == "retorno"
      ::AddIdeEventoRetorno( cPerApur, "" )
   OTHERWISE
      ::AddIdeEventoTrabalhador( cTpAmb, cProcEmi, cVerProc, cIndRetif, cNrRecibo, cIndGuia )
   ENDCASE

   ::AddIdeEmpregador( cTpInsc, cNrInsc )
RETURN Self

METHOD ToXml() CLASS TEsocialEventoXml
   LOCAL cXml, cConteudo := AllTrim( ::cConteudo )

   IF Empty( cConteudo ) .AND. ! Empty( ::cCodigoEvento ) .AND. Len( ::aCampos ) > 0
      ::SetCampo( "Id", ::cId )
      cXml := EsocialMontarXmlPorTemplate( ::cCodigoEvento, ::aCampos, ::cTemplatePath )
      IF ! Empty( cXml )
         RETURN cXml
      ENDIF
   ENDIF

   IF Empty( cConteudo )
      RETURN ""
   ENDIF

   IF Left( cConteudo, 8 ) == "<eSocial"
      RETURN cConteudo
   ENDIF

   IF Empty( ::cNomeEvento ) .OR. Empty( ::cSchemaEvento )
      RETURN ""
   ENDIF

   IF Left( cConteudo, Len( "<" + ::cNomeEvento ) ) == "<" + ::cNomeEvento
      cXml := '<eSocial xmlns="http://www.esocial.gov.br/schema/evt/' + ::cSchemaEvento + '/' + ::cVersaoSchema + '">'
      cXml += cConteudo
      cXml += '</eSocial>'
      RETURN cXml
   ENDIF

   cXml := '<eSocial xmlns="http://www.esocial.gov.br/schema/evt/' + ::cSchemaEvento + '/' + ::cVersaoSchema + '">'
   cXml += '<' + ::cNomeEvento + ' Id="' + EsocialXmlEscape( ::cId ) + '">'
   cXml += cConteudo
   cXml += '</' + ::cNomeEvento + '></eSocial>'
RETURN cXml

CLASS TEsocialEventoAdmissao FROM TEsocialEventoXml
   METHOD New()
   METHOD SetDadosTrabalhador()
   METHOD SetNascimento()
   METHOD SetEnderecoBrasil()
   METHOD SetEnderecoExterior()
   METHOD SetVinculo()
   METHOD SetCeletista()
   METHOD SetEstatutario()
   METHOD SetContrato()
   METHOD SetRemuneracao()
   METHOD SetDuracao()
ENDCLASS

METHOD New() CLASS TEsocialEventoAdmissao
   ::Super:New( "evtAdmissao", "evtAdmissao" )
RETURN Self

METHOD SetDadosTrabalhador( cCpfTrab, cNmTrab, cSexo, cRacaCor, cGrauInstr, cEstCiv, cNmSoc ) CLASS TEsocialEventoAdmissao
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   ::SetCampo( "nmTrab", cNmTrab )
   ::SetCampo( "sexo", cSexo )
   ::SetCampo( "racaCor", cRacaCor )
   ::SetCampo( "grauInstr", cGrauInstr )
   IF ! Empty( hb_DefaultValue( cEstCiv, "" ) )
      ::SetCampo( "estCiv", cEstCiv )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNmSoc, "" ) )
      ::SetCampo( "nmSoc", cNmSoc )
   ENDIF
RETURN Self

METHOD SetNascimento( cDtNascto, cPaisNascto, cPaisNac ) CLASS TEsocialEventoAdmissao
   ::SetCampo( "dtNascto", cDtNascto )
   ::SetCampo( "paisNascto", cPaisNascto )
   ::SetCampo( "paisNac", cPaisNac )
RETURN Self

METHOD SetEnderecoBrasil( cDscLograd, cNrLograd, cCep, cCodMunic, cUf, cTpLograd, cComplemento, cBairro ) CLASS TEsocialEventoAdmissao
   ::SetEscolha( "brasil" )
   IF ! Empty( hb_DefaultValue( cTpLograd, "" ) )
      ::SetCampo( "tpLograd", cTpLograd )
   ENDIF
   ::SetCampo( "dscLograd", cDscLograd )
   ::SetCampo( "nrLograd", cNrLograd )
   IF ! Empty( hb_DefaultValue( cComplemento, "" ) )
      ::SetCampo( "complemento", cComplemento )
   ENDIF
   IF ! Empty( hb_DefaultValue( cBairro, "" ) )
      ::SetCampo( "bairro", cBairro )
   ENDIF
   ::SetCampo( "cep", OnlyDigits( cCep ) )
   ::SetCampo( "codMunic", OnlyDigits( cCodMunic ) )
   ::SetCampo( "uf", Upper( AllTrim( hb_DefaultValue( cUf, "" ) ) ) )
RETURN Self

METHOD SetEnderecoExterior( cPaisResid, cDscLograd, cNrLograd, cNmCid, cCodPostal, cComplemento, cBairro ) CLASS TEsocialEventoAdmissao
   ::SetEscolha( "exterior" )
   ::SetCampo( "paisResid", cPaisResid )
   ::SetCampo( "dscLograd", cDscLograd )
   ::SetCampo( "nrLograd", cNrLograd )
   IF ! Empty( hb_DefaultValue( cComplemento, "" ) )
      ::SetCampo( "complemento", cComplemento )
   ENDIF
   IF ! Empty( hb_DefaultValue( cBairro, "" ) )
      ::SetCampo( "bairro", cBairro )
   ENDIF
   ::SetCampo( "nmCid", cNmCid )
   IF ! Empty( hb_DefaultValue( cCodPostal, "" ) )
      ::SetCampo( "codPostal", cCodPostal )
   ENDIF
RETURN Self

METHOD SetVinculo( cMatricula, cTpRegTrab, cTpRegPrev, cCadIni ) CLASS TEsocialEventoAdmissao
   ::SetCampo( "matricula", cMatricula )
   ::SetCampo( "tpRegTrab", cTpRegTrab )
   ::SetCampo( "tpRegPrev", cTpRegPrev )
   ::SetCampo( "cadIni", cCadIni )
RETURN Self

METHOD SetCeletista( cDtAdm, cTpAdmissao, cIndAdmissao, cTpRegJor, cNatAtividade, cCnpjSindCategProf, cNrProcTrab, cDtBase, cMatAnotJud ) CLASS TEsocialEventoAdmissao
   ::SetEscolha( "infoCeletista" )
   ::SetCampo( "dtAdm", cDtAdm )
   ::SetCampo( "tpAdmissao", cTpAdmissao )
   ::SetCampo( "indAdmissao", cIndAdmissao )
   IF ! Empty( hb_DefaultValue( cNrProcTrab, "" ) )
      ::SetCampo( "nrProcTrab", cNrProcTrab )
   ENDIF
   ::SetCampo( "tpRegJor", cTpRegJor )
   ::SetCampo( "natAtividade", cNatAtividade )
   IF ! Empty( hb_DefaultValue( cDtBase, "" ) )
      ::SetCampo( "dtBase", cDtBase )
   ENDIF
   ::SetCampo( "cnpjSindCategProf", OnlyDigits( cCnpjSindCategProf ) )
   IF ! Empty( hb_DefaultValue( cMatAnotJud, "" ) )
      ::SetCampo( "matAnotJud", cMatAnotJud )
   ENDIF
RETURN Self

METHOD SetEstatutario( cTpProv, cDtExercicio, cTpPlanRP, cIndTetoRGPS, cIndAbonoPerm, cDtIniAbono ) CLASS TEsocialEventoAdmissao
   ::SetEscolha( "infoEstatutario" )
   ::SetCampo( "tpProv", cTpProv )
   ::SetCampo( "dtExercicio", cDtExercicio )
   IF ! Empty( hb_DefaultValue( cTpPlanRP, "" ) )
      ::SetCampo( "tpPlanRP", cTpPlanRP )
   ENDIF
   IF ! Empty( hb_DefaultValue( cIndTetoRGPS, "" ) )
      ::SetCampo( "indTetoRGPS", cIndTetoRGPS )
   ENDIF
   IF ! Empty( hb_DefaultValue( cIndAbonoPerm, "" ) )
      ::SetCampo( "indAbonoPerm", cIndAbonoPerm )
   ENDIF
   IF ! Empty( hb_DefaultValue( cDtIniAbono, "" ) )
      ::SetCampo( "dtIniAbono", cDtIniAbono )
   ENDIF
RETURN Self

METHOD SetContrato( cCodCateg, cNmCargo, cCBOCargo, cNmFuncao, cCBOFuncao, cAcumCargo ) CLASS TEsocialEventoAdmissao
   ::SetCampo( "codCateg", OnlyDigits( cCodCateg ) )
   IF ! Empty( hb_DefaultValue( cNmCargo, "" ) )
      ::SetCampo( "nmCargo", cNmCargo )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCBOCargo, "" ) )
      ::SetCampo( "CBOCargo", OnlyDigits( cCBOCargo ) )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNmFuncao, "" ) )
      ::SetCampo( "nmFuncao", cNmFuncao )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCBOFuncao, "" ) )
      ::SetCampo( "CBOFuncao", OnlyDigits( cCBOFuncao ) )
   ENDIF
   IF ! Empty( hb_DefaultValue( cAcumCargo, "" ) )
      ::SetCampo( "acumCargo", cAcumCargo )
   ENDIF
RETURN Self

METHOD SetRemuneracao( cVrSalFx, cUndSalFixo, cDscSalVar ) CLASS TEsocialEventoAdmissao
   ::SetGrupoOpcional( "remuneracao" )
   ::SetCampo( "vrSalFx", cVrSalFx )
   ::SetCampo( "undSalFixo", cUndSalFixo )
   IF ! Empty( hb_DefaultValue( cDscSalVar, "" ) )
      ::SetCampo( "dscSalVar", cDscSalVar )
   ENDIF
RETURN Self

METHOD SetDuracao( cTpContr, cDtTerm, cClauAssec, cObjDet ) CLASS TEsocialEventoAdmissao
   ::SetGrupoOpcional( "duracao" )
   ::SetCampo( "tpContr", cTpContr )
   IF ! Empty( hb_DefaultValue( cDtTerm, "" ) )
      ::SetCampo( "dtTerm", cDtTerm )
   ENDIF
   IF ! Empty( hb_DefaultValue( cClauAssec, "" ) )
      ::SetCampo( "clauAssec", cClauAssec )
   ENDIF
   IF ! Empty( hb_DefaultValue( cObjDet, "" ) )
      ::SetCampo( "objDet", cObjDet )
   ENDIF
RETURN Self

CLASS TEsocialEventoAdmPrelim FROM TEsocialEventoXml
   METHOD New()
   METHOD SetRegistroPreliminar()
   METHOD SetInfoRegCTPS()
ENDCLASS
METHOD New() CLASS TEsocialEventoAdmPrelim
   ::Super:New( "evtAdmPrelim", "evtAdmPrelim" )
RETURN Self

METHOD SetRegistroPreliminar( cCpfTrab, cDtNascto, cDtAdm, cMatricula, cCodCateg, cNatAtividade ) CLASS TEsocialEventoAdmPrelim
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   ::SetCampo( "dtNascto", cDtNascto )
   ::SetCampo( "dtAdm", cDtAdm )
   ::SetCampo( "matricula", cMatricula )
   ::SetCampo( "codCateg", OnlyDigits( cCodCateg ) )
   IF ! Empty( hb_DefaultValue( cNatAtividade, "" ) )
      ::SetCampo( "natAtividade", cNatAtividade )
   ENDIF
RETURN Self

METHOD SetInfoRegCTPS( cCBOCargo, cVrSalFx, cUndSalFixo, cTpContr, cDtTerm ) CLASS TEsocialEventoAdmPrelim
   ::SetGrupoOpcional( "infoRegCTPS" )
   ::SetCampo( "CBOCargo", OnlyDigits( cCBOCargo ) )
   ::SetCampo( "vrSalFx", cVrSalFx )
   ::SetCampo( "undSalFixo", cUndSalFixo )
   ::SetCampo( "tpContr", cTpContr )
   IF ! Empty( hb_DefaultValue( cDtTerm, "" ) )
      ::SetCampo( "dtTerm", cDtTerm )
   ENDIF
RETURN Self

CLASS TEsocialEventoAfastTemp FROM TEsocialEventoXml
   METHOD New()
   METHOD SetInicioAfastamento()
   METHOD SetFimAfastamento()
   METHOD SetRetificacaoAfastamento()
ENDCLASS
METHOD New() CLASS TEsocialEventoAfastTemp
   ::Super:New( "evtAfastTemp", "evtAfastTemp" )
RETURN Self

METHOD SetInicioAfastamento( cDtIniAfast, cCodMotAfast, cInfoMesmoMtv, cTpAcidTransito, cObservacao ) CLASS TEsocialEventoAfastTemp
   ::SetGrupoOpcional( "iniAfastamento" )
   ::SetCampo( "dtIniAfast", cDtIniAfast )
   ::SetCampo( "codMotAfast", cCodMotAfast )
   IF ! Empty( hb_DefaultValue( cInfoMesmoMtv, "" ) )
      ::SetCampo( "infoMesmoMtv", cInfoMesmoMtv )
   ENDIF
   IF ! Empty( hb_DefaultValue( cTpAcidTransito, "" ) )
      ::SetCampo( "tpAcidTransito", cTpAcidTransito )
   ENDIF
   IF ! Empty( hb_DefaultValue( cObservacao, "" ) )
      ::SetCampo( "observacao", cObservacao )
   ENDIF
RETURN Self

METHOD SetFimAfastamento( cDtTermAfast ) CLASS TEsocialEventoAfastTemp
   ::SetGrupoOpcional( "fimAfastamento" )
RETURN ::SetCampo( "dtTermAfast", cDtTermAfast )

METHOD SetRetificacaoAfastamento( cOrigRetif, cTpProc, cNrProc ) CLASS TEsocialEventoAfastTemp
   ::SetGrupoOpcional( "infoRetif" )
   ::SetCampo( "origRetif", cOrigRetif )
   IF ! Empty( hb_DefaultValue( cTpProc, "" ) )
      ::SetCampo( "tpProc", cTpProc )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNrProc, "" ) )
      ::SetCampo( "nrProc", cNrProc )
   ENDIF
RETURN Self

CLASS TEsocialEventoAltCadastral FROM TEsocialEventoXml
   METHOD New()
   METHOD SetAlteracao()
   METHOD SetDadosTrabalhador()
   METHOD SetEnderecoBrasil()
   METHOD SetEnderecoExterior()
ENDCLASS
METHOD New() CLASS TEsocialEventoAltCadastral
   ::Super:New( "evtAltCadastral", "evtAltCadastral" )
RETURN Self

METHOD SetAlteracao( cDtAlteracao ) CLASS TEsocialEventoAltCadastral
RETURN ::SetCampo( "dtAlteracao", cDtAlteracao )

METHOD SetDadosTrabalhador( cCpfTrab, cNmTrab, cSexo, cRacaCor, cGrauInstr, cPaisNac, cEstCiv, cNmSoc ) CLASS TEsocialEventoAltCadastral
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   ::SetCampo( "nmTrab", cNmTrab )
   ::SetCampo( "sexo", cSexo )
   ::SetCampo( "racaCor", cRacaCor )
   ::SetCampo( "grauInstr", cGrauInstr )
   ::SetCampo( "paisNac", cPaisNac )
   IF ! Empty( hb_DefaultValue( cEstCiv, "" ) )
      ::SetCampo( "estCiv", cEstCiv )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNmSoc, "" ) )
      ::SetCampo( "nmSoc", cNmSoc )
   ENDIF
RETURN Self

METHOD SetEnderecoBrasil( cDscLograd, cNrLograd, cCep, cCodMunic, cUf, cTpLograd, cComplemento, cBairro ) CLASS TEsocialEventoAltCadastral
   ::SetEscolha( "brasil" )
   IF ! Empty( hb_DefaultValue( cTpLograd, "" ) )
      ::SetCampo( "tpLograd", cTpLograd )
   ENDIF
   ::SetCampo( "dscLograd", cDscLograd )
   ::SetCampo( "nrLograd", cNrLograd )
   IF ! Empty( hb_DefaultValue( cComplemento, "" ) )
      ::SetCampo( "complemento", cComplemento )
   ENDIF
   IF ! Empty( hb_DefaultValue( cBairro, "" ) )
      ::SetCampo( "bairro", cBairro )
   ENDIF
   ::SetCampo( "cep", OnlyDigits( cCep ) )
   ::SetCampo( "codMunic", OnlyDigits( cCodMunic ) )
   ::SetCampo( "uf", Upper( AllTrim( hb_DefaultValue( cUf, "" ) ) ) )
RETURN Self

METHOD SetEnderecoExterior( cPaisResid, cDscLograd, cNrLograd, cNmCid, cCodPostal, cComplemento, cBairro ) CLASS TEsocialEventoAltCadastral
   ::SetEscolha( "exterior" )
   ::SetCampo( "paisResid", cPaisResid )
   ::SetCampo( "dscLograd", cDscLograd )
   ::SetCampo( "nrLograd", cNrLograd )
   IF ! Empty( hb_DefaultValue( cComplemento, "" ) )
      ::SetCampo( "complemento", cComplemento )
   ENDIF
   IF ! Empty( hb_DefaultValue( cBairro, "" ) )
      ::SetCampo( "bairro", cBairro )
   ENDIF
   ::SetCampo( "nmCid", cNmCid )
   IF ! Empty( hb_DefaultValue( cCodPostal, "" ) )
      ::SetCampo( "codPostal", cCodPostal )
   ENDIF
RETURN Self

CLASS TEsocialEventoAltContratual FROM TEsocialEventoXml
   METHOD New()
   METHOD SetAlteracaoContratual()
   METHOD SetVinculo()
   METHOD SetCeletista()
   METHOD SetEstatutario()
   METHOD SetContrato()
   METHOD SetRemuneracao()
   METHOD SetDuracao()
ENDCLASS
METHOD New() CLASS TEsocialEventoAltContratual
   ::Super:New( "evtAltContratual", "evtAltContratual" )
RETURN Self

METHOD SetAlteracaoContratual( cDtAlteracao, cDtEf, cDscAlt ) CLASS TEsocialEventoAltContratual
   ::SetCampo( "dtAlteracao", cDtAlteracao )
   IF ! Empty( hb_DefaultValue( cDtEf, "" ) )
      ::SetCampo( "dtEf", cDtEf )
   ENDIF
   IF ! Empty( hb_DefaultValue( cDscAlt, "" ) )
      ::SetCampo( "dscAlt", cDscAlt )
   ENDIF
RETURN Self

METHOD SetVinculo( cCpfTrab, cMatricula, cTpRegPrev ) CLASS TEsocialEventoAltContratual
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   ::SetCampo( "matricula", cMatricula )
   ::SetCampo( "tpRegPrev", cTpRegPrev )
RETURN Self

METHOD SetCeletista( cTpRegJor, cNatAtividade, cCnpjSindCategProf, cDtBase ) CLASS TEsocialEventoAltContratual
   ::SetEscolha( "infoCeletista" )
   ::SetCampo( "tpRegJor", cTpRegJor )
   ::SetCampo( "natAtividade", cNatAtividade )
   IF ! Empty( hb_DefaultValue( cDtBase, "" ) )
      ::SetCampo( "dtBase", cDtBase )
   ENDIF
   ::SetCampo( "cnpjSindCategProf", OnlyDigits( cCnpjSindCategProf ) )
RETURN Self

METHOD SetEstatutario( cTpPlanRP, cIndTetoRGPS, cIndAbonoPerm ) CLASS TEsocialEventoAltContratual
   ::SetEscolha( "infoEstatutario" )
   ::SetCampo( "tpPlanRP", cTpPlanRP )
   ::SetCampo( "indTetoRGPS", cIndTetoRGPS )
   ::SetCampo( "indAbonoPerm", cIndAbonoPerm )
RETURN Self

METHOD SetContrato( cCodCateg, cNmCargo, cCBOCargo, cNmFuncao, cCBOFuncao, cAcumCargo ) CLASS TEsocialEventoAltContratual
   ::SetCampo( "codCateg", OnlyDigits( cCodCateg ) )
   IF ! Empty( hb_DefaultValue( cNmCargo, "" ) )
      ::SetCampo( "nmCargo", cNmCargo )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCBOCargo, "" ) )
      ::SetCampo( "CBOCargo", OnlyDigits( cCBOCargo ) )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNmFuncao, "" ) )
      ::SetCampo( "nmFuncao", cNmFuncao )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCBOFuncao, "" ) )
      ::SetCampo( "CBOFuncao", OnlyDigits( cCBOFuncao ) )
   ENDIF
   IF ! Empty( hb_DefaultValue( cAcumCargo, "" ) )
      ::SetCampo( "acumCargo", cAcumCargo )
   ENDIF
RETURN Self

METHOD SetRemuneracao( cVrSalFx, cUndSalFixo, cDscSalVar ) CLASS TEsocialEventoAltContratual
   ::SetGrupoOpcional( "remuneracao" )
   ::SetCampo( "vrSalFx", cVrSalFx )
   ::SetCampo( "undSalFixo", cUndSalFixo )
   IF ! Empty( hb_DefaultValue( cDscSalVar, "" ) )
      ::SetCampo( "dscSalVar", cDscSalVar )
   ENDIF
RETURN Self

METHOD SetDuracao( cTpContr, cDtTerm, cObjDet ) CLASS TEsocialEventoAltContratual
   ::SetGrupoOpcional( "duracao" )
   ::SetCampo( "tpContr", cTpContr )
   IF ! Empty( hb_DefaultValue( cDtTerm, "" ) )
      ::SetCampo( "dtTerm", cDtTerm )
   ENDIF
   IF ! Empty( hb_DefaultValue( cObjDet, "" ) )
      ::SetCampo( "objDet", cObjDet )
   ENDIF
RETURN Self

CLASS TEsocialEventoAnotJud FROM TEsocialEventoXml
   METHOD New()
   METHOD SetProcesso()
   METHOD SetAnotacao()
   METHOD SetCargo()
   METHOD SetRemuneracao()
ENDCLASS
METHOD New() CLASS TEsocialEventoAnotJud
   ::Super:New( "evtAnotJud", "evtAnotJud" )
RETURN Self

METHOD SetProcesso( cNrProcTrab, cDtSent, cUfVara, cCodMunic, cIdVara ) CLASS TEsocialEventoAnotJud
   ::SetCampo( "nrProcTrab", cNrProcTrab )
   ::SetCampo( "dtSent", cDtSent )
   ::SetCampo( "ufVara", Upper( AllTrim( hb_DefaultValue( cUfVara, "" ) ) ) )
   ::SetCampo( "codMunic", OnlyDigits( cCodMunic ) )
   ::SetCampo( "idVara", cIdVara )
RETURN Self

METHOD SetAnotacao( cCpfTrab, cNmTrab, cDtNascto, cDtAdm, cMatricula, cCodCateg, cNatAtividade, cTpContr, cTpRegTrab, cTpRegPrev ) CLASS TEsocialEventoAnotJud
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   ::SetCampo( "nmTrab", cNmTrab )
   ::SetCampo( "dtNascto", cDtNascto )
   ::SetCampo( "dtAdm", cDtAdm )
   ::SetCampo( "matricula", cMatricula )
   ::SetCampo( "codCateg", OnlyDigits( cCodCateg ) )
   ::SetCampo( "natAtividade", cNatAtividade )
   ::SetCampo( "tpContr", cTpContr )
   ::SetCampo( "tpRegTrab", cTpRegTrab )
   ::SetCampo( "tpRegPrev", cTpRegPrev )
RETURN Self

METHOD SetCargo( cDtCargo, cCBOCargo ) CLASS TEsocialEventoAnotJud
   ::SetCampo( "dtCargo", cDtCargo )
   ::SetCampo( "CBOCargo", OnlyDigits( cCBOCargo ) )
RETURN Self

METHOD SetRemuneracao( cDtRemun, cVrSalFx, cUndSalFixo, cDscSalVar ) CLASS TEsocialEventoAnotJud
   ::SetCampo( "dtRemun", cDtRemun )
   ::SetCampo( "vrSalFx", cVrSalFx )
   ::SetCampo( "undSalFixo", cUndSalFixo )
   IF ! Empty( hb_DefaultValue( cDscSalVar, "" ) )
      ::SetCampo( "dscSalVar", cDscSalVar )
   ENDIF
RETURN Self

CLASS TEsocialEventoBaixa FROM TEsocialEventoXml
   METHOD New()
   METHOD SetVinculo()
   METHOD SetBaixa()
ENDCLASS
METHOD New() CLASS TEsocialEventoBaixa
   ::Super:New( "evtBaixa", "evtBaixa" )
RETURN Self

METHOD SetVinculo( cCpfTrab, cMatricula ) CLASS TEsocialEventoBaixa
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   ::SetCampo( "matricula", cMatricula )
RETURN Self

METHOD SetBaixa( cMtvDeslig, cDtDeslig, cNrProcTrab, cDtProjFimAPI, cObservacao ) CLASS TEsocialEventoBaixa
   ::SetCampo( "mtvDeslig", cMtvDeslig )
   ::SetCampo( "dtDeslig", cDtDeslig )
   IF ! Empty( hb_DefaultValue( cDtProjFimAPI, "" ) )
      ::SetCampo( "dtProjFimAPI", cDtProjFimAPI )
   ENDIF
   ::SetCampo( "nrProcTrab", cNrProcTrab )
   IF ! Empty( hb_DefaultValue( cObservacao, "" ) )
      ::SetCampo( "observacao", cObservacao )
   ENDIF
RETURN Self

CLASS TEsocialEventoBasesFGTS FROM TEsocialEventoXml
   METHOD New()
ENDCLASS
METHOD New() CLASS TEsocialEventoBasesFGTS
   ::Super:New( "evtBasesFGTS", "evtBasesFGTS" )
RETURN Self

CLASS TEsocialEventoBasesTrab FROM TEsocialEventoXml
   METHOD New()
ENDCLASS
METHOD New() CLASS TEsocialEventoBasesTrab
   ::Super:New( "evtBasesTrab", "evtBasesTrab" )
RETURN Self

CLASS TEsocialEventoBenPrRP FROM TEsocialEventoXml
   METHOD New()
   METHOD SetBeneficiario()
   METHOD SetDemonstrativo()
   METHOD SetItemRemuneracao()
ENDCLASS
METHOD New() CLASS TEsocialEventoBenPrRP
   ::Super:New( "evtBenPrRP", "evtBenPrRP" )
RETURN Self

METHOD SetBeneficiario( cCpfBenef ) CLASS TEsocialEventoBenPrRP
RETURN ::SetCampo( "cpfBenef", OnlyDigits( cCpfBenef ) )

METHOD SetDemonstrativo( cIdeDmDev, cNrBeneficio ) CLASS TEsocialEventoBenPrRP
   ::SetCampo( "ideDmDev", cIdeDmDev )
   ::SetCampo( "nrBeneficio", cNrBeneficio )
RETURN Self

METHOD SetItemRemuneracao( cCodRubr, cIdeTabRubr, cVrRubr, cIndApurIR, cQtdRubr, cFatorRubr ) CLASS TEsocialEventoBenPrRP
   ::SetGrupoOpcional( "infoPerAnt" )
   ::SetCampo( "codRubr", cCodRubr )
   ::SetCampo( "ideTabRubr", cIdeTabRubr )
   IF ! Empty( hb_DefaultValue( cQtdRubr, "" ) )
      ::SetCampo( "qtdRubr", cQtdRubr )
   ENDIF
   IF ! Empty( hb_DefaultValue( cFatorRubr, "" ) )
      ::SetCampo( "fatorRubr", cFatorRubr )
   ENDIF
   ::SetCampo( "vrRubr", cVrRubr )
   IF ! Empty( hb_DefaultValue( cIndApurIR, "" ) )
      ::SetCampo( "indApurIR", cIndApurIR )
   ENDIF
RETURN Self

CLASS TEsocialEventoCdBenAlt FROM TEsocialEventoXml
   METHOD New()
   METHOD SetIdeBeneficio()
   METHOD SetAlteracaoBeneficio()
ENDCLASS
METHOD New() CLASS TEsocialEventoCdBenAlt
   ::Super:New( "evtCdBenAlt", "evtCdBenAlt" )
RETURN Self

METHOD SetIdeBeneficio( cCpfBenef, cNrBeneficio ) CLASS TEsocialEventoCdBenAlt
   ::SetCampo( "cpfBenef", OnlyDigits( cCpfBenef ) )
   ::SetCampo( "nrBeneficio", cNrBeneficio )
RETURN Self

METHOD SetAlteracaoBeneficio( cDtAltBeneficio, cTpBeneficio, cTpPlanRP, cIndSuspensao, cDsc ) CLASS TEsocialEventoCdBenAlt
   ::SetCampo( "dtAltBeneficio", cDtAltBeneficio )
   ::SetCampo( "tpBeneficio", cTpBeneficio )
   ::SetCampo( "tpPlanRP", cTpPlanRP )
   ::SetCampo( "indSuspensao", cIndSuspensao )
   IF ! Empty( hb_DefaultValue( cDsc, "" ) )
      ::SetCampo( "dsc", cDsc )
   ENDIF
RETURN Self

CLASS TEsocialEventoCdBenefAlt FROM TEsocialEventoXml
   METHOD New()
   METHOD SetBeneficiario()
   METHOD SetAlteracao()
   METHOD SetEnderecoBrasil()
ENDCLASS
METHOD New() CLASS TEsocialEventoCdBenefAlt
   ::Super:New( "evtCdBenefAlt", "evtCdBenefAlt" )
RETURN Self

METHOD SetBeneficiario( cCpfBenef, cNmBenefic, cSexo, cRacaCor, cIncFisMen, cEstCiv ) CLASS TEsocialEventoCdBenefAlt
   ::SetCampo( "cpfBenef", OnlyDigits( cCpfBenef ) )
   ::SetCampo( "nmBenefic", cNmBenefic )
   ::SetCampo( "sexo", cSexo )
   ::SetCampo( "racaCor", cRacaCor )
   ::SetCampo( "incFisMen", cIncFisMen )
   IF ! Empty( hb_DefaultValue( cEstCiv, "" ) )
      ::SetCampo( "estCiv", cEstCiv )
   ENDIF
RETURN Self

METHOD SetAlteracao( cDtAlteracao ) CLASS TEsocialEventoCdBenefAlt
RETURN ::SetCampo( "dtAlteracao", cDtAlteracao )

METHOD SetEnderecoBrasil( cDscLograd, cNrLograd, cCep, cCodMunic, cUf, cTpLograd, cComplemento, cBairro ) CLASS TEsocialEventoCdBenefAlt
   ::SetEscolha( "brasil" )
   IF ! Empty( hb_DefaultValue( cTpLograd, "" ) )
      ::SetCampo( "tpLograd", cTpLograd )
   ENDIF
   ::SetCampo( "dscLograd", cDscLograd )
   ::SetCampo( "nrLograd", cNrLograd )
   ::SetCampo( "cep", OnlyDigits( cCep ) )
   ::SetCampo( "codMunic", OnlyDigits( cCodMunic ) )
   ::SetCampo( "uf", Upper( AllTrim( hb_DefaultValue( cUf, "" ) ) ) )
   IF ! Empty( hb_DefaultValue( cComplemento, "" ) )
      ::SetCampo( "complemento", cComplemento )
   ENDIF
   IF ! Empty( hb_DefaultValue( cBairro, "" ) )
      ::SetCampo( "bairro", cBairro )
   ENDIF
RETURN Self

CLASS TEsocialEventoCdBenefIn FROM TEsocialEventoXml
   METHOD New()
   METHOD SetBeneficiario()
   METHOD SetEnderecoBrasil()
ENDCLASS
METHOD New() CLASS TEsocialEventoCdBenefIn
   ::Super:New( "evtCdBenefIn", "evtCdBenefIn" )
RETURN Self

METHOD SetBeneficiario( cCpfBenef, cNmBenefic, cDtNascto, cDtInicio, cRacaCor, cIncFisMen, cSexo, cEstCiv ) CLASS TEsocialEventoCdBenefIn
   ::SetCampo( "cpfBenef", OnlyDigits( cCpfBenef ) )
   ::SetCampo( "nmBenefic", cNmBenefic )
   ::SetCampo( "dtNascto", cDtNascto )
   ::SetCampo( "dtInicio", cDtInicio )
   IF ! Empty( hb_DefaultValue( cSexo, "" ) )
      ::SetCampo( "sexo", cSexo )
   ENDIF
   ::SetCampo( "racaCor", cRacaCor )
   IF ! Empty( hb_DefaultValue( cEstCiv, "" ) )
      ::SetCampo( "estCiv", cEstCiv )
   ENDIF
   ::SetCampo( "incFisMen", cIncFisMen )
RETURN Self

METHOD SetEnderecoBrasil( cDscLograd, cNrLograd, cCep, cCodMunic, cUf, cTpLograd, cComplemento, cBairro ) CLASS TEsocialEventoCdBenefIn
   ::SetEscolha( "brasil" )
   IF ! Empty( hb_DefaultValue( cTpLograd, "" ) )
      ::SetCampo( "tpLograd", cTpLograd )
   ENDIF
   ::SetCampo( "dscLograd", cDscLograd )
   ::SetCampo( "nrLograd", cNrLograd )
   ::SetCampo( "cep", OnlyDigits( cCep ) )
   ::SetCampo( "codMunic", OnlyDigits( cCodMunic ) )
   ::SetCampo( "uf", Upper( AllTrim( hb_DefaultValue( cUf, "" ) ) ) )
   IF ! Empty( hb_DefaultValue( cComplemento, "" ) )
      ::SetCampo( "complemento", cComplemento )
   ENDIF
   IF ! Empty( hb_DefaultValue( cBairro, "" ) )
      ::SetCampo( "bairro", cBairro )
   ENDIF
RETURN Self

CLASS TEsocialEventoCdBenIn FROM TEsocialEventoXml
   METHOD New()
   METHOD SetBeneficiario()
   METHOD SetBeneficio()
ENDCLASS
METHOD New() CLASS TEsocialEventoCdBenIn
   ::Super:New( "evtCdBenIn", "evtCdBenIn" )
RETURN Self

METHOD SetBeneficiario( cCpfBenef, cMatricula, cCnpjOrigem ) CLASS TEsocialEventoCdBenIn
   ::SetCampo( "cpfBenef", OnlyDigits( cCpfBenef ) )
   IF ! Empty( hb_DefaultValue( cMatricula, "" ) )
      ::SetCampo( "matricula", cMatricula )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCnpjOrigem, "" ) )
      ::SetCampo( "cnpjOrigem", OnlyDigits( cCnpjOrigem ) )
   ENDIF
RETURN Self

METHOD SetBeneficio( cCadIni, cNrBeneficio, cDtIniBeneficio, cTpBeneficio, cTpPlanRP, cIndSitBenef, cDsc ) CLASS TEsocialEventoCdBenIn
   ::SetCampo( "cadIni", cCadIni )
   IF ! Empty( hb_DefaultValue( cIndSitBenef, "" ) )
      ::SetCampo( "indSitBenef", cIndSitBenef )
   ENDIF
   ::SetCampo( "nrBeneficio", cNrBeneficio )
   ::SetCampo( "dtIniBeneficio", cDtIniBeneficio )
   ::SetCampo( "tpBeneficio", cTpBeneficio )
   ::SetCampo( "tpPlanRP", cTpPlanRP )
   IF ! Empty( hb_DefaultValue( cDsc, "" ) )
      ::SetCampo( "dsc", cDsc )
   ENDIF
RETURN Self

CLASS TEsocialEventoCdBenTerm FROM TEsocialEventoXml
   METHOD New()
   METHOD SetIdeBeneficio()
   METHOD SetTerminoBeneficio()
ENDCLASS
METHOD New() CLASS TEsocialEventoCdBenTerm
   ::Super:New( "evtCdBenTerm", "evtCdBenTerm" )
RETURN Self

METHOD SetIdeBeneficio( cCpfBenef, cNrBeneficio ) CLASS TEsocialEventoCdBenTerm
   ::SetCampo( "cpfBenef", OnlyDigits( cCpfBenef ) )
   ::SetCampo( "nrBeneficio", cNrBeneficio )
RETURN Self

METHOD SetTerminoBeneficio( cDtTermBeneficio, cMtvTermino, cCnpjOrgaoSuc, cNovoCPF ) CLASS TEsocialEventoCdBenTerm
   ::SetCampo( "dtTermBeneficio", cDtTermBeneficio )
   ::SetCampo( "mtvTermino", cMtvTermino )
   IF ! Empty( hb_DefaultValue( cCnpjOrgaoSuc, "" ) )
      ::SetCampo( "cnpjOrgaoSuc", OnlyDigits( cCnpjOrgaoSuc ) )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNovoCPF, "" ) )
      ::SetCampo( "novoCPF", OnlyDigits( cNovoCPF ) )
   ENDIF
RETURN Self

CLASS TEsocialEventoCessao FROM TEsocialEventoXml
   METHOD New()
   METHOD SetVinculo()
   METHOD SetInicioCessao()
   METHOD SetFimCessao()
ENDCLASS
METHOD New() CLASS TEsocialEventoCessao
   ::Super:New( "evtCessao", "evtCessao" )
RETURN Self

METHOD SetVinculo( cCpfTrab, cMatricula ) CLASS TEsocialEventoCessao
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   ::SetCampo( "matricula", cMatricula )
RETURN Self

METHOD SetInicioCessao( cDtIniCessao, cCnpjCess, cRespRemun ) CLASS TEsocialEventoCessao
   ::SetEscolha( "iniCessao" )
   ::SetCampo( "dtIniCessao", cDtIniCessao )
   ::SetCampo( "cnpjCess", OnlyDigits( cCnpjCess ) )
   ::SetCampo( "respRemun", cRespRemun )
RETURN Self

METHOD SetFimCessao( cDtTermCessao ) CLASS TEsocialEventoCessao
   ::SetEscolha( "fimCessao" )
RETURN ::SetCampo( "dtTermCessao", cDtTermCessao )

CLASS TEsocialEventoComProd FROM TEsocialEventoXml
   METHOD New()
   METHOD SetComercializacao()
ENDCLASS
METHOD New() CLASS TEsocialEventoComProd
   ::Super:New( "evtComProd", "evtComProd" )
RETURN Self

METHOD SetComercializacao( cPerApur, cNrInscEstabRural, cIndComerc, cVrTotCom ) CLASS TEsocialEventoComProd
   ::SetPeriodo( cPerApur, "" )
   ::SetCampo( "nrInscEstabRural", OnlyDigits( cNrInscEstabRural ) )
   ::SetCampo( "indComerc", cIndComerc )
   ::SetCampo( "vrTotCom", cVrTotCom )
RETURN Self

CLASS TEsocialEventoConsolidContProc FROM TEsocialEventoXml
   METHOD New()
   METHOD SetConsolidacao()
ENDCLASS
METHOD New() CLASS TEsocialEventoConsolidContProc
   ::Super:New( "evtConsolidContProc", "evtConsolidContProc" )
RETURN Self

METHOD SetConsolidacao( cNrProcTrab, cPerApurPgto ) CLASS TEsocialEventoConsolidContProc
   ::SetCampo( "nrProcTrab", cNrProcTrab )
   ::SetCampo( "perApurPgto", cPerApurPgto )
RETURN Self

CLASS TEsocialEventoContProc FROM TEsocialEventoXml
   METHOD New()
   METHOD SetIdeProcesso()
ENDCLASS
METHOD New() CLASS TEsocialEventoContProc
   ::Super:New( "evtContProc", "evtContProc" )
RETURN Self

METHOD SetIdeProcesso( cNrProcTrab, cPerApurPgto, cIdeSeqProc, cObs ) CLASS TEsocialEventoContProc
   ::SetCampo( "nrProcTrab", cNrProcTrab )
   ::SetCampo( "perApurPgto", cPerApurPgto )
   IF ! Empty( hb_DefaultValue( cIdeSeqProc, "" ) )
      ::SetCampo( "ideSeqProc", cIdeSeqProc )
   ENDIF
   IF ! Empty( hb_DefaultValue( cObs, "" ) )
      ::SetCampo( "obs", cObs )
   ENDIF
RETURN Self

CLASS TEsocialEventoContratAvNP FROM TEsocialEventoXml
   METHOD New()
   METHOD SetRemuneracaoAvulso()
ENDCLASS
METHOD New() CLASS TEsocialEventoContratAvNP
   ::Super:New( "evtContratAvNP", "evtContratAvNP" )
RETURN Self

METHOD SetRemuneracaoAvulso( cPerApur, cTpInsc, cNrInsc, cCodLotacao, cVrBcCp00, cVrBcCp15, cVrBcCp20, cVrBcCp25, cVrBcCp13, cVrBcFgts, cVrDescCP ) CLASS TEsocialEventoContratAvNP
   ::SetPeriodo( cPerApur, "" )
   ::SetCampo( "tpInsc", cTpInsc )
   ::SetCampo( "nrInsc", OnlyDigits( cNrInsc ) )
   ::SetCampo( "codLotacao", cCodLotacao )
   ::SetCampo( "vrBcCp00", cVrBcCp00 )
   ::SetCampo( "vrBcCp15", cVrBcCp15 )
   ::SetCampo( "vrBcCp20", cVrBcCp20 )
   ::SetCampo( "vrBcCp25", cVrBcCp25 )
   ::SetCampo( "vrBcCp13", cVrBcCp13 )
   ::SetCampo( "vrBcFgts", cVrBcFgts )
   ::SetCampo( "vrDescCP", cVrDescCP )
RETURN Self

CLASS TEsocialEventoCS FROM TEsocialEventoXml
   METHOD New()
ENDCLASS
METHOD New() CLASS TEsocialEventoCS
   ::Super:New( "evtCS", "evtCS" )
RETURN Self

CLASS TEsocialEventoDeslig FROM TEsocialEventoXml
   METHOD New()
   METHOD SetVinculo()
   METHOD SetDesligamento()
   METHOD SetPensaoAlimenticia()
   METHOD SetObservacao()
   METHOD SetIndGuia()
ENDCLASS
METHOD New() CLASS TEsocialEventoDeslig
   ::Super:New( "evtDeslig", "evtDeslig" )
RETURN Self

METHOD SetVinculo( cCpfTrab, cMatricula ) CLASS TEsocialEventoDeslig
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   ::SetCampo( "matricula", cMatricula )
RETURN Self

METHOD SetDesligamento( cMtvDeslig, cDtDeslig, cIndPagtoAPI, cDtAvPrv, cDtProjFimAPI, cNrProcTrab, cIndPDV ) CLASS TEsocialEventoDeslig
   ::SetCampo( "mtvDeslig", cMtvDeslig )
   ::SetCampo( "dtDeslig", cDtDeslig )
   ::SetCampo( "indPagtoAPI", hb_DefaultValue( cIndPagtoAPI, "N" ) )
   IF ! Empty( hb_DefaultValue( cDtAvPrv, "" ) )
      ::SetCampo( "dtAvPrv", cDtAvPrv )
   ENDIF
   IF ! Empty( hb_DefaultValue( cDtProjFimAPI, "" ) )
      ::SetCampo( "dtProjFimAPI", cDtProjFimAPI )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNrProcTrab, "" ) )
      ::SetCampo( "nrProcTrab", cNrProcTrab )
   ENDIF
   IF ! Empty( hb_DefaultValue( cIndPDV, "" ) )
      ::SetCampo( "indPDV", cIndPDV )
   ENDIF
RETURN Self

METHOD SetPensaoAlimenticia( cPensAlim, cPercAliment, cVrAlim ) CLASS TEsocialEventoDeslig
   IF ! Empty( hb_DefaultValue( cPensAlim, "" ) )
      ::SetCampo( "pensAlim", cPensAlim )
   ENDIF
   IF ! Empty( hb_DefaultValue( cPercAliment, "" ) )
      ::SetCampo( "percAliment", cPercAliment )
   ENDIF
   IF ! Empty( hb_DefaultValue( cVrAlim, "" ) )
      ::SetCampo( "vrAlim", cVrAlim )
   ENDIF
RETURN Self

METHOD SetObservacao( cObservacao ) CLASS TEsocialEventoDeslig
   ::SetGrupoOpcional( "observacoes" )
RETURN ::SetCampo( "observacao", cObservacao )

METHOD SetIndGuia( cIndGuia ) CLASS TEsocialEventoDeslig
RETURN ::SetCampo( "indGuia", cIndGuia )

CLASS TEsocialEventoExcProcTrab FROM TEsocialEventoXml
   METHOD New()
   METHOD SetExclusaoProcTrab()
ENDCLASS
METHOD New() CLASS TEsocialEventoExcProcTrab
   ::Super:New( "evtExcProcTrab", "evtExcProcTrab" )
RETURN Self

METHOD SetExclusaoProcTrab( cTpEvento, cNrRecEvt, cNrProcTrab, cCpfTrab, cPerApurPgto, cIdeSeqProc ) CLASS TEsocialEventoExcProcTrab
   ::SetCampo( "tpEvento", cTpEvento )
   ::SetCampo( "nrRecEvt", cNrRecEvt )
   ::SetCampo( "nrProcTrab", cNrProcTrab )
   IF ! Empty( hb_DefaultValue( cCpfTrab, "" ) )
      ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   ENDIF
   IF ! Empty( hb_DefaultValue( cPerApurPgto, "" ) )
      ::SetCampo( "perApurPgto", cPerApurPgto )
   ENDIF
   IF ! Empty( hb_DefaultValue( cIdeSeqProc, "" ) )
      ::SetCampo( "ideSeqProc", cIdeSeqProc )
   ENDIF
RETURN Self

CLASS TEsocialEventoFechaEvPer FROM TEsocialEventoXml
   METHOD New()
   METHOD SetFechamento()
ENDCLASS
METHOD New() CLASS TEsocialEventoFechaEvPer
   ::Super:New( "evtFechaEvPer", "evtFechaEvPer" )
RETURN Self

METHOD SetFechamento( cIndApuracao, cPerApur, cEvtRemun, cEvtPgtos, cEvtComProd, cEvtContratAvNP, cEvtInfoComplPer, cTransDCTFWeb, cNaoValid ) CLASS TEsocialEventoFechaEvPer
   ::SetPeriodo( cPerApur, cIndApuracao )
   ::SetCampo( "evtRemun", hb_DefaultValue( cEvtRemun, "S" ) )
   ::SetCampo( "evtPgtos", hb_DefaultValue( cEvtPgtos, "S" ) )
   ::SetCampo( "evtComProd", hb_DefaultValue( cEvtComProd, "N" ) )
   ::SetCampo( "evtContratAvNP", hb_DefaultValue( cEvtContratAvNP, "N" ) )
   ::SetCampo( "evtInfoComplPer", hb_DefaultValue( cEvtInfoComplPer, "N" ) )
   IF ! Empty( hb_DefaultValue( cTransDCTFWeb, "" ) )
      ::SetCampo( "transDCTFWeb", cTransDCTFWeb )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNaoValid, "" ) )
      ::SetCampo( "naoValid", cNaoValid )
   ENDIF
RETURN Self

CLASS TEsocialEventoFGTS FROM TEsocialEventoXml
   METHOD New()
ENDCLASS
METHOD New() CLASS TEsocialEventoFGTS
   ::Super:New( "evtFGTS", "evtFGTS" )
RETURN Self

CLASS TEsocialEventoFGTSProcTrab FROM TEsocialEventoXml
   METHOD New()
ENDCLASS
METHOD New() CLASS TEsocialEventoFGTSProcTrab
   ::Super:New( "evtFGTSProcTrab", "evtFGTSProcTrab" )
RETURN Self

CLASS TEsocialEventoInfoComplPer FROM TEsocialEventoXml
   METHOD New()
   METHOD SetSubstPatronal()
   METHOD SetAtividadeConcomitante()
ENDCLASS
METHOD New() CLASS TEsocialEventoInfoComplPer
   ::Super:New( "evtInfoComplPer", "evtInfoComplPer" )
RETURN Self

METHOD SetSubstPatronal( cIndSubstPatr, cPercRedContrib ) CLASS TEsocialEventoInfoComplPer
   ::SetGrupoOpcional( "infoSubstPatr" )
   ::SetCampo( "indSubstPatr", cIndSubstPatr )
   ::SetCampo( "percRedContrib", cPercRedContrib )
RETURN Self

METHOD SetAtividadeConcomitante( cFatorMes, cFator13 ) CLASS TEsocialEventoInfoComplPer
   ::SetGrupoOpcional( "infoAtivConcom" )
   ::SetCampo( "fatorMes", cFatorMes )
   ::SetCampo( "fator13", cFator13 )
RETURN Self

CLASS TEsocialEventoInfoEmpregador FROM TEsocialEventoXml
   METHOD New()
   METHOD SetInfoCadastro()
   METHOD SetDadosIsencao()
   METHOD SetInfoOrgInternacional()
   METHOD SetNovaValidade()
ENDCLASS
METHOD New() CLASS TEsocialEventoInfoEmpregador
   ::Super:New( "evtInfoEmpregador", "evtInfoEmpregador" )
RETURN Self

METHOD SetInfoCadastro( cClassTrib, cIndDesFolha, cIndOptRegEletron, cIndCoop, cIndConstr, cIndOpcCP, cIndPorte, cCnpjEFR, cDtTrans11096, cIndTribFolhaPisPasep, cIndPertIRRF ) CLASS TEsocialEventoInfoEmpregador
   ::SetCampo( "classTrib", cClassTrib )
   ::SetCampo( "indDesFolha", cIndDesFolha )
   ::SetCampo( "indOptRegEletron", cIndOptRegEletron )
   IF ! Empty( hb_DefaultValue( cIndCoop, "" ) )
      ::SetCampo( "indCoop", cIndCoop )
   ENDIF
   IF ! Empty( hb_DefaultValue( cIndConstr, "" ) )
      ::SetCampo( "indConstr", cIndConstr )
   ENDIF
   IF ! Empty( hb_DefaultValue( cIndOpcCP, "" ) )
      ::SetCampo( "indOpcCP", cIndOpcCP )
   ENDIF
   IF ! Empty( hb_DefaultValue( cIndPorte, "" ) )
      ::SetCampo( "indPorte", cIndPorte )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCnpjEFR, "" ) )
      ::SetCampo( "cnpjEFR", OnlyDigits( cCnpjEFR ) )
   ENDIF
   IF ! Empty( hb_DefaultValue( cDtTrans11096, "" ) )
      ::SetCampo( "dtTrans11096", cDtTrans11096 )
   ENDIF
   IF ! Empty( hb_DefaultValue( cIndTribFolhaPisPasep, "" ) )
      ::SetCampo( "indTribFolhaPisPasep", cIndTribFolhaPisPasep )
   ENDIF
   IF ! Empty( hb_DefaultValue( cIndPertIRRF, "" ) )
      ::SetCampo( "indPertIRRF", cIndPertIRRF )
   ENDIF
RETURN Self

METHOD SetDadosIsencao( cIdeMinLei, cNrCertif, cDtEmisCertif, cDtVencCertif, cNrProtRenov, cDtProtRenov, cDtDou, cPagDou ) CLASS TEsocialEventoInfoEmpregador
   ::SetCampo( "ideMinLei", cIdeMinLei )
   ::SetCampo( "nrCertif", cNrCertif )
   ::SetCampo( "dtEmisCertif", cDtEmisCertif )
   ::SetCampo( "dtVencCertif", cDtVencCertif )
   IF ! Empty( hb_DefaultValue( cNrProtRenov, "" ) )
      ::SetCampo( "nrProtRenov", cNrProtRenov )
   ENDIF
   IF ! Empty( hb_DefaultValue( cDtProtRenov, "" ) )
      ::SetCampo( "dtProtRenov", cDtProtRenov )
   ENDIF
   IF ! Empty( hb_DefaultValue( cDtDou, "" ) )
      ::SetCampo( "dtDou", cDtDou )
   ENDIF
   IF ! Empty( hb_DefaultValue( cPagDou, "" ) )
      ::SetCampo( "pagDou", cPagDou )
   ENDIF
RETURN Self

METHOD SetInfoOrgInternacional( cIndAcordoIsenMulta ) CLASS TEsocialEventoInfoEmpregador
RETURN ::SetCampo( "indAcordoIsenMulta", cIndAcordoIsenMulta )

METHOD SetNovaValidade( cIniValid, cFimValid ) CLASS TEsocialEventoInfoEmpregador
   IF ! Empty( hb_DefaultValue( cIniValid, "" ) )
      ::SetCampo( "iniValid", cIniValid )
   ENDIF
   IF ! Empty( hb_DefaultValue( cFimValid, "" ) )
      ::SetCampo( "fimValid", cFimValid )
   ENDIF
RETURN Self

CLASS TEsocialEventoIrrf FROM TEsocialEventoXml
   METHOD New()
ENDCLASS
METHOD New() CLASS TEsocialEventoIrrf
   ::Super:New( "evtIrrf", "evtIrrf" )
RETURN Self

CLASS TEsocialEventoIrrfBenef FROM TEsocialEventoXml
   METHOD New()
ENDCLASS
METHOD New() CLASS TEsocialEventoIrrfBenef
   ::Super:New( "evtIrrfBenef", "evtIrrfBenef" )
RETURN Self

CLASS TEsocialEventoPgtos FROM TEsocialEventoXml
   METHOD New()
   METHOD SetBeneficiario()
   METHOD SetInfoPgto()
ENDCLASS
METHOD New() CLASS TEsocialEventoPgtos
   ::Super:New( "evtPgtos", "evtPgtos" )
RETURN Self

METHOD SetBeneficiario( cCpfBenef ) CLASS TEsocialEventoPgtos
RETURN ::SetCampo( "cpfBenef", OnlyDigits( cCpfBenef ) )

METHOD SetInfoPgto( cDtPgto, cTpPgto, cPerRef, cIdeDmDev, cVrLiq, cPaisResidExt ) CLASS TEsocialEventoPgtos
   ::SetGrupoOpcional( "infoPgto" )
   ::SetCampo( "dtPgto", cDtPgto )
   ::SetCampo( "tpPgto", cTpPgto )
   ::SetCampo( "perRef", cPerRef )
   ::SetCampo( "ideDmDev", cIdeDmDev )
   ::SetCampo( "vrLiq", cVrLiq )
   IF ! Empty( hb_DefaultValue( cPaisResidExt, "" ) )
      ::SetCampo( "paisResidExt", cPaisResidExt )
   ENDIF
RETURN Self

CLASS TEsocialEventoProcTrab FROM TEsocialEventoXml
   METHOD New()
   METHOD SetProcesso()
   METHOD SetProcessoJudicial()
   METHOD SetProcessoCCP()
   METHOD SetTrabalhador()
   METHOD SetContrato()
ENDCLASS
METHOD New() CLASS TEsocialEventoProcTrab
   ::Super:New( "evtProcTrab", "evtProcTrab" )
RETURN Self

METHOD SetProcesso( cOrigem, cNrProcTrab, cObsProcTrab ) CLASS TEsocialEventoProcTrab
   ::SetCampo( "origem", cOrigem )
   ::SetCampo( "nrProcTrab", cNrProcTrab )
   IF ! Empty( hb_DefaultValue( cObsProcTrab, "" ) )
      ::SetCampo( "obsProcTrab", cObsProcTrab )
   ENDIF
RETURN Self

METHOD SetProcessoJudicial( cDtSent, cUfVara, cCodMunic, cIdVara ) CLASS TEsocialEventoProcTrab
   ::SetEscolha( "infoProcJud" )
   ::SetCampo( "dtSent", cDtSent )
   ::SetCampo( "ufVara", Upper( AllTrim( hb_DefaultValue( cUfVara, "" ) ) ) )
   ::SetCampo( "codMunic", OnlyDigits( cCodMunic ) )
   ::SetCampo( "idVara", cIdVara )
RETURN Self

METHOD SetProcessoCCP( cDtCCP, cTpCCP, cCnpjCCP ) CLASS TEsocialEventoProcTrab
   ::SetEscolha( "infoCCP" )
   ::SetCampo( "dtCCP", cDtCCP )
   ::SetCampo( "tpCCP", cTpCCP )
   IF ! Empty( hb_DefaultValue( cCnpjCCP, "" ) )
      ::SetCampo( "cnpjCCP", OnlyDigits( cCnpjCCP ) )
   ENDIF
RETURN Self

METHOD SetTrabalhador( cCpfTrab, cNmTrab, cDtNascto ) CLASS TEsocialEventoProcTrab
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   IF ! Empty( hb_DefaultValue( cNmTrab, "" ) )
      ::SetCampo( "nmTrab", cNmTrab )
   ENDIF
   IF ! Empty( hb_DefaultValue( cDtNascto, "" ) )
      ::SetCampo( "dtNascto", cDtNascto )
   ENDIF
RETURN Self

METHOD SetContrato( cTpContr, cIndContr, cIndCateg, cIndNatAtiv, cIndMotDeslig, cMatricula, cCodCateg, cDtInicio ) CLASS TEsocialEventoProcTrab
   ::SetCampo( "tpContr", cTpContr )
   ::SetCampo( "indContr", cIndContr )
   ::SetCampo( "indCateg", cIndCateg )
   ::SetCampo( "indNatAtiv", cIndNatAtiv )
   ::SetCampo( "indMotDeslig", cIndMotDeslig )
   IF ! Empty( hb_DefaultValue( cMatricula, "" ) )
      ::SetCampo( "matricula", cMatricula )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCodCateg, "" ) )
      ::SetCampo( "codCateg", OnlyDigits( cCodCateg ) )
   ENDIF
   IF ! Empty( hb_DefaultValue( cDtInicio, "" ) )
      ::SetCampo( "dtInicio", cDtInicio )
   ENDIF
RETURN Self

CLASS TEsocialEventoReabreEvPer FROM TEsocialEventoXml
   METHOD New()
   METHOD SetReabertura()
ENDCLASS
METHOD New() CLASS TEsocialEventoReabreEvPer
   ::Super:New( "evtReabreEvPer", "evtReabreEvPer" )
RETURN Self

METHOD SetReabertura( cIndApuracao, cPerApur ) CLASS TEsocialEventoReabreEvPer
RETURN ::SetPeriodo( cPerApur, cIndApuracao )

CLASS TEsocialEventoReativBen FROM TEsocialEventoXml
   METHOD New()
   METHOD SetIdeBeneficio()
   METHOD SetReativacao()
ENDCLASS
METHOD New() CLASS TEsocialEventoReativBen
   ::Super:New( "evtReativBen", "evtReativBen" )
RETURN Self

METHOD SetIdeBeneficio( cCpfBenef, cNrBeneficio ) CLASS TEsocialEventoReativBen
   ::SetCampo( "cpfBenef", OnlyDigits( cCpfBenef ) )
   ::SetCampo( "nrBeneficio", cNrBeneficio )
RETURN Self

METHOD SetReativacao( cDtEfetReativ, cDtEfeito ) CLASS TEsocialEventoReativBen
   ::SetCampo( "dtEfetReativ", cDtEfetReativ )
   ::SetCampo( "dtEfeito", cDtEfeito )
RETURN Self

CLASS TEsocialEventoReintegr FROM TEsocialEventoXml
   METHOD New()
   METHOD SetVinculo()
   METHOD SetReintegracao()
ENDCLASS
METHOD New() CLASS TEsocialEventoReintegr
   ::Super:New( "evtReintegr", "evtReintegr" )
RETURN Self

METHOD SetVinculo( cCpfTrab, cMatricula ) CLASS TEsocialEventoReintegr
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   ::SetCampo( "matricula", cMatricula )
RETURN Self

METHOD SetReintegracao( cTpReint, cDtEfetRetorno, cDtEfeito, cNrProcJud, cNrLeiAnistia ) CLASS TEsocialEventoReintegr
   ::SetCampo( "tpReint", cTpReint )
   IF ! Empty( hb_DefaultValue( cNrProcJud, "" ) )
      ::SetCampo( "nrProcJud", cNrProcJud )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNrLeiAnistia, "" ) )
      ::SetCampo( "nrLeiAnistia", cNrLeiAnistia )
   ENDIF
   ::SetCampo( "dtEfetRetorno", cDtEfetRetorno )
   ::SetCampo( "dtEfeito", cDtEfeito )
RETURN Self

CLASS TEsocialEventoRemun FROM TEsocialEventoXml
   METHOD New()
   METHOD SetTrabalhador()
   METHOD SetDemonstrativo()
   METHOD SetEstabLotacao()
   METHOD SetItemRemuneracao()
ENDCLASS
METHOD New() CLASS TEsocialEventoRemun
   ::Super:New( "evtRemun", "evtRemun" )
RETURN Self

METHOD SetTrabalhador( cCpfTrab ) CLASS TEsocialEventoRemun
RETURN ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )

METHOD SetDemonstrativo( cIdeDmDev, cCodCateg ) CLASS TEsocialEventoRemun
   ::SetCampo( "ideDmDev", cIdeDmDev )
   ::SetCampo( "codCateg", OnlyDigits( cCodCateg ) )
RETURN Self

METHOD SetEstabLotacao( cTpInsc, cNrInsc, cCodLotacao, cMatricula, cIndSimples ) CLASS TEsocialEventoRemun
   ::SetGrupoOpcional( "infoPerApur" )
   ::SetCampo( "tpInsc", cTpInsc )
   ::SetCampo( "nrInsc", OnlyDigits( cNrInsc ) )
   ::SetCampo( "codLotacao", cCodLotacao )
   IF ! Empty( hb_DefaultValue( cMatricula, "" ) )
      ::SetCampo( "matricula", cMatricula )
   ENDIF
   IF ! Empty( hb_DefaultValue( cIndSimples, "" ) )
      ::SetCampo( "indSimples", cIndSimples )
   ENDIF
RETURN Self

METHOD SetItemRemuneracao( cCodRubr, cIdeTabRubr, cVrRubr, cIndApurIR, cQtdRubr, cFatorRubr ) CLASS TEsocialEventoRemun
   ::SetCampo( "codRubr", cCodRubr )
   ::SetCampo( "ideTabRubr", cIdeTabRubr )
   IF ! Empty( hb_DefaultValue( cQtdRubr, "" ) )
      ::SetCampo( "qtdRubr", cQtdRubr )
   ENDIF
   IF ! Empty( hb_DefaultValue( cFatorRubr, "" ) )
      ::SetCampo( "fatorRubr", cFatorRubr )
   ENDIF
   ::SetCampo( "vrRubr", cVrRubr )
   IF ! Empty( hb_DefaultValue( cIndApurIR, "" ) )
      ::SetCampo( "indApurIR", cIndApurIR )
   ENDIF
RETURN Self

CLASS TEsocialEventoRmnRPPS FROM TEsocialEventoXml
   METHOD New()
   METHOD SetTrabalhador()
   METHOD SetDemonstrativo()
   METHOD SetEstabelecimento()
   METHOD SetItemRemuneracao()
ENDCLASS
METHOD New() CLASS TEsocialEventoRmnRPPS
   ::Super:New( "evtRmnRPPS", "evtRmnRPPS" )
RETURN Self

METHOD SetTrabalhador( cCpfTrab ) CLASS TEsocialEventoRmnRPPS
RETURN ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )

METHOD SetDemonstrativo( cIdeDmDev, cCodCateg ) CLASS TEsocialEventoRmnRPPS
   ::SetCampo( "ideDmDev", cIdeDmDev )
   ::SetCampo( "codCateg", OnlyDigits( cCodCateg ) )
RETURN Self

METHOD SetEstabelecimento( cTpInsc, cNrInsc, cMatricula ) CLASS TEsocialEventoRmnRPPS
   ::SetGrupoOpcional( "infoPerApur" )
   ::SetCampo( "tpInsc", cTpInsc )
   ::SetCampo( "nrInsc", OnlyDigits( cNrInsc ) )
   IF ! Empty( hb_DefaultValue( cMatricula, "" ) )
      ::SetCampo( "matricula", cMatricula )
   ENDIF
RETURN Self

METHOD SetItemRemuneracao( cCodRubr, cIdeTabRubr, cVrRubr, cIndApurIR, cQtdRubr, cFatorRubr ) CLASS TEsocialEventoRmnRPPS
   ::SetCampo( "codRubr", cCodRubr )
   ::SetCampo( "ideTabRubr", cIdeTabRubr )
   IF ! Empty( hb_DefaultValue( cQtdRubr, "" ) )
      ::SetCampo( "qtdRubr", cQtdRubr )
   ENDIF
   IF ! Empty( hb_DefaultValue( cFatorRubr, "" ) )
      ::SetCampo( "fatorRubr", cFatorRubr )
   ENDIF
   ::SetCampo( "vrRubr", cVrRubr )
   IF ! Empty( hb_DefaultValue( cIndApurIR, "" ) )
      ::SetCampo( "indApurIR", cIndApurIR )
   ENDIF
RETURN Self

CLASS TEsocialEventoTabEstab FROM TEsocialEventoXml
   METHOD New()
   METHOD SetIdeEstab()
   METHOD SetDadosEstab()
   METHOD SetAliqGilrat()
ENDCLASS
METHOD New() CLASS TEsocialEventoTabEstab
   ::Super:New( "evtTabEstab", "evtTabEstab" )
RETURN Self

METHOD SetIdeEstab( cTpInsc, cNrInsc, cIniValid, cFimValid ) CLASS TEsocialEventoTabEstab
   ::SetCampo( "tpInsc", cTpInsc )
   ::SetCampo( "nrInsc", OnlyDigits( cNrInsc ) )
   ::SetOperacao( EsocialValorCampoTemplate( ::aCampos, "operacao" ), cIniValid, cFimValid )
RETURN Self

METHOD SetDadosEstab( cCnaePrep, cCnpjResp, cTpCaepf, cIndSubstPatrObra ) CLASS TEsocialEventoTabEstab
   ::SetCampo( "cnaePrep", OnlyDigits( cCnaePrep ) )
   IF ! Empty( hb_DefaultValue( cCnpjResp, "" ) )
      ::SetCampo( "cnpjResp", OnlyDigits( cCnpjResp ) )
   ENDIF
   IF ! Empty( hb_DefaultValue( cTpCaepf, "" ) )
      ::SetCampo( "tpCaepf", cTpCaepf )
   ENDIF
   IF ! Empty( hb_DefaultValue( cIndSubstPatrObra, "" ) )
      ::SetCampo( "indSubstPatrObra", cIndSubstPatrObra )
   ENDIF
RETURN Self

METHOD SetAliqGilrat( cAliqRat, cFap ) CLASS TEsocialEventoTabEstab
   IF ! Empty( hb_DefaultValue( cAliqRat, "" ) )
      ::SetCampo( "aliqRat", cAliqRat )
   ENDIF
   IF ! Empty( hb_DefaultValue( cFap, "" ) )
      ::SetCampo( "fap", cFap )
   ENDIF
RETURN Self

CLASS TEsocialEventoTabLotacao FROM TEsocialEventoXml
   METHOD New()
   METHOD SetIdeLotacao()
   METHOD SetDadosLotacao()
   METHOD SetFpasLotacao()
ENDCLASS
METHOD New() CLASS TEsocialEventoTabLotacao
   ::Super:New( "evtTabLotacao", "evtTabLotacao" )
RETURN Self

METHOD SetIdeLotacao( cCodLotacao, cIniValid, cFimValid ) CLASS TEsocialEventoTabLotacao
   ::SetCampo( "codLotacao", cCodLotacao )
   ::SetOperacao( EsocialValorCampoTemplate( ::aCampos, "operacao" ), cIniValid, cFimValid )
RETURN Self

METHOD SetDadosLotacao( cTpLotacao, cTpInsc, cNrInsc ) CLASS TEsocialEventoTabLotacao
   ::SetCampo( "tpLotacao", cTpLotacao )
   IF ! Empty( hb_DefaultValue( cTpInsc, "" ) )
      ::SetCampo( "tpInsc", cTpInsc )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNrInsc, "" ) )
      ::SetCampo( "nrInsc", OnlyDigits( cNrInsc ) )
   ENDIF
RETURN Self

METHOD SetFpasLotacao( cFpas, cCodTercs, cCodTercsSusp ) CLASS TEsocialEventoTabLotacao
   ::SetCampo( "fpas", OnlyDigits( cFpas ) )
   ::SetCampo( "codTercs", OnlyDigits( cCodTercs ) )
   IF ! Empty( hb_DefaultValue( cCodTercsSusp, "" ) )
      ::SetCampo( "codTercsSusp", OnlyDigits( cCodTercsSusp ) )
   ENDIF
RETURN Self

CLASS TEsocialEventoTabProcesso FROM TEsocialEventoXml
   METHOD New()
   METHOD SetIdeProcesso()
   METHOD SetDadosProc()
   METHOD SetDadosProcJud()
   METHOD SetInfoSusp()
ENDCLASS
METHOD New() CLASS TEsocialEventoTabProcesso
   ::Super:New( "evtTabProcesso", "evtTabProcesso" )
RETURN Self

METHOD SetIdeProcesso( cTpProc, cNrProc, cIniValid, cFimValid ) CLASS TEsocialEventoTabProcesso
   ::SetCampo( "tpProc", cTpProc )
   ::SetCampo( "nrProc", cNrProc )
   ::SetOperacao( EsocialValorCampoTemplate( ::aCampos, "operacao" ), cIniValid, cFimValid )
RETURN Self

METHOD SetDadosProc( cIndMatProc, cIndAutoria, cObservacao ) CLASS TEsocialEventoTabProcesso
   ::SetCampo( "indMatProc", cIndMatProc )
   IF ! Empty( hb_DefaultValue( cIndAutoria, "" ) )
      ::SetCampo( "indAutoria", cIndAutoria )
   ENDIF
   IF ! Empty( hb_DefaultValue( cObservacao, "" ) )
      ::SetCampo( "observacao", cObservacao )
   ENDIF
RETURN Self

METHOD SetDadosProcJud( cUfVara, cCodMunic, cIdVara ) CLASS TEsocialEventoTabProcesso
   ::SetCampo( "ufVara", Upper( AllTrim( hb_DefaultValue( cUfVara, "" ) ) ) )
   ::SetCampo( "codMunic", OnlyDigits( cCodMunic ) )
   ::SetCampo( "idVara", cIdVara )
RETURN Self

METHOD SetInfoSusp( cCodSusp, cIndSusp, cDtDecisao, cIndDeposito ) CLASS TEsocialEventoTabProcesso
   ::SetCampo( "codSusp", cCodSusp )
   ::SetCampo( "indSusp", cIndSusp )
   ::SetCampo( "dtDecisao", cDtDecisao )
   ::SetCampo( "indDeposito", cIndDeposito )
RETURN Self

CLASS TEsocialEventoTabRubrica FROM TEsocialEventoXml
   METHOD New()
   METHOD SetIdeRubrica()
   METHOD SetDadosRubrica()
ENDCLASS
METHOD New() CLASS TEsocialEventoTabRubrica
   ::Super:New( "evtTabRubrica", "evtTabRubrica" )
RETURN Self

METHOD SetIdeRubrica( cCodRubr, cIdeTabRubr, cIniValid, cFimValid ) CLASS TEsocialEventoTabRubrica
   ::SetCampo( "codRubr", cCodRubr )
   ::SetCampo( "ideTabRubr", cIdeTabRubr )
   ::SetOperacao( EsocialValorCampoTemplate( ::aCampos, "operacao" ), cIniValid, cFimValid )
RETURN Self

METHOD SetDadosRubrica( cDscRubr, cNatRubr, cTpRubr, cCodIncCP, cCodIncIRRF, cCodIncFGTS, cCodIncCPRP, cCodIncPisPasep, cTetoRemun, cObservacao ) CLASS TEsocialEventoTabRubrica
   ::SetCampo( "dscRubr", cDscRubr )
   ::SetCampo( "natRubr", cNatRubr )
   ::SetCampo( "tpRubr", cTpRubr )
   ::SetCampo( "codIncCP", cCodIncCP )
   ::SetCampo( "codIncIRRF", cCodIncIRRF )
   ::SetCampo( "codIncFGTS", cCodIncFGTS )
   IF ! Empty( hb_DefaultValue( cCodIncCPRP, "" ) )
      ::SetCampo( "codIncCPRP", cCodIncCPRP )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCodIncPisPasep, "" ) )
      ::SetCampo( "codIncPisPasep", cCodIncPisPasep )
   ENDIF
   IF ! Empty( hb_DefaultValue( cTetoRemun, "" ) )
      ::SetCampo( "tetoRemun", cTetoRemun )
   ENDIF
   IF ! Empty( hb_DefaultValue( cObservacao, "" ) )
      ::SetCampo( "observacao", cObservacao )
   ENDIF
RETURN Self

CLASS TEsocialEventoTribProcTrab FROM TEsocialEventoXml
   METHOD New()
ENDCLASS
METHOD New() CLASS TEsocialEventoTribProcTrab
   ::Super:New( "evtTribProcTrab", "evtTribProcTrab" )
RETURN Self

CLASS TEsocialEventoTSVAltContr FROM TEsocialEventoXml
   METHOD New()
   METHOD SetTrabalhadorSemVinculo()
   METHOD SetAlteracao()
   METHOD SetCargoFuncao()
   METHOD SetRemuneracao()
ENDCLASS
METHOD New() CLASS TEsocialEventoTSVAltContr
   ::Super:New( "evtTSVAltContr", "evtTSVAltContr" )
RETURN Self

METHOD SetTrabalhadorSemVinculo( cCpfTrab, cMatricula, cCodCateg ) CLASS TEsocialEventoTSVAltContr
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   IF ! Empty( hb_DefaultValue( cMatricula, "" ) )
      ::SetCampo( "matricula", cMatricula )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCodCateg, "" ) )
      ::SetCampo( "codCateg", OnlyDigits( cCodCateg ) )
   ENDIF
RETURN Self

METHOD SetAlteracao( cDtAlteracao, cNatAtividade ) CLASS TEsocialEventoTSVAltContr
   ::SetCampo( "dtAlteracao", cDtAlteracao )
   IF ! Empty( hb_DefaultValue( cNatAtividade, "" ) )
      ::SetCampo( "natAtividade", cNatAtividade )
   ENDIF
RETURN Self

METHOD SetCargoFuncao( cNmCargo, cCBOCargo, cNmFuncao, cCBOFuncao ) CLASS TEsocialEventoTSVAltContr
   ::SetGrupoOpcional( "infoComplementares" )
   ::SetGrupoOpcional( "cargoFuncao" )
   IF ! Empty( hb_DefaultValue( cNmCargo, "" ) )
      ::SetCampo( "nmCargo", cNmCargo )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCBOCargo, "" ) )
      ::SetCampo( "CBOCargo", OnlyDigits( cCBOCargo ) )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNmFuncao, "" ) )
      ::SetCampo( "nmFuncao", cNmFuncao )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCBOFuncao, "" ) )
      ::SetCampo( "CBOFuncao", OnlyDigits( cCBOFuncao ) )
   ENDIF
RETURN Self

METHOD SetRemuneracao( cVrSalFx, cUndSalFixo, cDscSalVar ) CLASS TEsocialEventoTSVAltContr
   ::SetGrupoOpcional( "infoComplementares" )
   ::SetGrupoOpcional( "remuneracao" )
   ::SetCampo( "vrSalFx", cVrSalFx )
   ::SetCampo( "undSalFixo", cUndSalFixo )
   IF ! Empty( hb_DefaultValue( cDscSalVar, "" ) )
      ::SetCampo( "dscSalVar", cDscSalVar )
   ENDIF
RETURN Self

CLASS TEsocialEventoTSVInicio FROM TEsocialEventoXml
   METHOD New()
   METHOD SetDadosTrabalhador()
   METHOD SetNascimento()
   METHOD SetEnderecoBrasil()
   METHOD SetEnderecoExterior()
   METHOD SetInicioTSV()
   METHOD SetCargoFuncao()
   METHOD SetRemuneracao()
ENDCLASS
METHOD New() CLASS TEsocialEventoTSVInicio
   ::Super:New( "evtTSVInicio", "evtTSVInicio" )
RETURN Self

METHOD SetDadosTrabalhador( cCpfTrab, cNmTrab, cSexo, cRacaCor, cGrauInstr, cEstCiv, cNmSoc ) CLASS TEsocialEventoTSVInicio
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   ::SetCampo( "nmTrab", cNmTrab )
   ::SetCampo( "sexo", cSexo )
   ::SetCampo( "racaCor", cRacaCor )
   ::SetCampo( "grauInstr", cGrauInstr )
   IF ! Empty( hb_DefaultValue( cEstCiv, "" ) )
      ::SetCampo( "estCiv", cEstCiv )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNmSoc, "" ) )
      ::SetCampo( "nmSoc", cNmSoc )
   ENDIF
RETURN Self

METHOD SetNascimento( cDtNascto, cPaisNascto, cPaisNac ) CLASS TEsocialEventoTSVInicio
   ::SetCampo( "dtNascto", cDtNascto )
   ::SetCampo( "paisNascto", cPaisNascto )
   ::SetCampo( "paisNac", cPaisNac )
RETURN Self

METHOD SetEnderecoBrasil( cDscLograd, cNrLograd, cCep, cCodMunic, cUf, cTpLograd, cComplemento, cBairro ) CLASS TEsocialEventoTSVInicio
   ::SetEscolha( "brasil" )
   IF ! Empty( hb_DefaultValue( cTpLograd, "" ) )
      ::SetCampo( "tpLograd", cTpLograd )
   ENDIF
   ::SetCampo( "dscLograd", cDscLograd )
   ::SetCampo( "nrLograd", cNrLograd )
   IF ! Empty( hb_DefaultValue( cComplemento, "" ) )
      ::SetCampo( "complemento", cComplemento )
   ENDIF
   IF ! Empty( hb_DefaultValue( cBairro, "" ) )
      ::SetCampo( "bairro", cBairro )
   ENDIF
   ::SetCampo( "cep", OnlyDigits( cCep ) )
   ::SetCampo( "codMunic", OnlyDigits( cCodMunic ) )
   ::SetCampo( "uf", Upper( AllTrim( hb_DefaultValue( cUf, "" ) ) ) )
RETURN Self

METHOD SetEnderecoExterior( cPaisResid, cDscLograd, cNrLograd, cNmCid, cCodPostal, cComplemento, cBairro ) CLASS TEsocialEventoTSVInicio
   ::SetEscolha( "exterior" )
   ::SetCampo( "paisResid", cPaisResid )
   ::SetCampo( "dscLograd", cDscLograd )
   ::SetCampo( "nrLograd", cNrLograd )
   ::SetCampo( "nmCid", cNmCid )
   IF ! Empty( hb_DefaultValue( cCodPostal, "" ) )
      ::SetCampo( "codPostal", cCodPostal )
   ENDIF
   IF ! Empty( hb_DefaultValue( cComplemento, "" ) )
      ::SetCampo( "complemento", cComplemento )
   ENDIF
   IF ! Empty( hb_DefaultValue( cBairro, "" ) )
      ::SetCampo( "bairro", cBairro )
   ENDIF
RETURN Self

METHOD SetInicioTSV( cCadIni, cCodCateg, cDtInicio, cMatricula, cNrProcTrab, cNatAtividade ) CLASS TEsocialEventoTSVInicio
   ::SetCampo( "cadIni", cCadIni )
   IF ! Empty( hb_DefaultValue( cMatricula, "" ) )
      ::SetCampo( "matricula", cMatricula )
   ENDIF
   ::SetCampo( "codCateg", OnlyDigits( cCodCateg ) )
   ::SetCampo( "dtInicio", cDtInicio )
   IF ! Empty( hb_DefaultValue( cNrProcTrab, "" ) )
      ::SetCampo( "nrProcTrab", cNrProcTrab )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNatAtividade, "" ) )
      ::SetCampo( "natAtividade", cNatAtividade )
   ENDIF
RETURN Self

METHOD SetCargoFuncao( cNmCargo, cCBOCargo, cNmFuncao, cCBOFuncao ) CLASS TEsocialEventoTSVInicio
   ::SetGrupoOpcional( "infoComplementares" )
   ::SetGrupoOpcional( "cargoFuncao" )
   IF ! Empty( hb_DefaultValue( cNmCargo, "" ) )
      ::SetCampo( "nmCargo", cNmCargo )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCBOCargo, "" ) )
      ::SetCampo( "CBOCargo", OnlyDigits( cCBOCargo ) )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNmFuncao, "" ) )
      ::SetCampo( "nmFuncao", cNmFuncao )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCBOFuncao, "" ) )
      ::SetCampo( "CBOFuncao", OnlyDigits( cCBOFuncao ) )
   ENDIF
RETURN Self

METHOD SetRemuneracao( cVrSalFx, cUndSalFixo, cDscSalVar ) CLASS TEsocialEventoTSVInicio
   ::SetGrupoOpcional( "infoComplementares" )
   ::SetGrupoOpcional( "remuneracao" )
   ::SetCampo( "vrSalFx", cVrSalFx )
   ::SetCampo( "undSalFixo", cUndSalFixo )
   IF ! Empty( hb_DefaultValue( cDscSalVar, "" ) )
      ::SetCampo( "dscSalVar", cDscSalVar )
   ENDIF
RETURN Self

CLASS TEsocialEventoTSVTermino FROM TEsocialEventoXml
   METHOD New()
   METHOD SetTrabalhadorSemVinculo()
   METHOD SetTermino()
   METHOD SetPensaoAlimenticia()
   METHOD SetIndGuia()
ENDCLASS
METHOD New() CLASS TEsocialEventoTSVTermino
   ::Super:New( "evtTSVTermino", "evtTSVTermino" )
RETURN Self

METHOD SetTrabalhadorSemVinculo( cCpfTrab, cMatricula, cCodCateg ) CLASS TEsocialEventoTSVTermino
   ::SetCampo( "cpfTrab", OnlyDigits( cCpfTrab ) )
   IF ! Empty( hb_DefaultValue( cMatricula, "" ) )
      ::SetCampo( "matricula", cMatricula )
   ENDIF
   IF ! Empty( hb_DefaultValue( cCodCateg, "" ) )
      ::SetCampo( "codCateg", OnlyDigits( cCodCateg ) )
   ENDIF
RETURN Self

METHOD SetTermino( cDtTerm, cMtvDesligTSV, cNrProcTrab ) CLASS TEsocialEventoTSVTermino
   ::SetCampo( "dtTerm", cDtTerm )
   IF ! Empty( hb_DefaultValue( cMtvDesligTSV, "" ) )
      ::SetCampo( "mtvDesligTSV", cMtvDesligTSV )
   ENDIF
   IF ! Empty( hb_DefaultValue( cNrProcTrab, "" ) )
      ::SetCampo( "nrProcTrab", cNrProcTrab )
   ENDIF
RETURN Self

METHOD SetPensaoAlimenticia( cPensAlim, cPercAliment, cVrAlim ) CLASS TEsocialEventoTSVTermino
   IF ! Empty( hb_DefaultValue( cPensAlim, "" ) )
      ::SetCampo( "pensAlim", cPensAlim )
   ENDIF
   IF ! Empty( hb_DefaultValue( cPercAliment, "" ) )
      ::SetCampo( "percAliment", cPercAliment )
   ENDIF
   IF ! Empty( hb_DefaultValue( cVrAlim, "" ) )
      ::SetCampo( "vrAlim", cVrAlim )
   ENDIF
RETURN Self

METHOD SetIndGuia( cIndGuia ) CLASS TEsocialEventoTSVTermino
RETURN ::SetCampo( "indGuia", cIndGuia )

CLASS TEsocialEventoS1000 FROM TEsocialEventoInfoEmpregador
ENDCLASS

CLASS TEsocialEventoS1005 FROM TEsocialEventoTabEstab
ENDCLASS

CLASS TEsocialEventoS1010 FROM TEsocialEventoTabRubrica
ENDCLASS

CLASS TEsocialEventoS1020 FROM TEsocialEventoTabLotacao
ENDCLASS

CLASS TEsocialEventoS1070 FROM TEsocialEventoTabProcesso
ENDCLASS

CLASS TEsocialEventoS1200 FROM TEsocialEventoRemun
ENDCLASS

CLASS TEsocialEventoS1202 FROM TEsocialEventoRmnRPPS
ENDCLASS

CLASS TEsocialEventoS1207 FROM TEsocialEventoBenPrRP
ENDCLASS

CLASS TEsocialEventoS1210 FROM TEsocialEventoPgtos
ENDCLASS

CLASS TEsocialEventoS1260 FROM TEsocialEventoComProd
ENDCLASS

CLASS TEsocialEventoS1270 FROM TEsocialEventoContratAvNP
ENDCLASS

CLASS TEsocialEventoS1280 FROM TEsocialEventoInfoComplPer
ENDCLASS

CLASS TEsocialEventoS1298 FROM TEsocialEventoReabreEvPer
ENDCLASS

CLASS TEsocialEventoS1299 FROM TEsocialEventoFechaEvPer
ENDCLASS

CLASS TEsocialEventoS2190 FROM TEsocialEventoAdmPrelim
ENDCLASS

CLASS TEsocialEventoS2200 FROM TEsocialEventoAdmissao
ENDCLASS

CLASS TEsocialEventoS2205 FROM TEsocialEventoAltCadastral
ENDCLASS

CLASS TEsocialEventoS2206 FROM TEsocialEventoAltContratual
ENDCLASS

CLASS TEsocialEventoS2230 FROM TEsocialEventoAfastTemp
ENDCLASS

CLASS TEsocialEventoS2231 FROM TEsocialEventoCessao
ENDCLASS

CLASS TEsocialEventoS2298 FROM TEsocialEventoReintegr
ENDCLASS

CLASS TEsocialEventoS2299 FROM TEsocialEventoDeslig
ENDCLASS

CLASS TEsocialEventoS2300 FROM TEsocialEventoTSVInicio
ENDCLASS

CLASS TEsocialEventoS2306 FROM TEsocialEventoTSVAltContr
ENDCLASS

CLASS TEsocialEventoS2399 FROM TEsocialEventoTSVTermino
ENDCLASS

CLASS TEsocialEventoS2400 FROM TEsocialEventoCdBenefIn
ENDCLASS

CLASS TEsocialEventoS2405 FROM TEsocialEventoCdBenefAlt
ENDCLASS

CLASS TEsocialEventoS2410 FROM TEsocialEventoCdBenIn
ENDCLASS

CLASS TEsocialEventoS2416 FROM TEsocialEventoCdBenAlt
ENDCLASS

CLASS TEsocialEventoS2418 FROM TEsocialEventoReativBen
ENDCLASS

CLASS TEsocialEventoS2420 FROM TEsocialEventoCdBenTerm
ENDCLASS

CLASS TEsocialEventoS2500 FROM TEsocialEventoProcTrab
ENDCLASS

CLASS TEsocialEventoS2501 FROM TEsocialEventoContProc
ENDCLASS

CLASS TEsocialEventoS2555 FROM TEsocialEventoConsolidContProc
ENDCLASS

CLASS TEsocialEventoS3500 FROM TEsocialEventoExcProcTrab
ENDCLASS

CLASS TEsocialEventoS5001 FROM TEsocialEventoBasesTrab
ENDCLASS

CLASS TEsocialEventoS5002 FROM TEsocialEventoIrrfBenef
ENDCLASS

CLASS TEsocialEventoS5003 FROM TEsocialEventoBasesFGTS
ENDCLASS

CLASS TEsocialEventoS5011 FROM TEsocialEventoCS
ENDCLASS

CLASS TEsocialEventoS5012 FROM TEsocialEventoIrrf
ENDCLASS

CLASS TEsocialEventoS5013 FROM TEsocialEventoFGTS
ENDCLASS

CLASS TEsocialEventoS5501 FROM TEsocialEventoTribProcTrab
ENDCLASS

CLASS TEsocialEventoS5503 FROM TEsocialEventoFGTSProcTrab
ENDCLASS

CLASS TEsocialEventoS8200 FROM TEsocialEventoAnotJud
ENDCLASS

CLASS TEsocialEventoS8299 FROM TEsocialEventoBaixa
ENDCLASS

CLASS TEsocialSigner
   VAR oConfig     AS OBJECT
   VAR cThumbprint AS Character INIT ""
   VAR cSubject    AS Character INIT ""

   METHOD New()             // oConfig 
   METHOD SetThumbprint()   // cThumbprint 
   METHOD SetSubject()      // cSubject 
   METHOD AssinarArquivo()  // cEntrada, cSaida
   METHOD AssinarXml()      // cXml 
ENDCLASS

METHOD New( oConfig ) CLASS TEsocialSigner
   IF oConfig == Nil
      oConfig := TEsocialConfig():New()
   ENDIF
   ::oConfig := oConfig
   ::cThumbprint := ""
   ::cSubject := ""
RETURN Self

METHOD SetThumbprint( cThumbprint ) CLASS TEsocialSigner
   ::cThumbprint := AllTrim( cThumbprint )
RETURN Self

METHOD SetSubject( cSubject ) CLASS TEsocialSigner
   ::cSubject := AllTrim( cSubject )
RETURN Self

METHOD AssinarArquivo( cEntrada, cSaida ) CLASS TEsocialSigner
   LOCAL cXml, cAssinado

   IF Empty( cEntrada ) .OR. ! File( cEntrada )
      RETURN .F.
   ENDIF

   IF Empty( cSaida )
      cSaida := "Assinado.xml-esocial-loteevt.xml"
   ENDIF

   cXml := hb_MemoRead( cEntrada )
   cAssinado := ::AssinarXml( cXml )
   IF Empty( cAssinado )
      RETURN .F.
   ENDIF

   hb_MemoWrit( cSaida, cAssinado )
RETURN File( cSaida )

METHOD AssinarXml( cXml ) CLASS TEsocialSigner
   LOCAL cOut := cXml
   LOCAL nESocialStart, nESocialEnd, cEventRoot, cEventName, cId
   LOCAL cDigest, cSignedInfo, cSigBin, cSig64, cCertDer, cCert64, cSignature

   nESocialStart := hb_At( '<eSocial xmlns="http://www.esocial.gov.br/schema/evt/', cOut )
   DO WHILE nESocialStart > 0
      nESocialEnd := hb_At( "</eSocial>", cOut, nESocialStart )
      IF nESocialEnd == 0
         RETURN ""
      ENDIF
      nESocialEnd += Len( "</eSocial>" ) - 1

      cEventRoot := SubStr( cOut, nESocialStart, nESocialEnd - nESocialStart + 1 )
      cEventRoot := EsocialRemoveSignature( cEventRoot )
      cEventName := EsocialFirstEventName( cEventRoot )
      cId := EsocialEventId( cEventRoot, cEventName )
      IF Empty( cEventName ) .OR. Empty( cId )
         RETURN ""
      ENDIF

      cDigest := hb_Base64Encode( EsocialHexToBin( hb_SHA256( cEventRoot ) ) )

      cSignedInfo := EsocialSignedInfoCanon( "", cDigest )
      cSigBin := EsocialSignSha256Hash( EsocialHexToBin( hb_SHA256( cSignedInfo ) ), ::cSubject, ::cThumbprint )
      IF Empty( cSigBin )
         RETURN ""
      ENDIF

      cCertDer := EsocialCertDer( ::cSubject, ::cThumbprint )
      IF Empty( cCertDer )
         RETURN ""
      ENDIF

      cSig64 := EsocialOneLineBase64( hb_Base64Encode( cSigBin ) )
      cCert64 := EsocialOneLineBase64( hb_Base64Encode( cCertDer ) )
      cSignature := EsocialSignatureNode( "", cDigest, cSig64, cCert64 )

      cEventRoot := StrTran( cEventRoot, "</eSocial>", cSignature + "</eSocial>" )
      IF ::oConfig:lValidarXsd .AND. ! EsocialValidarEventoXsd( cEventRoot, ::oConfig:cXsdPath )
         RETURN ""
      ENDIF
      cOut := Left( cOut, nESocialStart - 1 ) + cEventRoot + SubStr( cOut, nESocialEnd + 1 )
      nESocialStart := hb_At( '<eSocial xmlns="http://www.esocial.gov.br/schema/evt/', cOut, nESocialStart + Len( cEventRoot ) )
   ENDDO
RETURN cOut

CLASS TEsocialClient
   VAR oConfig AS OBJECT

   METHOD New()                // oConfig
   METHOD EnviarLoteAssinado() // cArquivoXml
   METHOD ConsultarLote()      // cProtocolo
   METHOD ConsultarLoteDetalhado() // cProtocolo
   METHOD SoapEnvio()          // cXmlAssinado
   METHOD SoapConsulta()       // cProtocolo
ENDCLASS

CLASS TEsocialRetornoOcorrencia
   VAR cXml         INIT ""
   VAR nTipo        INIT 0
   VAR cCodigo      INIT ""
   VAR cDescricao   INIT ""
   VAR cLocalizacao INIT ""

   METHOD New() // cXml
ENDCLASS

CLASS TEsocialRetornoEvento
   VAR cId           INIT ""
   VAR nCdResposta   INIT 0
   VAR cDescResposta INIT ""
   VAR aOcorrencias  INIT {}
   VAR cXml          INIT ""

   METHOD New() // cXml
   METHOD Ok()
   METHOD GetOcorrenciaCount()
   METHOD GetOcorrencia() // nIndex zero-based igual Unimake
ENDCLASS

CLASS TEsocialRetornoLote
   VAR nCdResposta   INIT 0
   VAR cDescResposta INIT ""
   VAR cProtocolo    INIT ""
   VAR aEventos      INIT {}
   VAR aOcorrencias  INIT {}
   VAR cXml          INIT ""

   METHOD New() // cXml
   METHOD LoteOk()
   METHOD TodosEventosOk()
   METHOD GetEventoCount()
   METHOD GetEvento() // nIndex zero-based igual Unimake
   METHOD GetOcorrenciaCount()
   METHOD GetOcorrencia() // ocorrencias do status do lote, zero-based
   METHOD ToTexto()
ENDCLASS

CLASS TEsocialLote
   VAR cCnpj              AS Character INIT ""
   VAR cTpInscEmpregador  AS Character INIT "1"
   VAR cNrInscEmpregador  AS Character INIT ""
   VAR cTpInscTransmissor AS Character INIT "1"
   VAR cNrInscTransmissor AS Character INIT ""
   VAR cGrupo             AS Character INIT "2"

   METHOD New()            // cCnpj, cGrupo 
   METHOD SetEmpregador()  // cTpInsc, cNrInsc 
   METHOD SetTransmissor() // cTpInsc, cNrInsc 
   METHOD MontarXml()      // aEventosAssinados 
   METHOD Salvar()         // aEventosAssinados, cArquivo 
ENDCLASS

METHOD New( cCnpj, cGrupo ) CLASS TEsocialLote
   ::cCnpj := SoNumeroCnpj( hb_DefaultValue( cCnpj, "" ) )
   ::cNrInscEmpregador := ::cCnpj
   ::cNrInscTransmissor := ::cCnpj
   IF ! Empty( cGrupo )
      ::cGrupo := AllTrim( cGrupo )
   ENDIF
RETURN Self

METHOD SetEmpregador( cTpInsc, cNrInsc ) CLASS TEsocialLote
   ::cTpInscEmpregador := AllTrim( cTpInsc )
   ::cNrInscEmpregador := SoNumeroCnpj( cNrInsc )
RETURN Self

METHOD SetTransmissor( cTpInsc, cNrInsc ) CLASS TEsocialLote
   ::cTpInscTransmissor := AllTrim( cTpInsc )
   ::cNrInscTransmissor := SoNumeroCnpj( cNrInsc )
RETURN Self

METHOD MontarXml( aEventosAssinados ) CLASS TEsocialLote
   LOCAL cXml, cEvento, cId, nI

   cXml := '<?xml version="1.0" encoding="UTF-8"?>'
   cXml += '<eSocial xmlns="http://www.esocial.gov.br/schema/lote/eventos/envio/v1_1_1">'
   cXml += '<envioLoteEventos grupo="' + ::cGrupo + '">'
   cXml += '<ideEmpregador><tpInsc>' + ::cTpInscEmpregador + '</tpInsc><nrInsc>' + EsocialNrInscEmpregador( ::cTpInscEmpregador, ::cNrInscEmpregador ) + '</nrInsc></ideEmpregador>'
   cXml += '<ideTransmissor><tpInsc>' + ::cTpInscTransmissor + '</tpInsc><nrInsc>' + SoNumeroCnpj( ::cNrInscTransmissor ) + '</nrInsc></ideTransmissor>'
   cXml += '<eventos>'

   FOR nI := 1 TO Len( aEventosAssinados )
      cEvento := EsocialRemoveXmlDecl( AllTrim( aEventosAssinados[ nI ] ) )
      cId := EsocialEventId( cEvento, EsocialFirstEventName( cEvento ) )
      IF Empty( cId )
         cId := "IDLOTE" + StrZero( nI, 6 )
      ENDIF
      cXml += '<evento Id="' + cId + '">' + cEvento + '</evento>'
   NEXT

   cXml += '</eventos></envioLoteEventos></eSocial>'
RETURN cXml

METHOD Salvar( aEventosAssinados, cArquivo ) CLASS TEsocialLote
   IF Empty( cArquivo )
      cArquivo := "Assinado.xml-esocial-loteevt.xml"
   ENDIF
   hb_MemoWrit( cArquivo, ::MontarXml( aEventosAssinados ) )
RETURN File( cArquivo )

METHOD New( oConfig ) CLASS TEsocialClient
   IF oConfig == Nil
      oConfig := TEsocialConfig():New()
   ENDIF
   ::oConfig := oConfig
RETURN Self

METHOD EnviarLoteAssinado( cArquivoXml ) CLASS TEsocialClient
   LOCAL cXmlAssinado, cEnvelope, cRetorno, oHttp

   IF Empty( cArquivoXml )
      cArquivoXml := "Assinado.xml-esocial-loteevt.xml"
   ENDIF

   IF ! File( cArquivoXml )
      RETURN ""
   ENDIF

   cXmlAssinado := hb_MemoRead( cArquivoXml )
   cXmlAssinado := StrTran( cXmlAssinado, '<?xml version="1.0" encoding="UTF-8"?>', "" )
   cXmlAssinado := StrTran( cXmlAssinado, '<?xml version="1.0" encoding="utf-8"?>', "" )
   cXmlAssinado := AllTrim( cXmlAssinado )
   IF ::oConfig:lValidarXsd .AND. ! EsocialValidarEventosDoLoteXsd( cXmlAssinado, ::oConfig:cXsdPath )
      hb_MemoWrit( "Erro_Resposta.xml", EsocialValidacaoLastError() + hb_Eol() )
      RETURN ""
   ENDIF
   cEnvelope := ::SoapEnvio( cXmlAssinado )
   hb_MemoWrit( "Debug_Envelope_Final.xml", cEnvelope )

   BEGIN SEQUENCE WITH {|oErr| Break(oErr)}
      oHttp := Win_OleCreateObject( "MSXML2.ServerXMLHTTP.6.0" )
      IF ! Empty( ::oConfig:cCertName )
         oHttp:setOption( 3, "CURRENT_USER\My\" + ::oConfig:cCertName )
      ENDIF
      IF ::oConfig:lIgnoraErroSsl
         oHttp:setOption( 2, 13056 )
      ENDIF
      oHttp:open( "POST", ::oConfig:cEnvioUrl, .F. )
      oHttp:SetRequestHeader( "SOAPAction", ESOCIAL_SOAP_ENVIO )
      oHttp:SetRequestHeader( "Content-Type", "text/xml; charset=utf-8" )
      oHttp:send( cEnvelope )
      cRetorno := oHttp:responseText
   RECOVER
      cRetorno := ""
   END SEQUENCE

   EsocialMemoWritUtf8( "Erro_Resposta.xml", cRetorno )
RETURN cRetorno

METHOD ConsultarLote( cProtocolo ) CLASS TEsocialClient
   LOCAL cEnvelope, cRetorno, oHttp

   IF Empty( cProtocolo )
      RETURN ""
   ENDIF

   cEnvelope := ::SoapConsulta( cProtocolo )

   BEGIN SEQUENCE WITH {|oErr| Break(oErr)}
      oHttp := Win_OleCreateObject( "MSXML2.ServerXMLHTTP.6.0" )
      IF ! Empty( ::oConfig:cCertName )
         oHttp:setOption( 3, "CURRENT_USER\My\" + ::oConfig:cCertName )
      ENDIF
      IF ::oConfig:lIgnoraErroSsl
         oHttp:setOption( 2, 13056 )
      ENDIF
      oHttp:open( "POST", ::oConfig:cConsultaUrl, .F. )
      oHttp:SetRequestHeader( "SOAPAction", ESOCIAL_SOAP_CONSULTA )
      oHttp:SetRequestHeader( "Content-Type", "text/xml; charset=utf-8" )
      oHttp:send( cEnvelope )
      cRetorno := oHttp:responseText
   RECOVER
      cRetorno := ""
   END SEQUENCE
   EsocialMemoWritUtf8( "Retorno_eSocial.xml", cRetorno )
RETURN cRetorno

METHOD ConsultarLoteDetalhado( cProtocolo ) CLASS TEsocialClient
   LOCAL cRetorno
   cRetorno := ::ConsultarLote( cProtocolo )
RETURN TEsocialRetornoLote():New( cRetorno )

METHOD SoapEnvio( cXmlAssinado ) CLASS TEsocialClient
   LOCAL cEnvelope
   cEnvelope := '<?xml version="1.0" encoding="UTF-8"?>'
   cEnvelope += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v1="http://www.esocial.gov.br/servicos/empregador/lote/eventos/envio/v1_1_0">'
   cEnvelope += '<soapenv:Header/><soapenv:Body>'
   cEnvelope += '<v1:enviarLoteEventos><v1:loteEventos>'
   cEnvelope += cXmlAssinado
   cEnvelope += '</v1:loteEventos></v1:enviarLoteEventos>'
   cEnvelope += '</soapenv:Body></soapenv:Envelope>'
RETURN cEnvelope

METHOD SoapConsulta( cProtocolo ) CLASS TEsocialClient
   LOCAL cDocumento, cEnvelope
   cDocumento := '<eSocial xmlns="http://www.esocial.gov.br/schema/lote/eventos/envio/consulta/retornoProcessamento/v1_0_0">' + ;
                 '<consultaLoteEventos><protocoloEnvio>' + AllTrim( cProtocolo ) + '</protocoloEnvio></consultaLoteEventos>' + ;
                 '</eSocial>'

   cEnvelope := '<?xml version="1.0" encoding="UTF-8"?>'
   cEnvelope += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v1="http://www.esocial.gov.br/servicos/empregador/lote/eventos/envio/consulta/retornoProcessamento/v1_1_0">'
   cEnvelope += '<soapenv:Header/><soapenv:Body>'
   cEnvelope += '<v1:consultarLoteEventos><v1:consulta>' + cDocumento + '</v1:consulta></v1:consultarLoteEventos>'
   cEnvelope += '</soapenv:Body></soapenv:Envelope>'
RETURN cEnvelope

CLASS TEsocialCertificado
   // Configurações iniciais básicas
   VAR cCertificado AS Character INIT [NENHUM]                                 // Nome do certificado (Somente o Nome)
   VAR cCertNomecer AS Character INIT []                                       // Nome do certificado retornado (Nome completo CN=Nome do certificado, .....)
   VAR cCertEmissor AS Character INIT []                                       // Nome do Emissor do certificado retornado
   VAR dCertDataini              INIT Ctod([])                                 // Data Inicial de Validade do certificado retornado
   VAR dCertDatafim              INIT Ctod([])                                 // Data Final de Validade do certificado retornado
   VAR cCertImprDig AS Character INIT []                                       // Impressão Digital do certificado retornado
   VAR cCertSerial  AS Character INIT []                                       // Número Serial do certificado retornado
   VAR nCertVersao  AS Num       INIT 0                                        // Versão do certificado retornado
   VAR lCertInstall AS Logical   INIT .F.                                      // Verifica se o Certificado está Instalado no Repositório do Windows
   VAR lCertVencido AS Logical   INIT .F.                                      // Verifica se o Certificado está Vencido

   // Métodos Operacionais
   METHOD fCertificadoNative()
   METHOD fCertificadoPfx()                                                    // cCertificadoArquivo, cCertificadoSenha
ENDCLASS

METHOD fCertificadoNative()
   Local cDados:= SelecionarCertificadoNative()

   If Empty(cDados) .or. Left(cDados, 5) == [ERRO_]
      Return (Nil)
   Endif

   ::cCertNomecer:= ::cCertificado:= CertNativeToken(cDados, 1)
   ::cCertEmissor:= CertNativeToken(cDados, 2)
   ::dCertDataini:= StoD(CertNativeToken(cDados, 3))
   ::dCertDatafim:= StoD(CertNativeToken(cDados, 4))
   ::cCertImprDig:= CertNativeToken(cDados, 5)
   ::cCertSerial := CertNativeToken(cDados, 6)
   ::nCertVersao := Val(CertNativeToken(cDados, 7))
   ::lCertInstall:= CertNativeToken(cDados, 8) == [1]

   If Dtos(::dCertDatafim) < Dtos(Date())
      ::lCertVencido:= .T.
   Else
      ::lCertVencido:= .F.
   Endif

   If [CN=] $ ::cCertificado
      ::cCertificado:= Substr(::cCertificado, At([CN=], ::cCertificado) + 3)
      If [,] $ ::cCertificado
         ::cCertificado:= Substr(::cCertificado, 1, At([,], ::cCertificado) - 1)
      Endif
   Endif
Return (Nil)

* ---------> Metodo para ler dados do PFX sem CAPICOM e sem instalar <-------- *
METHOD fCertificadoPfx(cCertificadoArquivo, cCertificadoSenha) 
   Local cDados:= LerCertificadoPfxNative(cCertificadoArquivo, cCertificadoSenha)

   If Empty(cDados) .or. Left(cDados, 5) == [ERRO_]
      Return (Nil)
   Endif

   ::cCertNomecer:= ::cCertificado:= CertNativeToken(cDados, 1)
   ::cCertEmissor:= CertNativeToken(cDados, 2)
   ::dCertDataini:= StoD(CertNativeToken(cDados, 3))
   ::dCertDatafim:= StoD(CertNativeToken(cDados, 4))
   ::cCertImprDig:= CertNativeToken(cDados, 5)
   ::cCertSerial := CertNativeToken(cDados, 6)
   ::nCertVersao := Val(CertNativeToken(cDados, 7))
   ::lCertInstall:= CertNativeToken(cDados, 8) == [1]

   If Dtos(::dCertDatafim) < Dtos(Date())
      ::lCertVencido:= .T.
   Else
      ::lCertVencido:= .F.
   Endif

   If [CN=] $ ::cCertificado
      ::cCertificado:= Substr(::cCertificado, At([CN=], ::cCertificado) + 3)
      If [,] $ ::cCertificado
         ::cCertificado:= Substr(::cCertificado, 1, At([,], ::cCertificado) - 1)
      Endif
   Endif
Return (Nil)


METHOD New( cXml ) CLASS TEsocialRetornoOcorrencia
   ::cXml := hb_DefaultValue( cXml, "" )
   ::nTipo := Val( EsocialExtrairTag( ::cXml, "tipo" ) )
   ::cCodigo := EsocialExtrairTag( ::cXml, "codigo" )
   ::cDescricao := EsocialExtrairTag( ::cXml, "descricao" )
   ::cLocalizacao := EsocialExtrairTag( ::cXml, "localizacao" )
RETURN Self

METHOD New( cXml ) CLASS TEsocialRetornoEvento
   LOCAL cProc, cOcorr, nPos := 1

   ::cXml := hb_DefaultValue( cXml, "" )
   ::cId := EsocialXmlAttrValue( ::cXml, "Id" )
   IF Empty( ::cId )
      ::cId := EsocialXmlAttrValue( ::cXml, "ID" )
   ENDIF

   cProc := EsocialXmlPrimeiroBloco( ::cXml, "processamento" )
   IF Empty( cProc )
      cProc := ::cXml
   ENDIF

   ::nCdResposta := Val( EsocialExtrairTag( cProc, "cdResposta" ) )
   ::cDescResposta := EsocialExtrairTag( cProc, "descResposta" )
   ::aOcorrencias := {}

   DO WHILE .T.
      cOcorr := EsocialXmlBloco( cProc, "ocorrencia", nPos, @nPos )
      IF Empty( cOcorr )
         EXIT
      ENDIF
      AAdd( ::aOcorrencias, TEsocialRetornoOcorrencia():New( cOcorr ) )
   ENDDO
RETURN Self

METHOD Ok() CLASS TEsocialRetornoEvento
RETURN ::nCdResposta == 201

METHOD GetOcorrenciaCount() CLASS TEsocialRetornoEvento
RETURN Len( ::aOcorrencias )

METHOD GetOcorrencia( nIndex ) CLASS TEsocialRetornoEvento
   LOCAL nPos := hb_DefaultValue( nIndex, 0 ) + 1
   IF nPos < 1 .OR. nPos > Len( ::aOcorrencias )
      RETURN Nil
   ENDIF
RETURN ::aOcorrencias[ nPos ]

METHOD New( cXml ) CLASS TEsocialRetornoLote
   LOCAL cLote, cStatus, cEvento, cOcorr, nPos := 1

   ::cXml := hb_DefaultValue( cXml, "" )
   cLote := EsocialXmlPrimeiroBloco( ::cXml, "retornoProcessamentoLoteEventos" )
   IF Empty( cLote )
      cLote := ::cXml
   ENDIF

   cStatus := EsocialXmlPrimeiroBloco( cLote, "status" )
   IF Empty( cStatus )
      cStatus := cLote
   ENDIF

   ::nCdResposta := Val( EsocialExtrairTag( cStatus, "cdResposta" ) )
   ::cDescResposta := EsocialExtrairTag( cStatus, "descResposta" )
   ::cProtocolo := EsocialExtrairTag( cLote, "protocoloEnvio" )
   ::aEventos := {}
   ::aOcorrencias := {}

   DO WHILE .T.
      cOcorr := EsocialXmlBloco( cStatus, "ocorrencia", nPos, @nPos )
      IF Empty( cOcorr )
         EXIT
      ENDIF
      AAdd( ::aOcorrencias, TEsocialRetornoOcorrencia():New( cOcorr ) )
   ENDDO

   nPos := 1
   DO WHILE .T.
      cEvento := EsocialXmlBloco( cLote, "retornoEvento", nPos, @nPos )
      IF Empty( cEvento )
         EXIT
      ENDIF
      AAdd( ::aEventos, TEsocialRetornoEvento():New( cEvento ) )
   ENDDO
RETURN Self

METHOD LoteOk() CLASS TEsocialRetornoLote
RETURN ::nCdResposta == 201

METHOD TodosEventosOk() CLASS TEsocialRetornoLote
   LOCAL nI
   IF Len( ::aEventos ) == 0
      RETURN .F.
   ENDIF
   FOR nI := 1 TO Len( ::aEventos )
      IF ! ::aEventos[ nI ]:Ok()
         RETURN .F.
      ENDIF
   NEXT
RETURN .T.

METHOD GetEventoCount() CLASS TEsocialRetornoLote
RETURN Len( ::aEventos )

METHOD GetEvento( nIndex ) CLASS TEsocialRetornoLote
   LOCAL nPos := hb_DefaultValue( nIndex, 0 ) + 1
   IF nPos < 1 .OR. nPos > Len( ::aEventos )
      RETURN Nil
   ENDIF
RETURN ::aEventos[ nPos ]

METHOD GetOcorrenciaCount() CLASS TEsocialRetornoLote
RETURN Len( ::aOcorrencias )

METHOD GetOcorrencia( nIndex ) CLASS TEsocialRetornoLote
   LOCAL nPos := hb_DefaultValue( nIndex, 0 ) + 1
   IF nPos < 1 .OR. nPos > Len( ::aOcorrencias )
      RETURN Nil
   ENDIF
RETURN ::aOcorrencias[ nPos ]

METHOD ToTexto() CLASS TEsocialRetornoLote
   LOCAL cTexto, nI, nX, oEvento, oOcorr

   cTexto := "Lote: " + AllTrim( Str( ::nCdResposta ) ) + " - " + ::cDescResposta + hb_Eol()
   cTexto += "Protocolo: " + ::cProtocolo + hb_Eol()
   cTexto += "Eventos: " + AllTrim( Str( Len( ::aEventos ) ) ) + hb_Eol()

   FOR nX := 1 TO ::GetOcorrenciaCount()
      oOcorr := ::GetOcorrencia( nX - 1 )
      cTexto += "Ocorrencia do lote " + AllTrim( Str( nX ) ) + ": tipo=" + AllTrim( Str( oOcorr:nTipo ) ) + ", codigo=" + oOcorr:cCodigo + ", descricao=" + oOcorr:cDescricao + ", localizacao=" + oOcorr:cLocalizacao + hb_Eol()
   NEXT

   FOR nI := 1 TO Len( ::aEventos )
      oEvento := ::aEventos[ nI ]
      cTexto += "Evento " + AllTrim( Str( nI ) ) + ": " + oEvento:cId + " | " + AllTrim( Str( oEvento:nCdResposta ) ) + " - " + oEvento:cDescResposta + hb_Eol()
      FOR nX := 1 TO oEvento:GetOcorrenciaCount()
         oOcorr := oEvento:GetOcorrencia( nX - 1 )
         cTexto += "  Ocorrencia " + AllTrim( Str( nX ) ) + ": tipo=" + AllTrim( Str( oOcorr:nTipo ) ) + ", codigo=" + oOcorr:cCodigo + ", descricao=" + oOcorr:cDescricao + ", localizacao=" + oOcorr:cLocalizacao + hb_Eol()
      NEXT
   NEXT
RETURN cTexto

FUNCTION EsocialRetornoLoteFromXml( cXml )
RETURN TEsocialRetornoLote():New( cXml )

FUNCTION EsocialXmlPrimeiroBloco( cXml, cTag )
   LOCAL nNext := 1
RETURN EsocialXmlBloco( cXml, cTag, 1, @nNext )

FUNCTION EsocialXmlBloco( cXml, cTag, nFrom, nNext )
   LOCAL nStart, nTag, nOpenEnd, nClose, nEnd

   nNext := hb_DefaultValue( nFrom, 1 )
   nStart := hb_At( "<" + cTag, cXml, nNext )
   IF nStart == 0
      nTag := hb_At( ":" + cTag, cXml, nNext )
      IF nTag > 0
         nStart := Rat( "<", Left( cXml, nTag ) )
      ENDIF
   ENDIF
   IF nStart == 0
      RETURN ""
   ENDIF

   nOpenEnd := hb_At( ">", cXml, nStart )
   IF nOpenEnd == 0
      RETURN ""
   ENDIF
   IF SubStr( cXml, nOpenEnd - 1, 2 ) == "/>"
      nNext := nOpenEnd + 1
      RETURN SubStr( cXml, nStart, nOpenEnd - nStart + 1 )
   ENDIF

   nClose := hb_At( "</" + cTag + ">", cXml, nOpenEnd )
   IF nClose == 0
      nTag := hb_At( ":" + cTag + ">", cXml, nOpenEnd )
      IF nTag > 0
         nClose := Rat( "</", Left( cXml, nTag ) )
      ENDIF
   ENDIF
   IF nClose == 0
      RETURN ""
   ENDIF

   nEnd := hb_At( ">", cXml, nClose )
   IF nEnd == 0
      RETURN ""
   ENDIF
   nNext := nEnd + 1
RETURN SubStr( cXml, nStart, nEnd - nStart + 1 )

FUNCTION EsocialXmlAttrValue( cXml, cAttr )
   LOCAL nStart, nEnd
   nStart := hb_At( cAttr + '="', cXml )
   IF nStart == 0
      RETURN ""
   ENDIF
   nStart += Len( cAttr ) + 2
   nEnd := hb_At( '"', cXml, nStart )
   IF nEnd == 0
      RETURN ""
   ENDIF
RETURN SubStr( cXml, nStart, nEnd - nStart )

FUNCTION EsocialExtrairTag( cXml, cTag )
   LOCAL nStart, nClose, cResult := ""

   nStart := At( "<" + cTag + ">", cXml )
   IF nStart == 0
      nStart := hb_At( ":" + cTag + ">", cXml )
      IF nStart > 0
         nStart := Rat( "<", Left( cXml, nStart ) )
      ENDIF
   ENDIF

   IF nStart > 0
      nStart := hb_At( ">", cXml, nStart ) + 1
      nClose := hb_At( "</" + cTag + ">", cXml, nStart )
      IF nClose == 0
         nClose := hb_At( ":" + cTag + ">", cXml, nStart )
         IF nClose > 0
            nClose := Rat( "</", Left( cXml, nClose ) )
         ENDIF
      ENDIF

      IF nClose > nStart
         cResult := SubStr( cXml, nStart, nClose - nStart )
      ENDIF
   ENDIF
RETURN AllTrim( cResult )

FUNCTION EsocialRemoveSignature( cXml )
   LOCAL nStart, nEnd
   DO WHILE ( nStart := hb_At( '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">', cXml ) ) > 0
      nEnd := hb_At( "</Signature>", cXml, nStart )
      IF nEnd == 0
         EXIT
      ENDIF
      nEnd += Len( "</Signature>" ) - 1
      cXml := Left( cXml, nStart - 1 ) + SubStr( cXml, nEnd + 1 )
   ENDDO
RETURN cXml

FUNCTION EsocialRemoveXmlDecl( cXml )
   LOCAL nEnd
   cXml := AllTrim( cXml )
   IF Left( cXml, 5 ) == "<?xml"
      nEnd := hb_At( "?>", cXml )
      IF nEnd > 0
         cXml := AllTrim( SubStr( cXml, nEnd + 2 ) )
      ENDIF
   ENDIF
RETURN cXml

FUNCTION EsocialNovoEvento( cCodigo )
   LOCAL cCod := Upper( AllTrim( hb_DefaultValue( cCodigo, "" ) ) )

   cCod := StrTran( cCod, "-", "" )
   cCod := StrTran( cCod, " ", "" )
   IF Left( cCod, 1 ) != "S"
      cCod := "S" + cCod
   ENDIF

   DO CASE
   CASE cCod == "S1000" ; RETURN TEsocialEventoS1000():New()
   CASE cCod == "S1005" ; RETURN TEsocialEventoS1005():New()
   CASE cCod == "S1010" ; RETURN TEsocialEventoS1010():New()
   CASE cCod == "S1020" ; RETURN TEsocialEventoS1020():New()
   CASE cCod == "S1070" ; RETURN TEsocialEventoS1070():New()
   CASE cCod == "S1200" ; RETURN TEsocialEventoS1200():New()
   CASE cCod == "S1202" ; RETURN TEsocialEventoS1202():New()
   CASE cCod == "S1207" ; RETURN TEsocialEventoS1207():New()
   CASE cCod == "S1210" ; RETURN TEsocialEventoS1210():New()
   CASE cCod == "S1260" ; RETURN TEsocialEventoS1260():New()
   CASE cCod == "S1270" ; RETURN TEsocialEventoS1270():New()
   CASE cCod == "S1280" ; RETURN TEsocialEventoS1280():New()
   CASE cCod == "S1298" ; RETURN TEsocialEventoS1298():New()
   CASE cCod == "S1299" ; RETURN TEsocialEventoS1299():New()
   CASE cCod == "S2190" ; RETURN TEsocialEventoS2190():New()
   CASE cCod == "S2200" ; RETURN TEsocialEventoS2200():New()
   CASE cCod == "S2205" ; RETURN TEsocialEventoS2205():New()
   CASE cCod == "S2206" ; RETURN TEsocialEventoS2206():New()
   CASE cCod == "S2210" ; RETURN TEsocialEventoS2210():New()
   CASE cCod == "S2220" ; RETURN TEsocialEventoS2220():New()
   CASE cCod == "S2221" ; RETURN TEsocialEventoS2221():New()
   CASE cCod == "S2230" ; RETURN TEsocialEventoS2230():New()
   CASE cCod == "S2231" ; RETURN TEsocialEventoS2231():New()
   CASE cCod == "S2240" ; RETURN TEsocialEventoS2240():New()
   CASE cCod == "S2298" ; RETURN TEsocialEventoS2298():New()
   CASE cCod == "S2299" ; RETURN TEsocialEventoS2299():New()
   CASE cCod == "S2300" ; RETURN TEsocialEventoS2300():New()
   CASE cCod == "S2306" ; RETURN TEsocialEventoS2306():New()
   CASE cCod == "S2399" ; RETURN TEsocialEventoS2399():New()
   CASE cCod == "S2400" ; RETURN TEsocialEventoS2400():New()
   CASE cCod == "S2405" ; RETURN TEsocialEventoS2405():New()
   CASE cCod == "S2410" ; RETURN TEsocialEventoS2410():New()
   CASE cCod == "S2416" ; RETURN TEsocialEventoS2416():New()
   CASE cCod == "S2418" ; RETURN TEsocialEventoS2418():New()
   CASE cCod == "S2420" ; RETURN TEsocialEventoS2420():New()
   CASE cCod == "S2500" ; RETURN TEsocialEventoS2500():New()
   CASE cCod == "S2501" ; RETURN TEsocialEventoS2501():New()
   CASE cCod == "S2555" ; RETURN TEsocialEventoS2555():New()
   CASE cCod == "S3000" ; RETURN TEsocialEventoS3000():New()
   CASE cCod == "S3500" ; RETURN TEsocialEventoS3500():New()
   CASE cCod == "S5001" ; RETURN TEsocialEventoS5001():New()
   CASE cCod == "S5002" ; RETURN TEsocialEventoS5002():New()
   CASE cCod == "S5003" ; RETURN TEsocialEventoS5003():New()
   CASE cCod == "S5011" ; RETURN TEsocialEventoS5011():New()
   CASE cCod == "S5012" ; RETURN TEsocialEventoS5012():New()
   CASE cCod == "S5013" ; RETURN TEsocialEventoS5013():New()
   CASE cCod == "S5501" ; RETURN TEsocialEventoS5501():New()
   CASE cCod == "S5503" ; RETURN TEsocialEventoS5503():New()
   CASE cCod == "S8200" ; RETURN TEsocialEventoS8200():New()
   CASE cCod == "S8299" ; RETURN TEsocialEventoS8299():New()
   ENDCASE
RETURN Nil

FUNCTION EsocialMontarEventoXml( cCodigo, cTpInsc, cNrInsc, cXmlCorpo, cTpAmb, cProcEmi, cVerProc, cIndRetif, cNrRecibo, cIndApuracao, cPerApur, cIndGuia )
   LOCAL oEvento := EsocialNovoEvento( cCodigo )

   IF oEvento == Nil
      RETURN ""
   ENDIF

   oEvento:AddCabecalho( cTpInsc, cNrInsc, cTpAmb, cProcEmi, cVerProc, cIndRetif, cNrRecibo, cIndApuracao, cPerApur, cIndGuia )
   oEvento:AddXml( hb_DefaultValue( cXmlCorpo, "" ) )
RETURN oEvento:ToXml()

FUNCTION EsocialMontarEventoAssinado( cCodigo, cTpInsc, cNrInsc, cXmlCorpo, oSigner, cTpAmb, cProcEmi, cVerProc, cIndRetif, cNrRecibo, cIndApuracao, cPerApur, cIndGuia )
   LOCAL cXml

   IF oSigner == Nil
      RETURN ""
   ENDIF

   cXml := EsocialMontarEventoXml( cCodigo, cTpInsc, cNrInsc, cXmlCorpo, cTpAmb, cProcEmi, cVerProc, cIndRetif, cNrRecibo, cIndApuracao, cPerApur, cIndGuia )
   IF Empty( cXml )
      RETURN ""
   ENDIF
RETURN oSigner:AssinarXml( cXml )

FUNCTION EsocialTemplateArquivo( cCodigo, cTemplatePath )
   LOCAL aInfo := EsocialEventoInfo( cCodigo )
   LOCAL cBase := AllTrim( hb_DefaultValue( cTemplatePath, "templates_eventos" ) )

   IF Len( aInfo ) < 2
      RETURN ""
   ENDIF
   IF Right( cBase, 1 ) != "" .AND. Right( cBase, 1 ) != "/"
      cBase += ""
   ENDIF
RETURN cBase + aInfo[ 1 ] + "_" + aInfo[ 2 ] + ".xml"

FUNCTION EsocialCarregarTemplate( cCodigo, cTemplatePath )
   LOCAL cArquivo := EsocialTemplateArquivo( cCodigo, cTemplatePath )

   IF Empty( cArquivo ) .OR. ! File( cArquivo )
      RETURN ""
   ENDIF
RETURN hb_MemoRead( cArquivo )

FUNCTION EsocialPreencherTemplate( cTemplate, aCampos, lRemoverComentarios )
   LOCAL cXml := hb_DefaultValue( cTemplate, "" )
   LOCAL nI, aCampo, cNome, cValor

   IF lRemoverComentarios == Nil
      lRemoverComentarios := .T.
   ENDIF

   IF ValType( aCampos ) == "A"
      FOR nI := 1 TO Len( aCampos )
         aCampo := aCampos[ nI ]
         IF ValType( aCampo ) == "A" .AND. Len( aCampo ) >= 2
            cNome := AllTrim( hb_DefaultValue( aCampo[ 1 ], "" ) )
            cValor := EsocialValorTexto( aCampo[ 2 ] )
            IF ! Empty( cNome )
               cXml := StrTran( cXml, "{" + cNome + "}", EsocialXmlEscape( cValor ) )
            ENDIF
         ENDIF
      NEXT
   ENDIF

   cXml := EsocialAplicarEscolhasTemplate( cXml, aCampos )

   IF lRemoverComentarios
      cXml := EsocialRemoverComentariosXml( cXml )
   ENDIF
   cXml := EsocialRemoverLinhasComPlaceholder( cXml )
   cXml := EsocialRemoverGruposVazios( cXml )
RETURN AllTrim( cXml )

FUNCTION EsocialMontarXmlPorTemplate( cCodigo, aCampos, cTemplatePath )
   LOCAL cTemplate := EsocialCarregarTemplate( cCodigo, cTemplatePath )

   IF Empty( cTemplate )
      RETURN ""
   ENDIF
RETURN EsocialPreencherTemplate( cTemplate, aCampos, .T. )

FUNCTION EsocialAplicarEscolhasTemplate( cXml, aCampos )
   LOCAL cOperacao := Lower( EsocialValorCampoTemplate( aCampos, "operacao" ) )

   IF Empty( cOperacao )
      cOperacao := Lower( EsocialValorCampoTemplate( aCampos, "tipoOperacao" ) )
   ENDIF
   IF Empty( cOperacao ) .AND. ( "<inclusao>" $ cXml ) .AND. ( "<alteracao>" $ cXml ) .AND. ( "<exclusao>" $ cXml )
      cOperacao := "inclusao"
   ENDIF

   IF ! Empty( cOperacao ) .AND. ( "<inclusao>" $ cXml ) .AND. ( "<alteracao>" $ cXml ) .AND. ( "<exclusao>" $ cXml )
      IF cOperacao != "inclusao"
         cXml := EsocialRemoverBlocoXml( cXml, "inclusao" )
      ENDIF
      IF cOperacao != "alteracao"
         cXml := EsocialRemoverBlocoXml( cXml, "alteracao" )
      ENDIF
      IF cOperacao != "exclusao"
         cXml := EsocialRemoverBlocoXml( cXml, "exclusao" )
      ENDIF
   ENDIF
   cXml := EsocialAplicarGrupoEscolha( cXml, aCampos, { "brasil", "exterior" }, "brasil" )
   cXml := EsocialAplicarGrupoEscolha( cXml, aCampos, { "infoCeletista", "infoEstatutario" }, "infoCeletista" )
   cXml := EsocialAplicarGrupoEscolha( cXml, aCampos, { "iniCessao", "fimCessao" }, "iniCessao" )
   cXml := EsocialAplicarGrupoEscolha( cXml, aCampos, { "infoProcJud", "infoCCP" }, "infoProcJud" )
   cXml := EsocialRemoverOpcionaisNaoMarcados( cXml, aCampos )
RETURN cXml

FUNCTION EsocialRemoverOpcionaisNaoMarcados( cXml, aCampos )
   LOCAL aTags := { "dependente", "trabImig", "infoDeficiencia", "contato", "infoRegCTPS", "FGTS", "trabTemporario", "aprend", "sucessaoVinc", "transfDom", "mudancaCPF", "afastamento", "desligamento", "cessao", "observacoes", "treiCap", "remuneracao", "duracao", "localTrabalho", "horContratual", "alvaraJudicial", "iniAfastamento", "infoRetif", "fimAfastamento", "perAquis", "infoCessao", "infoMandSind", "infoMandElet", "infoInterm", "transfTit", "verbasResc", "remunAposDeslig", "remunAposTerm", "consigFGTS", "infoRRA", "despProcJud", "ideAdv", "infoPerApur", "infoPerAnt", "procJudTrab", "infoMV", "procCS", "infoComplementares", "cargoFuncao", "infoDirigenteSindical", "infoTrabCedido", "infoEstagiario", "localTrabGeral", "termino", "ageIntegracao", "supervisorEstagio", "infoPenMorte", "instPenMorte", "infoHomolog", "sucessaoBenef", "infoBenTermino", "suspensao", "infoComplem", "infoComplCont", "descFolha", "infoAgNocivo", "infoSimples", "infoPgto", "infoPgtoExt", "infoIRComplem", "perAnt", "infoDep", "infoIRCR", "dedDepen", "penAlim", "previdCompl", "infoProcRet", "infoValores", "dedSusp", "benefPen", "planSaude", "infoDepSau", "infoReembMed", "detReembTit", "infoReembDep", "infoSubstPatr", "infoSubstPatrOpPort", "infoAtivConcom", "infoPercTransf11096", "ideResp", "infoCompl", "infoVinc", "infoDeslig", "infoTerm", "mudCategAtiv", "unicContr", "abono" }
   LOCAL nI, cTag

   FOR nI := 1 TO Len( aTags )
      cTag := aTags[ nI ]
      IF Empty( EsocialValorCampoTemplate( aCampos, "grupo_" + cTag ) )
         cXml := EsocialRemoverBlocoXml( cXml, cTag )
      ENDIF
   NEXT
RETURN cXml

FUNCTION EsocialAplicarGrupoEscolha( cXml, aCampos, aTags, cPadrao )
   LOCAL cEscolha := EsocialEscolhaInformada( aCampos, aTags )
   LOCAL nI, cTag

   IF Empty( cEscolha )
      cEscolha := hb_DefaultValue( cPadrao, "" )
   ENDIF
   IF Empty( cEscolha )
      RETURN cXml
   ENDIF

   IF ! EsocialContemTodosBlocos( cXml, aTags )
      RETURN cXml
   ENDIF

   FOR nI := 1 TO Len( aTags )
      cTag := aTags[ nI ]
      IF cTag != cEscolha
         cXml := EsocialRemoverBlocoXml( cXml, cTag )
      ENDIF
   NEXT
RETURN cXml

FUNCTION EsocialEscolhaInformada( aCampos, aTags )
   LOCAL nI, cTag

   FOR nI := 1 TO Len( aTags )
      cTag := aTags[ nI ]
      IF ! Empty( EsocialValorCampoTemplate( aCampos, "escolha_" + cTag ) )
         RETURN cTag
      ENDIF
   NEXT
RETURN ""

FUNCTION EsocialContemTodosBlocos( cXml, aTags )
   LOCAL nI

   FOR nI := 1 TO Len( aTags )
      IF ! ( "<" + aTags[ nI ] + ">" $ cXml )
         RETURN .F.
      ENDIF
   NEXT
RETURN .T.

FUNCTION EsocialValorCampoTemplate( aCampos, cNome )
   LOCAL nI, cBusca := Lower( AllTrim( hb_DefaultValue( cNome, "" ) ) )

   IF ValType( aCampos ) == "A"
      FOR nI := 1 TO Len( aCampos )
         IF ValType( aCampos[ nI ] ) == "A" .AND. Len( aCampos[ nI ] ) >= 2
            IF Lower( AllTrim( hb_DefaultValue( aCampos[ nI, 1 ], "" ) ) ) == cBusca
               RETURN EsocialValorTexto( aCampos[ nI, 2 ] )
            ENDIF
         ENDIF
      NEXT
   ENDIF
RETURN ""

FUNCTION EsocialRemoverBlocoXml( cXml, cTag )
   LOCAL nIni, nFim, cFecha

   cTag := AllTrim( hb_DefaultValue( cTag, "" ) )
   IF Empty( cTag )
      RETURN cXml
   ENDIF

   cFecha := "</" + cTag + ">"
   DO WHILE ( nIni := hb_At( "<" + cTag + ">", cXml ) ) > 0
      nFim := hb_At( cFecha, cXml, nIni )
      IF nFim == 0
         EXIT
      ENDIF
      nFim += Len( cFecha ) - 1
      cXml := Left( cXml, nIni - 1 ) + SubStr( cXml, nFim + 1 )
   ENDDO
RETURN cXml

FUNCTION EsocialTemplateTemPendencias( cXml )
RETURN ( "{" $ hb_DefaultValue( cXml, "" ) ) .AND. ( "}" $ hb_DefaultValue( cXml, "" ) )

FUNCTION EsocialRemoverComentariosXml( cXml )
   LOCAL nIni, nFim

   cXml := hb_DefaultValue( cXml, "" )
   DO WHILE ( nIni := hb_At( "<!--", cXml ) ) > 0
      nFim := hb_At( "-->", cXml, nIni )
      IF nFim == 0
         EXIT
      ENDIF
      cXml := Left( cXml, nIni - 1 ) + SubStr( cXml, nFim + 3 )
   ENDDO
RETURN cXml

FUNCTION EsocialRemoverLinhasComPlaceholder( cXml )
   LOCAL aLinhas := hb_ATokens( hb_DefaultValue( cXml, "" ), Chr( 10 ) )
   LOCAL cNovo := "", nI, cLinha

   FOR nI := 1 TO Len( aLinhas )
      cLinha := aLinhas[ nI ]
      IF ! ( "{" $ cLinha .AND. "}" $ cLinha )
         cNovo += cLinha + Chr( 10 )
      ENDIF
   NEXT
RETURN cNovo

FUNCTION EsocialRemoverGruposVazios( cXml )
   LOCAL lMudou := .T.
   LOCAL nFim, nIniNome, nFimNome, cTag, nAbre, nAbreFim, cAntes, cMiolo, cDepois

   cXml := hb_DefaultValue( cXml, "" )
   DO WHILE lMudou
      lMudou := .F.
      nFim := hb_At( "</", cXml )
      DO WHILE nFim > 0
         nIniNome := nFim + 2
         nFimNome := hb_At( ">", cXml, nIniNome )
         IF nFimNome == 0
            EXIT
         ENDIF
         cTag := SubStr( cXml, nIniNome, nFimNome - nIniNome )
         nAbre := EsocialRat( "<" + cTag, Left( cXml, nFim - 1 ) )
         IF nAbre > 0
            nAbreFim := hb_At( ">", cXml, nAbre )
            IF nAbreFim > 0
               cMiolo := SubStr( cXml, nAbreFim + 1, nFim - nAbreFim - 1 )
               IF Empty( AllTrim( cMiolo ) )
                  cAntes := Left( cXml, nAbre - 1 )
                  cDepois := SubStr( cXml, nFimNome + 1 )
                  cXml := cAntes + cDepois
                  lMudou := .T.
                  EXIT
               ENDIF
            ENDIF
         ENDIF
         nFim := hb_At( "</", cXml, nFimNome + 1 )
      ENDDO
   ENDDO
RETURN cXml

FUNCTION EsocialRat( cBusca, cTexto )
   LOCAL nPos := 0, nAchou := 0

   DO WHILE ( nAchou := hb_At( cBusca, cTexto, nPos + 1 ) ) > 0
      nPos := nAchou
   ENDDO
RETURN nPos

FUNCTION EsocialValorTexto( xValor )
   LOCAL cTipo := ValType( xValor )

   DO CASE
   CASE xValor == Nil
      RETURN ""
   CASE cTipo == "C" .OR. cTipo == "M"
      RETURN AllTrim( xValor )
   CASE cTipo == "D"
      RETURN DateXml( xValor )
   CASE cTipo == "N"
      RETURN AllTrim( Str( xValor ) )
   CASE cTipo == "L"
      RETURN IIf( xValor, "1", "0" )
   ENDCASE
RETURN AllTrim( hb_ValToStr( xValor ) )

FUNCTION EsocialEventoInfo( cCodigo )
   LOCAL cCod := Upper( AllTrim( hb_DefaultValue( cCodigo, "" ) ) )

   cCod := StrTran( cCod, "-", "" )
   cCod := StrTran( cCod, " ", "" )
   IF Left( cCod, 1 ) != "S"
      cCod := "S" + cCod
   ENDIF

   DO CASE
   CASE cCod == "S1000" ; RETURN { "S-1000", "evtInfoEmpregador", "evtInfoEmpregador", "TEsocialEventoS1000", "tabela-inicial" }
   CASE cCod == "S1005" ; RETURN { "S-1005", "evtTabEstab", "evtTabEstab", "TEsocialEventoS1005", "tabela-inicial" }
   CASE cCod == "S1010" ; RETURN { "S-1010", "evtTabRubrica", "evtTabRubrica", "TEsocialEventoS1010", "tabela" }
   CASE cCod == "S1020" ; RETURN { "S-1020", "evtTabLotacao", "evtTabLotacao", "TEsocialEventoS1020", "tabela" }
   CASE cCod == "S1070" ; RETURN { "S-1070", "evtTabProcesso", "evtTabProcesso", "TEsocialEventoS1070", "tabela" }
   CASE cCod == "S1200" ; RETURN { "S-1200", "evtRemun", "evtRemun", "TEsocialEventoS1200", "folha" }
   CASE cCod == "S1202" ; RETURN { "S-1202", "evtRmnRPPS", "evtRmnRPPS", "TEsocialEventoS1202", "folha-opp" }
   CASE cCod == "S1207" ; RETURN { "S-1207", "evtBenPrRP", "evtBenPrRP", "TEsocialEventoS1207", "folha-opp" }
   CASE cCod == "S1210" ; RETURN { "S-1210", "evtPgtos", "evtPgtos", "TEsocialEventoS1210", "folha-mensal" }
   CASE cCod == "S1260" ; RETURN { "S-1260", "evtComProd", "evtComProd", "TEsocialEventoS1260", "folha-mensal-pf" }
   CASE cCod == "S1270" ; RETURN { "S-1270", "evtContratAvNP", "evtContratAvNP", "TEsocialEventoS1270", "folha-mensal" }
   CASE cCod == "S1280" ; RETURN { "S-1280", "evtInfoComplPer", "evtInfoComplPer", "TEsocialEventoS1280", "folha" }
   CASE cCod == "S1298" ; RETURN { "S-1298", "evtReabreEvPer", "evtReabreEvPer", "TEsocialEventoS1298", "folha-sem-retificacao" }
   CASE cCod == "S1299" ; RETURN { "S-1299", "evtFechaEvPer", "evtFechaEvPer", "TEsocialEventoS1299", "folha-sem-retificacao" }
   CASE cCod == "S2190" ; RETURN { "S-2190", "evtAdmPrelim", "evtAdmPrelim", "TEsocialEventoS2190", "trab-admissao" }
   CASE cCod == "S2200" ; RETURN { "S-2200", "evtAdmissao", "evtAdmissao", "TEsocialEventoS2200", "trab-admissao" }
   CASE cCod == "S2205" ; RETURN { "S-2205", "evtAltCadastral", "evtAltCadastral", "TEsocialEventoS2205", "trabalhador" }
   CASE cCod == "S2206" ; RETURN { "S-2206", "evtAltContratual", "evtAltContratual", "TEsocialEventoS2206", "trabalhador" }
   CASE cCod == "S2210" ; RETURN { "S-2210", "evtCAT", "evtCAT", "TEsocialEventoS2210", "trabalhador" }
   CASE cCod == "S2220" ; RETURN { "S-2220", "evtMonit", "evtMonit", "TEsocialEventoS2220", "trabalhador" }
   CASE cCod == "S2221" ; RETURN { "S-2221", "evtToxic", "evtToxic", "TEsocialEventoS2221", "trabalhador-pj" }
   CASE cCod == "S2230" ; RETURN { "S-2230", "evtAfastTemp", "evtAfastTemp", "TEsocialEventoS2230", "trabalhador" }
   CASE cCod == "S2231" ; RETURN { "S-2231", "evtCessao", "evtCessao", "TEsocialEventoS2231", "trabalhador-pj" }
   CASE cCod == "S2240" ; RETURN { "S-2240", "evtExpRisco", "evtExpRisco", "TEsocialEventoS2240", "trabalhador" }
   CASE cCod == "S2298" ; RETURN { "S-2298", "evtReintegr", "evtReintegr", "TEsocialEventoS2298", "trabalhador" }
   CASE cCod == "S2299" ; RETURN { "S-2299", "evtDeslig", "evtDeslig", "TEsocialEventoS2299", "trabalhador-indguia" }
   CASE cCod == "S2300" ; RETURN { "S-2300", "evtTSVInicio", "evtTSVInicio", "TEsocialEventoS2300", "trabalhador" }
   CASE cCod == "S2306" ; RETURN { "S-2306", "evtTSVAltContr", "evtTSVAltContr", "TEsocialEventoS2306", "trabalhador" }
   CASE cCod == "S2399" ; RETURN { "S-2399", "evtTSVTermino", "evtTSVTermino", "TEsocialEventoS2399", "trabalhador-indguia" }
   CASE cCod == "S2400" ; RETURN { "S-2400", "evtCdBenefIn", "evtCdBenefIn", "TEsocialEventoS2400", "trabalhador-pj" }
   CASE cCod == "S2405" ; RETURN { "S-2405", "evtCdBenefAlt", "evtCdBenefAlt", "TEsocialEventoS2405", "trabalhador-pj" }
   CASE cCod == "S2410" ; RETURN { "S-2410", "evtCdBenIn", "evtCdBenIn", "TEsocialEventoS2410", "trabalhador-pj" }
   CASE cCod == "S2416" ; RETURN { "S-2416", "evtCdBenAlt", "evtCdBenAlt", "TEsocialEventoS2416", "trabalhador-pj" }
   CASE cCod == "S2418" ; RETURN { "S-2418", "evtReativBen", "evtReativBen", "TEsocialEventoS2418", "trabalhador-pj" }
   CASE cCod == "S2420" ; RETURN { "S-2420", "evtCdBenTerm", "evtCdBenTerm", "TEsocialEventoS2420", "trabalhador-pj" }
   CASE cCod == "S2500" ; RETURN { "S-2500", "evtProcTrab", "evtProcTrab", "TEsocialEventoS2500", "trabalhador" }
   CASE cCod == "S2501" ; RETURN { "S-2501", "evtContProc", "evtContProc", "TEsocialEventoS2501", "trabalhador" }
   CASE cCod == "S2555" ; RETURN { "S-2555", "evtConsolidContProc", "evtConsolidContProc", "TEsocialEventoS2555", "exclusao-proc-trab" }
   CASE cCod == "S3000" ; RETURN { "S-3000", "evtExclusao", "evtExclusao", "TEsocialEventoS3000", "exclusao" }
   CASE cCod == "S3500" ; RETURN { "S-3500", "evtExcProcTrab", "evtExcProcTrab", "TEsocialEventoS3500", "exclusao-proc-trab" }
   CASE cCod == "S5001" ; RETURN { "S-5001", "evtBasesTrab", "evtBasesTrab", "TEsocialEventoS5001", "retorno-contrib" }
   CASE cCod == "S5002" ; RETURN { "S-5002", "evtIrrfBenef", "evtIrrfBenef", "TEsocialEventoS5002", "retorno" }
   CASE cCod == "S5003" ; RETURN { "S-5003", "evtBasesFGTS", "evtBasesFGTS", "TEsocialEventoS5003", "retorno" }
   CASE cCod == "S5011" ; RETURN { "S-5011", "evtCS", "evtCS", "TEsocialEventoS5011", "retorno-contrib" }
   CASE cCod == "S5012" ; RETURN { "S-5012", "evtIrrf", "evtIrrf", "TEsocialEventoS5012", "retorno-mensal" }
   CASE cCod == "S5013" ; RETURN { "S-5013", "evtFGTS", "evtFGTS", "TEsocialEventoS5013", "retorno-contrib" }
   CASE cCod == "S5501" ; RETURN { "S-5501", "evtTribProcTrab", "evtTribProcTrab", "TEsocialEventoS5501", "retorno" }
   CASE cCod == "S5503" ; RETURN { "S-5503", "evtFGTSProcTrab", "evtFGTSProcTrab", "TEsocialEventoS5503", "retorno" }
   CASE cCod == "S8200" ; RETURN { "S-8200", "evtAnotJud", "evtAnotJud", "TEsocialEventoS8200", "trab-jud" }
   CASE cCod == "S8299" ; RETURN { "S-8299", "evtBaixa", "evtBaixa", "TEsocialEventoS8299", "trab-jud" }
   ENDCASE
RETURN {}

FUNCTION EsocialCodigoPorTag( cNomeEvento )
   LOCAL cTag := AllTrim( hb_DefaultValue( cNomeEvento, "" ) )

   DO CASE
   CASE cTag == "evtInfoEmpregador" ; RETURN "S1000"
   CASE cTag == "evtTabEstab" ; RETURN "S1005"
   CASE cTag == "evtTabRubrica" ; RETURN "S1010"
   CASE cTag == "evtTabLotacao" ; RETURN "S1020"
   CASE cTag == "evtTabProcesso" ; RETURN "S1070"
   CASE cTag == "evtRemun" ; RETURN "S1200"
   CASE cTag == "evtRmnRPPS" ; RETURN "S1202"
   CASE cTag == "evtBenPrRP" ; RETURN "S1207"
   CASE cTag == "evtPgtos" ; RETURN "S1210"
   CASE cTag == "evtComProd" ; RETURN "S1260"
   CASE cTag == "evtContratAvNP" ; RETURN "S1270"
   CASE cTag == "evtInfoComplPer" ; RETURN "S1280"
   CASE cTag == "evtReabreEvPer" ; RETURN "S1298"
   CASE cTag == "evtFechaEvPer" ; RETURN "S1299"
   CASE cTag == "evtAdmPrelim" ; RETURN "S2190"
   CASE cTag == "evtAdmissao" ; RETURN "S2200"
   CASE cTag == "evtAltCadastral" ; RETURN "S2205"
   CASE cTag == "evtAltContratual" ; RETURN "S2206"
   CASE cTag == "evtCAT" ; RETURN "S2210"
   CASE cTag == "evtMonit" ; RETURN "S2220"
   CASE cTag == "evtToxic" ; RETURN "S2221"
   CASE cTag == "evtAfastTemp" ; RETURN "S2230"
   CASE cTag == "evtCessao" ; RETURN "S2231"
   CASE cTag == "evtExpRisco" ; RETURN "S2240"
   CASE cTag == "evtReintegr" ; RETURN "S2298"
   CASE cTag == "evtDeslig" ; RETURN "S2299"
   CASE cTag == "evtTSVInicio" ; RETURN "S2300"
   CASE cTag == "evtTSVAltContr" ; RETURN "S2306"
   CASE cTag == "evtTSVTermino" ; RETURN "S2399"
   CASE cTag == "evtCdBenefIn" ; RETURN "S2400"
   CASE cTag == "evtCdBenefAlt" ; RETURN "S2405"
   CASE cTag == "evtCdBenIn" ; RETURN "S2410"
   CASE cTag == "evtCdBenAlt" ; RETURN "S2416"
   CASE cTag == "evtReativBen" ; RETURN "S2418"
   CASE cTag == "evtCdBenTerm" ; RETURN "S2420"
   CASE cTag == "evtProcTrab" ; RETURN "S2500"
   CASE cTag == "evtContProc" ; RETURN "S2501"
   CASE cTag == "evtConsolidContProc" ; RETURN "S2555"
   CASE cTag == "evtExclusao" ; RETURN "S3000"
   CASE cTag == "evtExcProcTrab" ; RETURN "S3500"
   CASE cTag == "evtBasesTrab" ; RETURN "S5001"
   CASE cTag == "evtIrrfBenef" ; RETURN "S5002"
   CASE cTag == "evtBasesFGTS" ; RETURN "S5003"
   CASE cTag == "evtCS" ; RETURN "S5011"
   CASE cTag == "evtIrrf" ; RETURN "S5012"
   CASE cTag == "evtFGTS" ; RETURN "S5013"
   CASE cTag == "evtTribProcTrab" ; RETURN "S5501"
   CASE cTag == "evtFGTSProcTrab" ; RETURN "S5503"
   CASE cTag == "evtAnotJud" ; RETURN "S8200"
   CASE cTag == "evtBaixa" ; RETURN "S8299"
   ENDCASE
RETURN ""

FUNCTION EsocialValidacaoLastError()
RETURN s_cEsocialValidacaoLastError

FUNCTION EsocialValidarEventoXsd( cXml, cXsdPath )
   LOCAL cEventName, cSchemaFile, cSchemaPath, cNamespace
   LOCAL oCache, oDom, oErr
   LOCAL lOk := .F.

   s_cEsocialValidacaoLastError := ""
   cXml := AllTrim( hb_DefaultValue( cXml, "" ) )
   cXsdPath := AllTrim( hb_DefaultValue( cXsdPath, "xsd\schemas" ) )

   IF Empty( cXml )
      s_cEsocialValidacaoLastError := "XML vazio para validacao XSD"
      RETURN .F.
   ENDIF

   cEventName := EsocialFirstEventName( cXml )
   cSchemaFile := EsocialSchemaFilePorTag( cEventName )
   IF Empty( cSchemaFile )
      s_cEsocialValidacaoLastError := "Schema nao mapeado para evento " + cEventName
      RETURN .F.
   ENDIF

   cSchemaPath := cXsdPath
   IF Right( cSchemaPath, 1 ) != "" .AND. Right( cSchemaPath, 1 ) != "/"
      cSchemaPath += ""
   ENDIF
   cSchemaPath += cSchemaFile

   IF ! File( cSchemaPath )
      s_cEsocialValidacaoLastError := "Schema nao encontrado: " + cSchemaPath
      RETURN .F.
   ENDIF

   cNamespace := EsocialNamespace( cXml )
   IF Empty( cNamespace )
      s_cEsocialValidacaoLastError := "Namespace do evento nao encontrado"
      RETURN .F.
   ENDIF

   BEGIN SEQUENCE WITH {|oErrBreak| Break(oErrBreak)}
      oCache := Win_OleCreateObject( "MSXML2.XMLSchemaCache.6.0" )
      oCache:add( cNamespace, cSchemaPath )

      oDom := Win_OleCreateObject( "MSXML2.DOMDocument.6.0" )
      oDom:async := .F.
      oDom:validateOnParse := .T.
      oDom:resolveExternals := .T.
      oDom:schemas := oCache

      IF ! oDom:loadXML( cXml )
         oErr := oDom:parseError
         s_cEsocialValidacaoLastError := "Parse XML: " + oErr:reason
      ELSE
         oErr := oDom:validate()
         IF oErr:errorCode == 0
            lOk := .T.
         ELSE
            s_cEsocialValidacaoLastError := "XSD: " + oErr:reason
         ENDIF
      ENDIF
   RECOVER USING oErr
      s_cEsocialValidacaoLastError := "Erro validacao XSD"
   END SEQUENCE
RETURN lOk

FUNCTION EsocialValidarEventosDoLoteXsd( cXmlLote, cXsdPath )
   LOCAL nStart, nEnd, cEvento

   s_cEsocialValidacaoLastError := ""
   cXmlLote := AllTrim( hb_DefaultValue( cXmlLote, "" ) )
   nStart := hb_At( '<eSocial xmlns="http://www.esocial.gov.br/schema/evt/', cXmlLote )

   IF nStart == 0
      s_cEsocialValidacaoLastError := "Nenhum evento <eSocial> encontrado no lote"
      RETURN .F.
   ENDIF

   DO WHILE nStart > 0
      nEnd := hb_At( "</eSocial>", cXmlLote, nStart )
      IF nEnd == 0
         s_cEsocialValidacaoLastError := "Evento <eSocial> sem fechamento no lote"
         RETURN .F.
      ENDIF
      nEnd += Len( "</eSocial>" ) - 1
      cEvento := SubStr( cXmlLote, nStart, nEnd - nStart + 1 )
      IF ! EsocialValidarEventoXsd( cEvento, cXsdPath )
         RETURN .F.
      ENDIF
      nStart := hb_At( '<eSocial xmlns="http://www.esocial.gov.br/schema/evt/', cXmlLote, nEnd + 1 )
   ENDDO
RETURN .T.

FUNCTION EsocialValidarArquivoEventoXsd( cArquivoXml, cXsdPath )
   IF Empty( cArquivoXml ) .OR. ! File( cArquivoXml )
      s_cEsocialValidacaoLastError := "Arquivo XML nao encontrado: " + hb_DefaultValue( cArquivoXml, "" )
      RETURN .F.
   ENDIF
RETURN EsocialValidarEventoXsd( hb_MemoRead( cArquivoXml ), cXsdPath )

FUNCTION EsocialValidarArquivoLoteXsd( cArquivoXml, cXsdPath )
   IF Empty( cArquivoXml ) .OR. ! File( cArquivoXml )
      s_cEsocialValidacaoLastError := "Arquivo XML nao encontrado: " + hb_DefaultValue( cArquivoXml, "" )
      RETURN .F.
   ENDIF
RETURN EsocialValidarEventosDoLoteXsd( hb_MemoRead( cArquivoXml ), cXsdPath )

FUNCTION EsocialSchemaFilePorTag( cNomeEvento )
   LOCAL cTag := AllTrim( hb_DefaultValue( cNomeEvento, "" ) )

   DO CASE
   CASE cTag == "evtAdmissao" ; RETURN "evtAdmissao.xsd"
   CASE cTag == "evtAdmPrelim" ; RETURN "evtAdmPrelim.xsd"
   CASE cTag == "evtAfastTemp" ; RETURN "evtAfastTemp.xsd"
   CASE cTag == "evtAltCadastral" ; RETURN "evtAltCadastral.xsd"
   CASE cTag == "evtAltContratual" ; RETURN "evtAltContratual.xsd"
   CASE cTag == "evtAnotJud" ; RETURN "evtAnotJud.xsd"
   CASE cTag == "evtBaixa" ; RETURN "evtBaixa.xsd"
   CASE cTag == "evtBasesFGTS" ; RETURN "evtBasesFGTS.xsd"
   CASE cTag == "evtBasesTrab" ; RETURN "evtBasesTrab.xsd"
   CASE cTag == "evtBenPrRP" ; RETURN "evtBenPrRP.xsd"
   CASE cTag == "evtCAT" ; RETURN "evtCAT.xsd"
   CASE cTag == "evtCdBenAlt" ; RETURN "evtCdBenAlt.xsd"
   CASE cTag == "evtCdBenefAlt" ; RETURN "evtCdBenefAlt.xsd"
   CASE cTag == "evtCdBenefIn" ; RETURN "evtCdBenefIn.xsd"
   CASE cTag == "evtCdBenIn" ; RETURN "evtCdBenIn.xsd"
   CASE cTag == "evtCdBenTerm" ; RETURN "evtCdBenTerm.xsd"
   CASE cTag == "evtCessao" ; RETURN "evtCessao.xsd"
   CASE cTag == "evtComProd" ; RETURN "evtComProd.xsd"
   CASE cTag == "evtConsolidContProc" ; RETURN "evtConsolidContProc.xsd"
   CASE cTag == "evtContProc" ; RETURN "evtContProc.xsd"
   CASE cTag == "evtContratAvNP" ; RETURN "evtContratAvNP.xsd"
   CASE cTag == "evtCS" ; RETURN "evtCS.xsd"
   CASE cTag == "evtDeslig" ; RETURN "evtDeslig.xsd"
   CASE cTag == "evtExclusao" ; RETURN "evtExclusao.xsd"
   CASE cTag == "evtExcProcTrab" ; RETURN "evtExcProcTrab.xsd"
   CASE cTag == "evtExpRisco" ; RETURN "evtExpRisco.xsd"
   CASE cTag == "evtFechaEvPer" ; RETURN "evtFechaEvPer.xsd"
   CASE cTag == "evtFGTS" ; RETURN "evtFGTS.xsd"
   CASE cTag == "evtFGTSProcTrab" ; RETURN "evtFGTSProcTrab.xsd"
   CASE cTag == "evtInfoComplPer" ; RETURN "evtInfoComplPer.xsd"
   CASE cTag == "evtInfoEmpregador" ; RETURN "evtInfoEmpregador.xsd"
   CASE cTag == "evtIrrf" ; RETURN "evtIrrf.xsd"
   CASE cTag == "evtIrrfBenef" ; RETURN "evtIrrfBenef.xsd"
   CASE cTag == "evtMonit" ; RETURN "evtMonit.xsd"
   CASE cTag == "evtPgtos" ; RETURN "evtPgtos.xsd"
   CASE cTag == "evtProcTrab" ; RETURN "evtProcTrab.xsd"
   CASE cTag == "evtReabreEvPer" ; RETURN "evtReabreEvPer.xsd"
   CASE cTag == "evtReativBen" ; RETURN "evtReativBen.xsd"
   CASE cTag == "evtReintegr" ; RETURN "evtReintegr.xsd"
   CASE cTag == "evtRemun" ; RETURN "evtRemun.xsd"
   CASE cTag == "evtRmnRPPS" ; RETURN "evtRmnRPPS.xsd"
   CASE cTag == "evtTabEstab" ; RETURN "evtTabEstab.xsd"
   CASE cTag == "evtTabLotacao" ; RETURN "evtTabLotacao.xsd"
   CASE cTag == "evtTabProcesso" ; RETURN "evtTabProcesso.xsd"
   CASE cTag == "evtTabRubrica" ; RETURN "evtTabRubrica.xsd"
   CASE cTag == "evtToxic" ; RETURN "evtToxic.xsd"
   CASE cTag == "evtTribProcTrab" ; RETURN "evtTribProcTrab.xsd"
   CASE cTag == "evtTSVAltContr" ; RETURN "evtTSVAltContr.xsd"
   CASE cTag == "evtTSVInicio" ; RETURN "evtTSVInicio.xsd"
   CASE cTag == "evtTSVTermino" ; RETURN "evtTSVTermino.xsd"
   ENDCASE
RETURN ""

FUNCTION EsocialTipoIdeEventoPorTag( cNomeEvento )
   LOCAL cTag := AllTrim( hb_DefaultValue( cNomeEvento, "" ) )

   DO CASE
   CASE cTag == "evtInfoEmpregador" ; RETURN "tabela-inicial"
   CASE cTag == "evtTabEstab" ; RETURN "tabela-inicial"
   CASE cTag == "evtTabRubrica" ; RETURN "tabela"
   CASE cTag == "evtTabLotacao" ; RETURN "tabela"
   CASE cTag == "evtTabProcesso" ; RETURN "tabela"
   CASE cTag == "evtRemun" ; RETURN "folha"
   CASE cTag == "evtRmnRPPS" ; RETURN "folha-opp"
   CASE cTag == "evtBenPrRP" ; RETURN "folha-opp"
   CASE cTag == "evtPgtos" ; RETURN "folha-mensal"
   CASE cTag == "evtComProd" ; RETURN "folha-mensal-pf"
   CASE cTag == "evtContratAvNP" ; RETURN "folha-mensal"
   CASE cTag == "evtInfoComplPer" ; RETURN "folha"
   CASE cTag == "evtReabreEvPer" ; RETURN "folha-sem-retificacao"
   CASE cTag == "evtFechaEvPer" ; RETURN "folha-sem-retificacao"
   CASE cTag == "evtAdmPrelim" ; RETURN "trab-admissao"
   CASE cTag == "evtAdmissao" ; RETURN "trab-admissao"
   CASE cTag == "evtAltCadastral" ; RETURN "trabalhador"
   CASE cTag == "evtAltContratual" ; RETURN "trabalhador"
   CASE cTag == "evtCAT" ; RETURN "trabalhador"
   CASE cTag == "evtMonit" ; RETURN "trabalhador"
   CASE cTag == "evtToxic" ; RETURN "trabalhador-pj"
   CASE cTag == "evtAfastTemp" ; RETURN "trabalhador"
   CASE cTag == "evtCessao" ; RETURN "trabalhador-pj"
   CASE cTag == "evtExpRisco" ; RETURN "trabalhador"
   CASE cTag == "evtReintegr" ; RETURN "trabalhador"
   CASE cTag == "evtDeslig" ; RETURN "trabalhador-indguia"
   CASE cTag == "evtTSVInicio" ; RETURN "trabalhador"
   CASE cTag == "evtTSVAltContr" ; RETURN "trabalhador"
   CASE cTag == "evtTSVTermino" ; RETURN "trabalhador-indguia"
   CASE cTag == "evtCdBenefIn" ; RETURN "trabalhador-pj"
   CASE cTag == "evtCdBenefAlt" ; RETURN "trabalhador-pj"
   CASE cTag == "evtCdBenIn" ; RETURN "trabalhador-pj"
   CASE cTag == "evtCdBenAlt" ; RETURN "trabalhador-pj"
   CASE cTag == "evtReativBen" ; RETURN "trabalhador-pj"
   CASE cTag == "evtCdBenTerm" ; RETURN "trabalhador-pj"
   CASE cTag == "evtProcTrab" ; RETURN "trabalhador"
   CASE cTag == "evtContProc" ; RETURN "trabalhador"
   CASE cTag == "evtConsolidContProc" ; RETURN "exclusao-proc-trab"
   CASE cTag == "evtExclusao" ; RETURN "exclusao"
   CASE cTag == "evtExcProcTrab" ; RETURN "exclusao-proc-trab"
   CASE cTag == "evtBasesTrab" ; RETURN "retorno-contrib"
   CASE cTag == "evtIrrfBenef" ; RETURN "retorno"
   CASE cTag == "evtBasesFGTS" ; RETURN "retorno"
   CASE cTag == "evtCS" ; RETURN "retorno-contrib"
   CASE cTag == "evtIrrf" ; RETURN "retorno-mensal"
   CASE cTag == "evtFGTS" ; RETURN "retorno-contrib"
   CASE cTag == "evtTribProcTrab" ; RETURN "retorno"
   CASE cTag == "evtFGTSProcTrab" ; RETURN "retorno"
   CASE cTag == "evtAnotJud" ; RETURN "trab-jud"
   CASE cTag == "evtBaixa" ; RETURN "trab-jud"
   ENDCASE
RETURN ""

FUNCTION EsocialMemoWritUtf8( cArquivo, cTexto )
   LOCAL cOut := hb_DefaultValue( cTexto, "" )

   IF Empty( cOut )
      RETURN hb_MemoWrit( cArquivo, cOut )
   ENDIF

   IF hb_At( "<?xml", cOut ) == 1 .AND. hb_At( "encoding=", Left( cOut, 100 ) ) == 0
      cOut := '<?xml version="1.0" encoding="UTF-8"?>' + hb_Eol() + cOut
   ENDIF
RETURN hb_MemoWrit( cArquivo, hb_StrToUTF8( cOut ) )

FUNCTION EsocialFirstEventName( cEventRoot )
   LOCAL nStart, nEnd, cTag
   nStart := hb_At( "><", cEventRoot )
   IF nStart == 0
      RETURN ""
   ENDIF
   nStart += 2
   nEnd := hb_At( " ", cEventRoot, nStart )
   IF nEnd == 0
      nEnd := hb_At( ">", cEventRoot, nStart )
   ENDIF
   cTag := SubStr( cEventRoot, nStart, nEnd - nStart )
RETURN AllTrim( cTag )

FUNCTION EsocialEventId( cEventRoot, cEventName )
   LOCAL nStart, nEnd, cOpen
   cOpen := "<" + cEventName
   nStart := hb_At( cOpen, cEventRoot )
   IF nStart == 0
      RETURN ""
   ENDIF
   nStart := hb_At( 'Id="', cEventRoot, nStart )
   IF nStart == 0
      RETURN ""
   ENDIF
   nStart += 4
   nEnd := hb_At( '"', cEventRoot, nStart )
RETURN SubStr( cEventRoot, nStart, nEnd - nStart )

FUNCTION EsocialCanonicalEvent( cEventRoot, cEventName )
   LOCAL nStart, nEnd, cEvent, cNs
   nStart := hb_At( "<" + cEventName, cEventRoot )
   nEnd := hb_At( "</" + cEventName + ">", cEventRoot, nStart )
   IF nStart == 0 .OR. nEnd == 0
      RETURN ""
   ENDIF
   nEnd += Len( "</" + cEventName + ">" ) - 1
   cEvent := SubStr( cEventRoot, nStart, nEnd - nStart + 1 )
   IF ! 'xmlns="' $ Left( cEvent, hb_At( ">", cEvent ) )
      cNs := EsocialNamespace( cEventRoot )
      cEvent := Stuff( cEvent, Len( "<" + cEventName ) + 1, 0, ' xmlns="' + cNs + '"' )
   ENDIF
RETURN cEvent

FUNCTION EsocialNamespace( cXml )
   LOCAL nStart, nEnd
   nStart := hb_At( 'xmlns="', cXml )
   IF nStart == 0
      RETURN ""
   ENDIF
   nStart += 7
   nEnd := hb_At( '"', cXml, nStart )
RETURN SubStr( cXml, nStart, nEnd - nStart )

FUNCTION EsocialSignedInfoCanon( cReferenceUri, cDigest )
   LOCAL cXml
   cXml := '<SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#">'
   cXml += '<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"></CanonicalizationMethod>'
   cXml += '<SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"></SignatureMethod>'
   cXml += '<Reference URI="' + cReferenceUri + '">'
   cXml += '<Transforms>'
   cXml += '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"></Transform>'
   cXml += '<Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"></Transform>'
   cXml += '</Transforms>'
   cXml += '<DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"></DigestMethod>'
   cXml += '<DigestValue>' + cDigest + '</DigestValue>'
   cXml += '</Reference>'
   cXml += '</SignedInfo>'
RETURN cXml

FUNCTION EsocialSignedInfoNode( cReferenceUri, cDigest )
   LOCAL cXml
   cXml := '<SignedInfo>'
   cXml += '<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>'
   cXml += '<SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>'
   cXml += '<Reference URI="' + cReferenceUri + '">'
   cXml += '<Transforms>'
   cXml += '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>'
   cXml += '<Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>'
   cXml += '</Transforms>'
   cXml += '<DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>'
   cXml += '<DigestValue>' + cDigest + '</DigestValue>'
   cXml += '</Reference>'
   cXml += '</SignedInfo>'
RETURN cXml

FUNCTION EsocialSignatureNode( cReferenceUri, cDigest, cSignature, cCert )
RETURN '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">' + EsocialSignedInfoNode( cReferenceUri, cDigest ) + '<SignatureValue>' + cSignature + '</SignatureValue><KeyInfo><X509Data><X509Certificate>' + cCert + '</X509Certificate></X509Data></KeyInfo></Signature>'

FUNCTION EsocialOneLineBase64( cText )
RETURN StrTran( StrTran( AllTrim( cText ), Chr( 13 ), "" ), Chr( 10 ), "" )

FUNCTION EsocialHexToBin( cHex )
   LOCAL cBin := "", nI
   FOR nI := 1 TO Len( cHex ) STEP 2
      cBin += Chr( hb_HexToNum( SubStr( cHex, nI, 2 ) ) )
   NEXT
RETURN cBin

FUNCTION EsocialNovoId()
   LOCAL cBase
   cBase := DToS( Date() ) + StrTran( Time(), ":", "" ) + Right( StrZero( hb_RandomInt( 0, 999999999 ), 9 ), 9 )
RETURN "ID" + PadR( cBase, 34, "0" )

FUNCTION EsocialNovoIdEvento( cTpInsc, cNrInsc )
   LOCAL cInsc, cSeq
   cInsc := SoNumeroCnpj( cNrInsc )
   IF AllTrim( cTpInsc ) == "1"
      cInsc := Left( cInsc, 8 ) + "000000"
   ELSE
      cInsc := Left( cInsc, 11 ) + "000"
   ENDIF
   cSeq := Right( StrZero( hb_RandomInt( 1, 99999 ), 5 ), 5 )
RETURN "ID" + AllTrim( cTpInsc ) + cInsc + DToS( Date() ) + StrTran( Time(), ":", "" ) + cSeq

FUNCTION EsocialXmlEscape( cText )
   cText := hb_DefaultValue( cText, "" )
   cText := StrTran( cText, "&", "&amp;" )
   cText := StrTran( cText, '"', "&quot;" )
   cText := StrTran( cText, "'", "&apos;" )
   cText := StrTran( cText, "<", "&lt;" )
   cText := StrTran( cText, ">", "&gt;" )
RETURN cText

FUNCTION EsocialNrInscEmpregador( cTpInsc, cNrInsc )
   cNrInsc := SoNumeroCnpj( cNrInsc )
   IF AllTrim( cTpInsc ) == "1" .AND. Len( cNrInsc ) > 8
      RETURN Left( cNrInsc, 8 )
   ENDIF
RETURN cNrInsc

FUNCTION OnlyDigits( cText )
   Local cSoNumeros:= [], cChar

   For EACH cChar IN cText
       If cChar $ "0123456789"
          cSoNumeros += cChar
       EndIf
   Next
RETURN cSoNumeros

FUNCTION DateXml(dDate)
Return (Transf(Dtos(dDate), "@R 9999-99-99"))

FUNCTION SoNumeroCnpj(cTxt)
   Local cSoNumeros:= [], cChar

   For EACH cChar IN cTxt
       If (cChar >= "0" .and. cChar <= "9") .or. (cChar >= "A" .and. cChar <= "Z")
          cSoNumeros += cChar
       EndIf
   Next
Return (cSoNumeros)

Static Function CertNativeToken(cDados, nToken)
   Local nPos:= 1, nStart:= 1, nAtual:= 1

   Do While nAtual < nToken
      nPos:= At(Chr(9), SubStr(cDados, nStart))
      If nPos == 0
         Return []
      Endif
      nStart += nPos
      nAtual++
   Enddo

   nPos:= At(Chr(9), SubStr(cDados, nStart))
   If nPos == 0
      Return SubStr(cDados, nStart)
   Endif
Return SubStr(cDados, nStart, nPos - 1)

#pragma BEGINDUMP

#include "hbapi.h"
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <wincrypt.h>
#include <ctype.h>
#include <string.h>

#ifdef _MSC_VER
#pragma comment( lib, "advapi32.lib" )
#pragma comment( lib, "crypt32.lib" )
#pragma comment( lib, "cryptui.lib" )
#endif

#ifndef CRYPT_STRING_NOCRLF
#define CRYPT_STRING_NOCRLF 0x40000000
#endif

PCCERT_CONTEXT WINAPI CryptUIDlgSelectCertificateFromStore(
   HCERTSTORE hCertStore,
   HWND hwnd,
   LPCWSTR pwszTitle,
   LPCWSTR pwszDisplayString,
   DWORD dwDontUseColumn,
   DWORD dwFlags,
   void * pvReserved );

static void nfse_hex_from_blob_reversed( const BYTE * pData, DWORD cbData, char * out )
{
   static const char * hex = "0123456789ABCDEF";
   DWORD i, j = 0;

   for( i = cbData; i > 0; --i )
   {
      BYTE b = pData[ i - 1 ];
      out[ j++ ] = hex[ ( b >> 4 ) & 0x0F ];
      out[ j++ ] = hex[ b & 0x0F ];
   }
   out[ j ] = '\0';
}

static void nfse_hex_from_blob_direct( const BYTE * pData, DWORD cbData, char * out )
{
   static const char * hex = "0123456789ABCDEF";
   DWORD i, j = 0;

   for( i = 0; i < cbData; ++i )
   {
      BYTE b = pData[ i ];
      out[ j++ ] = hex[ ( b >> 4 ) & 0x0F ];
      out[ j++ ] = hex[ b & 0x0F ];
   }
   out[ j ] = '\0';
}

static void nfse_normalize_serial( const char * in, char * out, DWORD outSize )
{
   DWORD j = 0;

   while( *in && j + 1 < outSize )
   {
      unsigned char ch = ( unsigned char ) *in++;
      if( isxdigit( ch ) )
         out[ j++ ] = ( char ) toupper( ch );
   }
   out[ j ] = '\0';
}

static void nfse_return_last_error( const char * prefix )
{
   char msg[ 128 ];
   wsprintfA( msg, "%s WindowsError=%lu", prefix, GetLastError() );
   hb_retc( msg );
}

static void nfse_filetime_to_yyyymmdd( const FILETIME * ft, char * out )
{
   SYSTEMTIME st;
   FileTimeToSystemTime( ft, &st );
   wsprintfA( out, "%04u%02u%02u", st.wYear, st.wMonth, st.wDay );
}

static void nfse_append_field( char * out, DWORD outSize, const char * value, BOOL withTab )
{
   if( value )
      lstrcatA( out, value );
   if( withTab )
      lstrcatA( out, "\t" );
}

HB_FUNC( SELECIONARCERTIFICADONATIVE )
{
   HCERTSTORE hStore = NULL;
   PCCERT_CONTEXT pCert = NULL;
   DWORD needed = 0;
   char subject[ 1024 ];
   char issuer[ 1024 ];
   char validFrom[ 16 ];
   char validTo[ 16 ];
   char thumb[ 128 ];
   char serial[ 256 ];
   char version[ 16 ];
   char archived[ 2 ];
   BYTE hash[ 64 ];
   DWORD hashLen = sizeof( hash );
   char result[ 4096 ];

   subject[ 0 ] = issuer[ 0 ] = validFrom[ 0 ] = validTo[ 0 ] = '\0';
   thumb[ 0 ] = serial[ 0 ] = version[ 0 ] = archived[ 0 ] = result[ 0 ] = '\0';

   hStore = CertOpenStore( CERT_STORE_PROV_SYSTEM_A, 0, 0,
                           CERT_SYSTEM_STORE_CURRENT_USER | CERT_STORE_READONLY_FLAG, "MY" );
   if( ! hStore )
   {
      nfse_return_last_error( "ERRO_CERTIFICADO: nao foi possivel abrir o repositorio MY." );
      return;
   }

   pCert = CryptUIDlgSelectCertificateFromStore( hStore, NULL,
                                                 L"Selecione o certificado para uso da NFS-e",
                                                 L"Selecione o certificado digital",
                                                 0, 0, NULL );
   if( ! pCert )
   {
      CertCloseStore( hStore, 0 );
      hb_retc( "ERRO_CERTIFICADO: certificado nao selecionado." );
      return;
   }

   CertNameToStrA( X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
                   &pCert->pCertInfo->Subject,
                   CERT_X500_NAME_STR | CERT_NAME_STR_REVERSE_FLAG,
                   subject, sizeof( subject ) );

   CertNameToStrA( X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
                   &pCert->pCertInfo->Issuer,
                   CERT_X500_NAME_STR | CERT_NAME_STR_REVERSE_FLAG,
                   issuer, sizeof( issuer ) );

   nfse_filetime_to_yyyymmdd( &pCert->pCertInfo->NotBefore, validFrom );
   nfse_filetime_to_yyyymmdd( &pCert->pCertInfo->NotAfter, validTo );

   if( CertGetCertificateContextProperty( pCert, CERT_HASH_PROP_ID, hash, &hashLen ) )
      nfse_hex_from_blob_direct( hash, hashLen, thumb );

   nfse_hex_from_blob_reversed( pCert->pCertInfo->SerialNumber.pbData,
                                pCert->pCertInfo->SerialNumber.cbData,
                                serial );

   wsprintfA( version, "%lu", pCert->pCertInfo->dwVersion + 1 );

   needed = 0;
   archived[ 0 ] = CertGetCertificateContextProperty( pCert, CERT_ARCHIVED_PROP_ID, NULL, &needed ) ? '1' : '0';
   archived[ 1 ] = '\0';

   nfse_append_field( result, sizeof( result ), subject, TRUE );
   nfse_append_field( result, sizeof( result ), issuer, TRUE );
   nfse_append_field( result, sizeof( result ), validFrom, TRUE );
   nfse_append_field( result, sizeof( result ), validTo, TRUE );
   nfse_append_field( result, sizeof( result ), thumb, TRUE );
   nfse_append_field( result, sizeof( result ), serial, TRUE );
   nfse_append_field( result, sizeof( result ), version, TRUE );
   nfse_append_field( result, sizeof( result ), archived, FALSE );

   hb_retc( result );

   CertFreeCertificateContext( pCert );
   CertCloseStore( hStore, 0 );
}

HB_FUNC( LERCERTIFICADOPFXNATIVE )
{
   const char * fileName = hb_parc( 1 );
   const char * password = hb_parc( 2 );
   HANDLE hFile = INVALID_HANDLE_VALUE;
   DWORD fileSize = 0;
   DWORD bytesRead = 0;
   BYTE * fileData = NULL;
   CRYPT_DATA_BLOB pfxBlob;
   WCHAR wPassword[ 512 ];
   HCERTSTORE hPfxStore = NULL;
   PCCERT_CONTEXT pCert = NULL;
   DWORD needed = 0;
   char subject[ 1024 ];
   char issuer[ 1024 ];
   char validFrom[ 16 ];
   char validTo[ 16 ];
   char thumb[ 128 ];
   char serial[ 256 ];
   char version[ 16 ];
   char archived[ 2 ];
   BYTE hash[ 64 ];
   DWORD hashLen = sizeof( hash );
   char result[ 4096 ];

   if( ! fileName || ! *fileName )
   {
      hb_retc( "ERRO_PFX: arquivo PFX nao informado." );
      return;
   }

   subject[ 0 ] = issuer[ 0 ] = validFrom[ 0 ] = validTo[ 0 ] = '\0';
   thumb[ 0 ] = serial[ 0 ] = version[ 0 ] = archived[ 0 ] = result[ 0 ] = '\0';

   hFile = CreateFileA( fileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL );
   if( hFile == INVALID_HANDLE_VALUE )
   {
      nfse_return_last_error( "ERRO_PFX: nao foi possivel abrir o arquivo." );
      return;
   }

   fileSize = GetFileSize( hFile, NULL );
   if( fileSize == INVALID_FILE_SIZE || fileSize == 0 )
   {
      CloseHandle( hFile );
      hb_retc( "ERRO_PFX: arquivo PFX vazio ou invalido." );
      return;
   }

   fileData = ( BYTE * ) hb_xgrab( fileSize );
   if( ! ReadFile( hFile, fileData, fileSize, &bytesRead, NULL ) || bytesRead != fileSize )
   {
      hb_xfree( fileData );
      CloseHandle( hFile );
      nfse_return_last_error( "ERRO_PFX: falha ao ler o arquivo." );
      return;
   }
   CloseHandle( hFile );

   pfxBlob.cbData = fileSize;
   pfxBlob.pbData = fileData;

   MultiByteToWideChar( CP_ACP, 0, password ? password : "", -1, wPassword, sizeof( wPassword ) / sizeof( WCHAR ) );

   hPfxStore = PFXImportCertStore( &pfxBlob, wPassword, 0 );
   hb_xfree( fileData );

   if( ! hPfxStore )
   {
      nfse_return_last_error( "ERRO_PFX: senha invalida ou falha ao importar PFX em memoria." );
      return;
   }

   pCert = CertEnumCertificatesInStore( hPfxStore, NULL );
   if( ! pCert )
   {
      CertCloseStore( hPfxStore, 0 );
      hb_retc( "ERRO_PFX: nenhum certificado encontrado no PFX." );
      return;
   }

   CertNameToStrA( X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
                   &pCert->pCertInfo->Subject,
                   CERT_X500_NAME_STR | CERT_NAME_STR_REVERSE_FLAG,
                   subject, sizeof( subject ) );

   CertNameToStrA( X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
                   &pCert->pCertInfo->Issuer,
                   CERT_X500_NAME_STR | CERT_NAME_STR_REVERSE_FLAG,
                   issuer, sizeof( issuer ) );

   nfse_filetime_to_yyyymmdd( &pCert->pCertInfo->NotBefore, validFrom );
   nfse_filetime_to_yyyymmdd( &pCert->pCertInfo->NotAfter, validTo );

   if( CertGetCertificateContextProperty( pCert, CERT_HASH_PROP_ID, hash, &hashLen ) )
      nfse_hex_from_blob_direct( hash, hashLen, thumb );

   nfse_hex_from_blob_reversed( pCert->pCertInfo->SerialNumber.pbData,
                                pCert->pCertInfo->SerialNumber.cbData,
                                serial );

   wsprintfA( version, "%lu", pCert->pCertInfo->dwVersion + 1 );

   needed = 0;
   archived[ 0 ] = CertGetCertificateContextProperty( pCert, CERT_ARCHIVED_PROP_ID, NULL, &needed ) ? '1' : '0';
   archived[ 1 ] = '\0';

   nfse_append_field( result, sizeof( result ), subject, TRUE );
   nfse_append_field( result, sizeof( result ), issuer, TRUE );
   nfse_append_field( result, sizeof( result ), validFrom, TRUE );
   nfse_append_field( result, sizeof( result ), validTo, TRUE );
   nfse_append_field( result, sizeof( result ), thumb, TRUE );
   nfse_append_field( result, sizeof( result ), serial, TRUE );
   nfse_append_field( result, sizeof( result ), version, TRUE );
   nfse_append_field( result, sizeof( result ), archived, FALSE );

   hb_retc( result );

   CertCloseStore( hPfxStore, 0 );
}

HB_FUNC( ASSINARRPSSPNATIVE )
{
   const char * serialParam = hb_parc( 1 );
   const BYTE * textParam   = ( const BYTE * ) hb_parc( 2 );
   DWORD textLen            = ( DWORD ) hb_parclen( 2 );
   char serialBusca[ 128 ];
   HCERTSTORE hStore = NULL;
   PCCERT_CONTEXT pCert = NULL;
   PCCERT_CONTEXT pFound = NULL;
   HCRYPTPROV hKey = 0;
   DWORD dwKeySpec = 0;
   BOOL mustFreeKey = FALSE;
   HCRYPTHASH hHash = 0;
   BYTE * sig = NULL;
   DWORD sigLen = 0;
   char * base64 = NULL;
   DWORD base64Len = 0;
   DWORD i;

   if( ! serialParam || ! *serialParam || ! textParam )
   {
      hb_retc( "ERRO_ASSINATURA_RPS: parametros invalidos." );
      return;
   }

   nfse_normalize_serial( serialParam, serialBusca, sizeof( serialBusca ) );

   hStore = CertOpenStore( CERT_STORE_PROV_SYSTEM_A, 0, 0,
                           CERT_SYSTEM_STORE_CURRENT_USER | CERT_STORE_READONLY_FLAG, "MY" );
   if( ! hStore )
   {
      nfse_return_last_error( "ERRO_ASSINATURA_RPS: nao foi possivel abrir o repositorio MY." );
      return;
   }

   while( ( pCert = CertEnumCertificatesInStore( hStore, pCert ) ) != NULL )
   {
      DWORD cbSerial = pCert->pCertInfo->SerialNumber.cbData;
      char serialRev[ 256 ];
      char serialDir[ 256 ];

      if( cbSerial * 2 + 1 > sizeof( serialRev ) )
         continue;

      nfse_hex_from_blob_reversed( pCert->pCertInfo->SerialNumber.pbData, cbSerial, serialRev );
      nfse_hex_from_blob_direct( pCert->pCertInfo->SerialNumber.pbData, cbSerial, serialDir );

      if( strcmp( serialBusca, serialRev ) == 0 || strcmp( serialBusca, serialDir ) == 0 )
      {
         pFound = CertDuplicateCertificateContext( pCert );
         break;
      }
   }

   if( ! pFound )
   {
      CertCloseStore( hStore, 0 );
      hb_retc( "ERRO_ASSINATURA_RPS: certificado nao encontrado pelo serial." );
      return;
   }

   if( ! CryptAcquireCertificatePrivateKey( pFound, 0, NULL, &hKey, &dwKeySpec, &mustFreeKey ) )
   {
      CertFreeCertificateContext( pFound );
      CertCloseStore( hStore, 0 );
      nfse_return_last_error( "ERRO_ASSINATURA_RPS: nao foi possivel obter a chave privada." );
      return;
   }

   if( ! CryptCreateHash( ( HCRYPTPROV ) hKey, CALG_SHA1, 0, 0, &hHash ) )
   {
      if( mustFreeKey ) CryptReleaseContext( ( HCRYPTPROV ) hKey, 0 );
      CertFreeCertificateContext( pFound );
      CertCloseStore( hStore, 0 );
      nfse_return_last_error( "ERRO_ASSINATURA_RPS: CryptCreateHash falhou." );
      return;
   }

   if( ! CryptHashData( hHash, textParam, textLen, 0 ) )
   {
      CryptDestroyHash( hHash );
      if( mustFreeKey ) CryptReleaseContext( ( HCRYPTPROV ) hKey, 0 );
      CertFreeCertificateContext( pFound );
      CertCloseStore( hStore, 0 );
      nfse_return_last_error( "ERRO_ASSINATURA_RPS: CryptHashData falhou." );
      return;
   }

   if( ! CryptSignHashA( hHash, dwKeySpec, NULL, 0, NULL, &sigLen ) )
   {
      CryptDestroyHash( hHash );
      if( mustFreeKey ) CryptReleaseContext( ( HCRYPTPROV ) hKey, 0 );
      CertFreeCertificateContext( pFound );
      CertCloseStore( hStore, 0 );
      nfse_return_last_error( "ERRO_ASSINATURA_RPS: CryptSignHash tamanho falhou." );
      return;
   }

   sig = ( BYTE * ) hb_xgrab( sigLen );
   if( ! CryptSignHashA( hHash, dwKeySpec, NULL, 0, sig, &sigLen ) )
   {
      hb_xfree( sig );
      CryptDestroyHash( hHash );
      if( mustFreeKey ) CryptReleaseContext( ( HCRYPTPROV ) hKey, 0 );
      CertFreeCertificateContext( pFound );
      CertCloseStore( hStore, 0 );
      nfse_return_last_error( "ERRO_ASSINATURA_RPS: CryptSignHash falhou." );
      return;
   }

   /* CryptoAPI retorna assinatura RSA little-endian; .NET RSAPKCS1 retorna big-endian. */
   for( i = 0; i < sigLen / 2; ++i )
   {
      BYTE tmp = sig[ i ];
      sig[ i ] = sig[ sigLen - 1 - i ];
      sig[ sigLen - 1 - i ] = tmp;
   }

   if( ! CryptBinaryToStringA( sig, sigLen, CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF, NULL, &base64Len ) )
   {
      hb_xfree( sig );
      CryptDestroyHash( hHash );
      if( mustFreeKey ) CryptReleaseContext( ( HCRYPTPROV ) hKey, 0 );
      CertFreeCertificateContext( pFound );
      CertCloseStore( hStore, 0 );
      nfse_return_last_error( "ERRO_ASSINATURA_RPS: CryptBinaryToString tamanho falhou." );
      return;
   }

   base64 = ( char * ) hb_xgrab( base64Len + 1 );
   if( ! CryptBinaryToStringA( sig, sigLen, CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF, base64, &base64Len ) )
   {
      hb_xfree( base64 );
      hb_xfree( sig );
      CryptDestroyHash( hHash );
      if( mustFreeKey ) CryptReleaseContext( ( HCRYPTPROV ) hKey, 0 );
      CertFreeCertificateContext( pFound );
      CertCloseStore( hStore, 0 );
      nfse_return_last_error( "ERRO_ASSINATURA_RPS: CryptBinaryToString falhou." );
      return;
   }

   hb_retc( base64 );

   hb_xfree( base64 );
   hb_xfree( sig );
   CryptDestroyHash( hHash );
   if( mustFreeKey ) CryptReleaseContext( ( HCRYPTPROV ) hKey, 0 );
   CertFreeCertificateContext( pFound );
   CertCloseStore( hStore, 0 );
}

#pragma ENDDUMP