# composition.rb
#
require 'oauth.rb'
require 'onetimepad.rb'
require 'attack_csrf.rb'
require 'attack_eavesdropper.rb'

# Composition #1
mergedView = composeViews(VIEW_OAUTH, VIEW_CSRF, 
                          :Module => {
                            :Client => :GoodClient,
                            :AuthorizationServer => :GoodServer,
                            :ResourceOwner => :GoodServer,
                            :ResourceServer => :GoodServer},
                          :Op => {
                            :reqAccessToken => :httpReq,
                            :sendResp => :httpResp,
                            :reqAuth => :httpReq,
                            :reqRes => :httpReq
                          }, 
                          :Data => {}
                        )

# Composition #2
# mergedView = composeViews(V_ONETIMEPAD, V_EAVESDROPPER, 
#                           :Module => {
#                             :Sender => :EndpointA,
#                             :Receiver => :EndpointB},
#                           :Op => {
#                             :send => :deliver
#                           }, 
#                           :Data => {}
#                           )

drawView mergedView
pp mergedView
dumpAlloy mergedView, "merged.als"
#pp VIEW_OAUTH
#dumpAlloy VIEW_OAUTH
#pp VIEW_CSRF
#dumpAlloy VIEW_CSRF

