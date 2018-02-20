//
//  CSColorWell.m
//  CocoaSplit
//
//  Created by Zakk on 2/19/18.
//  Copyright © 2018 Zakk. All rights reserved.
//

#import "CSColorWell.h"

@implementation CSColorWell

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}


-(void)activate:(BOOL)exclusive
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CSColorWellActivated" object:self];
    [super activate:exclusive];
}

-(void)deactivate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CSColorWellDeactivated" object:self];

    [super deactivate];
}
@end
