//
//  LTWGUIDownloader.m
//  LTWToolkit
//
//  Created by David Alexander on 25/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWGUIDownloader.h"

#import "LTWGUIMediator.h"
#import "LTWDatabase.h"

#ifdef GTK_PLATFORM
#include <winsock.h>
#else
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netdb.h>
#endif

#include <sys/stat.h>

@implementation LTWGUIDownloader

-(id)initWithDelegate:(id)theDelegate proxyHostname:(NSString*)theProxyHostname proxyPort:(NSUInteger)theProxyPort proxyUsername:(NSString*)theProxyUsername proxyPassword:(NSString*)theProxyPassword dataPath:(NSString*)theDataPath {
    if ((self = [super init])) {
        delegate = [theDelegate retain];
        proxyHostname = [theProxyHostname retain];
        proxyPort = theProxyPort;
        proxyUsername = [theProxyUsername retain];
        proxyPassword = [theProxyPassword retain];
        dataPath = [theDataPath retain];
        lastFileTimestamp = 0;
        databases = [[NSMutableDictionary alloc] init];
        
        // To prevent a race condition, this must be done AFTER all the ivars have been filled in.
        [NSThread detachNewThreadSelector:@selector(downloadAssessments) toTarget:self withObject:nil];
        [NSThread detachNewThreadSelector:@selector(loadKnownIssues) toTarget:self withObject:nil];
    }
    
    return self;
}

-(void)downloadAssessments {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [delegate threadSafePushStatus:[NSString stringWithFormat:@"Searching for assessment files in %@...", dataPath]];
    
    [self loadExistingFiles];
    
    [delegate threadSafePushStatus:@"Checking for new assessment files to download..."];
    
    while ([self downloadFile]);
    
    [pool drain];
}

-(void)handleFile:(NSString*)filename downloaded:(BOOL)downloaded {
    LTWDatabase *database = [[LTWDatabase alloc] initWithDataFile:[dataPath stringByAppendingPathComponent:filename]];
    if (!database) return;
    [databases setObject:database forKey:filename];
    lastFileTimestamp = [database assessmentFileTimestamp];
    
    LTWGUIDatabaseFile *file = [[[LTWGUIDatabaseFile alloc] init] autorelease];
    [file setFilename:filename];
    [file setFilePath:[dataPath stringByAppendingPathComponent:filename]];
    
    LTWGUIMethodCall *call = [[LTWGUIMethodCall alloc] initWithSelector:@selector(assessmentFileFound:) argument:file];
    [delegate callOnMainThread:call];
}

-(void)loadFile:(NSString*)filename {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [delegate threadSafePushStatus:[NSString stringWithFormat:@"Loading %@...", filename]];
    LTWDatabase *database = [databases objectForKey:filename];
    [database loadArticlesWithDelegate:self];
    
    LTWGUIMethodCall *call = [[LTWGUIMethodCall alloc] initWithSelector:@selector(finishedLoadingArticles) argument:filename];
    [delegate callOnMainThread:call];
    [delegate threadSafePushStatus:[NSString stringWithFormat:@"Finished loading %@...", filename]];
    
    [pool drain];
}

-(void)startLoadAssessmentFile:(NSString*)filename {
    [NSThread detachNewThreadSelector:@selector(loadFile:) toTarget:self withObject:filename];
}

-(void)startUploadAssessmentFile:(NSString*)filename {
    [NSThread detachNewThreadSelector:@selector(uploadFile:) toTarget:self withObject:filename];
}

-(void)startSubmitBugReport:(NSString*)text {
    [NSThread detachNewThreadSelector:@selector(submitBugReport:) toTarget:self withObject:text];
}

-(void)articleLoaded:(LTWArticle*)article articleID:(NSUInteger)articleID {
    if (articleID == 1) {
        LTWGUIMethodCall *call = [[LTWGUIMethodCall alloc] initWithSelector:@selector(displaySourceArticle:) argument:article];
        [delegate callOnMainThread:call];
    }else{
        LTWGUIMethodCall *call = [[LTWGUIMethodCall alloc] initWithSelector:@selector(loadNonSourceArticle:) argument:article];
        [delegate callOnMainThread:call];
    }
}

-(void)loadExistingFiles {
    for (NSString *filename in [[NSFileManager defaultManager] directoryContentsAtPath:dataPath]) {
        if ([filename hasSuffix:@".ltw"]) {
            [self handleFile:filename downloaded:NO];
        }
    }
}

