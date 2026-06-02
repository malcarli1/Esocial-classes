/*****************************************************************************
 * SISTEMA  : ROTINA EVENTUAL                                                *
 * PROGRAMA : ESOCIAL_CRYPTO.PRG                                             *
 * OBJETIVO : Ponte criptografica Harbour -> Windows CryptoAPI               *
 *            manter a classe eSocial em Harbour, usando apenas APIs nativas *
 *            do Windows para acessar a chave privada do certificado e gerar *
 *            assinatura RSA.                                                *
 * AUTOR    : Franklin Brasil                                                *
 * ALTERADO : Marcelo Antonio Lazzaro Carli                                  *
 * DATA     : 29.05.2026                                                     *
 * ULT. ALT.: 02.06.2026                                                     *
 *****************************************************************************/

FUNCTION EsocialSignSha256Hash( cHashBin, cSubject, cThumbprint )
RETURN __EsocialSignSha256Hash( cHashBin, hb_DefaultValue( cSubject, "" ), hb_DefaultValue( cThumbprint, "" ) )

FUNCTION EsocialCryptoLastError()
RETURN __EsocialCryptoLastError()

FUNCTION EsocialCertDer( cSubject, cThumbprint )
RETURN __EsocialCertDer( hb_DefaultValue( cSubject, "" ), hb_DefaultValue( cThumbprint, "" ) )

#pragma BEGINDUMP

#include "hbapi.h"
#include "hbapiitm.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <wincrypt.h>

#ifndef CALG_SHA_256
#define CALG_SHA_256 (ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_SHA_256)
#endif

#ifndef CRYPT_ACQUIRE_ALLOW_NCRYPT_KEY_FLAG
#define CRYPT_ACQUIRE_ALLOW_NCRYPT_KEY_FLAG 0x00010000
#endif

#ifndef CRYPT_ACQUIRE_PREFER_NCRYPT_KEY_FLAG
#define CRYPT_ACQUIRE_PREFER_NCRYPT_KEY_FLAG 0x00020000
#endif

#ifndef CERT_NCRYPT_KEY_SPEC
#define CERT_NCRYPT_KEY_SPEC 0xFFFFFFFF
#endif

#ifndef NCRYPT_PAD_PKCS1_FLAG
#define NCRYPT_PAD_PKCS1_FLAG 0x00000002
#endif

#ifndef ERROR_SUCCESS
#define ERROR_SUCCESS 0
#endif

typedef ULONG_PTR HB_NCRYPT_KEY_HANDLE;

typedef struct _HB_BCRYPT_PKCS1_PADDING_INFO
{
   LPCWSTR pszAlgId;
} HB_BCRYPT_PKCS1_PADDING_INFO;

typedef LONG HB_SECURITY_STATUS;
typedef HB_SECURITY_STATUS ( WINAPI * HB_NCRYPT_SIGN_HASH )( HB_NCRYPT_KEY_HANDLE, void *, BYTE *, DWORD, BYTE *, DWORD, DWORD *, DWORD );
typedef HB_SECURITY_STATUS ( WINAPI * HB_NCRYPT_FREE_OBJECT )( HB_NCRYPT_KEY_HANDLE );

static DWORD s_dwLastError = 0;
static char s_szLastStage[ 64 ] = "";

static void hb_esocial_set_error( const char * pszStage )
{
   s_dwLastError = GetLastError();
   lstrcpynA( s_szLastStage, pszStage, sizeof( s_szLastStage ) );
}

static BOOL hb_esocial_ncrypt_sign_sha256( HB_NCRYPT_KEY_HANDLE hKey, const BYTE * pbHash, DWORD cbHash )
{
   HMODULE hNCrypt = LoadLibraryA( "ncrypt.dll" );
   HB_NCRYPT_SIGN_HASH pNCryptSignHash;
   HB_NCRYPT_FREE_OBJECT pNCryptFreeObject;
   HB_BCRYPT_PKCS1_PADDING_INFO padding;
   DWORD cbSig = 0;
   BYTE * pbSig = NULL;
   HB_SECURITY_STATUS status;

   if( ! hNCrypt )
   {
      hb_esocial_set_error( "LoadLibrary-ncrypt" );
      return FALSE;
   }

   pNCryptSignHash = ( HB_NCRYPT_SIGN_HASH ) GetProcAddress( hNCrypt, "NCryptSignHash" );
   pNCryptFreeObject = ( HB_NCRYPT_FREE_OBJECT ) GetProcAddress( hNCrypt, "NCryptFreeObject" );
   if( ! pNCryptSignHash )
   {
      hb_esocial_set_error( "GetProcAddress-NCryptSignHash" );
      FreeLibrary( hNCrypt );
      return FALSE;
   }

   padding.pszAlgId = L"SHA256";
   status = pNCryptSignHash( hKey, &padding, ( PBYTE ) pbHash, cbHash, NULL, 0, &cbSig, NCRYPT_PAD_PKCS1_FLAG );
   if( status != ERROR_SUCCESS || cbSig == 0 )
   {
      s_dwLastError = ( DWORD ) status;
      lstrcpynA( s_szLastStage, "NCryptSignHash-size", sizeof( s_szLastStage ) );
      FreeLibrary( hNCrypt );
      return FALSE;
   }

   pbSig = ( BYTE * ) hb_xgrab( cbSig );
   status = pNCryptSignHash( hKey, &padding, ( PBYTE ) pbHash, cbHash, pbSig, cbSig, &cbSig, NCRYPT_PAD_PKCS1_FLAG );
   if( status == ERROR_SUCCESS )
   {
      hb_retclen( ( const char * ) pbSig, cbSig );
      hb_xfree( pbSig );
      FreeLibrary( hNCrypt );
      return TRUE;
   }

   hb_xfree( pbSig );
   s_dwLastError = ( DWORD ) status;
   lstrcpynA( s_szLastStage, "NCryptSignHash-data", sizeof( s_szLastStage ) );
   if( pNCryptFreeObject )
      ; /* freed by caller */
   FreeLibrary( hNCrypt );
   return FALSE;
}

