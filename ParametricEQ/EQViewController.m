//
//  EQViewController.m
//  ParametricEQ
//
//  Created by Julian Vogels on 25/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import "EQViewController.h"

@interface EQViewController ()

@property (assign, nonatomic) RingBuffer *ringBuffer;
@property (assign, nonatomic) float normPanX;
@property (assign, nonatomic) float normPanY;

@end

@implementation EQViewController

// Graphics
@synthesize micButton;
@synthesize eqView;

// Novocaine
@synthesize audioManager;
@synthesize ringBuffer;

@synthesize JVPEF;

// filter params
@synthesize fs;
@synthesize f0;
@synthesize g;
@synthesize q;
@synthesize normPanX;
@synthesize normPanY;


- (void) viewWillAppear:(BOOL)animated {
    
    __weak EQViewController *wself = self;
    
    self.isRealTimeAudio = NO;
    
    // TBD those should be constants
    f0 = 1000.0f;
    g = 20.0f;
    q = 3.0f;
    
    
    _frequencyLocations = [[NSMutableArray alloc] initWithCapacity:PARQ_CURVE_ACCURACY];
    _magnitudesAtLocations = [[NSMutableArray alloc] initWithCapacity:PARQ_CURVE_ACCURACY];
    double frequencyPoint;
    
    for (int i = 0; i <= PARQ_CURVE_ACCURACY; i++) {
        frequencyPoint = ((double)PARQ_MAX_F0-(double)PARQ_MIN_F0)/((double)PARQ_CURVE_ACCURACY)*((double)i);
        //        NSLog(@"frequencypoint: %ld \n", frequencyPoint);
        [_frequencyLocations insertObject:[NSNumber numberWithDouble:frequencyPoint] atIndex:i];
        [_magnitudesAtLocations insertObject:[NSNumber numberWithDouble:0.0L] atIndex:i];
    }
    
    NSLog(@"magnitudeArray:\t%@", _magnitudesAtLocations);
    
    
    [self initNovocaine:(EQViewController *)wself];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Novocaine / DSP Methods

-(void) initNovocaine:(EQViewController *)wself {
    
    ringBuffer = new RingBuffer(32768, 2);
    audioManager = [Novocaine audioManager];
    fs = audioManager.samplingRate;
    
    
    __block float dbVal = 0.0;
    __block float normVal = 0.0;
    __weak UIButton *wmicButton = micButton;
    
    
    // initialize audio file reader
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"apfelsinen" withExtension:@"m4a"];
    
    
    // NVDSP Peaking EQ Filter init
    JVPEF = [[JVPeakingEQ alloc] initWithSamplingRate:audioManager.samplingRate];
    JVPEF.sampleRate = self.audioManager.samplingRate;
    
    JVPEF.delegate = self;
    JVPEF.centerFrequency = PARQ_DEFAULTS_F0;
    JVPEF.Q = PARQ_DEFAULTS_Q;
    JVPEF.G = PARQ_DEFAULTS_G;
    NSLog(@"Gs: JVPEF: %f g: %f", JVPEF.G, self.g);
    
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        
        if ([wself isRealTimeAudio]) {
            //        float volume = 0.5;
            //        vDSP_vsmul(data, 1, &volume, data, 1, numFrames*numChannels);
            wself.ringBuffer->AddNewInterleavedFloatData(data, numFrames, numChannels);
            
            
            // TDB [ut into utlity function
            vDSP_vsq(data, 1, data, 1, numFrames*numChannels);
            float meanVal = 0.0;
            vDSP_meanv(data, 1, &meanVal, numFrames*numChannels);
            normVal = meanVal;
            float one = 1.0;
            vDSP_vdbcon(&meanVal, 1, &one, &meanVal, 1, 1, 0);
            dbVal = dbVal + 0.2*(meanVal - dbVal);
            
            normVal *= 10;
            if (normVal > 1.0) {
                normVal = 1.0;
            }
            
            //printf("Decibel level: %f\t%f\n", dbVal, normVal);
            dispatch_async(dispatch_get_main_queue(), ^{
                [wmicButton setBackgroundColor:[UIColor colorWithRed:0 green:1 blue:0 alpha:normVal]];
                
            });
        }
    }];
    
    
    //    __weak __block NSMutableArray *wCoeffs = _coeffs;
    
    if (![self isRealTimeAudio]) {
        _fileReader = [[AudioFileReader alloc]
                       initWithAudioFileURL:fileUrl
                       samplingRate:audioManager.samplingRate
                       numChannels:audioManager.numOutputChannels];
        
        [_fileReader play];
    }
    
    // Adjust filter settings (initialization)
    //    [self adjustFilterWithCenterFrequency:f0 dbGain:g Q:q];
    
    
    [self.audioManager setOutputBlock:^(float *outData, UInt32 numFrames, UInt32 numChannels) {
        if ([wself isRealTimeAudio]) {
            wself.ringBuffer->FetchInterleavedData(outData, numFrames, numChannels);
        } else {
            [wself.fileReader retrieveFreshAudio:outData numFrames:numFrames numChannels:numChannels];
        }
        
        [wself.JVPEF filterData:outData numFrames:numFrames numChannels:numChannels];
        
    }];
    
    
    [audioManager play];
}


