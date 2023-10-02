var documenterSearchIndex = {"docs":
[{"location":"developer-guide/#Developer-Guide","page":"Developer Guide","title":"Developer Guide","text":"","category":"section"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"For those wanting to contribute to Ray.jl this guide will assist you in creating a development environment allowing you update the Julia code and Ray C++ wrapper.","category":"page"},{"location":"developer-guide/#Setting-up-your-development-environment","page":"Developer Guide","title":"Setting up your development environment","text":"","category":"section"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"Building the Ray.jl project requires the following tools to be installed. This list is provided for informational purposes and typically users should follow the platform specific install sections.","category":"page"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"Julia version ≥ v1.8\nPython version ≥ v3.7\nPython venv\nBazelisk\nGCC / G++ ≥ v9","category":"page"},{"location":"developer-guide/#Install-Dependencies-on-macOS","page":"Developer Guide","title":"Install Dependencies on macOS","text":"","category":"section"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"Install Homebrew\nInstall Julia\nInstall Python (we recommend via pyenv)\nNavigate to the root of the Ray.jl repo\nInstall Ray dependencies:\nbrew update\nbrew install bazelisk wget","category":"page"},{"location":"developer-guide/#Install-dependencies-on-Linux","page":"Developer Guide","title":"Install dependencies on Linux","text":"","category":"section"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"Install Julia\nInstall Python\nNavigate to the root of the Ray.jl repo\nInstall Ray dependencies:\n# Add a PPA containing gcc-9 for older versions of Ubuntu.\nsudo add-apt-repository -y ppa:ubuntu-toolchain-r/test\nsudo apt-get update\nsudo apt-get install -y build-essential curl git gcc-9 g++-9 pkg-config psmisc unzip\nsudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 90 \\\n  --slave /usr/bin/g++ g++ /usr/bin/g++-9 \\\n  --slave /usr/bin/gcov gcov /usr/bin/gcov-9\n\n# Install Bazelisk\ncase $(uname -m) in\n  x86_64) ARCH=amd64;;\n  aarch64) ARCH=arm64;;\nesac\n\ncurl -fsSLo bazel https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-${ARCH}\nsudo install bazel /usr/local/bin","category":"page"},{"location":"developer-guide/#Prepare-Python-virtual-environment","page":"Developer Guide","title":"Prepare Python virtual environment","text":"","category":"section"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"We recommend always using the same virtual environment as otherwise Bazel will perform unnecessary rebuilds when using switching between different versions of Python.","category":"page"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"python -m venv venv\nsource venv/bin/activate\n# make sure we're using up-to-date version of pip and wheel:\npython -m pip install --upgrade pip wheel","category":"page"},{"location":"developer-guide/#Build-Ray.jl","page":"Developer Guide","title":"Build Ray.jl","text":"","category":"section"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"The initial Ray.jl build can be done as follows:","category":"page"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"source venv/bin/activate\njulia --project=build -e 'using Pkg; Pkg.instantiate()'\n\n# Build \"ray_julia\" library. Will adds an entry in \"~/.julia/artifacts/Overrides.toml\" unless `--no-override` is specified\njulia --project=build build/build_library.jl","category":"page"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"Subsequent builds can done via:","category":"page"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"source venv/bin/activate\njulia --project=build build/build_library.jl && julia --project -e 'using Ray' && julia --project","category":"page"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"If you decide to switch back to using the the pre-built binaries you will have to revert the modification to your ~/.julia/artifacts/Overrides.toml.","category":"page"},{"location":"developer-guide/#Build-Ray-CLI/Backend","page":"Developer Guide","title":"Build Ray CLI/Backend","text":"","category":"section"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"We currently rely on a patched version of upstream Ray CLI that is aware of Julia as a supported language and knows how to launch Julia worker processes. Until these changes are upstreamed to the Ray project we'll need to keep using a patched version of the Ray CLI:","category":"page"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"source venv/bin/activate\ncd build/ray/python\npip install --verbose .\ncd -","category":"page"},{"location":"developer-guide/#Test-the-build","page":"Developer Guide","title":"Test the build","text":"","category":"section"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"Once you have built Ray.jl and the Ray CLI you can validate your build by running the test suite:","category":"page"},{"location":"developer-guide/","page":"Developer Guide","title":"Developer Guide","text":"source venv/bin/activate\njulia --project -e 'using Pkg; Pkg.test()'","category":"page"},{"location":"installation/#Installation","page":"Installation","title":"Installation","text":"","category":"section"},{"location":"installation/","page":"Installation","title":"Installation","text":"Ultimately we aim to make installing Ray.jl as simple as running Pkg.add(\"Ray\"). However, at the moment there are some manual steps are required to install Ray.jl. For users with machines using the Linux x86_64 or macOS aarch64 (Apple Silicon) platforms we have provided pre-built binaries for each Ray.jl release.","category":"page"},{"location":"installation/","page":"Installation","title":"Installation","text":"To install these dependencies and Ray.jl run the following:","category":"page"},{"location":"installation/","page":"Installation","title":"Installation","text":"# Install the Ray CLI\nPYTHON=$(python3 --version | perl -ne '/(\\d+)\\.(\\d+)/; print \"cp$1$2-cp$1$2\"')\ncase $(uname -s) in\n    Linux) OS=manylinux2014;;\n    Darwin) OS=macosx_13_0;;\nesac\nARCH=$(uname -m)\nRELEASE=\"ray-2.5.1+1\"\npip install -U \"ray[default] @ https://github.com/beacon-biosignals/ray/releases/download/$RELEASE/${RELEASE%+*}-${PYTHON}-${OS}_${ARCH}.whl\" \"pydantic<2\"\n\n# Install the Julia packages \"ray_julia_jll\" and \"Ray\"\nTAG=\"v0.1.0\" julia -e 'using Pkg; Pkg.add(PackageSpec(url=\"https://github.com/beacon-biosignals/Ray.jl\", rev=ENV[\"TAG\"]))'","category":"page"},{"location":"installation/","page":"Installation","title":"Installation","text":"Users attempting to use Ray.jl on other platforms can attempt to build the package from source.","category":"page"},{"location":"building-artifacts/#Building-Artifacts","page":"Building Artifacts","title":"Building Artifacts","text":"","category":"section"},{"location":"building-artifacts/","page":"Building Artifacts","title":"Building Artifacts","text":"For Ray.jl releases we provide pre-built binary artifacts to allow for easy installation of the Ray.jl package. Currently, we need to build a custom Ray CLI which includes Julia language support and platform specific shared libraries for ray_julia_jll.","category":"page"},{"location":"building-artifacts/#Ray-CLI/Server","page":"Building Artifacts","title":"Ray CLI/Server","text":"","category":"section"},{"location":"building-artifacts/","page":"Building Artifacts","title":"Building Artifacts","text":"Follow the instructions outlined in the Beacon fork of Ray.","category":"page"},{"location":"building-artifacts/#Artifacts","page":"Building Artifacts","title":"Artifacts","text":"","category":"section"},{"location":"building-artifacts/","page":"Building Artifacts","title":"Building Artifacts","text":"The ray_julia artifacts are hosted via GitHub releases and will be downloaded automatically for any supported platform (currently x86_64-linux-gnu and aarch64-apple-darwin).","category":"page"},{"location":"building-artifacts/","page":"Building Artifacts","title":"Building Artifacts","text":"At the moment updating these artifacts is semi-automated in that the GitHub actions builds the x86_64-linux-gnu artifacts but builds for aarch64-apple-darwin must be performed manually on a compatible host system.","category":"page"},{"location":"building-artifacts/","page":"Building Artifacts","title":"Building Artifacts","text":"To update the artifacts, ensure you are running on macOS using Apple Silicon (aarch64-apple-darwin) and have first have already built Ray.jl successfully. Then perform the following steps:","category":"page"},{"location":"building-artifacts/","page":"Building Artifacts","title":"Building Artifacts","text":"Create a new branch (based off of origin/HEAD) and update the Ray.jl version in the Project.toml file. Commit and push this change to a new PR.\nNavigate to the build directory\nRun the build_tarballs.jl script builds the tarball for the host platform and Julia version used. Using the --all flag builds the host platform tarballs for all supported Julia versions. When running this on aarch64-apple-darwin we'll build those artifacts locally and then use --fetch to retrieve GitHub Action built artifacts for x86_64-linux-gnu. It is advised you run this within the Python virtual environment associated with the Ray.jl package to avoid unnecessary Bazel rebuilds. Re-running this script will overwrite an existing tarball for this version of Ray.jl.\njulia --project -e 'using Pkg; Pkg.instantiate()'\n\n# Cleanup any tarballs from previous builds\nrm -rf tarballs\n\n# Build the host tarballs. When run on Apple Silicon this builds the aarch64-apple-darwin tarballs\nsource ../venv/bin/activate\njulia --project build_tarballs.jl --all\n\n# Fetches the x86_64-linux-gnu tarballs from GitHub Actions (may need to wait)\nread -s GITHUB_TOKEN\nexport GITHUB_TOKEN\njulia --project build_tarballs.jl --fetch\nRun the upload_tarballs.jl script to publish the tarballs as assets of a GitHub pre-release, which requires a GITHUB_TOKEN environment variable. Re-running this script will only upload new tarballs and skip any that have already been published.\nread -s GITHUB_TOKEN\nexport GITHUB_TOKEN\njulia --project upload_tarballs.jl\nRun bind_artifacts.jl to modify local Artifacts.toml with the artifacts associated with the Ray.jl version specified in the Project.toml. After running this you should commit and push the changes to the PR you created in Step 1.\njulia --project bind_artifacts.jl\n\ngit commit -a -m \"Update Artifacts.toml\"\ngit push origin\nMerge the PR. If the PR becomes out of date with the default branch then you will need to repeat steps 3-6 to ensure that the tarballs include the current changes. In some scenarios re-building the tarballs may be unnecessary such as a documentation only change. If in doubt re-build the tarballs.\nAfter the PR is merged, delete the existing tag (which will convert the release to a draft) and create a new one (with the same version) from the commit you just merged. Then update the GitHub release to point to the new tag.\ngit tag -d $tag\ngit push origin :$tag\ngit tag $tag\n\n# Update GitHub Release to point to the updated tag\nRegister the new tag as normal with JuliaRegistrator.","category":"page"},{"location":"#Ray.jl","page":"API Documentation","title":"Ray.jl","text":"","category":"section"},{"location":"","page":"API Documentation","title":"API Documentation","text":"Modules = [Ray]\nPrivate = false","category":"page"},{"location":"#Ray.Ray","page":"API Documentation","title":"Ray.Ray","text":"Ray\n\nThis package provides user-facing interface for Julia-on-Ray.\n\n\n\n\n\n","category":"module"},{"location":"#Non-exported-functions-and-types","page":"API Documentation","title":"Non-exported functions and types","text":"","category":"section"},{"location":"","page":"API Documentation","title":"API Documentation","text":"Modules = [Ray]\nPublic = false","category":"page"},{"location":"#Ray.GLOBAL_STATE_ACCESSOR","page":"API Documentation","title":"Ray.GLOBAL_STATE_ACCESSOR","text":"const GLOBAL_STATE_ACCESSOR::Ref{ray_jll.GlobalStateAccessor}\n\nGlobal binding for GCS client interface to access global state information. Currently only used to get the next job ID.\n\nThis is set during init and used there to get the Job ID for the driver.\n\n\n\n\n\n","category":"constant"},{"location":"#Base.isready-Tuple{ObjectRef}","page":"API Documentation","title":"Base.isready","text":"Base.isready(obj_ref::ObjectRef)\n\nCheck whether obj_ref has a value that's ready to be retrieved.\n\n\n\n\n\n","category":"method"},{"location":"#Base.wait-Tuple{ObjectRef}","page":"API Documentation","title":"Base.wait","text":"Base.wait(obj_ref::ObjectRef) -> Nothing\n\nBlock until isready(obj_ref).\n\n\n\n\n\n","category":"method"},{"location":"#Ray.get-Tuple{ObjectRef}","page":"API Documentation","title":"Ray.get","text":"Ray.get(obj_ref::ObjectRef)\n\nRetrieves the data associated with the object reference from the object store. This method is blocking until the data is available in the local object store.\n\nIf the task that generated the ObjectRef failed with a Julia exception, the captured exception will be thrown on get.\n\n\n\n\n\n","category":"method"},{"location":"#Ray.get_all_reference_counts-Tuple{}","page":"API Documentation","title":"Ray.get_all_reference_counts","text":"get_all_reference_counts()\n\nFor testing/debugging purposes, returns a Dict{ray_jll.ObjectID,Tuple{Int,Int}} containing the reference counts for each object ID that the local raylet knows about.  The first count is the \"local reference\" count, and the second is the count of submitted tasks depending on the object.\n\n\n\n\n\n","category":"method"},{"location":"#Ray.get_job_id-Tuple{}","page":"API Documentation","title":"Ray.get_job_id","text":"get_job_id() -> UInt32\n\nGet the current job ID for this worker or driver. Job ID is the id of your Ray drivers that create tasks.\n\n\n\n\n\n","category":"method"},{"location":"#Ray.get_task_id-Tuple{}","page":"API Documentation","title":"Ray.get_task_id","text":"get_task_id() -> String\n\nGet the current task ID for this worker in hex format.\n\n\n\n\n\n","category":"method"},{"location":"#Ray.put-Tuple{Any}","page":"API Documentation","title":"Ray.put","text":"Ray.put(data) -> ObjectRef\n\nStore data in the object store. Returns an object reference which can used to retrieve the data with Ray.get.\n\n\n\n\n\n","category":"method"}]
}
