const STATUS_CODE_SYMBOLS = (:OK,
                             :OutOfMemory,
                             :KeyError,
                             :TypeError,
                             :Invalid,
                             :IOError,
                             :UnknownError,
                             :NotImplemented,
                             :RedisError,
                             :TimedOut,
                             :Interrupted,
                             :IntentionalSystemExit,
                             :UnexpectedSystemExit,
                             :CreationTaskError,
                             :NotFound,
                             :Disconnected,
                             :SchedulingCancelled,
                             :ObjectExists,
                             :ObjectNotFound,
                             :ObjectAlreadySealed,
                             :ObjectStoreFull,
                             :TransientObjectStoreFull,
                             :GrpcUnavailable,
                             :GrpcUnknown,
                             :OutOfDisk,
                             :ObjectUnknownOwner,
                             :RpcError,
                             :OutOfResource,
                             :ObjectRefEndOfStream)

const LANGUAGE_SYMBOLS = (:PYTHON, :JAVA, :CPP, :JULIA)
const WORKER_TYPE_SYMBOLS = (:WORKER, :DRIVER, :SPILL_WORKER, :RESTORE_WORKER)

const ERROR_TYPE_SYMBOLS = (:WORKER_DIED,
                            :ACTOR_DIED,
                            :OBJECT_UNRECONSTRUCTABLE,
                            :TASK_EXECUTION_EXCEPTION,
                            :OBJECT_IN_PLASMA,
                            :TASK_CANCELLED,
                            :ACTOR_CREATION_FAILED,
                            :RUNTIME_ENV_SETUP_FAILED,
                            :OBJECT_LOST,
                            :OWNER_DIED,
                            :OBJECT_DELETED,
                            :DEPENDENCY_RESOLUTION_FAILED,
                            :OBJECT_UNRECONSTRUCTABLE_MAX_ATTEMPTS_EXCEEDED,
                            :OBJECT_UNRECONSTRUCTABLE_LINEAGE_EVICTED,
                            :OBJECT_FETCH_TIMED_OUT,
                            :LOCAL_RAYLET_DIED,
                            :TASK_PLACEMENT_GROUP_REMOVED,
                            :ACTOR_PLACEMENT_GROUP_REMOVED,
                            :TASK_UNSCHEDULABLE_ERROR,
                            :ACTOR_UNSCHEDULABLE_ERROR,
                            :OUT_OF_DISK_ERROR,
                            :OBJECT_FREED,
                            :OUT_OF_MEMORY,
                            :NODE_DIED)

# Generate the following methods for our wrapped enum types:
# - A constructor allowing you to create a value via a `Symbol` (e.g. `StatusCode(:OK)`).
# - A `Symbol` method allowing you convert a enum value to a `Symbol` (e.g. `Symbol(OK)`).
# - A `instances` method allowing you to get a list of all enum values (e.g. `instances(StatusCode)`).
@eval begin
    $(_enum_expr(:StatusCode, STATUS_CODE_SYMBOLS))
    $(_enum_expr(:Language, LANGUAGE_SYMBOLS))
    $(_enum_expr(:WorkerType, WORKER_TYPE_SYMBOLS))
    $(_enum_expr(:ErrorType, ERROR_TYPE_SYMBOLS))
end

function check_status(status::Status)
    ok(status) && return nothing

    msg = message(status)

    # TODO: Implement throw custom exception types like in:
    # _raylet.pyx:437
    error(msg)

    return nothing
end

#####
##### Function descriptor wrangling
#####

# build a FunctionDescriptor from a julia function
function function_descriptor(f::Function)
    mod = string(parentmodule(f))
    name = string(nameof(f))
    hash = let io = IOBuffer()
        serialize(io, f)
        # hexidecimal string repr of hash
        string(Base.hash(io.data); base=16)
    end
    return function_descriptor(mod, name, hash)
end

Base.show(io::IO, fd::FunctionDescriptor) = print(io, ToString(fd))
Base.show(io::IO, fd::JuliaFunctionDescriptor) = print(io, ToString(fd))
function Base.propertynames(fd::JuliaFunctionDescriptor, private::Bool=false)
    public_properties = (:module_name, :function_name, :function_hash)
    return if private
        tuple(public_properties..., fieldnames(typeof(fd))...)
    else
        public_properties
    end
end

function Base.getproperty(fd::JuliaFunctionDescriptor, field::Symbol)
    return if field === :module_name
        # these return refs so we need to de-reference them
        ModuleName(fd)[]
    elseif field === :function_name
        FunctionName(fd)[]
    elseif field === :function_hash
        FunctionHash(fd)[]
    else
        Base.getfield(fd, field)
    end
