//
//  CSFileStreamServiceFactory.m
//  CSFileStreamServicePlugin
//
//  Created by Zakk on 7/16/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSFileStreamServiceFactory.h"


@implementation CSFileStreamServiceFactory
+(NSArray *)captureSourceClasses
{
    return @[[FileStreamService class], [CSFileStreamRTMPService class]];}


+(NSArray *)streamServiceClasses
{
    return nil;
}

+(NSArray *)extraPluginClasses
{
    return nil;
}


@end
