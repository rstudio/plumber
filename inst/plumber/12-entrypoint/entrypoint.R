
pr <- plumb("myplumberapi.R")
pr$registerHook("preroute", sessionCookie("secret", "cookieName"))

pr
