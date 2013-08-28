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
drawView mergedView, "merged_oauth.dot"
dumpAlloy mergedView, "merged_oauth.als"

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
drawView mergedView2, "merged_open_redirect_oauth.dot"
dumpAlloy mergedView2, "merged_open_redirect_oauth.als"


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
drawView mergedView3, "merged_replay_oauth.dot"
dumpAlloy mergedView3, "merged_replay_oauth.als"


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
                             :httpResp => :httpResp,
                             :visit => :visit
                           },
                           :Data => {}
                           )
drawView mergedClient, "merged_client.dot"
dumpAlloy mergedClient, "merged_client.als"

mergedClient_replay = composeViews(mergedClient, VIEW_REPLAY,
                                   :Module => {
                                     :TrustedServer => :Endpoint,
                                     :MaliciousServer => :Endpoint,
                                     :Client => :Endpoint
                                   },
                                   :Op => {
                                     :httpReq => :deliver,
                                     :httpResp => :deliver,
                                     :visit => :visit
                                   },
                                   :Data => {}
                                   )
drawView mergedClient_replay, "merged_client_replay.dot"
dumpAlloy mergedClient_replay, "merged_client_replay.als"

mergedView_final = composeViews(VIEW_OAUTH, mergedClient_replay,
                           :Module => {
                             :ClientApp => :Client_Endpoint,
                             :AuthorizationServer => :TrustedServer_Endpoint,
                             :ResourceOwner => :TrustedServer_Endpoint,
                             :ResourceServer => :TrustedServer_Endpoint},
                           :Op => {
                             :reqAccessToken => :httpReq_deliver,
                             :sendResp => :httpResp_deliver,
                             :reqAuth => :httpReq_deliver,
                             :reqRes => :httpReq_deliver
                           }, 
                           :Data => {
#                             :Resource => :Payload
                           })

# drawView mergedView2, "merged2_network.dot"
# dumpAlloy mergedView2, "merged2_network.als"

drawView mergedView_final, "merged_final.dot"
dumpAlloy mergedView_final, "merged_final.als"

#pp VIEW_OAUTH
#dumpAlloy VIEW_OAUTH
#pp VIEW_CSRF
#dumpAlloy VIEW_CSRF
