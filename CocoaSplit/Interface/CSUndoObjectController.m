//
//  CSUndoObjectController.m
//  CocoaSplit
//
//  Created by Zakk on 2/19/18.
//

#import "CSUndoObjectController.h"

@implementation CSUndoObjectController



-(void)awakeFromNib
{
    if (!_undoNotificationCenter)
    {
        _undoNotificationCenter = [[NSNotificationCenter alloc] init];
        _undoNotificationQueue = [[NSNotificationQueue alloc] initWithNotificationCenter:_undoNotificationCenter];
        [_undoNotificationCenter addObserver:self selector:@selector(undoNotification:) name:nil object:nil];
    }
    
    _pausedUndoKeys = [NSMutableDictionary dictionary];
}

-(void)undoNotification:(NSNotification *)notification
{
    NSString *keyPath = notification.name;
    id propValue = notification.object;
    
    if (self.undoDelegate)
    {
        [self.undoDelegate performUndoForKeyPath:keyPath usingValue:propValue];
    }
}


-(void)dealloc
{
    if (_undoNotificationCenter)
    {
        [_undoNotificationCenter removeObserver:self];
    }
}


-(void)registerUndoForProperty:(NSString *)propName
{
    
    if ([_pausedUndoKeys valueForKey:propName])
    {
        return;
    }
    
    id propertyValue = [self valueForKeyPath:propName];
    
    NSNotification *undoNotification = [NSNotification notificationWithName:propName object:propertyValue];
    [_undoNotificationQueue enqueueNotification:undoNotification postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];

}

-(void)pauseUndoForKeyPath:(NSString *)keyPath
{
    [_pausedUndoKeys setObject:@(YES) forKey:keyPath];
}


-(void)resumeUndoForKeyPath:(NSString *)keyPath
{
    [_pausedUndoKeys removeObjectForKey:keyPath];
}

-(void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    [self registerUndoForProperty:keyPath];
    [super setValue:value forKeyPath:keyPath];
}
@end
