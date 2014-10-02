//
//  Utils.h
//  ParametricEQ
//
//  Created by Julian Vogels on 29/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//
#import "constant.h"
#import <Foundation/Foundation.h>

@interface Utils : NSObject

+(float)convertToNormF0:(float)frequency;
+(float)convertToNormGain:(float)gain;
+(float)convertToBandwidth:(float)q;



@end