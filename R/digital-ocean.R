
checkAnalogSea <- function(){
  if (!requireNamespace("analogsea", quietly = TRUE)) {
    stop("The analogsea package is not available but is required in order to use the provisioning functions. Please install analogsea.",
         call. = FALSE)
  }
}

#' Provision a DigitalOcean plumber server
#'
#' Create (if required), install the necessary prerequisites, and
#' deploy a sample plumber application on a DigitalOcean virtual machine.
#' This command is idempotent, so feel free to run it on a single server multiple times.
#' @param droplet The DigitalOcean droplet that you want to provision (see [analogsea::droplet()]). If empty, a new DigitalOcean server will be created.
#' @param unstable If `FALSE`, will install plumber from CRAN. If `TRUE`, will install the unstable version of plumber from GitHub.
#' @param ... Arguments passed into the [analogsea::droplet_create()] function.
#' @details Provisions a Ubuntu 16.04-x64 droplet with the following customizations:
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
do_provision <- function(droplet, unstable=FALSE, ...){
  checkAnalogSea()

  if (missing(droplet)){
    # No droplet provided; create a new server
    message("THIS ACTION COSTS YOU MONEY!")
    message("Provisioning a new server for which you will get a bill from DigitalOcean.")

    createArgs <- list(...)
    createArgs$tags <- c(createArgs$tags, "plumber")
    createArgs$image <- "ubuntu-16-04-x64"

    droplet <- do.call(analogsea::droplet_create, createArgs)

    # Wait for the droplet to come online
    analogsea::droplet_wait(droplet)

    # I often still get a closed port after droplet_wait returns. Buffer for just a bit
    Sys.sleep(15)

    # Refresh the droplet; sometimes the original one doesn't yet have a network interface.
    droplet <- analogsea::droplet(id=droplet$id)
  }

  # Provision
  analogsea::debian_add_swap(droplet) # FIXME: don't do if already added, not idempotent.
  install_new_r(droplet)
  install_plumber(droplet, unstable)
  install_api(droplet)
  setup_systemctl(droplet)
  install_nginx(droplet)
  install_firewall(droplet)
}

install_plumber <- function(droplet, unstable){
  if (unstable){
    analogsea::debian_apt_get_install(droplet, "libcurl4-openssl-dev")
    analogsea::debian_apt_get_install(droplet, "libgit2-dev")
    analogsea::debian_apt_get_install(droplet, "libssl-dev")
    analogsea::install_r_package(droplet, "devtools", repo="https://cran.rstudio.com")
    analogsea::droplet_ssh(droplet, "Rscript -e \"devtools::install_github('trestletech/plumber')\"")
  } else {
    analogsea::install_r_package(droplet, "plumber")
  }
}

install_api <- function(droplet){
  analogsea::droplet_ssh(droplet, "mkdir -p /var/plumber")
  analogsea::droplet_upload(droplet, local=normalizePath(
      paste0(system.file("examples", "10-welcome", package="plumber"), "/**"), mustWork=FALSE), #TODO: Windows support for **?
      remote="/var/plumber/",
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
  analogsea::droplet_upload(droplet, local=system.file("server", "nginx.conf", package="plumber"),
                 remote="/etc/nginx/sites-available/plumber")
  analogsea::droplet_ssh(droplet, "ln -sf /etc/nginx/sites-available/plumber /etc/nginx/sites-enabled/")
  analogsea::droplet_ssh(droplet, "systemctl reload nginx")
}

setup_systemctl <- function(droplet){
  analogsea::droplet_upload(droplet, local=system.file("server", "plumber.service", package="plumber"),
                 remote="/etc/systemd/system/plumber.service")
  analogsea::droplet_ssh(droplet, "systemctl start plumber && sleep 1") #TODO: can systemctl listen for the port to come online so we don't have to guess at a sleep value?
  analogsea::droplet_ssh(droplet, "systemctl enable plumber")
  analogsea::droplet_ssh(droplet, "systemctl status plumber")
}

install_new_r <- function(droplet){
  analogsea::droplet_ssh(droplet, c("echo 'deb https://cran.rstudio.com/bin/linux/ubuntu trusty/' >> /etc/apt/sources.list",
                  "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9"))
  analogsea::debian_apt_get_update(droplet)
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
#' function. These changes may take a few minutes or hours to propogate around
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
#' @param droplet The DigitalOcean droplet on which you wish to provision HTTPS
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

    analogsea::droplet_ssh(droplet, paste0("nslookup ", domain, " > /tmp/nslookup"))
    analogsea::droplet_download(droplet, "/tmp/nslookup", nslookup)

    nsout <- readLines(nslookup)
    file.remove(nslookup)
    ips <- nsout[grepl("^Address: ", nsout)]
    ip <- gsub("^Address: (.*)$", "\\1", ips)

    do_ips <- unlist(lapply(droplet$networks, function(x){ lapply(x, "[[", "ip_address") }))
    if (length(intersect(ip, do_ips)) == 0){
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

  droplet
}

