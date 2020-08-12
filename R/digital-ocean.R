
# can't really test these.
# nocov start

checkAnalogSea <- function() {
  if (!requireNamespace("analogsea", quietly = TRUE)) {
    stop("The analogsea package is not available but is required in order to use the provisioning functions. Please install analogsea.",
         call. = FALSE)
  }


  suggests <- read.dcf(system.file("DESCRIPTION", package = "plumber"))[1, "Suggests"]
  pkgs <- strsplit(suggests, ",")[[1]]
  pkgs <- trimws(pkgs)
  analogsea_version <- gsub("[^.0-9]", "", pkgs[grepl("^analogsea ", pkgs)])
  if (utils::packageVersion("analogsea") < package_version(analogsea_version)) {
    stop("The analogsea package is not high enough. Please update `analogsea`.",
         call. = FALSE)
  }
}

#' Provision a DigitalOcean plumber server
#'
#' Create (if required), install the necessary prerequisites, and
#' deploy a sample plumber application on a DigitalOcean virtual machine.
#' You may sign up for a Digital Ocean account [here](https://m.do.co/c/add0b50f54c4).
#' This command is idempotent, so feel free to run it on a single server multiple times.
#' @param droplet The DigitalOcean droplet that you want to provision (see [analogsea::droplet()]). If empty, a new DigitalOcean server will be created.
#' @param unstable If `FALSE`, will install plumber from CRAN. If `TRUE`, will install the unstable version of plumber from GitHub.
#' @param example If `TRUE`, will deploy an example API named `hello` to the server on port 8000.
#' @param ... Arguments passed into the [analogsea::droplet_create()] function.
#' @details Provisions a Ubuntu 20.04-x64 droplet with the following customizations:
#'  - A recent version of R installed
#'  - plumber installed globally in the system library
#'  - An example plumber API deployed at `/var/plumber`
#'  - A systemd definition for the above plumber API which will ensure that the plumber
#'    API is started on machine boot and respawned if the R process ever crashes. On the
#'    server you can use commands like `systemctl restart plumber` to manage your API, or
#'    `journalctl -u plumber` to see the logs associated with your plumber process.
#'  - The `nginx`` web server installed to route web traffic from port 80 (HTTP) to your plumber
#'    process.
#'  - `ufw` installed as a firewall to restrict access on the server. By default it only
#'    allows incoming traffic on port 22 (SSH) and port 80 (HTTP).
#'  - A 4GB swap file is created to ensure that machines with little RAM (the default) are
#'    able to get through the necessary R package compilations.
#' @export
do_provision <- function(droplet, unstable=FALSE, example=TRUE, ...){
  checkAnalogSea()

  if (missing(droplet)){
    # No droplet provided; create a new server
    message("THIS ACTION COSTS YOU MONEY!")
    message("Provisioning a new server for which you will get a bill from DigitalOcean.")

    createArgs <- list(...)
    createArgs$tags <- c(createArgs$tags, "plumber")
    createArgs$image <- "ubuntu-20-04-x64"

    droplet <- do.call(analogsea::droplet_create, createArgs)

    # Wait for the droplet to come online
    analogsea::droplet_wait(droplet)

    # I often still get a closed port after droplet_wait returns. Buffer for just a bit
    Sys.sleep(25)

    # Refresh the droplet; sometimes the original one doesn't yet have a network interface.
    droplet <- analogsea::droplet(id=droplet$id)
  }

  # Provision
  lines <- droplet_capture(droplet, 'swapon | grep "/swapfile" | wc -l')
  if (lines != "1"){
    analogsea::debian_add_swap(droplet)
  }
  install_new_r(droplet)
  install_plumber(droplet, unstable)
  install_api(droplet)
  install_nginx(droplet)
  install_firewall(droplet)

  if (example){
    do_deploy_api(droplet, "hello", system.file("plumber", "10-welcome", package="plumber"), port=8000, forward=TRUE)
  }

  invisible(droplet)
}

