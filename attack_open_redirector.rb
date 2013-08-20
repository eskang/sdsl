# attack_open_redirector.rb
# model of an attack that involves an open redirector

require 'view.rb'

u = mod :User do
  stores set(:visits, :Addr)
  invokes(:visit,
          :when => expr(:visits).contains(arg(:dest)))
  assumes (neg(expr(:visits).contains(expr(:BadServer).join(expr(:addr)))))
end

c = mod :GoodClient do 
  exports(:visit,
          :args => [:dest])
  # exports responses with redirects
  exports(:httpResp,
          :args => [:redirect])
  # invokes requests with redirects
  invokes(:httpReq,
          :when => disj(conj(triggeredBy(:visit), 
                             arg(:addr).eq(arg(:addr, trig))),
                        conj(triggeredBy(:httpResp),
                             arg(:addr).eq(arg(:redirect, trig)))))
  invokes(:httpReq2,
          :when => disj(conj(triggeredBy(:visit), 
                             arg(:addr).eq(arg(:addr, trig))),
                        conj(triggeredBy(:httpResp),
                             arg(:addr).eq(arg(:redirect, trig))))) 
end

bs = mod :BadServer do
  stores :addr, :Addr
  exports(:httpReq2, 
          :args => [:addr2])
  invokes(:httpResp)
end

gs = mod :GoodServer do
  stores :addr, :Addr
  # accepts requests
  exports(:httpReq,
          :args => [:addr])
  # sends responses with redirect
  invokes(:httpResp)
end

VIEW_OPEN_REDIRECTOR = view :OpenRedirector do
  modules u, c, bs, gs
  trusted c, gs, u
  data :Addr, :Payload
  critical :Payload
end

drawView VIEW_OPEN_REDIRECTOR, "open_redirector.dot"
dumpAlloy VIEW_OPEN_REDIRECTOR, "open_redirector.als"

