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
// Utils

#import "Utils.h"

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
-(NSMutableArray *)calculateBiquadMagnitudeResponseWithCoeffs:(float [5])coeffs Locations:(NSMutableArray *)locations inRect:(CGRect)rect;
+(long double) performMagnitudeResponseWithCoeffs:(float [5])coeffs sampleRate:(float)fs andLocation:(long double)frequencyPoint;

@end
