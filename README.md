# WIN-FPM
Implements a PHP FastCGI Pool Manager on Windows

## Usage

```
win-fpm.cmd
```

## NGINX Example

```
upstream winfpm {
    server 127.0.0.1:9001
    server 127.0.0.1:9002
    server 127.0.0.1:9003
    server 127.0.0.1:9004
    server 127.0.0.1:9005
    server 127.0.0.1:9006
    server 127.0.0.1:9007
    server 127.0.0.1:9008
}

location ~ \.php$ {
    fastcgi_pass   winfpm;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
    include        fastcgi_params;
}
```

## Caddy 2.0 Example

```
php_fastcgi {
        to localhost:9001
        to localhost:9002
        to localhost:9003
        to localhost:9004
        to localhost:9005
        to localhost:9006
        to localhost:9007
        to localhost:9008
}
```

## Caddy 1.0 Example

```
fastcgi / 127.0.0.1:9001 php {
    upstream 127.0.0.1:9002
    upstream 127.0.0.1:9003
    upstream 127.0.0.1:9004
    upstream 127.0.0.1:9005
    upstream 127.0.0.1:9006
    upstream 127.0.0.1:9007
    upstream 127.0.0.1:9008
}
```