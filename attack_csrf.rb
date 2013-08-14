# attack_csrf.rb
# model of a cross-site request forgery attack

require 'view.rb'

goodServer = mod :GoodServer do
  stores :cookies, :Op, :Cookie
  stores :addr, :Addr
  stores set(:protected, :Op)
  creates :Cookie
  exports(:httpReq, 
          :args => [set(:headers, :Data), item(:dest, :Addr)],
          :when => af("o in protected implies some o.headers & cookies[o]"))
  invokes(:httpResp,
          :when => af("some o.trigger & httpReq"))
end

badServer = mod :BadServer do
  stores :addr, :Addr
  creates :BadDOM
  exports(:httpReq2,
          :args => [set(:headers2, :Data), item(:dest2, :Addr)])
  invokes(:httpResp,
          :when => af("some o.trigger & httpReq2 and " +
                      "some o.respHeaders & BadDOM"))
end

goodClient = mod :GoodClient do
  stores :cookies, :Addr, :Cookie
  exports(:httpResp,
          :args => [set(:respHeaders, :Data)])
  invokes(:httpReq,
          :when => conj(
                        af("some cookies[o.dest] implies " + 
                           "some o.headers & cookies[o.dest]"),
                        disj(
                             af("o.headers & Payload in creates"),
                             af("some o.trigger & httpResp and " + 
                                "some o.trigger.respHeaders & BadDOM"))
                        ))
  invokes(:httpReq2,
          :when => conj(
                        af("some cookies[o.dest2] implies " + 
                           "some o.headers2 & cookies[o.dest2]"),
                        af("no o.headers2 & Payload")))
end

VIEW_CSRF = view :AttackCSRF do
  modules goodServer, badServer, goodClient
  trusted goodServer, goodClient
  data :Cookie, :BadDOM, :Addr, :Payload
  critical :Payload
end

# puts goodServer
# puts badServer
# puts goodClient

# writeDot mods
