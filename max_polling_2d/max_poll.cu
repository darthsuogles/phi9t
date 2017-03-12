// -*- c++-mode -*-
#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <cassert>
#include <gflags/gflags.h>

DEFINE_int32(kernel_grid_dim, 32, "[CUDA]: kernel's grid (square) size.");
DEFINE_int32(kernel_block_dim, 16, "[CUDA]: kernel's block (square) size.");
//DEFINE_int32(kernel_block_mult, 4, "[CUDA]: multiplicity of the sub-image each block works on.");
DEFINE_bool(validate, false, "Check the correctness of the result against reference CPU implementation.");
//DEFINE_bool(perf_test, false, "Whether to perform test the implementation.");
DEFINE_bool(random_init, false, "Whether to create randomly initialized data.");

#define CHECK_ERROR(...) {                                  \
        cudaGetLastError();                                 \
        __VA_ARGS__;                                        \
        cudaError_t err = cudaPeekAtLastError();            \
        if ( cudaSuccess != err ) {                         \
            printf("[CUDA ERROR] => %s\n\tmsg: %s\n",		\
                   #__VA_ARGS__, cudaGetErrorString(err));	\
        }                                                   \
    }

template <typename T>
struct Image3D {
    size_t nrows, ncols, nz;
    size_t nbytes;
    T *data;

    T get(int z, int x, int y) {
        return data[x + ncols * (y + nrows * z)];
    }

    void set(int z, int x, int y, T val) {
        data[x + ncols * (y + nrows * z)] = val;
    }

    Image3D(size_t nrows, size_t ncols, size_t nz)
        : nrows(nrows), ncols(ncols), nz(nz) {
        nbytes = nrows * ncols * nz * sizeof(T);
        data = new T[nrows * ncols * nz];
    }

    ~Image3D() {
        delete [] data;
    }

    void print() {
        for (int z = 0; z < nz; ++z) {
            for (int y = 0; y < nrows; ++y) {
                for (int x = 0; x < ncols; ++x) {
                    printf("%3d ", get(z, x, y));
                }
                std::cout << std::endl;
            }
            std::cout << "<--- z: " << z << "--->" << std::endl;
        }
        std::cout << "-----------------------------------" << std::endl;
    }
};

template <typename T>
__global__ void maxPoll2D_naive(const T *img_src, 
                                size_t nrows, size_t ncols, size_t nz,
                                T *img_dst, size_t K) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    int idy = threadIdx.y + blockIdx.y * blockDim.y;
    int tile_dim_x = blockDim.x * gridDim.x;
    int tile_dim_y = blockDim.y * gridDim.y;

    const T MIN_VAL = (T) INT_MIN;

    size_t nx = ncols - K + 1;
    size_t ny = nrows - K + 1;

    for (int z = 0; z < nz; ++z) {
        T *zimg_src = img_src + z * ncols * nrows;
        T *zimg_dst = img_dst + z * ny * nx;

        for (int y = idy; y < ny; y += tile_dim_y) {
            for (int x = idx; x < nx; x += tile_dim_x) {
                T max_val = MIN_VAL;
                for (int iy = y; iy < y + K; ++iy) {
                    T *pwnd = zimg_src + iy * ncols + x;
                    for (int i = 0; i < K; ++i)
                        max_val = max(max_val, *pwnd++);
                }
                zimg_dst[x + nx * y] = max_val;
            }
        }
    }
}

/**
 * With a block dimension, too
 */
