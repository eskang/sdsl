# oauth.rb
# model of a basic OAuth protocol

require 'view.rb'

resOwner = mod :ResourceOwner do
  stores :authGrants, :Credential, :AuthGrant
  creates :AuthGrant
  # "req's argument includes credentials"
  exports(:reqAuth, 
          :args => [:cred], 
          :when => hasKey(:authGrants, arg(:cred)))
  # "in response to reqAuth"
  # "authorization grant for the requested scope
  invokes(:sendResp, 
          :when => conj(triggeredBy(:reqAuth), 
                        nav(:authGrants, arg(:cred, trig)).eq(arg(:data))))
#:when => [triggeredBy :reqAuth,
#          authGrants.cred(trig) == data]
end

client = mod :Client do
  stores :cred, :Credential
  creates :Credential
  invokes :reqAuth
  invokes :reqRes
  invokes :reqAccessToken
  exports :sendResp, :args => [:data]
end

authServer = mod :AuthorizationServer do
  stores :accessTokens, :AuthGrant, :AccessToken
  creates :AccessToken
  exports(:reqAccessToken, 
          :args => [:authGrant], 
          :when => hasKey(:accessTokens, arg(:authGrant)))
  invokes(:sendResp, 
          :when => conj(triggeredBy(:reqAccessToken),
                        nav(:accessTokens, 
                            arg(:authGrant, trig)).eq(arg(:data))))                    
end

resServer = mod :ResourceServer do
  stores :resources, :AccessToken, :Resource
  creates :Resource
  exports(:reqRes, 
          :args => [:accessToken],
          :when => hasKey(:resources, arg(:accessToken)))
  invokes(:sendResp,
          :when => conj(triggeredBy(:reqRes),
                        nav(:resources, 
                            arg(:accessToken, trig)).eq(arg(:data))))
end

VIEW_OAUTH = view :OAuth do 
  modules resOwner, client, authServer, resServer
  data :Credential, :AuthGrant, :AccessToken, :Resource
  critical :Resource
  trusted resOwner, client, authServer, resServer
end

drawView VIEW_OAUTH, "oauth.dot"
dumpAlloy VIEW_OAUTH, "oauth.als"

# puts resOwner
# puts client
# puts authServer
# puts resServer

# writeDot mods
