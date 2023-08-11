using Test
using Ray
using Aqua

using ray_core_worker_julia_jll

include("utils.jl")

# setup some modules for teh function manager tests...
module M
f(x) = x + 1

module MM
f(x) = x - 1
end # module MM

end # module M

module N
using ..M: f
g(x) = x - 1
end


@testset "Ray.jl" begin
    @testset "Aqua" begin
        Aqua.test_all(Ray; ambiguities=false)
    end

    setup_ray_head_node() do
        @tesset "function manager" begin include("function_manager.jl") end
    end
end
