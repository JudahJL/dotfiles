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

extern fn CInt symlink(ZString target, ZString linkpath);
extern fn ZString realpath(ZString path, ZString resolved_path);

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
  if (!file::exists(src)) {
    io::fprintfn(io::stderr(), "Source does not exist: %s", src);
    return false;
  }
  
  ZString tdest = dest.zstr_tcopy();
  ZString tsrc = src.zstr_tcopy();
  
  if (file::exists(dest) || path::is_link(dest)) {
    ZString absolute_dest = realpath(tdest, null);
    defer libc::free(absolute_dest);
    
    // if(absolute_dest == null) {
    //   io::fprintfn(io::stderr(), "Failed to get realpath of %s: %s", tdest, libc::strerror(libc::errno()));
    //   return;
    // }
    
    // if(path::is_link(dest) && (absolute_dest == tsrc)) {
    //   io::printfn("Already linked: %s → %s", dest, src);
    //   return;
    // }
    if (absolute_dest != null) {
      if (path::is_link(dest) && (absolute_dest == tsrc)) {
        io::printfn("Already linked: %s → %s", dest, src);
        return true;
      }
    } else if (!path::is_link(dest)) {
      io::fprintfn(io::stderr(), "Failed to get realpath of %s: %s", tdest, libc::strerror(libc::errno()));
      return false;
    }
    
    if(!overwrite) {
      io::printfn("Skipping existing file: %s", dest);
      return true;
    }

    if (backup) {
      String backup_path = string::format(mem, "%s.%s.bak", dest, datetime::now().format(tmem, DateTimeFormat.RFC3339ZMS));
      defer backup_path.free(mem);
      
      @pool() {
	ZString tbackup_path = backup_path.zstr_tcopy();
	if(libc::rename(tdest, tbackup_path) == 0) {
	  io::printfn("Backed up %s → %s", tdest, tbackup_path);
	} else {
	  io::fprintfn(io::stderr(), "Failed to backup %s → %s", tdest, tbackup_path);
	  return false;
	}
      };
    } else {
      if (path::is_dir(dest) && !path::is_link(dest)) {
	io::fprintfn(io::stderr(), "Refusing to overwrite directory: %s", dest);
	return true;
      }
      
      if(catch err = path::delete(dest)) {
	io::fprintfn(io::stderr(), "Failed to remove %s: %s", dest, err);
	return false;
      }
      io::printfn("Removed existing: %s", dest);
    }  
  }
  // ignore existant dir status
  if(catch err = path::mkdir(dest.parent(), true)) {
    io::fprintfn(io::stderr(), "Failed to mkdir: %s", dest);
    return false;
  }
  
  if(symlink(tsrc, tdest) == 0) {
    io::printfn("%s -> %s", tdest, tsrc);
  } else {
    io::fprintfn(io::stderr(), "Failed to symlink %s -> %s: %s", tdest, tsrc, libc::strerror(libc::errno()));
    return false;
  }
  return true;
  // io::printfn("src = %s, dest = %s, overwrite = '%s', backup = '%s'", src, dest, overwrite, backup);
}

// ####################################################################################################

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
  
  Path? mapping_file = repo.append(mem, "mappings.json");
  if(catch err = mapping_file) {
    io::fprintfn(io::stderr(), "Failed to fetch mappings.json: %s", err);
    return 1;
  }
  defer mapping_file.free(mem);
  
  File? m = file::open((String)mapping_file, "r");
  if(catch err = m) {
    io::fprintfn(io::stderr(), "Failed to open mappings.json: %s", err);
    return 1;
  }
  defer m.close();

  DString mapping_str;
  char[128] buff;
  
  for(sz? n = m.read(&buff);; n = m.read(&buff)) {
    if(catch err = n) {
      io::fprintfn(io::stderr(), "Failed to read mappings.json: %s", err);
      return 1;
    }
    mapping_str.append(buff[:n]);
    if(n > 0) continue;
    break;
  }

  Mapping[]? mappings = json::unmarshal(tmem, mapping_str.str_view(), Mapping[]);
  
  if(catch err = mappings) {
    io::fprintfn(io::stderr(), "Failed to unmarshal mappings.json: %s", err);
    return 1;
  }
  bool ok = true;
  foreach(&mapping: mappings) {
    if(mapping.mirror.len) {
      Path? src = repo.append(mem, mapping.mirror);
      if(catch err = src) {
	io::fprintfn(io::stderr(), "Failed to build src '%s': %s", mapping.mirror, err);
	return 1;
      }
      defer src.free(mem);

      Path? dest = home.append(mem, mapping.mirror);
      if(catch err = dest) {
	io::fprintfn(io::stderr(), "Failed to build dest '%s': %s", mapping.mirror, err);
	return 1;
      }
      defer dest.free(mem);
      
      if(!create_symlink(src, dest, true, true)) {
	ok = false;
      }
    } else {
      Path? src = repo.append(mem, mapping.repo);
      if(catch err = src) {
	io::fprintfn(io::stderr(), "Failed to build src '%s': %s", mapping.mirror, err);
	return 1;
      }
      defer src.free(mem);

      Path? dest = home.append(mem, mapping.home);
      if(catch err = dest) {
	io::fprintfn(io::stderr(), "Failed to build dest '%s': %s", mapping.mirror, err);
	return 1;
      }
      defer dest.free(mem);
      
      if(!create_symlink(src, dest, true, true)) {
	ok = false;
      }
    }
  }
  if (!ok) return 1;
  return 0;
}
