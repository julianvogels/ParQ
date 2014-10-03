//
//  EQViewController.m
//  ParametricEQ
//
//  Created by Julian Vogels on 25/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import "EQViewController.h"

@interface EQViewController ()

@property (assign, nonatomic) float normPanX;
@property (assign, nonatomic) float normPanY;

@end

@implementation EQViewController

// Graphics
@synthesize micButton;
@synthesize soundFileButton;
@synthesize eqView;

// ParQDSP
@synthesize dsp;

// filter params
@synthesize normPanX;
@synthesize normPanY;


- (void) viewWillAppear:(BOOL)animated {
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Calculate frequency points for curve
    _frequencyLocations = [[NSMutableArray alloc] initWithCapacity:PARQ_CURVE_ACCURACY];
    NSMutableArray *defaultPoints = [[NSMutableArray alloc] initWithCapacity:PARQ_CURVE_ACCURACY];
    double frequencyPoint;
    double frequencyLogPoint;
    
    for (int i = 0; i <= PARQ_CURVE_ACCURACY; i++) {
        frequencyPoint = PARQ_MIN_F0+((double)PARQ_MAX_F0-(double)PARQ_MIN_F0)/((double)PARQ_CURVE_ACCURACY)*((double)i);
        // x'i = (log(xi)-log(xmin)) / (log(xmax)-log(xmin))
        
//        frequencyLogPoint = PARQ_MIN_F0+(logf((double)PARQ_MAX_F0)/logf((double)PARQ_MIN_F0))/(logf((double)PARQ_MAX_F0)-logf((double)PARQ_MIN_F0))/((double)PARQ_CURVE_ACCURACY)*((double)i);
        
        frequencyLogPoint = log10f(frequencyPoint);
        
//        frequencyLogPoint = frequencyPoint;
        
        NSLog(@"frequencypoint: %f log: %f \n", frequencyPoint, frequencyLogPoint);
        
        [_frequencyLocations insertObject:[NSNumber numberWithDouble:frequencyLogPoint] atIndex:i];
        [defaultPoints insertObject:[NSValue valueWithCGPoint:CGPointMake(frequencyLogPoint, [Utils convertToNormGain:0.0f])] atIndex:i];
    }
    self.eqView.points = defaultPoints;
    [eqView setNeedsDisplay];
    
    // Initialize UI
    [_freqLabel setText:[NSString stringWithFormat:@"%.0f Hz", PARQ_DEFAULTS_F0]];
    [_gainLabel setText:[NSString stringWithFormat:@"%.2f db", PARQ_DEFAULTS_G]];
    [_qLabel    setText:[NSString stringWithFormat:@"%.2f",    PARQ_DEFAULTS_Q]];
    
    // Initialize DSP
    dsp = [[ParQDSP alloc] init];
    dsp.delegate = self;
    [dsp initDSP];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Filter Graph Methods

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
        float logFreqPointinHz = (([[_frequencyLocations objectAtIndex:i] doubleValue]/log10f(PARQ_MAX_F0))*(PARQ_MAX_F0-PARQ_MIN_F0));
        omega = 2.0L*M_PI*logFreqPointinHz / dsp.fs;
        
        // biquad magnitude response (http://rs-met.com/documents/dsp/BasicDigitalFilters.pdf p.2)
        numerator = powl(b0, 2) + powl(b1, 2) + powl(b2, 2) + 2.0L*(b0*b1 + b1*b2)*cosl(omega) + 2.0L*b0*b2*cosl(2.0L*omega);
        denominator = 1.0L + powl(a1, 2) + powl(a2, 2) + 2.0L*(a1 + a1*a2)*cosl(omega) + 2.0L*a2*cosl(2.0L*omega);
        magnitude = sqrtl(numerator / denominator);
        
        //        NSLog(@"FreqPoint: %f\tomega:\t%LF\tnumerator:\t%LF\tdenominator:\t%LF\tmagnitude:\t%LF",[[_frequencyLocations objectAtIndex:i] doubleValue], omega, numerator, denominator, magnitude);
        
        // Calculating absolute x value
        CGFloat x10 = pow(10, [[_frequencyLocations objectAtIndex:i] floatValue]);
        // Value over frequency range times actual width of the view
        CGFloat x = (x10/(PARQ_MAX_F0-PARQ_MIN_F0))*(eqView.frame.size.width-2*PARQ_MARGIN_X);
        
        //        CGFloat logmax = log10f(PARQ_MAX_F0 / PARQ_MIN_F0);
        //        CGFloat X = eqView.frame.size.width * log10f([[_frequencyLocations objectAtIndex:i] floatValue] / PARQ_MIN_F0) / logmax;
        //        CGFloat v = PARQ_MIN_F0 * 10 * (logmax * X / eqView.frame.size.width);
        //        NSLog(@"Value: %f", v);
        
        // Calculating absolute y value
        CGFloat y = (1.0f-[Utils convertToNormGain:20.0f*log10f(magnitude)])*eqView.frame.size.height;
        
        if (isnan(y)) {
            y = 0.0f;
            NSLog(@"WARNING: caught NaN in calculateBiquadMagnitudeResponseWithCoeffs");
        }
        
        [points insertObject:[NSValue valueWithCGPoint:CGPointMake(x, y)] atIndex:i];
    }
    
