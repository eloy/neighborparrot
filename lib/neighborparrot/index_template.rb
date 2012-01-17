require 'erb'
require 'pp'

module Neighborparrot

  SERVER_URL = "https://neighborparrot.net"
  ASSETS_URL = "https://neighborparrot.com"

  def get_index_template(env)
    @template_cache = {} unless @template_cache
    use_polyfill = env.params['use_polyfill'] == 'true'
    template = use_polyfill ? :index_polyfill : :index
    unless @template_cache[template]
      @template_cache[template] = parse_index_template env, use_polyfill
    end
    return @template_cache[template]
  end

  def parse_index_template(env, use_polyfill = false)
    server_url = env.config[:server_url] || SERVER_URL
    assets_path = env.config[:assets_path] || ASSETS_URL
    return INDEX_TEMPLATE.result(binding)
  end

INDEX_TEMPLATE = ERB.new <<-EOF
<html>
<head>
  <META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">
  <% if use_polyfill %>
    <script type="text/javascript" src="<%= assets_path %>/js/eventsource.js"></script>
  <% end %>
  <script type="text/javascript" src="<%= assets_path %>/js/broker.js"></script>
</head>
<body>
:-)
<script>
  broker = new Broker("<%= server_url %>");
  setTimeout(function() { broker.open(); }, 0);
</script>
</body>
</html>
EOF
end
