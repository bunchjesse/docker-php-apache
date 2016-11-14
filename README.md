# PHP 7 + Apache2 + More

# Introduction
This is a fork of the official PHP + Apache image but with a bunch of switches for development and production usage.

## Apache2
By default, apache2 listens on ports 80 and 443 with a self-signed SSL certificate and serves files from the `/web/public` directory.

### Customizing Apache2
This image was built to be ready to go and any common configuration changes you need to make should be doable with the following environment variables:

#### APACHE_DOCUMENT_ROOT
default: `/web/public`

#### APACHE_SSL_CERT_FILE
default: `/etc/ssl/certs/ssl-cert-snakeoil.pem`

#### APACHE_SSL_KEY_FILE
default: `/etc/ssl/private/ssl-cert-snakeoil.key`

If you need to tweak something that is not provided here, you can do so via `.htaccess` or you can add your own custom configuration to `/etc/apache2/conf-available`. Be sure to enable your configuration with `a2enconf`.

## PHP
PHP is enabled with the preform mpm as recommended in the official PHP 7 docker image.

### Customizing PHP
The following PHP configuration variables are configurable with environment variables:

#### PHP_MEMORY_LIMIT
default: `16M`

#### PHP_POST_MAX_SIZE
default: `32M`

#### PHP_UPLOAD_MAX_FILESIZE
default: `16M`

### Xdebug
Xdebug is installed and can be configured with the following environment variables:

#### XDEBUG_ENABLED
default: `0`

#### XDEBUG_REMOTE_ENABLE
default: `0`

#### XDEBUG_REMOTE_AUTOSTART
default: `0`

#### XDEBUG_REMOTE_CONNECT_BACK
default: `0`

#### XDEBUG_REMOTE_HOST
default: `localhost`

#### XDEBUG_IDEKEY
default: `docker`

### Opcode Caching
Xdebug is installed and can be enabled or disabled with an environment variable:

#### PHP_OPCACHE_ENABLED
default: `1`

### Composer
Composer is installed along with [Prestissimo](https://github.com/hirak/prestissimo) to help speed up composer installs.

### Node && NPM
Both are installed and ready to go.

## Runtime Scripts
This image follows the [Flexible Docker entrypoints scripts](http://www.camptocamp.com/en/actualite/flexible-docker-entrypoints-scripts/) format in that there is a `/docker-entrypoint.d` folder that contains all of the scripts that will be run at startup *before* apache2 is started. Internally, this is used to do some last minute tweaking of things based on the environment. You may add whatever scripts you want to this (make sure to chmod +x them!) and they'll be run also.