install_plumber <- function(droplet, unstable){
  # Satisfy sodium's requirements
  analogsea::debian_apt_get_install(droplet, "libsodium-dev")

  if (unstable){
    analogsea::debian_apt_get_install(droplet, "libcurl4-openssl-dev")
    analogsea::debian_apt_get_install(droplet, "libgit2-dev")
    analogsea::debian_apt_get_install(droplet, "libssl-dev")
    analogsea::debian_apt_get_install(droplet, "libsodium-dev")
    analogsea::install_r_package(droplet, "remotes", repo="https://cran.rstudio.com")
    analogsea::droplet_ssh(droplet, "Rscript -e \"remotes::install_github('rstudio/plumber')\"")
  } else {
    analogsea::install_r_package(droplet, "plumber")
  }
}

#' Captures the output from running some command via SSH
#' @noRd
droplet_capture <- function(droplet, command){
    tf <- tempdir()
    randName <- paste(sample(c(letters, LETTERS), size=10, replace=TRUE), collapse="")
    tff <- file.path(tf, randName)
    on.exit({
      if (file.exists(tff)) {
        file.remove(tff)
      }
    })
    analogsea::droplet_ssh(droplet, paste0(command, " > /tmp/", randName))
    analogsea::droplet_download(droplet, paste0("/tmp/", randName), tf)
    analogsea::droplet_ssh(droplet, paste0("rm /tmp/", randName))
    lin <- readLines(tff)
    lin
}

install_api <- function(droplet){
  analogsea::droplet_ssh(droplet, "mkdir -p /var/plumber")
  example_plumber_file <- system.file("plumber", "10-welcome", "plumber.R", package="plumber")
  if (nchar(example_plumber_file) < 1) {
    stop("Could not find example 10-welcome plumber file", call. = FALSE)
  }
  analogsea::droplet_upload(
    droplet,
    local = example_plumber_file,
    remote = "/var/plumber/",
    verbose = TRUE)
}

install_firewall <- function(droplet){
  analogsea::droplet_ssh(droplet, "ufw allow http")
  analogsea::droplet_ssh(droplet, "ufw allow ssh")
  analogsea::droplet_ssh(droplet, "ufw -f enable")
}

install_nginx <- function(droplet){
  analogsea::debian_apt_get_install(droplet, "nginx")
  analogsea::droplet_ssh(droplet, "rm -f /etc/nginx/sites-enabled/default") # Disable the default site
  analogsea::droplet_ssh(droplet, "mkdir -p /var/certbot")
  analogsea::droplet_ssh(droplet, "mkdir -p /etc/nginx/sites-available/plumber-apis/")
  analogsea::droplet_upload(droplet, local=system.file("server", "nginx.conf", package="plumber"),
                 remote="/etc/nginx/sites-available/plumber")
  analogsea::droplet_ssh(droplet, "ln -sf /etc/nginx/sites-available/plumber /etc/nginx/sites-enabled/")
  analogsea::droplet_ssh(droplet, "systemctl reload nginx")
}

install_new_r <- function(droplet){
  analogsea::droplet_ssh(droplet, "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 51716619E084DAB9")
  analogsea::droplet_ssh(droplet, "echo 'deb https://cran.rstudio.com/bin/linux/ubuntu focal-cran40/' >> /etc/apt/sources.list.d/cran.list")
  # TODO: use the analogsea version once https://github.com/sckott/analogsea/issues/139 is resolved
  #analogsea::debian_apt_get_update(droplet)
  analogsea::droplet_ssh(droplet, "sudo apt-get update -qq")
  analogsea::droplet_ssh(droplet, 'sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade')

  analogsea::debian_install_r(droplet)
}