- (NSMutableArray *) calculateCoefficientsWithF0:(float)frequency dbGain:(float)gain Q:(float)qfactor {
    if (!frequency) {
        frequency = f0;
    }
    if (!gain) {
        gain = g;
    }
    if (!qfactor) {
        qfactor = q;
    }
    if (!(frequency <= PARQ_MIN_F0) && !(qfactor <= 0.0f) &&
        !(frequency > PARQ_MAX_F0) && !(qfactor > PARQ_MAX_Q)) {
        
        // thanks to https://dsp.stackexchange.com/questions/3091/plotting-the-magnitude-response-of-a-biquad-filter
        
        // conversion dbGain
        long double A = powl(10.0L, gain/40.0L);
        // normalize frequency
        long double omega0 = 2.0L * M_PI * frequency / fs;
        // alpha from q
        long double alpha = sinl(omega0) / (2*qfactor);
        NSLog(@"alpha1:\t%LF", alpha);
        // alpha from bandwidth
        long double y = ((2.0L*powl(qfactor, 2)+1.0L)/(2.0L*powl(qfactor, 2)))+sqrtl((powl(((2.0L*powl(qfactor, 2)+1.0L)/(powl(qfactor, 2))), 2)/4.0L)-1.0L); // q factor to bandwidth
        long double bandwidthOctaves = log2l(y); // bandwidth in octaves
        long double alpha2 = sinl(omega0)*sinhl( ((logl(2.0L))/2.0L * bandwidthOctaves * omega0/sinl(omega0)));
        NSLog(@"alpha2:\t%LF", alpha2);
        
        _a0 = (1  + (alpha / A));
        _b0 = (1 + (alpha * A))             / _a0;
        _b1 = (-2 * cosl(omega0))           / _a0;
        _b2 = (1 - (alpha * A))             / _a0;
        _a1 = (-2 * cosl(omega0))           / _a0;
        _a2 = (1 - alpha / A)               / _a0;
        
        
        NSLog(@"coeffEQ:\t%f\t%f\t%f\t%f\t%f\t%f", _b0, _b1, _b2, _a0, _a1, _a2);
        
        NSMutableArray *coefficients = [[NSMutableArray alloc] initWithObjects:
                                        [NSNumber numberWithDouble:_b0],
                                        [NSNumber numberWithDouble:_b1],
                                        [NSNumber numberWithDouble:_b2],
                                        [NSNumber numberWithDouble:_a1],
                                        [NSNumber numberWithDouble:_a2],
                                        nil];
        
        
        // Store new settings:
        f0 = frequency;
        g = gain;
        q = qfactor;
        
        NSLog(@"Coefficients:\t%@", coefficients);
        
        return coefficients;
        
    } else {
        NSLog(@"WARNING: either f0 or q out of bounds");
        return nil;
    }
    
}

