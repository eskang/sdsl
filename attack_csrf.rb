# attack_csrf.rb
# model of a cross-site request forgery attack

require 'view.rb'

u = mod :User do
  stores set(:intentsA, :URL)
  invokes(:visit,
          # user only types dest address that he/she intends to visit
          :when => [:intentsA.contains(o.destA)])
end

goodServer = mod :TrustedServer do
  stores :cookies, :Op, :Cookie
  stores :addrA, :Hostname
  stores set(:protected, :Op)
  creates :DOM
  creates :Cookie
  exports(:httpReq, 
          :args => [item(:cookie, :Cookie), 
                    item(:addrA, :URL)],
          # if op is protected, only accept when it provides a valid cookie
          :when => [implies(:protected.contains(o),
                            o.cookie.eq(:cookies[o]))])
  invokes(:httpResp,
          :when => [triggeredBy :httpReq])
end

badServer = mod :MaliciousServer do
  stores :addrA, :Hostname
  creates :DOM   
  exports(:httpReq,
          :args => [item(:cookie, :Cookie), 
                    item(:addrA, :URL)])
  invokes(:httpResp,
          :when => [triggeredBy :httpReq])
end

goodClient = mod :Client do
  stores :cookies, :URL, :Cookie
  exports(:visit,
          :args => [item(:destA, :URL)])
  exports(:httpResp,
          :args => [item(:dom, :DOM),
                    item(:addrA, :URL)])
  invokes(:httpReq,
          :when => [
                    # req always contains any associated cookie
                    implies(some(:cookies[o.addrA]),
                            o.cookie.eq(:cookies[o.addrA])),
                    disj(
                         # sends a http request only when
                         # the user initiates a connection 
                         conj(triggeredBy(:visit), 
                              o.addrA.eq(trig.destA)),
                         # or in response to a src tag
                         conjs([triggeredBy(:httpResp),
                                trig.dom.tags.src.contains(o.addrA)]
                               ))
                   ])
end

dom = datatype :DOM do
  field set(:tags, :HTMLTag)
  extends :Payload
end

url = datatype :URL do
  field item(:host, :Hostname)
  field set(:args, :Payload)
end

imgTag = datatype :ImgTag do 
  field item(:src, :URL)
  extends :HTMLTag
end
tag = datatype :HTMLTag do setAbstract end

cookie = datatype :Cookie do extends :Payload end
otherPayload = datatype :OtherPayload do extends :Payload end
payload = datatype :Payload do setAbstract end

VIEW_CSRF = view :AttackCSRF do
  modules u, goodServer, badServer, goodClient
  trusted goodServer, goodClient, u
  data url, :Hostname, cookie, otherPayload, payload, dom, tag, imgTag
end

drawView VIEW_CSRF, "csrf.dot"
dumpAlloy VIEW_CSRF, "csrf.als"
# puts goodServer
# puts badServer
# puts goodClient

# writeDot mods