#' Add HTTPS to a plumber Droplet
#'
#' Adds TLS/SSL (HTTPS) to a droplet created using [do_provision()].
#'
#' In order to get a TLS/SSL certificate, you need to point a domain name to the
#' IP address associated with your droplet. If you don't already have a domain
#' name, you can register one [here](http://tres.tl/domain). Point a (sub)domain
#' to the IP address associated with your plumber droplet before calling this
#' function. These changes may take a few minutes or hours to propagate around
#' the Internet, but once complete you can then execute this function with the
#' given domain to be granted a TLS/SSL certificate for that domain.
#' @details Obtains a free TLS/SSL certificate from
#'   [letsencrypt](https://letsencrypt.org/) and installs it in nginx. It also
#'   configures nginx to route all unencrypted HTTP traffic (port 80) to HTTPS.
#'   Your TLS certificate will be automatically renewed and deployed. It also
#'   opens port 443 in the firewall to allow incoming HTTPS traffic.
#'
#'   Historically, HTTPS certificates required payment in advance. If you
#'   appreciate this service, consider [donating to the letsencrypt
#'   project](https://letsencrypt.org/donate/).
#' @param droplet The droplet on which to act. See [analogsea::droplet()].
#' @param domain The domain name associated with this instance. Used to obtain a
#'   TLS/SSL certificate.
#' @param email Your email address; given only to letsencrypt when requesting a
#'   certificate to enable them to contact you about issues with renewal or
#'   security.
#' @param termsOfService Set to `TRUE` to agree to the letsencrypt subscriber
#'   agreement. At the time of writing, the current version is available [here](https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf).
#'   Must be set to true to obtain a certificate through letsencrypt.
#' @param force If `FALSE`, will abort if it believes that the given domain name
#'   is not yet pointing at the appropriate IP address for this droplet. If
#'   `TRUE`, will ignore this check and attempt to proceed regardless.
#' @export
do_configure_https <- function(droplet, domain, email, termsOfService=FALSE, force=FALSE){
  checkAnalogSea()

  # This could be done locally, but I don't have a good way of testing cross-platform currently.
  # I can't figure out how to capture the output of the system() call inside
  # of droplet_ssh, so just write to and download a file :\
  if (!force){
    nslookup <- tempfile()

    nsout <- droplet_capture(droplet, paste0("nslookup ", domain))

    ips <- nsout[grepl("^Address: ", nsout)]
    ip <- gsub("^Address: (.*)$", "\\1", ips)

    # It turns out that the floating IP is not data that we have about the droplet
    # Also, if the floating IP was assigned after we created the droplet object that was
    # passed in, then we might not have that information available anyways.
    # It turns out that we can use the 'Droplet Metadata' system to query for this info
    # from the droplet to get a real-time response.
    metadata <- droplet_capture(droplet, "curl http://169.254.169.254/metadata/v1.json")

    parsed <- safeFromJSON(metadata)
    floating <- unlist(lapply(parsed$floating_ip, function(ipv){ ipv$ip_address }))
    ephemeral <- unlist(parsed$interfaces$public)["ipv4.ip_address"]

    if (ip %in% ephemeral) {
      warning("You should consider using a Floating IP address on your droplet for DNS. Currently ",
              "you're using the ephemeral IP address of your droplet for DNS which is dangerous; ",
              "as soon as you terminate your droplet your DNS records will be pointing to an IP ",
              "address you no longer control. A floating IP will give you the opportunity to ",
              "create a new droplet and reassign the floating IP used with DNS later.")
    } else if (! ip %in% floating) {
      print(list(ip=ip, floatingIPs = unname(floating), ephemeralIPs = unname(ephemeral)))
      stop("It doesn't appear that the domain name '", domain, "' is pointed to an IP address associated with this droplet. ",
           "This could be due to a DNS misconfiguration or because the changes just haven't propagated through the Internet yet. ",
           "If you believe this is an error, you can override this check by setting force=TRUE.")
    }
    message("Confirmed that '", domain, "' references one of the available IP addresses.")
  }

  if(missing(domain)){
    stop("You must provide a valid domain name which points to this server in order to get an SSL certificate.")
  }
  if (missing(email)){
    stop("You must provide an email to letsencrypt -- the provider of your SSL certificate -- for 'urgent renewal and security notices'.")
  }
  if (!termsOfService){
    stop("You must agree to the letsencrypt terms of service before running this function")
  }

  # Trim off any protocol prefix if one exists
  domain <- sub("^https?://", "", domain)
  # Trim off any trailing slash if one exists.
  domain <- sub("/$", "", domain)

  # Prepare the nginx conf file.
  conf <- readLines(system.file("server", "nginx-ssl.conf", package="plumber"))
  conf <- gsub("\\$DOMAIN\\$", domain, conf)

  conffile <- tempfile()
  writeLines(conf, conffile)

  analogsea::droplet_ssh(droplet, "add-apt-repository ppa:certbot/certbot")
  analogsea::debian_apt_get_update(droplet)
  analogsea::debian_apt_get_install(droplet, "certbot")
  analogsea::droplet_ssh(droplet, "ufw allow https")
  analogsea::droplet_ssh(droplet, sprintf("certbot certonly --webroot -w /var/certbot/ -n -d %s --email %s --agree-tos --renew-hook '/bin/systemctl reload nginx'", domain, email))
  analogsea::droplet_upload(droplet, conffile, "/etc/nginx/sites-available/plumber")
  analogsea::droplet_ssh(droplet, "systemctl reload nginx")

  # TODO: add this as a catch()
  file.remove(conffile)

  invisible(droplet)
}

