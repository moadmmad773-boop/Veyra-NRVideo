// Test-build stand-in for src/ngx/NvOfSession.cpp.
// The NVIDIA Optical Flow SDK (nvOpticalFlowD3D12.h) is only downloadable after an
// NVIDIA Developer Program sign-in, so this CI build cannot fetch it. The session
// reports itself unavailable, exactly as on a GPU without NVOF (AMD/Intel): callers
// already take their fallback paths. Used ONLY by .github/workflows/test-build.yml.
#include "veyra/ngx/NvOfSession.h"
#include "veyra/Log.h"

namespace veyra::ngx {

struct NvOfSession::FnList {};

NvOfSession::~NvOfSession() { shutdown(); }

bool NvOfSession::initialize(ID3D12Device*, ID3D12Resource*, ID3D12Resource*, ID3D12Resource*,
                             ID3D12Resource*, const Desc&, Status& status) {
    static bool logged = false;
    if (!logged) {
        logged = true;
        log::warn("nvof-session", "NVIDIA Optical Flow SDK not included in this CI test build; NVOF unavailable");
    }
    status = Status::LoadLibraryFailure;
    return false;
}

bool NvOfSession::execute(uint64_t, Status& status) {
    status = Status::DeviceFailure;
    return false;
}

bool NvOfSession::unregisterAll(Status& status) {
    status = Status::Ok;
    return true;
}

void NvOfSession::shutdown() {
    delete fn_;
    fn_ = nullptr;
    initialized_ = false;
}

} // namespace veyra::ngx
