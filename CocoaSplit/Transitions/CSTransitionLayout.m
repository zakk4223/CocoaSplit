//
//  CSTransitionLayout.m
//  CocoaSplit
//
//  Created by Zakk on 3/19/18.
//

#import "CSTransitionLayout.h"
#import "CaptureController.h"
#import "CSLayoutTransition.h"
#import "CSLayoutLayoutTransitionViewController.h"

@implementation CSTransitionLayout
@synthesize holdDuration = _holdDuration;

-(instancetype) init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutDeleted:) name:CSNotificationLayoutDeleted object:nil];
    }
    return self;
}


-(void)layoutDeleted:(NSNotification *)notification
{
    SourceLayout *deleted = notification.object;
    if (self.layout)
    {
        if ([self.layout.uuid isEqualToString:deleted.uuid])
        {
            self.layout = nil;
            self.active = NO;
        }
    }
}



-(id)copyWithZone:(NSZone *)zone
{
    CSTransitionLayout *newObj = [super copyWithZone:zone];
    if (newObj)
    {
        newObj.layout = self.layout;
    }
    return newObj;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    if (self.layout)
    {
        [aCoder encodeObject:self.layout forKey:@"layout"];
    }
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.layout = [aDecoder decodeObjectForKey:@"layout"];
    }
    return self;
}


+(NSArray *)subTypes
{
    NSMutableArray *ret = [NSMutableArray array];
    for (SourceLayout *layout in CaptureController.sharedCaptureController.sourceLayouts)
    {
        
        
        CSTransitionLayout *newTransition = [[CSTransitionLayout alloc] init];
        newTransition.layout = layout;
        [ret addObject:newTransition];
    }
    return ret;
}



+(NSString *)transitionCategory
{
    return @"Layout";
}


-(NSString *)name
{
    
    NSString *ret = [super name];
    if (!ret && self.layout)
    {
        ret = self.layout.name;
    }
    return ret;
}


-(NSObject<CSInputSourceProtocol> *)getInputSource
{

    NSPasteboardItem *layoutItem = [[NSPasteboardItem alloc] init];
    NSData *uuidData = [NSKeyedArchiver archivedDataWithRootObject:self.layout.uuid];
    [layoutItem setData:uuidData forType:@"cocoasplit.layout"];
    return [CaptureController.sharedCaptureController inputSourceForPasteboardItem:layoutItem];
}





-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController
{
    CSLayoutLayoutTransitionViewController *vc = [[CSLayoutLayoutTransitionViewController alloc] init];
    vc.transition = self;
    return vc;
}


@end