static int hb_esocial_hexval( char c )
{
   if( c >= '0' && c <= '9' ) return c - '0';
   if( c >= 'a' && c <= 'f' ) return c - 'a' + 10;
   if( c >= 'A' && c <= 'F' ) return c - 'A' + 10;
   return -1;
}

static int hb_esocial_thumbprint_to_bytes( const char * pszHex, BYTE * out, DWORD * pcbOut )
{
   DWORD n = 0;
   int hi = -1;

   while( pszHex && *pszHex )
   {
      int v = hb_esocial_hexval( *pszHex++ );
      if( v < 0 )
         continue;

      if( hi < 0 )
         hi = v;
      else
      {
         if( n >= *pcbOut )
            return 0;
         out[ n++ ] = ( BYTE ) ( ( hi << 4 ) | v );
         hi = -1;
      }
   }

   if( hi >= 0 )
      return 0;

   *pcbOut = n;
   return n > 0;
}

static PCCERT_CONTEXT hb_esocial_find_cert( HCERTSTORE hStore, const char * pszSubject, const char * pszThumb )
{
   PCCERT_CONTEXT pCert = NULL;

   if( pszThumb && pszThumb[ 0 ] )
   {
      BYTE hash[ 64 ];
      DWORD cbHash = sizeof( hash );
      CRYPT_HASH_BLOB blob;

      if( ! hb_esocial_thumbprint_to_bytes( pszThumb, hash, &cbHash ) )
         return NULL;

      blob.cbData = cbHash;
      blob.pbData = hash;
      return CertFindCertificateInStore( hStore, X509_ASN_ENCODING | PKCS_7_ASN_ENCODING, 0,
                                         CERT_FIND_HASH, &blob, NULL );
   }

   while( ( pCert = CertEnumCertificatesInStore( hStore, pCert ) ) != NULL )
   {
      char subject[ 2048 ];
      CRYPT_KEY_PROV_INFO * pInfo = NULL;
      DWORD cbInfo = 0;
      DWORD len = CertGetNameStringA( pCert, CERT_NAME_SIMPLE_DISPLAY_TYPE, 0, NULL, subject, sizeof( subject ) );
      CertGetCertificateContextProperty( pCert, CERT_KEY_PROV_INFO_PROP_ID, NULL, &cbInfo );
      if( len > 1 && cbInfo > 0 )
      {
         int match = 0;
         pInfo = ( CRYPT_KEY_PROV_INFO * ) hb_xgrab( cbInfo );
         if( CertGetCertificateContextProperty( pCert, CERT_KEY_PROV_INFO_PROP_ID, pInfo, &cbInfo ) )
         {
            if( pszSubject && pszSubject[ 0 ] )
               match = strstr( subject, pszSubject ) != NULL;
            else
               match = strstr( subject, "LTDA" ) != NULL ||
                       strstr( subject, "CNPJ" ) != NULL ||
                       strstr( subject, "e-CNPJ" ) != NULL ||
                       strstr( subject, "E-CNPJ" ) != NULL;
         }
         hb_xfree( pInfo );

         if( match )
            return CertDuplicateCertificateContext( pCert );
      }
   }

   return NULL;
}

