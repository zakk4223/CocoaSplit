//
//  CSLayoutTransition.h
//  CocoaSplit
//
//  Created by Zakk on 8/12/17.
//

#import <Foundation/Foundation.h>
#import "SourceLayout.h"


@protocol CSLayoutTransitionExport <JSExport>
@property (assign) bool transitionFullScene;
@property (assign) bool waitForMedia;
@property (strong) CATransition *transition;
+(CSLayoutTransition *)createTransition;
@end

@interface CSLayoutTransition : NSObject <CSLayoutTransitionExport, NSCopying, NSCoding>

@property (assign) bool transitionFullScene;
@property (assign) bool waitForMedia;
@property (strong) CATransition *transition;
+(CSLayoutTransition *)createTransition;



@end