template <typename T, int BLK_M>
__global__ void maxPoll2D(const T *img_src, 
                          int nrows, int ncols, int nz,
                          T *img_dst, int K) {
    const T MIN_VAL = (T) INT_MIN;

    int dst_nrows = nrows - K + 1;
    int dst_ncols = ncols - K + 1;
    int dst_nbx = BLK_M * blockDim.x;
    int dst_nby = BLK_M * blockDim.y;
    int dst_stride_x = dst_nbx * gridDim.x;
    int dst_stride_y = dst_nby * gridDim.y;
    int src_nbx = dst_nbx + K - 1;
    int src_nby = dst_nby + K - 1;

    extern __shared__ T shmem_img_src[]; // at least src_nbx * src_nby * sizeof(T)

    for (int z = blockIdx.z; z < nz; z += gridDim.z) {
        const T *zimg_src = img_src + z * ncols * nrows;
        T *zimg_dst = img_dst + z * dst_ncols * dst_nrows;

        for (int by = blockIdx.y * dst_nby;
             by < dst_nrows; by += dst_stride_y) {
            for (int bx = blockIdx.x * dst_nbx;
                 bx < dst_ncols; bx += dst_stride_x) {

                // Copy data into shared memory
                int src_bndx = min(src_nbx, ncols - bx);
                int src_bndy = min(src_nby, nrows - by);
                for (int ty = threadIdx.y;
                     ty < src_bndy; ty += blockDim.y) {
                    for (int tx = threadIdx.x;
                         tx < src_bndx; tx += blockDim.x) {
                        shmem_img_src[ tx + src_nbx * ty ] =
                            zimg_src[ tx + bx + ncols * (ty + by) ];
                    }
                }
                __syncthreads();

                // Compute max polling
                int dst_bndx = min(dst_nbx, dst_ncols - bx);
                int dst_bndy = min(dst_nby, dst_nrows - by);
                for (int ty = threadIdx.y;
                     ty < dst_bndy; ty += blockDim.y) {
                    for (int tx = threadIdx.x;
                         tx < dst_bndx; tx += blockDim.x) {
                        T max_val = MIN_VAL;
                        for (int i = 0; i < K; ++i) {
                            for (int j = 0; j < K; ++j) {
                                max_val = max(max_val,
                                              shmem_img_src[tx + j + src_nbx * (ty + i)]);
                            }
                        }
                        zimg_dst[ tx + bx + dst_ncols * (ty + by) ] = max_val;
                    }
                }
                __syncthreads(); // !! must sync before proceeding to next loop
            }
        }
    }
}

struct KernelProfile {
    dim3 grid_dim;
    dim3 block_dim;

    void print(std::ostream &ostrm = std::cerr) {
        ostrm << "[CUDA]  grid size: "
              << "x = " << grid_dim.x << " "
              << "y = " << grid_dim.y << " "
              << "z = " << grid_dim.z << std::endl;
        ostrm << "[CUDA] block size: "
              << "x = " << block_dim.x << " "
              << "y = " << block_dim.y << " "
              << "z = " << block_dim.z << std::endl;
    }
};

template <typename T, int BLK_M>
Image3D<T> maxPollGPU(const Image3D<T> &img_orig, int K,
                      const KernelProfile &kernel_profile) {
    // Size of the max polling kernel
    int nrows = img_orig.nrows;
    int ncols = img_orig.ncols;
    int nz = img_orig.nz;
    Image3D<int> img_poll(nrows - K + 1, ncols - K + 1, nz);

    // Allocate GPU memory
    int *d_img_src, *d_img_dst;

    size_t IMG_SRC_NBYTES = img_orig.nbytes;
    size_t IMG_DST_NBYTES = img_poll.nbytes;
    CHECK_ERROR( cudaMalloc((void **) &d_img_src, IMG_SRC_NBYTES) );
    CHECK_ERROR( cudaMalloc((void **) &d_img_dst, IMG_DST_NBYTES) );

    int *h_img_src = img_orig.data;
    int *h_img_dst = img_poll.data;

    //dim3 cuGridDim(32, 32, nz), cuBlockDim(16, 16, 1);
    dim3 cuGridDim = kernel_profile.grid_dim;
    dim3 cuBlockDim = kernel_profile.block_dim;
  
    size_t SHMEM_NBYTES = 256 + sizeof(int) *
        (BLK_M * cuBlockDim.x + K - 1) *
        (BLK_M * cuBlockDim.y + K - 1);

    printf("Computing max polling for image size: %d %d %d, K = %d\n", nrows, ncols, nz, K);
    CHECK_ERROR( cudaMemcpy(d_img_src, h_img_src, IMG_SRC_NBYTES, cudaMemcpyHostToDevice) );
    CHECK_ERROR( maxPoll2D<int, BLK_M>
                 <<<cuGridDim, cuBlockDim, SHMEM_NBYTES>>>(d_img_src, nrows, ncols, nz, d_img_dst, K) );
    //CHECK_ERROR( maxPoll2D_naive<int><<<cuGridDim, cuBlockDim>>>(d_img_src, nrows, ncols, nz, d_img_dst, K) );
    CHECK_ERROR( cudaMemcpy(h_img_dst, d_img_dst, IMG_DST_NBYTES, cudaMemcpyDeviceToHost) );

    cudaFree(d_img_src);
    cudaFree(d_img_dst);
    return img_poll;
}

