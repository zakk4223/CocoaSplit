//
//  CSScrollView.m
//  CocoaSplit
//
//  Created by Zakk on 5/9/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSScrollView.h"

@implementation CSScrollView

-(instancetype) initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        NSLog(@"WHEEEEEEE");
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return self;
}
@end
