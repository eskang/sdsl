# attack_open_redirector.rb
# model of an attack that involves an open redirector

require 'view.rb'

u = mod :User do
  stores set(:intents, :Addr)
  invokes(:visit,
          # user only types dest address that he/she intends to visit
          :when => [:intents.contains(o.dest)])
  # assumption: the user doesn't type addresses of a malicious site
  assumes (neg(:intents.contains(:MaliciousServer.addr)))
end

gs = mod :TrustedServer do
  stores :addr, :Addr
  # accepts any requests
  exports(:httpReq,
          :args => [:addr])
  invokes(:httpResp,
          :when => [triggeredBy(:httpReq)])
end

bs = mod :MaliciousServer do
  stores :addr, :Addr
  exports(:httpReq2, 
          :args => [:addr2])
  invokes(:httpResp)
end

c = mod :Client do 
  exports(:visit,
          :args => [:dest])
  # exports responses with redirects
  exports(:httpResp,
          :args => [:redirect])
  # invokes requests with redirects
  invokes(:httpReq,
          # sends a http request only when
          :when => [disj(
                         # the user initiates a connection or
                         conj(triggeredBy(:visit), o.addr.eq(trig.dest)),
                         # receives a redirect header from the server
                         conj(triggeredBy(:httpResp),
                              o.addr.eq(trig.redirect)))])
  invokes(:httpReq2,
          :when => [disj(conj(triggeredBy(:visit), o.addr2.eq(trig.dest)),
                         conj(triggeredBy(:httpResp),
                              o.addr2.eq(trig.redirect)))])
end

VIEW_OPEN_REDIRECTOR = view :OpenRedirector do
  modules u, c, bs, gs
  trusted c, gs, u
  data :Addr, :Payload
  critical :Payload
end

drawView VIEW_OPEN_REDIRECTOR, "open_redirector.dot"
dumpAlloy VIEW_OPEN_REDIRECTOR, "open_redirector.als"
