//
//  FileStreamService.m
//  CSFileStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "FileStreamService.h"
#import "FileStreamServiceViewController.h"


@implementation FileStreamService



-(instancetype) init
{
    if(self = [super init])
    {
        self.isReady = YES;
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.fileName forKey:@"fileName"];
    [aCoder encodeBool:self.useTimestamp forKey:@"useTimestamp"];
    [aCoder encodeBool:self.noClobber forKey:@"noClobber"];
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.fileName = [aDecoder decodeObjectForKey:@"fileName"];
        self.noClobber = [aDecoder decodeBoolForKey:@"noClobber"];
        self.useTimestamp = [aDecoder decodeBoolForKey:@"useTimestamp"];
    }
    
    return self;
}


-(NSViewController *)getConfigurationView
{
 
    FileStreamServiceViewController *configViewController;
    
    configViewController = [[FileStreamServiceViewController alloc] initWithNibName:@"FileStreamServiceViewController" bundle:[NSBundle bundleForClass:self.class]];
    configViewController.serviceObj = self;
    return configViewController;
}



-(NSString *)getServiceFormat
{
    return nil;
}



-(NSString *)getServiceDestination
{
    NSString *useFilename = self.fileName;
    NSString *pathExt = [self.fileName pathExtension];
    NSString *noExt = [useFilename stringByDeletingPathExtension];

    if (self.useTimestamp)
    {
        NSDateFormatter *dFormat = [[NSDateFormatter alloc] init];
        dFormat.dateFormat = @"yyyyMMddHHmmss";
        NSString *dateStr = [dFormat stringFromDate:[NSDate date]];
        useFilename = [NSString stringWithFormat:@"%@-%@.%@", noExt, dateStr, pathExt];
    }
    
    if (self.noClobber)
    {
        noExt = [useFilename stringByDeletingPathExtension];

        NSFileManager *fManager = [[NSFileManager alloc] init];
        NSString *noExt = [useFilename stringByDeletingPathExtension];
        int fidx = 1;
        while ([fManager fileExistsAtPath:useFilename])
        {
            useFilename = [NSString stringWithFormat:@"%@-%d.%@", noExt, fidx, pathExt];
            fidx++;
        }
    }
    return useFilename;
}



+(NSString *)label
{
    return @"File/RTMP";
}


+(NSString *)serviceDescription
{
    return @"File/RTMP";
}

@end
