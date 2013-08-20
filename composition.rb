# composition.rb
#
require 'oauth.rb'
require 'onetimepad.rb'
require 'attack_csrf.rb'
require 'attack_eavesdropper.rb'
require 'attack_open_redirector.rb'

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
# mergedView2 = composeViews(V_ONETIMEPAD, V_EAVESDROPPER, 
#                            :Module => {
#                              :Sender => :EndpointA,
#                              :Receiver => :EndpointB},
#                            :Op => {
#                              :send => :deliver
#                            }, 
#                            :Data => {}
#                            )

# Composition #3
mergedView3 = composeViews(VIEW_OAUTH, VIEW_OPEN_REDIRECTOR,
                           :Module => {
                             :Client => :GoodClient,
                             :AuthorizationServer => :GoodServer,
                             :ResourceOwner => :GoodServer,
                             :ResourceServer => :GoodServer
                           },
                           :Op => {
                             :reqAccessToken => :httpReq,
                             :sendResp => :httpResp,
                             :reqAuth => :httpReq,
                             :reqRes => :httpReq
                           }, 
                           :Data => {}
                           )

drawView mergedView, "merged_oauth.dot"
dumpAlloy mergedView, "merged_oauth.als"

# drawView mergedView2, "merged_onetimepad.dot"
# dumpAlloy mergedView2, "merged_onetimepad.als"

drawView mergedView3, "merged_oauth3.dot"
dumpAlloy mergedView3, "merged_oauth3.als"

#pp VIEW_OAUTH
#dumpAlloy VIEW_OAUTH
#pp VIEW_CSRF
#dumpAlloy VIEW_CSRF

