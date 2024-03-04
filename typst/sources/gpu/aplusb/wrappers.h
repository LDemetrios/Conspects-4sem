#ifndef WRAPPERS_H
#define WRAPPERS_H

#include "utils.h"
#include <stdexcept>
#include <string>
#include <vector>
#include <CL/cl.h>

class exec_error : public std::runtime_error {
public:
    explicit exec_error(const std::string& what) : std::runtime_error(what) {}
    explicit exec_error(const char* what) : std::runtime_error(what) {}

    exec_error(const exec_error&) = default;
    exec_error& operator=(const exec_error&) = default;
};

#define ERROR_MESSAGE(func, ...) ("Request " #func "(" #__VA_ARGS__ __VA_OPT__(", ") "...) terminated with non-zero exit code " + std::to_string(err) + ": " + wErrorCode(err))

#define REQUEST(SizeT, T, Func, ...)                                                                     \
    SizeT size;                                                                                          \
    auto err = Func(__VA_ARGS__ __VA_OPT__(,) 0, nullptr, &size);                                        \
    if (err != 0) {                                                                                      \
        if (err == -1) return {};                                                                        \
        throw exec_error ( ERROR_MESSAGE(Func,  __VA_ARGS__ __VA_OPT__(,) 0, nullptr, &size));           \
    }                                                                                                    \
    std::vector<T> result(size);                                                                         \
    err = Func(__VA_ARGS__ __VA_OPT__(,) size, result.data(), &size);                                    \
    if (err != 0) {                                                                                      \
        throw exec_error ( ERROR_MESSAGE(Func,  __VA_ARGS__ __VA_OPT__(,), size, result.data(), &size)); \
    }                                                                                                    \
    return result;

/* #ext:begin:callmacro */
#define CALL(Func, ...)                                                   \
    cl_int err = Func(__VA_ARGS__);                                       \
    if (err != 0) {                                                       \
        throw exec_error(ERROR_MESSAGE(Func __VA_OPT__(,) __VA_ARGS__ )); \
    }
/* #ext:end:callmacro */

#define CREATE(T, Func, ...)                                                     \
    cl_int err;                                                                  \
    T t = Func(__VA_ARGS__ __VA_OPT__(,) & err);                                 \
    if (err != 0) {                                                              \
        throw exec_error(ERROR_MESSAGE(Func,  __VA_ARGS__ __VA_OPT__(,), &err)); \
    }                                                                            \
    return t;


std::vector<cl_platform_id> wGetPlatformIDs();

std::vector<cl_device_id> wGetDeviceIDs(cl_platform_id platform, cl_device_type device_type);

template <class T>
std::vector<T> wGetPlatformInfo(cl_platform_id platform, cl_platform_info param) {
    REQUEST(size_t, T, clGetPlatformInfo, platform, param);
}

std::string wGetPlatformInfoStr(cl_platform_id platform, cl_platform_info param);


cl_context wCreateContext(
const cl_context_properties* properties,
 std::vector<cl_device_id>& devices,
                          void (*pfn_notify)(const char* errinfo, const void* private_info, size_t cb, void* user_data) = nullptr,
                          void* user_data = nullptr
);

cl_program wCreateProgramWithSource(
    cl_context context,
    cl_uint count,
    const char** strings,
    const size_t* lengths);

std::vector<char> wGetProgramBuildInfo(cl_program program,
                                       cl_device_id device,
                                       cl_program_build_info param_name);

void wBuildProgram(
    cl_program program,
    std::vector<cl_device_id>& devices,
    const char* options = "",
    void (*pfn_notify)(cl_program program, void* user_data) = nullptr,
    void* user_data = nullptr
);

cl_kernel wCreateKernel(cl_program program, const char* kernel_name);

cl_mem wCreateBuffer(cl_context context,
                     cl_mem_flags flags,
                     size_t size,
                     void* host_ptr);

void wSetKernelArg(cl_kernel kernel,
                   cl_uint arg_index,
                   size_t arg_size,
                   const void* arg_value);
cl_command_queue wCreateCommandQueue(cl_context context,
                                     cl_device_id device,
                                     cl_command_queue_properties properties);

void wEnqueueWriteBuffer(cl_command_queue command_queue,
                         cl_mem buffer,
                         cl_bool blocking_write,
                         size_t offset,
                         size_t size,
                         const void* ptr,
                         cl_uint num_events_in_wait_list,
                         const cl_event* event_wait_list,
                         cl_event* event);

void wEnqueueNDRangeKernel(cl_command_queue command_queue,
                           cl_kernel kernel,
                           cl_uint work_dim,
                           const size_t* global_work_offset,
                           const size_t* global_work_size,
                           const size_t* local_work_size,
                           cl_uint num_events_in_wait_list = 0,
                           const cl_event* event_wait_list = nullptr,
                           cl_event* event = nullptr);

void wEnqueueReadBuffer(
    cl_command_queue command_queue,
    cl_mem buffer,
    cl_bool blocking_read,
    size_t offset,
    size_t size,
    void* ptr,
    cl_uint num_events_in_wait_list = 0,
    const cl_event* event_wait_list = nullptr,
    cl_event* event = nullptr);
#endif // WRAPPERS_H
