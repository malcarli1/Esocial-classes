# Esocial-classes

eSocial Bridge for Harbour 🚀
Uma biblioteca nativa e de alta performance desenvolvida em Harbour para geração, validação e assinatura digital dos eventos de SST (Saúde e Segurança do Trabalho) e demais obrigações do eSocial.

O grande diferencial deste projeto é a ponte criptográfica (esocial_crypto.prg), que realiza a assinatura digital SHA256 utilizando diretamente as APIs nativas do ecossistema Windows (CryptoAPI). Isso elimina completamente a dependência de executáveis externos (como OpenSSL via linha de comando ou utilitários de terceiros), garantindo maior velocidade, segurança e facilidade de distribuição do seu sistema.

✨ Principais Características
Ponte Criptográfica Nativa (esocial_crypto.prg): Assinatura digital padrão XML-DSIG usando a CryptoAPI do Windows (crypt32.dll / advapi32.dll) através de código C acoplado via #pragma BEGINDUMP.

Geração Automatizada de XML: Classes estruturadas que geram os Schemas XML rigorosamente dentro das regras e versões vigentes do eSocial (Ex: Evento S-2221 - Exame Toxicológico).

Abstração de Complexidade: Orientação a Objetos simples e intuitiva para preenchimento de informações do empregador, trabalhador e dados clínicos/laboratoriais.

Compatibilidade Total: Pronto para compilação com Harbour 3.2+ utilizando o compilador C Borland (bcc).

🛠️ Como Funciona? (Exemplo de Uso)
Integrar os eventos do eSocial ao seu sistema ERP se resume a poucas linhas de código:

Snippet de código

#include "hbclass.ch"

PROCEDURE Main()
   LOCAL oS2221, cXml
   
   // Instancia o evento S-2221 (Exame Toxicológico)
   
   oS2221 := TEsocialEventoS2221():New()
   
   oS2221:SetAmbiente( "2" ) // Produção Restrita
   
   oS2221:SetEmpregador( "1", "99999999999999" )
   
   oS2221:SetTrabalhador( "122434108269", "M12345", "101" )
   
   oS2221:SetMedico( "Dr. Marcelo Lazzaro", "999999", "SP" )
   
   oS2221:SetEventoToxico( "2026-06-02", "68467240000134", "TX12345678" )
   

   // Gera o XML bruto limpo
   
   cXml := oS2221:ToXml()
   
   // Pronto para passar pela esocial_crypto para assinatura digital!
   
   ? "XML gerado com sucesso!" 
   
RETURN

🏗️ Como Compilar
O projeto utiliza o gerenciador de compilação hbmk2 nativo do Harbour. Certifique-se de vincular as bibliotecas de sistema do Windows responsáveis pela criptografia:

Bash
@echo off
setlocal

set "PATH=C:\Borland\bcc58\Bin;C:\MiniGUI\Harbour\bin\bin;%PATH%"
set "HB_COMPILER=bcc"

:: Executa a compilação enviando a saída para o filtro FINDSTR, eliminando linhas que contenham "Warning"
C:\MiniGUI\Harbour\bin\hbmk2.exe demo_classes.prg esocial_classes.prg esocial_crypto.prg -comp=bcc -lhbwin -LC:\Borland\bcc58\Lib\PSDK -lcrypt32 -ladvapi32 -q -w0 2>&1 | findstr /V /I /C:"Warning"

rem pause
endlocal

👥 Autores e Filosofia do Projeto
Este projeto nasceu da união de esforços de desenvolvedores que acreditam na evolução contínua da linguagem Harbour para sistemas de missão crítica corporativos:

Franklin Brasil — Concepção do projeto, arquitetura de classes de negócios do eSocial, mapeamento das regras de validação governamentais.

Marcelo Antonio Lázzaro — mapeamento das regras de validação governamentais e testes de integração ERP.

🤝 Compromisso com a Comunidade Harbour
Este projeto não tem a pretensão de concorrer com nenhuma solução comercial ou biblioteca Open Source existente no ecossistema Harbour.

O objetivo principal desta classe é acrescentar uma alternativa técnica e gratuita para a comunidade, servindo como material de estudo e fornecendo uma fundação sólida de código nativo para quem precisa resolver o desafio da assinatura digital SHA256 (padrão eSocial) diretamente em C/Harbour, sem intermediários. Toda contribuição, correção ou melhoria enviada via Pull Request será muito bem-vinda para fortalecer nossa comunidade! 

📄 Licença
Este projeto está sob a licença MIT - consulte o arquivo LICENSE para obter detalhes. Você está livre para usar, modificar e distribuir comercialmente esta ponte criptográfica.
