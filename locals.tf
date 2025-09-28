locals {
  home = {
    gate = {
      nginx = {
        install = {
          script = {
            tmpPath = "/tmp/install_nginx.sh"
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
