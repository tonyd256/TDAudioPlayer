//
//  NSInputStream+URLInitialization.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/11/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "NSInputStream+URLInitialization.h"

@implementation NSInputStream (URLInitialization)

+ (NSInputStream *)inputStreamWithExternalURL:(NSURL *)url
{
    CFHTTPMessageRef message = CFHTTPMessageCreateRequest(NULL, (CFStringRef)@"GET", (__bridge CFURLRef)(url), kCFHTTPVersion1_1);

    if (!message) return nil;

    CFReadStreamRef stream = CFReadStreamCreateForHTTPRequest(NULL, message);
    CFRelease(message);

    if (!stream) return nil;

    CFReadStreamSetProperty(stream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue);

    CFDictionaryRef proxySettings = CFNetworkCopySystemProxySettings();

    CFReadStreamSetProperty(stream, kCFStreamPropertyHTTPProxy, proxySettings);

    CFRelease(proxySettings);

    if ([url.absoluteString rangeOfString:@"https"].location != NSNotFound) {
        NSDictionary *sslSettings = @{(NSString *)kCFStreamSSLLevel: (NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL,
                                      (NSString *)kCFStreamSSLAllowsExpiredCertificates: @YES,
                                      (NSString *)kCFStreamSSLAllowsExpiredRoots: @YES,
                                      (NSString *)kCFStreamSSLAllowsAnyRoot: @YES,
                                      (NSString *)kCFStreamSSLValidatesCertificateChain: @NO,
                                      (NSString *)kCFStreamSSLPeerName: [NSNull null]};

        CFReadStreamSetProperty(stream, kCFStreamPropertySSLSettings, (__bridge CFTypeRef)(sslSettings));
    }

//    CFRetain(stream);
    return (__bridge NSInputStream *)stream;
}

@end
