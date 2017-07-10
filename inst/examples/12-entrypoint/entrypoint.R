
pr <- plumb("myplumberapi.R")
pr$addGlobalProcessor(sessionCookie("secret", "cookieName"))

pr
