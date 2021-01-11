# WIN-FPM
Implements a PHP FastCGI Pool Manager on Windows

## Usage

```
win-fpm.exe -basePort 9001 -poolSize 8 -phpDir C:/php -fcgiChildren 2 -listenHost 127.0.0.1 -errorLimit 10
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