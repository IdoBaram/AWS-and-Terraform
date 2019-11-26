#! /bin/bash
sudo apt-get install nginx -y
sudo service nginx start
echo "" > /var/www/html/index.nginx-debian.html
cat <<EOT >> /var/www/html/index.nginx-debian.html
<header>
<h1>Welcome Ops School lesson 3 homework</h1>
<h2>your server name is hostname</h>
<link rel="stylesheet" href="index.css">
</header>
EOT
cat <<EOT >> /var/www/html/index.css
	@import url(https://fonts.googleapis.com/css?family=Source+Sans+Pro:400,900);
body {
	background: linear-gradient( rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)), url('https://i.ibb.co/0YR0cXS/opsschool-1.png');
	background-size: cover;
	font-family: "Source Sans Pro", sans-serif;}
 header {
		position: absolute;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		color: white;
		text-align: center;
	}
	h1 {
		text-transform: uppercase;
		margin: 0;
		font-size: 3rem;
		white-space: nowrap;
	}
	p {
		margin: 0;
		font-size: 1.5rem;
	}
EOT
sudo sed -i "s/hostname/$(cat /etc/hostname)/" /var/www/html/index.nginx-debian.html
sudo apt-get update 
sudo apt-get install python-pip -y
sudo apt-get install s3cmd -y
cat <<EOT >> /home/ubuntu/.s3cfg
[default]
access_key =
secret_key = 
security_token =
EOT
cat <<EOT>> /home/ubuntu/nginxs3.sh
#!/bin/bash
s3cmd put /var/log/nginx/access.log s3://ngnixlogstf/\$HOSTNAME/\`date +%Y-%m-%dT%H:%M\`_access.log
EOT
sudo chmod 555 /home/ubuntu/nginxs3.sh
sudo echo "0 * * * * root /home/ubuntu/nginxs3.sh" >> /etc/crontab