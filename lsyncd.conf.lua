settings {
    logfile = "/var/log/lsyncd/lsyncd.log",
    statusFile = "/var/log/lsyncd/lsyncd.status",
    nodaemon = false
}

-- Dự án 1: Hongkong Luxury
sync {
    default.rsync,
    source = "/opt/hongkong-server/",
    target = "root@vungvang.duckdns.org:/opt/hongkong-server/",
    rsync = {
        archive = true,
        compress = true,
        _extra = {"--delete"}
    }
}
