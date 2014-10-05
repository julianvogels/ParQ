ParQ
====

## Parametric Equalizer iPhone App


This iOS 8 app makes use of [Novocaine](https://github.com/alexbw/novocaine) (@alexbw) and [NVDSP](https://github.com/bartolsthoorn/NVDSP) (@bartolsthoorn) to implement a parametric Equalizer with only one peaking EQ filter using a biquad section. The filter's magnitude response is plotted and can be interacted with by using pan and pinch gestures on the view, which changes center frequency, gain and q factor. 

### Main features include:
* DSP methods to calculate filter coefficients (based on NVDSP) and magnitude response
* scalable `UIView` subclass `EQView`, which draws the magnitude response on a lin-log graph (gain - center frequency)
* possibility to pick songs from the iTunes library or to use microphone input
* display of the filter parameters with possibility to toggle between Q and bandwidth

### To be done:
* interpolation of filter coefficients (or at least parameters `fc`, `g`, `q`)
