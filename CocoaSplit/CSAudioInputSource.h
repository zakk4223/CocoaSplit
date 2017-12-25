//
//  CSAudioInputSource.h
//  CocoaSplit
//
//  Created by Zakk on 7/5/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSInputSourceBase.h"
#import "CAMultiAudioEngine.h"

@interface CSAudioInputSource : CSInputSourceBase
{
    
    NSMutableDictionary *_previousSaveData;
    NSMutableDictionary *_savedAudioSettings;
    
    float _previousVolume;
    bool _previousEnabled;
}

@property (strong) NSString *audioUUID;
@property (assign) float audioVolume;
@property (assign) bool audioEnabled;
@property (strong) CAMultiAudioInput *audioNode;
@property (strong) NSString *audioFilePath;
@property (assign) bool fileLoop;
@property (assign) Float64 fileStartTime;
@property (assign) Float64 fileEndTime;
@property (assign) Float64 fileDuration;


-(instancetype) initWithAudioNode:(CAMultiAudioNode *)node;
-(instancetype) initWithPath:(NSString *)path;

@end

