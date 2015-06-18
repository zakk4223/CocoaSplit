//
//  CSDeckLinkWrapper.m
//  CSDeckLinkCapturePlugin
//
//  Created by Zakk on 6/17/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSDeckLinkWrapper.h"

@implementation CSDeckLinkWrapper
@synthesize deckLink = _deckLink;



-(instancetype)initWithDeckLink:(IDeckLink *)device
{
    if (self = [self init])
    {
        self.deckLink = device;
    }
    
    return self;
}


-(void)setDeckLink:(IDeckLink *)deckLink
{
    if (deckLink)
    {
        deckLink->AddRef();
    }
    
    _deckLink = deckLink;
}

-(IDeckLink *)deckLink
{
    return _deckLink;
}

-(void)dealloc
{
    if (_deckLink)
    {
        _deckLink->Release();
    }
}

@end
