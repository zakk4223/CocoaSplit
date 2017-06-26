//
//  CSInputSourceBase.m
//  CocoaSplit
//
//  Created by Zakk on 6/26/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSInputSourceBase.h"

@implementation CSInputSourceBase


-(void)createUUID
{
    CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
    self.uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
    CFRelease(tmpUUID);
    
}


-(void)frameTick
{
    return;
}

-(void)willDelete
{
    return;
}

-(bool)isDifferentInput:(NSObject<CSInputSourceProtocol> *)from
{
    return YES;
}

@end
