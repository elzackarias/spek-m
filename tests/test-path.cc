#include <set>

#include "spek-path.h"

#include "test.h"

#ifdef __APPLE__

// "León" with a precomposed "ó" (NFC), as wxWidgets hands paths to Spek on macOS.
static const std::string LEON_NFC = "Le\xc3\xb3n";
// "León" with "o" + combining acute accent (NFD), as stored on some SMB shares.
static const std::string LEON_NFD = "Leo\xcc\x81n";

// A file system that, like SMB, only finds names by their exact bytes.
static SpekFileSystem fake_fs(const std::set<std::string>& paths)
{
    SpekFileSystem fs;
    fs.exists = [paths] (const std::string& path) {
        return path == "/" || paths.count(path) > 0;
    };
    fs.list = [paths] (const std::string& dir) {
        std::string prefix = dir == "/" ? "/" : dir + "/";
        std::vector<std::string> entries;
        for (const auto& path : paths) {
            if (path.compare(0, prefix.size(), prefix) == 0 &&
                path.find('/', prefix.size()) == std::string::npos) {
                entries.push_back(path.substr(prefix.size()));
            }
        }
        return entries;
    };
    return fs;
}

static void test_resolve_nfd_on_disk()
{
    auto fs = fake_fs({
        "/Volumes",
        "/Volumes/Jose",
        "/Volumes/Jose/" + LEON_NFD,
        "/Volumes/Jose/" + LEON_NFD + "/01 - " + LEON_NFD + ".flac",
    });
    test(
        "NFC path finds NFD names",
        "/Volumes/Jose/" + LEON_NFD + "/01 - " + LEON_NFD + ".flac",
        spek_resolve_path("/Volumes/Jose/" + LEON_NFC + "/01 - " + LEON_NFC + ".flac", fs)
    );
}

static void test_resolve_mixed_forms()
{
    auto fs = fake_fs({
        "/m",
        "/m/" + LEON_NFD,
        "/m/" + LEON_NFD + "/" + LEON_NFC + ".flac",
    });
    test(
        "each component keeps its own on-disk form",
        "/m/" + LEON_NFD + "/" + LEON_NFC + ".flac",
        spek_resolve_path("/m/" + LEON_NFC + "/" + LEON_NFC + ".flac", fs)
    );
}

static void test_resolve_unchanged()
{
    auto fs = fake_fs({"/m", "/m/Laura.flac", "/m/" + LEON_NFC + ".flac"});
    test("existing ASCII path", std::string("/m/Laura.flac"), spek_resolve_path("/m/Laura.flac", fs));
    test(
        "existing NFC path",
        "/m/" + LEON_NFC + ".flac",
        spek_resolve_path("/m/" + LEON_NFC + ".flac", fs)
    );
    test(
        "missing file is returned as is",
        "/m/" + LEON_NFC + "/x.flac",
        spek_resolve_path("/m/" + LEON_NFC + "/x.flac", fs)
    );
    test("relative path is returned as is", LEON_NFC, spek_resolve_path(LEON_NFC, fs));
}

static void test_resolve_real_fs()
{
    test(
        "real file system, existing path",
        std::string(SAMPLES_DIR "/2ch-44100Hz-16bps.wav"),
        spek_resolve_path(SAMPLES_DIR "/2ch-44100Hz-16bps.wav")
    );
}

void test_path()
{
    run("path: NFD names on disk", test_resolve_nfd_on_disk);
    run("path: mixed forms", test_resolve_mixed_forms);
    run("path: unchanged", test_resolve_unchanged);
    run("path: real file system", test_resolve_real_fs);
}

#else

void test_path()
{
}

#endif
