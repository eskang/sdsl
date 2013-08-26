# composition.rb
#
require 'oauth.rb'
require 'network.rb'
require 'attack_csrf.rb'
require 'attack_eavesdropper.rb'
require 'attack_open_redirector.rb'
require 'attack_replay.rb'

# Composition #1
mergedView = composeViews(VIEW_OAUTH, VIEW_CSRF, 
                          :Module => {
                            :ClientApp => :Client,
                            :AuthorizationServer => :TrustedServer,
                            :ResourceOwner => :TrustedServer,
                            :ResourceServer => :TrustedServer},
                          :Op => {
                            :reqAccessToken => :httpReq,
                            :sendResp => :httpResp,
                            :reqAuth => :httpReq,
                            :reqRes => :httpReq
                          }, 
                          :Data => {
                            :Resource => :Payload
                          })

mergedView2 = composeViews(VIEW_OAUTH, VIEW_OPEN_REDIRECTOR, 
                           :Module => {
                             :ClientApp => :Client,
                             :AuthorizationServer => :TrustedServer,
                             :ResourceOwner => :TrustedServer,
                             :ResourceServer => :TrustedServer},
                          :Op => {
                             :reqAccessToken => :httpReq,
                             :sendResp => :httpResp,
                             :reqAuth => :httpReq,
                             :reqRes => :httpReq
                           }, 
                           :Data => {
                             :Resource => :Payload
                           })

mergedView3 = composeViews(VIEW_OAUTH, VIEW_REPLAY, 
                           :Module => {
                             :ClientApp => :Endpoint,
                             :AuthorizationServer => :Endpoint,
                             :ResourceOwner => :Endpoint,
                             :ResourceServer => :Endpoint},
                          :Op => {
                             :reqAccessToken => :deliver,
                             :sendResp => :deliver,
                             :reqAuth => :deliver,
                             :reqRes => :deliver
                           }, 
                           :Data => {
#                             :Resource => :Packet
                           })

# # Composition #2
# mergedView2 = composeViews(V_NETWORK, V_EAVESDROPPER, 
#                            :Module => {
#                              :Sender => :EndpointA,
#                              :Receiver => :EndpointB},
#                            :Op => {}, 
#                            :Data => {}
#                            )

# # Composition #3
# mergedView3 = composeViews(VIEW_OAUTH, VIEW_OPEN_REDIRECTOR,
#                            :Module => {
#                              :ClientApp => :Client,
#                              :AuthorizationServer => :TrustedServer,
#                              :ResourceOwner => :TrustedServer,
#                              :ResourceServer => :TrustedServer
#                            },
#                            :Op => {
#                              :reqAccessToken => :httpReq,
#                              :sendResp => :httpResp,
#                              :reqAuth => :httpReq,
#                              :reqRes => :httpReq
#                            }, 
#                            :Data => {}
#                            )

# Composition #4
mergedClient = composeViews(VIEW_OPEN_REDIRECTOR, VIEW_CSRF,
                            :Module => {
                             :User => :User,
                             :TrustedServer => :TrustedServer,
                             :MaliciousServer => :MaliciousServer,
                             :Client => :Client
                           },
                           :Op => {
                             :httpReq => :httpReq,
                             :httpReq2 => :httpReq2,
                             :httpResp => :httpResp,
                             :visit => :visit
                           },
                           :Data => {}
                           )

mergedView_final = composeViews(VIEW_OAUTH, mergedClient,
                           :Module => {
                             :ClientApp => :Client,
                             :AuthorizationServer => :TrustedServer,
                             :ResourceOwner => :TrustedServer,
                             :ResourceServer => :TrustedServer},
                           :Op => {
                             :reqAccessToken => :httpReq,
                             :sendResp => :httpResp,
                             :reqAuth => :httpReq,
                             :reqRes => :httpReq
                           }, 
                           :Data => {
                             :Resource => :Payload
                           })

drawView mergedView, "merged1_oauth.dot"
dumpAlloy mergedView, "merged1_oauth.als"

# drawView mergedView2, "merged2_network.dot"
# dumpAlloy mergedView2, "merged2_network.als"

drawView mergedView2, "merged2_oauth.dot"
dumpAlloy mergedView2, "merged2_oauth.als"

drawView mergedView3, "merged3_oauth.dot"
dumpAlloy mergedView3, "merged3_oauth.als"

drawView mergedClient, "merged_client.dot"
dumpAlloy mergedClient, "merged_client.als"

drawView mergedView_final, "merged_final_oauth.dot"
dumpAlloy mergedView_final, "merged_final_oauth.als"

#pp VIEW_OAUTH
#dumpAlloy VIEW_OAUTH
#pp VIEW_CSRF
#dumpAlloy VIEW_CSRF
