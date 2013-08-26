open models/basic
open models/crypto[Data]

-- module ResourceOwner
one sig ResourceOwner extends Module {
	authGrants : Credential -> AuthGrant,
}{
	all o : this.receives[reqAuth] | (some authGrants[arg[o.(reqAuth <: cred)]])
	all o : this.sends[sendResp] | triggeredBy[o,reqAuth]
	all o : this.sends[sendResp] | authGrants[o.trigger.cred] = o.(sendResp <: data)
}

-- module ClientApp
one sig ClientApp extends Module {
	cred : lone Credential,
}
-- module AuthorizationServer
one sig AuthorizationServer extends Module {
	accessTokens : AuthGrant -> AccessToken,
}{
	all o : this.receives[reqAccessToken] | (some accessTokens[o.(reqAccessToken <: authGrant)])
	all o : this.sends[sendResp] | triggeredBy[o,reqAccessToken]
	all o : this.sends[sendResp] | accessTokens[o.trigger.authGrant] = o.(sendResp <: data)
}

-- module ResourceServer
one sig ResourceServer extends Module {
	resources : AccessToken -> Resource,
}{
	all o : this.receives[reqRes] | (some resources[arg[o.(reqRes <: accessToken)]])
	all o : this.sends[sendResp] | triggeredBy[o,reqRes]
	all o : this.sends[sendResp] | resources[o.trigger.accessToken] = o.(sendResp <: data)
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = ResourceOwner + ClientApp + AuthorizationServer + ResourceServer
}

-- operation reqRes
sig reqRes extends Op {
	accessToken : lone Data,
}{
	args = accessToken
	sender in ClientApp
	receiver in ResourceServer
}

-- operation reqAccessToken
sig reqAccessToken extends Op {
	authGrant : lone Data,
}{
	args = authGrant
	sender in ClientApp
	receiver in AuthorizationServer
}

-- operation sendResp
sig sendResp extends Op {
	data : lone Data,
}{
	args = data
	sender in ResourceOwner + AuthorizationServer + ResourceServer
	receiver in ClientApp
}

-- operation reqAuth
sig reqAuth extends Op {
	cred : lone Data,
}{
	args = cred
	sender in ClientApp
	receiver in ResourceOwner
}

-- fact dataFacts
fact dataFacts {
	creates.Credential in ClientApp
	creates.AuthGrant in ResourceOwner
	creates.AccessToken in AuthorizationServer
	creates.Resource in ResourceServer
}

-- datatype declarations
sig Credential extends Data {
}{
	no fields
}
sig AuthGrant extends Data {
}{
	no fields
}
sig AccessToken extends Data {
}{
	no fields
}
sig Resource extends Data {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }

-- fact criticalDataFacts
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
