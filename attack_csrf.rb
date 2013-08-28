# attack_csrf.rb
# model of a cross-site request forgery attack

require 'view.rb'

u = mod :User do
  stores set(:intents, :Addr)
  invokes(:visit,
          # user only types dest address that he/she intends to visit
          :when => [:intents.contains(o.dest)])
end

goodServer = mod :TrustedServer do
  stores :cookies, :Op, :Cookie
  stores :addr, :Addr
  stores set(:protected, :Op)
  creates :Cookie
  exports(:httpReq, 
          :args => [set(:headers, :Data), :addr],
          # if op is protected, only accept when it provides a valid cookie
          :when => [implies(:protected.contains(o),
                            o.headers.contains(:cookies[o]))])
  invokes(:httpResp,
          :when => [triggeredBy :httpReq])
end

badServer = mod :MaliciousServer do
  stores :addr, :Addr
  creates :DOM       # some malicious DOM
  creates :Payload
  exports(:httpReq,
          :args => [set(:headers, :Data), :addr])
  invokes(:httpResp,
          :when => [triggeredBy :httpReq])
end

goodClient = mod :Client do
  stores :cookies, :Addr, :Cookie
  creates :Payload
  exports(:visit,
          :args => [:dest])
  exports(:httpResp,
          :args => [set(:respHeaders, :HTTPHeader)])
  invokes(:httpReq,
          :when => [
                    # req always contains any associated cookie
                    implies(some(:cookies[o.addr]),
                            o.headers.contains(:cookies[o.addr])),
                    disj(
                         # sends a http request only when
                         # the user initiates a connection 
                         conj(triggeredBy(:visit), 
                              o.addr.eq(trig.dest)),
                         # or in response to a malicious DOM 
                         conjs([triggeredBy(:httpResp),
                                trig.respHeaders.contains(:DOM),
                                o.addr.eq(trig.respHeaders.srcTag)]
                               ))
                         ])
end

dom = datatype :DOM do
  field item(:srcTag, :Addr)
  field item(:payload, :Payload)
  extends :HTTPHeader
end

httpHeader = datatype :HTTPHeader do
  setAbstract
end

VIEW_CSRF = view :AttackCSRF do
  modules u, goodServer, badServer, goodClient
  trusted goodServer, goodClient, u
  data :Cookie, :Addr, :Payload, httpHeader, dom
  critical :Payload
  protected goodServer
end

drawView VIEW_CSRF, "csrf.dot"
dumpAlloy VIEW_CSRF, "csrf.als"
# puts goodServer
# puts badServer
# puts goodClient

# writeDot mods

