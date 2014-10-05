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
    
    // ------------------------------------
    // Calculate frequency points for curve
    // ------------------------------------
    _frequencyLocations = [[NSMutableArray alloc] initWithCapacity:PARQ_CURVE_ACCURACY];
    NSMutableArray *defaultPoints = [[NSMutableArray alloc] initWithCapacity:PARQ_CURVE_ACCURACY];
    long double frequencyPoint;
    
    for (int i = 0; i <= PARQ_CURVE_ACCURACY; i++) {
        frequencyPoint = 20*powf(10, (((float)i)/((float)PARQ_CURVE_ACCURACY))*3.0f);
        [_frequencyLocations insertObject:[NSNumber numberWithDouble:frequencyPoint] atIndex:i];
        [defaultPoints insertObject:[NSValue valueWithCGPoint:CGPointMake(frequencyPoint+PARQ_MARGIN_Y, [Utils convertToNormGain:0.0f])] atIndex:i];
    }
    self.eqView.points = defaultPoints;
    [eqView setNeedsDisplay];
    
    // ------------------------------------
    // Initialize UI
    // ------------------------------------
    [_freqLabel setText:[NSString stringWithFormat:@"%.0f Hz", PARQ_DEFAULTS_F0]];
    [_gainLabel setText:[NSString stringWithFormat:@"%.2f db", PARQ_DEFAULTS_G]];
    [_qLabel    setText:[NSString stringWithFormat:@"%.2f",    PARQ_DEFAULTS_Q]];
    
    // ------------------------------------
    // Initialize interpolation
    // ------------------------------------
    self.duration = self.remainingTime = PARQ_INTERP_TIME;
    self.lastDrawTime = 0;
    
    // ------------------------------------
    // Initialize DSP
    // ------------------------------------
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
#pragma mark JVPeakingEQ delegate methods
/* filterCoefficients method gets called every time new filter coefficients are calculated 
 * within a JVPeakingEQ class of which this is the delegate.
 *
 * In this method, the received coefficients are used to calculate the magnitude response
 * which is then plotted in an instance of the EQView UIView subclass.
 */
- (void) filterCoefficients:(float [5])coeffs {
    self.eqView.points = [dsp calculateBiquadMagnitudeResponseWithCoeffs:coeffs Locations:_frequencyLocations inRect:eqView.frame];
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
    }
}

- (IBAction)SoundFileButtonTouchUpInside:(id)sender {
    [soundFileButton setSelected:YES];
    [micButton setSelected:NO];
    
    [dsp.fileReader pause];
    [dsp.audioManager pause];
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    mediaPicker.delegate = self;
    [self presentViewController:mediaPicker animated:YES completion:nil];
    
    // possible memory issue to look into: https://stackoverflow.com/questions/19493355/novocaine-loading-files-from-ipod-library-memory-issue
    
}

- (void) updateCenterFrequency:(float)normF0{
    if (normF0 < 0.0f) {
        normF0 = 0.0f;
    } else if (normF0 > 1.0f) {
        normF0 = 1.0f;
    }
    
    float absoluteFreq = [Utils convertToLogFrequency:normF0];
    
    // TBD Interpolate frequency value
    //    [self animateFrom:[NSNumber numberWithFloat:dsp.JVPEF.centerFrequency] toNumber:[NSNumber numberWithFloat:absoluteFreq] withLabel:self.freqLabel];
    
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
    
    dsp.JVPEF.G = dbGain;
    
    [self.gainLabel setText:[NSString stringWithFormat:@"%.2f dB", dbGain]];
}

#pragma mark Gesture Recognizer methods

- (IBAction)qButtonTouchUpInside:(id)sender {
    // Change button's selected attribute
    [_qButton setSelected:![_qButton isSelected]];
    // change value rendering
    if ([_qButton isSelected]) {
        [self.qLabel setText:[NSString stringWithFormat:@"%.2f", [Utils convertToBandwidth:dsp.JVPEF.Q]]];
    } else {
        [self.qLabel setText:[NSString stringWithFormat:@"%.2f", dsp.JVPEF.Q]];
    }
}


