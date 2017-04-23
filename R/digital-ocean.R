
#' Provision a DigitalOcean plumber server
#'
#' Create (if required), install the necessary prerequisites, and
#' deploy a sample plumber application on a DigitalOcean virtual machine.
#' This command is idempotent, so feel free to run it on a single server multiple times.
#' @param dropletId The numeric identifier of the DigitalOcean server that you want to provision (see [analogsea::droplets()]). If empty, a new DigitalOcean server will be created.
#' @param unstable If `FALSE`, will install plumber from CRAN. If `TRUE`, will install the unstable version of plumber from GitHub.
#' @param ... Arguments passed into the [analogsea::droplet_create()] function.
#' @export
do_provision <- function(dropletId, unstable=FALSE, ...){
  droplet <- NULL
  if (missing(dropletId)){
    # No dropletId provided; create a new server
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

  } else if (!is.numeric(dropletId)){
    stop("dropletId must be numeric; cannot use: '", dropletId, "' of type ", typeof(dropletId))
  } else {
    # otherwise we were given a numeric droplet ID; use that.
    droplet <- analogsea::droplet(id=dropletId)
  }

  # Provision
  droplet %>%
    debian_add_swap() %>%
    install_new_r() %>%
    install_plumber(unstable) %>%
    install_api() %>%
    setup_systemctl() %>%
    install_nginx() %>%
    install_firewall()


}

install_plumber <- function(droplet, unstable){
  if (unstable){
    droplet %>%
      analogsea::debian_apt_get_install("libcurl4-openssl-dev") %>%
      analogsea::debian_apt_get_install("libgit2-dev") %>%
      analogsea::debian_apt_get_install("libssl-dev") %>%
      install_r_package("devtools", repo="https://cran.rstudio.com") %>%
      droplet_ssh("Rscript -e \"devtools::install_github('trestletech/plumber')\"")
  } else {
    droplet %>%
      install_r_package("plumber")
  }
}

install_api <- function(droplet){
  droplet %>%
    droplet_ssh("mkdir -p /var/plumber") %>%
    droplet_upload(local=normalizePath(
      paste0(system.file("examples", "10-welcome", package="plumber"), "/**"), mustWork=FALSE), #TODO: Windows support for **?
      remote="/var/plumber/",
      verbose = TRUE)
}

install_firewall <- function(droplet){
  droplet %>%
    droplet_ssh("ufw allow http") %>%
    droplet_ssh("ufw allow ssh") %>%
    droplet_ssh("ufw -f enable")
}

install_nginx <- function(droplet){
  droplet %>%
    debian_apt_get_install("nginx") %>%
    droplet_ssh("rm -f /etc/nginx/sites-enabled/default") %>% # Disable the default site
    droplet_ssh("mkdir -p /var/certbot") %>%
    droplet_upload(local=system.file("server", "nginx.conf", package="plumber"),
                   remote="/etc/nginx/sites-available/plumber") %>%
    droplet_ssh("ln -sf /etc/nginx/sites-available/plumber /etc/nginx/sites-enabled/") %>%
    droplet_ssh("systemctl reload nginx")

}

setup_systemctl <- function(droplet){
  droplet %>%
    droplet_upload(local=system.file("server", "plumber.service", package="plumber"),
                   remote="/etc/systemd/system/plumber.service") %>%
    droplet_ssh("systemctl start plumber && sleep 1") %>% #TODO: can systemctl listen for the port to come online so we don't have to guess at a sleep value?
    droplet_ssh("systemctl enable plumber") %>%
    droplet_ssh("systemctl status plumber")
}

install_new_r <- function(droplet){
  droplet %>%
    droplet_ssh(c("echo 'deb https://cran.rstudio.com/bin/linux/ubuntu trusty/' >> /etc/apt/sources.list",
                  "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9")) %>%
    debian_apt_get_update() %>%
    debian_install_r()
}

install_ssl <- function(droplet, domain, email, termsOfService=FALSE){
  # FIXME: verify that DNS is properly configured

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

  d <- droplet %>%
    droplet_ssh("add-apt-repository ppa:certbot/certbot") %>%
    debian_apt_get_update() %>%
    debian_apt_get_install("certbot") %>%
    droplet_ssh("ufw allow https") %>%
    droplet_ssh(sprintf("certbot certonly --webroot -w /var/certbot/ -n -d %s --email %s --agree-tos --renew-hook '/bin/systemctl reload nginx'", domain, email)) %>%
    droplet_upload(conffile, "/etc/nginx/sites-available/plumber") %>%
    droplet_ssh("systemctl reload nginx")

  # TODO: add this as a catch()
  file.remove(conffile)

  d
}

