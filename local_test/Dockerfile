FROM nginx:latest
COPY test-crt.pem /etc/nginx/test-crt.pem
COPY test-key.pem /etc/nginx/test-key.pem
RUN rm /etc/nginx/conf.d/default.conf
ADD custom_nginx.conf /etc/nginx/conf.d/
