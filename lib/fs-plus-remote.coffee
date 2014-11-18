fs_plus = require 'fs-plus'
deasync = require 'deasync'
ssh = require 'ssh2'

local_fs = fs_plus

conn = null
sftp_conn = null

map_remote_files = {}

module.exports =
  local: local_fs

  isReadmePath: (path) ->
    fs_plus.isReadmePath path

  isCompressedExtension: (extension) ->
    fs_plus.isCompressedExtension extension

  isImageExtension: (extension) ->
    fs_plus.isImageExtension extension

  isPdfExtension: (extension) ->
    fs_plus.isPdfExtension extension

  isBinaryExtension: (extension) ->
    fs_plus.isBinaryExtension extension

  isCaseInsensitive: ->
    true

  connectToRemoteSync: (opt) ->
    @disconnectRemote
    conn = new ssh
    sftp_conn = null
    conn.on 'ready', () ->
      conn.sftp (err, sftp) ->
        throw err if err
        sftp_conn = sftp
    conn.connect opt
    until sftp_conn
      deasync.sleep 100
    true

  connectToRemote: (opt, callback) ->
    @disconnectRemote
    conn = new ssh
    sftp_conn = null
    conn.on 'ready', () ->
      conn.sftp (err, sftp) ->
        sftp_conn = sftp
        callback err
    conn.connect opt

  disconnectRemote: () ->
    sftp_conn.end() if sftp_conn
    sftp_conn = null
    conn.end() if conn
    conn = null

  realpath: (path, [cache], callback) ->
    local_fs.realpath path, cache, callback if not sftp_conn
    sftp_conn.realpath path, (err, resolvedPath) ->
      callback err, resolvedPath

  readdirSync: (path) ->
    local_fs.readdirSync path if not sftp_conn
    filelist = null
    sftp_conn.readdir path, (err, _filelist) ->
      throw err if err
      filelist = _filelist
    until filelist
      deasync.sleep 100
    files = []
    for file in filelist
      files.push file.filename
    files

  lstatSyncNoException: (path) ->
    local_fs.lstatSyncNoException path if not sftp_conn
    stats = null
    sftp_conn.lstat path, (err, _stats) ->
      null if err
      stats = _stats
    until stats
      deasync.sleep 100
    stats

  statSyncNoException: (path) ->
    local_fs.statSyncNoException path if not sftp_conn
    stats = null
    sftp_conn.stat path, (err, _stats) ->
      null if err
      stats = _stats
    until stats
      deasync.sleep 100
    stats

  isDirectorySync: (path) ->
    local_fs.isDirectorySync path if not sftp_conn
    stats = @statSyncNoException path
    false if not stats
    stats.isDirectory()

  existsSync: (path) ->
    local_fs.existsSync path if not sftp_conn
    stats = @statSyncNoException path
    not not stats

  copySync: (path, newPath) ->
    local_fs.copySync path, newPath if not sftp_conn
    #TODO
    console.log "copySync", path, newPath
    true

  moveSync: (path, newPath) ->
    local_fs.moveSync path, newPath if not sftp_conn
    moveDone = False
    sftp_conn.rename path, newPath, (err) ->
      throw err if err
      moveDone = True
    until moveDone
      deasync.sleep 100
    true

  writeFileSync: (path, data) ->
    local_fs.writeFileSync path, data if not sftp_conn
    #TODO
    console.log "writeFileSync", path
    true

  readFileSync: (path) ->
    local_fs.readFileSync path if not sftp_conn
    #TODO
    console.log "readFileSync", path
    true
