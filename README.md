# Frequency-Domain Image Processing (Tugas 2 IF4073)

A single MATLAB GUI application for image processing in the frequency domain, made for
IF4073 Pemrosesan Citra Digital (ITB, Semester I 2026/2027). It covers:

| Part | Task | Methods |
|---|---|---|
| B | Smoothing / blurring | Ideal, Gaussian and Butterworth low-pass filters (ILPF, GLPF, BLPF) |
| C | High-pass filtering | Ideal, Gaussian and Butterworth high-pass filters (IHPF, GHPF, BHPF) |
| D | Brightness increase | TODO: method |
| E | Periodic noise restoration | Bandreject (ideal, Butterworth, Gaussian) and notch reject filters |
| F | Motion blur restoration | Own motion PSF / H(u,v), inverse filtering, Wiener filtering |

Every filter and degradation model is built as our own transfer function H(u,v) and applied as
`G = H .* F` on the centred spectrum. Built-in functions such as `imgaussfilt` or `deconvwnr` are
used only as a separate comparison in the batch results, never as the main implementation.
Grey and colour (RGB) images are supported in every part.

## Team

| Name | NIM | Parts |
|---|---|---|
| TODO | TODO | B, C, E |
| TODO | TODO | D, F |

## Dependencies

- MATLAB R2026a (developed and tested on R2026a Update 5). The GUI uses `uifigure`, `uigridlayout`
  and `uitabgroup`.
- Image Processing Toolbox, for support functions only (`imread`, `imshow`, `im2double`, `ind2rgb`)
  and for the labelled built-in comparisons.

## Test data

The official test images are not stored in this repository. Unzip them into `data/` with folder
and file names unchanged:

```
data/
  B_smoothing_blurring_frequency/   input/  reference/
  C_high_pass_filtering_frequency/  input/
  D_brightness_frequency/           input/  reference/
  E_periodic_noise_restoration/     input/  reference/
  F_motion_blur_restoration/        input/  reference/  README.md
```

## How to run

All commands are run from the project root.

**GUI**: in MATLAB type `main`, or from a terminal:
```
matlab -r "main"
```
Click **Load image...**, choose a tab (B to F), set the parameters, then **Apply**. The tab shows
the input, its spectrum, the filter or degradation function, the result and the parameters used.
**Save result...** stores the result.

**Batch**: processes every input image and writes figures to `results/<part>/` and all
parameters and scores (MSE, PSNR against the reference) to `results/params.csv`:
```
matlab -batch "addpath('scripts'); run_all"          % all parts
matlab -batch "addpath('scripts'); run_all('BCE')"   % only some parts
```

**Tests**: runs every test and saves a report to `tests/log/`:
```
matlab -batch "addpath('scripts'); run_tests"
```

## Project structure

```
main.m          entry point: adds src/ to the path and opens the GUI
src/core/       filters and frequency-domain operations (pure functions)
src/io/         reading images and finding reference images
src/gui/        the window (FreqApp), the shared tab layout, one builder per part (tabB ... tabF)
scripts/        run_all (batch), run_partB ... run_partF, run_tests
tests/          unit and GUI tests (test_*.m)
```

Conventions: images are `double` in [0,1]; H(u,v) is centred with DC at
`(floor(M/2)+1, floor(N/2)+1)`; filtering is circular (no zero-padding); spectra are shown as
`log(1 + |F|)` scaled to [0,1]; colour images are filtered per RGB channel.

## Parts

### B. Smoothing / blurring
TODO

### C. High-pass filtering
TODO

### D. Brightness increase
TODO

### E. Periodic noise restoration
TODO

### F. Motion blur restoration
TODO
