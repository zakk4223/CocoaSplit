//
//  CSNDISource.m
//  CSNDICapturePlugin
//
//  Created by Zakk on 1/19/18.
//

#import "CSNDISource.h"
#import "CSNDICapture.h"

@implementation CSNDISource


-(instancetype)initWithSource:(NDIlib_source_t)source
{
    if (self = [self init])
    {
        _ndiSource = source;
    }
    
    return self;
}

-(NSString *)name
{
    return [NSString stringWithUTF8String:_ndiSource.p_ndi_name];
}

-(NSString *)ipaddress
{
    return [NSString stringWithUTF8String:_ndiSource.p_ip_address];
}


@end
