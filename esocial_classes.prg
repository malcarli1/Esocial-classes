/*****************************************************************************
 * SISTEMA  : ROTINA EVENTUAL                                                *
 * PROGRAMA : ESOCIAL_CLASSES.PRG                                            *
 * OBJETIVO : Gerar, Assinar e Enviar Arquivos do eSocial                    *
 * AUTOR    : Franklin Brasil                                                *
 * ALTERADO : Marcelo Antonio Lazzaro Carli                                  *
 * DATA     : 29.05.2026                                                     *
 * ULT. ALT.: 02.06.2026                                                     *
 *****************************************************************************/
#include "hbclass.ch"

#define ESOCIAL_URL_ENVIO_RESTRITA "https://webservices.producaorestrita.esocial.gov.br/servicos/empregador/enviarloteeventos/WsEnviarLoteEventos.svc"
#define ESOCIAL_URL_CONSULTA_RESTRITA "https://webservices.producaorestrita.esocial.gov.br/servicos/empregador/consultarloteeventos/WsConsultarLoteEventos.svc"
#define ESOCIAL_URL_ENVIO_PRODUCAO "https://webservices.envio.esocial.gov.br/servicos/empregador/enviarloteeventos/WsEnviarLoteEventos.svc"
#define ESOCIAL_URL_CONSULTA_PRODUCAO "https://webservices.consulta.esocial.gov.br/servicos/empregador/consultarloteeventos/WsConsultarLoteEventos.svc"
#define ESOCIAL_SOAP_ENVIO "http://www.esocial.gov.br/servicos/empregador/lote/eventos/envio/v1_1_0/ServicoEnviarLoteEventos/EnviarLoteEventos"
#define ESOCIAL_SOAP_CONSULTA "http://www.esocial.gov.br/servicos/empregador/lote/eventos/envio/consulta/retornoProcessamento/v1_1_0/ServicoConsultarLoteEventos/ConsultarLoteEventos"

CLASS TEsocialConfig
   VAR cEnvioUrl      AS Character INIT ""
   VAR cConsultaUrl   AS Character INIT ""
   VAR cCertName      AS Character INIT ""
   VAR lIgnoraErroSsl AS Logical   INIT .T.

   METHOD New()
   METHOD UseProducao()
   METHOD UseProducaoRestrita()
   METHOD UseMockLocal()
   METHOD SetCertName()         // cCertName 
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
   ::cNrCRM := AllTrim( cNrCRM )
   ::cUfCRM := Upper( AllTrim( cUfCRM ) )
RETURN Self

METHOD SetRespMonit( cNmResp, cNrCRM, cUfCRM, cCpfResp ) CLASS TEsocialEventoS2220
   ::cNmRespMonit := AllTrim( cNmResp )
   ::cNrCRMRespMonit := AllTrim( cNrCRM )
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
   IF ! Empty( ::cNrRecibo )
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
   VAR cTpEvento AS Character INIT "S-2220"
   VAR cNrRecEvt AS Character INIT "1.1.0000000099999999999"

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
   IF ! Empty( ::cNrRecibo )
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
   IF ! Empty( ::cNrRecibo )
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
   IF ! Empty( ::cNrRecibo )
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

CLASS TEsocialSigner
   VAR oConfig                  INIT NIL
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
      cOut := Left( cOut, nESocialStart - 1 ) + cEventRoot + SubStr( cOut, nESocialEnd + 1 )
      nESocialStart := hb_At( '<eSocial xmlns="http://www.esocial.gov.br/schema/evt/', cOut, nESocialStart + Len( cEventRoot ) )
   ENDDO
RETURN cOut

CLASS TEsocialClient
   VAR oConfig INIT NIL

   METHOD New()                // oConfig 
   METHOD EnviarLoteAssinado() // cArquivoXml 
   METHOD ConsultarLote()      // cProtocolo
   METHOD SoapEnvio()          // cXmlAssinado 
   METHOD SoapConsulta()       // cProtocolo 
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
