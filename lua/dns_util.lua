local resolver = require("resty.dns.resolver")

local _M = {}

local function a_records(answers)
  local addresses = {}

  for _, ans in ipairs(answers) do
    if ans.address then
      table.insert(addresses, ans.address)
    end
  end

  return addresses
end

local function resolve_host(host, r, qtype)
  local answers
  answers, err = r:query(host, { qtype = qtype }, {})
  if not answers then
    return nil, tostring(err)
  end

  if answers.errcode then
    return nil, string.format("server returned error code: %s: %s", answers.errcode, answers.errstr)
  end

  local addresses = a_records(answers)
  if #addresses == 0 then
    return nil, "no record resolved"
  end

  return addresses, nil
end

function _M.resolve(host)
  local r
  r, err = resolver:new{
    nameservers = configuration.nameservers,
    retrans = 5,
    timeout = 2000,  -- 2 sec
  }

  if not r then
    ngx.log(ngx.ERR, "failed to instantiate the resolver: " .. tostring(err))
    return nil
  end

  local addresses
  addresses, err = resolve_host(host, r, r.TYPE_A)
  if not addresses then
    ngx.log(ngx.ERR, string.format("failed to query the DNS server: DNS: %s, error: %s", host, tostring(err)))
    return nil
  elseif #addresses == 0 then
    ngx.log(ngx.ERR, "DNS resolve to empty result"..host)
    return nil
  end

  return addresses
end

return _M
