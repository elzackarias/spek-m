#include "spek-path.h"

#ifdef __APPLE__
#include <CoreFoundation/CoreFoundation.h>
#include <dirent.h>
#include <sys/stat.h>

// Unicode NFC form of a UTF-8 string, or the string itself if it isn't UTF-8.
static std::string to_nfc(const std::string& s)
{
    CFStringRef str = CFStringCreateWithBytes(
        nullptr, reinterpret_cast<const UInt8 *>(s.data()), s.size(), kCFStringEncodingUTF8, false
    );
    if (!str) {
        return s;
    }
    CFMutableStringRef normalized = CFStringCreateMutableCopy(nullptr, 0, str);
    CFRelease(str);
    CFStringNormalize(normalized, kCFStringNormalizationFormC);

    CFRange range = CFRangeMake(0, CFStringGetLength(normalized));
    CFIndex size = 0;
    CFStringGetBytes(normalized, range, kCFStringEncodingUTF8, 0, false, nullptr, 0, &size);
    std::string result(size, '\0');
    CFStringGetBytes(
        normalized, range, kCFStringEncodingUTF8, 0, false,
        reinterpret_cast<UInt8 *>(&result[0]), size, nullptr
    );
    CFRelease(normalized);
    return result;
}

static SpekFileSystem real_fs()
{
    SpekFileSystem fs;
    fs.exists = [] (const std::string& path) {
        struct stat st;
        return stat(path.c_str(), &st) == 0;
    };
    fs.list = [] (const std::string& dir) {
        std::vector<std::string> entries;
        if (DIR *d = opendir(dir.c_str())) {
            while (struct dirent *entry = readdir(d)) {
                entries.push_back(entry->d_name);
            }
            closedir(d);
        }
        return entries;
    };
    return fs;
}
#endif

std::string spek_resolve_path(const std::string& path)
{
#ifdef __APPLE__
    return spek_resolve_path(path, real_fs());
#else
    return path;
#endif
}

std::string spek_resolve_path(const std::string& path, const SpekFileSystem& fs)
{
#ifdef __APPLE__
    if (path.empty() || path[0] != '/' || fs.exists(path)) {
        return path;
    }

    std::string resolved;
    size_t start = 1;
    while (start <= path.size()) {
        size_t end = path.find('/', start);
        if (end == std::string::npos) {
            end = path.size();
        }
        std::string component = path.substr(start, end - start);
        start = end + 1;
        if (component.empty()) {
            continue;
        }

        std::string candidate = resolved + "/" + component;
        if (!fs.exists(candidate)) {
            std::string wanted = to_nfc(component);
            bool found = false;
            for (const auto& entry : fs.list(resolved.empty() ? "/" : resolved)) {
                if (to_nfc(entry) == wanted) {
                    candidate = resolved + "/" + entry;
                    found = true;
                    break;
                }
            }
            if (!found) {
                return path;
            }
        }
        resolved = candidate;
    }
    return resolved.empty() ? path : resolved;
#else
    (void) fs;
    return path;
#endif
}
