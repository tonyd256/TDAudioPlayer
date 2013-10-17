//
//  TDAudioStream.m
//  Console.fm
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Simple Casual. All rights reserved.
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

    _stream = (__bridge CFReadStreamRef)inputStream;

    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (!self) return nil;

    CFHTTPMessageRef message = CFHTTPMessageCreateRequest(NULL, (CFStringRef)@"GET", (__bridge CFURLRef)(url), kCFHTTPVersion1_1);

    if (!message) {
        NSLog(@"Error creating CFHTTPMessageRef");
        return nil;
    }

    _stream = CFReadStreamCreateForHTTPRequest(NULL, message);
    CFRelease(message);

    if (!_stream) {
        NSLog(@"Error creating CFReadStreamRef");
        return nil;
    }

    if (CFReadStreamSetProperty(_stream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue) == false) {
        NSLog(@"Error setting autoredirect property");
    }

    CFDictionaryRef proxySettings = CFNetworkCopySystemProxySettings();

    if (!CFReadStreamSetProperty(_stream, kCFStreamPropertyHTTPProxy, proxySettings)) {
        NSLog(@"Error setting proxy settings");
    }

    CFRelease(proxySettings);

    if ([url.absoluteString rangeOfString:@"https"].location != NSNotFound) {
        NSDictionary *sslSettings = @{(NSString *)kCFStreamSSLLevel: (NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL,
                                      (NSString *)kCFStreamSSLAllowsExpiredCertificates: @YES,
                                      (NSString *)kCFStreamSSLAllowsExpiredRoots: @YES,
                                      (NSString *)kCFStreamSSLAllowsAnyRoot: @YES,
                                      (NSString *)kCFStreamSSLValidatesCertificateChain: @NO,
                                      (NSString *)kCFStreamSSLPeerName: [NSNull null]};

        if (!CFReadStreamSetProperty(_stream, kCFStreamPropertySSLSettings, (__bridge CFTypeRef)(sslSettings))) {
            NSLog(@"Error setting ssl settings");
        }
    }

    return self;
}

- (void)dealloc
{
    CFRelease(_stream);
}

- (void)open
{
    CFStreamClientContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    CFReadStreamSetClient(self.stream, kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred | kCFStreamEventHasBytesAvailable | kCFStreamEventOpenCompleted | kCFStreamEventCanAcceptBytes, TDReadStreamCallback, &context);
    CFReadStreamScheduleWithRunLoop(self.stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

    if (!CFReadStreamOpen(self.stream)) {
        NSLog(@"Error opening stream");
        return;
    }
}

- (UInt32)readData:(uint8_t *)data maxLength:(UInt32)maxLength
{
    return CFReadStreamRead(self.stream, data, maxLength);
}

@end