-(int)socketWithHost:(const char*)hostname port:(int)port {
#ifdef GTK_PLATFORM
    static __thread BOOL initialisedWinsock = NO;
    if (!initialisedWinsock) {
        WSADATA data;
        WSAStartup(MAKEWORD(2, 2), &data);
        initialisedWinsock = YES;
    }
#endif
    
    struct sockaddr_in address;
    struct hostent *host = gethostbyname(proxyHostname ? [proxyHostname UTF8String] : hostname);
    
    if (!host) return 0;
    
    address.sin_family = host->h_addrtype;
    address.sin_port = htons(proxyPort ? proxyPort : port);
    memcpy(&address.sin_addr, host->h_addr, host->h_length);
    
    int sock = socket(host->h_addrtype, SOCK_STREAM, 0);
    
    if (!sock) return 0;
    
    connect(sock, (struct sockaddr*)&address, sizeof address);
    
    return sock;
}

-(void)writeCString:(const char*)cString toSocket:(int)sock {
    NSUInteger lengthRemaining = strlen(cString);
    while (lengthRemaining > 0) {
        lengthRemaining -= send(sock, cString, lengthRemaining, 0);
    }
}

-(void)writeString:(NSString*)string toSocket:(int)sock {
    [self writeCString:[string UTF8String] toSocket:sock];
}

-(void)writeLine:(NSString*)string toSocket:(int)sock {
    [self writeString:string toSocket:sock];
    [self writeString:@"\r\n" toSocket:sock];
}

// NOTE: The buffer that this method returns will be reused on the next call.
-(const char*)readStringFromSocket:(int)sock length:(int*)length {
    static char buffer[1024];
    NSUInteger bytesRead = recv(sock, buffer, sizeof buffer - 1, 0);
    buffer[bytesRead] = '\0';
    *length = bytesRead;
    return buffer;
}

//Base64 encoding functions from http://cvs.savannah.gnu.org/viewvc/*checkout*/gnulib/gnulib/lib/base64.c?revision=HEAD

#define BASE64_LENGTH(inlen) ((((inlen) + 2) / 3) * 4)

/* C89 compliant way to cast 'char' to 'unsigned char'. */
static inline unsigned char
to_uchar (char ch)
{
    return ch;
}

/* Base64 encode IN array of size INLEN into OUT array of size OUTLEN.
 If OUTLEN is less than BASE64_LENGTH(INLEN), write as many bytes as
 possible.  If OUTLEN is larger than BASE64_LENGTH(INLEN), also zero
 terminate the output buffer. */
void
base64_encode (const char *restrict in, size_t inlen,
               char *restrict out, size_t outlen)
{
    static const char b64str[64] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    while (inlen && outlen)
    {
        *out++ = b64str[(to_uchar (in[0]) >> 2) & 0x3f];
        if (!--outlen)
            break;
        *out++ = b64str[((to_uchar (in[0]) << 4)
                         + (--inlen ? to_uchar (in[1]) >> 4 : 0))
                        & 0x3f];
        if (!--outlen)
            break;
        *out++ =
        (inlen
         ? b64str[((to_uchar (in[1]) << 2)
                   + (--inlen ? to_uchar (in[2]) >> 6 : 0))
                  & 0x3f]
         : '=');
        if (!--outlen)
            break;
        *out++ = inlen ? b64str[to_uchar (in[2]) & 0x3f] : '=';
        if (!--outlen)
            break;
        if (inlen)
            inlen--;
        if (inlen)
            in += 3;
    }
    
    if (outlen)
        *out = '\0';
}

// End Base64 encoding functions.

-(NSString*)readLineFromSocket:(int)sock {
    // NOTE: This is a hack to avoid having to deal with "ungetting" characters.
    // We read one char at a time until we encounter a newline.
    // This would be very inefficient if we were dealing with a lot of data in lines, but we're not -- the bulk of the data is in the response body, which has a fixed length.
    char c;
    NSMutableString *line = [NSMutableString string];
    while (recv(sock, &c, 1, 0) == 1 && c != '\n' && c != '\r') {
        [line appendFormat:@"%c", c];
    }
    if (c == '\r') recv(sock, &c, 1, 0); // skip over '\n'
    return line;
}