#' Deploy or Update an API
#'
#' Deploys an API from your local machine to make it available on the remote
#' plumber server.
#' @param droplet The droplet on which to act. It's expected that this droplet
#'   was provisioned using [do_provision()].  See [analogsea::droplet()] to
#'   obtain a reference to a running droplet.
#' @param path The remote path/name of the application
#' @param localPath The local path to the API that you want to deploy. The
#'   entire directory referenced will be deployed, and the `plumber.R` file
#'   inside of that directory will be used as the root plumber file. The
#'   directory MUST contain a `plumber.R` file.
#' @param port The internal port on which this service should run. This will not
#'   be user visible, but must be unique and point to a port that is available
#'   on your server. If unsure, try a number around `8000`.
#' @param forward If `TRUE`, will setup requests targeting the root URL on the
#'   server to point to this application. See the [do_forward()] function for
#'   more details.
#' @param swagger If `TRUE`, will enable the Swagger interface for the remotely
#'   deployed API. By default, the interface is disabled.
#' @param preflight R commands to run after [plumb()]ing the `plumber.R` file,
#'   but before `run()`ing the plumber service. This is an opportunity to e.g.
#'   add new filters. If you need to specify multiple commands, they should be
#'   semi-colon-delimited.
#' @export
do_deploy_api <- function(droplet, path, localPath, port, forward=FALSE,
                          swagger=FALSE, preflight){
  # Trim off any leading slashes
  path <- sub("^/+", "", path)
  # Trim off any trailing slashes if any exist.
  path <- sub("/+$", "", path)

  if (grepl("/", path)){
    stop("Can't deploy to nested paths. '", path, "' should not have a / in it.")
  }

  # TODO: check local path for plumber.R file.
  apiPath <- file.path(localPath, "plumber.R")
  if (!file.exists(apiPath)){
    stop("Your local API must contain a `plumber.R` file. ", apiPath, " does not exist")
  }

  ### UPLOAD the API ###
  remoteTmp <- paste0("/tmp/", paste0(sample(LETTERS, 10, replace=TRUE), collapse=""))
  dirName <- basename(localPath)
  analogsea::droplet_ssh(droplet, paste0("mkdir -p ", remoteTmp))
  analogsea::droplet_upload(droplet, local=localPath, remote=remoteTmp)
  analogsea::droplet_ssh(droplet, paste("mv", paste0(remoteTmp, "/", dirName, "/"), paste0("/var/plumber/", path)))

  ### SYSTEMD ###
  serviceName <- paste0("plumber-", path)

  service <- readLines(system.file("server", "plumber.service", package="plumber"))
  service <- gsub("\\$PORT\\$", port, service)
  service <- gsub("\\$PATH\\$", paste0("/", path), service)

  if (missing(preflight)){
    preflight <- ""
  } else {
    # Append semicolon if necessary
    if (!grepl(";\\s*$", preflight)){
      preflight <- paste0(preflight, ";")
    }
  }
  service <- gsub("\\$PREFLIGHT\\$", preflight, service)

  if (missing(swagger)){
    swagger <- "FALSE"
  } else {
    swagger <- "TRUE"
  }
  service <- gsub("\\$SWAGGER\\$", swagger, service)

  servicefile <- tempfile()
  writeLines(service, servicefile)

  remotePath <- file.path("/etc/systemd/system", paste0(serviceName, ".service"))

  analogsea::droplet_upload(droplet, servicefile, remotePath)
  analogsea::droplet_ssh(droplet, "systemctl daemon-reload")

  # TODO: add this as a catch()
  file.remove(servicefile)

  # TODO: differentiate between new service (start) and existing service (restart)
  analogsea::droplet_ssh(droplet, paste0("systemctl start ", serviceName, " && sleep 1")) #TODO: can systemctl listen for the port to come online so we don't have to guess at a sleep value?
  analogsea::droplet_ssh(droplet, paste0("systemctl restart ", serviceName, " && sleep 1"))
  analogsea::droplet_ssh(droplet, paste0("systemctl enable ", serviceName))
  analogsea::droplet_ssh(droplet, paste0("systemctl status ", serviceName))

  ### NGINX ###
  # Prepare the nginx conf file
  conf <- readLines(system.file("server", "plumber-api.conf", package="plumber"))
  conf <- gsub("\\$PORT\\$", port, conf)
  conf <- gsub("\\$PATH\\$", path, conf)

  conffile <- tempfile()
  writeLines(conf, conffile)

  remotePath <- file.path("/etc/nginx/sites-available/plumber-apis", paste0(path, ".conf"))

  analogsea::droplet_upload(droplet, conffile, remotePath)

  # TODO: add this as a catch()
  file.remove(conffile)

  if (forward){
    do_forward(droplet, path)
  }

  analogsea::droplet_ssh(droplet, "systemctl reload nginx")
}

