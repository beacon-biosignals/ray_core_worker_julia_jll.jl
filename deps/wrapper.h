#pragma once

#include <string>

#include "jlcxx/jlcxx.hpp"
#include "ray/core_worker/common.h"
#include "ray/core_worker/core_worker.h"
#include "src/ray/protobuf/common.pb.h"

using namespace ray;
using ray::core::CoreWorkerProcess;
using ray::core::CoreWorkerOptions;
using ray::core::WorkerType;

void initialize_coreworker(int node_manager_port);
void shutdown_coreworker();
ObjectID put(void *ptr, size_t size);
void *get(ObjectID object_id);
LocalMemoryBuffer *demo(LocalMemoryBuffer *buffer);

std::string ToString(ray::FunctionDescriptor function_descriptor);

JLCXX_MODULE define_julia_module(jlcxx::Module& mod);