-(void)authenticateWithProxyOnSocket:(int)sock {
    // NOTE: This line should really be somewhere else!
    [self writeLine:@"User-agent: LTW Assessment Tool (pre-release 0.1)" toSocket:sock];
    
    if (!proxyUsername || !proxyPassword) return;
    
    const char *credentials = [[NSString stringWithFormat:@"%@:%@", proxyUsername, proxyPassword] UTF8String];
    
    NSUInteger length = strlen(credentials);
    NSUInteger base64Length = BASE64_LENGTH(length);
    
    char *base64Credentials = malloc(base64Length+1);
    
    base64_encode(credentials, length, base64Credentials, base64Length+1);
    
    [self writeString:@"Proxy-Authorization: Basic " toSocket:sock];
    [self writeCString:base64Credentials toSocket:sock];
    [self writeLine:@"" toSocket:sock];
    free(base64Credentials);
                                     
}


-(void)loadKnownIssues {
    int sock = [self socketWithHost:"linkthewiki.nfshost.com" port:80];
    if (!sock) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [self writeLine:@"GET http://linkthewiki.nfshost.com/knownissues.php HTTP/1.1" toSocket:sock];
    [self writeLine:@"Host: linkthewiki.nfshost.com" toSocket:sock];
    [self authenticateWithProxyOnSocket:sock];
    [self writeLine:@"" toSocket:sock];
    
    NSString *header;
    NSUInteger contentLength = 0;
    do {
        header = [self readLineFromSocket:sock];
        if ([header hasPrefix:@"Content-Length: "]) {
            contentLength = atoi([header UTF8String] + 16);
        }
    } while (![header isEqual:@""]);
    
    NSMutableString *response = [NSMutableString string];
    while (contentLength > 0) {
        int bytesRead = 0;
        const char *string = [self readStringFromSocket:sock length:&bytesRead];
        if (bytesRead == 0) break;
        contentLength -= bytesRead;
        [response appendFormat:@"%s",string];
    }
    
    LTWGUIMethodCall *call = [[[LTWGUIMethodCall alloc] initWithSelector:@selector(setKnownIssues:) argument:response] autorelease];
    [delegate callOnMainThread:call];
    
    [pool drain];
}

-(BOOL)downloadFile {
    int sock = [self socketWithHost:"linkthewiki.nfshost.com" port:80];
    if (!sock) {
        [delegate threadSafePushStatus:@"Error downloading assessment files. (Check your connection and proxy settings.)"];
        return NO;
    }
    
    [self writeLine:[NSString stringWithFormat:@"GET http://linkthewiki.nfshost.com/getfile.php?last_file_timestamp=%d HTTP/1.1", lastFileTimestamp] toSocket:sock];
    [self writeLine:@"Host: linkthewiki.nfshost.com" toSocket:sock];
    [self authenticateWithProxyOnSocket:sock];
    [self writeLine:@"" toSocket:sock];
    
    NSString *responseCode = [self readLineFromSocket:sock];
    
    if (![responseCode isEqual:@"HTTP/1.1 200 OK"]) {
        [delegate threadSafePushStatus:[NSString stringWithFormat:@"Finished downloading assessment files. (%d downloaded.)", numFilesDownloaded]];
        return NO;
    }
    
    NSUInteger contentLength = 0;
    FILE *downloadFile = NULL;
    NSString *filename = nil;
    NSString *downloadFilePath = nil;
    
    NSString *header;
    do {
        header = [self readLineFromSocket:sock];
        if ([header hasPrefix:@"Content-Length: "]) {
            contentLength = atoi([header UTF8String] + 16);
        }else if ([header hasPrefix:@"Content-Disposition: attachment; filename=\""]) {
            filename = [header substringWithRange:NSMakeRange(43, [header length] - 43 - 1)];
            downloadFilePath = [dataPath stringByAppendingPathComponent:filename];
            
            FILE *existingFile = fopen([downloadFilePath UTF8String], "r");
            if (existingFile) {
                fclose(existingFile);
                return NO;
            }else{
                downloadFile = fopen([downloadFilePath UTF8String], "wb");
            }
        }
    } while (![header isEqual:@""]);
    
    while (contentLength > 0) {
        int bytesRead = 0;
        const char *string = [self readStringFromSocket:sock length:&bytesRead];
        if (bytesRead == 0) break;
        contentLength -= bytesRead;
        fwrite(string, 1, bytesRead, downloadFile);
        
        [delegate threadSafePushStatus:[NSString stringWithFormat:@"Downloading %@. (%d bytes remaining.)", filename, contentLength]];
    }
    
    [delegate threadSafePushStatus:[NSString stringWithFormat:@"Finished downloading %@.", filename]];
    
    fclose(downloadFile);
    
    [self handleFile:filename downloaded:YES];
    
    numFilesDownloaded++;
    
    return YES;
}

