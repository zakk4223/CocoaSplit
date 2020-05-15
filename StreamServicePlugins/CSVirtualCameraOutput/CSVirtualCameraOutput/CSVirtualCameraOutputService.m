//
//  CSVirtualCameraOutputService.m
//  CSVirtualCameraOutput
//
//  Created by Zakk on 5/6/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import "CSVirtualCameraOutputService.h"
#import "CSVirtualCameraOutput.h"

@implementation CSVirtualCameraOutputService

+(NSString *)label
{
    return @"Virtual Camera";
}

-(NSObject <CSOutputWriterProtocol> *)createOutput
{
    return [[CSVirtualCameraOutput alloc] init];
}


-(NSString *)getServiceDestination
{
    return @"COCOASPLIT";
}


@end
