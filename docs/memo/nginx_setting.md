    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        #root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        #include /etc/nginx/default.d/*.conf;
        location ^~.*$ {
            proxy_pass https://al00038-local-https.s3.ap-northeast-1.amazonaws.com/index.html;
            resolver 169.254.169.253;
        }

        location / {
            proxy_pass https://al00038-local-https.s3.ap-northeast-1.amazonaws.com/;
            resolver 169.254.169.253;
            proxy_intercept_errors on;
        }

        error_page 403 /403.html;
        location = /403.html {
            proxy_pass https://al00038-local-https.s3.ap-northeast-1.amazonaws.com/index.html;
            resolver 169.254.169.253;
        }


        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }