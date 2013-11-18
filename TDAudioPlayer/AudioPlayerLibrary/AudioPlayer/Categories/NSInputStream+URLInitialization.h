//
//  NSInputStream+URLInitialization.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/11/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

@interface NSInputStream (URLInitialization)

+ (NSInputStream *)inputStreamWithExternalURL:(NSURL *)url;

@end