-(BOOL)uploadFile:(NSString*)filename {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    struct stat stat;
    
    FILE *uploadFile = fopen([[dataPath stringByAppendingPathComponent:filename] UTF8String], "rb");
    
    if (!uploadFile) return NO;
    
    fstat(fileno(uploadFile), &stat);
    
    int sock = [self socketWithHost:"linkthewiki.nfshost.com" port:80];
    
    if (!sock) {
        [delegate threadSafePushStatus:@"Error uploading assessment file. (Check your connection and proxy settings.)"];
        return NO;
    }
    
    NSString *lastComponent =
#ifdef GTK_PLATFORM
    [[filename componentsSeparatedByString:@"\\"] lastObject];
#else
    [[filename componentsSeparatedByString:@"/"] lastObject];
#endif
    
    [self writeLine:[NSString stringWithFormat:@"PUT http://linkthewiki.nfshost.com/upload/%@ HTTP/1.1", lastComponent] toSocket:sock];
    [self writeLine:@"Host: linkthewiki.nfshost.com" toSocket:sock];
    [self authenticateWithProxyOnSocket:sock];
    [self writeLine:[NSString stringWithFormat:@"Content-Length: %lld", stat.st_size] toSocket:sock];
    [self writeLine:@"" toSocket:sock];
    
    NSUInteger bytesRemaining = stat.st_size;
    
    while (YES) {
        char buffer[1024];
        NSUInteger bytesRead = fread(buffer, 1, sizeof buffer - 1, uploadFile);
        if (bytesRead == 0) break;
        
        buffer[bytesRead] = '\0';
        
        [self writeCString:buffer toSocket:sock];
        
        bytesRemaining -= bytesRead;
        [delegate threadSafePushStatus:[NSString stringWithFormat:@"Uploading %@. (%d bytes remaining.)", filename, bytesRemaining]];
        
    }
    
    fclose(uploadFile);
    
    NSString *responseCode = [self readLineFromSocket:sock];
    BOOL result = [responseCode isEqual:@"HTTP/1.1 201 Created"];
    
    if (result) {
        [delegate threadSafePushStatus:[NSString stringWithFormat:@"Finished uploading %@.", filename]];
    }else{
        [delegate threadSafePushStatus:[NSString stringWithFormat:@"Failed to upload %@. (Received response %@.)", filename, responseCode]];
    }
    
#ifdef GTK_PLATFORM
    shutdown(sock, SD_BOTH);
    closesocket(sock);
#else
    shutdown(sock, SHUT_RDWR);
    close(sock);
#endif
    
    [pool drain];
    
    return result;
}


-(void)submitBugReport:(NSString*)text {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [delegate threadSafePushStatus:@"Submitting bug report."];
    
    int sock = [self socketWithHost:"linkthewiki.nfshost.com" port:80];
    
    if (!sock) {
        [delegate threadSafePushStatus:@"Error submitting bug report. (Check your connection and proxy settings.)"];
        return;
    }
    
    const char *cString = [text UTF8String];
    NSUInteger textLength = strlen(cString);
    
    [self writeLine:@"PUT http://linkthewiki.nfshost.com/bugreport HTTP/1.1" toSocket:sock];
    [self writeLine:@"Host: linkthewiki.nfshost.com" toSocket:sock];
    [self authenticateWithProxyOnSocket:sock];
    [self writeLine:[NSString stringWithFormat:@"Content-Length: %d", textLength] toSocket:sock];
    [self writeLine:@"" toSocket:sock];
    
    [self writeCString:cString toSocket:sock];
    
    NSString *responseCode = [self readLineFromSocket:sock];
    BOOL result = [responseCode isEqual:@"HTTP/1.1 201 OK"];
    
    if (result) {
        [delegate threadSafePushStatus:@"Finished submitting bug report."];
    }else{
        [delegate threadSafePushStatus:[NSString stringWithFormat:@"Failed to submit bug report. (Received response %@.)", responseCode]];
    }
    
#ifdef GTK_PLATFORM
    shutdown(sock, SD_BOTH);
    closesocket(sock);
#else
    shutdown(sock, SHUT_RDWR);
    close(sock);
#endif
    
    [pool drain];
}


@end
