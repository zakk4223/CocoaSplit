//
//  CSUndoObjectController.h
//  CocoaSplit
//
//  Created by Zakk on 2/19/18.
//

#import <Cocoa/Cocoa.h>
#import "CSUndoObjectControllerDelegate.h"

@interface CSUndoObjectController : NSObjectController
{
    NSNotificationCenter *_undoNotificationCenter;
    NSNotificationQueue *_undoNotificationQueue;
    NSMutableDictionary *_pausedUndoKeys;
}


@property (weak) id<CSUndoObjectControllerDelegate> undoDelegate;

-(void)pauseUndoForKeyPath:(NSString *)keyPath;
-(void)resumeUndoForKeyPath:(NSString *)keyPath;
@end
