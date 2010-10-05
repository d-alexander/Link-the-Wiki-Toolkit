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

-(id)initWithDelegate:(id)theDelegate {
    if ((self = [super init])) {
        delegate = theDelegate;
        lastFileTimestamp = 0;
        databases = [[NSMutableDictionary alloc] init];
        
        // To prevent a race condition, this must be done AFTER all the ivars have been filled in.
        [NSThread detachNewThreadSelector:@selector(downloadAssessments) toTarget:self withObject:nil];
    }
    
    return self;
}

-(void)downloadAssessments {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [delegate pushStatus:@"Loading existing assessment files..."];
    
    [self loadExistingFiles];
    
    [delegate pushStatus:@"Downloading new assessment files..."];
    
    while ([self downloadFile]);
    
    [delegate pushStatus:@"Finished downloading."];
    
    [pool drain];
}

-(void)handleFile:(NSString*)filename downloaded:(BOOL)downloaded {
    LTWDatabase *database = [[LTWDatabase alloc] initWithDataFile:filename];
    [databases setObject:database forKey:filename];
    lastFileTimestamp = [database assessmentFileTimestamp];
    
    LTWGUIMethodCall *call = [[LTWGUIMethodCall alloc] initWithSelector:@selector(assessmentFileFound:) argument:filename];
    [delegate callOnMainThread:call];
}

// NOTE: The file should eventually be provided as a GUI-represented object.
-(void)loadFile:(NSString*)filename {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    LTWDatabase *database = [databases objectForKey:filename];
    [database loadArticlesWithDelegate:self];
    
    [pool drain];
}

-(void)startLoadAssessmentFile:(NSString*)filename {
    [NSThread detachNewThreadSelector:@selector(loadFile:) toTarget:self withObject:filename];
}

-(void)articleLoaded:(LTWArticle*)article articleID:(NSUInteger)articleID {
    NSLog(@"%d: %@", articleID, article);
    if (articleID == 1) {
        LTWGUIMethodCall *call = [[LTWGUIMethodCall alloc] initWithSelector:@selector(displaySourceArticle:) argument:article];
        [delegate callOnMainThread:call];
    }else{
        LTWGUIMethodCall *call = [[LTWGUIMethodCall alloc] initWithSelector:@selector(loadNonSourceArticle:) argument:article];
        [delegate callOnMainThread:call];
    }
}

-(void)loadExistingFiles {
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:(@""DATA_PATH)];
    for (NSString *filename = [enumerator nextObject]; filename; filename = [enumerator nextObject]) {
        if ([filename hasSuffix:@".ltw"]) {
            [self handleFile:[@""DATA_PATH stringByAppendingPathComponent:filename] downloaded:NO];
        }
    }
}

-(int)socketWithHost:(const char*)hostname port:(int)port {
#ifdef GTK_PLATFORM
    static BOOL initialisedWinsock = NO;
    if (!initialisedWinsock) {
        WSADATA data;
        WSAStartup(MAKEWORD(2, 2), &data);
        initialisedWinsock = YES;
    }
#endif
    
    // TODO: Handle errors.
    struct sockaddr_in address;
    struct hostent *host = gethostbyname(hostname);
    
    if (!host) return 0;
    
    address.sin_family = host->h_addrtype;
    address.sin_port = htons(port);
    memcpy(&address.sin_addr, host->h_addr, host->h_length);
    
    int sock = socket(host->h_addrtype, SOCK_STREAM, 0);
    
    if (!sock) return 0;
    
    connect(sock, (struct sockaddr*)&address, sizeof address);
    
    return sock;
}

-(void)writeString:(NSString*)string toSocket:(int)sock {
    const char *cString = [string UTF8String];
    NSUInteger lengthRemaining = strlen(cString);
    while (lengthRemaining > 0) {
        lengthRemaining -= send(sock, cString, lengthRemaining, 0);
    }
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

-(BOOL)downloadFile {
    int sock = [self socketWithHost:"linkthewiki.nfshost.com" port:80];
    
    if (!sock) return NO;
    
    [self writeLine:[NSString stringWithFormat:@"GET /getfile.php?last_file_timestamp=%d HTTP/1.1", lastFileTimestamp] toSocket:sock];
    [self writeLine:@"Host: linkthewiki.nfshost.com" toSocket:sock];
    [self writeLine:@"" toSocket:sock];
    
    NSString *responseCode = [self readLineFromSocket:sock];
    
    if (![responseCode isEqual:@"HTTP/1.1 200 OK"]) return NO;
    
    NSUInteger contentLength = 0;
    FILE *downloadFile = NULL;
    NSString *downloadFilePath = nil;
    
    NSString *header;
    do {
        header = [self readLineFromSocket:sock];
        if ([header hasPrefix:@"Content-Length: "]) {
            contentLength = atoi([header UTF8String] + 16);
        }else if ([header hasPrefix:@"Content-Disposition: attachment; filename=\""]) {
            NSString *filename = [header substringWithRange:NSMakeRange(43, [header length] - 43 - 1)];
            downloadFilePath = [@""DATA_PATH stringByAppendingPathComponent:filename];
            
            downloadFile = fopen([downloadFilePath UTF8String], "wb");
        }
    } while (![header isEqual:@""]);
    
    while (contentLength > 0) {
        int bytesRead = 0;
        const char *string = [self readStringFromSocket:sock length:&bytesRead];
        if (bytesRead == 0) break;
        contentLength -= bytesRead;
        fwrite(string, 1, bytesRead, downloadFile);
    }
    
    fclose(downloadFile);
    
    [self handleFile:downloadFilePath downloaded:YES];
    
    return YES;
}

-(BOOL)uploadFile:(NSString*)filename {
    struct stat stat;
    
    FILE *uploadFile = fopen([[@""DATA_PATH stringByAppendingPathComponent:filename] UTF8String], "rb");
    fstat(fileno(uploadFile), &stat);
    
    int sock = [self socketWithHost:"linkthewiki.nfshost.com" port:80];
    
    [self writeLine:[NSString stringWithFormat:@"PUT /%@ HTTP/1.1", filename] toSocket:sock];
    [self writeLine:@"Host: linkthewiki.nfshost.com" toSocket:sock];
    [self writeLine:[NSString stringWithFormat:@"Content-Length: %d", stat.st_size] toSocket:sock];
    [self writeLine:@"" toSocket:sock];
    
    while (YES) {
        char buffer[1024];
        NSUInteger bytesRead = fread(buffer, 1, sizeof buffer - 1, uploadFile);
        if (bytesRead == 0) break;
        
        buffer[bytesRead] = '\0';
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [self writeString:[NSString stringWithUTF8String:buffer] toSocket:sock];
        [pool drain];
    }
    
    fclose(uploadFile);
    
    
    return YES;
}

@end
