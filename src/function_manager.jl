_mib_string(num_bytes) = string(div(num_bytes, 1024 * 1024), " MiB")


function check_oversized_function(serialized, function_descriptor)
    len = length(serialized)
    if len > FUNCTION_SIZE_ERROR_THRESHOLD
        msg = "The function $(ray_jll.CallString(function_descriptor)) is too " *
              "large ($(_mib_string(len))); FUNCTION_SIZE_ERROR_THRESHOLD=" *
              "$(_mib_string(FUNCTION_SIZE_ERROR_THRESHOLD)). " * _check_msg
        throw(ArgumentError(msg))
    elseif len > FUNCTION_SIZE_WARN_THRESHOLD
        msg = "The function $(ray_jll.CallString(function_descriptor)) is very " *
              "large ($(_mib_string(len))). " * _check_msg
        @warn msg
        # TODO: push warning message to driver if this is a worker
        # https://github.com/beacon-biosignals/Ray.jl/issues/59
    end
    return nothing
end

Base.@kwdef struct FunctionManager
    gcs_client::ray_jll.JuliaGcsClient
    functions::Dict{String,Any}
end

const FUNCTION_MANAGER = Ref{FunctionManager}()

function _init_global_function_manager(gcs_address)
    @info "Connecting function manager to GCS at $gcs_address..."
    gcs_client = ray_jll.JuliaGcsClient(gcs_address)
    ray_jll.Connect(gcs_client)
    FUNCTION_MANAGER[] = FunctionManager(; gcs_client, functions=Dict{String,Any}())

    return nothing
end

function function_key(fd::ray_jll.JuliaFunctionDescriptor, job_id=get_job_id())
    return string("RemoteFunction:", job_id, ":", fd.function_hash)
end

function export_function!(fm::FunctionManager, f, job_id=get_job_id())
    fd = ray_jll.function_descriptor(f)
    function_locations = functionloc.(methods(f))
    key = function_key(fd, job_id)
    @debug "Exporting function to function store:" fd key function_locations
    # DFK: I _think_ the string memory may be mangled if we don't `deepcopy`. Not sure but
    # it can't hurt
    if ray_jll.Exists(fm.gcs_client, FUNCTION_MANAGER_NAMESPACE, deepcopy(key), -1)
        @debug "Function already present in GCS store:" fd key
    else
        @debug "Exporting function to GCS store:" fd key
        val = base64encode(serialize, f)
        check_oversized_function(val, fd)
        ray_jll.Put(fm.gcs_client, FUNCTION_MANAGER_NAMESPACE, key, val, true, -1)
    end
end

function timedwait_for_function(fm::FunctionManager, fd::ray_jll.JuliaFunctionDescriptor,
                                job_id=get_job_id(); timeout_s=10)
    key = function_key(fd, job_id)
    status = try
        exists = ray_jll.Exists(fm.gcs_client, FUNCTION_MANAGER_NAMESPACE, key, timeout_s)
        exists ? :ok : :timed_out
    catch e
        if e isa ErrorException && contains(e.msg, "Deadline Exceeded")
            return :timed_out
        else
            rethrow()
        end
    end
    return status
end

# XXX: this will error if the function is not found in the store.
# TODO: consider _trying_ to resolve the function descriptor locally (i.e.,
# somthing like `eval(Meta.parse(CallString(fd)))`), falling back to the function
# store only if needed.
# https://github.com/beacon-biosignals/Ray.jl/issues/60
function import_function!(fm::FunctionManager, fd::ray_jll.JuliaFunctionDescriptor,
                          job_id=get_job_id())
    return get!(fm.functions, fd.function_hash) do
        key = function_key(fd, job_id)
        @debug "Function not found locally, retrieving from function store" fd key
        val = ray_jll.Get(fm.gcs_client, FUNCTION_MANAGER_NAMESPACE, key, -1)
        try
            io = IOBuffer()
            iob64 = Base64DecodePipe(io)
            write(io, val)
            seekstart(io)
            f = deserialize(iob64)
            # need to handle world-age issues on remote workers when
            # deserializing the function effectively defines it
            return (args...; kwargs...) -> Base.invokelatest(f, args...; kwargs...)
        catch e
            error("Failed to deserialize function from store: $(fd)")
        end
    end
end