#' Forward Root Requests to an API
#'
#' @param droplet The droplet on which to act. It's expected that this droplet
#'   was provisioned using [do_provision()].
#' @param path The path to which root requests should be forwarded
#' @export
do_forward <- function(droplet, path){
  # Trim off any leading slashes
  path <- sub("^/+", "", path)
  # Trim off any trailing slashes if any exist.
  path <- sub("/+$", "", path)

  if (grepl("/", path)){
    stop("Can't deploy to nested paths. '", path, "' should not have a / in it.")
  }

  forward <- readLines(system.file("server", "forward.conf", package="plumber"))
  forward <- gsub("\\$PATH\\$", paste0(path), forward)

  forwardfile <- tempfile()
  writeLines(forward, forwardfile)

  analogsea::droplet_upload(droplet, forwardfile, "/etc/nginx/sites-available/plumber-apis/_forward.conf")

  # TODO: add this as a catch()
  file.remove(forwardfile)

  invisible(droplet)
}

#' Remove an API from the server
#'
#' Removes all services and routing rules associated with a particular service.
#' Optionally purges the associated API directory from disk.
#' @param droplet The droplet on which to act. It's expected that this droplet
#'   was provisioned using [do_provision()]. See [analogsea::droplet()] to
#'   obtain a reference to a running droplet.
#' @param path The path/name of the plumber service
#' @param delete If `TRUE`, will also delete the associated directory
#'   (`/var/plumber/whatever`) from the server.
#' @export
do_remove_api <- function(droplet, path, delete=FALSE){
  # Trim off any leading slashes
  path <- sub("^/+", "", path)
  # Trim off any trailing slashes if any exist.
  path <- sub("/+$", "", path)

  if (grepl("/", path)){
    stop("Can't deploy to nested paths. '", path, "' should not have a / in it.")
  }

  # Given that we're about to `rm -rf`, let's just be safe...
  if (grepl("\\.\\.", path)){
    stop("Paths don't allow '..'s.")
  }
  if (nchar(path)==0){
    stop("Path cannot be empty.")
  }

  serviceName <- paste0("plumber-", path)
  analogsea::droplet_ssh(droplet, paste0("systemctl stop ", serviceName))
  analogsea::droplet_ssh(droplet, paste0("systemctl disable ", serviceName))
  analogsea::droplet_ssh(droplet, paste0("rm /etc/systemd/system/", serviceName, ".service"))
  analogsea::droplet_ssh(droplet, paste0("rm /etc/nginx/sites-available/plumber-apis/", path, ".conf"))

  analogsea::droplet_ssh(droplet, "systemctl reload nginx")

  if(delete){
    analogsea::droplet_ssh(droplet, paste0("rm -rf /var/plumber/", path))
  }
}

#' Remove the forwarding rule
#'
#' Removes the forwarding rule from the root path on the server. The server will
#' no longer forward requests for `/` to an application.
#' @param droplet The droplet on which to act. It's expected that this droplet
#'   was provisioned using [do_provision()]. See [analogsea::droplet()] to obtain a reference to a running droplet.
#' @export
do_remove_forward <- function(droplet){
  analogsea::droplet_ssh(droplet, "rm /etc/nginx/sites-available/plumber-apis/_forward.conf")
  analogsea::droplet_ssh(droplet, "systemctl reload nginx")
}

# nocov end
