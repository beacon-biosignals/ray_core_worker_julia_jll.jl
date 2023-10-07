# The exceptions defined here mostly mirror the exceptions supported by Ray for Python:
# https://github.com/ray-project/ray/blob/ray-2.5.1/python/ray/exceptions.py

"""
    RayError <: Exception

Abstract super type of all Ray exception types.
"""
abstract type RayError <: Exception end

"""
    RayTaskError <: RayError

Indicates that a Ray task threw an exception during execution.

If a Ray task throws an exception during execution, a `RayTaskError` is stored for the
Ray task's output. When the object is retrieved, the contained exception is detected and
thrown thereby propogating the exception to the Ray task caller.
"""
struct RayTaskError <: RayError
    task_name::String
    pid::Int
    ip::IPAddr
    task_id::String
    captured::CapturedException
end

function RayTaskError(task_name::AbstractString, captured::CapturedException)
    return RayTaskError(task_name, getpid(), getipaddr(), get_task_id(), captured)
end

function Base.showerror(io::IO, ex::RayTaskError, bt=nothing; backtrace=true)
    print(io, "$RayTaskError: $(ex.task_name) ")
    print(io, "(pid=$(ex.pid), ip=$(ex.ip), task_id=$(ex.task_id))")
    if backtrace
        bt !== nothing && Base.show_backtrace(io, bt)
        println(io)
    end
    printstyled(io, "\nnested exception: "; color=Base.error_color())
    # Call 3-argument `showerror` to allow specifying `backtrace`
    showerror(io, ex.captured.ex, ex.captured.processed_bt; backtrace)
    return nothing
end

"""
    OutOfMemoryError <: RayError

Indicates that the node is running out of memory and is close to full.

This exception is thrown when the node is low on memory and tasks or actors are being
evicted to free up memory.
"""
struct OutOfMemoryError <: RayError
    msg::String
end

function Base.showerror(io::IO, ex::OutOfMemoryError)
    print(io, "$OutOfMemoryError: $(ex.msg)")
    return nothing
end

"""
    RaySystemError <: RayError

Indicates that Ray encountered a system error.

This exception is thrown when:
- The raylet is killed.
- Deserialization of a `ObjectRef` contains an unknown metadata error type.
"""
struct RaySystemError <: RayError
    msg::String
end

function Base.showerror(io::IO, ex::RaySystemError)
    print(io, "$RaySystemError: $(ex.msg)")
    return nothing
end
