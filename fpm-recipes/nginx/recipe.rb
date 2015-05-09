class Nginx < FPM::Cookery::Recipe
  description 'a high performance web server and a reverse proxy server'

  name 'nginx'
  version '1.8.0'
  revision 2
  homepage 'http://nginx.org/'
  source "http://nginx.org/download/nginx-#{version}.tar.gz"
  sha256 '23cca1239990c818d8f6da118320c4979aadf5386deda691b1b7c2c96b9df3d5'

  section 'httpd'

  build_depends 'build-essential', 'git', 'libgeoip-dev', 'libpcre3-dev', 'zlib1g-dev', 'libssl-dev (<< 1.0.0)', 'libgd2-noxpm-dev', 'libperl-dev', 'wget'
  depends 'libpcre3', 'zlib1g', 'libssl0.9.8', 'libgeoip1', 'libgd2-noxpm-dev'

  provides 'nginx-full', 'nginx-common'
  replaces 'nginx-full', 'nginx-common'
  conflicts 'nginx-full', 'nginx-common'

  config_files '/etc/nginx/nginx.conf', '/etc/nginx/mime.types',
               '/var/www/nginx-default/index.html'

  post_install 'postinst'

  def build
    safesystem "git clone https://github.com/octohost/ngx_txid.git #{builddir}/ngx_txid"
    safesystem "git clone https://github.com/pagespeed/ngx_pagespeed.git #{builddir}/ngx_pagespeed"
    safesystem "cd #{builddir}/ngx_pagespeed/ && curl -LO https://dl.google.com/dl/page-speed/psol/1.9.32.3.tar.gz"
    safesystem "cd #{builddir}/ngx_pagespeed/ && tar -zxf 1.9.32.3.tar.gz"
    configure \
      '--sbin-path=/usr/sbin/nginx',
      '--with-http_stub_status_module',
      '--with-http_ssl_module',
      '--with-http_spdy_module',
      '--with-http_gzip_static_module',
      '--with-pcre',
      '--with-debug',
      '--with-http_dav_module',
      '--with-http_flv_module',
      '--with-http_geoip_module',
      '--with-http_gzip_static_module',
      '--with-http_realip_module',
      '--with-http_image_filter_module',
      '--with-http_sub_module',
      '--with-ipv6',
      '--with-sha1=/usr/include/openssl',
      '--with-md5=/usr/include/openssl',
      '--with-http_secure_link_module',
      '--with-http_sub_module',
      '--with-http_addition_module',
      "--add-module=#{builddir}/ngx_txid",
      "--add-module=#{builddir}/ngx_pagespeed",

      prefix: prefix,

      user: 'www-data',
      group: 'www-data',

      pid_path: '/var/run/nginx.pid',
      lock_path: '/var/lock/nginx.lock',
      conf_path: '/etc/nginx/nginx.conf',
      http_log_path: '/var/log/nginx/access.log',
      error_log_path: '/var/log/nginx/error.log',
      http_proxy_temp_path: '/var/lib/nginx/proxy',
      http_fastcgi_temp_path: '/var/lib/nginx/fastcgi',
      http_client_body_temp_path: '/var/lib/nginx/body',
      http_uwsgi_temp_path: '/var/lib/nginx/uwsgi',
      http_scgi_temp_path: '/var/lib/nginx/scgi'

    make
  end

  def install
    # startup script
    (etc / 'init.d').install_p(workdir / 'nginx.init.d', 'nginx')

    # config files
    (etc / 'nginx').install Dir['conf/*']

    # default site
    (var / 'www/nginx-default').install Dir['html/*']

    # server
    sbin.install Dir['objs/nginx']

    # man page
    man8.install Dir['objs/nginx.8']
    gzip_path = '/bin/gzip'
    safesystem gzip_path, man8 / 'nginx.8'

    # support dirs
    %w( run lock log/nginx lib/nginx ).map do |dir|
      (var / dir).mkpath
    end
  end
end
