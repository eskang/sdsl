open models/basic
open models/crypto[Data]

-- module ResourceOwner
one sig ResourceOwner extends Module {
	authGrants : Credential -> AuthGrant,
}{
	all o : this.receives[(reqAuth)] | (some authGrants[o.cred])
	all o : this.sends[(sendResp)] | ((some (o.trigger & (reqAuth)))) and ((authGrants[o.trigger.cred] = o.data))
}

-- module Client
one sig Client extends Module {
	cred : lone Credential,
}
-- module AuthorizationServer
one sig AuthorizationServer extends Module {
	accessTokens : AuthGrant -> AccessToken,
}{
	all o : this.receives[(reqAccessToken)] | (some accessTokens[o.authGrant])
	all o : this.sends[(sendResp)] | ((some (o.trigger & (reqAccessToken)))) and ((accessTokens[o.trigger.authGrant] = o.data))
}

-- module ResourceServer
one sig ResourceServer extends Module {
	resources : AccessToken -> Resource,
}{
	all o : this.receives[(reqRes)] | (some resources[o.accessToken])
	all o : this.sends[(sendResp)] | ((some (o.trigger & (reqRes)))) and ((resources[o.trigger.accessToken] = o.data))
}

fact trustedModuleFacts {
	TrustedModule = ResourceOwner + Client + AuthorizationServer + ResourceServer
}
-- operation reqRes
sig reqRes extends Op {
	accessToken : lone Data,
}{
	args = accessToken
	sender in Client
	receiver in ResourceServer
}
-- operation reqAccessToken
sig reqAccessToken extends Op {
	authGrant : lone Data,
}{
	args = authGrant
	sender in Client
	receiver in AuthorizationServer
}
-- operation sendResp
sig sendResp extends Op {
	data : lone Data,
}{
	args = data
	sender in ResourceOwner + AuthorizationServer + ResourceServer
	receiver in Client
}
-- operation reqAuth
sig reqAuth extends Op {
	cred : lone Data,
}{
	args = cred
	sender in Client
	receiver in ResourceOwner
}
fact dataFacts {
	creates.Credential in Client
	creates.AuthGrant in ResourceOwner
	creates.AccessToken in AuthorizationServer
	creates.Resource in ResourceServer
}
sig Credential extends Data {}
sig AuthGrant extends Data {}
sig AccessToken extends Data {}
sig Resource extends Data {}
sig OtherData extends Data {}
fact criticalDataFacts {
	CriticalData = Resource
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