- (NSMutableArray *) calculateBiquadMagnitudeResponseWithCoeffs:(float [5])coeffs {
    
    // Declaration of magnitude vars
    long double omega;
    long double numerator;
    long double denominator;
    long double magnitude;
    long double b0, b1, b2, a1, a2;
    
    NSMutableArray *points = [[NSMutableArray alloc] initWithCapacity:[_frequencyLocations count]];
    
    b0 = coeffs[0];
    b1 = coeffs[1];
    b2 = coeffs[2];
    a1 = coeffs[3];
    a2 = coeffs[4];
    
    //    NSLog(@"----------------");
    //    NSLog(@"Params: f0: %f\t g: %f\t q %f", JVPEF.centerFrequency, JVPEF.G, JVPEF.Q);
    //    NSLog(@"Coeffs: b0 %f\t b1 %f\t b2 %f\t a1 %f\t a2 %f", coeffs[0], coeffs[1], coeffs[2], coeffs[3], coeffs[4]);
    //    NSLog(@"----------------");
    
    // calculate biquad magnitude for n frequency points
    for (int i = 0; i < [_frequencyLocations count]; ++ i) {
        
        // convert frequency points to normalized frequency on unit circle
        omega = 2.0L*M_PI*[[_frequencyLocations objectAtIndex:i] doubleValue] / fs;
        // biquad magnitude response (http://rs-met.com/documents/dsp/BasicDigitalFilters.pdf p.2)
        numerator = powl(b0, 2) + powl(b1, 2) + powl(b2, 2) + 2.0L*(b0*b1 + b1*b2)*cosl(omega) + 2.0L*b0*b2*cosl(2.0L*omega);
        denominator = 1.0L + powl(a1, 2) + powl(a2, 2) + 2.0L*(a1 + a1*a2)*cosl(omega) + 2.0L*a2*cosl(2.0L*omega);
        magnitude = sqrtl(numerator / denominator);
        //        NSLog(@"1 FreqPoint: %f\tomega:\t%LF\tnumerator:\t%LF\tdenominator:\t%LF\tmagnitude:\t%LF",[[_frequencyLocations objectAtIndex:i] doubleValue], omega, numerator, denominator, magnitude);
        // Store the magnitude response in an array to be used for display (after interpolation)
        omega = 2.0L*M_PI*[[_frequencyLocations objectAtIndex:i] doubleValue] / JVPEF.sampleRate;
        numerator = b0*b0 + b1*b1 + b2*b2 + 2.0L*(b0*b1 + b1*b2)*cosl(omega) + 2.0L*b0*b2*cosl(2.0L*omega);
        denominator = 1.0L + a1*a1 + a2*a2 + 2.0L*(a1 + a1*a2)*cosl(omega) + 2.0L*a2*cosl(2.0L*omega);
        magnitude = sqrtl(numerator / denominator);
        //        NSLog(@"2 FreqPoint: %f\tomega:\t%LF\tnumerator:\t%LF\tdenominator:\t%LF\tmagnitude:\t%LF",[[_frequencyLocations objectAtIndex:i] doubleValue], omega, numerator, denominator, magnitude);
        
        CGFloat x = ([[_frequencyLocations objectAtIndex:i] floatValue]/(PARQ_MAX_F0-PARQ_MIN_F0))*eqView.frame.size.width;
        CGFloat y = (1.0f-[Utils convertToNormGain:20.0f*log10f(magnitude)])*eqView.frame.size.height;
        if (isnan(y)) {
            y = 0.0f;
            NSLog(@"WARNING: caught NaN in calculateBiquadMagnitudeResponseWithCoeffs");
        }
        
        [points insertObject:[NSValue valueWithCGPoint:CGPointMake(x, y)] atIndex:i];
    }
    
    return points;
    
}


#pragma mark -
#pragma mark JVPeakingEQ delegate methods

- (void) filterCoefficients:(float [5])coeffs {
    //    NSLog(@"Coeffs:%f%f%f%f%f", coeffs[0], coeffs[1], coeffs[2], coeffs[3], coeffs[4]);
    [self.eqView adjustGraph];
    self.eqView.points = [self calculateBiquadMagnitudeResponseWithCoeffs:coeffs];
    [self.eqView setNeedsDisplay];
}

