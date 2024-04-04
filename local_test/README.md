# How To

## start

`docker build -t my-nginx . && docker run --name my-nginx -d -p 443:443 my-nginx`

`openssl s_client -connect localhost:443 -CAfile <ca file> -showcerts`

## stop
`docker stop my-nginx && docker rm my-nginx`