# oauth.rb
# model of a basic OAuth protocol

require 'view.rb'

resOwner = mod :ResourceOwner do
  stores :authGrants, :Credential, :AuthGrant
  creates :AuthGrant
  # "req's argument includes credentials"
  exports(:reqAuth, 
          :args => [:cred], 
          :when => contains(:authGrants, arg(:cred)))
  # "in response to reqAuth"
  # "authorization grant for the requested scope
  invokes(:sendResp, 
          :when => conj(triggeredBy(:reqAuth), 
                        equals(nav(:authGrants, 
                                   arg(:cred, trig)), 
                               arg(:data))))
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
          :when => contains(:accessTokens, arg(:authGrant)))
  invokes(:sendResp, 
          :when => conj(triggeredBy(:reqAccessToken),
                        equals(nav(:accessTokens, arg(:authGrant, trig)),
                               arg(:data))))                       
end

resServer = mod :ResourceServer do
  stores :resources, :AccessToken, :Resource
  creates :Resource
  exports(:reqRes, 
          :args => [:accessToken],
          :when => contains(:resources, arg(:accessToken)))
  invokes(:sendResp,
          :when => conj(triggeredBy(:reqRes),
                        equals(nav(:resources, 
                                   arg(:accessToken, trig)),
                               arg(:data))))
end

VIEW_OAUTH = view :OAuth do 
  modules resOwner, client, authServer, resServer
  data :Credential, :AuthGrant, :AccessToken, :Resource
  critical :Resource
  trusted resOwner, client, authServer, resServer
end

# puts resOwner
# puts client
# puts authServer
# puts resServer

# writeDot mods
