package 'nginx' do
  action :install
end

file '/etc/nginx/sites-available/default' do
  content <<~NGINX
    server {
      listen 8080;
      server_name _;
      
      root /var/www/html;
      index index.html;
      
      location / {
        try_files $uri $uri/ =404;
      }
    }
  NGINX
end

service 'nginx' do
  action [:enable, :start]
  subscribes :restart, 'file[/etc/nginx/sites-available/default]', :immediately
end