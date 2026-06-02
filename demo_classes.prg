/*****************************************************************************
 * SISTEMA  : ROTINA EVENTUAL                                                *
 * PROGRAMA : DEMO_CLASSES.PRG                                               *
 * OBJETIVO : Gerar, Assinar e Enviar Arquivos do eSocial                    *
 * AUTOR    : Franklin Brasil                                                *
 * ALTERADO : Marcelo Antonio Lazzaro Carli                                  *
 * DATA     : 29.05.2026                                                     *
 * ULT. ALT.: 02.06.2026                                                     *
 *****************************************************************************/

* para testar descomente individualmente cada evento

PROCEDURE Main()
   LOCAL oConfig, oClient, oSigner, oLote
   LOCAL oS2210A, oS2220A, oS2220B, oS2221A, oS2221B, oS2240A, oS3000A, oS3000B, cEvento, cEventoAssinado
   LOCAL cRet, cProtocolo, cConsulta
   LOCAL aEventosAssinados := {}

   Set Date Briti             &&& data no formato dd/mm/aaaa
   Set Dele On                &&& ignora registros marcados por deleção
   Set Score Off
   Set Exact On
   Setcancel(.F.)             &&& evitar cancelar sistema c/ ALT + C
   Set Cent On                &&& ano com 4 dígitos
   Set Epoch to 2000          &&& ano a partir de 2000

*  oConfig := TEsocialConfig():New():UseMockLocal()
*  oConfig := TEsocialConfig():New():UseProducaoRestrita()
   oConfig := TEsocialConfig():New():UseProducao()
   oConfig:SetCertName( "MEDICINA DO TRABALHO LTDA:12345678901234" )

   oClient := TEsocialClient():New( oConfig )
   oSigner := TEsocialSigner():New( oConfig )
   oSigner:SetSubject( "12345678901234" )                 // Pode enviar assim tb 12.345.678/9012-34

   oLote := TEsocialLote():New( "99999999999999", "2" )   // Pode enviar assim tb 99.999.999/9999-99
   oLote:SetEmpregador( "1", "99.999.999/9999-99" )       // Pode enviar assim tb 99999999999999
   oLote:SetTransmissor( "1", "12345678901234" )          // Pode enviar assim tb 12.345.678/9012-34

   *********** S2210 Comunicação de Acidente de Trabalho ******************************************
   oS2210A := TEsocialEventoS2210():New()
   oS2210A:SetAmbiente( "2" )
   oS2210A:SetEmpregador( "1", "99999999999999" )         // Pode enviar assim tb 99.999.999/9999-99
   oS2210A:SetTrabalhador( "12243410826", "32", "" )      // Pode enviar assim tb 122.434.108-26
   oS2210A:SetAcidente( Ctod("01/06/2026"), "1", "0800", "0100", "1", "N", "N", "200004300", "1", "", Ctod("01/06/2026"), "N", Nil )
   oS2210A:SetLocalAcidente( "1", "Setor administrativo", "", "RUA TESTE", "100", "", "CENTRO", "17500000", "3529005", "SP", "", "", "1", "99999999999999" )
   oS2210A:SetParteAtingida( "753030000", "0" )
   oS2210A:SetAgenteCausador( "303075200" )
   oS2210A:SetAtestado( Ctod("01/06/2026"), "0900", "N", "1", "N", "702070000", "Z00", "Dr. Pimpolho", "1", "123456", "SP", "", "", "" )

   cEvento := oS2210A:ToXml()
   cEventoAssinado := oSigner:AssinarXml( cEvento )
   IF Empty( cEventoAssinado )
      hb_MemoWrit( "demo_classes.log", "ERRO assinatura S-2210: " + EsocialCryptoLastError() + hb_Eol() )
      RETURN
   ENDIF
   AAdd( aEventosAssinados, cEventoAssinado )

   hb_MemoWrit( "evento_s2210.xml", cEvento )
   hb_MemoWrit( "evento_s2210_assinado.xml", cEventoAssinado)