int main(int argc, char **argv) {
    // // img_orig.print();
    gflags::ParseCommandLineFlags(&argc, &argv, true);
  
    int nrows, ncols, nz, K;
    bool is_parse_stdin = false;
    if ( 5 == argc ) {
        std::cerr << "Parsing input sizes from stdin" << std::endl;
        nrows = atoi(argv[1]);
        ncols = atoi(argv[2]);
        nz = atoi(argv[3]);
        K = atoi(argv[4]);
    } else {
        std::cerr << "Parsing from stdin" << std::endl;
        std::cin >> nrows >> ncols >> nz;
        is_parse_stdin = true;
    }

    Image3D<int> img_orig(nrows, ncols, nz);
    if ( is_parse_stdin ) {
        for (int z = 0; z < nz; ++z) {
            for (int y = 0; y < nrows; ++y) {
                for (int x = 0; x < ncols; ++x) {
                    int val; std::cin >> val;
                    img_orig.set(z, x, y, val);
                }
            }
        }
        std::cin >> K;
    }

    // Randomly initialize the input
    if ( FLAGS_random_init ) {
        std::cerr << "Randomly initializing input, might take a while ..." << std::endl;
        for (int z = 0; z < nz; ++z) {
            for (int y = 0; y < nrows; ++y)
                for (int x = 0; x < ncols; ++x)
                    img_orig.set(z, x, y, rand() % 256);
        }
    }

    dim3 cuGridDim(FLAGS_kernel_grid_dim, FLAGS_kernel_grid_dim, nz);
    dim3 cuBlockDim(FLAGS_kernel_block_dim, FLAGS_kernel_block_dim, 1);
    KernelProfile kernel_profile;
    kernel_profile.grid_dim = cuGridDim;
    kernel_profile.block_dim = cuBlockDim;
    kernel_profile.print();
  
    Image3D<int> img_poll = maxPollGPU<int, 3>(img_orig, K, kernel_profile);
    //cout << img_poll.nrows << " " << img_poll.ncols << endl;  

    // Check the result
    if ( FLAGS_validate ) {
        std::cerr << "Validating result, might take a while ... ";
        int num_err = 0;
        for (int z = 0; z < nz; ++z)
            for (int y = 0; y < nrows - K + 1; ++y)
                for (int x = 0; x < ncols - K + 1; ++x) {
                    int ref_max = INT_MIN;
                    for (int i = 0; i < K; ++i)
                        for (int j = 0; j < K; ++j)
                            ref_max = max(ref_max, img_orig.get(z, x + j, y + i));

                    int val = img_poll.get(z, x, y);
                    if ( val != ref_max ) {
                        // printf("z = %d, x = %d, y = %d, val = %d, ref = %d\n",
                        // 	 z, x, y, val, ref_max);
                        ++num_err;
                    }
                }
        if ( 0 == num_err )
            std::cerr << "PASSED !" << std::endl;
        else
            std::cerr << "FAILED with error counts: " << num_err << std::endl;
    }
    //assert( 0 == num_err );
    //img_poll.print();
}
