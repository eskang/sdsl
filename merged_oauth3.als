open models/basic
open models/crypto[Data]

-- module ResourceOwner_GoodServer
one sig ResourceOwner_GoodServer extends Module {
	addr : lone Addr,
	authGrants : Credential -> AuthGrant,
}
-- module BadServer
one sig BadServer extends Module {
	addr : lone Addr,
}
-- module ResourceServer_GoodServer
one sig ResourceServer_GoodServer extends Module {
	addr : lone Addr,
	resources : AccessToken -> Resource,
}
-- module AuthorizationServer_GoodServer
one sig AuthorizationServer_GoodServer extends Module {
	addr : lone Addr,
	accessTokens : AuthGrant -> AccessToken,
}
-- module Client_GoodClient
one sig Client_GoodClient extends Module {
	cred : lone Credential,
}{
	all o : this.sends[(httpReq2)] | (((some (o.trigger & (visit)))) and (o.addr = o.trigger.addr)) or (((some (o.trigger & (sendResp_httpResp)))) and (o.addr = o.trigger.redirect))
}

-- module User
one sig User extends Module {
	visits : set Addr,
}{
	all o : this.sends[(visit)] | (some (visits & o.dest))
	not ((some (visits & BadServer.addr)))
}

-- operation sendResp_httpResp
sig sendResp_httpResp extends Op {
	data : lone Data,
	redirect : lone Data,
}{
	args = data + redirect
	sender in ResourceOwner_GoodServer + BadServer + ResourceServer_GoodServer + AuthorizationServer_GoodServer
	receiver in Client_GoodClient
}
-- operation visit
sig visit extends Op {
	dest : lone Data,
}{
	args = dest
	sender in User
	receiver in Client_GoodClient
}
-- operation reqAccessToken_httpReq
sig reqAccessToken_httpReq extends Op {
	authGrant : lone Data,
	addr : lone Data,
}{
	args = authGrant + addr
	sender in Client_GoodClient
	receiver in AuthorizationServer_GoodServer
}
-- operation httpReq2
sig httpReq2 extends Op {
	addr2 : lone Data,
}{
	args = addr2
	sender in Client_GoodClient
	receiver in BadServer
}
-- operation reqRes_httpReq
sig reqRes_httpReq extends Op {
	accessToken : lone Data,
	addr : lone Data,
}{
	args = accessToken + addr
	sender in Client_GoodClient
	receiver in ResourceServer_GoodServer
}
-- operation reqAuth_httpReq
sig reqAuth_httpReq extends Op {
	cred : lone Data,
	addr : lone Data,
}{
	args = cred + addr
	sender in Client_GoodClient
	receiver in ResourceOwner_GoodServer
}
fact dataFacts {
	creates.Credential in Client_GoodClient
	creates.AuthGrant in ResourceOwner_GoodServer
	creates.AccessToken in AuthorizationServer_GoodServer
	creates.Resource in ResourceServer_GoodServer
	no creates.Payload
}
sig Credential extends Data {}
sig AuthGrant extends Data {}
sig AccessToken extends Data {}
sig Resource extends Data {}
sig Addr extends Data {}
sig Payload extends Data {}
sig OtherData extends Data {}
fact criticalDataFacts {
	CriticalData = Resource + Payload
}


fun RelevantOp : Op -> Step {
	{o : Op, t : Step | o.post = t and o in SuccessOp}
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
