//
//  CSDeckLinkWrapper.h
//  CSDeckLinkCapturePlugin
//
//  Created by Zakk on 6/17/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeckLinkBridge.h"

@interface CSDeckLinkWrapper : NSObject

@property (assign) IDeckLink *deckLink;


-(instancetype)initWithDeckLink:(IDeckLink *)device;

@end
