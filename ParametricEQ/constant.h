//
//  constant.h
//  ParametricEQ
//
//  Created by Julian Vogels on 29/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#ifndef ParametricEQ_constant_h
#define ParametricEQ_constant_h

// Filter params
#define PARQ_DEFAULTS_F0 1000.0f
#define PARQ_DEFAULTS_G 0.0f
#define PARQ_DEFAULTS_Q 1.5f

// Filter param max/mins
#define PARQ_MAX_F0 20000.0f
#define PARQ_MIN_F0 10.0f
#define PARQ_MAX_Q 25.0f
#define PARQ_MAX_GAIN 36.0f
#define PARQ_MIN_GAIN -48.0f

// No of calculated frequency points in filter curve display
#define PARQ_CURVE_ACCURACY 100

// Default (startup) input source: YES for mic, NO for sound file
#define PARQ_DEFAULTS_INPUT NO

// X and Y margins of filter curve view (determine insets, to draw axes)
#define PARQ_MARGIN_Y 4.0f
#define PARQ_MARGIN_X 5.0f

// Interpolation time in s
#define PARQ_INTERP_TIME 2.0f
// Threshold for interpolation in Hz
#define PARQ_INTERP_THRES_F0 10.0f


// TBD obsolete ?
#define PARQ_Q_SCALINGFACTOR 5.0f

#endif
