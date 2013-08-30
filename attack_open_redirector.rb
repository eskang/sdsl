# attack_open_redirector.rb
# model of an attack that involves an open redirector

require 'view.rb'

u = mod :User do
  stores set(:intentsB, :Addr)
  invokes(:visit,
          # user only types dest address that he/she intends to visit
          :when => [:intentsB.contains(o.destB)])
  # assumption: the user doesn't type addresses of a malicious site
  assumes(neg(:intentsB.contains(:MaliciousServer.addrB)))
end

gs = mod :TrustedServer do
  stores :addrB, :Addr
  # accepts any requests
  exports(:httpReq,
          :args => [item(:addrB, :Addr)])
  invokes(:httpResp,
          :when => [triggeredBy(:httpReq)])
end

bs = mod :MaliciousServer do
  stores :addrB, :Addr
  exports(:httpReq, 
          :args => [item(:addrB, :Addr)])
  invokes(:httpResp)
end

c = mod :Client do 
  exports(:visit,
          :args => [item(:destB, :Addr)])
  # exports responses with redirects
  exports(:httpResp,
          :args => [item(:redirect, :Addr)])
  # invokes requests with redirects
  invokes(:httpReq,
          # sends a http request only when
          :when => [disj(
                         # the user initiates a connection or
                         conj(triggeredBy(:visit), o.addrB.eq(trig.destB)),
                         # receives a redirect header from the server
                         conj(triggeredBy(:httpResp),
                              o.addrB.eq(trig.redirect)))])
end

VIEW_OPEN_REDIRECTOR = view :OpenRedirector do
  modules u, c, bs, gs
  trusted c, gs, u
  data :Addr
end

drawView VIEW_OPEN_REDIRECTOR, "open_redirector.dot"
dumpAlloy VIEW_OPEN_REDIRECTOR, "open_redirector.als"