#pragma mark -
#pragma mark UI Methods

- (IBAction)micButtonTouchUpInside:(id)sender {
    // TBD switch mic on
    [micButton setSelected:![micButton isSelected]];
    if ([micButton isSelected])
    {
        [micButton setTintColor:[UIColor greenColor]];
    } else {
        [micButton setTintColor:[UIColor colorWithRed:0.4352 green:0 blue:255 alpha:1]];
    }
    NSLog(@"Frequency Locations:\t%@\n", self.frequencyLocations);
    for (int i = 0; i < [_frequencyLocations count]; i++) {
        NSLog(@"%f\n",[[_frequencyLocations objectAtIndex:i] floatValue]);
    }
    NSLog(@"Magnitude:\t%@", self.magnitudesAtLocations);
    
}

- (IBAction)pinchGesture:(UIPinchGestureRecognizer *)sender {
    CGFloat scale = [sender scale];
    NSLog(@"Scale: %f", scale);
    // local q and then assign
    float qfactor = JVPEF.Q;
    if (scale < 1.0f && scale > 0.0f && qfactor >= 0.0f) {
        qfactor = qfactor-((1-scale)/10);
    } else if (scale > 1.0f && qfactor <= PARQ_MAX_Q) {
        qfactor = qfactor+((scale-1)/10);
    }
    if ([_qButton isSelected]) {
        [self.qLabel setText:[NSString stringWithFormat:@"%.2f", [Utils convertToBandwidth:qfactor]]];
    } else {
        [self.qLabel setText:[NSString stringWithFormat:@"%.2f", qfactor]];
    }
    JVPEF.Q = qfactor;
    
    [self updateEQView];
}

- (IBAction)qButtonTouchUpInside:(id)sender {
    [_qButton setSelected:![_qButton isSelected]];
    if ([_qButton isSelected]) {
        //        [_qButton setTitle:@"BW" forState:UIControlStateNormal];
        [self.qLabel setText:[NSString stringWithFormat:@"%.2f", [Utils convertToBandwidth:JVPEF.Q]]];
    } else {
        [self.qLabel setText:[NSString stringWithFormat:@"%.2f", JVPEF.Q]];
    }
}

- (IBAction)panGesture:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:eqView];
    
    normPanX = (point.x/eqView.bounds.size.width);
    normPanY = (point.y/eqView.bounds.size.height);
    NSLog(@"Point: %f\t%f\tProcessed:\t%f\t%f", point.x, point.y, normPanX, normPanY);
    
    [self updateCenterFrequency:normPanX];
    
    [self updateGain:normPanY];
    
    // Update EQView once
    [self updateEQView];
}



- (void) updateCenterFrequency:(float)normF0{
    if (normF0 < 0.0f) {
        normF0 = 0.0f;
    } else if (normF0 > 1.0f) {
        normF0 = 1.0f;
    }
    
    float absoluteFreq =normF0*(PARQ_MAX_F0-PARQ_MIN_F0);
    
    //    [self adjustFilterWithCenterFrequency:absoluteFreq dbGain:g Q:q];
    JVPEF.centerFrequency = absoluteFreq;
    
    [self.freqLabel setText:[NSString stringWithFormat:@"%.0f Hz", absoluteFreq]];
}

- (void) updateGain:(float)normGain{
    if (normGain < 0.0f) {
        normGain = 0.0f;
    } else if (normGain > 1.0f) {
        normGain = 1.0f;
    }
    
    float dbGain = ((1-normGain)-fabs(PARQ_MIN_GAIN)/(fabs(PARQ_MIN_GAIN)+fabs(PARQ_MAX_GAIN)))*(fabs(PARQ_MAX_GAIN)+fabs(PARQ_MIN_GAIN));
    
    //    [self adjustFilterWithCenterFrequency:f0 dbGain:dbGain Q:q];
    JVPEF.G = dbGain;
    
    [self.gainLabel setText:[NSString stringWithFormat:@"%.2f dB", dbGain]];
}

- (void) updateEQView {
    NSLog(@"upadtyah");
    [eqView setNeedsDisplay];
}
@end
