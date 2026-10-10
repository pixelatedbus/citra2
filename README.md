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
Low-pass filters built with `lowpassH`: ideal `D <= D0`, Gaussian `exp(-D^2 / 2D0^2)` and
Butterworth `1 / (1 + (D/D0)^2n)`.

- **GUI (tab B):** choose the filter, `D0` and `n` (Butterworth only), then Apply. The tab shows the input, its
  spectrum, H(u,v), the result and its spectrum. When the image comes from `data/B_.../input/`, it also shows the
  PSNR of the input and of the result against the reference.
- **Batch (`run_partB`):** every input with ILPF, GLPF and BLPF for `D0` from 10 to 280. One CSV row per setting,
  plus a figure per image with a PSNR-vs-`D0` plot and the three filters at the same cutoff.
- **Finding:** GLPF gives the best PSNR on every input, BLPF is close behind, and ILPF is worst because its
  sharp cutoff causes ringing. The best `D0` is higher for fine texture (grass) than for smooth scenes (rocket).

### C. High-pass filtering
High-pass filters built with `highpassH = 1 - lowpassH` (IHPF, GHPF, BHPF). The mean is removed, so the result
has negative values. `highpassDisplay` shows it as `|g|` normalised (default: black background, bright edges),
as `|g|`, or rescaled from min to max (keeps the sign).

- **GUI (tab C):** filter, `D0`, `n` and the display mode. The parameter line and the saved file name state the
  display mode used.
- **Batch (`run_partC`):** every input with the three filters at `D0` = 10, 30 and 60, saved as a 3×3 grid per
  image. There are no reference images for part C, so no PSNR.
- **Finding:** IHPF produces doubled, wavy edges (ringing); GHPF and BHPF give clean single edges. A small `D0`
  keeps edges and texture, while a large `D0` keeps only the finest detail and noise.

### D. Brightness increase
TODO

### E. Periodic noise restoration
Periodic noise appears as isolated spikes in the centred spectrum. Two reject filters:

- **Notch reject (`notchRejectH`)**: one hole per spike at offset `(du, dv)` with radius `r`. The mirror spike
  `(-du, -dv)` is removed automatically, offsets may be fractional, and the shape is ideal, Butterworth or
  Gaussian.
- **Bandreject (`bandrejectH`)**: a ring of radius `D0` and width `W`, ideal, Butterworth or Gaussian.

How to use them:
- **GUI (tab E):** pick the filter and shape, then enter the notches in the table (`du`, `dv`, radius) or the ring's
  `D0` and `W`. The hint shows the spectrum centre, so a spike seen at spectrum pixel `(x, y)` is at
  `du = y - uc`, `dv = x - vc`. The tab shows the degraded image, the spectrum before, the mask, the spectrum
  after and the restored image.
- **Batch (`run_partE`):** the spike positions from the spectrum analysis of each input are documented at the
  top of the file. It sweeps notch shape × radius, compares radii (brick), fundamental vs harmonics (hubble), and
  notch vs bandreject (rocket), and saves figures with all five views.

| image | spikes (du, dv) | PSNR input → restored |
|---|---|---|
| brick | (15.21, −35.98) | 21.05 → 35.71 dB |
| grass | (20.43, 25.72) | 20.06 → 31.37 dB |
| hubble | (0, 38.26), (0, 76.5), (0, 114.8) | 22.39 → 31.00 dB |
| rocket | (32, 0) | 21.73 → 42.67 dB |

- **Notch beats bandreject:** the notch removes only the noise, while a ring also removes real image frequencies
  at the same radius (rocket: 42.67 dB with the notch, at best 39.30 dB with a ring).
- **Radius depends on where the spike falls:** spikes that fall between frequency samples spread into their
  neighbours and need a radius of about 5; an on-grid spike needs only 1.
- **Hubble's stripes were clipped** on the dark sky. That clipping creates harmonics and leaves faint stripes
  that no linear filter can fully remove.

### F. Motion blur restoration
TODO
