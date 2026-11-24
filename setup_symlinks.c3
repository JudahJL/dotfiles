#!/usr/bin/env -S c3c compile-run
module setup_symlinks;
import libc;
import std::encoding::json; // supports jsonc
import std::io::path;
import std::io::file;
import std::time::datetime;


struct Mapping (Printable) {
  String mirror;
  String repo;
  String home;
}

extern fn CInt    symlink(ZString target, ZString linkpath)     @feat(POSIX);
extern fn ZString realpath(ZString path, ZString resolved_path) @feat(POSIX);

fn sz? Mapping.to_format(&self, Formatter* f) @dynamic
{
  if(self.mirror.len) {
    return f.printf("Mapping{.mirror = '%s'}", self.mirror);
  } else {
    return f.printf("Mapping{.repo = '%s', .home = '%s'}", self.repo, self.home);
  }
}

fn bool create_symlink(
  Path src, Path dest,
  bool overwrite = false,
  bool backup = false
) => @pool() {
  bool success   = false;
  bool backed_up = false;

  if (!file::exists(src)) {
    io::fprintfn(io::stderr(), "Source does not exist: %s", src);
    success = false;
    return success;
  }

  ZString tdest = dest.zstr_tcopy();
  ZString tsrc = src.zstr_tcopy();

  // MAYBE: FIX: this is enough for a human level collision. This won't run 1000 / sec
  String backup_path = string::format(mem, "%s.%s.bak", dest, datetime::now().format(tmem, DateTimeFormat.RFC3339ZMS));
  defer backup_path.free(mem);

  ZString tbackup_path = backup_path.zstr_tcopy();

  defer {
    if (backed_up && !success) {
      if(libc::rename(tbackup_path, tdest) == 0) {
	io::printfn("Restored %s → %s", tbackup_path, tdest);
      } else {
	io::fprintfn(io::stderr(), "Failed to restore %s → %s: %s", tbackup_path, tdest, libc::strerror(libc::errno()));
      }
    }
  }

  if (file::exists(dest) || path::is_link(dest)) {
    ZString absolute_src = realpath(tsrc, null);
    defer libc::free(absolute_src);
    if(absolute_src == null) {
      io::fprintfn(io::stderr(), "Failed to resolve source of %s: %s", tsrc, libc::strerror(libc::errno()));
      success = false;
      return success;
    }

    ZString absolute_dest = realpath(tdest, null);
    int resolve_error = absolute_dest == null ? libc::errno() : 0;
    defer libc::free(absolute_dest);
    if (absolute_dest != null) {
      if (absolute_dest == absolute_src) {
	if(path::is_link(dest)) {
          io::printfn("Already linked: %s → %s", dest, src);
          success = true;
	  return success;
	}
	io::fprintfn(io::stderr(), "Source and destination resolve to the same path: %s", dest);
	success = false;
	return success;
      }
    } else if (!path::is_link(dest)) {
      io::fprintfn(io::stderr(), "Failed to resolve destination %s: %d",tdest, resolve_error);
      success = false;
      return success;
    }

    if(!overwrite) {
      io::printfn("Skipping existing file: %s", dest);
      success = true;
      return success;
    }

    if (path::is_dir(dest) && !path::is_link(dest)) {
      io::fprintfn(io::stderr(), "Refusing to overwrite directory: %s", dest);
      success = false;
      return success;
    }

    if (backup) {
      if(libc::rename(tdest, tbackup_path) == 0) {
	io::printfn("Backed up %s → %s", tdest, tbackup_path);
	backed_up = true;
      } else {
	io::fprintfn(io::stderr(), "Failed to backup %s → %s: %s", tdest, tbackup_path, libc::strerror(libc::errno()));
	success = false;
	return success;
      }
    } else {
      if(catch err = path::delete(dest)) {
	io::fprintfn(io::stderr(), "Failed to remove %s: %s", dest, err);
	success = false;
	return success;
      }
      io::printfn("Removed existing: %s", dest);
    }
  }

  // ignore existant dir status
  if(catch err = path::mkdir(dest.parent(), true)) {
    io::fprintfn(io::stderr(), "Failed to mkdir '%s': %s", dest, err);
    success = false;
    return success;
  }

  if(symlink(tsrc, tdest) == 0) {
    io::printfn("%s → %s", tdest, tsrc);
    success = true;
    return success;
  } else {
    io::fprintfn(io::stderr(), "Failed to symlink %s → %s: %s", tdest, tsrc, libc::strerror(libc::errno()));
    success = false;
    return success;
  }
}

