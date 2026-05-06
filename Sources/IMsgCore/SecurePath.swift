import Darwin
import Foundation

/// Lexical-walk symlink detector. Used wherever we accept a filesystem path
/// from outside the dylib (RPC inbox dir, attachment paths) and want to refuse
/// any path that traverses a symbolic link, including parent components.
///
/// `realpath()` alone isn't sufficient: a same-UID attacker who can write to
/// our RPC inbox could otherwise symlink an arbitrary file (a credential file,
/// a password manager DB) into a location they control and have Messages.app
/// exfiltrate it as an attachment. Comparing the resolved path against the
/// lexical input is fragile too — macOS rewrites `/tmp` to `/private/tmp`,
/// breaking that check for legitimate paths. Walking each component with
/// `lstat()` and refusing the path on any `S_IFLNK` is the robust answer.
public enum SecurePath {
  /// Returns true if any component of `path` (after tilde expansion and CWD
  /// resolution for relative paths) is a symbolic link. Final component
  /// included.
  public static func hasSymlinkComponent(_ path: String) -> Bool {
    var lexicalPath = (path as NSString).expandingTildeInPath
    if !lexicalPath.hasPrefix("/") {
      lexicalPath =
        (FileManager.default.currentDirectoryPath as NSString)
        .appendingPathComponent(lexicalPath)
    }

    let components = (lexicalPath as NSString).pathComponents
    guard !components.isEmpty else { return false }

    var cursor = components.first == "/" ? "/" : ""
    for component in components where component != "/" && !component.isEmpty {
      cursor = (cursor as NSString).appendingPathComponent(component)

      var info = stat()
      if lstat(cursor, &info) != 0 {
        continue
      }
      if (info.st_mode & S_IFMT) == S_IFLNK {
        return true
      }
    }
    return false
  }
}
