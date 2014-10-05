//
//  JVPeakingEQ.m
//  ParametricEQ
//
//  Created by Julian Vogels on 30/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import "JVPeakingEQ.h"
#import "ParQDSP.h"

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

        [super setCoefficients];
        
        
        // Report back to delegate
        if (delegateRespondsTo.filterCoefficients) {
            float coeffs[5] = {b0, b1, b2, a1, a2};
            [delegate filterCoefficients:coeffs];
        }
    }
}

// Method not used! Attempt to interpolate coefficients
- (void) interpolateCoefficientsWithLBlock:(long)L_block sampleRate:(long)F_s fromSourceCoefficients:(float [5])coefficients_src toDestinationCoefficients:(float [5])coefficients_dest fromSourceGain:(long double)ksrc toDestinationGain:(long double)kdest{
    
    // reference: http://www.dafx.ca/proceedings/papers/p_057.pdf
    
    // PI refers to Parameter Interpolation
    // first we need to calculate N_pi, the *length* of PI, i.e. the total number of updates to complete PI
    // block size of samples to compute one set of coefficients: L_block (denotes update interval)
    
    long double N_ps; // ?? no description of this variable
    long double N_pi; // maybe it's just a typo and they meant N_pi?
    
    // Sample period Ts
    long double T_s = 1/F_s;
    
    // T_pi denotes the time of *duration* of PI
    long double T_pi = N_ps * L_block * T_s;

    // Gain interpolation variable
    long double km;
    
    // -------------------------
    // Denominator Interpolation
    // -------------------------
    
    // Coefficients to be found
    float a1m;
    float a2m;
    
    long double a1src = coefficients_src[3];
    long double a2src = coefficients_src[4];
    
    long double a1dest = coefficients_dest[3];
    long double a2dest = coefficients_dest[4];
    
    // delta values
    long double a1delta = (a1dest - a1src)/N_pi;
    long double a2delta = (a2dest - a2src)/N_pi;

    // calculation see below
    
    // -------------------------
    // Numerator Interpolation
    // -------------------------
    // "Sliding Edges"
    
    // Coefficients to be found
    float b0m; // TBD how to calculate b0?!
    float b1m;
    float b2m;
    
    // determine omega 1 and 2
    long double omega1 = 0.0;
    long double omega2 = F_s/2; // M_PI or Nyquist, F_s/2 needed for function call to ParQDSP
    
    // calculate edge points of starting point (src):
    long double g1src = [ParQDSP performMagnitudeResponseWithCoeffs:coefficients_src sampleRate:F_s andLocation:omega1];
    long double g2src = [ParQDSP performMagnitudeResponseWithCoeffs:coefficients_src sampleRate:F_s andLocation:omega2];
    
    // calculate edge points of destination point (dest):
    long double g1dest = [ParQDSP performMagnitudeResponseWithCoeffs:coefficients_dest sampleRate:F_s andLocation:omega1];
    long double g2dest = [ParQDSP performMagnitudeResponseWithCoeffs:coefficients_dest sampleRate:F_s andLocation:omega2];
    
    // containers for intermediate values
    long double g1m;
    long double g2m;
    
    // delta values
    long double g1delta = (g1dest - g1src)/N_pi;
    long double g2delta = (g2dest - g2src)/N_pi;
    
    
    // -------------------------
    // interpolation steps
    // -------------------------
    
    // Calculating intermediate values with linear law; m denotes the stage of PI
    // TBD this has to be performed in a RunLoop, not a for statement
    // TBD the runloop has to be reset when the function is called again
        for (int m = 0; m < N_pi; m++) {
            // Denominator
            // a_i[m] = a_i_src + m * delta a_i, where delta a_i = (a_i_dest - a_i_src)/N_pi)
            a1m = a1src + m * a1delta;
            a2m = a2src + m * a2delta;
            
            // Numerator
            g1m = g1src + m * g1delta;
            g2m = g2src + m * g2delta;
            km = ksrc + m * (kdest - ksrc)/N_pi;
            
            // b0?
            b1m = ((g1m-g2m)*(1+a2)+(g1m+g2m)*a1)/2*km;
            b2m = ((g1m+g2m)*(1+a2)+(g1m-g2m)*a1)/(2*km-1);
            
            // b0, b1, b2, a1, a2
            float coefficientsm[5] = {b0m, b1m, b2m, a1m, a2m};
            
        }
    
    
    
    
}


@end