# Pippi: Computer music with python

v2.0.0 - Alpha 1

## Install dependencies

Pippi requires python 3.5+

Pippi uses `numpy` and `pysoundfile` which in turn rely on some 
C libraries you may need to manually install on your platform. 
More docs forthcoming as the deps for version 2 settle (especially 
as the interactive console comes together again.)

In the meantime, please do open a bug on github if you try this 
out and have trouble installing it!

    pip install -r requirements.txt

## Install from source

    python setup.py install

## Run the simple grains example

    cd examples
    python simple_grains.py

Which will produce a WAV file named `simple_grains.wav` in the examples directory.

## To run tests

    make test

## Release Notes

### 2.0.0 - Alpha 1

This is the initial alpha release of pippi 2 -- which is very barebones at the moment, 
but already pretty functional!

Beware: the behavior of core functionality and features will probably change throughout the 
alpha releases of pippi 2. I'll try to document it here in the release notes.

This release provides:

- SoundBuffer abstraction for reading/writing soundfiles and doing basic operations on sounds.
- Osc abstraction for simple wavetable synthesis.
- Initial set of built-in wavetables for windowing (sine, triangle, saw, inverse saw) 
  and synthesis (sine, cosine, triangle, saw inverse saw)
- Set of panning algorithms and other built-in sound operations like addition, subtraction, 
  multiplication, mixing (and operater-overloaded mixing via `sound &= sound`), dubbing, 
  concatenation.
- A small set of helpers and shortcuts via the `dsp` module for loading, mixing, and concatenating (via `dsp.join`) sounds.
- Basic granular synthesis and wavetable synthesis examples.

Some basic things from pippi 1 that are still missing (and coming very soon!):

- Pitch shifting sounds
- Square and impulse wavetables for windowing and synthesis
- Using arbitrary wavetables for windowing and synthesis

Bigger things from pippi 1 that are still missing:

- Pulsar synthesis
- The interactive / live mode and console which includes stuff like
    - MIDI support
    - Voice handling
    - Live code reloading

I'm excited to revisit the interactive console especially, and I'm looking into some cool 
stuff like using pippi instruments as generators to feed into sound streams, which should 
hopefully overcome some awkwardness of treating pippi 1 instruments like streams.


