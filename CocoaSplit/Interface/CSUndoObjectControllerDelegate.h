//
//  CSUndoObjectControllerDelegate.h
//  CocoaSplit
//
//  Created by Zakk on 2/19/18.
//

#import <Foundation/Foundation.h>

@protocol CSUndoObjectControllerDelegate <NSObject>

-(void)performUndoForKeyPath:(NSString *)keyPath usingValue:(id)usingValue;

@end
