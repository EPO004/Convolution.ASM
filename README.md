# Convolution.ASM

Low-level implementations of **matrix multiplication** and **2D convolution** in x86-64 NASM assembly, with a Python reference implementation and benchmark results for comparing scalar and SIMD execution.

This project focuses on implementing common numerical operations in x86-64 assembly, working directly with single-precision floating-point values, and comparing a straightforward scalar implementation with an SSE-vectorized version.

## Features

- Scalar matrix multiplication in x86-64 NASM
- SSE-vectorized matrix multiplication
- 2D valid convolution in x86-64 NASM
- Python reference implementation for matrix multiplication
- Sample input files
- Benchmark scripts
- Recorded benchmark results
- Persian project report

## Repository Structure

```text
Convolution.ASM/
├── convolution/
│   ├── convolution.asm
│   ├── benchmark.sh
│   ├── large_input.txt
│   ├── sample_input.txt
│   └── sharpen_kernel.txt
├── matrix-multiplication/
│   ├── matrix_multiply_scalar.asm
│   ├── matrix_multiply_simd.asm
│   ├── matrix_multiply_reference.py
│   ├── benchmark.sh
│   ├── benchmark_input.txt
│   ├── input_3x3.txt
│   └── input_5x5.txt
├── results/
│   ├── convolution_benchmark.txt
│   ├── matrix_multiply_3x3.txt
│   └── matrix_multiply_5x5.txt
├── docs/
│   ├── report-fa.pdf
│   └── images/
│       ├── matrix-multiplication-results.png
│       └── convolution-results.png
├── .gitignore
└── README.md
```

## Matrix Multiplication

The `matrix-multiplication/` directory contains scalar assembly, SIMD assembly, and Python implementations of matrix multiplication.

### Scalar Assembly

`matrix_multiply_scalar.asm` implements the standard matrix multiplication formula:

```text
C[i][j] = Σ A[i][k] × B[k][j]
```

The implementation uses nested loops and scalar single-precision SSE instructions such as:

```text
movss
mulss
addss
```

The matrices are stored in statically allocated buffers and use a fixed row stride of 8 elements.

### SIMD Assembly

`matrix_multiply_simd.asm` optimizes the matrix multiplication inner product using 128-bit SSE registers.

The main steps are:

1. Matrix `B` is stored in transposed form while being read.
2. Four adjacent `float32` elements from a row of matrix `A` are loaded into an XMM register.
3. Four corresponding elements from the transposed matrix `B` are loaded into another XMM register.
4. `mulps` performs four floating-point multiplications simultaneously.
5. `addps` accumulates the partial products.
6. Shuffle and add instructions reduce the four SIMD lanes into one scalar result.

Transposing matrix `B` makes the values used in each dot product contiguous in memory, improving memory access patterns and making SIMD processing easier.

The implementation is vectorized with SSE instructions and does not create multiple operating-system threads.

### Python Reference

`matrix_multiply_reference.py` contains a direct high-level implementation of the same triple-loop matrix multiplication algorithm.

It can be used for checking the behavior of the assembly implementation and for comparing high-level and low-level implementations.

The Python and assembly benchmark loops use different repetition counts, so raw timing values should be interpreted with that difference in mind.

## 2D Convolution

`convolution/convolution.asm` implements a 2D sliding-window operation over an input matrix and a smaller kernel.

For an `n × n` input matrix and an `m × m` kernel, the output dimension is:

```text
(n - m + 1) × (n - m + 1)
```

Each output element is calculated as:

```text
output[i][j] += image[i + k][j + p] × kernel[k][p]
```

The implementation uses single-precision floating-point arithmetic with SSE scalar instructions.

### Storage Layout

The convolution implementation uses fixed row strides in its address calculations:

- Image row stride: `2048`
- Kernel row stride: `8`
- Maximum intended image size: `2048 × 2048`
- Maximum intended kernel size: `8 × 8`

Inputs should remain within these dimensions unless the address calculations and buffer sizes are changed.

The current implementation applies the kernel directly without reversing it. Mathematically, this corresponds to a 2D cross-correlation operation, although the project uses the term convolution.

## Requirements

A Linux x86-64 environment is recommended.

Required tools:

- NASM
- GCC
- Python 3
- `bc`

On Debian or Ubuntu:

```bash
sudo apt update
sudo apt install nasm gcc python3 bc
```

## Build

### Scalar Matrix Multiplication

```bash
cd matrix-multiplication

nasm -f elf64 matrix_multiply_scalar.asm -o matrix_multiply_scalar.o
gcc -no-pie matrix_multiply_scalar.o -o matrix_multiply_scalar
```

### SIMD Matrix Multiplication

```bash
cd matrix-multiplication

nasm -f elf64 matrix_multiply_simd.asm -o matrix_multiply_simd.o
gcc -no-pie matrix_multiply_simd.o -o matrix_multiply_simd
```