HB_FUNC( __ESOCIALSIGNSHA256HASH )
{
   const BYTE * pbHash = ( const BYTE * ) hb_parc( 1 );
   DWORD cbHash = ( DWORD ) hb_parclen( 1 );
   const char * pszSubject = hb_parc( 2 );
   const char * pszThumb = hb_parc( 3 );
   HCERTSTORE hStore = NULL;
   PCCERT_CONTEXT pCert = NULL;
   ULONG_PTR hKey = 0;
   DWORD dwKeySpec = 0;
   BOOL fCallerFree = FALSE;
   HCRYPTHASH hHash = 0;
   DWORD cbSig = 0;
   BYTE * pbSig = NULL;
   BOOL ok = FALSE;

   if( cbHash != 32 )
   {
      s_dwLastError = 0;
      lstrcpynA( s_szLastStage, "hash-size", sizeof( s_szLastStage ) );
      hb_retc_null();
      return;
   }

   hStore = CertOpenStore( CERT_STORE_PROV_SYSTEM_A, 0, 0,
                           CERT_SYSTEM_STORE_CURRENT_USER | CERT_STORE_READONLY_FLAG, "MY" );
   if( ! hStore )
   {
      hb_esocial_set_error( "CertOpenStore" );
      hb_retc_null();
      return;
   }

   pCert = hb_esocial_find_cert( hStore, pszSubject, pszThumb );
   if( ! pCert )
      hb_esocial_set_error( "find-cert" );
   if( pCert &&
       CryptAcquireCertificatePrivateKey( pCert, CRYPT_ACQUIRE_COMPARE_KEY_FLAG | CRYPT_ACQUIRE_ALLOW_NCRYPT_KEY_FLAG | CRYPT_ACQUIRE_PREFER_NCRYPT_KEY_FLAG,
                                          NULL, ( HCRYPTPROV * ) &hKey, &dwKeySpec, &fCallerFree ) )
   {
      if( dwKeySpec == CERT_NCRYPT_KEY_SPEC )
      {
         ok = hb_esocial_ncrypt_sign_sha256( ( HB_NCRYPT_KEY_HANDLE ) hKey, pbHash, cbHash );
      }
      else
      {
         HCRYPTPROV hProv = ( HCRYPTPROV ) hKey;
         if( CryptCreateHash( hProv, CALG_SHA_256, 0, 0, &hHash ) )
         {
            if( CryptSetHashParam( hHash, HP_HASHVAL, ( BYTE * ) pbHash, 0 ) )
            {
               if( CryptSignHashA( hHash, dwKeySpec, NULL, 0, NULL, &cbSig ) && cbSig > 0 )
               {
                  pbSig = ( BYTE * ) hb_xgrab( cbSig );
                  if( CryptSignHashA( hHash, dwKeySpec, NULL, 0, pbSig, &cbSig ) )
                  {
                     DWORD i;
                     for( i = 0; i < cbSig / 2; ++i )
                     {
                        BYTE tmp = pbSig[ i ];
                        pbSig[ i ] = pbSig[ cbSig - 1 - i ];
                        pbSig[ cbSig - 1 - i ] = tmp;
                     }
                     hb_retclen( ( const char * ) pbSig, cbSig );
                     ok = TRUE;
                  }
                  else
                     hb_esocial_set_error( "CryptSignHash-data" );
                  hb_xfree( pbSig );
               }
               else
                  hb_esocial_set_error( "CryptSignHash-size" );
            }
            else
               hb_esocial_set_error( "CryptSetHashParam" );
            CryptDestroyHash( hHash );
         }
         else
            hb_esocial_set_error( "CryptCreateHash-SHA256" );
      }
   }
   else if( pCert )
      hb_esocial_set_error( "CryptAcquireCertificatePrivateKey" );

   if( fCallerFree && hKey )
   {
      if( dwKeySpec == CERT_NCRYPT_KEY_SPEC )
      {
         HMODULE hNCrypt = LoadLibraryA( "ncrypt.dll" );
         if( hNCrypt )
         {
            HB_NCRYPT_FREE_OBJECT pNCryptFreeObject = ( HB_NCRYPT_FREE_OBJECT ) GetProcAddress( hNCrypt, "NCryptFreeObject" );
            if( pNCryptFreeObject )
               pNCryptFreeObject( ( HB_NCRYPT_KEY_HANDLE ) hKey );
            FreeLibrary( hNCrypt );
         }
      }
      else
         CryptReleaseContext( ( HCRYPTPROV ) hKey, 0 );
   }

   if( pCert )
      CertFreeCertificateContext( pCert );
   if( hStore )
      CertCloseStore( hStore, 0 );

   if( ! ok )
      hb_retc_null();
}

HB_FUNC( __ESOCIALCRYPTOLASTERROR )
{
   char buffer[ 128 ];
   wsprintfA( buffer, "%s:%lu", s_szLastStage, ( unsigned long ) s_dwLastError );
   hb_retc( buffer );
}

HB_FUNC( __ESOCIALCERTDER )
{
   const char * pszSubject = hb_parc( 1 );
   const char * pszThumb = hb_parc( 2 );
   HCERTSTORE hStore = CertOpenStore( CERT_STORE_PROV_SYSTEM_A, 0, 0,
                                      CERT_SYSTEM_STORE_CURRENT_USER | CERT_STORE_READONLY_FLAG, "MY" );
   PCCERT_CONTEXT pCert = NULL;

   if( ! hStore )
   {
      hb_esocial_set_error( "CertOpenStore" );
      hb_retc_null();
      return;
   }

   pCert = hb_esocial_find_cert( hStore, pszSubject, pszThumb );
   if( pCert )
   {
      hb_retclen( ( const char * ) pCert->pbCertEncoded, pCert->cbCertEncoded );
      CertFreeCertificateContext( pCert );
   }
   else
   {
      hb_esocial_set_error( "find-cert" );
      hb_retc_null();
   }

   CertCloseStore( hStore, 0 );
}

#pragma ENDDUMP