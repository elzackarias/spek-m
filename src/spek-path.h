#pragma once

#include <functional>
#include <string>
#include <vector>

struct SpekFileSystem
{
    std::function<bool (const std::string& path)> exists;
    std::function<std::vector<std::string> (const std::string& dir)> list;
};

// Returns the path as it is actually spelled on disk.
//
// wxWidgets on macOS converts file names to Unicode NFC, but SMB shares and
// some other file systems only find a name by its exact bytes, e.g. "León"
// stored with a combining accent (NFD). If `path` doesn't exist, each
// component is matched against its directory's entries ignoring Unicode
// normalization. Returns `path` unchanged if it exists or nothing matches.
// Only macOS does the matching; elsewhere `path` is returned unchanged.
std::string spek_resolve_path(const std::string& path);
std::string spek_resolve_path(const std::string& path, const SpekFileSystem& fs);
