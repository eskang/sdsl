open models/basic

one sig BadServer extends Module {
	addr : lone Addr,
}{
	all o : this.sends[httpResp] | some o.trigger & httpReq2 and some o.respHeaders & BadDOM
}
sig httpReq2 extends Op {
	headers2 : set Data,
	dest2 : lone Addr,
}{
	receiver in BadServer
	args = headers2 + dest2
}

one sig Client_GoodClient extends Module {
	cred : lone Credential,
	cookies : Addr -> Cookie,
}{
}
sig sendResp extends Op {
	data : lone Data,
}{
	receiver in Client_GoodClient
	args = data
}

sig reqAccessToken extends Op {
	authGrant : lone Data,
}{
	receiver in AuthorizationServer_GoodServer
	args = authGrant
}
one sig AuthorizationServer_GoodServer extends Module {
	accessTokens : AuthGrant -> AccessToken,
	cookies : Op -> Cookie,
	addr : lone Addr,
	protected : set Op,
}{
	all o : this.receives[reqAccessToken] | (some accessTokens[o.authGrant])
	all o : this.sends[sendResp] | ((some (o.trigger & reqAccessToken))) and ((accessTokens[o.trigger.authGrant] = o.data))
}

one sig ResourceOwner_GoodServer extends Module {
	authGrants : Credential -> AuthGrant,
	cookies : Op -> Cookie,
	addr : lone Addr,
	protected : set Op,
}{
	all o : this.receives[reqAuth] | (some authGrants[o.cred])
	all o : this.sends[sendResp] | ((some (o.trigger & reqAuth))) and ((authGrants[o.trigger.cred] = o.data))
}
sig reqAuth extends Op {
	cred : lone Data,
}{
	receiver in ResourceOwner_GoodServer
	args = cred
}

sig reqRes extends Op {
	accessToken : lone Data,
}{
	receiver in ResourceServer_GoodServer
	args = accessToken
}
one sig ResourceServer_GoodServer extends Module {
	resources : AccessToken -> Resource,
	cookies : Op -> Cookie,
	addr : lone Addr,
	protected : set Op,
}{
	all o : this.receives[reqRes] | (some resources[o.accessToken])
	all o : this.sends[sendResp] | ((some (o.trigger & reqRes))) and ((resources[o.trigger.accessToken] = o.data))
}

fact invocationFacts {
	httpResp.sender in BadServer
	reqRes.sender in Client_GoodClient
	reqAccessToken.sender in Client_GoodClient
	sendResp.sender in AuthorizationServer_GoodServer + ResourceOwner_GoodServer + ResourceServer_GoodServer
	reqAuth.sender in Client_GoodClient
}
fact dataCreationFacts {
	creates.BadDOM in BadServer
	creates.AccessToken in AuthorizationServer_GoodServer
	creates.AuthGrant in ResourceOwner_GoodServer
	creates.Credential in Client_GoodClient
	creates.Resource in ResourceServer_GoodServer
	creates.Cookie in AuthorizationServer_GoodServer + ResourceOwner_GoodServer + ResourceServer_GoodServer
}


run SanityCheck {
	all m : Module |
		some sender.m & SuccessOp
} for 5 but 9 Data, 10 Step, 9 Op

check Confidentiality {
   Confidentiality 
} for 5 but 9 Data, 10 Step, 9 Op

check Integrity {
   Integrity
} for 5 but 9 Data, 10 Step, 9 Op
