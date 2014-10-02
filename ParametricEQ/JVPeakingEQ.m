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

//    if (!(centerFrequency <= PARQ_MIN_F0) && !(Q <= 0.0f) &&
//        !(centerFrequency > PARQ_MAX_F0) && !(Q > PARQ_MAX_Q)) {
//        
//        // thanks to https://dsp.stackexchange.com/questions/3091/plotting-the-magnitude-response-of-a-biquad-filter
//        
//        // conversion dbGain
//        long double A = powl(10.0L, G/40.0L);
//        // normalize frequency
//        long double omega0 = 2.0L * M_PI * centerFrequency / self.sampleRate;
//        // alpha from q
//        long double alpha_ = sinl(omega0) / (2*Q);
////        NSLog(@"alpha1:\t%LF", alpha_);
//        // alpha from bandwidth
//        long double y = ((2.0L*powl(Q, 2)+1.0L)/(2.0L*powl(Q, 2)))+sqrtl((powl(((2.0L*powl(Q, 2)+1.0L)/(powl(Q, 2))), 2)/4.0L)-1.0L); // q factor to bandwidth
//        long double bandwidthOctaves = logl(y)/logl(2.0f); // bandwidth in octaves
//        long double alpha2 = sinl(omega0)*sinhl( ((logl(2.0L)/logl(M_E))/2.0L * bandwidthOctaves * omega0/sinl(omega0)));
////        NSLog(@"alpha2:\t%LF", alpha2);
//        
//        
//        A = sqrt(pow(10.0f, (G/20.0f)));
//        
//        a0 = (1  + (alpha_ / A));
//        b0 = (1 + (alpha_ * A))             / a0;
//        b1 = (-2 * cosl(omega0))           / a0;
//        b2 = (1 - (alpha_ * A))             / a0;
//        a1 = (-2 * cosl(omega0))           / a0;
//        a2 = (1 - alpha_ / A)               / a0;
//        
//        [super setCoefficients];
//    }
    if ((centerFrequency != 0.0f) && (Q != 0.0f)) {
        
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
        
        if (delegateRespondsTo.filterCoefficients) {
            float coeffs[5] = {b0, b1, b2, a1, a2};
            [delegate filterCoefficients:coeffs];
        }
    }
}




@end