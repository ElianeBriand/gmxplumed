# GMXPlumed
[![](https://img.shields.io/docker/pulls/elianebriand/gmxplumed_avx2.svg)](https://hub.docker.com/r/elianebriand/gmxplumed_avx2) [![](https://img.shields.io/github/last-commit/elianebriand/gmxplumed.svg)](https://github.com/ElianeBriand/gmxplumed/commits)
 
 

## Software versions
*   Gromacs v2019.4
*   Plumed v2.6
*   CUDA v10.0
*   Ubuntu v16.04

## Docker hub image:

```
docker run -it elianebriand/gmxplumed_avx2
```

## Notes
Gromacs is configured to use AVX2_256 instructions and will therefore run only on newest Intel hardware. MPI is enabled for PLUMED, while Gromacs is compiled with gcc with OpenMP threading only.
