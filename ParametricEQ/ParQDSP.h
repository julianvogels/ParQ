//
//  ParQDSP.h
//  ParametricEQ
//
//  Created by Julian Vogels on 02/10/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import <Foundation/Foundation.h>

// Novocaine DSP
#import <Novocaine/Novocaine.h>
#import <Novocaine/AudioFileReader.h>
#import <Novocaine/RingBuffer.h>
// NVDSP
#import <NVDSP/NVPeakingEQFilter.h>
#import <NVDSP/NVDSP.h>
#import <Accelerate/Accelerate.h>
// Custom Class
#import "JVPeakingEQ.h"

// Delegate protocol
//@protocol ParQDSPDelegate <NSObject>
//
//@optional
//- (void) updateLevelMeter:(float)level;
//@end



@interface ParQDSP : NSObject

@property (nonatomic, weak) id <JVPeakingEQDelegate> delegate;

// Samplerate
@property (assign, nonatomic) float fs;

// Novocaine
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) AudioFileReader *fileReader;
@property (strong, nonatomic) JVPeakingEQ *JVPEF;

-(void)initDSP;
-(void)setupFilterWithMicInput;
-(void)setupFilterWithSoundFileURL:(NSURL *)fileUrl;


@end
