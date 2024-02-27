#include <algorithm>
#include <iostream>
#include <set>
#include <vector>
#include <CL/cl.h>

template <class T>
std::ostream& operator<<(std::ostream& out, std::vector<T>& v) {
    out << '[';
    for (size_t i = 0; i < v.size(); i++) {
        if (i != 0) out << ' ';
        out << v[i];
    }
    out << ']';
    return out;
}

void print() {
    //do nothing
}

template <class A, class... Args>
void print(A&& a, Args&&... args) {
    std::cout << a;
    print(std::forward<Args>(args)...);
}

template <class... Args>
void println(Args&&... args) {
    print(std::forward<Args>(args)...);
    std::cout << std::endl;
}

class exec_error : public std::runtime_error {
public:
    explicit exec_error(const std::string& what) : std::runtime_error(what) {}
    explicit exec_error(const char* what) : std::runtime_error(what) {}

    exec_error(const exec_error&) = default;
    exec_error& operator=(const exec_error&) = default;
};

/* #ext:begin:wmacros */
#define ERROR_MESSAGE(func, ...) "Request " #func "(" #__VA_ARGS__ __VA_OPT__(", ") "...) terminated with non-zero exit code " + std::to_string(err)

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

std::vector<cl_platform_id> wGetPlatformIDs() {
    REQUEST(uint32_t, cl_platform_id, clGetPlatformIDs)
}

/* #ext:end:wmacros */


std::vector<cl_device_id> wGetDeviceIDs(cl_platform_id platform, cl_device_type device_type) {
    REQUEST(cl_uint, cl_device_id, clGetDeviceIDs, platform, device_type)
}

template <class T>
std::vector<T> wGetPlatformInfo(cl_platform_id platform, cl_platform_info param) {
    REQUEST(size_t, T, clGetPlatformInfo, platform, param);
}

std::string wGetPlatformInfoStr(cl_platform_id platform, cl_platform_info param) {
    auto res = wGetPlatformInfo<char>(platform, param);
    return std::string(res.begin(), res.end());
}

#define CREATE(T, Func, ...)                                                     \
    cl_int err;                                                                  \
    T t = Func(__VA_ARGS__ __VA_OPT__(,) & err);                                 \
    if (err != 0) {                                                              \
        throw exec_error(ERROR_MESSAGE(Func,  __VA_ARGS__ __VA_OPT__(,), &err)); \
    }                                                                            \
    return t;

cl_context wCreateContext(const cl_context_properties* properties, std::vector<cl_device_id>& devices,
                          void (*pfn_notify)(const char* errinfo, const void* private_info, size_t cb, void* user_data) = nullptr,
                          void* user_data = nullptr) {
    CREATE(cl_context, clCreateContext, properties, devices.size(), devices.data(), pfn_notify, user_data)
}

cl_program wCreateProgramWithSource(
    cl_context context,
    cl_uint count,
    const char** strings,
    const size_t* lengths) {
    CREATE(cl_program, clCreateProgramWithSource, context, count, strings, lengths);
}

/* #ext:begin:buildmacro */
std::vector<char> wGetProgramBuildInfo(cl_program program,
                                       cl_device_id device,
                                       cl_program_build_info param_name) {
    REQUEST(size_t, char, clGetProgramBuildInfo, program, device, param_name);
}

void wBuildProgram(
    cl_program program,
    std::vector<cl_device_id>& devices,
    const char* options = "",
    void (*pfn_notify)(cl_program program, void* user_data) = nullptr,
    void* user_data = nullptr
) {
    auto err = clBuildProgram(program, devices.size(), devices.data(), options, pfn_notify, user_data);
    if (err != 0) {
        println("clBuildProgram returned with non-zero code: ", err);
        for (auto device : devices) {
            println();
            println("Build info for device ", device, ":");
            auto log = wGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG);
            println(std::string(log.begin(), log.end()));
        }
    };
}
/* #ext:end:buildmacro */

cl_kernel wCreateKernel(cl_program program, const char* kernel_name) {
    CREATE(cl_kernel, clCreateKernel, program, kernel_name);
}

cl_mem wCreateBuffer(cl_context context,
                     cl_mem_flags flags,
                     size_t size,
                     void* host_ptr) {
    CREATE(cl_mem, clCreateBuffer, context, flags, size, host_ptr);
}

/* #ext:begin:callmacro */
#define CALL(Func, ...)                                                   \
    cl_int err = Func(__VA_ARGS__);                                       \
    if (err != 0) {                                                       \
        throw exec_error(ERROR_MESSAGE(Func __VA_OPT__(,) __VA_ARGS__ )); \
    }
/* #ext:end:callmacro */

void wSetKernelArg(cl_kernel kernel,
                   cl_uint arg_index,
                   size_t arg_size,
                   const void* arg_value) {
    CALL(clSetKernelArg, kernel, arg_index, arg_size, arg_value)
}

cl_command_queue wCreateCommandQueue(cl_context context,
                                     cl_device_id device,
                                     cl_command_queue_properties properties) {
    CREATE(cl_command_queue, clCreateCommandQueue, context, device, properties);
}

void wEnqueueWriteBuffer(cl_command_queue command_queue,
                         cl_mem buffer,
                         cl_bool blocking_write,
                         size_t offset,
                         size_t size,
                         const void* ptr,
                         cl_uint num_events_in_wait_list,
                         const cl_event* event_wait_list,
                         cl_event* event) {
    CALL(clEnqueueWriteBuffer, command_queue, buffer, blocking_write, offset, size, ptr, num_events_in_wait_list,
         event_wait_list, event);
}

void wEnqueueNDRangeKernel(cl_command_queue command_queue,
                           cl_kernel kernel,
                           cl_uint work_dim,
                           const size_t* global_work_offset,
                           const size_t* global_work_size,
                           const size_t* local_work_size,
                           cl_uint num_events_in_wait_list = 0,
                           const cl_event* event_wait_list = nullptr,
                           cl_event* event = nullptr) {
    CALL(clEnqueueNDRangeKernel, command_queue, kernel, work_dim, global_work_offset, global_work_size, local_work_size,
         num_events_in_wait_list, event_wait_list, event);
}

void wEnqueueReadBuffer(
    cl_command_queue command_queue,
    cl_mem buffer,
    cl_bool blocking_read,
    size_t offset,
    size_t size,
    void* ptr,
    cl_uint num_events_in_wait_list = 0,
    const cl_event* event_wait_list = nullptr,
    cl_event* event = nullptr) {
    CALL(clEnqueueReadBuffer, command_queue, buffer, blocking_read, offset, size, ptr, num_events_in_wait_list,
         event_wait_list, event);
}
