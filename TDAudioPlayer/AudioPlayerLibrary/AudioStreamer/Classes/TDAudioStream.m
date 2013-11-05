//
//  TDAudioStream.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDAudioStream.h"

@interface TDAudioStream () <NSStreamDelegate>

@property (assign, nonatomic) CFReadStreamRef stream;

@end

void TDReadStreamCallback(CFReadStreamRef inStream, CFStreamEventType eventType, void *inClientInfo)
{
    TDAudioStream *stream = (__bridge TDAudioStream *)inClientInfo;

    if (eventType == kCFStreamEventHasBytesAvailable) {
        [stream.delegate audioStream:stream didRaiseEvent:TDAudioStreamEventHasData];
    } else if (eventType == kCFStreamEventEndEncountered) {
        [stream.delegate audioStream:stream didRaiseEvent:TDAudioStreamEventEnd];
    } else if (eventType == kCFStreamEventErrorOccurred) {
        [stream.delegate audioStream:stream didRaiseEvent:TDAudioStreamEventError];
    }
}

@implementation TDAudioStream

- (instancetype)initWithInputStream:(NSInputStream *)inputStream
{
    self = [super init];
    if (!self) return nil;

    self.stream = (__bridge CFReadStreamRef)inputStream;
    CFRetain(self.stream);

    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (!self) return nil;

    CFHTTPMessageRef message = CFHTTPMessageCreateRequest(NULL, (CFStringRef)@"GET", (__bridge CFURLRef)(url), kCFHTTPVersion1_1);

    if (!message) return nil;

    self.stream = CFReadStreamCreateForHTTPRequest(NULL, message);
    CFRelease(message);

    if (!self.stream) return nil;

    CFReadStreamSetProperty(self.stream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue);

    CFDictionaryRef proxySettings = CFNetworkCopySystemProxySettings();

    CFReadStreamSetProperty(self.stream, kCFStreamPropertyHTTPProxy, proxySettings);

    CFRelease(proxySettings);

    if ([url.absoluteString rangeOfString:@"https"].location != NSNotFound) {
        NSDictionary *sslSettings = @{(NSString *)kCFStreamSSLLevel: (NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL,
                                      (NSString *)kCFStreamSSLAllowsExpiredCertificates: @YES,
                                      (NSString *)kCFStreamSSLAllowsExpiredRoots: @YES,
                                      (NSString *)kCFStreamSSLAllowsAnyRoot: @YES,
                                      (NSString *)kCFStreamSSLValidatesCertificateChain: @NO,
                                      (NSString *)kCFStreamSSLPeerName: [NSNull null]};

        CFReadStreamSetProperty(self.stream, kCFStreamPropertySSLSettings, (__bridge CFTypeRef)(sslSettings));
    }

    return self;
}

- (BOOL)open
{
    CFStreamClientContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    CFReadStreamSetClient(self.stream, kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred | kCFStreamEventHasBytesAvailable, TDReadStreamCallback, &context);
    CFReadStreamScheduleWithRunLoop(self.stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

    return CFReadStreamOpen(self.stream);
}

- (UInt32)readData:(uint8_t *)data maxLength:(UInt32)maxLength
{
    return (UInt32)CFReadStreamRead(self.stream, data, maxLength);
}

- (void)dealloc
{
    CFReadStreamClose(self.stream);
    CFReadStreamUnscheduleFromRunLoop(self.stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFRelease(_stream);
}

@end
