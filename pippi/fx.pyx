# cython: language_level=3

import numpy as np
import numbers
import random
cimport cython
from .soundbuffer cimport SoundBuffer
from . cimport wavetables
from .filters cimport _fir
from .dsp cimport _mag
from cpython cimport bool

cdef double MINDENSITY = 0.001

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
cdef double[:,:] _norm(double[:,:] snd, double ceiling):
    cdef int i = 0
    cdef int c = 0
    cdef int framelength = len(snd)
    cdef int channels = snd.shape[1]
    cdef double normval = 1
    cdef double maxval = _mag(snd)

    normval = ceiling / maxval
    for i in range(framelength):
        for c in range(channels):
            snd[i,c] *= normval

    return snd

cpdef SoundBuffer norm(SoundBuffer snd, double ceiling):
    snd.frames = _norm(snd.frames, ceiling)
    return snd

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
cdef double[:,:] _delay(double[:,:] snd, double[:,:] out, int delayframes, double feedback):
    cdef int i = 0
    cdef int c = 0
    cdef int framelength = len(snd)
    cdef int channels = snd.shape[1]
    cdef double sample = 0

    for i in range(framelength):
        delayindex = i - delayframes
        for c in range(channels):
            if delayindex < 0:
                sample = snd[i,c]
            else:
                sample = snd[delayindex,c] * feedback
                snd[i,c] += sample
            out[i,c] = sample

    return out

cpdef SoundBuffer delay(SoundBuffer snd, double delaytime, double feedback):
    cdef double[:,:] out = np.zeros((len(snd), snd.channels), dtype='d')
    cdef int delayframes = <int>(snd.samplerate * delaytime)
    snd.frames = _delay(snd.frames, out, delayframes, feedback)
    return snd

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
cdef double[:,:] _mdelay(double[:,:] snd, double[:,:] out, int[:] delays, double feedback):
    cdef int i = 0
    cdef int c = 0
    cdef int j = 0
    cdef int framelength = len(snd)
    cdef int numdelays = len(delays)
    cdef int channels = snd.shape[1]
    cdef int delayindex = 0
    cdef double sample = 0
    cdef double dsample = 0
    cdef double output = 0
    cdef int delaylinestart = 0
    cdef int delaylinepos = 0
    cdef int delayreadindex = 0

    cdef int delaylineslength = sum(delays)
    cdef double[:,:] delaylines = np.zeros((delaylineslength, channels), dtype='d')
    cdef int[:] delaylineindexes = np.zeros(numdelays, dtype='i')

    for i in range(framelength):
        for c in range(channels):
            sample = snd[i,c]
            delaylinestart = 0
            for j in range(numdelays):
                delayreadindex = i - delays[j]
                delayindex = delaylineindexes[j]
                delaylinepos = delaylinestart + delayindex
                output = delaylines[delaylinepos,c]

                if delayreadindex < 0:
                    dsample = 0
                else:
                    dsample = snd[delayreadindex,c] * feedback
                    output += dsample
                    sample += output

                delayindex += 1
                delayindex %= delays[j]

                delaylines[delaylinepos,c] = output
                delaylineindexes[j] = delayindex
                delaylinestart += delays[j]

            out[i,c] = sample

    return out

cpdef SoundBuffer mdelay(SoundBuffer snd, list delays, double feedback):
    cdef double[:,:] out = np.zeros((len(snd), snd.channels), dtype='d')
    cdef int numdelays = len(delays)
    cdef double delay
    cdef int[:] delayframes = np.array([ snd.samplerate * delay for delay in delays ], dtype='i')
    snd.frames = _mdelay(snd.frames, out, delayframes, feedback)
    return snd

cpdef SoundBuffer convolve(SoundBuffer snd, double[:] impulse, bool normalize=True):
    cdef double[:,:] out = np.zeros((len(snd), snd.channels), dtype='d')
    cdef int _normalize = 1 if normalize else 0
    snd.frames = _fir(snd.frames, out, impulse, normalize)
    return 

cpdef SoundBuffer go(SoundBuffer snd, 
                          object factor,
                          double density=1, 
                          double wet=1,
                          double minlength=0.01, 
                          double maxlength=0.06, 
                          double minclip=0.4, 
                          double maxclip=0.8, 
                          object win=None
                    ):
    if wet <= 0:
        return snd

    cdef wavetables.Wavetable factors = None
    if not isinstance(factor, numbers.Real):
        factors = wavetables.Wavetable(factor)

    density = max(MINDENSITY, density)

    cdef double outlen = snd.dur + maxlength
    cdef SoundBuffer out = SoundBuffer(length=outlen, channels=snd.channels, samplerate=snd.samplerate)
    cdef wavetables.Wavetable window
    if win is None:
        window = wavetables.Wavetable(initwin=wavetables.HANN)
    else:
        window = wavetables.Wavetable(win)

    cdef double grainlength = random.triangular(minlength, maxlength)
    cdef double pos = 0
    cdef double clip
    cdef SoundBuffer grain

    while pos < outlen:
        grain = snd.cut(pos, grainlength)
        clip = random.triangular(minclip, maxclip)
        grain *= random.triangular(0, factor * wet)
        grain = grain.clip(-clip, clip)
        out.dub(grain * window.data, pos)

        pos += (grainlength/2) * (1/density)
        grainlength = random.triangular(minlength, maxlength)

    if wet > 0:
        out *= wet

    if wet < 1:
        out.dub(snd * abs(wet-1), 0)

    return out
