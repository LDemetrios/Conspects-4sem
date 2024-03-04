#include <algorithm>
#include <iostream>
#include <vector>
#include <CL/cl.h>
#include "utils.h"
#include "wrappers.h"

std::vector<char> readfile(const char* name) {
    FILE* file = fopen(name, "rb");
    fseek(file, 0, SEEK_END);
    size_t len = ftell(file);
    rewind(file);

    std::vector<char> result(len);
    fread(result.data(), sizeof(char), len, file);
    fclose(file);

    return result;
}

int main() {
    auto platforms = wGetPlatformIDs();
    println(platforms);

    for (auto platform : platforms) {
        println();
        println(platform);
        auto profile = wGetPlatformInfoStr(platform, CL_PLATFORM_PROFILE);
        auto version = wGetPlatformInfoStr(platform, CL_PLATFORM_VERSION);
        auto name = wGetPlatformInfoStr(platform, CL_PLATFORM_NAME);
        auto vendor = wGetPlatformInfoStr(platform, CL_PLATFORM_VENDOR);
        auto extensions = wGetPlatformInfoStr(platform, CL_PLATFORM_EXTENSIONS);
        auto host_timer_resolution = wGetPlatformInfo<cl_ulong>(platform, CL_PLATFORM_HOST_TIMER_RESOLUTION);
        println("Profile:               ", profile);
        println("Version:               ", version);
        println("Name:                  ", name);
        println("Vendor:                ", vendor);
        println("Extensions:            ", extensions);
        println("Host Timer Resolution: ", host_timer_resolution);
    }


    for (auto platform : platforms) {
        println("For platform ", platform);
        println("CPU:         ", wGetDeviceIDs( platform, CL_DEVICE_TYPE_CPU));
        println("GPU:         ", wGetDeviceIDs( platform, CL_DEVICE_TYPE_GPU));
        println("ACCELERATOR: ", wGetDeviceIDs( platform,
                                                  CL_DEVICE_TYPE_ACCELERATOR));
        println("DEFAULT:     ", wGetDeviceIDs( platform, CL_DEVICE_TYPE_DEFAULT));
        println("ALL:         ", wGetDeviceIDs( platform, CL_DEVICE_TYPE_ALL));
    }

    std::vector<cl_device_id> devices = wGetDeviceIDs(platforms[0], CL_DEVICE_TYPE_ALL);

    auto context = wCreateContext(nullptr, devices, nullptr, nullptr);

    auto source = readfile("program.cl");
    const char* ptr = source.data();
    const size_t len = source.size();

    cl_program program = wCreateProgramWithSource(context, 1, &ptr, &len);

    wBuildProgram(program, devices, "", nullptr, nullptr);

    cl_kernel add = wCreateKernel(program, "add");;
    cl_mem aBuffer = wCreateBuffer(context, CL_MEM_READ_ONLY, 4, nullptr);
    cl_mem bBuffer = wCreateBuffer(context, CL_MEM_READ_ONLY, 4, nullptr);
    cl_mem cBuffer = wCreateBuffer(context, CL_MEM_WRITE_ONLY, 4, nullptr);
    wSetKernelArg(add, 0, sizeof(cl_mem), &aBuffer);
    wSetKernelArg(add, 1, sizeof(cl_mem), &bBuffer);
    wSetKernelArg(add, 2, sizeof(cl_mem), &cBuffer);

    auto command_queue = wCreateCommandQueue(context, devices[0], CL_QUEUE_PROFILING_ENABLE);
    cl_int a = 2;
    cl_int b = 3;

    wEnqueueWriteBuffer(command_queue, aBuffer, false, 0, 4, &a, 0, nullptr, nullptr);
    wEnqueueWriteBuffer(command_queue, bBuffer, false, 0, 4, &b, 0, nullptr, nullptr);

    size_t global_work_size = 1;
    wEnqueueNDRangeKernel(command_queue, add, 1, nullptr, &global_work_size,
                          nullptr, 0, nullptr, nullptr);
    cl_int c = 0;
    wEnqueueReadBuffer(command_queue, cBuffer, true, 0, 4, &c, 0, nullptr, nullptr);
    println(c);

    clReleaseMemObject(aBuffer);
    clReleaseMemObject(bBuffer);
    clReleaseMemObject(cBuffer);
    clReleaseProgram(program);
    clReleaseKernel(add);
    clReleaseCommandQueue(command_queue);
    clReleaseContext(context);
}


