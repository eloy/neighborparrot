if Goliath.prod?
  server_url = "https://neighborparrot.net"
  assets_path = "https://neighborparrot.com"
else
  server_url = "http://localhost:9000"
  assets_path = server_url
end

INDEX_TEMPLATE= <<EOF
<html>
<head>
  <META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">
  <script type="text/javascript" src="#{assets_path}/js/jquery.min.js"></script>
  <script type="text/javascript" src="#{assets_path}/js/eventsource.js"></script>
  <script type="text/javascript" src="#{assets_path}/js/jquery.ba-postmessage.js"></script>
  <script type="text/javascript" src="#{assets_path}/js/broker.js"></script>
</head>
<body>
:-)
<script>
  app.broker = new Broker("#{server_url}");
  app.broker.open();
</script>
</body>
</html>
EOF
