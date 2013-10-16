//
//  TDAudioStream.m
//  Console.fm
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Simple Casual. All rights reserved.
//

#import "TDAudioStream.h"

@interface TDAudioStream () <NSStreamDelegate>

//@property (strong, atomic) NSInputStream *stream;
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

//    _stream = inputStream;
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

    CFReadStreamRef stream = CFReadStreamCreateForHTTPRequest(NULL, message);
    CFRelease(message);

    if (!stream) {
        NSLog(@"Error creating CFReadStreamRef");
        return nil;
    }

    if (CFReadStreamSetProperty(stream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue) == false) {
        NSLog(@"Error setting autoredirect property");
        return nil;
    }

    CFDictionaryRef proxySettings = CFNetworkCopySystemProxySettings();

    /*if (!*/CFReadStreamSetProperty(stream, kCFStreamPropertyHTTPProxy, proxySettings);//) {
//        NSLog(@"Error setting proxy settings");
//        CFRelease(proxySettings);
//        return nil;
//    }

    CFRelease(proxySettings);

    if ([url.absoluteString rangeOfString:@"https"].location != NSNotFound) {
        NSDictionary *sslSettings = @{(NSString *)kCFStreamSSLLevel: (NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL,
                                      (NSString *)kCFStreamSSLAllowsExpiredCertificates: @YES,
                                      (NSString *)kCFStreamSSLAllowsExpiredRoots: @YES,
                                      (NSString *)kCFStreamSSLAllowsAnyRoot: @YES,
                                      (NSString *)kCFStreamSSLValidatesCertificateChain: @NO,
                                      (NSString *)kCFStreamSSLPeerName: [NSNull null]};

        if (!CFReadStreamSetProperty(stream, kCFStreamPropertySSLSettings, (__bridge CFTypeRef)(sslSettings))) {
            NSLog(@"Error setting ssl settings");
        }
    }

//    _stream = (__bridge NSInputStream *)stream;
    _stream = stream;

    return self;
}

- (void)open
{
    CFStreamClientContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    CFReadStreamSetClient(self.stream, kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred | kCFStreamEventHasBytesAvailable | kCFStreamEventOpenCompleted | kCFStreamEventCanAcceptBytes, TDReadStreamCallback, &context);
    CFReadStreamScheduleWithRunLoop(self.stream, CFRunLoopGetMain(), kCFRunLoopCommonModes);

    if (!CFReadStreamOpen(self.stream)) {
        NSLog(@"Error opening stream");
        return;
    }

//    self.stream.delegate = self;
//    [self.stream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
//    [self.stream open];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (eventCode == NSStreamEventHasBytesAvailable) {
        [self.delegate audioStream:self didRaiseEvent:TDAudioStreamEventHasData];
    } else if (eventCode == NSStreamEventEndEncountered) {
        [self.delegate audioStream:self didRaiseEvent:TDAudioStreamEventEnd];
    } else if (eventCode == NSStreamEventErrorOccurred) {
        [self.delegate audioStream:self didRaiseEvent:TDAudioStreamEventError];
    }
}

- (UInt32)readData:(uint8_t *)data maxLength:(UInt32)maxLength
{
    return CFReadStreamRead(self.stream, data, maxLength);
//    return [self.stream read:data maxLength:maxLength];
}

@end