//    NSLog(@"Points array: %@", points);
    
    return points;
    
}

#pragma mark -
#pragma mark JVPeakingEQ delegate methods

- (void) filterCoefficients:(float [5])coeffs {
    //        NSLog(@"Coeffs:%f%f%f%f%f", coeffs[0], coeffs[1], coeffs[2], coeffs[3], coeffs[4]);
    self.eqView.points = [self calculateBiquadMagnitudeResponseWithCoeffs:coeffs];
    [self.eqView setNeedsDisplay];
}

#pragma mark -
#pragma mark MPMediaPickerController delegate methods

-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if ([mediaItemCollection count] < 1) {
        return;
    }
    
    MPMediaItem *item = [[mediaItemCollection items] objectAtIndex:0];
    
    if (!item) {
        return;
    }
    
    NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
    
    // Some error handling and notification
    if (![Utils coreAudioCanOpenURL:assetURL]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"File Read Error"
                                                        message:@"Sorry, the file you chose has an unsupported format."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
        
    } else {
        NSLog(@"AudioAssetURL: %@", assetURL);
        [dsp setupFilterWithSoundFileURL:assetURL];
    }
    
    
}

-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    
    // just dismiss
    [self dismissViewControllerAnimated:YES completion:nil ];
}

#pragma mark -
#pragma mark UI Methods

- (void) updateLevelMeter:(float)levelMeter {
    [micButton setBackgroundColor:[UIColor colorWithRed:0 green:1 blue:0 alpha:levelMeter]];
}


- (IBAction)micButtonTouchUpInside:(id)sender {
    if (([soundFileButton isSelected]&&![micButton isSelected]) || (![soundFileButton isSelected]&&![micButton isSelected])) {
        [micButton setSelected:YES];
        [soundFileButton setSelected:NO];

        [dsp.fileReader pause];
        [dsp.audioManager pause];
        [dsp setupFilterWithMicInput];
        NSLog(@"micbutton");
    }
}

- (IBAction)SoundFileButtonTouchUpInside:(id)sender {
    NSLog(@"soundfilebutton");
    [soundFileButton setSelected:YES];
    [micButton setSelected:NO];
    
    [dsp.fileReader pause];
    [dsp.audioManager pause];
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    mediaPicker.delegate = self;
    [self presentViewController:mediaPicker animated:YES completion:nil];
    
    // possible memory issue to look into: https://stackoverflow.com/questions/19493355/novocaine-loading-files-from-ipod-library-memory-issue
    
}


- (IBAction)pinchGesture:(UIPinchGestureRecognizer *)sender {
    CGFloat scale = [sender scale];
    NSLog(@"Scale: %f", scale);
    // local q and then assign
    float qfactor = dsp.JVPEF.Q;
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
    dsp.JVPEF.Q = qfactor;
    
    [self updateEQView];
}

- (IBAction)qButtonTouchUpInside:(id)sender {
    [_qButton setSelected:![_qButton isSelected]];
    if ([_qButton isSelected]) {
        //        [_qButton setTitle:@"BW" forState:UIControlStateNormal];
        [self.qLabel setText:[NSString stringWithFormat:@"%.2f", [Utils convertToBandwidth:dsp.JVPEF.Q]]];
    } else {
        [self.qLabel setText:[NSString stringWithFormat:@"%.2f", dsp.JVPEF.Q]];
    }
}



- (IBAction)panGesture:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:eqView];
    
    normPanX = (point.x/eqView.bounds.size.width);
    normPanY = (point.y/eqView.bounds.size.height);
    //    NSLog(@"Point: %f\t%f\tProcessed:\t%f\t%f", point.x, point.y, normPanX, normPanY);
    
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
    
    float absoluteFreq =[Utils convertToLogScale:(normF0*(PARQ_MAX_F0-PARQ_MIN_F0)+PARQ_MIN_F0)];
    
    //    [self adjustFilterWithCenterFrequency:absoluteFreq dbGain:g Q:q];
    dsp.JVPEF.centerFrequency = absoluteFreq;
    
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
    dsp.JVPEF.G = dbGain;
    
    [self.gainLabel setText:[NSString stringWithFormat:@"%.2f dB", dbGain]];
}

- (void) updateEQView {
    NSLog(@"upadtyah");
    [eqView setNeedsDisplay];
}
@end