end

Base.show(io::IO, status::Status) = print(io, ToString(status))

const CORE_WORKER = Ref{Union{CoreWorker,Nothing}}()

function GetCoreWorker()
    if !isassigned(CORE_WORKER) || isnothing(CORE_WORKER[])
        CORE_WORKER[] = _GetCoreWorker()[]
    end
    return CORE_WORKER[]::CoreWorker
end

function shutdown_driver()
    _shutdown_driver()
    CORE_WORKER[] = nothing

    return nothing
end

#####
##### Message
#####

function ParseFromString(::Type{T}, str::AbstractString) where {T<:Message}
    message = T()
    ParseFromString(message, str)
    return message
end

function JsonStringToMessage(::Type{T}, json::AbstractString) where {T<:Message}
    message = T()
    JsonStringToMessage(json, CxxPtr(message))
    return message
end

let msg_types = (Address, JobConfig, ObjectReference)
    for T in msg_types
        types = (Symbol(nameof(T), :Allocated), Symbol(nameof(T), :Dereferenced))
        for A in types, B in types
            @eval function Base.:(==)(a::$A, b::$B)
                serialized_a = safe_convert(String, SerializeAsString(a))
                serialized_b = safe_convert(String, SerializeAsString(b))
                return serialized_a == serialized_b
            end
        end
    end
end

function Serialization.serialize(s::AbstractSerializer, message::Message)
    serialized_message = safe_convert(String, SerializeAsString(message))

    serialize_type(s, Message)
    serialize(s, supertype(typeof(message)))
    serialize(s, serialized_message)

    return nothing
end

function Serialization.deserialize(s::AbstractSerializer, ::Type{Message})
    T = deserialize(s)
    serialized_message = deserialize(s)

    message = T()
    ParseFromString(message, safe_convert(StdString, serialized_message))

    return message
end

#####
##### Address <: Message
#####

# there's annoying conversion from protobuf binary blobs for the "fields" so we
# handle it on the C++ side rather than wrapping everything.
Base.show(io::IO, addr::Address) = print(io, _string(addr))

#####
##### Buffer
#####

NullPtr(::Type{Buffer}) = BufferFromNull()

#####
##### BaseID
#####

for T in (:ObjectID, :JobID, :TaskID)
    @eval begin
        function FromBinary(::Type{$T}, str::AbstractString)
            if ncodeunits(str) != 28
                msg = "Expected binary size is 28, provided data size is $(ncodeunits(str)): $(repr(str))"
                throw(ArgumentError(msg))
            end
            return $(Symbol(T, :FromBinary))(str)
        end

        function FromHex(::Type{$T}, str::AbstractString)
            if length(str) != 2 * 28
                msg = "Expected hex string length is 2 * 28, provided length is $(length(str))"
                throw(ArgumentError(msg))
            end
            return $(Symbol(T, :FromHex))(str)
        end

        FromRandom(::Type{$T}) = $(Symbol(T, :FromRandom))()
        $T(str::AbstractString) = FromHex($T, str)
    end

    # cannot believe I'm doing this...
    #
    # Because ObjectID is a CxxWrap-defined type, it has two subtypes:
    # `ObjectIDAllocated` and `ObjectIDDereferenced`.  The first is returned when we
    # construct directly or return by value, the second when you pull a ref out of
    # say `std::vector<ObjectID>`.
    #
    # ObjectID is abstract, so the normal method definition:
    #
    # Base.:(==)(a::ObjectID, b::ObjectID) = Hex(a) == Hex(b)
    #
    # is shadowed by more specific fallbacks defined by CxxWrap.
    sub_types = (Symbol(T, :Allocated), Symbol(T, :Dereferenced))
    for A in sub_types, B in sub_types
        @eval Base.:(==)(a::$A, b::$B) = Hex(a) == Hex(b)
    end
end

FromBinary(::Type{T}, bytes) where {T <: BaseID} = FromBinary(T, String(deepcopy(bytes)))

Binary(::Type{String}, id::BaseID) = safe_convert(String, Binary(id))
Binary(::Type{Vector{UInt8}}, id::BaseID) = Vector{UInt8}(Binary(String, id))

function Base.show(io::IO, x::BaseID)
    T = supertype(typeof(x))
    write(io, "$T(\"", Hex(x), "\")")
    return nothing
end

function Base.hash(x::BaseID, h::UInt)
    T = supertype(typeof(x))
    return hash(T, hash(Hex(x), h))
end

#####
##### JobID
#####

