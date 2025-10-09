# Local values for LXC nginx configuration

locals {
  home = {
    gate = {
      nginx = {
        install = {
          script = {
            tmpPath = "/tmp/install_lxc_nginx.sh"
          }
        }
        conf = {
          proxy = {
            tmpPath = "/tmp/lxc_proxy.stream.conf"
          }
        }
      }
    }
  }
}