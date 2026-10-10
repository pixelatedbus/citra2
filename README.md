# Frequency-Domain Image Processing (Tugas 2 IF4073)

A single MATLAB GUI application for image processing in the frequency domain, made for
IF4073 Pemrosesan Citra Digital (ITB, Semester I 2026/2027). It covers:

| Part | Task | Methods |
|---|---|---|
| B | Smoothing / blurring | Ideal, Gaussian and Butterworth low-pass filters (ILPF, GLPF, BLPF) |
| C | High-pass filtering | Ideal, Gaussian and Butterworth high-pass filters (IHPF, GHPF, BHPF) |
| D | Brightness increase | Homomorphic filter on the log spectrum (main), low-frequency emphasis (comparison) |
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
Brightness lives in the lowest frequencies: the DC term is `M·N` times the mean intensity. Our spectrum analysis
of the inputs showed that each dark image is a power law of its reference, `dark = c · ref^γ` (γ = 1.17–1.41,
c = 0.30–0.36), the same over the whole image and in every RGB channel. A pure gain cannot undo that, because
the contrast is compressed as well. In the log domain the power law becomes linear, so the main method works on
the spectrum of `log(image)`:

- **Homomorphic (`homomorphicBrightness`, main):** `Z = FFT(log(f + 1/255))`, multiply by
  `H = gH + (gL − gH)·exp(−D²/2D0²)` (`brightnessH`), set the DC term so that the geometric mean of the result
  becomes the target `t`, then `exp(IFFT(·))`. `gL` and `gH` set the gains of the low and high frequencies of
  the log image (`gL = gH = 1/γ` undoes the power law). `D0 = 0` gives `gL` to the DC term only.
- **Low-frequency emphasis (comparison):** `G = H·F` on the image itself with `H = brightnessH(k, 1, D0)`:
  the mean and slow changes times `k`, the detail unchanged. With `D0 = 0` only the mean is raised.
- **Colour:** every RGB channel gets the same H and the same DC shift, so the channels keep their relation (HSV V
  only scored lower: ihc 33.2 vs 39.8 dB, because the darkening was applied per channel).
- **GUI (tab D):** method, `t`, `gL`, `gH`, `k` and `D0`. The parameter line shows the mean brightness before and
  after, and the PSNR against the reference when there is one.
- **Batch (`run_partD`):** homomorphic sweep of `g = gL = gH` × `t`, the same with separate `gL`, `gH` and
  `D0` > 0, and emphasis `k` × `D0`. One figure per image.

| image | input | DC gain only | emphasis (best) | homomorphic (best) |
|---|---|---|---|---|
| cell (grey) | 12.86 | 23.03 | 28.39 | **40.93** (g = 0.8, t = 0.25) |
| coins (grey) | 10.61 | 17.33 | 28.23 | **46.93** (g = 0.85, t = 0.325) |
| ihc (colour) | 6.36 | 16.80 | 22.95 | **39.83** (g = 0.8, t = 0.6) |
| retina (colour) | 10.02 | 16.04 | 28.63 | **37.67** (g = 0.85, t = 0.2) |

PSNR in dB against the reference. Raising only the DC term makes the image brighter but leaves it flat and grey.
The best homomorphic settings use the same gain at every frequency (`D0 = 0`). Separate low and high gains do
not help here, because the darkening is the same everywhere in the image. The target `t` is the brightness the
user wants. Without a reference, the default `t = 0.4` still brightens every image, but the score is lower because
each reference has its own brightness.

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
Degradation model `G = H·F + N`. `motionPSF(L, θ)` builds the PSF of a straight motion: a segment of length
`L − 1` with equal weight, rasterised with bilinear weights and normalised to sum 1. `psf2H` places it in an
`M × N` array with its centre at (1,1) and takes the FFT, so the restored image is not shifted.

- **Angle convention:** `θ` turns from the +x axis towards +y with rows pointing down, so a positive angle is
  clockwise on screen. We found this by blurring each reference and comparing with the input; `fspecial('motion')`
  uses the opposite sign. Our PSF reproduces the inputs to within the 8-bit rounding error (residual rms
  0.0012–0.0023, against 0.0021–0.0052 for `fspecial` at `−θ`).
- **Inverse filter (`inverseRestore`):** `F̂ = G / H`, stabilised by a threshold (terms with `|H| < t` are set to 0,
  the default) or a Butterworth radius `R0`. A motion blur H is zero along lines about `M/L` samples apart, so a
  radius limit is only stable below the first zero and never beat the input here.
- **Wiener filter (`wienerRestore`):** `F̂ = conj(H) / (|H|² + K) · G`, with `K` set in the GUI.
- **Borders (`motionRestore`):** the data was blurred with mirrored borders, not wrapped ones, so a plain
  (periodic) restoration rings at the edges. Options: `periodic`, `taper` (near the edges, blend the image into
  its own circular blur; the GUI default) and `mirror` (restore the mirrored 2M × 2N image; exact only for θ = 0°
  or 90°).
- **GUI (tab F):** `L` and `θ` are read from the file name and can be changed. Other controls: inverse mode with
  `t` or `R0`, Wiener `K`, border, and an optional "simulate" mode that blurs the loaded image first and adds noise
  with std `σ`. The tab shows the original, the degraded image, the PSF, `|H|`, the degraded spectrum, both
  results and the Wiener result's spectrum.
- **Batch (`run_partF`):** every input with the inverse `t` and `R0` sweeps and the Wiener `K` sweep, each with
  the three border options. It also runs the built-in `deconvwnr` as a separately labelled comparison.

| image | input | inverse (best) | Wiener (best) |
|---|---|---|---|
| astronaut L19 A20 | 20.99 | 26.30 (t = 0.05, taper) | **27.69** (K = 0.001, taper) |
| astronaut + noise | 20.61 | 22.43 (t = 0.15, mirror) | **22.75** (K = 0.03, mirror) |
| brick L17 A0 | 22.09 | 30.76 (t = 0.02, mirror) | **31.53** (K = 0.001, mirror) |
| coins L23 A35 | 20.35 | 25.46 (t = 0.02, taper) | **27.04** (K = 0.001, taper) |
| retina L15 A−25 | 31.54 | 37.49 (t = 0.05, periodic) | **38.10** (K = 0.003, periodic) |
| retina + noise | 28.64 | **31.22** (t = 0.4, periodic) | 27.42 (K = 0.05, periodic) |

- **Noise changes the best parameters:** without noise a small `t` or `K` works, but with noise the same settings
  amplify it enormously (retina + noise: 9.5 dB at `t = 0.02`). Both filters then need a much larger `t` or `K`,
  which also gives up detail.
- **Wiener with a constant K lowers the mean:** its gain at DC is `1/(1 + K)`. On the noisy retina, `K = 0.1` takes
  the mean from 0.352 to 0.319, and correcting only the DC raises the score from 25.5 to 30.8 dB. The smooth retina
  also suits the threshold inverse, which acts as a strong low-pass at `t = 0.4`.
- **Built-in check:** with the same PSF and `K`, `deconvwnr` gives the same PSNR as our periodic Wiener filter. With
  the `fspecial` PSF it scores up to 1.4 dB lower (retina 36.70 vs 38.10).
