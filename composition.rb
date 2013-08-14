# composition.rb
#
require 'oauth.rb'
require 'attack_csrf.rb'

mergedView = composeViews(VIEW_OAUTH, VIEW_CSRF, 
                          :Module => {
                            :Client => :GoodClient,
                            :AuthorizationServer => :GoodServer,
                            :ResourceOwner => :GoodServer,
                            :ResourceServer => :GoodServer},
                          :Op => {
#                             :reqAccessToken => :httpReq,
#                             :sendResp => :httpRes,
#                             :reqAuth => :httpReq,
#                             :reqRes => :httpReq
                          }, 
                          :Data => {}
                        )

drawView mergedView
pp mergedView
dumpAlloy mergedView
#pp VIEW_OAUTH
#dumpAlloy VIEW_OAUTH
#pp VIEW_CSRF
#dumpAlloy VIEW_CSRF