const String MAPPINGS_FILE = "mappings.json";

fn Mapping[]? get_mappings(Allocator allocator, Path* dir) {
  Path? mapping_file = dir.append(allocator, MAPPINGS_FILE);
  if(catch err = mapping_file) {
    io::fprintfn(io::stderr(), "Failed to fetch mappings.json: %s", err);
    return err~;
  }
  defer mapping_file.free(allocator);

  File? m = file::open(mapping_file, "r");
  if(catch err = m) {
    io::fprintfn(io::stderr(), "Failed to open mappings.json: %s", err);
    return err~;
  }
  defer m.close();

  DString mapping_str;
  mapping_str.init(allocator);
  defer mapping_str.free();
  char[128] buff;

  for(sz? n = m.read(&buff);; n = m.read(&buff)) {
    if(catch err = n) {
      io::fprintfn(io::stderr(), "Failed to read mappings.json: %s", err);
      return err~;
    }
    mapping_str.append(buff[:n]);
    if(n > 0) continue;
    break;
  }

  return json::unmarshal(allocator, mapping_str.str_view(), Mapping[])!;
}

// ####################################################################################################

// TODO: maybe add synlink resolution here
fn bool is_within(Path* root, Path* candidate) @inline {
    if (candidate.len <= root.len) return false;
    if (!candidate.starts_with(*root)) return false;

  return root.ends_with("/") || (*candidate)[root.len] == '/';
}

fn int main() {
  Path? home = path::home_directory(mem);
  if(catch err = home) {
    io::fprintfn(io::stderr(), "Failed to fetch home directory: %s", err);
    return 1;
  }
  defer home.free(mem);

  Path? repo = path::cwd(mem);
  if(catch err = repo) {
    io::fprintfn(io::stderr(), "Failed to fetch curr directory: %s", err);
    return 1;
  }
  defer repo.free(mem);

  Mapping[]? mappings = get_mappings(mem, &repo);
  if(catch err = mappings) {
    io::fprintfn(io::stderr(), "Failed to unmarshal mappings.json: %s", err);
    return 1;
  }
  defer {
    defer mem::free(mappings);
    foreach(&mapping: mappings) {
      mapping.home.free(mem);
      mapping.repo.free(mem);
      mapping.mirror.free(mem);
    }
  }

  bool ok = true;
  foreach(&mapping: mappings) {
    Path src;
    Path dest;

    defer {
      if(src.len) {
	src.free(mem);
      }
      if(dest.len){
	dest.free(mem);
      }
    }
    if(mapping.mirror.len) {
      Path? a_src = repo.append(mem, mapping.mirror);
      if(catch err = a_src) {
	io::fprintfn(io::stderr(), "Failed to build a_src from mirror '%s': %s", mapping.mirror, err);
	return 1;
      }
      src  = a_src;

      Path? a_dest = home.append(mem, mapping.mirror);
      if(catch err = a_dest) {
	io::fprintfn(io::stderr(), "Failed to build a_dest from mirror '%s': %s", mapping.mirror, err);
	return 1;
      }
      dest = a_dest;
    } else {
      Path? a_src = repo.append(mem, mapping.repo);
      if(catch err = a_src) {
	io::fprintfn(io::stderr(), "Failed to build a_src '%s': %s", mapping.repo, err);
	return 1;
      }
      src  = a_src;

      Path? a_dest = home.append(mem, mapping.home);
      if(catch err = a_dest) {
	io::fprintfn(io::stderr(), "Failed to build a_dest '%s': %s", mapping.home, err);
	return 1;
      }
      dest = a_dest;
    }

    if(!is_within(&repo, &src)) {
      io::fprintfn(io::stderr(), "'%s' has escaped '%s' using '..', unsafe to continue", src, repo);
      ok = false;
      continue;
    }

    if(!is_within(&home, &dest)) {
      io::fprintfn(io::stderr(), "'%s' has escaped '%s' using '..', unsafe to continue", dest, home);
      ok = false;
      continue;
    }

    if(!create_symlink(src, dest, true, true)) {
      ok = false;
      continue;
    }
  }
  if (!ok) return 1;
  return 0;
}
