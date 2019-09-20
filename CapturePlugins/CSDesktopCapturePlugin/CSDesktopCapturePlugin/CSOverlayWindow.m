//
//  CSOverlayWindow.m
//  CocoaSplit
//
//  Created by Zakk on 8/26/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSOverlayWindow.h"

@implementation CSOverlayWindow

- (BOOL)canBecomeKeyWindow
{
    return YES;
}



- (void)cancelOperation:(id)sender
{
    [self close];
}

-(BOOL) isMovableByWindowBackground
{
    return YES;
}
@end
