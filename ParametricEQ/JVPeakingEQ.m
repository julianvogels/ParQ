//
//  JVPeakingEQ.m
//  ParametricEQ
//
//  Created by Julian Vogels on 30/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import "JVPeakingEQ.h"

@implementation JVPeakingEQ {
    struct {
        unsigned int filterCoefficients:1;
    } delegateRespondsTo;
}
@synthesize delegate;

- (void)setDelegate:(id <JVPeakingEQDelegate>)aDelegate {
    if (delegate != aDelegate) {
        delegate = aDelegate;
        
        delegateRespondsTo.filterCoefficients = [delegate respondsToSelector:@selector(filterCoefficients:)];
    }
}

@synthesize Q;
@synthesize centerFrequency;
@synthesize G;

- (void) setQ:(float)_Q {
    Q = _Q;
    [self calculateCoefficients];
    
}

- (void) setG:(float)_G {
    G = _G;
    [self calculateCoefficients];
}

- (void) setCenterFrequency:(float)_centerFrequency {
    centerFrequency = _centerFrequency;
    [self calculateCoefficients];
}

- (void) calculateCoefficients {

    if (!(centerFrequency <= PARQ_MIN_F0) && !(Q <= 0.0f) &&
        !(centerFrequency > PARQ_MAX_F0) && !(Q > PARQ_MAX_Q)) {

        omega = 2*M_PI*centerFrequency/samplingRate;
        omegaS = sin(omega);
        omegaC = cos(omega);
        alpha = omegaS / (2*Q);
        
        float A = sqrt(pow(10.0f, (G/20.0f)));
        
        a0 = (1  + (alpha / A));
        b0 = (1 + (alpha * A))     / a0;
        b1 = (-2 * omegaC)         / a0;
        b2 = (1 - (alpha * A))     / a0;
        a1 = (-2 * omegaC)         / a0;
        a2 = (1 - alpha / A)       / a0;
//        NSLog(@"coeffJVPEF:\t%f\t%f\t%f\t%f\t%f\t%f", b0, b1, b2, a0, a1, a2);
        [super setCoefficients];
        
        
        // Report back to delegate
        if (delegateRespondsTo.filterCoefficients) {
            float coeffs[5] = {b0, b1, b2, a1, a2};
            [delegate filterCoefficients:coeffs];
        }
    }
}




@end