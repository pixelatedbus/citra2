# Pemrosesan Citra dalam Ranah Frekuensi

Aplikasi GUI MATLAB untuk Tugas 2 IF4073 Pemrosesan Citra Digital (ITB, 2026/2027). Semua penapis dan
model degradasi dibuat sendiri sebagai H(u,v) dan diterapkan pada spektrum terpusat (`G = H .* F`).
Citra keabuan dan berwarna didukung di semua bagian.

| Bagian | Isi |
|---|---|
| B | Penghalusan: ILPF, GLPF, BLPF |
| C | Penapisan lolos-tinggi: IHPF, GHPF, BHPF |
| D | Peningkatan kecerahan: penapisan homomorfik, *low-frequency emphasis* |
| E | Restorasi derau periodik: *notch reject*, *bandreject* |
| F | Restorasi *motion blur*: PSF sendiri, *inverse filtering*, Wiener filtering |

## Anggota

| Nama | NIM |
|---|---|
| [Nama 1] | [NIM 1] |
| [Nama 2] | [NIM 2] |

## Kebutuhan

- MATLAB R2026a
- Image Processing Toolbox (hanya untuk `imread`, `imshow`, `im2double`, `ind2rgb`, dan pembanding `deconvwnr`)

## Data uji

Ekstrak data uji resmi ke folder `data/` tanpa mengubah nama folder dan berkas
(`data/B_smoothing_blurring_frequency/`, ..., `data/F_motion_blur_restoration/`).

## Cara menjalankan

Dari folder proyek:

```
matlab -r "main"
```

Tekan **Load image...**, pilih tab B–F, atur parameter, lalu tekan **Apply**. **Save result...** menyimpan hasil.

Untuk memproses semua citra uji sekaligus (gambar ke `results/<bagian>/`, parameter dan PSNR ke
`results/params.csv`):

```
matlab -batch "addpath('scripts'); run_all"
```

## Struktur

```
main.m       membuka aplikasi
src/core/    penapis dan operasi ranah frekuensi
src/io/      pembacaan citra
src/gui/     jendela dan tab B-F
scripts/     pemrosesan batch (run_all, run_partB ... run_partF)
```
