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

template <class SizeT, class T>
std::vector<T> cl_request(auto func, const char* what, auto... args) {
    SizeT size;
    auto err = func(args..., 0, nullptr, &size);
    if (err != 0) {
        if (err == -1) return {}; // -1	if no OpenCL devices that matched device_type were found.
        throw exec_error(std::string(what) + std::to_string(err) + " while obtaining data size");
    }
    std::vector<T> result(size);
    err = func(args..., size, result.data(), &size);
    if (err != 0) {
        throw exec_error(std::string(what) + std::to_string(err) + " while obtaining data");
    }
    return result;
}

std::string cl_request_str(auto func, const char* what, auto... args) {
    std::vector<char> res = cl_request<size_t, char>(func, what, args...);
    return std::string(res.begin(), res.end());
}

template <class T>
T cl_create(auto func, const char* what, auto... args) {
    cl_int err;
    T t = func(args..., &err);
    if (err != 0) {
        throw exec_error(std::string(what) + std::to_string(err) + " while creating");
    }
    return t;
}

void cl_call(auto func, const char* what, auto... args) {
    cl_int err = func(args...);
    if (err != 0) {
        throw exec_error(std::string(what) + std::to_string(err) + " while calling");
    }
}

#define generate_error_message(func, ...) "Request " #func "(" #__VA_ARGS__ __VA_OPT__(", ") "...) terminated with non-zero exit code "

#define request(SizeT, T, func, ...) cl_request<SizeT, T>(&func, generate_error_message(func __VA_OPT__(,) __VA_ARGS__ ) __VA_OPT__(,) __VA_ARGS__)

#define request_str(func, ...) cl_request_str(&func, generate_error_message(func __VA_OPT__(,) __VA_ARGS__ ) __VA_OPT__(,) __VA_ARGS__)

#define create(T, func, ...) cl_create<T>(&func, generate_error_message(func __VA_OPT__(,) __VA_ARGS__ ) __VA_OPT__(,) __VA_ARGS__)

#define call(func, ...) cl_call(&func, generate_error_message(func __VA_OPT__(,) __VA_ARGS__ ) __VA_OPT__(,) __VA_ARGS__)


int main() {
auto platforms = request(uint32_t, cl_platform_id, clGetPlatformIDs);
std::vector<cl_device_id> devices = request(
    cl_uint, cl_device_id, clGetDeviceIDs, platforms[0], CL_DEVICE_TYPE_ALL
);

for (auto platform : platforms) {
    println(platform);
    auto profile = request_str(clGetPlatformInfo, platform, CL_PLATFORM_PROFILE);
    auto version = request_str(clGetPlatformInfo, platform, CL_PLATFORM_VERSION);
    auto name = request_str(clGetPlatformInfo, platform, CL_PLATFORM_NAME);
    auto vendor = request_str(clGetPlatformInfo, platform, CL_PLATFORM_VENDOR);
    auto extensions = request_str(clGetPlatformInfo, platform, CL_PLATFORM_EXTENSIONS);
    auto host_timer_resolution = request(size_t, cl_ulong, clGetPlatformInfo, platform,
                                          CL_PLATFORM_HOST_TIMER_RESOLUTION);
    println("Profile:               ", profile);
    println("Version:               ", version);
    println("Name:                  ", name);
    println("Vendor:                ", vendor);
    println("Extensions:            ", extensions);
    println("Host Timer Resolution: ", host_timer_resolution);
}
auto context = create(cl_context, clCreateContext, nullptr, devices.size(), devices.data(), nullptr, nullptr);
const char* source = "kernel void add(global const int *a, "
                                                "global const int *b, global int *c) {\n"
    "    *c = *a + *b;\n"
    "}\n";
std::vector<const char*> source_arr{source};

std::vector<size_t> source_lengths(source_arr.size());
std::transform(
    source_arr.begin(), source_arr.end(), source_lengths.begin(),
    [](const char* s) -> size_t { return std::string(s).length(); });

cl_program program = create(cl_program, clCreateProgramWithSource, context,
                            source_arr.size(), source_arr.data(), source_lengths.data());

println(program);

auto err = clBuildProgram(program, devices.size(), devices.data(), "", nullptr, nullptr);
if(err != 0) {
    println("clBuildProgram returned with non-zero code: ", err);
    for(auto device : devices) {
        println();
        println("Build info for device ", device, ":");
        println(request_str(clGetProgramBuildInfo, program, device, CL_PROGRAM_BUILD_LOG));
    }
};
 cl_kernel add = create(cl_kernel, clCreateKernel, program, "add");;
 cl_mem aBuffer = create(cl_mem, clCreateBuffer, context, CL_MEM_READ_ONLY, 4, nullptr);
cl_mem bBuffer = create(cl_mem, clCreateBuffer, context, CL_MEM_READ_ONLY, 4, nullptr);
cl_mem cBuffer = create(cl_mem, clCreateBuffer, context, CL_MEM_WRITE_ONLY, 4, nullptr);;
 err = clSetKernelArg(add, 0, sizeof(cl_mem), &aBuffer);
if (err != 0) throw exec_error("Can't set 0th kernel arg");
err = clSetKernelArg(add, 1, sizeof(cl_mem), &bBuffer);
if (err != 0) throw exec_error("Can't set 1st kernel arg");
err = clSetKernelArg(add, 2, sizeof(cl_mem), &cBuffer);
if (err != 0) throw exec_error("Can't set 2nd kernel arg");;
 auto command_queue = create(
    cl_command_queue, clCreateCommandQueue, context, devices[0], CL_QUEUE_PROFILING_ENABLE
);;
 cl_int a = 2;
cl_int b = 3;

call(clEnqueueWriteBuffer, command_queue, aBuffer, false, 0, 4, &a, 0, nullptr, nullptr);
call(clEnqueueWriteBuffer, command_queue, bBuffer, false, 0, 4, &b, 0, nullptr, nullptr);;
 size_t global_work_size = 1;
call(clEnqueueNDRangeKernel, command_queue, add, 1,
            nullptr, &global_work_size, nullptr, 0, nullptr, nullptr);;
 cl_int c = 0;
call(clEnqueueReadBuffer, command_queue, cBuffer, true, 0, 4, &c, 0, nullptr, nullptr);
println(c);

clReleaseMemObject(aBuffer);
clReleaseMemObject(bBuffer);
clReleaseMemObject(cBuffer);
clReleaseProgram(program);
clReleaseKernel(add);
clReleaseCommandQueue(command_queue);
clReleaseContext(context);
}
