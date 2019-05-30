local ngx_balancer = require "ngx.balancer"
local dns_util = require "dns_util"
local resty_roundrobin = require "balancer.roundrobin"

local balancers = {}
local _M = {}

local function get_balancer(key)
  local balancer = balancers[key]
  if not balancer then
    return
  end

  return balancer
end

local function create_balancer(backends)
  return resty_roundrobin:new(backends)
end

local function generate_full_address(ip, port)
  return table.concat({ip, ":", port})
end

function _M.rewrite()
  local backend_name = ngx.var.upstream_name
  local backend_port = ngx.var.upstream_port

  local balancer = get_balancer(backend_name)
  if balancer then
    return
  end

  local ips = dns_util.resolve(backend_name)
  if not ips or #ips == 0 then
    ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
    return ngx.exit(ngx.status)
  end

  local backends = {}
  for _, ip in pairs(ips) do
    local addr = generate_full_address(ip, backend_port)
    backends[addr] = 1
  end

  balancers[backend_name] = create_balancer(backends)
end

function _M.balance()
  local backend_name = ngx.var.upstream_name
  local balancer = get_balancer(backend_name)
  if not balancer then
    ngx.log(ngx.ERR, "cannot find load balancer for upstream: " .. backend_name)
    return
  end

  local peer = balancer:find()
  if not peer then
    ngx.log(ngx.WARN, "no peer was returned, upstream: " .. backend_name)
    return
  end

  ngx_balancer.set_more_tries(1)

  local ok, err = ngx_balancer.set_current_peer(peer)
  if not ok then
    ngx.log(ngx.ERR, string.format("error while setting current upstream peer %s: %s", peer, err))
  end
end

return _M
