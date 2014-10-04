//
//  Utils.m
//  ParametricEQ
//
//  Created by Julian Vogels on 29/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import "Utils.h"
#import <AudioToolbox/AudioToolbox.h>

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

+ (float)convertToLogScale:(float)frequency {
    return log10f(frequency)/log10f(PARQ_MAX_F0)*(PARQ_MAX_F0-PARQ_MIN_F0)+PARQ_MIN_F0;
}


// thanks to https://stackoverflow.com/questions/11364997/pick-music-from-ios-library-and-send-save

+(BOOL)coreAudioCanOpenURL:(NSURL*)url{
    
    OSStatus openErr = noErr;
    AudioFileID audioFile = NULL;
    openErr = AudioFileOpenURL((__bridge CFURLRef) url,
                               kAudioFileReadPermission ,
                               0,
                               &audioFile);
    if (audioFile) {
        AudioFileClose (audioFile);
    }
    return openErr ? NO : YES;
    
}

+(float)intepolateValueFrom:(float)valt0 to:(float)valt1 withTimeInstant:(float)t {
        return valt0 + (valt1 - valt0) * t;
}

+(float)convertToLogFrequency:(float)normVal {
    return 20*powf(10, normVal*3.0f);
}

@end