FromInt(::Type{JobID}, num::Integer) = JobIDFromInt(num)
Base.show(io::IO, jobid::JobID) = print(io, ToInt(jobid))

#####
##### ObjectID
#####

FromNil(::Type{ObjectID}) = ObjectIDFromNil()

#####
##### RayObject
#####

# Functions `get_data` and `get_metadata` inspired by `RayObjectsToDataMetadataPairs`:
# https://github.com/ray-project/ray/blob/ray-2.5.1/python/ray/_raylet.pyx#L458-L475

function get_data(ptr::SharedPtr{RayObject})
    ray_obj = ptr[]
    return if HasData(ray_obj)
        take!(GetData(ray_obj))
    else
        nothing
    end
end

function get_metadata(ptr::SharedPtr{RayObject})
    ray_obj = ptr[]
    return if HasMetadata(ray_obj)
        # Unlike `GetData`, `GetMetadata` returns a _reference_ to a pointer to a buffer, so
        # we need to dereference the return value to get the pointer that `take!` expects.
        take!(GetMetadata(ray_obj)[])
    else
        nothing
    end
end

#####
##### TaskArg
#####

function CxxWrap.StdLib.UniquePtr(ptr::Union{Ptr{Nothing},
                                             CxxPtr{<:TaskArgByReference},
                                             CxxPtr{<:TaskArgByValue}})
    return unique_ptr(ptr)
end

#####
##### Upstream fixes
#####

function Base.take!(buffer::CxxWrap.CxxWrapCore.SmartPointer{<:Buffer})
    buffer_ptr = Ptr{UInt8}(Data(buffer[]).cpp_object)
    buffer_size = Size(buffer[])
    vec = Vector{UInt8}(undef, buffer_size)
    unsafe_copyto!(Ptr{UInt8}(pointer(vec)), buffer_ptr, buffer_size)
    return vec
end

# Work around this: https://github.com/JuliaInterop/CxxWrap.jl/issues/300
function Base.push!(v::CxxPtr{StdVector{T}}, el::T) where {T<:SharedPtr{RayObject}}
    return push!(v, CxxRef(el))
end

# Work around CxxWrap's `push!` always dereferencing our value via `@cxxdereference`
# https://github.com/JuliaInterop/CxxWrap.jl/blob/0de5fbc5673367adc7e725cfc6e1fc6a8f9240a0/src/StdLib.jl#L78-L81
function Base.push!(v::StdVector{CxxPtr{TaskArg}}, el::CxxPtr{<:TaskArg})
    _push_back(v, el)
    return v
end

# XXX: Need to convert julia vectors to StdVector and build the
# `std::unordered_map` for resources. This function helps us avoid having
# CxxWrap as a direct dependency in Ray.jl
function _submit_task(fd, args, serialized_runtime_env_info, resources::AbstractDict)
    @debug "task resources: " resources
    resources = build_resource_requests(resources)
    return _submit_task(fd, args, serialized_runtime_env_info, resources)
end

# work around lack of wrapped `std::unordered_map`
function build_resource_requests(resources::Dict{<:AbstractString,<:Number})
    cpp_resources = CxxMapStringDouble()
    for (k, v) in pairs(resources)
        _setindex!(cpp_resources, float(v), k)
    end
    return cpp_resources
end

#####
##### runtime wrappers
#####

function initialize_worker(raylet_socket, store_socket, ray_address, node_ip_address,
                           node_manager_port, startup_token, runtime_env_hash,
                           task_executor::Function)

    # Note (omus): If you are trying to figure out what type to pass in here I recommend
    # starting with `Any`. This will cause failures at runtime that show up in the
    # "raylet.err" logs which tell you the type:
    #```
    # libc++abi: terminating due to uncaught exception of type std::runtime_error:
    # Incorrect argument type for cfunction at position 1, expected: RayFunctionAllocated,
    # obtained: Any
    # ```
    # Using `ConstCxxRef` doesn't seem supported (i.e. `const &`)
    arg_types = (RayFunctionAllocated, Ptr{Cvoid}, Ptr{Cvoid},
                 CxxWrap.StdLib.StdStringAllocated, CxxPtr{CxxWrap.StdString},
                 CxxPtr{CxxBool})
    # need to use `@eval` since `task_executor` is only defined at runtime
    cfunc = @eval @cfunction($(task_executor), Cvoid, ($(arg_types...),))

    @info "cfunction generated!"
    result = initialize_worker(raylet_socket, store_socket, ray_address, node_ip_address,
                               node_manager_port, startup_token, runtime_env_hash, cfunc)

    @info "worker exiting `ray_julia_jll.initialize_worker`"
    return result
end
