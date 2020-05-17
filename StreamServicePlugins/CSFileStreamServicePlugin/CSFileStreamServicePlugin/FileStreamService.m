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
        self.segmentCount = NULL;
        self.segmentTime = NULL;
        self.forceFormat = NULL;
    }
    return self;
}


-(BOOL)segmentFile
{
    return self.segmentTime || self.segmentCount;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.fileName forKey:@"fileName"];
    [aCoder encodeBool:self.useTimestamp forKey:@"useTimestamp"];
    [aCoder encodeBool:self.noClobber forKey:@"noClobber"];
    [aCoder encodeObject:self.segmentCount forKey:@"segmentCount"];
    [aCoder encodeObject:self.segmentTime forKey:@"segmentTime"];
    [aCoder encodeObject:self.forceFormat forKey:@"forceFormat"];
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.fileName = [aDecoder decodeObjectForKey:@"fileName"];
        self.noClobber = [aDecoder decodeBoolForKey:@"noClobber"];
        self.useTimestamp = [aDecoder decodeBoolForKey:@"useTimestamp"];
        self.forceFormat = [aDecoder decodeObjectForKey:@"forceFormat"];
        self.segmentCount = [aDecoder decodeObjectForKey:@"segmentCount"];
        self.segmentTime = [aDecoder decodeObjectForKey:@"segmentTime"];
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
    
    if (self.segmentFile)
    {
        return @"segment";
    }
    
    if (self.forceFormat)
    {
        return self.forceFormat;
    }
    
    return nil;
}


-(NSObject <CSOutputWriterProtocol> *)createOutput:(NSString *)forLayout
{
    NSObject<CSOutputWriterProtocol>*ret = [super createOutput];
    if (self.segmentFile)
    {
        NSMutableArray *outOpts = [NSMutableArray array];
        if (self.segmentTime)
        {
            [outOpts addObject:[NSString stringWithFormat:@"segment_time:%@", self.segmentTime]];
        }
        
        if (self.segmentCount)
        {
            [outOpts addObject:[NSString stringWithFormat:@"segment_wrap:%@", self.segmentCount]];
        }
        
        if (self.forceFormat)
        {
            [outOpts addObject:[NSString stringWithFormat:@"segment_format:%@", self.forceFormat]];
        }
        
        
        if (outOpts.count > 0)
        {
            ret.privateOptions = [outOpts componentsJoinedByString:@","];
        }
        
    }
    
    return ret;
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
        noExt = [NSString stringWithFormat:@"%@-%@", noExt, dateStr];
    }
    

    
    if (self.segmentFile)
    {
        noExt = [NSString stringWithFormat:@"%@-%%03d", noExt];
    }
    
    
    useFilename = [NSString stringWithFormat:@"%@.%@", noExt, pathExt];
    
    
    if (self.noClobber && !self.segmentFile)
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
    return @"File";
}


+(NSString *)serviceDescription
{
    return @"File";
}

+(NSImage *)serviceImage
{
    return [NSImage imageNamed:NSImageNameFolder];
}


-(void)prepareForStreamStart
{
    return;
}

@end
