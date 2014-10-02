//
//  Utils.m
//  ParametricEQ
//
//  Created by Julian Vogels on 29/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import "Utils.h"

@implementation Utils


+ (float)convertToNormF0:(float)frequency{
    return frequency/(PARQ_MAX_F0 / PARQ_MIN_F0);
}


+ (float)convertToNormGain:(float)gain{
    return (gain + fabs(PARQ_MIN_GAIN))/(fabs(PARQ_MIN_GAIN)+fabs(PARQ_MAX_GAIN));
}


+ (float)convertToBandwidth:(float)q{
    long double qsquared = powl(q, 2);
    long double y = ((2.0L*qsquared+1.0L)/(2.0L*qsquared))+
                    sqrtl((powl(((2.0L*qsquared+1.0L)/qsquared), 2)/4.0L)-1.0L); // q factor to bandwidth
    long double bandwidthOctaves = log2l(y); // bandwidth in octaves
    
    return bandwidthOctaves;
}


@end
