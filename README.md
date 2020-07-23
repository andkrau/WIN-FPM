# WIN-FPM
Implements a PHP FastCGI Pool Manager on Windows

## Usage

```html
win-fpm.exe -basePort 9001 -poolSize 8 -phpDir C:/php -fcgiChildren 2 -listenHost 127.0.0.1 -errorLimit 10
```
