//
//  JVPeakingEQ.h
//  ParametricEQ
//
//  Created by Julian Vogels on 30/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import "NVDSP.h"
#import "constant.h"

@protocol JVPeakingEQDelegate <NSObject>

@optional
- (void) updateLevelMeter:(float)level;
- (void) filterCoefficients:(float [5])coeffs;
@end

@interface JVPeakingEQ : NVDSP 

@property (nonatomic, weak) id <JVPeakingEQDelegate> delegate;
@property (nonatomic, assign, setter=setCenterFrequency:) float centerFrequency;
@property (nonatomic, assign, setter=setQ:) float Q;
@property (nonatomic, assign, setter=setG:) float G;
@property (nonatomic, assign) float sampleRate;

- (void) calculateCoefficients;

@end