### Convolution

```bash
cd convolution

nasm -f elf64 convolution.asm -o convolution.o
gcc -no-pie convolution.o -o convolution
```

The assembly programs call C library functions such as `scanf`, `printf`, and `putchar`, so the NASM object files are linked using GCC.

## Usage

### Matrix Multiplication Input Format

The matrix multiplication programs expect:

```text
n
A row 1
A row 2
...
A row n
B row 1
B row 2
...
B row n
```

Example:

```text
3
1 2 3
4 5 6
7 8 9
9 8 7
6 5 4
3 2 1
```

Run the scalar implementation:

```bash
cd matrix-multiplication
./matrix_multiply_scalar < input_3x3.txt
```

Run the SIMD implementation:

```bash
./matrix_multiply_simd < input_3x3.txt
```

Run the Python implementation:

```bash
python3 matrix_multiply_reference.py < input_3x3.txt
```

A 5×5 input is also available:

```bash
./matrix_multiply_scalar < input_5x5.txt
./matrix_multiply_simd < input_5x5.txt
python3 matrix_multiply_reference.py < input_5x5.txt
```

## Convolution Input Format

The convolution program expects:

```text
n
image row 1
image row 2
...
image row n
m
kernel row 1
kernel row 2
...
kernel row m
```

Run the sample input:

```bash
cd convolution
./convolution < sample_input.txt
```

The program prints the output dimension followed by the resulting matrix.

## Sharpening Kernel

`convolution/sharpen_kernel.txt` contains the following 3×3 sharpening kernel:

```text
0 -1 0
-1 5 -1
0 -1 0
```

This kernel increases the contribution of the center pixel while subtracting values from its direct neighbors.

## Benchmarking

Both implementation directories contain a small `benchmark.sh` script.

The script measures wall-clock execution time:

```bash
#!/usr/bin/env bash

time1=$(date +%s.%N)
./"$1"
time2=$(date +%s.%N)

echo "$time2 - $time1" | bc
```

Make the scripts executable:

```bash
chmod +x matrix-multiplication/benchmark.sh
chmod +x convolution/benchmark.sh
```

Example:

```bash
cd matrix-multiplication
./benchmark.sh matrix_multiply_scalar < input_3x3.txt
./benchmark.sh matrix_multiply_simd < input_3x3.txt
```

For convolution:

```bash
cd convolution
./benchmark.sh convolution < sample_input.txt
```

## Benchmark Results

Recorded benchmark outputs are stored in the `results/` directory.

### Matrix Multiplication

| Test | Scalar Assembly | SIMD Assembly | SIMD Speedup |
|---|---:|---:|---:|
| 3×3 benchmark | 2.3586 s | 1.5754 s | 1.50× |
| 5×5 benchmark | 9.0630 s | 5.3408 s | 1.70× |

The assembly benchmark sources repeat the multiplication many times so that execution time is large enough to measure more clearly.

### Convolution

| Implementation | Recorded Time |
|---|---:|
| Assembly | 0.06234 s |
| Python reference | 4.15188 s |

For this recorded run, the assembly implementation is approximately **66.6× faster**.

Benchmark results depend on the processor, operating system, CPU frequency scaling, background processes, linker behavior, and measurement method.

## Results Figures

### Matrix Multiplication

![Matrix multiplication benchmark results](docs/images/matrix-multiplication-results.png)

### Convolution

![Convolution benchmark results](docs/images/convolution-results.png)

## Project Report

The Persian project report is available here:

[Persian project report](docs/report-fa.pdf)

## Implementation Notes

### Calling Convention

The assembly source follows the x86-64 System V ABI used on Linux systems.

External C library functions are called using the standard calling convention, while floating-point matrix data is processed using SSE registers.

### Floating-Point Representation

The numerical data is stored as 32-bit IEEE-754 single-precision floating-point values.

Scalar operations use instructions such as:

```text
movss
mulss
addss
```

The SIMD implementation additionally uses packed instructions including:

```text
movups
mulps
addps
```

### SIMD Width

An XMM register is 128 bits wide.

Since each single-precision floating-point value occupies 32 bits:

```text
128 / 32 = 4
```

the SIMD multiplication implementation can process four `float32` values in one packed instruction.

## Limitations

- Matrix storage currently uses fixed-size buffers.
- Matrix row addressing assumes a fixed stride of 8 elements.
- Convolution image addressing assumes a row stride of 2048.
- Kernel addressing assumes a row stride of 8.
- The SIMD matrix multiplication implementation is based on SSE rather than AVX or AVX2.
- The project currently uses wall-clock shell timing rather than hardware performance counters.
- SIMD remainder handling is limited by the assumptions made in the current implementation.