- (IBAction)pinchGesture:(UIPinchGestureRecognizer *)sender {
    CGFloat scale = [sender scale];

    float qfactor = dsp.JVPEF.Q;
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
    }
    
    qfactor *= (1.0-scale)+1.0;
    if (qfactor > PARQ_MAX_Q) {
        qfactor = PARQ_MAX_Q;
    }
    
    sender.scale = 1.0;
    
    if ([_qButton isSelected]) {
        [self.qLabel setText:[NSString stringWithFormat:@"%.2f", [Utils convertToBandwidth:qfactor]]];
    } else {
        [self.qLabel setText:[NSString stringWithFormat:@"%.2f", qfactor]];
    }
    dsp.JVPEF.Q = qfactor;
    
}


- (IBAction)panGesture:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:eqView];
    
    // TBD add margin: this is the first attempt
//    //    normPanX = (FIGURE/(eqView.bounds.size.width-2*PARQ_MARGIN_X));
//    if (point.x >= PARQ_MARGIN_X && point.x <= eqView.bounds.size.width-PARQ_MARGIN_X) {
//        // in bounds
//        normPanX = (point.x-PARQ_MARGIN_X)/(eqView.bounds.size.width-2*PARQ_MARGIN_X);
//        [self updateCenterFrequency:normPanX];
//    }
//    
//    if (point.y >= PARQ_MARGIN_Y && point.y <= eqView.bounds.size.height-PARQ_MARGIN_Y) {
//        normPanY = (point.y-PARQ_MARGIN_Y)/(eqView.bounds.size.height-2*PARQ_MARGIN_Y);
//        [self updateGain:normPanY];
//    }
//    NSLog(@"Point: %f\t%f\tProcessed:\t%f\t%f", point.x, point.y, normPanX, normPanY);

    
    normPanX = (point.x/eqView.bounds.size.width);
    normPanY = (point.y/eqView.bounds.size.height);
    
    [self updateCenterFrequency:normPanX];
    
    [self updateGain:normPanY];
    
}


# pragma mark -
#pragma mark Interpolation methods
// Method not used! Attempt to interpolate parameters
// Not yet properly inplemented as of Sat 04 Oct 2014

// thanks to https://stackoverflow.com/questions/7798785/uilabel-animating-number-change and https://github.com/MarkQSchultz/DisplayLinkExample/blob/master/DisplayLinkExample/ViewController.m

- (void)animateFrom:(NSNumber *)fromVal toNumber:(NSNumber *)toVal withLabel:(UILabel *)label{
    _interpolateFrom = fromVal;
    _interpolateTo = toVal;
    NSLog(@"From: %f to: %f", [_interpolateFrom floatValue], [_interpolateTo floatValue]);
    
    // perform interpolation only for values with a difference bigger than the set threshold
    if (fabs([_interpolateTo floatValue]-[_interpolateFrom floatValue])>PARQ_INTERP_THRES_F0) {
        NSLog(@"bigger than threshold: %f", fabs([_interpolateTo floatValue]-[_interpolateFrom floatValue]));
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(animateNumber:)];
        [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    } else {
    dsp.JVPEF.centerFrequency = [toVal floatValue];
    }
}

- (void)animateNumber:(CADisplayLink *)sender {
    NSTimeInterval timestamp = sender.timestamp;
    
    // Check if we've drawn yet
    if (self.lastDrawTime == 0)
    {
        // If not, then set last draw time to the current timestamp of display link
        self.lastDrawTime = timestamp;
    }
    
    NSTimeInterval elapsedTimeSinceLastUpdate = timestamp - self.lastDrawTime;
    self.remainingTime = MAX(self.remainingTime - elapsedTimeSinceLastUpdate, 0);
    if (self.remainingTime > 0)
    {
        NSTimeInterval totalElapsedTime = self.duration - self.remainingTime;
        CGFloat percentageComplete = totalElapsedTime / self.duration;
        // do shit with percentage Value
        
        float interpVal = [_interpolateFrom floatValue] + ([_interpolateTo floatValue] - [_interpolateFrom floatValue]) * percentageComplete;
        
        NSLog(@"%f percent, value %f", percentageComplete, interpVal);
        dsp.JVPEF.centerFrequency = interpVal;
    }
    else
    {
        self.remainingTime = self.duration;
        [sender removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [sender invalidate];
    }
    
    self.lastDrawTime = timestamp;
}

@end
