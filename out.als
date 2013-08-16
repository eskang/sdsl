open models/basic

-- module BadServer
one sig BadServer extends Module {
	addr : lone Addr,
}{
	all o : this.sends[(sendResp_httpResp)] | some o.((sendResp_httpResp) <: trigger) & (httpReq2)
}

-- module Client_GoodClient
one sig Client_GoodClient extends Module {
	cookies : Addr -> Cookie,
	cred : lone Credential,
}{
	all o : this.sends[(httpReq2)] | (some cookies[o.((httpReq2) <: dest2)] implies some o.((httpReq2) <: headers2) & cookies[o.((httpReq2) <: dest2)]) and (no o.((httpReq2) <: headers2) & Payload)
}

-- module ResourceServer_GoodServer
one sig ResourceServer_GoodServer extends Module {
	cookies : Op -> Cookie,
	addr : lone Addr,
	protected : set Op,
	resources : AccessToken -> Resource,
}{
	all o : this.receives[(reqRes_httpReq)] | ((some resources[o.accessToken])) and (o in protected implies some o.((reqRes_httpReq) <: headers) & cookies[o])
	all o : this.sends[(sendResp_httpResp)] | (((some (o.trigger & (reqRes_httpReq)))) and ((resources[o.trigger.accessToken] = o.data))) and (some o.((sendResp_httpResp) <: trigger) & (reqRes_httpReq+reqAccessToken_httpReq+reqAuth_httpReq))
}

-- module ResourceOwner_GoodServer
one sig ResourceOwner_GoodServer extends Module {
	cookies : Op -> Cookie,
	addr : lone Addr,
	protected : set Op,
	authGrants : Credential -> AuthGrant,
}{
	all o : this.receives[(reqAuth_httpReq)] | ((some authGrants[o.cred])) and (o in protected implies some o.((reqAuth_httpReq) <: headers) & cookies[o])
	all o : this.sends[(sendResp_httpResp)] | (((some (o.trigger & (reqAuth_httpReq)))) and ((authGrants[o.trigger.cred] = o.data))) and (some o.((sendResp_httpResp) <: trigger) & (reqRes_httpReq+reqAccessToken_httpReq+reqAuth_httpReq))
}

-- module AuthorizationServer_GoodServer
one sig AuthorizationServer_GoodServer extends Module {
	cookies : Op -> Cookie,
	addr : lone Addr,
	protected : set Op,
	accessTokens : AuthGrant -> AccessToken,
}{
	all o : this.receives[(reqAccessToken_httpReq)] | ((some accessTokens[o.authGrant])) and (o in protected implies some o.((reqAccessToken_httpReq) <: headers) & cookies[o])
	all o : this.sends[(sendResp_httpResp)] | (((some (o.trigger & (reqAccessToken_httpReq)))) and ((accessTokens[o.trigger.authGrant] = o.data))) and (some o.((sendResp_httpResp) <: trigger) & (reqRes_httpReq+reqAccessToken_httpReq+reqAuth_httpReq))
}

-- operation reqRes_httpReq
sig reqRes_httpReq extends Op {
	accessToken : lone Data,
	headers : set Data,
	dest : lone Addr,
}{
	args = accessToken + headers + dest
	sender in Client_GoodClient
	receiver in ResourceServer_GoodServer
}
-- operation httpReq2
sig httpReq2 extends Op {
	headers2 : set Data,
	dest2 : lone Addr,
}{
	args = headers2 + dest2
	sender in Client_GoodClient
	receiver in BadServer
}
-- operation sendResp_httpResp
sig sendResp_httpResp extends Op {
	data : lone Data,
	respHeaders : set Data,
}{
	args = data + respHeaders
	sender in BadServer + ResourceServer_GoodServer + ResourceOwner_GoodServer + AuthorizationServer_GoodServer
	receiver in Client_GoodClient
}
-- operation reqAccessToken_httpReq
sig reqAccessToken_httpReq extends Op {
	authGrant : lone Data,
	headers : set Data,
	dest : lone Addr,
}{
	args = authGrant + headers + dest
	sender in Client_GoodClient
	receiver in AuthorizationServer_GoodServer
}
-- operation reqAuth_httpReq
sig reqAuth_httpReq extends Op {
	cred : lone Data,
	headers : set Data,
	dest : lone Addr,
}{
	args = cred + headers + dest
	sender in Client_GoodClient
	receiver in ResourceOwner_GoodServer
}
fact dataCreationFacts {
	creates.AccessToken in AuthorizationServer_GoodServer
	creates.AuthGrant in ResourceOwner_GoodServer
	creates.Resource in ResourceServer_GoodServer
	creates.BadDOM in BadServer
	creates.Cookie in ResourceServer_GoodServer + ResourceOwner_GoodServer + AuthorizationServer_GoodServer
	creates.Credential in Client_GoodClient
}
sig Credential extends Data {}
sig AuthGrant extends Data {}
sig AccessToken extends Data {}
sig Resource extends Data {}
sig Cookie extends Data {}
sig BadDOM extends Data {}
sig Addr extends Data {}
sig Payload extends Data {}


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