/*
   *********** S2220 Monitoramento de Saúde do Trabalhador ****************************************
   * Funcionario A *
   oS2220A := TEsocialEventoS2220():New()
   oS2220A:SetAmbiente( "2" )
   oS2220A:SetEmpregador( "1", "99999999999999" )         // Pode enviar assim tb 99.999.999/9999-99
   oS2220A:SetTrabalhador( "12243410826", "32", "" )      // Pode enviar assim tb 122.434.108-26
   oS2220A:SetAso( Ctod("29/05/2026"), "1", "1" )
   oS2220A:SetExame( Ctod("29/05/2026"), "0295", "1", "", "" )
   oS2220A:AddExame( Ctod("29/05/2026"), "0974", "1", "", "" ) // 1:N
   oS2220A:SetMedico( "Sicrano de Tal", "123456", "SP" )
   oS2220A:SetRespMonit( "Dr. Pimpolho", "987654", "SP", "" )

   cEvento := oS2220A:ToXml()
   cEventoAssinado := oSigner:AssinarXml( cEvento )
   IF Empty( cEventoAssinado )
      hb_MemoWrit( "demo_classes.log", "ERRO assinatura funcionario A: " + EsocialCryptoLastError() + hb_Eol() )
      RETURN
   ENDIF
   AAdd( aEventosAssinados, cEventoAssinado )

   * Funcionario B *
   oS2220B := TEsocialEventoS2220():New()
   oS2220B:SetAmbiente( "2" )
   oS2220B:SetEmpregador( "1", "99.999.999/9999-99" )            // Pode enviar assim tb 99999999999999
   oS2220B:SetTrabalhador( "408.279.418-20", "36", "" )          // Pode enviar assim tb 40827941820
   oS2220B:SetAso( Ctod("28/05/2026"), "1", "1" )
   oS2220B:SetExame( Ctod("28/05/2026"), "0295", "1", "", "" )
   oS2220B:AddExame( Ctod("28/05/2026"), "0234", "1", "", "" )
   oS2220B:AddExame( Ctod("28/05/2026"), "0693", "1", "", "" )
   oS2220B:SetMedico( "Fulano de Tal", "123456", "SP" )
   oS2220B:SetRespMonit( "Dr. Pimpolho", "987654", "SP", "" )

   cEvento := oS2220B:ToXml()
   cEventoAssinado := oSigner:AssinarXml( cEvento )
   IF Empty( cEventoAssinado )
      hb_MemoWrit( "demo_classes.log", "ERRO assinatura funcionario B: " + EsocialCryptoLastError() + hb_Eol() )
      RETURN
   ENDIF
   AAdd( aEventosAssinados, cEventoAssinado )

   hb_MemoWrit( "evento_s2220.xml", oS2220A:ToXml() + oS2220B:ToXml() )
   hb_MemoWrit( "evento_s2220_assinado.xml", aEventosAssinados[ 1 ] + aEventosAssinados[ 2 ] )

   *********** S2221 Exame Toxicológico do Motorista Profissional Empregado ***********************
   * Funcionario A *
   oS2221A := TEsocialEventoS2221():New()
   oS2221A:SetAmbiente( "2" )
   oS2221A:SetEmpregador( "1", "99999999999999" )                                  // Pode enviar assim tb 99.999.999/9999-99
   oS2221A:SetTrabalhador( "12243410826", "32", "" )                               // Pode enviar assim tb 122.434.108-26
   oS2221A:SetMedico( "Fulano de Tal", "123456", "SP" )
   oS2221A:SetEventoToxico( Ctod("01/06/2026"), "68467240000134", "DD111111111" )  // Pode enviar assim tb 68.467.240/0001-34

   cEvento := oS2221A:ToXml()
   cEventoAssinado := oSigner:AssinarXml( cEvento )
   IF Empty( cEventoAssinado )
      hb_MemoWrit( "demo_classes.log", "ERRO assinatura S-2221: " + EsocialCryptoLastError() + hb_Eol() )
      RETURN
   ENDIF
   AAdd( aEventosAssinados, cEventoAssinado )

   * Funcionario B *
   oS2221B := TEsocialEventoS2221():New()
   oS2221B:SetAmbiente( "2" )
   oS2221B:SetEmpregador( "1", "99.999.999/9999-99" )                                 // Pode enviar assim tb 99999999999999
   oS2221B:SetTrabalhador( "408.279.418-20", "36", "" )                               // Pode enviar assim tb 99999999999999
   oS2221B:SetMedico( "Sicrano de Tal", "999999", "SP" )
   oS2221B:SetEventoToxico( Ctod("02/06/2026"), "68.467.240/0001-34", "DD222222222" ) // Pode enviar assim tb 68467240000134

   cEvento := oS2221B:ToXml()
   cEventoAssinado := oSigner:AssinarXml( cEvento )
   IF Empty( cEventoAssinado )
      hb_MemoWrit( "demo_classes.log", "ERRO assinatura funcionario B: " + EsocialCryptoLastError() + hb_Eol() )
      RETURN
   ENDIF
   AAdd( aEventosAssinados, cEventoAssinado )

   hb_MemoWrit( "evento_s2221.xml", oS2221A:ToXml() + oS2221B:ToXml() )
   hb_MemoWrit( "evento_s2221_assinado.xml", aEventosAssinados[ 1 ] + aEventosAssinados[ 2 ] )

   *********** S2240 Condições Ambientais do Trabalho - Agentes Nocivos ***************************
   oS2240A := TEsocialEventoS2240():New()
   oS2240A:SetAmbiente( "2" )
   oS2240A:SetEmpregador( "1", "99999999999999" )
   oS2240A:SetTrabalhador( "12243410826", "32", "" )
   oS2240A:SetCondicao( Ctod("01/06/2026"), Nil )
   oS2240A:SetAmbienteTrabalho( "1", "SETOR ADMINISTRATIVO", "1", "99999999999999" )
   oS2240A:SetAtividade( "Executar atividades administrativas." )
   oS2240A:SetAgente( "09.01.001", "", "", "", "", "", "", "", "", "", "", "" )
   oS2240A:SetRespReg( "12243410826", "", "", "", "" )

   cEvento := oS2240A:ToXml()
   hb_MemoWrit( "evento_s2240.xml", cEvento )
   cEventoAssinado := oSigner:AssinarXml( cEvento )
   IF Empty( cEventoAssinado )
      hb_MemoWrit( "demo_classes.log", "ERRO assinatura S-2240: " + EsocialCryptoLastError() + hb_Eol() )
      RETURN
   ENDIF
   AAdd( aEventosAssinados, cEventoAssinado )

   *********** S3000 Exclusão de Eventos **********************************************************
   * Funcionario A *
   oS3000A := TEsocialEventoS3000():New()
   oS3000A:SetAmbiente( "2" )
   oS3000A:SetEmpregador( "1", "99999999999999" )       // Pode enviar assim tb 99.999.999/9999-99
   oS3000A:SetTrabalhador( "12243410826", "", "" )      // Pode enviar assim tb 122.434.108-26
   oS3000A:SetEventoExcluido( "S-2220", "1.1.0000000041171700438" )

   cEvento := oS3000A:ToXml()
   cEventoAssinado := oSigner:AssinarXml( cEvento )
   IF Empty( cEventoAssinado )
      hb_MemoWrit( "demo_classes.log", "ERRO assinatura S-3000: " + EsocialCryptoLastError() + hb_Eol() )
      RETURN
   ENDIF
   AAdd( aEventosAssinados, cEventoAssinado )

   * Funcionario B *
   oS3000B := TEsocialEventoS3000():New()
   oS3000B:SetAmbiente( "2" )
   oS3000B:SetEmpregador( "1", "07.074.096/000-181" )       // Pode enviar assim tb 99999999999999
   oS3000B:SetTrabalhador( "408.279.418-20", "", "" )       // Pode enviar assim tb 40827941820
   oS3000B:SetEventoExcluido( "S-2220", "1.1.0000000041171701896" )

   cEvento := oS3000B:ToXml()
   cEventoAssinado := oSigner:AssinarXml( cEvento )
   IF Empty( cEventoAssinado )
      hb_MemoWrit( "demo_classes.log", "ERRO assinatura funcionario B: " + EsocialCryptoLastError() + hb_Eol() )
      RETURN
   ENDIF
   AAdd( aEventosAssinados, cEventoAssinado )

   hb_MemoWrit( "evento_s3000.xml", oS3000A:ToXml() + oS3000B:ToXml() )
   hb_MemoWrit( "evento_s3000_assinado.xml", aEventosAssinados[ 1 ] + aEventosAssinados[ 2 ] )
*/
   oLote:Salvar( aEventosAssinados, "Assinado.xml-esocial-loteevt.xml" )
   cRet := oClient:EnviarLoteAssinado( "Assinado.xml-esocial-loteevt.xml" )
   cProtocolo := EsocialExtrairTag( cRet, "protocoloEnvio" )

   IF ! Empty( cProtocolo )
      cConsulta := oClient:ConsultarLote( cProtocolo )
      hb_MemoWrit( "demo_classes.log", "OK envio: " + cProtocolo + hb_Eol() + Left( cConsulta, 200 ) + hb_Eol() )
      ? "OK envio: " + cProtocolo
      ? Left( cConsulta, 120 )
      wait
   ELSE
      hb_MemoWrit( "demo_classes.log", "Falhou envio" + hb_Eol() + cRet + hb_Eol() )
      ? "Falhou envio"
      ? cRet
      wait
   ENDIF
RETURN (Nil)