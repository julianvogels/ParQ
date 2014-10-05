//
//  ParQDSP.m
//  ParametricEQ
//
//  Created by Julian Vogels on 02/10/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import "ParQDSP.h"

@interface ParQDSP ()

@property (assign, nonatomic) RingBuffer *ringBuffer;

@end


@implementation ParQDSP{
    struct {
        unsigned int updateLevelMeter:1;
        unsigned int filterCoefficients:1;
    } delegateRespondsTo;
    
}
@synthesize delegate;

- (void)setDelegate:(id <JVPeakingEQDelegate>)aDelegate {
    if (delegate != aDelegate) {
        delegate = aDelegate;
        
        delegateRespondsTo.updateLevelMeter = [delegate respondsToSelector:@selector(updateLevelMeter:)];
        delegateRespondsTo.filterCoefficients = [delegate respondsToSelector:@selector(filterCoefficients:)];
    }
}


// Novocaine
@synthesize audioManager;
@synthesize ringBuffer;
@synthesize JVPEF;

@synthesize fs;

#pragma mark -
#pragma mark DSP init method

-(void)initDSP {
    
    ringBuffer = new RingBuffer(32768, 2);
    audioManager = [Novocaine audioManager];
    fs = audioManager.samplingRate;
    
    // NVDSP Peaking EQ Filter init
    JVPEF = [[JVPeakingEQ alloc] initWithSamplingRate:audioManager.samplingRate];
    JVPEF.sampleRate = self.audioManager.samplingRate;
    
    JVPEF.delegate = self.delegate;

    
    if (PARQ_DEFAULTS_INPUT) {
        [self setupFilterWithMicInput];
    } else {
        [self setupFilterWithSoundFileURL:[[NSBundle mainBundle] URLForResource:@"apfelsinen" withExtension:@"m4a"]];
    }
    
    JVPEF.centerFrequency = PARQ_DEFAULTS_F0;
    JVPEF.Q = PARQ_DEFAULTS_Q;
    JVPEF.G = PARQ_DEFAULTS_G;
}

#pragma mark -
#pragma mark DSP setup methods

-(void)setupFilterWithMicInput {
    if (audioManager.playing) {
        [audioManager pause];
    }
    __weak ParQDSP *wself = self;

    /* ======================
     
     Input Block
     
     ====================== */
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        
            // Input scaling
            float volume = 0.5;
            vDSP_vsmul(data, 1, &volume, data, 1, numFrames*numChannels);
            wself.ringBuffer->AddNewInterleavedFloatData(data, numFrames, numChannels);
            
            float normVal = [wself audioLevelForData:data numFrames:numFrames numChannels:numChannels];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [wself.delegate updateLevelMeter:normVal];
                
            });
    }];
    
    /* ======================
     
     Output Block
     
     ====================== */
    
    [self.audioManager setOutputBlock:^(float *outData, UInt32 numFrames, UInt32 numChannels) {
        
        wself.ringBuffer->FetchInterleavedData(outData, numFrames, numChannels);
        
        [wself.JVPEF filterData:outData numFrames:numFrames numChannels:numChannels];
        
    }];
    
    
    [audioManager play];
}

-(void)setupFilterWithSoundFileURL:(NSURL *)fileUrl {
    if (fileUrl) {
    if (audioManager.playing) {
        [audioManager pause];
    }
    __weak ParQDSP *wself = self;
    
    
    /* ======================
     
     Input Block
     
     ====================== */
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        // Do Nothing
    }];
     
    
    /* ======================
     
     File Reader
     
     ====================== */
    
        _fileReader = [[AudioFileReader alloc]
                       initWithAudioFileURL:fileUrl
                       samplingRate:audioManager.samplingRate
                       numChannels:audioManager.numOutputChannels];
        
        [_fileReader play];
        _fileReader.currentTime = 0.0;
    
    if (!fileUrl) {
        NSLog(@"File Reader error");
    }

    
    /* ======================
     
     Output Block
     
     ====================== */
    
    [self.audioManager setOutputBlock:^(float *outData, UInt32 numFrames, UInt32 numChannels) {

        [wself.fileReader retrieveFreshAudio:outData numFrames:numFrames numChannels:numChannels];
        
        [wself.JVPEF filterData:outData numFrames:numFrames numChannels:numChannels];
        
    }];
    
    
    [audioManager play];
    } else {
        NSLog(@"WARNING: Could not set up filter - File URL not valid.");
    }
}


-(float)audioLevelForData:(float *)data numFrames:(UInt32)numFrames numChannels:(UInt32)numChannels{
    float dbVal = 0.0f;
    float normVal = 0.0f;
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
    
    return normVal;
}


#pragma mark -
#pragma mark Filter Graph Methods

- (NSMutableArray *) calculateBiquadMagnitudeResponseWithCoeffs:(float [5])coeffs Locations:(NSMutableArray *)locations inRect:(CGRect)rect {
    
    NSMutableArray *points = [[NSMutableArray alloc] initWithCapacity: [locations count]];
    
    long double magnitude;
    
    //    NSLog(@"------------------------------------------------------------------------");
    //    NSLog(@"Params: f0: %f\t g: %f\t q %f", JVPEF.centerFrequency, JVPEF.G, JVPEF.Q);
    //    NSLog(@"Coeffs: b0 %f\t b1 %f\t b2 %f\t a1 %f\t a2 %f", coeffs[0], coeffs[1], coeffs[2], coeffs[3], coeffs[4]);
    //    NSLog(@"------------------------------------------------------------------------");
    
    // calculate biquad magnitude for n frequency points
    for (int i = 0; i < [locations count]; ++ i) {
        
        magnitude = [[self class] performMagnitudeResponseWithCoeffs:coeffs sampleRate:fs andLocation:[[locations objectAtIndex:i] doubleValue]];
        
        // Value over frequency range times actual width of the view
        CGFloat x = PARQ_MARGIN_X+(((float)i)/[locations count])*(rect.size.width-PARQ_MARGIN_X);
        
        // Calculating absolute y value
        CGFloat y = (1.0f-[Utils convertToNormGain:20.0f*log10f(magnitude)])*rect.size.height;
        
        if (isnan(y)) {
            y = 0.0f;
            NSLog(@"WARNING: caught NaN in calculateBiquadMagnitudeResponseWithCoeffs");
        }
        
        [points insertObject:[NSValue valueWithCGPoint:CGPointMake(x, y)] atIndex:i];
    }
    
    return points;
    
}

+(long double) performMagnitudeResponseWithCoeffs:(float [5])coeffs sampleRate:(float)fs andLocation:(long double)frequencyPoint {
    // Declaration of magnitude vars
    long double omega;
    long double numerator;
    long double denominator;
    long double magnitude;
    long double b0, b1, b2, a1, a2;
    
    b0 = coeffs[0];
    b1 = coeffs[1];
    b2 = coeffs[2];
    a1 = coeffs[3];
    a2 = coeffs[4];
    
    omega = 2.0L*M_PI*frequencyPoint / fs;
    
    // biquad magnitude response (http://rs-met.com/documents/dsp/BasicDigitalFilters.pdf p.2)
    numerator = powl(b0, 2) + powl(b1, 2) + powl(b2, 2) + 2.0L*(b0*b1 + b1*b2)*cosl(omega) + 2.0L*b0*b2*cosl(2.0L*omega);
    denominator = 1.0L + powl(a1, 2) + powl(a2, 2) + 2.0L*(a1 + a1*a2)*cosl(omega) + 2.0L*a2*cosl(2.0L*omega);
    magnitude = sqrtl(numerator / denominator);

    return magnitude;
}

@end
