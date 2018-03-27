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
    [aCoder encodeObject:self.holdDuration forKey:@"holdDuration"];
    [aCoder encodeBool:self.waitForMedia forKey:@"waitForMedia"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.layout = [aDecoder decodeObjectForKey:@"layout"];
        
        self.holdDuration = [aDecoder decodeObjectForKey:@"holdDuration"];
        self.waitForMedia = [aDecoder decodeBoolForKey:@"waitForMedia"];
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

-(void)setHoldDuration:(NSNumber *)holdDuration
{
    _holdDuration = holdDuration;
}


-(NSNumber *)holdDuration
{
    if (_holdDuration)
    {
        return _holdDuration;
    }
    
    return self.duration;
}

-(NSString *)preChangeAction:(SourceLayout *)targetLayout
{
    NSPasteboardItem *layoutItem = [[NSPasteboardItem alloc] init];
    NSData *uuidData = [NSKeyedArchiver archivedDataWithRootObject:self.layout.uuid];
    [layoutItem setData:uuidData forType:@"cocoasplit.layout"];
    
    self.layoutSource = [CaptureController.sharedCaptureController inputSourceForPasteboardItem:layoutItem];
    self.layoutSource.persistent = YES;
    NSMutableString *scriptRet = [NSMutableString string];
    [scriptRet appendString:@"var usePreTrans = null;"];
    if (self.preTransition)
    {
        [scriptRet appendString:@"var actionScript = self.preTransition.preReplaceAction();"];
        [scriptRet appendString:@"if (actionScript) {var prelTrans = (new Function('self', actionScript))(self.preTransition); if (prelTrans) { usePreTrans = prelTrans.transition;} }"];
        [scriptRet appendString:@"self.realPreTransition = usePreTrans;"];
    }
    
    [scriptRet appendString:@"addInputToLayoutForTransition(self.layoutSource, self.realPreTransition);"];

    if (self.preTransition)
    {
        [scriptRet appendString:@"var postPreScript = self.preTransition.postReplaceAction();"];
        [scriptRet appendString:@"if (postPreScript) { (new Function('self', postPreScript))(self.preTransition);}"];
    }
    
    
    if (self.waitForMedia)
    {
        [scriptRet appendString:@"waitAnimation(self.layoutSource.duration);"];
    }
    self.realHoldDuration = self.holdDuration.floatValue;
    
    if (self.realHoldDuration > 0.0f)
    {
        [scriptRet appendString:@"waitAnimation(self.realHoldDuration);"];
    }
    
    return scriptRet;
}


-(NSString *)postChangeAction:(SourceLayout *)targetLayout
{

    NSMutableString *scriptRet = [NSMutableString string];
    [scriptRet appendString:@"var usePostTrans = null;"];

    if (self.postTransition)
    {
        [scriptRet appendString:@"var actionScript = self.postTransition.preRemoveAction();"];
        [scriptRet appendString:@"if (actionScript) {var prerTrans = (new Function('self', actionScript))(self.postTransition); if (prerTrans) { usePostTrans = prerTrans.transition;} }"];
        [scriptRet appendString:@"self.realPostTransition = usePostTrans;"];
    }
    [scriptRet appendString:@"removeInputFromLayout(self.layoutSource, self.realPostTransition);"];
    if (self.postTransition)
    {
        [scriptRet appendString:@"var postPostScript = self.postTransition.postRemoveAction();"];
        [scriptRet appendString:@"if (postPostScript) { (new Function('self', postPostScript))(self.postTransition);}"];
    }
    
    return scriptRet;
}

    




-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController
{
    CSLayoutLayoutTransitionViewController *vc = [[CSLayoutLayoutTransitionViewController alloc] init];
    vc.transition = self;
    return vc;
}


@end
